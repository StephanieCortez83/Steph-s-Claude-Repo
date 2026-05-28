<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.QuickLinks" Codebehind="QuickLinks.ascx.cs" %>
<script runat="server">
	string ChooseURL(string itemID, string URL)
	{
		return "../../EditLinks.aspx?ItemID=" + itemID.ToString() ;
	}
</script>
<asp:Panel ID="pnl" Runat="server"><span class="PortalHeader">Quick Links</span>&nbsp;&nbsp; 
<asp:HyperLink id="lnkAddQuickLink" runat="server" NavigateUrl="../../EditLinks.aspx?ItemID=-1"
		CssClass="CommandButton">Add Link</asp:HyperLink>
<hr />
  <div id="divQuickLinksGridData" style="overflow:hidden; overflow-y: scroll; max-height: 380px;">
    <asp:DataList id="grd" runat="server" cellpadding="4" width="100%" enableviewstate="false">
		<ItemTemplate>
			<span class="Normal">
				<asp:HyperLink id="editLink" ImageUrl="../../images/edit.gif" Text="Edit" NavigateUrl='<%# ChooseURL(Convert.ToString(DataBinder.Eval(Container.DataItem,"PortalLinkID")), (string)DataBinder.Eval(Container.DataItem,"Url")) %>' Visible='<%# CanEdit()%>' runat="server" />
				<asp:HyperLink NavigateUrl='<%# Server.HtmlEncode(DataBinder.Eval(Container.DataItem,"Url").ToString()) %>' Target='<%# DataBinder.Eval(Container.DataItem,"DisplayOption") %> ' runat="server">
				  <%# Server.HtmlEncode(DataBinder.Eval(Container.DataItem,"Title").ToString()) %>
				</asp:HyperLink>
			</span>
			<br />
		</ItemTemplate>
	</asp:DataList>
  </div>
</asp:Panel>
