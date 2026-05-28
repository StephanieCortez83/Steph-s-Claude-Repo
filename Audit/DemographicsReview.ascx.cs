using ACS.Core.Extensions;
using CCSBusinessObjects;
using CCSBusinessObjects.AppSystem;
using CCSBusinessObjects.BusinessObjects;
using CCSBusinessObjects.BusinessObjects.Service;
using CCSBusinessObjects.Common;
using CCSBusinessObjects.DAO;
using CCSBusinessObjects.DAO.Common;
using CCSBusinessObjects.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;

namespace CCSWebApp.WebPages.Controls.Audit
{
	public partial class DemographicsReview : BaseAuditControl
	{
		#region Internals
		private FacilityProfessionalDAO _facilityProfessionalDao;
		private PatientDispositionDestinationDAO _patientDispositionDestinationDao;
		private SimplePatientDispositionListDAO _simplePatientDispositionListDao;
		private ServiceAgreementConditionOfAccidentDAO _serviceAgreementConditionOfAccidentDao;
		private PhysicianServiceSpecialtyTemplateDAO _physicianServiceSpecialtyTemplateDao;
		private PatientDispositionMapItemDAO _patientDispositionMapItemDao;
		private ConsultingPhysicianDAO _consultingPhysicianDao;

		private const string TEXT95 = "CMS 1995";
		private const string TEXT97 = "CMS 1997";
		private const string NOT_SET_STRING = AppConstants.NOT_SET;
		private enum GridIndexes
		{
			Element = 0,
			PreviousValue = 1,
			AuditorValue = 2,
			AuditAction = 3,
		}
		#endregion Internals

		#region Properties
		public IChartAuditDemographicVersionItemService ChartAuditDemographicVersionItemService { get; set; }
		public IEnumerable<ChartAuditDemographicVersionItem> ChartAuditDemographicVersionItems { get; set; }
		public FacilityProfessionalDAO FacilityProfessionalDao => _facilityProfessionalDao ?? (_facilityProfessionalDao = new FacilityProfessionalDAO(RequestManager));
		public PatientDispositionDestinationDAO PatientDispositionDestinationDao => _patientDispositionDestinationDao ?? (_patientDispositionDestinationDao = new PatientDispositionDestinationDAO(RequestManager));
		public SimplePatientDispositionListDAO SimplePatientDispositionListDao => _simplePatientDispositionListDao ?? (_simplePatientDispositionListDao = new SimplePatientDispositionListDAO(RequestManager));
		public ServiceAgreementConditionOfAccidentDAO ServiceAgreementConditionOfAccidentDao => _serviceAgreementConditionOfAccidentDao ?? (_serviceAgreementConditionOfAccidentDao = new ServiceAgreementConditionOfAccidentDAO(RequestManager));
		public PhysicianServiceSpecialtyTemplateDAO PhysicianServiceSpecialtyTemplateDao => _physicianServiceSpecialtyTemplateDao ?? (_physicianServiceSpecialtyTemplateDao = new PhysicianServiceSpecialtyTemplateDAO(RequestManager));
		public PatientDispositionMapItemDAO PatientDispositionMapItemDao => _patientDispositionMapItemDao ?? (_patientDispositionMapItemDao = new PatientDispositionMapItemDAO(RequestManager));
		public ConsultingPhysicianDAO ConsultingPhysicianDao => _consultingPhysicianDao ?? (_consultingPhysicianDao = new ConsultingPhysicianDAO(RequestManager));
		#endregion Properties

		public void LoadModel(
			WebRequestManager requestManager,
			Chart chart,
			ChartPostBillAudit chartPostBillAudit)
		{
			RequestManager = requestManager;
			Chart = chart;
			ChartPostBillAudit = chartPostBillAudit;
			ChartAuditVersions = ChartAuditVersionService.GetChartAuditVersionListByChartAuditId(ChartPostBillAudit.Id);
			ChartAuditVersion = ChartAuditVersions.OrderByDescending(x => x.VersionNumber).FirstOrDefault();
			ChartAuditDemographicVersionItems = ChartAuditVersion == null
				? new List<ChartAuditDemographicVersionItem>()
				: ChartAuditDemographicVersionItemService.GetChartAuditDemographicVersionItemListByChartAuditVersionId(ChartAuditVersion.Id);
			ChartAuditSectionTypeCode = ChartAuditSectionTypeCode.Demographics;
		}

		public void ModelToView()
		{
			var auditAction = ChartAuditDemographicVersionItems.Any()
				? ChartAuditDemographicVersionItems.First()
				: null;
			if (auditAction == null)
				return;


			var chartAuditVersionNumber = ChartAuditVersions.FirstOrDefault(x => x.Id == auditAction.ChartAuditVersionId)?.VersionNumber;
			var previousVersionItem = new ChartAuditDemographicVersionItem();
			var currentVersionItem = new ChartAuditDemographicVersionItem();

			switch (chartAuditVersionNumber)
			{
				case 1:
					previousVersionItem = auditAction;
					currentVersionItem = null;
					break;
				case 2:
					previousVersionItem = auditAction.PrevChartAuditDemographicVersionItemId.HasValue
						? ChartAuditDemographicVersionItemService.GetChartAuditDemographicVersionItemById(auditAction.PrevChartAuditDemographicVersionItemId.Value)
						: null;
					currentVersionItem = auditAction;
					break;
			}
			// For demographics, there has to be two version items
			if (previousVersionItem != null && currentVersionItem != null)
			{
				grdChartDemographics.DataSource = GetChartDemographicComparisons(previousVersionItem, currentVersionItem);
				grdChartDemographics.DataBind();
			}

			txtComment.Text = ChartAuditVersionComment?.Comment ?? string.Empty;
		}

		protected void grdChartDemographics_ItemDataBound(object sender, DataGridItemEventArgs e)
		{
			if ((e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem)
			|| !(e.Item.DataItem is ChartAuditVersionDemographicsComparison demographicComparison))
				return;

			if (e.Item.FindControl("lblElement") is Label lblElement)
				lblElement.Text = demographicComparison.FieldName;
			if (e.Item.FindControl("lblPreviousValue") is Label lblPreviousValue)
				lblPreviousValue.Text = demographicComparison.PreviousValue;
			if (e.Item.FindControl("lblAuditorValue") is Label lblAuditorValue)
				lblAuditorValue.Text = demographicComparison.AuditorValue;
			if (e.Item.FindControl("lblAuditActionDescription") is Label lblAuditActionDescription)
				lblAuditActionDescription.Text = demographicComparison.ChartAuditActionTypeCode.GetDisplayDescription();

			e.Item.BackColor = AbstractBackColor;
			hdnAuditChange.Value = bool.TrueString;
		}

		private static ChartAuditActionTypeCode GetAction(string previousValue, string auditorValue)
		{
			if (string.IsNullOrWhiteSpace(previousValue)) 
				return ChartAuditActionTypeCode.Added;
			
			return string.IsNullOrWhiteSpace(auditorValue)
				? ChartAuditActionTypeCode.Deleted 
				: ChartAuditActionTypeCode.AbstractChange;
		}

		private IEnumerable<ChartAuditVersionDemographicsComparison> GetChartDemographicComparisons(ChartAuditDemographicVersionItemBase previousVersionItem, ChartAuditDemographicVersionItemBase currentVersionItem)
		{
			var chartAuditVersionDemographicsComparisons = new List<ChartAuditVersionDemographicsComparison>();

			if (Chart.ServiceAgreement.CollectArrivalMode.Visible
		    && Chart.ServiceAgreement.IncludeArrivalModeAsQaElement
		    && currentVersionItem.ServiceAgreementArrivalModeId != previousVersionItem.ServiceAgreementArrivalModeId)
			{
				var arrivalModeText = NOT_SET_STRING;
				var arrivalModeHistoryText = NOT_SET_STRING;
				if (currentVersionItem.ServiceAgreementArrivalModeId.HasValue)
					arrivalModeText = GetArrivalModeDescriptionFromArrivalModeId((int)currentVersionItem.ServiceAgreementArrivalModeId);
				if (previousVersionItem.ServiceAgreementArrivalModeId.HasValue)
					arrivalModeHistoryText = GetArrivalModeDescriptionFromArrivalModeId((int)previousVersionItem.ServiceAgreementArrivalModeId);
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.ArrivalMode, arrivalModeHistoryText, arrivalModeText));
			}

			if (Chart.ServiceAgreement.CollectAdmissionDate.Visible 
			    && Chart.ServiceAgreement.IncludeDateOfAdmissionAsQaElement
			    && currentVersionItem.AdmissionDateTime != previousVersionItem.AdmissionDateTime)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.AdmitDate, previousVersionItem.AdmissionDateTime.ToStringOrDefault(), currentVersionItem.AdmissionDateTime.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectArrivalDate.Visible 
			&& Chart.ServiceAgreement.IncludeDateOfArrivalAsQaElement
			&& currentVersionItem.ArrivalDateTime != previousVersionItem.ArrivalDateTime)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.ArrivalDate, previousVersionItem.ArrivalDateTime.ToStringOrDefault(), currentVersionItem.ArrivalDateTime.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectFacilityPatientDisposition.Visible 
			&& Chart.ServiceAgreement.IncludeFacilityDispositionAsQaElement)
			{
				if (currentVersionItem.PatientDispositionMapId != previousVersionItem.PatientDispositionMapId)
				{
					var facilityPatientDispositionText = NOT_SET_STRING;
					var facilityPatientDispositionHistoryText = NOT_SET_STRING;
					if (currentVersionItem.PatientDispositionMapId.HasValue 
					&& currentVersionItem.PatientDispositionId.HasValue)
					{
						var patientDispositionMapItem =
							PatientDispositionMapItemDao.Load((int)currentVersionItem.PatientDispositionMapId);
						facilityPatientDispositionText =
							$"{patientDispositionMapItem.Description}({patientDispositionMapItem.FacilityPatientDisposition})";
					}
						
					if (previousVersionItem.PatientDispositionMapId.HasValue 
					&& previousVersionItem.PatientDispositionId.HasValue)
					{
						var patientDispositionMapItem =
							PatientDispositionMapItemDao.Load((int)previousVersionItem.PatientDispositionMapId);
						facilityPatientDispositionHistoryText =
							$"{patientDispositionMapItem.Description}({patientDispositionMapItem.FacilityPatientDisposition})";
					}
					chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.FacilityPatientDisposition, facilityPatientDispositionHistoryText, facilityPatientDispositionText));
				}
				
				if (currentVersionItem.PatientDispositionDestinationId != previousVersionItem.PatientDispositionDestinationId
					&& !(currentVersionItem.PatientDispositionDestinationId == -1 && previousVersionItem.PatientDispositionDestinationId == null))
				{
					var destinations = PatientDispositionDestinationDao.LoadAllPatientDestinationsForServiceAgreement(Chart.ServiceAgreementID);
					if (destinations != null && destinations.Count > 0)
						chartAuditVersionDemographicsComparisons.Add(
							GetChartDemographicComparison(
								ChartDemographicField.PatientDispositionDestinationId, 
								destinations.Find(x => x.PatientDispositionDestinationID == previousVersionItem.PatientDispositionDestinationId)?.Description, 
								destinations.Find(x => x.PatientDispositionDestinationID == currentVersionItem.PatientDispositionDestinationId)?.Description));
					else
						chartAuditVersionDemographicsComparisons.Add(
							GetChartDemographicComparison(
								ChartDemographicField.PatientDispositionDestinationId,
								previousVersionItem.PatientDispositionDestinationId.ToStringOrDefault(),
								currentVersionItem.PatientDispositionDestinationId.ToStringOrDefault()));
				}
			}

			if (Chart.ServiceAgreement.CollectMedicalRecordNumber.Visible 
			&& Chart.ServiceAgreement.IncludeMrnAsQaElement
			&& currentVersionItem.MedicalRecordNum != previousVersionItem.MedicalRecordNum)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.MRN, previousVersionItem.MedicalRecordNum, currentVersionItem.MedicalRecordNum));

			if (Chart.ServiceAgreement.CollectPhysician.Visible 
			&& Chart.ServiceAgreement.IncludeProviderAsQaElement
			&& currentVersionItem.PhysicianId != previousVersionItem.PhysicianId)
			{
				var physicianText = NOT_SET_STRING;
				var physicianHistoryText = NOT_SET_STRING;
				if (currentVersionItem.PhysicianId > 0)
					physicianText = FacilityProfessionalDao.Load((int)currentVersionItem.PhysicianId).Name.LastCommaFirst;
				if (previousVersionItem.PhysicianId > 0)
					physicianHistoryText = FacilityProfessionalDao.Load((int)previousVersionItem.PhysicianId).Name.LastCommaFirst;
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.Physician, physicianHistoryText, physicianText));
			}

			if (Chart.ServiceAgreement.CollectDateToRoom.Visible 
			    && Chart.ServiceAgreement.IncludeTimeToRoomAsQaElement
			    && currentVersionItem.TimeToRoom != previousVersionItem.TimeToRoom)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.TimeToRoom, previousVersionItem.TimeToRoom.ToStringOrDefault(), currentVersionItem.TimeToRoom.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectTriageAcuity.Visible 
			&& Chart.ServiceAgreement.IncludeTriageLevelAsQaElement
			&& currentVersionItem.ServiceAgreementTriageAcuityId != previousVersionItem.ServiceAgreementTriageAcuityId)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.TriageLevel, previousVersionItem.ServiceAgreementTriageAcuityId.ToStringOrDefault(), currentVersionItem.ServiceAgreementTriageAcuityId.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectGender.Visible 
			&& Chart.ServiceAgreement.IncludeGenderAsQaElement
			&& currentVersionItem.Gender != previousVersionItem.Gender)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.Gender, previousVersionItem.Gender, currentVersionItem.Gender));

			if (Chart.ServiceAgreement.CollectResidentParticipatedInCare.Visible 
			&& Chart.ServiceAgreement.IncludeResidentParticipatedInCareAsQAElement
			&& currentVersionItem.ResidentParticipatedInCare != previousVersionItem.ResidentParticipatedInCare)
				chartAuditVersionDemographicsComparisons.Add(
					GetChartDemographicComparison(
						ChartDemographicField.ResidentParticipatedInCare, 
						(previousVersionItem.ResidentParticipatedInCare.HasValue ? (previousVersionItem.ResidentParticipatedInCare.Value ? "Yes" : "No") : "Not Set"), 
						(currentVersionItem.ResidentParticipatedInCare.HasValue ? (currentVersionItem.ResidentParticipatedInCare.Value ? "Yes" : "No") : "Not Set")));

			if (Chart.ServiceAgreement.CollectFinancialClass.Visible 
			&& Chart.ServiceAgreement.IncludeFinancialClassAsQaElement
			&& currentVersionItem.FinancialClassCd != previousVersionItem.FinancialClassCd)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.FinancialClassCode, previousVersionItem.FinancialClassCd, currentVersionItem.FinancialClassCd));

			if (Chart.ServiceAgreement.CollectDateOfBirth.Visible 
			&& Chart.ServiceAgreement.IncludeDateOfBirthAsQaElement 
			&& currentVersionItem.PatientDob != previousVersionItem.PatientDob)
			{
				var dobText = NOT_SET_STRING;
				var dobHistoryText = NOT_SET_STRING;

				if (currentVersionItem.PatientDob.HasValue)
					dobText = currentVersionItem.PatientDob.Value.ToShortDateString();
				if (previousVersionItem.PatientDob.HasValue)
					dobHistoryText = previousVersionItem.PatientDob.Value.ToShortDateString();
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.PatientDateOfBirth, dobHistoryText, dobText));
			}

			if (Chart.ServiceAgreement.CollectNursePractitioner.Visible 
			&& Chart.ServiceAgreement.IncludeNursePractitionerAsQaElement 
			&& currentVersionItem.NursePractitionerId != previousVersionItem.NursePractitionerId)
			{
				var nursePractitionerText = NOT_SET_STRING;
				var nursePractitionerHistoryText = NOT_SET_STRING;
				if (currentVersionItem.NursePractitionerId > 0)
					nursePractitionerText = FacilityProfessionalDao.Load((int)currentVersionItem.NursePractitionerId).Name.LastCommaFirst;
				if (previousVersionItem.NursePractitionerId > 0)
					nursePractitionerHistoryText = FacilityProfessionalDao.Load((int)previousVersionItem.NursePractitionerId).Name.LastCommaFirst;
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.NursePractitioner, nursePractitionerHistoryText, nursePractitionerText));
			}

			if (Chart.ServiceAgreement.CollectDateOfService.Visible 
			&& Chart.ServiceAgreement.IncludeDateOfServiceAsQaElement
			&& currentVersionItem.TimeOfService != previousVersionItem.TimeOfService)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.TimeOfService, previousVersionItem.TimeOfService.ToStringOrDefault(), currentVersionItem.TimeOfService.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectPatientDisposition.Visible 
			&& Chart.ServiceAgreement.IncludeDispositionAsQaElement 
			&& currentVersionItem.PatientDispositionId != previousVersionItem.PatientDispositionId)
			{
				var dispositionText = NOT_SET_STRING;
				var dispositionHistoryText = NOT_SET_STRING;
				if (currentVersionItem.PatientDispositionId > 0)
					dispositionText = SimplePatientDispositionListDao.GetDBValueByID((int)currentVersionItem.PatientDispositionId, "DESCRIPTION", false);
				if (previousVersionItem.PatientDispositionId > 0)
					dispositionHistoryText = SimplePatientDispositionListDao.GetDBValueByID((int)previousVersionItem.PatientDispositionId, "DESCRIPTION", false);
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.PatientDisposition, dispositionHistoryText, dispositionText));
			}
			
			if (Chart.ServiceAgreement.CollectFacilityAdminChartID.Visible 
			&& Chart.ServiceAgreement.IncludeFacilityAdminChartIdAsQaElement
			&& currentVersionItem.FacilityAdminChartId != previousVersionItem.FacilityAdminChartId)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.FacilityAdminChartID, previousVersionItem.FacilityAdminChartId, currentVersionItem.FacilityAdminChartId));

			if (Chart.ServiceAgreement.CollectDateOfDischarge.Visible 
			&& Chart.ServiceAgreement.IncludeTimeOfDischargeAsQaElement
			&& currentVersionItem.TimeOfDis != previousVersionItem.TimeOfDis)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.TimeOfDischarge, previousVersionItem.TimeOfDis.ToStringOrDefault(), currentVersionItem.TimeOfDis.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectConditionOfAccident 
			&& Chart.ServiceAgreement.IncludeConditionOfAccidentAsQaElement 
			&& currentVersionItem.ConditionOfAccidentId != previousVersionItem.ConditionOfAccidentId)
			{
				var conditionOfAccidentText = NOT_SET_STRING;
				var conditionOfAccidentHistoryText = NOT_SET_STRING;
				if (currentVersionItem.ConditionOfAccidentId > 0)
					conditionOfAccidentText = ServiceAgreementConditionOfAccidentDao.Load((int)currentVersionItem.ConditionOfAccidentId).Description;
				if (previousVersionItem.ConditionOfAccidentId > 0)
					conditionOfAccidentHistoryText = ServiceAgreementConditionOfAccidentDao.Load((int)previousVersionItem.ConditionOfAccidentId).Description;
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.ConditionOfAccident, conditionOfAccidentHistoryText, conditionOfAccidentText));
			}
			
			if (Chart.ServiceAgreement.CollectClinic.Visible 
			&& Chart.ServiceAgreement.IncludeClinicAsQaElement
			&& currentVersionItem.ClinicId != previousVersionItem.ClinicId)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.ClinicID, previousVersionItem.ClinicId, currentVersionItem.ClinicId));

			if (Chart.ServiceAgreement.CollectAttestationSignedByAttending.Visible 
			&& Chart.ServiceAgreement.IncludeAttestationAsQaElement
			&& currentVersionItem.AttestationSignedByAttending != previousVersionItem.AttestationSignedByAttending)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.AttestationSignedByAttending, previousVersionItem.AttestationSignedByAttending.ToStringOrDefault(), currentVersionItem.AttestationSignedByAttending.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectScribe 
			&& Chart.ServiceAgreement.IncludeScribeAsQaElement 
			&& currentVersionItem.ScribeId != previousVersionItem.ScribeId)
			{
				var scribeText = NOT_SET_STRING;
				var scribeHistoryText = NOT_SET_STRING;
				if (currentVersionItem.ScribeId.HasValue && currentVersionItem.ScribeId.Value > 0)
					scribeText = FacilityProfessionalDao.Load((int)currentVersionItem.ScribeId).Name.LastCommaFirst;
				if (previousVersionItem.ScribeId.HasValue && previousVersionItem.ScribeId.Value > 0)
					scribeHistoryText = FacilityProfessionalDao.Load((int)previousVersionItem.ScribeId).Name.LastCommaFirst;
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.Scribe, scribeHistoryText, scribeText));
			}

			if (Chart.ServiceAgreement.CollectUCLastEncounterDate.Visible 
			&& Chart.ServiceAgreement.IncludeLastEncounterAsQaElement
			&& currentVersionItem.LastEncounterDate != previousVersionItem.LastEncounterDate)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.LastEncounterDate, previousVersionItem.LastEncounterDate.ToStringOrDefault(), currentVersionItem.LastEncounterDate.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectLastMenstrualPeriod 
			&& Chart.ServiceAgreement.IncludeLMPAsQaElement
			&& currentVersionItem.LastMenstrualPeriod != previousVersionItem.LastMenstrualPeriod)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.LastMenstrualDate, previousVersionItem.LastMenstrualPeriod.ToStringOrDefault(), currentVersionItem.LastMenstrualPeriod.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectResident 
			&& Chart.ServiceAgreement.IncludeResidentAsQaElement 
			&& currentVersionItem.ResidentId != previousVersionItem.ResidentId)
			{
				var residentText = NOT_SET_STRING;
				var residentHistoryText = NOT_SET_STRING;
				if (currentVersionItem.ResidentId.HasValue && currentVersionItem.ResidentId.Value > 0)
					residentText = FacilityProfessionalDao.Load((int)currentVersionItem.ResidentId).Name.LastCommaFirst;
				if (previousVersionItem.ResidentId.HasValue && previousVersionItem.ResidentId.Value > 0)
					residentHistoryText = FacilityProfessionalDao.Load((int)previousVersionItem.ResidentId).Name.LastCommaFirst;
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.ResidentID, residentHistoryText, residentText));
			}

			if (Chart.ServiceAgreement.CollectPatientAge.Visible 
		    && Chart.ServiceAgreement.IncludeAgeAsQaElement
		    && currentVersionItem.PatientAge != previousVersionItem.PatientAge)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.PatientAge, previousVersionItem.PatientAge.ToString(), currentVersionItem.PatientAge.ToString()));

			if (Chart.ServiceAgreement.CollectTimeOfPhysicianEvaluation.Visible 
			&& Chart.ServiceAgreement.IncludeDateOfPhysEvalAsQaElement
			&& currentVersionItem.TimeOfPhysEval != previousVersionItem.TimeOfPhysEval)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.TimeOfPhysEval, previousVersionItem.TimeOfPhysEval.ToStringOrDefault(), currentVersionItem.TimeOfPhysEval.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectTimeOfTriage.Visible 
			&& Chart.ServiceAgreement.IncludeDateOfTriageAsQaElement
			&& currentVersionItem.TimeOfTriage != previousVersionItem.TimeOfTriage)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.TimeOfTriage, previousVersionItem.TimeOfTriage.ToStringOrDefault(), currentVersionItem.TimeOfTriage.ToStringOrDefault()));

			if (Chart.ServiceAgreement.CollectMedicalExaminerNotified.Visible 
			&& Chart.ServiceAgreement.IncludeMedicalExaminerNotifiedAsQaElement
			&& currentVersionItem.MedicalExaminerNotified != previousVersionItem.MedicalExaminerNotified)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.MedicalExaminerNotified, previousVersionItem.MedicalExaminerNotified.ToString(), currentVersionItem.MedicalExaminerNotified.ToString()));

			if (Chart.ServiceAgreement.CollectOrganDonation.Visible 
			&& Chart.ServiceAgreement.IncludeOrganDonationAsQaElement
			&& currentVersionItem.OrganDonation != previousVersionItem.OrganDonation)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.OrganDonation, previousVersionItem.OrganDonation.ToString(), currentVersionItem.OrganDonation.ToString()));

			if (Chart.ServiceAgreement.CollectSeenInEDWithin48HoursOfOR.Visible 
			&& Chart.ServiceAgreement.IncludeSeenInEDAsQaElement
			&& currentVersionItem.SeenInEdWithin48HoursOfOr != previousVersionItem.SeenInEdWithin48HoursOfOr)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.SeenInEDWithin48HoursOfOR, previousVersionItem.SeenInEdWithin48HoursOfOr.ToString(), currentVersionItem.SeenInEdWithin48HoursOfOr.ToString()));

			if (Chart.ServiceAgreement.CollectNursePractitioner.Visible 
			&& Chart.ServiceAgreement.CollectPhysician.Visible 
			&& currentVersionItem.ProviderEvalPerformedByInd != previousVersionItem.ProviderEvalPerformedByInd)
			{
				var providerEvalPerformedByIndText = NOT_SET_STRING;
				var providerEvalPerformedByIndHistoryText = NOT_SET_STRING;
				if (currentVersionItem.ProviderEvalPerformedByInd.HasValue)
					providerEvalPerformedByIndText = currentVersionItem.ProviderEvalPerformedByInd.Value ? "Mid-level" : "Attending";
				if (previousVersionItem.ProviderEvalPerformedByInd.HasValue)
					providerEvalPerformedByIndHistoryText = previousVersionItem.ProviderEvalPerformedByInd.Value ? "Mid-level" : "Attending";
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.ProviderEvalPerformedByInd, providerEvalPerformedByIndHistoryText, providerEvalPerformedByIndText));
			}

			if (Chart.ServiceAgreement.AllowToggleBetween95And97Guidelines 
			&& Chart.PhysicianServiceGuidelineID != currentVersionItem.PhysicianServiceGuidelineId)
			{
				switch (currentVersionItem.PhysicianServiceGuidelineId)
				{
					case 1 when previousVersionItem.PhysicianServiceGuidelineId == 6:
						chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.PhysicianServiceGuideline, TEXT97, TEXT95));
						break;
					case 6 when previousVersionItem.PhysicianServiceGuidelineId == 1:
						chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.PhysicianServiceGuideline, TEXT95, TEXT97));
						break;
				}
			}

			if ((Chart.PhysicianServiceSpecialtyTemplateID != null || currentVersionItem.PhysicianServiceSpecialtyTemplateId != null) 
			&& previousVersionItem.PhysicianServiceSpecialtyTemplateId != currentVersionItem.PhysicianServiceSpecialtyTemplateId)
			{
				var templateText = NOT_SET_STRING;
				var templateHistoryText = NOT_SET_STRING;
				if (currentVersionItem.PhysicianServiceSpecialtyTemplateId != null)
					templateText = PhysicianServiceSpecialtyTemplateDao.Load((int)currentVersionItem.PhysicianServiceSpecialtyTemplateId).TemplateDescription;
				if (previousVersionItem.PhysicianServiceSpecialtyTemplateId != null)
					templateHistoryText = PhysicianServiceSpecialtyTemplateDao.Load((int)previousVersionItem.PhysicianServiceSpecialtyTemplateId).TemplateDescription;
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.PhysicianSpecialtyTemplate, templateHistoryText, templateText));
			}

			if (Chart.ServiceAgreement.AllowPhysicianTimeBasedChargeCapture 
			&& currentVersionItem.UseTimeBasedChargeCapture != previousVersionItem.UseTimeBasedChargeCapture)
				chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.UseTimeBasedChargeCapture, previousVersionItem.UseTimeBasedChargeCapture.ToStringOrDefault(), currentVersionItem.UseTimeBasedChargeCapture.ToStringOrDefault()));

			// TODO: Figure out how to implement the below code given the objects/services available

			//if (Chart.ServiceAgreement.CollectConsultingPhysicians.Visible 
			//    && Chart.ServiceAgreement.IncludeConsultingPhysicianAsQAElement)
			//{
			//	// Check for physicians selected in the chart that do not exit in the history table. (Added by Auditor)
			//	foreach (ConsultingPhysician ccp in cdh.ChartConsultingPhysician)
			//	{
			//		var foundItem = false;

			//		foreach (ConsultingPhysician ccph in cdh.ChartConsultingPhysicianHistory)
			//		{
			//			if (ccp.FacilityProfessionalID == ccph.FacilityProfessionalID)
			//			{
			//				foundItem = true;
			//				break;
			//			}
			//		}

			//		if (!foundItem)
			//		{
			//			chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.ConsultingPhysician, string.Empty, ccp.FacilityProfessional.Name.LastCommaFirstSpaceMiddle));
			//		}
			//	}

			//	// Check for physicians selected in the histpry table that are not longer selected in the chart. (Removed by Auditor)
			//	foreach (ConsultingPhysician ccph in cdh.ChartConsultingPhysicianHistory)
			//	{
			//		var foundItem = false;

			//		foreach (ConsultingPhysician ccp in cdh.ChartConsultingPhysician)
			//		{
			//			if (ccph.FacilityProfessionalID == ccp.FacilityProfessionalID)
			//			{
			//				foundItem = true;
			//				break;
			//			}
			//		}

			//		if (!foundItem)
			//		{
			//			chartAuditVersionDemographicsComparisons.Add(GetChartDemographicComparison(ChartDemographicField.ConsultingPhysician, ccph.FacilityProfessional.Name.LastCommaFirstSpaceMiddle, string.Empty));
			//		}
			//	}
			//}

			return chartAuditVersionDemographicsComparisons;
		}

		private static ChartAuditVersionDemographicsComparison GetChartDemographicComparison(ChartDemographicField demographicField, string previousValue, string auditorValue)
		{
			return new ChartAuditVersionDemographicsComparison()
			{
				FieldName = demographicField.Text(),
				PreviousValue = previousValue,
				AuditorValue = auditorValue,
				ChartAuditActionTypeCode = GetAction(previousValue, auditorValue)
			};
		}

		public void Save()
		{
			if (!IsDataValid()) throw new Exception();

			if (string.IsNullOrWhiteSpace(txtComment.Text)) return;

			SaveComment(txtComment.Text);

		}

		private bool IsDataValid()
		{
			if (string.IsNullOrWhiteSpace(txtComment.Text) && hdnAuditChange.Value.Equals(bool.TrueString))
			{
				RequestManager.ErrorMessages.Add(
					new ErrorMessage(
						ErrorMessageTypeCode.AuditChangesRequireComment,
						ErrorMessageSeverityTypeCode.Severe,
						string.Format(ErrorMessageTypeCode.AuditChangesRequireComment.GetDisplayName(), ChartAuditSectionTypeCode.GetDisplayName())
					)
				);
				return false;
			}

			if (txtComment.Text.Length > 500)
			{
				RequestManager.ErrorMessages.Add(
					new ErrorMessage(
						ErrorMessageTypeCode.ExcessiveCommentLength,
						ErrorMessageSeverityTypeCode.Severe,
						string.Format(ErrorMessageTypeCode.ExcessiveCommentLength.GetDisplayName(), ChartAuditSectionTypeCode.GetDisplayName(), "500", txtComment.Text.Length.ToString())
					)
				);
				return false;
			}

			return true;
		}

		private string GetArrivalModeDescriptionFromArrivalModeId(int arrivalModeId)
		{
			using (var db = new CCSDBDataContext(RequestManager.DB))
			{
				var that =  db.SERVICE_AGREEMENT_ARRIVAL_MODEs.Where(d =>
					d.SERVICE_AGREEMENT_ARRIVAL_MODE_ID == arrivalModeId);

				return that.Any() ? that.First().DESCRIPTION : null;
			}
		}

		public class ChartAuditVersionDemographicsComparison
		{
			#region Properties
			public string FieldName { get; set; }
			public string PreviousValue { get; set; }
			public string AuditorValue { get; set; }
			public ChartAuditActionTypeCode ChartAuditActionTypeCode { get; set; }
			#endregion
		}
	}
}