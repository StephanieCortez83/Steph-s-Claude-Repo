<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.Events" Codebehind="Events.ascx.cs" %>
<asp:Panel ID="pnl" Runat="server">
	<span class="PortalHeader">Events</span>
	<asp:HyperLink id=lnkAddEvent NavigateUrl="../../EditEvents.aspx?ItemID=-1" CssClass="CommandButton" runat="server">Add Event</asp:HyperLink>
	<hr />
	<asp:DataList id="grd" runat="server" CellPadding="4" Width="98%" EnableViewState="false">
		<ItemTemplate>
			<span class="PortalItemTitle">
				<asp:HyperLink id="editLink" ImageUrl="../../images/edit.gif" Text="Edit" Visible='<%# CanEdit()%>' NavigateUrl='<%# "../../EditEvents.aspx?ItemID=" + DataBinder.Eval(Container.DataItem,"PortalEventID") %>' runat="server" />
				<asp:Label Text='<%# Server.HtmlEncode(DataBinder.Eval(Container.DataItem,"Title").ToString()) %>' runat="server" ID="Label1"/>
			</span>
			<br />
			<span class="PortalNormal"><em>
					<%# Server.HtmlEncode(DataBinder.Eval(Container.DataItem,"WhereWhen").ToString()) %>
				</em></span>
			<br />
			<span class="PortalNormal">
				<%# Server.HtmlEncode(DataBinder.Eval(Container.DataItem,"Description").ToString()) %>
			</span>
			<br />
		</ItemTemplate>
	</asp:DataList>
</asp:Panel>
