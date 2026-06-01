USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2745 - Create procedure - [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsBySAIdAndUPId].SQL

---------------------------------------------------------------------
-- 01) DACS-2745 - Create procedure - [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsBySAIdAndUPId].SQL
---------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsBySAIdAndUPId]
        @SaId INT					-- Service Agreement affected by this stored procedure
      , @UPId INT					-- User Profile Id for this actions
AS
BEGIN

	IF @SaId IS NULL OR @SaId <= 0
	BEGIN
		SELECT 'Result' = 'Error: Service Agreement Id is Invalid';
		RETURN;
	END;

	IF @UPId IS NULL OR @UPId <= 0
	BEGIN
		SELECT 'Result' = 'Error: User Profile Id is Invalid';
		RETURN;
	END;


	UPDATE  [dbo].[CHARGE_MASTER]
		SET   [AGE_MINIMUM] = NULL
			, [AGE_MAXIMUM] = NULL
			, [CHANGED_DATE_TIME] = GETDATE()
			, [CHANGING_USER_PROFILE_ID] = @UPId
	WHERE 
		([AGE_MINIMUM] = 0 AND [AGE_MAXIMUM] = 999) 
		OR ([AGE_MINIMUM] = 0 AND [AGE_MAXIMUM] = 11988)
		AND [SERVICE_AGREEMENT_ID] = @SaId;

	UPDATE [dbo].[CHARGE_MASTER]
		SET   [SPECIAL_HANDLING_INSTRUCTIONS] = NULL
			, [CHANGED_DATE_TIME] = GETDATE()
			, [CHANGING_USER_PROFILE_ID] = @UPId
	WHERE 
		[SPECIAL_HANDLING_INSTRUCTIONS] = 'FALSE'
		AND [SERVICE_AGREEMENT_ID] = @SaId;
		
	SELECT 'Result' = 'SUCCESS: Completed';

END
GO





-- End of 01) DACS-2745 - Create procedure - [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsBySAIdAndUPId].SQL
GO

-- Start of 02) DACS-2745 - Create procedure - [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsALLByUPId].SQL

---------------------------------------------------------------------
-- 02) DACS-2745 - Create procedure - [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsALLByUPId].SQL
---------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsALLByUPId]
      @UPId INT					-- User Profile Id for this actions
AS
BEGIN

	IF @UPId IS NULL OR @UPId <= 0
	BEGIN
		SELECT 'Result' = 'Error: User Profile Id is Invalid';
		RETURN;
	END;


	UPDATE  [dbo].[CHARGE_MASTER]
		SET   [AGE_MINIMUM] = NULL
			, [AGE_MAXIMUM] = NULL
			, [CHANGED_DATE_TIME] = GETDATE()
			, [CHANGING_USER_PROFILE_ID] = @UPId
	WHERE 
		([AGE_MINIMUM] = 0 AND [AGE_MAXIMUM] = 999) 
		OR ([AGE_MINIMUM] = 0 AND [AGE_MAXIMUM] = 11988);

	UPDATE [dbo].[CHARGE_MASTER]
		SET   [SPECIAL_HANDLING_INSTRUCTIONS] = NULL
			, [CHANGED_DATE_TIME] = GETDATE()
			, [CHANGING_USER_PROFILE_ID] = @UPId
	WHERE 
		[SPECIAL_HANDLING_INSTRUCTIONS] = 'FALSE';
		
	SELECT 'Result' = 'SUCCESS: Completed';

END
GO





-- End of 02) DACS-2745 - Create procedure - [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsALLByUPId].SQL
GO

-- Start of 01) DACS-2780 - Create OR Alter Procedure - [dbo].[Maintenance_ChartMenuReplaceDefaults].sql

-----------------------------------------------------
-- 01) DACS-2780 - Create OR Alter Procedure - [dbo].[Maintenance_ChartMenuReplaceDefaults].sql
-----------------------------------------------------
GO

GO

GO


CREATE OR ALTER PROCEDURE [dbo].[dbo.Maintenance_ChartMenuReplaceDefaults]
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @countDefaultEntries INT = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1);
	
	IF @countDefaultEntries > 0
	BEGIN
		PRINT('Default Chart Menu items already present: ' + CAST(@countDefaultEntries AS VARCHAR(20)));
		RETURN;
	END;
		
	DECLARE @insertDate DATE = GETDATE();

	INSERT INTO CHART_MENU
		(SERVICE_AGREEMENT_ID, MENU_ID, DISPLAY_SEQ, CREATION_DATE_TIME, CREATING_USER_PROFILE_ID, CHANGED_DATE_TIME, CHANGING_USER_PROFILE_ID)
	VALUES
		(-1, 0	 ,1	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 1	 ,2	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 13	 ,3	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 2	 ,4	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 18	 ,5	 ,@insertDate, 1	,@insertDate, 1),
		(-1, 3	 ,6	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 12	 ,7	 ,@insertDate, 1	,@insertDate, 1),
		(-1, 4	 ,8	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 5	 ,9	 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 6	 ,10 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 7	 ,11 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 14	 ,12 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 17	 ,13 ,@insertDate, 1	,@insertDate, 1),
		(-1, 8	 ,14 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 9	 ,15 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 10	 ,16 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 11	 ,17 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 15	 ,18 ,@insertDate, 1	,@insertDate, 1),	
		(-1, 16	 ,19 ,@insertDate, 1	,@insertDate, 1);

	SET @countDefaultEntries = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1);
	
	IF @countDefaultEntries > 0
	BEGIN
		PRINT('Default Chart Menu items now present: ' + CAST(@countDefaultEntries AS VARCHAR(20)));
		RETURN;
	END;
GO

/*
begin tran;
DELETE FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1
exec [dbo].[dbo.Maintenance_ChartMenuReplaceDefaults]
*/
-- End of 01) DACS-2780 - Create OR Alter Procedure - [dbo].[Maintenance_ChartMenuReplaceDefaults].sql
GO

-- Start of 02) DACS-2780 - Create OR Alter Procedure - [dbo].[Maintenance_ChartMenuQualifyCopyDefaultsToSAIdWithUPId].sql

-----------------------------------------------------
-- 02) DACS-2780 - Create OR Alter Procedure - [dbo].[Maintenance_ChartMenuQualifyCopyDefaultsToSAIdWithUPId].sql
-----------------------------------------------------
GO

GO

GO


CREATE OR ALTER PROCEDURE [dbo].[Maintenance_ChartMenuQualifyCopyDefaultsToSAIdWithUPId]
	 @SAId INT
	,@UPId INT
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'Result' = 'Error: SA Id is invalid.';
		RETURN;
	END;

	IF @UPId IS NULL OR @UPId <= 0
	BEGIN
		SELECT 'Result' = 'Error: UP Id is invalid.';
		RETURN;
	END;

	DECLARE @countDefaultEntries INT = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1);
	DECLARE @countTargetEntries INT = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = @SAId);
	
	IF @countDefaultEntries <= 0
	BEGIN
		PRINT('Default Chart Menu items not present.  attempting to correct... ');
		EXEC [dbo].[dbo.Maintenance_ChartMenuReplaceDefaults];
		SET @countDefaultEntries  = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1);
		
		IF @countDefaultEntries <= 0
		BEGIN
			SELECT 'Result' = 'Error: Failed to correct missing default Chart Menu items.';
			RETURN;
		END;
	END;
		
	IF @countTargetEntries > 0
	BEGIN
		SELECT 'Result' = 'SUCCESS: Chart Menu items already present for SA Id: ' + CAST(@SAId AS VARCHAR(20)) + ' = ' + CAST(@countTargetEntries AS VARCHAR(20));
		RETURN;
	END;

	DECLARE @insertDate DATE = GETDATE();
	
	IF OBJECT_ID('tempdb..#TempRows') IS NOT NULL
	BEGIN
		DROP TABLE #TempRows
	END;
	
	-- Fill temp table with our data
	SELECT TOP (30)
		  [SERVICE_AGREEMENT_ID]
		 ,[MENU_ID]
		 ,[DISPLAY_SEQ]
		 ,[CREATION_DATE_TIME]
		 ,[CREATING_USER_PROFILE_ID]
		 ,[CHANGED_DATE_TIME]
		 ,[CHANGING_USER_PROFILE_ID]
	INTO #TempRows
	FROM
		(	
			SELECT 
				 @SAId AS [SERVICE_AGREEMENT_ID]
				,[MENU_ID]
				,[DISPLAY_SEQ]
				,@insertDate AS [CREATION_DATE_TIME]
				,@UPId AS [CREATING_USER_PROFILE_ID]
				,@insertDate AS [CHANGED_DATE_TIME]
				,@UPId AS [CHANGING_USER_PROFILE_ID]
			FROM
				[CHART_MENU] src WITH (NOLOCK)
			WHERE 
				[SERVICE_AGREEMENT_ID] = -1
		) AS sourceList

	DECLARE @countTempEntries INT = (SELECT count(*) FROM #TempRows);
	print('temp table count Org: ' + CAST(@countTempEntries AS VARCHAR(20)));
	
	IF @countTempEntries <> @countDefaultEntries
	BEGIN
		SELECT 'Result' = 'Error: Chart Menu Default count does not match Temporary count : ' + CAST(@countDefaultEntries AS VARCHAR(20)) + ' :: ' + CAST(@countTempEntries AS VARCHAR(20));
		RETURN;
	END;


	INSERT INTO CHART_MENU
		(SERVICE_AGREEMENT_ID, MENU_ID, DISPLAY_SEQ, CREATION_DATE_TIME, CREATING_USER_PROFILE_ID, CHANGED_DATE_TIME, CHANGING_USER_PROFILE_ID)
	SELECT
			 #TempRows.[SERVICE_AGREEMENT_ID]
			,#TempRows.[MENU_ID]
			,#TempRows.[DISPLAY_SEQ]
			,#TempRows.[CREATION_DATE_TIME]
			,#TempRows.[CREATING_USER_PROFILE_ID]
			,#TempRows.[CHANGED_DATE_TIME]
			,#TempRows.[CHANGING_USER_PROFILE_ID]
		FROM #TempRows;	
	

	SET @countTargetEntries = (SELECT count(*)	FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = @SAId);
	
	IF @countTargetEntries <> @countTempEntries
		SELECT 'Result' = 'Error: Chart Menu count does not match Temporary count : ' + CAST(@countTargetEntries AS VARCHAR(20)) + ' :: ' + CAST(@countTempEntries AS VARCHAR(20));
	ELSE
		SELECT 'Result' = 'SUCCESS: Chart Menu for SA Id : ' + CAST(@SAId AS VARCHAR(20)) + ' = ' + CAST(@countTargetEntries AS VARCHAR(20));

GO

/*
begin tran;
DELETE FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = -1;
DELETE FROM [CHART_MENU] WHERE SERVICE_AGREEMENT_ID = 555236;
exec [dbo].[dbo.Maintenance_ChartMenuReplaceDefaults];
exec [dbo].[Maintenance_ChartMenuQualifyCopyDefaultsToSAIdWithUPId] @SAId=555236, @UPId=1
*/
-- End of 02) DACS-2780 - Create OR Alter Procedure - [dbo].[Maintenance_ChartMenuQualifyCopyDefaultsToSAIdWithUPId].sql
GO

-- Start of 1) Add ErrorCount column to ChartPostBillAudit Table.sql

GO 

Alter Table [dbo].[ChartPostBillAudit] 
add [ErrorCount] int;
-- End of 1) Add ErrorCount column to ChartPostBillAudit Table.sql
GO

-- Start of 2) Add Trigger to ChartPostBillAudit Table.sql

GO

CREATE TRIGGER [dbo].[ChartPostBillAudit_Completed] ON [dbo].[ChartPostBillAudit]
WITH EXEC AS CALLER
AFTER UPDATE
AS

DECLARE @errorCount INT
DECLARE @ChartId INT
DECLARE @newStatusId INT
DECLARE @chartPostBillAuditId INT
DECLARE @CompletedChartVersionId int;

SELECT 
	@chartId = i.ChartId,
	@chartPostBillAuditId = i.ChartPostBillAuditId, 
	@newStatusID = i.[ChartPostBillAuditStatusTypeCode] 
FROM inserted i;

SELECT @CompletedChartVersionId = isnull([ChartAuditVersionId],0)
FROM [dbo].[ChartAuditVersion] WHERE [ChartAuditId] = @chartPostBillAuditId and [VersionNumber] = 2;

IF @newStatusId in (3)
BEGIN

	-- If this is a new PBA structure or not.
	IF @CompletedChartVersionID > 0
	BEGIN
		select @errorCount = count(*) From 
		(
			SELECT ChartAuditAnesthesiaVersionItemId as versionItemId FROM ChartAuditAnesthesiaVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0
	
			UNION

			SELECT ChartAuditDemographicVersionItemId as versionItemId FROM ChartAuditDemographicVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0
	
			UNION

			SELECT ChartAuditDocumentationVersionItemId as versionItemId FROM ChartAuditDocumentationVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0

			UNION

			SELECT ChartAuditFacilityLOSVersionItemId as versionItemId FROM ChartAuditFacilityLOSVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0

			UNION

			SELECT ChartAuditPhysicianLOSVersionItemId as versionItemId FROM ChartAuditPhysicianLOSVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0

			UNION

			-- rules on procedures can vary, so this captures the non OBS procedure count.
			SELECT ChartAuditProcedureVersionItemId as versionItemId FROM ChartAuditProcedureVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0 AND ProcedureType <> 'OB'

			UNION

			-- rules on procedures can vary, so this captures the OBS procedure.
			SELECT ChartAuditProcedureVersionItemId as versionItemId FROM ChartAuditProcedureVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,3,5) and ExcludeFromQA = 0 AND ProcedureType = 'OB'

			UNION

			-- rules on dx codes can vary.  This captures counts for non primary.
			SELECT ChartAuditDiagnosisVersionItemId as versionItemId FROM ChartAuditDiagnosisVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,5) and ExcludeFromQA = 0 and IsPrimary = 0
	
			UNION

			-- rules on dx codes can vary.  This captures counts for primary.
			SELECT ChartAuditDiagnosisVersionItemId as versionItemId FROM ChartAuditDiagnosisVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,3,5) and ExcludeFromQA = 0 and DiagnosisTypeID in (2,3) AND IsPrimary = 1

			UNION

			-- rules on dx codes can vary.  This captures chief complaints.
			SELECT ChartAuditDiagnosisVersionItemId as versionItemId FROM ChartAuditDiagnosisVersionItem
			WHERE ChartAuditVersionId = @CompletedChartVersionId 
					and ChartAuditActionTypeCode in (1,2,3,5) and ExcludeFromQA = 0 and DiagnosisTypeID not in (2,3) AND IsPrimary = 1

		) as result
	END
	ELSE
	-- else get the error count using the old table.
	BEGIN

		Select @errorCount = count(*) from
		(
				Select [CHART_POST_BILL_AUDIT_REVIEW_ID]
				FROM [dbo].[CHART_POST_BILL_AUDIT_REVIEW] WHERE [CHART_ID] = @chartId
				AND (ISNULL([FACILITY_SVC_ERROR],0) > 0 
				OR ISNULL([INFUSION_ERROR],0) > 0
				OR ISNULL([PHYSICIAN_SVC_ERROR],0) > 0
				OR ISNULL([DIAGNOSIS_ICD10_ERROR],0) > 0
				OR ISNULL([OBSERVATION_HOURS_ERROR],0) > 0
				OR ISNULL([OBSERVATION_PROCEDURES_ERROR],0) > 0
				OR ISNULL([OBSERVATION_INFUSIONS_ERROR],0) > 0
				OR ISNULL([PHYSICIAN_PROCEDURE_ERROR],0) > 0
				OR ISNULL([PHYSICIAN_SVC_ERROR],0) > 0
				OR ISNULL([DEMOGRAPHIC_ERROR],0) > 0
				OR ISNULL([FACILITY_PROCEDURE_ERROR],0) > 0
				)
		) As result2

	END

	-- update the ChartPostBillAudit with the calculated errors in the PBA.
	UPDATE ChartPostBillAudit SET ErrorCount = @errorCount WHERE ChartPostBillAuditId = @chartPostBillAuditID
END

GO
-- End of 2) Add Trigger to ChartPostBillAudit Table.sql
GO

-- Start of 01) DACS-1671 - ALTER TABLE [dbo].[FACILITY_FINANCIAL_CLASS] - add column [USE_ALTERNATE_GOV_COMMERCIAL_MODE].sql

-----------------------------------------------------------------------------
-- 01) DACS-1671 - ALTER TABLE [dbo].[FACILITY_FINANCIAL_CLASS] - add column [USE_ALTERNATE_GOV_COMMERCIAL_MODE].sql
-----------------------------------------------------------------------------
GO

ALTER TABLE [dbo].[FACILITY_FINANCIAL_CLASS]
	ADD [USE_ALTERNATE_GOV_COMMERCIAL_MODE] INT NULL,
	CONSTRAINT [DF_USE_ALTERNATE_GOV_COMMERCIAL_MODE]  DEFAULT ((0)) FOR [USE_ALTERNATE_GOV_COMMERCIAL_MODE];

GO


-- End of 01) DACS-1671 - ALTER TABLE [dbo].[FACILITY_FINANCIAL_CLASS] - add column [USE_ALTERNATE_GOV_COMMERCIAL_MODE].sql
GO

-- Start of 02) DACS-1671 - Qualify Insert into PHYSICIAN_SERVICE_TIME_BASED_CALCULATION.sql

----------------------------------------------
-- 02) DACS-1671 - Qualify Insert into PHYSICIAN_SERVICE_TIME_BASED_CALCULATION.sql
-----------------------------------------------
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-----------------------------------------------
-- Set some variables
-----------------------------------------------
DECLARE @MDM2023EffectiveDate datetime = '2023-01-01'
DECLARE @MDM2023ExpirationDate datetime = '2099-12-31'

-- at this time there should be 0 (zero) records unless this script has already been processed.
DECLARE @countPresent INT = 
	(
		SELECT 
			COUNT(*) 
		FROM 
			[dbo].[PHYSICIAN_SERVICE_TIME_BASED_CALCULATION] 
		WHERE 
			[GOVT_COMMERCIAL_IND] = 'A'
	);

IF @countPresent > 0
BEGIN
	PRINT('Alternate data already present [' + CAST(@countPresent AS varchar(20)) + '].  Skipping inserts.');
	RETURN;
END

-- perform insert
INSERT INTO [dbo].[PHYSICIAN_SERVICE_TIME_BASED_CALCULATION] 
	(
	 [PHYSICIAN_SERVICE_CLASS_CD]
     ,[FROM_MINUTES]
     ,[TO_MINUTES]
     ,[SERVICE_LEVEL_CD]
     ,[ADDITIONAL_MINUTES_SPAN]
     ,[EACH_ADDITIONAL_MINUTES_SPAN_CPT_CODE]
     ,[EFFECTIVE_DATE]
     ,[EXPIRATION_DATE]
     ,[GOVT_COMMERCIAL_IND]
	) 
VALUES
-- PHYSICIAN_SERVICE_CLASS_CD	FROM_MINUTES	TO_MINUTES	SERVICE_LEVEL_CD	ADDITIONAL_MINUTES_SPAN	EACH_ADDITIONAL_MINUTES_SPAN_CPT_CODE	EFFECTIVE_DATE	EXPIRATION_DATE	GOVT_COMMERCIAL_IND

--        [EnumDescription("Consultation Inpatient")]  
--        InpatientConsultation = 10,
(10, 35, 44 , 2 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(10, 45, 59 , 3 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(10, 60, 79 , 4 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(10, 80, 94 , 5 , 15, 	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),


--        [EnumDescription("Consultation Outpatient")]  
--        OutPatientConsultation = 11,
(11, 20, 29 , 2 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(11, 30, 39 , 3 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(11, 40, 54 , 4 , 0 , 	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(11, 55, 69 , 5 , 15, 	'99417', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),


-----------------------------------------------------------------------------------------

--        [EnumDescription("Office or Other Outpatient Services - New")]
--        OfficeOtherOutPatientNew = 2,
(2 , 15, 29	, 2	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(2 , 30, 44	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(2 , 45, 59	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(2 , 60, 88	, 5	, 15,	'99417', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Office or Other Outpatient Services - Established")]
--        OfficeOtherOutPatientEstablished = 3,
(3 , 10, 19	, 2	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(3 , 20, 29	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(3 , 30, 39	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(3 , 40, 68	, 5	, 15,	'99417', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("ED Observation")]
--        EdObs = 5,
(5 , 40, 54	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(5 , 55, 74	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(5 , 75, 104, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Inpatient Admission/Discharge Same Day ")]
--        InpatientAdmissionDischargeSameDay = 7,
(7 , 45, 69	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(7 , 70, 84	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(7 , 85, 114, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Inpatient Initial Day ")]
--        InpatientInitialDay = 8,
(8 , 40, 54	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(8 , 55, 74	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(8 , 75, 104, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Inpatient Subsequent Day/Discharge Day ")]
--        InpatientSubsequentDischargeSameDay = 9,
(9 , 25, 34	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(9 , 35, 49	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(9 , 50, 79	, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Nursing Home-Initial Day")]
--        NursingHomeInitialDay = 12,
(12, 25, 34	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(12, 35, 44	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(12, 45, 94	, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Nursing Home-Subsequent Day")]
--        NursingHomeSubsequentDay = 13,
(13, 10, 14	, 2	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(13, 15, 29	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(13, 30, 44	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(13, 45, 84	, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Observation - Initial Day")]
--        ObservationInitialDay = 16,
(16, 40, 54	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(16, 55, 74	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(16, 75, 104, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),

--        [EnumDescription("Observation - Subsequent/Discharge Day")]
--        ObservationSubsequentDischargeDay = 17,
(17, 25, 34	, 3	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(17, 35, 49	, 4	, 0	,	NULL, 		@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A'),
(17, 50, 79	, 5	, 15,	'99418', 	@MDM2023EffectiveDate, @MDM2023ExpirationDate, 'A')



-- End of 02) DACS-1671 - Qualify Insert into PHYSICIAN_SERVICE_TIME_BASED_CALCULATION.sql
GO

-- Start of 03) DACS-1671 - ALTER TABLE [dbo].[CHART_PHYSICIAN_LEVEL_OF_SERVICE] - add time based columns.sql

-----------------------------------------------------------------------------
-- 03) DACS-1671 - ALTER TABLE [dbo].[CHART_PHYSICIAN_LEVEL_OF_SERVICE] - add time based columns.sql
-----------------------------------------------------------------------------
GO

ALTER TABLE [dbo].[CHART_PHYSICIAN_LEVEL_OF_SERVICE]
	ADD [CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES] [INT] NULL,
		[CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE] [INT] NULL,
		[CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY] [INT] NULL,
		[CLINIC_2021_TIME_BASED_ADDITIONAL_CPT_CODE] [VARCHAR](5) NULL,
		[CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE] [INT] NULL,
	CONSTRAINT [DF_CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES]  DEFAULT ((0)) FOR [CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES],
	CONSTRAINT [DF_CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE]  DEFAULT ((0)) FOR [CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE],
	CONSTRAINT [DF_CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY]  DEFAULT ((0)) FOR [CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY],
	CONSTRAINT [DF_CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE]  DEFAULT ((0)) FOR [CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE]
	;

GO


/*
For testing:
select top 10 * from [dbo].[CHART_PHYSICIAN_LEVEL_OF_SERVICE];
*/
-- End of 03) DACS-1671 - ALTER TABLE [dbo].[CHART_PHYSICIAN_LEVEL_OF_SERVICE] - add time based columns.sql
GO

-- Start of 1) DACS-2782 - Alter ICD_10_PHRASE_SEARCH_ALL_WORDS.sql

GO

ALTER PROCEDURE [dbo].[ICD_10_PHRASE_SEARCH_ALL_WORDS] 
 ( 
 @parmWord1 varchar(50), 
 @parmWord2 varchar(50), 
 @parmWord3 varchar(50), 
 @parmWord4 varchar(50), 
 @parmWord5 varchar(50) 
 ) 
 AS 
 BEGIN 

 declare @containsParmWord1 nvarchar(3000) 
 declare @containsParmWord2 nvarchar(3000) 
 declare @containsParmWord3 nvarchar(3000) 
 declare @containsParmWord4 nvarchar(3000) 
 declare @containsParmWord5 nvarchar(3000) 

 set @containsParmWord1 = null 
 set @containsParmWord2 = null 
 set @containsParmWord3 = null 
 set @containsParmWord4 = null 
 set @containsParmWord5 = null 

 declare @escParmWord1 nvarchar(3000) 
 declare @escParmWord2 nvarchar(3000) 
 declare @escParmWord3 nvarchar(3000) 
 declare @escParmWord4 nvarchar(3000) 
 declare @escParmWord5 nvarchar(3000) 

 set @escParmWord1 = null 
 set @escParmWord2 = null 
 set @escParmWord3 = null 
 set @escParmWord4 = null 
 set @escParmWord5 = null 


 declare @synTable table (syn_id int identity (1,1), syn_word varchar(1000), processed bit) 
 declare @id int 
 declare @synWord varchar(250) 

 if object_id('TempDB..#Results', 'U') is not null DROP TABLE #Results;
 create table #Results (ResultText varchar(250), ResultCode varchar(10));

 -- Try searching for multi-word synonyms first 
 if @parmWord2 <> '' 
 BEGIN 
 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord1 + ' ' + @parmWord2 
 insert into @synTable (syn_word, processed) select rtrim(REPLACE(DRUG_CLASSIFCATION,',','')), 0 from DRUG sy where sy.DRUG_GENERIC_NAME = @parmWord1 + ' ' + @parmWord2 
 insert into @synTable (syn_word, processed) select rtrim(REPLACE(DRUG_CLASSIFCATION,',','')), 0 from DRUG sy where sy.DRUG_TRADE_NAME = @parmWord1 + ' ' + @parmWord2 

 set @containsParmWord1 = ' FormsOf(INFLECTIONAL, "' + @parmWord1 + '") ' 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord1 = @containsParmWord1 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
 END 

 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord1 
 insert into @synTable (syn_word, processed) select rtrim(REPLACE(DRUG_CLASSIFCATION,',','')), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord1 +'%' and len(@parmWord1) > 3 
 insert into @synTable (syn_word, processed) select rtrim(REPLACE(DRUG_CLASSIFCATION,',','')), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord1 +'%' and len(@parmWord1) > 3 

 set @containsParmWord1 = '"' + @parmWord1 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord1 + '") ' 
 set @escParmWord1 = dbo.escapeFTSSearch (rtrim(@parmWord1)) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord1 = @containsParmWord1 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord1 IS NOT NULL) 
 BEGIN 
 set @escParmWord1 = @escParmWord1 + ' OR ' 
 END 
 set @escParmWord1 = @escParmWord1 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
  
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult1 varchar(100)
 if (LEN(@escParmWord1) > 2 AND SUBSTRING(@escParmWord1, len(@escParmWord1) -3, 3) = '   ')
 BEGIN
  set @testResult1 = dbo.StringBeforeLastIndex(@escParmWord1, 'AND') + ')'
  set @escParmWord1 = @testResult1;
 END

 END 

 if @parmWord2 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord2) > 1 insert into @synTable (syn_word, processed) select CM_WORD, 0 from [ICD_10_SYNONYMS] sy where sy.SYNONYM_WORD = @parmWord2 
 if LEN(@parmWord2) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord2 +'%' and len(@parmWord2) > 3 
 if LEN(@parmWord2) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord2 +'%' and len(@parmWord2) > 3 

 set @containsParmWord2 = '"' + @parmWord2 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord2 + '") ' 
 set @escParmWord2 = dbo.escapeFTSSearch (rtrim(@parmWord2)) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord2 = @containsParmWord2 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord2 IS NOT NULL) 
 BEGIN 
 set @escParmWord2 = @escParmWord2 + ' OR ' 
 END 
 set @escParmWord2 = @escParmWord2 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
 
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult2 varchar(100)
 if (LEN(@escParmWord2) > 2 AND SUBSTRING(@escParmWord2, len(@escParmWord2) -3, 3) = '   ')
 BEGIN
  set @testResult2 = dbo.StringBeforeLastIndex(@escParmWord2, 'AND') + ')'
  set @escParmWord2 = @testResult2;
 END

 END 

 if @parmWord3 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord3) > 1 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord3 
 if LEN(@parmWord3) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord3 +'%' and len(@parmWord3) > 3 
 if LEN(@parmWord3) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord3 +'%' and len(@parmWord3) > 3 
 set @containsParmWord3 = '"' + @parmWord3 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord3 + '") ' 
 set @escParmWord3 = dbo.escapeFTSSearch (rtrim(@parmWord3)) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord3 = @containsParmWord3 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord3 IS NOT NULL) 
 BEGIN 
 set @escParmWord3 = @escParmWord3 + ' OR ' 
 END 
 set @escParmWord3 = @escParmWord3 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
 
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult3 varchar(100)
 if (LEN(@escParmWord3) > 2 AND SUBSTRING(@escParmWord3, len(@escParmWord3) -3, 3) = '   ')
 BEGIN
  set @testResult3 = dbo.StringBeforeLastIndex(@escParmWord3, 'AND') + ')'
  set @escParmWord3 = @testResult3;
 END

 END 

 if @parmWord4 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord4) > 1 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord4 
 if LEN(@parmWord4) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord4 +'%' and len(@parmWord4) > 3 
 if LEN(@parmWord4) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord4 +'%' and len(@parmWord4) > 3 
 set @containsParmWord4 = '"' + @parmWord4 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord4 + '") ' 
 set @escParmWord4 = dbo.escapeFTSSearch (rtrim(@parmWord4)) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord4 = @containsParmWord4 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord4 IS NOT NULL) 
 BEGIN 
 set @escParmWord4 = @escParmWord4 + ' OR ' 
 END 
 set @escParmWord4 = @escParmWord4 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
  
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult4 varchar(100)
 if (LEN(@escParmWord4) > 2 AND SUBSTRING(@escParmWord4, len(@escParmWord4) -3, 3) = '   ')
 BEGIN
  set @testResult4 = dbo.StringBeforeLastIndex(@escParmWord4, 'AND') + ')'
  set @escParmWord4 = @testResult4;
 END

 END 

 if @parmWord5 <> '' 
 BEGIN 
 DELETE from @synTable 
 if LEN(@parmWord5) > 1 insert into @synTable (syn_word, processed) select CM_WORD, 0 from icd_10_SYNONYMS sy where sy.SYNONYM_WORD = @parmWord5 
 if LEN(@parmWord5) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_GENERIC_NAME like @parmWord5 +'%' and len(@parmWord5) > 3 
 if LEN(@parmWord5) > 2 insert into @synTable (syn_word, processed) select REPLACE(DRUG_CLASSIFCATION,',',''), 0 from DRUG sy where sy.DRUG_TRADE_NAME like @parmWord5 +'%' and len(@parmWord5) > 3 
 set @containsParmWord5 = '"' + @parmWord5 + '" OR FormsOf(INFLECTIONAL, "' + @parmWord5 + '") ' 
 set @escParmWord5 = dbo.escapeFTSSearch (rtrim(@parmWord5)) 
 if (select COUNT(*) from @synTable) > 0 
 BEGIN 
 WHILE exists (select * from @synTable where processed = 0) 
 BEGIN 
 set @id = (select MIN(syn_id) from @synTable where processed = 0) 
 set @synWord = (Select syn_word from @synTable where syn_id = @id) 
 set @containsParmWord5 = @containsParmWord5 + ' OR FormsOf(INFLECTIONAL, "' + @synWord + '") ' 
 if (@escParmWord5 IS NOT NULL) 
 BEGIN 
 set @escParmWord5 = @escParmWord5 + ' OR ' 
 END 
 set @escParmWord5 = @escParmWord5 + ' (' + dbo.escapeFTSSearch (@synWord) +' )' 
 update @synTable SET Processed = 1 where syn_id = @id 
 END 
 END 
   
 -- ACS-15364 Remove orphan "AND" from search text
  declare @testResult5 varchar(100)
 if (LEN(@escParmWord5) > 2 AND SUBSTRING(@escParmWord5, len(@escParmWord5) -3, 3) = '   ')
 BEGIN
  set @testResult5 = dbo.StringBeforeLastIndex(@escParmWord5, 'AND') + ')'
  set @escParmWord5 = @testResult5;
 END

 END 

 if @containsParmWord5 is not null 
 BEGIN 
 -- *** begin edit 1/11/2018 dsexton ***
 insert into #Results (ResultText, ResultCode)
 --SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --select *
 --FROM 
 --( 
 -- *** end edit 1/11/2018 dsexton ***
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(cm.[DESCRIPTION], @containsParmWord3) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord4) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord5) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord3)) 
 AND (@escParmWord4 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord4)) 
 AND (@escParmWord5 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord5)) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 -- begin dsexton modification 11/20/2015 (if @containsParmWord5) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 and CONTAINS(DESCRIPTION, @containsParmWord2) 
 and CONTAINS(DESCRIPTION, @containsParmWord3) 
 and CONTAINS(DESCRIPTION, @containsParmWord4) 
 and CONTAINS(DESCRIPTION, @containsParmWord5) 
 GROUP by CodeDescription, ICD_10_CODE 

 /* -- Old version did not include UNION for @escParmWord in this section. Not needed? 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 and CONTAINS(DESCRIPTION, @escParmWord2) 
 and CONTAINS(DESCRIPTION, @escParmWord3) 
 and CONTAINS(DESCRIPTION, @escParmWord4) 
 and CONTAINS(DESCRIPTION, @escParmWord5) 
 AND @escParmWord1 is not null 
 AND @escParmWord2 is not null 
 AND @escParmWord3 is not null 
 AND @escParmWord4 is not null 
 AND @escParmWord5 is not null 
 GROUP by CodeDescription, ICD_10_CODE 
 */ 

 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord2) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord3) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord4) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord5) 
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord5) ----------------------------- 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) AND CONTAINS(cm.TITLE, @containsParmWord5) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) AND CONTAINS(cm.TITLE, @containsParmWord5) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 --AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) AND CONTAINS(cm.TITLE, @containsParmWord5) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord3) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord4) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord5) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord4) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord5) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 
-- *** begin edit 1/11/2018 dsexton ***
 --) x 

 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText 
	   ,x.ResultCode 
	   ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
 -- *** end edit 1/11/2018 dsexton ***
 WHERE x.ResultCode <> ''
 order by x.ResultCode 
 END 

 ELSE 
 if @containsParmWord4 is not null 
 BEGIN 
 -- *** begin edit 1/11/2018 dsexton ***
insert into #Results (ResultText, ResultCode)
 --SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --Select *
 --FROM 
 --( 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(cm.[DESCRIPTION], @containsParmWord3) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord4) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord3)) 
 AND (@escParmWord4 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord4)) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 -- begin dsexton modification 11/20/2015 (if @containsParmWord4) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 and CONTAINS(DESCRIPTION, @containsParmWord2) 
 and CONTAINS(DESCRIPTION, @containsParmWord3) 
 and CONTAINS(DESCRIPTION, @containsParmWord4) 
 GROUP by CodeDescription, ICD_10_CODE 

 /* -- Old version did not include UNION for @escParmWord in this section. Not needed? 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 and CONTAINS(DESCRIPTION, @escParmWord2) 
 and CONTAINS(DESCRIPTION, @escParmWord3) 
 and CONTAINS(DESCRIPTION, @escParmWord4) 
 AND @escParmWord1 is not null 
 AND @escParmWord2 is not null 
 AND @escParmWord3 is not null 
 AND @escParmWord4 is not null 
 GROUP by CodeDescription, ICD_10_CODE 
 */ 

 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord2) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord3) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord4) 
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord4) ----------------------------- 


 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 --AND CONTAINS(cm.TITLE, @containsParmWord3) AND CONTAINS(cm.TITLE, @containsParmWord4) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord3) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord4) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord4) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 

 UNION ALL 
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord4) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord2))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord4) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord3))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord3) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord4) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord4))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord4) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 
 -- *** begin edit 1/11/2018 dsexton ***
 --) x 

 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText 
	   ,x.ResultCode 
	   ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
 -- *** end edit 1/11/2018 dsexton ***
 WHERE x.ResultCode <> ''
 order by x.ResultCode 
 END 
 ELSE 

 if @containsParmWord3 is not null 
 BEGIN 
-- *** begin edit 1/11/2018 dsexton ***
insert into #Results (ResultText, ResultCode)
--SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --FROM 
 --( 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(cm.[DESCRIPTION], @containsParmWord3) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord2)) 
 AND (@escParmWord3 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord3)) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 -- begin dsexton modification 11/20/2015 (if @containsParmWord3) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 and CONTAINS(DESCRIPTION, @containsParmWord2) 
 and CONTAINS(DESCRIPTION, @containsParmWord3) 
 GROUP by CodeDescription, ICD_10_CODE 


 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 and CONTAINS(DESCRIPTION, @escParmWord2) 
 and CONTAINS(DESCRIPTION, @escParmWord3) 
 AND @escParmWord1 is not null 
 AND @escParmWord2 is not null 
 AND @escParmWord3 is not null 
 GROUP by CodeDescription, ICD_10_CODE 


 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord2) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord3) 
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord3) ----------------------------- 


 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 AND CONTAINS(cm.TITLE, @containsParmWord3) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 --AND CONTAINS(cm.TITLE, @containsParmWord3) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord3) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2) 
 AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord3) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 

 UNION ALL 
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
 IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord3))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord3) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord2))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND CONTAINS(icm.[DESCRIPTION], @containsParmWord3) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

 -- *** begin edit 1/11/2018 dsexton ***
 --) x 

 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText
	   ,x.ResultCode 
	   ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
 -- *** end edit 1/11/2018 dsexton ***
 WHERE x.ResultCode <> ''
 order by x.ResultCode 
 END 

 ELSE 

 if @containsParmWord2 is not null 
 BEGIN 
 -- *** begin edit 1/11/2018 dsexton ***
 insert into #Results (ResultText, ResultCode)
 --SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --FROM 
 --( 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1) AND CONTAINS(cm.[DESCRIPTION], @containsParmWord2) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE (@escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)) 
 AND (@escParmWord2 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord2)) 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 


 -- begin dsexton modification 11/20/2015 (if @containsParmWord2) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 and CONTAINS(DESCRIPTION, @containsParmWord2) 
 GROUP by CodeDescription, ICD_10_CODE 

 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 and CONTAINS(DESCRIPTION, @escParmWord2) 
 AND @escParmWord1 is not null 
 AND @escParmWord2 is not null 
 GROUP by CodeDescription, ICD_10_CODE 

 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1) 
 and CONTAINS(INCLUSION_TERM_DESC, @containsParmWord2) 
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord2) ----------------------------- 


 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE 
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CONTAINS(cm.TITLE, @containsParmWord2) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord2) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord2) 
 AND cm.ICD_10_CODE is not null 
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 

 UNION ALL 
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord1) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord2) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord2))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord2) AND CONTAINS(icm.[DESCRIPTION], @containsParmWord1) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient' 
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

 -- *** begin edit 1/11/2018 dsexton ***
 --) x 
 
SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText 
	  ,x.ResultCode 
	  ,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
			AND CAST(getdate() as date) <= EXPIRATION_DATE AND CAST(getdate() as date) >= EFFECTIVE_DATE
-- *** end edit 1/11/2018 dsexton ***
 WHERE x.ResultCode <> ''
 order by x.ResultCode 
 
 END 

 ELSE 

 if @containsParmWord1 is not null 
 BEGIN 
 declare @codeWord varchar(15) 


 if (LEN(@parmWord1) < 7 AND LEN(@parmWord1) > 2) 
 BEGIN 
 if (LEN(@parmWord1) = 3) 
 BEGIN 
 set @codeWord = @parmWord1 
 END 
 ELSE 
 set @codeWord = SUBSTRING(@parmWord1, 1, 3) + '.' + SUBSTRING(@parmWord1, 4, LEN(@parmWord1) - 3) 
 END 

 -- *** begin edit 1/11/2018 dsexton ***
 insert into #Results (ResultText, ResultCode)
 --SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText , x.ResultCode 
 --FROM 
 --( 
 -- *** end edit 1/11/2018 dsexton ***
 -- Check if a 7th digit code 
 select cm.LONG_DESCRIPTION as ResultText, SUBSTRING(cm.ICD10_CM,1,3) + '.' + SUBSTRING(cm.ICD10_CM,4,4) as ResultCode from ICD10_CM cm with (NOLOCK) 
 WHERE cm.ICD10_CM = REPLACE(@parmWord1,'.','')
 AND LEN(REPLACE(@parmWord1,'.','')) = 7 
 AND CAST(getdate() as date) <= cm.EXPIRATION_DATE AND CAST(getdate() as date) >= cm.EFFECTIVE_DATE
 GROUP by cm.LONG_DESCRIPTION, cm.ICD10_CM 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE like REPLACE(cm.ICD_10_CODE, '.','') + '%' 
 WHERE CONTAINS(cm.[DESCRIPTION], @containsParmWord1)
 AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 


 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE like REPLACE(cm.ICD_10_CODE, '.','') + '%' 
 WHERE @escParmWord1 is not null AND CONTAINS(cm.[DESCRIPTION], @escParmWord1)
 AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 LEFT OUTER JOIN ICD_10_RELATIVE_USAGE ru on ru.ICD10_CODE like REPLACE(cm.ICD_10_CODE, '.','') + '%' 
 WHERE cm.ICD_10_CODE LIKE @codeWord + '%'
 AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 

 UNION ALL 
 select cm.DESCRIPTION as ResultText, cm.ICD_10_CODE as ResultCode from ICD_10_CODE_MASTER cm with (NOLOCK) 
 WHERE cm.DESCRIPTION LIKE '%' + @parmWord1 + '%' 
 GROUP by cm.DESCRIPTION, cm.ICD_10_CODE 


 -- begin dsexton modification 11/20/2015 (if @containsParmWord1) ----------------------------- 
 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @containsParmWord1) 
 GROUP by CodeDescription, ICD_10_CODE 

 union all 
 SELECT CodeDescription as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_Rule_Map with (NOLOCK) 
 WHERE CONTAINS(DESCRIPTION, @escParmWord1) 
 AND @escParmWord1 is not null 
 GROUP by CodeDescription, ICD_10_CODE 

 union all 
 SELECT DESCRIPTION as ResultText, ICD_10_CODE as ResultCode 
 FROM 
 dbo.ICD10_Code_InclusionTerm_Map with (NOLOCK) 
 WHERE CONTAINS(INCLUSION_TERM_DESC, @containsParmWord1)
 GROUP by DESCRIPTION, ICD_10_CODE 
 -- end dsexton modification 11/20/2015 (if @containsParmWord1) ----------------------------- 


 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_D_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE AND CAST(getdate() as date) <= i10.EXPIRATION_DT AND CAST(getdate() as date) >= i10.EFFECTIVE_DT
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by i10.DESCRIPTION, cm.CODE 

 UNION ALL 
 select i10.DESCRIPTION as ResultText, cm.CODE as ResultCode from ICD_10_E_INDEX cm with (NOLOCK) 
 INNER JOIN ICD_10_CODE_MASTER i10 on i10.ICD_10_CODE = cm.CODE AND CAST(getdate() as date) <= i10.EXPIRATION_DT AND CAST(getdate() as date) >= i10.EFFECTIVE_DT
 WHERE CONTAINS(cm.TITLE, @containsParmWord1) AND CAST(getdate() as date) <= cm.EXPIRATION_DT AND CAST(getdate() as date) >= cm.EFFECTIVE_DT
 GROUP by i10.DESCRIPTION, cm.CODE 

 --UNION ALL 
 --select cm.TITLE as ResultText, substring(cd.CODE,1,6) as ResultCode from ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS cm with (NOLOCK), ICD_10_TABLE_OF_DRUGS_CODES cd with (NOLOCK) 
 --WHERE CONTAINS(cm.TITLE, @containsParmWord1) 
 --and cd.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID = cm.ICD_10_TABLE_OF_DRUGS_AND_CHEMICALS_ID 
 --and cd.COLUMN_NUMBER = 1 and cd.CODE <> '--' 
--GROUP by cm.TITLE, cd.CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_generic_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_GENERIC_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_GENERIC_NAME, @containsParmWord1) 
 AND cm.ICD_10_CODE is not null and CAST(getdate() as date) <= cm.EXPIRATION_DTTM and CAST(getdate() as date) >= cm.EFFECTIVE_DTTM
 GROUP by cm.DRUG_GENERIC_NAME, cm.ICD_10_PCS_CODE 

-- *** begin edit 1/11/2018 dsexton ***
IF EXISTS (select 1 from drug where contains(drug_trade_name, @containsParmWord1))
insert into #Results (ResultText, ResultCode)
 --UNION ALL 
-- *** end edit 1/11/2018 dsexton ***
 select cm.DRUG_TRADE_NAME as ResultText, cm.ICD_10_PCS_CODE as ResultCode from DRUG cm with (NOLOCK) 
 WHERE CONTAINS(cm.DRUG_TRADE_NAME, @containsParmWord1) AND CAST(getdate() as date) <= cm.EXPIRATION_DTTM AND CAST(getdate() as date) >= cm.EFFECTIVE_DTTM
 GROUP by cm.DRUG_TRADE_NAME, cm.ICD_10_PCS_CODE 

 UNION ALL 
 select d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION as ResultText, icm.ICD_10_CODE as ResultCode 
 from DRUG d with (NOLOCK), DRUG d2 with (NOLOCK), DRUG_COMPOUND_INGREDIENT dci, ICD_10_CODE_MASTER icm 
 WHERE CONTAINS(d.DRUG_TRADE_NAME, @containsParmWord1) 
 AND dci.COMPOUND_DRUG_ID = d.DRUG_ID 
 AND dci.INGREDIENT_DRUG_ID = d2.DRUG_ID 
 AND d2.ICD_10_PCS_CODE = icm.ICD_10_CODE 
 AND d.DRUG_CLASSIFCATION = 'Multiingredient'
 AND CAST(getdate() as date) <= d.EXPIRATION_DTTM AND CAST(getdate() as date) >= d.EFFECTIVE_DTTM
 GROUP by d.DRUG_TRADE_NAME + ' (Ingredient: ' + d2.DRUG_GENERIC_NAME + ') ' + icm.DESCRIPTION, icm.ICD_10_CODE 

 -- *** begin edit 1/11/2018 dsexton ***
 --) x 
 
 SELECT DISTINCT UPPER(SUBSTRING(x.ResultText,1,1)) + SUBSTRING(x.ResultText,2,LEN(x.ResultText) -1) as ResultText 
				,x.ResultCode 
				,[ICD_10_CM].[SELECTION_IND] AS [SelectionInd]
 FROM #Results as x
-- *** end edit 1/11/2018 dsexton ***
 LEFT JOIN [ICD_10_CM]
		ON [ICD_10_CM].[ICD_10_CODE] = REPLACE(x.[ResultCode], '.', '')
		AND CAST(getdate() as date) <= EXPIRATION_DATE AND CAST(getdate() as date) >= EFFECTIVE_DATE
 WHERE x.ResultCode <> '' 
 order by x.ResultCode
 END 

 END
GO


-- End of 1) DACS-2782 - Alter ICD_10_PHRASE_SEARCH_ALL_WORDS.sql
GO

-- Start of 01) DACS-2802 - ALTER PROCEDURE - [dbo].[SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID].SQL

/*

DACS-2802 - Change sproc to remove enable_denial-mgmt column for changes made in DACS-2639

*/


GO

/****** Object:  StoredProcedure [dbo].[SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID]    Script Date: 10/9/2023 2:00:22 PM ******/
GO

GO



CREATE OR ALTER  PROCEDURE [dbo].[SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID] 
	@SERVICE_AGREEMENT_ID INT
AS
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT	[SERVICE_AGREEMENT_ID]
		,[FACILITY_ID]
		,[COMPANY_ID]
		,[EFFECTIVE_DATE]
		,[EXPIRATION_DATE]
		,[DESCRIPTION]
		,[HELP_DESK_PHONE_NUMBER]
		,[EVALUATE_FACILITY_SVC]
		,[EVALUATE_PHYSICIAN_SVC]
		,[PERFORM_PREBILL_AUDIT]
		,[COLLECT_ABSTRACT_PROCEDURE_CODES]
		,[PERFORM_DIAGNOSIS_CODING]
		,[CAN_ALTER_CONTENT]
		,[MODIFIER_OPTION_ID]
		,[COLLECT_DATE_OF_BIRTH]
		,[COLLECT_MEDICAL_RECORD_NUMBER]
		,[COLLECT_DATE_OF_SERVICE]
		,[COLLECT_TIME_OF_SERVICE]
		,[COLLECT_DATE_TO_ROOM]
		,[COLLECT_TIME_TO_ROOM]
		,[COLLECT_DATE_OF_PHYS_EVAL]
		,[COLLECT_TIME_OF_PHYS_EVAL]
		,[COLLECT_DATE_OF_PHYS_DIS]
		,[COLLECT_TIME_OF_PHYS_DIS]
		,[COLLECT_DATE_OF_TRIAGE]
		,[COLLECT_TIME_OF_TRIAGE]
		,[COLLECT_DATE_OF_DIS]
		,[COLLECT_TIME_OF_DIS]
		,[COLLECT_FINANCIAL_CLASS]
		,[COLLECT_TRIAGE_NURSE]
		,[COLLECT_DISCHARGE_NURSE]
		,[COLLECT_PHYSICIAN]
		,[COLLECT_PATIENT_DISPOSITION]
		,[COLLECT_DOCUMENTATION]
		,[IMAGING_METHOD_ID]
		,[IMAGING_ID]
		,[EXPORT_METHOD_ID]
		,[DELIVERY_CD]
		,[ALLOW_MULTIPLES_IN_FILE]
		,[DELIVER_TO]
		,[IMPORT_METHOD_ID]
		,[IMPORT_DIRECTORY]
		,[IMAGE_IMPORT_DIRECTORY]
		,[IMPORT_DELIVERY_NOTIFICATION]
		,[EXPORT_DELIVERY_NOTIFICATION]
		,[INBOUND_EMAIL_ACCOUNT_NAME]
		,[INBOUND_EMAIL_PASSWORD]
		,[INBOUND_EMAIL_SUBJECT]
		,[INBOUND_EMAIL_SUBJECT_FOR_IMAGES]
		,[INBOUND_EMAIL_CHARTS_LOCATION]
		,[INBOUND_FILE_EXTENSION]
		,[INBOUND_FILE_CONVERT_EXCEL_TO_CSV]
		,[IMAGE_FILE_EXTENSION]
		,[BARCODE_FACILITY_CHART_ID_RULE]
		,[FACILITY_CHART_ID_BARCODE_STARTS_WITH]
		,[ASSIGNMENT_METHOD_ID]
		,[INFUSION_INJECTION_METHOD_ID]
		,[MEDDATA_DIRECTORY_NAME]
		,[IMAGE_ACCESS_URL]
		,[BILL_SELECTION_METHOD_CD]
		,[BILL_CODER_METHOD_CD]
		,[BILL_QA_IND]
		,[BILL_PRO_FEE_METHOD_CD]
		,[AUDIT_ENABLED]
		,[IMAGE_EXPIRATION_DAYS]
		,[IMAGE_EXPORT_FORMAT]
		,[VALIDATE_DATE_OF_SERVICE_GREATER_THAN_180]
		,[COLLECT_ANESTHESIA]
		,[COLLECT_BLOOD_TYPE]
		,[COLLECT_CONSULTING_PHYSICIANS]
		,[CHART_RECAP_REPORT_FORMAT]
		,[DIAGNOSIS_CODE_LEFT_WITHOUT_BEING_SEEN_CHARTS]
		,[COLLECT_FACILITY_ADMIN_CHART_ID]
		,[COLLECT_PROCEDURE_DATES]
		,[EVALUATE_SUPPLIES]
		,[DISABLE_CCI_EDITS]
		,[COLLECT_ADDITIONAL_COMPLAINT]
		,[COLLECT_FACILITY_PATIENT_DISPOSITION]
		,[COLLECT_GENDER]
		,[AUDIT_HOSPITAL_CODED_CHARTS]
		,[FACILITY_HAS_RESIDENTS]
		,[SHOW_FINANCIAL_CLASS_CODE]
		,[SHOW_PATIENT_DISPOSITION]
		,[SHOW_FACILITY_PATIENT_DISPOSITION]
		,[DAYS_TO_AUTO_APPROVE]
		,[CREATION_DATE_TIME]
		,[CREATING_USER_PROFILE_ID]
		,[CHANGED_DATE_TIME]
		,[CHANGING_USER_PROFILE_ID]
		,[DIAGNOSIS_CODE_OUTPATIENT_ONLY]
		,[REPORT_ADMIT_DIAGNOSIS_AS_SECONDARY]
		,[DIAGNOSIS_CODE_SORT_ORDER_ID]
		,[COLLECT_SAFETY_DEVICE]
		,[COLLECT_SPORT_TYPE]
		,[COLLECT_UC_LAST_ENCOUNTER_DATE]
		,[COLLECT_RESIDENT_PARTICIPATED_IN_CARE]
		,[COLLECT_ATTESTATION_SIGNED_BY_ATTENDING]
		,[FACILITY_TYPE_CD]
		,[LCD_EDITS_METHOD_ID]
		,[OPTIONALLY_REPORT_ADMIT_DIAGNOSIS_AS_SECONDARY]
		,[COLLECT_PATIENT_AGE]
		,[SHOW_PATIENT_AGE]
		,[SERVICE_MODEL_CD]
		,[ACCT_MANAGER_USER_PROFILE_ID]
		,[ACCT_MANAGER_ASST_USER_PROFILE_ID]
		,[COLLECT_PHYSICIAN_SIGNATURE_PRESENT]
		,[EVALUATE_FACILITY_PROCEDURES]
		,[EVALUATE_PHYSICIAN_PROCEDURES]
		,[SPECIAL_RULE]
		,[EVALUATE_OBSERVATION_DEPARTMENTS]
		,[FAC_PROC_ADDL_DOS_NON_OBS]
		,[FAC_PROC_ADDL_DOS_OBS]
		,[INFUSION_INJECTION_ADDL_DOS_NON_OBS]
		,[INFUSION_INJECTION_ADDL_DOS_OBS]
		,[OBSERVATION_ADDL_DOS]
		,[DIAGNOSIS_PAGE_OPTION]
		,[PHYS_PROC_ADDL_DOS_NON_OBS]
		,[PHYS_PROC_ADDL_DOS_OBS]
		,[EXPORT_CHART_SORT_ORDER_ID]
		,[EXPORT_CHART_SORT_DIRECTION_ID]
		,[COLLECT_NURSE_PRACTITIONER]
		,[COLLECT_PROCEDURE_PHYSICIANS]
		,[DISPLAY_MODIFIER_32_CHECKBOX]
		,[EXPORT_E_CODE_849_9]
		,[ENABLE_GENDER_EDITS]
		,[ENABLE_AGE_EDITS]
		,[PASSWORD_EXPIRATION_DAYS]
		,[SHOW_NO_IVS_OR_FAC_PROCS_CHECKBOX_ON_DEMOGRAPHICS_PAGE]
		,[SHOW_DEPT_DROPDOWN_ON_INFUSION_INJECTION_PAGE]
		,[COLLECT_NO_PHYSICIAN_SERVICES_REASON]
		,[BILL_ONLY_ACTIVE_PROCEDURES_IND]
		,[COLLECT_CLINIC]
		,[SHOW_CLINIC]
		,[EXECUTE_PHYSICIAN_LOS_OVERRIDE_EDITS]
		,[IMPORT_OBS_PATIENTS_IN_PENDING_STATUS]
		,[EXECUTE_PHYSICIAN_LOS_OVERRIDE_25_MODIFIER_EDIT]
		,[COLLECT_SERVICE_LINE]
		,[SHOW_SERVICE_LINE]
		,[COLLECT_TERMINAL_DIGITS]
		,[SHOW_TERMINAL_DIGITS]
		,[FAC_PROC_DISPLAY_INSUFFICIENT_DOC_TO_BILL_CHECKBOX]
		,[PHYS_PROC_DISPLAY_INSUFFICIENT_DOC_TO_BILL_CHECKBOX]
		,[FAC_LOS_DISPLAY_PEND_AWAITING_CHARGES_BUTTON]
		,[FAC_PROC_DISPLAY_PEND_AWAITING_CHARGES_BUTTON]
		,[EXPORT_FAC_LOS_GC_MODIFIER_IF_RESIDENT_PARTICIPATED_IN_CARE]
		,[DEMO_TEST_SITE_IND]
		,[PERFORM_ECODE_EDITS]
		,[SHOW_NO_FACILITY_PROCEDURES_CHECKBOX_ON_INFUSION_INJECTION_PAGE]
		,[CREATE_PRODUCTIVITY_STAT_CHARGE_ON_CHART_COMPLETION]
		,[TURNAROUND_HOURS_REPORTING_THRESHOLD]
		,[TURNAROUND_HOURS_REPORTING_METHOD]
		,[TURNAROUND_START_TIME_IN_MINUTES]
		,[INFUSION_INJECTION_CALC_RULES_ID]
		,[DISABLE_EXAMINATION_BODY_AREAS]
		,[USE_SEQUENCING_FOR_CLINIC_VISITS]
		,[BASE_EXPORT_ON_TURNAROUND_HOURS]
		,[SPLIT_IMAGE_FILES]
		,[IMPORT_MULT_IMAGE_FILE_DIRECTORY]
		,[COLLECT_IMAGE_SOURCE]
		,[SHOW_IMAGE_SOURCE]
		,[COLLECT_UPIR_ID_FOR_PHYSICIAN_STAFF]
		,[APPLY_PHYSICIAN_SERVICE_MOD_BASED_ON_PAYOR]
		,[SHOW_RECONCILIATION_GRID_ON_AUDIT_REVIEW_PAGE]
		,[ALLOW_CODERS_TO_UPDATE_FACILITY_ADMIN_CHART_ID]
		,[REQUIRE_E849_CODES]
		,[CONDITION_DIAGNOSIS_CODING_ON_DATE_OF_SERVICE]
		,[DIAGNOSIS_CODING_START_DATE_OF_SERVICE]
		,[RATE_METHOD_CD]
		,[CONTRACTOR_RATE_METHOD_CD]
		,[SHOW_PROCEDURE_CLASS_DROPDOWN]
		,[WEEKEND_BONUS_THRESHOLD_COUNT]
		,[WEEKEND_BONUS_AGGREGATE_WITH_SERVICE_AGREEMENT_ID]
		,[REQUIRE_SUTURE_TECH_PROVIDER]
		,[COLLECT_CONDITION_OF_ACCIDENT]
		,[SHOW_SECONDARY_EMPLOYEE_ID_ON_STAFF_PAGE]
		,[SHOW_NO_FACILITY_SERVICES_CHECKBOX]
		,[SHOW_NO_ACTIVITY_CODES_CHECKBOX]
		,[COLLECT_ADMISSION_DATE]
		,[COLLECT_ADMISSION_TIME]
		,[PERFORM_E849_EDITS_WHEN_MVA_ECODES_PRESENT]
		,[ALLOW_ECODE_EXCEPTIONS]
		,[DISPLAY_SEPARATE_NO_IV_FACILITY_PROC_CHECKBOXES]
		,[CONTRACT_START_DATE]
		,[COLLECT_OBSERVATION_ATTENDING_PROVIDER]
		,[DISPLAY_DIAGNOSIS_PAGE_TO_CCS_CODERS]
		,[RECURRING_VISIT_METHOD_ID]
		,[CALC_INITIAL_HOUR_OBS_CHARGES]
		,[DISPLAY_NO_OBSERVATION_HOURS_CHECKBOX]
		,[DISPLAY_GENERIC_NAME_TEXTBOX_ON_INFUSION_INJECTION_PAGE]
		,[REQUIRE_FACILITY_ADMIN_CHART_ID_FOR_OBSERVATION_DISPOSITION]
		,[DISPLAY_INITIAL_DEPARTMENT]
		,[DISPLAY_MODIFIER_27_CHECKBOX]
		,[CALC_OBS_NO_CHARGE_WHEN_NO_OBS_HOURS]
		,[COLLECT_ARRIVAL_DATE]
		,[COLLECT_ARRIVAL_TIME]
		,[COLLECT_TRIAGE_ACUITY]
		,[COLLECT_ARRIVAL_MODE]
		,[DISPLAY_NO_DOCUMENTATION_ISSUES_CHECKBOX_ON_ALL_CHART_PAGES]
		,[COLLECT_DATA_FOR_CORE_MEASURES_REPORTING]
		,[FACILITY_CRITICAL_CARE_CALC_METHOD_DEFAULT_CD]
		,[PHYSICIAN_CRITICAL_CARE_CALC_METHOD_DEFAULT_CD]
		,[SLA_HOURS]
		,[CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE]
		,[PHYSICIAN_SERVICES_START_DATE_OF_SERVICE]
		,[PHYSICIAN_SERVICES_END_DATE_OF_SERVICE]
		,[CONDITION_PHYSICIAN_PROCEDURES_ON_DATE_OF_SERVICE]
		,[PHYSICIAN_PROCEDURES_START_DATE_OF_SERVICE]
		,[PHYSICIAN_PROCEDURES_END_DATE_OF_SERVICE]
		,[DISPLAY_COPY_DIAGNOSIS_CODES_FROM_FACILITY_ACCOUNT_BUTTON]
		,[COPY_DIAGNOSIS_CODES_FROM_FACILITY_ID]
		,[DISPLAY_MANUAL_AUDIT_BUTTON_ON_CHART_PAGES]
		,[ALLOW_E849_CODES_WITH_E930_THRU_E949_CODES]
		,[CONDITION_PHYSICIAN_SERVICES_ON_FINANCIAL_CLASS]
		,[CONDITION_PHYSICIAN_PROCEDURES_ON_FINANCIAL_CLASS]
		,[DISPLAY_OBSERVATION_TELEMETRY_OPTION]
		,[INFUSION_CHARGE_AMOUNTS_UPDATED]
		,[MAX_ARRIVAL_TO_TRIAGE_HOURS]
		,[MAX_TRIAGE_TO_ROOM_HOURS]
		,[MAX_ROOM_TO_MD_HOURS]
		,[INCLUDE_MRN_AS_QA_ELEMENT]
		,[INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT]
		,[INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT]
		,[INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT]
		,[INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT]
		,[INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT]
		,[INCLUDE_PROVIDER_AS_QA_ELEMENT]
		,[INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT]
		,[INCLUDE_GENDER_AS_QA_ELEMENT]
		,[COLLECT_LAST_MENSTRUAL_PERIOD]
		,[LIMIT_OBSERVATION_HOURS_BASED_ON_FINANCIAL_CLASS]
		,[EXPORT_000_FOR_NO_DIAGNOSIS_CODING]
		,[SHOW_COPY_TO_CLIPBOARD_BUTTONS]
		,[APPLY_PHYSICIAN_SERVICE_25_MODIFIER_BASED_ON_PERFORMING_PROVIDER]
		,[ANNUAL_VOLUME]
		,[ASSIGN_CHART_TO_UNASSIGNED_ON_MARK_AS_READY]
		,[SHOW_CODER_COMMENTS_ON_CHARTS_VIEW_PAGE]
		,[EXECUTE_DX_EDITS_WHEN_ENTERED]
		,[IMPORT_ALT_PATIENT_ID_CD]
		,[IMPORT_MRN_IND]
		,[IMPORT_GENDER_IND]
		,[IMPORT_PATIENT_DOB_IND]
		,[IMPORT_PATIENT_AGE_IND]
		,[IMPORT_FINAICIAL_CLASS_IND]
		,[IMPORT_PAYOR_NAME_IND]
		,[IMPORT_TIME_OF_SERVICE_IND]
		,[IMPORT_ATTEND_PHYS_ID_IND]
		,[IMPORT_ATTEND_PHYS_NAME_IND]
		,[IMPORT_FACILITY_PATIENT_DISPO_MAP_ID_IND]
		,[IMPORT_TIME_OF_DISCHARGE_IND]
		,[IMPORT_DATE_RECEIVED_IND]
		,[COLLECT_PAYOR_NAME]
		,[COLLECT_MODE_OF_DEPARTURE]
		,[COLLECT_ORGAN_DONATION]
		,[CHART_ASSIGNMENT_METHOD_ID]
		,[UNASSIGN_CHARTS_BASED_ON_INACTIVITY]
		,[MINUTES_OF_INACTIVITY]
		,[COLLECT_PAYOR]
		,[SHOW_POINTS_COLUMN_ON_FACILITY_SERVICE_PAGE]
		,[PHYSICIAN_SERVICE_GUIDELINE_METHOD]
		,[FORCE_QA_ON_DOWN_CODED_PROFEE]
		,[CORE_MEASURES_METHOD_ID]
		,[DISPLAY_MODIFIER_57_CHECKBOX]
		,[SHOW_ADD_TO_PROCEDURES_CHECKBOX_ON_PROCEDURE_PAGES]
		,[EXCLUDE_OBS_CHARGES_FROM_CHARGE_RECON]
		,[ALLOW_MULTIPLE_PENDING_REASONS]
		,[APPLY_Q6_MODIFIER_BASED_ON_PAYOR]
		,[APPLY_MICHIGAN_PROFEE_MEDICAID_MODIFIERS_BASED_ON_PAYOR]
		,[CALCULATE_OBSERVATION_HOURS]
		,[ALLOW_LOS_1_WITH_PROCEDURE]
		,[REQUIRE_EM_OVERRIDE_WITH_NO_PHYSICIAN_SERVICE]
		,[ORGANIZATION_ID]
		,[PHYSICIAN_SERVICE_PLAN_ID]
		,[SHOW_DO_NOT_APPLY_PHYSICIAN_MODIFIER_25_CHECKBOX]
		,[DISPLAY_GW_MODIFIER_CHECKBOX]
		,[BASE_PHYS_SERVICE_LVL_ON_PAYOR_METHOD]
		,[COLLECT_RESIDENT]
		,[COLLECT_PRIMARY_CARE_PHYSICIAN]
		,[COLLECT_SCRIBE]
		,[COLLECT_SUPERVISING_EMPLOYEE_ID]
		,[USE_PAYOR_CLASS_IND]
		,[ADD_LEADING_ZERO_TO_IMAGE_ACCOUNT_NUMBER_IF_NO_CHART_MATCH]
		,[COLLECT_BILLING_INSTRUCTIONS_IND]
		,[AUTOMATICALLY_APPLY_26_MODIFIER]
		,[AUTOMATICALLY_APPLY_54_MODIFIER_ON_90_DAY_GLOBAL]
		,[EXECUTE_MULTIPLE_MRN_FOR_DATE_OF_SERVICE_EDIT]
		,[GENERATE_DIRECTORY_STRUCTURE_ON_PATIENT_SUMMARY_EXPORT]
		,[REQUIRE_FT1_TRANS_POSTING_DATE_IN_SAME_MONTH_AS_DATE_OF_SERVICE]
		,[BASE_PHYS_SERVICE_LVL_ON_PAYOR_METHOD_EFFECTIVE_DT]
		,[FORCE_DIAGNOSIS_CODE_SELECTION_FOR_ALL_PROCEDURES]
		,[AUTOMATICALLY_ASSIGN_25_57_MODIFIER_TO_99292_IND]
		,[INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND]
		,[REQUIRE_SECONDARY_EMPLOYEE_ID_FOR_ED_ATTENDING_AND_PERFORMING_PROVIDERS]
		,[APPLY_PROCEDURE_S9088_TO_NON_MEDICARE_PATIENTS]
		,[EVALUATE_PHYSICIAN_OBSERVATION]
		,[PHYSICIAN_OBSERVATION_UNIT_TYPE]
		,[PHYSICIAN_ED_OBSERVATION_DOWNCODE_OPTION]
		,[EXPORT_CHIEF_COMPLAINT]
		,[COLLECT_ADMIT_TYPE]
		,[PHYSICIAN_PROCEDURE_PAGE_OPTION]
		,[SHOW_ADD_GC_MODIFIER_CHECKBOX_ON_PHYSICIAN_SERVICE_PAGE]
		,[SHOW_ADD_GE_MODIFIER_CHECKBOX_ON_PHYSICIAN_SERVICE_PAGE]
		,[PHYSICIAN_ED_OBSERVATION_USE_PRICE_INSTEAD_OF_RVU]
		,[FACILITY_CRITICAL_CARE_MINUTES_WARNING]
		,[FACILITY_CRITICAL_CARE_MINUTES_THRESHOLD]
		,[PHYSICIAN_CRITICAL_CARE_MINUTES_WARNING]
		,[PHYSICIAN_CRITICAL_CARE_MINUTES_THRESHOLD]
		,[USE_LEADTOOLS_IMAGE_VIEWER_FOR_PDF_DOCUMENTS]
		,[INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT]
		,[RCP_BILLING_IND]
		,[MIDLEVEL_ONLY_CHECKBOX_DISPLAY_IND]
		,[COLLECT_MEDICAL_EXAMINER_NOTIFIED]
		,[COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR]
		,[APPLY_57_MODIFIER_IF_PROCEDURE_QUALIFIES_90_DAY_GLOBAL]
		,[USE_CMS_DEFINITION_OF_SURGICAL_PROCEDURE]
		,[DISABLE_PHYSICIAN_CCI_EDITS]
		,[SHOW_ADD_24_MODIFIER_CHECKBOX_ON_PHYSICIAN_SERVICE_PAGE]
		,[EXPORT_OBSERVATION_HOUR_CHARGES]
		,[PERFORM_AUTOCOMPLETE_ON_DASHBOARD_CLIENT_NOTES]
		,[DIAGNOSIS_CODING_ICD10_EFFECTIVE_DATE]
		,[INDEX_IMAGES_ACROSS_MULTIPLE_SERVICE_AGREEMENTS]
		,[CALC_SECOND_HOUR_OBS_CHARGES]
		,[CALC_INITIAL_HOUR_OBS_FOR_DIRECT_OBS_PATIENTS]
		,[SHOW_NO_DX_CODING_CHECKBOX_ON_DX_PAGE]
		,[SHOW_ADD_25_MODIFIER_CHECKBOX_ON_PHYSICIAN_SERVICE_PAGE]
		,[SLA_RATE_METHOD_IND]
		,[BASE_LMP_COLLECTION_ON_FINANCIAL_CLASS]
		,[DISPLAY_LMP_DATE_NOT_AVAILABLE_CHECKBOX]
		,[DIAGNOSIS_CODING_ICD10_EXPIRATION_DATE]
		,[EXPORT_ICD10_AND_ICD9_EFFECTIVE_DATE]
		,[EXPORT_ICD10_AND_ICD9_EXPIRATION_DATE]
		,[EXPORT_ICD10_ONLY_EFFECTIVE_DATE]
		,[EXPORT_ICD10_ONLY_EXPIRATION_DATE]
		,[CONDITION_OF_ACCIDENT_COLLECTION_METHOD]
		,[APPLY_MODIFIER_25_TO_99053]
		,[ALLOW_SINGLE_MODERATE_MDM_OPTION]
		,[SINGLE_MODERATE_MDM_OPTION_EFFECTIVE_DATE]
		,[SINGLE_MODERATE_MDM_OPTION_EXPIRATION_DATE]
		,[COLLECT_ICD10_DOCUMENTATION_SCORING]
		,[ICD_10_PCS_EFFECTIVE_DATE]
		,[FACILITY_PROCEDURE_PAGE_OPTION]
		,[SHOW_PRACTICE_DROPDOWN_ON_DASHBOARD_PAGE]
		,[CALC_CHEMO_CONCURRENT_INFUSIONS]
		,[CODER_NOTES_ON_DEMOGRAPHICS_PAGE_OPTION]
		,[CODER_NOTES_ON_DEMOGRAPHICS_PAGE_SEPARATE_NOTES_EFFECTIVE_DATE]
		,[CODER_NOTES_ON_DEMOGRAPHICS_PAGE_SEPARATE_NOTES_EXPIRATION_DATE]
		,[DIAGNOSIS_CODE_INPATIENTS_BASED_ON_FINANCIAL_CLASS]
		,[DISPLAY_PATIENT_CLASS_ON_CHARTS_PAGE]
		,[INFUSION_INJECTION_PAGE_OPTION]
		,[ENABLE_PACKAGE_EVENTS]
		,[ADD_FACILITY_MODIFIER_25_TO_99292_IND]
		,[SHOW_DISCHARGE_DATE_ON_CHARTS_INDEX]
		,[CONDITION_OBS_CHARGING_ON_DOS]
		,[OBS_START_DOS]
		,[OBS_END_DOS]
		,[EXCLUDE_FROM_SECOND_AUDIT_IF_PENDED_BY_CODER]
		,[ICD10_REQUIRE_EXTERNAL_CAUSE_CODE]
		,[ICD10_REQUIRE_MECHANISM_OF_INJURY_CODE]
		,[ICD10_REQUIRE_PLACE_OF_OCCURRENCE_CODE]
		,[ICD10_REQUIRE_ACTIVITY_CODE]
		,[ICD10_REQUIRE_EXTERNAL_CAUSE_STATUS]
		,[EXPORT_DIAGNOSIS_CODE_ADJUSTMENTS]
		,[ENABLE_FRACTURE_CARE_DIAGNOSIS_EDITS]
		,[INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT]
		,[INCLUDE_DOB_AS_QA_ELEMENT]
		,[INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT]
		,[INCLUDE_DOS_AS_QA_ELEMENT]
		,[INCLUDE_DISPOSITION_AS_QA_ELEMENT]
		,[INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT]
		,[INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT]
		,[INCLUDE_COA_AS_QA_ELEMENT]
		,[INCLUDE_CLINIC_AS_QA_ELEMENT]
		,[INCLUDE_ATTESTATION_AS_QA_ELEMENT]
		,[INCLUDE_SCRIBE_AS_QA_ELEMENT]
		,[INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT]
		,[INCLUDE_LMP_AS_QA_ELEMENT]
		,[INCLUDE_RESIDENT_AS_QA_ELEMENT]
		,[INCLUDE_AGE_AS_QA_ELEMENT]
		,[INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT]
		,[INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT]
		,[INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT]
		,[INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT]
		,[INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT]
		,[ENABLE_POC_ADVERSE_REACTION_TO_MEDS_EDIT]
		,[ENABLE_POC_SUICIDE_ATTEMPT_EDIT]
		,[ENABLE_POC_MISADVENTURES_EDIT]
		,[DISABLE_MEDI_CAL_DIAGNOSIS_LIMIT]
		,[DISABLE_MEDI_CAL_MANAGED_CARE_DIAGNOSIS_LIMIT]
		,[ENABLE_POC_FIGHT_ASSAULT_RAPE_EDIT]
		,[ENABLE_POC_INJURY_DUE_TO_LEGAL_INT_EDIT]
		,[ENABLE_CLINIC_PAYOR_RULES]
		,[COLLECT_TRANSFER_FACILITY]
		,[ALLOW_TOGGLE_BETWEEN_95_AND_97_GUIDELINES]
		,[ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE]
		,[PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_LIST]
		,[DISABLE_ACTIVITY_CODES]
		,[EXPORT_ICD9_VOL3_EXPIRATION_DATE]
		,[CDI_EVALUATION_METHOD]
		,[APPLY_UA_MOD_TO_SURGICAL_FAC_PROCS_BASED_ON_PAYOR]
		,[ICD10_PCS_COLLECTION_METHOD_CD]
		,[ATHENA_PRACTICE_ID]
		,[EXPORT_ICD10_CODE_Y92_9]
		,[EXPORT_ICD10_CODE_Y93_9]
		,[EXPORT_ICD10_CODE_Y99_9]
		,[COLLECT_OBSERVATION_ARRIVAL_SOURCE]
		,[USE_INPATIENT_PHYSICIAN_SERVICE_PAGE]
		,[DIAGNOSIS_CODING_END_DATE_OF_SERVICE]
		,[INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT]
		,[ICD10_INCLUDE_POC_AND_ACTIVITY_CODES_FOR_TOXIC_EFFECT]
		,[DISPLAY_ADD_59_XU_MODIFIER]
		,[ENABLE_SEARCH_FOR_ED_ATTENDING_PROVIDER]
		,[SUPPLIES_DISPLAY_INSUFFICIENT_DOC_TO_BILL_CHECKBOX]
		,[REQUIRE_GENERIC_NAME_FOR_OBS_CHARTS]
		,[SHOW_INIT_DEPT_ONLY_ON_INF_INJ_AND_PROC_PAGES]
		,[SHOW_INITIAL_OBS_DEPT_DROPDOWN]
		,[ENABLE_ANESTHESIA_CALCULATOR]
		,[CHARGE_SURGICAL_PROCEDURES_FROM_ANESTHESIA_CALCULATOR]
		,[SHOW_PHYSICIAN_NAME]
		,[COLLECT_PREVENTATIVE_MEDICINE_CODES]
		,[ENABLE_SEARCH_FOR_MIDLEVEL_PROVIDER]
		,[ATHENA_SUBTRACT_NUMBER_OF_DAYS_FOR_IMPORT]
		,[DISABLE_ANESTHESIA_PHYSICAL_STATUS]
		,[DISABLE_ANESTHESIA_QUALIFYING_CIRCUMSTANCES]
		,[ATHENA_USE_FACILITY_ADMIN_CHART_ID_AS_ATHENA_ID]
		,[SEPARATE_POINT_ITEM_SECTIONS]
		,[DISPLAY_MODIFIER_AG_CHECKBOX]
		,[DISPLAY_MODIFIER_AF_CHECKBOX]
		,[ALLOW_MULTIPLE_PHYSICIAN_LEVELS]
		,[MAXIMUM_NUMBER_OF_PHYSICIAN_LEVELS]
		,[DISPLAY_CLIENT_NOTES_ON_CHARTS_PAGE]
		,[USE_MOVE_TO_PENDING_ANESTHESIA_REVIEW_WORKFLOW]
		,[COLLECT_SEPARATE_DIAGNOSIS_CODES_FOR_MULTIPLE_PHYSICIAN_LEVELS]
		,[DEFAULT_DIAGNOSIS_CODES_FROM_FIRST_PHYSICIAN_LEVEL]
		,[DISPLAY_MODIFIER_AI_CHECKBOX]
		,[ENABLE_SURGICAL_SYSTEM_PICKLISTS_FOR_FACILITY_PROCEDURES]
		,[ENABLE_SURGICAL_SYSTEM_PICKLISTS_FOR_PHYSICIAN_PROCEDURES]
		,[ATHENA_END_SUBTRACT_NUMBER_OF_DAYS_FOR_IMPORT]
		,[REQUIRE_INITIALS_FOR_NO_STOP_TIME_INFUSIONS]
		,[SHOW_BILL_DAYS_ON_CHARTS_VIEW_PAGE]
		,[BILL_DATE_DAYS_INPATIENT]
		,[BILL_DATE_DAYS_OBSERVATION]
		,[BILL_DATE_DAYS_SENT_HOME]
		,[SHOW_OBS_ARRIVAL_SOURCE_ON_CHARTS_VIEW_PAGE]
		--,[ENABLE_DENIAL_MANAGEMENT]							-- 20231009 - bugfix
		,[FACILITY_NPI]
		,[REQUIRE_DISPOSITION_WHEN_PENDING_CHART]
		,[REQUIRE_GENERIC_NAME_FOR_NON_OBS_CHARTS]
		,[SHOW_DO_NOT_APPLY_FACILITY_MODIFIER_25_CHECKBOX]
		,[ANESTHESIA_FIELD_AVOIDANCE_OPTION]
		,[DISPLAY_MODIFIER_CG_CHECKBOX]
		,[SHOW_FACILITY_ADMIN_CHART_ID]
		,[CLEAR_PENDING_REASON_ON_MOVE_TO_WIP]
		,[FACILITY_LOGIN_URL]
		,[ALLOW_CHARTS_WITH_OVERRIDE_LCD_ERRORS_TO_BE_AUTO_APPROVED]
		,[DISPLAY_MODIFIER_GQ_CHECKBOX]
		,[DISPLAY_MODIFIER_GT_CHECKBOX]
		,[DISPLAY_MODIFIER_G0_CHECKBOX]
		,[DISPLAY_MODIFIER_95_CHECKBOX]
		,[ENABLE_CS_MODIFIER]
		,[ENABLE_MULTIPLE_DX_CODES_ON_PROCEDURES]
		,[ANESTHESIA_ADDL_DOS_NON_OBS]
		,[ANESTHESIA_ADDL_DOS_OBS]
		,[DISPLAY_FACILITY_LOS_MODIFIER_95_CHECKBOX]
		,[DISPLAY_MULT_COLUMNS_ON_FLOS_PAGE]
		,[ENABLE_CR_MODIFIER]
		,[INCLUDE_MIPS_MEASURES_IN_MEDICAL_NECESSITY_GRID]
		,[ENABLE_BULK_DIAGNOSIS_CODE_ENTRY]
		,[COLLECT_DENIAL_PAYOR_CLAIM_NUMBER]			
		,[COLLECT_DENIAL_PAYOR_PATIENT_INSURED_RELATIONSHIP_TYPE]			
		,[COLLECT_DENIAL_PAYOR_POLICY_HOLDER_FIRST_NAME]			
		,[COLLECT_DENIAL_PAYOR_POLICY_HOLDER_LAST_NAME]			
		,[COLLECT_DENIAL_PAYOR_POLICE_HOLDER_DATE_OF_BIRTH]			
		,[USE_2021_GUIDELINES_FOR_CLINIC]
		,[USE_2021_GUIDELINES_EFFECTIVE_DATE]
		,[ARTICLES_EFFECTIVE_DATE]
		,[SHOW_BULK_CPT_SEARCH_ON_PROCS_PAGES]
		,[SHOW_PROC_BILLING_CODES_IN_CHART_OVERVIEW]
		,[DISPLAY_MODIFIER_GV_CHECKBOX]
		,[DISPLAY_PROVIDER_TYPE_CREDENTIALS]
		,[DISPLAY_MODIFIER_EP_CHECKBOX]
		,[DO_NOT_ALLOW_EXTERNAL_CAUSE_CODES]
		,[SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN]
		,[SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EFFECTIVE_DATE]
		,[SHOW_PROVIDER_SPECIFIED_LOS_DROPDOWN_EXPIRATION_DATE]
		,[OVERRIDE_BASIC_USER_TO_EXPERT]
		,[OVERRIDE_BASIC_USER_TO_EXPERT_EFFECTIVE_DATE]
		,[OVERRIDE_BASIC_USER_TO_EXPERT_EXPIRATION_DATE]
		,[BYPASS_ANESTHESIA_PROVIDER_MODIFIER_EDITS]
		,[DO_NOT_COLLECT_FACILITY_PROCEDURES_FOR_INPATIENTS]
		,[SHOW_WARNING_ON_FACILITY_PROC_PAGE_FOR_OBSERVATION_DISPOSITION]
		,[DELETE_EXISTING_CHART_IMAGES_WHEN_IMPORTING_NEW_IMAGE]
		,[COLLECT_DATE_TIME_OF_DEATH]
		,[COLLECT_FACILITY_PROCEDURE_TIME]
		,[DISPLAY_PHYSICIAN_MODIFIER_AF_CHECKBOX]
		,[DISPLAY_PHYSICIAN_MODIFIER_AG_CHECKBOX]
		,[OBSERVATION_HOURS_EXPORT_METHOD_ID]
		,[VALIDATE_DATE_OF_SERVICE_AGAINST_DISCHARGE_DATE]
		,[ALLOW_ADJUSTMENT_PERFORMING_PROVIDER]
		,[SHOW_FACILITY_PATIENT_DISPOSITION_ON_CHART_ADJUSTMENTS_PAGE]
		,[FORCE_DIAGNOSTIC_CODE_SELECTION_FOR_PHYSICIAN_SERVICES]
		,[DISPLAY_PHYSICIAN_MODIFIER_AM_CHECKBOX]
		,[DISPLAY_PHYSICIAN_MODIFIER_U7_CHECKBOX]
		,[DISPLAY_FACILITY_MODIFIER_32_CHECKBOX]
		,[SHOW_PROVIDER_SPECIFIED_PROCEDURES_LINK]
		,[SHOW_PROVIDER_SPECIFIED_PROCEDURES_LINK_EFFECTIVE_DATE]
		,[SHOW_PROVIDER_SPECIFIED_PROCEDURES_LINK_EXPIRATION_DATE]
		,[DISPLAY_PHYSICIAN_MODIFIER_SA_CHECKBOX]
		,[AUTOMATION_CODING_ENABLED]
		,[USE_MDM_2023_GUIDELINES]
		,[USE_MDM_2023_GUIDELINES_EFFECTIVE_DATE]
		,[SHOW_FACILITY_PATIENT_CLASS_ON_CHART_ADJUSTMENTS_PAGE]
		,[DISPLAY_MODIFIER_25_CHECKBOX]
		,[HIGHLIGHT_LAST_CHANGED_DATE_OVER_24_HOURS]
		,[SHOW_AGED_ACCOUNTS_IN_ORANGE]
		,[DISPLAY_MODIFIER_93_CHECKBOX]					-- added DACS-2475 - 20230619 - pippin
		,[DISPLAY_FACILITY_LOS_MODIFIER_93_CHECKBOX]	-- added DACS-2475 - 20230619 - pippin
		,[DISPLAY_MODIFIER_FS_CHECKBOX]					-- added DACS-2485 - 20230626 - pippin
		,[EXPORT_PROCEDURE_ADJUSTMENTS]					-- added DACS-2557 - 20230717 - dillon
		,[REQUIRE_PHYSICIAN_WHEN_PENDING_CHART]			-- added DACS-2737 - 20230918 - pippin
FROM	[dbo].[SERVICE_AGREEMENT] WITH (NOLOCK)
WHERE [SERVICE_AGREEMENT_ID] = @SERVICE_AGREEMENT_ID;

GO


-- End of 01) DACS-2802 - ALTER PROCEDURE - [dbo].[SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID].SQL
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
