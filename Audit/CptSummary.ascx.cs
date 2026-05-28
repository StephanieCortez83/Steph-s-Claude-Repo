using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.Common;
using CCSBusinessObjects.Utility;
using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Web.UI.WebControls;
using ACS.Core.Common.Configuration;
using ACS.Core.Extensions;
using ACS.Core.Sql;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.AppSystem;
using static StackExchange.Redis.Role;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class CptSummary : BaseAuditControl
	{
		#region Internals
		private enum GridIndexes
		{
			Id = 0,
			ChartSection = 1,
			PreviousCode = 2,
			AuditorCode = 3,
			AuditAction = 4,
			Correct = 5,
			ExcludeFromQaHidden = 6,
			ExcludeFromQa = 7,
			ExcludeReason = 8,
		}
		private bool? _isUserAuthorizedToExcludeFromQa;
		#endregion Internals

		#region Properties
		public IChartAuditProcedureVersionItemService CharAuditProcedureVersionItemService { get; set; }
		public IChartAuditFacilityLosVersionItemService ChartAuditFacilityLosVersionItemService { get; set; }
		public IChartAuditPhysicianLosVersionItemService ChartAuditPhysicianLosVersionItemService { get; set; }
		public IChartAuditAnesthesiaVersionItemService ChartAuditAnesthesiaVersionItemService { get; set; }
		private int CorrectCount { get; set; }
		private int RevisionCount { get; set; }
		private int AdditionCount { get; set; }
		private int DeletionCount { get; set; }
		private bool IsUserAuthorizedToExcludeFromQa
		{
			get
			{
				if (!_isUserAuthorizedToExcludeFromQa.HasValue)
					_isUserAuthorizedToExcludeFromQa = RequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_ALLOW_EXCLUDE_FROM_QA_REPORT);
				
				return _isUserAuthorizedToExcludeFromQa.Value;
			}
		}
			
		#endregion Properties

		public void LoadModel(
			WebRequestManager requestManager,
			Chart chart,
			IEnumerable<ExcludeFromQAReportReason> excludeReasons,
			ChartPostBillAudit chartPostBillAudit)
		{
			RequestManager = requestManager;
			Chart = chart;
			ExcludeReasons = excludeReasons;
			ChartPostBillAudit = chartPostBillAudit;
			ChartAuditVersions = ChartAuditVersionService.GetChartAuditVersionListByChartAuditId(ChartPostBillAudit.Id);
			ChartAuditVersion = ChartAuditVersions.OrderByDescending(x => x.VersionNumber).FirstOrDefault();
		}

		public void ModelToView()
		{
			grdCPTSummaryCoder.DataSource = GetCptCodeSummaries();
			grdCPTSummaryCoder.DataBind();

			PopulateOverallAccuracyGrid();
		}

		protected void grdCPTSummaryCoder_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ProcedureSummary auditAction))
				return;

			var chkExcludeFromReport = (CheckBox)e.Item.FindControl("chkExcludeFromReport");
			var ddlExcludeReason = (DropDownList)e.Item.FindControl("ddlExcludeReason");

			if (e.Item.FindControl("ltlChartSectionId") is Literal ltlChartSectionId)
				ltlChartSectionId.Text = ((int)auditAction.ChartAuditSectionTypeCode).ToString();
			if (e.Item.FindControl("lblChartSection") is Label lblChartSection)
			{
				lblChartSection.Text = auditAction.ChartAuditSectionTypeCode.GetShortName();
				lblChartSection.ToolTip = auditAction.ChartAuditSectionTypeCode.GetDisplayName();
			}
			if (e.Item.FindControl("lblPreviousCode") is Label lblPreviousCode)
			{
				lblPreviousCode.Text = auditAction.PreviousCode;
				lblPreviousCode.ToolTip = auditAction.PreviousCodeDescription;
			}
			if (e.Item.FindControl("lblAuditorCode") is Label lblAuditorCode)
			{
				lblAuditorCode.Text = auditAction.AuditorCode;
				lblAuditorCode.ToolTip = auditAction.AuditorCodeDescription;
			}
			if (e.Item.FindControl("lblAuditAction") is Label lblAuditAction)
				lblAuditAction.Text = auditAction.ChartAuditActionTypeCode.GetDisplayDescription();
			if (e.Item.FindControl("chkCorrectCode") is CheckBox chkCorrectCode)
				chkCorrectCode.Checked = auditAction.CorrectCode;

			FillDropDownList(
				ddlExcludeReason,
				auditAction.ExcludeReasons.ToList(),
				"ExcludeFromQAReportReasonDescription",
				"ExcludeFromQAReportReasonID",
				auditAction.ExcludeReasonId.ToString(),
				"None",
				"-1");

			// If the chart is not automated and automation error is not already selected, then remove the automation reason from the drop down list.
			if (!Chart.FacilityAutomationCodingComplete 
			&& !Chart.PhysicianAutomationCodingComplete 
			&& !ddlExcludeReason.SelectedItem.Text.Contains(AutomationErrorDescription))
				ddlExcludeReason.Items.Remove(ddlExcludeReason.Items.FindByText(AutomationErrorDescription));

			chkExcludeFromReport.Enabled = 
			ddlExcludeReason.Enabled = auditAction.ChartAuditActionTypeCode.In(
				ChartAuditActionTypeCode.Revised, 
				ChartAuditActionTypeCode.Added, 
				ChartAuditActionTypeCode.Deleted, 
				ChartAuditActionTypeCode.AbstractChange)
			&& IsUserAuthorizedToExcludeFromQa;

			switch (auditAction.ChartAuditActionTypeCode)
			{
				case ChartAuditActionTypeCode.Revised:
					e.Item.BackColor = RevisionBackColor;
					if (auditAction.ExcludeFromQa)
						CorrectCount += 1;
					else
						RevisionCount += 1;
					break;
				case ChartAuditActionTypeCode.Added:
					e.Item.BackColor = AdditionBackColor;
					if (auditAction.ExcludeFromQa)
						CorrectCount += 1;
					else
						AdditionCount += 1;
					break;
				case ChartAuditActionTypeCode.Deleted:
					e.Item.BackColor = DeletionBackColor;
					if (auditAction.ExcludeFromQa)
						CorrectCount += 1;
					else
						DeletionCount += 1;
					break;
				case ChartAuditActionTypeCode.AbstractChange:
					e.Item.BackColor = AbstractBackColor;
					CorrectCount += 1;
					break;
				case ChartAuditActionTypeCode.NoChange:
				default:
					CorrectCount += 1;
					break;
			}
		}

		public void Save()
		{
			if (!IsDataValid()) throw new Exception();

			foreach (DataGridItem item in grdCPTSummaryCoder.Items)
			{
				if (item.ItemType != ListItemType.Item && item.ItemType != ListItemType.AlternatingItem)
					continue;

				if (!(item.FindControl("ddlExcludeReason") is DropDownList ddlExcludeReason) || !int.TryParse(ddlExcludeReason.SelectedValue, out var selectedExcludeReasonId))
					continue;

				if (!int.TryParse(item.Cells[(int)GridIndexes.Id].Text, out var auditActionId))
					continue;

				if (!(item.FindControl("ltlChartSectionId") is Literal ltlChartSectionId) || !int.TryParse(ltlChartSectionId.Text, out var chartSectionId))
					continue;

				var chkExcludeFromReport = item.FindControl("chkExcludeFromReport") as CheckBox;

				switch ((ChartAuditSectionTypeCode)chartSectionId)
				{
					case ChartAuditSectionTypeCode.PhysicianProcedure:
					case ChartAuditSectionTypeCode.FacilityProcedure:
					case ChartAuditSectionTypeCode.ObservationProcedure:
					case ChartAuditSectionTypeCode.InfusionInjectionProcedure:
						var chartAuditProcedureVersionItem = CharAuditProcedureVersionItemService.GetChartAuditProcedureVersionItemById(auditActionId);
						if (chkExcludeFromReport != null
						&& chkExcludeFromReport.Checked == chartAuditProcedureVersionItem.ExcludeFromQA
						&& selectedExcludeReasonId == chartAuditProcedureVersionItem.ExcludeFromQAReasonID)
							break;

						chartAuditProcedureVersionItem.ExcludeFromQA = chkExcludeFromReport != null && chkExcludeFromReport.Checked;
						chartAuditProcedureVersionItem.ExcludeFromQAReasonID = chartAuditProcedureVersionItem.ExcludeFromQA ? selectedExcludeReasonId : -1;

						CharAuditProcedureVersionItemService.Save(RequestManager.SessionManager.SignedOnUserProfile.UserProfileID, chartAuditProcedureVersionItem);
						break;
					case ChartAuditSectionTypeCode.Anesthesia:
						var chartAuditAnesthesiaVersionItem = ChartAuditAnesthesiaVersionItemService.GetChartAuditAnesthesiaVersionItemById(auditActionId);
						if (chkExcludeFromReport != null
						&& chkExcludeFromReport.Checked == chartAuditAnesthesiaVersionItem.ExcludeFromQA
						&& selectedExcludeReasonId == chartAuditAnesthesiaVersionItem.ExcludeFromQAReasonID)
							break;

						chartAuditAnesthesiaVersionItem.ExcludeFromQA = chkExcludeFromReport != null && chkExcludeFromReport.Checked;
						chartAuditAnesthesiaVersionItem.ExcludeFromQAReasonID = chartAuditAnesthesiaVersionItem.ExcludeFromQA ? selectedExcludeReasonId : -1;

						ChartAuditAnesthesiaVersionItemService.Save(RequestManager.SessionManager.SignedOnUserProfile.UserProfileID, chartAuditAnesthesiaVersionItem);
						break;
					case ChartAuditSectionTypeCode.FacilityService:
						var chartAuditFacilityLosVersionItem = ChartAuditFacilityLosVersionItemService.GetChartAuditFacilityLosVersionItemById(auditActionId);
						if (chkExcludeFromReport != null
						&& chkExcludeFromReport.Checked == chartAuditFacilityLosVersionItem.ExcludeFromQA
						&& selectedExcludeReasonId == chartAuditFacilityLosVersionItem.ExcludeFromQAReasonID)
							break;

						chartAuditFacilityLosVersionItem.ExcludeFromQA = chkExcludeFromReport != null && chkExcludeFromReport.Checked;
						chartAuditFacilityLosVersionItem.ExcludeFromQAReasonID = chartAuditFacilityLosVersionItem.ExcludeFromQA.Value ? selectedExcludeReasonId : -1;

						ChartAuditFacilityLosVersionItemService.Save(RequestManager.SessionManager.SignedOnUserProfile.UserProfileID, chartAuditFacilityLosVersionItem);
						break;
					case ChartAuditSectionTypeCode.PhysicianService:
						var chartAuditPhysicianLosVersionItem = ChartAuditPhysicianLosVersionItemService.GetChartAuditPhysicianLosVersionItemById(auditActionId);
						if (chkExcludeFromReport != null
						&& chkExcludeFromReport.Checked == chartAuditPhysicianLosVersionItem.ExcludeFromQA
						&& selectedExcludeReasonId == chartAuditPhysicianLosVersionItem.ExcludeFromQAReasonID)
							break;

						chartAuditPhysicianLosVersionItem.ExcludeFromQA = chkExcludeFromReport != null && chkExcludeFromReport.Checked;
						chartAuditPhysicianLosVersionItem.ExcludeFromQAReasonID = chartAuditPhysicianLosVersionItem.ExcludeFromQA.Value ? selectedExcludeReasonId : -1;

						ChartAuditPhysicianLosVersionItemService.Save(RequestManager.SessionManager.SignedOnUserProfile.UserProfileID, chartAuditPhysicianLosVersionItem);
						break;
					case ChartAuditSectionTypeCode.Demographics:
					case ChartAuditSectionTypeCode.Documentation:
					case ChartAuditSectionTypeCode.Diagnosis:
					case ChartAuditSectionTypeCode.General:
					default: break;
				}
			}
		}

		public bool IsDataValid()
		{
			foreach (DataGridItem item in grdCPTSummaryCoder.Items)
			{
				if (item.ItemType != ListItemType.Item && item.ItemType != ListItemType.AlternatingItem)
					continue;

				if (!(item.FindControl("ddlExcludeReason") is DropDownList ddlExcludeReason) || !int.TryParse(ddlExcludeReason.SelectedValue, out var selectedExcludeReasonId))
					continue;

				if (item.FindControl("chkExcludeFromReport") is CheckBox chkExcludeFromReport
					&& chkExcludeFromReport.Checked
					&& selectedExcludeReasonId == -1)
				{
					RequestManager.ErrorMessages.Add(
						new ErrorMessage(
							ErrorMessageTypeCode.MissingRequiredField,
							ErrorMessageSeverityTypeCode.Severe,
							string.Format(ErrorMessageTypeCode.MissingRequiredField.GetDisplayName(), "Exclude from QA Report", "checked", "Exclude Reason")
						)
					);
					ddlExcludeReason.ForeColor = Color.Red;
					return false;
				}
				ddlExcludeReason.ForeColor = Color.Black;
			}

			return true;
		}

		private void PopulateOverallAccuracyGrid()
		{
			lblCorrect.Text = CorrectCount.ToString();
			lblRevisons.Text = RevisionCount.ToString();
			lblAdditions.Text = AdditionCount.ToString();
			lblDeletions.Text = DeletionCount.ToString();

			decimal codeChangeCount = AdditionCount + DeletionCount + RevisionCount;
			decimal totalCodeCount = CorrectCount + AdditionCount + RevisionCount;
			decimal coderScore = 0;

			if (totalCodeCount > 0)
			{
				coderScore = 100 - Math.Round(((codeChangeCount / totalCodeCount) * 100), 0);
				if (coderScore < 0)
					coderScore = 0;
			}

			lblScore.Text = $"{coderScore.ToString(CultureInfo.CurrentCulture)}%";
		}

		public IEnumerable<ProcedureSummary> GetCptCodeSummaries()
		{
			var cptCodeSummaries = new List<ProcedureSummary>();
			var chartAuditVersionId = ChartAuditVersion == null ? -1 : ChartAuditVersion.Id;
			if(chartAuditVersionId <= 0 && RequestManager != null)
				RequestManager.ErrorMessages?.Add(new ErrorMessage(0, ErrorMessageSeverityTypeCode.Warning, "ChartAuditVersion Id is invalid."));

			var facilityProcedureItems = CharAuditProcedureVersionItemService
				.GetChartAuditProcedureVersionItemListByChartAuditVersionIdAndProcedureType(chartAuditVersionId, ChartAuditSectionTypeCode.FacilityProcedure.GetShortName());
			var physicianProcedureItems = CharAuditProcedureVersionItemService
				.GetChartAuditProcedureVersionItemListByChartAuditVersionIdAndProcedureType(chartAuditVersionId, ChartAuditSectionTypeCode.PhysicianProcedure.GetShortName());
			var anesthesiaItems = ChartAuditAnesthesiaVersionItemService
				.GetChartAuditAnesthesiaVersionItemListByChartAuditVersionId(chartAuditVersionId);
			var observationItems = CharAuditProcedureVersionItemService
				.GetChartAuditProcedureVersionItemListByChartAuditVersionIdAndProcedureType(chartAuditVersionId, ChartAuditSectionTypeCode.ObservationProcedure.GetShortName());
			var infusionInjectionItems = CharAuditProcedureVersionItemService
				.GetChartAuditProcedureVersionItemListByChartAuditVersionIdAndProcedureType(chartAuditVersionId, ChartAuditSectionTypeCode.InfusionInjectionProcedure.GetShortName());
			var facilityServicesItems = ChartAuditFacilityLosVersionItemService.GetChartAuditFacilityLosVersionItemListByChartAuditVersionId(chartAuditVersionId);
			var physicianServicesItems = ChartAuditPhysicianLosVersionItemService.GetChartAuditPhysicianLosVersionItemListByChartAuditVersionId(chartAuditVersionId);

			// convert to ProcedureSummary and add sub lists to the entire list.
			cptCodeSummaries.AddRange(GetProcedureCodeSummaries(facilityProcedureItems,ChartAuditSectionTypeCode.FacilityProcedure));
			cptCodeSummaries.AddRange(GetProcedureCodeSummaries(physicianProcedureItems, ChartAuditSectionTypeCode.PhysicianProcedure));
			cptCodeSummaries.AddRange(GetAnesthesiaCodeSummaries(anesthesiaItems));
			cptCodeSummaries.AddRange(GetProcedureCodeSummaries(observationItems, ChartAuditSectionTypeCode.ObservationProcedure));
			cptCodeSummaries.AddRange(GetProcedureCodeSummaries(infusionInjectionItems, ChartAuditSectionTypeCode.InfusionInjectionProcedure));
			cptCodeSummaries.AddRange(GetFacilityServicesCodeSummaries(facilityServicesItems));
			cptCodeSummaries.AddRange(GetPhysicianServicesCodeSummaries(physicianServicesItems));

			return cptCodeSummaries;
		}

		private IEnumerable<ProcedureSummary> GetProcedureCodeSummaries(
			List<ChartAuditProcedureVersionItem> auditProcedureVersionItems,
			ChartAuditSectionTypeCode chartAuditSectionTypeCode)
		{
			var cptCodeSummaries = new List<ProcedureSummary>();

			foreach (var chartAuditProcedureVersionItem in auditProcedureVersionItems)
			{
				var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == chartAuditProcedureVersionItem.ChartAuditVersionId)?.VersionNumber;
				var previousVersionItem = new ChartAuditProcedureVersionItem();
				var currentVersionItem = new ChartAuditProcedureVersionItem();

				switch (chartAuditVersionNumber)
				{
					case 1:
						previousVersionItem = chartAuditProcedureVersionItem;
						currentVersionItem = null;
						break;
					case 2:
						previousVersionItem = chartAuditProcedureVersionItem.PrevChartAuditProcedureVersionItemId.HasValue
							? CharAuditProcedureVersionItemService.GetChartAuditProcedureVersionItemById(chartAuditProcedureVersionItem.PrevChartAuditProcedureVersionItemId.Value)
							: null;
						currentVersionItem = chartAuditProcedureVersionItem;
						break;
				}

				var usageCode = -1;
				var infusionCategory = false;

				switch (chartAuditSectionTypeCode)
				{
					case ChartAuditSectionTypeCode.Anesthesia: 
						usageCode = ChargeMasterUsageCode.USAGE_CODE_ANESTHESIA; 
						break;
					case ChartAuditSectionTypeCode.FacilityProcedure:
						usageCode = ChargeMasterUsageCode.USAGE_CODE_FACILITY_PROCEDURE;
						break;
					case ChartAuditSectionTypeCode.PhysicianProcedure:
						usageCode = ChargeMasterUsageCode.USAGE_CODE_PHYSICIAN_PROCEDURE;
						break;
					case ChartAuditSectionTypeCode.ObservationProcedure:
						usageCode = ChargeMasterUsageCode.USAGE_CODE_OBSERVATION;
						break;
					case ChartAuditSectionTypeCode.InfusionInjectionProcedure:
						usageCode = ChargeMasterUsageCode.USAGE_CODE_FACILITY_PROCEDURE;
						infusionCategory = true;
						break;
					case ChartAuditSectionTypeCode.FacilityService:
					case ChartAuditSectionTypeCode.PhysicianService:
					case ChartAuditSectionTypeCode.Demographics:
					case ChartAuditSectionTypeCode.Documentation:
					case ChartAuditSectionTypeCode.Diagnosis:
					case ChartAuditSectionTypeCode.General:
					default: break;
				}

				cptCodeSummaries.Add(new ProcedureSummary()
					{
						Id = chartAuditProcedureVersionItem.Id,
						ChartAuditSectionTypeCode = chartAuditSectionTypeCode,
						PreviousCode = previousVersionItem != null ? previousVersionItem.CptCode : string.Empty,
						PreviousCodeDescription = previousVersionItem != null ? GetCptCodeDescription(previousVersionItem.CptCode, usageCode, infusionCategory) : string.Empty,
						AuditorCode = currentVersionItem != null ? currentVersionItem.CptCode : string.Empty,
						AuditorCodeDescription = currentVersionItem != null ? GetCptCodeDescription(currentVersionItem.CptCode, usageCode, infusionCategory) : string.Empty,
						ChartAuditActionTypeCode = chartAuditProcedureVersionItem.ChartAuditActionTypeCode,
						CorrectCode = chartAuditProcedureVersionItem.IsPreviousVersionCorrect,
						ExcludeFromQa = chartAuditProcedureVersionItem.ExcludeFromQA,
						ExcludeReasonId = chartAuditProcedureVersionItem.ExcludeFromQAReasonID ?? -1,
						ExcludeReasons = ExcludeReasons.Where(x => x.ChartSection.Equals(chartAuditSectionTypeCode.GetShortName())).ToList(),
					}
				);
			}

			return cptCodeSummaries;
		}

		private IEnumerable<ProcedureSummary> GetFacilityServicesCodeSummaries(List<ChartAuditFacilityLosVersionItem> facilityLosVersionItems)
		{
			var cptCodeSummaries = new List<ProcedureSummary>();

			foreach (var facilityLosVersionItem in facilityLosVersionItems)
			{
				var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == facilityLosVersionItem.ChartAuditVersionId)?.VersionNumber;
				var previousVersionItem = new ChartAuditFacilityLosVersionItem();
				var currentVersionItem = new ChartAuditFacilityLosVersionItem();

				switch (chartAuditVersionNumber)
				{
					case 1:
						previousVersionItem = facilityLosVersionItem;
						currentVersionItem = null;
						break;
					case 2:
						previousVersionItem = facilityLosVersionItem.PrevChartAuditFacilityLosVersionItemId.HasValue
							? ChartAuditFacilityLosVersionItemService.GetChartAuditFacilityLosVersionItemById(facilityLosVersionItem.PrevChartAuditFacilityLosVersionItemId.Value)
							: null;
						currentVersionItem = facilityLosVersionItem;
						break;
				}

				cptCodeSummaries.Add(new ProcedureSummary()
					{
						Id = facilityLosVersionItem.Id,
						ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.FacilityService,
						PreviousCode = previousVersionItem != null ? previousVersionItem.CptCode : string.Empty,
						PreviousCodeDescription = previousVersionItem != null ? GetCptCodeDescription(previousVersionItem.CptCode, ChargeMasterUsageCode.USAGE_CODE_FACILITY_SERVICE) : string.Empty,
						AuditorCode = currentVersionItem != null ? currentVersionItem.CptCode : string.Empty,
						AuditorCodeDescription = currentVersionItem != null ? GetCptCodeDescription(currentVersionItem.CptCode, ChargeMasterUsageCode.USAGE_CODE_FACILITY_SERVICE) : string.Empty,
						ChartAuditActionTypeCode = facilityLosVersionItem.ChartAuditActionTypeCode,
						CorrectCode = facilityLosVersionItem.IsPreviousVersionCorrect == true,
						ExcludeFromQa = facilityLosVersionItem.ExcludeFromQA == true,
						ExcludeReasonId = facilityLosVersionItem.ExcludeFromQAReasonID ?? -1,
						ExcludeReasons = ExcludeReasons.Where(x => x.ChartSection.Equals(ChartAuditSectionTypeCode.FacilityService.GetShortName())).ToList(),
					}
				);
			}

			return cptCodeSummaries;
		}

		private IEnumerable<ProcedureSummary> GetAnesthesiaCodeSummaries(List<ChartAuditAnesthesiaVersionItem> anesthesiaVersionItems)
		{
			var cptCodeSummaries = new List<ProcedureSummary>();

			foreach (var anesthesiaVersionItem in anesthesiaVersionItems)
			{
				var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == anesthesiaVersionItem.ChartAuditVersionId)?.VersionNumber;
				var previousVersionItem = new ChartAuditAnesthesiaVersionItem();
				var currentVersionItem = new ChartAuditAnesthesiaVersionItem();

				switch (chartAuditVersionNumber)
				{
					case 1:
						previousVersionItem = anesthesiaVersionItem;
						currentVersionItem = null;
						break;
					case 2:
						previousVersionItem = anesthesiaVersionItem.PrevChartAuditAnesthesiaVersionItemId.HasValue
							? ChartAuditAnesthesiaVersionItemService.GetChartAuditAnesthesiaVersionItemById(anesthesiaVersionItem.PrevChartAuditAnesthesiaVersionItemId.Value)
							: null;
						currentVersionItem = anesthesiaVersionItem;
						break;
				}

				cptCodeSummaries.Add(new ProcedureSummary()
				{
					Id = anesthesiaVersionItem.Id,
					ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.Anesthesia,
					PreviousCode = previousVersionItem != null ? previousVersionItem.AnesthesiaCode : string.Empty,
					PreviousCodeDescription = previousVersionItem != null ? GetCptCodeDescription(previousVersionItem.AnesthesiaCode, ChargeMasterUsageCode.USAGE_CODE_ANESTHESIA) : string.Empty,
					AuditorCode = currentVersionItem != null ? currentVersionItem.AnesthesiaCode : string.Empty,
					AuditorCodeDescription = currentVersionItem != null ? GetCptCodeDescription(currentVersionItem.AnesthesiaCode, ChargeMasterUsageCode.USAGE_CODE_ANESTHESIA) : string.Empty,
					ChartAuditActionTypeCode = anesthesiaVersionItem.ChartAuditActionTypeCode,
					CorrectCode = anesthesiaVersionItem.IsPreviousVersionCorrect == true,
					ExcludeFromQa = anesthesiaVersionItem.ExcludeFromQA == true,
					ExcludeReasonId = anesthesiaVersionItem.ExcludeFromQAReasonID ?? -1,
					ExcludeReasons = ExcludeReasons.Where(x => x.ChartSection.Equals(ChartAuditSectionTypeCode.Anesthesia.GetShortName())).ToList(),
				}
				);
			}

			return cptCodeSummaries;
		}

		private IEnumerable<ProcedureSummary> GetPhysicianServicesCodeSummaries(List<ChartAuditPhysicianLosVersionItem> physicianLosVersionItems)
		{
			var cptCodeSummaries = new List<ProcedureSummary>();

			foreach (var physicianLosVersionItem in physicianLosVersionItems)
			{
				var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == physicianLosVersionItem.ChartAuditVersionId)?.VersionNumber;
				var previousVersionItem = new ChartAuditPhysicianLosVersionItem();
				var currentVersionItem = new ChartAuditPhysicianLosVersionItem();

				switch (chartAuditVersionNumber)
				{
					case 1:
						previousVersionItem = physicianLosVersionItem;
						currentVersionItem = null;
						break;
					case 2:
						previousVersionItem = physicianLosVersionItem.PrevChartAuditPhysicianLosVersionItemId.HasValue
							? ChartAuditPhysicianLosVersionItemService.GetChartAuditPhysicianLosVersionItemById(physicianLosVersionItem.PrevChartAuditPhysicianLosVersionItemId.Value)
							: null;
						currentVersionItem = physicianLosVersionItem;
						break;
				}

				cptCodeSummaries.Add(new ProcedureSummary()
					{
						Id = physicianLosVersionItem.Id,
						ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.PhysicianService,
						PreviousCode = previousVersionItem != null ? previousVersionItem.CptCode : string.Empty,
						PreviousCodeDescription = previousVersionItem != null ? GetCptCodeDescription(previousVersionItem.CptCode, ChargeMasterUsageCode.USAGE_CODE_PHYSICIAN_SERVICE) : string.Empty,
						AuditorCode = currentVersionItem != null ? currentVersionItem.CptCode : string.Empty,
						AuditorCodeDescription = currentVersionItem != null ? GetCptCodeDescription(currentVersionItem.CptCode, ChargeMasterUsageCode.USAGE_CODE_PHYSICIAN_SERVICE) : string.Empty,
						ChartAuditActionTypeCode = physicianLosVersionItem.ChartAuditActionTypeCode,
						CorrectCode = physicianLosVersionItem.IsPreviousVersionCorrect == true,
						ExcludeFromQa = physicianLosVersionItem.ExcludeFromQA == true,
						ExcludeReasonId = physicianLosVersionItem.ExcludeFromQAReasonID ?? -1,
						ExcludeReasons = ExcludeReasons.Where(x => x.ChartSection.Equals(ChartAuditSectionTypeCode.PhysicianService.GetShortName())).ToList(),
					}
				);
			}

			return cptCodeSummaries;
		}

		private string GetCptCodeDescription(string cptCode, int usageCode, bool infusionCategory = false)
		{
			var cptCodeDescription = string.Empty;

			using (var sql = new SqlService(ConnectionString.ACS) { AutoCloseConnection = true })
			{
				if (sql.Connection == null) sql.Connect();

				sql.AddParameter("@CptCode", SqlDbType.VarChar, cptCode);
				sql.AddParameter("@InfusionCategory", SqlDbType.Bit, infusionCategory);
				sql.AddParameter("@UsageCode", SqlDbType.Int, usageCode);
				sql.AddParameter("@ServiceAgreementId", SqlDbType.Int, Chart.ServiceAgreement.ServiceAgreementID);
				sql.AddParameter("@DateOfService", SqlDbType.Date, Chart.TimeOfService);

				using (var reader = sql.ExecuteStoredProcedureReader(
						   "dbo.SelectChargeMasterDescriptionByCptCodeAndInfusionCategoryAndUsageCodeAndServiceAgreementIdAndDateOfService"))
				{
					if (reader.Read())
						cptCodeDescription = reader.GetString(0);
					reader.Close();
				}
			}

			return cptCodeDescription;
		}

		public class ProcedureSummary
		{
			public int Id { get; set; }
			public ChartAuditSectionTypeCode ChartAuditSectionTypeCode { get; set; }
			public string PreviousCode { get; set; }
			public string PreviousCodeDescription { get; set; }
			public string AuditorCode { get; set; }
			public string AuditorCodeDescription { get; set; }
			public ChartAuditActionTypeCode ChartAuditActionTypeCode { get; set; }
			public bool CorrectCode { get; set; }
			public bool ExcludeFromQa { get; set; }
			public int ExcludeReasonId { get; set; } = -1;
			public IEnumerable<ExcludeFromQAReportReason> ExcludeReasons { get; set; }
		}
	}
}