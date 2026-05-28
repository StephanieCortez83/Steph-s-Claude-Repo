<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.FacilityFileDownloads" Codebehind="FacilityFileDownloads.ascx.cs" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="ajx" %>
<%@ Register TagPrefix="uc1" TagName="DateField" Src="../DateField.ascx" %>
<script type="text/javascript">

    function ToggleFacilityDownloads(expand) {
        let theBehavior = $find('CollapseBehaviorFacilityDownloads');

		if (theBehavior) {
		  var isCollapsed = theBehavior.get_Collapsed();
		  if (isCollapsed && expand) {
			theBehavior.expandPanel();
		  }
		  else if (!isCollapsed && !expand) {
			theBehavior.collapsePanel();
		  }
		}
	};

</script>

<asp:Panel ID="pnl" Runat="server">
	<span class="PortalHeader">My&nbsp;Downloads</span>
	<hr />
  <div class="AJAXCalendar">
	<asp:Label id="Label1" CssClass="RequiredFieldLabel" runat="server">Date:</asp:Label>
	<uc1:DateField ID="txtFromDate" runat="server" ValidateRange="true" ShowValidatorCallout="true" Required="true" />
	<asp:Label id="Label2" CssClass="RequiredFieldLabel" runat="server">To:</asp:Label>
	<uc1:DateField ID="txtToDate" runat="server" ValidateRange="true" ShowValidatorCallout="true" Required="true" />
	<asp:Label id="Label3" CssClass="RequiredFieldLabel" runat="server">Facility:</asp:Label>
	<asp:DropDownList id="cmbFacilities" CssClass="StdInput" runat="server"></asp:DropDownList>
	<asp:Button id="btnSubmit" CssClass="StdButton" runat="server" Text="Search" onclick="btnSubmit_Click"></asp:Button> &nbsp;
    <asp:Button ID="btnExpandFacilityDownloads" runat="server" CssClass="StdButton" Text="Expand Section" OnClientClick="ToggleFacilityDownloads(true); return false;" />
    <asp:Button ID="btnCollapseFacilityDownloads" runat="server" CssClass="StdButton" Text="Collapse Section" OnClientClick="ToggleFacilityDownloads(false); return false;" />

	</div>
    <asp:Panel ID="pnlFacilityDownloads" runat="server" CssClass="GroupBox">
		<asp:datagrid id="grd" runat="server" AutoGenerateColumns="false" DataKeyField="TransmissionBatchFileID">
			<ItemStyle CssClass="ListRow1"></ItemStyle>
			<HeaderStyle CssClass="ColHeading"></HeaderStyle>
			<Columns>
				<asp:BoundColumn Visible="False" DataField="TransmissionBatchID"></asp:BoundColumn>
				<asp:BoundColumn Visible="False" DataField="TransmissionBatchFileID"></asp:BoundColumn>
				<asp:BoundColumn Visible="False" DataField="FacilityID"></asp:BoundColumn>
				<asp:BoundColumn Visible="False" DataField="ServiceAgreementID"></asp:BoundColumn>
				<asp:ButtonColumn DataTextField="TransmissionDate" HeaderText="File Date" CommandName="Select" DataTextFormatString="{0:M/d/yyyy h:mm tt}"></asp:ButtonColumn>
				<asp:BoundColumn DataField="NumberOfCharts" HeaderText="Number of Charts" Visible="false"></asp:BoundColumn>
				<asp:BoundColumn DataField="FacilityName" HeaderText="Facility"></asp:BoundColumn>
				<asp:BoundColumn DataField="ExportDefinitionDescription" HeaderText="Export Definition"></asp:BoundColumn>
				<asp:BoundColumn DataField="PostingStartDateTime" HeaderText="Scripting Started" DataFormatString="{0:M/d/yyyy h:mm tt}"></asp:BoundColumn>
				<asp:BoundColumn DataField="PostingEndDateTime" HeaderText="Scripting Completed" DataFormatString="{0:M/d/yyyy h:mm tt}"></asp:BoundColumn>
			</Columns>
		</asp:datagrid>
	</asp:Panel>
    <ajx:CollapsiblePanelExtender ID="CollapsiblePanelExtender2" runat="server" 
    Collapsed="true" ExpandDirection="Vertical" TargetControlID="pnlFacilityDownloads"
    ScrollContents="true" BehaviorID="CollapseBehaviorFacilityDownloads">
	</ajx:CollapsiblePanelExtender>


</asp:Panel>
