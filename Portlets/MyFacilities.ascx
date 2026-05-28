<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.MyFacilities" Codebehind="MyFacilities.ascx.cs" %>
<asp:Panel id="pnl" Runat=server>
<span class="PortalHeader">My Facilities</span>
<hr />
<asp:DataGrid id="grd" runat="server" AutoGenerateColumns="False" DataKeyField="FacilityID">
	<ItemStyle CssClass="ListRow1"></ItemStyle>
	<HeaderStyle CssClass="ColHeading"></HeaderStyle>
	<Columns>
		<asp:BoundColumn Visible="False" DataField="FacilityID"></asp:BoundColumn>
		<asp:BoundColumn Visible="False" DataField="Name"></asp:BoundColumn>
		<asp:ButtonColumn DataTextField="Name" HeaderText="Name" CommandName="Select"></asp:ButtonColumn>
	</Columns>
</asp:DataGrid>
</asp:Panel>