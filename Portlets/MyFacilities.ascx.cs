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
	///		Summary description for QuickLinks.
	/// </summary>
	public partial class MyFacilities : System.Web.UI.UserControl
	{
		private WebRequestManager	m_RequestManager;


		private ArrayList			m_Facilities;

		public void PreparePortlet(WebRequestManager aRequestManager) 
		{
			m_RequestManager = aRequestManager;
			pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_MY_FACILITIES);
			m_Facilities = new SimpleFacilitiesListDAO(m_RequestManager).LoadAllAuthorized(Convert.ToInt32(m_RequestManager.SessionManager.SignedOnUserProfileID));
			grd.DataSource = m_Facilities;
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
			this.grd.ItemCommand += new System.Web.UI.WebControls.DataGridCommandEventHandler(this.grd_ItemCommand);

		}
		#endregion

		private void grd_ItemCommand(object source, System.Web.UI.WebControls.DataGridCommandEventArgs e)
		{
			switch(((LinkButton)e.CommandSource).CommandName)
			{
				case "Select":
					int itemID = Convert.ToInt32(grd.DataKeys[e.Item.ItemIndex]);
					SelectItem(itemID);
					break;
				default:
					break;
			}
		}

		void SelectItem(int itemID)
		{		
			m_RequestManager.SessionManager.SelectedFacilityID = itemID.ToString();
			Response.Redirect("FacilityView.aspx",false);
		}

	}
}
