<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="MedicalNecessityReview.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.MedicalNecessityReview" %>
<table>
  <tr>
    <td width="50%" >
      <asp:Panel runat="server" ID="pnlChartMedicalNecessityReview">
        <h3>Medical Necessity</h3>
        <br />
        <asp:DataGrid ID="grdChartMedicalNecessity" runat="server" CssClass="ListTable" AutoGenerateColumns="False" 
                      OnItemDataBound="grdChartMedicalNecessity_ItemDataBound">
          <ItemStyle CssClass="ListRow1"/>
          <HeaderStyle CssClass="ColHeading" Height="30px"/>
          <Columns>
            <%-- 0 --%>
            <asp:TemplateColumn HeaderText="Element" ItemStyle-Width="120px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblElement"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 1 --%>
            <asp:TemplateColumn HeaderText="As Sent" ItemStyle-Width="120px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousValue"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 2 --%>
            <asp:TemplateColumn HeaderText="Auditor" ItemStyle-Width="120px" ItemStyle-HorizontalAlign="Center">
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
      <asp:Label ID="lblMedicalNecessityComment" runat="server" Text="Auditor Comments (Medical Necessity):"  CssClass="FieldLabel"></asp:Label>
      <br />
      <asp:TextBox Rows="5" CssClass="StdInput" TextMode="MultiLine" MaxLength="500" Columns="70" 
                   ID="txtComment" onKeyUp="Count(this,500,'Chart Medical Necessity')" onChange="Count(this,500,'Chart Medical Necessity')"
                   runat="server"></asp:TextBox>
    </td>
  </tr>
</table>
<asp:HiddenField ID="hdnAuditChange" runat="server" />