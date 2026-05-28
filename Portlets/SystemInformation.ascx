<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.SystemInformation" Codebehind="SystemInformation.ascx.cs" %>
<asp:Panel id="pnl" runat="server">
<span class="PortalHeader">System Information</span>
<asp:HyperLink id="lnkAddEvent" runat="server" NavigateUrl="../../EditSystemInformation.aspx?ItemID=-1"  
	CssClass="CommandButton" >Add System Information</asp:HyperLink>
<hr />
<asp:DataList id="grd" runat="server" EnableViewState="false" Width="98%" CellPadding="4">
	<ItemTemplate>
		<span class="PortalItemTitle">
			<asp:HyperLink id="editLink" ImageUrl="../../images/edit.gif" Text="Edit" Visible='<%# CanEdit()%>'  NavigateUrl='<%# "../../EditSystemInformation.aspx?ItemID=" + DataBinder.Eval(Container.DataItem,"PortalSystemInformationID")  %>' runat="server" />
			<%# Server.HtmlEncode(DataBinder.Eval(Container.DataItem,"Title").ToString()) %>
		</span>
		<br />
		<span class="PortalNormal">
			<%# Server.HtmlEncode(DataBinder.Eval(Container.DataItem,"Description").ToString()) %>
		</span>
		<br />
	</ItemTemplate>
</asp:DataList>
</asp:Panel>
