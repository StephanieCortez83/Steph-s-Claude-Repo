<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.Documents" Codebehind="Documents.ascx.cs" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajx" %>
<%@ Register TagPrefix="uc1" TagName="DateField" Src="../DateField.ascx" %>
<script runat="server">
	string ChooseURL(string itemID, string URL)
	{
		return "../../EditDocuments.aspx?ItemID=" + itemID.ToString() ;
	}
</script>

<asp:Panel ID="pnl" runat="server">
  <span class="PortalHeader">Documents</span>&nbsp;&nbsp;
  <asp:HyperLink ID="lnkAddDocument" runat="server" CssClass="CommandButton" NavigateUrl="../../EditDocuments.aspx?ItemID=-1">Add Document</asp:HyperLink>
  <hr />
  <div class="AJAXCalendar">
    <asp:Label ID="Label1" CssClass="RequiredFieldLabel" runat="server">Date:</asp:Label>
    <uc1:DateField ID="txtFromDate" runat="server" ValidateRange="true" ShowValidatorCallout="true"
      Required="true" />
    <asp:Label ID="Label2" CssClass="RequiredFieldLabel" runat="server">To:</asp:Label>
    <uc1:DateField ID="txtToDate" runat="server" ValidateRange="true" ShowValidatorCallout="true"
      Required="true" />
    <asp:Label ID="Label3" CssClass="RequiredFieldLabel" runat="server">Facility:</asp:Label>
    <asp:DropDownList ID="cmbFacilities" CssClass="StdInput" runat="server">
    </asp:DropDownList>
    <asp:Button ID="btnSubmit" CssClass="StdButton" runat="server" Text="Search" OnClick="btnSubmit_Click">
    </asp:Button>
  </div>
  <div id="divDocumentGridData" style="overflow:hidden; overflow-y: scroll; max-height: 200px;">
  <asp:DataGrid ID="grd" runat="server" AutoGenerateColumns="False" DataKeyField="PortalDocumentID"
    GridLines="None" ShowHeader="False">
    <ItemStyle CssClass="ListRow1 noborder"></ItemStyle>
    <HeaderStyle CssClass="ColHeading"></HeaderStyle>
    <Columns>
      <asp:TemplateColumn>
        <ItemTemplate>
          <asp:HyperLink runat="server" Text="Edit" Visible='<%# CanEdit()%>' NavigateUrl='<%# "../../EditDocuments.aspx?ItemID=" + DataBinder.Eval(Container.DataItem,"PortalDocumentID")  %>' />
          <span class="PortalItemTitle">
            <asp:HyperLink ID="Hyperlink1" NavigateUrl='<%# DataBinder.Eval(Container.DataItem,"URL")  %>' runat="server">
    				  <%# Server.HtmlEncode(Eval("Title").ToString()) %>
            </asp:HyperLink>
            <em>-<%# DataBinder.Eval(Container.DataItem,"FormattedContentSize") %> bytes.</em>
          </span>
          &nbsp;&nbsp;&nbsp;&nbsp;
          <span class="PortalNormal">
            <em><%# DataBinder.Eval(Container.DataItem,"DatePosted") %></em>
          </span>
          <br />
          <span class="PortalNormal">
            <%# Server.HtmlEncode(DataBinder.Eval(Container.DataItem,"Description").ToString()) %>
          </span>
          <br />
        </ItemTemplate>
      </asp:TemplateColumn>
    </Columns>
  </asp:DataGrid>
  </div>
</asp:Panel>
