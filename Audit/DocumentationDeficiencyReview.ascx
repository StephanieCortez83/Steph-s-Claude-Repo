<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="DocumentationDeficiencyReview.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.DocumentationDeficiencyReview" %>
<table>
  <tr runat="server"  id="pnlDocumentationDeficiencyCoder">
    <td width="50%" >
      <asp:Panel runat="server" ID="pnlDocumentationDeficiency">
        <h3>Documentation Deficiency</h3>
        <br />
        <asp:DataGrid ID="grdDocumentationInequity" runat="server" CssClass="ListTable" AutoGenerateColumns="False"  OnItemDataBound="grdDocumentationInequity_ItemDataBound"
                      AllowPaging="False"  Width="100%">
          <ItemStyle CssClass="ListRow1"/>
          <HeaderStyle CssClass="ColHeading" Height="30px"/>
          <Columns>
            <%-- 0 --%>
            <asp:BoundColumn DataField="Id" Visible="false"/>
            <%-- 1 --%>
            <asp:TemplateColumn HeaderText="Documentation Item" ItemStyle-HorizontalAlign="Left">
              <ItemTemplate>
                <asp:Label Enabled="false" runat="server" ID="lblDocumentationItem"/>
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 2 --%>
            <asp:TemplateColumn HeaderText="As Sent" ItemStyle-Width="60px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="False" runat="server" id="lblPreviousDocumentationItemChecked"/>
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 3 --%>
            <asp:TemplateColumn HeaderText="From Auditor" ItemStyle-Width="60px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="False" runat="server" id="lblCurrentDocumentationItemChecked"/>
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 4 --%>
            <asp:TemplateColumn HeaderText="Audit Action" ItemStyle-Width="60px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="False" runat="server" id="lblAuditActionDescription"/>
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 5 --%>
            <asp:TemplateColumn HeaderText="Correct"  ItemStyle-Width="60px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:CheckBox Enabled="false" ID="chkCorrectCode"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 6 --%>
            <asp:BoundColumn DataField="ExcludeFromQA" Visible="false"/>     
            <%-- 7 --%>
            <asp:TemplateColumn HeaderText="Exclude from QA Report" ItemStyle-Width="60px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:CheckBox Enabled="true" ID="chkExcludeFromReport" runat="server" Checked='<%# DataBinder.Eval(Container.DataItem, "ExcludeFromQA")%>'/>
                <asp:HiddenField ID="hdnExclude" Value='<%# DataBinder.Eval(Container.DataItem, "ExcludeFromQA")%>'
                                 runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 8 --%>
            <asp:TemplateColumn HeaderText="Exclude Reason" ItemStyle-Width="60px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:DropDownList ID="ddlExcludeReason" runat="server" CssClass="StdInput"/>
                <%--<asp:HiddenField ID="hdnExcludeReasonID" Value='<%# DataBinder.Eval(Container.DataItem, "ExcludeFromQAReasonId") ?? "false" %>' runat="server" />--%>
              </ItemTemplate>
            </asp:TemplateColumn>
          </Columns>
        </asp:DataGrid>
      </asp:Panel>
    </td>
  </tr>
  <tr runat="server" id="pnlDocumentationDeficiencyComments">
    <td>
      <br />
      <asp:Label runat="server" Text="Auditor Comments (Documentation Deficiency):"  CssClass="FieldLabel"/>
      <br />
      <asp:TextBox Rows="5" CssClass="StdInput" TextMode="MultiLine" MaxLength="500" Columns="70"
                   ID="txtComment" onKeyUp="Count(this,500,'Documentation Deficiency')"
                   onChange="Count(this,500,'Documentation Deficiency')" runat="server"/>
    </td>
  </tr>
</table>
<asp:HiddenField ID="hdnAuditChange" runat="server" />