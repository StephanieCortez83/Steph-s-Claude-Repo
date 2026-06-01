USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of Kelvin6.0Scripts.sql

SET XACT_ABORT ON;

-- Start of Kelvin6.0Scripts.sql

-- End of Kelvin6.0Scripts.sql
GO

-- Start of 01) DACS-3591 - Create or Alter Stored Procedure - [dbo].[spRemoveInapplicablePqrs].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3591 - Create or Alter Stored Procedure - [dbo].[spRemoveInapplicablePqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spRemoveInapplicablePqrs', @DestProc = 'spRemoveInapplicablePqrs_DACS-3591';
GO


CREATE OR ALTER PROCEDURE [dbo].[spRemoveInapplicablePqrs]
	@ChartId INT
WITH EXEC AS CALLER
AS
BEGIN
	DECLARE @chart_id INT=@ChartId;

	DECLARE @RequiredMeasures TABLE
	(
	   [CMS_PQRI_MEASURE_ID] INT
	  ,[MEASURE_TITLE] VARCHAR(2000)		-- DACS-3591, pippin -- increased column width to 2000 (original = 500)
	  ,[CMS_PQRI_MEASURE_CODE_ID] INT
	  ,[CODING_SYSTEM] VARCHAR(20)
	  ,[OPTION_GROUP] NUMERIC(18,0)
	  ,[CODE] VARCHAR(20)
	  ,[MODIFIER] VARCHAR(20)
	  ,[DESCRIPTION] VARCHAR(500)
	  ,[END_DATE] DATE
	  ,[CODE_2] VARCHAR(6)
	  ,[MODIFIER_2] VARCHAR(20)
	  ,[ROW_NUMBER] BIGINT
	)
	------------------------------------------------------------------------------------
	-- DACS-3591, pippin -- formatting adjusted for improved readibility
	------------------------------------------------------------------------------------

	-- Populate the table variable with values returned from spSelectChartPQRS
	INSERT INTO @RequiredMeasures(
		 [CMS_PQRI_MEASURE_ID]
		,[MEASURE_TITLE]
		,[CMS_PQRI_MEASURE_CODE_ID]
		,[CODING_SYSTEM]
		,[OPTION_GROUP]
		,[CODE]
		,[MODIFIER]
		,[DESCRIPTION]
		,[END_DATE]
		,[CODE_2]
		,[MODIFIER_2]
		,[ROW_NUMBER]
		)
	  EXEC [spSelectChartPQRS] @ChartId=@chart_id

	-- Delete the PQRS items from PHYSICIAN_PROCEDURE_EVALUATION that are inapplicable to this chart
	DELETE 
		[PHYSICIAN_PROCEDURE_EVALUATION]
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID]=ppe.[PHYSICIAN_PROCEDURE_ID]
	WHERE 
		[CHART_ID]=@chart_id
		AND cm.[CHARGE_MASTER_USAGE_CODE]=9
		AND cm.[CPT_CODE] NOT IN (
			SELECT 
				cpmc.[CODE] 
			FROM 
				@RequiredMeasures rm
				JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID]=rm.[CMS_PQRI_MEASURE_ID]
			WHERE 
				cpmc.[CODING_SYSTEM] IN ('CPT_II', 'HCPCS')
				AND cpmc.[CODE]=cm.[CPT_CODE]
				AND ppe.[MODIFIERS] LIKE ISNULL('%' + cpmc.[MODIFIER] + '%', '')
			)
		AND cm.[CPT_CODE] NOT IN (
			SELECT 
				cpmc.[CODE_2] 
			FROM 
				@RequiredMeasures rm
				JOIN [CMS_PQRI_MEASURE_CODE] cpmc on cpmc.[CMS_PQRI_MEASURE_ID]=rm.[CMS_PQRI_MEASURE_ID]
			WHERE 
				cpmc.[CODING_SYSTEM] IN ('CPT_II', 'HCPCS')
				AND cpmc.[CODE_2]=cm.[CPT_CODE]
				AND ppe.[MODIFIERS] LIKE ISNULL('%' + cpmc.[MODIFIER] + '%', '')
			)
END; -- end SPROC
GO


-- End of 01) DACS-3591 - Create or Alter Stored Procedure - [dbo].[spRemoveInapplicablePqrs].SQL
GO

-- Start of 01) DACS-3592 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3592 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'AreAny2024MipsRuleSatisfiedByChart', @DestProc = 'AreAny2024MipsRuleSatisfiedByChart_DACS-3592';
GO

CREATE OR ALTER PROCEDURE [dbo].[AreAny2024MipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad ChartId ' = @ChartId;
		RETURN;
	END;
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @serviceAgreementId INT;
	DECLARE @dateOfService DATETIME;
	
	SELECT 
		 @serviceAgreementId = [SERVICE_AGREEMENT_ID]
		,@dateOfService = [TIME_OF_SERVICE]
	FROM 
		[dbo].[chart] 
	WHERE
		[CHART_ID] = @ChartId;

	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0 OR @dateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;

	PRINT('serviceAgreementId = ' + CAST(@serviceAgreementId AS VARCHAR(64)));
	PRINT('dateOfService = ' + CAST(@dateOfService AS VARCHAR(64)));

	
	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@serviceAgreementId, @Dos=@dateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @countSaMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- load our single criteria MIPS for testing
	-----------------------------------
	DECLARE @active2024MipsRules1CTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRules1CTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
	;
	
	IF @TestAll <> 1 DELETE FROM @active2024MipsRules1CTable WHERE [NAME] NOT IN (SELECT [NAME] FROM @activeSAMipsRulesTable);

	DECLARE @count1CMips INT = (SELECT COUNT(*) FROM @active2024MipsRules1CTable);
	IF @count1CMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No 2024 1 criteria Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT '@count1CMips = ' = @count1CMips;
	IF @ShowDebug = 1 SELECT * FROM @active2024MipsRules1CTable;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = @count1CMips;

	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchResultsTable TABLE ( [RESULT] VARCHAR(32), [QUESTION] VARCHAR(1024), [CODE] VARCHAR(32));
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [NAME] FROM @active2024MipsRules1CTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NOT NULL 
		BEGIN
			DELETE FROM @FetchResultsTable;
			
			DECLARE @SQL NVARCHAR(512) = N'EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type' + REPLACE(@FetchMipsName,'-','') + '] @ChartId=@fCId,@PqrsNum=@fPqrs,@Dos=@fDos;';
			DECLARE @ParmDefinition NVARCHAR(512) = N'@fCId INT, @fPqrs VARCHAR(32), @fDos DATETIME';

			IF @ShowDebug = 1 PRINT('  --> @SQL = ' + @SQL);

			INSERT INTO 
				@FetchResultsTable
			EXEC sp_executesql @SQL, @ParmDefinition, @fCId=@ChartId, @fPqrs=@FetchMipsName, @fDos=@dateOfService;			

			IF @ShowDebug = 1 SELECT * FROM @FetchResultsTable;

			IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
			BEGIN
				IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @FetchMipsName;

				IF @TestAll <> 1 
				BEGIN 
				-- cleanup our cursor
					CLOSE cursorTempRows;  
					DEALLOCATE cursorTempRows; 
				END;

				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				IF @TestAll <> 1 RETURN;
			END;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	-----------------------------------
	-- load our dual criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '005') OR @TestAll = 1
	BEGIN
		PRINT('Processing: 005-A');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A @ChartId=@ChartId,@PqrsNum='005-A',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='005-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		PRINT('-------------------');		
		PRINT('Processing: 005-B');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B @ChartId=@ChartId,@PqrsNum='005-B',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '005-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '008') OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: 008-A');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A @ChartId=@ChartId,@PqrsNum='008-A',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='008-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		PRINT('-------------------');		
		PRINT('Processing: 008-B');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B @ChartId=@ChartId,@PqrsNum='008-B',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '008-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	-----------------------------------
	-- load our PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	DECLARE @MipsNameToTest VARCHAR(32) = 'PQRANES1';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP60';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP61';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP64';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'HCPR24';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeHCPR24 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;


	-----------------------------------
	-- all done
	-----------------------------------
	PRINT('-------------------');		
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;
END; -- end of SPROC

GO

/*
EXEC [dbo].AreAny2024MipsRuleSatisfiedByChart @ChartId=2100113944,@ShowDebug=1,@TestAll=1; -- tests PQRANES1

*/
-- End of 01) DACS-3592 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
GO

-- Start of 01) DACS-3533 - ALTER TABLE Chart.sql

------------------------------------------------------------------------------------
-- 01) DACS-3533 - ALTER Table to add a new column
------------------------------------------------------------------------------------
GO

GO

GO

ALTER TABLE [dbo].[CHART] 
ADD NO_PQRS BIT NULL
-- End of 01) DACS-3533 - ALTER TABLE Chart.sql
GO

-- Start of 02) DACS-3533 - ALTER STORED PROC CHART_SELECT_BY_CHART_ID.sql

------------------------------------------------------------------------------------
-- 02) DACS-3533 - ALTER PROCEDURE [CHART_SELECT_BY_CHART_ID] to add NO_PQRS column to selection list
------------------------------------------------------------------------------------
GO

GO

GO


ALTER PROCEDURE [dbo].[CHART_SELECT_BY_CHART_ID]    
 @CHART_ID INT    
AS    
BEGIN    
 IF @CHART_ID IS NULL OR @CHART_ID <= 0    
 BEGIN    
  PRINT('@CHART_ID is invalid.');    
  RETURN;    
 END;    
    
 SET NOCOUNT ON    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
      
 SELECT TOP 1 -- this is a just in case safety item, do not remove. -- added DACS-3159 -- 20240412 -- pippin    
   [CHART_ID]    
  ,[SERVICE_AGREEMENT_ID]    
  ,[FACILITY_ID]    
  ,[FACILITY_CHART_ID]    
  ,[FACILITY_ADMIN_CHART_ID]    
  ,[MEDICAL_RECORD_NUM]    
  ,[PATIENT_TITLE]    
  ,[PATIENT_FIRST_NAME]    
  ,[PATIENT_MIDDLE_NAME]    
  ,[PATIENT_LAST_NAME]    
  ,[PATIENT_NAME_SUFFIX]    
  ,[PATIENT_ADDR_LINE_1]    
  ,[PATIENT_ADDR_LINE_2]    
  ,[PATIENT_CITY]    
  ,[PATIENT_STATE]    
  ,[PATIENT_ZIPCODE]    
  ,[PATIENT_DOB]    
  ,[TIME_OF_SERVICE]    
  ,[TIME_TO_ROOM]    
  ,[TIME_OF_PHYS_EVAL]    
  ,[TIME_OF_PHYS_DIS]    
  ,[TIME_OF_TRIAGE]    
  ,[TIME_OF_DIS]    
  ,[PHYSICIAN_ID]    
  ,[TRIAGE_NURSE_ID]    
  ,[DIS_NURSE_ID]    
  ,[DATE_RECEIVED]    
  ,[ASSIGNED_TO_ID]    
  ,[CHART_STATUS_ID]    
  ,[PENDING_REASON_ID]    
  ,[CODER_COMMENT]    
  ,[FAC_SVCS_COMPLETED]    
  ,[FAC_PROC_COMPLETED]    
  ,[PHYS_COMPLETED]    
  ,[PHYS_PROC_COMPLETED]    
  ,[PREBILL_AUDIT_COMPLETED]    
  ,[DEMOGRAPHICS_COMPLETED]    
  ,[RESULTS_COMPLETED]    
  ,[INFUSIONS_COMPLETED]    
  ,[FACILITY_CRITICAL_CARE]    
  ,[FACILITY_CRITICAL_CARE_MINUTES]    
  ,[PHYSICIAN_CRITICAL_CARE]    
  ,[PHYSICIAN_CRITICAL_CARE_MINUTES]    
  ,[FACILITY_LEVEL_ID]    
  ,[OVERRIDE_FACILITY_LEVEL_ID]    
  ,[PATIENT_DISPOSITION_ID]    
  ,[PHYSICIAN_HISTORY_ID]    
  ,[PHYSICIAN_EXAM_ID]    
  ,[PHYSICIAN_MDM_ID]    
  ,[PHYSICIAN_SERVICE_PROC_ID]    
  ,[PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID]    
  ,[OVERRIDE_PHYS_HIST_ID]    
  ,[OVERRIDE_PHYS_EXAM_ID]    
  ,[OVERRIDE_PHYS_MDM_ID]    
  ,[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]    
  ,[PHYSICIAN_SERVICE_MOD]    
  ,[COMPLETED_BY_USER_PROFILE_ID]    
  ,[APPROVED_BY_USER_PROFILE_ID]    
  ,[SENT_BY_USER_PROFILE_ID]    
  ,[COMPLETION_DATE]    
  ,[APPROVED_DATE]    
  ,[SENT_DATE]    
  ,[NON_ER_PROCEDURES_OVERRIDE]    
  ,[NO_FACILITY_SERVICES]    
  ,[NO_FACILITY_PROCEDURES]    
  ,[NO_PHYSICIAN_SERVICES]    
  ,[NO_PHYSICIAN_PROCEDURES]    
  ,[NO_PREBILL_AUDIT]    
  ,[NO_INJECTIONS_OR_INFUSIONS]    
  ,[EDITED_BY_EXPERT]    
  ,[NUMBER_OF_IV_PUSHES]    
  ,[IMAGES_AVAILABLE]    
  ,[DIAGNOSIS_CODING_COMPLETE]    
  ,[NO_DIAGNOSIS_CODING]    
  ,[CHIEF_COMPLAINT]    
  ,[PATIENT_CLASS_ID]    
  ,[PATIENT_CLASS_CD]    
  ,[INSUFFICIENT_PHYSICIAN_PROCEDURE_DOC]    
  ,[INSUFFICIENT_PHYSICIAN_PROCEDURE_REASON_ID]    
  ,[CLIENT_COMMENT]    
  ,[CHART_IMAGES_TRANSMITTED]    
  ,[FINANCIAL_CLASS_CD]    
  ,[DOCUMENTATION_COMPLETED]    
  ,[DOCUMENTATION_EVALUATION_OK]    
  ,[RESIDENT_ID]    
  ,[DEPARTMENT]    
  ,[LONG_PATIENT_ID1]    
  ,[LONG_PATIENT_ID2]    
  ,[NUMBER_OF_IV_PUSHES_SAME_SUB]    
  ,[APPROVAL_REASON_CODE]    
  ,[PRIMARY_COMPLAINT]    
  ,[PATIENT_DISPOSITION_MAP_ID]    
  ,[HORMONAL]    
  ,[NON_HORMONAL]    
  ,[INTERLESIONAL_7_OR_LESS]    
  ,[INTERLESIONAL_MORE_THAN_7]    
  ,[NUMBER_CHEMOTHERAPY_IV_PUSH]    
  ,[PROLONGED_IV_CHEMOTHERAPY]    
  ,[PROLONGED_IA_CHEMOTHERAPY]    
  ,[ADDITIONAL_CRITICAL_CARE_UNITS]    
  ,[SUPPLIES_COMPLETED]    
  ,[NO_SUPPLIES]    
  ,[ADDITIONAL_COMPLAINT]    
  ,[ADDITIONAL_COMPLAINT2]    
  ,[GENDER]    
  ,[HOSPITAL_POINTS]    
  ,[HOSPITAL_CHIEF_COMPLAINT]    
  ,[APPEARS_TO_QUALIFY_FOR_CRITICAL_CARE]    
  ,[SERVICES_PERFORMED_BY_RESIDENT]    
  ,[RESIDENT_PHYS_PRESENT]    
  ,[RESIDENT_PHYS_PRESENT_REF_RES_NOTES]    
  ,[RESIDENT_PHYS_PRESENT_DISCUSSED_PLAN]    
  ,[RESIDENT_PHYS_INDEPENDENT_REF_RES_NOTES]    
  ,[RESIDENT_PHYS_INDEPENDENT_PERSONALLY_SAW]    
  ,[RESIDENT_PHYS_INDEPENDENT_DISCUSSED]    
  ,[RESIDENT_CPT_ENTIRELY_PRESENT]    
  ,[RESIDENT_CPT_PRESENT_DURING_KEY_PORTION]    
  ,[FACILITY_LEVEL_CODER_COMMENT]    
  ,[CREATION_DATE_TIME]    
  ,[CREATING_USER_PROFILE_ID]    
  ,[CHANGED_DATE_TIME]    
  ,[CHANGING_USER_PROFILE_ID]    
  ,[OVERRIDE_LCD_ERRORS]    
  ,[EVER_COMPLETED]    
  ,[LAST_ENCOUNTER_DATE]    
  ,[SAFETY_DEVICE_CD]    
  ,[SPORT_TYPE_CD]    
  ,[RESIDENT_PARTICIPATED_IN_CARE]    
  ,[ATTESTATION_SIGNED_BY_ATTENDING]    
  ,[REPORT_CHIEF_COMPLAINT_AS_SECONDARY]    
  ,[REPORT_ADDITIONAL_COMPLAINT_AS_SECONDARY]    
  ,[REPORT_ADDITIONAL_COMPLAINT2_AS_SECONDARY]    
  ,[PATIENT_AGE]    
  ,[START_QA_USER_PROFILE_ID]    
  ,[START_QA_DATE]    
  ,[PHYSICIAN_SIGNATURE_PRESENT]    
  ,[OBS_DEPT_EVAL_COMPLETED]    
  ,[INITIAL_CHARGE_MASTER_DEPT_ID]    
  ,[PHYSICIAN_LEVEL_CODER_COMMENT]    
  ,[EXCLUDE_OBSERVATION_DIRECT_CHARGE]    
  ,[NURSE_PRACTITIONER_ID]    
  ,[ADD_MODIFIER_32_TO_PHYSICIAN_LOS]    
  ,[NO_PHYSICIAN_LOS_REASON_ID]    
  ,[CLINIC_ID]    
  ,[SERIAL_CODE]    
  ,[REGISTRATION_AREA]    
  ,[REGISTRATION_CODE]    
  ,[SERVICE_LINE_ID]    
  ,[TERMINAL_DIGITS]    
  ,[IMAGE_SOURCE_ID]    
  ,[PAYOR_CD]    
  ,[POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE]    
  ,[IS_PRIORITY]    
  ,[NO_ACTIVITY_CODES]    
  ,[NO_LCD_SERVICES]    
  ,[MODIFIER_25_REQUIRED_REASON_ID]    
  ,[CONDITION_OF_ACCIDENT_ID]    
  ,[ACCIDENT_DATE]    
  ,[ADMISSION_DATE_TIME]    
  ,[OBSERVATION_ATTENDING_PROVIDER_ID]    
  ,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]    
  ,[PATIENT_DISPOSITION_DESTINATION_ID]    
  ,[NO_OBSERVATION_HOURS]    
  ,[OBSERVATION_COMPLETED_BY_USER_PROFILE_ID]    
  ,[OBSERVATION_COMPLETION_DTTM]    
  ,[OBSERVATION_PROCEDURES_AUDIT_COMMENT]    
  ,[OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT]    
  ,[OBSERVATION_AUDITOR_REVIEW_FEEDBACK]    
  ,[FACILITY_LOS_27_MODIFIER]    
  ,[OBSERVATION_BILLING_METHOD_CD]    
  ,[ARRIVAL_DATE_TIME]    
  ,[SERVICE_AGREEMENT_TRIAGE_ACUITY_ID]    
  ,[SERVICE_AGREEMENT_ARRIVAL_MODE_ID]    
  ,[FACILITY_CRITICAL_CARE_CALC_METHOD_CD]    
  ,[FACILITY_CRITICAL_CARE_START_DATE]    
  ,[FACILITY_CRITICAL_CARE_STOP_DATE]    
  ,[PHYSICIAN_CRITICAL_CARE_CALC_METHOD_CD]    
  ,[PHYSICIAN_CRITICAL_CARE_START_DATE]    
  ,[PHYSICIAN_CRITICAL_CARE_STOP_DATE]    
  ,[AUDIT_REQUIRED]    
  ,[ARRIVAL_DATE_TIME_NOT_AVAILABLE]    
  ,[TIME_OF_TRIAGE_NOT_AVAILABLE]    
  ,[TIME_TO_ROOM_NOT_AVAILABLE]    
  ,[TIME_OF_PHYSICIAN_EVAL_NOT_AVAILABLE]    
  ,[ARRIVAL_MODE_NOT_AVAILABLE]    
  ,[TRIAGE_ACUITY_NOT_AVAILABLE]    
  ,[OBSERVATION_TELEMETRY]    
  ,[DEMOGRAPHIC_AUDIT_COMMENT]    
  ,[LAST_MENSTRUAL_PERIOD]    
  ,[PAYOR_NAME]    
  ,[SERVICE_AGREEMENT_MODE_OF_DEPARTURE_ID]    
  ,[ORGAN_DONATION]    
  ,[REASON_FOR_VISIT_CATEGORY_DETAIL_ID]    
  ,[ADD_MODIFIER_57_TO_PHYSICIAN_LOS]    
  ,[DO_NOT_APPLY_PHYSICIAN_MODIFER_25]    
  ,[ADD_MODIFIER_GW_TO_PHYSICIAN_LOS]    
  ,[PRIMARY_CARE_PHYSICIAN_ID]    
  ,[SCRIBE_ID]    
  ,[NO_ATTENDING_PROVIDER_SELECTED_IND]    
  ,[PROVIDER_EVAL_PERFORMED_BY_IND]    
  ,[BILLING_INSTRUCTIONS]    
  ,[PHYSICIAN_SERVICE_OBSERVATION_ADMIT_DATETIME]    
  ,[PHYSICIAN_SERVICE_OBSERVATION_DISCHARGE_DATETIME]    
  ,[PHYSICIAN_SERVICE_OBSERVATION_FINAL_EXAM]    
  ,[SUBSEQUENT_VISIT_CODE]    
  ,[SERVICE_AGREEMENT_ADMIT_TYPE_ID]    
  ,[LOCATION_CODE]    
  ,[BILLING_AREA]    
  ,[ADD_GC_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]    
  ,[ADD_GE_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]    
  ,[MEDICAL_EXAMINER_NOTIFIED]    
  ,[SEEN_IN_ED_WITHIN_48_HOURS_OF_OR]    
  ,[ADD_24_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]    
  ,[ADD_PHYSICIAN_SVC_25_MODIFIER]    
  ,[LMP_DATE_NOT_AVAILABLE]    
  ,[OBSERVATION_DISCHARGE_PROVIDER_ID]    
  ,[FORCED_AUDIT]    
  ,[FLAGGED_FOR_AUDIT]    
  ,[START_SECOND_LEVEL_QA_DATETIME]    
  ,[START_SECOND_LEVEL_QA_USER_PROFILE_ID]    
  ,[SECOND_LEVEL_QA_APPROVED_DATETIME]    
  ,[SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID]    
  ,[QUALIFIED_FOR_SECOND_AUDIT_AT_COMPLETION]    
  ,[FRACTURE_CARE_CPT_CHARGED]    
  ,[SERVICE_AGREEMENT_TRANSFER_FACILITY_ID]    
  ,[OVERRIDE_PHYSICIAN_SERVICE_GUIDELINE_ID]    
  ,[PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID]    
  ,[USE_TIME_BASED_CHARGE_CAPTURE]    
  ,[TIME_BASED_CHARGE_CAPTURE_COMMENT]    
  ,[TIME_BASED_PHYSICIAN_LOS]    
  ,[POST_BILL_AUDIT_STARTED]    
  ,[POST_BILL_AUDIT_STARTED_BY_USER_ID]    
  ,[POST_BILL_AUDIT_COMPLETED]    
  ,[POST_BILL_AUDIT_COMPLETED_BY_USER_ID]    
  ,[FLAGGED_FOR_POST_BILL_AUDIT_DT]    
  ,[ADD_59_XU_MODIFIER]    
  ,[ANESTHESIA_CODING_COMPLETE]    
  ,[NO_ANESTHESIA_CODING]    
  ,[USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE]    
  ,[PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID]    
  ,[USE_INPATIENT_DOWNCODE_OPTION]    
  ,[BYPASS_AUTO_APPROVAL]    
  ,[FACILITY_LOS_AF_MODIFIER]    
  ,[FACILITY_LOS_AG_MODIFIER]    
  ,[ADD_AI_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]    
  ,[DO_NOT_APPLY_FACILITY_MODIFIER_25]    
  ,[ADD_MODIFIER_CG_TO_PHYSICIAN_LOS]    
  ,[USE_EXPERT_HISTORY_WORKSHEET_SECTION]    
  ,[USE_EXPERT_EXAM_WORKSHEET_SECTION]    
  ,[USE_EXPERT_MDM_WORKSHEET_SECTION]    
  ,[ADD_MODIFIER_GQ_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_GT_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_G0_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_95_TO_PHYSICIAN_LOS]    
  ,[FACILITY_LOS_CS_MODIFIER]    
  ,[ADD_MODIFIER_CS_TO_PHYSICIAN_LOS]    
  ,[FACILITY_LOS_95_MODIFIER]    
  ,[ADD_MODIFIER_CR_TO_PHYSICIAN_LOS]    
  ,[CHART_HAS_QA_SCORECARD_DATA]    
  ,[CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES]    
  ,[CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE]    
  ,[CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE]    
  ,[CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY]    
  ,[CLINIC_2021_TIME_BASED_ADDITIONAL_CPT_CODE]    
  ,[ADD_MODIFIER_GV_TO_PHYSICIAN_LOS]    
  ,[PROVIDER_TYPE_CREDENTIALS_MODIFIER]    
  ,[SERVICE_AGREEMENT_PROVIDER_TYPE_CREDENTIAL_ID]    
  ,[ADD_MODIFIER_EP_TO_PHYSICIAN_LOS]    
  ,[PROVIDER_SPECIFIED_LOS_PHYSICIAN_SERVICE_PROC_ID]    
  ,[PROVIDER_SPECIFIED_LOS_MODIFIER]    
  ,[ADMIT_SOURCE_ID]    
  ,[DATE_TIME_OF_DEATH]    
  ,[FACILITY_AUTOMATION_CODING_COMPLETE]    
  ,[FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME]    
  ,[PHYSICIAN_AUTOMATION_CODING_COMPLETE]    
  ,[PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME]    
  ,[FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT]    
  ,[ADD_MODIFIER_AF_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_AG_TO_PHYSICIAN_LOS]    
  ,[CODER_ERROR_RESPONSE]    
  ,[CODER_ERROR_RESPONSE_COMMENTS]    
  ,[AUDITOR_ERROR_RESPONSE]    
  ,[AUDITOR_ERROR_RESPONSE_COMMENTS]    
  ,[CODER_RESPONSE_DATE]    
  ,[AUDITOR_RESPONSE_DATE]    
  ,[USE_TELEHEALTH]    
  ,[ATTESTATION_SYNCHRONIZED_AV_PRESENT]    
  ,[PLOS_ICD_10_CODE]    
  ,[ADD_MODIFIER_AM_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_U7_TO_PHYSICIAN_LOS]    
  ,[FACILITY_LOS_32_MODIFIER]    
  ,[NO_PROVIDER_SPECIFIED_PROCEDURES]    
  ,[ADD_MODIFIER_SA_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_93_TO_PHYSICIAN_LOS] -- added DACS-2475 - 20230619 - pippin    
  ,[FACILITY_LOS_93_MODIFIER]   -- added DACS-2475 - 20230619 - pippin    
  ,[ADD_MODIFIER_FS_TO_PHYSICIAN_LOS] -- added DACS-2485 - 20230626 - pippin    
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED  
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED_DATE_TIME
  ,NO_PQRS -- added DACS-3533 - 20240814 - kpanwar
 FROM     
  [dbo].[CHART]     
 WHERE     
  [CHART_ID] = @CHART_ID;    
END    
-- End of 02) DACS-3533 - ALTER STORED PROC CHART_SELECT_BY_CHART_ID.sql
GO

-- Start of 03) DACS-3533 ALTER STORED PROC SelectChartByFacilityIdAndFacilityChartIdentifier.sql

------------------------------------------------------------------------------------
-- 03) DACS-3533 - ALTER PROCEDURE [SelectChartByFacilityIdAndFacilityChartIdentifier] to add NO_PQRS column to selection list
------------------------------------------------------------------------------------
GO

GO

GO
  
  
CREATE OR ALTER     PROCEDURE [dbo].[SelectChartByFacilityIdAndFacilityChartIdentifier]   
   @facilityId INT  
 , @facilityChartIdentifier VARCHAR(20)  
AS  
BEGIN  
 ----------------  
 -- Simple select statement used by ChartDAO.cs within ACS  
 ----------------  
  
 ----------------  
 -- validate parameters  
 ----------------  
 IF @facilityId IS NULL OR @facilityId <= 0  
 BEGIN  
  PRINT('@facilityId is invalid.');  
  RETURN;  
 END;  
  
 IF @facilityChartIdentifier IS NULL OR Len(@facilityChartIdentifier) <= 0  
 BEGIN  
  PRINT('@facilityChartIdentifier is invalid.');  
  RETURN;  
 END;  
  
 SET NOCOUNT ON  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    
 SELECT TOP 1 -- this is a just in case safety item, do not remove. ACS sometimes has issues regarding duplicates that are generated by clients via batch importing  
   CHART_ID   
        ,SERVICE_AGREEMENT_ID  
  ,FACILITY_ID  
  ,FACILITY_CHART_ID  
  ,FACILITY_ADMIN_CHART_ID  
        ,MEDICAL_RECORD_NUM  
  ,PATIENT_TITLE  
  ,PATIENT_FIRST_NAME  
  ,PATIENT_MIDDLE_NAME  
  ,PATIENT_LAST_NAME  
  ,PATIENT_NAME_SUFFIX  
  ,PATIENT_ADDR_LINE_1  
  ,PATIENT_ADDR_LINE_2  
  ,PATIENT_CITY  
  ,PATIENT_STATE  
  ,PATIENT_ZIPCODE  
  ,PATIENT_DOB  
  ,TIME_OF_SERVICE  
  ,TIME_TO_ROOM  
  ,TIME_OF_PHYS_EVAL  
  ,TIME_OF_PHYS_DIS  
  ,TIME_OF_TRIAGE  
  ,TIME_OF_DIS  
  ,PHYSICIAN_ID  
  ,TRIAGE_NURSE_ID  
  ,DIS_NURSE_ID  
  ,DATE_RECEIVED   
        ,ASSIGNED_TO_ID   
        ,CHART_STATUS_ID   
        ,PENDING_REASON_ID  
        ,CODER_COMMENT   
        ,FAC_SVCS_COMPLETED   
        ,FAC_PROC_COMPLETED  
        ,PHYS_COMPLETED  
  ,PHYS_PROC_COMPLETED  
  ,PREBILL_AUDIT_COMPLETED  
  ,DEMOGRAPHICS_COMPLETED  
  ,RESULTS_COMPLETED  
  ,INFUSIONS_COMPLETED  
  ,FACILITY_CRITICAL_CARE  
  ,FACILITY_CRITICAL_CARE_MINUTES  
  ,PHYSICIAN_CRITICAL_CARE  
  ,PHYSICIAN_CRITICAL_CARE_MINUTES  
  ,FACILITY_LEVEL_ID  
  ,OVERRIDE_FACILITY_LEVEL_ID  
  ,PATIENT_DISPOSITION_ID  
  ,PHYSICIAN_HISTORY_ID  
  ,PHYSICIAN_EXAM_ID  
  ,PHYSICIAN_MDM_ID  
  ,PHYSICIAN_SERVICE_PROC_ID  
  ,PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID   
  ,OVERRIDE_PHYS_HIST_ID  
  ,OVERRIDE_PHYS_EXAM_ID  
  ,OVERRIDE_PHYS_MDM_ID  
  ,OVERRIDE_PHYSICIAN_SERVICE_PROC_ID  
  ,PHYSICIAN_SERVICE_MOD  
  ,COMPLETED_BY_USER_PROFILE_ID  
  ,APPROVED_BY_USER_PROFILE_ID  
  ,SENT_BY_USER_PROFILE_ID  
  ,COMPLETION_DATE  
  ,APPROVED_DATE  
  ,SENT_DATE  
  ,NON_ER_PROCEDURES_OVERRIDE   
        ,NO_FACILITY_SERVICES   
        ,NO_FACILITY_PROCEDURES   
        ,NO_PHYSICIAN_SERVICES   
        ,NO_PHYSICIAN_PROCEDURES   
        ,NO_PREBILL_AUDIT   
  ,NO_INJECTIONS_OR_INFUSIONS  
  ,EDITED_BY_EXPERT   
        ,NUMBER_OF_IV_PUSHES   
        ,IMAGES_AVAILABLE   
        ,DIAGNOSIS_CODING_COMPLETE   
        ,NO_DIAGNOSIS_CODING   
  ,CHIEF_COMPLAINT  
  ,PATIENT_CLASS_ID   
  ,PATIENT_CLASS_CD  
  ,INSUFFICIENT_PHYSICIAN_PROCEDURE_DOC   
  ,INSUFFICIENT_PHYSICIAN_PROCEDURE_REASON_ID  
  ,CLIENT_COMMENT   
  ,CHART_IMAGES_TRANSMITTED  
  ,FINANCIAL_CLASS_CD   
  ,DOCUMENTATION_COMPLETED   
  ,DOCUMENTATION_EVALUATION_OK  
  ,RESIDENT_ID   
  ,DEPARTMENT   
  ,LONG_PATIENT_ID1   
  ,LONG_PATIENT_ID2  
  ,NUMBER_OF_IV_PUSHES_SAME_SUB   
  ,APPROVAL_REASON_CODE   
  ,PRIMARY_COMPLAINT   
  ,PATIENT_DISPOSITION_MAP_ID  
  ,HORMONAL  
  ,NON_HORMONAL  
  ,INTERLESIONAL_7_OR_LESS  
  ,INTERLESIONAL_MORE_THAN_7  
  ,NUMBER_CHEMOTHERAPY_IV_PUSH  
  ,PROLONGED_IV_CHEMOTHERAPY  
  ,PROLONGED_IA_CHEMOTHERAPY  
  ,ADDITIONAL_CRITICAL_CARE_UNITS  
  ,SUPPLIES_COMPLETED  
  ,NO_SUPPLIES  
  ,ADDITIONAL_COMPLAINT  
  ,ADDITIONAL_COMPLAINT2  
  ,GENDER  
  ,HOSPITAL_POINTS  
  ,HOSPITAL_CHIEF_COMPLAINT  
  ,APPEARS_TO_QUALIFY_FOR_CRITICAL_CARE  
  ,SERVICES_PERFORMED_BY_RESIDENT  
  ,RESIDENT_PHYS_PRESENT  
  ,RESIDENT_PHYS_PRESENT_REF_RES_NOTES  
  ,RESIDENT_PHYS_PRESENT_DISCUSSED_PLAN  
  ,RESIDENT_PHYS_INDEPENDENT_REF_RES_NOTES  
  ,RESIDENT_PHYS_INDEPENDENT_PERSONALLY_SAW  
  ,RESIDENT_PHYS_INDEPENDENT_DISCUSSED  
  ,RESIDENT_CPT_ENTIRELY_PRESENT  
  ,RESIDENT_CPT_PRESENT_DURING_KEY_PORTION  
  ,FACILITY_LEVEL_CODER_COMMENT  
        ,CREATION_DATE_TIME   
  ,CREATING_USER_PROFILE_ID   
        ,CHANGED_DATE_TIME   
        ,CHANGING_USER_PROFILE_ID   
        ,OVERRIDE_LCD_ERRORS  
  ,EVER_COMPLETED  
  ,LAST_ENCOUNTER_DATE   
        ,SAFETY_DEVICE_CD   
        ,SPORT_TYPE_CD   
        ,RESIDENT_PARTICIPATED_IN_CARE  
  ,ATTESTATION_SIGNED_BY_ATTENDING  
  ,REPORT_CHIEF_COMPLAINT_AS_SECONDARY   
        ,REPORT_ADDITIONAL_COMPLAINT_AS_SECONDARY   
        ,REPORT_ADDITIONAL_COMPLAINT2_AS_SECONDARY   
        ,PATIENT_AGE   
        ,START_QA_USER_PROFILE_ID  
  ,START_QA_DATE  
  ,PHYSICIAN_SIGNATURE_PRESENT  
  ,OBS_DEPT_EVAL_COMPLETED  
  ,INITIAL_CHARGE_MASTER_DEPT_ID  
  ,PHYSICIAN_LEVEL_CODER_COMMENT  
  ,EXCLUDE_OBSERVATION_DIRECT_CHARGE  
  ,NURSE_PRACTITIONER_ID   
  ,ADD_MODIFIER_32_TO_PHYSICIAN_LOS  
  ,NO_PHYSICIAN_LOS_REASON_ID  
  ,CLINIC_ID  
  ,SERIAL_CODE  
  ,REGISTRATION_AREA  
  ,REGISTRATION_CODE   
        ,SERVICE_LINE_ID   
        ,TERMINAL_DIGITS   
        ,IMAGE_SOURCE_ID   
        ,PAYOR_CD   
        ,POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE   
        ,IS_PRIORITY   
        ,NO_ACTIVITY_CODES  
  ,NO_LCD_SERVICES   
  ,MODIFIER_25_REQUIRED_REASON_ID  
  ,CONDITION_OF_ACCIDENT_ID  
  ,ACCIDENT_DATE  
  ,ADMISSION_DATE_TIME  
  ,OBSERVATION_ATTENDING_PROVIDER_ID   
  ,OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID  
  ,PATIENT_DISPOSITION_DESTINATION_ID  
  ,NO_OBSERVATION_HOURS   
  ,OBSERVATION_COMPLETED_BY_USER_PROFILE_ID   
  ,OBSERVATION_COMPLETION_DTTM  
  ,OBSERVATION_PROCEDURES_AUDIT_COMMENT  
  ,OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT   
  ,OBSERVATION_AUDITOR_REVIEW_FEEDBACK  
  ,FACILITY_LOS_27_MODIFIER  
  ,OBSERVATION_BILLING_METHOD_CD   
  ,ARRIVAL_DATE_TIME  
  ,SERVICE_AGREEMENT_TRIAGE_ACUITY_ID  
  ,SERVICE_AGREEMENT_ARRIVAL_MODE_ID   
  ,FACILITY_CRITICAL_CARE_CALC_METHOD_CD  
  ,FACILITY_CRITICAL_CARE_START_DATE  
  ,FACILITY_CRITICAL_CARE_STOP_DATE   
  ,PHYSICIAN_CRITICAL_CARE_CALC_METHOD_CD  
  ,PHYSICIAN_CRITICAL_CARE_START_DATE   
  ,PHYSICIAN_CRITICAL_CARE_STOP_DATE   
  ,AUDIT_REQUIRED  
  ,ARRIVAL_DATE_TIME_NOT_AVAILABLE   
  ,TIME_OF_TRIAGE_NOT_AVAILABLE   
        ,TIME_TO_ROOM_NOT_AVAILABLE   
        ,TIME_OF_PHYSICIAN_EVAL_NOT_AVAILABLE   
        ,ARRIVAL_MODE_NOT_AVAILABLE  
  ,TRIAGE_ACUITY_NOT_AVAILABLE   
  ,OBSERVATION_TELEMETRY   
        ,DEMOGRAPHIC_AUDIT_COMMENT   
        ,LAST_MENSTRUAL_PERIOD   
        ,PAYOR_NAME  
  ,SERVICE_AGREEMENT_MODE_OF_DEPARTURE_ID  
  ,ORGAN_DONATION  
  ,REASON_FOR_VISIT_CATEGORY_DETAIL_ID   
  ,ADD_MODIFIER_57_TO_PHYSICIAN_LOS  
  ,DO_NOT_APPLY_PHYSICIAN_MODIFER_25  
  ,ADD_MODIFIER_GW_TO_PHYSICIAN_LOS  
  ,PRIMARY_CARE_PHYSICIAN_ID  
  ,SCRIBE_ID  
  ,NO_ATTENDING_PROVIDER_SELECTED_IND   
  ,PROVIDER_EVAL_PERFORMED_BY_IND  
  ,BILLING_INSTRUCTIONS  
  ,PHYSICIAN_SERVICE_OBSERVATION_ADMIT_DATETIME  
  ,PHYSICIAN_SERVICE_OBSERVATION_DISCHARGE_DATETIME  
  ,PHYSICIAN_SERVICE_OBSERVATION_FINAL_EXAM  
  ,SUBSEQUENT_VISIT_CODE  
  ,SERVICE_AGREEMENT_ADMIT_TYPE_ID  
  ,LOCATION_CODE  
  ,BILLING_AREA  
  ,ADD_GC_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL  
  ,ADD_GE_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL  
  ,MEDICAL_EXAMINER_NOTIFIED  
  ,SEEN_IN_ED_WITHIN_48_HOURS_OF_OR  
  ,ADD_24_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL  
  ,ADD_PHYSICIAN_SVC_25_MODIFIER   
  ,LMP_DATE_NOT_AVAILABLE  
  ,OBSERVATION_DISCHARGE_PROVIDER_ID  
  ,FORCED_AUDIT  
  ,FLAGGED_FOR_AUDIT   
  ,START_SECOND_LEVEL_QA_DATETIME  
  ,START_SECOND_LEVEL_QA_USER_PROFILE_ID  
  ,SECOND_LEVEL_QA_APPROVED_DATETIME  
  ,SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID  
  ,QUALIFIED_FOR_SECOND_AUDIT_AT_COMPLETION   
  ,FRACTURE_CARE_CPT_CHARGED  
  ,SERVICE_AGREEMENT_TRANSFER_FACILITY_ID  
  ,OVERRIDE_PHYSICIAN_SERVICE_GUIDELINE_ID  
  ,PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID   
  ,USE_TIME_BASED_CHARGE_CAPTURE  
  ,TIME_BASED_CHARGE_CAPTURE_COMMENT  
  ,TIME_BASED_PHYSICIAN_LOS  
  ,POST_BILL_AUDIT_STARTED  
  ,POST_BILL_AUDIT_STARTED_BY_USER_ID   
  ,POST_BILL_AUDIT_COMPLETED  
  ,POST_BILL_AUDIT_COMPLETED_BY_USER_ID  
  ,FLAGGED_FOR_POST_BILL_AUDIT_DT  
  ,ADD_59_XU_MODIFIER   
  ,ANESTHESIA_CODING_COMPLETE  
  ,NO_ANESTHESIA_CODING  
  ,USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE  
  ,PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID  
  ,USE_INPATIENT_DOWNCODE_OPTION  
  ,BYPASS_AUTO_APPROVAL   
  ,FACILITY_LOS_AF_MODIFIER  
  ,FACILITY_LOS_AG_MODIFIER  
  ,ADD_AI_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL  
  ,DO_NOT_APPLY_FACILITY_MODIFIER_25  
  ,ADD_MODIFIER_CG_TO_PHYSICIAN_LOS  
  ,USE_EXPERT_HISTORY_WORKSHEET_SECTION  
  ,USE_EXPERT_EXAM_WORKSHEET_SECTION  
  ,USE_EXPERT_MDM_WORKSHEET_SECTION   
  ,ADD_MODIFIER_GQ_TO_PHYSICIAN_LOS  
  ,ADD_MODIFIER_GT_TO_PHYSICIAN_LOS  
  ,ADD_MODIFIER_G0_TO_PHYSICIAN_LOS  
  ,ADD_MODIFIER_95_TO_PHYSICIAN_LOS  
  ,FACILITY_LOS_CS_MODIFIER  
  ,ADD_MODIFIER_CS_TO_PHYSICIAN_LOS  
  ,FACILITY_LOS_95_MODIFIER  
  ,ADD_MODIFIER_CR_TO_PHYSICIAN_LOS  
  ,CHART_HAS_QA_SCORECARD_DATA   
  ,CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES  
  ,CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE  
  ,CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE   
  ,CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY  
  ,CLINIC_2021_TIME_BASED_ADDITIONAL_CPT_CODE  
  ,ADD_MODIFIER_GV_TO_PHYSICIAN_LOS  
  ,PROVIDER_TYPE_CREDENTIALS_MODIFIER  
  ,SERVICE_AGREEMENT_PROVIDER_TYPE_CREDENTIAL_ID   
  ,ADD_MODIFIER_EP_TO_PHYSICIAN_LOS  
  ,PROVIDER_SPECIFIED_LOS_PHYSICIAN_SERVICE_PROC_ID  
  ,PROVIDER_SPECIFIED_LOS_MODIFIER  
  ,ADMIT_SOURCE_ID, DATE_TIME_OF_DEATH   
  ,FACILITY_AUTOMATION_CODING_COMPLETE  
  ,FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME  
  ,PHYSICIAN_AUTOMATION_CODING_COMPLETE  
  ,PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME  
  ,FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT   
  ,ADD_MODIFIER_AF_TO_PHYSICIAN_LOS  
        ,ADD_MODIFIER_AG_TO_PHYSICIAN_LOS  
        ,CODER_ERROR_RESPONSE  
        ,CODER_ERROR_RESPONSE_COMMENTS  
        ,AUDITOR_ERROR_RESPONSE  
        ,AUDITOR_ERROR_RESPONSE_COMMENTS  
        ,CODER_RESPONSE_DATE  
        ,AUDITOR_RESPONSE_DATE  
        ,USE_TELEHEALTH  
        ,ATTESTATION_SYNCHRONIZED_AV_PRESENT  
        ,PLOS_ICD_10_CODE  
        ,ADD_MODIFIER_AM_TO_PHYSICIAN_LOS  
        ,ADD_MODIFIER_U7_TO_PHYSICIAN_LOS  
        ,FACILITY_LOS_32_MODIFIER  
        ,NO_PROVIDER_SPECIFIED_PROCEDURES  
  ,ADD_MODIFIER_SA_TO_PHYSICIAN_LOS  
  ,ADD_MODIFIER_93_TO_PHYSICIAN_LOS  
  ,FACILITY_LOS_93_MODIFIER  
  ,ADD_MODIFIER_FS_TO_PHYSICIAN_LOS  
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED -- added column DACS-3484 - 2024-08-15  
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED_DATE_TIME -- added column DACS-3484 - 2024-08-15  
  ,NO_PQRS -- added DACS-3533 - 20240814 - kpanwar
 FROM [CHART]  
 WHERE   
     [FACILITY_ID] = @facilityId  
  AND [FACILITY_CHART_ID] = @facilityChartIdentifier;  
  
END -- end procedure  
  
-- End of 03) DACS-3533 ALTER STORED PROC SelectChartByFacilityIdAndFacilityChartIdentifier.sql
GO

-- Start of 04) DACS-3533 CREATE STORED PROC UpdateChartPQRSByChart.sql

-----------------------------------------------------------------------------
-- 04) DACS-3533 - Create or Alter Stored Procedure - [dbo].[UpdateChartPQRSByChart].SQL
-----------------------------------------------------------------------------
GO

GO

GO
    
CREATE OR ALTER PROCEDURE [dbo].[UpdateChartPQRSByChart]    
	 @ChartId INT    
	,@PqrsValue BIT    
AS    
BEGIN    
	IF @ChartId IS NULL OR @ChartId <= 0
		RETURN;    
    
	SET NOCOUNT ON    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    

	UPDATE [CHART]
		SET NO_PQRS = @PqrsValue
	WHERE 
	    [CHART_ID] = @ChartId
	  
END -- end procedure

GO
-- End of 04) DACS-3533 CREATE STORED PROC UpdateChartPQRSByChart.sql
GO

-- Start of 01) DACS-3592 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3592 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'AreAny2024MipsRuleSatisfiedByChart', @DestProc = 'AreAny2024MipsRuleSatisfiedByChart_DACS-3592';
GO

CREATE OR ALTER PROCEDURE [dbo].[AreAny2024MipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad ChartId ' = @ChartId;
		RETURN;
	END;
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @serviceAgreementId INT;
	DECLARE @dateOfService DATETIME;
	
	SELECT 
		 @serviceAgreementId = [SERVICE_AGREEMENT_ID]
		,@dateOfService = [TIME_OF_SERVICE]
	FROM 
		[dbo].[chart] 
	WHERE
		[CHART_ID] = @ChartId;

	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0 OR @dateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;

	PRINT('serviceAgreementId = ' + CAST(@serviceAgreementId AS VARCHAR(64)));
	PRINT('dateOfService = ' + CAST(@dateOfService AS VARCHAR(64)));

	
	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@serviceAgreementId, @Dos=@dateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @countSaMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- load our single criteria MIPS for testing
	-----------------------------------
	DECLARE @active2024MipsRules1CTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRules1CTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
	;
	
	IF @TestAll <> 1 DELETE FROM @active2024MipsRules1CTable WHERE [NAME] NOT IN (SELECT [NAME] FROM @activeSAMipsRulesTable);

	DECLARE @count1CMips INT = (SELECT COUNT(*) FROM @active2024MipsRules1CTable);
	IF @count1CMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No 2024 1 criteria Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT '@count1CMips = ' = @count1CMips;
	IF @ShowDebug = 1 SELECT * FROM @active2024MipsRules1CTable;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = @count1CMips;

	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchResultsTable TABLE ( [RESULT] VARCHAR(32), [QUESTION] VARCHAR(1024), [CODE] VARCHAR(32));
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [NAME] FROM @active2024MipsRules1CTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NOT NULL 
		BEGIN
			DELETE FROM @FetchResultsTable;
			
			DECLARE @SQL NVARCHAR(512) = N'EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type' + REPLACE(@FetchMipsName,'-','') + '] @ChartId=@fCId,@PqrsNum=@fPqrs,@Dos=@fDos;';
			DECLARE @ParmDefinition NVARCHAR(512) = N'@fCId INT, @fPqrs VARCHAR(32), @fDos DATETIME';

			IF @ShowDebug = 1 PRINT('  --> @SQL = ' + @SQL);

			INSERT INTO 
				@FetchResultsTable
			EXEC sp_executesql @SQL, @ParmDefinition, @fCId=@ChartId, @fPqrs=@FetchMipsName, @fDos=@dateOfService;			

			IF @ShowDebug = 1 SELECT * FROM @FetchResultsTable;

			IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
			BEGIN
				IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @FetchMipsName;

				IF @TestAll <> 1 
				BEGIN 
				-- cleanup our cursor
					CLOSE cursorTempRows;  
					DEALLOCATE cursorTempRows; 
				END;

				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				IF @TestAll <> 1 RETURN;
			END;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	-----------------------------------
	-- load our dual criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '005') OR @TestAll = 1
	BEGIN
		PRINT('Processing: 005-A');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A @ChartId=@ChartId,@PqrsNum='005-A',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='005-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		PRINT('-------------------');		
		PRINT('Processing: 005-B');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B @ChartId=@ChartId,@PqrsNum='005-B',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '005-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '008') OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: 008-A');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A @ChartId=@ChartId,@PqrsNum='008-A',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='008-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		PRINT('-------------------');		
		PRINT('Processing: 008-B');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B @ChartId=@ChartId,@PqrsNum='008-B',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '008-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	-----------------------------------
	-- load our PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	DECLARE @MipsNameToTest VARCHAR(32) = 'PQRANES1';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP60';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP61';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP64';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'HCPR24';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeHCPR24 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;


	-----------------------------------
	-- all done
	-----------------------------------
	PRINT('-------------------');		
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;
END; -- end of SPROC

GO

/*
EXEC [dbo].AreAny2024MipsRuleSatisfiedByChart @ChartId=2100113944,@ShowDebug=1,@TestAll=1; -- tests PQRANES1

*/
-- End of 01) DACS-3592 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
GO

-- Start of 01) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectChartPqrs', @DestProc = 'spSelectChartPqrs_DACS-3417';
GO

CREATE OR ALTER PROCEDURE [dbo].[spSelectChartPqrs] 
	@ChartId INT,
	@MeasureId INT = NULL,
	@MeasureCodeId INT = NULL
	WITH
EXEC AS CALLER AS

------------------------------------------------------------------------------------
-- Adds additional CODING_SYSTEM strings used within the various temporary tables to allow for extended behavior supporting new MIPS decision logic - DACS-3164 - 20240422 - pippin
------------------------------------------------------------------------------------

-- testing
-- DECLARE @ChartId INT = 2100107114;
-- DECLARE @MeasureId INT = NULL;
-- DECLARE @MeasureCodeId INT = NULL;
-- body of original SPROC -- >

DECLARE @chart_id INT = @ChartId;
DECLARE @measure_id INT = @MeasureId;
DECLARE @measure_code_id INT = @MeasureCodeId;
DECLARE @Now DATETIME = GETDATE();
DECLARE @flag VARCHAR(10) = '';
DECLARE @HasDXCode INT;
DECLARE @HasCPTCode INT;

Declare @PSP_CPT varchar(50)	-- added 2/21/2023 (dsexton)

-- Drop statements for new temp tables added 2/21/2023 (dsexton)
if object_id('TempDB..#MeasureList', 'U') is not null DROP TABLE #MeasureList;
if object_id('TempDB..#RequireCptMeasures', 'U') is not null DROP TABLE #RequireCptMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures2', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures2;
if object_id('TempDB..#RequiredMeasures2', 'U') is not null DROP TABLE #RequiredMeasures2;
if object_id('TempDB..#RequiredMeasuresOldLogic', 'U') is not null DROP TABLE #RequiredMeasuresOldLogic;
if object_id('TempDB..#Chart', 'U') is not null DROP TABLE #Chart;
--if object_id('TempDB..#ChartDiagCode9', 'U') is not null DROP TABLE #ChartDiagCode9;	-- DACS-3417, 08/19/2024 (pippin)
if object_id('TempDB..#ChartDiagCodeICD10', 'U') is not null DROP TABLE #ChartDiagCodeICD10;
if object_id('TempDB..#PPE_CPT', 'U') is not null DROP TABLE #PPE_CPT;

-- new temp table for tuning, 2/21/2023 (dsexton)
select chart_ID, service_agreement_ID, primary_complaint, chief_complaint, PHYSICIAN_SERVICE_PROC_ID, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
	, Time_of_Service, gender, patient_DOB, patient_age
  into #Chart	
from CHART
where chart_ID = @chart_id

-- select * from #Chart -- testing

/*
This sproc executes very frequently at certain times of the day. For example, on 2/21/2023 it executed nearly 8K times between 4:30-7:30 AM. By 3 pm it executed only an additional 3,500 times.
It is called by sproc spSelectMissingChartPqrs which has executed 37K times over the past seven days. 
Avg LReads have been 150K which adds up to several billion reads each day. 

Modified all CLR queries to instead write to temp tables, 2/21/2023 (dsexton).  This reduced logical reads 95% (13K vs 240K) when testing with chart_ID 101104526.
	-- Duration was reduced 80% (31ms vs 184ms).
*/


--WITH MeasureList						-- replaced all CLR queries with temp tables, 2/21/2023 (dsexton)
--AS (
	SELECT cpm.CMS_PQRI_MEASURE_ID,
		cpm.MEASURE_TITLE,
		cpm.REQUIRES_BOTH_CPT_AND_DX,
		cpmc.CMS_PQRI_MEASURE_CODE_ID,
		cpmc.CODING_SYSTEM,
		cpmc.OPTION_GROUP,
		cpmc.CODE,
		cpmc.MODIFIER,
		cpmc.[DESCRIPTION],
		CASE 
			WHEN cpmc.END_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.END_DATE 
			END END_DATE,
		cpmc.CODE_2,
		cpmc.MODIFIER_2,
		cpm.REQUIRES_MULTIPLE_CPTS,
		cpm.MULTIPLE_CPT_COUNT,
		cpm.REQUIRES_MULTIPLE_DX,
		cpm.REQUIRES_CPT_CODE,
		cpm.REQUIRED_CPT_CODE,
		CASE 
			WHEN COALESCE(cpm.REQUIRES_EM_ONLY, 0) = 1
				AND (c.PHYSICIAN_SERVICE_PROC_ID > 0 OR c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0)
				THEN 1
			ELSE 0
			END REQUIRES_EM_ONLY,
		CASE 
			WHEN COALESCE(cpm.MATCH_EM_LEVEL, 0) = 1
				THEN 1
			ELSE 0
			END MATCH_EM_LEVEL,
		CASE 
			WHEN cpmc.START_DATE IS NULL
				THEN '1/1/1900 00:00:00'
			ELSE cpmc.START_DATE
			END START_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE IS NULL
				THEN '02/20/2020 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
	    CONVERT(Date, c.TIME_OF_SERVICE) as DATE_OF_SERVICE,
		cpm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		cpm.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #MeasureList							-- tuning, 2/21/2023 (dsexton)
	FROM CMS_PQRI_MEASURE cpm WITH (NOLOCK)
	LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc WITH (NOLOCK) ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID
	--INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
	cross join #Chart c		--ON c.CHART_ID = @chart_id
	WHERE DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, c.TIME_OF_SERVICE)
		AND (
			ISNULL(cpm.GENDER, 'B') = 'B'
			OR cpm.GENDER = c.GENDER
			)
		AND (
			(
				(COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) = 0
				AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0)) = 999
				)
			OR (
				(c.PATIENT_AGE IS NOT NULL AND c.PATIENT_DOB IS NULL
				AND c.PATIENT_AGE BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				))
			
			OR (
				(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NOT NULL OR cpm.TO_AGE_FRACTIONAL IS NOT NULL)
				AND ((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				)
			
			OR (
			(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NULL AND cpm.TO_AGE_FRACTIONAL IS NULL)
				AND CAST(((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) AS INT) BETWEEN COALESCE(cpm.FROM_AGE, 0)  AND COALESCE(cpm.TO_AGE, 999)
				)
			)

		AND cpm.CMS_PQRI_MEASURE_ID IN (
			SELECT sapqrs.CMS_PQRI_MEASURE_ID
			FROM SERVICE_AGREEMENT_PQRS sapqrs WITH (NOLOCK)
			WHERE sapqrs.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND CONVERT(Date, c.TIME_OF_SERVICE) BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, @Now)
			)
	--),

-- select '#MeasureList' = null
-- select * from #MeasureList where measure_title like '%332%' OR measure_title like '% 7-%' -- testing


-- New objects for tuning, 2/21/2023 (dsexton)  -------------------------------------------------------------------------------
/* -- DACS-3417, 08/19/2024 (pippin)
SELECT cdc.ICD9_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, c.CHIEF_COMPLAINT, c.PRIMARY_COMPLAINT, c.Time_of_Service
  into #ChartDiagCode9
FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
*/

SELECT cdc.ICD10_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, cdc.DIAGNOSIS_TYPE_ID, cdc.IS_PRIMARY, c.Time_of_Service
  into #ChartDiagCodeICD10
FROM CHART_DIAGNOSIS_CODE_ICD10 cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID

SELECT cm.CPT_Code
  into #PPE_CPT
FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
	and ppe.CHART_ID = @chart_id	

select TOP 1 @PSP_CPT = CPT_CODE
FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
INNER JOIN #Chart c 
on PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
WHERE PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
        WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
            THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
        ELSE c.PHYSICIAN_SERVICE_PROC_ID
        END
-------------------------------------------------------------------------------------------------------------------

--RequiredMeasuresOldLogic
--AS (
SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		ROW_NUMBER() OVER (
			PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredMeasuresOldLogic	-- tuning, 2/21/2023 (dsexton)
	--FROM MeasureList ml
	from #MeasureList ml		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE (
			/*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
				
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR (cdc.DIAGNOSIS_TYPE_ID IN (1,3,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			OR (
				ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select 1 from #PPE_CPT as t where t.CPT_Code = ml.Code		-- tuning to replace old subquery, 2/21/2023 (dsexton)
					)
				)
			)
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
      ml.REQUIRES_EM_ONLY = 1
      AND 
			@PSP_CPT	 -- tuning to replace subquery, 2/21/2023 (dsexton)
			  IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395')
    )
--	)
-- select '#RequiredMeasuresOldLogic' = null
-- select * from #RequiredMeasuresOldLogic where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--,
--RequiredDiagnosisMeasures
--AS (

	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 		   
		  /*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 1)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			

--    )
	  
-- select '#RequiredDiagnosisMeasures' = null
-- select * from #RequiredDiagnosisMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
	
--	,
--	RequiredDiagnosisMeasures2
--AS (
	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures2
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 
		 /*  -- DACS-3417, 08/19/2024 (pippin)
		  ml.CODING_SYSTEM = 'I9'
			AND EXISTS (
			/-*	-- example of old subquery, 2/21/2023 (dsexton)
				SELECT *
				FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
				INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = cdc.CHART_ID
				INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				WHERE cdc.CHART_ID = @chart_id
			*-/
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 0)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						)
			
			)
 --   )
	  
-- select '#RequiredDiagnosisMeasures2' = null
-- select * from #RequiredDiagnosisMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--	,
--	RequireCptMeasures
--AS (
     SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequireCptMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					SELECT *
					FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
					INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
					WHERE ppe.CHART_ID = @chart_id
						AND cm.CPT_CODE = ml.CODE
						AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					)
				
			
			
			
			
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
		ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
      AND  (
              SELECT  CPT_CODE
              FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
              INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
              WHERE PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                  AND PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
                      WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
                          THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                      ELSE c.PHYSICIAN_SERVICE_PROC_ID
                      END 
              ) = ml.Code
			  AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
			  )
--),

-- select '#RequireCptMeasures' = null
-- select * from #RequireCptMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--	RequiredMeasures2
--AS (
   
    SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
		rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
into #RequiredMeasures2
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		
		UNION
		SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
        rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS = 1
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		GROUP BY rdm.CMS_PQRI_MEASURE_ID, rdm.MEASURE_TITLE, rdm.REQUIRES_BOTH_CPT_AND_DX, rdm.CMS_PQRI_MEASURE_CODE_ID, rdm.CODING_SYSTEM, rdm.OPTION_GROUP, rdm.CODE, rdm.MODIFIER, rdm.[DESCRIPTION], rdm.END_DATE, rdm.CODE_2, rdm.MODIFIER_2, rdm.REQUIRES_EM_ONLY, rdm.MEASURE_TOOLTIP, rdm.MEASURE_HOTSHEET_URI, rcm.MULTIPLE_CPT_COUNT
		HAVING COUNT(rcm.CODE) = rcm.MULTIPLE_CPT_COUNT

		UNION
		SELECT rdm2.CMS_PQRI_MEASURE_ID,
		rdm2.MEASURE_TITLE,
		rdm2.REQUIRES_BOTH_CPT_AND_DX,
		rdm2.CMS_PQRI_MEASURE_CODE_ID,
		rdm2.CODING_SYSTEM,
		rdm2.OPTION_GROUP,
		rdm2.CODE,
		rdm2.MODIFIER,
        rdm2.[DESCRIPTION],
		rdm2.END_DATE,
		rdm2.CODE_2,
		rdm2.MODIFIER_2,
		rdm2.REQUIRES_EM_ONLY,
		rdm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm2.CMS_PQRI_MEASURE_ID ORDER BY rdm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures2 rdm2
		from #RequiredDiagnosisMeasures2 rdm2															-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID				-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		AND rdm2.CODE IS NOT NULL
		UNION
		
		SELECT rmol.CMS_PQRI_MEASURE_ID,
		rmol.MEASURE_TITLE,
		rmol.REQUIRES_BOTH_CPT_AND_DX,
		rmol.CMS_PQRI_MEASURE_CODE_ID,
		rmol.CODING_SYSTEM,
		rmol.OPTION_GROUP,
		rmol.CODE,
		rmol.MODIFIER,
		rmol.[DESCRIPTION],
		rmol.END_DATE,
		rmol.CODE_2,
		rmol.MODIFIER_2,
		rmol.REQUIRES_EM_ONLY,
		rmol.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rmol.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rmol.CMS_PQRI_MEASURE_ID ORDER BY rmol.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredMeasuresOldLogic rmol
		from #RequiredMeasuresOldLogic rmol			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		WHERE rmol.REQUIRES_BOTH_CPT_AND_DX = 1
		AND CONVERT(Date, rmol.DATE_OF_SERVICE) < rmol.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
		AND rmol.CODE IS NOT NULL
		
		
		UNION
		 
		SELECT rcm.CMS_PQRI_MEASURE_ID,
		rcm.MEASURE_TITLE,
		rcm.REQUIRES_BOTH_CPT_AND_DX,
		rcm.CMS_PQRI_MEASURE_CODE_ID,
		rcm.CODING_SYSTEM,
		rcm.OPTION_GROUP,
		rcm.CODE,
		rcm.MODIFIER,
		rcm.[DESCRIPTION],
		rcm.END_DATE,
		rcm.CODE_2,
		rcm.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm.CMS_PQRI_MEASURE_ID ORDER BY rcm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm
		from #RequireCptMeasures rcm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND COALESCE(rcm.REQUIRES_CPT_CODE, 0) = 0
		AND rcm.CODE IS NOT NULL

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		 

		 UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--)

-- select '#RequiredMeasures2' = null
-- select * from #RequiredMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

	
SELECT DISTINCT CMS_PQRI_MEASURE_ID,
	MEASURE_TITLE,
	CMS_PQRI_MEASURE_CODE_ID,
	CODING_SYSTEM,
	NULL OPTION_GROUP,
	CASE COALESCE(REQUIRES_EM_ONLY, 0)
		WHEN 1
			THEN 'E&M'
		ELSE CODE
		END CODE,
	NULL MODIFIER,
	NULL [DESCRIPTION],
	NULL END_DATE,
	NULL CODE_2,
	NULL MODIFIER_2,
	NULL MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	NULL MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	CAST([ROW_NUMBER] AS BIGINT) [ROW_NUMBER]
--FROM RequiredMeasures2
from #RequiredMeasures2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
WHERE @measure_id IS NULL
	AND @measure_code_id IS NULL
	AND [ROW_NUMBER] = 1

UNION

SELECT ml.CMS_PQRI_MEASURE_ID,
	ml.MEASURE_TITLE,
	ml.CMS_PQRI_MEASURE_CODE_ID,
	ml.CODING_SYSTEM,
	ml.OPTION_GROUP,
	ml.CODE,
	ml.MODIFIER,
	ml.[DESCRIPTION],
	ml.END_DATE,
	ml.CODE_2,
	ml.MODIFIER_2,
	ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	ml.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	NULL [ROW_NUMBER]
--FROM MeasureList ml
from #MeasureList ml						-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--INNER JOIN RequiredMeasures2 rm ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
INNER JOIN #RequiredMeasures2 rm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
WHERE (
		ml.CMS_PQRI_MEASURE_ID = @measure_id
		OR ml.CMS_PQRI_MEASURE_CODE_ID = @measure_code_id
		)
	AND ml.CODING_SYSTEM IN (
		'CPT_II',
		'HCPCS'
		)
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
	
ORDER BY CMS_PQRI_MEASURE_ID ASC,
	MEASURE_TITLE DESC

GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'spSelectChartPqrs', N'PARAMETER',N'@MeasureCodeId'))
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
END

GO


-- End of 01) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL
GO

-- Start of 02) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectMissingChartPqrs', @DestProc = 'spSelectMissingChartPqrs_DACS-3417';
GO

CREATE OR ALTER   PROCEDURE [dbo].[spSelectMissingChartPqrs]
	@ChartId int
WITH EXEC AS CALLER
AS

SET NOCOUNT ON							-- DACS-3457 - 20240723 - pippin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @chart_id INT =@ChartId;
DECLARE @RequiredMeasures table
(
  CMS_PQRI_MEASURE_ID int,
  MEASURE_TITLE varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  CMS_PQRI_MEASURE_CODE_ID int,
  CODING_SYSTEM varchar(20),
  OPTION_GROUP numeric(18,0),
  CODE varchar(20),
  MODIFIER varchar(20),
  [DESCRIPTION] varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  END_DATE date,
  CODE_2 varchar(6),
  MODIFIER_2 varchar(20),
  MEASURE_TOOLTIP varchar(4000), 		-- DACS-3417 - 20240830 - pippin - added field
  MEASURE_HOTSHEET_URI varchar(1000), 	-- DACS-3417 - 20240830 - pippin - added field
  [ROW_NUMBER] bigint
)

INSERT INTO @RequiredMeasures(CMS_PQRI_MEASURE_ID, MEASURE_TITLE, CMS_PQRI_MEASURE_CODE_ID, CODING_SYSTEM, OPTION_GROUP, CODE, MODIFIER, [DESCRIPTION], END_DATE, CODE_2, MODIFIER_2, MEASURE_TOOLTIP, MEASURE_HOTSHEET_URI, [ROW_NUMBER])
  EXEC [spSelectChartPqrsTest1] @ChartId=@chart_id

SELECT *
FROM @RequiredMeasures rm
WHERE (SELECT COUNT(*)
       FROM PHYSICIAN_PROCEDURE_EVALUATION ppe
         JOIN CHARGE_MASTER cm on cm.CHARGE_MASTER_ID=ppe.PHYSICIAN_PROCEDURE_ID
         JOIN CMS_PQRI_MEASURE_CODE cpmc on cpmc.CMS_PQRI_MEASURE_ID=rm.CMS_PQRI_MEASURE_ID
       WHERE CHART_ID=@chart_id
         AND cm.CHARGE_MASTER_USAGE_CODE=9
         AND cpmc.CODING_SYSTEM in ('CPT_II', 'HCPCS')
         AND cm.CPT_CODE=cpmc.CODE
         AND ppe.MODIFIERS=isnull(cpmc.MODIFIER, ''))=0
GO


-- End of 02) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL
GO

-- Start of 03) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'SelectCmsPqrsMeasureResultsListById', @DestProc = 'SelectCmsPqrsMeasureResultsListById_DACS-3417';
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListById] 
	 @MeasureId INT
	,@Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		--PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));	-- DACS-3417, 08/19/2024 (pippin)
	END;

	DECLARE @dateOfService DATE = CAST(@Dos AS DATE);			-- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 cpm.[CMS_PQRI_MEASURE_ID]
		,cpm.[MEASURE_TITLE]
		,cpmc.[CMS_PQRI_MEASURE_CODE_ID]
		,cpmc.[CODING_SYSTEM]
		,cpmc.[OPTION_GROUP]
		,cpmc.[CODE]
		,cpmc.[MODIFIER]
		,cpmc.[DESCRIPTION]
		,
		CASE 
			WHEN cpmc.[END_DATE] IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.[END_DATE] 
			END [END_DATE]
		,cpmc.[CODE_2]
		,cpmc.[MODIFIER_2]
		,cpm.[MEASURE_TOOLTIP]				-- DACS-3417, 08/19/2024 (pippin)
		,cpm.[MEASURE_HOTSHEET_URI]			-- DACS-3417, 08/19/2024 (pippin)
		,NULL [ROW_NUMBER]
	FROM 
		[CMS_PQRI_MEASURE] cpm
		LEFT JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID] = cpm.[CMS_PQRI_MEASURE_ID]
	WHERE 
		--DATEADD(DAY, DATEDIFF(DAY, 0, @dateOfService), 0) BETWEEN cpm.[EFFECTIVE_DATE] AND ISNULL(cpm.[EXPIRATION_DATE], @dateOfService) -- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types
		(cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] >= @dateOfService)
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] >= @dateOfService) 
		AND cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[CODING_SYSTEM] IN ('CPT_II','HCPCS')
	ORDER BY 
		cpmc.[CODE], cpmc.[MODIFIER]
	;

END -- end procedure

GO


-- End of 03) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
GO

-- Start of 04) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'SelectCmsPqrsMeasureResultsListByPqrsNum', @DestProc = 'SelectCmsPqrsMeasureResultsListByPqrsNum_DACS-3417';
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] 
	  @PqrsNum VARCHAR(20)
	, @Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @PqrsNum IS NULL OR LEN(@PqrsNum) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @PqrsNum';
		RETURN;
	END;

	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		-- PRINT('==> @Dos set to ' + CAST(@Dos AS VARCHAR(40)));	-- DACS-3417, 08/19/2024 (pippin)
	END;

	DECLARE @dateOfService DATE = CAST(@Dos AS DATE);			-- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types
		
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @MeasureId INT = (
		SELECT TOP 1 
			[CMS_PQRI_MEASURE_ID] 
		FROM 
			[CMS_PQRI_MEASURE]
		WHERE 
			[pqrs#] = @PqrsNum
			AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] <= @dateOfService)	-- DACS-3417, 08/19/2024 (pippin)
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @dateOfService)
		);

	-- PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );	-- DACS-3417, 08/19/2024 (pippin)

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );	-- DACS-3417, 08/19/2024 (pippin)
	
	EXEC SelectCmsPqrsMeasureResultsListById @MeasureId=@MeasureId, @Dos=@Dos;

END -- end procedure

GO


-- End of 04) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL
GO

-- Start of 01) DACS-3533 - ALTER TABLE Chart.sql

------------------------------------------------------------------------------------
-- 01) DACS-3533 - ALTER Table to add a new column
------------------------------------------------------------------------------------
GO

GO

GO

ALTER TABLE [dbo].[CHART] 
ADD NO_PQRS BIT NULL
-- End of 01) DACS-3533 - ALTER TABLE Chart.sql
GO

-- Start of 02) DACS-3533 - ALTER STORED PROC CHART_SELECT_BY_CHART_ID.sql

------------------------------------------------------------------------------------
-- 02) DACS-3533 - ALTER PROCEDURE [CHART_SELECT_BY_CHART_ID] to add NO_PQRS column to selection list
------------------------------------------------------------------------------------
GO

GO

GO


ALTER PROCEDURE [dbo].[CHART_SELECT_BY_CHART_ID]    
 @CHART_ID INT    
AS    
BEGIN    
 IF @CHART_ID IS NULL OR @CHART_ID <= 0    
 BEGIN    
  PRINT('@CHART_ID is invalid.');    
  RETURN;    
 END;    
    
 SET NOCOUNT ON    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
      
 SELECT TOP 1 -- this is a just in case safety item, do not remove. -- added DACS-3159 -- 20240412 -- pippin    
   [CHART_ID]    
  ,[SERVICE_AGREEMENT_ID]    
  ,[FACILITY_ID]    
  ,[FACILITY_CHART_ID]    
  ,[FACILITY_ADMIN_CHART_ID]    
  ,[MEDICAL_RECORD_NUM]    
  ,[PATIENT_TITLE]    
  ,[PATIENT_FIRST_NAME]    
  ,[PATIENT_MIDDLE_NAME]    
  ,[PATIENT_LAST_NAME]    
  ,[PATIENT_NAME_SUFFIX]    
  ,[PATIENT_ADDR_LINE_1]    
  ,[PATIENT_ADDR_LINE_2]    
  ,[PATIENT_CITY]    
  ,[PATIENT_STATE]    
  ,[PATIENT_ZIPCODE]    
  ,[PATIENT_DOB]    
  ,[TIME_OF_SERVICE]    
  ,[TIME_TO_ROOM]    
  ,[TIME_OF_PHYS_EVAL]    
  ,[TIME_OF_PHYS_DIS]    
  ,[TIME_OF_TRIAGE]    
  ,[TIME_OF_DIS]    
  ,[PHYSICIAN_ID]    
  ,[TRIAGE_NURSE_ID]    
  ,[DIS_NURSE_ID]    
  ,[DATE_RECEIVED]    
  ,[ASSIGNED_TO_ID]    
  ,[CHART_STATUS_ID]    
  ,[PENDING_REASON_ID]    
  ,[CODER_COMMENT]    
  ,[FAC_SVCS_COMPLETED]    
  ,[FAC_PROC_COMPLETED]    
  ,[PHYS_COMPLETED]    
  ,[PHYS_PROC_COMPLETED]    
  ,[PREBILL_AUDIT_COMPLETED]    
  ,[DEMOGRAPHICS_COMPLETED]    
  ,[RESULTS_COMPLETED]    
  ,[INFUSIONS_COMPLETED]    
  ,[FACILITY_CRITICAL_CARE]    
  ,[FACILITY_CRITICAL_CARE_MINUTES]    
  ,[PHYSICIAN_CRITICAL_CARE]    
  ,[PHYSICIAN_CRITICAL_CARE_MINUTES]    
  ,[FACILITY_LEVEL_ID]    
  ,[OVERRIDE_FACILITY_LEVEL_ID]    
  ,[PATIENT_DISPOSITION_ID]    
  ,[PHYSICIAN_HISTORY_ID]    
  ,[PHYSICIAN_EXAM_ID]    
  ,[PHYSICIAN_MDM_ID]    
  ,[PHYSICIAN_SERVICE_PROC_ID]    
  ,[PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID]    
  ,[OVERRIDE_PHYS_HIST_ID]    
  ,[OVERRIDE_PHYS_EXAM_ID]    
  ,[OVERRIDE_PHYS_MDM_ID]    
  ,[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]    
  ,[PHYSICIAN_SERVICE_MOD]    
  ,[COMPLETED_BY_USER_PROFILE_ID]    
  ,[APPROVED_BY_USER_PROFILE_ID]    
  ,[SENT_BY_USER_PROFILE_ID]    
  ,[COMPLETION_DATE]    
  ,[APPROVED_DATE]    
  ,[SENT_DATE]    
  ,[NON_ER_PROCEDURES_OVERRIDE]    
  ,[NO_FACILITY_SERVICES]    
  ,[NO_FACILITY_PROCEDURES]    
  ,[NO_PHYSICIAN_SERVICES]    
  ,[NO_PHYSICIAN_PROCEDURES]    
  ,[NO_PREBILL_AUDIT]    
  ,[NO_INJECTIONS_OR_INFUSIONS]    
  ,[EDITED_BY_EXPERT]    
  ,[NUMBER_OF_IV_PUSHES]    
  ,[IMAGES_AVAILABLE]    
  ,[DIAGNOSIS_CODING_COMPLETE]    
  ,[NO_DIAGNOSIS_CODING]    
  ,[CHIEF_COMPLAINT]    
  ,[PATIENT_CLASS_ID]    
  ,[PATIENT_CLASS_CD]    
  ,[INSUFFICIENT_PHYSICIAN_PROCEDURE_DOC]    
  ,[INSUFFICIENT_PHYSICIAN_PROCEDURE_REASON_ID]    
  ,[CLIENT_COMMENT]    
  ,[CHART_IMAGES_TRANSMITTED]    
  ,[FINANCIAL_CLASS_CD]    
  ,[DOCUMENTATION_COMPLETED]    
  ,[DOCUMENTATION_EVALUATION_OK]    
  ,[RESIDENT_ID]    
  ,[DEPARTMENT]    
  ,[LONG_PATIENT_ID1]    
  ,[LONG_PATIENT_ID2]    
  ,[NUMBER_OF_IV_PUSHES_SAME_SUB]    
  ,[APPROVAL_REASON_CODE]    
  ,[PRIMARY_COMPLAINT]    
  ,[PATIENT_DISPOSITION_MAP_ID]    
  ,[HORMONAL]    
  ,[NON_HORMONAL]    
  ,[INTERLESIONAL_7_OR_LESS]    
  ,[INTERLESIONAL_MORE_THAN_7]    
  ,[NUMBER_CHEMOTHERAPY_IV_PUSH]    
  ,[PROLONGED_IV_CHEMOTHERAPY]    
  ,[PROLONGED_IA_CHEMOTHERAPY]    
  ,[ADDITIONAL_CRITICAL_CARE_UNITS]    
  ,[SUPPLIES_COMPLETED]    
  ,[NO_SUPPLIES]    
  ,[ADDITIONAL_COMPLAINT]    
  ,[ADDITIONAL_COMPLAINT2]    
  ,[GENDER]    
  ,[HOSPITAL_POINTS]    
  ,[HOSPITAL_CHIEF_COMPLAINT]    
  ,[APPEARS_TO_QUALIFY_FOR_CRITICAL_CARE]    
  ,[SERVICES_PERFORMED_BY_RESIDENT]    
  ,[RESIDENT_PHYS_PRESENT]    
  ,[RESIDENT_PHYS_PRESENT_REF_RES_NOTES]    
  ,[RESIDENT_PHYS_PRESENT_DISCUSSED_PLAN]    
  ,[RESIDENT_PHYS_INDEPENDENT_REF_RES_NOTES]    
  ,[RESIDENT_PHYS_INDEPENDENT_PERSONALLY_SAW]    
  ,[RESIDENT_PHYS_INDEPENDENT_DISCUSSED]    
  ,[RESIDENT_CPT_ENTIRELY_PRESENT]    
  ,[RESIDENT_CPT_PRESENT_DURING_KEY_PORTION]    
  ,[FACILITY_LEVEL_CODER_COMMENT]    
  ,[CREATION_DATE_TIME]    
  ,[CREATING_USER_PROFILE_ID]    
  ,[CHANGED_DATE_TIME]    
  ,[CHANGING_USER_PROFILE_ID]    
  ,[OVERRIDE_LCD_ERRORS]    
  ,[EVER_COMPLETED]    
  ,[LAST_ENCOUNTER_DATE]    
  ,[SAFETY_DEVICE_CD]    
  ,[SPORT_TYPE_CD]    
  ,[RESIDENT_PARTICIPATED_IN_CARE]    
  ,[ATTESTATION_SIGNED_BY_ATTENDING]    
  ,[REPORT_CHIEF_COMPLAINT_AS_SECONDARY]    
  ,[REPORT_ADDITIONAL_COMPLAINT_AS_SECONDARY]    
  ,[REPORT_ADDITIONAL_COMPLAINT2_AS_SECONDARY]    
  ,[PATIENT_AGE]    
  ,[START_QA_USER_PROFILE_ID]    
  ,[START_QA_DATE]    
  ,[PHYSICIAN_SIGNATURE_PRESENT]    
  ,[OBS_DEPT_EVAL_COMPLETED]    
  ,[INITIAL_CHARGE_MASTER_DEPT_ID]    
  ,[PHYSICIAN_LEVEL_CODER_COMMENT]    
  ,[EXCLUDE_OBSERVATION_DIRECT_CHARGE]    
  ,[NURSE_PRACTITIONER_ID]    
  ,[ADD_MODIFIER_32_TO_PHYSICIAN_LOS]    
  ,[NO_PHYSICIAN_LOS_REASON_ID]    
  ,[CLINIC_ID]    
  ,[SERIAL_CODE]    
  ,[REGISTRATION_AREA]    
  ,[REGISTRATION_CODE]    
  ,[SERVICE_LINE_ID]    
  ,[TERMINAL_DIGITS]    
  ,[IMAGE_SOURCE_ID]    
  ,[PAYOR_CD]    
  ,[POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE]    
  ,[IS_PRIORITY]    
  ,[NO_ACTIVITY_CODES]    
  ,[NO_LCD_SERVICES]    
  ,[MODIFIER_25_REQUIRED_REASON_ID]    
  ,[CONDITION_OF_ACCIDENT_ID]    
  ,[ACCIDENT_DATE]    
  ,[ADMISSION_DATE_TIME]    
  ,[OBSERVATION_ATTENDING_PROVIDER_ID]    
  ,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]    
  ,[PATIENT_DISPOSITION_DESTINATION_ID]    
  ,[NO_OBSERVATION_HOURS]    
  ,[OBSERVATION_COMPLETED_BY_USER_PROFILE_ID]    
  ,[OBSERVATION_COMPLETION_DTTM]    
  ,[OBSERVATION_PROCEDURES_AUDIT_COMMENT]    
  ,[OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT]    
  ,[OBSERVATION_AUDITOR_REVIEW_FEEDBACK]    
  ,[FACILITY_LOS_27_MODIFIER]    
  ,[OBSERVATION_BILLING_METHOD_CD]    
  ,[ARRIVAL_DATE_TIME]    
  ,[SERVICE_AGREEMENT_TRIAGE_ACUITY_ID]    
  ,[SERVICE_AGREEMENT_ARRIVAL_MODE_ID]    
  ,[FACILITY_CRITICAL_CARE_CALC_METHOD_CD]    
  ,[FACILITY_CRITICAL_CARE_START_DATE]    
  ,[FACILITY_CRITICAL_CARE_STOP_DATE]    
  ,[PHYSICIAN_CRITICAL_CARE_CALC_METHOD_CD]    
  ,[PHYSICIAN_CRITICAL_CARE_START_DATE]    
  ,[PHYSICIAN_CRITICAL_CARE_STOP_DATE]    
  ,[AUDIT_REQUIRED]    
  ,[ARRIVAL_DATE_TIME_NOT_AVAILABLE]    
  ,[TIME_OF_TRIAGE_NOT_AVAILABLE]    
  ,[TIME_TO_ROOM_NOT_AVAILABLE]    
  ,[TIME_OF_PHYSICIAN_EVAL_NOT_AVAILABLE]    
  ,[ARRIVAL_MODE_NOT_AVAILABLE]    
  ,[TRIAGE_ACUITY_NOT_AVAILABLE]    
  ,[OBSERVATION_TELEMETRY]    
  ,[DEMOGRAPHIC_AUDIT_COMMENT]    
  ,[LAST_MENSTRUAL_PERIOD]    
  ,[PAYOR_NAME]    
  ,[SERVICE_AGREEMENT_MODE_OF_DEPARTURE_ID]    
  ,[ORGAN_DONATION]    
  ,[REASON_FOR_VISIT_CATEGORY_DETAIL_ID]    
  ,[ADD_MODIFIER_57_TO_PHYSICIAN_LOS]    
  ,[DO_NOT_APPLY_PHYSICIAN_MODIFER_25]    
  ,[ADD_MODIFIER_GW_TO_PHYSICIAN_LOS]    
  ,[PRIMARY_CARE_PHYSICIAN_ID]    
  ,[SCRIBE_ID]    
  ,[NO_ATTENDING_PROVIDER_SELECTED_IND]    
  ,[PROVIDER_EVAL_PERFORMED_BY_IND]    
  ,[BILLING_INSTRUCTIONS]    
  ,[PHYSICIAN_SERVICE_OBSERVATION_ADMIT_DATETIME]    
  ,[PHYSICIAN_SERVICE_OBSERVATION_DISCHARGE_DATETIME]    
  ,[PHYSICIAN_SERVICE_OBSERVATION_FINAL_EXAM]    
  ,[SUBSEQUENT_VISIT_CODE]    
  ,[SERVICE_AGREEMENT_ADMIT_TYPE_ID]    
  ,[LOCATION_CODE]    
  ,[BILLING_AREA]    
  ,[ADD_GC_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]    
  ,[ADD_GE_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]    
  ,[MEDICAL_EXAMINER_NOTIFIED]    
  ,[SEEN_IN_ED_WITHIN_48_HOURS_OF_OR]    
  ,[ADD_24_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]    
  ,[ADD_PHYSICIAN_SVC_25_MODIFIER]    
  ,[LMP_DATE_NOT_AVAILABLE]    
  ,[OBSERVATION_DISCHARGE_PROVIDER_ID]    
  ,[FORCED_AUDIT]    
  ,[FLAGGED_FOR_AUDIT]    
  ,[START_SECOND_LEVEL_QA_DATETIME]    
  ,[START_SECOND_LEVEL_QA_USER_PROFILE_ID]    
  ,[SECOND_LEVEL_QA_APPROVED_DATETIME]    
  ,[SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID]    
  ,[QUALIFIED_FOR_SECOND_AUDIT_AT_COMPLETION]    
  ,[FRACTURE_CARE_CPT_CHARGED]    
  ,[SERVICE_AGREEMENT_TRANSFER_FACILITY_ID]    
  ,[OVERRIDE_PHYSICIAN_SERVICE_GUIDELINE_ID]    
  ,[PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID]    
  ,[USE_TIME_BASED_CHARGE_CAPTURE]    
  ,[TIME_BASED_CHARGE_CAPTURE_COMMENT]    
  ,[TIME_BASED_PHYSICIAN_LOS]    
  ,[POST_BILL_AUDIT_STARTED]    
  ,[POST_BILL_AUDIT_STARTED_BY_USER_ID]    
  ,[POST_BILL_AUDIT_COMPLETED]    
  ,[POST_BILL_AUDIT_COMPLETED_BY_USER_ID]    
  ,[FLAGGED_FOR_POST_BILL_AUDIT_DT]    
  ,[ADD_59_XU_MODIFIER]    
  ,[ANESTHESIA_CODING_COMPLETE]    
  ,[NO_ANESTHESIA_CODING]    
  ,[USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE]    
  ,[PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID]    
  ,[USE_INPATIENT_DOWNCODE_OPTION]    
  ,[BYPASS_AUTO_APPROVAL]    
  ,[FACILITY_LOS_AF_MODIFIER]    
  ,[FACILITY_LOS_AG_MODIFIER]    
  ,[ADD_AI_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]    
  ,[DO_NOT_APPLY_FACILITY_MODIFIER_25]    
  ,[ADD_MODIFIER_CG_TO_PHYSICIAN_LOS]    
  ,[USE_EXPERT_HISTORY_WORKSHEET_SECTION]    
  ,[USE_EXPERT_EXAM_WORKSHEET_SECTION]    
  ,[USE_EXPERT_MDM_WORKSHEET_SECTION]    
  ,[ADD_MODIFIER_GQ_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_GT_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_G0_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_95_TO_PHYSICIAN_LOS]    
  ,[FACILITY_LOS_CS_MODIFIER]    
  ,[ADD_MODIFIER_CS_TO_PHYSICIAN_LOS]    
  ,[FACILITY_LOS_95_MODIFIER]    
  ,[ADD_MODIFIER_CR_TO_PHYSICIAN_LOS]    
  ,[CHART_HAS_QA_SCORECARD_DATA]    
  ,[CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES]    
  ,[CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE]    
  ,[CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE]    
  ,[CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY]    
  ,[CLINIC_2021_TIME_BASED_ADDITIONAL_CPT_CODE]    
  ,[ADD_MODIFIER_GV_TO_PHYSICIAN_LOS]    
  ,[PROVIDER_TYPE_CREDENTIALS_MODIFIER]    
  ,[SERVICE_AGREEMENT_PROVIDER_TYPE_CREDENTIAL_ID]    
  ,[ADD_MODIFIER_EP_TO_PHYSICIAN_LOS]    
  ,[PROVIDER_SPECIFIED_LOS_PHYSICIAN_SERVICE_PROC_ID]    
  ,[PROVIDER_SPECIFIED_LOS_MODIFIER]    
  ,[ADMIT_SOURCE_ID]    
  ,[DATE_TIME_OF_DEATH]    
  ,[FACILITY_AUTOMATION_CODING_COMPLETE]    
  ,[FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME]    
  ,[PHYSICIAN_AUTOMATION_CODING_COMPLETE]    
  ,[PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME]    
  ,[FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT]    
  ,[ADD_MODIFIER_AF_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_AG_TO_PHYSICIAN_LOS]    
  ,[CODER_ERROR_RESPONSE]    
  ,[CODER_ERROR_RESPONSE_COMMENTS]    
  ,[AUDITOR_ERROR_RESPONSE]    
  ,[AUDITOR_ERROR_RESPONSE_COMMENTS]    
  ,[CODER_RESPONSE_DATE]    
  ,[AUDITOR_RESPONSE_DATE]    
  ,[USE_TELEHEALTH]    
  ,[ATTESTATION_SYNCHRONIZED_AV_PRESENT]    
  ,[PLOS_ICD_10_CODE]    
  ,[ADD_MODIFIER_AM_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_U7_TO_PHYSICIAN_LOS]    
  ,[FACILITY_LOS_32_MODIFIER]    
  ,[NO_PROVIDER_SPECIFIED_PROCEDURES]    
  ,[ADD_MODIFIER_SA_TO_PHYSICIAN_LOS]    
  ,[ADD_MODIFIER_93_TO_PHYSICIAN_LOS] -- added DACS-2475 - 20230619 - pippin    
  ,[FACILITY_LOS_93_MODIFIER]   -- added DACS-2475 - 20230619 - pippin    
  ,[ADD_MODIFIER_FS_TO_PHYSICIAN_LOS] -- added DACS-2485 - 20230626 - pippin    
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED  
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED_DATE_TIME
  ,NO_PQRS -- added DACS-3533 - 20240814 - kpanwar
 FROM     
  [dbo].[CHART]     
 WHERE     
  [CHART_ID] = @CHART_ID;    
END    
-- End of 02) DACS-3533 - ALTER STORED PROC CHART_SELECT_BY_CHART_ID.sql
GO

-- Start of 03) DACS-3533 ALTER STORED PROC SelectChartByFacilityIdAndFacilityChartIdentifier.sql

------------------------------------------------------------------------------------
-- 03) DACS-3533 - ALTER PROCEDURE [SelectChartByFacilityIdAndFacilityChartIdentifier] to add NO_PQRS column to selection list
------------------------------------------------------------------------------------
GO

GO

GO
  
  
CREATE OR ALTER     PROCEDURE [dbo].[SelectChartByFacilityIdAndFacilityChartIdentifier]   
   @facilityId INT  
 , @facilityChartIdentifier VARCHAR(20)  
AS  
BEGIN  
 ----------------  
 -- Simple select statement used by ChartDAO.cs within ACS  
 ----------------  
  
 ----------------  
 -- validate parameters  
 ----------------  
 IF @facilityId IS NULL OR @facilityId <= 0  
 BEGIN  
  PRINT('@facilityId is invalid.');  
  RETURN;  
 END;  
  
 IF @facilityChartIdentifier IS NULL OR Len(@facilityChartIdentifier) <= 0  
 BEGIN  
  PRINT('@facilityChartIdentifier is invalid.');  
  RETURN;  
 END;  
  
 SET NOCOUNT ON  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    
 SELECT TOP 1 -- this is a just in case safety item, do not remove. ACS sometimes has issues regarding duplicates that are generated by clients via batch importing  
   CHART_ID   
        ,SERVICE_AGREEMENT_ID  
  ,FACILITY_ID  
  ,FACILITY_CHART_ID  
  ,FACILITY_ADMIN_CHART_ID  
        ,MEDICAL_RECORD_NUM  
  ,PATIENT_TITLE  
  ,PATIENT_FIRST_NAME  
  ,PATIENT_MIDDLE_NAME  
  ,PATIENT_LAST_NAME  
  ,PATIENT_NAME_SUFFIX  
  ,PATIENT_ADDR_LINE_1  
  ,PATIENT_ADDR_LINE_2  
  ,PATIENT_CITY  
  ,PATIENT_STATE  
  ,PATIENT_ZIPCODE  
  ,PATIENT_DOB  
  ,TIME_OF_SERVICE  
  ,TIME_TO_ROOM  
  ,TIME_OF_PHYS_EVAL  
  ,TIME_OF_PHYS_DIS  
  ,TIME_OF_TRIAGE  
  ,TIME_OF_DIS  
  ,PHYSICIAN_ID  
  ,TRIAGE_NURSE_ID  
  ,DIS_NURSE_ID  
  ,DATE_RECEIVED   
        ,ASSIGNED_TO_ID   
        ,CHART_STATUS_ID   
        ,PENDING_REASON_ID  
        ,CODER_COMMENT   
        ,FAC_SVCS_COMPLETED   
        ,FAC_PROC_COMPLETED  
        ,PHYS_COMPLETED  
  ,PHYS_PROC_COMPLETED  
  ,PREBILL_AUDIT_COMPLETED  
  ,DEMOGRAPHICS_COMPLETED  
  ,RESULTS_COMPLETED  
  ,INFUSIONS_COMPLETED  
  ,FACILITY_CRITICAL_CARE  
  ,FACILITY_CRITICAL_CARE_MINUTES  
  ,PHYSICIAN_CRITICAL_CARE  
  ,PHYSICIAN_CRITICAL_CARE_MINUTES  
  ,FACILITY_LEVEL_ID  
  ,OVERRIDE_FACILITY_LEVEL_ID  
  ,PATIENT_DISPOSITION_ID  
  ,PHYSICIAN_HISTORY_ID  
  ,PHYSICIAN_EXAM_ID  
  ,PHYSICIAN_MDM_ID  
  ,PHYSICIAN_SERVICE_PROC_ID  
  ,PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID   
  ,OVERRIDE_PHYS_HIST_ID  
  ,OVERRIDE_PHYS_EXAM_ID  
  ,OVERRIDE_PHYS_MDM_ID  
  ,OVERRIDE_PHYSICIAN_SERVICE_PROC_ID  
  ,PHYSICIAN_SERVICE_MOD  
  ,COMPLETED_BY_USER_PROFILE_ID  
  ,APPROVED_BY_USER_PROFILE_ID  
  ,SENT_BY_USER_PROFILE_ID  
  ,COMPLETION_DATE  
  ,APPROVED_DATE  
  ,SENT_DATE  
  ,NON_ER_PROCEDURES_OVERRIDE   
        ,NO_FACILITY_SERVICES   
        ,NO_FACILITY_PROCEDURES   
        ,NO_PHYSICIAN_SERVICES   
        ,NO_PHYSICIAN_PROCEDURES   
        ,NO_PREBILL_AUDIT   
  ,NO_INJECTIONS_OR_INFUSIONS  
  ,EDITED_BY_EXPERT   
        ,NUMBER_OF_IV_PUSHES   
        ,IMAGES_AVAILABLE   
        ,DIAGNOSIS_CODING_COMPLETE   
        ,NO_DIAGNOSIS_CODING   
  ,CHIEF_COMPLAINT  
  ,PATIENT_CLASS_ID   
  ,PATIENT_CLASS_CD  
  ,INSUFFICIENT_PHYSICIAN_PROCEDURE_DOC   
  ,INSUFFICIENT_PHYSICIAN_PROCEDURE_REASON_ID  
  ,CLIENT_COMMENT   
  ,CHART_IMAGES_TRANSMITTED  
  ,FINANCIAL_CLASS_CD   
  ,DOCUMENTATION_COMPLETED   
  ,DOCUMENTATION_EVALUATION_OK  
  ,RESIDENT_ID   
  ,DEPARTMENT   
  ,LONG_PATIENT_ID1   
  ,LONG_PATIENT_ID2  
  ,NUMBER_OF_IV_PUSHES_SAME_SUB   
  ,APPROVAL_REASON_CODE   
  ,PRIMARY_COMPLAINT   
  ,PATIENT_DISPOSITION_MAP_ID  
  ,HORMONAL  
  ,NON_HORMONAL  
  ,INTERLESIONAL_7_OR_LESS  
  ,INTERLESIONAL_MORE_THAN_7  
  ,NUMBER_CHEMOTHERAPY_IV_PUSH  
  ,PROLONGED_IV_CHEMOTHERAPY  
  ,PROLONGED_IA_CHEMOTHERAPY  
  ,ADDITIONAL_CRITICAL_CARE_UNITS  
  ,SUPPLIES_COMPLETED  
  ,NO_SUPPLIES  
  ,ADDITIONAL_COMPLAINT  
  ,ADDITIONAL_COMPLAINT2  
  ,GENDER  
  ,HOSPITAL_POINTS  
  ,HOSPITAL_CHIEF_COMPLAINT  
  ,APPEARS_TO_QUALIFY_FOR_CRITICAL_CARE  
  ,SERVICES_PERFORMED_BY_RESIDENT  
  ,RESIDENT_PHYS_PRESENT  
  ,RESIDENT_PHYS_PRESENT_REF_RES_NOTES  
  ,RESIDENT_PHYS_PRESENT_DISCUSSED_PLAN  
  ,RESIDENT_PHYS_INDEPENDENT_REF_RES_NOTES  
  ,RESIDENT_PHYS_INDEPENDENT_PERSONALLY_SAW  
  ,RESIDENT_PHYS_INDEPENDENT_DISCUSSED  
  ,RESIDENT_CPT_ENTIRELY_PRESENT  
  ,RESIDENT_CPT_PRESENT_DURING_KEY_PORTION  
  ,FACILITY_LEVEL_CODER_COMMENT  
        ,CREATION_DATE_TIME   
  ,CREATING_USER_PROFILE_ID   
        ,CHANGED_DATE_TIME   
        ,CHANGING_USER_PROFILE_ID   
        ,OVERRIDE_LCD_ERRORS  
  ,EVER_COMPLETED  
  ,LAST_ENCOUNTER_DATE   
        ,SAFETY_DEVICE_CD   
        ,SPORT_TYPE_CD   
        ,RESIDENT_PARTICIPATED_IN_CARE  
  ,ATTESTATION_SIGNED_BY_ATTENDING  
  ,REPORT_CHIEF_COMPLAINT_AS_SECONDARY   
        ,REPORT_ADDITIONAL_COMPLAINT_AS_SECONDARY   
        ,REPORT_ADDITIONAL_COMPLAINT2_AS_SECONDARY   
        ,PATIENT_AGE   
        ,START_QA_USER_PROFILE_ID  
  ,START_QA_DATE  
  ,PHYSICIAN_SIGNATURE_PRESENT  
  ,OBS_DEPT_EVAL_COMPLETED  
  ,INITIAL_CHARGE_MASTER_DEPT_ID  
  ,PHYSICIAN_LEVEL_CODER_COMMENT  
  ,EXCLUDE_OBSERVATION_DIRECT_CHARGE  
  ,NURSE_PRACTITIONER_ID   
  ,ADD_MODIFIER_32_TO_PHYSICIAN_LOS  
  ,NO_PHYSICIAN_LOS_REASON_ID  
  ,CLINIC_ID  
  ,SERIAL_CODE  
  ,REGISTRATION_AREA  
  ,REGISTRATION_CODE   
        ,SERVICE_LINE_ID   
        ,TERMINAL_DIGITS   
        ,IMAGE_SOURCE_ID   
        ,PAYOR_CD   
        ,POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE   
        ,IS_PRIORITY   
        ,NO_ACTIVITY_CODES  
  ,NO_LCD_SERVICES   
  ,MODIFIER_25_REQUIRED_REASON_ID  
  ,CONDITION_OF_ACCIDENT_ID  
  ,ACCIDENT_DATE  
  ,ADMISSION_DATE_TIME  
  ,OBSERVATION_ATTENDING_PROVIDER_ID   
  ,OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID  
  ,PATIENT_DISPOSITION_DESTINATION_ID  
  ,NO_OBSERVATION_HOURS   
  ,OBSERVATION_COMPLETED_BY_USER_PROFILE_ID   
  ,OBSERVATION_COMPLETION_DTTM  
  ,OBSERVATION_PROCEDURES_AUDIT_COMMENT  
  ,OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT   
  ,OBSERVATION_AUDITOR_REVIEW_FEEDBACK  
  ,FACILITY_LOS_27_MODIFIER  
  ,OBSERVATION_BILLING_METHOD_CD   
  ,ARRIVAL_DATE_TIME  
  ,SERVICE_AGREEMENT_TRIAGE_ACUITY_ID  
  ,SERVICE_AGREEMENT_ARRIVAL_MODE_ID   
  ,FACILITY_CRITICAL_CARE_CALC_METHOD_CD  
  ,FACILITY_CRITICAL_CARE_START_DATE  
  ,FACILITY_CRITICAL_CARE_STOP_DATE   
  ,PHYSICIAN_CRITICAL_CARE_CALC_METHOD_CD  
  ,PHYSICIAN_CRITICAL_CARE_START_DATE   
  ,PHYSICIAN_CRITICAL_CARE_STOP_DATE   
  ,AUDIT_REQUIRED  
  ,ARRIVAL_DATE_TIME_NOT_AVAILABLE   
  ,TIME_OF_TRIAGE_NOT_AVAILABLE   
        ,TIME_TO_ROOM_NOT_AVAILABLE   
        ,TIME_OF_PHYSICIAN_EVAL_NOT_AVAILABLE   
        ,ARRIVAL_MODE_NOT_AVAILABLE  
  ,TRIAGE_ACUITY_NOT_AVAILABLE   
  ,OBSERVATION_TELEMETRY   
        ,DEMOGRAPHIC_AUDIT_COMMENT   
        ,LAST_MENSTRUAL_PERIOD   
        ,PAYOR_NAME  
  ,SERVICE_AGREEMENT_MODE_OF_DEPARTURE_ID  
  ,ORGAN_DONATION  
  ,REASON_FOR_VISIT_CATEGORY_DETAIL_ID   
  ,ADD_MODIFIER_57_TO_PHYSICIAN_LOS  
  ,DO_NOT_APPLY_PHYSICIAN_MODIFER_25  
  ,ADD_MODIFIER_GW_TO_PHYSICIAN_LOS  
  ,PRIMARY_CARE_PHYSICIAN_ID  
  ,SCRIBE_ID  
  ,NO_ATTENDING_PROVIDER_SELECTED_IND   
  ,PROVIDER_EVAL_PERFORMED_BY_IND  
  ,BILLING_INSTRUCTIONS  
  ,PHYSICIAN_SERVICE_OBSERVATION_ADMIT_DATETIME  
  ,PHYSICIAN_SERVICE_OBSERVATION_DISCHARGE_DATETIME  
  ,PHYSICIAN_SERVICE_OBSERVATION_FINAL_EXAM  
  ,SUBSEQUENT_VISIT_CODE  
  ,SERVICE_AGREEMENT_ADMIT_TYPE_ID  
  ,LOCATION_CODE  
  ,BILLING_AREA  
  ,ADD_GC_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL  
  ,ADD_GE_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL  
  ,MEDICAL_EXAMINER_NOTIFIED  
  ,SEEN_IN_ED_WITHIN_48_HOURS_OF_OR  
  ,ADD_24_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL  
  ,ADD_PHYSICIAN_SVC_25_MODIFIER   
  ,LMP_DATE_NOT_AVAILABLE  
  ,OBSERVATION_DISCHARGE_PROVIDER_ID  
  ,FORCED_AUDIT  
  ,FLAGGED_FOR_AUDIT   
  ,START_SECOND_LEVEL_QA_DATETIME  
  ,START_SECOND_LEVEL_QA_USER_PROFILE_ID  
  ,SECOND_LEVEL_QA_APPROVED_DATETIME  
  ,SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID  
  ,QUALIFIED_FOR_SECOND_AUDIT_AT_COMPLETION   
  ,FRACTURE_CARE_CPT_CHARGED  
  ,SERVICE_AGREEMENT_TRANSFER_FACILITY_ID  
  ,OVERRIDE_PHYSICIAN_SERVICE_GUIDELINE_ID  
  ,PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID   
  ,USE_TIME_BASED_CHARGE_CAPTURE  
  ,TIME_BASED_CHARGE_CAPTURE_COMMENT  
  ,TIME_BASED_PHYSICIAN_LOS  
  ,POST_BILL_AUDIT_STARTED  
  ,POST_BILL_AUDIT_STARTED_BY_USER_ID   
  ,POST_BILL_AUDIT_COMPLETED  
  ,POST_BILL_AUDIT_COMPLETED_BY_USER_ID  
  ,FLAGGED_FOR_POST_BILL_AUDIT_DT  
  ,ADD_59_XU_MODIFIER   
  ,ANESTHESIA_CODING_COMPLETE  
  ,NO_ANESTHESIA_CODING  
  ,USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE  
  ,PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID  
  ,USE_INPATIENT_DOWNCODE_OPTION  
  ,BYPASS_AUTO_APPROVAL   
  ,FACILITY_LOS_AF_MODIFIER  
  ,FACILITY_LOS_AG_MODIFIER  
  ,ADD_AI_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL  
  ,DO_NOT_APPLY_FACILITY_MODIFIER_25  
  ,ADD_MODIFIER_CG_TO_PHYSICIAN_LOS  
  ,USE_EXPERT_HISTORY_WORKSHEET_SECTION  
  ,USE_EXPERT_EXAM_WORKSHEET_SECTION  
  ,USE_EXPERT_MDM_WORKSHEET_SECTION   
  ,ADD_MODIFIER_GQ_TO_PHYSICIAN_LOS  
  ,ADD_MODIFIER_GT_TO_PHYSICIAN_LOS  
  ,ADD_MODIFIER_G0_TO_PHYSICIAN_LOS  
  ,ADD_MODIFIER_95_TO_PHYSICIAN_LOS  
  ,FACILITY_LOS_CS_MODIFIER  
  ,ADD_MODIFIER_CS_TO_PHYSICIAN_LOS  
  ,FACILITY_LOS_95_MODIFIER  
  ,ADD_MODIFIER_CR_TO_PHYSICIAN_LOS  
  ,CHART_HAS_QA_SCORECARD_DATA   
  ,CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES  
  ,CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE  
  ,CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE   
  ,CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY  
  ,CLINIC_2021_TIME_BASED_ADDITIONAL_CPT_CODE  
  ,ADD_MODIFIER_GV_TO_PHYSICIAN_LOS  
  ,PROVIDER_TYPE_CREDENTIALS_MODIFIER  
  ,SERVICE_AGREEMENT_PROVIDER_TYPE_CREDENTIAL_ID   
  ,ADD_MODIFIER_EP_TO_PHYSICIAN_LOS  
  ,PROVIDER_SPECIFIED_LOS_PHYSICIAN_SERVICE_PROC_ID  
  ,PROVIDER_SPECIFIED_LOS_MODIFIER  
  ,ADMIT_SOURCE_ID, DATE_TIME_OF_DEATH   
  ,FACILITY_AUTOMATION_CODING_COMPLETE  
  ,FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME  
  ,PHYSICIAN_AUTOMATION_CODING_COMPLETE  
  ,PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME  
  ,FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT   
  ,ADD_MODIFIER_AF_TO_PHYSICIAN_LOS  
        ,ADD_MODIFIER_AG_TO_PHYSICIAN_LOS  
        ,CODER_ERROR_RESPONSE  
        ,CODER_ERROR_RESPONSE_COMMENTS  
        ,AUDITOR_ERROR_RESPONSE  
        ,AUDITOR_ERROR_RESPONSE_COMMENTS  
        ,CODER_RESPONSE_DATE  
        ,AUDITOR_RESPONSE_DATE  
        ,USE_TELEHEALTH  
        ,ATTESTATION_SYNCHRONIZED_AV_PRESENT  
        ,PLOS_ICD_10_CODE  
        ,ADD_MODIFIER_AM_TO_PHYSICIAN_LOS  
        ,ADD_MODIFIER_U7_TO_PHYSICIAN_LOS  
        ,FACILITY_LOS_32_MODIFIER  
        ,NO_PROVIDER_SPECIFIED_PROCEDURES  
  ,ADD_MODIFIER_SA_TO_PHYSICIAN_LOS  
  ,ADD_MODIFIER_93_TO_PHYSICIAN_LOS  
  ,FACILITY_LOS_93_MODIFIER  
  ,ADD_MODIFIER_FS_TO_PHYSICIAN_LOS  
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED -- added column DACS-3484 - 2024-08-15  
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED_DATE_TIME -- added column DACS-3484 - 2024-08-15  
  ,NO_PQRS -- added DACS-3533 - 20240814 - kpanwar
 FROM [CHART]  
 WHERE   
     [FACILITY_ID] = @facilityId  
  AND [FACILITY_CHART_ID] = @facilityChartIdentifier;  
  
END -- end procedure  
  
-- End of 03) DACS-3533 ALTER STORED PROC SelectChartByFacilityIdAndFacilityChartIdentifier.sql
GO

-- Start of 04) DACS-3533 CREATE STORED PROC UpdateChartPQRSByChart.sql

-----------------------------------------------------------------------------
-- 04) DACS-3533 - Create or Alter Stored Procedure - [dbo].[UpdateChartPQRSByChart].SQL
-----------------------------------------------------------------------------
GO

GO

GO
    
CREATE OR ALTER PROCEDURE [dbo].[UpdateChartPQRSByChart]    
	 @ChartId INT    
	,@PqrsValue BIT    
AS    
BEGIN    
	IF @ChartId IS NULL OR @ChartId <= 0
		RETURN;    
    
	SET NOCOUNT ON    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    

	UPDATE [CHART]
		SET NO_PQRS = @PqrsValue
	WHERE 
	    [CHART_ID] = @ChartId
	  
END -- end procedure

GO
-- End of 04) DACS-3533 CREATE STORED PROC UpdateChartPQRSByChart.sql
GO

-- Start of 01) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectChartPqrs', @DestProc = 'spSelectChartPqrs_DACS-3417';
GO

CREATE OR ALTER PROCEDURE [dbo].[spSelectChartPqrs] 
	@ChartId INT,
	@MeasureId INT = NULL,
	@MeasureCodeId INT = NULL
	WITH
EXEC AS CALLER AS

------------------------------------------------------------------------------------
-- Adds additional CODING_SYSTEM strings used within the various temporary tables to allow for extended behavior supporting new MIPS decision logic - DACS-3164 - 20240422 - pippin
------------------------------------------------------------------------------------

-- testing
-- DECLARE @ChartId INT = 2100107114;
-- DECLARE @MeasureId INT = NULL;
-- DECLARE @MeasureCodeId INT = NULL;
-- body of original SPROC -- >

DECLARE @chart_id INT = @ChartId;
DECLARE @measure_id INT = @MeasureId;
DECLARE @measure_code_id INT = @MeasureCodeId;
DECLARE @Now DATETIME = GETDATE();
DECLARE @flag VARCHAR(10) = '';
DECLARE @HasDXCode INT;
DECLARE @HasCPTCode INT;

Declare @PSP_CPT varchar(50)	-- added 2/21/2023 (dsexton)

-- Drop statements for new temp tables added 2/21/2023 (dsexton)
if object_id('TempDB..#MeasureList', 'U') is not null DROP TABLE #MeasureList;
if object_id('TempDB..#RequireCptMeasures', 'U') is not null DROP TABLE #RequireCptMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures2', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures2;
if object_id('TempDB..#RequiredMeasures2', 'U') is not null DROP TABLE #RequiredMeasures2;
if object_id('TempDB..#RequiredMeasuresOldLogic', 'U') is not null DROP TABLE #RequiredMeasuresOldLogic;
if object_id('TempDB..#Chart', 'U') is not null DROP TABLE #Chart;
--if object_id('TempDB..#ChartDiagCode9', 'U') is not null DROP TABLE #ChartDiagCode9;	-- DACS-3417, 08/19/2024 (pippin)
if object_id('TempDB..#ChartDiagCodeICD10', 'U') is not null DROP TABLE #ChartDiagCodeICD10;
if object_id('TempDB..#PPE_CPT', 'U') is not null DROP TABLE #PPE_CPT;

-- new temp table for tuning, 2/21/2023 (dsexton)
select chart_ID, service_agreement_ID, primary_complaint, chief_complaint, PHYSICIAN_SERVICE_PROC_ID, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
	, Time_of_Service, gender, patient_DOB, patient_age
  into #Chart	
from CHART
where chart_ID = @chart_id

-- select * from #Chart -- testing

/*
This sproc executes very frequently at certain times of the day. For example, on 2/21/2023 it executed nearly 8K times between 4:30-7:30 AM. By 3 pm it executed only an additional 3,500 times.
It is called by sproc spSelectMissingChartPqrs which has executed 37K times over the past seven days. 
Avg LReads have been 150K which adds up to several billion reads each day. 

Modified all CLR queries to instead write to temp tables, 2/21/2023 (dsexton).  This reduced logical reads 95% (13K vs 240K) when testing with chart_ID 101104526.
	-- Duration was reduced 80% (31ms vs 184ms).
*/


--WITH MeasureList						-- replaced all CLR queries with temp tables, 2/21/2023 (dsexton)
--AS (
	SELECT cpm.CMS_PQRI_MEASURE_ID,
		cpm.MEASURE_TITLE,
		cpm.REQUIRES_BOTH_CPT_AND_DX,
		cpmc.CMS_PQRI_MEASURE_CODE_ID,
		cpmc.CODING_SYSTEM,
		cpmc.OPTION_GROUP,
		cpmc.CODE,
		cpmc.MODIFIER,
		cpmc.[DESCRIPTION],
		CASE 
			WHEN cpmc.END_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.END_DATE 
			END END_DATE,
		cpmc.CODE_2,
		cpmc.MODIFIER_2,
		cpm.REQUIRES_MULTIPLE_CPTS,
		cpm.MULTIPLE_CPT_COUNT,
		cpm.REQUIRES_MULTIPLE_DX,
		cpm.REQUIRES_CPT_CODE,
		cpm.REQUIRED_CPT_CODE,
		CASE 
			WHEN COALESCE(cpm.REQUIRES_EM_ONLY, 0) = 1
				AND (c.PHYSICIAN_SERVICE_PROC_ID > 0 OR c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0)
				THEN 1
			ELSE 0
			END REQUIRES_EM_ONLY,
		CASE 
			WHEN COALESCE(cpm.MATCH_EM_LEVEL, 0) = 1
				THEN 1
			ELSE 0
			END MATCH_EM_LEVEL,
		CASE 
			WHEN cpmc.START_DATE IS NULL
				THEN '1/1/1900 00:00:00'
			ELSE cpmc.START_DATE
			END START_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE IS NULL
				THEN '02/20/2020 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
	    CONVERT(Date, c.TIME_OF_SERVICE) as DATE_OF_SERVICE,
		cpm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		cpm.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #MeasureList							-- tuning, 2/21/2023 (dsexton)
	FROM CMS_PQRI_MEASURE cpm WITH (NOLOCK)
	LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc WITH (NOLOCK) ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID
	--INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
	cross join #Chart c		--ON c.CHART_ID = @chart_id
	WHERE DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, c.TIME_OF_SERVICE)
		AND (
			ISNULL(cpm.GENDER, 'B') = 'B'
			OR cpm.GENDER = c.GENDER
			)
		AND (
			(
				(COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) = 0
				AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0)) = 999
				)
			OR (
				(c.PATIENT_AGE IS NOT NULL AND c.PATIENT_DOB IS NULL
				AND c.PATIENT_AGE BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				))
			
			OR (
				(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NOT NULL OR cpm.TO_AGE_FRACTIONAL IS NOT NULL)
				AND ((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				)
			
			OR (
			(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NULL AND cpm.TO_AGE_FRACTIONAL IS NULL)
				AND CAST(((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) AS INT) BETWEEN COALESCE(cpm.FROM_AGE, 0)  AND COALESCE(cpm.TO_AGE, 999)
				)
			)

		AND cpm.CMS_PQRI_MEASURE_ID IN (
			SELECT sapqrs.CMS_PQRI_MEASURE_ID
			FROM SERVICE_AGREEMENT_PQRS sapqrs WITH (NOLOCK)
			WHERE sapqrs.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND CONVERT(Date, c.TIME_OF_SERVICE) BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, @Now)
			)
	--),

-- select '#MeasureList' = null
-- select * from #MeasureList where measure_title like '%332%' OR measure_title like '% 7-%' -- testing


-- New objects for tuning, 2/21/2023 (dsexton)  -------------------------------------------------------------------------------
/* -- DACS-3417, 08/19/2024 (pippin)
SELECT cdc.ICD9_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, c.CHIEF_COMPLAINT, c.PRIMARY_COMPLAINT, c.Time_of_Service
  into #ChartDiagCode9
FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
*/

SELECT cdc.ICD10_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, cdc.DIAGNOSIS_TYPE_ID, cdc.IS_PRIMARY, c.Time_of_Service
  into #ChartDiagCodeICD10
FROM CHART_DIAGNOSIS_CODE_ICD10 cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID

SELECT cm.CPT_Code
  into #PPE_CPT
FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
	and ppe.CHART_ID = @chart_id	

select TOP 1 @PSP_CPT = CPT_CODE
FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
INNER JOIN #Chart c 
on PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
WHERE PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
        WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
            THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
        ELSE c.PHYSICIAN_SERVICE_PROC_ID
        END
-------------------------------------------------------------------------------------------------------------------

--RequiredMeasuresOldLogic
--AS (
SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		ROW_NUMBER() OVER (
			PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredMeasuresOldLogic	-- tuning, 2/21/2023 (dsexton)
	--FROM MeasureList ml
	from #MeasureList ml		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE (
			/*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
				
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR (cdc.DIAGNOSIS_TYPE_ID IN (1,3,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			OR (
				ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select 1 from #PPE_CPT as t where t.CPT_Code = ml.Code		-- tuning to replace old subquery, 2/21/2023 (dsexton)
					)
				)
			)
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
      ml.REQUIRES_EM_ONLY = 1
      AND 
			@PSP_CPT	 -- tuning to replace subquery, 2/21/2023 (dsexton)
			  IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395')
    )
--	)
-- select '#RequiredMeasuresOldLogic' = null
-- select * from #RequiredMeasuresOldLogic where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--,
--RequiredDiagnosisMeasures
--AS (

	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 		   
		  /*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 1)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			

--    )
	  
-- select '#RequiredDiagnosisMeasures' = null
-- select * from #RequiredDiagnosisMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
	
--	,
--	RequiredDiagnosisMeasures2
--AS (
	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures2
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 
		 /*  -- DACS-3417, 08/19/2024 (pippin)
		  ml.CODING_SYSTEM = 'I9'
			AND EXISTS (
			/-*	-- example of old subquery, 2/21/2023 (dsexton)
				SELECT *
				FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
				INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = cdc.CHART_ID
				INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				WHERE cdc.CHART_ID = @chart_id
			*-/
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 0)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						)
			
			)
 --   )
	  
-- select '#RequiredDiagnosisMeasures2' = null
-- select * from #RequiredDiagnosisMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--	,
--	RequireCptMeasures
--AS (
     SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequireCptMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					SELECT *
					FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
					INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
					WHERE ppe.CHART_ID = @chart_id
						AND cm.CPT_CODE = ml.CODE
						AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					)
				
			
			
			
			
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
		ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
      AND  (
              SELECT  CPT_CODE
              FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
              INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
              WHERE PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                  AND PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
                      WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
                          THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                      ELSE c.PHYSICIAN_SERVICE_PROC_ID
                      END 
              ) = ml.Code
			  AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
			  )
--),

-- select '#RequireCptMeasures' = null
-- select * from #RequireCptMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--	RequiredMeasures2
--AS (
   
    SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
		rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
into #RequiredMeasures2
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		
		UNION
		SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
        rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS = 1
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		GROUP BY rdm.CMS_PQRI_MEASURE_ID, rdm.MEASURE_TITLE, rdm.REQUIRES_BOTH_CPT_AND_DX, rdm.CMS_PQRI_MEASURE_CODE_ID, rdm.CODING_SYSTEM, rdm.OPTION_GROUP, rdm.CODE, rdm.MODIFIER, rdm.[DESCRIPTION], rdm.END_DATE, rdm.CODE_2, rdm.MODIFIER_2, rdm.REQUIRES_EM_ONLY, rdm.MEASURE_TOOLTIP, rdm.MEASURE_HOTSHEET_URI, rcm.MULTIPLE_CPT_COUNT
		HAVING COUNT(rcm.CODE) = rcm.MULTIPLE_CPT_COUNT

		UNION
		SELECT rdm2.CMS_PQRI_MEASURE_ID,
		rdm2.MEASURE_TITLE,
		rdm2.REQUIRES_BOTH_CPT_AND_DX,
		rdm2.CMS_PQRI_MEASURE_CODE_ID,
		rdm2.CODING_SYSTEM,
		rdm2.OPTION_GROUP,
		rdm2.CODE,
		rdm2.MODIFIER,
        rdm2.[DESCRIPTION],
		rdm2.END_DATE,
		rdm2.CODE_2,
		rdm2.MODIFIER_2,
		rdm2.REQUIRES_EM_ONLY,
		rdm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm2.CMS_PQRI_MEASURE_ID ORDER BY rdm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures2 rdm2
		from #RequiredDiagnosisMeasures2 rdm2															-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID				-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		AND rdm2.CODE IS NOT NULL
		UNION
		
		SELECT rmol.CMS_PQRI_MEASURE_ID,
		rmol.MEASURE_TITLE,
		rmol.REQUIRES_BOTH_CPT_AND_DX,
		rmol.CMS_PQRI_MEASURE_CODE_ID,
		rmol.CODING_SYSTEM,
		rmol.OPTION_GROUP,
		rmol.CODE,
		rmol.MODIFIER,
		rmol.[DESCRIPTION],
		rmol.END_DATE,
		rmol.CODE_2,
		rmol.MODIFIER_2,
		rmol.REQUIRES_EM_ONLY,
		rmol.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rmol.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rmol.CMS_PQRI_MEASURE_ID ORDER BY rmol.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredMeasuresOldLogic rmol
		from #RequiredMeasuresOldLogic rmol			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		WHERE rmol.REQUIRES_BOTH_CPT_AND_DX = 1
		AND CONVERT(Date, rmol.DATE_OF_SERVICE) < rmol.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
		AND rmol.CODE IS NOT NULL
		
		
		UNION
		 
		SELECT rcm.CMS_PQRI_MEASURE_ID,
		rcm.MEASURE_TITLE,
		rcm.REQUIRES_BOTH_CPT_AND_DX,
		rcm.CMS_PQRI_MEASURE_CODE_ID,
		rcm.CODING_SYSTEM,
		rcm.OPTION_GROUP,
		rcm.CODE,
		rcm.MODIFIER,
		rcm.[DESCRIPTION],
		rcm.END_DATE,
		rcm.CODE_2,
		rcm.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm.CMS_PQRI_MEASURE_ID ORDER BY rcm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm
		from #RequireCptMeasures rcm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND COALESCE(rcm.REQUIRES_CPT_CODE, 0) = 0
		AND rcm.CODE IS NOT NULL

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		 

		 UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--)

-- select '#RequiredMeasures2' = null
-- select * from #RequiredMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

	
SELECT DISTINCT CMS_PQRI_MEASURE_ID,
	MEASURE_TITLE,
	CMS_PQRI_MEASURE_CODE_ID,
	CODING_SYSTEM,
	NULL OPTION_GROUP,
	CASE COALESCE(REQUIRES_EM_ONLY, 0)
		WHEN 1
			THEN 'E&M'
		ELSE CODE
		END CODE,
	NULL MODIFIER,
	NULL [DESCRIPTION],
	NULL END_DATE,
	NULL CODE_2,
	NULL MODIFIER_2,
	NULL MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	NULL MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	CAST([ROW_NUMBER] AS BIGINT) [ROW_NUMBER]
--FROM RequiredMeasures2
from #RequiredMeasures2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
WHERE @measure_id IS NULL
	AND @measure_code_id IS NULL
	AND [ROW_NUMBER] = 1

UNION

SELECT ml.CMS_PQRI_MEASURE_ID,
	ml.MEASURE_TITLE,
	ml.CMS_PQRI_MEASURE_CODE_ID,
	ml.CODING_SYSTEM,
	ml.OPTION_GROUP,
	ml.CODE,
	ml.MODIFIER,
	ml.[DESCRIPTION],
	ml.END_DATE,
	ml.CODE_2,
	ml.MODIFIER_2,
	ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	ml.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	NULL [ROW_NUMBER]
--FROM MeasureList ml
from #MeasureList ml						-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--INNER JOIN RequiredMeasures2 rm ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
INNER JOIN #RequiredMeasures2 rm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
WHERE (
		ml.CMS_PQRI_MEASURE_ID = @measure_id
		OR ml.CMS_PQRI_MEASURE_CODE_ID = @measure_code_id
		)
	AND ml.CODING_SYSTEM IN (
		'CPT_II',
		'HCPCS'
		)
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
	
ORDER BY CMS_PQRI_MEASURE_ID ASC,
	MEASURE_TITLE DESC

GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'spSelectChartPqrs', N'PARAMETER',N'@MeasureCodeId'))
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
END

GO


-- End of 01) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL
GO

-- Start of 02) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectMissingChartPqrs', @DestProc = 'spSelectMissingChartPqrs_DACS-3417';
GO

CREATE OR ALTER   PROCEDURE [dbo].[spSelectMissingChartPqrs]
	@ChartId int
WITH EXEC AS CALLER
AS

SET NOCOUNT ON							-- DACS-3457 - 20240723 - pippin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @chart_id INT =@ChartId;
DECLARE @RequiredMeasures table
(
  CMS_PQRI_MEASURE_ID int,
  MEASURE_TITLE varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  CMS_PQRI_MEASURE_CODE_ID int,
  CODING_SYSTEM varchar(20),
  OPTION_GROUP numeric(18,0),
  CODE varchar(20),
  MODIFIER varchar(20),
  [DESCRIPTION] varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  END_DATE date,
  CODE_2 varchar(6),
  MODIFIER_2 varchar(20),
  MEASURE_TOOLTIP varchar(4000), 		-- DACS-3417 - 20240830 - pippin - added field
  MEASURE_HOTSHEET_URI varchar(1000), 	-- DACS-3417 - 20240830 - pippin - added field
  [ROW_NUMBER] bigint
)

INSERT INTO @RequiredMeasures(CMS_PQRI_MEASURE_ID, MEASURE_TITLE, CMS_PQRI_MEASURE_CODE_ID, CODING_SYSTEM, OPTION_GROUP, CODE, MODIFIER, [DESCRIPTION], END_DATE, CODE_2, MODIFIER_2, MEASURE_TOOLTIP, MEASURE_HOTSHEET_URI, [ROW_NUMBER])
  EXEC [spSelectChartPqrsTest1] @ChartId=@chart_id

SELECT *
FROM @RequiredMeasures rm
WHERE (SELECT COUNT(*)
       FROM PHYSICIAN_PROCEDURE_EVALUATION ppe
         JOIN CHARGE_MASTER cm on cm.CHARGE_MASTER_ID=ppe.PHYSICIAN_PROCEDURE_ID
         JOIN CMS_PQRI_MEASURE_CODE cpmc on cpmc.CMS_PQRI_MEASURE_ID=rm.CMS_PQRI_MEASURE_ID
       WHERE CHART_ID=@chart_id
         AND cm.CHARGE_MASTER_USAGE_CODE=9
         AND cpmc.CODING_SYSTEM in ('CPT_II', 'HCPCS')
         AND cm.CPT_CODE=cpmc.CODE
         AND ppe.MODIFIERS=isnull(cpmc.MODIFIER, ''))=0
GO


-- End of 02) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL
GO

-- Start of 03) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'SelectCmsPqrsMeasureResultsListById', @DestProc = 'SelectCmsPqrsMeasureResultsListById_DACS-3417';
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListById] 
	 @MeasureId INT
	,@Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		--PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));	-- DACS-3417, 08/19/2024 (pippin)
	END;

	DECLARE @dateOfService DATE = CAST(@Dos AS DATE);			-- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 cpm.[CMS_PQRI_MEASURE_ID]
		,cpm.[MEASURE_TITLE]
		,cpmc.[CMS_PQRI_MEASURE_CODE_ID]
		,cpmc.[CODING_SYSTEM]
		,cpmc.[OPTION_GROUP]
		,cpmc.[CODE]
		,cpmc.[MODIFIER]
		,cpmc.[DESCRIPTION]
		,
		CASE 
			WHEN cpmc.[END_DATE] IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.[END_DATE] 
			END [END_DATE]
		,cpmc.[CODE_2]
		,cpmc.[MODIFIER_2]
		,cpm.[MEASURE_TOOLTIP]				-- DACS-3417, 08/19/2024 (pippin)
		,cpm.[MEASURE_HOTSHEET_URI]			-- DACS-3417, 08/19/2024 (pippin)
		,NULL [ROW_NUMBER]
	FROM 
		[CMS_PQRI_MEASURE] cpm
		LEFT JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID] = cpm.[CMS_PQRI_MEASURE_ID]
	WHERE 
		--DATEADD(DAY, DATEDIFF(DAY, 0, @dateOfService), 0) BETWEEN cpm.[EFFECTIVE_DATE] AND ISNULL(cpm.[EXPIRATION_DATE], @dateOfService) -- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types
		(cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] >= @dateOfService)
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] >= @dateOfService) 
		AND cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[CODING_SYSTEM] IN ('CPT_II','HCPCS')
	ORDER BY 
		cpmc.[CODE], cpmc.[MODIFIER]
	;

END -- end procedure

GO


-- End of 03) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
GO

-- Start of 04) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'SelectCmsPqrsMeasureResultsListByPqrsNum', @DestProc = 'SelectCmsPqrsMeasureResultsListByPqrsNum_DACS-3417';
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] 
	  @PqrsNum VARCHAR(20)
	, @Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @PqrsNum IS NULL OR LEN(@PqrsNum) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @PqrsNum';
		RETURN;
	END;

	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		-- PRINT('==> @Dos set to ' + CAST(@Dos AS VARCHAR(40)));	-- DACS-3417, 08/19/2024 (pippin)
	END;

	DECLARE @dateOfService DATE = CAST(@Dos AS DATE);			-- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types
		
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @MeasureId INT = (
		SELECT TOP 1 
			[CMS_PQRI_MEASURE_ID] 
		FROM 
			[CMS_PQRI_MEASURE]
		WHERE 
			[pqrs#] = @PqrsNum
			AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] <= @dateOfService)	-- DACS-3417, 08/19/2024 (pippin)
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @dateOfService)
		);

	-- PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );	-- DACS-3417, 08/19/2024 (pippin)

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );	-- DACS-3417, 08/19/2024 (pippin)
	
	EXEC SelectCmsPqrsMeasureResultsListById @MeasureId=@MeasureId, @Dos=@Dos;

END -- end procedure

GO


-- End of 04) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL
GO

-- Start of 01) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentProcedureCodesByChartId].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentProcedureCodesByChartId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

-- drop type 
DROP TYPE IF EXISTS t2xString32;

CREATE TYPE t2xString32 AS TABLE
(
	 Value1 VARCHAR(32)
	,Value2 VARCHAR(32)
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------

CREATE or Alter FUNCTION [dbo].[udfMIPSSelectPresentProcedureCodesByChartId]
(
	  @ChartId INT
	 ,@ServiceAgreementId INT
)
RETURNS @returnResults TABLE
(
	 Value1 VARCHAR(32)
	,Value2 VARCHAR(32)
)
AS
BEGIN
	----------------
	-- Present Procedure List 
	----------------
	INSERT INTO 
		@returnResults
	SELECT 
		 cm.[CPT_CODE] AS Value1
		,ppe.[MODIFIERS]  AS Value2
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE] p
		INNER JOIN [CHART] c ON p.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE 
		p.[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND p.[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO @returnResults ([Value1]) VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) >= 2 
		INSERT INTO @returnResults ([Value2]) VALUES (@PSP_MODIFIERS);
	 
	-- IF @ShowDebug <> 0 SELECT * FROM @returnResults; -- testing
	RETURN;
 END; -- end function

GO
-- End of 01) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentProcedureCodesByChartId].SQL
GO

-- Start of 02) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectCodeTableByCodingSystem].SQL

----------------------------------------
-- 02) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectCodeTableByCodingSystem].SQL
----------------------------------------
GO

GO

GO

-- drop type 
DROP TYPE IF EXISTS tIntString32;

CREATE TYPE tIntString32 AS TABLE
(
	 Id INT
	,Value VARCHAR(32)
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectCodeTableByCodingSystem]
(
	 @MeasureId INT
	,@CodingSystem VARCHAR(32) 
)
RETURNS @Codes TABLE
(
     Id INT
	,Value VARCHAR(32)
)
WITH EXECUTE AS CALLER
AS
BEGIN
	INSERT INTO 
		@Codes
	SELECT 
		 [CMS_PQRI_MEASURE_CODE_ID] AS Id
		,[CODE] AS Value
	FROM 
		[dbo].[CMS_PQRI_MEASURE_CODE]
	WHERE
		[CMS_PQRI_MEASURE_ID] = @measureId
		AND [CODING_SYSTEM] = @CodingSystem
		AND ([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] >= GETDATE())
	;		

	RETURN;
END;

GO

/*
-- testing
DECLARE @MipsCodes tIntString32;
INSERT INTO @MipsCodes SELECT * FROM dbo.udfMipsSelectCodeTableByCodingSystem(148,'C4');
SELECT * FROM @MipsCodes
*/
-- End of 02) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectCodeTableByCodingSystem].SQL
GO

-- Start of 03) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureIdFromPqrsCode].SQL

----------------------------------------
-- 03) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureIdFromPqrsCode].SQL
----------------------------------------
GO

GO

GO

CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMeasureIdFromPqrsCode]
(
	 @PqrsCode VARCHAR(32) 
	,@Dos DATETIME
)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN

	IF @PqrsCode IS NOT NULL AND LEN(LTRIM(RTRIM(@PqrsCode))) > 0
	BEGIN
		DECLARE @testPqrs INT = (
			SELECT TOP 1 
				[CMS_PQRI_MEASURE_ID] 
			FROM 
				[dbo].[CMS_PQRI_MEASURE] 
			WHERE 
				[PQRS#] = @PqrsCode 
				AND [EFFECTIVE_DATE] <= @Dos 
				AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) 
		);

		IF @testPqrs IS NOT NULL AND @testPqrs > 0
			RETURN @testPqrs;
	END;
	
	RETURN -1;
END;

GO

/*
-- testing
DECLARE @MipsId INT = dbo.udfMipsSelectMeasureIdFromPqrsCode('005-A','08-01-2024');
SELECT '@MipsId' = @MipsId
*/
-- End of 03) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureIdFromPqrsCode].SQL
GO

-- Start of 04) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE or Alter FUNCTION [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId]
(
	  @ChartId INT
)
RETURNS @returnResults TABLE
(
	 Id INT
	,Value VARCHAR(32)
)
AS
BEGIN
	----------------
	-- Present Diagnosis List 
	----------------
	INSERT INTO
		@returnResults
	SELECT 
		 [CHART_DIAGNOSIS_CODE_ICD10_ID] AS Id
		,[ICD10_CODE] AS Value
	FROM 
		[dbo].[CHART_DIAGNOSIS_CODE_ICD10]
	WHERE 
		[CHART_ID] = @ChartId

	RETURN;
 END; -- end function

GO

/*
testing:
DECLARE @MipsCodes tIntString32;
INSERT INTO @MipsCodes SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(10991611);
SELECT * FROM @MipsCodes
*/
	
-- End of 04) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId].SQL
GO

-- Start of 05) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMinimumChartInformationByChartId].SQL

----------------------------------------
-- 05) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMinimumChartInformationByChartId].SQL
----------------------------------------
GO

GO

GO

-- drop type 
DROP TYPE IF EXISTS tMipsChartMinimumInfo;

CREATE TYPE tMipsChartMinimumInfo AS TABLE
(
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId INT NULL
	,UseTelehealth BIT NULL
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMinimumChartInformationByChartId]
(
	 @ChartId INT
)
RETURNS @ChartInfo TABLE
(
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId INT NULL
	,UseTelehealth BIT NULL
)
WITH EXECUTE AS CALLER
AS
BEGIN

	INSERT INTO 
		@ChartInfo	
	SELECT TOP 1
		 [CHART_ID] AS ChartId
		,[SERVICE_AGREEMENT_ID] AS ServiceAgreementId
		,[TIME_OF_SERVICE] AS TimeOfService
		,[GENDER] AS Gender
		,[PATIENT_DOB] AS PatientDob
		,[PATIENT_AGE] AS PatientAge
		,[PATIENT_CLASS_ID] AS PatientClassId
		,[USE_TELEHEALTH] AS UseTelehealth
	FROM 
		[dbo].[CHART]
	WHERE 
		[CHART_ID] = @ChartId;

	RETURN;
END;

GO

/*
-- testing
DECLARE @MipsChartMinimumInfo tMipsChartMinimumInfo;
INSERT INTO @MipsChartMinimumInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(10991611);
SELECT * FROM @MipsChartMinimumInfo
*/


-- End of 05) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMinimumChartInformationByChartId].SQL
GO

-- Start of 06) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService].SQL

----------------------------------------
-- 06) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService].SQL
----------------------------------------
GO

GO

GO

-- drop type 
DROP TYPE IF EXISTS tMipsMeasureInfo;

CREATE TYPE tMipsMeasureInfo AS TABLE
(
	 MeasureId INT
	,MeasureName VARCHAR(32) NULL
	,Gender VARCHAR(32) NULL
	,FromAge INT NULL
	,ToAge INT NULL
	,RequiresEmOnly BIT NULL
	,Req2DxOr3Cpt BIT NULL
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService]
(
	 @MeasureName VARCHAR(32)
	,@DateOfService DATETIME
)
RETURNS @MeasureInfo TABLE
(
	 MeasureId INT
	,MeasureName VARCHAR(32) NULL
	,Gender VARCHAR(32) NULL
	,FromAge INT NULL
	,ToAge INT NULL
	,RequiresEmOnly BIT NULL
	,Req2DxOr3Cpt BIT NULL
)
WITH EXECUTE AS CALLER
AS
BEGIN

	IF @MeasureName IS NULL OR LEN(@MeasureName) <= 0
		RETURN;

	IF @DateOfService IS NULL
		SET @DateOfService = GETDATE();

	DECLARE @MeasureId INT = [dbo].[udfMipsSelectMeasureIdFromPqrsCode](@MeasureName, @DateOfService);

	IF @MeasureId IS NULL OR @MeasureId <= 0
		RETURN;

	INSERT INTO 
		@MeasureInfo	
	SELECT TOP 1
		 [CMS_PQRI_MEASURE_ID] AS MeasureId
		,[PQRS#] AS MeasureName
		,[GENDER] AS Gender
		,[FROM_AGE] AS FromAge
		,[TO_AGE] AS ToAge
		,[REQUIRES_EM_ONLY] AS RequiresEmOnly
		,[REQ_2_DX_OR_3CPT] AS Req2DxOr3Cpt
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] <= @DateOfService)
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @DateOfService )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;

	RETURN;
END;

GO

/*
-- testing
DECLARE @MipsMeasureInfo tMipsMeasureInfo;
INSERT INTO @MipsMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(148,'08-16-2024');
SELECT * FROM @MipsMeasureInfo
*/


-- End of 06) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService].SQL
GO

-- Start of 07) DACS-3581 - Create or Alter procedure - [dbo].[spMipsReturnQuestionResponses].SQL

----------------------------------------
-- 07) DACS-3581 - Create or Alter procedure - [dbo].[spMipsReturnQuestionResponses].SQL
----------------------------------------
GO

GO

GO

-- drop PROCEDURE
DROP PROCEDURE IF EXISTS spMipsReturnQuestionResponses;

-- drop TYPE 
DROP TYPE IF EXISTS tDenominatorInfo;

CREATE TYPE tDenominatorInfo AS TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
) --WITH ( MEMORY_OPTIMIZED = ON )
GO	
------------------------------------------------------------------------------------


CREATE or ALTER PROCEDURE [dbo].[spMipsReturnQuestionResponses]
(
	 @DenominatorInfo tDenominatorInfo READONLY
	,@MeasureId INT
)
WITH EXECUTE AS CALLER
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM @DenominatorInfo tdl WHERE tdl.[CodingSystem] = 'DQ411' AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0)
		SELECT 'RESULT' = '411', 'QUESTION' = ' ', 'CODE' = '00001';
	ELSE
		SELECT TOP 5
			'411' AS 'RESULT'
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[Code] AS 'CODE'
		FROM 
			@DenominatorInfo tdl
		WHERE 
			tdl.[CodingSystem] = 'DQ411'
			AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0
		ORDER BY
			tdl.[Code];
END;

GO

/*
-- testing
DECLARE @DenominatorInfo tDenominatorInfo;
-- fill with data
EXEC spMipsReturnQuestionResponses @DenominatorInfo=@DenominatorInfo, @MeasureId=148;
*/

-- End of 07) DACS-3581 - Create or Alter procedure - [dbo].[spMipsReturnQuestionResponses].SQL
GO

-- Start of 08) DACS-3581 - Create or Alter procedure - [dbo].[spMipsSelectQuestionDenominatorData].SQL

----------------------------------------
-- 08) DACS-3581 - Create or Alter procedure - [dbo].[spMipsSelectQuestionDenominatorData].SQL
----------------------------------------
GO

GO

GO

/*
CREATE TYPE tDenominatorInfo AS TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
) --WITH ( MEMORY_OPTIMIZED = ON )
*/
------------------------------------------------------------------------------------


CREATE or ALTER PROCEDURE [dbo].[spMipsSelectQuestionDenominatorData]
(
	 @MeasureId INT
	,@DateOfService DATETIME = NULL
)
WITH EXECUTE AS CALLER
AS
BEGIN
	----------------
	-- parameter validation		-- if speed is an issue, these can be removed.
	----------------
	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('@MeasureId is invalid. Exiting');
		RETURN;
	END;	

	IF @DateOfService IS NULL
	BEGIN 
		SET @DateOfService = GETDATE();
		PRINT('Null @DateOfService set to: ' + CAST(@DateOfService AS VARCHAR(64)));
	END;
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- return some data
	----------------
	SELECT 
		 [CODE]
		,[CODING_SYSTEM]
		,[DESCRIPTION]
		,[MODIFIER]
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @DateOfService
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @DateOfService)
		AND (cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] <= @DateOfService)
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @DateOfService)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','DQ411')
	ORDER BY 	-- if speed is an issue we can likely remove the order by clause
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 
END;

GO

/*
-- testing
EXEC spMipsSelectQuestionDenominatorData @MeasureId=200;
*/

---------------------------------------------------------------------------------------
--  Now Create a function version of the above SPROC
---------------------------------------------------------------------------------------
CREATE or Alter FUNCTION [dbo].[udfMipsSelectQuestionDenominatorData]
(
	 @MeasureId INT
	,@DateOfService DATETIME
)
RETURNS @returnResults TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
)
AS
BEGIN
	----------------
	-- parameter validation		-- if speed is an issue, these can be removed.
	----------------
	IF @DateOfService IS NULL
		SET @DateOfService = GETDATE();

	IF @MeasureId IS NOT NULL AND @MeasureId > 0
	BEGIN 
		----------------
		-- return some data
		----------------
		INSERT INTO 
			@returnResults
		SELECT 
			 [CODE]
			,[CODING_SYSTEM]
			,[DESCRIPTION]
			,[MODIFIER]
		FROM 
			[CMS_PQRI_MEASURE_CODE] cpmc
			INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
		WHERE
			cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND cpmc.[START_DATE] <= @DateOfService
			AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @DateOfService)
			AND (cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] <= @DateOfService)
			AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @DateOfService)
			AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
			AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','DQ411')
		ORDER BY 	-- if speed is an issue we can likely remove the order by clause
			cpmc.CMS_PQRI_MEASURE_CODE_ID; 
	END;	

	RETURN;
 END; -- end function

GO

/*
-- testing
DECLARE @tempDiagnosisList tDenominatorInfo;
INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(200, '08-21-2024');
SELECT * FROM @tempDiagnosisList;
*/
-- End of 08) DACS-3581 - Create or Alter procedure - [dbo].[spMipsSelectQuestionDenominatorData].SQL
GO

-- Start of 10) DACS-3581 - Create or Alter Stored Procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 10) DACS-3581 - Create or Alter Stored Procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad ChartId ' = @ChartId;
		RETURN;
	END;
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Chart info
	----------------
	DECLARE @MipsChartMinimumInfo tMipsChartMinimumInfo;
	/*
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId
	,UseTelehealth BIT NULL
	*/
	INSERT INTO @MipsChartMinimumInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug = 1 SELECT * FROM @MipsChartMinimumInfo
	
	IF NOT EXISTS (SELECT 1 FROM @MipsChartMinimumInfo)
	BEGIN 
		IF @ShowDebug = 1 SELECT 'Returned chart count is empty for ' = @ChartId;
		RETURN;
	END;

	DECLARE @chartServiceAgreementId INT;
	DECLARE @chartDateOfService DATETIME;
	DECLARE @chartGender VARCHAR(32) ;
	DECLARE @chartPatientDob DATETIME;
	DECLARE @chartPatientAge INT;
	DECLARE @chartPatientClassId INT;
	DECLARE @chartUseTelehealth BIT;
	
	SELECT TOP 1
		 @chartServiceAgreementId = [ServiceAgreementId]
		,@chartDateOfService = [TimeOfService] 
		,@chartGender = [Gender] 
		,@chartPatientDob = [PatientDob] 
		,@chartPatientAge = [PatientAge] 
		,@chartPatientClassId = [PatientClassId] 
		,@chartUseTelehealth = [UseTelehealth] 
	FROM 
		@MipsChartMinimumInfo;

	PRINT('chartserviceAgreementId = ' + CAST(@chartServiceAgreementId AS VARCHAR(64)));
	PRINT('chartdateOfService = ' + CAST(@chartDateOfService AS VARCHAR(64)));
	PRINT('chartgender = ' + CAST(@chartGender AS VARCHAR(64)));
	PRINT('chartpatientDob = ' + CAST(@chartPatientDob AS VARCHAR(64)));
	PRINT('chartpatientAge = ' + CAST(@chartPatientAge AS VARCHAR(64)));
	PRINT('chartPatientClassId = ' + CAST(@chartPatientClassId AS VARCHAR(64)));
	PRINT('chartUseTelehealth = ' + CAST(@chartUseTelehealth AS VARCHAR(64)));

	IF @chartServiceAgreementId IS NULL OR @chartServiceAgreementId <= 0 OR @chartDateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;


	---------------------------------
	-- get procedure codes for this chart
	---------------------------------
	DECLARE @TempFoundProcedureCodes t2xString32;
	INSERT INTO 
		@TempFoundProcedureCodes ( 
			 [Value1]
			,[Value2] 
		)
		SELECT * FROM [dbo].[udfMIPSSelectPresentProcedureCodesByChartId](@ChartId, @chartServiceAgreementId);
	
	IF NOT EXISTS (SELECT 1 FROM @TempFoundProcedureCodes)
	BEGIN
		-- if no procedure codes, then no MIPS will be satisfied
		IF @ShowDebug = 1 SELECT 'No procedure codes found for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT * FROM @TempFoundProcedureCodes;

	---------------------------------
	-- get diagnostic codes for this chart
	---------------------------------
	DECLARE @TempFoundDiagnosticCodes tIntString32;
	INSERT INTO 
		@TempFoundDiagnosticCodes ( 
			 [Id]
			,[Value] 
		)
		SELECT * FROM [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId](@ChartId);
	
	IF @ShowDebug = 1 SELECT * FROM @TempFoundDiagnosticCodes;

	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@chartServiceAgreementId, @Dos=@chartDateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF NOT EXISTS (SELECT 1 FROM @activeSAMipsRulesTable)
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- remove the MIPS 2024 entries from the list since they are checked by anothe SPROC of a similar name separately
	-----------------------------------
	DECLARE @active2024MipsRulesTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRulesTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
		,('005-A')
		,('005-B')
		,('008-A')
		,('008-B')
		,('PQRANES1')
		,('ACEP60')
		,('HCPR24')
		,('ACEP61')
		,('ACEP64')
	;
	
	DELETE FROM @activeSAMipsRulesTable WHERE [NAME] IN (SELECT [NAME] FROM @active2024MipsRulesTable);

	DECLARE @TotalToProcessCount INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @TotalToProcessCount <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No Original Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT '@TotalToProcessCount = ' = @TotalToProcessCount;
	IF @ShowDebug = 1 SELECT * FROM @activeSAMipsRulesTable;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;

	DECLARE @FetchMeasureId INT;
	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchGender VARCHAR(32);
	DECLARE @FetchFromAgeYears INT;
	DECLARE @FetchToAgeYears INT;
	DECLARE @FetchRequiresEmOnly BIT;
	
	DECLARE @FetchMipsMeasureInfo tMipsMeasureInfo;
	DECLARE @FetchMipsDiagCodes tIntString32;
	DECLARE @FetchMipsProcCodes tIntString32;
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT DISTINCT [NAME] FROM @activeSAMipsRulesTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): MIPS Name ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NULL OR LEN(LTRIM(RTRIM(@FetchMipsName))) <= 0
		BEGIN
			PRINT('  --> FetchMipsName is invalid ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName));
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;
		
		SET @FetchMeasureId = -1;
		DELETE FROM @FetchMipsMeasureInfo;
		DELETE FROM @FetchMipsDiagCodes;
		DELETE FROM @FetchMipsProcCodes;

		----------------
		-- Measure info
		----------------
		INSERT INTO @FetchMipsMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@FetchMipsName, @ChartDateOfService);
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsMeasureInfo

		----------------
		-- none of the original (pre 2024) MIPS will have [Req2DxOr3Cpt] set to a 1.
		----------------
		SET @FetchMeasureId = (SELECT TOP 1 [MeasureId] FROM @FetchMipsMeasureInfo WHERE ([Req2DxOr3Cpt] IS NULL OR [Req2DxOr3Cpt] = 0));
			
		IF @FetchMeasureId IS NULL OR @FetchMeasureId <= 0
		BEGIN 
			PRINT('  --> FetchMeasureId failed [Req2DxOr3Cpt] check for ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName));
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;

		SELECT TOP 1
			 @FetchMipsName = [MeasureName]
			,@FetchGender = [Gender] 
			,@FetchFromAgeYears = [FromAge] 
			,@FetchToAgeYears = [ToAge] 
			,@FetchRequiresEmOnly = [RequiresEmOnly] 
		FROM 
			@FetchMipsMeasureInfo;
			
		PRINT(' --> FetchMeasureId = ' + CAST(@FetchMeasureId AS VARCHAR(64)));
		PRINT(' --> FetchMipsName = ' + CAST(@FetchMipsName AS VARCHAR(64)));
		PRINT(' --> FetchGender = ' + CAST(@FetchGender AS VARCHAR(64)));
		PRINT(' --> FetchFromAgeYears = ' + CAST(@FetchFromAgeYears AS VARCHAR(64)));
		PRINT(' --> FetchToAgeYears = ' + CAST(@FetchToAgeYears AS VARCHAR(64)));
		PRINT(' --> FetchRequiresEmOnly = ' + CAST(@FetchRequiresEmOnly AS VARCHAR(64)));

		/*  -- does not work quite right.  might need to use the pat class id and or the location of service fields instead
		IF @FetchRequiresEmOnly = 1 
			AND EXISTS (SELECT 1 FROM @TempFoundProcedureCodes WHERE [Value1] IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395'))
		BEGIN 
			-- to maintain compatibility, the original MIPS only check the following if the field is SET
			-- may update later to check the PATIENT_CLASS_ID or LOCATION_OF_SERVICE instead, but for compatibility leave as is.
			IF @TestAll <> 1
			BEGIN
				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				-- cleanup our cursor
				CLOSE cursorTempRows;  
				DEALLOCATE cursorTempRows;
				RETURN 1;
			END
			ELSE
				PRINT('!!!! Satisfied MIPS (EM Only test) = ' + CAST(@FetchMipsName AS VARCHAR(64)));
		END;
		*/
		
		----------------
		-- check Gender = gender: U,X,F,M
		----------------
		IF @FetchGender IS NOT NULL 
			AND @FetchGender <> 'B' 
			AND (
					@ChartGender IS NULL
					OR (@ChartGender IS NOT NULL AND @ChartGender IN ('M','F') AND (@ChartGender <> @FetchGender))	
				)
		BEGIN
			PRINT(' --> Gender check failed for ' + @FetchMipsName + '[' + IIF(@FetchGender IS NULL, 'NULL', @FetchGender) + ':' + IIF(@ChartGender IS NULL, 'NULL', @ChartGender) + ']');
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;
		
		----------------
		-- check age
		----------------
		IF @FetchFromAgeYears IS NOT NULL OR @FetchToAgeYears IS NOT NULL
		BEGIN
			IF @chartDateOfService IS NULL
			BEGIN 
				PRINT(' --> chartDateOfService is invalid for age test.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;

			IF @chartPatientAge IS NULL OR @chartPatientAge < 0
				SET @chartpatientAge = dbo.fGetPatientAgeInYears(@chartpatientAge, @chartDateOfService, @chartPatientDob);

			IF @chartPatientAge IS NULL OR @chartPatientAge < 0 OR @chartPatientAge > 999
			BEGIN 
				PRINT(' --> chartPatientAge is invalid for age test.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;

			-- check the age constraints
			IF @FetchFromAgeYears IS NULL SET @FetchFromAgeYears = 0;
			IF @FetchToAgeYears IS NULL SET @FetchToAgeYears = 999;
			
			IF @chartPatientAge < @FetchFromAgeYears OR @chartPatientAge > @FetchToAgeYears
			BEGIN 
				PRINT(' --> chartPatientAge does not fall within the valid MIPS range.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;	

	
		----------------
		-- get the C4 data
		----------------
		INSERT INTO @FetchMipsProcCodes SELECT * FROM [dbo].[udfMipsSelectCodeTableByCodingSystem](@FetchMeasureId,'C4');
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsProcCodes;

		IF EXISTS (SELECT 1 FROM @FetchMipsProcCodes)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM @TempFoundProcedureCodes WHERE [Value1] IN (SELECT [Value] FROM @FetchMipsProcCodes))
			BEGIN
				PRINT(' --> No Procedure Codes are within C4 test list.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;


		----------------
		-- get the I10 data
		----------------
		INSERT INTO @FetchMipsDiagCodes SELECT * FROM [dbo].[udfMipsSelectCodeTableByCodingSystem](@FetchMeasureId,'I10');
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsDiagCodes;

		IF EXISTS (SELECT 1 FROM @FetchMipsDiagCodes)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM @TempFoundDiagnosticCodes WHERE [Value] IN (SELECT [Value] FROM @FetchMipsDiagCodes))
			BEGIN
				PRINT(' --> No Diagnostic Codes are within I10 test list.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;


		----------------
		-- MIPS passes if we make it all the way here
		----------------
		PRINT('!!!! MIPS [' + @FetchMipsName + '] Satisfied for Cid: ' + CAST(@ChartId AS VARCHAR(32)));

		IF @TestAll <> 1
		BEGIN
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
			-- cleanup our cursor
			CLOSE cursorTempRows;  
			DEALLOCATE cursorTempRows;
			RETURN 1;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO Original Mips satisfied for chart ' = @ChartId;

END; -- end of SPROC

GO

/*
testing:
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=121366953,@ShowDebug=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=121366953;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=122615466,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=122615466,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100113749,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100113749,@TestAll=1;

select top 20 * from chart order by chart_id desc;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100114071;

*/
-- End of 10) DACS-3581 - Create or Alter Stored Procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL
GO

-- Start of 20) DACS-3581 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL

------------------------------------------------------------------------------------
-- 20) DACS-3581 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of THEPQR4, there are 1 valid decision paths.  the data is stored by PQRS# 'THEPQR4' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;

	IF NOT EXISTS 
		(
			SELECT TOP 1 
				[PATIENT_CLASS_ID] 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				[PATIENT_CLASS_ID] = @chartPatientClassId 
				AND [SERVICE_AGREEMENT_ID] = @chartSAId
				AND ([PHYSICIAN_SERVICE_CLASS_CD] IN ('1','2','3','6','7','8','9','11','12','13') OR [LOCATION_OF_SERVICE] IN ('21','22','23','31','32','33'))
		)
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11,12,13) OR [LOCATION_OF_SERVICE] IN (21,22,23,31,32,33) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	

	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis in our inclusive diagnosis listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList tdl WHERE tdl.[CodingSystem] = 'DQ411' AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0)
		SELECT 'RESULT' = '411', 'QUESTION' = ' ', 'CODE' = '00001';
	ELSE
		SELECT TOP 5
			'411' AS 'RESULT'
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[Code] AS 'CODE'
		FROM 
			@tempDenominatorList tdl
		WHERE 
			tdl.[CodingSystem] = 'DQ411'
			AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0
		ORDER BY
			tdl.[Code];

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] @ChartId=2100113947, @PqrsNum='THEPQR4';
*/

-- End of 20) DACS-3581 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
GO

-- Start of 01) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentProcedureCodesByChartId].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentProcedureCodesByChartId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

-- drop type 
DROP TYPE IF EXISTS t2xString32;

CREATE TYPE t2xString32 AS TABLE
(
	 Value1 VARCHAR(32)
	,Value2 VARCHAR(32)
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------

CREATE or Alter FUNCTION [dbo].[udfMIPSSelectPresentProcedureCodesByChartId]
(
	  @ChartId INT
	 ,@ServiceAgreementId INT
)
RETURNS @returnResults TABLE
(
	 Value1 VARCHAR(32)
	,Value2 VARCHAR(32)
)
AS
BEGIN
	----------------
	-- Present Procedure List 
	----------------
	INSERT INTO 
		@returnResults
	SELECT 
		 cm.[CPT_CODE] AS Value1
		,ppe.[MODIFIERS]  AS Value2
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE] p
		INNER JOIN [CHART] c ON p.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE 
		p.[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND p.[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO @returnResults ([Value1]) VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) >= 2 
		INSERT INTO @returnResults ([Value2]) VALUES (@PSP_MODIFIERS);
	 
	-- IF @ShowDebug <> 0 SELECT * FROM @returnResults; -- testing
	RETURN;
 END; -- end function

GO
-- End of 01) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentProcedureCodesByChartId].SQL
GO

-- Start of 02) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectCodeTableByCodingSystem].SQL

----------------------------------------
-- 02) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectCodeTableByCodingSystem].SQL
----------------------------------------
GO

GO

GO

-- drop type 
DROP TYPE IF EXISTS tIntString32;

CREATE TYPE tIntString32 AS TABLE
(
	 Id INT
	,Value VARCHAR(32)
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectCodeTableByCodingSystem]
(
	 @MeasureId INT
	,@CodingSystem VARCHAR(32) 
)
RETURNS @Codes TABLE
(
     Id INT
	,Value VARCHAR(32)
)
WITH EXECUTE AS CALLER
AS
BEGIN
	INSERT INTO 
		@Codes
	SELECT 
		 [CMS_PQRI_MEASURE_CODE_ID] AS Id
		,[CODE] AS Value
	FROM 
		[dbo].[CMS_PQRI_MEASURE_CODE]
	WHERE
		[CMS_PQRI_MEASURE_ID] = @measureId
		AND [CODING_SYSTEM] = @CodingSystem
		AND ([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] >= GETDATE())
	;		

	RETURN;
END;

GO

/*
-- testing
DECLARE @MipsCodes tIntString32;
INSERT INTO @MipsCodes SELECT * FROM dbo.udfMipsSelectCodeTableByCodingSystem(148,'C4');
SELECT * FROM @MipsCodes
*/
-- End of 02) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectCodeTableByCodingSystem].SQL
GO

-- Start of 03) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureIdFromPqrsCode].SQL

----------------------------------------
-- 03) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureIdFromPqrsCode].SQL
----------------------------------------
GO

GO

GO

CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMeasureIdFromPqrsCode]
(
	 @PqrsCode VARCHAR(32) 
	,@Dos DATETIME
)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN

	IF @PqrsCode IS NOT NULL AND LEN(LTRIM(RTRIM(@PqrsCode))) > 0
	BEGIN
		DECLARE @testPqrs INT = (
			SELECT TOP 1 
				[CMS_PQRI_MEASURE_ID] 
			FROM 
				[dbo].[CMS_PQRI_MEASURE] 
			WHERE 
				[PQRS#] = @PqrsCode 
				AND [EFFECTIVE_DATE] <= @Dos 
				AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) 
		);

		IF @testPqrs IS NOT NULL AND @testPqrs > 0
			RETURN @testPqrs;
	END;
	
	RETURN -1;
END;

GO

/*
-- testing
DECLARE @MipsId INT = dbo.udfMipsSelectMeasureIdFromPqrsCode('005-A','08-01-2024');
SELECT '@MipsId' = @MipsId
*/
-- End of 03) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureIdFromPqrsCode].SQL
GO

-- Start of 04) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE or Alter FUNCTION [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId]
(
	  @ChartId INT
)
RETURNS @returnResults TABLE
(
	 Id INT
	,Value VARCHAR(32)
)
AS
BEGIN
	----------------
	-- Present Diagnosis List 
	----------------
	INSERT INTO
		@returnResults
	SELECT 
		 [CHART_DIAGNOSIS_CODE_ICD10_ID] AS Id
		,[ICD10_CODE] AS Value
	FROM 
		[dbo].[CHART_DIAGNOSIS_CODE_ICD10]
	WHERE 
		[CHART_ID] = @ChartId

	RETURN;
 END; -- end function

GO

/*
testing:
DECLARE @MipsCodes tIntString32;
INSERT INTO @MipsCodes SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(10991611);
SELECT * FROM @MipsCodes
*/
	
-- End of 04) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId].SQL
GO

-- Start of 05) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMinimumChartInformationByChartId].SQL

----------------------------------------
-- 05) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMinimumChartInformationByChartId].SQL
----------------------------------------
GO

GO

GO

-- drop type 
DROP TYPE IF EXISTS tMipsChartMinimumInfo;

CREATE TYPE tMipsChartMinimumInfo AS TABLE
(
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId INT NULL
	,UseTelehealth BIT NULL
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMinimumChartInformationByChartId]
(
	 @ChartId INT
)
RETURNS @ChartInfo TABLE
(
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId INT NULL
	,UseTelehealth BIT NULL
)
WITH EXECUTE AS CALLER
AS
BEGIN

	INSERT INTO 
		@ChartInfo	
	SELECT TOP 1
		 [CHART_ID] AS ChartId
		,[SERVICE_AGREEMENT_ID] AS ServiceAgreementId
		,[TIME_OF_SERVICE] AS TimeOfService
		,[GENDER] AS Gender
		,[PATIENT_DOB] AS PatientDob
		,[PATIENT_AGE] AS PatientAge
		,[PATIENT_CLASS_ID] AS PatientClassId
		,[USE_TELEHEALTH] AS UseTelehealth
	FROM 
		[dbo].[CHART]
	WHERE 
		[CHART_ID] = @ChartId;

	RETURN;
END;

GO

/*
-- testing
DECLARE @MipsChartMinimumInfo tMipsChartMinimumInfo;
INSERT INTO @MipsChartMinimumInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(10991611);
SELECT * FROM @MipsChartMinimumInfo
*/


-- End of 05) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMinimumChartInformationByChartId].SQL
GO

-- Start of 06) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService].SQL

----------------------------------------
-- 06) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService].SQL
----------------------------------------
GO

GO

GO

-- drop type 
DROP TYPE IF EXISTS tMipsMeasureInfo;

CREATE TYPE tMipsMeasureInfo AS TABLE
(
	 MeasureId INT
	,MeasureName VARCHAR(32) NULL
	,Gender VARCHAR(32) NULL
	,FromAge INT NULL
	,ToAge INT NULL
	,RequiresEmOnly BIT NULL
	,Req2DxOr3Cpt BIT NULL
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService]
(
	 @MeasureName VARCHAR(32)
	,@DateOfService DATETIME
)
RETURNS @MeasureInfo TABLE
(
	 MeasureId INT
	,MeasureName VARCHAR(32) NULL
	,Gender VARCHAR(32) NULL
	,FromAge INT NULL
	,ToAge INT NULL
	,RequiresEmOnly BIT NULL
	,Req2DxOr3Cpt BIT NULL
)
WITH EXECUTE AS CALLER
AS
BEGIN

	IF @MeasureName IS NULL OR LEN(@MeasureName) <= 0
		RETURN;

	IF @DateOfService IS NULL
		SET @DateOfService = GETDATE();

	DECLARE @MeasureId INT = [dbo].[udfMipsSelectMeasureIdFromPqrsCode](@MeasureName, @DateOfService);

	IF @MeasureId IS NULL OR @MeasureId <= 0
		RETURN;

	INSERT INTO 
		@MeasureInfo	
	SELECT TOP 1
		 [CMS_PQRI_MEASURE_ID] AS MeasureId
		,[PQRS#] AS MeasureName
		,[GENDER] AS Gender
		,[FROM_AGE] AS FromAge
		,[TO_AGE] AS ToAge
		,[REQUIRES_EM_ONLY] AS RequiresEmOnly
		,[REQ_2_DX_OR_3CPT] AS Req2DxOr3Cpt
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] <= @DateOfService)
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @DateOfService )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;

	RETURN;
END;

GO

/*
-- testing
DECLARE @MipsMeasureInfo tMipsMeasureInfo;
INSERT INTO @MipsMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(148,'08-16-2024');
SELECT * FROM @MipsMeasureInfo
*/


-- End of 06) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService].SQL
GO

-- Start of 07) DACS-3581 - Create or Alter procedure - [dbo].[spMipsReturnQuestionResponses].SQL

----------------------------------------
-- 07) DACS-3581 - Create or Alter procedure - [dbo].[spMipsReturnQuestionResponses].SQL
----------------------------------------
GO

GO

GO

-- drop PROCEDURE
DROP PROCEDURE IF EXISTS spMipsReturnQuestionResponses;

-- drop TYPE 
DROP TYPE IF EXISTS tDenominatorInfo;

CREATE TYPE tDenominatorInfo AS TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
) --WITH ( MEMORY_OPTIMIZED = ON )
GO	
------------------------------------------------------------------------------------


CREATE or ALTER PROCEDURE [dbo].[spMipsReturnQuestionResponses]
(
	 @DenominatorInfo tDenominatorInfo READONLY
	,@MeasureId INT
)
WITH EXECUTE AS CALLER
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM @DenominatorInfo tdl WHERE tdl.[CodingSystem] = 'DQ411' AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0)
		SELECT 'RESULT' = '411', 'QUESTION' = ' ', 'CODE' = '00001';
	ELSE
		SELECT TOP 5
			'411' AS 'RESULT'
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[Code] AS 'CODE'
		FROM 
			@DenominatorInfo tdl
		WHERE 
			tdl.[CodingSystem] = 'DQ411'
			AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0
		ORDER BY
			tdl.[Code];
END;

GO

/*
-- testing
DECLARE @DenominatorInfo tDenominatorInfo;
-- fill with data
EXEC spMipsReturnQuestionResponses @DenominatorInfo=@DenominatorInfo, @MeasureId=148;
*/

-- End of 07) DACS-3581 - Create or Alter procedure - [dbo].[spMipsReturnQuestionResponses].SQL
GO

-- Start of 08) DACS-3581 - Create or Alter procedure - [dbo].[spMipsSelectQuestionDenominatorData].SQL

----------------------------------------
-- 08) DACS-3581 - Create or Alter procedure - [dbo].[spMipsSelectQuestionDenominatorData].SQL
----------------------------------------
GO

GO

GO

/*
CREATE TYPE tDenominatorInfo AS TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
) --WITH ( MEMORY_OPTIMIZED = ON )
*/
------------------------------------------------------------------------------------


CREATE or ALTER PROCEDURE [dbo].[spMipsSelectQuestionDenominatorData]
(
	 @MeasureId INT
	,@DateOfService DATETIME = NULL
)
WITH EXECUTE AS CALLER
AS
BEGIN
	----------------
	-- parameter validation		-- if speed is an issue, these can be removed.
	----------------
	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('@MeasureId is invalid. Exiting');
		RETURN;
	END;	

	IF @DateOfService IS NULL
	BEGIN 
		SET @DateOfService = GETDATE();
		PRINT('Null @DateOfService set to: ' + CAST(@DateOfService AS VARCHAR(64)));
	END;
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- return some data
	----------------
	SELECT 
		 [CODE]
		,[CODING_SYSTEM]
		,[DESCRIPTION]
		,[MODIFIER]
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @DateOfService
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @DateOfService)
		AND (cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] <= @DateOfService)
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @DateOfService)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','DQ411')
	ORDER BY 	-- if speed is an issue we can likely remove the order by clause
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 
END;

GO

/*
-- testing
EXEC spMipsSelectQuestionDenominatorData @MeasureId=200;
*/

---------------------------------------------------------------------------------------
--  Now Create a function version of the above SPROC
---------------------------------------------------------------------------------------
CREATE or Alter FUNCTION [dbo].[udfMipsSelectQuestionDenominatorData]
(
	 @MeasureId INT
	,@DateOfService DATETIME
)
RETURNS @returnResults TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
)
AS
BEGIN
	----------------
	-- parameter validation		-- if speed is an issue, these can be removed.
	----------------
	IF @DateOfService IS NULL
		SET @DateOfService = GETDATE();

	IF @MeasureId IS NOT NULL AND @MeasureId > 0
	BEGIN 
		----------------
		-- return some data
		----------------
		INSERT INTO 
			@returnResults
		SELECT 
			 [CODE]
			,[CODING_SYSTEM]
			,[DESCRIPTION]
			,[MODIFIER]
		FROM 
			[CMS_PQRI_MEASURE_CODE] cpmc
			INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
		WHERE
			cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND cpmc.[START_DATE] <= @DateOfService
			AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @DateOfService)
			AND (cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] <= @DateOfService)
			AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @DateOfService)
			AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
			AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','DQ411')
		ORDER BY 	-- if speed is an issue we can likely remove the order by clause
			cpmc.CMS_PQRI_MEASURE_CODE_ID; 
	END;	

	RETURN;
 END; -- end function

GO

/*
-- testing
DECLARE @tempDiagnosisList tDenominatorInfo;
INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(200, '08-21-2024');
SELECT * FROM @tempDiagnosisList;
*/
-- End of 08) DACS-3581 - Create or Alter procedure - [dbo].[spMipsSelectQuestionDenominatorData].SQL
GO

-- Start of 10) DACS-3581 - Create or Alter Stored Procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 10) DACS-3581 - Create or Alter Stored Procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad ChartId ' = @ChartId;
		RETURN;
	END;
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Chart info
	----------------
	DECLARE @MipsChartMinimumInfo tMipsChartMinimumInfo;
	/*
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId
	,UseTelehealth BIT NULL
	*/
	INSERT INTO @MipsChartMinimumInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug = 1 SELECT * FROM @MipsChartMinimumInfo
	
	IF NOT EXISTS (SELECT 1 FROM @MipsChartMinimumInfo)
	BEGIN 
		IF @ShowDebug = 1 SELECT 'Returned chart count is empty for ' = @ChartId;
		RETURN;
	END;

	DECLARE @chartServiceAgreementId INT;
	DECLARE @chartDateOfService DATETIME;
	DECLARE @chartGender VARCHAR(32) ;
	DECLARE @chartPatientDob DATETIME;
	DECLARE @chartPatientAge INT;
	DECLARE @chartPatientClassId INT;
	DECLARE @chartUseTelehealth BIT;
	
	SELECT TOP 1
		 @chartServiceAgreementId = [ServiceAgreementId]
		,@chartDateOfService = [TimeOfService] 
		,@chartGender = [Gender] 
		,@chartPatientDob = [PatientDob] 
		,@chartPatientAge = [PatientAge] 
		,@chartPatientClassId = [PatientClassId] 
		,@chartUseTelehealth = [UseTelehealth] 
	FROM 
		@MipsChartMinimumInfo;

	PRINT('chartserviceAgreementId = ' + CAST(@chartServiceAgreementId AS VARCHAR(64)));
	PRINT('chartdateOfService = ' + CAST(@chartDateOfService AS VARCHAR(64)));
	PRINT('chartgender = ' + CAST(@chartGender AS VARCHAR(64)));
	PRINT('chartpatientDob = ' + CAST(@chartPatientDob AS VARCHAR(64)));
	PRINT('chartpatientAge = ' + CAST(@chartPatientAge AS VARCHAR(64)));
	PRINT('chartPatientClassId = ' + CAST(@chartPatientClassId AS VARCHAR(64)));
	PRINT('chartUseTelehealth = ' + CAST(@chartUseTelehealth AS VARCHAR(64)));

	IF @chartServiceAgreementId IS NULL OR @chartServiceAgreementId <= 0 OR @chartDateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;


	---------------------------------
	-- get procedure codes for this chart
	---------------------------------
	DECLARE @TempFoundProcedureCodes t2xString32;
	INSERT INTO 
		@TempFoundProcedureCodes ( 
			 [Value1]
			,[Value2] 
		)
		SELECT * FROM [dbo].[udfMIPSSelectPresentProcedureCodesByChartId](@ChartId, @chartServiceAgreementId);
	
	IF NOT EXISTS (SELECT 1 FROM @TempFoundProcedureCodes)
	BEGIN
		-- if no procedure codes, then no MIPS will be satisfied
		IF @ShowDebug = 1 SELECT 'No procedure codes found for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT * FROM @TempFoundProcedureCodes;

	---------------------------------
	-- get diagnostic codes for this chart
	---------------------------------
	DECLARE @TempFoundDiagnosticCodes tIntString32;
	INSERT INTO 
		@TempFoundDiagnosticCodes ( 
			 [Id]
			,[Value] 
		)
		SELECT * FROM [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId](@ChartId);
	
	IF @ShowDebug = 1 SELECT * FROM @TempFoundDiagnosticCodes;

	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@chartServiceAgreementId, @Dos=@chartDateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF NOT EXISTS (SELECT 1 FROM @activeSAMipsRulesTable)
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- remove the MIPS 2024 entries from the list since they are checked by anothe SPROC of a similar name separately
	-----------------------------------
	DECLARE @active2024MipsRulesTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRulesTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
		,('005-A')
		,('005-B')
		,('008-A')
		,('008-B')
		,('PQRANES1')
		,('ACEP60')
		,('HCPR24')
		,('ACEP61')
		,('ACEP64')
	;
	
	DELETE FROM @activeSAMipsRulesTable WHERE [NAME] IN (SELECT [NAME] FROM @active2024MipsRulesTable);

	DECLARE @TotalToProcessCount INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @TotalToProcessCount <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No Original Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT '@TotalToProcessCount = ' = @TotalToProcessCount;
	IF @ShowDebug = 1 SELECT * FROM @activeSAMipsRulesTable;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;

	DECLARE @FetchMeasureId INT;
	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchGender VARCHAR(32);
	DECLARE @FetchFromAgeYears INT;
	DECLARE @FetchToAgeYears INT;
	DECLARE @FetchRequiresEmOnly BIT;
	
	DECLARE @FetchMipsMeasureInfo tMipsMeasureInfo;
	DECLARE @FetchMipsDiagCodes tIntString32;
	DECLARE @FetchMipsProcCodes tIntString32;
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT DISTINCT [NAME] FROM @activeSAMipsRulesTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): MIPS Name ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NULL OR LEN(LTRIM(RTRIM(@FetchMipsName))) <= 0
		BEGIN
			PRINT('  --> FetchMipsName is invalid ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName));
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;
		
		SET @FetchMeasureId = -1;
		DELETE FROM @FetchMipsMeasureInfo;
		DELETE FROM @FetchMipsDiagCodes;
		DELETE FROM @FetchMipsProcCodes;

		----------------
		-- Measure info
		----------------
		INSERT INTO @FetchMipsMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@FetchMipsName, @ChartDateOfService);
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsMeasureInfo

		----------------
		-- none of the original (pre 2024) MIPS will have [Req2DxOr3Cpt] set to a 1.
		----------------
		SET @FetchMeasureId = (SELECT TOP 1 [MeasureId] FROM @FetchMipsMeasureInfo WHERE ([Req2DxOr3Cpt] IS NULL OR [Req2DxOr3Cpt] = 0));
			
		IF @FetchMeasureId IS NULL OR @FetchMeasureId <= 0
		BEGIN 
			PRINT('  --> FetchMeasureId failed [Req2DxOr3Cpt] check for ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName));
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;

		SELECT TOP 1
			 @FetchMipsName = [MeasureName]
			,@FetchGender = [Gender] 
			,@FetchFromAgeYears = [FromAge] 
			,@FetchToAgeYears = [ToAge] 
			,@FetchRequiresEmOnly = [RequiresEmOnly] 
		FROM 
			@FetchMipsMeasureInfo;
			
		PRINT(' --> FetchMeasureId = ' + CAST(@FetchMeasureId AS VARCHAR(64)));
		PRINT(' --> FetchMipsName = ' + CAST(@FetchMipsName AS VARCHAR(64)));
		PRINT(' --> FetchGender = ' + CAST(@FetchGender AS VARCHAR(64)));
		PRINT(' --> FetchFromAgeYears = ' + CAST(@FetchFromAgeYears AS VARCHAR(64)));
		PRINT(' --> FetchToAgeYears = ' + CAST(@FetchToAgeYears AS VARCHAR(64)));
		PRINT(' --> FetchRequiresEmOnly = ' + CAST(@FetchRequiresEmOnly AS VARCHAR(64)));

		/*  -- does not work quite right.  might need to use the pat class id and or the location of service fields instead
		IF @FetchRequiresEmOnly = 1 
			AND EXISTS (SELECT 1 FROM @TempFoundProcedureCodes WHERE [Value1] IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395'))
		BEGIN 
			-- to maintain compatibility, the original MIPS only check the following if the field is SET
			-- may update later to check the PATIENT_CLASS_ID or LOCATION_OF_SERVICE instead, but for compatibility leave as is.
			IF @TestAll <> 1
			BEGIN
				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				-- cleanup our cursor
				CLOSE cursorTempRows;  
				DEALLOCATE cursorTempRows;
				RETURN 1;
			END
			ELSE
				PRINT('!!!! Satisfied MIPS (EM Only test) = ' + CAST(@FetchMipsName AS VARCHAR(64)));
		END;
		*/
		
		----------------
		-- check Gender = gender: U,X,F,M
		----------------
		IF @FetchGender IS NOT NULL 
			AND @FetchGender <> 'B' 
			AND (
					@ChartGender IS NULL
					OR (@ChartGender IS NOT NULL AND @ChartGender IN ('M','F') AND (@ChartGender <> @FetchGender))	
				)
		BEGIN
			PRINT(' --> Gender check failed for ' + @FetchMipsName + '[' + IIF(@FetchGender IS NULL, 'NULL', @FetchGender) + ':' + IIF(@ChartGender IS NULL, 'NULL', @ChartGender) + ']');
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;
		
		----------------
		-- check age
		----------------
		IF @FetchFromAgeYears IS NOT NULL OR @FetchToAgeYears IS NOT NULL
		BEGIN
			IF @chartDateOfService IS NULL
			BEGIN 
				PRINT(' --> chartDateOfService is invalid for age test.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;

			IF @chartPatientAge IS NULL OR @chartPatientAge < 0
				SET @chartpatientAge = dbo.fGetPatientAgeInYears(@chartpatientAge, @chartDateOfService, @chartPatientDob);

			IF @chartPatientAge IS NULL OR @chartPatientAge < 0 OR @chartPatientAge > 999
			BEGIN 
				PRINT(' --> chartPatientAge is invalid for age test.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;

			-- check the age constraints
			IF @FetchFromAgeYears IS NULL SET @FetchFromAgeYears = 0;
			IF @FetchToAgeYears IS NULL SET @FetchToAgeYears = 999;
			
			IF @chartPatientAge < @FetchFromAgeYears OR @chartPatientAge > @FetchToAgeYears
			BEGIN 
				PRINT(' --> chartPatientAge does not fall within the valid MIPS range.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;	

	
		----------------
		-- get the C4 data
		----------------
		INSERT INTO @FetchMipsProcCodes SELECT * FROM [dbo].[udfMipsSelectCodeTableByCodingSystem](@FetchMeasureId,'C4');
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsProcCodes;

		IF EXISTS (SELECT 1 FROM @FetchMipsProcCodes)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM @TempFoundProcedureCodes WHERE [Value1] IN (SELECT [Value] FROM @FetchMipsProcCodes))
			BEGIN
				PRINT(' --> No Procedure Codes are within C4 test list.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;


		----------------
		-- get the I10 data
		----------------
		INSERT INTO @FetchMipsDiagCodes SELECT * FROM [dbo].[udfMipsSelectCodeTableByCodingSystem](@FetchMeasureId,'I10');
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsDiagCodes;

		IF EXISTS (SELECT 1 FROM @FetchMipsDiagCodes)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM @TempFoundDiagnosticCodes WHERE [Value] IN (SELECT [Value] FROM @FetchMipsDiagCodes))
			BEGIN
				PRINT(' --> No Diagnostic Codes are within I10 test list.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;


		----------------
		-- MIPS passes if we make it all the way here
		----------------
		PRINT('!!!! MIPS [' + @FetchMipsName + '] Satisfied for Cid: ' + CAST(@ChartId AS VARCHAR(32)));

		IF @TestAll <> 1
		BEGIN
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
			-- cleanup our cursor
			CLOSE cursorTempRows;  
			DEALLOCATE cursorTempRows;
			RETURN 1;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO Original Mips satisfied for chart ' = @ChartId;

END; -- end of SPROC

GO

/*
testing:
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=121366953,@ShowDebug=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=121366953;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=122615466,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=122615466,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100113749,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100113749,@TestAll=1;

select top 20 * from chart order by chart_id desc;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100114071;

*/
-- End of 10) DACS-3581 - Create or Alter Stored Procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL
GO

-- Start of 20) DACS-3581 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL

------------------------------------------------------------------------------------
-- 20) DACS-3581 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of THEPQR4, there are 1 valid decision paths.  the data is stored by PQRS# 'THEPQR4' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;

	IF NOT EXISTS 
		(
			SELECT TOP 1 
				[PATIENT_CLASS_ID] 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				[PATIENT_CLASS_ID] = @chartPatientClassId 
				AND [SERVICE_AGREEMENT_ID] = @chartSAId
				AND ([PHYSICIAN_SERVICE_CLASS_CD] IN ('1','2','3','6','7','8','9','11','12','13') OR [LOCATION_OF_SERVICE] IN ('21','22','23','31','32','33'))
		)
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11,12,13) OR [LOCATION_OF_SERVICE] IN (21,22,23,31,32,33) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	

	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis in our inclusive diagnosis listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList tdl WHERE tdl.[CodingSystem] = 'DQ411' AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0)
		SELECT 'RESULT' = '411', 'QUESTION' = ' ', 'CODE' = '00001';
	ELSE
		SELECT TOP 5
			'411' AS 'RESULT'
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[Code] AS 'CODE'
		FROM 
			@tempDenominatorList tdl
		WHERE 
			tdl.[CodingSystem] = 'DQ411'
			AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0
		ORDER BY
			tdl.[Code];

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] @ChartId=2100113947, @PqrsNum='THEPQR4';
*/

-- End of 20) DACS-3581 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
GO

-- Start of 01) DACS-3604 - Create or Alter function - [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService].SQL

----------------------------------------
-- 01) DACS-3604 - Create or Alter function - [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService].SQL
----------------------------------------
GO

GO


GO	

CREATE or ALTER FUNCTION [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService]
(
	 @PatientClassId INT
	,@ServiceAgreementId INT
	,@TestForPatientClassCodesCsv VARCHAR(64)
	,@TestForLocationOfServiceCsv VARCHAR(64)
)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN
	----------------
	-- validate parameters
	----------------
	IF @PatientClassId IS NULL 
		OR @PatientClassId <= 0
		OR @ServiceAgreementId IS NULL 
		OR @ServiceAgreementId <= 0
		RETURN -1;
	
	IF @TestForPatientClassCodesCsv IS NOT NULL AND LEN(LTRIM(RTRIM(@TestForPatientClassCodesCsv))) <= 0
		SET @TestForPatientClassCodesCsv = NULL;
	
	IF @TestForLocationOfServiceCsv IS NOT NULL AND LEN(LTRIM(RTRIM(@TestForLocationOfServiceCsv))) <= 0
		SET @TestForLocationOfServiceCsv = NULL;

	IF @TestForPatientClassCodesCsv IS NULL AND @TestForLocationOfServiceCsv IS NULL
		RETURN -2;
	
	----------------
	-- retrieve code and los from chart where PATIENT_CLASS_ID is specified
	----------------
	DECLARE @PhysicianServiceClassCode VARCHAR(64);
	DECLARE @LocationOfService VARCHAR(64);

	SELECT TOP 1 
		 @PhysicianServiceClassCode = [PHYSICIAN_SERVICE_CLASS_CD]
		,@LocationOfService = [LOCATION_OF_SERVICE]
	FROM 
		[dbo].[PATIENT_CLASS] WITH (NOLOCK)
	WHERE 
		[PATIENT_CLASS_ID] = @PatientClassId 
		AND [SERVICE_AGREEMENT_ID] = @ServiceAgreementId;
	
	----------------
	-- test patient class code
	----------------
	IF @TestForPatientClassCodesCsv IS NOT NULL AND @PhysicianServiceClassCode IS NOT NULL AND LEN(LTRIM(RTRIM(@PhysicianServiceClassCode))) > 0
	BEGIN
		DECLARE @splitsTestPatientCodes tIntString32;

		INSERT @splitsTestPatientCodes(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@TestForPatientClassCodesCsv, ',');
		
		IF EXISTS (SELECT 1 FROM @splitsTestPatientCodes) AND EXISTS (SELECT 1 FROM @splitsTestPatientCodes WHERE value = @PhysicianServiceClassCode)
			RETURN 1;
	END;

	----------------
	-- test location of service
	----------------
	IF @TestForLocationOfServiceCsv IS NOT NULL AND @LocationOfService IS NOT NULL AND LEN(LTRIM(RTRIM(@LocationOfService))) > 0
	BEGIN
		DECLARE @splitsTestLocationsOfService tIntString32;
		DECLARE @splitsChartLocationsOfService tIntString32;

		INSERT @splitsTestLocationsOfService(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@TestForLocationOfServiceCsv, ',');

		INSERT @splitsChartLocationsOfService(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@LocationOfService, ',');

		IF EXISTS (SELECT 1 FROM @splitsTestLocationsOfService) 
			AND EXISTS (SELECT 1 FROM @splitsChartLocationsOfService) -- prolly can remove.  just being paranoid about bad chart data
			AND EXISTS (SELECT 1 FROM @splitsChartLocationsOfService WHERE value IN (SELECT DISTINCT value FROM @splitsTestLocationsOfService))
				RETURN 1;
	END;

	RETURN 0;
END;

GO

/*
-- testing
DECLARE @result INT;
INSERT INTO @result SELECT * FROM dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(148,2307,'1,7,8,9','02,21,23');
SELECT * FROM @result
*/




-- End of 01) DACS-3604 - Create or Alter function - [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService].SQL
GO

-- Start of 02) DACS-3604 - CREATE or Alter FUNCTION - [dbo].[udfReturnMips411Questions].SQL

----------------------------------------
-- 02) DACS-3604 - CREATE or Alter FUNCTION - [dbo].[udfReturnMips411Questions].SQL
----------------------------------------
GO

GO

GO

	----------------
	-- making a reusable block out of oft used MIPS SQL Script
	----------------

CREATE or Alter FUNCTION [dbo].[udfReturnMips411Questions]
	(
		 @tempDenominatorList tDenominatorInfo READONLY
		,@MeasureId INT
	)
RETURNS @returnResults TABLE
(
	 [RESULT] VARCHAR(32)
	,[QUESTION] VARCHAR(2000)
	,[CODE] VARCHAR(32)
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList tdl WHERE tdl.[CodingSystem] = 'DQ411' AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0)
		INSERT INTO @returnResults ([RESULT], [QUESTION], [CODE])
			VALUES ('411', ' ', '00001')
	ELSE
		INSERT INTO @returnResults ([RESULT], [QUESTION], [CODE])
			SELECT TOP 5
				'411' AS 'RESULT'
				, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
				, tdl.[Code] AS 'CODE'
			FROM 
				@tempDenominatorList tdl
			WHERE 
				tdl.[CodingSystem] = 'DQ411'
				AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0
			ORDER BY
				tdl.[Code];
	RETURN;
END; -- end function

GO
 
-- End of 02) DACS-3604 - CREATE or Alter FUNCTION - [dbo].[udfReturnMips411Questions].SQL
GO

-- Start of 10) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL

------------------------------------------------------------------------------------
-- 10) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of THEPQR4, there are 1 valid decision paths.  the data is stored by PQRS# 'THEPQR4' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,2,3,6,7,8,9,11,12,13','21,22,23,31,32,33') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11,12,13) OR [LOCATION_OF_SERVICE] IN (21,22,23,31,32,33) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	
	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	
	-- do we have a Diagnosis in our inclusive diagnosis listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] @ChartId=2100113947, @PqrsNum='THEPQR4';
*/

-- End of 10) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
GO

-- Start of 11) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc =  'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of HCPR27, there are 1 valid decision paths.  the data is stored by PQRS# 'HCPR27' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,7,8,9','02,21,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,7,8,9) OR [LOCATION_OF_SERVICE] IN (02,21,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	

	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	
	 
	IF (NOT EXISTS (SELECT 1 FROM @tempProcedureList))
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	/*  NOT NEEDED at this time
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;
	*/

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Undergone CVC insertion (limited to internal jugular or subclavian lines) (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Undergone CVC insertion (limited to internal jugular or subclavian lines) (CPT Codes))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27] @ChartId=2100114190, @PqrsNum='HCPR27';
*/


-- End of 11) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL
GO

-- Start of 12) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL

------------------------------------------------------------------------------------
-- 12) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER  PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,2,3,6,7,8,9,11','02,11,19,20,21,22,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11) OR [LOCATION_OF_SERVICE] IN (02,11,19,20,21,22,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have an (ICD-10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of Syncope (ICD‐10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Inpatient or Observation Status settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39] @ChartId=2100113938, @PqrsNum='ECPR39';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39_DACS-3604] @ChartId=2100113938, @PqrsNum='ECPR39';
*/

-- End of 12) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL
GO

-- Start of 13) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL

------------------------------------------------------------------------------------
-- 13) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,2,3,6,7,8,9,11','02,10,11,19,20,22,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11) OR [LOCATION_OF_SERVICE] IN (02,10,11,19,20,22,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------


	-- do we have any Diagnosis of migraine PLUS (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have any Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46] @ChartId=2100113940, @PqrsNum='ECPR46';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46_DACS-3604] @ChartId=2100113940, @PqrsNum='ECPR46';
*/

-- End of 13) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL
GO

-- Start of 14) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL

------------------------------------------------------------------------------------
-- 14) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;
	

	----------------
	-- check PATIENT_CLASS_ID 
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9','21') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (7,8,9) OR [LOCATION_OF_SERVICE] IN (21) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have an (ICD-10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (ICD-10)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CPT)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1] @ChartId=2100113945, @PqrsNum='THEPQR1';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1_DACS-3604] @ChartId=2100113945, @PqrsNum='THEPQR1';
*/



-- End of 14) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL
GO

-- Start of 15) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL

------------------------------------------------------------------------------------
-- 15) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,2,3,6,7,8,9,11','02,21,22,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11) OR [LOCATION_OF_SERVICE] IN (02,21,22,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have any Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have any Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51] @ChartId=2100113941, @PqrsNum='ECPR51';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51_DACS-3604] @ChartId=2100113941, @PqrsNum='ECPR51';
*/


-- End of 15) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL
GO

-- Start of 16) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL

------------------------------------------------------------------------------------
-- 16) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9,12,13','21,31,32') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (7,8,9,12,13) OR [LOCATION_OF_SERVICE] IN (21,31,32) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Denominator Exclusion Diagnosis List?
	IF EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Denominator Exclusion Diagnosis List item found)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2] @ChartId=2100113946, @PqrsNum='THEPQR2';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2_DACS-3604] @ChartId=2100113946, @PqrsNum='THEPQR2';
*/



-- End of 16) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL
GO

-- Start of 17) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL

------------------------------------------------------------------------------------
-- 17) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for heart failure (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for heart failure (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Outpatient Encounters during performance period (CPT) and Inpatient Discharges during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have any diagnosis exclusions?
	IF EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Excluded code found (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3] @ChartId=2100114076, @PqrsNum='THEPQR3';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3_DACS-3604] @ChartId=2100114076, @PqrsNum='THEPQR3';
*/

-- End of 17) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL
GO

-- Start of 18) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL

------------------------------------------------------------------------------------
-- 18) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001] @ChartId=2100114076, @PqrsNum='001';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001_DACS-3604] @ChartId=2100114076, @PqrsNum='001';
*/
-- End of 18) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL
GO

-- Start of 19) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL

------------------------------------------------------------------------------------
-- 19) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick1MatchCountB <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] @ChartId=2100113748, @PqrsNum='007-A';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A_DACS-3604] @ChartId=2100113748, @PqrsNum='007-A';
*/


-- End of 19) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
GO

-- Start of 20) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL

------------------------------------------------------------------------------------
-- 20) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick1MatchCountB <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] @ChartId=2100113748, @PqrsNum='007-B';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B_DACS-3604] @ChartId=2100113748, @PqrsNum='007-B';
*/
-- End of 20) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
GO

-- Start of 21) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL

------------------------------------------------------------------------------------
-- 21) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1','23') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId CANNOT have a valid patient class type of (1) OR Location of Service of (23).', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047] @ChartId=2100113727, @PqrsNum='047';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047_DACS-3604] @ChartId=2100113727, @PqrsNum='047';
*/
-- End of 21) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL
GO

-- Start of 22) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL

------------------------------------------------------------------------------------
-- 22) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 3 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9','21') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an EXCLUDED Physician service class of (7, 8 or 9) Location of Service value of (21)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for pharyngitis or tonsillitis (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066] @ChartId=2100113927, @PqrsNum='066';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066_DACS-3604] @ChartId=2100113927, @PqrsNum='066';
*/


-- End of 22) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL
GO

-- Start of 23) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL

------------------------------------------------------------------------------------
-- 23) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 3months on date of encounter
	----------------
	DECLARE @ageFrom DECIMAL(5, 2) = 0.25;
	DECLARE @ageTo INT = 999;
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge DECIMAL(5, 2) = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
			RETURN;
		END;
		
		DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PatientDob] from @tempChartInfo);
		
		IF @patienDOB IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			RETURN;
		END;
		
		SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			RETURN;
		END;

		-- check the age constraints
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9','21') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an EXCLUDED Physician service class of (7, 8 or 9) Location of Service value of (21)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116] @ChartId=2100113593, @PqrsNum='116';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116_DACS-3604] @ChartId=2100113593, @PqrsNum='116';
*/
-- End of 23) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL
GO

-- Start of 24) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A].SQL

------------------------------------------------------------------------------------
-- 24) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD‐10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] @ChartId=2100113726, @PqrsNum='118-A';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A_DACS-3604] @ChartId=2100113726, @PqrsNum='118-A';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] @ChartId=2100116965, @PqrsNum='118-A';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A_DACS-3604] @ChartId=2100116965, @PqrsNum='118-A';
*/
-- End of 24) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A].SQL
GO

-- Start of 25) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL

------------------------------------------------------------------------------------
-- 25) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for diabetes (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;
	
	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] @ChartId=2100113726, @PqrsNum='118-B';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B_DACS-3604] @ChartId=2100113726, @PqrsNum='118-B';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] @ChartId=2100116965, @PqrsNum='118-B';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B_DACS-3604] @ChartId=2100116965, @PqrsNum='118-B';
*/

-- End of 25) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
GO

-- Start of 26) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL

------------------------------------------------------------------------------------
-- 26) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) -- OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList) -- ignore this for now since this is a "does NOT have" type of MIPS test
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Not Eligible for Depression Screening or Follow-Up Plan (Denominator Exclusions) – Patients who have been diagnosed with bipolar disorder?  if we do, reject this MIPS.
	IF EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have Depression Screening or Follow-Up Plan (Denominator Exclusions) – Patients who have been diagnosed with bipolar disorder)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT or HCPCS)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134] @ChartId=2100113931, @PqrsNum='134';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134_DACS-3604] @ChartId=2100113931, @PqrsNum='134';
*/

-- End of 26) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL
GO

-- Start of 27) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL

------------------------------------------------------------------------------------
-- 27) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of 187, there are 1 valid decision paths.  the data is stored by PQRS# '187' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId, null, '02,10') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	IF EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value2] IN (SELECT [Modifier] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187] @ChartId=2100113592, @PqrsNum='187';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187_DACS-3604] @ChartId=2100113592, @PqrsNum='187';
*/

-- End of 27) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL
GO

-- Start of 28) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL

------------------------------------------------------------------------------------
-- 28) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for atrial fibrillation or atrial flutter (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for atrial fibrillation or atrial flutter (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326] @ChartId=2100113591, @PqrsNum='326';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326_DACS-3604] @ChartId=2100113591, @PqrsNum='326';
*/


-- End of 28) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL
GO

-- Start of 29) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL

------------------------------------------------------------------------------------
-- 29) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for acute sinusitis (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for acute sinusitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for bacterial and infectious agents (ICD-10-CM)?
	DECLARE @AskQuestionG9364 VARCHAR(5) = 'G9364';
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SET @AskQuestionG9364 = 'GGGGG';
		PRINT('ask all questions since criteria Diagnosis for bacterial and infectious agents (ICD-10-CM) NOT found');
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[Code] AS 'CODE'
	FROM 
		@tempDenominatorList tdl
	WHERE 
		tdl.[CodingSystem] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
		AND tdl.[Code] <> @AskQuestionG9364
	ORDER BY
		tdl.[Code];

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114172, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114172, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100113594, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100113594, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114070, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114070, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114071, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114071, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114068, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114068, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114069, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114069, @PqrsNum='332';
*/


-- End of 29) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL
GO

-- Start of 30) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL

------------------------------------------------------------------------------------
-- 30) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId, null, '02,10') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	IF EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value2] IN (SELECT [Modifier] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415] @ChartId=2100113933, @PqrsNum='415';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415_DACS-3604] @ChartId=2100113933, @PqrsNum='415';
*/
-- End of 30) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL
GO

-- Start of 31) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL

------------------------------------------------------------------------------------
-- 31) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId, null,'02,10') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	IF EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value2] IN (SELECT [Modifier] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416] @ChartId=2100113934, @PqrsNum='416';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416_DACS-3604] @ChartId=2100113934, @PqrsNum='416';
*/


-- End of 31) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL
GO

-- Start of 01) DACS-3593 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3593 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL
------------------------------------------------------------------------------------
GO
-- begin tran; -- testing
	----------------
	/*
	reference document "MIPS 8.13.docx" within DACS-3361 Jira ticket for more details

	todo list: (* = handled in this Script)
	*005-A
	*005-B
	*007-A
	*007-B -- updated to show a question if cptcodes not found to satisfy miocarditus criteria (behaves as mipps 332 now)
	*332
	*ACEP60
	*ACEP61
	*ACEP64
	*ECPR39
	*ECPR51
	*HCPR27
	*PQRANES1
	*THEPQR1
	*THEPQR2
	*THEPQR4
	*HCPR24 - converting to single critera MIPS returning a question.
	*047 - updated to use the new fields that allow a definition to be placed below the MIPS.
	*134 - updated to replace question with denominator exclusion response entry
	*326 - converts questions to denominator exclusions
	415 - no changes made.  BUT, looks like it might need definitions added to follow the MIPS section
	*ECPR46 - updated to move the appendix image to bottom of MIPS
	*116 - changed questions to exclusions.  one exclusion has a lot of words (more than 500). uses an image that does not look quite right.  will have to wait for branch merge for image update.
	
	
	
	*/
	----------------
	
	--------------------------------------------
	-- Backup our data to be worked upon
	--------------------------------------------
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3593';
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3593';
	

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @measureId INT;
	DECLARE @measureName VARCHAR(32);
	
	DECLARE @foundRecordId INT;
	DECLARE @oldString VARCHAR(1000);
    DECLARE @newString VARCHAR(1000);

	----------------
	-- THEPQR1  : remove the "not"
	----------------
	SET @measureName = 'THEPQR1';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
		SET @oldString = 'Patient does <strong>NOT</strong> have any of';
		SET @newString = 'Patient does not have any of';

		SET @foundRecordId = (
			SELECT TOP 1
				[CMS_PQRI_MEASURE_CODE_ID] 
			FROM 
				[CMS_PQRI_MEASURE_CODE] 
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] LIKE (@oldString + '%')
			) ;

		SELECT '@foundRecordId =' = @foundRecordId;
		SELECT 'Old description =' = (SELECT [DESCRIPTION] FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_CODE_ID] = @foundrecordId) 

		IF @foundRecordId > 0
			UPDATE [CMS_PQRI_MEASURE_CODE]
				SET [DESCRIPTION] = REPLACE([DESCRIPTION], @oldString, @newString)
			WHERE
				[CMS_PQRI_MEASURE_CODE_ID] = @foundRecordId;
		ELSE
			SELECT 'Error: unable to find record to update for' + @measureName;
			
		SELECT 'New description =' = (SELECT [DESCRIPTION] FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_CODE_ID] = @foundrecordId) 

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';

	----------------
	-- THEPQR2  : reorder them
	----------------
	SET @measureName = 'THEPQR2';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
		DROP TABLE IF EXISTS #TempTHEPQR2Table;
		
		SELECT 
			*
		INTO 
			#TempTHEPQR2Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempTHEPQR2Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempTHEPQR2Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempTHEPQR2Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','QR201',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation indicating patient has an active diagnosis or a history of diagnosis that meets criteria for long-term utilization of Proton Pump Inhibitors. (PQR201) <p><img src="/WebPages/Images/MIPS/MIPS_THEPQR2_PQR201_DenominatorExclustionTable.png" alt="(PQR201) Exception table image"></p> ')
				,(@measureId,'HCPCS','DG002',NULL,'2024-01-01','Performance Met: (Inpatient): Proton Pump Inhibitors discontinued by discharge OR (PAC/SNF): Proton Pump Inhibitors discontinued. ')
				,(@measureId,'HCPCS','DG003',NULL,'2024-01-01','Performance Not Met: Proton Pump Inhibitors not discontinued; reason not given. ')
				,(@measureId,'HCPCS','DG004',NULL,'2024-01-01','Denominator Exception: <ul><li>Documented medical reason for exclusion</li><li>Patient refusal</li><li>Eloped or left AMA</li><li>Expired</li><li>Discharged to hospice</li></ul> ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG847',NULL,'2024-01-01','Was a Proton Pump Inhibitor (PPI) Medication DG847 used? <ul><li>Omeprazole (Prilosec, Prilosec OTC, Zegerid)</li><li>Lansoprazole (Prevacid)</li><li>Pantoprazole (Protonix)</li><li>Rebeprazole (Aciphex)</li><li>Esomeprazole (Nexium)</li><li>Dexlansoprazole (Dexilant, Kapidex)</li></ul> ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- PQRANES1  : reorder them
	----------------
	SET @measureName = 'PQRANES1';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempPQRANES1Table;
		
		SELECT 
			*
		INTO 
			#TempPQRANES1Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempPQRANES1Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempPQRANES1Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempPQRANES1Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','DG014',NULL,'2024-01-01','Performance Met: Patients for whom a peripheral nerve block is performed in the Emergency Department as evidenced by Presence of CPT Code, OR Documentation that peripheral nerve block was performed (CPT Codes: 64447, 64448, 64450) ')
				,(@measureId,'HCPCS','DG015',NULL,'2024-01-01','Performance Not Met: Peripheral nerve block not performed as evidenced by Absence of CPT Code in Numerator Met AND Absence of Documentation ')
				,(@measureId,'HCPCS','DG016',NULL,'2024-01-01','Denominator Exception: Documented medical reason for exclusion. Example of Medical Exclusions: open fracture, infection at the insertion site, or other medical reason, patient unable to consent. ')
				,(@measureId,'HCPCS','DG017',NULL,'2024-01-01','Denominator Exception: Documented patient refusal. Documentation Example: Patient refused block placement ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 332  : reorder them
	----------------
	SET @measureName = '332';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp332Table;
		
		SELECT 
			*
		INTO 
			#Temp332Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp332Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp332Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp332Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9315',NULL,'2024-01-01','Performance Met: Amoxicillin, with or without clavulanate, prescribed asa first line antibiotic at the time of diagnosis. ')
				,(@measureId,'HCPCS','G9314',NULL,'2024-01-01','Performance Not Met: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis, reason not given. ')
				,(@measureId,'HCPCS','G9313',NULL,'2024-01-01','Denominator Exception: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis for documented reason. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','G9364',NULL,'2024-01-01','Sinusitis caused by, or presumed to be caused by, bacterial infection: G9364? ')
				,(@measureId,'DQ411','G9498',NULL,'2024-01-01','Antibiotic regimen prescribed: G9498? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- HCPR27  : reorder them
	----------------
	SET @measureName = 'HCPR27';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempHCPR27Table;
		
		SELECT 
			*
		INTO 
			#TempHCPR27Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempHCPR27Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempHCPR27Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempHCPR27Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0704',NULL,'2024-01-01','Denominator EXCLUSION: Transferred, eloped, AMA, or expired patients are excluded. ')
				,(@measureId,'HCPCS','VH273',NULL,'2024-01-01','Performance Met:  Point-of-Care Ultrasound evaluation for Pneumothorax performed. ')
				,(@measureId,'HCPCS','VH275',NULL,'2024-01-01','Performance Not Met: Point-of-Care Ultrasound evaluation for pneumothorax not performed. ')
				,(@measureId,'HCPCS','VH274',NULL,'2024-01-01','Denominator Exception:  Documented medical reason for not performing Point-of-Care Ultrasound (e.g. no ultrasound machine available, patient refusal). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','00001',NULL,'2024-01-01','CVC Insertion was performed on internal jugular or subclavian veins (Pseudo Code): HCPR2701? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ECPR51  : reorder them
	----------------
	SET @measureName = 'ECPR51';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR51Table;
		
		SELECT 
			*
		INTO 
			#TempECPR51Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR51Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR51Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR51Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0700',NULL,'2024-01-01','Denominator EXCLUSION: Patient Transfered, elope or is an AMA patients? ')
				,(@measureId,'HCPCS','VE269',NULL,'2024-01-01','Performance Met: Naloxone was prescribed at discharge AND patient was educated about use. *NOTE: Distribution of Naloxone to patient at discharge is also acceptable in lieu of Naloxone prescription. ')
				,(@measureId,'HCPCS','VE271',NULL,'2024-01-01','Performance Not Met: Naloxone medication was not prescribed at discharge OR patient was not educated about use. ')
				,(@measureId,'HCPCS','VE270',NULL,'2024-01-01','Denominator Exception: Naloxone was not prescribed at discharge due to medical reasons such as allergy. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG519',NULL,'2024-01-01','Patient has Disposition of Discharged (Pseudo code - DG519)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP64  : reorder them
	----------------
	SET @measureName = 'ACEP64';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP64Table;
		
		SELECT 
			*
		INTO 
			#TempACEP64Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP64Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP64Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP64Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','P6401',NULL,'2024-01-01','Denominator EXCLUSIONS: <ul>  <li>Syncope</li>  <li>Pulmonary embolism</li>  <li>Proximal DVT</li>  <li>Already on anticoagulation at time of DVT diagnosis based on listed home medications</li></ul> ')
				,(@measureId,'HCPCS','P6402',NULL,'2024-01-01','Performance Met: Patient discharged from ED. ')
				,(@measureId,'HCPCS','P6403',NULL,'2024-01-01','Performance Not Met : Patient not discharged from ED. ')
				,(@measureId,'HCPCS','P6404',NULL,'2024-01-01','Denominator Exception: Death, LAMA, LWBS, LWT. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP60  : reorder them
	----------------
	SET @measureName = 'ACEP60';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP60Table;
		
		SELECT 
			*
		INTO 
			#TempACEP60Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP60Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP60Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP60Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','P6001',NULL,'2024-01-01','Denominator EXCLUSIONS: <ul><li>Heart Disease (coronary artery disease, Myocardial Infarction, CHF, cardiomyopathy, etc.)</li><li>Heart Rhythm Disorders (Arrhythmias, Sinus Node Dysfunction, Uncontrolled Atrial Fibrillation, etc.)</li><li>Aortic Dissection</li><li>Pulmonary Embolism</li><li>Subarachnoid Hemorrhage</li><li>Coagulation Disorder</li></ul> ')
				,(@measureId,'HCPCS','P6002',NULL,'2024-01-01','Performance Met: Patient discharged from ED. ')
				,(@measureId,'HCPCS','P6003',NULL,'2024-01-01','Performance Not Met: Patient not discharged from ED. ')
				,(@measureId,'HCPCS','P6004',NULL,'2024-01-01','Denominator Exception: Death, LAMA, LWBS, LWT. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP61  : reorder them
	----------------
	SET @measureName = 'ACEP61';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP61Table;
		
		SELECT 
			*
		INTO 
			#TempACEP61Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP61Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP61Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP61Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','DG063',NULL,'2024-01-01','Denominator EXCLUSIONS: History of Cystic Fibrosis, Airway Malformations, Immunodeficiency Syndromes, Pneumonia. ')
				,(@measureId,'HCPCS','DG062',NULL,'2024-01-01','Performance Met: A chest x-ray was ordered/performed for the patient. ')
				,(@measureId,'HCPCS','DG061',NULL,'2024-01-01','Performance Not Met: A chest x-ray was not ordered/performed for the patient. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';
 

	----------------
	-- ECPR39  : reorder them
	----------------
	SET @measureName = 'ECPR39';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR39Table;
		
		SELECT 
			*
		INTO 
			#TempECPR39Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR39Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR39Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR39Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0700',NULL,'2024-01-01','Denominator EXCLUSIONS: Transferred, eloped or AMA patients are excluded. ')
				,(@measureId,'HCPCS','VE250',NULL,'2024-01-01','Performance Met: Patients who did not have a head CT ordered. ')
				,(@measureId,'HCPCS','VE252',NULL,'2024-01-01','Performance Not Met: Patients who did have a Head CT ordered; reason not given. ')
				,(@measureId,'HCPCS','VE251',NULL,'2024-01-01','Denominator Exception:  Patients who did have a heat CT ordered for medical reason documented by the eligible professional <p>(i.e., <ul><li>Seizure;</li> <li>alcohol/drug intoxication;</li> <li>vomiting;</li> <li>altered mental status;</li> <li>abnormal neurologic exam;</li><li>concern for intracranial injury/hemorrhage, stroke, or mass lesion</li></ul>)</p> ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 005-A  : update title
	----------------
	SET @measureName = '005-A';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '005-A Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- should read:
		-- MIPS# 005-A : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF HF ASSESSED DURING AN OUTPATIENT ENCOUNTER): Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 005-A : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) <= 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period: (SUBMISSION CRITERIA 1: All patients with a diagnosis of HF assessed during an outpatient encounter). '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '005-A Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 005-B  : update title
	----------------
	SET @measureName = '005-B';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '005-B Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- should read:
		-- MIPS# 005-B : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF HF AND DISCHARGED FROM HOSPITAL DENOMINATOR) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 005-B : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) <= 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period: (SUBMISSION CRITERIA 2: All patients with a diagnosis of HF and discharged from hospital). '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '005-B Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- THEPQR4  : reorder and put the CPT to be written in a more visible place for the question.
	----------------
	SET @measureName = 'THEPQR4';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempTHEPQR4Table;
		
		SELECT 
			*
		INTO 
			#TempTHEPQR4Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempTHEPQR4Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempTHEPQR4Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempTHEPQR4Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','QR307',NULL,'2024-01-01','Denominator EXCLUSION: <ul><li>Patient on hospice, or discharged to hospice.</li><li>Eloped or left AMA.</li><li>Expired</li><li>Comfort measures documented (Documented code status of DNR-A)</li><li>Transferred to another hospital</li><li>Patient admission to psychiatric or behavioral care</li></ul> (PQR307) ')
				,(@measureId,'HCPCS','QR309',NULL,'2024-01-01','Performance Met:  Patient received order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service (PQR309) ')
				,(@measureId,'HCPCS','QR310',NULL,'2024-01-01','Performance Not Met:  Patient did not receive an order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service (PQR310) ')
				,(@measureId,'HCPCS','QR308',NULL,'2024-01-01','Denominator Exception: <ul><li>Patient or medical decision maker refusal.</li><li>Documented medical reason for exclusion (example: palliative care not appropriate).</li><li>Palliative care not available, or system issue preventing palliative care consult.</li></ul> (PQR308) ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG111',NULL,'2024-01-01','Patient has any of the following? (DG111) <ul><li>2+ same diag ED or hospitalizations in 12 months (PQR301)</li><li>Chronic oxygen, or Vent (PQR302)</li><li>Hospital Admit from LTC Fac (PQR303)</li><li>Stage 4/Metastatic cancer (PQR304)</li><li>Difficult to control phys symptoms (PQR305)</li><li>Complex care requirements (PQR306): <ul><li>Home infusion</li><li>Tube feeding</li><li>mechanical Vent</li><li>24hr Bedbound care</li></ul></li><li>(SDOH) (ICD10): Z55, Z56, Z59, Z60, Z64, Z65</li></ul>')
				;
		
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 007-A  : reorder them
	----------------
	SET @measureName = '007-A';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp007ATable;
		
		SELECT 
			*
		INTO 
			#Temp007ATable
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp007ATable;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp007ATable);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp007ATable);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9189',NULL,'2024-01-01','Performance Met: Beta-blocker therapy prescribed or currently being taken. ')
				,(@measureId,'HCPCS','G9188',NULL,'2024-01-01','Performance Not Met: Beta-blocker therapy not prescribed, reason not given. ')
				,(@measureId,'HCPCS','G9190',NULL,'2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons). ')
				,(@measureId,'HCPCS','G9191',NULL,'2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','G8694',NULL,'2024-01-01','Is Left ventricular ejection fraction (LVEF) less than <= 40% or documentation of moderate or severe LVSD: G8694? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 007-B  : reorder them
	----------------
	SET @measureName = '007-B';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp007BTable;
		
		SELECT 
			*
		INTO 
			#Temp007BTable
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp007BTable;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp007BTable);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp007BTable);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','4008F',NULL,'2024-01-01','Performance Met: Beta-blocker therapy prescribed or currently being taken. ')
				,(@measureId,'HCPCS','4008F','8P','2024-01-01','Performance Not Met: Beta-blocker therapy not prescribed, reason not otherwise specified. ')
				,(@measureId,'HCPCS','4008F','1P','2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons). ')
				,(@measureId,'HCPCS','4008F','2P','2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','00001',NULL,'2024-01-01','Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- HCPR24  : reorder them
	----------------
	SET @measureName = 'HCPR24';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempHCPR24Table;
		
		SELECT 
			*
		INTO 
			#TempHCPR24Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempHCPR24Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempHCPR24Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempHCPR24Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0704',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Transferred, eloped, AMA or expired patients are excluded. ')
				,(@measureId,'HCPCS','VH271',NULL,'2024-01-01','Performance Met: <ul><li>Vancomycin not ordered</li><li>OR Vancomycin discontinued at admission.</li><li>OR Vancomycin ordered AND MRSA infection identified or risk for MRSA infection documented <p>(i.e., <ul><li>nasal colonization,</li><li>prior MRSA infection,</li><li>recent hospitalization,</li><li>recent antibiotics,</li><li>penetrating injury,</li><li>IVDU,</li><li>purulent cellulitis,</li><li>SIRS criteria,</li><li>sepsis,</li><li>impaired host defense</li></ul>)</p></li></ul> ')
				,(@measureId,'HCPCS','VH272',NULL,'2024-01-01','Performance Not Met: : Vancomycin ordered AND no MRSA infection identified OR no risk for MRSA infection documented. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','V0717',NULL,'2024-01-01','Patient Admitted or placed in Observation Status (V0717)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			
		-- before changes
		SELECT 'HCPR24 Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: HCPR24 Appropriate Utilization of Vancomycin for Cellulitis: Percentage of patients with Cellulitis who did not receive Vancomycin unless MRSA Infection or risk for MRSA Infection was identified.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'HCPR24 : Appropriate Utilization of Vancomycin for Cellulitis: Percentage of patients with Cellulitis who did not receive Vancomycin unless MRSA Infection or risk for MRSA Infection was identified. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT 'HCPR24 Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 047  : update MEASURE_HOTSHEET_URI
	----------------
	SET @measureName = '047';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '047 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><strong>Definition:</strong></p><p><strong>Documentation that Patient did not Wish or was not able to Name a Surrogate Decision Maker or Provide an Advance Care Plan</strong> – May also include: <ul><li>That the patient’s cultural and/or spiritual beliefs preclude a discussion of advance care planning, and thus harmful to the physician-patient relationship.</li></ul></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '047 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

		-- remove the definition from the original not met response which was:
		-- Performance Not Met: Advance Care Planning not documented, reason not otherwise specified. <p><strong>Definition:</strong></p><p><strong>Documentation that Patient did not Wish or was not able to Name a Surrogate Decision Maker or Provide an Advance Care Plan</strong> – May also include: <ul><li>That the patient’s cultural and/or spiritual beliefs preclude a discussion of advance care planning, and thus harmful to the physician-patient relationship.</li></ul></p>

		SELECT '047 `Performance Not Met` description before update:' = (
			SELECT	
				[DESCRIPTION] 
			FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
				[CMS_PQRI_MEASURE_ID] = @measureId
				AND [CODING_SYSTEM] = 'HCPCS'
				AND [CODE] = '1123F'
				AND [MODIFIER] = '8P'
			);
		
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [DESCRIPTION] = 'Performance Not Met: Advance Care Planning not documented, reason not otherwise specified. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId
			AND [CODING_SYSTEM] = 'HCPCS'
			AND [CODE] = '1123F'
			AND [MODIFIER] = '8P';

		SELECT '047 `Performance Not Met` description after update:' = (
			SELECT	
				[DESCRIPTION] 
			FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
				[CMS_PQRI_MEASURE_ID] = @measureId
				AND [CODING_SYSTEM] = 'HCPCS'
				AND [CODE] = '1123F'
				AND [MODIFIER] = '8P'
			);
	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 134  : update title
	----------------
	SET @measureName = '134';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '134 Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: MIPS# 134 : Preventive Care and Screening: Screening for Depression and Follow-Up Plan : Percentage of patients aged 12 years and older screened for depression on the date of the encounter or up to 14 days prior to the date of the encounter using an age-appropriate standardized depression screening tool AND if positive, a follow-up plan is documented on the date of or up to two days after the date of the qualifying encounter. 

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 134 : Preventive Care and Screening: Screening for Depression and Follow-Up Plan : Percentage of patients aged 12 years and older screened for depression on the date of the encounter or up to 14 days prior to the date of the encounter using an age-appropriate standardized depression screening tool AND if positive, a follow-up plan is documented on the date of or up to two days after the date of the qualifying encounter. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '134 Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

		-- reorder the responses
		DROP TABLE IF EXISTS #Temp134Table;
		
		SELECT 
			*
		INTO 
			#Temp134Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp134Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp134Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp134Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9717',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation stating the patient has had a diagnosis of bipolar disorder. ')
				,(@measureId,'HCPCS','G8431',NULL,'2024-01-01','Performance Met: Screening for depression is documented as being positive AND a follow-up plan is documented. ')
				,(@measureId,'HCPCS','G8510',NULL,'2024-01-01','Performance Met: Screening for depression is documented as negative, a follow-up plan is not required. ')
				,(@measureId,'HCPCS','G8432',NULL,'2024-01-01','Performance Not Met: Depression screening not documented, reason not given. ')
				,(@measureId,'HCPCS','G8511',NULL,'2024-01-01','Performance Not Met: Screening for depression documented as positive, follow-up plan not documented, reason not given. ')
				,(@measureId,'HCPCS','G8433',NULL,'2024-01-01','Denominator Exception: Screening for depression not completed, documented patient or medical reason. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','G9717',NULL,'2024-01-01','Does NOT have Documentation stating the patient has had a diagnosis of bipolar disorder: (G9717)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;


	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 326  : reorder responses
	----------------
	SET @measureName = '326';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		DROP TABLE IF EXISTS #Temp326Table;
		
		SELECT 
			*
		INTO 
			#Temp326Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp326Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp326Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp326Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9929',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patient with transient or reversible cause of AF (e.g., pneumonia, hyperthyroidism, pregnancy, cardiac surgery). ')
				,(@measureId,'HCPCS','G9930',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients who are receiving comfort care only. ')
				,(@measureId,'HCPCS','G9931',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation of CHA2DS2-VASc risk score of 0 or 1 for men; or 0, 1, or 2 for women. ')
				,(@measureId,'HCPCS','G0044',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients with moderate or severe mitral stenosis. ')
				,(@measureId,'HCPCS','G0043',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients with mechanical prosthetic heart valve. ')
				,(@measureId,'HCPCS','G8967',NULL,'2024-01-01','Performance Met: FDA-approved oral anticoagulant is prescribed. ')
				,(@measureId,'HCPCS','G9928',NULL,'2024-01-01','Performance Not Met: FDA-approved anticoagulant not prescribed, reason not given. ')
				,(@measureId,'HCPCS','G8968',NULL,'2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing an FDA-approved anticoagulant (e.g., present or planned atrial appendage occlusion or ligation or patient being currently enrolled in a clinical trial related to AF/atrial flutter treatment). ')
				,(@measureId,'HCPCS','G8969',NULL,'2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing an oral anticoagulant that is FDA approved for the prevention of thromboembolism (e.g., patient preference for not receiving anticoagulation). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','00001',NULL,'2024-01-01','????: (00001)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;


	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ECPR46  : reorder codes
	----------------
	SET @measureName = 'ECPR46';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR46Table;
		
		SELECT 
			*
		INTO 
			#TempECPR46Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR46Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR46Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR46Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0709',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patient does NOT have active cancer, palliative care, or end-of-life care? ')
				,(@measureId,'HCPCS','VE263',NULL,'2024-01-01','Performance Met: Opiate not prescribed at discharge. ')
				,(@measureId,'HCPCS','VE265',NULL,'2024-01-01','Performance Not Met: Opiate prescribed, reason not specified. ')
				,(@measureId,'HCPCS','VE264',NULL,'2024-01-01','Denominator Exception: Opiate prescribed for medical reason documented by the Eligible Professional (i.e., suspected or diagnosed herniated disk, fracture, sciatica, radiculopathy). ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG469',NULL,'2024-01-01','Patient Disposition of Discharged – (Pseudo Code) (DG469)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

		-- before changes
		SELECT 'ECPR46 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><img src="/WebPages/Images/MIPS/Mips_ECPR46_AppendixAOpoidMedications.png" alt="(VE264) Appendix - Opoid Medications image"></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT 'ECPR46 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 116  : reorder codes
	----------------
	SET @measureName = '116';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp116Table;
		
		SELECT 
			*
		INTO 
			#Temp116Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp116Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp116Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp116Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G2176',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Outpatient, ED or Observation visits that result in an inpatient admission ')
				,(@measureId,'HCPCS','G2177',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Acute bronchitis/bronchiolitis episodes when the patient had a new or refill prescription of antibiotics (Table 1) in the 30 days prior to the episode date ')
				,(@measureId,'HCPCS','G9712',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation of medical reason(s) for prescribing or dispensing antibiotic. (G9712) <p><img src="/WebPages/Images/MIPS/MIPS_116_Definition1.png" alt="(G9712) Definition image"></p> ')
				,(@measureId,'HCPCS','G9713',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients who use hospice services any time during the measurement period ')
				,(@measureId,'HCPCS','4124F',NULL,'2024-01-01','Performance Met: Antibiotic neither prescribed nor dispensed. ')
				,(@measureId,'HCPCS','4120F',NULL,'2024-01-01','Performance Not Met: Antibiotic prescribed or dispensed. ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','ddd',NULL,'2024-01-01','Patient Disposition of Discharged – (Pseudo Code) (DG469)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

		-- before changes
		SELECT '116 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><img src="/WebPages/Images/MIPS/MIPS_116_Table1.png" alt="Table 1 image"></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '116 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


-- rollback tran; -- testing
-- commit tran; -- testing

GO

-- End of 01) DACS-3593 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL
GO

-- Start of 02) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));
	IF @ShowDebug <> 0 SELECT ' @foundDenominatorGroup1Pick1MatchCount =' =  @foundDenominatorGroup1Pick1MatchCount

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));
	IF @ShowDebug <> 0 SELECT ' @foundDenominatorGroup1Pick1MatchCountB =' =  @foundDenominatorGroup1Pick1MatchCountB

	IF @foundDenominatorGroup1Pick1MatchCount IS NULL AND @foundDenominatorGroup1Pick1MatchCountB IS NULL
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO


-- End of 02) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
GO

-- Start of 03) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount IS NULL AND @foundDenominatorGroup1Pick1MatchCountB IS NULL
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;
	
	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	-- satisfied enough to at least ask a question at this point.

	-- do we have a Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
		SELECT TOP 5
			'411' AS 'RESULT' 
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[Code] AS 'CODE'
		FROM 
			@tempDenominatorList tdl
		WHERE 
			tdl.[CodingSystem] = 'DQ411'
			AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
		ORDER BY
			tdl.[Code];
	ELSE
		SELECT 'RESULT'='411', 'QUESTION'=' ', 'CODE'='00001';


END -- end procedure

GO


-- End of 03) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
GO

-- Start of 04) DACS-3593 - Create  or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3593 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'AreAny2024MipsRuleSatisfiedByChart', @DestProc = 'AreAny2024MipsRuleSatisfiedByChart_DACS-3593';
GO

CREATE OR ALTER PROCEDURE [dbo].[AreAny2024MipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad ChartId ' = @ChartId;
		RETURN;
	END;
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @serviceAgreementId INT;
	DECLARE @dateOfService DATETIME;
	
	SELECT 
		 @serviceAgreementId = [SERVICE_AGREEMENT_ID]
		,@dateOfService = [TIME_OF_SERVICE]
	FROM 
		[dbo].[chart] 
	WHERE
		[CHART_ID] = @ChartId;

	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0 OR @dateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;

	PRINT('serviceAgreementId = ' + CAST(@serviceAgreementId AS VARCHAR(64)));
	PRINT('dateOfService = ' + CAST(@dateOfService AS VARCHAR(64)));

	
	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@serviceAgreementId, @Dos=@dateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @countSaMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- load our single criteria MIPS for testing
	-----------------------------------
	DECLARE @active2024MipsRules1CTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRules1CTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('HCPR24')							-- DACS-3593 - pippin - added
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
	;
	
	IF @TestAll <> 1 DELETE FROM @active2024MipsRules1CTable WHERE [NAME] NOT IN (SELECT [NAME] FROM @activeSAMipsRulesTable);

	DECLARE @count1CMips INT = (SELECT COUNT(*) FROM @active2024MipsRules1CTable);
	IF @count1CMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No 2024 1 criteria Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT '@count1CMips = ' = @count1CMips;
	IF @ShowDebug = 1 SELECT * FROM @active2024MipsRules1CTable;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = @count1CMips;

	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchResultsTable TABLE ( [RESULT] VARCHAR(32), [QUESTION] VARCHAR(1024), [CODE] VARCHAR(32));
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [NAME] FROM @active2024MipsRules1CTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NOT NULL 
		BEGIN
			DELETE FROM @FetchResultsTable;
			
			DECLARE @SQL NVARCHAR(512) = N'EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type' + REPLACE(@FetchMipsName,'-','') + '] @ChartId=@fCId,@PqrsNum=@fPqrs,@Dos=@fDos;';
			DECLARE @ParmDefinition NVARCHAR(512) = N'@fCId INT, @fPqrs VARCHAR(32), @fDos DATETIME';

			IF @ShowDebug = 1 PRINT('  --> @SQL = ' + @SQL);

			INSERT INTO 
				@FetchResultsTable
			EXEC sp_executesql @SQL, @ParmDefinition, @fCId=@ChartId, @fPqrs=@FetchMipsName, @fDos=@dateOfService;			

			IF @ShowDebug = 1 SELECT * FROM @FetchResultsTable;

			IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
			BEGIN
				IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @FetchMipsName;

				IF @TestAll <> 1 
				BEGIN 
				-- cleanup our cursor
					CLOSE cursorTempRows;  
					DEALLOCATE cursorTempRows; 
				END;

				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				IF @TestAll <> 1 RETURN;
			END;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	-----------------------------------
	-- load our dual criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '005') OR @TestAll = 1
	BEGIN
		PRINT('Processing: 005-A');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A @ChartId=@ChartId,@PqrsNum='005-A',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='005-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		PRINT('-------------------');		
		PRINT('Processing: 005-B');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B @ChartId=@ChartId,@PqrsNum='005-B',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '005-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '008') OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: 008-A');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A @ChartId=@ChartId,@PqrsNum='008-A',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='008-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		PRINT('-------------------');		
		PRINT('Processing: 008-B');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B @ChartId=@ChartId,@PqrsNum='008-B',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '008-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	-----------------------------------
	-- load our PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	DECLARE @MipsNameToTest VARCHAR(32) = 'PQRANES1';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP60';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP61';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP64';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	-----------------------------------
	-- all done
	-----------------------------------
	PRINT('-------------------');		
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;
END; -- end of SPROC

GO

/*
EXEC [dbo].AreAny2024MipsRuleSatisfiedByChart @ChartId=2100113944,@ShowDebug=1,@TestAll=1; -- tests PQRANES1

*/
-- End of 04) DACS-3593 - Create  or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
GO

-- Start of 05) DACS-3593 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3593 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId, null, '02,19,21,22,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [LOCATION_OF_SERVICE] IN (02,19,21,22,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	

	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis of Cellulitis (ICD10 Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of Cellulitis (ICD10 Codes))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24] @ChartId=2100113942,@PqrsNum='HCPR24',@Dos='8/9/2024';
*/
-- End of 05) DACS-3593 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24].SQL
GO

-- Start of 06) DACS-3593 - Create or Alter stored procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3593 - Create or Alter stored procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
------------------------------------------------------------------------------------
GO

GO

GO


CREATE OR ALTER   PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListById] 
	 @MeasureId INT
	,@Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		--PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));	-- DACS-3417, 08/19/2024 (pippin)
	END;

	DECLARE @dateOfService DATE = CAST(@Dos AS DATE);			-- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 cpm.[CMS_PQRI_MEASURE_ID]
		,cpm.[MEASURE_TITLE]
		,cpmc.[CMS_PQRI_MEASURE_CODE_ID]
		,cpmc.[CODING_SYSTEM]
		,cpmc.[OPTION_GROUP]
		,cpmc.[CODE]
		,cpmc.[MODIFIER]
		,cpmc.[DESCRIPTION]
		,
		CASE 
			WHEN cpmc.[END_DATE] IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.[END_DATE] 
			END [END_DATE]
		,cpmc.[CODE_2]
		,cpmc.[MODIFIER_2]
		,cpm.[MEASURE_TOOLTIP]				-- DACS-3417, 08/19/2024 (pippin)
		,cpm.[MEASURE_HOTSHEET_URI]			-- DACS-3417, 08/19/2024 (pippin)
		,NULL [ROW_NUMBER]
	FROM 
		[CMS_PQRI_MEASURE] cpm
		LEFT JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID] = cpm.[CMS_PQRI_MEASURE_ID]
	WHERE 
		--DATEADD(DAY, DATEDIFF(DAY, 0, @dateOfService), 0) BETWEEN cpm.[EFFECTIVE_DATE] AND ISNULL(cpm.[EXPIRATION_DATE], @dateOfService) -- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types
		(cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] <= @dateOfService)
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @dateOfService) 
		AND cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[CODING_SYSTEM] IN ('CPT_II','HCPCS')
	ORDER BY 
		cpmc.[CODE], cpmc.[MODIFIER]
	;

END -- end procedure

GO


-- End of 06) DACS-3593 - Create or Alter stored procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
GO

-- Start of 07) DACS-3593 - create or alter stored procedure - [dbo].[spSelectChartPqrs].SQL

------------------------------------------------------------------------------------
-- 07) DACS-3593 - create or alter stored procedure - [dbo].[spSelectChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectChartPqrs', @DestProc = 'spSelectChartPqrs_DACS-3593';
GO

CREATE OR ALTER   PROCEDURE [dbo].[spSelectChartPqrs] 
	@ChartId INT,
	@MeasureId INT = NULL,
	@MeasureCodeId INT = NULL
	WITH
EXEC AS CALLER AS

------------------------------------------------------------------------------------
-- Adds additional CODING_SYSTEM strings used within the various temporary tables to allow for extended behavior supporting new MIPS decision logic - DACS-3164 - 20240422 - pippin
------------------------------------------------------------------------------------

-- testing
-- DECLARE @ChartId INT = 2100107114;
-- DECLARE @MeasureId INT = NULL;
-- DECLARE @MeasureCodeId INT = NULL;
-- body of original SPROC -- >

DECLARE @chart_id INT = @ChartId;
DECLARE @measure_id INT = @MeasureId;
DECLARE @measure_code_id INT = @MeasureCodeId;
DECLARE @Now DATETIME = GETDATE();
DECLARE @flag VARCHAR(10) = '';
DECLARE @HasDXCode INT;
DECLARE @HasCPTCode INT;

Declare @PSP_CPT varchar(50)	-- added 2/21/2023 (dsexton)

-- Drop statements for new temp tables added 2/21/2023 (dsexton)
if object_id('TempDB..#MeasureList', 'U') is not null DROP TABLE #MeasureList;
if object_id('TempDB..#RequireCptMeasures', 'U') is not null DROP TABLE #RequireCptMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures2', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures2;
if object_id('TempDB..#RequiredMeasures2', 'U') is not null DROP TABLE #RequiredMeasures2;
if object_id('TempDB..#RequiredMeasuresOldLogic', 'U') is not null DROP TABLE #RequiredMeasuresOldLogic;
if object_id('TempDB..#Chart', 'U') is not null DROP TABLE #Chart;
--if object_id('TempDB..#ChartDiagCode9', 'U') is not null DROP TABLE #ChartDiagCode9;	-- DACS-3417, 08/19/2024 (pippin)
if object_id('TempDB..#ChartDiagCodeICD10', 'U') is not null DROP TABLE #ChartDiagCodeICD10;
if object_id('TempDB..#PPE_CPT', 'U') is not null DROP TABLE #PPE_CPT;

-- new temp table for tuning, 2/21/2023 (dsexton)
select chart_ID, service_agreement_ID, primary_complaint, chief_complaint, PHYSICIAN_SERVICE_PROC_ID, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
	, Time_of_Service, gender, patient_DOB, patient_age
  into #Chart	
from CHART
where chart_ID = @chart_id

-- select * from #Chart -- testing

/*
This sproc executes very frequently at certain times of the day. For example, on 2/21/2023 it executed nearly 8K times between 4:30-7:30 AM. By 3 pm it executed only an additional 3,500 times.
It is called by sproc spSelectMissingChartPqrs which has executed 37K times over the past seven days. 
Avg LReads have been 150K which adds up to several billion reads each day. 

Modified all CLR queries to instead write to temp tables, 2/21/2023 (dsexton).  This reduced logical reads 95% (13K vs 240K) when testing with chart_ID 101104526.
	-- Duration was reduced 80% (31ms vs 184ms).
*/


--WITH MeasureList						-- replaced all CLR queries with temp tables, 2/21/2023 (dsexton)
--AS (
	SELECT cpm.CMS_PQRI_MEASURE_ID,
		cpm.MEASURE_TITLE,
		cpm.REQUIRES_BOTH_CPT_AND_DX,
		cpmc.CMS_PQRI_MEASURE_CODE_ID,
		cpmc.CODING_SYSTEM,
		cpmc.OPTION_GROUP,
		cpmc.CODE,
		cpmc.MODIFIER,
		cpmc.[DESCRIPTION],
		CASE 
			WHEN cpmc.END_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.END_DATE 
			END END_DATE,
		cpmc.CODE_2,
		cpmc.MODIFIER_2,
		cpm.REQUIRES_MULTIPLE_CPTS,
		cpm.MULTIPLE_CPT_COUNT,
		cpm.REQUIRES_MULTIPLE_DX,
		cpm.REQUIRES_CPT_CODE,
		cpm.REQUIRED_CPT_CODE,
		CASE 
			WHEN COALESCE(cpm.REQUIRES_EM_ONLY, 0) = 1
				AND (c.PHYSICIAN_SERVICE_PROC_ID > 0 OR c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0)
				THEN 1
			ELSE 0
			END REQUIRES_EM_ONLY,
		CASE 
			WHEN COALESCE(cpm.MATCH_EM_LEVEL, 0) = 1
				THEN 1
			ELSE 0
			END MATCH_EM_LEVEL,
		CASE 
			WHEN cpmc.START_DATE IS NULL
				THEN '1/1/1900 00:00:00'
			ELSE cpmc.START_DATE
			END START_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE IS NULL
				THEN '02/20/2020 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
	    CONVERT(Date, c.TIME_OF_SERVICE) as DATE_OF_SERVICE,
		cpm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		cpm.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #MeasureList							-- tuning, 2/21/2023 (dsexton)
	FROM CMS_PQRI_MEASURE cpm WITH (NOLOCK)
	LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc WITH (NOLOCK) ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID
	--INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
	cross join #Chart c		--ON c.CHART_ID = @chart_id
	WHERE DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, c.TIME_OF_SERVICE)
		AND (
			ISNULL(cpm.GENDER, 'B') = 'B'
			OR cpm.GENDER = c.GENDER
			)
		AND (
			(
				(COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) = 0
				AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0)) = 999
				)
			OR (
				(c.PATIENT_AGE IS NOT NULL AND c.PATIENT_DOB IS NULL
				AND c.PATIENT_AGE BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				))
			
			OR (
				(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NOT NULL OR cpm.TO_AGE_FRACTIONAL IS NOT NULL)
				AND ((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				)
			
			OR (
			(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NULL AND cpm.TO_AGE_FRACTIONAL IS NULL)
				AND CAST(((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) AS INT) BETWEEN COALESCE(cpm.FROM_AGE, 0)  AND COALESCE(cpm.TO_AGE, 999)
				)
			)

		AND cpm.CMS_PQRI_MEASURE_ID IN (
			SELECT sapqrs.CMS_PQRI_MEASURE_ID
			FROM SERVICE_AGREEMENT_PQRS sapqrs WITH (NOLOCK)
			WHERE sapqrs.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND CONVERT(Date, c.TIME_OF_SERVICE) BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, @Now)
			)
	--),

-- select '#MeasureList' = null
-- select * from #MeasureList where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #MeasureList 


-- New objects for tuning, 2/21/2023 (dsexton)  -------------------------------------------------------------------------------
/* -- DACS-3417, 08/19/2024 (pippin)
SELECT cdc.ICD9_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, c.CHIEF_COMPLAINT, c.PRIMARY_COMPLAINT, c.Time_of_Service
  into #ChartDiagCode9
FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
*/

SELECT cdc.ICD10_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, cdc.DIAGNOSIS_TYPE_ID, cdc.IS_PRIMARY, c.Time_of_Service
  into #ChartDiagCodeICD10
FROM CHART_DIAGNOSIS_CODE_ICD10 cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID

SELECT cm.CPT_Code
  into #PPE_CPT
FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
	and ppe.CHART_ID = @chart_id	

select TOP 1 @PSP_CPT = CPT_CODE
FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
INNER JOIN #Chart c 
on PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
WHERE PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
        WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
            THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
        ELSE c.PHYSICIAN_SERVICE_PROC_ID
        END
-------------------------------------------------------------------------------------------------------------------

--RequiredMeasuresOldLogic
--AS (
SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		ROW_NUMBER() OVER (
			PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredMeasuresOldLogic	-- tuning, 2/21/2023 (dsexton)
	--FROM MeasureList ml
	from #MeasureList ml		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE (
			/*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
				
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR (cdc.DIAGNOSIS_TYPE_ID IN (1,3,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			OR (
				ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select 1 from #PPE_CPT as t where t.CPT_Code = ml.Code		-- tuning to replace old subquery, 2/21/2023 (dsexton)
					)
				)
			)
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
      ml.REQUIRES_EM_ONLY = 1
      AND 
			@PSP_CPT	 -- tuning to replace subquery, 2/21/2023 (dsexton)
			  IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395')
    )
--	)
-- select '#RequiredMeasuresOldLogic' = null
-- select * from #RequiredMeasuresOldLogic where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequiredMeasuresOldLogic 
--,
--RequiredDiagnosisMeasures
--AS (

	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 		   
		  /*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 1)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			

--    )
	  
-- select '#RequiredDiagnosisMeasures' = null
-- select * from #RequiredDiagnosisMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequiredDiagnosisMeasures 
	
--	,
--	RequiredDiagnosisMeasures2
--AS (
	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures2
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 
		 /*  -- DACS-3417, 08/19/2024 (pippin)
		  ml.CODING_SYSTEM = 'I9'
			AND EXISTS (
			/-*	-- example of old subquery, 2/21/2023 (dsexton)
				SELECT *
				FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
				INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = cdc.CHART_ID
				INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				WHERE cdc.CHART_ID = @chart_id
			*-/
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 0)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						)
			
			)
 --   )
	  
-- select '#RequiredDiagnosisMeasures2' = null
-- select * from #RequiredDiagnosisMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequiredDiagnosisMeasures2 

--	,
--	RequireCptMeasures
--AS (
     SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequireCptMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					SELECT *
					FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
					INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
					WHERE ppe.CHART_ID = @chart_id
						AND cm.CPT_CODE = ml.CODE
						AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					)
				
			
			
			
			
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
		ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
      AND  (
              SELECT  CPT_CODE
              FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
              INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
              WHERE PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                  AND PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
                      WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
                          THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                      ELSE c.PHYSICIAN_SERVICE_PROC_ID
                      END 
              ) = ml.Code
			  AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
			  )
--),

-- select '#RequireCptMeasures' = null
-- select * from #RequireCptMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequireCptMeasures 

--	RequiredMeasures2
--AS (
   
    SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
		rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
into #RequiredMeasures2
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		
		UNION
		SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
        rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS = 1
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		GROUP BY rdm.CMS_PQRI_MEASURE_ID, rdm.MEASURE_TITLE, rdm.REQUIRES_BOTH_CPT_AND_DX, rdm.CMS_PQRI_MEASURE_CODE_ID, rdm.CODING_SYSTEM, rdm.OPTION_GROUP, rdm.CODE, rdm.MODIFIER, rdm.[DESCRIPTION], rdm.END_DATE, rdm.CODE_2, rdm.MODIFIER_2, rdm.REQUIRES_EM_ONLY, rdm.MEASURE_TOOLTIP, rdm.MEASURE_HOTSHEET_URI, rcm.MULTIPLE_CPT_COUNT
		HAVING COUNT(rcm.CODE) = rcm.MULTIPLE_CPT_COUNT

		UNION
		SELECT rdm2.CMS_PQRI_MEASURE_ID,
		rdm2.MEASURE_TITLE,
		rdm2.REQUIRES_BOTH_CPT_AND_DX,
		rdm2.CMS_PQRI_MEASURE_CODE_ID,
		rdm2.CODING_SYSTEM,
		rdm2.OPTION_GROUP,
		rdm2.CODE,
		rdm2.MODIFIER,
        rdm2.[DESCRIPTION],
		rdm2.END_DATE,
		rdm2.CODE_2,
		rdm2.MODIFIER_2,
		rdm2.REQUIRES_EM_ONLY,
		rdm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm2.CMS_PQRI_MEASURE_ID ORDER BY rdm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures2 rdm2
		from #RequiredDiagnosisMeasures2 rdm2															-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID				-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		AND rdm2.CODE IS NOT NULL
		UNION
		
		SELECT rmol.CMS_PQRI_MEASURE_ID,
		rmol.MEASURE_TITLE,
		rmol.REQUIRES_BOTH_CPT_AND_DX,
		rmol.CMS_PQRI_MEASURE_CODE_ID,
		rmol.CODING_SYSTEM,
		rmol.OPTION_GROUP,
		rmol.CODE,
		rmol.MODIFIER,
		rmol.[DESCRIPTION],
		rmol.END_DATE,
		rmol.CODE_2,
		rmol.MODIFIER_2,
		rmol.REQUIRES_EM_ONLY,
		rmol.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rmol.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rmol.CMS_PQRI_MEASURE_ID ORDER BY rmol.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredMeasuresOldLogic rmol
		from #RequiredMeasuresOldLogic rmol			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		WHERE rmol.REQUIRES_BOTH_CPT_AND_DX = 1
		AND CONVERT(Date, rmol.DATE_OF_SERVICE) < rmol.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
		AND rmol.CODE IS NOT NULL
		
		
		UNION
		 
		SELECT rcm.CMS_PQRI_MEASURE_ID,
		rcm.MEASURE_TITLE,
		rcm.REQUIRES_BOTH_CPT_AND_DX,
		rcm.CMS_PQRI_MEASURE_CODE_ID,
		rcm.CODING_SYSTEM,
		rcm.OPTION_GROUP,
		rcm.CODE,
		rcm.MODIFIER,
		rcm.[DESCRIPTION],
		rcm.END_DATE,
		rcm.CODE_2,
		rcm.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm.CMS_PQRI_MEASURE_ID ORDER BY rcm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm
		from #RequireCptMeasures rcm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND COALESCE(rcm.REQUIRES_CPT_CODE, 0) = 0
		AND rcm.CODE IS NOT NULL

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		 

		 UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--)

-- select '#RequiredMeasures2' = null
-- select * from #RequiredMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequiredMeasures2 

	
SELECT DISTINCT CMS_PQRI_MEASURE_ID,
	MEASURE_TITLE,
	CMS_PQRI_MEASURE_CODE_ID,
	CODING_SYSTEM,
	NULL OPTION_GROUP,
	CASE COALESCE(REQUIRES_EM_ONLY, 0)
		WHEN 1
			THEN 'E&M'
		ELSE CODE
		END CODE,
	NULL MODIFIER,
	NULL [DESCRIPTION],
	NULL END_DATE,
	NULL CODE_2,
	NULL MODIFIER_2,
	MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	CAST([ROW_NUMBER] AS BIGINT) [ROW_NUMBER]
--FROM RequiredMeasures2
from #RequiredMeasures2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
WHERE @measure_id IS NULL
	AND @measure_code_id IS NULL
	AND [ROW_NUMBER] = 1

UNION

SELECT ml.CMS_PQRI_MEASURE_ID,
	ml.MEASURE_TITLE,
	ml.CMS_PQRI_MEASURE_CODE_ID,
	ml.CODING_SYSTEM,
	ml.OPTION_GROUP,
	ml.CODE,
	ml.MODIFIER,
	ml.[DESCRIPTION],
	ml.END_DATE,
	ml.CODE_2,
	ml.MODIFIER_2,
	ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	ml.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	NULL [ROW_NUMBER]
--FROM MeasureList ml
from #MeasureList ml						-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--INNER JOIN RequiredMeasures2 rm ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
INNER JOIN #RequiredMeasures2 rm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
WHERE (
		ml.CMS_PQRI_MEASURE_ID = @measure_id
		OR ml.CMS_PQRI_MEASURE_CODE_ID = @measure_code_id
		)
	AND ml.CODING_SYSTEM IN (
		'CPT_II',
		'HCPCS'
		)
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
	
ORDER BY CMS_PQRI_MEASURE_ID ASC,
	MEASURE_TITLE DESC

GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'spSelectChartPqrs', N'PARAMETER',N'@MeasureCodeId'))
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
END
GO

/*
exec spSelectChartPqrs @ChartId=2100113940,@MeasureId=null,@MeasureCodeId=null
*/
-- End of 07) DACS-3593 - create or alter stored procedure - [dbo].[spSelectChartPqrs].SQL
GO

-- Start of 08) DACS-3593 - create or alter stored procedure - [dbo].[spSelectMissingChartPqrs].SQL

------------------------------------------------------------------------------------
-- 08) DACS-3593 - create or alter stored procedure - [dbo].[spSelectMissingChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectMissingChartPqrs', @DestProc = 'spSelectMissingChartPqrs_DACS-3593a';
GO

CREATE OR ALTER PROCEDURE [dbo].[spSelectMissingChartPqrs]
	@ChartId int
WITH EXEC AS CALLER
AS

SET NOCOUNT ON							-- DACS-3457 - 20240723 - pippin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @chart_id INT =@ChartId;
DECLARE @RequiredMeasures table
(
  CMS_PQRI_MEASURE_ID int,
  MEASURE_TITLE varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  CMS_PQRI_MEASURE_CODE_ID int,
  CODING_SYSTEM varchar(20),
  OPTION_GROUP numeric(18,0),
  CODE varchar(20),
  MODIFIER varchar(20),
  [DESCRIPTION] varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  END_DATE date,
  CODE_2 varchar(6),
  MODIFIER_2 varchar(20),
  MEASURE_TOOLTIP varchar(4000), 		-- DACS-3417 - 20240830 - pippin - added field
  MEASURE_HOTSHEET_URI varchar(1000), 	-- DACS-3417 - 20240830 - pippin - added field
  [ROW_NUMBER] bigint
)

INSERT INTO @RequiredMeasures(
	 CMS_PQRI_MEASURE_ID
	,MEASURE_TITLE
	,CMS_PQRI_MEASURE_CODE_ID
	,CODING_SYSTEM
	,OPTION_GROUP
	,CODE
	,MODIFIER
	,[DESCRIPTION]
	,END_DATE
	,CODE_2
	,MODIFIER_2
	,MEASURE_TOOLTIP
	,MEASURE_HOTSHEET_URI
	,[ROW_NUMBER]
)
  EXEC [spSelectChartPqrs] @ChartId=@chart_id

SELECT *
FROM @RequiredMeasures rm
WHERE (SELECT COUNT(*)
       FROM PHYSICIAN_PROCEDURE_EVALUATION ppe
         JOIN CHARGE_MASTER cm on cm.CHARGE_MASTER_ID=ppe.PHYSICIAN_PROCEDURE_ID
         JOIN CMS_PQRI_MEASURE_CODE cpmc on cpmc.CMS_PQRI_MEASURE_ID=rm.CMS_PQRI_MEASURE_ID
       WHERE CHART_ID=@chart_id
         AND cm.CHARGE_MASTER_USAGE_CODE=9
         AND cpmc.CODING_SYSTEM in ('CPT_II', 'HCPCS', 'OTHER')			-- DACS-3593 - 20240903 - pippin - added 'OTHER' to "in" list
         AND cm.CPT_CODE=cpmc.CODE
         AND ppe.MODIFIERS=isnull(cpmc.MODIFIER, ''))=0
GO


-- End of 08) DACS-3593 - create or alter stored procedure - [dbo].[spSelectMissingChartPqrs].SQL
GO

-- Start of 09) DACS-3593 - create or alter stored procedure - [dbo].[spRemoveInapplicablePqrs].SQL

------------------------------------------------------------------------------------
-- 09) DACS-3593 - create or alter stored procedure - [dbo].[spRemoveInapplicablePqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spRemoveInapplicablePqrs', @DestProc = 'spRemoveInapplicablePqrs_DACS-3593a';
GO


CREATE OR ALTER PROCEDURE [dbo].[spRemoveInapplicablePqrs]
	@ChartId INT
WITH EXEC AS CALLER
AS
BEGIN
	DECLARE @chart_id INT=@ChartId;

	DECLARE @RequiredMeasures TABLE
	(
	   [CMS_PQRI_MEASURE_ID] INT
	  ,[MEASURE_TITLE] VARCHAR(2000)		-- DACS-3591, pippin -- increased column width to 2000 (original = 500)
	  ,[CMS_PQRI_MEASURE_CODE_ID] INT
	  ,[CODING_SYSTEM] VARCHAR(20)
	  ,[OPTION_GROUP] NUMERIC(18,0)
	  ,[CODE] VARCHAR(20)
	  ,[MODIFIER] VARCHAR(20)
	  ,[DESCRIPTION] VARCHAR(500)
	  ,[END_DATE] DATE
	  ,[CODE_2] VARCHAR(6)
	  ,[MODIFIER_2] VARCHAR(20)
	  ,[MEASURE_TOOLTIP] VARCHAR(4000)		-- added DACS-3593, 09/03/2024 (pippin)
	  ,[MEASURE_HOTSHEET_URI] VARCHAR(1000)	-- added DACS-3417, 08/19/2024 (pippin)
	  ,[ROW_NUMBER] BIGINT
	)
	------------------------------------------------------------------------------------
	-- DACS-3591, pippin -- formatting adjusted for improved readibility
	------------------------------------------------------------------------------------

	-- Populate the table variable with values returned from spSelectChartPQRS
	INSERT INTO @RequiredMeasures(
		 [CMS_PQRI_MEASURE_ID]
		,[MEASURE_TITLE]
		,[CMS_PQRI_MEASURE_CODE_ID]
		,[CODING_SYSTEM]
		,[OPTION_GROUP]
		,[CODE]
		,[MODIFIER]
		,[DESCRIPTION]
		,[END_DATE]
		,[CODE_2]
		,[MODIFIER_2]
	    ,[MEASURE_TOOLTIP]			-- added DACS-3593, 09/03/2024 (pippin)
	    ,[MEASURE_HOTSHEET_URI] 	-- added DACS-3417, 08/19/2024 (pippin)
		,[ROW_NUMBER]
		)
	  EXEC [spSelectChartPQRS] @ChartId=@chart_id

	-- Delete the PQRS items from PHYSICIAN_PROCEDURE_EVALUATION that are inapplicable to this chart
	DELETE 
		[PHYSICIAN_PROCEDURE_EVALUATION]
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID]=ppe.[PHYSICIAN_PROCEDURE_ID]
	WHERE 
		[CHART_ID]=@chart_id
		AND cm.[CHARGE_MASTER_USAGE_CODE]=9
		AND cm.[CPT_CODE] NOT IN (
			SELECT 
				cpmc.[CODE] 
			FROM 
				@RequiredMeasures rm
				JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID]=rm.[CMS_PQRI_MEASURE_ID]
			WHERE 
				cpmc.[CODING_SYSTEM] IN ('CPT_II', 'HCPCS', 'OTHER')
				AND cpmc.[CODE]=cm.[CPT_CODE]
				AND ppe.[MODIFIERS] LIKE ISNULL('%' + cpmc.[MODIFIER] + '%', '')
			)
		AND cm.[CPT_CODE] NOT IN (
			SELECT 
				cpmc.[CODE_2] 
			FROM 
				@RequiredMeasures rm
				JOIN [CMS_PQRI_MEASURE_CODE] cpmc on cpmc.[CMS_PQRI_MEASURE_ID]=rm.[CMS_PQRI_MEASURE_ID]
			WHERE 
				cpmc.[CODING_SYSTEM] IN ('CPT_II', 'HCPCS')
				AND cpmc.[CODE_2]=cm.[CPT_CODE]
				AND ppe.[MODIFIERS] LIKE ISNULL('%' + cpmc.[MODIFIER] + '%', '')
			)
END; -- end SPROC
GO


-- End of 09) DACS-3593 - create or alter stored procedure - [dbo].[spRemoveInapplicablePqrs].SQL
GO

-- Start of 01) DACS-3604 - Create or Alter function - [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService].SQL

----------------------------------------
-- 01) DACS-3604 - Create or Alter function - [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService].SQL
----------------------------------------
GO

GO


GO	

CREATE or ALTER FUNCTION [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService]
(
	 @PatientClassId INT
	,@ServiceAgreementId INT
	,@TestForPatientClassCodesCsv VARCHAR(64)
	,@TestForLocationOfServiceCsv VARCHAR(64)
)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN
	----------------
	-- validate parameters
	----------------
	IF @PatientClassId IS NULL 
		OR @PatientClassId <= 0
		OR @ServiceAgreementId IS NULL 
		OR @ServiceAgreementId <= 0
		RETURN -1;
	
	IF @TestForPatientClassCodesCsv IS NOT NULL AND LEN(LTRIM(RTRIM(@TestForPatientClassCodesCsv))) <= 0
		SET @TestForPatientClassCodesCsv = NULL;
	
	IF @TestForLocationOfServiceCsv IS NOT NULL AND LEN(LTRIM(RTRIM(@TestForLocationOfServiceCsv))) <= 0
		SET @TestForLocationOfServiceCsv = NULL;

	IF @TestForPatientClassCodesCsv IS NULL AND @TestForLocationOfServiceCsv IS NULL
		RETURN -2;
	
	----------------
	-- retrieve code and los from chart where PATIENT_CLASS_ID is specified
	----------------
	DECLARE @PhysicianServiceClassCode VARCHAR(64);
	DECLARE @LocationOfService VARCHAR(64);

	SELECT TOP 1 
		 @PhysicianServiceClassCode = [PHYSICIAN_SERVICE_CLASS_CD]
		,@LocationOfService = [LOCATION_OF_SERVICE]
	FROM 
		[dbo].[PATIENT_CLASS] WITH (NOLOCK)
	WHERE 
		[PATIENT_CLASS_ID] = @PatientClassId 
		AND [SERVICE_AGREEMENT_ID] = @ServiceAgreementId;
	
	----------------
	-- test patient class code
	----------------
	IF @TestForPatientClassCodesCsv IS NOT NULL AND @PhysicianServiceClassCode IS NOT NULL AND LEN(LTRIM(RTRIM(@PhysicianServiceClassCode))) > 0
	BEGIN
		DECLARE @splitsTestPatientCodes tIntString32;

		INSERT @splitsTestPatientCodes(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@TestForPatientClassCodesCsv, ',');
		
		IF EXISTS (SELECT 1 FROM @splitsTestPatientCodes) AND EXISTS (SELECT 1 FROM @splitsTestPatientCodes WHERE value = @PhysicianServiceClassCode)
			RETURN 1;
	END;

	----------------
	-- test location of service
	----------------
	IF @TestForLocationOfServiceCsv IS NOT NULL AND @LocationOfService IS NOT NULL AND LEN(LTRIM(RTRIM(@LocationOfService))) > 0
	BEGIN
		DECLARE @splitsTestLocationsOfService tIntString32;
		DECLARE @splitsChartLocationsOfService tIntString32;

		INSERT @splitsTestLocationsOfService(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@TestForLocationOfServiceCsv, ',');

		INSERT @splitsChartLocationsOfService(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@LocationOfService, ',');

		IF EXISTS (SELECT 1 FROM @splitsTestLocationsOfService) 
			AND EXISTS (SELECT 1 FROM @splitsChartLocationsOfService) -- prolly can remove.  just being paranoid about bad chart data
			AND EXISTS (SELECT 1 FROM @splitsChartLocationsOfService WHERE value IN (SELECT DISTINCT value FROM @splitsTestLocationsOfService))
				RETURN 1;
	END;

	RETURN 0;
END;

GO

/*
-- testing
DECLARE @result INT;
INSERT INTO @result SELECT * FROM dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(148,2307,'1,7,8,9','02,21,23');
SELECT * FROM @result
*/




-- End of 01) DACS-3604 - Create or Alter function - [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService].SQL
GO

-- Start of 02) DACS-3604 - CREATE or Alter FUNCTION - [dbo].[udfReturnMips411Questions].SQL

----------------------------------------
-- 02) DACS-3604 - CREATE or Alter FUNCTION - [dbo].[udfReturnMips411Questions].SQL
----------------------------------------
GO

GO

GO

	----------------
	-- making a reusable block out of oft used MIPS SQL Script
	----------------

CREATE or Alter FUNCTION [dbo].[udfReturnMips411Questions]
	(
		 @tempDenominatorList tDenominatorInfo READONLY
		,@MeasureId INT
	)
RETURNS @returnResults TABLE
(
	 [RESULT] VARCHAR(32)
	,[QUESTION] VARCHAR(2000)
	,[CODE] VARCHAR(32)
)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList tdl WHERE tdl.[CodingSystem] = 'DQ411' AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0)
		INSERT INTO @returnResults ([RESULT], [QUESTION], [CODE])
			VALUES ('411', ' ', '00001')
	ELSE
		INSERT INTO @returnResults ([RESULT], [QUESTION], [CODE])
			SELECT TOP 5
				'411' AS 'RESULT'
				, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
				, tdl.[Code] AS 'CODE'
			FROM 
				@tempDenominatorList tdl
			WHERE 
				tdl.[CodingSystem] = 'DQ411'
				AND tdl.[Description] IS NOT null AND LEN(tdl.[Description]) > 0
			ORDER BY
				tdl.[Code];
	RETURN;
END; -- end function

GO
 
-- End of 02) DACS-3604 - CREATE or Alter FUNCTION - [dbo].[udfReturnMips411Questions].SQL
GO

-- Start of 10) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL

------------------------------------------------------------------------------------
-- 10) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of THEPQR4, there are 1 valid decision paths.  the data is stored by PQRS# 'THEPQR4' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,2,3,6,7,8,9,11,12,13','21,22,23,31,32,33') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11,12,13) OR [LOCATION_OF_SERVICE] IN (21,22,23,31,32,33) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	
	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	
	-- do we have a Diagnosis in our inclusive diagnosis listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] @ChartId=2100113947, @PqrsNum='THEPQR4';
*/

-- End of 10) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
GO

-- Start of 11) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc =  'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of HCPR27, there are 1 valid decision paths.  the data is stored by PQRS# 'HCPR27' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,7,8,9','02,21,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,7,8,9) OR [LOCATION_OF_SERVICE] IN (02,21,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	

	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	
	 
	IF (NOT EXISTS (SELECT 1 FROM @tempProcedureList))
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	/*  NOT NEEDED at this time
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;
	*/

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Undergone CVC insertion (limited to internal jugular or subclavian lines) (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Undergone CVC insertion (limited to internal jugular or subclavian lines) (CPT Codes))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27] @ChartId=2100114190, @PqrsNum='HCPR27';
*/


-- End of 11) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL
GO

-- Start of 12) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL

------------------------------------------------------------------------------------
-- 12) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER  PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,2,3,6,7,8,9,11','02,11,19,20,21,22,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11) OR [LOCATION_OF_SERVICE] IN (02,11,19,20,21,22,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have an (ICD-10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of Syncope (ICD‐10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Inpatient or Observation Status settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39] @ChartId=2100113938, @PqrsNum='ECPR39';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39_DACS-3604] @ChartId=2100113938, @PqrsNum='ECPR39';
*/

-- End of 12) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL
GO

-- Start of 13) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL

------------------------------------------------------------------------------------
-- 13) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,2,3,6,7,8,9,11','02,10,11,19,20,22,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11) OR [LOCATION_OF_SERVICE] IN (02,10,11,19,20,22,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------


	-- do we have any Diagnosis of migraine PLUS (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have any Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46] @ChartId=2100113940, @PqrsNum='ECPR46';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46_DACS-3604] @ChartId=2100113940, @PqrsNum='ECPR46';
*/

-- End of 13) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL
GO

-- Start of 14) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL

------------------------------------------------------------------------------------
-- 14) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;
	

	----------------
	-- check PATIENT_CLASS_ID 
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9','21') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (7,8,9) OR [LOCATION_OF_SERVICE] IN (21) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have an (ICD-10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (ICD-10)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CPT)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1] @ChartId=2100113945, @PqrsNum='THEPQR1';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1_DACS-3604] @ChartId=2100113945, @PqrsNum='THEPQR1';
*/



-- End of 14) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL
GO

-- Start of 15) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL

------------------------------------------------------------------------------------
-- 15) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1,2,3,6,7,8,9,11','02,21,22,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (1,2,3,6,7,8,9,11) OR [LOCATION_OF_SERVICE] IN (02,21,22,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have any Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have any Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51] @ChartId=2100113941, @PqrsNum='ECPR51';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51_DACS-3604] @ChartId=2100113941, @PqrsNum='ECPR51';
*/


-- End of 15) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL
GO

-- Start of 16) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL

------------------------------------------------------------------------------------
-- 16) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9,12,13','21,31,32') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (7,8,9,12,13) OR [LOCATION_OF_SERVICE] IN (21,31,32) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Denominator Exclusion Diagnosis List?
	IF EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Denominator Exclusion Diagnosis List item found)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2] @ChartId=2100113946, @PqrsNum='THEPQR2';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2_DACS-3604] @ChartId=2100113946, @PqrsNum='THEPQR2';
*/



-- End of 16) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL
GO

-- Start of 17) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL

------------------------------------------------------------------------------------
-- 17) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for heart failure (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for heart failure (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Outpatient Encounters during performance period (CPT) and Inpatient Discharges during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have any diagnosis exclusions?
	IF EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Excluded code found (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3] @ChartId=2100114076, @PqrsNum='THEPQR3';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3_DACS-3604] @ChartId=2100114076, @PqrsNum='THEPQR3';
*/

-- End of 17) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL
GO

-- Start of 18) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL

------------------------------------------------------------------------------------
-- 18) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001] @ChartId=2100114076, @PqrsNum='001';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001_DACS-3604] @ChartId=2100114076, @PqrsNum='001';
*/
-- End of 18) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL
GO

-- Start of 19) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL

------------------------------------------------------------------------------------
-- 19) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick1MatchCountB <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] @ChartId=2100113748, @PqrsNum='007-A';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A_DACS-3604] @ChartId=2100113748, @PqrsNum='007-A';
*/


-- End of 19) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
GO

-- Start of 20) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL

------------------------------------------------------------------------------------
-- 20) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick1MatchCountB <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] @ChartId=2100113748, @PqrsNum='007-B';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B_DACS-3604] @ChartId=2100113748, @PqrsNum='007-B';
*/
-- End of 20) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
GO

-- Start of 21) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL

------------------------------------------------------------------------------------
-- 21) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1','23') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId CANNOT have a valid patient class type of (1) OR Location of Service of (23).', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047] @ChartId=2100113727, @PqrsNum='047';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047_DACS-3604] @ChartId=2100113727, @PqrsNum='047';
*/
-- End of 21) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL
GO

-- Start of 22) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL

------------------------------------------------------------------------------------
-- 22) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 3 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9','21') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an EXCLUDED Physician service class of (7, 8 or 9) Location of Service value of (21)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for pharyngitis or tonsillitis (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066] @ChartId=2100113927, @PqrsNum='066';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066_DACS-3604] @ChartId=2100113927, @PqrsNum='066';
*/


-- End of 22) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL
GO

-- Start of 23) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL

------------------------------------------------------------------------------------
-- 23) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 3months on date of encounter
	----------------
	DECLARE @ageFrom DECIMAL(5, 2) = 0.25;
	DECLARE @ageTo INT = 999;
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge DECIMAL(5, 2) = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
			RETURN;
		END;
		
		DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PatientDob] from @tempChartInfo);
		
		IF @patienDOB IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			RETURN;
		END;
		
		SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			RETURN;
		END;

		-- check the age constraints
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9','21') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an EXCLUDED Physician service class of (7, 8 or 9) Location of Service value of (21)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116] @ChartId=2100113593, @PqrsNum='116';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116_DACS-3604] @ChartId=2100113593, @PqrsNum='116';
*/
-- End of 23) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL
GO

-- Start of 24) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A].SQL

------------------------------------------------------------------------------------
-- 24) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD‐10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] @ChartId=2100113726, @PqrsNum='118-A';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A_DACS-3604] @ChartId=2100113726, @PqrsNum='118-A';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] @ChartId=2100116965, @PqrsNum='118-A';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A_DACS-3604] @ChartId=2100116965, @PqrsNum='118-A';
*/
-- End of 24) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A].SQL
GO

-- Start of 25) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL

------------------------------------------------------------------------------------
-- 25) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for diabetes (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;
	
	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] @ChartId=2100113726, @PqrsNum='118-B';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B_DACS-3604] @ChartId=2100113726, @PqrsNum='118-B';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] @ChartId=2100116965, @PqrsNum='118-B';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B_DACS-3604] @ChartId=2100116965, @PqrsNum='118-B';
*/

-- End of 25) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
GO

-- Start of 26) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL

------------------------------------------------------------------------------------
-- 26) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) -- OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList) -- ignore this for now since this is a "does NOT have" type of MIPS test
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Not Eligible for Depression Screening or Follow-Up Plan (Denominator Exclusions) – Patients who have been diagnosed with bipolar disorder?  if we do, reject this MIPS.
	IF EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have Depression Screening or Follow-Up Plan (Denominator Exclusions) – Patients who have been diagnosed with bipolar disorder)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT or HCPCS)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134] @ChartId=2100113931, @PqrsNum='134';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134_DACS-3604] @ChartId=2100113931, @PqrsNum='134';
*/

-- End of 26) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL
GO

-- Start of 27) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL

------------------------------------------------------------------------------------
-- 27) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of 187, there are 1 valid decision paths.  the data is stored by PQRS# '187' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId, null, '02,10') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	IF EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value2] IN (SELECT [Modifier] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187] @ChartId=2100113592, @PqrsNum='187';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187_DACS-3604] @ChartId=2100113592, @PqrsNum='187';
*/

-- End of 27) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL
GO

-- Start of 28) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL

------------------------------------------------------------------------------------
-- 28) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for atrial fibrillation or atrial flutter (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for atrial fibrillation or atrial flutter (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326] @ChartId=2100113591, @PqrsNum='326';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326_DACS-3604] @ChartId=2100113591, @PqrsNum='326';
*/


-- End of 28) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL
GO

-- Start of 29) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL

------------------------------------------------------------------------------------
-- 29) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for acute sinusitis (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for acute sinusitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for bacterial and infectious agents (ICD-10-CM)?
	DECLARE @AskQuestionG9364 VARCHAR(5) = 'G9364';
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SET @AskQuestionG9364 = 'GGGGG';
		PRINT('ask all questions since criteria Diagnosis for bacterial and infectious agents (ICD-10-CM) NOT found');
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[Code] AS 'CODE'
	FROM 
		@tempDenominatorList tdl
	WHERE 
		tdl.[CodingSystem] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
		AND tdl.[Code] <> @AskQuestionG9364
	ORDER BY
		tdl.[Code];

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114172, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114172, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100113594, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100113594, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114070, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114070, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114071, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114071, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114068, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114068, @PqrsNum='332';
--
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=2100114069, @PqrsNum='332';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332_DACS-3604] @ChartId=2100114069, @PqrsNum='332';
*/


-- End of 29) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL
GO

-- Start of 30) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL

------------------------------------------------------------------------------------
-- 30) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId, null, '02,10') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	IF EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value2] IN (SELECT [Modifier] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415] @ChartId=2100113933, @PqrsNum='415';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415_DACS-3604] @ChartId=2100113933, @PqrsNum='415';
*/
-- End of 30) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL
GO

-- Start of 31) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL

------------------------------------------------------------------------------------
-- 31) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- backup stored procedure
	----------------
EXEC [dbo].[Maintenance_BackupProcedure] 
	 @SrcProc  = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416'
	,@DestProc = 'PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416_DACS-3604';
GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId, null,'02,10') > 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	IF EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value2] IN (SELECT [Modifier] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416] @ChartId=2100113934, @PqrsNum='416';
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416_DACS-3604] @ChartId=2100113934, @PqrsNum='416';
*/


-- End of 31) DACS-3604 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL
GO

-- Start of 1) DACS-3399 - Create Proc spSelectIsChartPqrs.sql

GO

GO

GO

CREATE OR ALTER  PROCEDURE [dbo].[spSelectIsChartPqrs]   
 @ChartId INT,  
 @IsChartPqrs BIT OUTPUT
AS
BEGIN  

DECLARE @chart_id INT = @ChartId;  
DECLARE @Now DATETIME = GETDATE();  
DECLARE @flag VARCHAR(10) = '';  
DECLARE @HasDXCode INT;  
DECLARE @HasCPTCode INT;  
DECLARE @CPT_CODE AS VARCHAR(MAX)
DECLARE @PSP_CPT varchar(50)
  
-- Drop statements for new temp tables added 2/21/2023 (dsexton)  
if object_id('TempDB..#MeasureList', 'U') is not null DROP TABLE #MeasureList;  
if object_id('TempDB..#RequireCptMeasures', 'U') is not null DROP TABLE #RequireCptMeasures;  
if object_id('TempDB..#RequiredDiagnosisMeasures', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures;  
if object_id('TempDB..#RequiredDiagnosisMeasures2', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures2;  
if object_id('TempDB..#Chart', 'U') is not null DROP TABLE #Chart;  
if object_id('TempDB..#ChartDiagCodeICD10', 'U') is not null DROP TABLE #ChartDiagCodeICD10;  
if object_id('TempDB..#PPE_CPT', 'U') is not null DROP TABLE #PPE_CPT;  
  
SELECT
	chart_ID, service_agreement_ID, primary_complaint, chief_complaint, PHYSICIAN_SERVICE_PROC_ID, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID  
	,Time_of_Service, gender, patient_DOB, patient_age  
INTO #Chart   
FROM CHART  
WHERE
	chart_ID = @chart_id  
  
 SELECT cpm.CMS_PQRI_MEASURE_ID,  
  cpm.MEASURE_TITLE,  
  cpm.REQUIRES_BOTH_CPT_AND_DX,  
  cpmc.CMS_PQRI_MEASURE_CODE_ID,  
  cpmc.CODING_SYSTEM,  
  cpmc.OPTION_GROUP,  
  cpmc.CODE,  
  cpmc.MODIFIER,  
  cpmc.[DESCRIPTION],  
  CASE   
   WHEN cpmc.END_DATE IS NULL  
    THEN '12/31/9999 00:00:00'  
   ELSE cpmc.END_DATE   
   END END_DATE,  
  cpmc.CODE_2,  
  cpmc.MODIFIER_2,  
  cpm.REQUIRES_MULTIPLE_CPTS,  
  cpm.MULTIPLE_CPT_COUNT,  
  cpm.REQUIRES_MULTIPLE_DX,  
  cpm.REQUIRES_CPT_CODE,  
  cpm.REQUIRED_CPT_CODE,  
  CASE   
   WHEN COALESCE(cpm.REQUIRES_EM_ONLY, 0) = 1  
    AND (c.PHYSICIAN_SERVICE_PROC_ID > 0 OR c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0)  
    THEN 1  
   ELSE 0  
   END REQUIRES_EM_ONLY,  
  CASE   
   WHEN COALESCE(cpm.MATCH_EM_LEVEL, 0) = 1  
    THEN 1  
   ELSE 0  
   END MATCH_EM_LEVEL,  
  CASE   
   WHEN cpmc.START_DATE IS NULL  
    THEN '1/1/1900 00:00:00'  
   ELSE cpmc.START_DATE  
   END START_DATE,  
  CASE   
   WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE IS NULL  
    THEN '02/20/2020 00:00:00'  
   ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE  
   END REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,  
  CASE   
   WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE IS NULL  
    THEN '12/31/9999 00:00:00'  
   ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE  
   END REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,  
     CONVERT(Date, c.TIME_OF_SERVICE) as DATE_OF_SERVICE  
into #MeasureList 
 FROM CMS_PQRI_MEASURE cpm WITH (NOLOCK)  
 LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc WITH (NOLOCK) ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID  
 cross join #Chart c
 WHERE DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, c.TIME_OF_SERVICE)  
  AND (  
   ISNULL(cpm.GENDER, 'B') = 'B'  
   OR cpm.GENDER = c.GENDER  
   )  
  AND (  
   (  
    (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) = 0  
    AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0)) = 999  
    )  
   OR (  
    (c.PATIENT_AGE IS NOT NULL AND c.PATIENT_DOB IS NULL  
    AND c.PATIENT_AGE BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))  
    ))  
     
   OR (  
    (c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NOT NULL OR cpm.TO_AGE_FRACTIONAL IS NOT NULL)  
    AND ((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))  
    )  
     
   OR (  
   (c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NULL AND cpm.TO_AGE_FRACTIONAL IS NULL)  
    AND CAST(((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) AS INT) BETWEEN COALESCE(cpm.FROM_AGE, 0)  AND COALESCE(cpm.TO_AGE, 999)  
    )  
   )  
  
  AND cpm.CMS_PQRI_MEASURE_ID IN (  
   SELECT sapqrs.CMS_PQRI_MEASURE_ID  
   FROM SERVICE_AGREEMENT_PQRS sapqrs WITH (NOLOCK)  
   WHERE sapqrs.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
    AND CONVERT(Date, c.TIME_OF_SERVICE) BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, @Now)  
   )  
 
 
SELECT cdc.ICD10_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, cdc.DIAGNOSIS_TYPE_ID, cdc.IS_PRIMARY, c.Time_of_Service  
  into #ChartDiagCodeICD10  
FROM CHART_DIAGNOSIS_CODE_ICD10 cdc WITH (NOLOCK)  
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID  
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
  
SELECT cm.CPT_Code  
  into #PPE_CPT  
FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)  
INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID  
 and ppe.CHART_ID = @chart_id   

SELECT TOP 1 @PSP_CPT = CPT_CODE  
FROM 
	PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)  INNER JOIN #Chart c   
		ON PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
WHERE 
	PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE   
        WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0  
            THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID  
        ELSE c.PHYSICIAN_SERVICE_PROC_ID  
        END  
     
SELECT
	@CPT_CODE = CPT_CODE  
FROM 
	PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK) INNER JOIN CHART c WITH (NOLOCK) 
		ON psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
		AND c.CHART_ID = @chart_id  
WHERE 	
	psp.PHYSICIAN_SERVICE_PROC_ID = CASE   
										WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0  
										THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID  
									ELSE c.PHYSICIAN_SERVICE_PROC_ID  
									END  

SELECT 
	ml.CMS_PQRI_MEASURE_ID,
	ml.CODE,
	ml.MULTIPLE_CPT_COUNT
INTO #RequireCptMeasures  
FROM
	#MeasureList ml
WHERE
	ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE  
    AND 
	(
	EXISTS 
		(  
		 SELECT *  
		 FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)  
		 INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID  
		 WHERE ppe.CHART_ID = @chart_id  
		  AND cm.CPT_CODE = ml.CODE  
		  AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE  
		)
	OR 
	ml.Code = @CPT_CODE
	)

SELECT ml.CMS_PQRI_MEASURE_ID,  
  ml.MEASURE_TITLE,  
  ml.REQUIRES_BOTH_CPT_AND_DX,  
  ml.CMS_PQRI_MEASURE_CODE_ID,  
  ml.CODING_SYSTEM,  
  ml.OPTION_GROUP,  
  ml.CODE,  
  ml.MODIFIER,  
  ml.[DESCRIPTION],  
  ml.END_DATE,  
  ml.CODE_2,  
  ml.MODIFIER_2,  
  --ROW_NUMBER() OVER (  
   --PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC  
   --) [ROW_NUMBER],  
  REQUIRES_EM_ONLY,  
  ml.DATE_OF_SERVICE,  
  ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,  
  ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,  
  ml.REQUIRES_MULTIPLE_CPTS,  
  ml.MULTIPLE_CPT_COUNT,  
  ml.REQUIRES_MULTIPLE_DX,  
  ml.REQUIRES_CPT_CODE,  
  ml.REQUIRED_CPT_CODE  
into #RequiredDiagnosisMeasures  
FROM
	#MeasureList ml
 WHERE
    ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
    AND EXISTS (  
     select * from #ChartDiagCodeICD10 as cdc  -- tuning with temp table in the subquery, 2/21/2023 (dsexton)  
     where  
      cdc.ICD10_CODE = ml.CODE  
         AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE  
      AND (  
       ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1  
       OR (  
        (cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)  
        OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 1)  
        )  
       )  
      AND (  
       NOT EXISTS (  
        SELECT *  
        FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)  
        WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
        )  
       OR EXISTS (  
        SELECT *  
        FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)  
        WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
         AND CODE_1 = cdc.ICD10_CODE  
         AND CODE_2 IN (  
          SELECT ICD10_CODE  
          from #ChartDiagCodeICD10
          WHERE   
           (  
                        ICD10_CODE <> cdc.ICD10_CODE  
                        OR CODE_1 = CODE_2  
           )  
          )  
        )  
       )  
     )  

SELECT 
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM
	#RequiredDiagnosisMeasures rdm JOIN #RequireCptMeasures rcm 
		ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID    
WHERE 
	rdm.REQUIRES_BOTH_CPT_AND_DX = 1  
	AND rdm.REQUIRES_MULTIPLE_CPTS = 1  
	AND rdm.REQUIRES_MULTIPLE_DX IS NULL  
	AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE   
	AND rdm.CODE IS NOT NULL  
	AND rcm.CODE IS NOT NULL  
GROUP BY 
	rdm.CMS_PQRI_MEASURE_ID, rdm.MEASURE_TITLE, rdm.REQUIRES_BOTH_CPT_AND_DX, rdm.CMS_PQRI_MEASURE_CODE_ID, rdm.CODING_SYSTEM, rdm.OPTION_GROUP, rdm.CODE, rdm.MODIFIER, rdm.[DESCRIPTION], rdm.END_DATE, rdm.CODE_2, rdm.MODIFIER_2, rdm.REQUIRES_EM_ONLY, rcm.MULTIPLE_CPT_COUNT  
HAVING COUNT(rcm.CODE) = rcm.MULTIPLE_CPT_COUNT  

IF @IsChartPqrs = 1 RETURN;      

 SELECT ml.CMS_PQRI_MEASURE_ID,  
  ml.MEASURE_TITLE,  
  ml.REQUIRES_BOTH_CPT_AND_DX,  
  ml.CMS_PQRI_MEASURE_CODE_ID,  
  ml.CODING_SYSTEM,  
  ml.OPTION_GROUP,  
  ml.CODE,  
  ml.MODIFIER,  
  ml.[DESCRIPTION],  
  ml.END_DATE,  
  ml.CODE_2,  
  ml.MODIFIER_2,  
  REQUIRES_EM_ONLY,  
  ml.DATE_OF_SERVICE,  
  ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,  
  ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,  
  ml.REQUIRES_MULTIPLE_CPTS,  
  ml.MULTIPLE_CPT_COUNT,  
  ml.REQUIRES_MULTIPLE_DX,  
  ml.REQUIRES_CPT_CODE,  
  ml.REQUIRED_CPT_CODE  
INTO #RequiredDiagnosisMeasures2  
FROM
	#MeasureList ml JOIN #ChartDiagCodeICD10 cdc
	ON cdc.ICD10_CODE = ml.CODE  
WHERE   
	ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
	AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE  
	AND 
	(  
		ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1  
		OR 
		(  
		(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 0)  
		OR 
		NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 0)  
		)  
	)  	
   
SELECT 
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM
	#RequiredDiagnosisMeasures2 rdm2 JOIN #RequireCptMeasures rcm 
		ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
	JOIN #RequiredDiagnosisMeasures rdm 
		ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID    
WHERE 
	rdm.REQUIRES_BOTH_CPT_AND_DX = 1  
	AND rdm.REQUIRES_MULTIPLE_DX = 1  
	AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL  
	AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE   
	AND rdm.CODE IS NOT NULL  
	AND rcm.CODE IS NOT NULL  
	AND rdm2.CODE IS NOT NULL  

IF @IsChartPqrs = 1 RETURN;    

SELECT 
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM
	#MeasureList ml
WHERE 
	ml.REQUIRES_BOTH_CPT_AND_DX = 1  
	AND CONVERT(Date, ml.DATE_OF_SERVICE) < ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE  
	AND ml.CODE IS NOT NULL  
   AND (  
    ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
    AND EXISTS (  
     select * from #ChartDiagCodeICD10 as cdc
     where  
      cdc.ICD10_CODE = ml.CODE  
      AND (  
       ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1  
       OR (  
        (cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)  
        OR (cdc.DIAGNOSIS_TYPE_ID IN (1,3,5) AND cdc.IS_PRIMARY = 0)  
        )  
       )  
      AND (  
       NOT EXISTS (  
        SELECT *  
        FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)  
        WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
        )  
       OR EXISTS (  
        SELECT *  
        FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)  
        WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
         AND CODE_1 = cdc.ICD10_CODE  
         AND CODE_2 IN (SELECT ICD10_CODE FROM #ChartDiagCodeICD10 WHERE ICD10_CODE <> cdc.ICD10_CODE  OR CODE_1 = CODE_2)  
        )  
       )  
     )  
  )  
  OR 
  (  
    ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
    AND EXISTS (SELECT 1 FROM #PPE_CPT as t where t.CPT_Code = ml.Code)  
  )     
  OR 
  (  
	ml.REQUIRES_EM_ONLY = 1 AND @PSP_CPT IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395')  
  )      

IF @IsChartPqrs = 1 RETURN;    

IF((SELECT COUNT(*) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID IN (184, 185, 189)) > 1)
BEGIN
SELECT 
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM 
	#RequireCptMeasures rcm1 JOIN #RequireCptMeasures rcm2
	ON rcm1.CMS_PQRI_MEASURE_ID = rcm2.CMS_PQRI_MEASURE_ID
WHERE 
	(COALESCE(rcm1.REQUIRES_BOTH_CPT_AND_DX, 0) = 0  
	AND rcm1.REQUIRES_CPT_CODE = 1  
	AND rcm1.CODE IS NOT NULL) 
	OR
	(rcm2.CMS_PQRI_MEASURE_ID IN (184, 185, 189) AND rcm1.REQUIRED_CPT_CODE = rcm2.REQUIRED_CPT_CODE)
END

IF @IsChartPqrs = 1 RETURN;

SELECT
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM 
	#RequiredDiagnosisMeasures rdm JOIN #RequireCptMeasures rcm
		ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
	JOIN #MeasureList ml
		ON rdm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
WHERE 
	rdm.REQUIRES_BOTH_CPT_AND_DX = 1  
	AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL  
	AND rdm.REQUIRES_MULTIPLE_DX IS NULL  
	AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE   
	AND rdm.CODE IS NOT NULL  
	AND rcm.CODE IS NOT NULL  
	AND ml.CODING_SYSTEM IN ('CPT_II', 'HCPCS')  
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE 

RETURN;

END
GO

-- End of 1) DACS-3399 - Create Proc spSelectIsChartPqrs.sql
GO

-- Start of 01) DACS-3593 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3593 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL
------------------------------------------------------------------------------------
GO
-- begin tran; -- testing
	----------------
	/*
	reference document "MIPS 8.13.docx" within DACS-3361 Jira ticket for more details

	todo list: (* = handled in this Script)
	*005-A
	*005-B
	*007-A
	*007-B -- updated to show a question if cptcodes not found to satisfy miocarditus criteria (behaves as mipps 332 now)
	*332
	*ACEP60
	*ACEP61
	*ACEP64
	*ECPR39
	*ECPR51
	*HCPR27
	*PQRANES1
	*THEPQR1
	*THEPQR2
	*THEPQR4
	*HCPR24 - converting to single critera MIPS returning a question.
	*047 - updated to use the new fields that allow a definition to be placed below the MIPS.
	*134 - updated to replace question with denominator exclusion response entry
	*326 - converts questions to denominator exclusions
	415 - no changes made.  BUT, looks like it might need definitions added to follow the MIPS section
	*ECPR46 - updated to move the appendix image to bottom of MIPS
	*116 - changed questions to exclusions.  one exclusion has a lot of words (more than 500). uses an image that does not look quite right.  will have to wait for branch merge for image update.
	
	
	
	*/
	----------------
	
	--------------------------------------------
	-- Backup our data to be worked upon
	--------------------------------------------
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3593';
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3593';
	

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @measureId INT;
	DECLARE @measureName VARCHAR(32);
	
	DECLARE @foundRecordId INT;
	DECLARE @oldString VARCHAR(1000);
    DECLARE @newString VARCHAR(1000);

	----------------
	-- THEPQR1  : remove the "not"
	----------------
	SET @measureName = 'THEPQR1';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
		SET @oldString = 'Patient does <strong>NOT</strong> have any of';
		SET @newString = 'Patient does not have any of';

		SET @foundRecordId = (
			SELECT TOP 1
				[CMS_PQRI_MEASURE_CODE_ID] 
			FROM 
				[CMS_PQRI_MEASURE_CODE] 
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] LIKE (@oldString + '%')
			) ;

		SELECT '@foundRecordId =' = @foundRecordId;
		SELECT 'Old description =' = (SELECT [DESCRIPTION] FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_CODE_ID] = @foundrecordId) 

		IF @foundRecordId > 0
			UPDATE [CMS_PQRI_MEASURE_CODE]
				SET [DESCRIPTION] = REPLACE([DESCRIPTION], @oldString, @newString)
			WHERE
				[CMS_PQRI_MEASURE_CODE_ID] = @foundRecordId;
		ELSE
			SELECT 'Error: unable to find record to update for' + @measureName;
			
		SELECT 'New description =' = (SELECT [DESCRIPTION] FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_CODE_ID] = @foundrecordId) 

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';

	----------------
	-- THEPQR2  : reorder them
	----------------
	SET @measureName = 'THEPQR2';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
		DROP TABLE IF EXISTS #TempTHEPQR2Table;
		
		SELECT 
			*
		INTO 
			#TempTHEPQR2Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempTHEPQR2Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempTHEPQR2Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempTHEPQR2Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','QR201',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation indicating patient has an active diagnosis or a history of diagnosis that meets criteria for long-term utilization of Proton Pump Inhibitors. (PQR201) <p><img src="/WebPages/Images/MIPS/MIPS_THEPQR2_PQR201_DenominatorExclustionTable.png" alt="(PQR201) Exception table image"></p> ')
				,(@measureId,'HCPCS','DG002',NULL,'2024-01-01','Performance Met: (Inpatient): Proton Pump Inhibitors discontinued by discharge OR (PAC/SNF): Proton Pump Inhibitors discontinued. ')
				,(@measureId,'HCPCS','DG003',NULL,'2024-01-01','Performance Not Met: Proton Pump Inhibitors not discontinued; reason not given. ')
				,(@measureId,'HCPCS','DG004',NULL,'2024-01-01','Denominator Exception: <ul><li>Documented medical reason for exclusion</li><li>Patient refusal</li><li>Eloped or left AMA</li><li>Expired</li><li>Discharged to hospice</li></ul> ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG847',NULL,'2024-01-01','Was a Proton Pump Inhibitor (PPI) Medication DG847 used? <ul><li>Omeprazole (Prilosec, Prilosec OTC, Zegerid)</li><li>Lansoprazole (Prevacid)</li><li>Pantoprazole (Protonix)</li><li>Rebeprazole (Aciphex)</li><li>Esomeprazole (Nexium)</li><li>Dexlansoprazole (Dexilant, Kapidex)</li></ul> ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- PQRANES1  : reorder them
	----------------
	SET @measureName = 'PQRANES1';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempPQRANES1Table;
		
		SELECT 
			*
		INTO 
			#TempPQRANES1Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempPQRANES1Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempPQRANES1Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempPQRANES1Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','DG014',NULL,'2024-01-01','Performance Met: Patients for whom a peripheral nerve block is performed in the Emergency Department as evidenced by Presence of CPT Code, OR Documentation that peripheral nerve block was performed (CPT Codes: 64447, 64448, 64450) ')
				,(@measureId,'HCPCS','DG015',NULL,'2024-01-01','Performance Not Met: Peripheral nerve block not performed as evidenced by Absence of CPT Code in Numerator Met AND Absence of Documentation ')
				,(@measureId,'HCPCS','DG016',NULL,'2024-01-01','Denominator Exception: Documented medical reason for exclusion. Example of Medical Exclusions: open fracture, infection at the insertion site, or other medical reason, patient unable to consent. ')
				,(@measureId,'HCPCS','DG017',NULL,'2024-01-01','Denominator Exception: Documented patient refusal. Documentation Example: Patient refused block placement ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 332  : reorder them
	----------------
	SET @measureName = '332';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp332Table;
		
		SELECT 
			*
		INTO 
			#Temp332Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp332Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp332Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp332Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9315',NULL,'2024-01-01','Performance Met: Amoxicillin, with or without clavulanate, prescribed asa first line antibiotic at the time of diagnosis. ')
				,(@measureId,'HCPCS','G9314',NULL,'2024-01-01','Performance Not Met: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis, reason not given. ')
				,(@measureId,'HCPCS','G9313',NULL,'2024-01-01','Denominator Exception: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis for documented reason. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','G9364',NULL,'2024-01-01','Sinusitis caused by, or presumed to be caused by, bacterial infection: G9364? ')
				,(@measureId,'DQ411','G9498',NULL,'2024-01-01','Antibiotic regimen prescribed: G9498? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- HCPR27  : reorder them
	----------------
	SET @measureName = 'HCPR27';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempHCPR27Table;
		
		SELECT 
			*
		INTO 
			#TempHCPR27Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempHCPR27Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempHCPR27Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempHCPR27Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0704',NULL,'2024-01-01','Denominator EXCLUSION: Transferred, eloped, AMA, or expired patients are excluded. ')
				,(@measureId,'HCPCS','VH273',NULL,'2024-01-01','Performance Met:  Point-of-Care Ultrasound evaluation for Pneumothorax performed. ')
				,(@measureId,'HCPCS','VH275',NULL,'2024-01-01','Performance Not Met: Point-of-Care Ultrasound evaluation for pneumothorax not performed. ')
				,(@measureId,'HCPCS','VH274',NULL,'2024-01-01','Denominator Exception:  Documented medical reason for not performing Point-of-Care Ultrasound (e.g. no ultrasound machine available, patient refusal). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','00001',NULL,'2024-01-01','CVC Insertion was performed on internal jugular or subclavian veins (Pseudo Code): HCPR2701? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ECPR51  : reorder them
	----------------
	SET @measureName = 'ECPR51';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR51Table;
		
		SELECT 
			*
		INTO 
			#TempECPR51Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR51Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR51Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR51Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0700',NULL,'2024-01-01','Denominator EXCLUSION: Patient Transfered, elope or is an AMA patients? ')
				,(@measureId,'HCPCS','VE269',NULL,'2024-01-01','Performance Met: Naloxone was prescribed at discharge AND patient was educated about use. *NOTE: Distribution of Naloxone to patient at discharge is also acceptable in lieu of Naloxone prescription. ')
				,(@measureId,'HCPCS','VE271',NULL,'2024-01-01','Performance Not Met: Naloxone medication was not prescribed at discharge OR patient was not educated about use. ')
				,(@measureId,'HCPCS','VE270',NULL,'2024-01-01','Denominator Exception: Naloxone was not prescribed at discharge due to medical reasons such as allergy. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG519',NULL,'2024-01-01','Patient has Disposition of Discharged (Pseudo code - DG519)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP64  : reorder them
	----------------
	SET @measureName = 'ACEP64';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP64Table;
		
		SELECT 
			*
		INTO 
			#TempACEP64Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP64Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP64Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP64Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','P6401',NULL,'2024-01-01','Denominator EXCLUSIONS: <ul>  <li>Syncope</li>  <li>Pulmonary embolism</li>  <li>Proximal DVT</li>  <li>Already on anticoagulation at time of DVT diagnosis based on listed home medications</li></ul> ')
				,(@measureId,'HCPCS','P6402',NULL,'2024-01-01','Performance Met: Patient discharged from ED. ')
				,(@measureId,'HCPCS','P6403',NULL,'2024-01-01','Performance Not Met : Patient not discharged from ED. ')
				,(@measureId,'HCPCS','P6404',NULL,'2024-01-01','Denominator Exception: Death, LAMA, LWBS, LWT. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP60  : reorder them
	----------------
	SET @measureName = 'ACEP60';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP60Table;
		
		SELECT 
			*
		INTO 
			#TempACEP60Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP60Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP60Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP60Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','P6001',NULL,'2024-01-01','Denominator EXCLUSIONS: <ul><li>Heart Disease (coronary artery disease, Myocardial Infarction, CHF, cardiomyopathy, etc.)</li><li>Heart Rhythm Disorders (Arrhythmias, Sinus Node Dysfunction, Uncontrolled Atrial Fibrillation, etc.)</li><li>Aortic Dissection</li><li>Pulmonary Embolism</li><li>Subarachnoid Hemorrhage</li><li>Coagulation Disorder</li></ul> ')
				,(@measureId,'HCPCS','P6002',NULL,'2024-01-01','Performance Met: Patient discharged from ED. ')
				,(@measureId,'HCPCS','P6003',NULL,'2024-01-01','Performance Not Met: Patient not discharged from ED. ')
				,(@measureId,'HCPCS','P6004',NULL,'2024-01-01','Denominator Exception: Death, LAMA, LWBS, LWT. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP61  : reorder them
	----------------
	SET @measureName = 'ACEP61';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP61Table;
		
		SELECT 
			*
		INTO 
			#TempACEP61Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP61Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP61Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP61Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','DG063',NULL,'2024-01-01','Denominator EXCLUSIONS: History of Cystic Fibrosis, Airway Malformations, Immunodeficiency Syndromes, Pneumonia. ')
				,(@measureId,'HCPCS','DG062',NULL,'2024-01-01','Performance Met: A chest x-ray was ordered/performed for the patient. ')
				,(@measureId,'HCPCS','DG061',NULL,'2024-01-01','Performance Not Met: A chest x-ray was not ordered/performed for the patient. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';
 

	----------------
	-- ECPR39  : reorder them
	----------------
	SET @measureName = 'ECPR39';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR39Table;
		
		SELECT 
			*
		INTO 
			#TempECPR39Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR39Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR39Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR39Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0700',NULL,'2024-01-01','Denominator EXCLUSIONS: Transferred, eloped or AMA patients are excluded. ')
				,(@measureId,'HCPCS','VE250',NULL,'2024-01-01','Performance Met: Patients who did not have a head CT ordered. ')
				,(@measureId,'HCPCS','VE252',NULL,'2024-01-01','Performance Not Met: Patients who did have a Head CT ordered; reason not given. ')
				,(@measureId,'HCPCS','VE251',NULL,'2024-01-01','Denominator Exception:  Patients who did have a heat CT ordered for medical reason documented by the eligible professional <p>(i.e., <ul><li>Seizure;</li> <li>alcohol/drug intoxication;</li> <li>vomiting;</li> <li>altered mental status;</li> <li>abnormal neurologic exam;</li><li>concern for intracranial injury/hemorrhage, stroke, or mass lesion</li></ul>)</p> ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 005-A  : update title
	----------------
	SET @measureName = '005-A';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '005-A Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- should read:
		-- MIPS# 005-A : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF HF ASSESSED DURING AN OUTPATIENT ENCOUNTER): Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 005-A : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) <= 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period: (SUBMISSION CRITERIA 1: All patients with a diagnosis of HF assessed during an outpatient encounter). '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '005-A Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 005-B  : update title
	----------------
	SET @measureName = '005-B';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '005-B Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- should read:
		-- MIPS# 005-B : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF HF AND DISCHARGED FROM HOSPITAL DENOMINATOR) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 005-B : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) <= 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period: (SUBMISSION CRITERIA 2: All patients with a diagnosis of HF and discharged from hospital). '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '005-B Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- THEPQR4  : reorder and put the CPT to be written in a more visible place for the question.
	----------------
	SET @measureName = 'THEPQR4';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempTHEPQR4Table;
		
		SELECT 
			*
		INTO 
			#TempTHEPQR4Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempTHEPQR4Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempTHEPQR4Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempTHEPQR4Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','QR307',NULL,'2024-01-01','Denominator EXCLUSION: <ul><li>Patient on hospice, or discharged to hospice.</li><li>Eloped or left AMA.</li><li>Expired</li><li>Comfort measures documented (Documented code status of DNR-A)</li><li>Transferred to another hospital</li><li>Patient admission to psychiatric or behavioral care</li></ul> (PQR307) ')
				,(@measureId,'HCPCS','QR309',NULL,'2024-01-01','Performance Met:  Patient received order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service (PQR309) ')
				,(@measureId,'HCPCS','QR310',NULL,'2024-01-01','Performance Not Met:  Patient did not receive an order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service (PQR310) ')
				,(@measureId,'HCPCS','QR308',NULL,'2024-01-01','Denominator Exception: <ul><li>Patient or medical decision maker refusal.</li><li>Documented medical reason for exclusion (example: palliative care not appropriate).</li><li>Palliative care not available, or system issue preventing palliative care consult.</li></ul> (PQR308) ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG111',NULL,'2024-01-01','Patient has any of the following? (DG111) <ul><li>2+ same diag ED or hospitalizations in 12 months (PQR301)</li><li>Chronic oxygen, or Vent (PQR302)</li><li>Hospital Admit from LTC Fac (PQR303)</li><li>Stage 4/Metastatic cancer (PQR304)</li><li>Difficult to control phys symptoms (PQR305)</li><li>Complex care requirements (PQR306): <ul><li>Home infusion</li><li>Tube feeding</li><li>mechanical Vent</li><li>24hr Bedbound care</li></ul></li><li>(SDOH) (ICD10): Z55, Z56, Z59, Z60, Z64, Z65</li></ul>')
				;
		
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 007-A  : reorder them
	----------------
	SET @measureName = '007-A';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp007ATable;
		
		SELECT 
			*
		INTO 
			#Temp007ATable
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp007ATable;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp007ATable);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp007ATable);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9189',NULL,'2024-01-01','Performance Met: Beta-blocker therapy prescribed or currently being taken. ')
				,(@measureId,'HCPCS','G9188',NULL,'2024-01-01','Performance Not Met: Beta-blocker therapy not prescribed, reason not given. ')
				,(@measureId,'HCPCS','G9190',NULL,'2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons). ')
				,(@measureId,'HCPCS','G9191',NULL,'2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','G8694',NULL,'2024-01-01','Is Left ventricular ejection fraction (LVEF) less than <= 40% or documentation of moderate or severe LVSD: G8694? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 007-B  : reorder them
	----------------
	SET @measureName = '007-B';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp007BTable;
		
		SELECT 
			*
		INTO 
			#Temp007BTable
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp007BTable;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp007BTable);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp007BTable);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','4008F',NULL,'2024-01-01','Performance Met: Beta-blocker therapy prescribed or currently being taken. ')
				,(@measureId,'HCPCS','4008F','8P','2024-01-01','Performance Not Met: Beta-blocker therapy not prescribed, reason not otherwise specified. ')
				,(@measureId,'HCPCS','4008F','1P','2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons). ')
				,(@measureId,'HCPCS','4008F','2P','2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','00001',NULL,'2024-01-01','Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- HCPR24  : reorder them
	----------------
	SET @measureName = 'HCPR24';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempHCPR24Table;
		
		SELECT 
			*
		INTO 
			#TempHCPR24Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempHCPR24Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempHCPR24Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempHCPR24Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0704',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Transferred, eloped, AMA or expired patients are excluded. ')
				,(@measureId,'HCPCS','VH271',NULL,'2024-01-01','Performance Met: <ul><li>Vancomycin not ordered</li><li>OR Vancomycin discontinued at admission.</li><li>OR Vancomycin ordered AND MRSA infection identified or risk for MRSA infection documented <p>(i.e., <ul><li>nasal colonization,</li><li>prior MRSA infection,</li><li>recent hospitalization,</li><li>recent antibiotics,</li><li>penetrating injury,</li><li>IVDU,</li><li>purulent cellulitis,</li><li>SIRS criteria,</li><li>sepsis,</li><li>impaired host defense</li></ul>)</p></li></ul> ')
				,(@measureId,'HCPCS','VH272',NULL,'2024-01-01','Performance Not Met: : Vancomycin ordered AND no MRSA infection identified OR no risk for MRSA infection documented. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','V0717',NULL,'2024-01-01','Patient Admitted or placed in Observation Status (V0717)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			
		-- before changes
		SELECT 'HCPR24 Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: HCPR24 Appropriate Utilization of Vancomycin for Cellulitis: Percentage of patients with Cellulitis who did not receive Vancomycin unless MRSA Infection or risk for MRSA Infection was identified.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'HCPR24 : Appropriate Utilization of Vancomycin for Cellulitis: Percentage of patients with Cellulitis who did not receive Vancomycin unless MRSA Infection or risk for MRSA Infection was identified. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT 'HCPR24 Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 047  : update MEASURE_HOTSHEET_URI
	----------------
	SET @measureName = '047';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '047 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><strong>Definition:</strong></p><p><strong>Documentation that Patient did not Wish or was not able to Name a Surrogate Decision Maker or Provide an Advance Care Plan</strong> – May also include: <ul><li>That the patient’s cultural and/or spiritual beliefs preclude a discussion of advance care planning, and thus harmful to the physician-patient relationship.</li></ul></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '047 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

		-- remove the definition from the original not met response which was:
		-- Performance Not Met: Advance Care Planning not documented, reason not otherwise specified. <p><strong>Definition:</strong></p><p><strong>Documentation that Patient did not Wish or was not able to Name a Surrogate Decision Maker or Provide an Advance Care Plan</strong> – May also include: <ul><li>That the patient’s cultural and/or spiritual beliefs preclude a discussion of advance care planning, and thus harmful to the physician-patient relationship.</li></ul></p>

		SELECT '047 `Performance Not Met` description before update:' = (
			SELECT	
				[DESCRIPTION] 
			FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
				[CMS_PQRI_MEASURE_ID] = @measureId
				AND [CODING_SYSTEM] = 'HCPCS'
				AND [CODE] = '1123F'
				AND [MODIFIER] = '8P'
			);
		
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [DESCRIPTION] = 'Performance Not Met: Advance Care Planning not documented, reason not otherwise specified. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId
			AND [CODING_SYSTEM] = 'HCPCS'
			AND [CODE] = '1123F'
			AND [MODIFIER] = '8P';

		SELECT '047 `Performance Not Met` description after update:' = (
			SELECT	
				[DESCRIPTION] 
			FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
				[CMS_PQRI_MEASURE_ID] = @measureId
				AND [CODING_SYSTEM] = 'HCPCS'
				AND [CODE] = '1123F'
				AND [MODIFIER] = '8P'
			);
	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 134  : update title
	----------------
	SET @measureName = '134';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '134 Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: MIPS# 134 : Preventive Care and Screening: Screening for Depression and Follow-Up Plan : Percentage of patients aged 12 years and older screened for depression on the date of the encounter or up to 14 days prior to the date of the encounter using an age-appropriate standardized depression screening tool AND if positive, a follow-up plan is documented on the date of or up to two days after the date of the qualifying encounter. 

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 134 : Preventive Care and Screening: Screening for Depression and Follow-Up Plan : Percentage of patients aged 12 years and older screened for depression on the date of the encounter or up to 14 days prior to the date of the encounter using an age-appropriate standardized depression screening tool AND if positive, a follow-up plan is documented on the date of or up to two days after the date of the qualifying encounter. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '134 Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

		-- reorder the responses
		DROP TABLE IF EXISTS #Temp134Table;
		
		SELECT 
			*
		INTO 
			#Temp134Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp134Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp134Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp134Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9717',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation stating the patient has had a diagnosis of bipolar disorder. ')
				,(@measureId,'HCPCS','G8431',NULL,'2024-01-01','Performance Met: Screening for depression is documented as being positive AND a follow-up plan is documented. ')
				,(@measureId,'HCPCS','G8510',NULL,'2024-01-01','Performance Met: Screening for depression is documented as negative, a follow-up plan is not required. ')
				,(@measureId,'HCPCS','G8432',NULL,'2024-01-01','Performance Not Met: Depression screening not documented, reason not given. ')
				,(@measureId,'HCPCS','G8511',NULL,'2024-01-01','Performance Not Met: Screening for depression documented as positive, follow-up plan not documented, reason not given. ')
				,(@measureId,'HCPCS','G8433',NULL,'2024-01-01','Denominator Exception: Screening for depression not completed, documented patient or medical reason. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','G9717',NULL,'2024-01-01','Does NOT have Documentation stating the patient has had a diagnosis of bipolar disorder: (G9717)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;


	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 326  : reorder responses
	----------------
	SET @measureName = '326';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		DROP TABLE IF EXISTS #Temp326Table;
		
		SELECT 
			*
		INTO 
			#Temp326Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp326Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp326Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp326Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9929',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patient with transient or reversible cause of AF (e.g., pneumonia, hyperthyroidism, pregnancy, cardiac surgery). ')
				,(@measureId,'HCPCS','G9930',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients who are receiving comfort care only. ')
				,(@measureId,'HCPCS','G9931',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation of CHA2DS2-VASc risk score of 0 or 1 for men; or 0, 1, or 2 for women. ')
				,(@measureId,'HCPCS','G0044',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients with moderate or severe mitral stenosis. ')
				,(@measureId,'HCPCS','G0043',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients with mechanical prosthetic heart valve. ')
				,(@measureId,'HCPCS','G8967',NULL,'2024-01-01','Performance Met: FDA-approved oral anticoagulant is prescribed. ')
				,(@measureId,'HCPCS','G9928',NULL,'2024-01-01','Performance Not Met: FDA-approved anticoagulant not prescribed, reason not given. ')
				,(@measureId,'HCPCS','G8968',NULL,'2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing an FDA-approved anticoagulant (e.g., present or planned atrial appendage occlusion or ligation or patient being currently enrolled in a clinical trial related to AF/atrial flutter treatment). ')
				,(@measureId,'HCPCS','G8969',NULL,'2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing an oral anticoagulant that is FDA approved for the prevention of thromboembolism (e.g., patient preference for not receiving anticoagulation). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','00001',NULL,'2024-01-01','????: (00001)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;


	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ECPR46  : reorder codes
	----------------
	SET @measureName = 'ECPR46';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR46Table;
		
		SELECT 
			*
		INTO 
			#TempECPR46Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR46Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR46Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR46Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0709',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patient does NOT have active cancer, palliative care, or end-of-life care? ')
				,(@measureId,'HCPCS','VE263',NULL,'2024-01-01','Performance Met: Opiate not prescribed at discharge. ')
				,(@measureId,'HCPCS','VE265',NULL,'2024-01-01','Performance Not Met: Opiate prescribed, reason not specified. ')
				,(@measureId,'HCPCS','VE264',NULL,'2024-01-01','Denominator Exception: Opiate prescribed for medical reason documented by the Eligible Professional (i.e., suspected or diagnosed herniated disk, fracture, sciatica, radiculopathy). ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG469',NULL,'2024-01-01','Patient Disposition of Discharged – (Pseudo Code) (DG469)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

		-- before changes
		SELECT 'ECPR46 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><img src="/WebPages/Images/MIPS/Mips_ECPR46_AppendixAOpoidMedications.png" alt="(VE264) Appendix - Opoid Medications image"></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT 'ECPR46 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 116  : reorder codes
	----------------
	SET @measureName = '116';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp116Table;
		
		SELECT 
			*
		INTO 
			#Temp116Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp116Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp116Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp116Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G2176',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Outpatient, ED or Observation visits that result in an inpatient admission ')
				,(@measureId,'HCPCS','G2177',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Acute bronchitis/bronchiolitis episodes when the patient had a new or refill prescription of antibiotics (Table 1) in the 30 days prior to the episode date ')
				,(@measureId,'HCPCS','G9712',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation of medical reason(s) for prescribing or dispensing antibiotic. (G9712) <p><img src="/WebPages/Images/MIPS/MIPS_116_Definition1.png" alt="(G9712) Definition image"></p> ')
				,(@measureId,'HCPCS','G9713',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients who use hospice services any time during the measurement period ')
				,(@measureId,'HCPCS','4124F',NULL,'2024-01-01','Performance Met: Antibiotic neither prescribed nor dispensed. ')
				,(@measureId,'HCPCS','4120F',NULL,'2024-01-01','Performance Not Met: Antibiotic prescribed or dispensed. ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','ddd',NULL,'2024-01-01','Patient Disposition of Discharged – (Pseudo Code) (DG469)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

		-- before changes
		SELECT '116 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><img src="/WebPages/Images/MIPS/MIPS_116_Table1.png" alt="Table 1 image"></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '116 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


-- rollback tran; -- testing
-- commit tran; -- testing

GO

-- End of 01) DACS-3593 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL
GO

-- Start of 02) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));
	IF @ShowDebug <> 0 SELECT ' @foundDenominatorGroup1Pick1MatchCount =' =  @foundDenominatorGroup1Pick1MatchCount

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));
	IF @ShowDebug <> 0 SELECT ' @foundDenominatorGroup1Pick1MatchCountB =' =  @foundDenominatorGroup1Pick1MatchCountB

	IF @foundDenominatorGroup1Pick1MatchCount IS NULL AND @foundDenominatorGroup1Pick1MatchCountB IS NULL
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO


-- End of 02) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
GO

-- Start of 03) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

	----------------
	-- alter stored procedure
	----------------
CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount IS NULL AND @foundDenominatorGroup1Pick1MatchCountB IS NULL
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;
	
	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	-- satisfied enough to at least ask a question at this point.

	-- do we have a Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG2P1'))
		SELECT TOP 5
			'411' AS 'RESULT' 
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[Code] AS 'CODE'
		FROM 
			@tempDenominatorList tdl
		WHERE 
			tdl.[CodingSystem] = 'DQ411'
			AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
		ORDER BY
			tdl.[Code];
	ELSE
		SELECT 'RESULT'='411', 'QUESTION'=' ', 'CODE'='00001';


END -- end procedure

GO


-- End of 03) DACS-3593 - Create or Alter Stored procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
GO

-- Start of 04) DACS-3593 - Create  or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3593 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'AreAny2024MipsRuleSatisfiedByChart', @DestProc = 'AreAny2024MipsRuleSatisfiedByChart_DACS-3593';
GO

CREATE OR ALTER PROCEDURE [dbo].[AreAny2024MipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad ChartId ' = @ChartId;
		RETURN;
	END;
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @serviceAgreementId INT;
	DECLARE @dateOfService DATETIME;
	
	SELECT 
		 @serviceAgreementId = [SERVICE_AGREEMENT_ID]
		,@dateOfService = [TIME_OF_SERVICE]
	FROM 
		[dbo].[chart] 
	WHERE
		[CHART_ID] = @ChartId;

	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0 OR @dateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;

	PRINT('serviceAgreementId = ' + CAST(@serviceAgreementId AS VARCHAR(64)));
	PRINT('dateOfService = ' + CAST(@dateOfService AS VARCHAR(64)));

	
	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@serviceAgreementId, @Dos=@dateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @countSaMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- load our single criteria MIPS for testing
	-----------------------------------
	DECLARE @active2024MipsRules1CTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRules1CTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('HCPR24')							-- DACS-3593 - pippin - added
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
	;
	
	IF @TestAll <> 1 DELETE FROM @active2024MipsRules1CTable WHERE [NAME] NOT IN (SELECT [NAME] FROM @activeSAMipsRulesTable);

	DECLARE @count1CMips INT = (SELECT COUNT(*) FROM @active2024MipsRules1CTable);
	IF @count1CMips <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No 2024 1 criteria Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT '@count1CMips = ' = @count1CMips;
	IF @ShowDebug = 1 SELECT * FROM @active2024MipsRules1CTable;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = @count1CMips;

	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchResultsTable TABLE ( [RESULT] VARCHAR(32), [QUESTION] VARCHAR(1024), [CODE] VARCHAR(32));
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [NAME] FROM @active2024MipsRules1CTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NOT NULL 
		BEGIN
			DELETE FROM @FetchResultsTable;
			
			DECLARE @SQL NVARCHAR(512) = N'EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type' + REPLACE(@FetchMipsName,'-','') + '] @ChartId=@fCId,@PqrsNum=@fPqrs,@Dos=@fDos;';
			DECLARE @ParmDefinition NVARCHAR(512) = N'@fCId INT, @fPqrs VARCHAR(32), @fDos DATETIME';

			IF @ShowDebug = 1 PRINT('  --> @SQL = ' + @SQL);

			INSERT INTO 
				@FetchResultsTable
			EXEC sp_executesql @SQL, @ParmDefinition, @fCId=@ChartId, @fPqrs=@FetchMipsName, @fDos=@dateOfService;			

			IF @ShowDebug = 1 SELECT * FROM @FetchResultsTable;

			IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
			BEGIN
				IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @FetchMipsName;

				IF @TestAll <> 1 
				BEGIN 
				-- cleanup our cursor
					CLOSE cursorTempRows;  
					DEALLOCATE cursorTempRows; 
				END;

				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				IF @TestAll <> 1 RETURN;
			END;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	-----------------------------------
	-- load our dual criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '005') OR @TestAll = 1
	BEGIN
		PRINT('Processing: 005-A');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A @ChartId=@ChartId,@PqrsNum='005-A',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='005-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		PRINT('-------------------');		
		PRINT('Processing: 005-B');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B @ChartId=@ChartId,@PqrsNum='005-B',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '005-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '008') OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: 008-A');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A @ChartId=@ChartId,@PqrsNum='008-A',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='008-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
		
		PRINT('-------------------');		
		PRINT('Processing: 008-B');
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B @ChartId=@ChartId,@PqrsNum='008-B',@Dos=@dateOfService;
		
		IF EXISTS(SELECT * FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '008-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;
	
	-----------------------------------
	-- load our PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	DECLARE @MipsNameToTest VARCHAR(32) = 'PQRANES1';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP60';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP61';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	SET @MipsNameToTest = 'ACEP64';
	IF EXISTS (SELECT 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
	BEGIN
		PRINT('-------------------');		
		PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		INSERT INTO 
				@FetchResultsTable
		EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;

		IF EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN;
		END;
	END;

	-----------------------------------
	-- all done
	-----------------------------------
	PRINT('-------------------');		
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;
END; -- end of SPROC

GO

/*
EXEC [dbo].AreAny2024MipsRuleSatisfiedByChart @ChartId=2100113944,@ShowDebug=1,@TestAll=1; -- tests PQRANES1

*/
-- End of 04) DACS-3593 - Create  or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
GO

-- Start of 05) DACS-3593 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3593 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	


	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid time of service to test';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient Age to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId, null, '02,19,21,22,23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [LOCATION_OF_SERVICE] IN (02,19,21,22,23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	

	----------------
	-- Present Procedure List 
	----------------
	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis of Cellulitis (ICD10 Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of Cellulitis (ICD10 Codes))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO

/*
EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24] @ChartId=2100113942,@PqrsNum='HCPR24',@Dos='8/9/2024';
*/
-- End of 05) DACS-3593 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24].SQL
GO

-- Start of 06) DACS-3593 - Create or Alter stored procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3593 - Create or Alter stored procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
------------------------------------------------------------------------------------
GO

GO

GO


CREATE OR ALTER   PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListById] 
	 @MeasureId INT
	,@Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		--PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));	-- DACS-3417, 08/19/2024 (pippin)
	END;

	DECLARE @dateOfService DATE = CAST(@Dos AS DATE);			-- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 cpm.[CMS_PQRI_MEASURE_ID]
		,cpm.[MEASURE_TITLE]
		,cpmc.[CMS_PQRI_MEASURE_CODE_ID]
		,cpmc.[CODING_SYSTEM]
		,cpmc.[OPTION_GROUP]
		,cpmc.[CODE]
		,cpmc.[MODIFIER]
		,cpmc.[DESCRIPTION]
		,
		CASE 
			WHEN cpmc.[END_DATE] IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.[END_DATE] 
			END [END_DATE]
		,cpmc.[CODE_2]
		,cpmc.[MODIFIER_2]
		,cpm.[MEASURE_TOOLTIP]				-- DACS-3417, 08/19/2024 (pippin)
		,cpm.[MEASURE_HOTSHEET_URI]			-- DACS-3417, 08/19/2024 (pippin)
		,NULL [ROW_NUMBER]
	FROM 
		[CMS_PQRI_MEASURE] cpm
		LEFT JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID] = cpm.[CMS_PQRI_MEASURE_ID]
	WHERE 
		--DATEADD(DAY, DATEDIFF(DAY, 0, @dateOfService), 0) BETWEEN cpm.[EFFECTIVE_DATE] AND ISNULL(cpm.[EXPIRATION_DATE], @dateOfService) -- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types
		(cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] <= @dateOfService)
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @dateOfService) 
		AND cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[CODING_SYSTEM] IN ('CPT_II','HCPCS')
	ORDER BY 
		cpmc.[CODE], cpmc.[MODIFIER]
	;

END -- end procedure

GO


-- End of 06) DACS-3593 - Create or Alter stored procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
GO

-- Start of 07) DACS-3593 - create or alter stored procedure - [dbo].[spSelectChartPqrs].SQL

------------------------------------------------------------------------------------
-- 07) DACS-3593 - create or alter stored procedure - [dbo].[spSelectChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectChartPqrs', @DestProc = 'spSelectChartPqrs_DACS-3593';
GO

CREATE OR ALTER   PROCEDURE [dbo].[spSelectChartPqrs] 
	@ChartId INT,
	@MeasureId INT = NULL,
	@MeasureCodeId INT = NULL
	WITH
EXEC AS CALLER AS

------------------------------------------------------------------------------------
-- Adds additional CODING_SYSTEM strings used within the various temporary tables to allow for extended behavior supporting new MIPS decision logic - DACS-3164 - 20240422 - pippin
------------------------------------------------------------------------------------

-- testing
-- DECLARE @ChartId INT = 2100107114;
-- DECLARE @MeasureId INT = NULL;
-- DECLARE @MeasureCodeId INT = NULL;
-- body of original SPROC -- >

DECLARE @chart_id INT = @ChartId;
DECLARE @measure_id INT = @MeasureId;
DECLARE @measure_code_id INT = @MeasureCodeId;
DECLARE @Now DATETIME = GETDATE();
DECLARE @flag VARCHAR(10) = '';
DECLARE @HasDXCode INT;
DECLARE @HasCPTCode INT;

Declare @PSP_CPT varchar(50)	-- added 2/21/2023 (dsexton)

-- Drop statements for new temp tables added 2/21/2023 (dsexton)
if object_id('TempDB..#MeasureList', 'U') is not null DROP TABLE #MeasureList;
if object_id('TempDB..#RequireCptMeasures', 'U') is not null DROP TABLE #RequireCptMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures2', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures2;
if object_id('TempDB..#RequiredMeasures2', 'U') is not null DROP TABLE #RequiredMeasures2;
if object_id('TempDB..#RequiredMeasuresOldLogic', 'U') is not null DROP TABLE #RequiredMeasuresOldLogic;
if object_id('TempDB..#Chart', 'U') is not null DROP TABLE #Chart;
--if object_id('TempDB..#ChartDiagCode9', 'U') is not null DROP TABLE #ChartDiagCode9;	-- DACS-3417, 08/19/2024 (pippin)
if object_id('TempDB..#ChartDiagCodeICD10', 'U') is not null DROP TABLE #ChartDiagCodeICD10;
if object_id('TempDB..#PPE_CPT', 'U') is not null DROP TABLE #PPE_CPT;

-- new temp table for tuning, 2/21/2023 (dsexton)
select chart_ID, service_agreement_ID, primary_complaint, chief_complaint, PHYSICIAN_SERVICE_PROC_ID, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
	, Time_of_Service, gender, patient_DOB, patient_age
  into #Chart	
from CHART
where chart_ID = @chart_id

-- select * from #Chart -- testing

/*
This sproc executes very frequently at certain times of the day. For example, on 2/21/2023 it executed nearly 8K times between 4:30-7:30 AM. By 3 pm it executed only an additional 3,500 times.
It is called by sproc spSelectMissingChartPqrs which has executed 37K times over the past seven days. 
Avg LReads have been 150K which adds up to several billion reads each day. 

Modified all CLR queries to instead write to temp tables, 2/21/2023 (dsexton).  This reduced logical reads 95% (13K vs 240K) when testing with chart_ID 101104526.
	-- Duration was reduced 80% (31ms vs 184ms).
*/


--WITH MeasureList						-- replaced all CLR queries with temp tables, 2/21/2023 (dsexton)
--AS (
	SELECT cpm.CMS_PQRI_MEASURE_ID,
		cpm.MEASURE_TITLE,
		cpm.REQUIRES_BOTH_CPT_AND_DX,
		cpmc.CMS_PQRI_MEASURE_CODE_ID,
		cpmc.CODING_SYSTEM,
		cpmc.OPTION_GROUP,
		cpmc.CODE,
		cpmc.MODIFIER,
		cpmc.[DESCRIPTION],
		CASE 
			WHEN cpmc.END_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.END_DATE 
			END END_DATE,
		cpmc.CODE_2,
		cpmc.MODIFIER_2,
		cpm.REQUIRES_MULTIPLE_CPTS,
		cpm.MULTIPLE_CPT_COUNT,
		cpm.REQUIRES_MULTIPLE_DX,
		cpm.REQUIRES_CPT_CODE,
		cpm.REQUIRED_CPT_CODE,
		CASE 
			WHEN COALESCE(cpm.REQUIRES_EM_ONLY, 0) = 1
				AND (c.PHYSICIAN_SERVICE_PROC_ID > 0 OR c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0)
				THEN 1
			ELSE 0
			END REQUIRES_EM_ONLY,
		CASE 
			WHEN COALESCE(cpm.MATCH_EM_LEVEL, 0) = 1
				THEN 1
			ELSE 0
			END MATCH_EM_LEVEL,
		CASE 
			WHEN cpmc.START_DATE IS NULL
				THEN '1/1/1900 00:00:00'
			ELSE cpmc.START_DATE
			END START_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE IS NULL
				THEN '02/20/2020 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
	    CONVERT(Date, c.TIME_OF_SERVICE) as DATE_OF_SERVICE,
		cpm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		cpm.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #MeasureList							-- tuning, 2/21/2023 (dsexton)
	FROM CMS_PQRI_MEASURE cpm WITH (NOLOCK)
	LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc WITH (NOLOCK) ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID
	--INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
	cross join #Chart c		--ON c.CHART_ID = @chart_id
	WHERE DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, c.TIME_OF_SERVICE)
		AND (
			ISNULL(cpm.GENDER, 'B') = 'B'
			OR cpm.GENDER = c.GENDER
			)
		AND (
			(
				(COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) = 0
				AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0)) = 999
				)
			OR (
				(c.PATIENT_AGE IS NOT NULL AND c.PATIENT_DOB IS NULL
				AND c.PATIENT_AGE BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				))
			
			OR (
				(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NOT NULL OR cpm.TO_AGE_FRACTIONAL IS NOT NULL)
				AND ((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				)
			
			OR (
			(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NULL AND cpm.TO_AGE_FRACTIONAL IS NULL)
				AND CAST(((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) AS INT) BETWEEN COALESCE(cpm.FROM_AGE, 0)  AND COALESCE(cpm.TO_AGE, 999)
				)
			)

		AND cpm.CMS_PQRI_MEASURE_ID IN (
			SELECT sapqrs.CMS_PQRI_MEASURE_ID
			FROM SERVICE_AGREEMENT_PQRS sapqrs WITH (NOLOCK)
			WHERE sapqrs.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND CONVERT(Date, c.TIME_OF_SERVICE) BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, @Now)
			)
	--),

-- select '#MeasureList' = null
-- select * from #MeasureList where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #MeasureList 


-- New objects for tuning, 2/21/2023 (dsexton)  -------------------------------------------------------------------------------
/* -- DACS-3417, 08/19/2024 (pippin)
SELECT cdc.ICD9_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, c.CHIEF_COMPLAINT, c.PRIMARY_COMPLAINT, c.Time_of_Service
  into #ChartDiagCode9
FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
*/

SELECT cdc.ICD10_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, cdc.DIAGNOSIS_TYPE_ID, cdc.IS_PRIMARY, c.Time_of_Service
  into #ChartDiagCodeICD10
FROM CHART_DIAGNOSIS_CODE_ICD10 cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID

SELECT cm.CPT_Code
  into #PPE_CPT
FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
	and ppe.CHART_ID = @chart_id	

select TOP 1 @PSP_CPT = CPT_CODE
FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
INNER JOIN #Chart c 
on PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
WHERE PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
        WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
            THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
        ELSE c.PHYSICIAN_SERVICE_PROC_ID
        END
-------------------------------------------------------------------------------------------------------------------

--RequiredMeasuresOldLogic
--AS (
SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		ROW_NUMBER() OVER (
			PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredMeasuresOldLogic	-- tuning, 2/21/2023 (dsexton)
	--FROM MeasureList ml
	from #MeasureList ml		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE (
			/*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
				
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR (cdc.DIAGNOSIS_TYPE_ID IN (1,3,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			OR (
				ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select 1 from #PPE_CPT as t where t.CPT_Code = ml.Code		-- tuning to replace old subquery, 2/21/2023 (dsexton)
					)
				)
			)
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
      ml.REQUIRES_EM_ONLY = 1
      AND 
			@PSP_CPT	 -- tuning to replace subquery, 2/21/2023 (dsexton)
			  IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395')
    )
--	)
-- select '#RequiredMeasuresOldLogic' = null
-- select * from #RequiredMeasuresOldLogic where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequiredMeasuresOldLogic 
--,
--RequiredDiagnosisMeasures
--AS (

	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 		   
		  /*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 1)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			

--    )
	  
-- select '#RequiredDiagnosisMeasures' = null
-- select * from #RequiredDiagnosisMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequiredDiagnosisMeasures 
	
--	,
--	RequiredDiagnosisMeasures2
--AS (
	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures2
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 
		 /*  -- DACS-3417, 08/19/2024 (pippin)
		  ml.CODING_SYSTEM = 'I9'
			AND EXISTS (
			/-*	-- example of old subquery, 2/21/2023 (dsexton)
				SELECT *
				FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
				INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = cdc.CHART_ID
				INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				WHERE cdc.CHART_ID = @chart_id
			*-/
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 0)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						)
			
			)
 --   )
	  
-- select '#RequiredDiagnosisMeasures2' = null
-- select * from #RequiredDiagnosisMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequiredDiagnosisMeasures2 

--	,
--	RequireCptMeasures
--AS (
     SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequireCptMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					SELECT *
					FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
					INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
					WHERE ppe.CHART_ID = @chart_id
						AND cm.CPT_CODE = ml.CODE
						AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					)
				
			
			
			
			
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
		ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
      AND  (
              SELECT  CPT_CODE
              FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
              INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
              WHERE PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                  AND PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
                      WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
                          THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                      ELSE c.PHYSICIAN_SERVICE_PROC_ID
                      END 
              ) = ml.Code
			  AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
			  )
--),

-- select '#RequireCptMeasures' = null
-- select * from #RequireCptMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequireCptMeasures 

--	RequiredMeasures2
--AS (
   
    SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
		rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
into #RequiredMeasures2
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		
		UNION
		SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
        rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS = 1
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		GROUP BY rdm.CMS_PQRI_MEASURE_ID, rdm.MEASURE_TITLE, rdm.REQUIRES_BOTH_CPT_AND_DX, rdm.CMS_PQRI_MEASURE_CODE_ID, rdm.CODING_SYSTEM, rdm.OPTION_GROUP, rdm.CODE, rdm.MODIFIER, rdm.[DESCRIPTION], rdm.END_DATE, rdm.CODE_2, rdm.MODIFIER_2, rdm.REQUIRES_EM_ONLY, rdm.MEASURE_TOOLTIP, rdm.MEASURE_HOTSHEET_URI, rcm.MULTIPLE_CPT_COUNT
		HAVING COUNT(rcm.CODE) = rcm.MULTIPLE_CPT_COUNT

		UNION
		SELECT rdm2.CMS_PQRI_MEASURE_ID,
		rdm2.MEASURE_TITLE,
		rdm2.REQUIRES_BOTH_CPT_AND_DX,
		rdm2.CMS_PQRI_MEASURE_CODE_ID,
		rdm2.CODING_SYSTEM,
		rdm2.OPTION_GROUP,
		rdm2.CODE,
		rdm2.MODIFIER,
        rdm2.[DESCRIPTION],
		rdm2.END_DATE,
		rdm2.CODE_2,
		rdm2.MODIFIER_2,
		rdm2.REQUIRES_EM_ONLY,
		rdm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm2.CMS_PQRI_MEASURE_ID ORDER BY rdm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures2 rdm2
		from #RequiredDiagnosisMeasures2 rdm2															-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID				-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		AND rdm2.CODE IS NOT NULL
		UNION
		
		SELECT rmol.CMS_PQRI_MEASURE_ID,
		rmol.MEASURE_TITLE,
		rmol.REQUIRES_BOTH_CPT_AND_DX,
		rmol.CMS_PQRI_MEASURE_CODE_ID,
		rmol.CODING_SYSTEM,
		rmol.OPTION_GROUP,
		rmol.CODE,
		rmol.MODIFIER,
		rmol.[DESCRIPTION],
		rmol.END_DATE,
		rmol.CODE_2,
		rmol.MODIFIER_2,
		rmol.REQUIRES_EM_ONLY,
		rmol.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rmol.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rmol.CMS_PQRI_MEASURE_ID ORDER BY rmol.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredMeasuresOldLogic rmol
		from #RequiredMeasuresOldLogic rmol			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		WHERE rmol.REQUIRES_BOTH_CPT_AND_DX = 1
		AND CONVERT(Date, rmol.DATE_OF_SERVICE) < rmol.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
		AND rmol.CODE IS NOT NULL
		
		
		UNION
		 
		SELECT rcm.CMS_PQRI_MEASURE_ID,
		rcm.MEASURE_TITLE,
		rcm.REQUIRES_BOTH_CPT_AND_DX,
		rcm.CMS_PQRI_MEASURE_CODE_ID,
		rcm.CODING_SYSTEM,
		rcm.OPTION_GROUP,
		rcm.CODE,
		rcm.MODIFIER,
		rcm.[DESCRIPTION],
		rcm.END_DATE,
		rcm.CODE_2,
		rcm.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm.CMS_PQRI_MEASURE_ID ORDER BY rcm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm
		from #RequireCptMeasures rcm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND COALESCE(rcm.REQUIRES_CPT_CODE, 0) = 0
		AND rcm.CODE IS NOT NULL

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		 

		 UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--)

-- select '#RequiredMeasures2' = null
-- select * from #RequiredMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
-- select * from #RequiredMeasures2 

	
SELECT DISTINCT CMS_PQRI_MEASURE_ID,
	MEASURE_TITLE,
	CMS_PQRI_MEASURE_CODE_ID,
	CODING_SYSTEM,
	NULL OPTION_GROUP,
	CASE COALESCE(REQUIRES_EM_ONLY, 0)
		WHEN 1
			THEN 'E&M'
		ELSE CODE
		END CODE,
	NULL MODIFIER,
	NULL [DESCRIPTION],
	NULL END_DATE,
	NULL CODE_2,
	NULL MODIFIER_2,
	MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	CAST([ROW_NUMBER] AS BIGINT) [ROW_NUMBER]
--FROM RequiredMeasures2
from #RequiredMeasures2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
WHERE @measure_id IS NULL
	AND @measure_code_id IS NULL
	AND [ROW_NUMBER] = 1

UNION

SELECT ml.CMS_PQRI_MEASURE_ID,
	ml.MEASURE_TITLE,
	ml.CMS_PQRI_MEASURE_CODE_ID,
	ml.CODING_SYSTEM,
	ml.OPTION_GROUP,
	ml.CODE,
	ml.MODIFIER,
	ml.[DESCRIPTION],
	ml.END_DATE,
	ml.CODE_2,
	ml.MODIFIER_2,
	ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	ml.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	NULL [ROW_NUMBER]
--FROM MeasureList ml
from #MeasureList ml						-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--INNER JOIN RequiredMeasures2 rm ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
INNER JOIN #RequiredMeasures2 rm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
WHERE (
		ml.CMS_PQRI_MEASURE_ID = @measure_id
		OR ml.CMS_PQRI_MEASURE_CODE_ID = @measure_code_id
		)
	AND ml.CODING_SYSTEM IN (
		'CPT_II',
		'HCPCS'
		)
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
	
ORDER BY CMS_PQRI_MEASURE_ID ASC,
	MEASURE_TITLE DESC

GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'spSelectChartPqrs', N'PARAMETER',N'@MeasureCodeId'))
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
END
GO

/*
exec spSelectChartPqrs @ChartId=2100113940,@MeasureId=null,@MeasureCodeId=null
*/
-- End of 07) DACS-3593 - create or alter stored procedure - [dbo].[spSelectChartPqrs].SQL
GO

-- Start of 08) DACS-3593 - create or alter stored procedure - [dbo].[spSelectMissingChartPqrs].SQL

------------------------------------------------------------------------------------
-- 08) DACS-3593 - create or alter stored procedure - [dbo].[spSelectMissingChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectMissingChartPqrs', @DestProc = 'spSelectMissingChartPqrs_DACS-3593a';
GO

CREATE OR ALTER PROCEDURE [dbo].[spSelectMissingChartPqrs]
	@ChartId int
WITH EXEC AS CALLER
AS

SET NOCOUNT ON							-- DACS-3457 - 20240723 - pippin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @chart_id INT =@ChartId;
DECLARE @RequiredMeasures table
(
  CMS_PQRI_MEASURE_ID int,
  MEASURE_TITLE varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  CMS_PQRI_MEASURE_CODE_ID int,
  CODING_SYSTEM varchar(20),
  OPTION_GROUP numeric(18,0),
  CODE varchar(20),
  MODIFIER varchar(20),
  [DESCRIPTION] varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  END_DATE date,
  CODE_2 varchar(6),
  MODIFIER_2 varchar(20),
  MEASURE_TOOLTIP varchar(4000), 		-- DACS-3417 - 20240830 - pippin - added field
  MEASURE_HOTSHEET_URI varchar(1000), 	-- DACS-3417 - 20240830 - pippin - added field
  [ROW_NUMBER] bigint
)

INSERT INTO @RequiredMeasures(
	 CMS_PQRI_MEASURE_ID
	,MEASURE_TITLE
	,CMS_PQRI_MEASURE_CODE_ID
	,CODING_SYSTEM
	,OPTION_GROUP
	,CODE
	,MODIFIER
	,[DESCRIPTION]
	,END_DATE
	,CODE_2
	,MODIFIER_2
	,MEASURE_TOOLTIP
	,MEASURE_HOTSHEET_URI
	,[ROW_NUMBER]
)
  EXEC [spSelectChartPqrs] @ChartId=@chart_id

SELECT *
FROM @RequiredMeasures rm
WHERE (SELECT COUNT(*)
       FROM PHYSICIAN_PROCEDURE_EVALUATION ppe
         JOIN CHARGE_MASTER cm on cm.CHARGE_MASTER_ID=ppe.PHYSICIAN_PROCEDURE_ID
         JOIN CMS_PQRI_MEASURE_CODE cpmc on cpmc.CMS_PQRI_MEASURE_ID=rm.CMS_PQRI_MEASURE_ID
       WHERE CHART_ID=@chart_id
         AND cm.CHARGE_MASTER_USAGE_CODE=9
         AND cpmc.CODING_SYSTEM in ('CPT_II', 'HCPCS', 'OTHER')			-- DACS-3593 - 20240903 - pippin - added 'OTHER' to "in" list
         AND cm.CPT_CODE=cpmc.CODE
         AND ppe.MODIFIERS=isnull(cpmc.MODIFIER, ''))=0
GO


-- End of 08) DACS-3593 - create or alter stored procedure - [dbo].[spSelectMissingChartPqrs].SQL
GO

-- Start of 09) DACS-3593 - create or alter stored procedure - [dbo].[spRemoveInapplicablePqrs].SQL

------------------------------------------------------------------------------------
-- 09) DACS-3593 - create or alter stored procedure - [dbo].[spRemoveInapplicablePqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spRemoveInapplicablePqrs', @DestProc = 'spRemoveInapplicablePqrs_DACS-3593a';
GO


CREATE OR ALTER PROCEDURE [dbo].[spRemoveInapplicablePqrs]
	@ChartId INT
WITH EXEC AS CALLER
AS
BEGIN
	DECLARE @chart_id INT=@ChartId;

	DECLARE @RequiredMeasures TABLE
	(
	   [CMS_PQRI_MEASURE_ID] INT
	  ,[MEASURE_TITLE] VARCHAR(2000)		-- DACS-3591, pippin -- increased column width to 2000 (original = 500)
	  ,[CMS_PQRI_MEASURE_CODE_ID] INT
	  ,[CODING_SYSTEM] VARCHAR(20)
	  ,[OPTION_GROUP] NUMERIC(18,0)
	  ,[CODE] VARCHAR(20)
	  ,[MODIFIER] VARCHAR(20)
	  ,[DESCRIPTION] VARCHAR(500)
	  ,[END_DATE] DATE
	  ,[CODE_2] VARCHAR(6)
	  ,[MODIFIER_2] VARCHAR(20)
	  ,[MEASURE_TOOLTIP] VARCHAR(4000)		-- added DACS-3593, 09/03/2024 (pippin)
	  ,[MEASURE_HOTSHEET_URI] VARCHAR(1000)	-- added DACS-3417, 08/19/2024 (pippin)
	  ,[ROW_NUMBER] BIGINT
	)
	------------------------------------------------------------------------------------
	-- DACS-3591, pippin -- formatting adjusted for improved readibility
	------------------------------------------------------------------------------------

	-- Populate the table variable with values returned from spSelectChartPQRS
	INSERT INTO @RequiredMeasures(
		 [CMS_PQRI_MEASURE_ID]
		,[MEASURE_TITLE]
		,[CMS_PQRI_MEASURE_CODE_ID]
		,[CODING_SYSTEM]
		,[OPTION_GROUP]
		,[CODE]
		,[MODIFIER]
		,[DESCRIPTION]
		,[END_DATE]
		,[CODE_2]
		,[MODIFIER_2]
	    ,[MEASURE_TOOLTIP]			-- added DACS-3593, 09/03/2024 (pippin)
	    ,[MEASURE_HOTSHEET_URI] 	-- added DACS-3417, 08/19/2024 (pippin)
		,[ROW_NUMBER]
		)
	  EXEC [spSelectChartPQRS] @ChartId=@chart_id

	-- Delete the PQRS items from PHYSICIAN_PROCEDURE_EVALUATION that are inapplicable to this chart
	DELETE 
		[PHYSICIAN_PROCEDURE_EVALUATION]
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID]=ppe.[PHYSICIAN_PROCEDURE_ID]
	WHERE 
		[CHART_ID]=@chart_id
		AND cm.[CHARGE_MASTER_USAGE_CODE]=9
		AND cm.[CPT_CODE] NOT IN (
			SELECT 
				cpmc.[CODE] 
			FROM 
				@RequiredMeasures rm
				JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID]=rm.[CMS_PQRI_MEASURE_ID]
			WHERE 
				cpmc.[CODING_SYSTEM] IN ('CPT_II', 'HCPCS', 'OTHER')
				AND cpmc.[CODE]=cm.[CPT_CODE]
				AND ppe.[MODIFIERS] LIKE ISNULL('%' + cpmc.[MODIFIER] + '%', '')
			)
		AND cm.[CPT_CODE] NOT IN (
			SELECT 
				cpmc.[CODE_2] 
			FROM 
				@RequiredMeasures rm
				JOIN [CMS_PQRI_MEASURE_CODE] cpmc on cpmc.[CMS_PQRI_MEASURE_ID]=rm.[CMS_PQRI_MEASURE_ID]
			WHERE 
				cpmc.[CODING_SYSTEM] IN ('CPT_II', 'HCPCS')
				AND cpmc.[CODE_2]=cm.[CPT_CODE]
				AND ppe.[MODIFIERS] LIKE ISNULL('%' + cpmc.[MODIFIER] + '%', '')
			)
END; -- end SPROC
GO


-- End of 09) DACS-3593 - create or alter stored procedure - [dbo].[spRemoveInapplicablePqrs].SQL
GO

-- Start of 1) DACS-3399 - Create Proc spSelectIsChartPqrs.sql

GO

GO

GO

CREATE OR ALTER  PROCEDURE [dbo].[spSelectIsChartPqrs]   
 @ChartId INT,  
 @IsChartPqrs BIT OUTPUT
AS
BEGIN  

DECLARE @chart_id INT = @ChartId;  
DECLARE @Now DATETIME = GETDATE();  
DECLARE @flag VARCHAR(10) = '';  
DECLARE @HasDXCode INT;  
DECLARE @HasCPTCode INT;  
DECLARE @CPT_CODE AS VARCHAR(MAX)
DECLARE @PSP_CPT varchar(50)
  
-- Drop statements for new temp tables added 2/21/2023 (dsexton)  
if object_id('TempDB..#MeasureList', 'U') is not null DROP TABLE #MeasureList;  
if object_id('TempDB..#RequireCptMeasures', 'U') is not null DROP TABLE #RequireCptMeasures;  
if object_id('TempDB..#RequiredDiagnosisMeasures', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures;  
if object_id('TempDB..#RequiredDiagnosisMeasures2', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures2;  
if object_id('TempDB..#Chart', 'U') is not null DROP TABLE #Chart;  
if object_id('TempDB..#ChartDiagCodeICD10', 'U') is not null DROP TABLE #ChartDiagCodeICD10;  
if object_id('TempDB..#PPE_CPT', 'U') is not null DROP TABLE #PPE_CPT;  
  
SELECT
	chart_ID, service_agreement_ID, primary_complaint, chief_complaint, PHYSICIAN_SERVICE_PROC_ID, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID  
	,Time_of_Service, gender, patient_DOB, patient_age  
INTO #Chart   
FROM CHART  
WHERE
	chart_ID = @chart_id  
  
 SELECT cpm.CMS_PQRI_MEASURE_ID,  
  cpm.MEASURE_TITLE,  
  cpm.REQUIRES_BOTH_CPT_AND_DX,  
  cpmc.CMS_PQRI_MEASURE_CODE_ID,  
  cpmc.CODING_SYSTEM,  
  cpmc.OPTION_GROUP,  
  cpmc.CODE,  
  cpmc.MODIFIER,  
  cpmc.[DESCRIPTION],  
  CASE   
   WHEN cpmc.END_DATE IS NULL  
    THEN '12/31/9999 00:00:00'  
   ELSE cpmc.END_DATE   
   END END_DATE,  
  cpmc.CODE_2,  
  cpmc.MODIFIER_2,  
  cpm.REQUIRES_MULTIPLE_CPTS,  
  cpm.MULTIPLE_CPT_COUNT,  
  cpm.REQUIRES_MULTIPLE_DX,  
  cpm.REQUIRES_CPT_CODE,  
  cpm.REQUIRED_CPT_CODE,  
  CASE   
   WHEN COALESCE(cpm.REQUIRES_EM_ONLY, 0) = 1  
    AND (c.PHYSICIAN_SERVICE_PROC_ID > 0 OR c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0)  
    THEN 1  
   ELSE 0  
   END REQUIRES_EM_ONLY,  
  CASE   
   WHEN COALESCE(cpm.MATCH_EM_LEVEL, 0) = 1  
    THEN 1  
   ELSE 0  
   END MATCH_EM_LEVEL,  
  CASE   
   WHEN cpmc.START_DATE IS NULL  
    THEN '1/1/1900 00:00:00'  
   ELSE cpmc.START_DATE  
   END START_DATE,  
  CASE   
   WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE IS NULL  
    THEN '02/20/2020 00:00:00'  
   ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE  
   END REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,  
  CASE   
   WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE IS NULL  
    THEN '12/31/9999 00:00:00'  
   ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE  
   END REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,  
     CONVERT(Date, c.TIME_OF_SERVICE) as DATE_OF_SERVICE  
into #MeasureList 
 FROM CMS_PQRI_MEASURE cpm WITH (NOLOCK)  
 LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc WITH (NOLOCK) ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID  
 cross join #Chart c
 WHERE DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, c.TIME_OF_SERVICE)  
  AND (  
   ISNULL(cpm.GENDER, 'B') = 'B'  
   OR cpm.GENDER = c.GENDER  
   )  
  AND (  
   (  
    (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) = 0  
    AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0)) = 999  
    )  
   OR (  
    (c.PATIENT_AGE IS NOT NULL AND c.PATIENT_DOB IS NULL  
    AND c.PATIENT_AGE BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))  
    ))  
     
   OR (  
    (c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NOT NULL OR cpm.TO_AGE_FRACTIONAL IS NOT NULL)  
    AND ((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))  
    )  
     
   OR (  
   (c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NULL AND cpm.TO_AGE_FRACTIONAL IS NULL)  
    AND CAST(((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) AS INT) BETWEEN COALESCE(cpm.FROM_AGE, 0)  AND COALESCE(cpm.TO_AGE, 999)  
    )  
   )  
  
  AND cpm.CMS_PQRI_MEASURE_ID IN (  
   SELECT sapqrs.CMS_PQRI_MEASURE_ID  
   FROM SERVICE_AGREEMENT_PQRS sapqrs WITH (NOLOCK)  
   WHERE sapqrs.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
    AND CONVERT(Date, c.TIME_OF_SERVICE) BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, @Now)  
   )  
 
 
SELECT cdc.ICD10_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, cdc.DIAGNOSIS_TYPE_ID, cdc.IS_PRIMARY, c.Time_of_Service  
  into #ChartDiagCodeICD10  
FROM CHART_DIAGNOSIS_CODE_ICD10 cdc WITH (NOLOCK)  
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID  
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
  
SELECT cm.CPT_Code  
  into #PPE_CPT  
FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)  
INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID  
 and ppe.CHART_ID = @chart_id   

SELECT TOP 1 @PSP_CPT = CPT_CODE  
FROM 
	PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)  INNER JOIN #Chart c   
		ON PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
WHERE 
	PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE   
        WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0  
            THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID  
        ELSE c.PHYSICIAN_SERVICE_PROC_ID  
        END  
     
SELECT
	@CPT_CODE = CPT_CODE  
FROM 
	PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK) INNER JOIN CHART c WITH (NOLOCK) 
		ON psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
		AND c.CHART_ID = @chart_id  
WHERE 	
	psp.PHYSICIAN_SERVICE_PROC_ID = CASE   
										WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0  
										THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID  
									ELSE c.PHYSICIAN_SERVICE_PROC_ID  
									END  

SELECT 
	ml.CMS_PQRI_MEASURE_ID,
	ml.CODE,
	ml.MULTIPLE_CPT_COUNT
INTO #RequireCptMeasures  
FROM
	#MeasureList ml
WHERE
	ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE  
    AND 
	(
	EXISTS 
		(  
		 SELECT *  
		 FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)  
		 INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID  
		 WHERE ppe.CHART_ID = @chart_id  
		  AND cm.CPT_CODE = ml.CODE  
		  AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE  
		)
	OR 
	ml.Code = @CPT_CODE
	)

SELECT ml.CMS_PQRI_MEASURE_ID,  
  ml.MEASURE_TITLE,  
  ml.REQUIRES_BOTH_CPT_AND_DX,  
  ml.CMS_PQRI_MEASURE_CODE_ID,  
  ml.CODING_SYSTEM,  
  ml.OPTION_GROUP,  
  ml.CODE,  
  ml.MODIFIER,  
  ml.[DESCRIPTION],  
  ml.END_DATE,  
  ml.CODE_2,  
  ml.MODIFIER_2,  
  --ROW_NUMBER() OVER (  
   --PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC  
   --) [ROW_NUMBER],  
  REQUIRES_EM_ONLY,  
  ml.DATE_OF_SERVICE,  
  ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,  
  ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,  
  ml.REQUIRES_MULTIPLE_CPTS,  
  ml.MULTIPLE_CPT_COUNT,  
  ml.REQUIRES_MULTIPLE_DX,  
  ml.REQUIRES_CPT_CODE,  
  ml.REQUIRED_CPT_CODE  
into #RequiredDiagnosisMeasures  
FROM
	#MeasureList ml
 WHERE
    ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
    AND EXISTS (  
     select * from #ChartDiagCodeICD10 as cdc  -- tuning with temp table in the subquery, 2/21/2023 (dsexton)  
     where  
      cdc.ICD10_CODE = ml.CODE  
         AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE  
      AND (  
       ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1  
       OR (  
        (cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)  
        OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 1)  
        )  
       )  
      AND (  
       NOT EXISTS (  
        SELECT *  
        FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)  
        WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
        )  
       OR EXISTS (  
        SELECT *  
        FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)  
        WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
         AND CODE_1 = cdc.ICD10_CODE  
         AND CODE_2 IN (  
          SELECT ICD10_CODE  
          from #ChartDiagCodeICD10
          WHERE   
           (  
                        ICD10_CODE <> cdc.ICD10_CODE  
                        OR CODE_1 = CODE_2  
           )  
          )  
        )  
       )  
     )  

SELECT 
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM
	#RequiredDiagnosisMeasures rdm JOIN #RequireCptMeasures rcm 
		ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID    
WHERE 
	rdm.REQUIRES_BOTH_CPT_AND_DX = 1  
	AND rdm.REQUIRES_MULTIPLE_CPTS = 1  
	AND rdm.REQUIRES_MULTIPLE_DX IS NULL  
	AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE   
	AND rdm.CODE IS NOT NULL  
	AND rcm.CODE IS NOT NULL  
GROUP BY 
	rdm.CMS_PQRI_MEASURE_ID, rdm.MEASURE_TITLE, rdm.REQUIRES_BOTH_CPT_AND_DX, rdm.CMS_PQRI_MEASURE_CODE_ID, rdm.CODING_SYSTEM, rdm.OPTION_GROUP, rdm.CODE, rdm.MODIFIER, rdm.[DESCRIPTION], rdm.END_DATE, rdm.CODE_2, rdm.MODIFIER_2, rdm.REQUIRES_EM_ONLY, rcm.MULTIPLE_CPT_COUNT  
HAVING COUNT(rcm.CODE) = rcm.MULTIPLE_CPT_COUNT  

IF @IsChartPqrs = 1 RETURN;      

 SELECT ml.CMS_PQRI_MEASURE_ID,  
  ml.MEASURE_TITLE,  
  ml.REQUIRES_BOTH_CPT_AND_DX,  
  ml.CMS_PQRI_MEASURE_CODE_ID,  
  ml.CODING_SYSTEM,  
  ml.OPTION_GROUP,  
  ml.CODE,  
  ml.MODIFIER,  
  ml.[DESCRIPTION],  
  ml.END_DATE,  
  ml.CODE_2,  
  ml.MODIFIER_2,  
  REQUIRES_EM_ONLY,  
  ml.DATE_OF_SERVICE,  
  ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,  
  ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,  
  ml.REQUIRES_MULTIPLE_CPTS,  
  ml.MULTIPLE_CPT_COUNT,  
  ml.REQUIRES_MULTIPLE_DX,  
  ml.REQUIRES_CPT_CODE,  
  ml.REQUIRED_CPT_CODE  
INTO #RequiredDiagnosisMeasures2  
FROM
	#MeasureList ml JOIN #ChartDiagCodeICD10 cdc
	ON cdc.ICD10_CODE = ml.CODE  
WHERE   
	ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
	AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE  
	AND 
	(  
		ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1  
		OR 
		(  
		(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 0)  
		OR 
		NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 0)  
		)  
	)  	
   
SELECT 
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM
	#RequiredDiagnosisMeasures2 rdm2 JOIN #RequireCptMeasures rcm 
		ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
	JOIN #RequiredDiagnosisMeasures rdm 
		ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID    
WHERE 
	rdm.REQUIRES_BOTH_CPT_AND_DX = 1  
	AND rdm.REQUIRES_MULTIPLE_DX = 1  
	AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL  
	AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE   
	AND rdm.CODE IS NOT NULL  
	AND rcm.CODE IS NOT NULL  
	AND rdm2.CODE IS NOT NULL  

IF @IsChartPqrs = 1 RETURN;    

SELECT 
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM
	#MeasureList ml
WHERE 
	ml.REQUIRES_BOTH_CPT_AND_DX = 1  
	AND CONVERT(Date, ml.DATE_OF_SERVICE) < ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE  
	AND ml.CODE IS NOT NULL  
   AND (  
    ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
    AND EXISTS (  
     select * from #ChartDiagCodeICD10 as cdc
     where  
      cdc.ICD10_CODE = ml.CODE  
      AND (  
       ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1  
       OR (  
        (cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)  
        OR (cdc.DIAGNOSIS_TYPE_ID IN (1,3,5) AND cdc.IS_PRIMARY = 0)  
        )  
       )  
      AND (  
       NOT EXISTS (  
        SELECT *  
        FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)  
        WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
        )  
       OR EXISTS (  
        SELECT *  
        FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)  
        WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
         AND CODE_1 = cdc.ICD10_CODE  
         AND CODE_2 IN (SELECT ICD10_CODE FROM #ChartDiagCodeICD10 WHERE ICD10_CODE <> cdc.ICD10_CODE  OR CODE_1 = CODE_2)  
        )  
       )  
     )  
  )  
  OR 
  (  
    ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')  
    AND EXISTS (SELECT 1 FROM #PPE_CPT as t where t.CPT_Code = ml.Code)  
  )     
  OR 
  (  
	ml.REQUIRES_EM_ONLY = 1 AND @PSP_CPT IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395')  
  )      

IF @IsChartPqrs = 1 RETURN;    

IF((SELECT COUNT(*) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID IN (184, 185, 189)) > 1)
BEGIN
SELECT 
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM 
	#RequireCptMeasures rcm1 JOIN #RequireCptMeasures rcm2
	ON rcm1.CMS_PQRI_MEASURE_ID = rcm2.CMS_PQRI_MEASURE_ID
WHERE 
	(COALESCE(rcm1.REQUIRES_BOTH_CPT_AND_DX, 0) = 0  
	AND rcm1.REQUIRES_CPT_CODE = 1  
	AND rcm1.CODE IS NOT NULL) 
	OR
	(rcm2.CMS_PQRI_MEASURE_ID IN (184, 185, 189) AND rcm1.REQUIRED_CPT_CODE = rcm2.REQUIRED_CPT_CODE)
END

IF @IsChartPqrs = 1 RETURN;

SELECT
	@IsChartPqrs = IIF(COUNT(*)>0, 1, 0) 
FROM 
	#RequiredDiagnosisMeasures rdm JOIN #RequireCptMeasures rcm
		ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
	JOIN #MeasureList ml
		ON rdm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID  
WHERE 
	rdm.REQUIRES_BOTH_CPT_AND_DX = 1  
	AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL  
	AND rdm.REQUIRES_MULTIPLE_DX IS NULL  
	AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE   
	AND rdm.CODE IS NOT NULL  
	AND rcm.CODE IS NOT NULL  
	AND ml.CODING_SYSTEM IN ('CPT_II', 'HCPCS')  
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE 

RETURN;

END
GO

-- End of 1) DACS-3399 - Create Proc spSelectIsChartPqrs.sql
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
