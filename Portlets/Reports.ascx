<%@ Control Language="c#" Inherits="CCSWeb.WebPages.Controls.Portlets.Reports" CodeBehind="Reports.ascx.cs" %>
<style type="text/css">
    .indent{ padding-left:20px; }
    .col1{ float:left; }
    .col2{ float:right; }
    .mid{ float:right; width:50%; }
    .ColPanel{ margin-bottom:5px; overflow:auto }
 </style>
<script type="text/javascript">


function ToggleAll(expand) {
  for (var i = 1; i <= 20; i++) {
    var name = 'CollapseBehavior' + i;
    var theBehavior = $find(name);

    if (theBehavior) {
      var isCollapsed = theBehavior.get_Collapsed();
      if (isCollapsed && expand) {
        theBehavior.expandPanel();
      }
      else if (!isCollapsed && !expand) {
        theBehavior.collapsePanel();
      }
    }
    else {
      break;
    }
  }
};
</script>
<asp:Panel ID="pnl" runat="server">
  <span class="PortalHeader">Reports</span>&nbsp;&nbsp;
  <asp:HyperLink ID="lnkAddReport" runat="server" CssClass="CommandButton" NavigateUrl="../../EditPortalReports.aspx?ItemID=-1">Add Report</asp:HyperLink>
     <asp:Button ID="btnExpandAll" runat="server" CssClass="StdButton" Text="Expand All" OnClientClick="ToggleAll(true); return false;" />
     <asp:Button ID="btnCollapseAll" runat="server" CssClass="StdButton" Text="Collapse All" OnClientClick="ToggleAll(false); return false;" />
  <hr noshade="noshade" size="1" />
     <div id="mainDiv" style="height: 635px; width: 777px; overflow: auto;">
         <div class="ColPanel">
            <asp:Panel ID="Panel10" runat="server">
              <div class="GroupBoxTitle" style="height: 20px;">
                <div class="col1">
                  <asp:Label ID="Label7" runat="server" Text="Documentation Improvement: "></asp:Label>
                </div>
                <div class="col2">
                  <asp:Label ID="Label2" runat="server" Text="" CssClass="CollapsePanel"></asp:Label>
                </div>
                <br style="clear: both;" />
              </div>
            </asp:Panel>
             <asp:Panel ID="pnlDocmentationImprovement" runat="server" CssClass="GroupBox">
                 <table>
                     <tr>
                         <td>
                              <asp:DataList ID="grdDocumentationImprovement" runat="server" EnableViewState="false" Width="100%" CellPadding="4"
                                OnItemDataBound="grdDocumentationImprovement_ItemDataBound">
                                <ItemTemplate>
                                  <span class="PortalItemTitle">
                                    <asp:HyperLink ID="editLink" ImageUrl="../../images/edit.gif" Visible='<%# CanEdit()%>' Text="Edit"
                                      NavigateUrl='<%# "../../EditPortalReports.aspx?ItemID=" + Eval("PortalReportID")  %>'
                                      runat="server" />
                                    <asp:HyperLink ID="lnkViewSpecs" Text="(Specs)" runat="server" />
                                    <asp:LinkButton ID="lbGoToReport" runat="server" CommandName="GoToReport" CommandArgument='<%# Eval("PortalReportID") %>'
                                      OnCommand="Command_Click" Text='<%# Server.HtmlEncode(Eval("Name").ToString()) %>' />
                                  </span>
                                  <span class="PortalNormal">
                                    <%# Server.HtmlEncode(Eval("Description").ToString()) %>
                                  </span>
                                  <br />
                                </ItemTemplate>
                              </asp:DataList>
                         </td>
                     </tr>
                 </table>
             </asp:Panel>
             <ajx:CollapsiblePanelExtender ID="CollapsiblePanelExtender1" runat="server" 
              Collapsed="true" CollapsedText="(Show Reports...)" ExpandedText="(Hide Reports...)"
              ExpandDirection="Vertical" TargetControlID="pnlDocmentationImprovement"
              ScrollContents="true" BehaviorID="CollapseBehavior1">
            </ajx:CollapsiblePanelExtender>
          </div>
         <div class="ColPanel">
            <asp:Panel ID="Panel2" runat="server">
              <div class="GroupBoxTitle" style="height: 20px;">
                <div class="col1">
                  <asp:Label ID="Label4" runat="server" Text="Productivity: "></asp:Label>
                </div>
                <div class="col2">
                  <asp:Label ID="Label5" runat="server" Text="" CssClass="CollapsePanel"></asp:Label>
                </div>
                <br style="clear: both;" />
              </div>
            </asp:Panel>
             <asp:Panel ID="pnlProductivity" runat="server" CssClass="GroupBox">
                 <table>
                     <tr>
                         <td>
                              <asp:DataList ID="grdProductivity" runat="server" EnableViewState="false" Width="100%" CellPadding="4"
                                OnItemDataBound="grdProductivity_ItemDataBound">
                                <ItemTemplate>
                                  <span class="PortalItemTitle">
                                    <asp:HyperLink ID="editLink" ImageUrl="../../images/edit.gif" Visible='<%# CanEdit()%>' Text="Edit"
                                      NavigateUrl='<%# "../../EditPortalReports.aspx?ItemID=" + Eval("PortalReportID")  %>'
                                      runat="server" />
                                    <asp:HyperLink ID="lnkViewSpecs" Text="(Specs)" runat="server" />
                                    <asp:LinkButton ID="lbGoToReport" runat="server" CommandName="GoToReport" CommandArgument='<%# Eval("PortalReportID") %>'
                                      OnCommand="Command_Click" Text='<%# Server.HtmlEncode(Eval("Name").ToString()) %>' />
                                  </span>
                                  <span class="PortalNormal">
                                    <%# Server.HtmlEncode(Eval("Description").ToString()) %>
                                  </span>
                                  <br />
                                </ItemTemplate>
                              </asp:DataList>
                         </td>
                     </tr>
                 </table>
             </asp:Panel>
             <ajx:CollapsiblePanelExtender ID="CollapsiblePanelExtender3" runat="server"
              Collapsed="true" CollapsedText="(Show Reports...)" ExpandedText="(Hide Reports...)"
              ExpandDirection="Vertical" TargetControlID="pnlProductivity"
              ScrollContents="true" BehaviorID="CollapseBehavior3">
            </ajx:CollapsiblePanelExtender>
          </div>
         <div class="ColPanel">
            <asp:Panel ID="Panel5" runat="server">
              <div class="GroupBoxTitle" style="height: 20px;">
                <div class="col1">
                  <asp:Label ID="Label9" runat="server" Text="Reconcilation: "></asp:Label>
                </div>
                <div class="col2">
                  <asp:Label ID="Label10" runat="server" Text="" CssClass="CollapsePanel"></asp:Label>
                </div>
                <br style="clear: both;" />
              </div>
            </asp:Panel>
             <asp:Panel ID="pnlReconcliation" runat="server" CssClass="GroupBox">
                 <table>
                     <tr>
                         <td>
                              <asp:DataList ID="grdReconciliation" runat="server" EnableViewState="false" Width="100%" CellPadding="4"
                                OnItemDataBound="grdReconciliation_ItemDataBound">
                                <ItemTemplate>
                                  <span class="PortalItemTitle">
                                    <asp:HyperLink ID="editLink" ImageUrl="../../images/edit.gif" Visible='<%# CanEdit()%>' Text="Edit"
                                      NavigateUrl='<%# "../../EditPortalReports.aspx?ItemID=" + Eval("PortalReportID")  %>'
                                      runat="server" />
                                    <asp:HyperLink ID="lnkViewSpecs" Text="(Specs)" runat="server" />
                                    <asp:LinkButton ID="lbGoToReport" runat="server" CommandName="GoToReport" CommandArgument='<%# Eval("PortalReportID") %>'
                                      OnCommand="Command_Click" Text='<%# Server.HtmlEncode(Eval("Name").ToString()) %>' />
                                  </span>
                                  <span class="PortalNormal">
                                    <%# Server.HtmlEncode(Eval("Description").ToString()) %>
                                  </span>
                                  <br />
                                </ItemTemplate>
                              </asp:DataList>
                         </td>
                     </tr>
                 </table>
             </asp:Panel>
             <ajx:CollapsiblePanelExtender ID="CollapsiblePanelExtender5" runat="server"
              Collapsed="true" CollapsedText="(Show Reports...)" ExpandedText="(Hide Reports...)"
              ExpandDirection="Vertical" TargetControlID="pnlReconcliation"
              ScrollContents="true" BehaviorID="CollapseBehavior4">
            </ajx:CollapsiblePanelExtender>
          </div>
         <div class="ColPanel">
            <asp:Panel ID="Panel7" runat="server">
              <div class="GroupBoxTitle" style="height: 20px;">
                <div class="col1">
                  <asp:Label ID="Label11" runat="server" Text="Statistics - Facility: "></asp:Label>
                </div>
                <div class="col2">
                  <asp:Label ID="Label12" runat="server" Text="" CssClass="CollapsePanel"></asp:Label>
                </div>
                <br style="clear: both;" />
              </div>
            </asp:Panel>
             <asp:Panel ID="pnlStatFacility" runat="server" CssClass="GroupBox">
                 <table>
                     <tr>
                         <td>
                              <asp:DataList ID="grdStatFacility" runat="server" EnableViewState="false" Width="100%" CellPadding="4"
                                OnItemDataBound="grdStatFacility_ItemDataBound">
                                <ItemTemplate>
                                  <span class="PortalItemTitle">
                                    <asp:HyperLink ID="editLink" ImageUrl="../../images/edit.gif" Visible='<%# CanEdit()%>' Text="Edit"
                                      NavigateUrl='<%# "../../EditPortalReports.aspx?ItemID=" + Eval("PortalReportID")  %>'
                                      runat="server" />
                                    <asp:HyperLink ID="lnkViewSpecs" Text="(Specs)" runat="server" />
                                    <asp:LinkButton ID="lbGoToReport" runat="server" CommandName="GoToReport" CommandArgument='<%# Eval("PortalReportID") %>'
                                      OnCommand="Command_Click" Text='<%# Server.HtmlEncode(Eval("Name").ToString()) %>' />
                                  </span>
                                  <span class="PortalNormal">
                                    <%# Server.HtmlEncode(Eval("Description").ToString()) %>
                                  </span>
                                  <br />
                                </ItemTemplate>
                              </asp:DataList>
                         </td>
                     </tr>
                 </table>
             </asp:Panel>
             <ajx:CollapsiblePanelExtender ID="CollapsiblePanelExtender6" runat="server" 
              Collapsed="true" CollapsedText="(Show Reports...)" ExpandedText="(Hide Reports...)"
              ExpandDirection="Vertical" TargetControlID="pnlStatFacility"
              ScrollContents="true" BehaviorID="CollapseBehavior5">
            </ajx:CollapsiblePanelExtender>
          </div>
         <div class="ColPanel">
            <asp:Panel ID="Panel3" runat="server">
              <div class="GroupBoxTitle" style="height: 20px;">
                <div class="col1">
                  <asp:Label ID="Label6" runat="server" Text="Statistics - Provider: "></asp:Label>
                </div>
                <div class="col2">
                  <asp:Label ID="Label8" runat="server" Text="" CssClass="CollapsePanel"></asp:Label>
                </div>
                <br style="clear: both;" />
              </div>
            </asp:Panel>
             <asp:Panel ID="pnlStatProvider" runat="server" CssClass="GroupBox">
                 <table>
                     <tr>
                         <td>
                              <asp:DataList ID="grdStatProvider" runat="server" EnableViewState="false" Width="100%" CellPadding="4"
                                OnItemDataBound="grdStatProvider_ItemDataBound">
                                <ItemTemplate>
                                  <span class="PortalItemTitle">
                                    <asp:HyperLink ID="editLink" ImageUrl="../../images/edit.gif" Visible='<%# CanEdit()%>' Text="Edit"
                                      NavigateUrl='<%# "../../EditPortalReports.aspx?ItemID=" + Eval("PortalReportID")  %>'
                                      runat="server" />
                                    <asp:HyperLink ID="lnkViewSpecs" Text="(Specs)" runat="server" />
                                    <asp:LinkButton ID="lbGoToReport" runat="server" CommandName="GoToReport" CommandArgument='<%# Eval("PortalReportID") %>'
                                      OnCommand="Command_Click" Text='<%# Server.HtmlEncode(Eval("Name").ToString()) %>' />
                                  </span>
                                  <span class="PortalNormal">
                                    <%# Server.HtmlEncode(Eval("Description").ToString()) %>
                                  </span>
                                  <br />
                                </ItemTemplate>
                              </asp:DataList>
                         </td>
                     </tr>
                 </table>
             </asp:Panel>
             <ajx:CollapsiblePanelExtender ID="CollapsiblePanelExtender4" runat="server" CollapseControlID="Label8"
              Collapsed="true" ExpandControlID="Label8" CollapsedText="(Show Reports...)" ExpandedText="(Hide Reports...)"
              TextLabelID="Label8" ExpandDirection="Vertical" TargetControlID="pnlStatProvider"
              ScrollContents="true" BehaviorID="CollapseBehavior6">
            </ajx:CollapsiblePanelExtender>
          </div>
          <div class="ColPanel">
            <asp:Panel ID="Panel1" runat="server">
              <div class="GroupBoxTitle" style="height: 20px;">
                <div class="col1">
                  <asp:Label ID="Label1" runat="server" Text="Internal: "></asp:Label>
                </div>
                <div class="col2">
                  <asp:Label ID="Label3" runat="server" Text="" CssClass="CollapsePanel"></asp:Label>
                </div>
                <br style="clear: both;" />
              </div>
            </asp:Panel>
             <asp:Panel ID="pnlInternal" runat="server" CssClass="GroupBox">
                 <table>
                     <tr>
                         <td>
                              <asp:DataList ID="grdInternal" runat="server" EnableViewState="false" Width="100%" CellPadding="4"
                                OnItemDataBound="grdInternal_ItemDataBound">
                                <ItemTemplate>
                                  <span class="PortalItemTitle">
                                    <asp:HyperLink ID="editLink" ImageUrl="../../images/edit.gif" Visible='<%# CanEdit()%>' Text="Edit"
                                      NavigateUrl='<%# "../../EditPortalReports.aspx?ItemID=" + Eval("PortalReportID")  %>'
                                      runat="server" />
                                    <asp:HyperLink ID="lnkViewSpecs" Text="(Specs)" runat="server" />
                                    <asp:LinkButton ID="lbGoToReport" runat="server" CommandName="GoToReport" CommandArgument='<%# Eval("PortalReportID") %>'
                                      OnCommand="Command_Click" Text='<%# Server.HtmlEncode(Eval("Name").ToString()) %>' />
                                  </span>
                                  <span class="PortalNormal">
                                    <%# Server.HtmlEncode(Eval("Description").ToString()) %>
                                  </span>
                                  <br />
                                </ItemTemplate>
                              </asp:DataList>
                         </td>
                     </tr>
                 </table>
             </asp:Panel>
             
            <ajx:CollapsiblePanelExtender ID="CollapsiblePanelExtender2" runat="server"
            Collapsed="true"  CollapsedText="(Show Reports...)" ExpandedText="(Hide Reports...)"
            ExpandDirection="Vertical" TargetControlID="pnlInternal"
            ScrollContents="true" BehaviorID="CollapseBehavior2">
            </ajx:CollapsiblePanelExtender>

          </div>
 
  </div>
</asp:Panel>
