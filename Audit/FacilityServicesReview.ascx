<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="FacilityServicesReview.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.FacilityServicesReview" %>
<table>
  <tr>
    <td>
      <asp:Panel runat="server" ID="pnlFacilityServices">
        <h3>Facility Level of Service</h3>
        <br />
        <asp:DataGrid ID="grdFacilityLOS" runat="server" CssClass="ListTable" AutoGenerateColumns="False" OnItemDataBound="grdFacilityLOS_ItemDataBound"
                      AllowPaging="False" Width="100%">
          <ItemStyle CssClass="ListRow1"/>
          <HeaderStyle CssClass="ColHeading" Height="40px"/>
          <Columns>
            <%-- 0 --%>
            <asp:BoundColumn DataField="Id" Visible="false"/>
            <%-- 1 --%>
            <asp:TemplateColumn HeaderText="Previous Code"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousCode"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 2 --%>
            <asp:TemplateColumn HeaderText="Auditor Code"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorCode"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 3 --%>
            <asp:TemplateColumn HeaderText="Audit Action"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditActionDescription"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 4 --%>
            <asp:BoundColumn DataField="ExcludeFromQA" Visible="false"/> 
          </Columns>
        </asp:DataGrid>
      </asp:Panel>
    </td>
  </tr>
  <tr>
    <td>
      <table>
        <tr>
          <td>
            <asp:DataGrid ID="grdFacilityServices" runat="server" CssClass="ListTable" AutoGenerateColumns="False" OnItemDataBound="grdFacilityServices_ItemDataBound"
                          AllowPaging="False">
              <ItemStyle CssClass="ListRow1"/>
              <HeaderStyle CssClass="ColHeading" Height="30px"/>
              <Columns>
                <%-- 0 --%>
                <asp:BoundColumn DataField="FacilityServiceDescription" HeaderText="Service Description"/>
                <%-- 1 --%>
                <asp:BoundColumn DataField="Points" HeaderText="Points"/>
                <%-- 2 --%>
                <asp:BoundColumn DataField="ChartAuditActionTypeCode" HeaderText="Audit Action"/>
              </Columns>
            </asp:DataGrid>
          </td>
        </tr>
        <tr>
          <td>
            <br />
            <asp:Label ID="lblFacilityServicesComment" runat="server" Text="Auditor Comments (Facility Services):"  CssClass="FieldLabel"/>
            <br />
            <asp:TextBox ID="txtComment" Wrap="True" MaxLength="500" 
                         Columns="70" Rows="5" runat="server" CssClass="StdInput" TextMode="MultiLine" onKeyUp="Count(this,500,'Facility Services')"
                         onChange="Count(this,500,'Facility Services')"/>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
<asp:HiddenField ID="hdnAuditChange" runat="server" />