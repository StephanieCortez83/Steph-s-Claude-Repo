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
    using CCSBusinessObjects.Utility;
	using System.Resources;
	using System.Globalization;
	using System.Web.Security;

	/// <summary>
	///		Summary description for FacilityFileDownloads.
	/// </summary>
	public partial class FacilityFileDownloads : System.Web.UI.UserControl
	{
		private WebRequestManager	m_RequestManager;

		protected ArrayList			m_TransmissionBatchList;
		protected TransmissionBatchSearchCriteria m_SearchCriteria;
        protected ArrayList         m_FacilitiesList;


		private ArrayList			m_Facilities;

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
			this.grd.ItemCommand += new System.Web.UI.WebControls.DataGridCommandEventHandler(this.grd_ItemCommand);

		}
		#endregion

		public void PreparePortlet(WebRequestManager aRequestManager)
		{
			m_RequestManager = aRequestManager;
			pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_FACILITY_FILE_DOWNLOADS);

			
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

				SetView(-1,DateTime.Now.ToShortDateString(),DateTime.Now.ToShortDateString());

                // Attribute added to date textbox to handle users entering a two-digit year
                //txtFromDate.Attributes.Add("onblur", "validateYear(this);");
                //txtToDate.Attributes.Add("onblur", "validateYear(this);");
			}
		}

		private void SetView(int facilityID, String fromDate, String toDate) 
		{
			m_Facilities = new SimpleFacilitiesListDAO(m_RequestManager).LoadAllAuthorized(m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID);

            m_SearchCriteria = new TransmissionBatchSearchCriteria();
            m_SearchCriteria.FacilityID = facilityID;
            m_SearchCriteria.TransmissionDateFromStr = fromDate;
            m_SearchCriteria.TransmissionDateToStr = toDate;

            if (facilityID == -1)
            {
                m_SearchCriteria.Facilities = m_Facilities;
            }
            txtFromDate.Text = fromDate;
            txtToDate.Text = toDate;
            cmbFacilities.SelectedValue = facilityID.ToString();

            m_TransmissionBatchList = new TransmissionBatchFileListDAO(m_RequestManager).LoadAllGivenCriteria(m_SearchCriteria);
            grd.DataSource = m_TransmissionBatchList;
            grd.DataBind();
		}

		private void grd_ItemCommand(object source, System.Web.UI.WebControls.DataGridCommandEventArgs e)
		{
			switch(((LinkButton)e.CommandSource).CommandName)
			{
				case "Select":
					DataGridItem item = e.Item;
					int transmissionBatchID = Convert.ToInt32(item.Cells[0].Text);
					int transmissionBatchFileID = Convert.ToInt32(item.Cells[1].Text);
					DownloadFile(transmissionBatchID, transmissionBatchFileID);
					break;
				default:
					break;
			}
		}

        void DownloadFile(int transmissionBatchID, int transmissionBatchFileID)
        {
            // Get the file data
            TransmissionBatch batch = new TransmissionBatch(transmissionBatchID, m_RequestManager);
            TransmissionBatchFile batchFile = new TransmissionBatchFile(transmissionBatchFileID, m_RequestManager);

            ServiceAgreementDAO saDAO = new ServiceAgreementDAO(m_RequestManager);
            ServiceAgreement sa = saDAO.Load(batch.ServiceAgreementID);

            String fileName = batchFile.FileName;
            String contentType = batchFile.MIMEType;

            // Stream it back to the browser
            this.Response.Clear(); 
            this.Response.AddHeader("Content-disposition", "attachment; filename=" + fileName);
            this.Response.Expires = 0;
            this.Response.ContentType = contentType;

            if (batchFile.ContentSize > 0)
            {
                this.Response.OutputStream.Write(batchFile.Contents, 0, batchFile.ContentSize);
            }

            //			this.Response.Write(batchFile.FileData);
            this.Response.End();
        }

		protected void btnSubmit_Click(object sender, System.EventArgs e)
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

			SetView(Convert.ToInt32(cmbFacilities.SelectedValue),fromDate.ToShortDateString(), toDate.ToShortDateString());
		}
	}
}
