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
	///		Summary description for Announcements.
	/// </summary>
	public partial class SystemInformation : System.Web.UI.UserControl
	{


		private WebRequestManager	m_RequestManager;
		private ArrayList			m_SystemInformation;
		private bool				m_CanEdit;

		public void PreparePortlet(WebRequestManager aRequestManager) 
		{
			m_RequestManager = aRequestManager;
			pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_SYSTEM_INFORMATION);
			m_SystemInformation = new SimpleSystemInformationListDAO(m_RequestManager).LoadAll();
			UserProfile signedOnUserProfile = m_RequestManager.SessionManager.SignedOnUserProfile;

			if (signedOnUserProfile != null) 
			{
				m_CanEdit = signedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_ADMINISTRATION);
			}
			else 
			{
				m_CanEdit = false;
			}
			lnkAddEvent.Visible = m_CanEdit;

			// If there are no system information events, post a notice that there are none.
			if (m_SystemInformation.Count == 0) 
			{
				PortalSystemInformation li = new PortalSystemInformation(m_RequestManager);
				li.PortalSystemInformationID = -1;
				li.Description = "There are no current system announcements.";
				li.ExpireDate = DateTime.Now;
				li.Title = "No current system announcements.";
				m_SystemInformation.Add(li);
			}

			grd.DataSource = m_SystemInformation;
			grd.DataBind();
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

	}
}
