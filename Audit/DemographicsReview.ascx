<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="DemographicsReview.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.DemographicsReview" %>
<table>
  <tr>
    <td>
      <asp:Panel runat="server" ID="pnlChartDemographicReview">
        <h3>Demographic Elements</h3>
        <br />
        <asp:DataGrid ID="grdChartDemographics" runat="server" CssClass="ListTable" AutoGenerateColumns="False" 
                      OnItemDataBound="grdChartDemographics_ItemDataBound">
          <ItemStyle CssClass="ListRow1"/>
          <HeaderStyle CssClass="ColHeading" Height="30px"/>
          <Columns>
            <%-- 0 --%>
            <asp:TemplateColumn HeaderText="Element" ItemStyle-HorizontalAlign="Left" HeaderStyle-HorizontalAlign="Left">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblElement"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 1 --%>
            <asp:TemplateColumn HeaderText="Previous Value" ItemStyle-HorizontalAlign="Left" HeaderStyle-HorizontalAlign="Left">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousValue"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 2 --%>
            <asp:TemplateColumn HeaderText="Auditor Value" ItemStyle-HorizontalAlign="Left" HeaderStyle-HorizontalAlign="Left">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorValue"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 3 --%>
            <asp:TemplateColumn HeaderText="Audit Action"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditActionDescription"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
          </Columns>
        </asp:DataGrid>
      </asp:Panel>
    </td>
  </tr>
  <tr>
    <td>
      <br />
      <asp:Label runat="server" Text="Auditor Comments (Demographics):"  CssClass="FieldLabel"/>
      <br />
      <asp:TextBox Rows="5" CssClass="StdInput" TextMode="MultiLine" MaxLength="500" Columns="70" 
                   ID="txtComment" onKeyUp="Count(this,500,'Chart Demographics')" onChange="Count(this,500,'Chart Demographics')"
                   runat="server"/>
    </td>
  </tr>
</table>
<asp:HiddenField ID="hdnAuditChange" runat="server" />