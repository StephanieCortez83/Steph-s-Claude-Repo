namespace CCSWeb.WebPages.Controls.Portlets
{
	using CCSBusinessObjects.AppSystem;
	using CCSBusinessObjects.BusinessObjects;
	using CCSBusinessObjects.Common.Utility;
	using CCSBusinessObjects.DAO;
	using System;
	using System.Collections;


	/// <summary>
	///		Summary description for QuickLinks.
	/// </summary>
	public partial class QuickLinks : System.Web.UI.UserControl
	{
		#region Internals

		protected System.Web.UI.WebControls.LinkButton btnAddNew;

		private WebRequestManager	m_RequestManager;
		private ArrayList			m_QuickLinks;
		private bool				m_CanEdit;

		#endregion Internals

		public void PreparePortlet(WebRequestManager aRequestManager) 
		{
			m_RequestManager = aRequestManager;
			var signedOnUserProfile = m_RequestManager.SessionManager?.SignedOnUserProfile;
			pnl.Visible = signedOnUserProfile?.HasRight(UserRight.RIGHT_PORTAL_QUICK_LINKS) == true;

			if (!pnl.Visible)
				return;

			string cacheKey = $"QuickLinks_{(int)signedOnUserProfile?.UserProfileID}";
			var _cachingUtilities = new CachingUtilities(null);
			var cachedPayload = (ArrayList)null;

			try
			{
				cachedPayload = (ArrayList)_cachingUtilities.CachePull(cacheKey);
			}
			catch { } // do not care why it fails, we cannot have this causing a system error all of its own.  caching is not that important

			if (cachedPayload != null && cachedPayload.Count > 0)
				m_QuickLinks = cachedPayload;
			else
			{
				m_QuickLinks = new SimpleQuickLinksListDAO(m_RequestManager).LoadAllAuthorized();

				if (m_QuickLinks != null && m_QuickLinks.Count > 0)
					_cachingUtilities.CachePush(cacheKey, m_QuickLinks, CachingUtilities.CacheDurationHours_30Minutes);
			}

			m_CanEdit = false;
			if (signedOnUserProfile != null && signedOnUserProfile.UserProfileID > 0) 
				m_CanEdit = signedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_ADMINISTRATION);

			lnkAddQuickLink.Visible = m_CanEdit;

			grd.DataSource = m_QuickLinks;
			grd.DataBind();
		}

		public bool CanEdit() => m_CanEdit;

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
