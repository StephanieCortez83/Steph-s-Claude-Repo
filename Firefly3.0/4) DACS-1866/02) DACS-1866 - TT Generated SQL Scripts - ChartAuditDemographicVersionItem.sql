---------------------------------------------------------------------------------
-- 02) DACS-1866 - TT Generated SQL Scripts - ChartAuditDemographicVersionItem.sql
---------------------------------------------------------------------------------
USE [RevCycleDB]
GO
 
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
/*
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditDemographicVersionItem', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditDemographicVersionItem.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditDemographicVersionItem
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditDemographicVersionItem]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditDemographicVersionItem].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditDemographicVersionItem]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditDemographicVersionItemByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditDemographicVersionItemByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditDemographicVersionItemByChartAuditVersionId]
END
GO
*/
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditDemographicVersionItem', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.InsertChartAuditDemographicVersionItem
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

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId
	 @ChartAuditDemographicVersionItemId int
	,@ChartAuditVersionId int
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
AS

UPDATE [dbo].[ChartAuditDemographicVersionItem] SET
	 [ChartAuditVersionId] = @ChartAuditVersionId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartAuditActionTypeCode] = @ChartAuditActionTypeCode
	,[ActionDescription] = @ActionDescription
	,[PrevChartAuditDemographicVersionItemId] = @PrevChartAuditDemographicVersionItemId
	,[IsPreviousVersionCorrect] = @IsPreviousVersionCorrect
	,[ExcludeFromQA] = @ExcludeFromQA
	,[ExcludeFromQAReasonID] = @ExcludeFromQAReasonID
	,[ChartId] = @ChartId
	,[AdmissionDateTime] = @AdmissionDateTime
	,[ArrivalDateTime] = @ArrivalDateTime
	,[MedicalRecordNum] = @MedicalRecordNum
	,[PatientDispositionMapId] = @PatientDispositionMapId
	,[PhysicianId] = @PhysicianId
	,[ServiceAgreementArrivalModeId] = @ServiceAgreementArrivalModeId
	,[ServiceAgreementTriageAcuityId] = @ServiceAgreementTriageAcuityId
	,[TimeToRoom] = @TimeToRoom
	,[Gender] = @Gender
	,[ResidentParticipatedInCare] = @ResidentParticipatedInCare
	,[FinancialClassCd] = @FinancialClassCd
	,[PatientDob] = @PatientDob
	,[NursePractitionerId] = @NursePractitionerId
	,[ProviderEvalPerformedByInd] = @ProviderEvalPerformedByInd
	,[TimeOfService] = @TimeOfService
	,[PatientDispositionId] = @PatientDispositionId
	,[FacilityAdminChartId] = @FacilityAdminChartId
	,[TimeOfDis] = @TimeOfDis
	,[ConditionOfAccidentId] = @ConditionOfAccidentId
	,[ClinicId] = @ClinicId
	,[AttestationSignedByAttending] = @AttestationSignedByAttending
	,[ScribeId] = @ScribeId
	,[LastEncounterDate] = @LastEncounterDate
	,[LastMenstrualPeriod] = @LastMenstrualPeriod
	,[ResidentId] = @ResidentId
	,[PatientAge] = @PatientAge
	,[TimeOfPhysEval] = @TimeOfPhysEval
	,[TimeOfTriage] = @TimeOfTriage
	,[MedicalExaminerNotified] = @MedicalExaminerNotified
	,[OrganDonation] = @OrganDonation
	,[SeenInEdWithin48HoursOfOr] = @SeenInEdWithin48HoursOfOr
	,[PhysicianServiceGuidelineId] = @PhysicianServiceGuidelineId
	,[PhysicianServiceSpecialtyTemplateId] = @PhysicianServiceSpecialtyTemplateId
	,[UseTimeBasedChargeCapture] = @UseTimeBasedChargeCapture
	,[TimeBasedPhysicianLos] = @TimeBasedPhysicianLos
	,[UsePreventativeMedicineChargeCapture] = @UsePreventativeMedicineChargeCapture
	,[PreventativeMedicinePhysicianProcId] = @PreventativeMedicinePhysicianProcId
	,[NoLcdServices] = @NoLcdServices
	,[PatientDispositionDestinationId] = @PatientDispositionDestinationId
WHERE
	[ChartAuditDemographicVersionItemId] = @ChartAuditDemographicVersionItemId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId
	@ChartAuditDemographicVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditDemographicVersionItem]
WHERE
	[ChartAuditDemographicVersionItemId] = @ChartAuditDemographicVersionItemId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId]
	@ChartAuditDemographicVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditDemographicVersionItem].[ChartAuditDemographicVersionItemId]
	,[ChartAuditDemographicVersionItem].[ChartAuditVersionId]
	,[ChartAuditDemographicVersionItem].[DateTimeCreated]
	,[ChartAuditDemographicVersionItem].[CreatedByUserProfileId]
	,[ChartAuditDemographicVersionItem].[DateTimeLastUpdated]
	,[ChartAuditDemographicVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditDemographicVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditDemographicVersionItem].[ActionDescription]
	,[ChartAuditDemographicVersionItem].[PrevChartAuditDemographicVersionItemId]
	,[ChartAuditDemographicVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditDemographicVersionItem].[ExcludeFromQA]
	,[ChartAuditDemographicVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditDemographicVersionItem].[ChartId]
	,[ChartAuditDemographicVersionItem].[AdmissionDateTime]
	,[ChartAuditDemographicVersionItem].[ArrivalDateTime]
	,[ChartAuditDemographicVersionItem].[MedicalRecordNum]
	,[ChartAuditDemographicVersionItem].[PatientDispositionMapId]
	,[ChartAuditDemographicVersionItem].[PhysicianId]
	,[ChartAuditDemographicVersionItem].[ServiceAgreementArrivalModeId]
	,[ChartAuditDemographicVersionItem].[ServiceAgreementTriageAcuityId]
	,[ChartAuditDemographicVersionItem].[TimeToRoom]
	,[ChartAuditDemographicVersionItem].[Gender]
	,[ChartAuditDemographicVersionItem].[ResidentParticipatedInCare]
	,[ChartAuditDemographicVersionItem].[FinancialClassCd]
	,[ChartAuditDemographicVersionItem].[PatientDob]
	,[ChartAuditDemographicVersionItem].[NursePractitionerId]
	,[ChartAuditDemographicVersionItem].[ProviderEvalPerformedByInd]
	,[ChartAuditDemographicVersionItem].[TimeOfService]
	,[ChartAuditDemographicVersionItem].[PatientDispositionId]
	,[ChartAuditDemographicVersionItem].[FacilityAdminChartId]
	,[ChartAuditDemographicVersionItem].[TimeOfDis]
	,[ChartAuditDemographicVersionItem].[ConditionOfAccidentId]
	,[ChartAuditDemographicVersionItem].[ClinicId]
	,[ChartAuditDemographicVersionItem].[AttestationSignedByAttending]
	,[ChartAuditDemographicVersionItem].[ScribeId]
	,[ChartAuditDemographicVersionItem].[LastEncounterDate]
	,[ChartAuditDemographicVersionItem].[LastMenstrualPeriod]
	,[ChartAuditDemographicVersionItem].[ResidentId]
	,[ChartAuditDemographicVersionItem].[PatientAge]
	,[ChartAuditDemographicVersionItem].[TimeOfPhysEval]
	,[ChartAuditDemographicVersionItem].[TimeOfTriage]
	,[ChartAuditDemographicVersionItem].[MedicalExaminerNotified]
	,[ChartAuditDemographicVersionItem].[OrganDonation]
	,[ChartAuditDemographicVersionItem].[SeenInEdWithin48HoursOfOr]
	,[ChartAuditDemographicVersionItem].[PhysicianServiceGuidelineId]
	,[ChartAuditDemographicVersionItem].[PhysicianServiceSpecialtyTemplateId]
	,[ChartAuditDemographicVersionItem].[UseTimeBasedChargeCapture]
	,[ChartAuditDemographicVersionItem].[TimeBasedPhysicianLos]
	,[ChartAuditDemographicVersionItem].[UsePreventativeMedicineChargeCapture]
	,[ChartAuditDemographicVersionItem].[PreventativeMedicinePhysicianProcId]
	,[ChartAuditDemographicVersionItem].[NoLcdServices]
	,[ChartAuditDemographicVersionItem].[PatientDispositionDestinationId]
FROM
	[dbo].[ChartAuditDemographicVersionItem]
WHERE
	[ChartAuditDemographicVersionItem].[ChartAuditDemographicVersionItemId] = @ChartAuditDemographicVersionItemId

GO	
		
------------------------------------------------------------------
-- Unscoped Select Sproc
------------------------------------------------------------------
RAISERROR('Creating unscoped select stored procedure:', 0, 1) WITH NOWAIT;	

RAISERROR('...creating [dbo].[SelectChartAuditDemographicVersionItem]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditDemographicVersionItem]
	 @PageIndex int = NULL
    ,@PageSize int = 25
    ,@WhereClause varchar(1000) = NULL
    ,@OrderByClause varchar(250) = NULL
    ,@RecordCount int OUTPUT
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--[ID LIST]------------------------------------------------------

CREATE TABLE #tmp
(
	[IndexId] int IDENTITY (1, 1) NOT NULL,
	[ChartAuditDemographicVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditDemographicVersionItemId) ' +
		   'SELECT [ChartAuditDemographicVersionItemId] ' +
		   'FROM [ChartAuditDemographicVersionItem] ' 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' WHERE (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditDemographicVersionItem].[DateTimeCreated]'

EXEC sp_executesql @sql

--[RANGE]----------------------------------------------------------

SELECT @RecordCount = @@ROWCOUNT

DECLARE @FirstRecord int
DECLARE @LastRecord  int

IF @PageIndex IS NOT NULL
BEGIN
	SET @FirstRecord = (@PageIndex * @PageSize) + 1
	SET @LastRecord  = (@PageIndex + 1) * @PageSize
END
ELSE
BEGIN
	SET @FirstRecord = 1
	SET @LastRecord  = @RecordCount
END

--[DATA]------------------------------------------------------------

SELECT
	 [ChartAuditDemographicVersionItem].[ChartAuditDemographicVersionItemId]
	,[ChartAuditDemographicVersionItem].[ChartAuditVersionId]
	,[ChartAuditDemographicVersionItem].[DateTimeCreated]
	,[ChartAuditDemographicVersionItem].[CreatedByUserProfileId]
	,[ChartAuditDemographicVersionItem].[DateTimeLastUpdated]
	,[ChartAuditDemographicVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditDemographicVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditDemographicVersionItem].[ActionDescription]
	,[ChartAuditDemographicVersionItem].[PrevChartAuditDemographicVersionItemId]
	,[ChartAuditDemographicVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditDemographicVersionItem].[ExcludeFromQA]
	,[ChartAuditDemographicVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditDemographicVersionItem].[ChartId]
	,[ChartAuditDemographicVersionItem].[AdmissionDateTime]
	,[ChartAuditDemographicVersionItem].[ArrivalDateTime]
	,[ChartAuditDemographicVersionItem].[MedicalRecordNum]
	,[ChartAuditDemographicVersionItem].[PatientDispositionMapId]
	,[ChartAuditDemographicVersionItem].[PhysicianId]
	,[ChartAuditDemographicVersionItem].[ServiceAgreementArrivalModeId]
	,[ChartAuditDemographicVersionItem].[ServiceAgreementTriageAcuityId]
	,[ChartAuditDemographicVersionItem].[TimeToRoom]
	,[ChartAuditDemographicVersionItem].[Gender]
	,[ChartAuditDemographicVersionItem].[ResidentParticipatedInCare]
	,[ChartAuditDemographicVersionItem].[FinancialClassCd]
	,[ChartAuditDemographicVersionItem].[PatientDob]
	,[ChartAuditDemographicVersionItem].[NursePractitionerId]
	,[ChartAuditDemographicVersionItem].[ProviderEvalPerformedByInd]
	,[ChartAuditDemographicVersionItem].[TimeOfService]
	,[ChartAuditDemographicVersionItem].[PatientDispositionId]
	,[ChartAuditDemographicVersionItem].[FacilityAdminChartId]
	,[ChartAuditDemographicVersionItem].[TimeOfDis]
	,[ChartAuditDemographicVersionItem].[ConditionOfAccidentId]
	,[ChartAuditDemographicVersionItem].[ClinicId]
	,[ChartAuditDemographicVersionItem].[AttestationSignedByAttending]
	,[ChartAuditDemographicVersionItem].[ScribeId]
	,[ChartAuditDemographicVersionItem].[LastEncounterDate]
	,[ChartAuditDemographicVersionItem].[LastMenstrualPeriod]
	,[ChartAuditDemographicVersionItem].[ResidentId]
	,[ChartAuditDemographicVersionItem].[PatientAge]
	,[ChartAuditDemographicVersionItem].[TimeOfPhysEval]
	,[ChartAuditDemographicVersionItem].[TimeOfTriage]
	,[ChartAuditDemographicVersionItem].[MedicalExaminerNotified]
	,[ChartAuditDemographicVersionItem].[OrganDonation]
	,[ChartAuditDemographicVersionItem].[SeenInEdWithin48HoursOfOr]
	,[ChartAuditDemographicVersionItem].[PhysicianServiceGuidelineId]
	,[ChartAuditDemographicVersionItem].[PhysicianServiceSpecialtyTemplateId]
	,[ChartAuditDemographicVersionItem].[UseTimeBasedChargeCapture]
	,[ChartAuditDemographicVersionItem].[TimeBasedPhysicianLos]
	,[ChartAuditDemographicVersionItem].[UsePreventativeMedicineChargeCapture]
	,[ChartAuditDemographicVersionItem].[PreventativeMedicinePhysicianProcId]
	,[ChartAuditDemographicVersionItem].[NoLcdServices]
	,[ChartAuditDemographicVersionItem].[PatientDispositionDestinationId]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditDemographicVersionItem] 
			ON [ChartAuditDemographicVersionItem].[ChartAuditDemographicVersionItemId] = [tmp].[ChartAuditDemographicVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditDemographicVersionItemByChartAuditVersionId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditDemographicVersionItemByChartAuditVersionId]
	 @ChartAuditVersionId int
	,@PageIndex int = NULL
    ,@PageSize int = 25
    ,@WhereClause varchar(1000) = NULL
    ,@OrderByClause varchar(250) = NULL
    ,@RecordCount int OUTPUT
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--[ID LIST]------------------------------------------------------

CREATE TABLE #tmp
(
	[IndexId] int IDENTITY (1, 1) NOT NULL,
	[ChartAuditDemographicVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditDemographicVersionItemId) ' +
		   'SELECT [ChartAuditDemographicVersionItem].[ChartAuditDemographicVersionItemId] ' +
		   'FROM [ChartAuditDemographicVersionItem] ' +
		   'WHERE [ChartAuditDemographicVersionItem].[ChartAuditVersionId] = ' + CAST(@ChartAuditVersionId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditDemographicVersionItem].[DateTimeCreated] '

EXEC sp_executesql @sql

--[RANGE]----------------------------------------------------------

SELECT @RecordCount = @@ROWCOUNT

DECLARE @FirstRecord int
DECLARE @LastRecord  int

IF @PageIndex IS NOT NULL
BEGIN
	SET @FirstRecord = (@PageIndex * @PageSize) + 1
	SET @LastRecord  = (@PageIndex  + 1) * @PageSize
END
ELSE
BEGIN
	SET @FirstRecord = 1
	SET @LastRecord  = @RecordCount
END

--[DATA]------------------------------------------------------------

SELECT
	 [ChartAuditDemographicVersionItem].[ChartAuditDemographicVersionItemId]
	,[ChartAuditDemographicVersionItem].[ChartAuditVersionId]
	,[ChartAuditDemographicVersionItem].[DateTimeCreated]
	,[ChartAuditDemographicVersionItem].[CreatedByUserProfileId]
	,[ChartAuditDemographicVersionItem].[DateTimeLastUpdated]
	,[ChartAuditDemographicVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditDemographicVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditDemographicVersionItem].[ActionDescription]
	,[ChartAuditDemographicVersionItem].[PrevChartAuditDemographicVersionItemId]
	,[ChartAuditDemographicVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditDemographicVersionItem].[ExcludeFromQA]
	,[ChartAuditDemographicVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditDemographicVersionItem].[ChartId]
	,[ChartAuditDemographicVersionItem].[AdmissionDateTime]
	,[ChartAuditDemographicVersionItem].[ArrivalDateTime]
	,[ChartAuditDemographicVersionItem].[MedicalRecordNum]
	,[ChartAuditDemographicVersionItem].[PatientDispositionMapId]
	,[ChartAuditDemographicVersionItem].[PhysicianId]
	,[ChartAuditDemographicVersionItem].[ServiceAgreementArrivalModeId]
	,[ChartAuditDemographicVersionItem].[ServiceAgreementTriageAcuityId]
	,[ChartAuditDemographicVersionItem].[TimeToRoom]
	,[ChartAuditDemographicVersionItem].[Gender]
	,[ChartAuditDemographicVersionItem].[ResidentParticipatedInCare]
	,[ChartAuditDemographicVersionItem].[FinancialClassCd]
	,[ChartAuditDemographicVersionItem].[PatientDob]
	,[ChartAuditDemographicVersionItem].[NursePractitionerId]
	,[ChartAuditDemographicVersionItem].[ProviderEvalPerformedByInd]
	,[ChartAuditDemographicVersionItem].[TimeOfService]
	,[ChartAuditDemographicVersionItem].[PatientDispositionId]
	,[ChartAuditDemographicVersionItem].[FacilityAdminChartId]
	,[ChartAuditDemographicVersionItem].[TimeOfDis]
	,[ChartAuditDemographicVersionItem].[ConditionOfAccidentId]
	,[ChartAuditDemographicVersionItem].[ClinicId]
	,[ChartAuditDemographicVersionItem].[AttestationSignedByAttending]
	,[ChartAuditDemographicVersionItem].[ScribeId]
	,[ChartAuditDemographicVersionItem].[LastEncounterDate]
	,[ChartAuditDemographicVersionItem].[LastMenstrualPeriod]
	,[ChartAuditDemographicVersionItem].[ResidentId]
	,[ChartAuditDemographicVersionItem].[PatientAge]
	,[ChartAuditDemographicVersionItem].[TimeOfPhysEval]
	,[ChartAuditDemographicVersionItem].[TimeOfTriage]
	,[ChartAuditDemographicVersionItem].[MedicalExaminerNotified]
	,[ChartAuditDemographicVersionItem].[OrganDonation]
	,[ChartAuditDemographicVersionItem].[SeenInEdWithin48HoursOfOr]
	,[ChartAuditDemographicVersionItem].[PhysicianServiceGuidelineId]
	,[ChartAuditDemographicVersionItem].[PhysicianServiceSpecialtyTemplateId]
	,[ChartAuditDemographicVersionItem].[UseTimeBasedChargeCapture]
	,[ChartAuditDemographicVersionItem].[TimeBasedPhysicianLos]
	,[ChartAuditDemographicVersionItem].[UsePreventativeMedicineChargeCapture]
	,[ChartAuditDemographicVersionItem].[PreventativeMedicinePhysicianProcId]
	,[ChartAuditDemographicVersionItem].[NoLcdServices]
	,[ChartAuditDemographicVersionItem].[PatientDispositionDestinationId]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditDemographicVersionItem] 
			ON [ChartAuditDemographicVersionItem].[ChartAuditDemographicVersionItemId] = [tmp].[ChartAuditDemographicVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

