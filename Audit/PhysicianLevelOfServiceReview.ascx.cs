using CCSBusinessObjects.BusinessObjects;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.Common;
using CCSBusinessObjects.Utility;
using ACS.Core.Extensions;
using CCSBusinessObjects.DAO;
using Microsoft.Extensions.Azure;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class PhysicianLevelOfServiceReview : BaseAuditControl
	{
		#region Internals
		private FacilityProfessionalDAO _facilityProfessionalDao;
		private PhysicianServiceRatingCodeListDAO _physicianServiceRatingCodeListDao;
		private PatientClassDAO _patientClassDao;
		private enum GridIndexes
		{
			Id = 0,
			PreviousDateOfService = 1,
			PreviousProvider = 2,
			PreviousCptCode = 3,
			PreviousHistory = 4,
			PreviousExam = 5,
			PreviousMdm = 6,
			AuditorDateOfService = 7,
			AuditorProvider = 8,
			AuditorCptCode = 9,
			AuditorHistory = 10,
			AuditorExam = 11,
			AuditorMdm = 12,
			AuditAction = 13,
		}

		private enum GridServiceIndexes
		{
			LevelNbr = 0,
			ServiceDescription = 1,
			Quantity = 2,
			Points = 3,
			AuditAction = 4,
		}

		private enum PhysicianCategoryId
		{
			History = 1,
			Exam = 2,
			MedicalDecisionMaking = 3,
		}
		#endregion Internals

		#region Properties
		public IChartAuditPhysicianLosVersionItemService ChartAuditPhysicianLosVersionItemService { get; set; }
		public IChartAuditPhysicianLosEvalVersionItemService ChartAuditPhysicianLosEvalVersionItemService { get; set; }
		public IEnumerable<ChartAuditPhysicianLosVersionItem> ChartAuditPhysicianLosVersionItems { get; set; }
		public IEnumerable<ChartAuditPhysicianLosEvalVersionItem> ChartAuditPhysicianLosEvalVersionItems { get; set; }
		public FacilityProfessionalDAO FacilityProfessionalDao => _facilityProfessionalDao ?? (_facilityProfessionalDao = new FacilityProfessionalDAO(RequestManager));
		public PhysicianServiceRatingCodeListDAO PhysicianServiceRatingCodeListDao => _physicianServiceRatingCodeListDao ?? (_physicianServiceRatingCodeListDao = new PhysicianServiceRatingCodeListDAO(RequestManager));
		public PatientClassDAO PatientClassDao => _patientClassDao ?? (_patientClassDao = new PatientClassDAO(RequestManager));
		#endregion Properties

		public void LoadModel(
			WebRequestManager requestManager,
			Chart chart,
			ChartPostBillAudit chartPostBillAudit)
		{
			RequestManager = requestManager;
			Chart = chart;
			ChartPostBillAudit = chartPostBillAudit;
			ChartAuditVersions = ChartAuditVersionService.GetChartAuditVersionListByChartAuditId(ChartPostBillAudit.Id);
			ChartAuditVersion = ChartAuditVersions.OrderByDescending(x => x.VersionNumber).FirstOrDefault();
			ChartAuditPhysicianLosVersionItems = ChartAuditVersion == null
				? new List<ChartAuditPhysicianLosVersionItem>()
				: ChartAuditPhysicianLosVersionItemService.GetChartAuditPhysicianLosVersionItemListByChartAuditVersionId(ChartAuditVersion.Id);
			ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.PhysicianService;

			// load the service detail version for each Los item.
			var chartAuditPhysicianLosEvalVersionItems = new List<ChartAuditPhysicianLosEvalVersionItem>();
			foreach (ChartAuditPhysicianLosVersionItem losItem in ChartAuditPhysicianLosVersionItems)
			{
				chartAuditPhysicianLosEvalVersionItems.AddRange(ChartAuditPhysicianLosEvalVersionItemService.GetChartAuditPhysicianLosEvalVersionItemListByChartAuditPhysicianLosVersionItemId(losItem.Id));
			}
			ChartAuditPhysicianLosEvalVersionItems = chartAuditPhysicianLosEvalVersionItems;
		}

		public void ModelToView()
		{
			grdPhysicianLOS.DataSource = ChartAuditPhysicianLosVersionItems;
			grdPhysicianLOS.DataBind();

			//Bind data to grdPhysicianServices
			grdPhysicianServices.DataSource = ChartAuditPhysicianLosEvalVersionItems;
			grdPhysicianServices.DataBind();

			txtComment.Text = ChartAuditVersionComment?.Comment ?? string.Empty;
		}

		protected void grdPhysicianLOS_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditPhysicianLosVersionItem auditAction))
				return;

			var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == auditAction.ChartAuditVersionId)?.VersionNumber;
			var previousVersionItem = new ChartAuditPhysicianLosVersionItem();
			var currentVersionItem = new ChartAuditPhysicianLosVersionItem();

			switch (chartAuditVersionNumber)
			{
				case 1:
					previousVersionItem = auditAction;
					currentVersionItem = null;
					break;
				case 2:
					previousVersionItem = auditAction.PrevChartAuditPhysicianLosVersionItemId.HasValue
						? ChartAuditPhysicianLosVersionItemService.GetChartAuditPhysicianLosVersionItemById(auditAction.PrevChartAuditPhysicianLosVersionItemId.Value)
						: null;
					currentVersionItem = auditAction;
					break;
			}

			if (e.Item.FindControl("lblPreviousDateOfService") is Label lblPreviousDateOfService && previousVersionItem?.DateOfService != null)
				lblPreviousDateOfService.Text = previousVersionItem.DateOfService.Value.ToShortDateString();
			if (e.Item.FindControl("lblPreviousProvider") is Label lblPreviousProvider && previousVersionItem?.ProviderId != null)
				lblPreviousProvider.Text = FacilityProfessionalDao.GetPhysicianName((int)previousVersionItem.ProviderId);
			if (e.Item.FindControl("lblPreviousCptCode") is Label lblPreviousCptCode && previousVersionItem?.CptCode != null)
			{
				lblPreviousCptCode.Text = previousVersionItem.CptCode;
				if (!string.IsNullOrWhiteSpace(previousVersionItem.Modifier)) lblPreviousCptCode.Text += $"-{previousVersionItem.Modifier}";
			}
			if (e.Item.FindControl("lblPreviousHistory") is Label lblPreviousHistory && previousVersionItem?.PhysicianHistoryId != null)
				lblPreviousHistory.Text = GetCategoryDescription((int)previousVersionItem.PhysicianHistoryId, (int)PhysicianCategoryId.History);
			if (e.Item.FindControl("lblPreviousExam") is Label lblPreviousExam &&
			    previousVersionItem?.PhysicianExamId != null) lblPreviousExam.Text = GetCategoryDescription((int)previousVersionItem.PhysicianExamId, (int)PhysicianCategoryId.Exam);
			if (e.Item.FindControl("lblPreviousMdm") is Label lblPreviousMdm && previousVersionItem?.PhysicianMdmId != null)
				lblPreviousMdm.Text = GetCategoryDescription((int)previousVersionItem.PhysicianMdmId, (int)PhysicianCategoryId.MedicalDecisionMaking);
			if (e.Item.FindControl("lblAuditorDateOfService") is Label lblAuditorDateOfService && currentVersionItem?.DateOfService != null)
				lblAuditorDateOfService.Text = currentVersionItem.DateOfService.Value.ToShortDateString();
			if (e.Item.FindControl("lblAuditorProvider") is Label lblAuditorProvider && currentVersionItem?.ProviderId != null)
				lblAuditorProvider.Text = FacilityProfessionalDao.GetPhysicianName((int)currentVersionItem.ProviderId);
			if (e.Item.FindControl("lblAuditorCptCode") is Label lblAuditorCptCode &&  currentVersionItem?.CptCode != null)
			{
				lblAuditorCptCode.Text = currentVersionItem.CptCode;
				if (!string.IsNullOrWhiteSpace(currentVersionItem.Modifier)) lblAuditorCptCode.Text += $"-{currentVersionItem.Modifier}";
			}
			if (e.Item.FindControl("lblAuditorHistory") is Label lblAuditorHistory && currentVersionItem?.PhysicianHistoryId != null)
				lblAuditorHistory.Text = GetCategoryDescription((int)currentVersionItem.PhysicianHistoryId, (int)PhysicianCategoryId.History);
			if (e.Item.FindControl("lblAuditorExam") is Label lblAuditorExam && currentVersionItem?.PhysicianExamId != null)
				lblAuditorExam.Text = GetCategoryDescription((int)currentVersionItem.PhysicianExamId, (int)PhysicianCategoryId.Exam);
			if (e.Item.FindControl("lblAuditorMdm") is Label lblAuditorMdm && currentVersionItem?.PhysicianMdmId != null)
				lblAuditorMdm.Text = GetCategoryDescription((int)currentVersionItem.PhysicianMdmId, (int)PhysicianCategoryId.MedicalDecisionMaking);
			if (e.Item.FindControl("lblAuditActionDescription") is Label lblAuditActionDescription && currentVersionItem != null)
				lblAuditActionDescription.Text = currentVersionItem.ChartAuditActionTypeCode.GetDisplayDescription();

			if (string.IsNullOrWhiteSpace(hdnAuditChange.Value) || hdnAuditChange.Value.Equals(bool.FalseString))
				hdnAuditChange.Value = auditAction.ChartAuditActionTypeCode.In(
					ChartAuditActionTypeCode.Added,
					ChartAuditActionTypeCode.Deleted,
					ChartAuditActionTypeCode.Revised,
					ChartAuditActionTypeCode.AbstractChange
				).ToString();

			switch (auditAction.ChartAuditActionTypeCode)
			{
				case ChartAuditActionTypeCode.Added:
					e.Item.Cells[(int)GridIndexes.AuditAction].BackColor =
					e.Item.Cells[(int)GridIndexes.PreviousCptCode].BackColor = 
					e.Item.Cells[(int)GridIndexes.AuditorCptCode].BackColor = AdditionBackColor;
					break;
				case ChartAuditActionTypeCode.Deleted:
					e.Item.Cells[(int)GridIndexes.AuditAction].BackColor =
					e.Item.Cells[(int)GridIndexes.PreviousCptCode].BackColor = 
					e.Item.Cells[(int)GridIndexes.AuditorCptCode].BackColor = DeletionBackColor;
					break;
				case ChartAuditActionTypeCode.Revised:
					if (previousVersionItem?.ProviderId != null
					&& currentVersionItem?.ProviderId != null
					&& previousVersionItem.ProviderId != currentVersionItem.ProviderId)
					{
						e.Item.Cells[(int)GridIndexes.PreviousProvider].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorProvider].BackColor = RevisionBackColor;
					}
					if (previousVersionItem?.Modifier!= null
					&& currentVersionItem?.Modifier != null
					&& previousVersionItem.Modifier != currentVersionItem.Modifier)
					{
						e.Item.Cells[(int)GridIndexes.PreviousCptCode].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorCptCode].BackColor = RevisionBackColor;
					}
					e.Item.Cells[(int)GridIndexes.AuditAction].BackColor = RevisionBackColor;
					break;
				case ChartAuditActionTypeCode.AbstractChange:
					if (previousVersionItem?.DateOfService != null 
					&& currentVersionItem?.DateOfService != null 
					&& !previousVersionItem.DateOfService.Value.Equals(currentVersionItem.DateOfService.Value))
					{
						e.Item.Cells[(int)GridIndexes.PreviousDateOfService].BackColor = 
						e.Item.Cells[(int)GridIndexes.AuditorDateOfService].BackColor = AbstractBackColor;
					}
					e.Item.Cells[(int)GridIndexes.AuditAction].BackColor = AbstractBackColor;
					break;
				case ChartAuditActionTypeCode.NoChange:
				default: break;
			}
		}

		protected void grdPhysicianServices_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditPhysicianLosEvalVersionItem auditAction))
				return;

			switch (auditAction.ChartAuditActionTypeCode)
			{
				case ChartAuditActionTypeCode.Added:
					e.Item.Cells[(int)GridServiceIndexes.AuditAction].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.LevelNbr].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.ServiceDescription].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.Quantity].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.Points].BackColor = AdditionBackColor;
					break;
				case ChartAuditActionTypeCode.Deleted:
					e.Item.Cells[(int)GridServiceIndexes.AuditAction].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.LevelNbr].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.ServiceDescription].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.Quantity].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.Points].BackColor = DeletionBackColor;
					break;
				case ChartAuditActionTypeCode.Revised:
					e.Item.Cells[(int)GridServiceIndexes.AuditAction].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.LevelNbr].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.ServiceDescription].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.Quantity].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.Points].BackColor = RevisionBackColor;
					break;
				case ChartAuditActionTypeCode.AbstractChange:
					e.Item.Cells[(int)GridServiceIndexes.AuditAction].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.LevelNbr].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.ServiceDescription].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.Quantity].BackColor =
					e.Item.Cells[(int)GridServiceIndexes.Points].BackColor = AbstractBackColor;
					break;
				case ChartAuditActionTypeCode.NoChange:
				default: break;
			}
		}

		private string GetCategoryDescription(int categoryRating, int categoryId)
		{
			var patientClass = PatientClassDao.Load(Chart.PatientClassID);
			var categoryList = PhysicianServiceRatingCodeListDao.LoadAllForCategory(categoryId, patientClass.PhysicianServiceClassCD, Chart.TimeOfService, Chart.PhysicianServiceGuidelineID).ToList<SimplePhysicianServiceRatingCodeListItem>();

			return categoryList.FirstOrDefault(x => x.PhysicianServiceCategoryRating == categoryRating)?.Description;
		}

		public void Save()
		{
			if (!IsDataValid()) throw new Exception();

			SaveComment(txtComment.Text);
		}

		public bool IsDataValid()
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
			return true;
		}
	}
}