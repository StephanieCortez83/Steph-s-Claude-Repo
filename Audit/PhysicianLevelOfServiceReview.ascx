<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="PhysicianLevelOfServiceReview.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.PhysicianLevelOfServiceReview" %>
<table>
  <tr>
    <td width="50%" >
      <asp:Panel runat="server" ID="pnlPhysicianLOS">
        <h3>Physician Levels of Service</h3>
        <br />
        <asp:DataGrid ID="grdPhysicianLOS" runat="server" CssClass="ListTable" AutoGenerateColumns="False" OnItemDataBound="grdPhysicianLOS_ItemDataBound"
                      AllowPaging="False" Width="100%">
          <ItemStyle CssClass="ListRow1"/>
          <HeaderStyle CssClass="ColHeading" Height="30px"/>
          <Columns>
            <%-- 0 --%>
            <asp:BoundColumn DataField="Id" Visible="false"/>
            <%-- 1 --%>
            <asp:TemplateColumn HeaderText="Previous DOS"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousDateOfService" runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 2 --%>
            <asp:TemplateColumn HeaderText="Previous Provider"  ItemStyle-Width="100px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousProvider"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 3 --%>
            <asp:TemplateColumn HeaderText="Previous Code"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousCptCode"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 4 --%>
            <asp:TemplateColumn HeaderText="Previous History"  ItemStyle-Width="75px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousHistory"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 5 --%>
            <asp:TemplateColumn HeaderText="Previous Exam" ItemStyle-Width="75px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousExam"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 6 --%>
            <asp:TemplateColumn HeaderText="Previous MDM" ItemStyle-Width="75px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousMdm"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 7 --%>
            <asp:TemplateColumn HeaderText="Auditor DOS"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorDateOfService"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 8 --%>
            <asp:TemplateColumn HeaderText="Auditor Provider"  ItemStyle-Width="100px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorProvider"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 9 --%>
            <asp:TemplateColumn HeaderText="Auditor Code"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorCptCode"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 10 --%>
            <asp:TemplateColumn HeaderText="Auditor History"  ItemStyle-Width="75px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorHistory"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 11 --%>
            <asp:TemplateColumn HeaderText="Auditor Exam" ItemStyle-Width="75px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorExam"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 12 --%>
            <asp:TemplateColumn HeaderText="Auditor MDM" ItemStyle-Width="75px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorMdm"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 13 --%>
            <asp:TemplateColumn HeaderText="Audit Action"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditActionDescription"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 14 --%>
            <asp:BoundColumn DataField="ExcludeFromQA" Visible="false" /> 
          </Columns>
        </asp:DataGrid>
      </asp:Panel>
    </td>
  </tr>
  <tr>
    <td >
      <asp:DataGrid ID="grdPhysicianServices" runat="server" CssClass="ListTable" AutoGenerateColumns="False" OnItemDataBound="grdPhysicianServices_ItemDataBound"
                    AllowPaging="False">
        <ItemStyle CssClass="ListRow1"/>
        <HeaderStyle CssClass="ColHeading" Height="30px"/>
        <Columns>
          <asp:BoundColumn DataField="LevelNbr" HeaderText="Level"/>
          <asp:BoundColumn DataField="ServiceDescription" HeaderText="Description"/>
          <asp:BoundColumn DataField="Quantity" HeaderText="Quantity"/>
          <asp:BoundColumn DataField="Points" HeaderText="Points"/>
          <asp:BoundColumn DataField="ChartAuditActionTypeCode" HeaderText="Audit Action"/>
        </Columns>
      </asp:DataGrid>
    </td>
  </tr>
  <tr id="pnlPhysLOSComments" runat="server">
    <td>
      <br />
      <asp:Label ID="Label4" runat="server" Text="Auditor Comments (Physician Services):" CssClass="FieldLabel"/>
      <br />
      <asp:TextBox Rows="5" CssClass="StdInput" TextMode="MultiLine" MaxLength="500" Columns="70"
                   ID="txtComment" onKeyUp="Count(this,500,'Physician LOS')"
                   onChange="Count(this,500,'PhysicianServices')" runat="server"/>
    </td>
  </tr>
</table>
<asp:HiddenField ID="hdnAuditChange" runat="server"/>