SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAuditDemographicVersionItem]
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditDemographicVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@AdmissionDateTime datetime = NULL
	,@ArrivalDateTime datetime = NULL
	,@MedicalRecordNum varchar(20) = NULL
	,@PatientDispositionMapId int = NULL
	,@PhysicianId int = NULL
	,@ServiceAgreementArrivalModeId int = NULL
	,@ServiceAgreementTriageAcuityId int = NULL
	,@TimeToRoom datetime = NULL
	,@Gender varchar(1) = NULL
	,@ResidentParticipatedInCare bit = NULL
	,@FinancialClassCd varchar(10) = NULL
	,@PatientDob datetime = NULL
	,@NursePractitionerId int = NULL
	,@ProviderEvalPerformedByInd bit = NULL
	,@TimeOfService datetime = NULL
	,@PatientDispositionId int = NULL
	,@FacilityAdminChartId varchar(20) = NULL
	,@TimeOfDis datetime = NULL
	,@ConditionOfAccidentId int = NULL
	,@ClinicId varchar(10) = NULL
	,@AttestationSignedByAttending bit = NULL
	,@ScribeId int = NULL
	,@LastEncounterDate datetime = NULL
	,@LastMenstrualPeriod datetime = NULL
	,@ResidentId int = NULL
	,@PatientAge int = NULL
	,@TimeOfPhysEval datetime = NULL
	,@TimeOfTriage datetime = NULL
	,@MedicalExaminerNotified bit = NULL
	,@OrganDonation bit = NULL
	,@SeenInEdWithin48HoursOfOr bit = NULL
	,@PhysicianServiceGuidelineId int = NULL
	,@PhysicianServiceSpecialtyTemplateId int = NULL
	,@UseTimeBasedChargeCapture bit = NULL
	,@TimeBasedPhysicianLos int = NULL
	,@UsePreventativeMedicineChargeCapture bit = NULL
	,@PreventativeMedicinePhysicianProcId int = NULL
	,@NoLcdServices bit = NULL
	,@PatientDispositionDestinationId int = NULL
	,@ChartAuditDemographicVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditDemographicVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditDemographicVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[AdmissionDateTime]
	,[ArrivalDateTime]
	,[MedicalRecordNum]
	,[PatientDispositionMapId]
	,[PhysicianId]
	,[ServiceAgreementArrivalModeId]
	,[ServiceAgreementTriageAcuityId]
	,[TimeToRoom]
	,[Gender]
	,[ResidentParticipatedInCare]
	,[FinancialClassCd]
	,[PatientDob]
	,[NursePractitionerId]
	,[ProviderEvalPerformedByInd]
	,[TimeOfService]
	,[PatientDispositionId]
	,[FacilityAdminChartId]
	,[TimeOfDis]
	,[ConditionOfAccidentId]
	,[ClinicId]
	,[AttestationSignedByAttending]
	,[ScribeId]
	,[LastEncounterDate]
	,[LastMenstrualPeriod]
	,[ResidentId]
	,[PatientAge]
	,[TimeOfPhysEval]
	,[TimeOfTriage]
	,[MedicalExaminerNotified]
	,[OrganDonation]
	,[SeenInEdWithin48HoursOfOr]
	,[PhysicianServiceGuidelineId]
	,[PhysicianServiceSpecialtyTemplateId]
	,[UseTimeBasedChargeCapture]
	,[TimeBasedPhysicianLos]
	,[UsePreventativeMedicineChargeCapture]
	,[PreventativeMedicinePhysicianProcId]
	,[NoLcdServices]
	,[PatientDispositionDestinationId]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditDemographicVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@AdmissionDateTime
	,@ArrivalDateTime
	,@MedicalRecordNum
	,@PatientDispositionMapId
	,@PhysicianId
	,@ServiceAgreementArrivalModeId
	,@ServiceAgreementTriageAcuityId
	,@TimeToRoom
	,@Gender
	,@ResidentParticipatedInCare
	,@FinancialClassCd
	,@PatientDob
	,@NursePractitionerId
	,@ProviderEvalPerformedByInd
	,@TimeOfService
	,@PatientDispositionId
	,@FacilityAdminChartId
	,@TimeOfDis
	,@ConditionOfAccidentId
	,@ClinicId
	,@AttestationSignedByAttending
	,@ScribeId
	,@LastEncounterDate
	,@LastMenstrualPeriod
	,@ResidentId
	,@PatientAge
	,@TimeOfPhysEval
	,@TimeOfTriage
	,@MedicalExaminerNotified
	,@OrganDonation
	,@SeenInEdWithin48HoursOfOr
	,@PhysicianServiceGuidelineId
	,@PhysicianServiceSpecialtyTemplateId
	,@UseTimeBasedChargeCapture
	,@TimeBasedPhysicianLos
	,@UsePreventativeMedicineChargeCapture
	,@PreventativeMedicinePhysicianProcId
	,@NoLcdServices
	,@PatientDispositionDestinationId 
)

SET @ChartAuditDemographicVersionItemId = @@IDENTITY

GO
