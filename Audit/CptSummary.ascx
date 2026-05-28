<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="CptSummary.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.CptSummary" %>
<style type="text/css">
  .accuracyTable td {
    border:ridge; 
    text-align:center
  }
</style>
<table>
  <tr>
    <td valign="top" align="left" width="50%">
      <h3>CPT/HCPCS Code Only Audit Summary</h3>
      <asp:DataGrid ID="grdCPTSummaryCoder" runat="server" CssClass="ListTable" AutoGenerateColumns="False" 
                    OnItemDataBound="grdCPTSummaryCoder_ItemDataBound" AllowPaging="False" Width="100%">
        <ItemStyle CssClass="ListRow1"/>
        <HeaderStyle CssClass="ColHeading" Height="30px"/>
        <Columns>
          <%-- 0 --%>
          <asp:BoundColumn DataField="Id" Visible="false" />
          <%-- 1 --%>
          <asp:TemplateColumn HeaderText="Section"  ItemStyle-Width="30px" ItemStyle-HorizontalAlign="Center"  >
            <ItemTemplate>
              <asp:Literal ID="ltlChartSectionId" Visible="False" runat="server" />
              <asp:Label Enabled="false" ID="lblChartSection"  runat="server" />
            </ItemTemplate>
          </asp:TemplateColumn>
          <%-- 2 --%>
          <asp:TemplateColumn HeaderText="Previous Code"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
            <ItemTemplate>
              <asp:Label Enabled="false" ID="lblPreviousCode"  runat="server" />
            </ItemTemplate>
          </asp:TemplateColumn>
          <%-- 3 --%>
          <asp:TemplateColumn HeaderText="Auditor Code"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
            <ItemTemplate>
              <asp:Label Enabled="false" ID="lblAuditorCode"  runat="server" />
            </ItemTemplate>
          </asp:TemplateColumn>
          <%-- 4 --%>
          <asp:TemplateColumn HeaderText="Audit Action"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
            <ItemTemplate>
              <asp:Label Enabled="false" ID="lblAuditAction"  runat="server" />
            </ItemTemplate>
          </asp:TemplateColumn>
          <%-- 5 --%>
          <asp:TemplateColumn HeaderText="Correct"  ItemStyle-Width="70px" ItemStyle-HorizontalAlign="Center"  >
            <ItemTemplate>
              <asp:CheckBox Enabled="false" ID="chkCorrectCode"  runat="server" />
            </ItemTemplate>
          </asp:TemplateColumn>
          <%-- 6 --%>
          <asp:BoundColumn DataField="ExcludeFromQa" Visible="false"/>
          <%-- 7 --%>
          <asp:TemplateColumn HeaderText="Exclude from QA Report" ItemStyle-Width="50px" ItemStyle-HorizontalAlign="Center">
            <ItemTemplate>
              <asp:CheckBox Enabled="true" ID="chkExcludeFromReport"  Checked='<%# DataBinder.Eval(Container.DataItem, "ExcludeFromQa") %>'
                            runat="server" />
              <asp:HiddenField ID="hdnExclude" Value='<%# DataBinder.Eval(Container.DataItem, "ExcludeFromQa") %>'
                               runat="server" />
            </ItemTemplate>
          </asp:TemplateColumn>
          <%-- 8 --%>
          <asp:TemplateColumn HeaderText="Exclude Reason" ItemStyle-Width="120px" ItemStyle-HorizontalAlign="Center">
            <ItemTemplate>
              <asp:DropDownList ID="ddlExcludeReason" runat="server" width="275px" CssClass="StdInput"/>
            </ItemTemplate>
          </asp:TemplateColumn>
        </Columns>
      </asp:DataGrid>
    </td>
  </tr>
  <tr>
    <td>
      <br />
      <table class="accuracyTable">
        <tr class="ColHeading" style="height:25px">
          <td colspan="2">
            <asp:Label ID="lblOverall" Text="<b>Overall CPT/HCPCS Accuracy</b>"  runat="server" />
          </td>
        </tr>
        <tr>
          <td><asp:Label Text="Correct Codes" runat="server"/></td>
          <td><asp:Label ID="lblCorrect" runat="server"/></td>
        </tr>
        <tr>
          <td><asp:Label Text="Revisions" runat="server"/></td>
          <td><asp:Label ID="lblRevisons" runat="server"/></td>
        </tr>
        <tr>
          <td><asp:Label Text="Additions"  runat="server"/></td>
          <td><asp:Label ID="lblAdditions" runat="server"/></td>
        </tr>
        <tr>
          <td><asp:Label Text="Deletions" runat="server"/></td>
          <td><asp:Label ID="lblDeletions" runat="server"/></td>
        </tr>
        <tr>
          <td><asp:Label Text="Overall Accuracy" runat="server"/></td>
          <td><asp:Label ID="lblScore" runat="server"/></td>
        </tr>
      </table>
    </td>
  </tr>
</table>