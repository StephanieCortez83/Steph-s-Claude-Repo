USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3243 - Create of Alter Stored Procedure - [dbo].[SelectPhysicianServiceProcIdAndInUseByServiceAgreementId].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3243 - Create of Alter Stored Procedure - [dbo].[SelectPhysicianServiceProcIdAndInUseByServiceAgreementId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysicianServiceProcIdAndInUseByServiceAgreementId] 
	  @serviceAgreementId INT
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- SQL Originally created by Mr. Sexton
	-- Leaving substantially as written
	----------------

	----------------
	-- validate parameters
	----------------
	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0
	BEGIN
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- DECLARE @ServiceAgreementId INT = 1009 -- testing
	 
	IF OBJECT_ID('TempDB..#ProcIDs', 'U') IS NOT NULL DROP TABLE #ProcIDs
	IF OBJECT_ID('TempDB..#Results', 'U') IS NOT NULL DROP TABLE #Results
	 
	SELECT  
		physician_service_proc_ID
		, Service_Agreement_Id
	INTO 
		#ProcIDs
	FROM 
		PHYSICIAN_SERVICE_PROCEDURE 
	WHERE 
		SERVICE_AGREEMENT_ID = @serviceAgreementId
	 
	SELECT 
		service_agreement_ID
		, physician_service_proc_ID
		, RowCnt = count(*)
	INTO 
		#Results
	FROM 
		chart
	WHERE 
		service_agreement_ID = @serviceAgreementId
		AND (
				physician_service_proc_ID IN (SELECT physician_service_proc_ID FROM #ProcIDs)
				OR override_physician_service_proc_ID IN (SELECT physician_service_proc_ID FROM #ProcIDs)
			)
	GROUP BY 
		service_agreement_ID
		, physician_service_proc_ID
	 
	-- SELECT * FROM #Results	 -- for reference/testing		 
	-- SELECT sum(RowCnt) FROM #Results		-- 256666       -- for reference/testing
	 
	SELECT 
		--t1.service_agreement_ID,
		t1.physician_service_proc_ID
		, IN_USE = CASE WHEN t2.RowCnt IS NULL THEN 0 ELSE 1 END
	FROM 
		#ProcIDs AS t1
		LEFT JOIN #Results AS t2 
			ON t1.service_agreement_ID = t2.service_agreement_ID
			AND t1.physician_service_proc_ID = t2.physician_service_proc_ID
	ORDER BY 
		IN_USE DESC
		, physician_service_proc_ID

END -- end procedure

GO

/*
testing:
begin tran; -- testing
EXEC [SelectPhysicianServiceProcIdAndInUseByServiceAgreementId] @serviceAgreementId=1009
*/
-- End of 01) DACS-3243 - Create of Alter Stored Procedure - [dbo].[SelectPhysicianServiceProcIdAndInUseByServiceAgreementId].SQL
GO

-- Start of 01) DACS-3208 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 76.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3208 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 76.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '76';
	DECLARE @Dos DATETIME = '01-01-2024';
	DECLARE @dateOfExpiration DATETIME = '12-31-2023';

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	PRINT('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @dateOfExpiration
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	

		SET @countPQRS = 
			(
				SELECT COUNT(*) 
				FROM [dbo].[CMS_PQRI_MEASURE] 
				WHERE [PQRS#] = @PqrsCd
					AND [EFFECTIVE_DATE] <= @Dos
					AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
			);

		PRINT('after expiration @countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));
		
		IF @countPQRS > 0
		BEGIN 
			PRINT('Expiration failed.  Needs table assistance.  Exiting.');
			RETURN;
		END;

	END;

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
			 '76'
			,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
			,'PQRS# 76 Prevention of Central Venous Catheter (CVC): Related Bloodstream Infections'	
			,'B'
			,0
			,999
			,@Dos
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,0
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
SELECT TOP 1000 * FROM [dbo].[CMS_PQRI_MEASURE]
where [PQRS#] IN ('76');
*/
-- End of 01) DACS-3208 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 76.SQL
GO

-- Start of 02) DACS-3208 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 76.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3208 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 76.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '76';
	DECLARE @Dos DATETIME = '01-01-2024';

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
		PRINT('No Measure loaded for 76.  Cannot continue.');
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
				AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
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
			AND [CODING_SYSTEM] IN ('C4','CPT_II')
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
				AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Needs table assistance.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'C4','36555',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36556',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36557',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36558',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36560',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36561',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36563',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36565',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36566',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36568',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36569',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36570',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36571',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36572',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36573',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36578',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36580',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36581',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36582',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36583',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36584',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36585',NULL,@Dos,NULL)
		,(@MeasureId,'C4','93503',NULL,@Dos,NULL)			
				
		,(@MeasureId,'CPT_II','6030F','1P',@Dos,'Denominator Exception: 6030F with 1P: Documentation of medical reason(s) for not following all elements of maximal sterile barrier technique, hand hygiene, skin preparation and, if ultrasound is used, sterile ultrasound techniques during CVC insertion (including increased risk of harm to patient if adherence to aseptic technique would cause delay in CVC insertion)')			
		,(@MeasureId,'CPT_II','6030F','8P',@Dos,'Performance Not Met: 6030F with 8P: All elements of maximal sterile barrier technique, hand hygiene, skin preparation and, if ultrasound is used, sterile ultrasound techniques not followed, reason not otherwise specified')			
		,(@MeasureId,'CPT_II','6030F',NULL,@Dos,'Performance Met: CPT II 6030F: All elements of maximal sterile barrier technique, hand hygiene, skin preparation and, if ultrasound is used, sterile ultrasound techniques followed')			

		; -- expect 26 inserts
		
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
				AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
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
		AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
SELECT TOP 1000 * FROM [dbo].[CMS_PQRI_MEASURE]
where [PQRS#] IN ('76');

SELECT TOP 1000 * 
FROM [dbo].[CMS_PQRI_MEASURE_CODE]
WHERE CMS_PQRI_MEASURE_ID IN (195)
*/
-- End of 02) DACS-3208 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 76.SQL
GO

-- Start of 03) DACS-3208 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureId_Type76].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3208 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureId_Type76].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureId_Type76] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 76, it is too simple to "trigger" the older MIPS tools/SPROCS.  This script is designed around this example.
	-- will handle them seperately based on the MeasureId passed into this script
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - 6030F
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - (6030F with 1P)
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - (6030F with 8P)
	-- returns 4 to indicate that one of the 3 above states is met but indeterminant due to modifier.  the ACS UI will deal with this
	
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
	-- IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList - not needed at present.

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
		--, GENDER  	- not needed at present.
		--, PATIENT_DOB - not needed at present.
		--, PATIENT_AGE - not needed at present.
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
		--, [REQ_2_DX_OR_3CPT]  - not needed at present.
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
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
 

	----------------
	-- check for gender CONSTRAINTS  - not needed at present.
	----------------
/*
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
*/
	
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
	DECLARE @PSP_MODIFIERS varchar(250);
	
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
	-- Present Diagnosis List - not needed at present.
	----------------
/*	SELECT 
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
		AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroupC4MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'C4');
	
	IF @foundDenominatorGroupC4MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator C4 records';
		RETURN;
	END;

	-- do we have a Patient procedure during the performance period (CPT)?
	SET @foundDenominatorGroupC4MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'C4'));
	IF @foundDenominatorGroupC4MatchCount <= 0 
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient procedure during the performance period (CPT))', 'Code' = 'ERR-1-NPP';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Performance Met: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 4 to indicate that one of the 3 above states is met but indeterminant due to modifier.  the ACS UI will deal with this
	
	DECLARE @found6030FCount INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '6030F');  /*@ResultPerformanceCodeMet*/

	IF @found6030FCount >= 0
	BEGIN 
		SELECT 'Result' = 4, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = '6030F';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (6030F,6030F+1P,6030F+8P)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '76'

exec [dbo].[PqrsMeasureIsSatisfiedByMeasureId_Type76] 
	  @ChartId = 2100107114
	, @PqrsNum  = '76'
	--, @Dos DATETIME = NULL
	--, @MeasureId INT = NULL
	, @ShowDebug = 1

-----------------------------------------------------
--select top 20000 * from CMS_PQRI_MEASURE
-- where CMS_PQRI_MEASURE_ID = 201
--order by CMS_PQRI_MEASURE_ID desc;

-- MIPS# 76 Prevention of Catheter-Related Bloodstream Infections (CRBSI): Central Venous Catheter (CVC) Insertion Protocol
--exec [dbo].[SelectCmsPqrsMeasureResultsListById] @MeasureId = 201;

begin tran; -- testing
*/
-- End of 03) DACS-3208 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureId_Type76].SQL
GO

-- Start of 04) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureListById].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListById] 
	  @MeasureId INT
	, @Dos DATETIME = NULL
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
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 cpm.CMS_PQRI_MEASURE_ID
		,cpm.MEASURE_TITLE
		,cpmc.CMS_PQRI_MEASURE_CODE_ID
		,cpmc.CODING_SYSTEM
		,cpmc.OPTION_GROUP
		,cpmc.CODE
		,cpmc.MODIFIER
		,cpmc.[DESCRIPTION]
		,
		CASE 
			WHEN cpmc.END_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.END_DATE 
			END END_DATE
		,cpmc.CODE_2
		,cpmc.MODIFIER_2
		,NULL [ROW_NUMBER]
	FROM 
		CMS_PQRI_MEASURE cpm
		LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID
	WHERE 
		DATEADD(DAY, DATEDIFF(DAY, 0, @Dos), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, @Dos)
		AND cpm.CMS_PQRI_MEASURE_ID = @MeasureId
		AND cpmc.CODING_SYSTEM IN ('CPT_II','HCPCS')
	ORDER BY cpmc.CODE, cpmc.MODIFIER
	;

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '76'
exec [dbo].[SelectCmsPqrsMeasureResultsListById] @MeasureId = 201; -- 51 is the old id
201	76	MIPS CLINICAL QUALITY MEASURES (CQMS)	PQRS# 76 Prevention of Central Venous Catheter (CVC): Related Bloodstream Infections	B	0	999	2024-01-01	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
begin tran; -- testing
*/
-- End of 04) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureListById].SQL
GO

-- Start of 05) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectPqrsMeasuresByCidSaidUsageCodeDos].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectPqrsMeasuresByCidSaidUsageCodeDos].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPqrsMeasuresByCidSaidUsageCodeDos] 
	  @chartId INT
	, @serviceAgreementId INT
	, @usageCode INT
	, @chartDOS DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @chartId < 0
	BEGIN
		-- SELECT 'Error' = -1, 'Message' = 'bad @chartId';
		RETURN;
	END;
		
	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0
	BEGIN
		-- SELECT 'Error' = -1, 'Message' = 'bad @serviceAgreementId';
		RETURN;
	END;

	IF @chartDOS IS NULL
	BEGIN
		SET @chartDOS = GETDATE();
		-- PRINT('@chartDOS set to ' + CAST(@chartDOS AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		  CM.CHARGE_MASTER_ID
		, CM.CHARGE_MASTER_CATEGORY_ID
		, CM.DESCRIPTION
		, CM.LONG_DESCRIPTION
		, CM.CPT_CODE
		, CM.BILLING_CODE
		, CM.MODIFIER_REQUIRED
		, PPE.ICD9_CODE
		, PPE.ICD_10_CODE
		, PPE.PROCEDURE_DATE
		, CMC.DESCRIPTION
		, PPE.QUANTITY
		, PPE.MODIFIERS
		, PPE.PHYSICIAN_ID
		, PPE.INSUFFICIENT_DOCUMENTATION_TO_BILL
		, PPE.ADD_TO_FACILITY_PROCEDURE
		, CM.MAX_QUANTITY
		, CM.ALLOW_NEGATIVE_UNITS_IND
		, CM.CHARGE_MASTER_DEPT_ID 
		, 0 EXCLUDE_FROM_CODER_QA_REPORT
		, CAST(0 AS BIT) HAS_MODIFIERS
	FROM 
		CHARGE_MASTER CM 
        LEFT JOIN PHYSICIAN_PROCEDURE_EVALUATION PPE ON CM.CHARGE_MASTER_ID = PPE.PHYSICIAN_PROCEDURE_ID
			AND (CHART_ID= @chartId OR CHART_ID IS NULL)
        JOIN CHARGE_MASTER_CATEGORY CMC ON CMC.CHARGE_MASTER_CATEGORY_ID = CM.CHARGE_MASTER_CATEGORY_ID
    WHERE 
		@chartDOS BETWEEN CM.EFFECTIVE_DATE AND CM.EXPIRATION_DATE
		AND CM.SERVICE_AGREEMENT_ID = @serviceAgreementId            
        AND CM.CHARGE_MASTER_USAGE_CODE = @usageCode
	;

END -- end procedure

GO

/*
testing:
EXEC SelectPqrsMeasuresByCidSaidUsageCodeDos
	@chartId = 2100107114,
    @serviceAgreementId = 555266,
    @usageCode = 9,
    @chartDOS = '1/22/2024 12:00:00 AM'
begin tran; -- testing
*/
-- End of 05) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectPqrsMeasuresByCidSaidUsageCodeDos].SQL
GO

-- Start of 06) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] 
	  @SaId INT
	, @Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN
		
	IF @SaId IS NULL OR @SaId <= 0
		RETURN;

	IF @Dos IS NULL
		SET @Dos = GETDATE();

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP 500
		[PQRS#]
	FROM 
		SERVICE_AGREEMENT_PQRS p
		INNER JOIN CMS_PQRI_MEASURE c ON c.CMS_PQRI_MEASURE_ID = p.CMS_PQRI_MEASURE_ID
	WHERE 
		SERVICE_AGREEMENT_ID= @SaId
		AND @Dos >= c.[EFFECTIVE_DATE]
		AND (c.[EXPIRATION_DATE] IS NULL OR c.[EXPIRATION_DATE] >= @Dos)
		AND @Dos >= p.[EFFECTIVE_DATE]
		AND (p.[EXPIRATION_DATE] IS NULL OR p.[EXPIRATION_DATE] >= @Dos)
	;

END -- end procedure

GO

/*
testing:
EXEC SelectActiveServiceAgreementMipsBySaidAndDos
	@SaId = 555266,
    @Dos = '1/22/2024 12:00:00 AM'
begin tran; -- testing
*/
-- End of 06) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos].SQL
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
