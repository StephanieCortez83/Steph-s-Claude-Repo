using System;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.DAO;
using System.Linq;
using System.Web.UI.WebControls;
using CCSBusinessObjects.Common;
using System.Collections.Generic;
using System.Drawing;
using ACS.Core.Extensions;
using CCSBusinessObjects.Utility;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class DocumentationDeficiencyReview : BaseAuditControl
	{
		#region Internals
		private DocumentationItemDAO _documentationItemDao;
		private enum GridIndexes
		{
			Id = 0,
			DocumentationItem = 1,
			AsSent = 2,
			FromAuditor = 3,
			AuditAction = 4,
			Correct = 5,
			ExcludeFromQaHidden = 6,
			ExcludeFromQa = 7,
			ExcludeReason = 8,
		}
		private bool? _isUserAuthorizedToExcludeFromQa;
		#endregion Internals

		#region Properties
		public IChartAuditDocumentationVersionItemService ChartAuditDocumentationVersionItemService { get; set; }
		public DocumentationItemDAO DocumentationItemDao => _documentationItemDao ?? (_documentationItemDao = new DocumentationItemDAO(RequestManager));
		public IEnumerable<ChartAuditDocumentationVersionItem> ChartAuditDocumentationVersionsItems { get; set; }

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
			ChartAuditDocumentationVersionsItems = ChartAuditVersion == null
				? new List<ChartAuditDocumentationVersionItem>()
				: ChartAuditDocumentationVersionItemService.GetChartAuditDocumentationVersionItemListByChartAuditVersionId(ChartAuditVersion.Id);
			ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.Documentation;
		}

		public void ModelToView()
		{
			grdDocumentationInequity.DataSource = ChartAuditDocumentationVersionsItems;
			grdDocumentationInequity.DataBind();

			txtComment.Text = ChartAuditVersionComment?.Comment ?? string.Empty;
		}

		protected void grdDocumentationInequity_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditDocumentationVersionItem auditAction)) 
				return;

			var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == auditAction.ChartAuditVersionId)?.VersionNumber;
			var previousVersionItem = new ChartAuditDocumentationVersionItem();
			var currentVersionItem = new ChartAuditDocumentationVersionItem();

			switch (chartAuditVersionNumber)
			{
				case 1:
					previousVersionItem = auditAction;
					currentVersionItem = null;
					break;
				case 2:
					previousVersionItem = auditAction.PrevChartAuditDocumentationVersionItemId.HasValue
						? ChartAuditDocumentationVersionItemService.GetChartAuditDocumentationVersionItemById(auditAction.PrevChartAuditDocumentationVersionItemId.Value)
						: null;
					currentVersionItem = auditAction;
					break;
			}

			if (e.Item.FindControl("lblPreviousDocumentationItemChecked") is Label lblPreviousDocumentationItemChecked && previousVersionItem?.DocumentationChecked != null)
				lblPreviousDocumentationItemChecked.Text = previousVersionItem.DocumentationChecked.ToString();
			if (e.Item.FindControl("lblCurrentDocumentationItemChecked") is Label lblCurrentDocumentationItemChecked && currentVersionItem?.DocumentationChecked != null)
				lblCurrentDocumentationItemChecked.Text = currentVersionItem.DocumentationChecked.ToString();
			if (e.Item.FindControl("lblAuditActionDescription") is Label lblAuditActionDescription && currentVersionItem?.ChartAuditActionTypeCode != null)
				lblAuditActionDescription.Text = currentVersionItem.ChartAuditActionTypeCode.GetDisplayDescription();
			if (e.Item.FindControl("lblDocumentationItem") is Label lblDocumentationItem)
			{
				var docItem = auditAction.DocumentationId.HasValue
					? DocumentationItemDao.Load(auditAction.DocumentationId.Value)
					: new DocumentationItem(RequestManager);
				lblDocumentationItem.Text = docItem?.Name ?? string.Empty;
			}
			if (e.Item.FindControl("chkCorrectCode") is CheckBox chkCorrectCode && currentVersionItem?.IsPreviousVersionCorrect != null)
				chkCorrectCode.Checked = currentVersionItem.IsPreviousVersionCorrect == true;
			if (e.Item.FindControl("chkExcludeFromReport") is CheckBox chkExcludeFromReport && e.Item.FindControl("ddlExcludeReason") is DropDownList ddlExcludeReason)
			{
				ddlExcludeReason.Enabled = 
				chkExcludeFromReport.Enabled = IsUserAuthorizedToExcludeFromQa && currentVersionItem?.IsPreviousVersionCorrect != null && currentVersionItem.IsPreviousVersionCorrect == false;
				chkExcludeFromReport.Checked = currentVersionItem?.ExcludeFromQA != null && currentVersionItem.ExcludeFromQA == true;

				FillDropDownList(
					ddlExcludeReason, 
					ExcludeReasons.Where(x => x.ChartSection.Equals(ChartAuditSectionTypeCode.GetShortName())).ToList(), 
					"ExcludeFromQAReportReasonDescription", 
					"ExcludeFromQAReportReasonID", 
					auditAction.ExcludeFromQAReasonID.ToString(), 
					"None", 
					"-1");
			}

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

			foreach (DataGridItem item in grdDocumentationInequity.Items)
			{
				if (item.ItemType != ListItemType.Item && item.ItemType != ListItemType.AlternatingItem)
					continue;

				if (!(item.FindControl("ddlExcludeReason") is DropDownList ddlExcludeReason) || !int.TryParse(ddlExcludeReason.SelectedValue, out var selectedExcludeReasonId))
					continue;

				if (!int.TryParse(item.Cells[(int)GridIndexes.Id].Text, out var auditActionId))
					continue;

				if (!(ChartAuditDocumentationVersionItemService.GetChartAuditDocumentationVersionItemById(auditActionId) is ChartAuditDocumentationVersionItem auditAction))
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

				ChartAuditDocumentationVersionItemService.Save(RequestManager.SessionManager.SignedOnUserProfile.UserProfileID, auditAction);
			}

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

			foreach (DataGridItem item in grdDocumentationInequity.Items)
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