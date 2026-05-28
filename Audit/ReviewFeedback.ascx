<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="ReviewFeedback.ascx.cs" Inherits="CCSWebApp.WebPages.Controls.Audit.ReviewFeedback" %>
<table>
  <tr>
    <td>
      <h3>General Auditor Feedback</h3>
      <asp:TextBox Rows="5" CssClass="StdInput" TextMode="MultiLine" MaxLength="500" Columns="70"
                   ID="txtComment" onKeyUp="Count(this,500,'Auditer Review Feedback')"
                   onChange="Count(this,500,'Auditer Review Feedback')" runat="server"/>
    </td>
  </tr>
</table>