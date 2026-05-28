using System.Collections.Generic;
using System.Linq;
using CCSBusinessObjects.BusinessObjects;
using System.Web.UI.WebControls;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.Common;
using CCSBusinessObjects.Utility;
using System;
using ACS.Core.Extensions;
using System.Text;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.Menu;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.StartPanel;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class AnesthesiaReview : BaseAuditControl
	{
		#region Internals
		private enum GridIndexes
		{
			Id = 0,
			PreviousCode = 1,
			AuditorCode = 2,
			AuditAction = 3,
			ChangeDetail = 4,
			ExcludeFromQa = 5
		}
		#endregion Internals

		#region Properties
		public IChartAuditAnesthesiaVersionItemService ChartAuditAnesthesiaVersionItemService { get; set; }
		public IEnumerable<ChartAuditAnesthesiaVersionItem> ChartAuditAnesthesiaVersionItems { get; set; }
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
			ChartAuditAnesthesiaVersionItems = ChartAuditVersion == null
				? new List<ChartAuditAnesthesiaVersionItem>()
				: ChartAuditAnesthesiaVersionItemService.GetChartAuditAnesthesiaVersionItemListByChartAuditVersionId(ChartAuditVersion.Id);
			ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.Anesthesia;
		}

		public void ModelToView()
		{
			grdAnesthesiaCoding.DataSource = ChartAuditAnesthesiaVersionItems;
			grdAnesthesiaCoding.DataBind();

			txtComment.Text = ChartAuditVersionComment?.Comment ?? string.Empty;
		}

		protected void grdAnesthesiaCoding_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditAnesthesiaVersionItem auditAction))
				return;

			var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == auditAction.ChartAuditVersionId)?.VersionNumber;
			var previousVersionItem = new ChartAuditAnesthesiaVersionItem();
			var currentVersionItem = new ChartAuditAnesthesiaVersionItem();

			switch (chartAuditVersionNumber)
			{
				case 1:
					previousVersionItem = auditAction;
					currentVersionItem = null;
					break;
				case 2:
					previousVersionItem = auditAction.PrevChartAuditAnesthesiaVersionItemId.HasValue
						? ChartAuditAnesthesiaVersionItemService.GetChartAuditAnesthesiaVersionItemById(auditAction.PrevChartAuditAnesthesiaVersionItemId.Value)
						: null;
					currentVersionItem = auditAction;
					break;
			}

			if (e.Item.FindControl("lblPreviousCode") is Label lblPreviousCode && previousVersionItem?.AnesthesiaCode != null)
				lblPreviousCode.Text = previousVersionItem.AnesthesiaCode;
			
			if (e.Item.FindControl("lblAuditorCode") is Label lblAuditorCode)
				// Because the code is part of the key, it is never actually deleted from the version item.  But we want to supress it on the display.
				if (currentVersionItem?.AnesthesiaCode != null && currentVersionItem?.ChartAuditActionTypeCode != ChartAuditActionTypeCode.Deleted)
					lblAuditorCode.Text = currentVersionItem.AnesthesiaCode;
				else
					lblAuditorCode.Text = "";

			if (e.Item.FindControl("lblAuditActionDescription") is Label lblAuditActionDescription)
				lblAuditActionDescription.Text = auditAction.ChartAuditActionTypeCode.GetDisplayDescription();

			// add change detail, only for revised or abstract changes.
			if (e.Item.FindControl("lblAuditChangeDetail") is Label lblAuditChangeDetail && (auditAction.ChartAuditActionTypeCode == ChartAuditActionTypeCode.Revised || auditAction.ChartAuditActionTypeCode == ChartAuditActionTypeCode.AbstractChange))
				lblAuditChangeDetail.Text = formatChangeDetailHTML(previousVersionItem, currentVersionItem);

			if (string.IsNullOrWhiteSpace(hdnAuditChange.Value) || hdnAuditChange.Value.Equals(bool.FalseString))
				hdnAuditChange.Value = auditAction.ChartAuditActionTypeCode.In(
					ChartAuditActionTypeCode.Revised,
					ChartAuditActionTypeCode.Added,
					ChartAuditActionTypeCode.Deleted, 
					ChartAuditActionTypeCode.AbstractChange 
				).ToString();

			switch (auditAction.ChartAuditActionTypeCode)
			{
				case ChartAuditActionTypeCode.Revised: e.Item.BackColor = RevisionBackColor; break;
				case ChartAuditActionTypeCode.Added: e.Item.BackColor = AdditionBackColor; break;
				case ChartAuditActionTypeCode.Deleted: e.Item.BackColor = DeletionBackColor; break;
				case ChartAuditActionTypeCode.AbstractChange: e.Item.BackColor = AbstractBackColor; break;
				case ChartAuditActionTypeCode.NoChange:
				default: break;
			}
		}
		public void Save()
		{
			if (!IsDataValid()) throw new Exception();

			if (string.IsNullOrWhiteSpace(txtComment.Text)) return;
			
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
						string.Format(ErrorMessageTypeCode.AuditChangesRequireComment.GetDisplayName(), "Anesthesia Coding")
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

		private string formatChangeDetailHTML(ChartAuditAnesthesiaVersionItem prevItem, ChartAuditAnesthesiaVersionItem curItem)
		{
			var displayHTML = new StringBuilder();

			if (prevItem != null && curItem != null)
			{

				if (prevItem?.StartTime != curItem?.StartTime)
					displayHTML.Append(formatChangeDetailHTMLItem("StartTime", prevItem.StartTime?.ToString("h:mm tt"), curItem.StartTime?.ToString("h:mm tt")));
				if (prevItem?.StopTime != curItem?.StopTime)
					displayHTML.Append(formatChangeDetailHTMLItem("StopTime", prevItem.StopTime?.ToString("h:mm tt"), curItem.StopTime?.ToString("h:mm tt")));
				if (prevItem?.ExcludeMinutes != curItem?.ExcludeMinutes)
					displayHTML.Append(formatChangeDetailHTMLItem("ExcludeMinutes", prevItem.ExcludeMinutes.ToString(), curItem.ExcludeMinutes.ToString()));
				if (prevItem?.Units != curItem?.Units)
					displayHTML.Append(formatChangeDetailHTMLItem("Units", prevItem.Units.ToString(), curItem.Units.ToString()));
				if (prevItem?.Minutes != curItem?.Minutes)
					displayHTML.Append(formatChangeDetailHTMLItem("Minutes", prevItem.Minutes.ToString(), curItem.Minutes.ToString()));
				if (prevItem?.ProviderModifiers != curItem?.ProviderModifiers)
					displayHTML.Append(formatChangeDetailHTMLItem("ProviderModifiers", prevItem.ProviderModifiers.ToString(), curItem.ProviderModifiers.ToString()));
				if (prevItem?.MacModifiers != curItem?.MacModifiers)
					displayHTML.Append(formatChangeDetailHTMLItem("MacModifiers", prevItem.MacModifiers.ToString(), curItem.MacModifiers.ToString()));
				if (prevItem?.PhysicalStatusModifier != curItem?.PhysicalStatusModifier)
					displayHTML.Append(formatChangeDetailHTMLItem("PhysicalStatusModifier", prevItem.PhysicalStatusModifier.ToString(), curItem.PhysicalStatusModifier.ToString()));
				if (prevItem?.BaseUnitExceptionFieldAvoidance != curItem?.BaseUnitExceptionFieldAvoidance)
					displayHTML.Append(formatChangeDetailHTMLItem("BaseUnitExceptionFieldAvoidance", prevItem.BaseUnitExceptionFieldAvoidance.ToString(), curItem.BaseUnitExceptionFieldAvoidance.ToString()));
				if (prevItem?.BaseUnitExceptionNonSupine != curItem?.BaseUnitExceptionNonSupine)
					displayHTML.Append(formatChangeDetailHTMLItem("BaseUnitExceptionNonSupine", prevItem.BaseUnitExceptionNonSupine.ToString(), curItem.BaseUnitExceptionNonSupine.ToString()));
				if (prevItem?.BaseUnitExceptionModifier != curItem?.BaseUnitExceptionModifier)
					displayHTML.Append(formatChangeDetailHTMLItem("BaseUnitExceptionModifier", prevItem.BaseUnitExceptionModifier.ToString(), curItem.BaseUnitExceptionModifier.ToString()));
				if (prevItem?.QualifyingCircumstanceCode != curItem?.QualifyingCircumstanceCode)
					displayHTML.Append(formatChangeDetailHTMLItem("QualifyingCircumstanceCode", prevItem.QualifyingCircumstanceCode.ToString(), curItem.QualifyingCircumstanceCode.ToString()));
				if (prevItem?.ChargeMasterId != curItem?.ChargeMasterId)
					displayHTML.Append(formatChangeDetailHTMLItem("ChargeMasterId", prevItem.ChargeMasterId.ToString(), curItem.ChargeMasterId.ToString()));
				if (prevItem?.BaseUnitExceptionLimitedAccessToAirway != curItem?.BaseUnitExceptionLimitedAccessToAirway)
					displayHTML.Append(formatChangeDetailHTMLItem("BaseUnitExceptionLimitedAccessToAirway", prevItem.BaseUnitExceptionLimitedAccessToAirway.ToString(), curItem.BaseUnitExceptionLimitedAccessToAirway.ToString()));
				if (prevItem?.DocumentationSupportsIncreasedComplexity != curItem?.DocumentationSupportsIncreasedComplexity)
					displayHTML.Append(formatChangeDetailHTMLItem("DocumentationSupportsIncreasedComplexity", prevItem.DocumentationSupportsIncreasedComplexity.ToString(), curItem.DocumentationSupportsIncreasedComplexity.ToString()));
				if (prevItem?.DocumentationSupportsIncreasedComplexityReasonId != curItem?.DocumentationSupportsIncreasedComplexityReasonId)
					displayHTML.Append(formatChangeDetailHTMLItem("DocumentationSupportsIncreasedComplexityReasonId", prevItem.DocumentationSupportsIncreasedComplexityReasonId.ToString(), curItem.DocumentationSupportsIncreasedComplexityReasonId.ToString()));
				if (prevItem?.CptModifiers != curItem?.CptModifiers)
					displayHTML.Append(formatChangeDetailHTMLItem("CptModifiers", prevItem.CptModifiers.ToString(), curItem.CptModifiers.ToString()));
			}

			return displayHTML.ToString();
		}

		private string formatChangeDetailHTMLItem(string fieldName, string before, string after)
		{
			if (before.Length <= 0)
				before = "null";
			return "<b>" + fieldName + "</b>  " + before + " => " + after + "<br/>";
		}
	}
}