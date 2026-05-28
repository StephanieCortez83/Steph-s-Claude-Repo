<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.BatchProcessingInfo" Codebehind="BatchProcessingInfo.ascx.cs" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajx" %>
<%@ Register TagPrefix="uc1" TagName="DateField" Src="../DateField.ascx" %>
<asp:Panel ID="pnl" Runat="server">
	<span class="PortalHeader">Batch Processing Info</span>
	<hr />
	<asp:Label id="Label1" runat="server" CssClass="RequiredFieldLabel">Start Date:</asp:Label>
	<uc1:DateField ID="txtStartDate" runat="server" ValidateRange="true" ShowValidatorCallout="true" Required="true" />
	<asp:Label id="Label3" runat="server" CssClass="RequiredFieldLabel">End Date:</asp:Label>
	<uc1:DateField ID="txtEndDate" runat="server" ValidateRange="true" ShowValidatorCallout="true" Required="true" />
	<asp:Label id="Label2" runat="server" CssClass="RequiredFieldLabel">Error Level:</asp:Label>
	<asp:DropDownList id="cmbErrorLevel" runat="server" CssClass="StdInput">
		<asp:ListItem Value="0">Informational</asp:ListItem>
		<asp:ListItem Value="1">Start</asp:ListItem>
		<asp:ListItem Value="2">Complete</asp:ListItem>
		<asp:ListItem Value="3">Severe</asp:ListItem>
		<asp:ListItem Value="4">Exception</asp:ListItem>
	</asp:DropDownList>
	<br />
	<asp:Label id="Label4" runat="server" CssClass="RequiredFieldLabel">Facility:</asp:Label>
	<asp:DropDownList id="cmbFacilities" runat="server" CssClass="StdInput"/>
	<asp:Label id="Label5" runat="server" CssClass="RequiredFieldLabel">Process:</asp:Label>	
	<asp:DropDownList id="cmbProcess" runat="server" CssClass="StdInput">
		<asp:ListItem Value="">[All]</asp:ListItem>
		<asp:ListItem Value="IMPORT">Census Import</asp:ListItem>
		<asp:ListItem Value="EMAIL EXPORT">Email Export</asp:ListItem>
		<asp:ListItem Value="EXPORT">Export</asp:ListItem>
		<asp:ListItem Value="REASSIGN CHARTS">Reassign Work in Progress Charts</asp:ListItem>
		<asp:ListItem Value="CHART STATUS">Change Chart Status</asp:ListItem>
	</asp:DropDownList>
	<asp:Button id="btnSubmit" runat="server" CssClass="StdButton" Text="Search" onclick="btnSubmit_Click"></asp:Button>
	<asp:datagrid id="grd" runat="server" DataKeyField="BatchLogID" AutoGenerateColumns="False">
		<ItemStyle CssClass="ListRow1"></ItemStyle>
		<HeaderStyle CssClass="ColHeading"></HeaderStyle>
		<Columns>
			<asp:BoundColumn Visible="False" DataField="BatchLogID"></asp:BoundColumn>
			<asp:BoundColumn DataField="CreationDateTime" HeaderText="When" ></asp:BoundColumn>
			<asp:BoundColumn DataField="ErrorCodeDescription" HeaderText="Error Code"></asp:BoundColumn>
			<asp:BoundColumn DataField="Description" HeaderText="Description"></asp:BoundColumn>
		</Columns>
	</asp:datagrid>
</asp:Panel>
