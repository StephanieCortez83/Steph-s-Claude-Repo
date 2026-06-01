------------------------------------------------------------------------------------
-- 01) DACS-3163 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] - gender correction.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] 
	  @ChartId INT
	, @MeasureId INT
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9315
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9313
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9314
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
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
		
	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
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
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		, [GENDER]
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
	DECLARE @gender VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempChartInfo);

	IF (@gender IS NULL OR @gender IN ('U', 'X')) SET @gender = 'B';
	
	IF @gender <> 'B'
	BEGIN 
		DECLARE @genderCheck VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempMeasureInfo);
		
		IF @genderCheck IS NULL SET @genderCheck = 'B';

		IF @gender <> @genderCheck AND @genderCheck <> 'B'
		BEGIN 
			PRINT('@ChartId does not match gender test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not match gender test', 'Code' = 'ERR-0-GEN';
			RETURN;
		END;
	END;

	PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	
	SELECT TOP 1 
		@PSP_CPT = [CPT_CODE]
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
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
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
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorGroup2Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2');
	DECLARE @foundDenominatorGroup2Pick3MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3');
	
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

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P3 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P3 records';
		RETURN;
	END;

	-- do we have a diag for acute sinusitus?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		PRINT('Date completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no acute sinusitus)', 'Code' = 'ERR-1-NAS';
		RETURN;
	END;
	
	-- are we missing both bacterial infection and G9364?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));

	IF @foundDenominatorGroup1Pick2MatchCount <= 0 AND @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no bacterial infection)', 'Code' = 'ERR-2-NBI';
		RETURN;
	END;
	
	-- do we have a Phys Svcs E and M code?
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2'));

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no E&M code match)', 'Code' = 'ERR-3-NEC';
		RETURN;
	END;

	-- do we have a antibiotic regimine (G9498) code?
	SET @foundDenominatorGroup2Pick3MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'));

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (no antibiotic regimine)', 'Code' = 'ERR-4-NAR';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Performance Met: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + Performance Met) - G9315
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + denominator exception) - G9313
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + Performance NOT Met) - G9314
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Data completeness met + But no codes in chart already found for denominator value) - ????
	-- DECLARE @ResultPerformanceCodeMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE 'Performance Met:%')
	-- DECLARE @ResultPerformanceCodeNotMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE 'Performance Not Met:%')
	-- DECLARE @ResultPerformanceCodeExMet VARCHAR(20) = (SELECT TOP 1 [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'HCPCS' AND [DESCRIPTION] LIKE '%Performance Exclusion:%')

	DECLARE @foundG9315Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9315');  /*@ResultPerformanceCodeMet*/

	IF @foundG9315Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'G9315';
		RETURN;
	END;

	DECLARE @foundG9313Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9313');  /*@ResultPerformanceCodeExMet*/

	IF @foundG9313Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G9313';
		RETURN;
	END;

	DECLARE @foundG9314Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9314');  /*@ResultPerformanceCodeNotMet*/

	IF @foundG9314Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'G9314';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code set from list (G9315,G9313,G9314)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332'
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/