using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.DAO;
using CCSBusinessObjects.Services;
using CCSBusinessObjects.Utility;
using CCSWeb.WebPages.Controls;
using System.Resources;
using System.Globalization;
using System.Web.Security;
using System.Data.SqlClient;
using System.Configuration;

namespace CCSWeb.WebPages
{
    /// <summary>
    /// Summary description for SecurityView.
    /// </summary>
    public partial class AddExclusionRule : CCSBasePage //System.Web.UI.Page
    {
        // Named constants 
        private const int SERVICE_ITEM_TO_SERVICE_ITEM_EXCLUSION = 1;
        private const int SERVICE_ITEM_TO_PROCEDURE_EXCLUSION = 2;
        private const int SERVICE_ITEM_TO_PATIENT_DISPOSITION_EXCLUSION = 3;
        private const String DEFAULT_EXPIRATION_DATE = "12/31/2099";
        private const String ERROR_CSS_CLASS = "StdInputErr";

        // Private variables used by the form
        private ArrayList m_ServiceItemList; private int m_ExclusionTypeID;
        private ArrayList m_ServiceItemList2; private int m_UserProfileID;
        private ArrayList m_PatientDispositionList; private int m_PatientDispositionID;
        private ArrayList m_ExclusionTypeList; private int m_ExclusionItemID;
        private int m_FacilityServiceScheduleID; private DateTime m_ExpirationDate;
        private int m_FacilityServiceScheduleItemID; private DateTime m_EffectiveDate;
        private int m_FacilityServiceScheduleItemExclusionID; private String m_CPT_CODE;
        private FacilityServiceSchedule m_FacilityServiceSchedule;

        protected void Page_Load(object sender, System.EventArgs e)
        {
            m_RequestManager = Master.RequestManager;

            if (!IsAuthorized())
            {
                Response.Redirect("Unauthorized.aspx", false);
            }

            InitializeFormObjects();

            if (!IsPostBack)
            {
                LoadModel();
                ModelToView();
                setVisibleControls();
            }
        }

        /// <summary>
        /// Create any base objects needed by the form
        /// </summary>
        private void InitializeFormObjects()
        {
            UserProfile signedOnUserProfile = Master.RequestManager.SessionManager.SignedOnUserProfile;

            m_FacilityServiceScheduleID = -1;
            m_FacilityServiceScheduleItemExclusionID = -1;
            m_UserProfileID = signedOnUserProfile.UserProfileID;
            m_CPT_CODE = "";
            m_FacilityServiceSchedule = null;
        }


        /// <summary>
        /// Copies the values specified on the form into private member variables for processing
        /// </summary>
        private void GetFormData()
        {
            try
            {
                if (Request.QueryString["fssid"] != "")
                {
                    m_FacilityServiceScheduleID = Convert.ToInt32(Request.QueryString["fssid"]);
                }
                if (Request.QueryString["fssiid"] != "")
                {
                    m_FacilityServiceScheduleItemID = Convert.ToInt32(Request.QueryString["fssiid"]);
                }
                if (Request.QueryString["fssieid"] != "" && !Request.QueryString["btn"].Equals("addExclusion"))
                {
                    m_FacilityServiceScheduleItemExclusionID = Convert.ToInt32(Request.QueryString["fssieid"]);
                }
                if (TypeDropDownList.SelectedValue != "")
                {
                    m_ExclusionTypeID = Convert.ToInt32(TypeDropDownList.SelectedValue);
                }
                if (SI2PDDispositionDDL.SelectedValue != "")
                {
                    m_PatientDispositionID = Convert.ToInt32(SI2PDDispositionDDL.SelectedValue);
                }

                m_EffectiveDate = Convert.ToDateTime(txtEffectiveDate.Text);
                m_ExpirationDate = Convert.ToDateTime(txtExpirationDate.Text);

                if (SI2PCPTCodeTextBox.Text != "")
                {
                    m_CPT_CODE = SI2PCPTCodeTextBox.Text;
                }
                if (SI2SIServiceItem2DDL.SelectedValue != "")
                {
                    m_ExclusionItemID = Convert.ToInt32(SI2SIServiceItem2DDL.SelectedValue);
                }
            }

            catch (Exception ex)
            {
                WebRequestManager.SystemError(Response, Session, ex);
            }
        }

        /// <summary>
        /// Determines whether the user is authorized to the page and the data displayed on the
        /// page.
        /// </summary>
        /// <returns>True if the user can see the page and the requested data, false otherwise.</returns>
        public bool IsAuthorized()
        {
            bool result = false;
            UserProfile signedOnUserProfile = Master.RequestManager.SessionManager.SignedOnUserProfile;

            if (signedOnUserProfile != null)
            {
                if (signedOnUserProfile.HasRight(UserRight.RIGHT_USER_ADMINISTRATION))
                {
                    result = true;
                }
            }

            else
            {
                Response.Redirect("../login.aspx?ReturnUrl=WebPages/News.aspx");
            }

            return result;
        }

        /// <summary>
        /// Validates the form data
        /// </summary>
        /// <returns>True if all form data is valid.  False if not and error messages are created.</returns>
        private bool ValidFormData()
        {
            FacilityServiceScheduleItemDAO fssiDAO = new FacilityServiceScheduleItemDAO(Master.RequestManager);
            bool res = true;
            int errors = 0;

            SI2SIServiceItem1DDL.CssClass = "StdInput";
            SI2SIServiceItem2DDL.CssClass = "StdInput";
            SI2PDDispositionDDL.CssClass = "StdInput";
            SI2PCPTCodeTextBox.CssClass = "StdInput";
            txtEffectiveDate.CssClass = "StdInput";
            txtExpirationDate.CssClass = "StdInput";

            if (TypeDropDownList.SelectedItem.Text.Equals("Service Item to Service Item Exclusion") && SI2SIServiceItem2DDL.SelectedIndex == 0)
            {
                ErrorMessage errMsg = new ErrorMessage(367, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                errMsg.AddMessageData("%1", "Service Item 2");
                Master.RequestManager.ErrorMessages.Add(errMsg);
                SetFocusToFirstError(1, errors++);
                SI2SIServiceItem2DDL.CssClass = ERROR_CSS_CLASS;
                res = false;
            }

            else if (TypeDropDownList.SelectedItem.Text.Equals("Service Item to Patient Disposition Exclusion") && SI2PDDispositionDDL.SelectedIndex == 0)
            {
                ErrorMessage errMsg = new ErrorMessage(367, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                errMsg.AddMessageData("%1", "Patient Disposition");
                Master.RequestManager.ErrorMessages.Add(errMsg);
                SetFocusToFirstError(2, errors++);
                SI2PDDispositionDDL.CssClass = ERROR_CSS_CLASS;
                res = false;
            }

            else if (TypeDropDownList.SelectedItem.Text.Equals("Service Item to Procedure Exclusion") && SI2PCPTCodeTextBox.Text.Length == 0)
            {
                ErrorMessage errMsg = new ErrorMessage(367, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                errMsg.AddMessageData("%1", "CPT Code");
                Master.RequestManager.ErrorMessages.Add(errMsg);
                SetFocusToFirstError(3, errors++);
                SI2PCPTCodeTextBox.CssClass = ERROR_CSS_CLASS;
                res = false;
            }

            if (StringUtility.IsValidDateStr(txtEffectiveDate.Text) && StringUtility.IsValidDateStr(txtExpirationDate.Text))
            {
                m_EffectiveDate = Convert.ToDateTime(txtEffectiveDate.Text);
                m_ExpirationDate = Convert.ToDateTime(txtExpirationDate.Text);
                int parentServiceItemID;

                if (Request.QueryString["fssiid"] == null || Request.QueryString["fssiid"] == "")
                {
                    parentServiceItemID = Convert.ToInt32(SI2SIServiceItem1DDL.SelectedValue);
                }

                else
                {
                    parentServiceItemID = Convert.ToInt32(Request.QueryString["fssiid"]);
                }

                DateTime ParentItemEffectiveDate = Convert.ToDateTime(fssiDAO.GetDBValueByID(parentServiceItemID, "EFFECTIVE_DATE"));
                DateTime ParentItemExpirationDate = Convert.ToDateTime(fssiDAO.GetDBValueByID(parentServiceItemID, "EXPIRATION_DATE"));

                if (m_EffectiveDate > m_ExpirationDate)
                {
                    ErrorMessage errMsg = new ErrorMessage(106, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    SetFocusToFirstError(4, errors++);
                    txtEffectiveDate.CssClass = ERROR_CSS_CLASS;
                    res = false;
                }

                else
                {
                    if (m_EffectiveDate < ParentItemEffectiveDate || m_EffectiveDate > ParentItemExpirationDate)
                    {
                        ErrorMessage errMsg = new ErrorMessage(356, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                        errMsg.AddMessageData("%1", "Effective Date");
                        errMsg.AddMessageData("%2", ParentItemEffectiveDate.ToShortDateString());
                        errMsg.AddMessageData("%3", ParentItemExpirationDate.ToShortDateString());
                        Master.RequestManager.ErrorMessages.Add(errMsg);
                        SetFocusToFirstError(4, errors++);
                        txtEffectiveDate.CssClass = ERROR_CSS_CLASS;
                        res = false;
                    }

                    if (m_ExpirationDate < ParentItemEffectiveDate || m_ExpirationDate > ParentItemExpirationDate)
                    {
                        ErrorMessage errMsg = new ErrorMessage(356, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                        errMsg.AddMessageData("%1", "Expiration Date");
                        errMsg.AddMessageData("%2", ParentItemEffectiveDate.ToShortDateString());
                        errMsg.AddMessageData("%3", ParentItemExpirationDate.ToShortDateString());
                        Master.RequestManager.ErrorMessages.Add(errMsg);
                        SetFocusToFirstError(5, errors++);
                        txtExpirationDate.CssClass = ERROR_CSS_CLASS;
                        res = false;
                    }
                }  
            }

            else
            {
                if (!StringUtility.IsValidDateStr(txtEffectiveDate.Text))
                {
                    ErrorMessage errMsg = new ErrorMessage(74, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    SetFocusToFirstError(3, errors++);
                    txtEffectiveDate.CssClass = ERROR_CSS_CLASS;
                    res = false;
                }

                if (!StringUtility.IsValidDateStr(txtExpirationDate.Text))
                {
                    ErrorMessage errMsg = new ErrorMessage(75, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    SetFocusToFirstError(4, errors++);
                    txtExpirationDate.CssClass = ERROR_CSS_CLASS;
                    res = false;
                }
            }

            return res;
        }

        /// <summary>
        /// Loads the model data into the member data for the form
        /// </summary>
        private void LoadModel()
        {
            FacilityServiceScheduleExclusionDAO fsseDAO = new FacilityServiceScheduleExclusionDAO(Master.RequestManager);
            FacilityServiceScheduleItemDAO fssiDAO = new FacilityServiceScheduleItemDAO(Master.RequestManager);
            FacilityServiceExclusionTypeDAO fsetDAO = new FacilityServiceExclusionTypeDAO(Master.RequestManager);
            SimplePatientDispositionListDAO spdlDAO = new SimplePatientDispositionListDAO(Master.RequestManager);
            FacilityServiceScheduleDAO fssDAO = new FacilityServiceScheduleDAO(Master.RequestManager);

            if (Request.QueryString["fssid"] != "")
            {
                m_FacilityServiceScheduleID = Convert.ToInt32(Request.QueryString["fssid"]);
                m_FacilityServiceSchedule = fssDAO.Load(m_FacilityServiceScheduleID);
            }

            if (Request.QueryString["fssiid"] != "")
            {
                m_FacilityServiceScheduleItemID = Convert.ToInt32(Request.QueryString["fssiid"]);
            }

            if (Request.QueryString["fssieid"] != "" && Request.QueryString["fssieid"] != null)
            {
                m_FacilityServiceScheduleItemExclusionID = Convert.ToInt32(Request.QueryString["fssieid"]);
                m_EffectiveDate = Convert.ToDateTime(fsseDAO.GetDBValueByID(m_FacilityServiceScheduleItemExclusionID, "EFFECTIVE_DATE"));
                m_ExpirationDate = Convert.ToDateTime(fsseDAO.GetDBValueByID(m_FacilityServiceScheduleItemExclusionID, "EXPIRATION_DATE"));
            }

            m_ServiceItemList = fssiDAO.LoadAllRelatedServiceItems(m_FacilityServiceScheduleID);
            m_ServiceItemList2 = fssiDAO.LoadAllRelatedServiceItems(m_FacilityServiceScheduleID);
            m_PatientDispositionList = spdlDAO.LoadAll(false);
            m_ExclusionTypeList = fsetDAO.LoadAll();
        }

        /// <summary>
        /// Copies the form member data into the controls
        /// </summary>
        private void ModelToView()
        {
            SI2SIServiceItem1.Text = Request.QueryString["desc"];

            // Fill Service Item 1 DropDownList
            SI2SIServiceItem1DDL.Items.Clear();
            SI2SIServiceItem1DDL.DataSource = m_ServiceItemList;
            SI2SIServiceItem1DDL.DataValueField = "FacilityServiceScheduleItemID";
            SI2SIServiceItem1DDL.DataTextField = "Description";
            SI2SIServiceItem1DDL.DataBind();
            SI2SIServiceItem1DDL.Items.Insert(0, "");

            // Fill Service Item 2 DropDownList
            SI2SIServiceItem2DDL.Items.Clear();
            SI2SIServiceItem2DDL.DataSource = m_ServiceItemList2;
            SI2SIServiceItem2DDL.DataValueField = "FacilityServiceScheduleItemID";
            SI2SIServiceItem2DDL.DataTextField = "Description";
            SI2SIServiceItem2DDL.DataBind();
            SI2SIServiceItem2DDL.Items.Insert(0, "");

            // Fill Exclusion Type DropDownList
            TypeDropDownList.DataSource = m_ExclusionTypeList;
            TypeDropDownList.DataValueField = "FacilityServiceExclusionTypeID";
            TypeDropDownList.DataTextField = "Description";
            TypeDropDownList.DataBind();
            TypeDropDownList.Items.Insert(0, "");
            TypeDropDownList.Items.RemoveAt(TypeDropDownList.Items.IndexOf(TypeDropDownList.Items.FindByText("Procedure to Procedure Exclusion")));

            // Fill Patient Disposition DropDownList
            SI2PDDispositionDDL.Items.Clear();
            SI2PDDispositionDDL.DataSource = m_PatientDispositionList;
            SI2PDDispositionDDL.DataValueField = "PatientDispositionID";
            SI2PDDispositionDDL.DataTextField = "Description";
            SI2PDDispositionDDL.DataBind();
            SI2PDDispositionDDL.Items.Insert(0, "");
            SI2PDDispositionDDL.Items.RemoveAt(SI2PDDispositionDDL.Items.IndexOf(SI2PDDispositionDDL.Items.FindByText("Not set")));
            SI2PDDispositionDDL.Items.RemoveAt(SI2PDDispositionDDL.Items.IndexOf(SI2PDDispositionDDL.Items.FindByText("Unknown")));

            if (Request.QueryString["sn"] != null)
            {
                ScheduleNameTextBox.Text = Request.QueryString["sn"];
            }
            else if (m_FacilityServiceSchedule != null)
            {
                ScheduleNameTextBox.Text = m_FacilityServiceSchedule.Description;
            }

            txtEffectiveDate.Text = m_EffectiveDate.ToShortDateString();
            txtExpirationDate.Text = m_ExpirationDate.ToShortDateString();

            if ((Request.QueryString["btn"].Equals("editExclusion") || Request.QueryString["btn"].Equals("editExclusionT2"))
                && TypeDropDownList.SelectedIndex != 0)
            {
                FillCPTCodeTextBox();
            }

            else
            {
                txtEffectiveDate.Text = DateTime.Now.ToShortDateString();
                txtExpirationDate.Text = DEFAULT_EXPIRATION_DATE;
            }

            //txtEffectiveDate.Attributes.Add("onblur", "validateYear(this);");
            //txtExpirationDate.Attributes.Add("onblur", "validateYear(this);");

            Master.DisplayErrorMessages();
        }

        public void GoToPointsItems(object sender, System.EventArgs e)
        {
            Response.Redirect("PointsItems.aspx?btn=" + Request.QueryString["btn"] + "&said=" + Request.QueryString["said"] +
                "&fssid=" + Request.QueryString["fssid"] + "&sn=" + Request.QueryString["sn"]);
        }

        protected void btnLogOut_Click(object sender, System.EventArgs e)
        {
            SignOut();
        }

        protected void TypeDropDownList_SelectedIndexChanged(object sender, EventArgs e)
        {
            setVisibleControls();
            FillCPTCodeTextBox();
        }

        /// Set the DropDownList value from database
        protected void DropDownList_DataBound(object sender, EventArgs e)
        {
            if (Request.QueryString["btn"].Equals("editExclusion") || Request.QueryString["btn"].Equals("editExclusionT2"))
            {
                FacilityServiceScheduleExclusionDAO fseDAO = new FacilityServiceScheduleExclusionDAO(Master.RequestManager);
                DropDownList ddl = (DropDownList)sender;
                SI2SIServiceItem1.Text = Request.QueryString["desc"];
                String ServiceItem = "";

                if (Request.QueryString["fssieid"] != null)
                {
                    if (ddl.ID.Equals("TypeDropDownList"))
                    {
                        ServiceItem = fseDAO.GetDBValueByID(Convert.ToInt32(Request.QueryString["fssieid"]), "EXCLUSION_TYPE_ID");
                    }

                    else
                    {
                        ServiceItem = fseDAO.GetDBValueByID(Convert.ToInt32(Request.QueryString["fssieid"]), "EXCLUSION_ITEM_ID");
                    }
                }

                ddl.SelectedIndex = ddl.Items.IndexOf(ddl.Items.FindByValue(ServiceItem));
            }
        }

        public void FillCPTCodeTextBox()
        {
            FacilityServiceScheduleExclusionDAO fsseDAO = new FacilityServiceScheduleExclusionDAO(Master.RequestManager);

            if (TypeDropDownList.SelectedItem.Text.Equals("Service Item to Procedure Exclusion"))
            {
                SI2PCPTCodeTextBox.Text = fsseDAO.GetDBValueByID(Convert.ToInt32(Request.QueryString["fssieid"]), "CPT_CODE");
            }
        }

        public void GoToExclusionRules(object sender, System.EventArgs e)
        {
            Response.Redirect("ExclusionRules.aspx?btn=" + Request.QueryString["btn"] + "&said=" + Request.QueryString["said"] +
                "&fssid=" + Request.QueryString["fssid"] + "&sn=" + Request.QueryString["sn"]);
        }

        protected void AddExclusionSubmitButton_Click(object sender, EventArgs e)
        {
            SaveChanges();

            if (Master.RequestManager.ErrorMessages.Count == 0)
            {
                // Return to the Points Items page
                Response.Redirect("PointsItems.aspx?btn=edit&fssid=" + Request.QueryString["fssid"] + "&said=" + Request.QueryString["said"] + "&fssiid=" +
                Request.QueryString["fssiid"] + "&sn=" + Request.QueryString["sn"]);
            }
        }

        protected void SI2SIServiceItem2DDL_SelectedIndexChanged(object sender, EventArgs e)
        {
            SI2SIServiceItem2DDL.SelectedIndex = SI2SIServiceItem2DDL.SelectedIndex;
        }
        protected void SI2SIServiceItem1DDL_SelectedIndexChanged(object sender, EventArgs e)
        {
            SI2SIServiceItem1DDL.SelectedIndex = SI2SIServiceItem1DDL.SelectedIndex;
        }

        // Returns user to FacilityServices.aspx when cancel button is clicked.
        protected void AddExclusionCancelButton_Click(object sender, EventArgs e)
        {
            Response.Redirect("PointsItems.aspx?btn=edit&said=" + Request.QueryString["said"] + "&fssid=" + Request.QueryString["fssid"] + "&fssiid=" +
                Request.QueryString["fssiid"] + "&sn=" + Request.QueryString["sn"]);
        }

        // This function handles the insert or update of a record
        private void ProcessUpdates()
        {
            FacilityServiceScheduleExclusionDAO fsseDAO = new FacilityServiceScheduleExclusionDAO(Master.RequestManager);
            FacilityServiceScheduleExclusion fsse = new FacilityServiceScheduleExclusion();
            fsse.TrackPropertyChanges = true;
            fsse.ServiceAgreementID = Convert.ToInt32(Request.QueryString["said"]);
            DropDownList filledDropDownList = SI2SIServiceItem2DDL;

            if (m_ExclusionTypeID == SERVICE_ITEM_TO_PATIENT_DISPOSITION_EXCLUSION)
            {
                filledDropDownList = SI2PDDispositionDDL;
            }

            fsse.FacilityServiceScheduleItemExclusionID = m_FacilityServiceScheduleItemExclusionID;
            fsse.FacilityServiceScheduleItemID = m_FacilityServiceScheduleItemID;
            fsse.FacilityServiceScheduleID = m_FacilityServiceScheduleID;
            fsse.ExclusionTypeID = Convert.ToInt32(TypeDropDownList.SelectedValue);
            fsse.FacilityServiceScheduleItemID = m_FacilityServiceScheduleItemID;

            if (m_ExclusionTypeID == SERVICE_ITEM_TO_PROCEDURE_EXCLUSION)
            {
                fsse.CPTCode = SI2PCPTCodeTextBox.Text;
                fsse.ExclusionItemID = -1;
            }

            else
            {
                fsse.ExclusionItemID = Convert.ToInt32(filledDropDownList.SelectedValue);
            }

            fsse.EffectiveDate = m_EffectiveDate;
            fsse.ExpirationDate = m_ExpirationDate;

            try
            {
                fsseDAO.Save(fsse);
            }

            catch (Exception ex)
            {
                WebRequestManager.SystemError(Response, Session, ex);
            }
        }

        // This function saves the form data to the database
        private void SaveChanges()
        {
            if (ValidFormData())
            {
                // Get data from form and add it to the page's private variables
                GetFormData();

                // Insert the new record or update a existing record
                ProcessUpdates();
            }

            else
            {
                Master.DisplayErrorMessages();
            }
        }

        // Displays and hides options based on exclusion type selected
        private void setVisibleControls()
        {
            if (TypeDropDownList.SelectedItem.Text.Equals("Service Item to Service Item Exclusion"))
            {
                SI2SIServiceItem1Label.Visible = true;
                SI2SIServiceItem1.Visible = true;
                ddlSI2SIServiceItem1Label.Visible = false;
                SI2SIServiceItem1DDL.Visible = false;
                SI2PDDispositionLabel.Visible = false;
                SI2PDDispositionDDL.Visible = false;
                SI2SIServiceItem2Label.Visible = true;
                SI2SIServiceItem2DDL.Visible = true;
                SI2PCPTCodeLabel.Visible = false;
                SI2PCPTCodeTextBox.Visible = false;
                lblEffectiveDate.Visible = true;
                lblExpirationDate.Visible = true;
                txtEffectiveDate.Visible = true;
                imgEffectiveDateCalendar.Visible = true;
                txtExpirationDate.Visible = true;
                imgExpirationDateCalendar.Visible = true;
                AddExclusionSubmitButton.Enabled = true;
            }

            else if (TypeDropDownList.SelectedItem.Text.Equals("Service Item to Procedure Exclusion"))
            {
                SI2SIServiceItem1Label.Visible = true;
                SI2SIServiceItem1.Visible = true;
                ddlSI2SIServiceItem1Label.Visible = false;
                SI2SIServiceItem1DDL.Visible = false;
                SI2PDDispositionLabel.Visible = false;
                SI2PDDispositionDDL.Visible = false;
                SI2SIServiceItem2Label.Visible = false;
                SI2SIServiceItem2DDL.Visible = false;
                SI2PCPTCodeLabel.Visible = true;
                SI2PCPTCodeTextBox.Visible = true;
                lblEffectiveDate.Visible = true;
                lblExpirationDate.Visible = true;
                txtEffectiveDate.Visible = true;
                imgEffectiveDateCalendar.Visible = true;
                txtExpirationDate.Visible = true;
                imgExpirationDateCalendar.Visible = true;
                AddExclusionSubmitButton.Enabled = true;
            }

            else if (TypeDropDownList.SelectedItem.Text.Equals("Service Item to Patient Disposition Exclusion"))
            {
                SI2SIServiceItem1Label.Visible = true;
                SI2SIServiceItem1.Visible = true;
                ddlSI2SIServiceItem1Label.Visible = false;
                SI2SIServiceItem1DDL.Visible = false;
                SI2PDDispositionLabel.Visible = true;
                SI2PDDispositionDDL.Visible = true;
                SI2SIServiceItem2Label.Visible = false;
                SI2SIServiceItem2DDL.Visible = false;
                SI2PCPTCodeLabel.Visible = false;
                SI2PCPTCodeTextBox.Visible = false;
                lblEffectiveDate.Visible = true;
                lblExpirationDate.Visible = true;
                txtEffectiveDate.Visible = true;
                imgEffectiveDateCalendar.Visible = true;
                txtExpirationDate.Visible = true;
                imgExpirationDateCalendar.Visible = true;
                AddExclusionSubmitButton.Enabled = true;
            }

            else
            {
                ddlSI2SIServiceItem1Label.Visible = false;
                SI2SIServiceItem1DDL.Visible = false;
                SI2PDDispositionLabel.Visible = false;
                SI2PDDispositionDDL.Visible = false;
                SI2SIServiceItem1Label.Visible = false;
                SI2SIServiceItem1.Visible = false;
                SI2SIServiceItem2Label.Visible = false;
                SI2SIServiceItem2DDL.Visible = false;
                SI2PCPTCodeLabel.Visible = false;
                SI2PCPTCodeTextBox.Visible = false;
                lblEffectiveDate.Visible = false;
                lblExpirationDate.Visible = false;
                txtEffectiveDate.Visible = false;
                imgEffectiveDateCalendar.Visible = false;
                txtExpirationDate.Visible = false;
                imgExpirationDateCalendar.Visible = false;
                AddExclusionSubmitButton.Enabled = false;
            }
        }

        private void SetFocusToFirstError(int controlIndex, int numErrors)
        {
            ArrayList formControls = new ArrayList();

            formControls.Add(SI2SIServiceItem1DDL);
            formControls.Add(SI2SIServiceItem2DDL);
            formControls.Add(SI2PDDispositionDDL);
            formControls.Add(SI2PCPTCodeTextBox);
            formControls.Add(txtEffectiveDate);
            formControls.Add(txtExpirationDate);

            if (numErrors == 0)
            {
                SetFocus((Control)formControls[controlIndex]);
            }
        }
    }
}
