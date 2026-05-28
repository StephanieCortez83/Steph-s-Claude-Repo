<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.Announcements" Codebehind="Announcements.ascx.cs" %>

<asp:Panel id="pnl" runat="server">
	<span class="PortalHeader">Announcements</span>

	<asp:HyperLink 
		id="lnkAddEvent" 
		runat="server" 
		NavigateUrl="../../EditAnnouncements.aspx?ItemID=-1"  
		CssClass="CommandButton" >
		
		Add Announcement
	</asp:HyperLink>

	<hr />

	<asp:DataList id="grd" runat="server" EnableViewState="false" Width="98%" CellPadding="4">
		<ItemTemplate>
			<span class="PortalItemTitle">
				<asp:HyperLink 
					id="editLink" 
					ImageUrl="../../images/edit.gif" 
					Text="Edit" 
					Visible='<%# CanEdit()%>'  
					NavigateUrl='<%# "../../EditAnnouncements.aspx?ItemID=" + DataBinder.Eval(Container.DataItem,"PortalAnnouncementID")  %>' 
					runat="server" />

				<%# DataBinder.Eval(Container.DataItem,"Title").ToString() %>
			</span>

			<br />

			<span class="PortalNormal">
				<%# DataBinder.Eval(Container.DataItem,"Description").ToString() %>
				&nbsp;
				<asp:HyperLink 
					id="moreLink" 
					NavigateUrl='<%# DataBinder.Eval(Container.DataItem,"MoreLink") %>' 
					Visible='false' 
					runat="server">
					read more...
				</asp:HyperLink>
			</span>
		
			<br />
		</ItemTemplate>
	</asp:DataList>
</asp:Panel>
