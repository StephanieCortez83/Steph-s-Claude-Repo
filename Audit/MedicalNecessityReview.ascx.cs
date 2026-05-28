using System.Collections.Generic;
using System.Linq;
using CCSBusinessObjects.BusinessObjects;
using System.Web.UI.WebControls;
using ACS.Core.Extensions;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.Common;
using CCSBusinessObjects.Utility;
using System;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class MedicalNecessityReview : BaseAuditControl
	{
		#region Internals
		private enum GridIndexes
		{
			Element = 0,
			AsSent = 1,
			FromAuditor = 2,
			AuditAction = 3,
		}
		#endregion Internals

		#region Properties
		public IChartAuditDemographicVersionItemService ChartAuditDemographicVersionItemService { get; set; }
		public IEnumerable<ChartAuditDemographicVersionItem> ChartAuditDemographicVersionItems { get; set; }
		#endregion

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
			ChartAuditDemographicVersionItems = ChartAuditVersion == null
				? new List<ChartAuditDemographicVersionItem>()
				: ChartAuditDemographicVersionItemService.GetChartAuditDemographicVersionItemListByChartAuditVersionId(ChartAuditVersion.Id);
			ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.MedicalNecessity;
		}

		public void ModelToView()
		{
			grdChartMedicalNecessity.DataSource = ChartAuditDemographicVersionItems;
			grdChartMedicalNecessity.DataBind();

			txtComment.Text = ChartAuditVersionComment?.Comment ?? string.Empty;
		}

		protected void grdChartMedicalNecessity_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditDemographicVersionItem auditAction))
				return;

			var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == auditAction.ChartAuditVersionId)?.VersionNumber;
			var previousVersionItem = new ChartAuditDemographicVersionItem();
			var currentVersionItem = new ChartAuditDemographicVersionItem();

			switch (chartAuditVersionNumber)
			{
				case 1:
					previousVersionItem = auditAction;
					currentVersionItem = null;
					break;
				case 2:
					previousVersionItem = auditAction.PrevChartAuditDemographicVersionItemId.HasValue
						? ChartAuditDemographicVersionItemService.GetChartAuditDemographicVersionItemById(auditAction.PrevChartAuditDemographicVersionItemId.Value)
						: null;
					currentVersionItem = auditAction;
					break;
			}

			if (previousVersionItem == null 
			|| currentVersionItem == null 
			|| previousVersionItem.NoLcdServices == currentVersionItem.NoLcdServices)
				return;

			if (e.Item.FindControl("lblElement") is Label lblElement)
				lblElement.Text = ChartDemographicField.NoLCDServices.Text();
			if (e.Item.FindControl("lblPreviousValue") is Label lblPreviousValue && previousVersionItem.NoLcdServices != null)
				lblPreviousValue.Text = previousVersionItem.NoLcdServices.ToString();
			if (e.Item.FindControl("lblAuditorValue") is Label lblAuditorValue && currentVersionItem.NoLcdServices != null)
				lblAuditorValue.Text = currentVersionItem.NoLcdServices.ToString();
			if (e.Item.FindControl("lblAuditActionDescription") is Label lblAuditActionDescription)
				lblAuditActionDescription.Text = ChartAuditActionTypeCode.AbstractChange.GetDisplayDescription();

			e.Item.BackColor = AbstractBackColor;
			hdnAuditChange.Value = bool.TrueString;
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