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
	using CCSBusinessObjects.Common.Utility;

	/// <summary>
	///		Summary description for ChartStats.
	/// </summary>
	public partial class ChartStats : System.Web.UI.UserControl
	{

		private WebRequestManager	m_RequestManager;

		private ArrayList			m_ChartStats;

		public void PreparePortlet(WebRequestManager aRequestManager) 
		{
			m_RequestManager = aRequestManager;

			if (pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_CHART_STATS))
			{
				var chartStatsCachedKey = $"ChartStatistics_{aRequestManager.SessionManager.SignedOnUserProfile.UserProfileID}"; 
				var _cachingUtilities = new CachingUtilities(null);
				m_ChartStats = (ArrayList)_cachingUtilities.CachePull(chartStatsCachedKey);

				lblCachedIndicator.Visible = !(m_ChartStats == null || m_ChartStats.Count <= 0);

				if (!lblCachedIndicator.Visible)
				{
					m_ChartStats = new ChartsStatsListDAO(m_RequestManager).LoadAllForUser(Convert.ToInt32(m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID));
					if(m_ChartStats != null && m_ChartStats.Count > 0)
					{
						int countTotal = 0,
							countPastWeek = 0,
							countToday = 0;

						foreach (ChartsStatsListItem item in m_ChartStats)
						{
							countTotal += item.Count;
							countPastWeek += item.CountPastWeek;
							countToday += item.CountToday;
						}

						m_ChartStats.Add(new ChartsStatsListItem()
						{
							Status = "Totals",
							Count = countTotal,
							CountPastWeek = countPastWeek,
							CountToday = countToday,
						});

						_cachingUtilities.CachePush(chartStatsCachedKey, m_ChartStats, CachingUtilities.CacheDurationHours_1Hour * 0.5);
					}
				}

				if (m_ChartStats == null || m_ChartStats.Count <= 0)
					pnl.Visible = false;
				else
				{
					grd.DataSource = m_ChartStats;
					grd.DataBind();
					pnl.Visible = true;
				}
			}
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
