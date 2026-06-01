SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type7B] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 7, there are 2 valid decision paths.  the data is stored by PQRS# '7-A' and '7-B' for example.  This script is designed around this example.
	-- will handle them seperately based on the MeasureId passed into this script
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9189 or 4008F
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9190 or 4008F with 1P
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9191 or 4008F with 2P
	-- returns 4 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9192 or (4008F with 3P
	-- returns 5 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9188 or (4008F with 8P
	
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
		, ppe.[MODIFIERS]
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

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	-- do we have a History of cardiac surgery (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (coronary artery disease) OR (cardiac surgery)', 'Code' = 'ERR-1-NCA';
		RETURN;
	END;

	-- Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM):
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (prior (within the past 3 years) myocardial infarction)', 'Code' = 'ERR-2-NMI';
		RETURN;
	END;

	-- Patient encounter during performance period – to be used for numerator evaluation (CPT)
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2'));

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (At least one additional patient encounter during performance period)', 'Code' = 'ERR-3-NPP';
		RETURN;
	END;

	-- At least one additional patient encounter during performance period (CPT)
	SET @foundDenominatorGroup2Pick3MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'));

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Left ventricular ejection fraction)', 'Code' = 'ERR-4-NAP';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Performance Met: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9189 or 4008F
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9190 or 4008F with 1P
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9191 or 4008F with 2P
	-- returns 4 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9192 or 4008F with 3P
	-- returns 5 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9188 or 4008F with 8P

	DECLARE @found4008FCount INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F');  /*@ResultPerformanceCodeMet*/

	IF @found4008FCount >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = '4008F';
		RETURN;
	END;

	DECLARE @found4008F8PCount INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F' AND [MODIFIERS] LIKE '%8P%');  /*@ResultPerformanceCodeNotMet*/

	IF @found4008F8PCount >= 0
	BEGIN 
		SELECT 'Result' = 5, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = '4008F+8P';
		RETURN;
	END;

	DECLARE @found4008F1PCount INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F' AND [MODIFIERS] LIKE '%1P%');  /*@ResultPerformanceCodeExMet*/

	IF @found4008F1PCount >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = '4008F+1P';
		RETURN;
	END;

	DECLARE @found4008F2PCount INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F' AND [MODIFIERS] LIKE '%2P%');  /*@ResultPerformanceCodeExMet*/

	IF @found4008F1PCount >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = '4008F+2P';
		RETURN;
	END;

	DECLARE @found4008F3PCount INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F' AND [MODIFIERS] LIKE '%3P%');  /*@ResultPerformanceCodeExMet*/

	IF @found4008F3PCount >= 0
	BEGIN 
		SELECT 'Result' = 4, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = '4008F+3P';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (4008F,4008F+1P,4008F+2P,4008F+3P,4008F+8P)', 'Code' = '????';

END -- end procedure

GO
