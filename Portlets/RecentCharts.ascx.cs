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

public partial class WebPages_Controls_Portlets_RecentCharts : System.Web.UI.UserControl
{
    private WebRequestManager m_RequestManager;

    public void PreparePortlet(WebRequestManager aRequestManager)
    {
        m_RequestManager = aRequestManager;
        pnl.Visible = aRequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_PORTAL_CHART_STATS);
        var m_RecentCharts = new SimpleRecentChartsListDAO(m_RequestManager).SelectMostRecentCharts();
        var keepers = new ArrayList();
        foreach (SimpleRecentChartsListItem li in m_RecentCharts)
        {
            AddIfUnique(keepers, li);
            if (keepers.Count > 4)
            {
                break;
            }
        }

        grd.DataSource = keepers;
        grd.DataBind();

		pnlRecentChartsACSChartId.Visible = m_RequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.DEBUG_MESSAGING);
	}

    private void AddIfUnique(ArrayList keepers, SimpleRecentChartsListItem newone)
    {
        bool found = false;
        foreach (SimpleRecentChartsListItem li in keepers)
        {
            if (li.ChartID == newone.ChartID)
            {
                found = true;
                break;
            }
        }
        if (!found)
        {
            keepers.Add(newone);
        }
    }

    protected void btnRecentChartsACSChartId_Click(object sender, EventArgs e)
    {
		lblRecentChartsACSChartIdErrors.Visible = false;
		lblRecentChartsACSChartIdErrors.Text = string.Empty;

		if (!int.TryParse(txtACSChartId.Text, out var searchACSChartId)) searchACSChartId = -1;

        if (searchACSChartId > 0 
            && m_RequestManager != null
            && new ChartDAO(m_RequestManager)?.ChartExists(searchACSChartId) == true)
			Response.Redirect($"ShowChart.aspx?ChartID={searchACSChartId}");

		txtACSChartId.Text = string.Empty;
        lblRecentChartsACSChartIdErrors.Text = "ACS CID not found or not authorized.";
		lblRecentChartsACSChartIdErrors.Visible = true;
	}
}
