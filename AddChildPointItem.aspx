<%@ Page Title="Add Child Point Items" Language="C#" MasterPageFile="~/WebPages/Administration.Master"
  CodeBehind="AddChildPointItem.aspx.cs" Inherits="CCSWeb.WebPages.AddChildPointItem" %>

<%@ MasterType VirtualPath="~/WebPages/Administration.Master" %>
<asp:Content ID="ScriptsAndCSS" ContentPlaceHolderID="ScriptsAndCSS" runat="server">
  <link href="tabs.css" type="text/css" rel="stylesheet" />
</asp:Content>
<asp:Content ID="IntroArea" ContentPlaceHolderID="IntroArea" runat="server">
  <h2>
    Facility Service Schedule
  </h2>
</asp:Content>
<asp:Content ID="MainContent" ContentPlaceHolderID="MainContent" runat="server">
  <div>
    <asp:Label ID="ScheduleNameLabel" runat="server">Schedule Name: </asp:Label>
    <asp:TextBox ID="ScheduleNameTextBox" CssClass="StdInput" ReadOnly="true" Width="300"
      runat="server"></asp:TextBox>
  </div>
  <div id="header">
    <ul id="primary">
      <li><span>Points Items</span></li>
    </ul>
  </div>
  <div id="main">
    <div id="contents">
      <asp:Table ID="EditExclusionRule" runat="server">
        <asp:TableRow>
          <asp:TableCell>
            <table width="400px">
              <tr>
                <td align="right">
                  <asp:Label ID="TypeLabel" runat="server" Text="Description: " />
                </td>
                <td colspan="3">
                  <asp:TextBox ID="DescriptionTextBox" runat="server" CssClass="StdInput" MaxLength="75"
                    Width="350px"></asp:TextBox>
                </td>
              </tr>
             <tr>
                <td align="right">
                  <asp:Label ID="PointsLabel" Width="100px" runat="server" Text="Points: " />
                </td>
                <td>
                  <asp:TextBox ID="PointsTextBox" Width="225px" CssClass="StdInput" MaxLength="5" runat="server"></asp:TextBox>
                  <ajx:FilteredTextBoxExtender ID="txtPointsExtender" runat="server" TargetControlID="PointsTextBox"
                    FilterType="Numbers" />
                </td>
              </tr>
              <tr>
                <td align="right" valign="top">
                  <asp:Label ID="LongDescriptionLabel" CssClass="valignTop" runat="server" Text="Long Description: " />
                </td>
                <td colspan="3">
                  <asp:TextBox ID="LongDescriptionTextBox" CssClass="StdInput" Width="550px" MaxLength="1000"
                    TextMode="MultiLine" Rows="10" runat="server"></asp:TextBox>
                </td>
              </tr>
              <tr>
                <td align="right" valign="top">
                  <asp:Label ID="lblEffectiveDate" runat="server" Text="Effective Date: " />
                </td>
                <td>
                  <uc1:DateField ID="txtEffectiveDate" runat="server" ValidateRange="true" ShowValidatorCallout="true"
                    Required="true" />
                </td>
              </tr>
              <tr>
                <td align="right" valign="top">
                  <asp:Label ID="lblExpirationDate" runat="server" Text="Expiration Date: " />
                </td>
                <td>
                  <uc1:DateField ID="txtExpirationDate" runat="server" ValidateRange="true" ShowValidatorCallout="true"
                    Required="true" />
                </td>
              </tr>
              
              <tr>
                <td colspan="3">
                  <asp:Button ID="AddOnItemSubmitButton" CssClass="StdButton" OnClick="AddOnItemSubmitButton_Click"
                    runat="server" Text="Submit" />&nbsp;&nbsp;
                  <asp:Button ID="AddOnItemCancelButton" CssClass="StdButton" OnClick="AddOnItemCancelButton_Click"
                    runat="server" Text="Return" />
                </td>
              </tr>
            </table>
          </asp:TableCell>
        </asp:TableRow>
      </asp:Table>
    </div>
      <asp:HiddenField ID="hfParentFacilityServiceScheduleItemID" runat="server" />
      <asp:HiddenField ID="hfFacilityServiceScheduleItemID" runat="server" />
      <asp:HiddenField ID="hfFacilityServiceScheduleID" runat="server" />
      <asp:HiddenField ID="hfScheduleName" runat="server" />
      
  </div>
</asp:Content>
