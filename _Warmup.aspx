<%@ Page Title="Site Warmup" Language="C#" MasterPageFile="~/WebPages/Chart.Master" Inherits="CCSWeb.WebPages._Warmup" CodeBehind="_Warmup.aspx.cs" EnableEventValidation="false"%>
<%@ MasterType VirtualPath="~/WebPages/Chart.Master" %>
<asp:Content ID="ScriptsAndCSS" ContentPlaceHolderID="ScriptsAndCSS" runat="server"></asp:Content>
<asp:Content ID="IntroArea" ContentPlaceHolderID="IntroArea" runat="server">
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
  <div id="warningErrors" style="display:none;">
    <cc1:ErrorListView ID="lstWarningErrors" runat="server" />
  </div>
  <table cellspacing="0" cellpadding="0" width="100%" border="0">
    <tr>
      <td valign="top" align="left" width="100%">
          Hello there.
      </td>
    </tr>
  </table>

<!-- Debug Information -->
  <div id="divDebugInfo" runat="server" style="display: table; text-align: center; margin-top: 10px;  margin-bottom: 10px; margin-left: auto; margin-right: auto; background: white;" class="footer">
    <br />
    <asp:Button ID="btnDebugInfoToggleView" runat="server" Text="Toggle Debug Info Visibility" OnClientClick="return showHideDebugInfo()" />
    <hr /><br />
    <table id="tbDebugInfo" cellspacing="0" class="GroupBox" cellpadding="0" width="100%" border="0">
        <tr>
            <td class="GroupBoxTitle" colspan="4">Debug Information:</td>
        </tr>
        <tr>
            <td>
                <asp:TextBox TextMode="MultiLine" ID="txtDebugInfo" Wrap="true" readonly="true" Enabled="false" Height="220px" Columns="200" Rows="5" runat="server" ClientIDMode="Static"></asp:TextBox>
            </td>
        </tr>
    </table>
  </div>

<script type="text/javascript">

	function showHideDebugInfo() {

		var tbDebugInfo = document.getElementById("tbDebugInfo");

		if (!tbDebugInfo)
			return false;

		if (tbDebugInfo.style.display == "" || tbDebugInfo.style.display == "block") {
			tbDebugInfo.style.display = "none";
		}
		else {
			tbDebugInfo.style.display = "block";
		}

		return false;
	}

</script>

</asp:Content>