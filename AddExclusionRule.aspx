<%@ Page Title="Exclusion Rules" Language="C#" MasterPageFile="~/WebPages/Administration.Master"
  CodeBehind="AddExclusionRule.aspx.cs" Inherits="CCSWeb.WebPages.AddExclusionRule" %>

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
      <li>
        <asp:LinkButton ID="ExclusionRulesLinkButton" OnClick="GoToExclusionRules" CssClass="StdInput"
          runat="server" Text="Exclusion Rules" /></li>
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
                  <asp:Label ID="TypeLabel" runat="server" Text="Type: " />
                </td>
                <td>
                  <asp:DropDownList ID="TypeDropDownList" OnSelectedIndexChanged="TypeDropDownList_SelectedIndexChanged"
                    Width="300px" runat="server" AutoPostBack="true" OnDataBound="DropDownList_DataBound"
                    CssClass="StdInput">
                    <asp:ListItem Text=""></asp:ListItem>
                  </asp:DropDownList>
                </td>
              </tr>
              <tr>
                <td align="right">
                  <asp:Label ID="SI2SIServiceItem1Label" runat="server" Text="Service Item 1: " />
                </td>
                <td>
                  <asp:Label ID="SI2SIServiceItem1" runat="server" />
                </td>
              </tr>
              <tr>
                <td align="right">
                  <asp:Label ID="ddlSI2SIServiceItem1Label" runat="server" Text="Service Item 1: " />
                </td>
                <td>
                  <asp:DropDownList ID="SI2SIServiceItem1DDL" CssClass="StdInput" OnSelectedIndexChanged="SI2SIServiceItem1DDL_SelectedIndexChanged"
                    AutoPostBack="true" OnDataBound="DropDownList_DataBound" Width="300px" runat="server">
                    <asp:ListItem Text=""></asp:ListItem>
                  </asp:DropDownList>
                </td>
              </tr>
              <tr>
                <td align="right">
                  <asp:Label ID="SI2SIServiceItem2Label" runat="server" Text="Service Item 2: " />
                </td>
                <td>
                  <asp:DropDownList ID="SI2SIServiceItem2DDL" CssClass="StdInput" OnSelectedIndexChanged="SI2SIServiceItem2DDL_SelectedIndexChanged"
                    AutoPostBack="true" OnDataBound="DropDownList_DataBound" Width="300px" runat="server">
                    <asp:ListItem Text=""></asp:ListItem>
                  </asp:DropDownList>
                </td>
              </tr>
              <tr>
                <td align="right">
                  <asp:Label ID="SI2PCPTCodeLabel" Text="CPT Code: " runat="server" />
                </td>
                <td>
                  <asp:TextBox ID="SI2PCPTCodeTextBox" CssClass="StdInput" Width="250px" runat="server" />
                </td>
              </tr>
              <tr>
                <td align="right">
                  <asp:Label ID="SI2PDDispositionLabel" Text="Disposition: " runat="server" />
                </td>
                <td>
                  <asp:DropDownList ID="SI2PDDispositionDDL" CssClass="StdInput" OnDataBound="DropDownList_DataBound"
                    Width="300px" runat="server">
                    <asp:ListItem Text=""></asp:ListItem>
                  </asp:DropDownList>
                </td>
              </tr>
              <tr>
                <td align="right" valign="top">
                  <asp:Label ID="lblEffectiveDate" runat="server" Text="Effective Date: " />
                </td>
                <td>
                  <asp:TextBox ID="txtEffectiveDate" Width="70px" CssClass="StdInput" MaxLength="10"
                    runat="server"></asp:TextBox>
                  &nbsp;
                  <asp:ImageButton runat="Server" ID="imgEffectiveDateCalendar" ImageUrl="~/images/Calendar_scheduleHS.png"
                    AlternateText="Click to show calendar" />
                  &nbsp;
                  <ajx:CalendarExtender ID="txtEffectiveDate_CalendarExtender" runat="server" CssClass="CalendarExtender"
                    Enabled="True" TargetControlID="txtEffectiveDate" PopupButtonID="imgEffectiveDateCalendar"
                    PopupPosition="TopRight">
                  </ajx:CalendarExtender>
                  <ajx:MaskedEditExtender ID="MaskedEditExtender1" TargetControlID="txtEffectiveDate"
                    Mask="99/99/9999" MessageValidatorTip="true" MaskType="Date" InputDirection="RightToLeft"
                    runat="server" ErrorTooltipCssClass="MaskedEdit" OnInvalidCssClass="StdInputErr" />
                  <ajx:MaskedEditValidator ID="MaskedEditValidator1" runat="server" ControlExtender="MaskedEditExtender1"
                    ControlToValidate="txtEffectiveDate" EmptyValueMessage="Effective date is required"
                    InvalidValueMessage="Effective date is invalid" IsValidEmpty="false" TooltipMessage="Input a date"></ajx:MaskedEditValidator>
                </td>
              </tr>
              <tr>
                <td align="right" valign="top">
                  <asp:Label ID="lblExpirationDate" runat="server" Text="Expiration Date: " />
                </td>
                <td>
                  <asp:TextBox ID="txtExpirationDate" Width="70px" CssClass="StdInput" MaxLength="10"
                    runat="server"></asp:TextBox>
                  &nbsp;
                  <asp:ImageButton runat="Server" ID="imgExpirationDateCalendar" ImageUrl="~/images/Calendar_scheduleHS.png"
                    AlternateText="Click to show calendar" />
                  &nbsp;
                  <ajx:CalendarExtender ID="txtExpirationDate_CalendarExtender" runat="server" CssClass="CalendarExtender"
                    Enabled="True" TargetControlID="txtExpirationDate" PopupButtonID="imgExpirationDateCalendar"
                    PopupPosition="TopRight" OnClientDateSelectionChanged="checkDate">
                  </ajx:CalendarExtender>
                  <ajx:MaskedEditExtender ID="MaskedEditExtender2" TargetControlID="txtExpirationDate"
                    Mask="99/99/9999" MessageValidatorTip="true" MaskType="Date" InputDirection="RightToLeft"
                    runat="server" ErrorTooltipCssClass="MaskedEdit" OnInvalidCssClass="StdInputErr" />
                  <ajx:MaskedEditValidator ID="MaskedEditValidator2" runat="server" ControlExtender="MaskedEditExtender2"
                    ControlToValidate="txtExpirationDate" EmptyValueMessage="Expiration date is required"
                    InvalidValueMessage="Expiration date is invalid" IsValidEmpty="false" TooltipMessage="Input a date"></ajx:MaskedEditValidator>
                </td>
              </tr>
              <tr>
                <td colspan="3">
                  <asp:Button ID="AddExclusionSubmitButton" CssClass="StdButton" OnClick="AddExclusionSubmitButton_Click"
                    runat="server" Text="Submit" />&nbsp;&nbsp;
                  <asp:Button ID="AddExclusionCancelButton" CssClass="StdButton" OnClick="AddExclusionCancelButton_Click"
                    runat="server" Text="Return" />
                </td>
              </tr>
            </table>
          </asp:TableCell>
        </asp:TableRow>
      </asp:Table>
    </div>
  </div>
</asp:Content>
