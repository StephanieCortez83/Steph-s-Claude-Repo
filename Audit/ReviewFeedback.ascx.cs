using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.Common;
using CCSBusinessObjects.Utility;
using System;
using ACS.Core.Extensions;
using CCSBusinessObjects.BusinessObjects.Service;
using System.Collections.Generic;
using System.Linq;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class ReviewFeedback : BaseAuditControl
	{
		#region Internals
		#endregion Internals

		#region Properties
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
			ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.General;
		}

		public void ModelToView() => txtComment.Text = ChartAuditVersionComment?.Comment ?? string.Empty;

		public void Save()
		{
			if (!IsDataValid()) throw new Exception();

			SaveComment(txtComment.Text);
		}

		public bool IsDataValid()
		{
			if (txtComment.Text.Length > 500)
			{
				RequestManager.ErrorMessages.Add(
					new ErrorMessage(
						ErrorMessageTypeCode.ExcessiveCommentLength,
						ErrorMessageSeverityTypeCode.Severe,
						string.Format(ErrorMessageTypeCode.ExcessiveCommentLength.GetDisplayName(), "General Auditor Feedback", "500", txtComment.Text.Length.ToString())
					)
				);
				return false;
			}

			return true;
		}
	}
}