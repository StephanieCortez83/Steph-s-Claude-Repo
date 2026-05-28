using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.DAO;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace CCSWeb.WebPages.Controls
{
    public partial class ChartPhysicianProcedures : System.Web.UI.UserControl
    {
        private const int ADD_TO_FACILITY_EVALUATION_COLUMN_NUMBER = 0;
        private const int PROCEDURE_DATE_COLUMN_NUMBER = 7;
        private const int PHYSICIAN_COLUMN_NUMBER = 8;
        private const int INSUFFICIENT_DOC_TO_BILL_COLUMN_NUMBER = 9;

        public int ChartId { get; set; }
        public int ProcedureCategoryId { get; set; }
        
        private Chart Chart { get; set; }
        private WebRequestManager m_RequestManager { get; set; }
        private bool m_ControlsDisabled;

        protected void Page_Load(object sender, EventArgs e)
        {
            m_RequestManager = new WebRequestManager(Session);

            try
            {
                Chart = new Chart(ChartId, m_RequestManager);
                m_ControlsDisabled = !Chart.AllowSave;
                grdProcedures.DataSource = new PhysicianProcedureEvaluationListDAO(m_RequestManager).LoadAllForCategory(Chart.ChartID, Chart.ServiceAgreementID, ProcedureCategoryId);
                grdProcedures.DataBind();

                grdProcedures.Columns[PROCEDURE_DATE_COLUMN_NUMBER].Visible = Chart.ServiceAgreement.CollectProcedureDates.Required 
                    || Chart.ServiceAgreement.CollectProcedureDates.Optional;
                grdProcedures.Columns[PHYSICIAN_COLUMN_NUMBER].Visible = Chart.ServiceAgreement.CollectProcedurePhysicians.Required
                    || Chart.ServiceAgreement.CollectProcedurePhysicians.Optional;
                grdProcedures.Columns[INSUFFICIENT_DOC_TO_BILL_COLUMN_NUMBER].Visible = Chart.ServiceAgreement.PhysProcDisplayInsufficientDocToBillCheckbox;
                grdProcedures.Columns[ADD_TO_FACILITY_EVALUATION_COLUMN_NUMBER].Visible = Chart.ServiceAgreement.ShowAddToProceduresCheckboxOnProcedurePages;

                if (m_ControlsDisabled)
                {
                    var basePage = new CCSBasePage(m_RequestManager);
                    foreach (Control c in Page.Controls)
                    {
                        foreach (Control ctrl in c.Controls)
                        {
                            basePage.SetControlsEnabledStatus(ctrl, false);
                        }
                    }
                }
            }
            finally
            {
                m_RequestManager.EndRequest();
            }
        }

        protected void grdProcedures_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType == DataControlRowType.DataRow)
            {
                var hfSelectedPhysician = (HiddenField)e.Row.FindControl("hfSelectedPhysician");
                var obj = (PhysicianProcedureEvaluationListItem)e.Row.DataItem;
                var txtQuantity = (SpinButton)e.Row.FindControl("txtQuantity");
                var btnSelectModifier = (HtmlInputControl)e.Row.FindControl("btnSelectModifier");

                btnSelectModifier.Visible = obj.HasModifiers;

                // Only load up procedure date drop down if we are collecting procedure dates
                if (Chart.ServiceAgreement.CollectProcedureDates.Visible)
                {
                    DropDownList cmbProcedureDate = (DropDownList)e.Row.FindControl("cmbProcedureDate");
                    cmbProcedureDate.Items.Clear();
                    cmbProcedureDate.Items.Add(new ListItem(Chart.TimeOfService.ToShortDateString()));

                    // 5-5-2010 Changed to get days to add from Service Agreement
                    if ((Chart.ServiceAgreement.EvaluateObservationDepartments) && (Chart.PatientDispositionID == PatientDisposition.OBSERVATION))
                    {
                        if (Chart.ServiceAgreement.PhysProcAddlDatesOfServiceOBS > 0)
                        {
                            for (int i = 1; i <= Chart.ServiceAgreement.PhysProcAddlDatesOfServiceOBS; i++)
                            {
                                DateTime tmpDate = Chart.TimeOfService.AddDays(i);
                                cmbProcedureDate.Items.Add(new ListItem(tmpDate.ToShortDateString(), tmpDate.ToShortDateString()));
                            }
                        }
                    }
                    else
                    {
                        if (Chart.ServiceAgreement.PhysProcAddlDatesOfServiceNonOBS > 0)
                        {
                            for (int i = 1; i <= Chart.ServiceAgreement.PhysProcAddlDatesOfServiceNonOBS; i++)
                            {
                                DateTime tmpDate = Chart.TimeOfService.AddDays(i);
                                cmbProcedureDate.Items.Add(new ListItem(tmpDate.ToShortDateString(), tmpDate.ToShortDateString()));
                            }
                        }
                    }

                    try
                    {
                        if ((obj.ProcedureDate.Date > Chart.TimeOfService.Date) && (cmbProcedureDate.Items.FindByText(obj.ProcedureDate.ToShortDateString()) == null))
                        {
                            cmbProcedureDate.Items.Add(new ListItem(obj.ProcedureDate.ToShortDateString(), obj.ProcedureDate.ToShortDateString()));
                        }
                        cmbProcedureDate.SelectedValue = obj.ProcedureDate.ToShortDateString();
                    }
                    catch (Exception)
                    {
                        cmbProcedureDate.Items.Add(new ListItem(obj.ProcedureDate.ToShortDateString(), obj.ProcedureDate.ToShortDateString()));
                        cmbProcedureDate.SelectedValue = obj.ProcedureDate.ToShortDateString();
                    }
                }

                txtQuantity.MaxValue = obj.MaxQuantity;
                txtQuantity.MinValue = obj.AllowNegativeUnitsInd ? obj.MaxQuantity * -1 : 0;

                // Only load up physician drop down if we are collecting procedure physicians
                if (Chart.ServiceAgreement.CollectProcedurePhysicians.Visible)
                {
                    Label lblCPT = (Label)e.Row.FindControl("lblCPT");
                    Button btnSelectPhysician = (Button)e.Row.FindControl("btnSelectPhysician");
                    FacilityProfessionalDAO fpDAO = new FacilityProfessionalDAO(m_RequestManager);
                    Label lblPhysician = (Label)e.Row.FindControl("lblPhysician");

                    if (obj.Quantity != 0)
                        hfSelectedPhysician.Value = obj.PhysicianID.ToString();

                    if (hfSelectedPhysician.Value != "-1" && hfSelectedPhysician.Value != "")
                        lblPhysician.Text = fpDAO.GetPhysicianName(Convert.ToInt32(hfSelectedPhysician.Value));

                    else
                    {
                        if (Chart.ServiceAgreement.CollectProcedurePhysicians.Optional)
                            lblPhysician.Text = "Attending";
                        else
                            lblPhysician.Text = "Not Selected";

                        hfSelectedPhysician.Value = "-1";
                    }

                    if (string.IsNullOrEmpty(lblPhysician.Text))
                    {
                        if (DefaultToAttending(lblCPT.Text) && Convert.ToInt32(txtQuantity.Text) != 0 && Chart.PhysicianID != -1)
                        {
                            if (Chart.NursePractitionerID > 0)
                            {
                                //lblPhysician.Text = PhysicianProcedureEvalEnhanced.MIDLEVEL_LABEL;
                                hfSelectedPhysician.Value = Chart.NursePractitionerID.ToString();
                            }
                            else if (Chart.PhysicianID != -1)
                            {
                                //lblPhysician.Text = PhysicianProcedureEvalEnhanced.ATTENDING_LABEL;
                                hfSelectedPhysician.Value = Chart.PhysicianID.ToString();
                            }
                            else
                            {
                                if (Chart.NursePractitionerID > 0)
                                {
                                    btnSelectPhysician.Attributes.Remove("onclick");
                                    btnSelectPhysician.Attributes.Add("onclick", "SetSelectedPhysician(this, 'Nurse provider');");
                                }

                                else if (Chart.PhysicianID != -1)
                                {
                                    btnSelectPhysician.Attributes.Remove("onclick");
                                    btnSelectPhysician.Attributes.Add("onclick", "SetSelectedPhysician(this, 'Attending physician');");
                                }
                            }
                        }
                        else
                        {
                            if (Chart.ServiceAgreement.CollectProcedurePhysicians.Optional)
                            {
                                lblPhysician.Text = "Attending";
                            }

                            else
                            {
                                lblPhysician.Text = "Not Selected";
                            }

                            hfSelectedPhysician.Value = "-1";
                        }
                    }
                }

                // Only display the Insufficient Documentation to Bill checkbox if specified by the Service Agreement
                if (Chart.ServiceAgreement.PhysProcDisplayInsufficientDocToBillCheckbox)
                {
                    CheckBox chkInsufficientDocToBill = (CheckBox)e.Row.FindControl("chkInsufficientDocToBill");
                    chkInsufficientDocToBill.Checked = obj.InsufficientDocToBill;
                }

                if (Chart.ServiceAgreement.ShowAddToProceduresCheckboxOnProcedurePages)
                {
                    CheckBox chkAddToFacilityProcedure = (CheckBox)e.Row.FindControl("chkAddToFacilityProcedure");
                    chkAddToFacilityProcedure.Visible = chkAddToFacilityProcedure.Visible && !CPTCode.IsRadiologyCPT(obj.CPTCode) && obj.CPTCode != "93010";

                    bool visible = false;
                    if (chkAddToFacilityProcedure.Visible)
                    {
                        // see if the CPT code exists on the facility side
                        foreach (FacilityProcedureEvaluationListItem li in Chart.FacilityProcedures)
                        {
                            if (li.CPTCode == obj.CPTCode)
                            {
                                visible = true;
                                break;
                            }
                        }

                        // hide the checkbox if the CPT code does not exists on the facility side
                        chkAddToFacilityProcedure.Visible = visible;
                    }


                    chkAddToFacilityProcedure.Checked = chkAddToFacilityProcedure.Visible && obj.AddToFacilityProcedure;
                }
            }
        }

        private bool DefaultToAttending(String cptCode)
        {
            int iCpt=0;

            if (cptCode.Trim().ToUpper() != "SUPLY" && !int.TryParse(cptCode, out iCpt))
                return false;

            return ((cptCode.Trim().ToUpper() == "SUPLY") || (iCpt >= 90000 && iCpt <= 99999) || (iCpt == 51701 || iCpt == 51702) || (iCpt >= 29000 && iCpt <= 29999));
        }
    }
}