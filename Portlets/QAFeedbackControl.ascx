<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="QAFeedbackControl.ascx.cs" Inherits="CCSWeb.WebPages.Controls.Portlets.QAFeedbackControl" %>
<asp:Panel ID="pnlConrol" runat="server">
	<span class="PortalHeader"></span>
	<hr />


</asp:Panel>

<asp:Panel ID="pnlQA" runat="server">
  <span class="PortalHeader"></span>&nbsp;&nbsp;
        <ajx:ModalPopupExtender ID="popupQAFeedback" runat="server" 
                TargetControlID="btnFakeTrigger" PopupControlID="ModalPopupQAFeedback" 
            PopupDragHandleControlID="PopupHeader" Drag="true" BackgroundCssClass="blur">
        </ajx:ModalPopupExtender>
        <asp:Button ID="btnFakeTrigger" Style="display: none" runat="server" />
        <asp:Panel ID="ModalPopupQAFeedback" HorizontalAlign="Center" runat="server"  Height="94%" Width="97%" DefaultButton="btnMarkAsReviewed">
            <div class="EditPopup RoundAllCorners" style="text-align:center; height:100%; width:inherit;">
                <div class="PopupHeader RoundTopCorners" id="PopupHeader" style="text-align:center; height:25px; width:100%; " >                                                        
                <asp:Label ID="lblPopupTitle" runat="server"  Style="color: White; text-align:center; font-family: Arial,sans-serif; height:25px;
                        font-weight: bold; font-size: 10pt;"  Text="QA Feedback Control"></asp:Label>              
                </div>
    
                <div id="CoderPopup"  class="PopupBody" runat="server" style="height:90%; width:100%;text-align:left;overflow:auto;" >
                    <table>
                        <tr>
                            <td >
                            <asp:Label ID="lblSummaryCoder" Text="Summary:" CssClass="FieldLabel"  Font-Size="Medium" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td id="tdDateRange" visible="false" runat="server">
                                    <br />
                                <div id="divDateRange" runat="server" visible="false" class="form-field" >
                                  <span class="FieldLabel block">QA Date Range:</span>
                                  <div class="block">
                                    <span class="indent">From:</span>
                                    <uc1:DateField ID="dfFromDate" runat="server" SetFocusOnLoad="true" ValidateRange="true"
                                      ValidationGroup="Group1" />
                                    <span>To:</span>
                                    <uc1:DateField ID="dfToDate" runat="server" ValidateRange="true" ValidationGroup="Group1" />
                                      <asp:Button id="btnRefresh" OnClick="btnRefresh_Click" UseSubmitBehavior="false" CssClass="StdButton" OnClientClick="this.disabled = true;" runat="server" Text="Refresh"></asp:Button>
                                      <asp:Button id="btnCancel" OnClientClick="this.disabled = true;"  UseSubmitBehavior="false" 
                                                    OnClick="btnCancel_Click" CssClass="StdButton" runat="server" Text="Cancel"></asp:Button>
                                  </div>
                                </div>
                            </td>
                        </tr>
                        <tr id="trNoResults" runat="server">
                            <td>
                                <br />
                                <asp:Label ID="lblNoResults" Text="No results for this date range."  CssClass="FieldLabel" visible="false" runat="server" ></asp:Label>
                            </td>
                        </tr>
                    </table>
                    <div id="divCoderResults" runat="server" visible="false">
                        <br /> &nbsp;         
                    <table id="tblCoderSummary" runat="server">
                        <tr>
                            <td style="width:70%">
                                <asp:Label ID="lblCoderHeading" CssClass="FieldLabel"  Text="Audit Summary"  Font-Size="small" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr></tr>
                        <tr>
                            <td>
                            <asp:Label ID="lblTotalChartsCoder" Text="Total Charts Coded: " CssClass="FieldLabel" runat="server" ></asp:Label>
                            &nbsp;&nbsp;
                            <asp:Label ID="lblTotalAuditedCoder" Text="Total Charts Audited: " CssClass="FieldLabel" runat="server" ></asp:Label>
                            </td> 
                        </tr>
                        <tr></tr>
                    </table>
                    <table>
                        <tr>
                            <td>
                                <asp:Label ID="lblAccuracyCoder" Text="Of the charts audited, the accuracy rates were: " CssClass="FieldLabel" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr></tr>
                        <tr>
                            <td></td>
                            <td><b>Demographics:</b></td>
                            <td align="right">
                                <asp:Label ID="lblDemographicsCoder"   runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td ><b>Facility Service:</b></td>
                            <td align="right">
                                <asp:Label ID="lblFacilityServiceCoder"  runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Facility Infusion/Injection:</b></td>
                            <td align="right">
                                <asp:Label ID="lblFacilityInfInjCoder" Text=""  runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>FacilityProcedures:</b></td>
                            <td align="right">
                                <asp:Label ID="lblFacilityProcCoder" Text=""  runat="server" ></asp:Label>
                            </td>
 
                        </tr>
                        
                        <tr>
                            <td></td>
                            <td><b>Physician Service:</b></td>
                            <td align="right">
                                <asp:Label ID="lblPhysicianServiceCoder" Text=""   runat="server" ></asp:Label>
                            </td>
                           <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Physician Procedures:</b></td>
                            <td align="right">
                                <asp:Label ID="lblPhysicianProcCoder" Text=""  runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Diagnosis Coding:</b></td>
                            <td align="right">
                                <asp:Label ID="lblDiagnosisCoder"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr id="trObsSummary" runat="server">
                            <td></td>
                            <td><b>Obs Hours:</b></td>
                            <td align="right">
                                <asp:Label ID="lblObsHoursCoder" Text=""   runat="server" ></asp:Label>
                            </td>
                           <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Obs Inf/Inj:</b></td>
                            <td align="right">
                                <asp:Label ID="lblObsInfInjCoder" Text=""  runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Obs Procedures:</b></td>
                            <td align="right">
                                <asp:Label ID="lblObsProcCoder"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td></td>
                            <td><b>  Total Accuracy:</b></td>
                            <td align="right">
                                <asp:Label ID="lblTotalRate" Text=""  runat="server" ></asp:Label>
                            </td>
                        </tr>
                    </table>
                    <table style="width=90%">
                          <tr>
                            <td style="width:70%">
                            <asp:Label ID="lblAuditorChanges" CssClass="FieldLabel"  Text="Auditor Changes to Charts Completed by this User"  Font-Size="small" runat="server" ></asp:Label>
                            </td>
                        </tr>
                    </table>   

                    <table style="width:97%">
                    <tr>
                        <td valign="top" align="left">
                            <asp:DataGrid ID="grdResults" runat="server" OnItemDataBound="grdResults_ItemDataBound" OnItemCommand="grdResults_ItemCommand" CssClass="ListTable"
                        AutoGenerateColumns="False" DataKeyField="ChartID" AllowPaging="False">
                            <AlternatingItemStyle CssClass="ListRow2"></AlternatingItemStyle>
                            <ItemStyle CssClass="ListRow1"></ItemStyle>
                            <HeaderStyle CssClass="ColHeading"></HeaderStyle>                        
                          <Columns>
                          <asp:BoundColumn Visible="False" DataField="ChartID"></asp:BoundColumn>
                          <asp:TemplateColumn HeaderText="">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle  HorizontalAlign="Left"></ItemStyle>
                            <ItemTemplate>
                                <asp:LinkButton id="lnkAuditReviewCoder" CommandName="AuditReview"  runat="server">View</asp:LinkButton>
                            </ItemTemplate>
                           </asp:TemplateColumn>
                          <asp:BoundColumn DataField="FacilityName" HeaderText="Facility" >
                            <ItemStyle Width="20%"></ItemStyle>
                          </asp:BoundColumn>
                          <asp:BoundColumn DataField="FacilityChartID" HeaderText="Account #">
                            <ItemStyle Width="10%"></ItemStyle>
                          </asp:BoundColumn>
                          <asp:BoundColumn DataField="DateApprovedString" HeaderText="Date Approved">
                            <ItemStyle Width="10%"></ItemStyle>
                          </asp:BoundColumn>

                          <asp:TemplateColumn HeaderText="Facility LOS">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                            <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityLOSPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityLOSPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblFacilityLOSComment" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityLOSComment") %>'></asp:Label>
                            </ItemTemplate>
                           </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Facility Inf/Inj">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityInfInjPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityInfInjPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblFacilityInfInjComment" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityInfInjComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Facility Proc">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityProcPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityProcPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblFacilityProcComment" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityProcComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Physician E&M">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblPhysicianLOSPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "PhysicianLOSPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblPhysicianLOSComment" Text='<%# DataBinder.Eval(Container.DataItem, "PhysicianLOSComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Physician Proc">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblPhysicianProcPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "PhysicianProcPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblPhysicianProcComment" Text='<%# DataBinder.Eval(Container.DataItem, "PhysicianProcComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Dx Coding">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblDiagnosisPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "DiagnosisPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblDiagnosisComment" Text='<%# DataBinder.Eval(Container.DataItem, "DiagnosisComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Demographics">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblDemographicsPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "DemographicsPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblDemographicsComment" Text='<%# DataBinder.Eval(Container.DataItem, "DemographicsComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Obs Hours" >
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblObsHoursPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "ObsHoursPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblObsHoursComment" Text='<%# DataBinder.Eval(Container.DataItem, "ObsHoursComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Obs Inf/Inj"  >
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblObsInfInjPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "ObsInfInjPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblObsInfInjComment" Text='<%# DataBinder.Eval(Container.DataItem, "ObsInfInjComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Obs Proc" >
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblObsProcPassFail" Text='<%# DataBinder.Eval(Container.DataItem, "ObsProcPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblObsProcComment" Text='<%# DataBinder.Eval(Container.DataItem, "ObsProcComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Auditor Actions">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "20%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                               <asp:ListBox ID="lstChartAuditAction" runat="server" CssClass="StdInput"></asp:ListBox>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:BoundColumn Visible="False" DataField="FacilityLOSPassFail" HeaderText="Facility Service"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="FacilityInfInjPassFail" HeaderText="Facility Inf/Inj"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="FacilityProcPassFail" HeaderText="Facility Proc"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="PhysicianLOSPassFail" HeaderText="Physician E&M"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="PhysicianProcPassFail" HeaderText="Physician Proc"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="DiagnosisPassFail" HeaderText="Diagnosis Coding"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="DemographicsPassFail" HeaderText="Demographics"></asp:BoundColumn>
                        </Columns>
                      </asp:DataGrid>
                        </td>
                    </tr>

                    </table>                                     
                    </div>

                    <div id="divAuditorResults" runat="server" visible="false">
                    <br /> &nbsp;         
                    <table id="tblAuditorSummary" runat="server">
                        <tr></tr>
                        <tr>
                            <td style="width:70%">
                                <asp:Label ID="lblSecondAuditHeading" CssClass="FieldLabel"  Text="Second Audit Summary"  Font-Size="small" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr></tr>
                        <tr>
                            <td>
                            <asp:Label ID="lblTotalCharts2ndAudited" Text="Total Charts 2nd Level Audited: " CssClass="FieldLabel" runat="server" ></asp:Label>
                            &nbsp;&nbsp;
                            <asp:Label ID="lblTotal2ndLevelChanged" Text="Total Charts with 2nd Level Auditor Changes: " CssClass="FieldLabel" runat="server" ></asp:Label>
                            </td> 
                        </tr>
                        <tr></tr>
                    </table>
                    <table>
                        <tr>
                            <td>
                                <asp:Label ID="lblAccuracyAuditor" Text="Of the charts 2nd Level Audited, the accuracy rates were: " CssClass="FieldLabel" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr></tr>
                        <tr>
                            <td></td>
                            <td><b>Demographics:</b></td>
                            <td align="right">
                                <asp:Label ID="lblDemographicsAuditor"   runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td ><b>Facility Service:</b></td>
                            <td align="right">
                                <asp:Label ID="lblFacilityServiceAuditor"  runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Facility Infusion/Injection:</b></td>
                            <td align="right">
                                <asp:Label ID="lblFacilityInfInjAuditor" Text=""  runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>FacilityProcedures:</b></td>
                            <td align="right">
                                <asp:Label ID="lblFacilityProcAuditor" Text=""  runat="server" ></asp:Label>
                            </td>
 
                        </tr>
                        
                        <tr>
                            <td></td>
                            <td><b>Physician Service:</b></td>
                            <td align="right">
                                <asp:Label ID="lblPhysicianServiceAuditor" Text=""   runat="server" ></asp:Label>
                            </td>
                           <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Physician Procedures:</b></td>
                            <td align="right">
                                <asp:Label ID="lblPhysicianProcAuditor" Text=""  runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Diagnosis Coding:</b></td>
                            <td align="right">
                                <asp:Label ID="lblDiagnosisAuditor"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr id="trObsSummaryAuditor" runat="server" >
                            <td></td>
                            <td><b>Obs Hours:</b></td>
                            <td align="right">
                                <asp:Label ID="lblObsHoursAuditor" Text=""   runat="server" ></asp:Label>
                            </td>
                           <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Obs Inf/Inj:</b></td>
                            <td align="right">
                                <asp:Label ID="lblObsInfInjAuditor" Text=""  runat="server" ></asp:Label>
                            </td>
                            <td>&nbsp;&nbsp;&nbsp;</td>
                            <td><b>Obs Procedures:</b></td>
                            <td align="right">
                                <asp:Label ID="lblObsProcAuditor"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td></td>
                            <td><b>  Total Accuracy:</b></td>
                            <td align="right">
                                <asp:Label ID="lblTotalRateAuditor" Text=""  runat="server" ></asp:Label>
                            </td>
                        </tr>
                    </table>
                    <table style="width=90%">
                          <tr>
                            <td style="width:70%">
                            <asp:Label ID="Label12" CssClass="FieldLabel"  Text="Second Level Auditor Changes to Charts Audited by this User"  Font-Size="small" runat="server" ></asp:Label>
                            </td>
                        </tr>
                    </table>   

                    <table style="width:97%">
                    <tr>
                        <td valign="top" align="left">
                        <asp:DataGrid ID="grdResultsAuditor" runat="server" OnItemCommand="grdResults_ItemCommand" OnItemDataBound="grdResultsAuditor_ItemDataBound"  CssClass="ListTable"
                        AutoGenerateColumns="False" DataKeyField="ChartID" AllowPaging="False">
                            <AlternatingItemStyle CssClass="ListRow2"></AlternatingItemStyle>
                            <ItemStyle CssClass="ListRow1"></ItemStyle>
                            <HeaderStyle CssClass="ColHeading"></HeaderStyle>                        
                          <Columns>
                          <asp:BoundColumn Visible="False" DataField="ChartID"></asp:BoundColumn>
                          <asp:TemplateColumn HeaderText="">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle HorizontalAlign="Left"></ItemStyle>
                            <ItemTemplate>
                                <asp:LinkButton id="lnkAuditReviewAuditor" runat="server" CommandName="AuditReview"  >View</asp:LinkButton>
                            </ItemTemplate>
                           </asp:TemplateColumn>
                          <asp:BoundColumn DataField="FacilityName" HeaderText="Facility" >
                            <ItemStyle Width="20%"></ItemStyle>
                          </asp:BoundColumn>
                          <asp:BoundColumn DataField="FacilityChartID" HeaderText="Account #">
                            <ItemStyle Width="10%"></ItemStyle>
                          </asp:BoundColumn>
                          <asp:BoundColumn DataField="DateApprovedString" HeaderText="Date Approved">
                            <ItemStyle Width="10%"></ItemStyle>
                          </asp:BoundColumn>

                          <asp:TemplateColumn HeaderText="Facility LOS">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                            <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityLOSPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityLOSPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblFacilityLOSCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityLOSComment") %>'></asp:Label>
                            </ItemTemplate>
                           </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Facility Inf/Inj">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityInfInjPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityInfInjPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblFacilityInfInjCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityInfInjComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Facility Proc">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityProcPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityProcPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblFacilityProcCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "FacilityProcComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Physician E&M">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblPhysicianLOSPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "PhysicianLOSPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblPhysicianLOSCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "PhysicianLOSComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Physician Proc">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblPhysicianProcPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "PhysicianProcPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblPhysicianProcCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "PhysicianProcComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Dx Coding">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblDiagnosisPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "DiagnosisPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblDiagnosisCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "DiagnosisComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Demographics">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblDemographicsPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "DemographicsPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblDemographicsCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "DemographicsComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>


                          <asp:TemplateColumn HeaderText="Obs Hours">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblObsHoursPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "ObsHoursPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblObsHoursCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "ObsHoursComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Obs Inf/Inj" >
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblObsInfInjPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "ObsInfInjPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblObsInfInjCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "ObsInfInjComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Obs Proc">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "17%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblObsProcPassFailAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "ObsProcPassFail") %>'></asp:Label>
                              </br>
                              <asp:Label runat="server" ID="lblObsProcCommentAuditor" Text='<%# DataBinder.Eval(Container.DataItem, "ObsProcComment") %>'></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>
                          <asp:TemplateColumn HeaderText="Auditor Actions">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width= "20%" HorizontalAlign="Left"></ItemStyle>
                           <ItemTemplate>
                               <asp:ListBox ID="lstChartAuditActionsAuditor" runat="server" CssClass="StdInput"></asp:ListBox>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:BoundColumn Visible="False" DataField="FacilityLOSPassFail" HeaderText="Facility Service"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="FacilityInfInjPassFail" HeaderText="Facility Inf/Inj"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="FacilityProcPassFail" HeaderText="Facility Proc"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="PhysicianLOSPassFail" HeaderText="Physician E&M"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="PhysicianProcPassFail" HeaderText="Physician Proc"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="DiagnosisPassFail" HeaderText="Diagnosis Coding"></asp:BoundColumn>
                          <asp:BoundColumn Visible="False" DataField="DemographicsPassFail" HeaderText="Demographics"></asp:BoundColumn>
                        </Columns>
                      </asp:DataGrid>
                    </td>
                    </tr>
                    </table>                                     
                    </div>

                    <div id="divScorecardCoderResults" runat="server" visible="false">
                        <br /> &nbsp;   
                        <asp:Label ID="lblCoderScorecard" CssClass="FieldLabel"  Text="<b>Coder Scorecard</b>" Font-Size="Medium" runat="server" ></asp:Label>
                        <br /><br />
                        <table border="1" runat="server"  id="tblScorecardCoderAccuracy">
                        <tr>
                            <td colspan="2"  class="ColHeading">
                                <asp:Label ID="Label20"  Text="<b>Code Assignment Accuracy </b> " runat="server" ></asp:Label>
                            </td> 
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label21" Text="Number of Accurate Codes: " Width="200px"  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCountAccurateCodes" Width="60px"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label22" Text="Number of Codes Revised: " Width="200px"  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCountRevisions" Width="60px"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label23" Text="Number of Codes Added: " Width="200px"  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCountAdditions" Width="60px"  runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label24" Text="Number of Codes Removed: "  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCountDeletions" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label25" Text="Coder Accuracy: " CssClass="FieldLabel" runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCoderAccuracy"  CssClass="FieldLabel" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr></tr>
                        <tr></tr>
                    </table>   
                    <br />
                    <table id="tblScorecardCoderSummary" runat="server" border="1">
                        <tr>
                            <td class="ColHeading" colspan="2">
                                <asp:Label ID="Label18" Text="Audit Scope"   runat="server" ></asp:Label>
                            </td>
                            <td class="ColHeading" colspan="2">
                                <asp:Label ID="Label6" Text="Coding Specifics"   runat="server" ></asp:Label>
                            </td>
                            <td class="ColHeading" colspan="2">
                                <asp:Label ID="Label7" Text="Additional Quality Monitoring Items"   runat="server" ></asp:Label>
                            </td>
                        </tr>

                        <tr>
                            <td >
                                <asp:Label ID="Label2"  Width="200px" Text="Number of Charts Coded: "  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblTotalChartsCoded" width="60px" runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label4" Text="Diagnosis: "  Width="200px" runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblDxAccuracy"  runat="server"  Width="60px" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label11" Text="Chief Complaint Assignment: "  Width="200px" runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblChiefComplaintAccuracy"   runat="server"  Width="60px"></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label3" Text="Number of Charts Reviewed: "  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblTotalChartsAudited"  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label9" Text="Facility CPT-4/HCPCS: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblFacilityCPTAccuracy"   runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label13" Text="Principal Diagnosis: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblPrimaryDxAccuracy"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label19" Text="Percent Reviewed: "  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblPercentReviewed"   runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label5" Text="Professional Fee E/M: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblPhysicianServicesAccuracy"  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label14" Text="Injection and Infusion: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblInfInjAccuracy" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                            <td>
                                <asp:Label ID="Label8" Text="Facility E/M:"  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblFacilityServicesAccuracy"   runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label15" Text="Modifier Usage: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblModifierUsageAccuracy"  runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                            <td>
                                <asp:Label ID="Label26" Text="Professional CPT-4/HCPCS: "  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblProfCPTAccuracy"   runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label16" Text="Demographics: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblDemographicsAccuracy"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                            <td>
                                <asp:Label ID="Label47" Text="Anesthesia: "  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblAnesthesiaAccuracy" runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label27" Text="Observation Hours: " runat="server"></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblObsHoursAccuracy" runat="server"></asp:Label>
                            </td>
                        </tr>
                    <tr>
                        <td></td>
                        <td></td>
                        <td></td>
                        <td></td>
                        <td>
                            <asp:Label ID="Label56" Text="MIPS Measures: "  runat="server" ></asp:Label>                            
                        </td>
                        <td>
                            <asp:Label ID="lblMIPSAccuracy"   runat="server" ></asp:Label>                                
                        </td>
                    </tr>
                    <tr>
                        <td></td>
                        <td></td>
                        <td></td>
                        <td></td>
                        <td>
                            <asp:Label ID="Label55" Text="Documentation Deficiency: " runat="server"></asp:Label>                            
                        </td>
                        <td>
                            <asp:Label ID="lblDocumentationDeficiencyAccuracy" runat="server"></asp:Label>                                
                        </td>
                    </tr>
                    <tr>
                        <td></td>
                        <td></td>
                        <td>
                            <asp:Label ID="Label10" Text="Overall Accuracy: " runat="server"></asp:Label>
                        </td>
                        <td>
                            <asp:Label ID="lblOverallAccuracy" runat="server"></asp:Label>
                        </td>
                        <td></td>
                        <td></td>
                    </tr>
                    <tr></tr>
                        </table>
                    <br />
                    <table style="width=90%">
                            <tr>
                            <td style="width:70%">
                            <asp:Label ID="Label17" CssClass="FieldLabel"  Text="Auditor Changes to Charts Completed by this User"  Font-Size="small" runat="server" ></asp:Label>
                            </td>
                        </tr>
                    </table>   

                    <table style="width:97%" id="tblCoderDetailsGrid" runat="server">
                    <tr >
                        <td valign="top" align="left">
                            <asp:DataGrid ID="grdScorecardCoderDetails" runat="server" OnItemDataBound="grdScorecardCoderDetails_ItemDataBound" OnItemCommand="grdScorecardResults_ItemCommand" CssClass="ListTable"
                        AutoGenerateColumns="False" DataKeyField="ChartID" AllowPaging="False">
                            <AlternatingItemStyle CssClass="ListRow2"></AlternatingItemStyle>
                            <ItemStyle CssClass="ListRow1"></ItemStyle>
                            <HeaderStyle CssClass="ColHeading"></HeaderStyle>                        
                          <Columns>
                          <asp:BoundColumn Visible="False" DataField="ChartID"></asp:BoundColumn>
                          <asp:TemplateColumn HeaderText="">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width="20px"  HorizontalAlign="Center"></ItemStyle>
                            <ItemTemplate>
                                <asp:LinkButton id="lnkAuditReviewCoder" CommandName="AuditReview"  runat="server">View</asp:LinkButton>
                            </ItemTemplate>
                           </asp:TemplateColumn>
                          <asp:BoundColumn DataField="ServiceAgreementDescription" HeaderText="Facility" >
                            <ItemStyle Width="20%" HorizontalAlign="Center"></ItemStyle>
                          </asp:BoundColumn>
                          <asp:BoundColumn DataField="FacilityChartID" HeaderText="Account #">
                            <ItemStyle Width="10%" HorizontalAlign="Center"></ItemStyle>
                          </asp:BoundColumn>
                          <asp:TemplateColumn HeaderText="Date Approved">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "10%" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblDateApproved"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>
                          <asp:TemplateColumn HeaderText="Facility LOS">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                            <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityLOSPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                           </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Inf / Inj">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityInfInjPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Facility Proc">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityProcPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Physician E/M">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblPhysicianLOSPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Physician Proc">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblPhysicianProcPassFail" ></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Dx Coding">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblDiagnosisPassFail" ></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Obs Hours" >
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblObsHoursPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Anesthesia Coding">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblAnesthesiaPassFail" ></asp:Label>
                              </br>
                          </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Auditor Notes">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "250px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblAuditorNotes"></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>
                        </Columns>
                      </asp:DataGrid>
                        </td>
                    </tr>
                    </table>
                        <br /><br />
                        <asp:Label ID="lblAuditorScorecard" CssClass="FieldLabel"  Text="<b>Auditor Scorecard</b>" Font-Size="Medium" runat="server" ></asp:Label>
                        <br /><br />
                        <table border="1" runat="server"  id="tblScorecardAuditorAccuracy">
                        <tr>
                            <td colspan="2"  class="ColHeading">
                                <asp:Label ID="Label48"  Text="<b>Code Assignment Accuracy </b> " runat="server" ></asp:Label>
                            </td> 
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label49" Text="Number of Accurate Codes: " Width="200px"  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCountAccurateCodesAuditor" Width="60px"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label50" Text="Number of Codes Revised: " Width="200px"  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCountRevisionsAuditor" Width="60px"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label51" Text="Number of Codes Added: " Width="200px"  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCountAdditionsAuditor" Width="60px"  runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label52" Text="Number of Codes Removed: "  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblCountDeletionsAuditor" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label53" Text="Auditor Accuracy: " CssClass="FieldLabel" runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblAuditorAccuracy"  CssClass="FieldLabel" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr></tr>
                        <tr></tr>
                    </table>   
                    <br />
                    <table id="tblScorecardAuditorSummary" runat="server" border="1">
                        <tr>
                            <td class="ColHeading" colspan="2">
                                <asp:Label ID="Label28" Text="Audit Scope"   runat="server" ></asp:Label>
                            </td>
                            <td class="ColHeading" colspan="2">
                                <asp:Label ID="Label29" Text="Coding Specifics"   runat="server" ></asp:Label>
                            </td>
                            <td class="ColHeading" colspan="2">
                                <asp:Label ID="Label30" Text="Additional Quality Monitoring Items"   runat="server" ></asp:Label>
                            </td>
                        </tr>

                        <tr>
                            <td >
                                <asp:Label ID="Label31"  Width="200px" Text="Number of Charts Approved by Auditor"  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblChartsApproved" width="60px" runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label33" Text="Diagnosis: "  Width="200px" runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblDxAccuracyAuditor"  runat="server"  Width="60px" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label34" Text="Chief Complaint Assignment: "  Width="200px" runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblChiefComplaintAccuracyAuditor"   runat="server"  Width="60px"></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label35" Text="Number of Charts 2nd Level Audited"  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblTotalChartsSecondAudited"  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label36" Text="Facility CPT-4/HCPCS: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblFacilityCPTAccuracyAuditor"   runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label37" Text="Principal Diagnosis: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblPrimaryDxAccuracyAuditor"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="Label38" Text="Percent Reviewed: "  runat="server" ></asp:Label>
                            </td> 
                            <td>
                                <asp:Label ID="lblPercentReviewedAuditor"   runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label39" Text="Professional Fee E/M: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblPhysicianServicesAccuracyAuditor"  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label40" Text="Injection and Infusion: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblInfInjAccuracyAuditor" runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                            <td>
                                <asp:Label ID="Label41" Text="Facility E/M:"  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblFacilityServicesAccuracyAuditor"   runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label42" Text="Modifier Usage: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblModifierUsageAccuracyAuditor"  runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                            <td>
                                <asp:Label ID="Label43" Text="Professional CPT-4/HCPCS: "  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblProfCPTAccuracyAuditor"   runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="Label44" Text="Demographics: " runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblDemographicsAccuracyAuditor"   runat="server" ></asp:Label>
                            </td>
                        </tr>
                        <tr>
                            <td></td>
                            <td></td>
                            <td>
                                <asp:Label ID="Label1" Text="Anesthesia: "  runat="server" ></asp:Label>
                            </td>
                            <td>
                                <asp:Label ID="lblAnesthesiaAccuracyAuditor" runat="server" ></asp:Label>
                            </td>
                        <td>
                            <asp:Label ID="Label45" Text="Observation Hours: " runat="server"></asp:Label>
                        </td>
                        <td>
                            <asp:Label ID="lblObsHoursAccuracyAuditor" runat="server"></asp:Label>
                        </td>
                    </tr>
                        <tr>
                            <td></td>
                            <td></td>
                            <td></td>
                            <td></td>
                            <td>
                                <asp:Label ID="Label58" Text="MIPS Measures: "  runat="server" ></asp:Label>                            
                            </td>
                            <td>
                                <asp:Label ID="lblMIPSAccuracyAuditor"   runat="server" ></asp:Label>                                
                            </td>
                        </tr>
                    <tr>
                        <td></td>
                        <td></td>
                        <td>
                            <asp:Label ID="Label46" Text="Overall Accuracy: " runat="server"></asp:Label>
                        </td>
                        <td>
                            <asp:Label ID="lblOverallAccuracyAuditor" runat="server"></asp:Label>
                        </td>
                        <td>
                            <asp:Label ID="Label32" Text="Documentation Deficiency: "  runat="server" ></asp:Label>                            
                        </td>
                        <td>
                            <asp:Label ID="lblDocumentationDeficiencyAccuracyAuditor"   runat="server" ></asp:Label>                                
                        </td>
                    </tr>
                    <tr></tr>
                        </table>
                    <br />
                    <table style="width=90%">
                            <tr>
                            <td style="width:70%">
                            <asp:Label ID="lblSecondAuditGridHeading" CssClass="FieldLabel"  Text="Second Auditor Changes to Charts Approved by this User"  Font-Size="small" runat="server" ></asp:Label>
                            </td>
                        </tr>
                    </table>   


                    <table style="width:97%" id="tblAuditorDetailsGrid" runat="server">
                    <tr>
                        <td valign="top" align="left">
                            <asp:DataGrid ID="grdScorecardAuditorDetails" runat="server" OnItemDataBound="grdScorecardAuditorDetails_ItemDataBound" OnItemCommand="grdScorecardResults_ItemCommand" CssClass="ListTable"
                        AutoGenerateColumns="False" DataKeyField="ChartID" AllowPaging="False">
                            <AlternatingItemStyle CssClass="ListRow2"></AlternatingItemStyle>
                            <ItemStyle CssClass="ListRow1"></ItemStyle>
                            <HeaderStyle CssClass="ColHeading"></HeaderStyle>                        
                          <Columns>
                          <asp:BoundColumn Visible="False" DataField="ChartID"></asp:BoundColumn>
                          <asp:TemplateColumn HeaderText="">
                            <HeaderStyle HorizontalAlign="Left"></HeaderStyle>
                            <ItemStyle Width="20px"  HorizontalAlign="Center"></ItemStyle>
                            <ItemTemplate>
                                <asp:LinkButton id="lnkAuditReviewCoder" CommandName="AuditReview"  runat="server">View</asp:LinkButton>
                            </ItemTemplate>
                           </asp:TemplateColumn>
                          <asp:BoundColumn DataField="ServiceAgreementDescription" HeaderText="Facility" >
                            <ItemStyle Width="20%" HorizontalAlign="Center"></ItemStyle>
                          </asp:BoundColumn>
                          <asp:BoundColumn DataField="FacilityChartID" HeaderText="Account #">
                            <ItemStyle Width="10%" HorizontalAlign="Center"></ItemStyle>
                          </asp:BoundColumn>
                          <asp:TemplateColumn HeaderText="Date Approved">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "10%" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblDateApproved"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>
                          <asp:TemplateColumn HeaderText="Facility LOS">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                            <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityLOSPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                           </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Inf / Inj">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityInfInjPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Facility Proc">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblFacilityProcPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Physician E/M">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblPhysicianLOSPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Physician Proc">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblPhysicianProcPassFail" ></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Dx Coding">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblDiagnosisPassFail" ></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Obs Hours" >
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "30px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblObsHoursPassFail"></asp:Label>
                              </br>
                            </ItemTemplate>
                          </asp:TemplateColumn>

                          <asp:TemplateColumn HeaderText="Auditor Notes">
                            <HeaderStyle HorizontalAlign="Center"></HeaderStyle>
                            <ItemStyle Width= "250px" HorizontalAlign="Center"></ItemStyle>
                           <ItemTemplate>
                              <asp:Label runat="server" ID="lblAuditorNotes"></asp:Label>
                            </ItemTemplate>
                          </asp:TemplateColumn>
                        </Columns>
                      </asp:DataGrid>
                        </td>
                    </tr>
                    </table>                                     
                    </div>
                    <table>
                        <tr>
                            <td style="width:100%" align="left">
                                <br /><br />
<%--                                <asp:CheckBox id="chkMarkAsReviewed" text="I have reviewed the QA feedback on this page." runat="server"></asp:CheckBox>--%>
                                <br />
                                <asp:Button ID="btnMarkAsReviewed"  OnClientClick="this.disabled = true;"  UseSubmitBehavior="false" 
                                    OnClick="btnMarkAsReviewed_Click" runat="server" CssClass="StdButton" Text="I certify that I have reviewed the QA feedback on this page" />
                             <br />
                             </td>
                        </tr>
                    </table>
                </div>


            </div>
        </asp:Panel>
</asp:Panel>


