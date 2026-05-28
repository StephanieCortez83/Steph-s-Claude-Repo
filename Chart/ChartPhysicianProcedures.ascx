<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="ChartPhysicianProcedures.ascx.cs" Inherits="CCSWeb.WebPages.Controls.ChartPhysicianProcedures" EnableViewState="False" %>
<form id="form1" runat="server">
  <asp:GridView ID="grdProcedures" CssClass="procedureGrid" DataKeyNames="PhysicianProcedureID" AutoGenerateColumns="false" 
    EmptyDataText="There are no procedures in this category." runat="server" Width="100%" OnRowDataBound="grdProcedures_RowDataBound">
    <HeaderStyle CssClass="ColHeading" />
    <RowStyle CssClass="AltListRow1" />
    <AlternatingRowStyle CssClass="AltListRow2" />
    <Columns>
      <asp:TemplateField HeaderText="Add to Facility Procedures" ItemStyle-Width="100px">
        <ItemStyle HorizontalAlign="Center" />
        <ItemTemplate>
          <asp:CheckBox ID="chkAddToFacilityProcedure" runat="server"></asp:CheckBox>
        </ItemTemplate>
      </asp:TemplateField>
      <asp:TemplateField HeaderText="Quantity">
        <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
        <ItemStyle HorizontalAlign="Left" Width="80px"></ItemStyle>
        <ItemTemplate>
          <uc1:SpinButton ID="txtQuantity" runat="server" CssClass="StdInput spn-select-qty" 
            Text='<%# DataBinder.Eval(Container.DataItem, "Quantity") %>' MaxLength="5" Columns="5">
          </uc1:SpinButton>
          <asp:HiddenField ID="hfMaxQuantity" Value='<%# Eval("MaxQuantity") %>' runat="server" />
          <asp:HiddenField ID="hfAllowNegativeUnitsInd" Value='<%# Eval("AllowNegativeUnitsInd") %>' runat="server" />
        </ItemTemplate>
      </asp:TemplateField>
      <asp:TemplateField HeaderText="Procedure" ItemStyle-Width="60%">
        <ItemTemplate>
          <asp:Label ID="lblProcedureDescription" runat="server" Text='<%# Eval("ProcedureDescription") %>'></asp:Label>
          <asp:HiddenField ID="hdnProcedureId" runat="server" Value='<%# Eval("PhysicianProcedureID") %>' />
        </ItemTemplate>
      </asp:TemplateField>
      <asp:TemplateField HeaderText="CPT">
        <ItemTemplate>
          <asp:Label ID="lblCPT" runat="server" Width="35px" CssClass="lblCpt" Text='<%# Eval("cptCode") %>'></asp:Label>
        </ItemTemplate>
      </asp:TemplateField>
      <asp:TemplateField HeaderText="Modifiers">
        <ItemStyle Width="5px" />
        <ItemTemplate>
          <asp:Label ID="lblModifiers" runat="server" Text='<%# Eval("Modifiers") %>'>
          </asp:Label>
          <asp:HiddenField ID="hfModifiers" runat="server" />
        </ItemTemplate>
      </asp:TemplateField>
      <asp:TemplateField>
        <ItemTemplate>
          <input id="btnSelectModifier" runat="server" type="button" class="StdButton addModifier" value="..." />
        </ItemTemplate>
      </asp:TemplateField>
      <asp:BoundField DataField="BillingCode" HeaderText="Billing Code"></asp:BoundField>
      <asp:TemplateField HeaderText="Procedure Date">
        <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
        <ItemStyle HorizontalAlign="Left"></ItemStyle>
        <ItemTemplate>
          <asp:DropDownList ID="cmbProcedureDate" runat="server" CssClass="StdInput" />
        </ItemTemplate>
      </asp:TemplateField>
      <asp:TemplateField HeaderText="Performing Provider">
        <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
        <ItemStyle HorizontalAlign="Left" Width="200px"></ItemStyle>
        <ItemTemplate>
          <asp:Button ID="btnSelectPhysician" runat="server" Text="Select" CssClass="select-performing-provider StdButton" />
          <asp:HiddenField ID="hfSelectedPhysician" runat="server" />
          <asp:Label ID="lblPhysician" runat="server" Text="Not Selected"></asp:Label>
        </ItemTemplate>
      </asp:TemplateField>
      <asp:TemplateField HeaderText="Insufficient Documentation To Bill">
        <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
        <ItemStyle HorizontalAlign="Center"></ItemStyle>
        <ItemTemplate>
          <asp:CheckBox ID="chkInsufficientDocToBill" runat="server" CssClass="Checkbox" />
        </ItemTemplate>
      </asp:TemplateField>
    </Columns>
  </asp:GridView>
</form>
