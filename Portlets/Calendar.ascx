<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.Calendar" Codebehind="Calendar.ascx.cs" %>
<asp:Panel id="pnl" runat="server">
	<span class="PortalHeader">Calendar</span>
	<hr />
	<asp:Calendar id="Calendar1" runat="server">
		<TitleStyle CssClass="ColHeading"></TitleStyle>
	</asp:Calendar>
</asp:Panel>
