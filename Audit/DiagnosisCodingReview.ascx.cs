using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.Common;
using CCSBusinessObjects.DAO;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web.UI.WebControls;
using CCSBusinessObjects.BusinessObjects.Service;
using System;
using System.Drawing;
using ACS.Core.Extensions;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.Utility;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class DiagnosisCodingReview : BaseAuditControl
	{
		#region Internals
		private FacilityProfessionalDAO _facilityProfessionalDao;
		private PhysicianServiceEvaluationListDAO _physicianServiceEvaluationListDao;
		private ChartDiagnosisCodeICD10DAO _chartDiagnosisCodeIcd10Dao;

		private enum GridIndexes
		{
			Id = 0,
			DateProviderEm = 1,
			PreviousDiagnosisType = 2,
			PreviousCode = 3,
			AuditorDiagnosisType = 4,
			AuditorCode = 5,
			AuditAction = 6,
			Correct = 7,
			ExcludeFromQaHidden = 8,
			ExcludeFromQa = 9,
			ExcludeReason = 10,
		}

		private enum AuditResultsGridIndexes
		{
			Accuracy = 0,
			AccuracyCount = 1,
			AdditionalResults = 2,
			PassFail = 3,
		}
		#endregion

		#region Properties
		public IChartAuditDiagnosisVersionItemService ChartAuditDiagnosisVersionItemService { get; set; }
		public List<ChartPhysicianLevelOfService> LevelOfServiceList { get; set; }
		public FacilityProfessionalDAO FacilityProfessionalDao => _facilityProfessionalDao ?? (_facilityProfessionalDao = new FacilityProfessionalDAO(RequestManager));
		public PhysicianServiceEvaluationListDAO PhysicianServiceEvaluationListDao => _physicianServiceEvaluationListDao ?? (_physicianServiceEvaluationListDao = new PhysicianServiceEvaluationListDAO(RequestManager));
		public ChartDiagnosisCodeICD10DAO ChartDiagnosisCodeIcd10Dao => _chartDiagnosisCodeIcd10Dao ?? (_chartDiagnosisCodeIcd10Dao = new ChartDiagnosisCodeICD10DAO(RequestManager));
		public IEnumerable<ChartAuditDiagnosisVersionItem> ChartAuditDiagnosisVersionItems { get; set; }
		#endregion

		public void LoadModel(
			WebRequestManager requestManager,
			Chart chart, 
			IEnumerable<ExcludeFromQAReportReason> excludeReasons, 
			List<ChartPhysicianLevelOfService> levelOfServiceList,
			ChartPostBillAudit chartPostBillAudit)
		{
			RequestManager = requestManager;
			Chart = chart;
			ExcludeReasons = excludeReasons;
			LevelOfServiceList = levelOfServiceList;
			ChartPostBillAudit = chartPostBillAudit;
			ChartAuditVersions = ChartAuditVersionService.GetChartAuditVersionListByChartAuditId(ChartPostBillAudit.Id);
			ChartAuditVersion = ChartAuditVersions.OrderByDescending(x => x.VersionNumber).FirstOrDefault();
			ChartAuditDiagnosisVersionItems = ChartAuditVersion == null 
				? new List<ChartAuditDiagnosisVersionItem>() 
				: ChartAuditDiagnosisVersionItemService.GetChartAuditDiagnosisVersionItemListByChartAuditVersionId(ChartAuditVersion.Id);
			ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.Diagnosis;
		}

		public void ModelToView()
		{
			grdDiagnosisCodingICD10.DataSource = ChartAuditDiagnosisVersionItems;
			grdDiagnosisCodingICD10.DataBind();

			grdDiagnosisAuditResults.DataSource = GetDiagnosisCodingAuditSummaryDataTable();
			grdDiagnosisAuditResults.DataBind();

			txtComment.Text = ChartAuditVersionComment.Comment;
		}

		protected void grdDiagnosisCodingICD10_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) 
			|| !(e.Item.DataItem is ChartAuditDiagnosisVersionItem auditAction)) 
				return;

			var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == auditAction.ChartAuditVersionId)?.VersionNumber;
			var previousDiagnosisVersionItem = new ChartAuditDiagnosisVersionItem();
			var currentDiagnosisVersionItem = new ChartAuditDiagnosisVersionItem();

			switch (chartAuditVersionNumber)
			{
				case 1:
					previousDiagnosisVersionItem = auditAction;
					currentDiagnosisVersionItem = null;
					break;
				case 2:
					previousDiagnosisVersionItem = auditAction.PrevChartAuditDiagnosisVersionItemId.HasValue
						? ChartAuditDiagnosisVersionItemService.GetChartAuditDiagnosisVersionItemById(auditAction.PrevChartAuditDiagnosisVersionItemId.Value)
						: null;
					currentDiagnosisVersionItem = auditAction;
					break;
			}

			// If Service Agreement allows multiple LOS, display the column and build the description
			if (e.Item.FindControl("lblLevelOfService") is Label lblLevelOfService)
			{
				if (Chart.ServiceAgreement.AllowMultiplePhysicianLevels)
				{
					lblLevelOfService.Visible = true;
					foreach (var los in LevelOfServiceList)
					{
						if (los.LevelNumber != auditAction.LevelNumber) continue;
						var provider = FacilityProfessionalDao.Load(los.ProviderID);
						var providerLastName = provider.Name.LastName.ToUpper();
						var cptCode = PhysicianServiceEvaluationListDao.GetCPTCode(Chart.ServiceAgreementID, los.PhysicianServiceProcID);
						lblLevelOfService.Text = $"{los.DateOfService.Month}/{los.DateOfService.Day}({providerLastName}, {cptCode})";
						lblLevelOfService.ToolTip = $"{los.DateOfService.ToShortDateString()} {provider.Name.LastCommaFirstSpaceMiddle}";
					}
				}
				else
					lblLevelOfService.Visible = false;
			}

			if (e.Item.FindControl("lblPreviousDiagnosisType") is Label lblPreviousDiagnosisType && previousDiagnosisVersionItem?.DiagnosisTypeId != null)
				lblPreviousDiagnosisType.Text = GetDiagnosisTypeDescription(previousDiagnosisVersionItem);
			if (e.Item.FindControl("lblPreviousIcdCode") is Label lblPreviousIcdCode && previousDiagnosisVersionItem?.ICDCode != null)
				lblPreviousIcdCode.Text = previousDiagnosisVersionItem.ICDCode;
			if (e.Item.FindControl("lblAuditorDiagnosisType") is Label lblAuditorDiagnosisType && currentDiagnosisVersionItem?.DiagnosisTypeId != null)
				lblAuditorDiagnosisType.Text = GetDiagnosisTypeDescription(currentDiagnosisVersionItem);
			if (e.Item.FindControl("lblAuditorIcdCode") is Label lblAuditorIcdCode && currentDiagnosisVersionItem?.ICDCode != null)
				lblAuditorIcdCode.Text = currentDiagnosisVersionItem.ICDCode;
			if (e.Item.FindControl("lblAuditActionDescription") is Label lblAuditActionDescription && currentDiagnosisVersionItem?.ChartAuditActionTypeCode != null)
				lblAuditActionDescription.Text = currentDiagnosisVersionItem.ChartAuditActionTypeCode.GetDisplayDescription();
			if (e.Item.FindControl("chkCorrectCode") is CheckBox chkCorrectCode && currentDiagnosisVersionItem?.IsPreviousVersionCorrect != null) 
				chkCorrectCode.Checked = currentDiagnosisVersionItem.IsPreviousVersionCorrect == true;
			if (e.Item.FindControl("chkExcludeFromReport") is CheckBox chkExcludeFromReport && e.Item.FindControl("ddlExcludeReason") is DropDownList ddlExcludeReason)
			{
				ddlExcludeReason.Enabled =
				chkExcludeFromReport.Enabled = currentDiagnosisVersionItem.IsPreviousVersionCorrect == false;
				chkExcludeFromReport.Checked = currentDiagnosisVersionItem.ExcludeFromQA == true;

				FillDropDownList(
					ddlExcludeReason,
					ExcludeReasons.Where(x => x.ChartSection.Equals(ChartAuditSectionTypeCode.GetShortName())).ToList(),
					"ExcludeFromQAReportReasonDescription",
					"ExcludeFromQAReportReasonID",
					auditAction.ExcludeFromQAReasonID.ToString(),
					"None",
					"-1");

				// If the chart is not automated and automation error is not already selected, then remove the automation reason from the drop down list.
				if (!Chart.FacilityAutomationCodingComplete && !ddlExcludeReason.SelectedItem.Text.Contains(AutomationErrorDescription))
					ddlExcludeReason.Items.Remove(ddlExcludeReason.Items.FindByText(AutomationErrorDescription));

				if (e.Item.FindControl("hdnExcludeReasonID") is HiddenField hdnExcludeReasonId) 
					hdnExcludeReasonId.Value = ddlExcludeReason.SelectedValue;
			}
			
			var fromCell = e.Item.Cells[(int)GridIndexes.PreviousCode];
			if (previousDiagnosisVersionItem?.ICDCode != null) 
				fromCell.ToolTip = GetIcdCodeDescription(previousDiagnosisVersionItem.ICDCode);

			var toCell = e.Item.Cells[(int)GridIndexes.AuditorCode];
			if (currentDiagnosisVersionItem?.ICDCode != null) 
				toCell.ToolTip = GetIcdCodeDescription(currentDiagnosisVersionItem.ICDCode);

			if (string.IsNullOrWhiteSpace(hdnAuditChange.Value) || hdnAuditChange.Value.Equals(bool.FalseString))
				hdnAuditChange.Value = auditAction.ChartAuditActionTypeCode.In(
					ChartAuditActionTypeCode.Added,
					ChartAuditActionTypeCode.Deleted, 
					ChartAuditActionTypeCode.Revised
				).ToString();

			switch (auditAction.ChartAuditActionTypeCode)
			{
				case ChartAuditActionTypeCode.Added: e.Item.BackColor = AdditionBackColor; break;
				case ChartAuditActionTypeCode.Deleted: e.Item.BackColor = DeletionBackColor; break;
				case ChartAuditActionTypeCode.Revised: e.Item.BackColor = RevisionBackColor; break;
				case ChartAuditActionTypeCode.AbstractChange:
				case ChartAuditActionTypeCode.NoChange:
				default: break;
			}
		}

		private static string GetDiagnosisTypeDescription(ChartAuditDiagnosisVersionItemBase chartAuditDiagnosisVersionItem)
		{
			switch (chartAuditDiagnosisVersionItem.DiagnosisTypeId)
			{
				case ChartDiagnosisCodeICD10.COMPLAINT:
					return chartAuditDiagnosisVersionItem.IsPrimary == true ? "Chief Complaint" : "Secondary Complaint";
				case ChartDiagnosisCodeICD10.DIAGNOSIS:
					return chartAuditDiagnosisVersionItem.IsPrimary == true ? "Primary Dx" : "Secondary Dx";
				case ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS:
					return chartAuditDiagnosisVersionItem.IsPrimary == true ? "Chief Complaint and Primary Dx" : "Addtl Complaint and Secondary Dx ";
				case ChartDiagnosisCodeICD10.COMPLAINT_AND_SECONDARY_DIAGNOSIS:
					return "Chief Complaint and Secondary Diagnosis ";
				default:
					return string.Empty;
			}
		}

		private string GetIcdCodeDescription(string icdCode) => 
			ChartDiagnosisCodeIcd10Dao.GetIcdCodeDescriptionByIcdCodeAndDateOfService(icdCode, Chart.TimeOfService);

		private DataTable GetDiagnosisCodingAuditSummaryDataTable()
		{
			var chiefComplaintErrors = 0;
			var primaryDiagnosisErrors = 0;
			var totalRevisions = 0;
			var totalAdditions = 0;
			var totalDeletions = 0;
			var totalCorrect = 0;

			foreach (var item in ChartAuditDiagnosisVersionItems)
			{
				var isChiefComplaintChange = false;
				var isPrimaryDiagnosisChange = false;

				switch (item.ChartAuditActionTypeCode)
				{
					case ChartAuditActionTypeCode.Revised:
						if (item.ExcludeFromQA == true)
							totalCorrect += 1;
						else
							totalRevisions += 1;

						var previousVersion = item.PrevChartAuditDiagnosisVersionItemId.HasValue ?
							ChartAuditDiagnosisVersionItemService.GetChartAuditDiagnosisVersionItemById(item.PrevChartAuditDiagnosisVersionItemId.Value) : null;

						if (previousVersion == null) break;

						var isPreviousItemChiefComplaint = previousVersion.IsPrimary == true
															&& previousVersion.DiagnosisTypeId.HasValue
															&& previousVersion.DiagnosisTypeId.Value.In(ChartDiagnosisCodeICD10.COMPLAINT, ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS, ChartDiagnosisCodeICD10.COMPLAINT_AND_SECONDARY_DIAGNOSIS);
						var isPreviousItemPrimaryDiagnosis = previousVersion.IsPrimary == true
						                                    && previousVersion.DiagnosisTypeId.HasValue
						                                    && previousVersion.DiagnosisTypeId.Value.In(ChartDiagnosisCodeICD10.DIAGNOSIS, ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS);
						var isCurrentItemChiefComplaint = item.IsPrimary == true
															&& item.DiagnosisTypeId.HasValue
															&& item.DiagnosisTypeId.Value.In(ChartDiagnosisCodeICD10.COMPLAINT, ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS, ChartDiagnosisCodeICD10.COMPLAINT_AND_SECONDARY_DIAGNOSIS);
						var isCurrentItemPrimaryDiagnosis = item.IsPrimary == true
															&& item.DiagnosisTypeId.HasValue
															&& item.DiagnosisTypeId.Value.In(ChartDiagnosisCodeICD10.DIAGNOSIS, ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS);

						isChiefComplaintChange = isPreviousItemChiefComplaint != isCurrentItemChiefComplaint 
												|| (isPreviousItemChiefComplaint && previousVersion.ICDCode != item.ICDCode);
						isPrimaryDiagnosisChange = isPreviousItemPrimaryDiagnosis != isCurrentItemPrimaryDiagnosis 
						                        || (isPreviousItemPrimaryDiagnosis && previousVersion.ICDCode != item.ICDCode);

						break;
					case ChartAuditActionTypeCode.Added:
						if (item.ExcludeFromQA == true)
							totalCorrect += 1;
						else
							totalAdditions += 1;

						isChiefComplaintChange = item.IsPrimary == true
						                        && item.DiagnosisTypeId.HasValue
						                        && item.DiagnosisTypeId.Value.In(ChartDiagnosisCodeICD10.COMPLAINT, ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS, ChartDiagnosisCodeICD10.COMPLAINT_AND_SECONDARY_DIAGNOSIS);
						isPrimaryDiagnosisChange = item.IsPrimary == true
						                        && item.DiagnosisTypeId.HasValue
						                        && item.DiagnosisTypeId.Value.In(ChartDiagnosisCodeICD10.DIAGNOSIS, ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS);
						break;
					case ChartAuditActionTypeCode.Deleted:
						if (item.ExcludeFromQA == true)
							totalCorrect += 1;
						else
							totalDeletions += 1;

						isChiefComplaintChange = item.IsPrimary == true
												&& item.DiagnosisTypeId.HasValue 
												&& item.DiagnosisTypeId.Value.In(ChartDiagnosisCodeICD10.COMPLAINT, ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS, ChartDiagnosisCodeICD10.COMPLAINT_AND_SECONDARY_DIAGNOSIS);
						isPrimaryDiagnosisChange = item.IsPrimary == true
												&& item.DiagnosisTypeId.HasValue
												&& item.DiagnosisTypeId.Value.In(ChartDiagnosisCodeICD10.DIAGNOSIS, ChartDiagnosisCodeICD10.COMPLAINT_AND_DIAGNOSIS);
						break;
					case ChartAuditActionTypeCode.AbstractChange:
					case ChartAuditActionTypeCode.NoChange:
					default: totalCorrect += 1; break;
				}

				if (isChiefComplaintChange) chiefComplaintErrors += 1;
				if (isPrimaryDiagnosisChange) primaryDiagnosisErrors += 1;
			}

			var lblChiefComplaintPassFail = chiefComplaintErrors > 0 ? "Fail" : "Pass";
			var lblPrimaryDxPassFail = primaryDiagnosisErrors > 0 ? "Fail" : "Pass";

			//Scorecard summary
			decimal codeChangeCount = totalRevisions + totalDeletions + totalAdditions;
			decimal totalCodeCount = totalCorrect + totalAdditions + totalRevisions;
			decimal coderScore = 0;

			if (totalCodeCount > 0)
			{
				coderScore = 100 - Math.Round(((codeChangeCount / totalCodeCount) * 100), 0);
				if (coderScore < 0)
					coderScore = 0;
			}

			var diagnosisCodingAuditDataTable = new DataTable();
			diagnosisCodingAuditDataTable.Columns.Add("Accuracy");
			diagnosisCodingAuditDataTable.Columns.Add("AccuracyCount");
			diagnosisCodingAuditDataTable.Columns.Add("AdditionalResults");
			diagnosisCodingAuditDataTable.Columns.Add("PassFail");

			var correctCodesDataRow = diagnosisCodingAuditDataTable.NewRow();
			correctCodesDataRow["Accuracy"] = "Correct Codes";
			correctCodesDataRow["AccuracyCount"] = totalCorrect.ToString();
			correctCodesDataRow["AdditionalResults"] = "Chief Complaint";
			correctCodesDataRow["PassFail"] = lblChiefComplaintPassFail;
			diagnosisCodingAuditDataTable.Rows.Add(correctCodesDataRow);

			var revisionsDataRow = diagnosisCodingAuditDataTable.NewRow();
			revisionsDataRow["Accuracy"] = "Revisions";
			revisionsDataRow["AccuracyCount"] = totalRevisions.ToString();
			revisionsDataRow["AdditionalResults"] = "Primary Dx";
			revisionsDataRow["PassFail"] = lblPrimaryDxPassFail;
			diagnosisCodingAuditDataTable.Rows.Add(revisionsDataRow);

			var additionsDataRow = diagnosisCodingAuditDataTable.NewRow();
			additionsDataRow["Accuracy"] = "Additions";
			additionsDataRow["AccuracyCount"] = totalAdditions.ToString();
			additionsDataRow["AdditionalResults"] = string.Empty;
			additionsDataRow["PassFail"] = string.Empty;
			diagnosisCodingAuditDataTable.Rows.Add(additionsDataRow);

			var deletionsDataRow = diagnosisCodingAuditDataTable.NewRow();
			deletionsDataRow["Accuracy"] = "Deletions";
			deletionsDataRow["AccuracyCount"] = totalDeletions.ToString();
			deletionsDataRow["AdditionalResults"] = string.Empty;
			deletionsDataRow["PassFail"] = string.Empty;
			diagnosisCodingAuditDataTable.Rows.Add(deletionsDataRow);

			var overallScoreDataRow = diagnosisCodingAuditDataTable.NewRow();
			overallScoreDataRow["Accuracy"] = "Overall Score";
			overallScoreDataRow["AccuracyCount"] = $"{coderScore}%";
			overallScoreDataRow["AdditionalResults"] = string.Empty;
			overallScoreDataRow["PassFail"] = string.Empty;
			diagnosisCodingAuditDataTable.Rows.Add(overallScoreDataRow);

			return diagnosisCodingAuditDataTable;
		}

		protected void grdDiagnosisAuditResults_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

			var passFail = e.Item.Cells[(int)AuditResultsGridIndexes.PassFail];
			passFail.BackColor = passFail.Text.ToUpper().Equals("FAIL") ? FailColor : PassColor;
		}

		public void Save()
		{
			if (!IsDataValid()) throw new Exception();

			foreach (DataGridItem item in grdDiagnosisCodingICD10.Items)
			{
				if (item.ItemType != ListItemType.Item && item.ItemType != ListItemType.AlternatingItem)
					continue;

				if (!(item.FindControl("ddlExcludeReason") is DropDownList ddlExcludeReason) || !int.TryParse(ddlExcludeReason.SelectedValue, out var selectedExcludeReasonId))
					continue;

				if (!int.TryParse(item.Cells[(int)GridIndexes.Id].Text, out var auditActionId))
					continue;

				if (!(ChartAuditDiagnosisVersionItemService.GetChartAuditDiagnosisVersionItemById(auditActionId) is ChartAuditDiagnosisVersionItem auditAction))
					continue;

				var chkExcludeFromReport = item.FindControl("chkExcludeFromReport") as CheckBox;
				if (chkExcludeFromReport != null 
				    && chkExcludeFromReport.Checked == auditAction.ExcludeFromQA
				    && selectedExcludeReasonId == auditAction.ExcludeFromQAReasonID) 
					continue;
				
				auditAction.ExcludeFromQA = chkExcludeFromReport != null && chkExcludeFromReport.Checked;
				auditAction.ExcludeFromQAReasonID = chkExcludeFromReport != null && chkExcludeFromReport.Checked
					? selectedExcludeReasonId
					: -1;

				ChartAuditDiagnosisVersionItemService.Save(RequestManager.SessionManager.SignedOnUserProfile.UserProfileID, auditAction);
			}

			if (!string.IsNullOrWhiteSpace(txtComment.Text)) 
				SaveComment(txtComment.Text);
		}

		private bool IsDataValid()
		{
			if (string.IsNullOrWhiteSpace(txtComment.Text) && hdnAuditChange.Value.Equals(bool.TrueString))
			{
				RequestManager.ErrorMessages.Add(
					new ErrorMessage(
						ErrorMessageTypeCode.AuditChangesRequireComment,
						ErrorMessageSeverityTypeCode.Severe,
						string.Format(ErrorMessageTypeCode.AuditChangesRequireComment.GetDisplayName(), ChartAuditSectionTypeCode.GetDisplayName())
					)
				);
				return false;
			}

			if (txtComment.Text.Length > 500)
			{
				RequestManager.ErrorMessages.Add(
					new ErrorMessage(
						ErrorMessageTypeCode.ExcessiveCommentLength,
						ErrorMessageSeverityTypeCode.Severe,
						string.Format(ErrorMessageTypeCode.ExcessiveCommentLength.GetDisplayName(), ChartAuditSectionTypeCode.GetDisplayName(), "500", txtComment.Text.Length.ToString())
					)
				);
				return false;
			}

			foreach (DataGridItem item in grdDiagnosisCodingICD10.Items)
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
	}
}