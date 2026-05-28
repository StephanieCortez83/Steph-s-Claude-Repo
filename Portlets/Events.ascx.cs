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
	///		Summary description for Events.
	/// </summary>
	public partial class Events : System.Web.UI.UserControl
	{

		private WebRequestManager	m_RequestManager;


		private ArrayList			m_Events;
		private bool				m_CanEdit;

		public void PreparePortlet(WebRequestManager aRequestManager) 
		{
			m_RequestManager = aRequestManager;
			pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_EVENTS);
			m_Events = new SimpleEventsListDAO(m_RequestManager).LoadAll();

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
			grd.DataSource = m_Events;
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
