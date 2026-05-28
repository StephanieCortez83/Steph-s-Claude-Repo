<%@ Control Language="C#" AutoEventWireup="true" Inherits="WebPages_Controls_Portlets_RecentCharts" Codebehind="RecentCharts.ascx.cs" %>
<asp:Panel ID="pnl" Runat="server"><span class="PortalHeader">Recent Charts</span>&nbsp;&nbsp; 
<hr />
<asp:datalist id="grd" runat="server" cellpadding="4" width="100%" enableviewstate="false" DataKeyField="ChartID">
		<itemtemplate>
			<span class="Normal">			
				<asp:HyperLink ID="HyperLink1" 	navigateurl='<%# DataBinder.Eval(Container.DataItem,"Url") %>' runat="server" >
					<%# DataBinder.Eval(Container.DataItem,"AccessInfoLine1") %>
				</asp:HyperLink>
                <br /><span class="Normal"><asp:Label ID="Label1" runat="server" Text='<%# DataBinder.Eval(Container.DataItem,"AccessInfoLine2") %>' /></span>
			</span>						
			<br />
		</itemtemplate>
	</asp:datalist>
	
	<asp:Panel ID="pnlRecentChartsACSChartId" runat="server">
		<div id="divRecentChartsACSChartId">
			<br />
			<asp:TextBox ID="txtACSChartId" runat="server" CssClass="StdInput" MaxLength="20" Columns="20" ToolTip="Enter numeric ACS Chart Id.  ex. 12349876"></asp:TextBox>
			<ajx:FilteredTextBoxExtender ID="FilteredTextBoxExtender4" runat="server" TargetControlID="txtACSChartId" FilterType="Numbers"></ajx:FilteredTextBoxExtender>
			<asp:Button ID="btnRecentChartsACSChartId" ClientIDMode="Static" runat="server" UseSubmitBehavior="False" OnClick="btnRecentChartsACSChartId_Click" Text="ACS CID Search" />
			<p style="color:red"><asp:Label ID="lblRecentChartsACSChartIdErrors" runat="server" Text="" ></asp:Label></p>
		</div>
	</asp:Panel>
</asp:Panel>