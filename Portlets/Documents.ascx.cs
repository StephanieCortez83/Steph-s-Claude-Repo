namespace CCSWeb.WebPages.Controls.Portlets
{
	using System;
	using System.Data;
	using System.Drawing;
	using System.Web;
	using System.Web.UI.WebControls;
	using System.Web.UI.HtmlControls;
	using System.Collections;
	using CCSBusinessObjects.BusinessObjects;
	using CCSBusinessObjects.AppSystem;
	using CCSBusinessObjects.DAO;
	using System.Resources;
	using System.Globalization;
	using System.Web.Security;


	/// <summary>
	///		Summary description for Documents.
	/// </summary>
	public partial class Documents : System.Web.UI.UserControl
	{

		private WebRequestManager	m_RequestManager;
		private ArrayList			m_Documents;
		private bool				m_CanEdit;
        protected ArrayList         m_FacilitiesList;
        //private ArrayList m_Facilities;
        protected TransmissionBatchSearchCriteria m_SearchCriteria;

		public void PreparePortlet(WebRequestManager aRequestManager) 
		{
			m_RequestManager = aRequestManager;
			pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_DOCUMENTS);
            
            if (!IsPostBack)
            {
                SimpleFacilitiesListDAO sflDAO = new SimpleFacilitiesListDAO(m_RequestManager);
                m_FacilitiesList = sflDAO.LoadAllAuthorized(m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID);
                cmbFacilities.Items.Clear();
                cmbFacilities.SelectedValue = null;
                cmbFacilities.DataSource = m_FacilitiesList;
                cmbFacilities.DataTextField = "Name";
                cmbFacilities.DataValueField = "FacilityID";
                cmbFacilities.DataBind();
                cmbFacilities.Items.Insert(0, new ListItem("[All]", "-1"));

                SetView(-1, "1/1/1990", DateTime.Now.ToShortDateString());

                // Attribute added to date textbox to handle users entering a two-digit year
                //txtFromDate.Attributes.Add("onblur", "validateYear(this);");
                //txtToDate.Attributes.Add("onblur", "validateYear(this);");
            }

		}

		public bool CanEdit() 
		{
			return m_CanEdit;
		}

        private void SetView(int facilityID, String fromDate, String toDate)
        {
            // Clean out all expired documents
            PortalDocumentDAO dao = new PortalDocumentDAO(m_RequestManager);
            dao.DeleteAllExpired();

            txtFromDate.Text = fromDate;
            txtToDate.Text = toDate;
            cmbFacilities.SelectedValue = facilityID.ToString();

            m_Documents = dao.LoadAllVisibleToSignedOnUserGivenCriteria(facilityID, fromDate, toDate);

            UserProfile signedOnUserProfile = m_RequestManager.SessionManager.SignedOnUserProfile;

            if (signedOnUserProfile != null)
            {
                m_CanEdit = signedOnUserProfile.HasRight(UserRight.RIGHT_ALLOW_ADD_PORTAL_DOCUMENT);
            }
            else
            {
                m_CanEdit = false;
            }
            lnkAddDocument.Visible = m_CanEdit;
            grd.DataSource = m_Documents;
            grd.DataBind();
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

		private void btnDeleteExpired_Click(object sender, System.EventArgs e)
		{
		}

        protected void btnSubmit_Click(object sender, EventArgs e)
        {
            DateTime fromDate;
            DateTime toDate;
            // Attempt to use the date provided.  If it fails, just convert what was entered
            // to today's date
            try
            {
                fromDate = Convert.ToDateTime(txtFromDate.Text);

                // If date entered by user is not a valid SQL date, default in today's date.
                if (!fromDate.IsValidSqlDateTime())
                {
                    fromDate = DateTime.Now;
                }
            }
            catch (Exception)
            {
                fromDate = DateTime.Now;
                txtFromDate.Text = fromDate.ToShortDateString();  // Repair date entered by user
            }
            try
            {
                toDate = Convert.ToDateTime(txtToDate.Text);

                // If date entered by user is not a valid SQL date, default in today's date.
                if (!toDate.IsValidSqlDateTime())
                {
                    toDate = DateTime.Now;
                }
            }
            catch (Exception)
            {
                toDate = DateTime.Now;
                txtToDate.Text = toDate.ToShortDateString();  // Repair date entered by user
            }

            SetView(Convert.ToInt32(cmbFacilities.SelectedValue), fromDate.ToShortDateString(), toDate.ToShortDateString());

        }
}
}
