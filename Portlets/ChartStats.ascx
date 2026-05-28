<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.ChartStats" Codebehind="ChartStats.ascx.cs" %>
<asp:Panel id="pnl" runat="server">
    <link href="../Content/font-awesome.min.css" rel="stylesheet" />
	<span class="PortalHeader">Chart Stats&nbsp;
		<i class="fa fa-info-circle fs14" style="font-size:small; cursor: pointer;" data-toggle="tooltip" data-placement="top" title="Count field displays totals by assignment.  Week and Total fields show totals by Sign On."></i>
		<asp:Label ID="lblCachedIndicator" runat="server" Visible="false" style="font-size:small;" >*</asp:Label>
	</span>
	<hr />
	<asp:DataGrid id="grd" AutoGenerateColumns="False" runat="server">
		<ItemStyle CssClass="ListRow1"></ItemStyle>
		<HeaderStyle CssClass="ColHeading"></HeaderStyle>
		<Columns>
			<asp:BoundColumn DataField="Status" HeaderText="Status"></asp:BoundColumn>
			<asp:BoundColumn DataField="Count" HeaderText="Count"></asp:BoundColumn>
			<asp:BoundColumn DataField="CountPastWeek" HeaderText="Week"></asp:BoundColumn>
			<asp:BoundColumn DataField="CountToday" HeaderText="Today"></asp:BoundColumn>
		</Columns>
	</asp:DataGrid>
</asp:Panel>
