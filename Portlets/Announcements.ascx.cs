using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.DAO;
using System;
using System.Collections.Generic;

namespace CCSWeb.WebPages.Controls.Portlets
{
	public partial class Announcements : System.Web.UI.UserControl
	{
		private WebRequestManager m_RequestManager;
		private IEnumerable<SimpleAnnouncementsListItem> m_Announcements;
		private bool m_CanEdit;

		public void PreparePortlet(WebRequestManager aRequestManager)
		{
			m_RequestManager = aRequestManager;
			pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_ANNOUNCEMENTS);
			m_Announcements = new SimpleAnnouncementsListDAO(m_RequestManager).LoadAll();
			var signedOnUserProfile = m_RequestManager.SessionManager.SignedOnUserProfile;

			if (signedOnUserProfile != null)
			{
				m_CanEdit = signedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_ADMINISTRATION);
			}
			else
			{
				m_CanEdit = false;
			}
			lnkAddEvent.Visible = m_CanEdit;

			grd.DataSource = m_Announcements;
			grd.DataBind();
		}

		public bool CanEdit()
		{
			return m_CanEdit;
		}

		#region web form designer generated code

		override protected void OnInit(EventArgs e)
		{
			InitializeComponent();
			base.OnInit(e);
		}

		private void InitializeComponent()
		{

		}

		#endregion
	}
}
