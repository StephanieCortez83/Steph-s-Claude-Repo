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
    public partial class AddChildPointItem : CCSBasePage //System.Web.UI.Page
    {
        // Named constants 
        
        private const String DEFAULT_EXPIRATION_DATE = "12/31/2099";
        private const String ERROR_CSS_CLASS = "StdInputErr";

        // Private variables used by the form
        
        private int m_FacilityServiceScheduleID; private DateTime m_ExpirationDate;
        private int m_FacilityServiceScheduleItemID; private DateTime m_EffectiveDate;
       
        private FacilityServiceSchedule m_FacilityServiceSchedule;
        private String m_SortOrder;
        private String m_SortDirection;
        protected ArrayList m_PointsItemsList;
        private String m_Description;
        private int m_Points;
        private String m_LongDescription;
        private DateTime m_ParentEffDate;
        private DateTime m_ParentExpDate;


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
                m_SortOrder = Convert.ToInt32(FacilityServiceScheduleItem.SortMethod.PresentationSequence).ToString();
                m_SortDirection = FacilityServiceScheduleItem.SortDirection.ASC.ToString();
                LoadModel();
                ModelToView();
               
            }
        }

        /// <summary>
        /// Create any base objects needed by the form
        /// </summary>
        private void InitializeFormObjects()
        {
            UserProfile signedOnUserProfile = Master.RequestManager.SessionManager.SignedOnUserProfile;

            m_FacilityServiceScheduleID = -1;
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
            var signedOnUserProfile = Master.RequestManager.SessionManager.SignedOnUserProfile;

            if (signedOnUserProfile == null)
                Response.Redirect("../login.aspx?ReturnUrl=WebPages/News.aspx");

            return signedOnUserProfile.HasRight(UserRight.RIGHT_ALLOW_SERVICE_AGREEMENT_ADMINISTRATOR) ||
                    signedOnUserProfile.HasRight(UserRight.RIGHT_FACILITY_SERVICES_ADMINISTRATION);
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
            DescriptionTextBox.CssClass = "StdInput";
            PointsTextBox.CssClass = "StdInput";

            if (!IsValidString(DescriptionTextBox.Text.Trim(), "Description", 1, 75))
            {
                SetFocusToFirstError(0, errors++);
                DescriptionTextBox.CssClass = ERROR_CSS_CLASS;
                res = false;
            }

            if (!StringUtility.IsInteger(PointsTextBox.Text.Trim()) || PointsTextBox.Text.Trim() == ""
                    || !StringUtility.IsNumeric(PointsTextBox.Text.Trim()))
            {
                SetFocusToFirstError(1, errors++);
                ErrorMessage errMsg = new ErrorMessage(158, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                errMsg.AddMessageData("%1", "Points field must conatin an integer");
                Master.RequestManager.ErrorMessages.Add(errMsg);
                PointsTextBox.CssClass = ERROR_CSS_CLASS;
                res = false;
            }

            if (!IsValidString(LongDescriptionTextBox.Text.Trim(), "Long Description", 1, 1000))
            {
                SetFocusToFirstError(3, errors++);
                LongDescriptionTextBox.CssClass = ERROR_CSS_CLASS;
                res = false;
            }

            if (StringUtility.IsValidDateStr(txtEffectiveDate.Text) && StringUtility.IsValidDateStr(txtExpirationDate.Text))
            {
                if (hfParentFacilityServiceScheduleItemID.Value == "") 
                {
                    FacilityServiceScheduleItem fssi = new FacilityServiceScheduleItem(fssiDAO,
                    Convert.ToInt32(hfFacilityServiceScheduleID.Value), Convert.ToInt32(hfFacilityServiceScheduleItemID.Value));
                    m_ParentEffDate = fssi.EffectiveDate;
                    m_ParentExpDate = fssi.ExpirationDate;
                }
                else 
                {
                    FacilityServiceScheduleItem fssi = new FacilityServiceScheduleItem(fssiDAO,
                    Convert.ToInt32(hfFacilityServiceScheduleID.Value), Convert.ToInt32(hfParentFacilityServiceScheduleItemID.Value));
                    m_ParentEffDate = fssi.EffectiveDate;
                    m_ParentExpDate = fssi.ExpirationDate;

                }
                
               
                m_EffectiveDate = Convert.ToDateTime(txtEffectiveDate.Text);
                m_ExpirationDate = Convert.ToDateTime(txtExpirationDate.Text);

                if(m_EffectiveDate < m_ParentEffDate)
                {
                    ErrorMessage errMsg = new ErrorMessage(158, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    errMsg.AddMessageData("%1", "Effective Date must be equal or greater than the Parent Item Effective Date");
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    res = false;
                }
                if (m_ExpirationDate > m_ParentExpDate)
                {
                    ErrorMessage errMsg = new ErrorMessage(158, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    errMsg.AddMessageData("%1", "Expiration Date must be equal or lesser than the Parent Item Expiration Date");
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    res = false;
                }

                if (m_EffectiveDate > m_ExpirationDate)
                {
                    ErrorMessage errMsg = new ErrorMessage(106, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    res = false;
                }
            }

            else
            {
                if (!StringUtility.IsValidDateStr(txtEffectiveDate.Text))
                {
                    ErrorMessage errMsg = new ErrorMessage(74, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    res = false;
                }

                if (!StringUtility.IsValidDateStr(txtExpirationDate.Text))
                {
                    ErrorMessage errMsg = new ErrorMessage(75, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    res = false;
                }
            }

            return res;
        }

        private void SetFocusToFirstError(int controlIndex, int numErrors)
        {
            ArrayList formControls = new ArrayList();

            formControls.Add(DescriptionTextBox);
            formControls.Add(PointsTextBox);
            formControls.Add(new TextBox());
            formControls.Add(LongDescriptionTextBox);
            formControls.Add(txtEffectiveDate.TextBox);
            formControls.Add(txtExpirationDate.TextBox);


            if (numErrors == 0)
            {
                SetFocus((Control)formControls[controlIndex]);
            }
        }

        private bool IsValidString(String s, String columnHeadingName, int minChars, int maxChars)
        {
            bool res = true;

            if (!StringUtility.IsAlphaNumericWithAllPunctuation(s))
            {
                ErrorMessage errMsg = new ErrorMessage(158, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                errMsg.AddMessageData("%1", columnHeadingName + " field contains some invalid characters");
                Master.RequestManager.ErrorMessages.Add(errMsg);
                res = false;
            }

            if (!StringUtility.IsValidStringLength(s, minChars, maxChars))
            {
                ErrorMessage errMsg = new ErrorMessage(157, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                errMsg.AddMessageData("%1", columnHeadingName + " must be between " + minChars + " and " + maxChars + " characters");
                Master.RequestManager.ErrorMessages.Add(errMsg);
                res = false;
            }

            return res;
        }

        /// <summary>
        /// Loads the model data into the member data for the form
        /// </summary>
        private void LoadModel()
        {
           
            FacilityServiceScheduleItemDAO fssiDAO = new FacilityServiceScheduleItemDAO(Master.RequestManager);
            FacilityServiceScheduleDAO fssDAO = new FacilityServiceScheduleDAO(Master.RequestManager);

            if (Request.QueryString["fssid"] != "")
            {
                m_FacilityServiceScheduleID = Convert.ToInt32(Request.QueryString["fssid"]);
                m_FacilityServiceSchedule = fssDAO.Load(m_FacilityServiceScheduleID);
                hfFacilityServiceScheduleID.Value = m_FacilityServiceScheduleID.ToString();
            }

            if (Request.QueryString["fssiid"] != "")
            {
                m_FacilityServiceScheduleItemID = Convert.ToInt32(Request.QueryString["fssiid"]);
                hfFacilityServiceScheduleItemID.Value = m_FacilityServiceScheduleItemID.ToString();
            }
            else
            {
                m_FacilityServiceScheduleItemID = -1;
            }

            if (Request.QueryString["btn"] != null)
            {
                if (Request.QueryString["btn"].Equals("editChildPointItem") && m_FacilityServiceScheduleID > 0 && m_FacilityServiceScheduleItemID != -1)
                {
                    FacilityServiceScheduleItem fssi = fssiDAO.LoadItemForEdit(new FacilityServiceScheduleItem(), Convert.ToInt32(Request.QueryString["fssid"]), Convert.ToInt32(Request.QueryString["fssiid"]));
                    m_Description = fssi.Description;
                    m_LongDescription = fssi.LongDescription;
                    m_Points = fssi.Points;
                    m_EffectiveDate = fssi.EffectiveDate;
                    m_ExpirationDate = fssi.ExpirationDate;
                    hfParentFacilityServiceScheduleItemID.Value = fssi.ParentFacilityServiceScheduleItemID.ToString();

                }
            }
           
              
        }

        /// <summary>
        /// Copies the form member data into the controls
        /// </summary>
        private void ModelToView()
        {
           
            if (Request.QueryString["sn"] != null)
            {
                ScheduleNameTextBox.Text = Request.QueryString["sn"];
                hfScheduleName.Value = ScheduleNameTextBox.Text;
            }
            else if (m_FacilityServiceSchedule != null)
            {
                ScheduleNameTextBox.Text = m_FacilityServiceSchedule.Description;
            }
            if (Request.QueryString["btn"] != null)
            {
                if (Request.QueryString["btn"].Equals("editChildPointItem"))
                {
                    DescriptionTextBox.Text = m_Description;
                    PointsTextBox.Text = m_Points.ToString();
                    LongDescriptionTextBox.Text = m_LongDescription;
                    txtEffectiveDate.Text = m_EffectiveDate.ToShortDateString();
                    txtExpirationDate.Text = m_ExpirationDate.ToShortDateString();
                }
                else
                {
                    txtEffectiveDate.Text = DateTime.Now.ToShortDateString();
                    txtExpirationDate.Text = DEFAULT_EXPIRATION_DATE;
                }
            }
            else
            {
                txtEffectiveDate.Text = DateTime.Now.ToShortDateString();
                txtExpirationDate.Text = DEFAULT_EXPIRATION_DATE;
            }
               
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

       

        /// Set the DropDownList value from database
       
      

        public void GoToExclusionRules(object sender, System.EventArgs e)
        {
            Response.Redirect("ExclusionRules.aspx?btn=" + Request.QueryString["btn"] + "&said=" + Request.QueryString["said"] +
                "&fssid=" + Request.QueryString["fssid"] + "&sn=" + Request.QueryString["sn"]);
        }

        protected void AddOnItemSubmitButton_Click(object sender, EventArgs e)
        {
            SaveChanges();

            if (Master.RequestManager.ErrorMessages.Count == 0)
            {
                // Return to the Points Items page
                Response.Redirect("PointsItems.aspx?btn=edit&fssid=" + Request.QueryString["fssid"] + "&said=" + Request.QueryString["said"] + "&fssiid=" +
                hfFacilityServiceScheduleItemID.Value + "&sn=" + hfScheduleName.Value);
            }
        }

        
        // Returns user to FacilityServices.aspx when cancel button is clicked.
        protected void AddOnItemCancelButton_Click(object sender, EventArgs e)
        {
            var fssiid = hfFacilityServiceScheduleItemID.Value;

            if (hfParentFacilityServiceScheduleItemID.Value != "")            
                fssiid = hfParentFacilityServiceScheduleItemID.Value;
                
            Response.Redirect("PointsItems.aspx?btn=edit&fssid=" + Request.QueryString["fssid"] + "&said=" + Request.QueryString["said"] + "&fssiid=" + fssiid + "&sn=" + hfScheduleName.Value);

        }

        // This function handles the insert or update of a record
        

        // This function saves the form data to the database
        private void SaveChanges()
        {
            if (ValidFormData())
            {
                // Get data from form and add it to the page's private variables
                GetFormData();
                FacilityServiceScheduleItemDAO fssiDAO = new FacilityServiceScheduleItemDAO(Master.RequestManager);
                int fssid = 0;
                if (Request.QueryString["fssid"] != "")
                {
                    fssid = Convert.ToInt32(Request.QueryString["fssid"]);
                }

                int fssiid = 0;
                if(hfParentFacilityServiceScheduleItemID.Value != "")
                {
                    if (Convert.ToInt32(hfParentFacilityServiceScheduleItemID.Value) > 0)
                    {
                        fssiid = Convert.ToInt32(hfParentFacilityServiceScheduleItemID.Value);
                    }
                }
                else 
                { 
                    fssiid = Convert.ToInt32(hfFacilityServiceScheduleItemID.Value);
                }

                
                if(Request.QueryString["btn"] != null)
                {
                    if (Request.QueryString["btn"].Equals("addChildPointItem"))
                    {
                        FacilityServiceScheduleItem fssi = new FacilityServiceScheduleItem(fssiDAO,
                       Convert.ToInt32(Request.QueryString["fssid"]), fssiid);
                        FacilityServiceScheduleItem fssiNew = new FacilityServiceScheduleItem();
                        fssiNew.TrackPropertyChanges = true;
                        fssiNew.ServiceAgreementID = Convert.ToInt32(Request.QueryString["said"]);
                        fssiNew.FacilityServiceScheduleID = fssi.FacilityServiceScheduleID;
                        fssiNew.Description = "ADD-ON:" + DescriptionTextBox.Text.Trim();
                        fssiNew.LongDescription = LongDescriptionTextBox.Text.Trim();
                        fssiNew.Points = Convert.ToInt32(PointsTextBox.Text.Trim());
                        fssiNew.EffectiveDate = Convert.ToDateTime(txtEffectiveDate.Text.Trim());
                        fssiNew.ExpirationDate = Convert.ToDateTime(txtExpirationDate.Text.Trim());
                        fssiNew.PresentationSequence = fssi.PresentationSequence;
                        fssiNew.CriticalCare = fssi.CriticalCare;
                        fssiNew.Require25Modifier = fssi.Require25Modifier;
                        fssiNew.ParentItem = false;
                        fssiNew.ParentFacilityServiceScheduleItemID = fssi.FacilityServiceScheduleItemID;
                        try
                        {
                            fssiDAO.Save(fssiNew, $"Service Agreement - Facility Service Schedules - Points Items - Add Child Point Item {fssiNew.Description}");
                        }
                        catch (Exception ex)
                        {
                            WebRequestManager.SystemError(Response, Session, ex);
                        }
                    }
                    else
                    {
                        FacilityServiceScheduleItem fssi = new FacilityServiceScheduleItem(fssiDAO,
                      Convert.ToInt32(Request.QueryString["fssid"]), Convert.ToInt32(Request.QueryString["fssiid"]));
                        fssi.TrackPropertyChanges = true;
                        fssi.ServiceAgreementID = Convert.ToInt32(Request.QueryString["said"]);
                        fssi.Description = DescriptionTextBox.Text;
                        fssi.LongDescription = LongDescriptionTextBox.Text;
                        fssi.Points = Convert.ToInt32(PointsTextBox.Text);
                        fssi.EffectiveDate = Convert.ToDateTime(txtEffectiveDate.Text.Trim());
                        fssi.ExpirationDate = Convert.ToDateTime(txtExpirationDate.Text.Trim());

                        try
                        {
                            fssiDAO.Save(fssi, $"Service Agreement - Facility Service Schedules - Points Items - Add Child Point Item {fssi.Description}");
                        }
                        catch (Exception ex)
                        {
                            WebRequestManager.SystemError(Response, Session, ex);
                        }
                    }
                }
               

               

            }

            else
            {
                Master.DisplayErrorMessages();
            }
        }

        
        
    }
}
