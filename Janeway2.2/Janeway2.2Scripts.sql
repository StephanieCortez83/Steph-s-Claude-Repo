USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3211 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - ACEP60.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3211 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - ACEP60.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = 'ACEP60';
	DECLARE @Dos DATETIME = '01-01-2024' --GETDATE();

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [REQ_2_DX_OR_3CPT] = 1
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 'ACEP60'
				,'Facilitate Quality and Performance'
				,'ACEP60 Syncope – Avoidance of admission for adult patients with low-risk syncope: Percentage of emergency department (ED) visits for patients aged 18-50 years with a diagnosis of low-risk syncope who were discharged.'	
				,'B'
				,18
				,50
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);



	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ACEP60' -- = 198
*/
-- End of 01) DACS-3211 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - ACEP60.SQL
GO

-- Start of 02) DACS-3211 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ACEP60.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3211 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ACEP60.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ACEP60';
	DECLARE @Dos DATETIME = '01-01-2024' --GETDATE();

	DECLARE @MeasureId INT = 
		(
			SELECT [CMS_PQRI_MEASURE_ID]
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('No Measure loaded for ACEP60.  Cannot continue.');
		SELECT 'Error' = -1;
		RETURN;
	END;

	PRINT('@MeasureId = ' + CAST(@MeasureId AS VARCHAR(30)));

	DECLARE @countPQRSCodes INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
		);

	SELECT '@countPQRSCodes' = @countPQRSCodes; -- testing


	IF @countPQRSCodes > 0
	BEGIN 
		PRINT('Found Measure Codes.  Expiring existing.');
	
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [END_DATE] = DATEADD(minute,-1,CAST(CAST(@Dos AS DATE) AS DATETIME))
		WHERE
			[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND [START_DATE] <= @Dos
			AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
			AND [CODE] IS NOT NULL
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	END;

	DECLARE @countPQRSCodesAfterExpiration INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'DG1P1','99281',@Dos,NULL)
		,(@MeasureId,'DG1P1','99282',@Dos,NULL)
		,(@MeasureId,'DG1P1','99283',@Dos,NULL)
		,(@MeasureId,'DG1P1','99284',@Dos,NULL)
		,(@MeasureId,'DG1P1','99285',@Dos,NULL)
		,(@MeasureId,'DG1P1','99291',@Dos,NULL)
		,(@MeasureId,'DG1P1','99292',@Dos,NULL)
		
		,(@MeasureId,'DG1P2','R55',@Dos,NULL)
		
		,(@MeasureId,'DG2P1','P6001',@Dos,NULL) -- EXCLUDE codes
		
		-- ,(@MeasureId,'DG2P2','G8923',@Dos,NULL) -- not used
		-- ,(@MeasureId,'DG2P3','M1152',@Dos,NULL)  -- not used
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','P6002',@Dos,'Performance Met: Patient discharged from ED')
		,(@MeasureId,'HCPCS','P6004',@Dos,'Denominator Exception: Death, LAMA, LWBS, LWT')
		,(@MeasureId,'HCPCS','P6003',@Dos,'Performance Not Met: Patient NOT discharged from ED')
		; -- expect 12 total inserts
				
		
	DECLARE @countPQRSCodesFinal INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
		);

	SELECT '@countPQRSCodesFinal' = @countPQRSCodesFinal;

	-- testing:
	SELECT 
		*
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ACEP60'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 198
*/
-- End of 02) DACS-3211 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ACEP60.SQL
GO

-- Start of 03) DACS-3211 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3211 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of ACEP60, there is 1 valid decision path.  This script is designed around this example.
	-- checks chart age within range of 18 to 50
	-- checks that the chart patient class is Emergency department (ED)
	-- requires one CPT code within the DG1P1 GROUP 
	-- requires one ICD10 code within the DG1P2 GROUP 
	-- and EXCLUDES a CPT code within the DG2P1 GROUP
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - P6002
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - P6004
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - P6003
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors, or not an ED patient class
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
	SELECT TOP 1
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
				-- AND [DESCRIPTION] like 'emergency%'	
				AND PHYSICIAN_SERVICE_CLASS_CD = 1
		)
	BEGIN 
		PRINT('@ChartId does not have a valid patient class type of ED to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid patient class type of ED to test', 'Code' = 'ERR-0-AED';
		RETURN;
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
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','HCPCS')
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


	-- do we have Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes))', 'Code' = 'ERR-1-NEP';
		RETURN;
	END;

	-- do we have Patient had a diagnosis of syncope (ICD10)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient had a diagnosis of syncope (ICD10))', 'Code' = 'ERR-2-NDS';
		RETURN;
	END;

	-- EXCLUSION CHECK: do we have (“Pseudo” code - ACEP6001)?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount > 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (“Pseudo” code - ACEP6001) Found', 'Code' = 'ERR-3-NPC';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - P6002
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - P6004
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - P6003

	DECLARE @foundP6002Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'P6002');  /*@ResultPerformanceCodeMet*/

	IF @foundP6002Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'P6002';
		RETURN;
	END;

	DECLARE @foundP6003Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'P6003');  /*@ResultPerformanceCodeNotMet*/

	IF @foundP6003Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'P6003';
		RETURN;
	END;

	DECLARE @foundP6004Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'P6004');  /*@ResultPerformanceCodeExMet*/

	IF @foundP6004Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'P6004';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (P6002,P6003,P6004)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ACEP60'

EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60
	  @ChartId = 2100107114
	, @PqrsNum = 'ACEP60'
	, @Dos = '1/22/2024 12:00:00 AM'
	-- , @ShowDebug = 1;
	
begin tran; -- testing
*/
-- End of 03) DACS-3211 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60].SQL
GO

-- Start of 01) DACS-3159 - Create of Alter Stored Procedure - [dbo].[SelectChartByFacilityIdAndFacilityChartIdentifier].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3159 - Create of Alter Stored Procedure - [dbo].[SelectChartByFacilityIdAndFacilityChartIdentifier].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartByFacilityIdAndFacilityChartIdentifier] 
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
		
	SELECT TOP 1	-- this is a just in case safety item, do not remove. ACS sometimes has issues regarding duplicates that are generated by clients via batch importing
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
	FROM [CHART]
	WHERE 
	    [FACILITY_ID] = @facilityId
		AND [FACILITY_CHART_ID] = @facilityChartIdentifier;

END -- end procedure

GO
-- End of 01) DACS-3159 - Create of Alter Stored Procedure - [dbo].[SelectChartByFacilityIdAndFacilityChartIdentifier].SQL
GO

-- Start of 02) DACS-3159 - Alter Stored Procedure - [dbo].[CHART_SELECT_BY_CHART_ID].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3159 - Alter Stored Procedure - [dbo].[CHART_SELECT_BY_CHART_ID].SQL
------------------------------------------------------------------------------------
GO

GO

GO

ALTER PROCEDURE [dbo].[CHART_SELECT_BY_CHART_ID]
	@CHART_ID INT
AS
BEGIN
	----------------
	-- Simple select statement used by ChartDAO.cs within ACS
	----------------

	----------------
	-- validate parameters
	----------------
	IF @CHART_ID IS NULL OR @CHART_ID <= 0
	BEGIN
		PRINT('@CHART_ID is invalid.');
		RETURN;
	END;

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
	SELECT TOP 1	-- this is a just in case safety item, do not remove. -- added DACS-3159 -- 20240412 -- pippin
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
		,[ADD_MODIFIER_93_TO_PHYSICIAN_LOS]	-- added DACS-2475 - 20230619 - pippin
		,[FACILITY_LOS_93_MODIFIER]			-- added DACS-2475 - 20230619 - pippin
		,[ADD_MODIFIER_FS_TO_PHYSICIAN_LOS]	-- added DACS-2485 - 20230626 - pippin
	FROM	
		[dbo].[CHART] 
	WHERE 
		[CHART_ID] = @CHART_ID;
END

GO


-- End of 02) DACS-3159 - Alter Stored Procedure - [dbo].[CHART_SELECT_BY_CHART_ID].SQL
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
