USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3368 - Script adds 'Use ImageViewer Rev2' Defined Right and related User Group and Group Rights.SQL

----------------------------------------
-- 01) DACS-3368 - Script adds 'Use ImageViewer Rev2' Defined Right and related User Group and Group Rights.SQL
----------------------------------------
GO

----------------------------------------
-- Step 1)  Get the needed variables in order to perform the task
----------------------------------------
DECLARE	@DEFINED_RIGHT_ID int =						167;  -- DEFINED_RIGHT_ID to be created
DECLARE	@DEFINED_RIGHT_NAME varchar(50) =			'ImageViewer - Use Rev 2';
DECLARE	@DEFINED_RIGHT_DEFINITION varchar(2000) =	NULL;  -- If null, the stored procedure will use the @DEFINED_RIGHT_NAME value
DECLARE	@CREATING_USER_ID int =						10149; -- Marcus Ferrell
DECLARE @USER_GROUP_NAME varchar(35) =				'ImageViewer - Use Rev 2';

DECLARE	@DEFINED_RIGHT_RESULT_ID int;
DECLARE	@USER_GROUP_RESULT_ID int;
DECLARE	@GROUP_RIGHT_RESULT_ID int;


----------------------------------------
-- Step 2)  Create the DEFINED_RIGHT table entry
----------------------------------------
exec [dbo].[DEFINED_RIGHT_QUALIFY_INSERT]
	 @DEFINED_RIGHT_ID =				@DEFINED_RIGHT_ID
	,@DEFINED_RIGHT_NAME =				@DEFINED_RIGHT_NAME
	,@DEFINED_RIGHT_DEFINITION =		@DEFINED_RIGHT_DEFINITION
	,@DEFINED_RIGHT_CREATING_USER_ID =	@CREATING_USER_ID
	,@DEFINED_RIGHT_RESULT_ID =			@DEFINED_RIGHT_RESULT_ID OUTPUT;

--PRINT('DRTI_ID = ' + CAST(@DEFINED_RIGHT_RESULT_ID as VARCHAR(32)));


----------------------------------------
-- Step 3)  Create the associated USER_GROUP and GROUP_RIGHTS table entries
----------------------------------------
exec [dbo].[LINK_DEFINED_RIGHT_TO_USER_GROUP_NAME_AND_GROUP_RIGHTS_QUALIFY_INSERT]
	 @DEFINED_RIGHT_ID =	@DEFINED_RIGHT_RESULT_ID
	,@USER_GROUP_NAME =		@USER_GROUP_NAME
	,@CREATING_USER_ID =	@CREATING_USER_ID
	,@USER_GROUP_ID =		@USER_GROUP_RESULT_ID OUTPUT
	,@GROUP_RIGHTS_ID =		@GROUP_RIGHT_RESULT_ID OUTPUT

--PRINT('LDRTUGNAGRTI_UG_ID = ' + CAST(@USER_GROUP_RESULT_ID as VARCHAR(32)));
--PRINT('LDRTUGNAGRTI_GR_ID = ' + CAST(@GROUP_RIGHT_RESULT_ID as VARCHAR(32)));

-- End of 01) DACS-3368 - Script adds 'Use ImageViewer Rev2' Defined Right and related User Group and Group Rights.SQL
GO

-- Start of 01) DACS-3225 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = HCPR27.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3225 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = HCPR27.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = 'HCPR27';
	DECLARE @Dos DATETIME = '01-01-2024'

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
				 'HCPR27'
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'HCPR27 : Point-of-Care Ultrasound: Evaluation for Pneumothorax after Central Venous Catheter (CVC) Placement : Percentage of patients aged 18 years and older who undergo central venous catheter (CVC) insertion for whom Point-of-Care Ultrasound was performed to evaluate for pneumothorax. '	
				,'B'
				,18
				,999
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'HCPR27' -- = 213
*/
-- End of 01) DACS-3225 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = HCPR27.SQL
GO

-- Start of 02) DACS-3225 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = HCPR27.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3225 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = HCPR27.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'HCPR27';
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
		PRINT('No Measure loaded for HCPR27.  Cannot continue.');
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
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
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)
 		 (@MeasureId,'DG1P1','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99292',NULL,@Dos,NULL)

		-- Undergone CVC insertion (limited to internal jugular or subclavian lines) (CPT Codes)
		,(@MeasureId,'DG1P2','36555',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36556',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36557',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36558',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36560',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36561',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36563',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36565',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36566',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36568',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36569',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36570',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36571',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36572',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36573',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36578',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36580',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36581',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36582',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36583',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36584',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36585',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93503',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93594',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93595',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93596',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93597',NULL,@Dos,NULL)
 		
		-- measure code numerators
		,(@MeasureId,'HCPCS','VH273',NULL,@Dos,'Performance Met:  Point-of-Care Ultrasound evaluation for Pneumothorax performed. ')
		,(@MeasureId,'HCPCS','VH275',NULL,@Dos,'Performance Not Met: Point-of-Care Ultrasound evaluation for pneumothorax not performed. ')
		,(@MeasureId,'HCPCS','VH274',NULL,@Dos,'Denominator Exception:  Documented medical reason for not performing Point-of-Care Ultrasound (e.g. no ultrasound machine available, patient refusal) ')
		,(@MeasureId,'HCPCS','V0704',NULL,@Dos,'Denominator EXCLUSION: Transferred, eloped, AMA, or expired patients are excluded ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Was a CVC Insertion was performed on internal jugular or subclavian veins (Pseudo Code): HCPR2701? ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 47 total inserts
		
		
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
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
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'HCPR27' -- = 213
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 213
*/
-- End of 02) DACS-3225 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = HCPR27.SQL
GO

-- Start of 03) DACS-3225 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3225 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('1','7','8','9') OR [LOCATION_OF_SERVICE] IN ('02','21','23'))
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
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
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

	-- do we have a Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Undergone CVC insertion (limited to internal jugular or subclavian lines) (CPT Codes)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Undergone CVC insertion (limited to internal jugular or subclavian lines) (CPT Codes))', 'Code' = 'ERR-3-NPE';
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'HCPR27' -- = ???

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27
	@ChartId = 2100111832
	,@PqrsNum = 'HCPR27'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/
-- End of 03) DACS-3225 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27].SQL
GO

-- Start of 04) DACS-3225 - Create of Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3225 - Create of Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL
------------------------------------------------------------------------------------
GO

GO

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
		PRINT('==> @Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
		
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
			AND EFFECTIVE_DATE <= @Dos
			AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE >= @Dos)
		);

	PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );
	
	EXEC SelectCmsPqrsMeasureResultsListById @MeasureId=@MeasureId, @Dos=@Dos;

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '76'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 201
exec [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] @PqrsNum = 'THEPQR4'; 
exec [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] @PqrsNum = 'HCPR27';
exec [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] @PqrsNum = '76'; 
exec [dbo].[SelectCmsPqrsMeasureResultsListById] @MeasureId = 201; -- 51 is the old id
201	76	MIPS CLINICAL QUALITY MEASURES (CQMS)	PQRS# 76 Prevention of Central Venous Catheter (CVC): Related Bloodstream Infections	B	0	999	2024-01-01	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
begin tran; -- testing
*/
-- End of 04) DACS-3225 - Create of Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL
GO

-- Start of 11) DACS-3230 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR4.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3230 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR4.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR4';
	DECLARE @Dos DATETIME = '01-01-2024'

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
				 'THEPQR4'
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'THEPQR4 : Consultation to Palliative Care for Patients with End Stage Conditions : The measure will identify patients with end stage diagnoses who meet any of the listed criteria for a palliative care consult. '	
				,'B'
				,18
				,999
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR4' -- = 212
*/
-- End of 11) DACS-3230 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR4.SQL
GO

-- Start of 12) DACS-3230 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR4.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3230 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR4.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR4';
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
		PRINT('No Measure loaded for THEPQR4.  Cannot continue.');
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
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
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators - TBD.  For now, use a question instead.
		-- (@MeasureId,'DG1P1','I11.0',NULL,@Dos,NULL)

		 (@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
 		
		-- measure code numerators
		,(@MeasureId,'HCPCS','QR309',NULL,@Dos,'Performance Met:  Patient received order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service ')
		,(@MeasureId,'HCPCS','QR310',NULL,@Dos,'Performance Not Met:  Patient did not receive an order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service ')
		,(@MeasureId,'HCPCS','QR308',NULL,@Dos,'Denominator Exception: <p><ul><li>Patient or medical decision maker refusal.</li><li>Documented medical reason for exclusion (example: palliative care not appropriate).</li><li>Palliative care not available, or system issue preventing palliative care consult.</li></ul></p> ')
		,(@MeasureId,'HCPCS','QR307',NULL,@Dos,'Denominator EXCLUSION: <p><ul><li>Patient on hospice, or discharged to hospice.</li><li>Eloped or left AMA.</li><li>Expired</li><li>Comfort measures documented (Documented code status of DNR-A)</li><li>Transferred to another hospital</li><li>Patient admission to psychiatric or behavioral care</li></ul></p>')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Patient has any of the following? <p><ul><li>Cancer</li><li>Stroke or TIA</li><li>Chronic obstructive pulmonary disease (COPD)</li><li>Neurodegenerative Disease</li><li>Congestive Heart Failure (CHF)</li><li>Kidney Failure (ESRD)</li></ul></p> ')
		,(@MeasureId,'DQ411','00002',NULL,@Dos,'Patient has any of the following? <p><ul><li>2+ same diag ED or hospitalizations in 12 months (PQR301)</li><li>Chronic oxygen, or Vent (PQR302)</li><li>Hospital Admit from LTC Fac (PQR303)</li><li>Stage 4/Metastatic cancer (PQR304)</li><li>Difficult to control phys symptoms (PQR305)</li><li>Complex care requirements (PQR306): <ul><li>Home infusion</li><li>Tube feeding</li><li>mechanical Vent</li><li>24hr Bedbound care</li></ul></li><li>(SDOH) (ICD10): Z55, Z56, Z59, Z60, Z64, Z65</li></ul></p>')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 26 total inserts
		
		
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
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
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR4' -- = 212
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 212
*/
-- End of 12) DACS-3230 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR4.SQL
GO

-- Start of 13) DACS-3230 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3230 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('1','2','3','6','7','8','9','11','12','13') OR [LOCATION_OF_SERVICE] IN ('21','22','23','31','32','33'))
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
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	--DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'); -- TBD for now using a question
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	-- IF @foundDenominatorGroup1Pick1MatchCount <= 0
	-- BEGIN
		-- PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		-- RETURN;
	-- END;

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

	-- do we have a Diagnosis in our inclusive diagnosis listing?
	-- TBD for now using a question
	-- SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	-- IF @foundDenominatorGroup1Pick1MatchCount <= 0
	-- BEGIN 
		-- PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		-- RETURN;
	-- END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR4' -- = 212

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4
	@ChartId = 2100111832
	,@PqrsNum = 'THEPQR4'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/
-- End of 13) DACS-3230 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
GO

-- Start of 14) DACS-3230 - Alter Procedure - [dbo].[Maintenance_SelectChartAccessUserProfilesInPast45DaysByChartId].SQL

----------------------------------------------------------------------------------------
-- 04) DACS-3230 - Alter Procedure - [dbo].[Maintenance_SelectChartAccessUserProfilesInPast45DaysByChartId].SQL
----------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROC [dbo].[Maintenance_SelectChartAccessUserProfilesInPast45DaysByChartId]  
	@chartId Int
AS  
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DROP TABLE IF EXISTS #TmpResultsMSCAUPIP45DC;

	SELECT DISTINCT TOP 10 
		[USER_PROFILE_ID]
		, [SIGN_ON_ID] = cast(null as varchar(100))
	INTO 
		#TmpResultsMSCAUPIP45DC
	FROM 
		[dbo].[CHART_ACCESS]
	WHERE
		[CHART_ID] = @chartId
		AND DATEDIFF(day,[ACCESS_DATE_TIME],GETDATE()) BETWEEN 0 AND 45;

	IF (SELECT COUNT(*) FROM #TmpResultsMSCAUPIP45DC) <= 0
	BEGIN
		PRINT ('no data');
		RETURN
	END;

	UPDATE #TmpResultsMSCAUPIP45DC
		SET SIGN_ON_ID = u.SIGN_ON_ID
	FROM
		[USER_PROFILE] as u
		JOIN #TmpResultsMSCAUPIP45DC as t ON t.[USER_PROFILE_ID] = u.[USER_PROFILE_ID];
		
	SELECT
		*
	FROM
		#TmpResultsMSCAUPIP45DC;

GO

/*
Testing:
-- exec [dbo].[Maintenance_SelectChartAccessUserProfilesInPast45DaysByChartId] @chartId=2100111810
select DISTINCT top 10 USER_PROFILE_ID from chart_Access where chart_id = 2100111810
*/



-- End of 14) DACS-3230 - Alter Procedure - [dbo].[Maintenance_SelectChartAccessUserProfilesInPast45DaysByChartId].SQL
GO

-- Start of 15) DACS-3230 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureByMeasureId].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3230 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureByMeasureId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriMeasureByMeasureId] 
	@measureId INT
WITH EXEC AS CALLER AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	------------------------------------------------------
	/*
	 replaces inline SQL from Load(...) of "\CCSBusinessObjects\DAO\CMSRules\CMSPQRIMeasureDAO.cs" within ACS project
			sql = "SELECT " + m_Fields sdsdsdsfsdfffdsfds
               + "FROM CMS_PQRI_MEASURE WITH (NOLOCK) "
               + "WHERE CMS_PQRI_MEASURE_ID=" + measureID;	*/
	------------------------------------------------------

	SELECT TOP 1
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#]
		, [MEASURE_TOPIC]
		, [MEASURE_TITLE]
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [EFFECTIVE_DATE]
		, [EXPIRATION_DATE]
    FROM 
		[CMS_PQRI_MEASURE]
    WHERE 
		[CMS_PQRI_MEASURE_ID] = @measureId;

	
END -- end procedure

GO

/*
testing:
exec [dbo].[SelectCmsPqriMeasureByMeasureId] @measureId = 11


*/
-- End of 15) DACS-3230 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureByMeasureId].SQL
GO

-- Start of 16) DACS-3230 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasures].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3230 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasures].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriMeasures] 
WITH EXEC AS CALLER AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	------------------------------------------------------
	/*
	 replaces inline SQL from LoadAllForED(...) of "\CCSBusinessObjects\DAO\CMSRules\\CMSPQRIMeasureDAO.cs" within ACS project
	  original const string sql = "select " + m_Fields
           + "from CMS_PQRI_MEASURE WITH (NOLOCK) "
		   //+ "where @ActiveOnly=0 or dateadd(day, datediff(day, 0, getdate()), 0) between EFFECTIVE_DATE and isnull(EXPIRATION_DATE, getdate())"
		   + "order by PQRS#";  
	*/
	------------------------------------------------------

		
    SELECT
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#]
		, [MEASURE_TOPIC]
		, [MEASURE_TITLE]
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [EFFECTIVE_DATE]
		, [EXPIRATION_DATE]
	
    FROM
		[CMS_PQRI_MEASURE]
	ORDER BY 
		[PQRS#];

	
END -- end procedure

GO

/*
testing:
exec [dbo].[SelectCmsPqriMeasures] 

*/
-- End of 16) DACS-3230 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasures].SQL
GO

-- Start of 01) DACS-3362 Drop Denial Tables.sql

----------------------------------------
-- 01) DACS-3362 - SQL Script will remove Denial tables from DB as Denial is completely removed from ACS
----------------------------------------
GO

BEGIN TRY

    DROP TABLE [dbo].[DENIAL_DOCUMENT_TYPE]
    DROP TABLE [dbo].[DENIAL_INSURANCE_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_LOG_NOTE]
    DROP TABLE [dbo].[DENIAL_LOG_NOTE_CATEGORY]
    DROP TABLE [dbo].[DENIAL_OUTCOME_ANALYZER_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE]
    DROP TABLE [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_PAYOR_CATEGORY]
    DROP TABLE [dbo].[DENIAL_PAYOR_DETERMINATION_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_REASON_CATEGORY_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]
    DROP TABLE [dbo].[DENIAL_REASON_GROUP_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]
    DROP TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER]
    DROP TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]
    DROP TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]
    DROP TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]
    DROP TABLE [dbo].[DENIAL_CLAIM_PROCEDURE]
    DROP TABLE [dbo].[DENIAL_REVENUE_CODE]
    DROP TABLE [dbo].[DENIAL_REVENUE_CODE_CATEGORY]
    DROP TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_REASON_CODE] -- foreign key
    DROP TABLE [dbo].[DENIAL_REMIT_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_PAYOR]
    DROP TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]
    DROP TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]
    DROP TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE]
    DROP TABLE [dbo].[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_ACTION_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_COMMENT]
    DROP TABLE [dbo].[DENIAL_CLAIM_COMMENT_TYPE]
    DROP TABLE [dbo].[DENIAL_CLAIM_DOCUMENT]
    DROP TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]
    DROP TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_FORM_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE]
    DROP TABLE [dbo].[DENIAL_CLAIM_OUTCOME]
    DROP TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION]
    DROP TABLE [dbo].[DENIAL_CLAIM_PATIENT]
    DROP TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_STATUS_HISTORY]
    DROP TABLE [dbo].[DENIAL_CLAIM_STATUS_REASON_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM_STATUS_TYPE_CODE]
    DROP TABLE [dbo].[DENIAL_CLAIM]
    DROP TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON]
    DROP TABLE [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]
    DROP TABLE [dbo].[DENIAL_SERVICE_LOCATION]
    DROP TABLE [dbo].[DENIAL_SERVICE_PLACE]
    DROP TABLE [dbo].[DENIAL_TYPE_CODE]
    DROP TABLE [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER]
    DROP TABLE [dbo].[GLOBAL_CPT_CODE]
    DROP TABLE [dbo].[GLOBAL_HCPCS_CODE]    
    DROP TABLE [dbo].[GLOBAL_PROCEDURE_CODE_TYPE_CODE]
    DROP TABLE [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER]
	DROP TABLE [dbo].[GLOBAL_MODIFIER]
    
	COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
-- End of 01) DACS-3362 Drop Denial Tables.sql
GO

-- Start of 02) DACS-3362 Table Rollback Scripts.sql

----------------------------------------
-- 02) DACS-3362 - SQL Script will rollback all denial tables removed as part of script 01) DACS-3362 Drop Denial Tables.sql (Only Schema, indexes and triggers)
----------------------------------------
GO

GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM](
	[DENIAL_CLAIM_ID] [int] IDENTITY(1,1) NOT NULL,
	[FACILITY_ID] [int] NOT NULL,
	[SERVICE_AGREEMENT_ID] [int] NOT NULL,
	[FACILITY_CHART_IDENTIFIER] [varchar](20) NULL,
	[BILLING_ACCOUNT_IDENTIFIER] [varchar](20) NULL,
	[CLAIM_NUMBER] [varchar](50) NOT NULL,
	[ASSIGNED_TO_USER_PROFILE_ID] [int] NULL,
	[DENIAL_CLAIM_FORM_TYPE_CODE] [tinyint] NOT NULL,
	[DENIAL_CLAIM_STATUS_TYPE_CODE] [tinyint] NOT NULL,
	[DENIAL_CLAIM_STATUS_CHANGE_DATE_TIME] [datetime] NOT NULL,
	[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_ID] [int] NULL,
	[DENIAL_CLAIM_ACTION_TYPE_CODE] [tinyint] NULL,
	[DENIAL_TYPE_CODE] [tinyint] NULL,
	[IS_PRIORITY] [bit] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[DENIAL_DATE_TIME] [datetime] NOT NULL,
	[DENIAL_SERVICE_LOCATION_ID] [int] NULL,
	[DENIAL_SERVICE_PLACE_ID] [int] NULL,
	[RECEIVED_DATE_TIME] [datetime] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[FOLLOW_UP_DATE_TIME] [datetime] NULL,
	[ENCOUNTER_NUMBER] [varchar](255) NULL,
	[DATE_OF_SERVICE_START] [datetime] NULL,
	[DATE_OF_SERVICE_END] [datetime] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_ID] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_FACILITY_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]') AND name = N'IX_DENIAL_CLAIM_FACILITY_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_FACILITY_ID] ON [dbo].[DENIAL_CLAIM]
(
	[FACILITY_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE](
	[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_ACTION_REASON_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_ACTION_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_ACTION_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_ACTION_TYPE_CODE](
	[DENIAL_CLAIM_ACTION_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_ACTION_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_ACTION_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_COMMENT]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_COMMENT]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_COMMENT](
	[DENIAL_CLAIM_COMMENT_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[COMMENTS] [varchar](5000) NULL,
	[DENIAL_CLAIM_COMMENT_TYPE_ID] [int] NULL,
	[CREATION_DATE_TIME] [datetime] NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_COMMENT] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_COMMENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_COMMENT_TYPE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_COMMENT_TYPE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_COMMENT_TYPE](
	[DENIAL_CLAIM_COMMENT_TYPE_ID] [int] NOT NULL,
	[DESCRIPTION] [varchar](100) NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_COMMENT_TYPE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_COMMENT_TYPE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_DOCUMENT]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_DOCUMENT]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_DOCUMENT](
	[DENIAL_CLAIM_DOCUMENT_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[DENIAL_DOCUMENT_TYPE_ID] [int] NOT NULL,
	[DOCUMENT_COMMENTS] [varchar](5000) NULL,
	[DOCUMENT_DATE_RECEIVED] [datetime] NOT NULL,
	[MIME_TYPE] [varchar](100) NOT NULL,
	[FILE_SYSTEM_FILE_NAME] [varchar](256) NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_DOCUMENT] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_DOCUMENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_DOCUMENT_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_DOCUMENT]') AND name = N'IX_DENIAL_CLAIM_DOCUMENT_DENIAL_CLAIM_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_DOCUMENT_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_DOCUMENT]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL](
	[DENIAL_CLAIM_FACILITY_PROFESSIONAL_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[FACILITY_PROFESSIONAL_ID] [int] NOT NULL,
	[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE] [tinyint] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_FACILITY_PROFESSIONAL] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_FACILITY_PROFESSIONAL_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_FACILITY_PROFESSIONAL_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]') AND name = N'IX_DENIAL_CLAIM_FACILITY_PROFESSIONAL_DENIAL_CLAIM_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_FACILITY_PROFESSIONAL_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE](
	[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_FACILITY_PROFESSIONAL_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_FORM_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FORM_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_FORM_TYPE_CODE](
	[DENIAL_CLAIM_FORM_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NOT NULL,
	[EXTERNAL_CODE] [varchar](120) NOT NULL,
	[DESCRIPTION] [varchar](500) NOT NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_FORM_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_FORM_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE](
	[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[ICD10_CODE] [varchar](10) NOT NULL,
	[IS_PRIMARY] [bit] NOT NULL,
	[IS_PRESENT_ON_ADMISSION] [bit] NOT NULL,
	[IS_INVALID_CODE] [bit] NOT NULL,
	[USER_ACKNOWLEDGED_INVALID_CODE] [bit] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[ORDINAL] [int] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[IS_CHIEF_COMPLAINT] [bit] NOT NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE]') AND name = N'IX_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_DENIAL_CLAIM_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_OUTCOME]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_OUTCOME](
	[DENIAL_CLAIM_OUTCOME_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[DENIAL_OUTCOME_ANALYZER_TYPE_CODE] [tinyint] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID] [int] NULL,
	[FOLLOW_UP_DATE_TIME] [datetime] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_OUTCOME] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_OUTCOME_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_OUTCOME_NOTE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME_NOTE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE](
	[DENIAL_CLAIM_OUTCOME_NOTE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_OUTCOME_ID] [int] NOT NULL,
	[OBJECT_TYPE] [varchar](100) NOT NULL,
	[EVENT_NAME] [varchar](100) NULL,
	[NOTE] [varchar](max) NOT NULL,
	[IS_SYSTEM_GENERATED] [bit] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[USER_PROFILE_ID] [int] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_OUTCOME_NOTE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_OUTCOME_NOTE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1] TEXTIMAGE_ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_OUTCOME_NOTE_DENIAL_CLAIM_OUTCOME_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME_NOTE]') AND name = N'IX_DENIAL_CLAIM_OUTCOME_NOTE_DENIAL_CLAIM_OUTCOME_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_OUTCOME_NOTE_DENIAL_CLAIM_OUTCOME_ID] ON [dbo].[DENIAL_CLAIM_OUTCOME_NOTE]
(
	[DENIAL_CLAIM_OUTCOME_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PATIENT]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PATIENT](
	[DENIAL_CLAIM_PATIENT_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[FIRST_NAME] [varchar](35) NOT NULL,
	[MIDDLE_NAME] [varchar](35) NULL,
	[LAST_NAME] [varchar](35) NOT NULL,
	[SUFFIX] [varchar](10) NULL,
	[DATE_OF_BIRTH] [datetime] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PATIENT] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_PATIENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PATIENT_CONDITION]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT_CONDITION]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION](
	[DENIAL_CLAIM_PATIENT_CONDITION_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[DENIAL_CLAIM_PATIENT_ID] [int] NOT NULL,
	[IS_EMPLOYMENT_ACCIDENT] [bit] NOT NULL,
	[IS_AUTO_ACCIDENT] [bit] NOT NULL,
	[IS_OTHER_ACCIDENT] [bit] NOT NULL,
	[CONDITION_DATE_TIME] [datetime] NULL,
	[STATE] [varchar](2) NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PATIENT_CONDITION] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_PATIENT_CONDITION_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PAYOR]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PAYOR]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PAYOR](
	[DENIAL_CLAIM_PAYOR_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[DENIAL_INSURANCE_TYPE_CODE] [tinyint] NOT NULL,
	[DENIAL_SERVICE_AGREEMENT_PAYOR_ID] [int] NOT NULL,
	[INSURANCE_IDENTIFIER] [varchar](100) NOT NULL,
	[INSURANCE_GROUP_NUMBER] [varchar](100) NULL,
	[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE] [tinyint] NULL,
	[POLICY_HOLDER_FIRST_NAME] [varchar](35) NULL,
	[POLICY_HOLDER_LAST_NAME] [varchar](35) NULL,
	[POLICY_HOLDER_DATE_OF_BIRTH] [datetime] NULL,
	[AUTHORIZATION_NUMBER] [varchar](100) NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[PAYOR_CLAIM_NUMBER] [varchar](255) NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PAYOR] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_PAYOR_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PROCEDURE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PROCEDURE](
	[DENIAL_CLAIM_PROCEDURE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[DATE_OF_SERVICE_START] [datetime] NOT NULL,
	[DATE_OF_SERVICE_END] [datetime] NOT NULL,
	[DENIAL_REVENUE_CODE_ID] [int] NULL,
	[GLOBAL_PROCEDURE_CODE_TYPE_CODE] [tinyint] NULL,
	[GLOBAL_PROCEDURE_CODE_ID] [int] NULL,
	[CHARGE_AMOUNT] [money] NOT NULL,
	[UNITS] [int] NOT NULL,
	[PAYMENT_AMOUNT] [money] NOT NULL,
	[WRITE_OFF_AMOUNT] [money] NULL,
	[ALLOWED_AMOUNT] [money] NULL,
	[DENIAL_CLAIM_ACTION_TYPE_CODE] [tinyint] NULL,
	[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE] [tinyint] NULL,
	[DENIAL_PAYOR_DETERMINATION_TYPE_CODE] [tinyint] NULL,
	[PAYOR_DETERMINATION_RECEIVED_DATETIME] [datetime] NULL,
	[FOLLOW_UP_DATETIME] [datetime] NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[PAID_GLOBAL_PROCEDURE_CODE_TYPE_CODE] [tinyint] NULL,
	[PAID_GLOBAL_PROCEDURE_CODE_ID] [int] NULL,
	[LEVEL_1_DENIAL_PAYOR_DETERMINATION_TYPE_CODE] [tinyint] NULL,
	[LEVEL_1_PAYOR_DETERMINATION_DATE_TIME] [datetime] NULL,
	[LEVEL_1_TICKET_NUMBER] [varchar](255) NULL,
	[LEVEL_2_DENIAL_PAYOR_DETERMINATION_TYPE_CODE] [tinyint] NULL,
	[LEVEL_2_PAYOR_DETERMINATION_DATE_TIME] [datetime] NULL,
	[LEVEL_2_TICKET_NUMBER] [varchar](255) NULL,
	[PATIENT_RESPONSIBILITY_AMOUNT] [money] NOT NULL,
	[INITIAL_PAYMENT_AMOUNT] [money] NULL,
	[IS_WRITE_OFF_AMOUNT_UNKNOWN] [bit] NOT NULL,
	[IS_ALLOWED_AMOUNT_UNKNOWN] [bit] NOT NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PROCEDURE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_DENIAL_CLAIM_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE](
	[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_ID] [int] NOT NULL,
	[ICD10_CODE] [varchar](10) NOT NULL,
	[IS_PRIMARY] [bit] NOT NULL,
	[ORDINAL] [int] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_DENIAL_CLAIM_PROCEDURE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_DENIAL_CLAIM_PROCEDURE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_DENIAL_CLAIM_PROCEDURE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE]
(
	[DENIAL_CLAIM_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION](
	[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID] [int] NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_REVISION_ID] [int] NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_ID] [int] NOT NULL,
	[ICD10_CODE] [varchar](10) NOT NULL,
	[IS_PRIMARY] [bit] NOT NULL,
	[ORDINAL] [int] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[REVISION_DATE_TIME] [datetime] NOT NULL,
	[REVISION_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION](
	[DENIAL_CLAIM_PROCEDURE_REVISION_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_ID] [int] NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[DATE_OF_SERVICE_START] [datetime] NOT NULL,
	[DATE_OF_SERVICE_END] [datetime] NOT NULL,
	[DENIAL_REVENUE_CODE_ID] [int] NULL,
	[GLOBAL_PROCEDURE_CODE_TYPE_CODE] [tinyint] NULL,
	[GLOBAL_PROCEDURE_CODE_ID] [int] NULL,
	[CHARGE_AMOUNT] [money] NOT NULL,
	[UNITS] [int] NOT NULL,
	[PAYMENT_AMOUNT] [money] NOT NULL,
	[WRITE_OFF_AMOUNT] [money] NULL,
	[ALLOWED_AMOUNT] [money] NULL,
	[DENIAL_CLAIM_ACTION_TYPE_CODE] [tinyint] NULL,
	[DENIAL_CLAIM_ACTION_REASON_TYPE_CODE] [tinyint] NULL,
	[DENIAL_PAYOR_DETERMINATION_TYPE_CODE] [tinyint] NULL,
	[PAYOR_DETERMINATION_RECEIVED_DATETIME] [datetime] NULL,
	[FOLLOW_UP_DATETIME] [datetime] NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[REVISION_DATE_TIME] [datetime] NOT NULL,
	[REVISION_USER_PROFILE_ID] [int] NULL,
	[PAID_GLOBAL_PROCEDURE_CODE_TYPE_CODE] [tinyint] NULL,
	[PAID_GLOBAL_PROCEDURE_CODE_ID] [int] NULL,
	[LEVEL_1_DENIAL_PAYOR_DETERMINATION_TYPE_CODE] [tinyint] NULL,
	[LEVEL_1_PAYOR_DETERMINATION_DATE_TIME] [datetime] NULL,
	[LEVEL_1_TICKET_NUMBER] [varchar](255) NULL,
	[LEVEL_2_DENIAL_PAYOR_DETERMINATION_TYPE_CODE] [tinyint] NULL,
	[LEVEL_2_PAYOR_DETERMINATION_DATE_TIME] [datetime] NULL,
	[LEVEL_2_TICKET_NUMBER] [varchar](255) NULL,
	[PATIENT_RESPONSIBILITY_AMOUNT] [money] NOT NULL,
	[INITIAL_PAYMENT_AMOUNT] [money] NULL,
	[IS_WRITE_OFF_AMOUNT_UNKNOWN] [bit] NOT NULL,
	[IS_ALLOWED_AMOUNT_UNKNOWN] [bit] NOT NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PROCEDURE_REVISION] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_PROCEDURE_REVISION_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_PROCEDURE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_PROCEDURE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_PROCEDURE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE](
	[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_ID] [int] NOT NULL,
	[DENIAL_REASON_CODE_ID] [int] NOT NULL,
	[DENIAL_REASON_GROUP_TYPE_CODE] [tinyint] NULL,
	[DENIAL_REMIT_CODE_ID] [int] NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_DENIAL_CLAIM_PROCEDURE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_DENIAL_CLAIM_PROCEDURE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_DENIAL_CLAIM_PROCEDURE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]
(
	[DENIAL_CLAIM_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION](
	[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID] [int] NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_REVISION_ID] [int] NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_ID] [int] NOT NULL,
	[DENIAL_REASON_CODE_ID] [int] NOT NULL,
	[DENIAL_REASON_GROUP_TYPE_CODE] [tinyint] NULL,
	[DENIAL_REMIT_CODE_ID] [int] NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[REVISION_DATE_TIME] [datetime] NOT NULL,
	[REVISION_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER](
	[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_ID] [int] NOT NULL,
	[GLOBAL_MODIFIER_ID] [int] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_DENIAL_CLAIM_PROCEDURE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_DENIAL_CLAIM_PROCEDURE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_DENIAL_CLAIM_PROCEDURE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER]
(
	[DENIAL_CLAIM_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION](
	[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID] [int] NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_REVISION_ID] [int] NOT NULL,
	[DENIAL_CLAIM_PROCEDURE_ID] [int] NOT NULL,
	[GLOBAL_MODIFIER_ID] [int] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[REVISION_DATE_TIME] [datetime] NOT NULL,
	[REVISION_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE](
	[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[ICD10_CODE] [varchar](10) NOT NULL,
	[IS_PRIMARY] [bit] NOT NULL,
	[IS_PRESENT_ON_ADMISSION] [bit] NOT NULL,
	[IS_INVALID_CODE] [bit] NOT NULL,
	[USER_ACKNOWLEDGED_INVALID_CODE] [bit] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[ORDINAL] [int] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[IS_CHIEF_COMPLAINT] [bit] NOT NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE]') AND name = N'IX_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_DENIAL_CLAIM_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_STATUS_HISTORY]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_STATUS_HISTORY]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_STATUS_HISTORY](
	[DENIAL_CLAIM_STATUS_HISTORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NOT NULL,
	[DENIAL_CLAIM_STATUS_TYPE_CODE] [tinyint] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_STATUS_HISTORY] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_STATUS_HISTORY_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_STATUS_REASON_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_STATUS_REASON_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_STATUS_REASON_TYPE_CODE](
	[DENIAL_CLAIM_STATUS_REASON_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_STATUS_REASON_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_STATUS_REASON_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_CLAIM_STATUS_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_STATUS_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_CLAIM_STATUS_TYPE_CODE](
	[DENIAL_CLAIM_STATUS_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NOT NULL,
	[EXTERNAL_CODE] [varchar](120) NOT NULL,
	[DESCRIPTION] [varchar](500) NOT NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_STATUS_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_CLAIM_STATUS_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_DOCUMENT_TYPE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_DOCUMENT_TYPE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_DOCUMENT_TYPE](
	[DENIAL_DOCUMENT_TYPE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_DOCUMENT_CATEGORY_TYPE_CODE] [tinyint] NOT NULL,
	[NAME] [varchar](200) NOT NULL,
	[AUTO_MOVE_TO_DENIAL_CLAIM_STATUS_TYPE_CODE] [tinyint] NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_DOCUMENT_TYPE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_DOCUMENT_TYPE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_DOCUMENT_TYPE_DENIAL_DOCUMENT_CATEGORY_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_DOCUMENT_TYPE]') AND name = N'IX_DENIAL_DOCUMENT_TYPE_DENIAL_DOCUMENT_CATEGORY_TYPE_CODE')
CREATE CLUSTERED INDEX [IX_DENIAL_DOCUMENT_TYPE_DENIAL_DOCUMENT_CATEGORY_TYPE_CODE] ON [dbo].[DENIAL_DOCUMENT_TYPE]
(
	[DENIAL_DOCUMENT_CATEGORY_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_INSURANCE_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_INSURANCE_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_INSURANCE_TYPE_CODE](
	[DENIAL_INSURANCE_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_INSURANCE_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_INSURANCE_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_LOG_NOTE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_LOG_NOTE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_LOG_NOTE](
	[DENIAL_LOG_NOTE_ID] [int] IDENTITY(44000000,1) NOT NULL,
	[DENIAL_CLAIM_ID] [int] NULL,
	[SUMMARY] [varchar](256) NULL,
	[DETAIL] [varchar](2000) NULL,
	[ACTION_DATE] [datetime] NULL,
	[ACTION_USER_ID] [int] NULL,
	[DENIAL_LOG_NOTE_CATEGORY_ID] [int] NULL,
	[CREATION_DATE_TIME] [datetime] NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_LOG_NOTE_DENIAL_LOG_NOTE_ID] PRIMARY KEY CLUSTERED 
(
	[DENIAL_LOG_NOTE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[DENIAL_LOG_NOTE_CATEGORY]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_LOG_NOTE_CATEGORY]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_LOG_NOTE_CATEGORY](
	[DENIAL_LOG_NOTE_CATEGORY_ID] [int] NOT NULL,
	[DESCRIPTION] [varchar](50) NULL,
	CONSTRAINT [PK_DENIAL_LOG_NOTE_CATEGORY] PRIMARY KEY CLUSTERED 
(
	[DENIAL_LOG_NOTE_CATEGORY_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_OUTCOME_ANALYZER_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_OUTCOME_ANALYZER_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_OUTCOME_ANALYZER_TYPE_CODE](
	[DENIAL_OUTCOME_ANALYZER_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_CLAIM_OUTCOME_ANALYZER_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_OUTCOME_ANALYZER_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE](
	[DENIAL_OUTCOME_NOTE_TEMPLATE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE] [tinyint] NOT NULL,
	[NAME] [varchar](100) NOT NULL,
	[TEMPLATE] [varchar](max) NOT NULL,
	[EXAMPLE] [varchar](max) NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_OUTCOME_NOTE_TEMPLATE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_OUTCOME_NOTE_TEMPLATE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1] TEXTIMAGE_ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_OUTCOME_NOTE_TEMPLATE_DENIAL_OUTCOME_NOTE_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE]') AND name = N'IX_DENIAL_OUTCOME_NOTE_TEMPLATE_DENIAL_OUTCOME_NOTE_TYPE_CODE')
CREATE CLUSTERED INDEX [IX_DENIAL_OUTCOME_NOTE_TEMPLATE_DENIAL_OUTCOME_NOTE_TYPE_CODE] ON [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE]
(
	[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE](
	[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_OUTCOME_NOTE_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_OUTCOME_NOTE_TEMPLATE_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE](
	[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_PATIENT_INSURED_RELATIONSHIP_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_PAYOR_CATEGORY]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_PAYOR_CATEGORY]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_PAYOR_CATEGORY](
	[DENIAL_PAYOR_CATEGORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[DESCRIPTION] [varchar](200) NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_PAYOR_CATEGORY] PRIMARY KEY CLUSTERED 
(
	[DENIAL_PAYOR_CATEGORY_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_PAYOR_DETERMINATION_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_PAYOR_DETERMINATION_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_PAYOR_DETERMINATION_TYPE_CODE](
	[DENIAL_PAYOR_DETERMINATION_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_PAYOR_DETERMINATION_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_PAYOR_DETERMINATION_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_REASON_CATEGORY_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CATEGORY_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_REASON_CATEGORY_TYPE_CODE](
	[DENIAL_REASON_CATEGORY_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NOT NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_REASON_CATEGORY_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_REASON_CATEGORY_TYPE_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_REASON_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_REASON_CODE](
	[DENIAL_REASON_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [varchar](10) NOT NULL,
	[SHORT_DESCRIPTION] [varchar](100) NOT NULL,
	[DESCRIPTION] [varchar](max) NULL,
	[DENIAL_TYPE_CODE] [tinyint] NULL,
	[DENIAL_REASON_CATEGORY_TYPE_CODE] [tinyint] NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_REASON_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1] TEXTIMAGE_ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE](
	[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_REASON_CODE_ID] [int] NOT NULL,
	[DENIAL_REASON_GROUP_TYPE_CODE] [tinyint] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_REASON_CODE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_DENIAL_REASON_CODE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]') AND name = N'IX_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_DENIAL_REASON_CODE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_DENIAL_REASON_CODE_ID] ON [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]
(
	[DENIAL_REASON_CODE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE](
	[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_REASON_CODE_ID] [int] NOT NULL,
	[DENIAL_REMIT_CODE_ID] [int] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REASON_CODE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]') AND name = N'IX_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REASON_CODE_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REASON_CODE_ID] ON [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]
(
	[DENIAL_REASON_CODE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_REASON_GROUP_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_GROUP_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_REASON_GROUP_TYPE_CODE](
	[DENIAL_REASON_GROUP_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NOT NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_REASON_GROUP_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_REASON_GROUP_TYPE_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_REMIT_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REMIT_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_REMIT_CODE](
	[DENIAL_REMIT_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [varchar](5) NOT NULL,
	[SHORT_DESCRIPTION] [varchar](500) NULL,
	[DESCRIPTION] [varchar](max) NOT NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_REMIT_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_REMIT_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1] TEXTIMAGE_ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_REVENUE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_REVENUE_CODE](
	[DENIAL_REVENUE_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_REVENUE_CODE_CATEGORY_ID] [int] NOT NULL,
	[CODE] [nvarchar](10) NOT NULL,
	[DESCRIPTION] [nvarchar](200) NOT NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_REVENUE_CODE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_REVENUE_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_REVENUE_CODE_DENIAL_REVENUE_CODE_CATEGORY_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE]') AND name = N'IX_DENIAL_REVENUE_CODE_DENIAL_REVENUE_CODE_CATEGORY_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_REVENUE_CODE_DENIAL_REVENUE_CODE_CATEGORY_ID] ON [dbo].[DENIAL_REVENUE_CODE]
(
	[DENIAL_REVENUE_CODE_CATEGORY_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_REVENUE_CODE_CATEGORY]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE_CATEGORY]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_REVENUE_CODE_CATEGORY](
	[DENIAL_REVENUE_CODE_CATEGORY_ID] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [nvarchar](10) NOT NULL,
	[DESCRIPTION] [nvarchar](200) NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_REVENUE_CODE_CATEGORY] PRIMARY KEY CLUSTERED 
(
	[DENIAL_REVENUE_CODE_CATEGORY_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR](
	[DENIAL_SERVICE_AGREEMENT_PAYOR_ID] [int] IDENTITY(1,1) NOT NULL,
	[SERVICE_AGREEMENT_ID] [int] NOT NULL,
	[FACILITY_PAYOR_ID] [varchar](50) NULL,
	[FACILITY_PAYOR_NAME] [varchar](100) NOT NULL,
	[ADDRESS_LINE_1] [varchar](35) NULL,
	[ADDRESS_LINE_2] [varchar](35) NULL,
	[CITY] [varchar](25) NULL,
	[STATE] [varchar](2) NULL,
	[POSTAL_CODE] [varchar](50) NULL,
	[PHONE_AREA_CODE] [varchar](3) NULL,
	[PHONE_NUMBER] [varchar](7) NULL,
	[PHONE_EXT] [varchar](5) NULL,
	[WEBSITE_URL] [varchar](50) NULL,
	[DENIAL_PAYOR_CATEGORY_ID] [int] NULL,
	[LEVEL_1_APPEAL_DAYS] [int] NULL,
	[LEVEL_2_APPEAL_DAYS] [int] NULL,
	[LEVEL_3_APPEAL_DAYS] [int] NULL,
	[TIMELY_FILING_DAYS] [int] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	CONSTRAINT [PK_DENIAL_SERVICE_AGREEMENT_PAYOR] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_SERVICE_AGREEMENT_PAYOR_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_PAYOR_SERVICE_AGREEMENT_SERVICE_AGREEMENT_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]') AND name = N'IX_DENIAL_PAYOR_SERVICE_AGREEMENT_SERVICE_AGREEMENT_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_PAYOR_SERVICE_AGREEMENT_SERVICE_AGREEMENT_ID] ON [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]
(
	[SERVICE_AGREEMENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT](
	[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_SERVICE_AGREEMENT_PAYOR_ID] [int] NOT NULL,
	[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_ID] [int] NOT NULL,
	[SERVICE_AGREEMENT_ID] [int] NULL,
	[DENIAL_PAYOR_DOCUMENT_DESCRIPTION] [varchar](256) NULL,
	[MIME_TYPE] [varchar](35) NULL,
	[COMMENT] [varchar](1000) NULL,
	[FILE_SYSTEM_FILE_NAME] [varchar](256) NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_PAYOR_DOCUMENT_DESCRIPTION] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_DENIAL_SERVICE_AGREEMENT_PAYOR_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]') AND name = N'IX_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_DENIAL_SERVICE_AGREEMENT_PAYOR_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_DENIAL_SERVICE_AGREEMENT_PAYOR_ID] ON [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]
(
	[DENIAL_SERVICE_AGREEMENT_PAYOR_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE](
	[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DOCUMENT_TYPE_DESCRIPTION] [varchar](100) NOT NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_TYPE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON](
	[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_ID] [int] IDENTITY(1,1) NOT NULL,
	[SERVICE_AGREEMENT_ID] [int] NOT NULL,
	[REASON] [varchar](500) NOT NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_SERVICE_AGREEMENT_PENDING_REASON] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_SERVICE_AGREEMENT_PENDING_REASON_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Index [IX_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SERVICE_AGREEMENT_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON]') AND name = N'IX_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SERVICE_AGREEMENT_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SERVICE_AGREEMENT_ID] ON [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON]
(
	[SERVICE_AGREEMENT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DENIAL_SERVICE_LOCATION]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_SERVICE_LOCATION](
	[DENIAL_SERVICE_LOCATION_ID] [int] IDENTITY(1,1) NOT NULL,
	[SERVICE_AGREEMENT_ID] [int] NOT NULL,
	[NAME] [varchar](500) NOT NULL,
	[NPI] [varchar](10) NULL,
	[ADDRESS_LINE_1] [varchar](35) NULL,
	[ADDRESS_LINE_2] [varchar](35) NULL,
	[CITY] [varchar](25) NULL,
	[STATE] [varchar](2) NULL,
	[POSTAL_CODE] [varchar](50) NULL,
	[FEDERAL_TAX_ID] [varchar](9) NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[IS_DEFAULT] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_SERVICE_LOCATION] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_SERVICE_LOCATION_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_SERVICE_LOCATION_SERVICE_SERVICE_AGREEMENT_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION]') AND name = N'IX_DENIAL_SERVICE_LOCATION_SERVICE_SERVICE_AGREEMENT_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_SERVICE_LOCATION_SERVICE_SERVICE_AGREEMENT_ID] ON [dbo].[DENIAL_SERVICE_LOCATION]
(
	[SERVICE_AGREEMENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE](
	[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_ID] [int] IDENTITY(1,1) NOT NULL,
	[DENIAL_SERVICE_LOCATION_ID] [int] NOT NULL,
	[DENIAL_SERVICE_PLACE_ID] [int] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE] PRIMARY KEY NONCLUSTERED 
(
	[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_LOCATION_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]') AND name = N'IX_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_LOCATION_ID')
CREATE CLUSTERED INDEX [IX_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_LOCATION_ID] ON [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]
(
	[DENIAL_SERVICE_LOCATION_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[DENIAL_SERVICE_PLACE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_PLACE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_SERVICE_PLACE](
	[DENIAL_SERVICE_PLACE_ID] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [nvarchar](10) NOT NULL,
	[NAME] [nvarchar](500) NOT NULL,
	[DESCRIPTION] [nvarchar](1000) NOT NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_DENIAL_SERVICE_PLACE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_SERVICE_PLACE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[DENIAL_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[DENIAL_TYPE_CODE](
	[DENIAL_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_DENIAL_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[DENIAL_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Table [dbo].[GLOBAL_CPT_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_CPT_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[GLOBAL_CPT_CODE](
	[GLOBAL_CPT_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [varchar](5) NOT NULL,
	[SHORT_DESCRIPTION] [varchar](250) NOT NULL,
	[DESCRIPTION] [varchar](max) NOT NULL,
	[LAY_TERMS] [varchar](max) NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_GLOBAL_CPT_CODE] PRIMARY KEY CLUSTERED 
(
	[GLOBAL_CPT_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1] TEXTIMAGE_ON [FGData1]
END
GO
/****** Object:  Table [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER](
	[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_ID] [int] IDENTITY(1,1) NOT NULL,
	[GLOBAL_CPT_CODE_ID] [int] NOT NULL,
	[GLOBAL_MODIFIER_ID] [int] NOT NULL,
	[DENIAL_CLAIM_FORM_TYPE_CODE] [int] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER] PRIMARY KEY NONCLUSTERED 
(
	[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER]') AND name = N'IX_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER')
CREATE CLUSTERED INDEX [IX_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER] ON [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER]
(
	[GLOBAL_CPT_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Table [dbo].[GLOBAL_HCPCS_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_HCPCS_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[GLOBAL_HCPCS_CODE](
	[GLOBAL_HCPCS_CODE_ID] [int] IDENTITY(1,1) NOT NULL,
	[CODE] [varchar](5) NOT NULL,
	[SHORT_DESCRIPTION] [varchar](250) NOT NULL,
	[DESCRIPTION] [varchar](max) NOT NULL,
	[HCPCS_COVERAGE_TYPE_CODE] [tinyint] NOT NULL,
	[IS_ASC_APPROVED] [bit] NOT NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_GLOBAL_HCPCS_CODE] PRIMARY KEY CLUSTERED 
(
	[GLOBAL_HCPCS_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1] TEXTIMAGE_ON [FGData1]
END
GO
/****** Object:  Table [dbo].[GLOBAL_MODIFIER]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_MODIFIER]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[GLOBAL_MODIFIER](
	[GLOBAL_MODIFIER_ID] [int] IDENTITY(1,1) NOT NULL,
	[MODIFIER] [varchar](2) NOT NULL,
	[SHORT_DESCRIPTION] [varchar](50) NOT NULL,
	[DESCRIPTION] [varchar](max) NOT NULL,
	[MODIFIER_TYPE_CODE] [tinyint] NOT NULL,
	[HCPCS_COVERAGE_TYPE_CODE] [tinyint] NULL,
	[EFFECTIVE_DATE] [datetime] NULL,
	[EXPIRATION_DATE] [datetime] NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
	CONSTRAINT [PK_GLOBAL_MODIFIER] PRIMARY KEY CLUSTERED 
(
	[GLOBAL_MODIFIER_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1] TEXTIMAGE_ON [FGData1]
END
GO
/****** Object:  Table [dbo].[GLOBAL_PROCEDURE_CODE_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_PROCEDURE_CODE_TYPE_CODE]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[GLOBAL_PROCEDURE_CODE_TYPE_CODE](
	[GLOBAL_PROCEDURE_CODE_TYPE_CODE] [tinyint] NOT NULL,
	[KEY] [varchar](100) NOT NULL,
	[DISPLAY_NAME] [varchar](120) NULL,
	[EXTERNAL_CODE] [varchar](120) NULL,
	[DESCRIPTION] [varchar](500) NULL,
	CONSTRAINT [PK_GLOBAL_PROCEDURE_CODE_TYPE_CODE] PRIMARY KEY CLUSTERED 
(
	[GLOBAL_PROCEDURE_CODE_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_DENIAL_CLAIM_ASSIGNED_TO_USER_PROFILE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]') AND name = N'IX_DENIAL_CLAIM_ASSIGNED_TO_USER_PROFILE_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_ASSIGNED_TO_USER_PROFILE_ID] ON [dbo].[DENIAL_CLAIM]
(
	[ASSIGNED_TO_USER_PROFILE_ID] ASC
)
INCLUDE([DENIAL_CLAIM_ID],[DENIAL_CLAIM_STATUS_TYPE_CODE]) WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_CHANGING_USER_PROFILE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]') AND name = N'IX_DENIAL_CLAIM_CHANGING_USER_PROFILE_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_CHANGING_USER_PROFILE_ID] ON [dbo].[DENIAL_CLAIM]
(
	[CHANGING_USER_PROFILE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_FACILITY_ID_SERVICE_AGREEMENT_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]') AND name = N'IX_DENIAL_CLAIM_FACILITY_ID_SERVICE_AGREEMENT_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_FACILITY_ID_SERVICE_AGREEMENT_ID] ON [dbo].[DENIAL_CLAIM]
(
	[FACILITY_ID] ASC,
	[SERVICE_AGREEMENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_COMMENT_CLAIMID_CLAIM_COMMENT_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_COMMENT]') AND name = N'IX_DENIAL_CLAIM_COMMENT_CLAIMID_CLAIM_COMMENT_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_COMMENT_CLAIMID_CLAIM_COMMENT_ID] ON [dbo].[DENIAL_CLAIM_COMMENT]
(
	[DENIAL_CLAIM_ID] ASC,
	[DENIAL_CLAIM_COMMENT_ID] ASC
)
INCLUDE([CREATION_DATE_TIME]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_COMMENT_CLAIMID_CLAIM_COMMENT_TYPE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_COMMENT]') AND name = N'IX_DENIAL_CLAIM_COMMENT_CLAIMID_CLAIM_COMMENT_TYPE_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_COMMENT_CLAIMID_CLAIM_COMMENT_TYPE_ID] ON [dbo].[DENIAL_CLAIM_COMMENT]
(
	[DENIAL_CLAIM_ID] ASC,
	[DENIAL_CLAIM_COMMENT_TYPE_ID] ASC
)
INCLUDE([CREATION_DATE_TIME]) WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_FACILITY_PROFESSIONAL_FACILITY_PROFESSIONAL_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]') AND name = N'IX_DENIAL_CLAIM_FACILITY_PROFESSIONAL_FACILITY_PROFESSIONAL_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_FACILITY_PROFESSIONAL_FACILITY_PROFESSIONAL_ID] ON [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]
(
	[FACILITY_PROFESSIONAL_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME]') AND name = N'IX_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_ID')
CREATE UNIQUE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_OUTCOME]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_DENIAL_CLAIM_OUTCOME_NOTE_OBJECT_TYPE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME_NOTE]') AND name = N'IX_DENIAL_CLAIM_OUTCOME_NOTE_OBJECT_TYPE')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_OUTCOME_NOTE_OBJECT_TYPE] ON [dbo].[DENIAL_CLAIM_OUTCOME_NOTE]
(
	[OBJECT_TYPE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PATIENT_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT]') AND name = N'IX_DENIAL_CLAIM_PATIENT_DENIAL_CLAIM_ID')
CREATE UNIQUE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PATIENT_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_PATIENT]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT_CONDITION]') AND name = N'IX_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_ID')
CREATE UNIQUE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_PATIENT_CONDITION]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_PATIENT_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT_CONDITION]') AND name = N'IX_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_PATIENT_ID')
CREATE UNIQUE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_PATIENT_ID] ON [dbo].[DENIAL_CLAIM_PATIENT_CONDITION]
(
	[DENIAL_CLAIM_PATIENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PAYOR_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PAYOR]') AND name = N'IX_DENIAL_CLAIM_PAYOR_DENIAL_CLAIM_ID')
CREATE UNIQUE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PAYOR_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_PAYOR]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_REVISION_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_REVISION_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_REVISION_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]') AND name = N'IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID] ON [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]
(
	[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_CLAIM_STATUS_HISTORY_DENIAL_CLAIM_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_STATUS_HISTORY]') AND name = N'IX_DENIAL_CLAIM_STATUS_HISTORY_DENIAL_CLAIM_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_CLAIM_STATUS_HISTORY_DENIAL_CLAIM_ID] ON [dbo].[DENIAL_CLAIM_STATUS_HISTORY]
(
	[DENIAL_CLAIM_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_DENIAL_REASON_CODE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE]') AND name = N'IX_DENIAL_REASON_CODE_CODE')
CREATE NONCLUSTERED INDEX [IX_DENIAL_REASON_CODE_CODE] ON [dbo].[DENIAL_REASON_CODE]
(
	[CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_DENIAL_REASON_CODE_SHORT_DESCRIPTION]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE]') AND name = N'IX_DENIAL_REASON_CODE_SHORT_DESCRIPTION')
CREATE NONCLUSTERED INDEX [IX_DENIAL_REASON_CODE_SHORT_DESCRIPTION] ON [dbo].[DENIAL_REASON_CODE]
(
	[SHORT_DESCRIPTION] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_REASON_CODE_DENIAL_REASON_GROUP_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]') AND name = N'IX_DENIAL_REASON_CODE_DENIAL_REASON_GROUP_TYPE_CODE')
CREATE NONCLUSTERED INDEX [IX_DENIAL_REASON_CODE_DENIAL_REASON_GROUP_TYPE_CODE] ON [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]
(
	[DENIAL_REASON_GROUP_TYPE_CODE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_DENIAL_REMIT_CODE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REMIT_CODE]') AND name = N'IX_DENIAL_REMIT_CODE_CODE')
CREATE NONCLUSTERED INDEX [IX_DENIAL_REMIT_CODE_CODE] ON [dbo].[DENIAL_REMIT_CODE]
(
	[CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_DENIAL_REVENUE_CODE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE]') AND name = N'IX_DENIAL_REVENUE_CODE_CODE')
CREATE NONCLUSTERED INDEX [IX_DENIAL_REVENUE_CODE_CODE] ON [dbo].[DENIAL_REVENUE_CODE]
(
	[CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_DENIAL_REVENUE_CODE_CATEGORY_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE_CATEGORY]') AND name = N'IX_DENIAL_REVENUE_CODE_CATEGORY_CODE')
CREATE UNIQUE NONCLUSTERED INDEX [IX_DENIAL_REVENUE_CODE_CATEGORY_CODE] ON [dbo].[DENIAL_REVENUE_CODE_CATEGORY]
(
	[CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_DENIAL_SERVICE_AGREEMENT_PAYOR_SERVICE_AGREEMENT_ID_FACILITY_PAYOR_NAME]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]') AND name = N'IX_DENIAL_SERVICE_AGREEMENT_PAYOR_SERVICE_AGREEMENT_ID_FACILITY_PAYOR_NAME')
CREATE NONCLUSTERED INDEX [IX_DENIAL_SERVICE_AGREEMENT_PAYOR_SERVICE_AGREEMENT_ID_FACILITY_PAYOR_NAME] ON [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]
(
	[SERVICE_AGREEMENT_ID] ASC,
	[FACILITY_PAYOR_NAME] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
/****** Object:  Index [IX_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SERVICE_AGREEMENT_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]') AND name = N'IX_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SERVICE_AGREEMENT_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SERVICE_AGREEMENT_ID] ON [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]
(
	[SERVICE_AGREEMENT_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_PLACE_ID]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]') AND name = N'IX_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_PLACE_ID')
CREATE NONCLUSTERED INDEX [IX_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_PLACE_ID] ON [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]
(
	[DENIAL_SERVICE_PLACE_ID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_GLOBAL_CPT_CODE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_CPT_CODE]') AND name = N'IX_GLOBAL_CPT_CODE_CODE')
CREATE NONCLUSTERED INDEX [IX_GLOBAL_CPT_CODE_CODE] ON [dbo].[GLOBAL_CPT_CODE]
(
	[CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
/****** Object:  Index [IX_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_GLOBAL_CPT_CODE_ID_GLOBAL_MODIFIER_ID_DENIAL_CLAIM_FORM_TYPE_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER]') AND name = N'IX_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_GLOBAL_CPT_CODE_ID_GLOBAL_MODIFIER_ID_DENIAL_CLAIM_FORM_TYPE_CODE')
CREATE UNIQUE NONCLUSTERED INDEX [IX_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_GLOBAL_CPT_CODE_ID_GLOBAL_MODIFIER_ID_DENIAL_CLAIM_FORM_TYPE_CODE] ON [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER]
(
	[GLOBAL_CPT_CODE_ID] ASC,
	[GLOBAL_MODIFIER_ID] ASC,
	[DENIAL_CLAIM_FORM_TYPE_CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_GLOBAL_HCPCS_CODE]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_HCPCS_CODE]') AND name = N'IX_GLOBAL_HCPCS_CODE')
CREATE UNIQUE NONCLUSTERED INDEX [IX_GLOBAL_HCPCS_CODE] ON [dbo].[GLOBAL_HCPCS_CODE]
(
	[CODE] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_GLOBAL_MODIFIER_MODIFIER]    Script Date: 7/3/2024 11:32:09 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[GLOBAL_MODIFIER]') AND name = N'IX_GLOBAL_MODIFIER_MODIFIER')
CREATE NONCLUSTERED INDEX [IX_GLOBAL_MODIFIER_MODIFIER] ON [dbo].[GLOBAL_MODIFIER]
(
	[MODIFIER] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_DENIAL_CLAIM_STATUS_TYPE_CODE_ID]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM] ADD  CONSTRAINT [DF_DENIAL_CLAIM_DENIAL_CLAIM_STATUS_TYPE_CODE_ID]  DEFAULT ((1)) FOR [DENIAL_CLAIM_STATUS_TYPE_CODE]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_DENIAL_CLAIM_STATUS_CHANGE_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM] ADD  CONSTRAINT [DF_DENIAL_CLAIM_DENIAL_CLAIM_STATUS_CHANGE_DATE_TIME]  DEFAULT (getdate()) FOR [DENIAL_CLAIM_STATUS_CHANGE_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_IS_PRIORITY]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM] ADD  CONSTRAINT [DF_DENIAL_CLAIM_IS_PRIORITY]  DEFAULT ((0)) FOR [IS_PRIORITY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM] ADD  CONSTRAINT [DF_DENIAL_CLAIM_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM] ADD  CONSTRAINT [DF_DENIAL_CLAIM_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM] ADD  CONSTRAINT [DF_DENIAL_CLAIM_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_DOCUMENT_DOCUMENT_DATE_RECEIVED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_DOCUMENT] ADD  CONSTRAINT [DF_DENIAL_CLAIM_DOCUMENT_DOCUMENT_DATE_RECEIVED]  DEFAULT (getdate()) FOR [DOCUMENT_DATE_RECEIVED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_DOCUMENT_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_DOCUMENT] ADD  CONSTRAINT [DF_DENIAL_CLAIM_DOCUMENT_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_DOCUMENT_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_DOCUMENT] ADD  CONSTRAINT [DF_DENIAL_CLAIM_DOCUMENT_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_DOCUMENT_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_DOCUMENT] ADD  CONSTRAINT [DF_DENIAL_CLAIM_DOCUMENT_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_FACILITY_PROFESSIONAL_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL] ADD  CONSTRAINT [DF_DENIAL_CLAIM_FACILITY_PROFESSIONAL_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_FACILITY_PROFESSIONAL_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL] ADD  CONSTRAINT [DF_DENIAL_CLAIM_FACILITY_PROFESSIONAL_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_PRIMARY]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_PRIMARY]  DEFAULT ((0)) FOR [IS_PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_PRESENT_ON_ADMISSION]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_PRESENT_ON_ADMISSION]  DEFAULT ((0)) FOR [IS_PRESENT_ON_ADMISSION]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_INVALID]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_INVALID]  DEFAULT ((0)) FOR [IS_INVALID_CODE]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_USER_ACKNOWLEDGED_INVALID_CODE]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_USER_ACKNOWLEDGED_INVALID_CODE]  DEFAULT ((0)) FOR [USER_ACKNOWLEDGED_INVALID_CODE]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_ORDINAL]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_ORDINAL]  DEFAULT ((0)) FOR [ORDINAL]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_CHIEF_COMPLAINT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_IS_CHIEF_COMPLAINT]  DEFAULT ((0)) FOR [IS_CHIEF_COMPLAINT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_OUTCOME_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME] ADD  CONSTRAINT [DF_DENIAL_CLAIM_OUTCOME_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_OUTCOME_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME] ADD  CONSTRAINT [DF_DENIAL_CLAIM_OUTCOME_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_OUTCOME_NOTE_IS_AUTOMATED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_OUTCOME_NOTE_IS_AUTOMATED]  DEFAULT ((0)) FOR [IS_SYSTEM_GENERATED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_OUTCOME_NOTE_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_OUTCOME_NOTE_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_OUTCOME_NOTE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_OUTCOME_NOTE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_OUTCOME_NOTE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_OUTCOME_NOTE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PATIENT_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PATIENT_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PATIENT_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PATIENT_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PATIENT_CONDITION_IS_EMPLOYMENT_ACCIDENT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PATIENT_CONDITION_IS_EMPLOYMENT_ACCIDENT]  DEFAULT ((0)) FOR [IS_EMPLOYMENT_ACCIDENT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PATIENT_CONDITION_IS_AUTO_ACCIDENT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PATIENT_CONDITION_IS_AUTO_ACCIDENT]  DEFAULT ((0)) FOR [IS_AUTO_ACCIDENT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PATIENT_CONDITION_IS_OTHER_ACCIDENT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PATIENT_CONDITION_IS_OTHER_ACCIDENT]  DEFAULT ((0)) FOR [IS_OTHER_ACCIDENT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PATIENT_CONDITION_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PATIENT_CONDITION_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PATIENT_CONDITION_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PATIENT_CONDITION_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PAYOR_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PAYOR] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PAYOR_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PAYOR_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PAYOR] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PAYOR_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_CHARGE_AMOUNT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_CHARGE_AMOUNT]  DEFAULT ((0)) FOR [CHARGE_AMOUNT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_UNITS]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_UNITS]  DEFAULT ((1)) FOR [UNITS]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_PAYMENT_AMOUNT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_PAYMENT_AMOUNT]  DEFAULT ((0)) FOR [PAYMENT_AMOUNT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_PATIENT_RESPONSIBILITY_AMOUNT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_PATIENT_RESPONSIBILITY_AMOUNT]  DEFAULT ((0)) FOR [PATIENT_RESPONSIBILITY_AMOUNT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_IS_WRITE_OFF_AMOUNT_UKNOWN]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_IS_WRITE_OFF_AMOUNT_UKNOWN]  DEFAULT ((0)) FOR [IS_WRITE_OFF_AMOUNT_UNKNOWN]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_IS_ALLOWED_AMOUNT_UNKNOWN]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_IS_ALLOWED_AMOUNT_UNKNOWN]  DEFAULT ((0)) FOR [IS_ALLOWED_AMOUNT_UNKNOWN]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_IS_PRIMARY]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_IS_PRIMARY]  DEFAULT ((0)) FOR [IS_PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ORDINAL]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_ORDINAL]  DEFAULT ((0)) FOR [ORDINAL]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_IS_PRIMARY]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_IS_PRIMARY]  DEFAULT ((0)) FOR [IS_PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_ORDINAL]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_ORDINAL]  DEFAULT ((0)) FOR [ORDINAL]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_REVISION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_REVISION_DATE_TIME]  DEFAULT (getdate()) FOR [REVISION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_REVISION_ARCHIVE_CHARGE_AMOUNT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_REVISION_ARCHIVE_CHARGE_AMOUNT]  DEFAULT ((0)) FOR [CHARGE_AMOUNT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_REVISION_ARCHIVE_UNITS]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_REVISION_ARCHIVE_UNITS]  DEFAULT ((1)) FOR [UNITS]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_REVISION_PAYMENT_AMOUNT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_REVISION_PAYMENT_AMOUNT]  DEFAULT ((0)) FOR [PAYMENT_AMOUNT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_REVISION_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_REVISION_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_REVISION_REVISION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_REVISION_REVISION_DATE_TIME]  DEFAULT (getdate()) FOR [REVISION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_REVISION_PATIENT_RESPONSIBILITY_AMOUNT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_REVISION_PATIENT_RESPONSIBILITY_AMOUNT]  DEFAULT ((0)) FOR [PATIENT_RESPONSIBILITY_AMOUNT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_REVISION_IS_WRITE_OFF_AMOUNT_UKNOWN]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_REVISION_IS_WRITE_OFF_AMOUNT_UKNOWN]  DEFAULT ((0)) FOR [IS_WRITE_OFF_AMOUNT_UNKNOWN]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_REVISION_IS_ALLOWED_AMOUNT_UNKNOWN]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_REVISION_IS_ALLOWED_AMOUNT_UNKNOWN]  DEFAULT ((0)) FOR [IS_ALLOWED_AMOUNT_UNKNOWN]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_REVISION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_REVISION_DATE_TIME]  DEFAULT (getdate()) FOR [REVISION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_REVISION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION] ADD  CONSTRAINT [DF_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_REVISION_DATE_TIME]  DEFAULT (getdate()) FOR [REVISION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_PRIMARY]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_PRIMARY]  DEFAULT ((0)) FOR [IS_PRIMARY]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_PRESENT_ON_ADMISSION]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_PRESENT_ON_ADMISSION]  DEFAULT ((0)) FOR [IS_PRESENT_ON_ADMISSION]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_INVALID_CODE]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_INVALID_CODE]  DEFAULT ((0)) FOR [IS_INVALID_CODE]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_USER_ACKNOWLEDGED_INVALID_CODE]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_USER_ACKNOWLEDGED_INVALID_CODE]  DEFAULT ((0)) FOR [USER_ACKNOWLEDGED_INVALID_CODE]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ORDINAL]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ORDINAL]  DEFAULT ((0)) FOR [ORDINAL]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_CHIEF_COMPLAINT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ADD  CONSTRAINT [DF_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_IS_CHIEF_COMPLAINT]  DEFAULT ((0)) FOR [IS_CHIEF_COMPLAINT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_TO_DENIAL_CLAIM_STATUS_TYPE_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_STATUS_HISTORY] ADD  CONSTRAINT [DF_DENIAL_CLAIM_TO_DENIAL_CLAIM_STATUS_TYPE_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CLAIM_TO_DENIAL_CLAIM_STATUS_TYPE_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_CLAIM_STATUS_HISTORY] ADD  CONSTRAINT [DF_DENIAL_CLAIM_TO_DENIAL_CLAIM_STATUS_TYPE_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_DOCUMENT_TYPE2_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_DOCUMENT_TYPE] ADD  CONSTRAINT [DF_DENIAL_DOCUMENT_TYPE2_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_DOCUMENT_TYPE2_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_DOCUMENT_TYPE] ADD  CONSTRAINT [DF_DENIAL_DOCUMENT_TYPE2_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_OUTCOME_NOTE_TEMPLATE_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE] ADD  CONSTRAINT [DF_DENIAL_OUTCOME_NOTE_TEMPLATE_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_OUTCOME_NOTE_TEMPLATE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE] ADD  CONSTRAINT [DF_DENIAL_OUTCOME_NOTE_TEMPLATE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_OUTCOME_NOTE_TEMPLATE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_OUTCOME_NOTE_TEMPLATE] ADD  CONSTRAINT [DF_DENIAL_OUTCOME_NOTE_TEMPLATE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_PAYOR_CATEGORY_CREATON_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_PAYOR_CATEGORY] ADD  CONSTRAINT [DF_DENIAL_PAYOR_CATEGORY_CREATON_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_PAYOR_CATEGORY_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_PAYOR_CATEGORY] ADD  CONSTRAINT [DF_DENIAL_PAYOR_CATEGORY_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REASON_CODE] ADD  CONSTRAINT [DF_DENIAL_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REASON_CODE] ADD  CONSTRAINT [DF_DENIAL_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE] ADD  CONSTRAINT [DF_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE] ADD  CONSTRAINT [DF_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE] ADD  CONSTRAINT [DF_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE] ADD  CONSTRAINT [DF_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REMITTANCE_ADVICE_REMARK_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REMIT_CODE] ADD  CONSTRAINT [DF_DENIAL_REMITTANCE_ADVICE_REMARK_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REMITTANCE_ADVICE_REMARK_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REMIT_CODE] ADD  CONSTRAINT [DF_DENIAL_REMITTANCE_ADVICE_REMARK_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REVENUE_CODE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REVENUE_CODE] ADD  CONSTRAINT [DF_DENIAL_REVENUE_CODE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REVENUE_CODE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REVENUE_CODE] ADD  CONSTRAINT [DF_DENIAL_REVENUE_CODE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REVENUE_CODE_CATEGORY_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REVENUE_CODE_CATEGORY] ADD  CONSTRAINT [DF_DENIAL_REVENUE_CODE_CATEGORY_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_REVENUE_CODE_CATEGORY_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_REVENUE_CODE_CATEGORY] ADD  CONSTRAINT [DF_DENIAL_REVENUE_CODE_CATEGORY_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_AGREEMENT_PAYOR_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR] ADD  CONSTRAINT [DF_DENIAL_SERVICE_AGREEMENT_PAYOR_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_AGREEMENT_PAYOR_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR] ADD  CONSTRAINT [DF_DENIAL_SERVICE_AGREEMENT_PAYOR_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT] ADD  CONSTRAINT [DF_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT] ADD  CONSTRAINT [DF_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON] ADD  CONSTRAINT [DF_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON] ADD  CONSTRAINT [DF_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_LOCATION_IS_DEFAULT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION] ADD  CONSTRAINT [DF_DENIAL_SERVICE_LOCATION_IS_DEFAULT]  DEFAULT ((0)) FOR [IS_DEFAULT]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_LOCATION_OF_SERVICE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION] ADD  CONSTRAINT [DF_DENIAL_LOCATION_OF_SERVICE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_LOCATION_OF_SERVICE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION] ADD  CONSTRAINT [DF_DENIAL_LOCATION_OF_SERVICE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE] ADD  CONSTRAINT [DF_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE] ADD  CONSTRAINT [DF_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_PLACE_OF_SERVICE_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_PLACE] ADD  CONSTRAINT [DF_DENIAL_PLACE_OF_SERVICE_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_DENIAL_PLACE_OF_SERVICE_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[DENIAL_SERVICE_PLACE] ADD  CONSTRAINT [DF_DENIAL_PLACE_OF_SERVICE_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_CPT_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_CPT_CODE] ADD  CONSTRAINT [DF_GLOBAL_CPT_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_CPT_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_CPT_CODE] ADD  CONSTRAINT [DF_GLOBAL_CPT_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_GLOBAL_CPT_CODE_TO_GLOBAL_MODIFIER_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_HCPCS_IS_ACS_APPROVED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_HCPCS_CODE] ADD  CONSTRAINT [DF_GLOBAL_HCPCS_IS_ACS_APPROVED]  DEFAULT ((0)) FOR [IS_ASC_APPROVED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_HCPCS_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_HCPCS_CODE] ADD  CONSTRAINT [DF_GLOBAL_HCPCS_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_HCPCS_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_HCPCS_CODE] ADD  CONSTRAINT [DF_GLOBAL_HCPCS_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_MODIFIER_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_GLOBAL_MODIFIER_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_GLOBAL_MODIFIER_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_GLOBAL_MODIFIER_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_DENIAL_SERVICE_AGREEMENT_PENDING_REASON]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_DENIAL_SERVICE_AGREEMENT_PENDING_REASON] FOREIGN KEY([DENIAL_SERVICE_AGREEMENT_PENDING_REASON_ID])
REFERENCES [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON] ([DENIAL_SERVICE_AGREEMENT_PENDING_REASON_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_DENIAL_SERVICE_AGREEMENT_PENDING_REASON]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM] CHECK CONSTRAINT [FK_DENIAL_CLAIM_DENIAL_SERVICE_AGREEMENT_PENDING_REASON]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_DENIAL_SERVICE_LOCATION]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_DENIAL_SERVICE_LOCATION] FOREIGN KEY([DENIAL_SERVICE_LOCATION_ID])
REFERENCES [dbo].[DENIAL_SERVICE_LOCATION] ([DENIAL_SERVICE_LOCATION_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_DENIAL_SERVICE_LOCATION]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM] CHECK CONSTRAINT [FK_DENIAL_CLAIM_DENIAL_SERVICE_LOCATION]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_DENIAL_SERVICE_PLACE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_DENIAL_SERVICE_PLACE] FOREIGN KEY([DENIAL_SERVICE_PLACE_ID])
REFERENCES [dbo].[DENIAL_SERVICE_PLACE] ([DENIAL_SERVICE_PLACE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_DENIAL_SERVICE_PLACE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM] CHECK CONSTRAINT [FK_DENIAL_CLAIM_DENIAL_SERVICE_PLACE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_FACILITY]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_FACILITY] FOREIGN KEY([FACILITY_ID])
REFERENCES [dbo].[FACILITY] ([FACILITY_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_FACILITY]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM] CHECK CONSTRAINT [FK_DENIAL_CLAIM_FACILITY]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_SERVICE_AGREEMENT] FOREIGN KEY([FACILITY_ID], [SERVICE_AGREEMENT_ID])
REFERENCES [dbo].[SERVICE_AGREEMENT] ([FACILITY_ID], [SERVICE_AGREEMENT_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM] CHECK CONSTRAINT [FK_DENIAL_CLAIM_SERVICE_AGREEMENT]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_USER_PROFILE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_USER_PROFILE] FOREIGN KEY([ASSIGNED_TO_USER_PROFILE_ID])
REFERENCES [dbo].[USER_PROFILE] ([USER_PROFILE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_USER_PROFILE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM]'))
ALTER TABLE [dbo].[DENIAL_CLAIM] CHECK CONSTRAINT [FK_DENIAL_CLAIM_USER_PROFILE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_Denial_Claim]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_Denial_Claim] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_Denial_Claim]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL] CHECK CONSTRAINT [FK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_Denial_Claim]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_FACILITY_PROFESSIONAL]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_FACILITY_PROFESSIONAL] FOREIGN KEY([FACILITY_PROFESSIONAL_ID])
REFERENCES [dbo].[FACILITY_PROFESSIONAL] ([FACILITY_PROF_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_FACILITY_PROFESSIONAL]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_FACILITY_PROFESSIONAL] CHECK CONSTRAINT [FK_DENIAL_CLAIM_FACILITY_PROFESSIONAL_FACILITY_PROFESSIONAL]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_DENIAL_CLAIM] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_ORIGINAL_DIAGNOSIS_CODE_DENIAL_CLAIM]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_ID] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME] CHECK CONSTRAINT [FK_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID] FOREIGN KEY([DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID])
REFERENCES [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] ([DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME] CHECK CONSTRAINT [FK_DENIAL_CLAIM_OUTCOME_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_OUTCOME_NOTE_DENIAL_CLAIM_OUTCOME]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME_NOTE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_OUTCOME_NOTE_DENIAL_CLAIM_OUTCOME] FOREIGN KEY([DENIAL_CLAIM_OUTCOME_ID])
REFERENCES [dbo].[DENIAL_CLAIM_OUTCOME] ([DENIAL_CLAIM_OUTCOME_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_OUTCOME_NOTE_DENIAL_CLAIM_OUTCOME]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME_NOTE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_OUTCOME_NOTE_DENIAL_CLAIM_OUTCOME]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_OUTCOME_NOTE_USER_PROFILE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME_NOTE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_OUTCOME_NOTE_USER_PROFILE] FOREIGN KEY([USER_PROFILE_ID])
REFERENCES [dbo].[USER_PROFILE] ([USER_PROFILE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_OUTCOME_NOTE_USER_PROFILE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_OUTCOME_NOTE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_OUTCOME_NOTE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_OUTCOME_NOTE_USER_PROFILE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PATIENT_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PATIENT_DENIAL_CLAIM] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PATIENT_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PATIENT_DENIAL_CLAIM]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT_CONDITION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT_CONDITION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_PATIENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT_CONDITION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_PATIENT] FOREIGN KEY([DENIAL_CLAIM_PATIENT_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PATIENT] ([DENIAL_CLAIM_PATIENT_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_PATIENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PATIENT_CONDITION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PATIENT_CONDITION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PATIENT_CONDITION_DENIAL_CLAIM_PATIENT]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PAYOR_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PAYOR]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PAYOR]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PAYOR_DENIAL_CLAIM] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PAYOR_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PAYOR]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PAYOR] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PAYOR_DENIAL_CLAIM]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PAYOR_DENIAL_SERVICE_AGREEMENT_PAYOR]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PAYOR]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PAYOR]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PAYOR_DENIAL_SERVICE_AGREEMENT_PAYOR] FOREIGN KEY([DENIAL_SERVICE_AGREEMENT_PAYOR_ID])
REFERENCES [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR] ([DENIAL_SERVICE_AGREEMENT_PAYOR_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PAYOR_DENIAL_SERVICE_AGREEMENT_PAYOR]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PAYOR]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PAYOR] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PAYOR_DENIAL_SERVICE_AGREEMENT_PAYOR]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DENIAL_CLAIM_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DENIAL_CLAIM_ID] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DENIAL_CLAIM_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DENIAL_CLAIM_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DENIAL_REVENUE_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DENIAL_REVENUE_CODE] FOREIGN KEY([DENIAL_REVENUE_CODE_ID])
REFERENCES [dbo].[DENIAL_REVENUE_CODE] ([DENIAL_REVENUE_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DENIAL_REVENUE_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DENIAL_REVENUE_CODE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_DENIAL_CLAIM_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_DENIAL_CLAIM_PROCEDURE_ID] FOREIGN KEY([DENIAL_CLAIM_PROCEDURE_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PROCEDURE] ([DENIAL_CLAIM_PROCEDURE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_DENIAL_CLAIM_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_DENIAL_CLAIM_PROCEDURE_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID] FOREIGN KEY([DENIAL_CLAIM_PROCEDURE_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PROCEDURE] ([DENIAL_CLAIM_PROCEDURE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION] FOREIGN KEY([DENIAL_CLAIM_PROCEDURE_REVISION_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ([DENIAL_CLAIM_PROCEDURE_REVISION_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_ID] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_REVISION_DENIAL_CLAIM_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_DENIAL_REMIT_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_DENIAL_REMIT_CODE] FOREIGN KEY([DENIAL_REMIT_CODE_ID])
REFERENCES [dbo].[DENIAL_REMIT_CODE] ([DENIAL_REMIT_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_DENIAL_REMIT_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_DENIAL_REMIT_CODE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_DENIAL_CLAIM_PROCEDURE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_DENIAL_CLAIM_PROCEDURE] FOREIGN KEY([DENIAL_CLAIM_PROCEDURE_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PROCEDURE] ([DENIAL_CLAIM_PROCEDURE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_DENIAL_CLAIM_PROCEDURE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_DENIAL_CLAIM_PROCEDURE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_DENIAL_REASON_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_DENIAL_REASON_CODE] FOREIGN KEY([DENIAL_REASON_CODE_ID])
REFERENCES [dbo].[DENIAL_REASON_CODE] ([DENIAL_REASON_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_DENIAL_REASON_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_DENIAL_REASON_CODE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE] FOREIGN KEY([DENIAL_CLAIM_PROCEDURE_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PROCEDURE] ([DENIAL_CLAIM_PROCEDURE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION] FOREIGN KEY([DENIAL_CLAIM_PROCEDURE_REVISION_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PROCEDURE_REVISION] ([DENIAL_CLAIM_PROCEDURE_REVISION_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_CLAIM_PROCEDURE_REVISION]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_REASON_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_REASON_CODE] FOREIGN KEY([DENIAL_REASON_CODE_ID])
REFERENCES [dbo].[DENIAL_REASON_CODE] ([DENIAL_REASON_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_REASON_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_REASON_CODE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_REMIT_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_REMIT_CODE] FOREIGN KEY([DENIAL_REMIT_CODE_ID])
REFERENCES [dbo].[DENIAL_REMIT_CODE] ([DENIAL_REMIT_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_REMIT_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_DENIAL_REASON_CODE_REVISION_DENIAL_REMIT_CODE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_DENIAL_DENIAL_CLAIM_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_DENIAL_DENIAL_CLAIM_PROCEDURE_ID] FOREIGN KEY([DENIAL_CLAIM_PROCEDURE_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PROCEDURE] ([DENIAL_CLAIM_PROCEDURE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_DENIAL_DENIAL_CLAIM_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_DENIAL_DENIAL_CLAIM_PROCEDURE_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_DENIAL_CLAIM_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_DENIAL_CLAIM_PROCEDURE_ID] FOREIGN KEY([DENIAL_CLAIM_PROCEDURE_ID])
REFERENCES [dbo].[DENIAL_CLAIM_PROCEDURE] ([DENIAL_CLAIM_PROCEDURE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_DENIAL_CLAIM_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION] CHECK CONSTRAINT [FK_DENIAL_CLAIM_PROCEDURE_TO_GLOBAL_MODIFIER_REVISION_DENIAL_DENIAL_CLAIM_PROCEDURE_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_DENIAL_CLAIM] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE] CHECK CONSTRAINT [FK_DENIAL_CLAIM_REVISED_DIAGNOSIS_CODE_DENIAL_CLAIM]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_STATUS_HISTORY_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_STATUS_HISTORY]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_STATUS_HISTORY]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_CLAIM_STATUS_HISTORY_DENIAL_CLAIM] FOREIGN KEY([DENIAL_CLAIM_ID])
REFERENCES [dbo].[DENIAL_CLAIM] ([DENIAL_CLAIM_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_CLAIM_STATUS_HISTORY_DENIAL_CLAIM]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_CLAIM_STATUS_HISTORY]'))
ALTER TABLE [dbo].[DENIAL_CLAIM_STATUS_HISTORY] CHECK CONSTRAINT [FK_DENIAL_CLAIM_STATUS_HISTORY_DENIAL_CLAIM]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_LOG_NOTE_DENIAL_LOG_NOTE_CATEGORY]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_LOG_NOTE]'))
ALTER TABLE [dbo].[DENIAL_LOG_NOTE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_LOG_NOTE_DENIAL_LOG_NOTE_CATEGORY] FOREIGN KEY([DENIAL_LOG_NOTE_CATEGORY_ID])
REFERENCES [dbo].[DENIAL_LOG_NOTE_CATEGORY] ([DENIAL_LOG_NOTE_CATEGORY_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_LOG_NOTE_DENIAL_LOG_NOTE_CATEGORY]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_LOG_NOTE]'))
ALTER TABLE [dbo].[DENIAL_LOG_NOTE] CHECK CONSTRAINT [FK_DENIAL_LOG_NOTE_DENIAL_LOG_NOTE_CATEGORY]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_DENIAL_REASON_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]'))
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_DENIAL_REASON_CODE] FOREIGN KEY([DENIAL_REASON_CODE_ID])
REFERENCES [dbo].[DENIAL_REASON_CODE] ([DENIAL_REASON_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_DENIAL_REASON_CODE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE]'))
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE] CHECK CONSTRAINT [FK_DENIAL_REASON_CODE_TO_DENIAL_REASON_GROUP_TYPE_CODE_DENIAL_REASON_CODE]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REASON_CODE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]'))
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REASON_CODE_ID] FOREIGN KEY([DENIAL_REASON_CODE_ID])
REFERENCES [dbo].[DENIAL_REASON_CODE] ([DENIAL_REASON_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REASON_CODE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]'))
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE] CHECK CONSTRAINT [FK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REASON_CODE_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REMIT_CODE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]'))
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REMIT_CODE_ID] FOREIGN KEY([DENIAL_REMIT_CODE_ID])
REFERENCES [dbo].[DENIAL_REMIT_CODE] ([DENIAL_REMIT_CODE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REMIT_CODE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE]'))
ALTER TABLE [dbo].[DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE] CHECK CONSTRAINT [FK_DENIAL_REASON_CODE_TO_DENIAL_REMIT_CODE_DENIAL_REMIT_CODE_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_REVENUE_CODE_DENIAL_REVENUE_CODE_CATEGORY_DENIAL_REVENUE_CODE_CATEGORY_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE]'))
ALTER TABLE [dbo].[DENIAL_REVENUE_CODE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_REVENUE_CODE_DENIAL_REVENUE_CODE_CATEGORY_DENIAL_REVENUE_CODE_CATEGORY_ID] FOREIGN KEY([DENIAL_REVENUE_CODE_CATEGORY_ID])
REFERENCES [dbo].[DENIAL_REVENUE_CODE_CATEGORY] ([DENIAL_REVENUE_CODE_CATEGORY_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_REVENUE_CODE_DENIAL_REVENUE_CODE_CATEGORY_DENIAL_REVENUE_CODE_CATEGORY_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE]'))
ALTER TABLE [dbo].[DENIAL_REVENUE_CODE] CHECK CONSTRAINT [FK_DENIAL_REVENUE_CODE_DENIAL_REVENUE_CODE_CATEGORY_DENIAL_REVENUE_CODE_CATEGORY_ID]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_AGREEMENT_PAYOR_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_SERVICE_AGREEMENT_PAYOR_SERVICE_AGREEMENT] FOREIGN KEY([SERVICE_AGREEMENT_ID])
REFERENCES [dbo].[SERVICE_AGREEMENT] ([SERVICE_AGREEMENT_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_AGREEMENT_PAYOR_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR] CHECK CONSTRAINT [FK_DENIAL_SERVICE_AGREEMENT_PAYOR_SERVICE_AGREEMENT]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SERVICE_AGREEMENT] FOREIGN KEY([SERVICE_AGREEMENT_ID])
REFERENCES [dbo].[SERVICE_AGREEMENT] ([SERVICE_AGREEMENT_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT] CHECK CONSTRAINT [FK_DENIAL_SERVICE_AGREEMENT_PAYOR_DOCUMENT_SERVICE_AGREEMENT]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SERVICE_AGREEMENT] FOREIGN KEY([SERVICE_AGREEMENT_ID])
REFERENCES [dbo].[SERVICE_AGREEMENT] ([SERVICE_AGREEMENT_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_AGREEMENT_PENDING_REASON] CHECK CONSTRAINT [FK_DENIAL_SERVICE_AGREEMENT_PENDING_REASON_SERVICE_AGREEMENT]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_LOCATION_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_SERVICE_LOCATION_SERVICE_AGREEMENT] FOREIGN KEY([SERVICE_AGREEMENT_ID])
REFERENCES [dbo].[SERVICE_AGREEMENT] ([SERVICE_AGREEMENT_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_LOCATION_SERVICE_AGREEMENT]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION] CHECK CONSTRAINT [FK_DENIAL_SERVICE_LOCATION_SERVICE_AGREEMENT]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_LOCATION]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_LOCATION] FOREIGN KEY([DENIAL_SERVICE_LOCATION_ID])
REFERENCES [dbo].[DENIAL_SERVICE_LOCATION] ([DENIAL_SERVICE_LOCATION_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_LOCATION]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE] CHECK CONSTRAINT [FK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_LOCATION]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_PLACE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]  WITH CHECK ADD  CONSTRAINT [FK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_PLACE] FOREIGN KEY([DENIAL_SERVICE_PLACE_ID])
REFERENCES [dbo].[DENIAL_SERVICE_PLACE] ([DENIAL_SERVICE_PLACE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_PLACE]') AND parent_object_id = OBJECT_ID(N'[dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE]'))
ALTER TABLE [dbo].[DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE] CHECK CONSTRAINT [FK_DENIAL_SERVICE_LOCATION_DENIAL_SERVICE_PLACE_DENIAL_SERVICE_PLACE]
GO
/****** Object:  Trigger [dbo].[TRG_DENIAL_CLAIM_AFTER_UPDATE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TRG_DENIAL_CLAIM_AFTER_UPDATE]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[TRG_DENIAL_CLAIM_AFTER_UPDATE]
	ON [dbo].[DENIAL_CLAIM]
	AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- indicates self-recursion, so do not fire again
	IF TRIGGER_NESTLEVEL(OBJECT_ID(''dbo.DENIAL_CLAIM'')) > 1	
	BEGIN
		RETURN;		
	END

	--------------------------------------------------------------------------------
	-- when a claim status has been changed, add the ''previous'' status to history
	--------------------------------------------------------------------------------
	IF EXISTS (
		SELECT *
		FROM [inserted]
		INNER JOIN [deleted]
				ON [deleted].[DENIAL_CLAIM_ID]				  = [inserted].[DENIAL_CLAIM_ID]
				AND [deleted].[DENIAL_CLAIM_STATUS_TYPE_CODE] <> [inserted].[DENIAL_CLAIM_STATUS_TYPE_CODE]
	)
	BEGIN
		
		-- add the record to history
		INSERT INTO [DENIAL_CLAIM_STATUS_HISTORY]
		(
				[DENIAL_CLAIM_ID]
			,[DENIAL_CLAIM_STATUS_TYPE_CODE]
			,[CREATING_USER_PROFILE_ID]
			,[CHANGING_USER_PROFILE_ID]
		)
		SELECT [deleted].[DENIAL_CLAIM_ID]
				,[deleted].[DENIAL_CLAIM_STATUS_TYPE_CODE]
				,2 -- admin
				,2 -- admin
		FROM [deleted]

		-- update the claim table with the time the ''current'' status was set
		UPDATE [DENIAL_CLAIM]
			SET [DENIAL_CLAIM].[DENIAL_CLAIM_STATUS_CHANGE_DATE_TIME] = GETDATE()
		FROM [deleted]
		INNER JOIN [DENIAL_CLAIM]
				ON [DENIAL_CLAIM].[DENIAL_CLAIM_ID] = [deleted].[DENIAL_CLAIM_ID]
	END

END
' 
GO
ALTER TABLE [dbo].[DENIAL_CLAIM] ENABLE TRIGGER [TRG_DENIAL_CLAIM_AFTER_UPDATE]
GO
/****** Object:  Trigger [dbo].[DENIAL_REVENUE_CODE_AFTERUPDATE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE_AFTERUPDATE]'))
EXEC dbo.sp_executesql @statement = N'
CREATE TRIGGER [dbo].[DENIAL_REVENUE_CODE_AFTERUPDATE]
	ON [dbo].[DENIAL_REVENUE_CODE]
	AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE [DENIAL_REVENUE_CODE]
	SET [CHANGED_DATE_TIME] = GETDATE()
	FROM
		[inserted]
		INNER JOIN [DENIAL_REVENUE_CODE]
				ON [DENIAL_REVENUE_CODE].[DENIAL_REVENUE_CODE_ID] = [inserted].[DENIAL_REVENUE_CODE_ID]

END
' 
GO
ALTER TABLE [dbo].[DENIAL_REVENUE_CODE] ENABLE TRIGGER [DENIAL_REVENUE_CODE_AFTERUPDATE]
GO
/****** Object:  Trigger [dbo].[DENIAL_REVENUE_CODE_CATEGORY_AFTERUPDATE]    Script Date: 7/3/2024 11:32:09 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[DENIAL_REVENUE_CODE_CATEGORY_AFTERUPDATE]'))
EXEC dbo.sp_executesql @statement = N'
CREATE TRIGGER [dbo].[DENIAL_REVENUE_CODE_CATEGORY_AFTERUPDATE]
	ON [dbo].[DENIAL_REVENUE_CODE_CATEGORY]
	AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE [DENIAL_REVENUE_CODE_CATEGORY]
	SET [CHANGED_DATE_TIME] = GETDATE()
	FROM
		[inserted]
		INNER JOIN [DENIAL_REVENUE_CODE_CATEGORY]
				ON [DENIAL_REVENUE_CODE_CATEGORY].[DENIAL_REVENUE_CODE_CATEGORY_ID] = [inserted].[DENIAL_REVENUE_CODE_CATEGORY_ID]

END
' 
GO
ALTER TABLE [dbo].[DENIAL_REVENUE_CODE_CATEGORY] ENABLE TRIGGER [DENIAL_REVENUE_CODE_CATEGORY_AFTERUPDATE]
GO
-- End of 02) DACS-3362 Table Rollback Scripts.sql
GO

-- Start of 03) DACS-3362 Table Rollback Script 2.sql

----------------------------------------
-- 03) DACS-3362 - SQL Script will rollback [CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER] table removed as part of script 01) DACS-3362 Drop Denial Tables.sql (Only Schema, indexes and triggers)
----------------------------------------

GO
/****** Object:  Table [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER]    Script Date: 7/5/2024 9:58:00 AM ******/
GO
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER](
	[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_ID] [int] IDENTITY(1,1) NOT NULL,
	[CEP_PROJECT_RECORD_PROCEDURE_ID] [int] NOT NULL,
	[GLOBAL_MODIFIER_ID] [int] NOT NULL,
	[IS_DELETED] [bit] NOT NULL,
	[CREATION_DATE_TIME] [datetime] NOT NULL,
	[CREATING_USER_PROFILE_ID] [int] NULL,
	[CHANGED_DATE_TIME] [datetime] NOT NULL,
	[CHANGING_USER_PROFILE_ID] [int] NULL,
 CONSTRAINT [PK_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER] PRIMARY KEY NONCLUSTERED 
(
	[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
) ON [FGData1]
END
GO
/****** Object:  Index [IX_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CEP_PROJECT_RECORD_PROCEDURE_ID]    Script Date: 7/5/2024 9:58:00 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER]') AND name = N'IX_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CEP_PROJECT_RECORD_PROCEDURE_ID')
CREATE CLUSTERED INDEX [IX_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CEP_PROJECT_RECORD_PROCEDURE_ID] ON [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER]
(
	[CEP_PROJECT_RECORD_PROCEDURE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_IS_DELETED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_IS_DELETED]  DEFAULT ((0)) FOR [IS_DELETED]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CREATION_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CHANGED_DATE_TIME]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER] ADD  CONSTRAINT [DF_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
END
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CEP_PROJECT_RECORD_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER]'))
ALTER TABLE [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER]  WITH CHECK ADD  CONSTRAINT [FK_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CEP_PROJECT_RECORD_PROCEDURE_ID] FOREIGN KEY([CEP_PROJECT_RECORD_PROCEDURE_ID])
REFERENCES [dbo].[CEP_PROJECT_RECORD_PROCEDURE] ([CEP_PROJECT_RECORD_PROCEDURE_ID])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CEP_PROJECT_RECORD_PROCEDURE_ID]') AND parent_object_id = OBJECT_ID(N'[dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER]'))
ALTER TABLE [dbo].[CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER] CHECK CONSTRAINT [FK_CEP_PROJECT_RECORD_PROCEDURE_GLOBAL_MODIFIER_CEP_PROJECT_RECORD_PROCEDURE_ID]
GO
-- End of 03) DACS-3362 Table Rollback Script 2.sql
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
