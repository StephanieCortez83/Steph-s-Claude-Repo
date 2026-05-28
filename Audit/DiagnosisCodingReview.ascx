<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="DiagnosisCodingReview.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.DiagnosisCodingReview" %>
<table>
  <tr runat="server"  id="pnlDiagnosisCoding">
    <td width="50%" >
      <asp:Panel runat="server" ID="pnlDiagnosisCodingICD10">
        <h3>Diagnosis Coding</h3>
        <br />
        <asp:DataGrid ID="grdDiagnosisCodingICD10" runat="server" CssClass="ListTable" AutoGenerateColumns="False" OnItemDataBound="grdDiagnosisCodingICD10_ItemDataBound"
                      AllowPaging="False"  Width="100%">
          <ItemStyle CssClass="ListRow1" HorizontalAlign="Center" VerticalAlign="Middle"/>
          <HeaderStyle CssClass="ColHeading"  Height="30px"/>
          <Columns>
            <%-- 0 --%>
            <asp:BoundColumn DataField="Id" Visible="false"/>
            <%-- 1 --%>
            <asp:TemplateColumn HeaderText="Date, Provider, E/M" ItemStyle-Width="190px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblLevelOfService"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 2 --%>
            <asp:TemplateColumn HeaderText="Previous Diagnosis Type" ItemStyle-Width="120px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousDiagnosisType"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 3 --%>
            <asp:TemplateColumn HeaderText="Previous Code" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblPreviousIcdCode" runat="server"></asp:Label>
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 4 --%>
            <asp:TemplateColumn HeaderText="Auditor Diagnosis Type" ItemStyle-Width="120px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="false" ID="lblAuditorDiagnosisType"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 5 --%>
            <asp:TemplateColumn HeaderText="Auditor Code" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="False" id="lblAuditorIcdCode" runat="server"></asp:Label>
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 6 --%>
            <asp:TemplateColumn HeaderText="Audit Action" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:Label Enabled="False" ID="lblAuditActionDescription" runat="server"></asp:Label>
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 7 --%>
            <asp:TemplateColumn HeaderText="Correct"  ItemStyle-Width="80px" ItemStyle-HorizontalAlign="Center"  >
              <ItemTemplate>
                <asp:CheckBox Enabled="false" ID="chkCorrectCode"  runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 8 --%>
            <asp:BoundColumn DataField="ExcludeFromQA" Visible="false" />                                
            <%-- 9 --%>
            <asp:TemplateColumn HeaderText="Exclude from QA Report" ItemStyle-Width="100px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:CheckBox Enabled="true" ID="chkExcludeFromReport" runat="server" />
                <asp:HiddenField ID="hdnExclude" Value='<%# DataBinder.Eval(Container.DataItem, "ExcludeFromQA") ?? "false" %>'
                                 runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>
            <%-- 10 --%>
            <asp:TemplateColumn HeaderText="Exclude Reason" ItemStyle-Width="120px" ItemStyle-HorizontalAlign="Center">
              <ItemTemplate>
                <asp:DropDownList ID="ddlExcludeReason" runat="server" CssClass="StdInput"/>
                <asp:HiddenField ID="hdnExcludeReasonID" Value='<%# DataBinder.Eval(Container.DataItem, "ExcludeFromQA") ?? "false" %>' runat="server" />
              </ItemTemplate>
            </asp:TemplateColumn>

          </Columns>
        </asp:DataGrid>

      </asp:Panel>
    </td>
  </tr>
  <tr runat="server" id="pnlDiagnosisAuditResults">
    <td>
      <br />
      <asp:DataGrid ID="grdDiagnosisAuditResults" runat="server" CssClass="ListTable" AutoGenerateColumns="False"  OnItemDataBound="grdDiagnosisAuditResults_ItemDataBound"
                    AllowPaging="False" Width="525px">
        <ItemStyle Height="20px" CssClass="ListRow1"/>
        <HeaderStyle CssClass="ColHeading"  Height="30px"/>
        <Columns>
          <%-- 0 --%>
          <asp:BoundColumn ItemStyle-HorizontalAlign="Center" DataField="Accuracy" HeaderText="Overall Chart DX Accuracy"/>
          <%-- 1 --%>
          <asp:BoundColumn ItemStyle-HorizontalAlign="Center" DataField="AccuracyCount"/>
          <%-- 2 --%>
          <asp:BoundColumn ItemStyle-HorizontalAlign="Center" DataField="AdditionalResults" HeaderText="Additional Results"/>
          <%-- 3 --%>
          <asp:BoundColumn ItemStyle-HorizontalAlign="Center" DataField="PassFail" />
        </Columns>
      </asp:DataGrid>
    </td>
  </tr>
  <tr runat="server" id="pnlDiagnosisAuditComments">
    <td>
      <br />
      <asp:Label runat="server" Text="Auditor Comments (Diagnosis):"  CssClass="FieldLabel"/>
      <br />
      <asp:TextBox Rows="5" CssClass="StdInput" TextMode="MultiLine" MaxLength="500" Columns="70"
                   ID="txtComment" onKeyUp="Count(this,500,'Diagnosis Coding')"
                   onChange="Count(this,500,'Diagnosis Coding')" runat="server"/>
    </td>
  </tr>
</table>
<asp:HiddenField ID="hdnAuditChange" runat="server" />
