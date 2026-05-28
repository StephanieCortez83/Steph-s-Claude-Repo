using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.DAO;
using System;
using System.Linq;
using System.Web.UI.WebControls;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.Common;
using ACS.Core.Extensions;
using CCSBusinessObjects.Utility;
using System.Collections.Generic;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class ProceduresReview : BaseAuditControl
	{
		#region Internals
		private ChargeMasterDepartmentDAO _chargeMasterDepartmentDao;
		private FacilityProfessionalDAO _facilityProfessionalDao;

		private enum GridIndexes
		{
			Id = 0,
			PreviousCode = 1,
			PreviousProvider = 2,
			PreviousUnits = 3,
			PreviousModifier = 4,
			PreviousDateOfService = 5,
			PreviousDepartment = 6,
			AuditorCode = 7,
			AuditorProvider = 8,
			AuditorUnits = 9,
			AuditorModifier = 10,
			AuditorDateOfService = 11,
			AuditorDepartment = 12,
			AuditAction = 13,
			ExcludeFromQa = 14,
		}
		#endregion Internals

		#region Properties

		public IChartAuditProcedureVersionItemService ChartAuditProcedureVersionItemService { get; set; }
		public ChargeMasterDepartmentDAO ChargeMasterDepartmentDao => _chargeMasterDepartmentDao ?? (_chargeMasterDepartmentDao = new ChargeMasterDepartmentDAO(RequestManager));
		public FacilityProfessionalDAO FacilityProfessionalDao => _facilityProfessionalDao ?? (_facilityProfessionalDao = new FacilityProfessionalDAO(RequestManager));
		public IEnumerable<ChartAuditProcedureVersionItem> ChartAuditProcedureVersionItems { get; set; }
		#endregion Properties

		public void LoadModel(
			WebRequestManager requestManager,
			Chart chart,
			ChartPostBillAudit chartPostBillAudit,
			ChartAuditSectionTypeCode chartAuditSectionTypeCode
		)
		{
			RequestManager = requestManager;
			Chart = chart;
			ChartPostBillAudit = chartPostBillAudit;
			ChartAuditVersions = ChartAuditVersionService.GetChartAuditVersionListByChartAuditId(ChartPostBillAudit.Id);
			ChartAuditVersion = ChartAuditVersions.OrderByDescending(x => x.VersionNumber).FirstOrDefault();
			ChartAuditSectionTypeCode = chartAuditSectionTypeCode;
			ChartAuditProcedureVersionItems = ChartAuditVersion == null
				? new List<ChartAuditProcedureVersionItem>()
				: ChartAuditProcedureVersionItemService.GetChartAuditProcedureVersionItemListByChartAuditVersionIdAndProcedureType(ChartAuditVersion.Id, ChartAuditSectionTypeCode.GetShortName());
			
		}

		public void ModelToView()
		{
			grdProcedures.DataSource = ChartAuditProcedureVersionItems;
			grdProcedures.DataBind();

			txtComment.Text = ChartAuditVersionComment.Comment;
		}

		protected void grdProcedures_OnItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditProcedureVersionItem auditAction))
				return;

			var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == auditAction.ChartAuditVersionId)?.VersionNumber;
			var previousVersionItem = new ChartAuditProcedureVersionItem();
			var currentVersionItem = new ChartAuditProcedureVersionItem();

			switch (chartAuditVersionNumber)
			{
				case 1:
					previousVersionItem = auditAction;
					currentVersionItem = null;
					break;
				case 2:
					previousVersionItem = auditAction.PrevChartAuditProcedureVersionItemId.HasValue
						? ChartAuditProcedureVersionItemService.GetChartAuditProcedureVersionItemById(auditAction.PrevChartAuditProcedureVersionItemId.Value)
						: null;
					currentVersionItem = auditAction;
					break;
			}

			if (e.Item.FindControl("lblPreviousCPTCode") is Label lblPreviousCptCode && previousVersionItem?.CptCode != null)
				lblPreviousCptCode.Text = previousVersionItem.CptCode;
			if (e.Item.FindControl("lblPreviousProvider") is Label lblPreviousProvider && previousVersionItem?.ProviderId != null)
				lblPreviousProvider.Text = FacilityProfessionalDao.Load((int)previousVersionItem.ProviderId).Name.LastCommaFirst;
			if (e.Item.FindControl("lblPreviousQuantity") is Label lblPreviousQuantity && previousVersionItem?.Quantity != null && previousVersionItem.Quantity.Value > 0)
				lblPreviousQuantity.Text = previousVersionItem.Quantity.Value.ToString();
			if (e.Item.FindControl("lblPreviousModifier") is Label lblPreviousModifier && previousVersionItem?.Modifier != null)
				lblPreviousModifier.Text = previousVersionItem.Modifier;
			if (e.Item.FindControl("lblPreviousDateOfService") is Label lblPreviousDateOfService && previousVersionItem?.ProcedureDate != null)
				lblPreviousDateOfService.Text = previousVersionItem.ProcedureDate.Value.ToShortDateString();
			if (e.Item.FindControl("lblPreviousDept") is Label lblPreviousDept && previousVersionItem?.ChargeMasterDeptId != null)
				lblPreviousDept.Text = ChargeMasterDepartmentDao.Load((int)previousVersionItem.ChargeMasterDeptId).Name;
			if (e.Item.FindControl("lblAuditorCptCode") is Label lblAuditorCptCode && currentVersionItem?.CptCode != null)
				lblAuditorCptCode.Text = currentVersionItem.CptCode;
			if (e.Item.FindControl("lblAuditorProvider") is Label lblAuditorProvider && currentVersionItem?.ProviderId != null)
				lblAuditorProvider.Text = FacilityProfessionalDao.Load((int)currentVersionItem.ProviderId).Name.LastCommaFirst;
			if (e.Item.FindControl("lblAuditorQuantity") is Label lblAuditorQuantity && currentVersionItem?.Quantity != null && currentVersionItem.Quantity.Value > 0)
				lblAuditorQuantity.Text = currentVersionItem.Quantity.Value.ToString();
			if (e.Item.FindControl("lblAuditorModifier") is Label lblAuditorModifier && currentVersionItem?.Modifier != null)
				lblAuditorModifier.Text = currentVersionItem.Modifier;
			if (e.Item.FindControl("lblAuditorDateOfService") is Label lblAuditorDateOfService && currentVersionItem?.ProcedureDate != null)
				lblAuditorDateOfService.Text = currentVersionItem.ProcedureDate.Value.ToShortDateString();
			if (e.Item.FindControl("lblAuditorDept") is Label lblAuditorDept && currentVersionItem?.ChargeMasterDeptId != null)
				lblAuditorDept.Text = ChargeMasterDepartmentDao.Load((int)currentVersionItem.ChargeMasterDeptId).Name;
			if (e.Item.FindControl("lblAuditActionDescription") is Label lblAuditActionDescription && currentVersionItem != null)
				lblAuditActionDescription.Text = currentVersionItem.ChartAuditActionTypeCode.GetDisplayDescription();

			if (string.IsNullOrWhiteSpace(hdnAuditChange.Value) || hdnAuditChange.Value.Equals(bool.FalseString))
				hdnAuditChange.Value = auditAction.ChartAuditActionTypeCode.In(
					ChartAuditActionTypeCode.Added,
					ChartAuditActionTypeCode.Deleted,
					ChartAuditActionTypeCode.Revised
				).ToString();

			switch (auditAction.ChartAuditActionTypeCode)
			{
				case ChartAuditActionTypeCode.Added:
					e.Item.Cells[(int)GridIndexes.AuditAction].BackColor =
					e.Item.Cells[(int)GridIndexes.PreviousCode].BackColor = 
					e.Item.Cells[(int)GridIndexes.AuditorCode].BackColor = AdditionBackColor;
					break;
				case ChartAuditActionTypeCode.Deleted:
					e.Item.Cells[(int)GridIndexes.AuditAction].BackColor =
					e.Item.Cells[(int)GridIndexes.PreviousCode].BackColor = 
					e.Item.Cells[(int)GridIndexes.AuditorCode].BackColor = DeletionBackColor;
					break;
				case ChartAuditActionTypeCode.Revised:
					e.Item.Cells[(int)GridIndexes.AuditAction].BackColor = RevisionBackColor;
					if (previousVersionItem?.CptCode != null && currentVersionItem?.CptCode != null && previousVersionItem.CptCode != currentVersionItem.CptCode)
					{
						e.Item.Cells[(int)GridIndexes.PreviousCode].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorCode].BackColor = RevisionBackColor;
					}
					if (previousVersionItem?.ProviderId != null && currentVersionItem?.ProviderId != null && previousVersionItem.ProviderId.Value != currentVersionItem.ProviderId.Value)
					{
						e.Item.Cells[(int)GridIndexes.PreviousProvider].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorProvider].BackColor = RevisionBackColor;
					}
					if (previousVersionItem?.Quantity != null && currentVersionItem?.Quantity != null && previousVersionItem.Quantity.Value != currentVersionItem.Quantity.Value)
					{
						e.Item.Cells[(int)GridIndexes.PreviousUnits].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorUnits].BackColor = RevisionBackColor;
					}
					if (previousVersionItem?.Modifier != null && currentVersionItem?.Modifier != null && !previousVersionItem.Modifier.Equals(currentVersionItem.Modifier))
					{
						e.Item.Cells[(int)GridIndexes.PreviousModifier].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorModifier].BackColor = RevisionBackColor;
					}
					if (previousVersionItem?.ProcedureDate != null && currentVersionItem?.ProcedureDate != null && !previousVersionItem.ProcedureDate.Value.Equals(currentVersionItem.ProcedureDate.Value))
					{
						e.Item.Cells[(int)GridIndexes.PreviousDateOfService].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorDateOfService].BackColor = RevisionBackColor;
					}
					if (previousVersionItem?.ChargeMasterDeptId != null && currentVersionItem?.ChargeMasterDeptId != null && previousVersionItem.ChargeMasterDeptId.Value != currentVersionItem.ChargeMasterDeptId.Value)
					{
						e.Item.Cells[(int)GridIndexes.PreviousDepartment].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorDepartment].BackColor = RevisionBackColor;
					}
					break;
				case ChartAuditActionTypeCode.AbstractChange:
					e.Item.Cells[(int)GridIndexes.AuditAction].BackColor = AbstractBackColor;
					if (previousVersionItem?.ProcedureDate != null && currentVersionItem?.ProcedureDate != null && !previousVersionItem.ProcedureDate.Value.Equals(currentVersionItem.ProcedureDate.Value))
					{
						e.Item.Cells[(int)GridIndexes.PreviousDateOfService].BackColor = 
						e.Item.Cells[(int)GridIndexes.AuditorDateOfService].BackColor = AbstractBackColor;
					}
					if (previousVersionItem?.ChargeMasterDeptId != null && currentVersionItem?.ChargeMasterDeptId != null && previousVersionItem.ChargeMasterDeptId.Value != currentVersionItem.ChargeMasterDeptId.Value)
					{
						e.Item.Cells[(int)GridIndexes.PreviousDepartment].BackColor =
						e.Item.Cells[(int)GridIndexes.AuditorDepartment].BackColor = AbstractBackColor;
					}
					break;
				case ChartAuditActionTypeCode.NoChange:
				default: break;
			}
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