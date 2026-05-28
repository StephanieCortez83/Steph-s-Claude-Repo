namespace CCSWeb.WebPages.Controls.Portlets
{
	using CCSBusinessObjects.AppSystem;
	using CCSBusinessObjects.BusinessObjects;
	using System;

	public partial class Welcome : System.Web.UI.UserControl
	{
		#region internals

		private WebRequestManager _requestManager;

		#endregion internals

		#region events

		public void PreparePortlet(WebRequestManager requestManager)
		{
			_requestManager = requestManager;
			pnl.Visible = requestManager?.SessionManager?.SignedOnUserProfile?.HasRight(UserRight.RIGHT_PORTAL_WELCOME) == true;
		}

		protected void Page_Load(object sender, System.EventArgs e) =>
			tblICD10Link.Visible = _requestManager?.SessionManager?.SignedOnUserProfile?.HasRight(UserRight.RIGHT_ALLOW_ICD10_ADMIN) == true;

		#endregion events

		#region web Form Designer generated code

		override protected void OnInit(EventArgs e) =>
			base.OnInit(e);

		#endregion  web Form Designer generated code
	}
}
