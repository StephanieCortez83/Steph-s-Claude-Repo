------------------------------------------------------------------------------------
-- 03) DACS-3223 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51] 
	  @ChartId INT
	, @MeasureId INT = NULL
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

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;
		
	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	-- No age restrictions at this time.
	-- PRINT ('Age criteria satisfied to continue comparisons.');

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF NOT EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('1','2','3','6','7','8','9','11') OR [LOCATION_OF_SERVICE] IN ('02','21','22','23'))
		)
	BEGIN 
		PRINT('@ChartId does not have a valid patient class type of (1, 2, 3, 6, 7, 8, 9 or 11) OR Location of Service of (02, 21, 22, 23) to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid patient class type of (1, 2, 3, 6, 7, 8, 9 or 11) OR Location of Service of (02, 21, 22, 23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
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
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
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

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have any Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have any Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR51' -- = 225

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51
	@ChartId = 2100112304
	,@PqrsNum = 'ECPR51'
	,@Dos = '7/11/2024 2:38:01 PM'

begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/

