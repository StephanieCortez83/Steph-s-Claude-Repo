namespace CCSWeb.WebPages.Controls.Portlets
{
	using System;
	using System.Web.UI.WebControls;
	using System.Collections;
    using System.Linq;
    using CCSBusinessObjects.BusinessObjects;
	using CCSBusinessObjects.AppSystem;
	using CCSBusinessObjects.DAO;

    /// <summary>
	///		Summary description for Documents.
	/// </summary>
	public partial class Reports : System.Web.UI.UserControl
	{

		private WebRequestManager	m_RequestManager;
		private ArrayList			m_Reports;
        private ArrayList _DocImprovementReports;
        private ArrayList _InternalReports;
        private ArrayList _ProductivityReports;
        private ArrayList _ReconciliationReports;
        private ArrayList _StatFacilityReports;
        private ArrayList _StatProviderReports;
        private bool				m_CanEdit;

        public void PreparePortlet(WebRequestManager aRequestManager) 
		{
			m_RequestManager = aRequestManager;
			pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_REPORTS);
			var dao = new PortalReportDAO(m_RequestManager);

			// Get a list of all reports that should be visible to this user
			m_Reports = dao.LoadAllVisibleToSignedOnUser();

			var signedOnUserProfile = m_RequestManager.SessionManager.SignedOnUserProfile;

			m_CanEdit = signedOnUserProfile != null && signedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_ADMINISTRATION);
            _DocImprovementReports = new ArrayList();
            _InternalReports = new ArrayList();
            _ProductivityReports = new ArrayList();
            _ReconciliationReports = new ArrayList();
            _StatFacilityReports = new ArrayList();
            _StatProviderReports = new ArrayList();

            var pReports = m_Reports.Cast<PortalReport>();

            var docImprovReports = pReports.Where(p => p.PortalReportCategoryID == 1);
            var internReports = pReports.Where(p => p.PortalReportCategoryID == 2);
            var prodReports = pReports.Where(p => p.PortalReportCategoryID == 3);
            var recReports = pReports.Where(p => p.PortalReportCategoryID == 4);
            var statfacReports = pReports.Where(p => p.PortalReportCategoryID == 5);
            var statProvReports = pReports.Where(p => p.PortalReportCategoryID == 6);

            foreach (PortalReport pr in docImprovReports)
            {
                _DocImprovementReports.Add(pr);
            }

            foreach (PortalReport pr in internReports)
            {
                _InternalReports.Add(pr);
            }

            foreach (PortalReport pr in prodReports)
            {
                _ProductivityReports.Add(pr);
            }

            foreach (PortalReport pr in recReports)
            {
                _ReconciliationReports.Add(pr);
            }

            foreach (PortalReport pr in statfacReports)
            {
                _StatFacilityReports.Add(pr);
            }

            foreach (PortalReport pr in statProvReports)
            {
                _StatProviderReports.Add(pr);
            }

            if (_DocImprovementReports.Count > 0)
            {
                grdDocumentationImprovement.DataSource = _DocImprovementReports;
                grdDocumentationImprovement.DataBind();
                Panel10.Visible = true;
                CollapsiblePanelExtender1.ExpandControlID = "Label2";
                CollapsiblePanelExtender1.CollapseControlID = "Label2";
                CollapsiblePanelExtender1.TextLabelID = "Label2";
            }
            else
            {
                Panel10.Visible = false;
                CollapsiblePanelExtender1.ExpandControlID = "";
                CollapsiblePanelExtender1.CollapseControlID = "";
                CollapsiblePanelExtender1.TextLabelID = "";
            }

           
            if (_InternalReports.Count > 0)
            {
                if (m_RequestManager.SessionManager.SignedOnUserProfile.UserClassCode == UserClass.CORPORATE_EMPLOYEE)
                {
                    grdInternal.DataSource = _InternalReports;
                    grdInternal.DataBind();
                    Panel1.Visible = true;
                    grdInternal.Visible = true;
                    CollapsiblePanelExtender2.ExpandControlID = "Label3";
                    CollapsiblePanelExtender2.CollapseControlID = "Label3";
                    CollapsiblePanelExtender2.TextLabelID = "Label3";
                }
                else
                {
                    Panel1.Visible = false;
                    grdInternal.Visible = false;
                    CollapsiblePanelExtender2.ExpandControlID = "";
                    CollapsiblePanelExtender2.CollapseControlID = "";
                    CollapsiblePanelExtender2.TextLabelID = "";

                }
            }
            else
            {
                Panel1.Visible = false;
                CollapsiblePanelExtender2.ExpandControlID = "";
                CollapsiblePanelExtender2.CollapseControlID = "";
                CollapsiblePanelExtender2.TextLabelID = "";

            }
            
            if (_ProductivityReports.Count > 0)
            {
                grdProductivity.DataSource = _ProductivityReports;
                grdProductivity.DataBind();
                Panel2.Visible = true;
                CollapsiblePanelExtender3.ExpandControlID = "Label5";
                CollapsiblePanelExtender3.CollapseControlID = "Label5";
                CollapsiblePanelExtender3.TextLabelID = "Label5";
            }
            else
            {
                Panel2.Visible = false;
                CollapsiblePanelExtender3.ExpandControlID = "";
                CollapsiblePanelExtender3.CollapseControlID = "";
                CollapsiblePanelExtender3.TextLabelID = "";
            }
           
            if(_ReconciliationReports.Count > 0)
            {
                grdReconciliation.DataSource = _ReconciliationReports;
                grdReconciliation.DataBind();
                Panel5.Visible = true;
                CollapsiblePanelExtender5.ExpandControlID = "Label10";
                CollapsiblePanelExtender5.CollapseControlID = "Label10";
                CollapsiblePanelExtender5.TextLabelID = "Label10";
            }
            else
            {
                Panel5.Visible = false;
                CollapsiblePanelExtender5.ExpandControlID = "";
                CollapsiblePanelExtender5.CollapseControlID = "";
                CollapsiblePanelExtender5.TextLabelID = "";
            }
            
            if(_StatFacilityReports.Count > 0)
            {
                grdStatFacility.DataSource = _StatFacilityReports;
                grdStatFacility.DataBind();
                Panel7.Visible = true;
                CollapsiblePanelExtender6.ExpandControlID = "Label12";
                CollapsiblePanelExtender6.CollapseControlID = "Label12";
                CollapsiblePanelExtender6.TextLabelID = "Label12";
            }
            else
            {
                Panel7.Visible = false;
                CollapsiblePanelExtender6.ExpandControlID = "";
                CollapsiblePanelExtender6.CollapseControlID = "";
                CollapsiblePanelExtender6.TextLabelID = "";
            }
           
            if(_StatProviderReports.Count > 0)
            {
                grdStatProvider.DataSource = _StatProviderReports;
                grdStatProvider.DataBind();
                Panel3.Visible = true;
                CollapsiblePanelExtender4.ExpandControlID = "Label8";
                CollapsiblePanelExtender4.CollapseControlID = "Label8";
                CollapsiblePanelExtender4.TextLabelID = "Label8";
            }
            else
            {
                Panel3.Visible = false;
                CollapsiblePanelExtender4.ExpandControlID = "";
                CollapsiblePanelExtender4.CollapseControlID = "";
                CollapsiblePanelExtender4.TextLabelID = "";
            }
            


            lnkAddReport.Visible = m_RequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_CAN_ADD_PORTAL_REPORT);
		}

		public bool CanEdit() 
		{
			return m_CanEdit;
		}

		#region Web Form Designer generated code
		override protected void OnInit(EventArgs e)
		{
			//
			// CODEGEN: This call is required by the ASP.NET Web Form Designer.
			//
			InitializeComponent();
			base.OnInit(e);
		}
		
		/// <summary>
		///		Required method for Designer support - do not modify
		///		the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{

		}
		#endregion

	    protected void Command_Click(object sender, CommandEventArgs e)
        {
            switch (e.CommandName)
            {
                case "GoToReport":
                    var pr = new PortalReportDAO(m_RequestManager).Load(Convert.ToInt32(e.CommandArgument));
                    
                    // Get the report path from the ReportServer.CATALOG table
                    if (pr.ReportItemID != Guid.Empty)
                    {
                        var ril = new ReportItemList(m_RequestManager).LoadItem(pr.ReportItemID.ToString());
                        Response.Redirect("~/WebPages/ReportView.aspx?&ReportName=" + Server.UrlEncode(ril.Path) + "&ReportUser=" + m_RequestManager.SessionManager.SignedOnUserProfileID, false);
                    }

                    break;
            } // End switch
        } // End Command_Click

        /// <summary>
        /// Handles the ItemDataBound event of the grd control.
        /// </summary>
        /// <param name="sender">The source of the event.</param>
        /// <param name="e">The <see cref="System.Web.UI.WebControls.DataListItemEventArgs"/> instance containing the event data.</param>
        protected void grdDocumentationImprovement_ItemDataBound(object sender, DataListItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            var lnkViewSpecs = e.Item.FindControl("lnkViewSpecs") as HyperLink;
            var pr = e.Item.DataItem as PortalReport;

            if (lnkViewSpecs == null || pr == null) return;

            lnkViewSpecs.Visible = m_CanEdit && pr.HasSpec;
            lnkViewSpecs.NavigateUrl = "~/WebPages/DownloadDocument.aspx?SpecId=" + pr.ReportItemID;
        }

        protected void grdInternal_ItemDataBound(object sender, DataListItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            var lnkViewSpecs = e.Item.FindControl("lnkViewSpecs") as HyperLink;
            var pr = e.Item.DataItem as PortalReport;

            if (lnkViewSpecs == null || pr == null) return;

            lnkViewSpecs.Visible = m_CanEdit && pr.HasSpec;
            lnkViewSpecs.NavigateUrl = "~/WebPages/DownloadDocument.aspx?SpecId=" + pr.ReportItemID;
        }

        protected void grdProductivity_ItemDataBound(object sender, DataListItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            var lnkViewSpecs = e.Item.FindControl("lnkViewSpecs") as HyperLink;
            var pr = e.Item.DataItem as PortalReport;

            if (lnkViewSpecs == null || pr == null) return;

            lnkViewSpecs.Visible = m_CanEdit && pr.HasSpec;
            lnkViewSpecs.NavigateUrl = "~/WebPages/DownloadDocument.aspx?SpecId=" + pr.ReportItemID;
        }

        protected void grdReconciliation_ItemDataBound(object sender, DataListItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            var lnkViewSpecs = e.Item.FindControl("lnkViewSpecs") as HyperLink;
            var pr = e.Item.DataItem as PortalReport;

            if (lnkViewSpecs == null || pr == null) return;

            lnkViewSpecs.Visible = m_CanEdit && pr.HasSpec;
            lnkViewSpecs.NavigateUrl = "~/WebPages/DownloadDocument.aspx?SpecId=" + pr.ReportItemID;
        }

        protected void grdStatFacility_ItemDataBound(object sender, DataListItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            var lnkViewSpecs = e.Item.FindControl("lnkViewSpecs") as HyperLink;
            var pr = e.Item.DataItem as PortalReport;

            if (lnkViewSpecs == null || pr == null) return;

            lnkViewSpecs.Visible = m_CanEdit && pr.HasSpec;
            lnkViewSpecs.NavigateUrl = "~/WebPages/DownloadDocument.aspx?SpecId=" + pr.ReportItemID;
        }

        protected void grdStatProvider_ItemDataBound(object sender, DataListItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;

            var lnkViewSpecs = e.Item.FindControl("lnkViewSpecs") as HyperLink;
            var pr = e.Item.DataItem as PortalReport;

            if (lnkViewSpecs == null || pr == null) return;

            lnkViewSpecs.Visible = m_CanEdit && pr.HasSpec;
            lnkViewSpecs.NavigateUrl = "~/WebPages/DownloadDocument.aspx?SpecId=" + pr.ReportItemID;
        }

        /// <summary>
        /// Handles the Click event of the lbViewSpecs control.
        /// </summary>
        /// <param name="sender">The source of the event.</param>
        /// <param name="e">The <see cref="System.EventArgs"/> instance containing the event data.</param>
        protected void lbViewSpecs_Click(object sender, EventArgs e)
        {
            var linkButton = sender as LinkButton;

            if (linkButton != null)
                Response.Redirect("~/WebPages/DownloadDocument.aspx?SpecId=" + linkButton.CommandArgument, false);
        }
	} // End Reports
} // End Portlets
