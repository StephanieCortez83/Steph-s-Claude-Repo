<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="AnesthesiaReview.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.AnesthesiaReview" %>
<table>
  <tr>
    <td>
      <asp:Panel runat="server" ID="pnlAnesthesiaCoding">
        <h3>Anesthesia Coding</h3>
        <table>
          <tr>
            <td>
              <asp:DataGrid ID="grdAnesthesiaCoding" runat="server" CssClass="ListTable" AutoGenerateColumns="False" OnItemDataBound="grdAnesthesiaCoding_ItemDataBound"
                            AllowPaging="False" Width="100%">
                <ItemStyle CssClass="ListRow1"/>
                <HeaderStyle CssClass="ColHeading"  Height="30px"/>
                <Columns>
                  <%-- 0 --%>
                  <asp:BoundColumn DataField="Id" Visible="false"/>
                  <%-- 1 --%>
                  <asp:TemplateColumn HeaderText="Previous Code" ItemStyle-HorizontalAlign="Center">
                    <ItemTemplate>
                      <asp:Label runat="server" ID="lblPreviousCode"/>
                    </ItemTemplate>
                  </asp:TemplateColumn>
                  <%-- 2 --%>
                  <asp:TemplateColumn HeaderText="Audit Code" ItemStyle-HorizontalAlign="Center">
                    <ItemTemplate>
                      <asp:Label runat="server" ID="lblAuditorCode"/>
                    </ItemTemplate>
                  </asp:TemplateColumn>
                  <%-- 3 --%>
                  <asp:TemplateColumn HeaderText="Audit Action" ItemStyle-HorizontalAlign="Left">
                    <ItemTemplate>
                      <asp:Label runat="server" ID="lblAuditActionDescription"/>
                    </ItemTemplate>
                  </asp:TemplateColumn>
                  <%-- 4 --%>
                  <asp:TemplateColumn HeaderText="Change Detail" ItemStyle-HorizontalAlign="Left">
                    <ItemTemplate>
                        <asp:Label runat="server" ID="lblAuditChangeDetail"/>
                    </ItemTemplate>
                  </asp:TemplateColumn>
                  <%-- 5 --%>
                  <asp:BoundColumn DataField="ExcludeFromQa" Visible="false"/>                                
                </Columns>
              </asp:DataGrid>
            </td>
          </tr>
          <tr>
            <td>
              <br />
              <asp:Label ID="lblAnesthesiaComment" runat="server" Text="Auditor Comments (Anesthesia Coding):"  CssClass="FieldLabel"/>
              <br />
              <asp:TextBox Rows="5" CssClass="StdInput" TextMode="MultiLine" MaxLength="500" Columns="50"
                           ID="txtComment" onKeyUp="Count(this,500,'Anesthesia Coding')"
                           onChange="Count(this,500,'Anesthesia Coding')" runat="server"/>
            </td>
          </tr>
        </table>
      </asp:Panel>
    </td>
  </tr>
</table>
<asp:HiddenField ID="hdnAuditChange" runat="server" />