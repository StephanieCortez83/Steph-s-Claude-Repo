using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSWeb.WebPages;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.Common;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class BaseAuditControl : UserControl
	{
		#region Internals

		protected const string AutomationErrorDescription = "Automation Error";

		protected Color AdditionBackColor = Color.FromArgb(233, 138, 125);
		protected Color RevisionBackColor = Color.FromArgb(248, 203, 173);
		protected Color DeletionBackColor = Color.FromArgb(142, 169, 219);
		protected Color AbstractBackColor = Color.Yellow;
		protected Color PassColor = Color.FromArgb(198, 239, 206);
		protected Color FailColor = Color.FromArgb(255, 199, 206);

		private ChartAuditVersionComment _chartAuditVersionComment;

		#endregion Internals

		#region Properties

		public Chart Chart { get; set; }
		public IEnumerable<ExcludeFromQAReportReason> ExcludeReasons { get; set; }
		public IEnumerable<ChartAuditVersion> ChartAuditVersions { get; set; }
		public ChartPostBillAudit ChartPostBillAudit { get; set; }
		public WebRequestManager RequestManager { get; set; }
		public IChartAuditVersionService ChartAuditVersionService { get; set; }
		public IChartAuditVersionCommentService ChartAuditVersionCommentService { get; set; }
		public ChartAuditVersion ChartAuditVersion { get; set; }
		public ChartAuditSectionTypeCode ChartAuditSectionTypeCode { get; set; }
		public ChartAuditVersionComment ChartAuditVersionComment
		{
			get
			{
				if (_chartAuditVersionComment == null)
				{
					if(ChartAuditVersionCommentService == null || ChartAuditVersion == null)
						_chartAuditVersionComment = new ChartAuditVersionComment();
					else
					{
						var commentList =
							ChartAuditVersionCommentService?
								.GetChartAuditVersionCommentListByChartAuditVersionIdAndChartAuditSectionTypeCode((int)ChartAuditVersion.Id, ChartAuditSectionTypeCode);
						_chartAuditVersionComment = commentList != null && commentList.Count > 0
							? commentList[commentList.Count - 1]
							: new ChartAuditVersionComment();
					}
				}
				return _chartAuditVersionComment;
			}
		}
		#endregion Properties

		#region Methods
		/// <summary>
		/// Populates the DropDownList with values from the DataSource
		/// </summary>
		/// <param name="dropDownList">DropDownList to populate</param>
		/// <param name="dataSource"> DataSource as an ArrayList</param>
		/// <param name="dataTextField">DataTextField</param>
		/// <param name="dataValueField">DataValueField</param>
		/// <param name="selectedValue">Selected value</param>
		/// <param name="defaultListItemText">Text to appear as first item in list</param>
		/// <param name="defaultListItemValue">Value of first item in list</param>
		protected void FillDropDownList(DropDownList dropDownList, IList dataSource, string dataTextField, string dataValueField, string selectedValue, string defaultListItemText, string defaultListItemValue)
		{
			dropDownList.Items.Clear();
			dropDownList.SelectedValue = null;
			dropDownList.DataSource = dataSource;
			dropDownList.DataTextField = dataTextField;
			dropDownList.DataValueField = dataValueField;
			dropDownList.TryDataBind();
			dropDownList.Items.Insert(0, new ListItem(defaultListItemText, defaultListItemValue));

			dropDownList.SelectedValue = dropDownList.Items.FindByValue(selectedValue) != null ? selectedValue : "0";
		}

		public void SaveComment(string commentText)
		{
			ChartAuditVersionComment.Comment = commentText;
			ChartAuditVersionComment.ChartAuditVersionId = ChartAuditVersion.Id;
			ChartAuditVersionComment.ChartAuditSectionTypeCode = ChartAuditSectionTypeCode;

			ChartAuditVersionCommentService?.Save(RequestManager.SessionManager.SignedOnUserProfile.UserProfileID, ChartAuditVersionComment);
		}
		#endregion Methods	
	}
}