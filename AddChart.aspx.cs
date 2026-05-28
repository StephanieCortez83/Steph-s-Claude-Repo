using System;
using System.Collections;
using System.Web.UI.WebControls;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.DAO;
using CCSBusinessObjects.Services;
using CCSBusinessObjects.Utility;

namespace CCSWeb.WebPages
{
	/// <summary>
	/// Summary description for AddChart.
	/// </summary>
	public partial class AddChart : CCSBasePage //System.Web.UI.Page
	{
				
		private int					m_FacilityID;
		private String				m_DateReceivedStr;
		private String				m_TimeReceivedStr;
		private DateTime			m_DateReceived;
		private int					m_AssignedToUserProfileID;
		private String				m_FacilityChartIdentifier;
		private String				m_FirstName;
		private String				m_LastName;
		private String				m_DateOfServiceStr;
		private String				m_MedicalRecordNumber;
		private DateTime			m_DateOfService;
        private bool                m_RecurringVisit;
		protected ArrayList			m_FacilitiesList;
		protected ArrayList			m_UsersList;
		private ServiceAgreement	m_ServiceAgreement;


		protected void Page_Load(object sender, System.EventArgs e)
		{
            m_RequestManager = Master.RequestManager;
			txtFirstName.MaxLength = Chart.PATIENT_FIRST_NAME_MAX_LENGTH;
			txtLastName.MaxLength = Chart.PATIENT_LAST_NAME_MAX_LENGTH;

            if (!IsAuthorized()) 
			{
				Response.Redirect("Unauthorized.aspx",false);
			}

			InitializeFormObjects();


			if (!IsPostBack) 
			{
				SetDefaultView();
				LoadModel();
				ModelToView();
			}
		}
		/// <summary>
		/// Create any base objects needed by the form
		/// </summary>
		private void InitializeFormObjects() 
		{
            Boolean.TryParse((Request.QueryString["Type"] == RecurringVisitMethod.CREATED_FROM_CHARTS_VIEW_PAGE.ToString()).ToString(), out m_RecurringVisit);
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
				if (signedOnUserProfile.HasRight(UserRight.RIGHT_ADD_CHART)) 
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

		public void SetDefaultView() 
		{
            DateTime currentDateTime = DateTime.Now;
			m_FacilityID = Convert.ToInt32(Master.RequestManager.SessionManager.SelectedFacilityID);
			m_DateReceivedStr = currentDateTime.ToShortDateString();
            m_TimeReceivedStr = currentDateTime.ToString("HHmmss");
			m_AssignedToUserProfileID = Convert.ToInt32(Master.RequestManager.SessionManager.SignedOnUserProfileID);
			m_FacilityChartIdentifier = "";
			m_MedicalRecordNumber = String.Empty;
			m_FirstName = "";
			m_LastName = "";
			m_DateOfServiceStr = "";
		}

		public void GetFormData() 
		{
			m_FacilityID = Convert.ToInt32(cmbFacility.SelectedValue);
			m_AssignedToUserProfileID = Convert.ToInt32(cmbAssignedTo.SelectedValue);
			m_DateReceivedStr = txtDateReceived.Text.Trim();
            m_TimeReceivedStr = txtTimeReceived.Text.Trim();
			m_FacilityChartIdentifier = txtFacilityChartIdentifier.Text.Trim().ToUpper();
			m_MedicalRecordNumber = txtMedicalRecordNumber.Text.Trim().ToUpper();
			m_FirstName = txtFirstName.Text.Trim();
			m_LastName = txtLastName.Text.Trim();
			m_DateOfServiceStr = txtDateOfService.Text.Trim();
		}

		private void LoadModel()
		{
			m_ServiceAgreement = new ServiceAgreementDAO(Master.RequestManager).LoadCurrentForFacility(m_FacilityID);
		}

		/// <summary>
		/// Copies the form member data into the controls
		/// </summary>
		private void ModelToView() 
		{														
            lblAddChart.Text = m_RecurringVisit ? "Add Recurring Visit Chart" : "Add Chart";

			// Fill Facilities combo
			SimpleFacilitiesListDAO sflDAO = new SimpleFacilitiesListDAO(Master.RequestManager);
            //ACS-12412 - Gene - changed the two loads for the m_FacilitiesList to use the "Master.RequestManager.SessionManager.SignedOnUserProfile.UserProfileID"
            // instead of the "Master.RequestManager.SessionManager.SignedOnUserProfileID".
            m_FacilitiesList = m_RecurringVisit ?
                 sflDAO.LoadAllAuthorizedWithRecurring(Convert.ToInt32(Master.RequestManager.SessionManager.SignedOnUserProfile.UserProfileID)) :
                sflDAO.LoadAllAuthorized(Convert.ToInt32(Master.RequestManager.SessionManager.SignedOnUserProfile.UserProfileID));

			cmbFacility.DataSource = m_FacilitiesList;
			cmbFacility.DataTextField = "Name";
			cmbFacility.DataValueField = "FacilityID";
            cmbFacility.TryDataBind();
			cmbFacility.Items.Insert(0,new ListItem("[Select A Facility]","-1"));
			cmbFacility.SelectedValue = m_FacilityID.ToString();

            if (m_FacilitiesList.Count == 1)
            {
                cmbFacility.SelectedIndex = 1;
            }

            // Fill Users Status combo
            SimpleUsersListDAO ulDAO = new SimpleUsersListDAO(Master.RequestManager);
			//m_UsersList = ulDAO.LoadAll();
            //ACS-12412 - Gene -  changed the load for the m_UsersList to use the "Master.RequestManager.SessionManager.SignedOnUserProfile.UserProfileID"
            // instead of the "Master.RequestManager.SessionManager.SignedOnUserProfileID".
            m_UsersList = ulDAO.LoadAllWithChartAuthorityAndFacilityAccess(m_FacilityID, Convert.ToInt32(Master.RequestManager.SessionManager.SignedOnUserProfile.UserProfileID));
			cmbAssignedTo.DataSource = m_UsersList;
			cmbAssignedTo.DataTextField = "FormattedName";
			cmbAssignedTo.DataValueField = "UserProfileID";
			cmbAssignedTo.TryDataBind();
			cmbAssignedTo.Items.Insert(0,new ListItem("[Select A User]","-1"));
            try
            {
                cmbAssignedTo.SelectedValue = m_AssignedToUserProfileID.ToString();
            }
            catch (Exception)
            {
                cmbAssignedTo.SelectedValue = "-1";
            }			

			// Basic fields
			txtDateReceived.Text = m_DateReceivedStr;
            txtTimeReceived.Text = m_TimeReceivedStr;
			txtFacilityChartIdentifier.Text = m_FacilityChartIdentifier;
			txtMedicalRecordNumber.Text = m_MedicalRecordNumber;
			txtLastName.Text = m_LastName;
			txtFirstName.Text = m_FirstName;
			txtDateOfService.Text = m_DateOfServiceStr;
            
            // Disable patient name fields when adding a recurring visit.
            txtFirstName.Enabled = !m_RecurringVisit;
            txtLastName.Enabled = !m_RecurringVisit;

			upName.Visible =
				lblPatientName.Visible = m_ServiceAgreement == null ? true : m_ServiceAgreement.CollectPatientName.Visible;

			// Error messages
			ErrorListView1.ErrorMessages = Master.RequestManager.ErrorMessages;
		}

		/// <summary>
		/// Validates the form data
		/// </summary>
		/// <returns>True if all form data is valid.  False if not and error messages are created.</returns>
		private bool ValidFormData() 
		{
			bool res = true;
            String tempDateReceived = "";
            UserProfile signedOnUserProfile = Master.RequestManager.SessionManager.SignedOnUserProfile;

            if ((m_DateReceivedStr.Length > 0) && (m_TimeReceivedStr.Length > 0))
            {
                try
                {
                    tempDateReceived = m_DateReceivedStr + " " + m_TimeReceivedStr.Substring(0, 2) + ":" + m_TimeReceivedStr.Substring(2, 2) + ":" + m_TimeReceivedStr.Substring(4, 2);
                    if (!StringUtility.IsValidDateStr(tempDateReceived, m_DateReceived))
                    {
                        ErrorMessage errMsg = new ErrorMessage(68, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                        Master.RequestManager.ErrorMessages.Add(errMsg);
                        res = false;
                    }
                    else
                    {
                        m_DateReceived = Convert.ToDateTime(tempDateReceived);
                        DateTime today = DateTime.Now;
                        if (m_DateReceived > today)
                        {
                            ErrorMessage errMsg = new ErrorMessage(69, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                            Master.RequestManager.ErrorMessages.Add(errMsg);
                            res = false;
                        }
                    }
                }
                catch (Exception)
                {
                    ErrorMessage errMsg = new ErrorMessage(68, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    Master.RequestManager.ErrorMessages.Add(errMsg);
                    res = false;
                }
            }
            else
            {
                ErrorMessage errMsg = new ErrorMessage(68, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                Master.RequestManager.ErrorMessages.Add(errMsg);
                res = false;
            }

			if (m_DateOfServiceStr.Length > 0 ) 
			{
				if (!StringUtility.IsValidDateStr(m_DateOfServiceStr,m_DateOfService)) 
				{
					ErrorMessage errMsg = new ErrorMessage(70,ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
					Master.RequestManager.ErrorMessages.Add(errMsg);
					res = false;
				}
				else 
				{
					m_DateOfService = Convert.ToDateTime(m_DateOfServiceStr);
					System.TimeSpan priorDays = new TimeSpan(180,0,0,0,0);
					DateTime today = DateTime.Now;
					DateTime prev180 = today.Subtract(priorDays);
                    if (m_DateOfService > today) 
                    {
                        ErrorMessage errMsg = new ErrorMessage(71, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                        Master.RequestManager.ErrorMessages.Add(errMsg);
                        res = false;
                    }
                    else
                    {
                        if (m_FacilityID != -1)
                        {
                            FacilityDAO fDAO = new FacilityDAO(Master.RequestManager);
                            
                            if ((m_ServiceAgreement.ValidateDateOfServiceGreaterThan180DaysOld) && (m_DateOfService < prev180))
                            {
                                ErrorMessage errMsg = new ErrorMessage(71, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                                Master.RequestManager.ErrorMessages.Add(errMsg);
                                res = false;
                            }

                            if (!signedOnUserProfile.HasRight(UserRight.RIGHT_ALLOW_DOS_PRIOR_TO_SERVICE_AGREEMENT))
                            {
                                if (m_DateOfService < m_ServiceAgreement.EffectiveDateRange.StartDateTime)
                                {
                                    ErrorMessage errMsg = new ErrorMessage(329, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                                    errMsg.AddMessageData("%1", m_ServiceAgreement.EffectiveDateRange.StartDateTime.ToString("M/d/yyyy"));
                                    Master.RequestManager.ErrorMessages.Add(errMsg);
                                    res = false;
                                }
                            }
                        }
                    }
				}
			}
            else
            {
				ErrorMessage errMsg = new ErrorMessage(70, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
				Master.RequestManager.ErrorMessages.Add(errMsg);
				res = false;
			}

			if (m_FacilityID == -1 ) 
			{
				ErrorMessage errMsg = new ErrorMessage(18,ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
				Master.RequestManager.ErrorMessages.Add(errMsg);
				res = false;
			}

			if (m_AssignedToUserProfileID == -1 ) 
			{
				ErrorMessage errMsg = new ErrorMessage(19,ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
				Master.RequestManager.ErrorMessages.Add(errMsg);
				res = false;
			}

			if (m_FacilityChartIdentifier.Length == 0 ) 
			{
				ErrorMessage errMsg = new ErrorMessage(20,ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
				Master.RequestManager.ErrorMessages.Add(errMsg);
				res = false;
			}

			if (m_FacilityID != -1 && m_ServiceAgreement?.CollectPatientName != null)
			{
				if (m_ServiceAgreement == null || !m_ServiceAgreement.CollectPatientName.DoNotCollect)
				{
					if ((m_ServiceAgreement == null || m_ServiceAgreement.CollectPatientName.Required) && m_FirstName == "")
					{
						ErrorMessage errMsg = new ErrorMessage(23, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
						Master.RequestManager.ErrorMessages.Add(errMsg);
						res = false;
					}
					else
					{
						if (!m_RecurringVisit && !PersonName.ValidName(m_FirstName))
						{
							ErrorMessage errMsg = new ErrorMessage(23, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
							Master.RequestManager.ErrorMessages.Add(errMsg);
							res = false;
						}
					}

					if ((m_ServiceAgreement == null || m_ServiceAgreement.CollectPatientName.Required) && m_LastName == "")
					{
						ErrorMessage errMsg = new ErrorMessage(25, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
						Master.RequestManager.ErrorMessages.Add(errMsg);
						res = false;
					}
					else
					{
						if (!m_RecurringVisit && !PersonName.ValidName(m_LastName))
						{
							ErrorMessage errMsg = new ErrorMessage(25, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
							Master.RequestManager.ErrorMessages.Add(errMsg);
							res = false;
						}

					}
				}

				// If we are creating a new recurring visit chart
				if (res && m_RecurringVisit)
				{
					ChartDAO cDAO = new ChartDAO(Master.RequestManager);
					Chart c = cDAO.GetMaxChartForFacilityChartID(m_ServiceAgreement.ServiceAgreementID, m_FacilityChartIdentifier, true);

					if (c.ChartID.Equals(Chart.NEW_OBJECT_ID))
					{
						//Chart Identifier does not exist for this facility
						ErrorMessage errMsg = new ErrorMessage(489, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
						Master.RequestManager.ErrorMessages.Add(errMsg);
						res = false;
					}

					else
					{
						// Date of Service provided is not within 31 days of the prior visit recorded in the system
						if (m_DateOfService.CompareTo(c.TimeOfService) == 1 ? (m_DateOfService - c.TimeOfService).Days > 31 : (c.TimeOfService - m_DateOfService).Days > 31)
						{
							ErrorMessage errMsg = new ErrorMessage(490, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
							errMsg.AddMessageData("%1", c.TimeOfService.ToShortDateString());
							Master.RequestManager.ErrorMessages.Add(errMsg);
							res = false;
						}
					}
				}

				txtMedicalRecordNumber.Text = txtMedicalRecordNumber.Text.Trim().ToUpper();
				if (!Chart.ValidMedicalRecordNumber(txtMedicalRecordNumber.Text, m_ServiceAgreement.CollectMedicalRecordNumber.Required))
				{
					ErrorMessage errMsg = new ErrorMessage(27, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
					Master.RequestManager.ErrorMessages.Add(errMsg);
					res = false;
				}
			}
			return res;
		}


		protected void btnLogOut_Click(object sender, System.EventArgs e)
		{
			SignOut();
		}


		protected void btnSave_Click(object sender, System.EventArgs e)
		{
			GetFormData();

			LoadModel();
			
			if (ValidFormData())
			{	  

				AddChartForFacilityService acs = new AddChartForFacilityService(Master.RequestManager);
		
				Chart chart = acs.AddChartForFacility(m_FacilityID, m_DateReceived, m_FacilityChartIdentifier, m_AssignedToUserProfileID, m_FirstName, m_LastName, m_DateOfService, m_RecurringVisit, m_MedicalRecordNumber);

				if (acs.Successful) 
				{
					Master.RequestManager.SessionManager.SelectedChartID = chart.ChartID.ToString();
					Master.RequestManager.SessionManager.SelectedFacilityID = chart.FacilityID.ToString();

                    // Log access to this chart
                    WebSessionManager sessionMgr = (WebSessionManager)Master.RequestManager.SessionManager;
                    sessionMgr.ChartAccessID = ChartAccessDAO.LogAccess(Master.RequestManager, Convert.ToInt32(Master.RequestManager.SessionManager.SignedOnUserProfileID), chart.ChartID).ToString();
                    //ChartAccessDAO.LogAccess(Master.RequestManager, Convert.ToInt32(Master.RequestManager.SessionManager.SignedOnUserProfileID), chart.ChartID);
                    Master.RequestManager.SessionManager.IsAddNewChart = true;
					Response.Redirect("ChartDemographics.aspx");
				}
				else 
				{
					ModelToView();
				}
			}
			else 
			{
				ErrorListView1.ErrorMessages = Master.RequestManager.ErrorMessages;
				ErrorListView1.ValidationErrors = Master.RequestManager.ValidationErrors;
			}
		}

		protected void btnSaveAndAddAnother_Click(object sender, System.EventArgs e)
		{
			GetFormData();
			LoadModel();
			
			if (ValidFormData())
			{	  

				AddChartForFacilityService acs = new AddChartForFacilityService(Master.RequestManager);
		
				Chart chart = acs.AddChartForFacility(m_FacilityID, m_DateReceived, m_FacilityChartIdentifier, m_AssignedToUserProfileID, m_FirstName, m_LastName, m_DateOfService, m_RecurringVisit, m_MedicalRecordNumber);

				if (acs.Successful) 
				{
					Master.RequestManager.SessionManager.SelectedChartID = chart.ChartID.ToString();
					Master.RequestManager.SessionManager.SelectedFacilityID = chart.FacilityID.ToString();
					
					// Prepare for next chart to be added.
                    int saveFacilityID = m_FacilityID;
                    string saveDateOfServiceStr = m_DateOfServiceStr;
                    int saveAssignedToUserProfileID = m_AssignedToUserProfileID;
                    SetDefaultView();
                    m_FacilityID = saveFacilityID;
                    m_DateOfServiceStr = saveDateOfServiceStr;
                    m_AssignedToUserProfileID = saveAssignedToUserProfileID;

					ErrorMessage errMsg = new ErrorMessage(21,ErrorMessage.ERROR_MESSAGE_SEVERITY_INFO);
					Master.RequestManager.ErrorMessages.Add(errMsg);

                    txtFacilityChartIdentifier.Focus();

					ModelToView();
				}
				else 
				{
					ModelToView();
				}
			}
			else 
			{
				ErrorListView1.ErrorMessages = Master.RequestManager.ErrorMessages;
				ErrorListView1.ValidationErrors = Master.RequestManager.ValidationErrors;
			}
		}

        protected void txtFacilityChartIdentifier_TextChanged(object sender, EventArgs e)
        {
            if (m_RecurringVisit)
            {
                GetFormData();
				LoadModel();

				if (String.IsNullOrEmpty(m_FacilityChartIdentifier) == false)
                {
                    ServiceAgreement sa = new ServiceAgreementDAO(Master.RequestManager).LoadCurrentForFacility(m_FacilityID);
                    ChartDAO cDAO = new ChartDAO(Master.RequestManager);
                    Chart c = cDAO.GetMaxChartForFacilityChartID(sa.ServiceAgreementID, m_FacilityChartIdentifier, true);
                    if (c.ChartID != Chart.NEW_OBJECT_ID)
                    {
                        txtFirstName.Text = c.Patient.Name.FirstName;
                        txtLastName.Text = c.Patient.Name.LastName;

                        txtDateOfService.TextBox.Focus();
                    }

                    else
                    {
                        txtFirstName.Text = txtLastName.Text = string.Empty;

						//Chart Identifier does not exist for this facility
						ErrorMessage errMsg = new ErrorMessage(489, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                        Master.RequestManager.ErrorMessages.Add(errMsg);

                        ModelToView();

                        txtFacilityChartIdentifier.Attributes.Add("onfocus", "this.select();");
                        txtFacilityChartIdentifier.Focus();
                    }

                   

                }
                else
                {
                    txtFirstName.Text = txtLastName.Text = string.Empty;

                    //Chart Identifier does not exist for this facility
                    ErrorMessage errMsg = new ErrorMessage(20, ErrorMessage.ERROR_MESSAGE_SEVERITY_SEVERE);
                    Master.RequestManager.ErrorMessages.Add(errMsg);

                    ModelToView();

                    txtFacilityChartIdentifier.Attributes.Add("onfocus", "this.select();");
                    txtFacilityChartIdentifier.Focus();
                }

                upName.Update();
            }

            else
            {

                txtDateOfService.TextBox.Focus();
            }
        }
	}
}
