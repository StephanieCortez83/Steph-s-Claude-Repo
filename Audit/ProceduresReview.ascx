<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="ProceduresReview.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.ProceduresReview" %>
<%@ Import Namespace="ACS.Core.Extensions" %>
<table>
  <tr>
    <td width="50%" >
      <asp:Panel runat="server" ID="pnlProcedures">
        <h3><%= ChartAuditSectionTypeCode.GetDisplayName() %></h3>
        <br />
        <asp:DataGrid ID="grdProcedures" runat="server" CssClass="ListTable" AutoGenerateColumns="False" OnItemDataBound="grdProcedures_OnItemDataBound"
                      AllowPaging="False" Width="100%">
          <ItemStyle CssClass="ListRow1" HorizontalAlign="Center" VerticalAlign="Middle"/>
          <HeaderStyle CssClass="ColHeading"  Height="30px"/>
          <Columns>
            <%-- 0 --%>
            <asp:BoundColumn DataField="Id" Visible="false"/>
            <%-- 1 --%>
            <asp:TemplateColumn HeaderText="Previous Code"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousCptCode"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 2 --%>
            <asp:TemplateColumn HeaderText="Previous Provider"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousProvider"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 3 --%>
            <asp:TemplateColumn HeaderText="Previous Units"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousQuantity"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 4 --%>
            <asp:TemplateColumn HeaderText="Previous Modifier"  ItemStyle-Width="75px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousModifier"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 5 --%>
            <asp:TemplateColumn HeaderText="Previous DOS"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousDateOfService"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 6 --%>
            <asp:TemplateColumn HeaderText="Previous Dept" ItemStyle-Width="100px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousDept"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 7 --%>
            <asp:TemplateColumn HeaderText="Audit Code"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorCptCode"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 8 --%>
            <asp:TemplateColumn HeaderText="Audit Provider"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorProvider"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 9 --%>
            <asp:TemplateColumn HeaderText="Audit Units"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorQuantity"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 10 --%>
            <asp:TemplateColumn HeaderText="Audit Modifier"  ItemStyle-Width="80px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorModifier"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 11 --%>
            <asp:TemplateColumn HeaderText="Audit DOS"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorDateOfService"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 12 --%>
            <asp:TemplateColumn HeaderText="Audit Dept" ItemStyle-Width="100px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorDept"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 13 --%>
            <asp:TemplateColumn HeaderText="Audit Action"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditActionDescription"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 14 --%>
            <asp:BoundColumn DataField="ExcludeFromQA" Visible="false"/>
          </Columns>
        </asp:DataGrid>
      </asp:Panel>
    </td>
  </tr>
  <tr runat="server" id="pnlComments">
    <td>
      <br />
      <asp:Label runat="server" CssClass="FieldLabel"> Auditor Comments (<%= ChartAuditSectionTypeCode.GetDisplayName() %>): </asp:label>
      <br />
      <asp:TextBox Rows="5" CssClass="StdInput" TextMode="MultiLine" MaxLength="500" Columns="70"
                   ID="txtComment" onKeyUp="Count(this,500,'Procedures')"
                   onChange="Count(this,500,'Procedures')" runat="server"/>
    </td>
  </tr>
</table>
<asp:HiddenField ID="hdnAuditChange" runat="server" />