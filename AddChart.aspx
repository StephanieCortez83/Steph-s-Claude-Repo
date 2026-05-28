<%@ Page Title="Add Chart" Language="C#" MasterPageFile="~/ClinicalCodingSolutions.master" Inherits="CCSWeb.WebPages.AddChart" CodeBehind="AddChart.aspx.cs" %>
<%@ MasterType VirtualPath="~/ClinicalCodingSolutions.Master" %>
<asp:Content ID="PageBody" ContentPlaceHolderID="PageBody" runat="server">
  <table class="IntroArea" cellspacing="0" cellpadding="0" width="100%" border="0">
    <!-- Intro Paragraphs and Help Text -->
    <tr>
      <td>
        <h2>
          <asp:Label ID="lblAddChart" runat="server" Text="Add Chart" CssClass="h2Label"></asp:Label></h2>
        <p>
          This page allows you to manually add a chart. To do so, you must select that facility
          that sent the chart and assign the date the chart was received. You will also need
          to uniquely identify the chart by assigning it a facility chart identifier and then
          make an initial assignment. Click Save to complete the process of adding a chart.
          If a service agreement exists that covers this chart and the chart identifier is
          unique for the facility, the chart will be added and you will be redirected to the
          chart demographics page to begin work on the chart.
        </p>
      </td>
    </tr>
    <!-- Errors -->
    <tr>
      <td>
        <asp:UpdatePanel ID="upErrors" runat="server">
          <ContentTemplate>
            <cc1:ErrorListView ID="ErrorListView1" runat="server"></cc1:ErrorListView>
          </ContentTemplate>
        </asp:UpdatePanel>
      </td>
    </tr>
  </table>
  <table class="MainBodyArea" cellspacing="0" cellpadding="0" width="100%" border="0">
    <!-- Main Data -->
    <tr>
      <td valign="top" align="left" width="65%">
        <table cellspacing="0" cellpadding="0" border="0">
          <!-- Demographics Information -->
          <tr>
            <td valign="top" align="left">
              <div class="GroupBox" style="width: 100%;">
                <div class="GroupBoxTitle">
                  Chart Identification:</div>
                <asp:Panel ID="pnlAddChart" runat="server" DefaultButton="btnSave">
                  <table cellspacing="0" cellpadding="0" width="100%">
                    <tr>
                      <td>
                        <asp:Label ID="Label25" runat="server" CssClass="RequiredFieldLabel">Facility:</asp:Label>
                      </td>
                      <td>
                        <asp:DropDownList ID="cmbFacility" runat="server" CssClass="StdInput" TabIndex="1">
                        </asp:DropDownList>
                      </td>
                      <td>
                        <asp:Label ID="Label27" runat="server" CssClass="RequiredFieldLabel">Date Received:</asp:Label>
                      </td>
                      <td colspan="1">
                        <uc1:DateField ID="txtDateReceived" runat="server" CssClass="StdInput" Required="true"
                          ValidateRange="true" />
                        <asp:TextBox ID="txtTimeReceived" runat="server" CssClass="StdInput" MaxLength="6"
                          Columns="6"></asp:TextBox><br />
                        <asp:Label ID="Label13" runat="server" CssClass="FieldFormat">mm/dd/yyyy</asp:Label>
                        <asp:Label ID="Label3" runat="server" CssClass="FieldFormat">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;hhmmss</asp:Label>
                      </td>
                    </tr>
                    <tr>
                      <td>
                        <asp:Label ID="Label26" runat="server" CssClass="RequiredFieldLabel"> Chart Identifier:</asp:Label>
                      </td>
                      <td>
                        <asp:UpdatePanel ID="upChartID" runat="server">
                          <ContentTemplate>
                            <asp:TextBox ID="txtFacilityChartIdentifier" runat="server" CssClass="StdInput" MaxLength="20"
                              Columns="21" AutoPostBack="true" OnTextChanged="txtFacilityChartIdentifier_TextChanged"
                              TabIndex="2"></asp:TextBox>
                          </ContentTemplate>
                        </asp:UpdatePanel>
                      </td>
                      <td>
                        <asp:Label ID="Label4" runat="server" CssClass="RequiredFieldLabel">Date of Service:</asp:Label>
                      </td>
                      <td>
                        <uc1:DateField ID="txtDateOfService" runat="server" CssClass="StdInput DOSModalSource" Required="true"
                          ValidateRange="true" TabIndex="3" ClientIDMode="Static" />
                        <asp:Label ID="Label2" runat="server" CssClass="FieldFormat">mm/dd/yyyy</asp:Label>
                      </td>
                    </tr>
                    <tr>
                        <td>
                            <asp:Label ID="lblMedicalRecordNumber" runat="server" CssClass="RequiredFieldLabel">Medical Record Number:</asp:Label>
                        </td>
                        <td>
                            <asp:TextBox ID="txtMedicalRecordNumber" runat="server" TabIndex="4" CssClass="StdInput" MaxLength="20" Columns="20" ></asp:TextBox>
                        </td>
                    </tr>
                    <tr>
                      <td>
                        <asp:Label ID="lblPatientName" runat="server" CssClass="RequiredFieldLabel"> Patient Name:</asp:Label>
                      </td>
                      <td>
                        <asp:UpdatePanel ID="upName" UpdateMode="Conditional" runat="server">
                          <ContentTemplate>
                            <table cellspacing="0" cellpadding="0" border="0">
                              <tr>
                                <th align="left">
                                  Last Name
                                </th>
                                <th>
                                  &nbsp;
                                </th>
                                <th align="left">
                                  First Name
                                </th>
                              </tr>
                              <tr>
                                <td align="left">
                                  <asp:TextBox ID="txtLastName" runat="server" CssClass="StdInput" TabIndex="5"></asp:TextBox>
                                </td>
                                <td>
                                  &nbsp;
                                </td>
                                <td align="left">
                                  <asp:TextBox ID="txtFirstName" runat="server" CssClass="StdInput" TabIndex="6"></asp:TextBox>
                                </td>
                              </tr>
                            </table>
                          </ContentTemplate>
                        </asp:UpdatePanel>
                      </td>
                      <td>
                        <asp:Label ID="Label28" runat="server" CssClass="RequiredFieldLabel">Assigned To:</asp:Label>
                      </td>
                      <td>
                        <asp:DropDownList ID="cmbAssignedTo" runat="server" CssClass="StdInput" TabIndex="7">
                        </asp:DropDownList>
                      </td>
                    </tr>
                  </table>
                </asp:Panel>
                <div style="padding: .5em;">
                  <input class="StdButton" type="reset" value="Reset" style="float: left;" />
                  <asp:Button ID="btnSaveAndAddAnother" runat="server" CssClass="StdButton" Text="Save and Add Another"
                    OnClick="btnSaveAndAddAnother_Click" OnClientClick="DisableAllButtons();" UseSubmitBehavior="False"
                    TabIndex="8" Style="float: right;"></asp:Button>
                  <asp:Button ID="btnSave" runat="server" CssClass="StdButton" Text="Save" OnClick="btnSave_Click"
                    TabIndex="7" OnClientClick="DisableAllButtons();" UseSubmitBehavior="False" Style="float: right;">
                  </asp:Button>
                  <br style="clear: both;" />
                </div>
              </div>
            </td>
          </tr>
        </table>
      </td>
      <!-- Help -->
      <td valign="top" align="left">
        <table cellspacing="0" cellpadding="0" border="0">
          <tr>
            <td>
              <p>
                <strong>Help:</strong> Before you can work on a chart, the chart must be added into
                the system. Charts can either be added in manually or automatically. This page allows
                you to manually enter a chart.
              </p>
              <p>
                To enter a chart, you must identify the facility that sent the chart and the date
                the chart was received. Doing so allows the system to automatically select the service
                agreement that is in place with the facility. The service agreement will then be
                used to dictate the work that must be done on the chart.
              </p>
              <p>
                To ensure duplicate charts are not entered, the system keeps track of all facility
                assigned chart identifiers. You will not be able to add a chart if someone else
                has already added a chart with the same chart identifier.
              </p>
              <p>
                When you add a chart, you also select who will be assigned to work on the chart.
              </p>
              <p>
                Once you have completed all of the information required to enter a chart, click
                Save. If the chart was successfully added, you will be redirected to the chart set
                up and demographics page which will allow you to begin your work on the chart. If
                the chart could not be added, an error message will display indicate why the chart
                could not be added by the system.
              </p>
              <p>
                You can add mulitiple charts at once by clicking on Save and Add Another. The chart
                information that you have entered will be used to create a chart, but you will be
                immediately returned back to this page so that you can add another.
              </p>
            </td>
          </tr>
        </table>
      </td>
      <!-- End Help -->
    </tr>
  </table>

    <script type="text/javascript">

        let _SourceDOSElement = undefined;
        function ValidateDOSModal() {
            if (!_SourceDOSElement)
                return;

            if (_SourceDOSElement.value.trim() == "")
                return;

            // validate our date here format : mm/dd/yyyy
            let todaysDate = new Date();
            let dosDate = new Date(_SourceDOSElement.value);

            if (todaysDate.toDateString() === dosDate.toDateString())
                alert('The Date of service for this account is Today (' + dosDate.toDateString() + ')');
        }

        function SetupDOSModal() {
            let sourceDOS = document.getElementsByClassName("DOSModalSource");
            if (!sourceDOS)
                return;

            _SourceDOSElement = undefined;
            // looking for <input name="ctl00$PageBody$txtDateOfService$TextBox1" type="text" id = "TextBox1"
            for (let i = 0; i < sourceDOS.length; i++) {
                if (sourceDOS[i].name.indexOf("$txtDateOfService$") > 6) {
                    _SourceDOSElement = sourceDOS[i];
                    break;
                }
            }
            
            if (_SourceDOSElement)
                _SourceDOSElement.addEventListener("change", ValidateDOSModal);
        }
        SetupDOSModal();

    </script>
</asp:Content>
