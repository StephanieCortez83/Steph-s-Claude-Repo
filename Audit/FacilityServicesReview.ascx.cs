using System.Collections.Generic;
using System.Linq;
using CCSBusinessObjects.BusinessObjects;
using System.Web.UI.WebControls;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.Common;
using ACS.Core.Extensions;
using CCSBusinessObjects.Utility;
using System;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class FacilityServicesReview : BaseAuditControl
	{
		#region Internals
		private enum GridIndexes
		{
			Id = 0,
			PreviousCode = 1,
			AuditorCode = 2,
			AuditAction = 3,
			ExcludeFromQa = 4,
		}

		private enum GridIndexesServices
		{
			FacilityServiceDescription = 0,
			Points = 1,	
			AuditAction = 2,
		}
		#endregion Internals

		#region Properties
		public IChartAuditFacilityLosVersionItemService ChartAuditFacilityLosVersionItemService { get; set; }
		public IEnumerable<ChartAuditFacilityLosVersionItem> ChartAuditFacilityLosVersionItems { get; set; }
		public IChartAuditFacilityLosEvalVersionItemService ChartAuditFacilityLosEvalVersionItemService { get; set; }
		public IEnumerable<ChartAuditFacilityLosEvalVersionItem> ChartAuditFacilityLosEvalVersionItems { get; set; }

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
			ChartAuditFacilityLosVersionItems = ChartAuditVersion == null
				? new List<ChartAuditFacilityLosVersionItem>()
				: ChartAuditFacilityLosVersionItemService.GetChartAuditFacilityLosVersionItemListByChartAuditVersionId(ChartAuditVersion.Id);
			ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.FacilityService;

			// Get the evaluation list of services selected that went into the LOS calculation.
			// There is only one level for Facility LOS calculations.
			if (ChartAuditFacilityLosVersionItems != null && ChartAuditFacilityLosVersionItems.Count() > 0)
			{
				var ChartFacilityLos = ChartAuditFacilityLosVersionItems.OrderByDescending(x => x.ChartAuditVersionId).FirstOrDefault();
				ChartAuditFacilityLosEvalVersionItems = ChartAuditVersion == null
					? new List<ChartAuditFacilityLosEvalVersionItem>()
					: ChartAuditFacilityLosEvalVersionItemService.GetChartAuditFacilityLosEvalVersionItemListByChartAuditFacilityLosVersionItemId(ChartFacilityLos.Id);
			}
			else
				ChartAuditFacilityLosEvalVersionItems = new List<ChartAuditFacilityLosEvalVersionItem>();
		}

		public void ModelToView()
		{
			grdFacilityLOS.DataSource = ChartAuditFacilityLosVersionItems;
			grdFacilityLOS.DataBind();

			//TODO: Get and bind DataSource for grdFacilityServices
			grdFacilityServices.DataSource = ChartAuditFacilityLosEvalVersionItems;
			grdFacilityServices.DataBind();

			txtComment.Text = ChartAuditVersionComment.Comment;
		}

		protected void grdFacilityLOS_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditFacilityLosVersionItem auditAction))
				return;

			var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == auditAction.ChartAuditVersionId)?.VersionNumber;
			var previousVersionItem = new ChartAuditFacilityLosVersionItem();
			var currentVersionItem = new ChartAuditFacilityLosVersionItem();

			switch (chartAuditVersionNumber)
			{
				case 1:
					previousVersionItem = auditAction;
					currentVersionItem = null;
					break;
				case 2:
					previousVersionItem = auditAction.PrevChartAuditFacilityLosVersionItemId.HasValue
						? ChartAuditFacilityLosVersionItemService.GetChartAuditFacilityLosVersionItemById(auditAction.PrevChartAuditFacilityLosVersionItemId.Value)
						: null;
					currentVersionItem = auditAction;
					break;
			}

			if (e.Item.FindControl("lblPreviousCode") is Label lblPreviousCode && previousVersionItem?.CptCode != null)
			{
				lblPreviousCode.Text = previousVersionItem.CptCode;
				if (!string.IsNullOrWhiteSpace(previousVersionItem.Modifier)) lblPreviousCode.Text += $"-{previousVersionItem.Modifier}";
			}
			if (e.Item.FindControl("lblAuditorCode") is Label lblAuditorCode && currentVersionItem?.CptCode != null)
			{
				lblAuditorCode.Text = currentVersionItem.CptCode;
				if (!string.IsNullOrWhiteSpace(currentVersionItem.Modifier)) lblAuditorCode.Text += $"-{currentVersionItem.Modifier}";
			}
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
					e.Item.Cells[(int)GridIndexes.PreviousCode].BackColor =
					e.Item.Cells[(int)GridIndexes.AuditorCode].BackColor = AdditionBackColor;
					break;
				case ChartAuditActionTypeCode.Deleted:
					e.Item.Cells[(int)GridIndexes.PreviousCode].BackColor =
					e.Item.Cells[(int)GridIndexes.AuditorCode].BackColor = DeletionBackColor;
					break;
				case ChartAuditActionTypeCode.Revised:
					e.Item.Cells[(int)GridIndexes.PreviousCode].BackColor =
					e.Item.Cells[(int)GridIndexes.AuditorCode].BackColor = RevisionBackColor;
					break;
				case ChartAuditActionTypeCode.AbstractChange:
					e.Item.Cells[(int)GridIndexes.PreviousCode].BackColor =
					e.Item.Cells[(int)GridIndexes.AuditorCode].BackColor = AbstractBackColor;
					break;
				case ChartAuditActionTypeCode.NoChange:
				default: break;
			}
		}

		protected void grdFacilityServices_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditFacilityLosEvalVersionItem auditAction))
				return;

			switch (auditAction.ChartAuditActionTypeCode)
			{
				case ChartAuditActionTypeCode.Added:
					e.Item.Cells[(int)GridIndexesServices.AuditAction].BackColor =
					e.Item.Cells[(int)GridIndexesServices.FacilityServiceDescription].BackColor =
					e.Item.Cells[(int)GridIndexesServices.Points].BackColor = AdditionBackColor;
					break;
				case ChartAuditActionTypeCode.Deleted:
					e.Item.Cells[(int)GridIndexesServices.AuditAction].BackColor =
					e.Item.Cells[(int)GridIndexesServices.FacilityServiceDescription].BackColor =
					e.Item.Cells[(int)GridIndexesServices.Points].BackColor = DeletionBackColor;
					break;
				case ChartAuditActionTypeCode.Revised:
					e.Item.Cells[(int)GridIndexesServices.AuditAction].BackColor =
					e.Item.Cells[(int)GridIndexesServices.FacilityServiceDescription].BackColor =
					e.Item.Cells[(int)GridIndexesServices.Points].BackColor = RevisionBackColor;
					break;
				case ChartAuditActionTypeCode.AbstractChange:
					e.Item.Cells[(int)GridIndexesServices.AuditAction].BackColor =
					e.Item.Cells[(int)GridIndexesServices.FacilityServiceDescription].BackColor =
					e.Item.Cells[(int)GridIndexesServices.Points].BackColor = AbstractBackColor;
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

			return true;
		}
	}
}