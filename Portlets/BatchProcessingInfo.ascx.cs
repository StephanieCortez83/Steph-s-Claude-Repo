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
	///		Summary description for FacilityFileDownloads.
	/// </summary>
	public partial class BatchProcessingInfo : System.Web.UI.UserControl
	{
		private WebRequestManager	m_RequestManager;

		protected ArrayList			m_BatchLogList;
		protected BatchLogSearchCriteria m_SearchCriteria;
        protected ArrayList m_FacilitiesList;


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
			pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_BATCH_PROCESSING);
            Page.Form.DefaultButton = btnSubmit.UniqueID;
			if (!IsPostBack) 
			{
                SimpleFacilitiesListDAO sflDAO = new SimpleFacilitiesListDAO(m_RequestManager);
                m_FacilitiesList = sflDAO.LoadAllAuthorized(Convert.ToInt32(m_RequestManager.SessionManager.SignedOnUserProfileID));


                cmbFacilities.Items.Clear();
                cmbFacilities.SelectedValue = null;
                cmbFacilities.DataSource = m_FacilitiesList;
                cmbFacilities.DataTextField = "Name";
                cmbFacilities.DataValueField = "FacilityID";
                cmbFacilities.DataBind();
                cmbFacilities.Items.Insert(0,new ListItem("[All]","-1"));
                cmbFacilities.SelectedValue = "-1";

				SetView(DateTime.Now.ToShortDateString(),DateTime.Now.AddDays(1).ToShortDateString(), BatchLogItem.ERROR_CODE_SEVERE);
			}
		}

		private void SetView(String fromDate, String toDate, int errorLevel) 
		{
			m_SearchCriteria = new BatchLogSearchCriteria();
			m_SearchCriteria.DateFromStr = fromDate;
			m_SearchCriteria.DateToStr = toDate;
			m_SearchCriteria.ErrorCode = errorLevel;
            m_SearchCriteria.FacilityID = Convert.ToInt32(cmbFacilities.SelectedValue);
            m_SearchCriteria.ProcessID = cmbProcess.SelectedValue;

			txtStartDate.Text = fromDate;
            txtEndDate.Text = toDate;

			m_BatchLogList = new LogDAO(m_RequestManager).LoadAllGivenCriteria(m_SearchCriteria);

			cmbErrorLevel.SelectedValue = errorLevel.ToString();

			grd.DataSource = m_BatchLogList;
			grd.DataBind();
		}

		private void grd_ItemCommand(object source, System.Web.UI.WebControls.DataGridCommandEventArgs e)
		{
			switch(((LinkButton)e.CommandSource).CommandName)
			{
				case "Select":
					int itemID = Convert.ToInt32(grd.DataKeys[e.Item.ItemIndex]);
					break;
				default:
					break;
			}
		}

		protected void btnSubmit_Click(object sender, System.EventArgs e)
		{
			DateTime fromDate;
			DateTime toDate;
			// Attempt to use the date provided.  If it fails, just convert what was entered
			// to today's date
			try 
			{
				fromDate = Convert.ToDateTime(txtStartDate.Text);
                toDate = Convert.ToDateTime(txtEndDate.Text);
			}
			catch (Exception) 
			{
				fromDate = DateTime.Now;
				toDate = fromDate.AddDays(1);
				txtStartDate.Text = fromDate.ToShortDateString();  // Repair date entered by user
                txtEndDate.Text = toDate.ToShortDateString();
			}


			SetView(fromDate.ToShortDateString(), toDate.ToShortDateString(), Convert.ToInt32(cmbErrorLevel.SelectedValue));
		}

	}
}
