using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.Common;
using CCSBusinessObjects.Data.Service;

namespace CCSWeb.WebPages.Controls.Portlets
{
    using System;
    using System.Data;
    using System.Drawing;
    using System.Web;
    using System.Web.UI.WebControls;
    using System.Web.UI.HtmlControls;
    using CCSBusinessObjects.AppSystem;
    using CCSBusinessObjects.BusinessObjects;
    using CCSBusinessObjects.DAO;
    using CCSBusinessObjects.Services;
    using CCSBusinessObjects.Utility;
    using System.Collections.Generic;
    using System.Collections;
    using Newtonsoft.Json.Converters;

    public partial class QAFeedbackControl : System.Web.UI.UserControl
    {
        public DateTime FromDate
        {
            get { return m_FromDate; }
            set { m_FromDate = value; }
        }
        public DateTime ToDate
        {
            get { return m_ToDate; }
            set { m_ToDate = value; }
        }

        public bool HasResults
        {
            get { return m_HasResults; }
            set { m_HasResults = value; }
        }

        private DateTime m_FromDate;
        private DateTime m_ToDate;
        private bool m_HasResults = false;
        private bool m_ShowAccountLink = false;

        private int chartsCodedCount = 0;
        private int chartsAuditedCount = 0;
        private int chartsApprovedByAuditor = 0;
        private int chartsSecondAuditedForAuditor = 0;

        private WebRequestManager m_RequestManager;

        protected List<ChartQAFeedbackItem> m_FeedbackResults = new List<ChartQAFeedbackItem>();
        protected List<ChartQAFeedbackItem> m_FeedbackResultsAuditor = new List<ChartQAFeedbackItem>();

        protected List<ChartQAScorecardSummary> m_ScorecardCoderItems = new List<ChartQAScorecardSummary>();
        protected List<ChartQAScorecardSummary> m_ScorecardAuditorItems = new List<ChartQAScorecardSummary>();

        ChartDAO m_ChartDAO;
        private ChartDemographicHistory m_ChartDemographicChanges;

        public void PreparePortlet(WebRequestManager aRequestManager)
        {
            m_RequestManager = aRequestManager;
            m_FromDate = new DateTime();
            m_ToDate = new DateTime();
            m_ChartDAO = new ChartDAO(m_RequestManager);
        }

        protected void Page_Load(object sender, System.EventArgs e)
        {
            if (m_RequestManager != null)
            {
                if (!IsPostBack)
                {
                    m_ShowAccountLink = false;
                    // Put user code to initialize the page here
                    if (this.Parent.Page.Title.ToUpper() != "NEWS")
                    {
                        LoadQAReviewWithDateRange();
                    }
                    else
                    {
                        this.CheckIfQAReviewToBeDisplayed();
                    }
                }
                else
                {
                    if (m_RequestManager.SessionManager.SignedOnUserProfileID == m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID.ToString() || divDateRange.Visible)
                    {
                        this.CheckIfQAReviewToBeDisplayed();
                    }
                }
            }
        }

        private void CheckIfQAReviewToBeDisplayed()
        {
            if (m_RequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_DISPLAY_QA_FEEDBACK_AT_LOGIN))
            {
                if (m_RequestManager.SessionManager.SignedOnUserProfileID == m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID.ToString())
                {
                    if (divDateRange.Visible)
                    {
                        LoadQAReviewWithDateRange();
                    }
                    else
                    {
                        //If this is the first time the user is reviewing QA feedback online, default to the last time the user logged on, less 3 days. 
                        DateTime lastReviewDate;
                        if (m_RequestManager.SessionManager.SignedOnUserProfile.LastReviewedQAFeedback == null)
                        {
                            DateTime lastLogonDate = new UserLogonDAO(m_RequestManager).GetLastLogonDateForUser(m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID);
                            if (lastLogonDate == null || lastLogonDate == DateTime.MinValue)
                            {
                                lastReviewDate = DateTime.Now.AddDays(-3);
                            }
                            else
                            {
                                lastReviewDate = lastLogonDate.AddDays(-3);
                            }
                        }
                        else
                        {
                            lastReviewDate = Convert.ToDateTime(m_RequestManager.SessionManager.SignedOnUserProfile.LastReviewedQAFeedback);
                        }

                        // Do no load QA Review if the user has already reviewed it today
                        if (lastReviewDate.Date != DateTime.Now.Date)
                        {
                            LoadQAReview();
                        }
                    }
                }
                else
                {
                    DateTime lastLogonDate = new UserLogonDAO(m_RequestManager).GetLastLogonDateForUser(m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID);
                    if (lastLogonDate.Date != DateTime.Now.Date)
                    {
                        if (divDateRange.Visible)
                        {
                            LoadQAReviewWithDateRange();
                        }
                        else
                        {
                            LoadQAReview();
                        }
                    }
                }
            }
        }

        private void LoadQAReviewWithDateRange()
        {
            btnRefresh.Visible = true;
            dfFromDate.Visible = true;
            dfToDate.Visible = true;
            divDateRange.Visible = true;
            tdDateRange.Visible = true;
            m_ShowAccountLink = true;

            if (!IsPostBack)
            {
                this.dfFromDate.Text = DateTime.Today.AddDays(-5).ToShortDateString();
                this.dfToDate.Text = DateTime.Today.ToShortDateString();
                this.FromDate = Convert.ToDateTime(dfFromDate.Text);
                this.ToDate = Convert.ToDateTime(dfToDate.Text);
            }
            else
            {
                if (dfFromDate.Text != String.Empty && dfToDate.Text != String.Empty)
                {
                    this.FromDate = Convert.ToDateTime(dfFromDate.Text);
                    this.ToDate = Convert.ToDateTime(dfToDate.Text);
                }
            }
            int userProfileID = m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID;

            //ACS-15642  Load the scorecard controls based on user
            if (m_RequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_USE_QA_SCORECARD_FOR_AUDIT_FEEDBACK))
            {
                LoadQAScorecard(FromDate, ToDate, userProfileID);
                btnMarkAsReviewed.Visible = false;
                popupQAFeedback.Show();
            }
            else
            {
                ChartQAFeedbackItemDAO feedbackDAO = new ChartQAFeedbackItemDAO(m_RequestManager);
                m_ChartDAO = new ChartDAO(m_RequestManager);

                m_FeedbackResults = feedbackDAO.LoadFeedbackList(FromDate, ToDate, userProfileID);
                m_FeedbackResultsAuditor = feedbackDAO.LoadSecondAuditFeedbackList(FromDate, ToDate, userProfileID);

                lblSummaryCoder.Text = "QA Feedback for: " + m_RequestManager.SessionManager.SignedOnUserProfile.Name.FormattedNameWithSuffix.ToString();
                lblSummaryCoder.Text += " from " + FromDate.ToShortDateString() + " to " + ToDate.ToShortDateString();

                //Coder
                if (m_FeedbackResults.Count > 0)
                {

                    ChartQAFeedbackSummary summary = new ChartQAFeedbackSummaryDAO(m_RequestManager).Load(FromDate, ToDate, userProfileID);
                    //this.lblFacilityServiceCoder.Text = FormatRate(summary.FacilityLOSRate);
                    //lblFacilityInfInjCoder.Text = FormatRate(summary.FacilityInfInjRate);
                    //lblFacilityProcCoder.Text = FormatRate(summary.FacilityProcRate);
                    //lblPhysicianServiceCoder.Text = FormatRate(summary.PhysicianLOSRate);
                    //lblPhysicianProcCoder.Text = FormatRate(summary.PhysicianProcRate);
                    //lblDiagnosisCoder.Text = FormatRate(summary.DiagnosisRate);
                    //lblDemographicsCoder.Text = FormatRate(summary.DemographicsRate);
                    //lblObsHoursCoder.Text = FormatRate(summary.ObsHoursRate);
                    //lblObsInfInjCoder.Text = FormatRate(summary.ObsInfInjRate);
                    //lblObsProcCoder.Text = FormatRate(summary.ObsProcRate);
                    lblFacilityServiceCoder.Text = FormatRate(summary.FacilityLOSAvailable, summary.FacilityLOSRate);
                    lblFacilityInfInjCoder.Text = FormatRate(summary.FacilityInfInjAvailable, summary.FacilityInfInjRate);
                    lblFacilityProcCoder.Text = FormatRate(summary.FacilityProcAvailable, summary.FacilityProcRate);
                    lblPhysicianServiceCoder.Text = FormatRate(summary.PhysicianLOSAvailable, summary.PhysicianLOSRate);
                    lblPhysicianProcCoder.Text = FormatRate(summary.PhysicianProcAvailable, summary.PhysicianProcRate);
                    lblDiagnosisCoder.Text = FormatRate(summary.DiagnosisAvailable, summary.DiagnosisRate);
                    lblDemographicsCoder.Text = FormatRate(summary.DemographicsAvailable, summary.DemographicsRate);
                    lblObsHoursCoder.Text = FormatRate(summary.ObsHoursAvailable, summary.ObsHoursRate);
                    lblObsInfInjCoder.Text = FormatRate(summary.ObsInfInjAvailable, summary.ObsInfInjRate);
                    lblObsProcCoder.Text = FormatRate(summary.ObsProcAvailable, summary.ObsProcRate);

                    lblTotalRate.Text = FormatRate(summary.TotalRate);
                    lblTotalChartsCoder.Text = "Total Charts Coded: " + summary.TotalCharts.ToString();
                    lblTotalAuditedCoder.Text = "Total Charts Audited: " + summary.TotalChartsAudited.ToString();

                    this.grdResults.DataSource = m_FeedbackResults;
                    grdResults.DataBind();
                    divCoderResults.Visible = true;
                }

                //Auditor (2nd level audits)
                if (m_FeedbackResultsAuditor.Count > 0)
                {
                    ChartQAFeedbackSummary summary = new ChartQAFeedbackSummaryDAO(m_RequestManager).LoadAuditor(FromDate, ToDate, userProfileID);
                    this.lblFacilityServiceAuditor.Text = FormatRate(summary.FacilityLOSRate);
                    lblFacilityInfInjAuditor.Text = FormatRate(summary.FacilityInfInjRate);
                    lblFacilityProcAuditor.Text = FormatRate(summary.FacilityProcRate);
                    lblPhysicianServiceAuditor.Text = FormatRate(summary.PhysicianLOSRate);
                    lblPhysicianProcAuditor.Text = FormatRate(summary.PhysicianProcRate);
                    lblDiagnosisAuditor.Text = FormatRate(summary.DiagnosisRate);
                    lblDemographicsAuditor.Text = FormatRate(summary.DemographicsRate);
                    lblObsHoursAuditor.Text = FormatRate(summary.ObsHoursRate);
                    lblObsInfInjAuditor.Text = FormatRate(summary.ObsInfInjRate);
                    lblObsProcAuditor.Text = FormatRate(summary.ObsProcRate);

                    lblTotalRateAuditor.Text = FormatRate(summary.TotalRate);
                    this.lblTotalCharts2ndAudited.Text = "Total Charts 2nd Level Audited: " + summary.TotalCharts.ToString();
                    this.lblTotal2ndLevelChanged.Text = "Total Charts with 2nd Level Auditor Changes: " + summary.TotalChartsAudited.ToString();

                    this.grdResultsAuditor.DataSource = m_FeedbackResults;
                    grdResultsAuditor.DataBind();
                    divAuditorResults.Visible = true;
                }

                if (!divCoderResults.Visible && !divAuditorResults.Visible)
                {
                    HasResults = false;
                    this.pnlConrol.Visible = true;
                    lblNoResults.Visible = true;
                    trNoResults.Visible = true;
                    pnlQA.Visible = true;
                }
                else
                {
                    HasResults = true;
                    lblNoResults.Visible = false;
                    trNoResults.Visible = false;
                    this.pnlConrol.Visible = true;
                    pnlQA.Visible = true;
                }

                //chkMarkAsReviewed.Visible = false;
                btnMarkAsReviewed.Visible = false;
                popupQAFeedback.Show();
            }
        }
        private void LoadCoderScorecardDetails(int chartCount)
        {
            int totalCodesCount = 0;
            int totalCorrectCodesCount = 0;
            int totalRevisedCodesCount = 0;
            int totalAddedCodesCount = 0;
            int totalDeletedCodesCount = 0;
            int dxAttempted = 0, dxCorrect = 0, dxAdditions = 0, dxRevisions = 0, dxDeletions = 0, dxAbstract = 0;
            int facProcAttempted = 0, facProcCorrect = 0, facProcAdditions = 0, facProcRevisions = 0, facProcDeletions = 0, facProcAbstract = 0;
            int infusionInjectionAttempted = 0, infusionInjectionCorrect = 0, infusionInjectionAdditions = 0, infusionInjectionRevisions = 0, infusionInjectionDeletions = 0, infusionInjectionAbstract = 0;
            int profProcAttempted = 0, profProcCorrect = 0, profProcAdditions = 0, profProcRevisions = 0, profProcDeletions = 0, profProcAbstract = 0;
            int anesthesiaAttempted = 0, anesthesiaCorrect = 0, anesthesiaAdditions = 0, anesthesiaRevisions = 0, anesthesiaDeletions = 0, anesthesiaAbstract = 0;
            int obsHoursAttempted = 0, obsHoursCorrect = 0, obsHoursAdditions = 0, obsHoursRevisions = 0, obsHoursDeletions = 0, obsHoursAbstract = 0;
            int facilityLOSAttempted = 0, facilityLOSCorrect = 0, facilityLOSAdditions = 0, facilityLOSRevisions = 0, facilityLOSDeletions = 0, facilityLOSAbstract = 0;
            int physicianLOSAttempted = 0, physicianLOSCorrect = 0, physicianLOSAdditions = 0, physicianLOSRevisions = 0, physicianLOSDeletions = 0, physicianLOSAbstract = 0;
            int chiefComplaintChange = 0, primaryDxChange = 0,  dxChartsSubmitted = 0, infInjectionChange = 0, infInjectionChartsSubmitted = 0, modifierUsageChange = 0, demographicChanges = 0, obsHoursChanges = 0, obsHoursChartsSubmitted = 0;
            int MIPSSubmitted = 0, MIPSChanges = 0;
            int documentationDeficiencySubmitted = 0, documentationDeficiencyChanges = 0;

            //Get totals from list
            foreach (ChartQAScorecardSummary item in m_ScorecardCoderItems)
            {
                totalCodesCount += item.TotalCodesCount ?? 0;
                totalCorrectCodesCount += item.TotalCorrectCodesCount ?? 0;
                totalRevisedCodesCount += item.TotalRevisedCodesCount ?? 0;
                totalAddedCodesCount += item.TotalAddedCodesCount ?? 0;
                totalDeletedCodesCount += item.TotalDeletedCodesCount ?? 0;

                dxAttempted += item.DxAttempted ?? 0;
                dxCorrect += item.DxCorrect ?? 0;
                dxAdditions += item.DxAdditions ?? 0;
                dxRevisions += item.DxRevisions ?? 0;
                dxDeletions += item.DxDeletions ?? 0;
                dxAbstract += item.DxAbstract ?? 0;

                facProcAttempted += item.FacilityProcAttempted ?? 0;
                facProcCorrect += item.FacilityProcCorrect ?? 0;
                facProcAdditions += item.FacilityProcAdditions ?? 0;
                facProcRevisions += item.FacilityProcRevisions ?? 0;
                facProcDeletions += item.FacilityProcDeletions ?? 0;
                facProcAbstract += item.FacilityProcAbstract ?? 0;

                infusionInjectionAttempted += item.InfusionInjectionAttempted ?? 0;
                infusionInjectionCorrect += item.InfusionInjectionCorrect ?? 0;
                infusionInjectionAdditions += item.InfusionInjectionAdditions ?? 0;
                infusionInjectionRevisions += item.InfusionInjectionRevisions ?? 0;
                infusionInjectionDeletions += item.InfusionInjectionDeletions ?? 0;
                infusionInjectionAbstract += item.InfusionInjectionAbstract ?? 0;

                profProcAttempted += item.ProfProcAttempted ?? 0;
                profProcCorrect += item.ProfProcCorrect ?? 0;
                profProcAdditions += item.ProfProcAdditions ?? 0;
                profProcRevisions += item.ProfProcRevisions ?? 0;
                profProcDeletions += item.ProfProcDeletions ?? 0;
                profProcAbstract += item.ProfProcAbstract ?? 0;

                anesthesiaAttempted += item.AnesthesiaAttempted ?? 0;
                anesthesiaCorrect += item.AnesthesiaCorrect ?? 0;
                anesthesiaAdditions += item.AnesthesiaAdditions ?? 0;
                anesthesiaRevisions += item.AnesthesiaRevisions ?? 0;
                anesthesiaDeletions += item.AnesthesiaDeletions ?? 0;
                anesthesiaAbstract += item.AnesthesiaAbstract ?? 0;

                obsHoursAttempted += item.ObsHoursAttempted ?? 0;
                obsHoursCorrect += item.ObsHoursCorrect ?? 0;
                obsHoursAdditions += item.ObsHoursAdditions ?? 0;
                obsHoursRevisions += item.ObsHoursRevisions ?? 0;
                obsHoursDeletions += item.ObsHoursDeletions ?? 0;
                obsHoursAbstract += item.ObsHoursAbstract ?? 0;

                facilityLOSAttempted += item.FacilityLOSAttempted ?? 0;
                facilityLOSCorrect += item.FacilityLOSCorrect ?? 0;
                facilityLOSAdditions += item.FacilityLOSAdditions ?? 0;
                facilityLOSRevisions += item.FacilityLOSRevisions ?? 0;
                facilityLOSDeletions += item.FacilityLOSDeletions ?? 0;
                facilityLOSAbstract += item.FacilityLOSAbstract ?? 0;

                physicianLOSAttempted += item.PhysicianLOSAttempted ?? 0;
                physicianLOSCorrect += item.PhysicianLOSCorrect ?? 0;
                physicianLOSAdditions += item.PhysicianLOSAdditions ?? 0;
                physicianLOSRevisions += item.PhysicianLOSRevisions ?? 0;
                physicianLOSDeletions += item.PhysicianLOSDeletions ?? 0;
                physicianLOSAbstract += item.PhysicianLOSAbstract ?? 0;

                //Additional quality monitoring items
                chiefComplaintChange += item.DiagnosisChiefComplaintChanges ?? 0;
                primaryDxChange += item.DiagnosisPrimaryDxChanges ?? 0;
                dxChartsSubmitted += item.DiagnosisChartsSubmitted ?? 0;

                if (item.InfusionInjectionChanges > 0)
                    infInjectionChange += 1;
               
                infInjectionChartsSubmitted += item.InfusionInjectionChartsSubmitted ?? 0;
                obsHoursChanges += item.ObsHoursChanges ?? 0;
                obsHoursChartsSubmitted += item.ObsHoursChartsSubmitted ?? 0;
                //modifierUsageChange += item.ProcedureModifierChanges + (item.FacilityLOSModifierChanges + item.PhysicianLOSModifierChanges) ?? 0;
                if (item.ProcedureModifierChanges > 0 || item.FacilityLOSModifierChanges > 0 || item.PhysicianLOSModifierChanges > 0)
                {
                    modifierUsageChange += 1;
                }
                demographicChanges += item.DemographicChanges ?? 0;
                MIPSChanges += item.MIPSChanges ?? 0;
                MIPSSubmitted += item.MIPSSubmitted ?? 0;
                documentationDeficiencyChanges += item.DocumentationDeficiencyChanges ?? 0;
                documentationDeficiencySubmitted += item.DocumentationDeficiencySubmitted ?? 0;
            }

            // Coding specifics totals/overall accuracy
            int total1 = totalAddedCodesCount + totalRevisedCodesCount + totalDeletedCodesCount;
            int total2 = totalCorrectCodesCount + totalAddedCodesCount + totalRevisedCodesCount;
            lblOverallAccuracy.Text = "N/A";
            lblCoderAccuracy.Text = "N/A";
            if (total2 > 0)
            {
                int overallAccuracyPercentage = 100 - (Convert.ToInt32(Math.Round(Convert.ToDecimal(total1) * 100) / Convert.ToDecimal(total2)));
                //int overallAccuracyPercentage = (int)((decimal)total1 / (decimal)(total2) * 100);
                if (overallAccuracyPercentage < 0 )
                {
                    overallAccuracyPercentage = 0;
                }
                lblOverallAccuracy.Text = overallAccuracyPercentage.ToString() + "%";
                lblCoderAccuracy.Text = overallAccuracyPercentage.ToString() + "%";
            }

            lblCountAccurateCodes.Text = totalCorrectCodesCount.ToString();
            lblCountRevisions.Text = totalRevisedCodesCount.ToString();
            lblCountAdditions.Text = totalAddedCodesCount.ToString();
            lblCountDeletions.Text = totalDeletedCodesCount.ToString();


            //Coding Specifics section
            lblDxAccuracy.Text = "N/A";
            int dxSum = dxCorrect + dxRevisions + dxAdditions;
            if (dxSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)dxAdditions + (decimal)dxDeletions + (decimal)dxRevisions) / (decimal)(dxSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblDxAccuracy.Text = thisPercentage.ToString() + "%";
            }
            else if (dxCorrect + dxRevisions + dxAdditions > 0)
            {
                lblDxAccuracy.Text = "0%";
            }

            lblFacilityCPTAccuracy.Text = "N/A";
            int cptCorrectSum = facProcCorrect + facProcRevisions + facProcAdditions + infusionInjectionCorrect + infusionInjectionRevisions + infusionInjectionAdditions;
            int cptChangesSum = facProcDeletions + facProcRevisions + facProcAdditions + infusionInjectionDeletions + infusionInjectionRevisions + infusionInjectionAdditions;
                
            if (cptCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)cptChangesSum / (decimal)cptCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblFacilityCPTAccuracy.Text = thisPercentage.ToString() + "%";
            }
            else if (cptChangesSum > 0)
            {
                lblFacilityCPTAccuracy.Text = "0%";
            }

            lblPhysicianServicesAccuracy.Text = "N/A";
            int physicianLOSCorrectSum = physicianLOSCorrect + physicianLOSRevisions + physicianLOSAdditions;
            int physicianLOSChangesSum = physicianLOSDeletions + physicianLOSRevisions + physicianLOSAdditions;
            if (physicianLOSCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)physicianLOSChangesSum / (decimal)physicianLOSCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblPhysicianServicesAccuracy.Text = thisPercentage.ToString() + "%";
            }
            else if (physicianLOSChangesSum > 0)
            {
                lblPhysicianServicesAccuracy.Text = "0%";
            }

            lblFacilityServicesAccuracy.Text = "N/A";
            int facilityLOSCorrectSum = facilityLOSCorrect + facilityLOSRevisions + facilityLOSAdditions;
            int facilityLOSChangesSum = facilityLOSDeletions + facilityLOSRevisions + facilityLOSAdditions;
            if (facilityLOSCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)facilityLOSChangesSum / (decimal)facilityLOSCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblFacilityServicesAccuracy.Text = thisPercentage.ToString() + "%";
            }
            else if (facilityLOSChangesSum > 0)
            {
                lblFacilityServicesAccuracy.Text = "0%";
            }

            lblProfCPTAccuracy.Text = "N/A";
            int profCPTCorrectSum = profProcCorrect + profProcRevisions + profProcAdditions;
            int profCPTChangesSum = profProcDeletions + profProcRevisions + profProcAdditions;
            if (profCPTCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)profCPTChangesSum / (decimal)profCPTCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblProfCPTAccuracy.Text = thisPercentage.ToString() + "%";
            }
            else if (profCPTChangesSum > 0)
            {
                lblProfCPTAccuracy.Text = "0%";
            }

            lblAnesthesiaAccuracy.Text = "N/A";
            int anesthesiaCorrectSum = anesthesiaCorrect + anesthesiaRevisions + anesthesiaAdditions;
            int anesthesiaChangesSum = anesthesiaDeletions + anesthesiaRevisions + anesthesiaAdditions;
            if (anesthesiaCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)anesthesiaChangesSum / (decimal)anesthesiaCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblAnesthesiaAccuracy.Text = thisPercentage.ToString() + "%";
            }
            else if (anesthesiaChangesSum > 0)
            {
                lblAnesthesiaAccuracy.Text = "0%";
            }

            //lblObsHoursAccuracy.Text = "N/A";
            //int obsHoursCorrectSum = obsHoursCorrect + obsHoursRevisions + obsHoursAdditions;
            //int obsHoursChangesSum = obsHoursDeletions + obsHoursRevisions + obsHoursAdditions;
            //if (obsHoursCorrectSum > 0)
            //{
            //    int thisPercentage = 100 - (int)(((decimal)obsHoursChangesSum / (decimal)obsHoursCorrectSum) * 100);
            //    if (thisPercentage < 0)
            //    {
            //        thisPercentage = 0;
            //    }
            //    lblObsHoursAccuracy.Text = thisPercentage.ToString() + "%";
            //}
            //else if (obsHoursChangesSum > 0)
            //{
            //    lblObsHoursAccuracy.Text = "0%";
            //}

            // --------------Additional Quality Monitoring section 

            // Chief Complaint and Primary Dx accuracy
            if (dxChartsSubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)chiefComplaintChange / (decimal)(dxChartsSubmitted) * 100);
                lblChiefComplaintAccuracy.Text = accuracyPercentage.ToString() + "%";
                accuracyPercentage = 100 - (int)((decimal)primaryDxChange / (decimal)(dxChartsSubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblPrimaryDxAccuracy.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblChiefComplaintAccuracy.Text = "N/A";
                lblPrimaryDxAccuracy.Text = "N/A";
            }

            //Modifier usage accuracy
            if (chartsAuditedCount > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)modifierUsageChange / (decimal)(chartsAuditedCount) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblModifierUsageAccuracy.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblModifierUsageAccuracy.Text = "N/A";
            }

            //Infusion/Injection accuracy
            if (infInjectionChartsSubmitted > 0)
            {
                
                int accuracyPercentage = 100 - (int)((decimal)infInjectionChange / (decimal)(infInjectionChartsSubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblInfInjAccuracy.Text = accuracyPercentage.ToString() + "%";
            }
            else if (infInjectionChange > 0)
            {
                lblInfInjAccuracy.Text = "0%";
            }
            else
            {
                lblInfInjAccuracy.Text = "N/A";
            }

            //Observation hours accuracy
            if (obsHoursChartsSubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)obsHoursChanges / (decimal)(obsHoursChartsSubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblObsHoursAccuracy.Text = accuracyPercentage.ToString() + "%";
            }
            else if (obsHoursChanges > 0)
            {
                lblObsHoursAccuracy.Text = "0%";
            }
            else
            {
                lblObsHoursAccuracy.Text = "N/A";
            }

            //Demographcis accuracy
            if (chartsAuditedCount > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)demographicChanges / (decimal)(chartsAuditedCount) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblDemographicsAccuracy.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblDemographicsAccuracy.Text = "N/A";
            }

            //MIPS accuracy
            if (MIPSSubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)MIPSChanges / (decimal)(MIPSSubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblMIPSAccuracy.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblMIPSAccuracy.Text = "N/A";
            }

            //Documentation Deficiency accuracy
            if (documentationDeficiencySubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)documentationDeficiencyChanges / (decimal)(documentationDeficiencySubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblDocumentationDeficiencyAccuracy.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblDocumentationDeficiencyAccuracy.Text = "N/A";
            }

            grdScorecardCoderDetails.DataSource = m_ScorecardCoderItems;
            grdScorecardCoderDetails.DataBind();
            grdScorecardCoderDetails.Visible = true;

            divScorecardCoderResults.Visible = m_ScorecardCoderItems.Count > 0;
        }
        private void LoadAuditorScorecardDetails(int chartCount)
        {
            int totalCodesCount = 0;
            int totalCorrectCodesCount = 0;
            int totalRevisedCodesCount = 0;
            int totalAddedCodesCount = 0;
            int totalDeletedCodesCount = 0;
            int dxAttempted = 0, dxCorrect = 0, dxAdditions = 0, dxRevisions = 0, dxDeletions = 0, dxAbstract = 0;
            int facProcAttempted = 0, facProcCorrect = 0, facProcAdditions = 0, facProcRevisions = 0, facProcDeletions = 0, facProcAbstract = 0;
            int infusionInjectionAttempted = 0, infusionInjectionCorrect = 0, infusionInjectionAdditions = 0, infusionInjectionRevisions = 0, infusionInjectionDeletions = 0, infusionInjectionAbstract = 0;
            int profProcAttempted = 0, profProcCorrect = 0, profProcAdditions = 0, profProcRevisions = 0, profProcDeletions = 0, profProcAbstract = 0;
            int anesthesiaAttempted = 0, anesthesiaCorrect = 0, anesthesiaAdditions = 0, anesthesiaRevisions = 0, anesthesiaDeletions = 0, anesthesiaAbstract = 0;
            int obsHoursAttempted = 0, obsHoursCorrect = 0, obsHoursAdditions = 0, obsHoursRevisions = 0, obsHoursDeletions = 0, obsHoursAbstract = 0;
            int facilityLOSAttempted = 0, facilityLOSCorrect = 0, facilityLOSAdditions = 0, facilityLOSRevisions = 0, facilityLOSDeletions = 0, facilityLOSAbstract = 0;
            int physicianLOSAttempted = 0, physicianLOSCorrect = 0, physicianLOSAdditions = 0, physicianLOSRevisions = 0, physicianLOSDeletions = 0, physicianLOSAbstract = 0;
            int chiefComplaintChange = 0, primaryDxChange = 0, dxChartsSubmitted = 0, infInjectionChange = 0, infInjectionChartsSubmitted = 0, modifierUsageChange = 0, demographicChanges = 0, obsHoursChanges = 0, obsHoursChartsSubmitted = 0;
            int MIPSChanges = 0, MIPSSubmitted = 0;
            int documentationDeficiencySubmitted = 0, documentationDeficiencyChanges = 0;

            //Get totals from list
            foreach (ChartQAScorecardSummary item in m_ScorecardAuditorItems)
            {
                totalCodesCount += item.TotalCodesCount ?? 0;
                totalCorrectCodesCount += item.TotalCorrectCodesCount ?? 0;
                totalRevisedCodesCount += item.TotalRevisedCodesCount ?? 0;
                totalAddedCodesCount += item.TotalAddedCodesCount ?? 0;
                totalDeletedCodesCount += item.TotalDeletedCodesCount ?? 0;

                dxAttempted += item.DxAttempted ?? 0;
                dxCorrect += item.DxCorrect ?? 0;
                dxAdditions += item.DxAdditions ?? 0;
                dxRevisions += item.DxRevisions ?? 0;
                dxDeletions += item.DxDeletions ?? 0;
                dxAbstract += item.DxAbstract ?? 0;

                facProcAttempted += item.FacilityProcAttempted ?? 0;
                facProcCorrect += item.FacilityProcCorrect ?? 0;
                facProcAdditions += item.FacilityProcAdditions ?? 0;
                facProcRevisions += item.FacilityProcRevisions ?? 0;
                facProcDeletions += item.FacilityProcDeletions ?? 0;
                facProcAbstract += item.FacilityProcAbstract ?? 0;

                infusionInjectionAttempted += item.InfusionInjectionAttempted ?? 0;
                infusionInjectionCorrect += item.InfusionInjectionCorrect ?? 0;
                infusionInjectionAdditions += item.InfusionInjectionAdditions ?? 0;
                infusionInjectionRevisions += item.InfusionInjectionRevisions ?? 0;
                infusionInjectionDeletions += item.InfusionInjectionDeletions ?? 0;
                infusionInjectionAbstract += item.InfusionInjectionAbstract ?? 0;

                profProcAttempted += item.ProfProcAttempted ?? 0;
                profProcCorrect += item.ProfProcCorrect ?? 0;
                profProcAdditions += item.ProfProcAdditions ?? 0;
                profProcRevisions += item.ProfProcRevisions ?? 0;
                profProcDeletions += item.ProfProcDeletions ?? 0;
                profProcAbstract += item.ProfProcAbstract ?? 0;

                anesthesiaAttempted += item.AnesthesiaAttempted ?? 0;
                anesthesiaCorrect += item.AnesthesiaCorrect ?? 0;
                anesthesiaAdditions += item.AnesthesiaAdditions ?? 0;
                anesthesiaRevisions += item.AnesthesiaRevisions ?? 0;
                anesthesiaDeletions += item.AnesthesiaDeletions ?? 0;
                anesthesiaAbstract += item.AnesthesiaAbstract ?? 0;

                obsHoursAttempted += item.ObsHoursAttempted ?? 0;
                obsHoursCorrect += item.ObsHoursCorrect ?? 0;
                obsHoursAdditions += item.ObsHoursAdditions ?? 0;
                obsHoursRevisions += item.ObsHoursRevisions ?? 0;
                obsHoursDeletions += item.ObsHoursDeletions ?? 0;
                obsHoursAbstract += item.ObsHoursAbstract ?? 0;

                facilityLOSAttempted += item.FacilityLOSAttempted ?? 0;
                facilityLOSCorrect += item.FacilityLOSCorrect ?? 0;
                facilityLOSAdditions += item.FacilityLOSAdditions ?? 0;
                facilityLOSRevisions += item.FacilityLOSRevisions ?? 0;
                facilityLOSDeletions += item.FacilityLOSDeletions ?? 0;
                facilityLOSAbstract += item.FacilityLOSAbstract ?? 0;

                physicianLOSAttempted += item.PhysicianLOSAttempted ?? 0;
                physicianLOSCorrect += item.PhysicianLOSCorrect ?? 0;
                physicianLOSAdditions += item.PhysicianLOSAdditions ?? 0;
                physicianLOSRevisions += item.PhysicianLOSRevisions ?? 0;
                physicianLOSDeletions += item.PhysicianLOSDeletions ?? 0;
                physicianLOSAbstract += item.PhysicianLOSAbstract ?? 0;

                //Additional quality monitoring items
                chiefComplaintChange += item.DiagnosisChiefComplaintChanges ?? 0;
                primaryDxChange += item.DiagnosisPrimaryDxChanges ?? 0;
                dxChartsSubmitted += item.DiagnosisChartsSubmitted ?? 0;

                if (item.InfusionInjectionChanges > 0)
                    infInjectionChange += 1;

                infInjectionChartsSubmitted += item.InfusionInjectionChartsSubmitted ?? 0;
                obsHoursChanges += item.ObsHoursChanges ?? 0;
                obsHoursChartsSubmitted += item.ObsHoursChartsSubmitted ?? 0;

                //modifierUsageChange += item.ProcedureModifierChanges + (item.FacilityLOSModifierChanges + item.PhysicianLOSModifierChanges) ?? 0;
                if (item.ProcedureModifierChanges > 0 || item.FacilityLOSModifierChanges > 0 || item.PhysicianLOSModifierChanges > 0)
                {
                    modifierUsageChange += 1;
                }
                
                demographicChanges += item.DemographicChanges ?? 0;
                MIPSChanges += item.MIPSChanges ?? 0;
                MIPSSubmitted += item.MIPSSubmitted ?? 0;
                documentationDeficiencyChanges += item.DocumentationDeficiencyChanges ?? 0;
                documentationDeficiencySubmitted += item.DocumentationDeficiencySubmitted ?? 0;
            }

            // Coding specifics totals/overall accuracy
            int total1 = totalAddedCodesCount + totalRevisedCodesCount + totalDeletedCodesCount;
            int total2 = totalCorrectCodesCount + totalAddedCodesCount + totalRevisedCodesCount;
            lblOverallAccuracyAuditor.Text = "N/A";
            lblAuditorAccuracy.Text = "N/A";
            if (total2 > 0)
            {
                int overallAccuracyPercentage = 100 - (Convert.ToInt32(Math.Round(Convert.ToDecimal(total1) * 100) / Convert.ToDecimal(total2)));
                //int overallAccuracyPercentage = (int)((decimal)total1 / (decimal)(total2) * 100);
                if (overallAccuracyPercentage < 0)
                {
                    overallAccuracyPercentage = 0;
                }
                lblOverallAccuracyAuditor.Text = overallAccuracyPercentage.ToString() + "%";
                lblAuditorAccuracy.Text = overallAccuracyPercentage.ToString() + "%";
            }

            lblCountAccurateCodesAuditor.Text = totalCorrectCodesCount.ToString();
            lblCountRevisionsAuditor.Text = totalRevisedCodesCount.ToString();
            lblCountAdditionsAuditor.Text = totalAddedCodesCount.ToString();
            lblCountDeletionsAuditor.Text = totalDeletedCodesCount.ToString();
            //lblAuditorAccuracy.Text = "N/A";
            //if (totalCodesCount > 0)
            //{
            //    int accuracyPercentage = (int)((decimal)totalCorrectCodesCount / (decimal)(totalCodesCount) * 100);
            //    if (accuracyPercentage < 0)
            //    {
            //        accuracyPercentage = 0;
            //    }
            //    lblAuditorAccuracy.Text = accuracyPercentage.ToString() + "%";
            //}
            //else
            //{
            //    lblAuditorAccuracy.Text = String.Empty;
            //}

            //Coding Specifics section
            lblDxAccuracyAuditor.Text = "N/A";
            int dxSum = dxCorrect + dxRevisions + dxAdditions;
            if (dxSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)dxAdditions + (decimal)dxDeletions + (decimal)dxRevisions) / (decimal)(dxSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblDxAccuracyAuditor.Text = thisPercentage.ToString() + "%";
            }
            else if (dxCorrect + dxRevisions + dxAdditions > 0)
            {
                lblDxAccuracyAuditor.Text = "0%";
            }

            lblFacilityCPTAccuracyAuditor.Text = "N/A";
            int cptCorrectSum = facProcCorrect + facProcRevisions + facProcAdditions + infusionInjectionCorrect + infusionInjectionRevisions + infusionInjectionAdditions;
            int cptChangesSum = facProcDeletions + facProcRevisions + facProcAdditions + infusionInjectionDeletions + infusionInjectionRevisions + infusionInjectionAdditions;
            if (cptCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)cptChangesSum / (decimal)cptCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblFacilityCPTAccuracyAuditor.Text = thisPercentage.ToString() + "%";
            }
            else if (cptChangesSum > 0)
            {
                lblFacilityCPTAccuracyAuditor.Text = "0%";
            }

            lblPhysicianServicesAccuracyAuditor.Text = "N/A";
            int physicianLOSCorrectSum = physicianLOSCorrect + physicianLOSRevisions + physicianLOSAdditions;
            int physicianLOSChangesSum = physicianLOSDeletions + physicianLOSRevisions + physicianLOSAdditions;
            if (physicianLOSCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)physicianLOSChangesSum / (decimal)physicianLOSCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblPhysicianServicesAccuracyAuditor.Text = thisPercentage.ToString() + "%";
            }
            else if (physicianLOSChangesSum > 0)
            {
                lblPhysicianServicesAccuracyAuditor.Text = "0%";
            }

            lblFacilityServicesAccuracyAuditor.Text = "N/A";
            int facilityLOSCorrectSum = facilityLOSCorrect + facilityLOSRevisions + facilityLOSAdditions;
            int facilityLOSChangesSum = facilityLOSDeletions + facilityLOSRevisions + facilityLOSAdditions;
            if (facilityLOSCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)facilityLOSChangesSum / (decimal)facilityLOSCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblFacilityServicesAccuracyAuditor.Text = thisPercentage.ToString() + "%";
            }
            else if (facilityLOSChangesSum > 0)
            {
                lblFacilityServicesAccuracyAuditor.Text = "0%";
            }

            lblProfCPTAccuracyAuditor.Text = "N/A";
            int profCPTCorrectSum = profProcCorrect + profProcDeletions + profProcRevisions + profProcAdditions;
            int profCPTChangesSum = profProcDeletions + profProcRevisions + profProcAdditions;
            if (profCPTCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)profCPTChangesSum / (decimal)profCPTCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblProfCPTAccuracyAuditor.Text = thisPercentage.ToString() + "%";
            }
            else if (profCPTChangesSum > 0)
            {
                lblProfCPTAccuracyAuditor.Text = "0%";
            }

            lblAnesthesiaAccuracy.Text = "N/A";
            int anesthesiaCorrectSum = anesthesiaCorrect + anesthesiaRevisions + anesthesiaAdditions;
            int anesthesiaChangesSum = anesthesiaDeletions + anesthesiaRevisions + anesthesiaAdditions;
            if (anesthesiaCorrectSum > 0)
            {
                int thisPercentage = 100 - (int)(((decimal)anesthesiaChangesSum / (decimal)anesthesiaCorrectSum) * 100);
                if (thisPercentage < 0)
                {
                    thisPercentage = 0;
                }
                lblAnesthesiaAccuracyAuditor.Text = thisPercentage.ToString() + "%";
            }
            else if (anesthesiaChangesSum > 0)
            {
                lblAnesthesiaAccuracyAuditor.Text = "0%";
            }

            //lblObsHoursAccuracyAuditor.Text = "N/A";
            //int obsHoursCorrectSum = obsHoursDeletions + obsHoursRevisions + obsHoursAdditions;
            //int obsHoursChangesSum = obsHoursDeletions + obsHoursRevisions + obsHoursAdditions;
            //if (obsHoursCorrectSum > 0)
            //{
            //    int thisPercentage = 100 - (int)(((decimal)obsHoursChangesSum / (decimal)obsHoursCorrectSum) * 100);
            //    if (thisPercentage < 0)
            //    {
            //        thisPercentage = 0;
            //    }
            //    lblObsHoursAccuracyAuditor.Text = thisPercentage.ToString() + "%";
            //}
            //else if (obsHoursChangesSum > 0)
            //{
            //    lblObsHoursAccuracyAuditor.Text = "0%";
            //}

            // --------------Additional Quality Monitoring section 

            // Chief Complaint and Primary Dx accuracy
            if (dxChartsSubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)chiefComplaintChange / (decimal)(dxChartsSubmitted) * 100);
                lblChiefComplaintAccuracyAuditor.Text = accuracyPercentage.ToString() + "%";
                accuracyPercentage = 100 - (int)((decimal)primaryDxChange / (decimal)(dxChartsSubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblPrimaryDxAccuracyAuditor.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblChiefComplaintAccuracyAuditor.Text = "N/A";
                lblPrimaryDxAccuracyAuditor.Text = "N/A";
            }

            //Modifier usage accuracy
            if (chartsSecondAuditedForAuditor > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)modifierUsageChange / (decimal)(chartsSecondAuditedForAuditor) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblModifierUsageAccuracyAuditor.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblModifierUsageAccuracyAuditor.Text = "N/A";
            }

            //Infusion/Injection accuracy
            if (infInjectionChartsSubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)infInjectionChange / (decimal)(infInjectionChartsSubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblInfInjAccuracyAuditor.Text = accuracyPercentage.ToString() + "%";
            }
            else if (infInjectionChange > 0)
            {
                lblInfInjAccuracyAuditor.Text = "0%";
            }
            else
            {
                lblInfInjAccuracyAuditor.Text = "N/A";
            }

            //Observation hours accuracy
            if (obsHoursChartsSubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)obsHoursChanges / (decimal)(obsHoursChartsSubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblObsHoursAccuracyAuditor.Text = accuracyPercentage.ToString() + "%";
            }
            else if (obsHoursChanges > 0)
            {
                lblObsHoursAccuracyAuditor.Text = "0%";
            }
            else
            {
                lblObsHoursAccuracyAuditor.Text = "N/A";
            }

            //Demographcis accuracy
            if (chartsSecondAuditedForAuditor > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)demographicChanges / (decimal)(chartsSecondAuditedForAuditor) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblDemographicsAccuracyAuditor.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblDemographicsAccuracyAuditor.Text = "N/A";
            }

            //MIPS accuracy
            if (MIPSSubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)MIPSChanges / (decimal)(MIPSSubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblMIPSAccuracyAuditor.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblMIPSAccuracyAuditor.Text = "N/A";
            }
            
            //Documentation Deficiency accuracy
            if (documentationDeficiencySubmitted > 0)
            {
                int accuracyPercentage = 100 - (int)((decimal)documentationDeficiencyChanges / (decimal)(documentationDeficiencySubmitted) * 100);
                if (accuracyPercentage < 0)
                {
                    accuracyPercentage = 0;
                }
                lblDocumentationDeficiencyAccuracyAuditor.Text = accuracyPercentage.ToString() + "%";
            }
            else
            {
                lblDocumentationDeficiencyAccuracyAuditor.Text = "N/A";
            }

            grdScorecardAuditorDetails.DataSource = m_ScorecardAuditorItems;
            grdScorecardAuditorDetails.DataBind();
            grdScorecardAuditorDetails.Visible = true;

            if (m_ScorecardCoderItems.Count > 0 || m_ScorecardAuditorItems.Count > 0)
            {
                divScorecardCoderResults.Visible = true;
            }
            
        }
        private void LoadQAScorecard(DateTime fromDate, DateTime toDate, int userProfileID)
        {
            lblSummaryCoder.Text = "QA Feedback for: " + m_RequestManager.SessionManager.SignedOnUserProfile.Name.FormattedNameWithSuffix.ToString();
            lblSummaryCoder.Text += " from " + fromDate.ToShortDateString() + " to " + toDate.ToShortDateString();

            ChartQAScorecardSummaryDAO scDAO = new ChartQAScorecardSummaryDAO(m_RequestManager);
            m_ScorecardCoderItems = scDAO.LoadFeedbackList(fromDate, toDate, userProfileID);
            m_ScorecardAuditorItems = scDAO.LoadFeedbackListAuditor(fromDate, toDate, userProfileID);
           // m_FeedbackResultsAuditor = feedbackDAO.LoadSecondAuditFeedbackList(FromDate, ToDate, userProfileID);
            chartsCodedCount = scDAO.GetTotalChartsCountForCoder(fromDate, toDate, userProfileID);
            chartsAuditedCount = scDAO.GetTotalChartsReviewedCountForCoder(fromDate, toDate, userProfileID);
            chartsApprovedByAuditor = scDAO.GetTotalChartsApprovedCountForFirstAuditor(fromDate, toDate, userProfileID);
            chartsSecondAuditedForAuditor = scDAO.GetTotalChartsReviewedCountForFirstAuditor(fromDate, toDate, userProfileID);

            lblTotalChartsCoded.Text = chartsCodedCount.ToString();
            lblTotalChartsAudited.Text = chartsAuditedCount.ToString();

            divScorecardCoderResults.Visible = (chartsCodedCount > 0 || chartsAuditedCount > 0);
            if (chartsCodedCount > 0)
            {
                LoadCoderScorecardDetails(chartsCodedCount);
                int reviewedPercentage = (int)(((decimal)chartsAuditedCount / (decimal)chartsCodedCount) * 100);
                this.lblPercentReviewed.Text = reviewedPercentage.ToString() + "%";
                tblScorecardCoderSummary.Visible = true;
                tblScorecardCoderAccuracy.Visible = true;
                tblCoderDetailsGrid.Visible = true;
            }
            else
            {
                lblTotalChartsAudited.Text = "0";
                tblScorecardCoderSummary.Visible = false;
                tblScorecardCoderAccuracy.Visible = false;
                tblCoderDetailsGrid.Visible = false;
            }

            //Second Audit review
            if (chartsApprovedByAuditor > 0)
            {
                LoadAuditorScorecardDetails(chartsApprovedByAuditor);
                lblTotalChartsSecondAudited.Text = chartsSecondAuditedForAuditor.ToString();
                lblChartsApproved.Text = chartsApprovedByAuditor.ToString();
                int reviewedPercentage = (int)(((decimal)chartsSecondAuditedForAuditor / (decimal)chartsApprovedByAuditor) * 100);
                this.lblPercentReviewedAuditor.Text = reviewedPercentage.ToString() + "%";
                tblScorecardAuditorSummary.Visible = true;
                tblScorecardAuditorAccuracy.Visible = true;
                tblAuditorDetailsGrid.Visible = true;
                lblAuditorScorecard.Visible = true;
                lblSecondAuditGridHeading.Visible = true;
            }
            else
            {
                lblTotalChartsSecondAudited.Text = "0";
                tblScorecardAuditorSummary.Visible = false;
                tblScorecardAuditorAccuracy.Visible = false;
                tblAuditorDetailsGrid.Visible = false;
                lblAuditorScorecard.Visible = false;
                lblSecondAuditGridHeading.Visible = false;
            }

            divCoderResults.Visible = false;
            divAuditorResults.Visible = false;
        }

        private void LoadQAReview()
        {
            DateTime fromDate = new DateTime();
            btnRefresh.Visible = false;
            dfFromDate.Visible = false;
            dfToDate.Visible = false;
            divDateRange.Visible = false;
            lblNoResults.Visible = false;
            trNoResults.Visible = false;
            tdDateRange.Visible = false;

            //If this is the first time the user is reviewing QA feedback online, default to the last time the user logged on, less 3 days. 
            if (m_RequestManager.SessionManager.SignedOnUserProfile.LastReviewedQAFeedback == null)
            {
                DateTime lastLogonDate = new UserLogonDAO(m_RequestManager).GetLastLogonDateForUser(m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID);
                if (lastLogonDate == null || lastLogonDate == DateTime.MinValue)
                {
                    fromDate = DateTime.Now.AddDays(-3);
                }
                else
                {
                    fromDate = lastLogonDate.AddDays(-3);
                }
            }
            else
            {
                fromDate = Convert.ToDateTime(m_RequestManager.SessionManager.SignedOnUserProfile.LastReviewedQAFeedback);
            }

            DateTime toDate = DateTime.Now;
            dfFromDate.Text = fromDate.ToShortDateString();
            dfToDate.Text = toDate.ToShortDateString();

            int userProfileID = m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID;
            //ACS-15642  Load the scorecard controls based on user
            if (m_RequestManager.SessionManager.SignedOnUserProfile.HasRight(UserRight.RIGHT_USE_QA_SCORECARD_FOR_AUDIT_FEEDBACK))
            {
                LoadQAScorecard(fromDate, toDate, userProfileID);
            }
            else
            {
                ChartQAFeedbackItemDAO feedbackDAO = new ChartQAFeedbackItemDAO(m_RequestManager);
                m_ChartDAO = new ChartDAO(m_RequestManager);

                m_FeedbackResults = feedbackDAO.LoadFeedbackList(fromDate, toDate, userProfileID);
                m_FeedbackResultsAuditor = feedbackDAO.LoadSecondAuditFeedbackList(fromDate, toDate, userProfileID);

                lblSummaryCoder.Text = "QA Feedback for: " + m_RequestManager.SessionManager.SignedOnUserProfile.Name.FormattedNameWithSuffix.ToString();
                lblSummaryCoder.Text += " from " + fromDate.ToShortDateString() + " to " + toDate.ToShortDateString();

                //Coder
                if (m_FeedbackResults.Count > 0)
                {
                    ChartQAFeedbackSummary summary = new ChartQAFeedbackSummaryDAO(m_RequestManager).Load(fromDate, toDate, userProfileID);

                    lblFacilityServiceCoder.Text = FormatRate(summary.FacilityLOSAvailable, summary.FacilityLOSRate);
                    lblFacilityInfInjCoder.Text = FormatRate(summary.FacilityInfInjAvailable, summary.FacilityInfInjRate);
                    lblFacilityProcCoder.Text = FormatRate(summary.FacilityProcAvailable, summary.FacilityProcRate);
                    lblPhysicianServiceCoder.Text = FormatRate(summary.PhysicianLOSAvailable, summary.PhysicianLOSRate);
                    lblPhysicianProcCoder.Text = FormatRate(summary.PhysicianProcAvailable, summary.PhysicianProcRate);
                    lblDiagnosisCoder.Text = FormatRate(summary.DiagnosisAvailable, summary.DiagnosisRate);
                    lblDemographicsCoder.Text = FormatRate(summary.DemographicsAvailable, summary.DemographicsRate);
                    lblObsHoursCoder.Text = FormatRate(summary.ObsHoursAvailable, summary.ObsHoursRate);
                    lblObsInfInjCoder.Text = FormatRate(summary.ObsInfInjAvailable, summary.ObsInfInjRate);
                    lblObsProcCoder.Text = FormatRate(summary.ObsProcAvailable, summary.ObsProcRate);

                    lblTotalRate.Text = FormatRate(summary.TotalRate);
                    lblTotalChartsCoder.Text += summary.TotalCharts.ToString();
                    lblTotalAuditedCoder.Text += summary.TotalChartsAudited.ToString();


                    this.grdResults.DataSource = m_FeedbackResults;
                    grdResults.DataBind();
                    divCoderResults.Visible = true;
                }

                //Auditor (2nd level audits)
                if (m_FeedbackResultsAuditor.Count > 0)
                {
                    ChartQAFeedbackSummary summary = new ChartQAFeedbackSummaryDAO(m_RequestManager).LoadAuditor(fromDate, toDate, userProfileID);
                    this.lblFacilityServiceAuditor.Text = FormatRate(summary.FacilityLOSRate);
                    lblFacilityInfInjAuditor.Text = FormatRate(summary.FacilityInfInjRate);
                    lblFacilityProcAuditor.Text = FormatRate(summary.FacilityProcRate);
                    lblPhysicianServiceAuditor.Text = FormatRate(summary.PhysicianLOSRate);
                    lblPhysicianProcAuditor.Text = FormatRate(summary.PhysicianProcRate);
                    lblDiagnosisAuditor.Text = FormatRate(summary.DiagnosisRate);
                    lblDemographicsAuditor.Text = FormatRate(summary.DemographicsRate);
                    lblTotalRateAuditor.Text = FormatRate(summary.TotalRate);
                    this.lblTotalCharts2ndAudited.Text += summary.TotalCharts.ToString();
                    this.lblTotal2ndLevelChanged.Text += summary.TotalChartsAudited.ToString();

                    this.grdResultsAuditor.DataSource = m_FeedbackResults;
                    grdResultsAuditor.DataBind();
                    divAuditorResults.Visible = true;
                }
            }

            if (divCoderResults.Visible || divAuditorResults.Visible)
            {
                this.pnlConrol.Visible = true;
                pnlQA.Visible = true;
                popupQAFeedback.Show();
            }
            else if (divScorecardCoderResults.Visible)
            {
                pnlQA.Visible = true;
                popupQAFeedback.Show();
            }
        }

        private String FormatRate(decimal rateToFormat)
        {
            String formattedRate = String.Empty;

            if (rateToFormat == -1)
            {
                formattedRate = "N/A";
            }
            else
            {
                formattedRate = rateToFormat.ToString("P1");
            }

            return formattedRate;
        }

        private String FormatRate(decimal attempted, decimal rateToFormat)
        {
            String formattedRate = String.Empty;

            //If the attempted qty is greater than zero but no points earned, rate is 0% instead of "N/A"
            if (attempted > 0 && rateToFormat == -1)
            {
                rateToFormat = 0;
            }

            if (rateToFormat == -1)
            {
                formattedRate = "N/A";
            }
            else
            {
                formattedRate = rateToFormat.ToString("P1");
            }
            
            return formattedRate;
        }
        protected void grdResults_ItemDataBound(object sender, DataGridItemEventArgs e)
        {
            if (e.Item.ItemIndex >= 0)
            {                
                ChartQAFeedbackItem currentItem = (ChartQAFeedbackItem)e.Item.DataItem;                
                LinkButton lnkAuditReview = (LinkButton)e.Item.FindControl("lnkAuditReviewCoder");
                lnkAuditReview.Visible = m_ShowAccountLink;
                lnkAuditReview.CommandArgument = currentItem.ChartID.ToString();

                Label lblFacilityLOSPassFail = (Label)e.Item.FindControl("lblFacilityLOSPassFail");
                Label lblFacilityLOSComment = (Label)e.Item.FindControl("lblFacilityLOSComment");
                if (lblFacilityLOSPassFail.Text.ToUpper() == "FAIL")
                {
                    lblFacilityLOSPassFail.BackColor = Color.Yellow;
                    lblFacilityLOSComment.BackColor = Color.Yellow;
                }

                Label lblFacilityInfInjPassFail = (Label)e.Item.FindControl("lblFacilityInfInjPassFail");
                Label lblFacilityInfInjComment = (Label)e.Item.FindControl("lblFacilityInfInjComment");
                if (lblFacilityInfInjPassFail.Text.ToUpper() == "FAIL")
                {
                    lblFacilityInfInjPassFail.BackColor = Color.Yellow;
                    lblFacilityInfInjComment.BackColor = Color.Yellow;
                }

                Label lblFacilityProcPassFail = (Label)e.Item.FindControl("lblFacilityProcPassFail");
                Label lblFacilityProcComment = (Label)e.Item.FindControl("lblFacilityProcComment");
                if (lblFacilityProcPassFail.Text.ToUpper() == "FAIL")
                {
                    lblFacilityProcPassFail.BackColor = Color.Yellow;
                    lblFacilityProcComment.BackColor = Color.Yellow;
                }
                
                Label lblPhysicianLOSPassFail = (Label)e.Item.FindControl("lblPhysicianLOSPassFail");
                Label lblPhysicianLOSComment = (Label)e.Item.FindControl("lblPhysicianLOSComment");
                if (lblPhysicianLOSPassFail.Text.ToUpper() == "FAIL")
                {
                    lblPhysicianLOSPassFail.BackColor = Color.Yellow;
                    lblPhysicianLOSComment.BackColor = Color.Yellow;
                }
                
                Label lblPhysicianProcPassFail = (Label)e.Item.FindControl("lblPhysicianProcPassFail");
                Label lblPhysicianProcComment = (Label)e.Item.FindControl("lblPhysicianProcComment");
                if (lblPhysicianProcPassFail.Text.ToUpper() == "FAIL")
                {
                    lblPhysicianProcPassFail.BackColor = Color.Yellow;
                    lblPhysicianProcComment.BackColor = Color.Yellow;
                }
                
                Label lblDiagnosisPassFail = (Label)e.Item.FindControl("lblDiagnosisPassFail");
                Label lblDiagnosisComment = (Label)e.Item.FindControl("lblDiagnosisComment");
                if (lblDiagnosisPassFail.Text.ToUpper() == "FAIL")
                {
                    lblDiagnosisPassFail.BackColor = Color.Yellow;
                    lblDiagnosisComment.BackColor = Color.Yellow;
                }
                
                Label lblDemographicsPassFail = (Label)e.Item.FindControl("lblDemographicsPassFail");
                Label lblDemographicsComment = (Label)e.Item.FindControl("lblDemographicsComment");
                if (lblDemographicsPassFail.Text.ToUpper() == "FAIL")
                {
                    lblDemographicsPassFail.BackColor = Color.Yellow;
                    lblDemographicsComment.BackColor = Color.Yellow;
                }

                Label lblObsHoursPassFail = (Label)e.Item.FindControl("lblObsHoursPassFail");
                Label lblObsHoursComment = (Label)e.Item.FindControl("lblObsHoursComment");
                if (lblObsHoursPassFail.Text.ToUpper() == "FAIL")
                {
                    lblObsHoursPassFail.BackColor = Color.Yellow;
                    lblObsHoursComment.BackColor = Color.Yellow;
                }
                Label lblObsInfInjPassFail = (Label)e.Item.FindControl("lblObsInfInjPassFail");
                Label lblObsInfInjComment = (Label)e.Item.FindControl("lblObsInfInjComment");
                if (lblObsInfInjPassFail.Text.ToUpper() == "FAIL")
                {
                    lblObsInfInjPassFail.BackColor = Color.Yellow;
                    lblObsInfInjComment.BackColor = Color.Yellow;
                }
                Label lblObsProcPassFail = (Label)e.Item.FindControl("lblObsProcPassFail");
                Label lblObsProcComment = (Label)e.Item.FindControl("lblObsProcComment");
                if (lblObsProcPassFail.Text.ToUpper() == "FAIL")
                {
                    lblObsProcPassFail.BackColor = Color.Yellow;
                    lblObsProcComment.BackColor = Color.Yellow;
                }
                ListBox lstChartAuditAction = (ListBox)e.Item.FindControl("lstChartAuditAction");
                lstChartAuditAction.BorderStyle = BorderStyle.None;

                Chart thisChart = m_ChartDAO.Load(currentItem.ChartID);

                ArrayList fs = thisChart.FacilityServiceEvaluation.PerformAuditComparison();
                if (fs.Count > 0)
                {
                    //foreach (Chart_ChartLOSHistoryDiff obj in fs)
                    //{
                    //    lstChartAuditAction.Items.Add("Fac Services-" + obj.comparisonResult + ": " + obj.description);
                    //}
                    foreach (Object obj in fs)
                    {
                        String fsDescription = String.Empty;
                        if (obj.GetType().Name == "FacilityServiceEvaluationListItem")
                        {
                            FacilityServiceEvaluationListItem fsItem = (FacilityServiceEvaluationListItem)obj;
                            lstChartAuditAction.Items.Add("Fac Services-" + fsItem.ComparisonResult + ": " + fsItem.Description);
                        }
                        else
                        {
                            Chart_ChartLOSHistoryDiff fsItem = (Chart_ChartLOSHistoryDiff)obj;
                            lstChartAuditAction.Items.Add("Fac Services-" + fsItem.comparisonResult + ": " + fsItem.description);
                        }
                    }
                }

                FacilityServiceEvaluationListDAO evalDAO = new FacilityServiceEvaluationListDAO(m_RequestManager);
                ArrayList facilityLOSChanges = evalDAO.GetFacilityLOSChange(thisChart.ChartID);
                if (facilityLOSChanges.Count > 0)
                {
                    const String baseDescription = "Based on auditor action, ";
                    String losChangeDescription = string.Empty;

                    if (!facilityLOSChanges[1].ToString().Equals(facilityLOSChanges[3].ToString()))
                    {
                        losChangeDescription += baseDescription + "Facility LOS changed from '";
                        losChangeDescription += facilityLOSChanges[3].ToString() + "' to '";
                        losChangeDescription += facilityLOSChanges[1].ToString() + "'";
                        lstChartAuditAction.Items.Add(losChangeDescription);
                    }
                }

                ArrayList inf = thisChart.ChartInfusionEvaluation.PerformAuditComparison(1);
                if (inf.Count > 0)
                {
                    foreach (ChartInfusionResultListItem obj in inf)
                    {
                        lstChartAuditAction.Items.Add("Inf/Inj-" + obj.ComparisonResult + ": " + obj.ProcedureDescription + ", " + obj.Modifiers);
                    }
                }

                ArrayList fp = thisChart.FacilityProcedureEvaluation.PerformAuditComparison(1);
                if (fp.Count > 0)
                {
                    foreach (FacilityProcedureEvaluationListItem obj in fp)
                    {
                        lstChartAuditAction.Items.Add("Fac Proc-" + obj.ComparisonResult + ": " + obj.ProcedureDescription);
                    }
                }

                ArrayList pp = thisChart.PhysicianProcedureEvaluation.PerformAuditComparison();
                if (pp.Count > 0)
                {
                    foreach (PhysicianProcedureEvaluationListItem obj in pp)
                    {
                        lstChartAuditAction.Items.Add("Phys Proc-" + obj.ComparisonResult + ": " + obj.ProcedureDescription);
                    }
                }

                ArrayList pe = thisChart.PhysicianEvaluationRating.PerformAuditComparison();
                if (pe.Count > 0)
                {
                    foreach (Object obj in pe)
                    {
                        if (obj.GetType().Name == "PhysicianServiceEvaluationListItem")
                        {
                            PhysicianServiceEvaluationListItem compareItem = (PhysicianServiceEvaluationListItem)obj;
                            if (compareItem.ExcludeFromCoderQAReport == false)
                            {
                                String objDesc = compareItem.ServiceDescription;
                                objDesc = RemoveHTMLElementsFromDescription(objDesc);
                                if (objDesc.Length > 60)
                                {
                                    objDesc = compareItem.ServiceDescription.Substring(0, 60) + "...";
                                }
                                lstChartAuditAction.Items.Add("Phys E&M-" + compareItem.ComparisonResult + ": " + objDesc);
                            }
                        }
                        else
                        {
                            Chart_ChartLOSHistoryDiff compareItem = (Chart_ChartLOSHistoryDiff)obj;
                            if (compareItem.ExcludeFromCoderQAReport == false)
                            {
                                String objDesc = compareItem.description;
                                objDesc = RemoveHTMLElementsFromDescription(objDesc);
                                lstChartAuditAction.Items.Add("Phys E&M-" + objDesc);
                            }
                        }
                    }
                }

                PhysicianServiceEvaluationListDAO physicianEvalDAO = new PhysicianServiceEvaluationListDAO(m_RequestManager);
                ArrayList physicianLOSChanges = physicianEvalDAO.GetPhysicianLOSChange(thisChart.ChartID);

                if (physicianLOSChanges.Count > 0)
                {
                    String losChangeDescription = "Based on auditor action, Physician LOS changed from '";
                    losChangeDescription += physicianLOSChanges[3].ToString() + "' to '";
                    losChangeDescription += physicianLOSChanges[1].ToString() + "'";
                    lstChartAuditAction.Items.Add(losChangeDescription);
                }

                if (thisChart.ServiceAgreement.PerformDiagnosisCoding == true)
                {
                    if (thisChart.ServiceAgreement.DiagnosisCodingICD10EffectiveDate <= thisChart.TimeOfService)
                    {
                        ArrayList dx = thisChart.DiagnosisCodingEvaluation.PerformAuditComparisonICD10();
                        if (dx.Count > 0)
                        {
                            foreach (ChartDiagnosisCodeICD10 obj in dx)
                            {
                                lstChartAuditAction.Items.Add("Diagnosis-" + obj.ComparisonResult + ": " + obj.ICD10Description);
                            }
                        }
                    }
                    else
                    {
                        ArrayList dx = thisChart.DiagnosisCodingEvaluation.PerformAuditComparison();
                        if (dx.Count > 0)
                        {
                            foreach (ChartDiagnosisCodeListItem obj in dx)
                            {
                                lstChartAuditAction.Items.Add("Diagnosis-" + obj.ComparisonResult + ": " + obj.Description);
                            }
                        }
                    }
                }

                ChartDemographicHistoryDAO cdhDAO = new ChartDemographicHistoryDAO(m_RequestManager);
                m_ChartDemographicChanges = cdhDAO.GetDemographicChanges(thisChart.ChartID);

                List<ChartDemographicComparison> demographicsComparison;
                bool demoComp = ChartDemographicComparison.PerformComparison(thisChart, m_ChartDemographicChanges, out demographicsComparison);
                if (demographicsComparison.Count > 0)
                {
                    foreach (ChartDemographicComparison obj in demographicsComparison)
                    {
                        lstChartAuditAction.Items.Add("Demographics-" + obj.ComparisonResult);
                    }
                }
            }
        }
        protected void grdScorecardCoderDetails_ItemDataBound(object sender, DataGridItemEventArgs e)
        {
            if (e.Item.ItemIndex >= 0)
            {
                ChartQAScorecardSummary currentItem = (ChartQAScorecardSummary)e.Item.DataItem;
                LinkButton lnkAuditReview = (LinkButton)e.Item.FindControl("lnkAuditReviewCoder");
                lnkAuditReview.Visible = m_ShowAccountLink;
                lnkAuditReview.CommandArgument = currentItem.ChartID.ToString();
                Chart thisChart = new ChartDAO(m_RequestManager).Load(currentItem.ChartID);

                Label lblAuditorNotes = (Label)e.Item.FindControl("lblAuditorNotes");
                Label lblFacilityLOSPassFail = (Label)e.Item.FindControl("lblFacilityLOSPassFail");
                Label lblFacilityInfInjPassFail = (Label)e.Item.FindControl("lblFacilityInfInjPassFail");
                Label lblFacilityProcPassFail = (Label)e.Item.FindControl("lblFacilityProcPassFail");
                Label lblPhysicianLOSPassFail = (Label)e.Item.FindControl("lblPhysicianLOSPassFail");
                Label lblPhysicianProcPassFail = (Label)e.Item.FindControl("lblPhysicianProcPassFail");
                Label lblDiagnosisPassFail = (Label)e.Item.FindControl("lblDiagnosisPassFail");
                Label lblObsHoursPassFail = (Label)e.Item.FindControl("lblObsHoursPassFail");
                Label lblDateApproved = (Label)e.Item.FindControl("lblDateApproved");

                if (thisChart.ServiceAgreement.EvaluateFacilityService && (currentItem.FacilityLOSCorrect + currentItem.FacilityLOSAdditions + currentItem.FacilityLOSDeletions + currentItem.FacilityLOSRevisions + currentItem.FacilityLOSAbstract) > 0)
                {
                    lblFacilityLOSPassFail.Text = FormatScorecardDetail(currentItem.FacilityLOSAdditions, currentItem.FacilityLOSDeletions, currentItem.FacilityLOSRevisions, currentItem.FacilityLOSAbstract);
                }
                else
                {
                    lblFacilityLOSPassFail.Text = "--";
                }

                if (thisChart.ServiceAgreement.EvaluateFacilityProcedures && (currentItem.FacilityProcCorrect + currentItem.FacilityProcAdditions + currentItem.FacilityProcDeletions + currentItem.FacilityProcRevisions + currentItem.FacilityProcAbstract) > 0)
                {
                    lblFacilityProcPassFail.Text = FormatScorecardDetail(currentItem.FacilityProcAdditions, currentItem.FacilityProcDeletions, currentItem.FacilityProcRevisions, currentItem.FacilityProcAbstract);
                }
                else
                {
                    lblFacilityProcPassFail.Text = "--";
                }
                if ((thisChart.ServiceAgreement.InfusionInjectionMethodID == ServiceAgreement.INFUSION_INJECTION_METHOD_BASE ||
                    thisChart.ServiceAgreement.InfusionInjectionMethodID == ServiceAgreement.INFUSION_INJECTION_METHOD_CHEMOTHERAPY)
                    && (currentItem.InfusionInjectionAttempted + currentItem.InfusionInjectionAbstract + currentItem.InfusionInjectionAdditions + currentItem.InfusionInjectionCorrect + currentItem.InfusionInjectionDeletions + currentItem.InfusionInjectionRevisions) > 0)
                {
                    lblFacilityInfInjPassFail.Text = FormatScorecardDetail(currentItem.InfusionInjectionAdditions, currentItem.InfusionInjectionDeletions, currentItem.InfusionInjectionRevisions, currentItem.InfusionInjectionAbstract);
                }
                else
                {
                    lblFacilityInfInjPassFail.Text = "--";
                }
                if (thisChart.ServiceAgreement.EvaluatePhysicianProcedures && (currentItem.ProfProcCorrect + currentItem.ProfProcAdditions + currentItem.ProfProcDeletions + currentItem.ProfProcRevisions + currentItem.ProfProcAbstract) > 0)
                {
                    lblPhysicianProcPassFail.Text = FormatScorecardDetail(currentItem.ProfProcAdditions, currentItem.ProfProcDeletions, currentItem.ProfProcRevisions, currentItem.ProfProcAbstract);
                }
                else
                {
                    lblPhysicianProcPassFail.Text = "--";
                }
                 
                if (thisChart.ServiceAgreement.EvaluatePhysicianService && (currentItem.PhysicianLOSCorrect + currentItem.PhysicianLOSAdditions + currentItem.PhysicianLOSDeletions + currentItem.PhysicianLOSRevisions + currentItem.PhysicianLOSAbstract) > 0)
                {
                    lblPhysicianLOSPassFail.Text = FormatScorecardDetail(currentItem.PhysicianLOSAdditions, currentItem.PhysicianLOSDeletions, currentItem.PhysicianLOSRevisions, currentItem.PhysicianLOSAbstract);
                }
                else
                {
                    lblPhysicianLOSPassFail.Text = "--";
                }
                if (thisChart.ServiceAgreement.PerformDiagnosisCoding && (currentItem.DxAttempted + currentItem.DxAbstract + currentItem.DxAdditions + currentItem.DxCorrect + currentItem.DxDeletions + currentItem.DxRevisions) > 0)
                {
                    lblDiagnosisPassFail.Text = FormatScorecardDetail(currentItem.DxAdditions, currentItem.DxDeletions, currentItem.DxRevisions, currentItem.DxAbstract);
                }
                else
                {
                    lblDiagnosisPassFail.Text = "--";
                }
                if (thisChart.PatientDisposition.PatientDispositionID == PatientDisposition.OBSERVATION && thisChart.ServiceAgreement.EvaluateObservationDepartments
                    && (currentItem.ObsHoursAttempted + currentItem.ObsHoursAbstract + currentItem.ObsHoursAdditions + currentItem.ObsHoursCorrect + currentItem.ObsHoursDeletions + currentItem.ObsHoursRevisions) > 0)
                {
                    lblObsHoursPassFail.Text = FormatScorecardDetail(currentItem.ObsHoursAdditions, currentItem.ObsHoursDeletions, currentItem.ObsHoursRevisions, currentItem.ObsHoursAbstract);
                }
                else
                {
                    lblObsHoursPassFail.Text = "--";
                }

                lblDateApproved.Text = currentItem.ApprovedDate.ToShortDateString();

                ChartAuditCommentsDAO chartAuditCommentsDAO = new ChartAuditCommentsDAO(m_RequestManager);
                ChartAuditComments comments = chartAuditCommentsDAO.Load(currentItem.ChartID);

                string commentSeparator = string.Empty;
                if (comments.AuditorReviewFeedback != String.Empty || comments.SecondLevelAuditorReviewFeedback != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("General", comments.AuditorReviewFeedback, comments.SecondLevelAuditorReviewFeedback);
                    commentSeparator = "; ";
                }
                if (comments.DemographicAuditComment != String.Empty || comments.SecondLevelDemographicAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("Demographics", comments.DemographicAuditComment, comments.SecondLevelDemographicAuditComment);
                    commentSeparator = "; ";
                }
                if (comments.FacilityServiceLevelAuditComment != String.Empty || comments.SecondLevelFacilityServiceLevelAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("Fac Svcs", comments.FacilityServiceLevelAuditComment, comments.SecondLevelFacilityServiceLevelAuditComment);
                    commentSeparator = "; ";
                }
                if (comments.InfusionInjectionAuditComment != String.Empty || comments.SecondLevelInfusionInjectionAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("Inf/Inj", comments.InfusionInjectionAuditComment, comments.SecondLevelInfusionInjectionAuditComment);

                    commentSeparator = "; ";
                }
                if (comments.FacilityProceduresAuditComment != String.Empty || comments.SecondLevelFacilityProceduresAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("Fac Proc", comments.FacilityProceduresAuditComment, comments.SecondLevelFacilityProceduresAuditComment);
                    commentSeparator = "; ";
                }
                if (comments.PhysicianServiceLevelAuditComment != String.Empty || comments.SecondLevelPhysicianServiceLevelAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("Phys E/M", comments.PhysicianServiceLevelAuditComment, comments.SecondLevelPhysicianServiceLevelAuditComment);
                    commentSeparator = "; ";
                }
                if (comments.PhysicianProceduresAuditComment != String.Empty || comments.SecondLevelPhysicianProceduresAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("Phys Proc", comments.PhysicianProceduresAuditComment, comments.SecondLevelPhysicianProceduresAuditComment);
                    commentSeparator = "; ";
                }
                if (comments.DiagnosisCodingAuditComment != String.Empty || comments.SecondLevelDiagnosisCodingAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("Diagnosis:", comments.DiagnosisCodingAuditComment, comments.SecondLevelDiagnosisCodingAuditComment);

                    commentSeparator = "; ";
                }
                if (comments.ObservationAuditorReviewFeedback != String.Empty || comments.SecondLevelObservationAuditorReviewFeedback != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + FormatAuditorComments("Obs", comments.ObservationAuditorReviewFeedback, comments.SecondLevelObservationAuditorReviewFeedback);
                    commentSeparator = "; ";
                }
            }
        }
        private string FormatAuditorComments(string prefix, string firstAuditorComment, string secondAuditorComment)
        {
            string formattedComment = string.Empty;

            if (secondAuditorComment != string.Empty)
            {
                if (firstAuditorComment != string.Empty)
                {
                    formattedComment = prefix + ": (1st Auditor) " + firstAuditorComment + "; (2nd Auditor) " + secondAuditorComment;
                }
                else
                {
                    formattedComment = prefix + ": (2nd Auditor) " + secondAuditorComment;
                }
            }
            else
            {
                if (firstAuditorComment != string.Empty)
                {
                    formattedComment = prefix + ": " + firstAuditorComment;
                }
            }
            return formattedComment;
        }

        protected void grdScorecardAuditorDetails_ItemDataBound(object sender, DataGridItemEventArgs e)
        {
            if (e.Item.ItemIndex >= 0)
            {
                ChartQAScorecardSummary currentItem = (ChartQAScorecardSummary)e.Item.DataItem;
                LinkButton lnkAuditReview = (LinkButton)e.Item.FindControl("lnkAuditReviewCoder");
                lnkAuditReview.Visible = m_ShowAccountLink;
                lnkAuditReview.CommandArgument = currentItem.ChartID.ToString();
                Chart thisChart = new ChartDAO(m_RequestManager).Load(currentItem.ChartID);

                Label lblAuditorNotes = (Label)e.Item.FindControl("lblAuditorNotes");
                Label lblFacilityLOSPassFail = (Label)e.Item.FindControl("lblFacilityLOSPassFail");
                Label lblFacilityInfInjPassFail = (Label)e.Item.FindControl("lblFacilityInfInjPassFail");
                Label lblFacilityProcPassFail = (Label)e.Item.FindControl("lblFacilityProcPassFail");
                Label lblPhysicianLOSPassFail = (Label)e.Item.FindControl("lblPhysicianLOSPassFail");
                Label lblPhysicianProcPassFail = (Label)e.Item.FindControl("lblPhysicianProcPassFail");
                Label lblDiagnosisPassFail = (Label)e.Item.FindControl("lblDiagnosisPassFail");
                Label lblObsHoursPassFail = (Label)e.Item.FindControl("lblObsHoursPassFail");
                Label lblDateApproved = (Label)e.Item.FindControl("lblDateApproved");

                if (thisChart.ServiceAgreement.EvaluateFacilityService && (currentItem.FacilityLOSCorrect + currentItem.FacilityLOSAdditions + currentItem.FacilityLOSDeletions + currentItem.FacilityLOSRevisions + currentItem.FacilityLOSAbstract) > 0)
                {
                    lblFacilityLOSPassFail.Text = FormatScorecardDetail(currentItem.FacilityLOSAdditions, currentItem.FacilityLOSDeletions, currentItem.FacilityLOSRevisions, currentItem.FacilityLOSAbstract);
                }
                else
                {
                    lblFacilityLOSPassFail.Text = "--";
                }

                if (thisChart.ServiceAgreement.EvaluateFacilityProcedures && (currentItem.FacilityProcCorrect + currentItem.FacilityProcAdditions + currentItem.FacilityProcDeletions + currentItem.FacilityProcRevisions + currentItem.FacilityProcAbstract) > 0)
                {
                    lblFacilityProcPassFail.Text = FormatScorecardDetail(currentItem.FacilityProcAdditions, currentItem.FacilityProcDeletions, currentItem.FacilityProcRevisions, currentItem.FacilityProcAbstract);
                }
                else
                {
                    lblFacilityProcPassFail.Text = "--";
                }
                if ((thisChart.ServiceAgreement.InfusionInjectionMethodID == ServiceAgreement.INFUSION_INJECTION_METHOD_BASE ||
                    thisChart.ServiceAgreement.InfusionInjectionMethodID == ServiceAgreement.INFUSION_INJECTION_METHOD_CHEMOTHERAPY)
                    && (currentItem.InfusionInjectionAttempted + currentItem.InfusionInjectionAbstract + currentItem.InfusionInjectionAdditions + currentItem.InfusionInjectionCorrect + currentItem.InfusionInjectionDeletions + currentItem.InfusionInjectionRevisions) > 0)

                {
                    lblFacilityInfInjPassFail.Text = FormatScorecardDetail(currentItem.InfusionInjectionAdditions, currentItem.InfusionInjectionDeletions, currentItem.InfusionInjectionRevisions, currentItem.InfusionInjectionAbstract);
                }
                else
                {
                    lblFacilityInfInjPassFail.Text = "--";
                }
                if (thisChart.ServiceAgreement.EvaluatePhysicianProcedures && (currentItem.ProfProcCorrect + currentItem.ProfProcAdditions + currentItem.ProfProcDeletions + currentItem.ProfProcRevisions + currentItem.ProfProcAbstract) > 0)
                {
                    lblPhysicianProcPassFail.Text = FormatScorecardDetail(currentItem.ProfProcAdditions, currentItem.ProfProcDeletions, currentItem.ProfProcRevisions, currentItem.ProfProcAbstract);
                }
                else
                {
                    lblPhysicianProcPassFail.Text = "--";
                }

                if (thisChart.ServiceAgreement.EvaluatePhysicianService && (currentItem.PhysicianLOSCorrect + currentItem.PhysicianLOSAdditions + currentItem.PhysicianLOSDeletions + currentItem.PhysicianLOSRevisions + currentItem.PhysicianLOSAbstract) > 0)
                {
                    lblPhysicianLOSPassFail.Text = FormatScorecardDetail(currentItem.PhysicianLOSAdditions, currentItem.PhysicianLOSDeletions, currentItem.PhysicianLOSRevisions, currentItem.PhysicianLOSAbstract);
                }
                else
                {
                    lblPhysicianLOSPassFail.Text = "--";
                }
                if (thisChart.ServiceAgreement.PerformDiagnosisCoding && (currentItem.DxAttempted + currentItem.DxAbstract + currentItem.DxAdditions + currentItem.DxCorrect + currentItem.DxDeletions + currentItem.DxRevisions) > 0)
                {
                    lblDiagnosisPassFail.Text = FormatScorecardDetail(currentItem.DxAdditions, currentItem.DxDeletions, currentItem.DxRevisions, currentItem.DxAbstract);
                }
                else
                {
                    lblDiagnosisPassFail.Text = "--";
                }
                if (thisChart.PatientDisposition.PatientDispositionID == PatientDisposition.OBSERVATION && thisChart.ServiceAgreement.EvaluateObservationDepartments
                    && (currentItem.ObsHoursAttempted + currentItem.ObsHoursAbstract + currentItem.ObsHoursAdditions + currentItem.ObsHoursCorrect + currentItem.ObsHoursDeletions + currentItem.ObsHoursRevisions) > 0)

                {
                    lblObsHoursPassFail.Text = FormatScorecardDetail(currentItem.ObsHoursAdditions, currentItem.ObsHoursDeletions, currentItem.ObsHoursRevisions, currentItem.ObsHoursAbstract);
                }
                else
                {
                    lblObsHoursPassFail.Text = "--";
                }

                if (thisChart.SecondLevelQAApprovedDateTime != null)
                {
                    lblDateApproved.Text = Convert.ToDateTime(thisChart.SecondLevelQAApprovedDateTime).ToShortDateString();
                }
                else
                {
                    lblDateApproved.Text = string.Empty;
                }

                ChartAuditCommentsDAO chartAuditCommentsDAO = new ChartAuditCommentsDAO(m_RequestManager);
                ChartAuditComments comments = chartAuditCommentsDAO.Load(currentItem.ChartID);

                string commentSeparator = string.Empty;
                if (comments.AuditorReviewFeedback != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "General: " + comments.AuditorReviewFeedback;
                    commentSeparator = "; ";
                }
                if (comments.SecondLevelDemographicAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "Demographics: " + comments.SecondLevelDemographicAuditComment;
                    commentSeparator = "; ";
                }
                if (comments.SecondLevelFacilityServiceLevelAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "Fac Svcs: " + comments.SecondLevelFacilityServiceLevelAuditComment;
                    commentSeparator = "; ";
                }
                if (comments.SecondLevelInfusionInjectionAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "Inf/Inj: " + comments.SecondLevelInfusionInjectionAuditComment;
                    commentSeparator = "; ";
                }
                if (comments.SecondLevelFacilityProceduresAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "Fac Proc: " + comments.SecondLevelFacilityProceduresAuditComment;
                    commentSeparator = "; ";
                }
                if (comments.SecondLevelPhysicianServiceLevelAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "Phys E/M: " + comments.SecondLevelPhysicianServiceLevelAuditComment;
                    commentSeparator = "; ";
                }
                if (comments.SecondLevelPhysicianProceduresAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "Phys Proc: " + comments.SecondLevelPhysicianProceduresAuditComment;
                    commentSeparator = "; ";
                }
                if (comments.SecondLevelDiagnosisCodingAuditComment != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "Diagnosis: " + comments.SecondLevelDiagnosisCodingAuditComment;
                    commentSeparator = "; ";
                }
                if (comments.SecondLevelObservationAuditorReviewFeedback != String.Empty)
                {
                    lblAuditorNotes.Text += commentSeparator + "Obs: " + comments.SecondLevelObservationAuditorReviewFeedback;
                    commentSeparator = "; ";
                }
            }
        }
        private string FormatScorecardDetail(int? additionCount, int? deletionCount, int? revisionCount, int? abstractCount)
        {
            string text = string.Empty;
            string separator = string.Empty;

            if (Convert.ToInt32(additionCount) > 0)
            {
                text += separator + "<mark>" + Convert.ToInt32(additionCount).ToString() + " Addition </mark>";
                separator = "</br>";
            }
            if (Convert.ToInt32(deletionCount) > 0)
            {
                text += separator + "<mark>" + Convert.ToInt32(deletionCount).ToString() + " Deletion </mark>";
                separator = "</br>";
            }
            if (Convert.ToInt32(revisionCount) > 0)
            {
                text += separator + "<mark>" + Convert.ToInt32(revisionCount).ToString() + " Revision</mark>";
                separator = "</br>";
            }

            if (text == string.Empty)
            {
                text = "Correct";
                separator = "</br>";
            }
            if (Convert.ToInt32(abstractCount) > 0)
            {
                text += separator + "<mark>" + Convert.ToInt32(abstractCount).ToString() + " Abstract</mark>";
            }
            return text;
        }

        private String RemoveHTMLElementsFromDescription(String description)
        {
            String workingDescription = description;

            workingDescription = RemoveSingleHTMLElement(workingDescription, "<BR>");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "</BR>");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "<B>");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "</B>");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "<br>");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "<br/>");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "<b>");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "</br>");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "nbsp;");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "nbsp");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "NBSP");
            workingDescription = RemoveSingleHTMLElement(workingDescription, "<BR/>");

            return workingDescription;
        }

        private String RemoveSingleHTMLElement(String description, String element)
        {
            String workingText = description;
            String blankSpace = " ";
            workingText = workingText.Replace(element, blankSpace);
            if (workingText.EndsWith(blankSpace))
            {
                workingText = workingText.Trim() + blankSpace;
            }
            return workingText;
        }

        public void grdResults_ItemCommand(object source, System.Web.UI.WebControls.DataGridCommandEventArgs e)
        {
            String chartID = e.CommandArgument.ToString();
            m_RequestManager.SessionManager.SelectedChartID = chartID;
            string redirect = "<script>window.open('./ChartAuditReviewView.aspx','QAChartAUditReview');</script>";
            Page.Response.Write(redirect);
        }
        public void grdScorecardResults_ItemCommand(object source, System.Web.UI.WebControls.DataGridCommandEventArgs e)
        {
	        m_RequestManager.SessionManager.SelectedChartID = e.CommandArgument.ToString();
	        var applicationFeatureService = new ApplicationFeatureService(new ApplicationFeatureDataService());
	        var allowPostBillAuditRefactorFeature = applicationFeatureService.AllowFeature(
		        ApplicationFeatureTypeCode.PostBillAuditRefactor, 
				ApplicationFeatureDomainObjectTypeCode.User,
		        m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID);
	        var redirectPage = allowPostBillAuditRefactorFeature ? "ChartAuditReview" : "ChartScorecardAuditReview";
	        var redirect = $"<script>window.open('./{redirectPage}.aspx','QAChartAuditReview');</script>";
            Page.Response.Write(redirect);
        }
        protected void grdResultsAuditor_ItemDataBound(object sender, DataGridItemEventArgs e)
        {
            if (e.Item.ItemIndex >= 0)
            {
                ChartQAFeedbackItem currentItem = (ChartQAFeedbackItem)e.Item.DataItem;
                LinkButton lnkAuditReview = (LinkButton)e.Item.FindControl("lnkAuditReviewAuditor");
                lnkAuditReview.Visible = m_ShowAccountLink;
                lnkAuditReview.CommandArgument = currentItem.ChartID.ToString();

                Label lblFacilityLOSPassFail = (Label)e.Item.FindControl("lblFacilityLOSPassFailAuditor");
                Label lblFacilityLOSComment = (Label)e.Item.FindControl("lblFacilityLOSCommentAuditor");
                if (lblFacilityLOSPassFail.Text.ToUpper() == "FAIL")
                {
                    lblFacilityLOSPassFail.BackColor = Color.Yellow;
                    lblFacilityLOSComment.BackColor = Color.Yellow;
                }

                Label lblFacilityInfInjPassFail = (Label)e.Item.FindControl("lblFacilityInfInjPassFailAuditor");
                Label lblFacilityInfInjComment = (Label)e.Item.FindControl("lblFacilityInfInjCommentAuditor");
                if (lblFacilityInfInjPassFail.Text.ToUpper() == "FAIL")
                {
                    lblFacilityInfInjPassFail.BackColor = Color.Yellow;
                    lblFacilityInfInjComment.BackColor = Color.Yellow;
                }

                Label lblFacilityProcPassFail = (Label)e.Item.FindControl("lblFacilityProcPassFailAuditor");
                Label lblFacilityProcComment = (Label)e.Item.FindControl("lblFacilityProcCommentAuditor");
                if (lblFacilityProcPassFail.Text.ToUpper() == "FAIL")
                {
                    lblFacilityProcPassFail.BackColor = Color.Yellow;
                    lblFacilityProcComment.BackColor = Color.Yellow;
                }
                Label lblPhysicianLOSPassFail = (Label)e.Item.FindControl("lblPhysicianLOSPassFailAuditor");
                Label lblPhysicianLOSComment = (Label)e.Item.FindControl("lblPhysicianLOSCommentAuditor");
                if (lblPhysicianLOSPassFail.Text.ToUpper() == "FAIL")
                {
                    lblPhysicianLOSPassFail.BackColor = Color.Yellow;
                    lblPhysicianLOSComment.BackColor = Color.Yellow;
                }
                Label lblPhysicianProcPassFail = (Label)e.Item.FindControl("lblPhysicianProcPassFailAuditor");
                Label lblPhysicianProcComment = (Label)e.Item.FindControl("lblPhysicianProcCommentAuditor");
                if (lblPhysicianProcPassFail.Text.ToUpper() == "FAIL")
                {
                    lblPhysicianProcPassFail.BackColor = Color.Yellow;
                    lblPhysicianProcComment.BackColor = Color.Yellow;
                }
                Label lblDiagnosisPassFail = (Label)e.Item.FindControl("lblDiagnosisPassFailAuditor");
                Label lblDiagnosisComment = (Label)e.Item.FindControl("lblDiagnosisCommentAuditor");
                if (lblDiagnosisPassFail.Text.ToUpper() == "FAIL")
                {
                    lblDiagnosisPassFail.BackColor = Color.Yellow;
                    lblDiagnosisComment.BackColor = Color.Yellow;
                }
                Label lblDemographicsPassFail = (Label)e.Item.FindControl("lblDemographicsPassFailAuditor");
                Label lblDemographicsComment = (Label)e.Item.FindControl("lblDemographicsCommentAuditor");
                if (lblDemographicsPassFail.Text.ToUpper() == "FAIL")
                {
                    lblDemographicsPassFail.BackColor = Color.Yellow;
                    lblDemographicsComment.BackColor = Color.Yellow;
                }
                Label lblObsHoursPassFail = (Label)e.Item.FindControl("lblObsHoursPassFailAuditor");
                Label lblObsHoursComment = (Label)e.Item.FindControl("lblObsHoursCommentAuditor");
                if (lblObsHoursPassFail.Text.ToUpper() == "FAIL")
                {
                    lblObsHoursPassFail.BackColor = Color.Yellow;
                    lblObsHoursComment.BackColor = Color.Yellow;
                }
                Label lblObsInfInjPassFail = (Label)e.Item.FindControl("lblObsInfInjPassFailAuditor");
                Label lblObsInfInjComment = (Label)e.Item.FindControl("lblObsInfInjCommentAuditor");
                if (lblObsHoursPassFail.Text.ToUpper() == "FAIL")
                {
                    lblObsInfInjPassFail.BackColor = Color.Yellow;
                    lblObsInfInjComment.BackColor = Color.Yellow;
                }
                Label lblObsProcPassFail = (Label)e.Item.FindControl("lblObsProcPassFailAuditor");
                Label lblObsProcComment = (Label)e.Item.FindControl("lblObsProcCommentAuditor");
                if (lblObsHoursPassFail.Text.ToUpper() == "FAIL")
                {
                    lblObsProcPassFail.BackColor = Color.Yellow;
                    lblObsProcComment.BackColor = Color.Yellow;
                }
                ListBox lstChartAuditAction = (ListBox)e.Item.FindControl("lstChartAuditActionsAuditor");
                lstChartAuditAction.BorderStyle = BorderStyle.None;

                Chart thisChart = m_ChartDAO.Load(currentItem.ChartID);

                ArrayList fs = thisChart.FacilityServiceEvaluation.PerformSecondLevelAuditComparison();
                if (fs.Count > 0)
                {
                    foreach (Object obj in fs)
                    {
                        String fsDescription = string.Empty;
                        if (obj.GetType().Name == "FacilityServiceEvaluationListItem")
                        {
                            FacilityServiceEvaluationListItem fsItem = (FacilityServiceEvaluationListItem)obj;
                            lstChartAuditAction.Items.Add("Fac Services-" + fsItem.ComparisonResult + ": " + fsDescription);
                        }
                        else
                        {
                            Chart_ChartLOSHistoryDiff fsItem = (Chart_ChartLOSHistoryDiff)obj;
                            lstChartAuditAction.Items.Add("Fac Services-" + fsItem.comparisonResult + ": " + fsDescription);
                        }
                    }
                }

                FacilityServiceEvaluationListDAO evalDAO = new FacilityServiceEvaluationListDAO(m_RequestManager);
                ArrayList facilityLOSChanges = evalDAO.GetSecondLevelFacilityLOSChange(thisChart.ChartID);
                if (facilityLOSChanges.Count > 0)
                {
                    const String baseDescription = "Based on 2nd auditor action, ";
                    String losChangeDescription = string.Empty;

                    if (!facilityLOSChanges[1].ToString().Equals(facilityLOSChanges[3].ToString()))
                    {
                        losChangeDescription += baseDescription + "Facility LOS changed from '";
                        losChangeDescription += facilityLOSChanges[3].ToString() + "' to '";
                        losChangeDescription += facilityLOSChanges[1].ToString() + "'";
                        lstChartAuditAction.Items.Add(losChangeDescription);
                    }
                }

                ArrayList inf = thisChart.ChartInfusionEvaluation.PerformSecondLevelAuditComparison(1);
                if (inf.Count > 0)
                {
                    foreach (ChartInfusionResultListItem obj in inf)
                    {
                        lstChartAuditAction.Items.Add("Inf/Inj-" + obj.ComparisonResult + ": " + obj.ProcedureDescription + ", " + obj.Modifiers);
                    }
                }

                ArrayList fp = thisChart.FacilityProcedureEvaluation.PerformSecondLevelAuditComparison(1);
                if (fp.Count > 0)
                {
                    foreach (FacilityProcedureEvaluationListItem obj in fp)
                    {
                        lstChartAuditAction.Items.Add("Fac Proc-" + obj.ComparisonResult + ": " + obj.ProcedureDescription);
                    }
                }

                ArrayList pp = thisChart.PhysicianProcedureEvaluation.PerformSecondLevelAuditComparison();
                if (pp.Count > 0)
                {
                    foreach (PhysicianProcedureEvaluationListItem obj in pp)
                    {
                        lstChartAuditAction.Items.Add("Phys Proc-" + obj.ComparisonResult + ": " + obj.ProcedureDescription);
                    }
                }

                ArrayList pe = thisChart.PhysicianEvaluationRating.PerformSecondLevelAuditComparison();
                if (pe.Count > 0)
                {
                    //foreach (PhysicianServiceEvaluationListItem obj in pe)
                    //{
                    //    String objDesc = obj.ServiceDescription;
                    //    objDesc = RemoveHTMLElementsFromDescription(objDesc);
                    //    if (objDesc.Length > 60)
                    //    {
                    //        objDesc = objDesc.Substring(0, 60) + "...";
                    //    }
                    //    lstChartAuditAction.Items.Add("Phys E&M-" + obj.ComparisonResult + ": " + objDesc);
                    //}

                    foreach (Object obj in pe)
                    {
                        if (obj.GetType().Name == "PhysicianServiceEvaluationListItem")
                        {
                            PhysicianServiceEvaluationListItem compareItem = (PhysicianServiceEvaluationListItem)obj;
                            if (compareItem.ExcludeFromCoderQAReport == false)
                            {
                                String objDesc = compareItem.ServiceDescription;
                                objDesc = RemoveHTMLElementsFromDescription(objDesc);
                                if (objDesc.Length > 60)
                                {
                                    objDesc = compareItem.ServiceDescription.Substring(0, 60) + "...";
                                }
                                lstChartAuditAction.Items.Add("Phys E&M-" + compareItem.ComparisonResult + ": " + objDesc);
                            }
                        }
                        else
                        {
                            Chart_ChartLOSHistoryDiff compareItem = (Chart_ChartLOSHistoryDiff)obj;
                            if (compareItem.ExcludeFromCoderQAReport == false)
                            {
                                String objDesc = compareItem.description;
                                objDesc = RemoveHTMLElementsFromDescription(objDesc);
                                lstChartAuditAction.Items.Add("Phys E&M-" + objDesc);
                            }
                        }
                    }
                }

                PhysicianServiceEvaluationListDAO physicianEvalDAO = new PhysicianServiceEvaluationListDAO(m_RequestManager);
                ArrayList physicianLOSChanges = physicianEvalDAO.GetSecondLevelPhysicianLOSChange(thisChart.ChartID);

                if (physicianLOSChanges.Count > 0)
                {
                    String losChangeDescription = "Based on 2nd auditor action, Physician LOS changed from '";
                    losChangeDescription += physicianLOSChanges[3].ToString() + "' to '";
                    losChangeDescription += physicianLOSChanges[1].ToString() + "'";
                    lstChartAuditAction.Items.Add(losChangeDescription);
                }

                if (thisChart.ServiceAgreement.PerformDiagnosisCoding == true)
                {
                    if (thisChart.ServiceAgreement.DiagnosisCodingICD10EffectiveDate <= thisChart.TimeOfService)
                    {
                        ArrayList dx = thisChart.DiagnosisCodingEvaluation.PerformSecondLevelAuditComparisonICD10();
                        if (dx.Count > 0)
                        {
                            foreach (ChartDiagnosisCodeICD10 obj in dx)
                            {
                                lstChartAuditAction.Items.Add("Diagnosis-" + obj.ComparisonResult + ": " + obj.ICD10Description);
                            }
                        }
                    }
                    else
                    {
                        ArrayList dx = thisChart.DiagnosisCodingEvaluation.PerformSecondLevelAuditComparison();
                        if (dx.Count > 0)
                        {
                            foreach (ChartDiagnosisCodeListItem obj in dx)
                            {
                                lstChartAuditAction.Items.Add("Diagnosis-" + obj.ComparisonResult + ": " + obj.Description);
                            }
                        }
                    }
                }

                ChartDemographicHistoryDAO cdhDAO = new ChartDemographicHistoryDAO(m_RequestManager);
                m_ChartDemographicChanges = cdhDAO.GetDemographicSecondLevelAuditChanges(thisChart.ChartID);

                List<ChartDemographicComparison> demographicsComparison;
                bool demoComp = ChartDemographicComparison.PerformComparison(thisChart, m_ChartDemographicChanges, out demographicsComparison);
                if (demographicsComparison.Count > 0)
                {
                    foreach (ChartDemographicComparison obj in demographicsComparison)
                    {
                        lstChartAuditAction.Items.Add("Demographics-" + obj.ComparisonResult);
                    }
                }
            }
        }

        protected void btnMarkAsReviewed_Click(object sender, System.EventArgs e)
        {
            //popupQAFeedback.Hide();
            if (m_RequestManager.SessionManager.SignedOnUserProfileID == m_RequestManager.SessionManager.SignedOnUserProfile.UserProfileID.ToString())
            {
                UserProfileDAO userDAO = new UserProfileDAO(m_RequestManager);
                m_RequestManager.SessionManager.SignedOnUserProfile.LastReviewedQAFeedback = DateTime.Now;
                userDAO.Save(m_RequestManager.SessionManager.SignedOnUserProfile);
            }
            m_ShowAccountLink = true;
            btnMarkAsReviewed.Visible = false;
            LoadQAReviewWithDateRange();
        }

        protected void btnRefresh_Click(object sender, System.EventArgs e)
        {
            LoadQAReviewWithDateRange();
        }

        protected void btnCancel_Click(object sender, System.EventArgs e)
        {
            m_RequestManager.SessionManager.SelectedChartID = String.Empty;
            divDateRange.Visible = false;

            if (this.Parent.Page.Title.ToUpper() == "NEWS")
            {
                popupQAFeedback.Hide();
            }
            else
            {
                Response.Redirect("News.aspx", false);
            }
            
        }
    }
}
