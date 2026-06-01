USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of Kelvin5.1Scripts.sql

SET XACT_ABORT ON;

-- Start of Kelvin5.1Scripts.sql

-- End of Kelvin5.1Scripts.sql
GO

-- Start of 01) DACS-3410 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3410 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

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
	
	IF @ShowDebug = 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;
END; -- end of SPROC

GO

/*
	this SPROC replaces the following method:
		public bool AreAny2024MipsRuleSatisfiedAtPresent(int serviceAgreementId, int chartId)

	var sql = $"PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type{pqrsNum.Replace("-A", "A").Replace("-B", "B")}";
	
testing:
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=121366953,@ShowDebug=1;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=121366953;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=122615466,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=122615466,@TestAll=1;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=2100113749,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=2100113749,@TestAll=1;

select top 20 * from chart order by chart_id desc;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=2100114071;

EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] @ChartId=121366953,@PqrsNum=118-B,@Dos='';

*/
-- End of 01) DACS-3410 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
GO

-- Start of 02) DACS-3410 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3410 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
------------------------------------------------------------------------------------
GO

GO

GO


CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
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
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
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
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		--PRINT ('Age criteria satisfied to continue comparisons.');
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
	 
	--IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	--BEGIN
	--	PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;


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

	--IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	--BEGIN
	--	PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
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
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	-- IF @foundDenominatorQuestionsMatchCount <= 0
	-- BEGIN
		-- --PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		-- RETURN;
	-- END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for diabetes (ICD-10-CM) listing?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	IF (SELECT COUNT(*) FROM #tempDenominatorList tdl WHERE tdl.[CODING_SYSTEM] = 'DQ411' AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0) <= 0
		SELECT 'RESULT' = '411', 'QUESTION' = ' ', 'CODE' = '00001';
	ELSE
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


-- End of 02) DACS-3410 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
GO

-- Start of 01) DACS-3580 INSERT DEFINED_RIGHT.sql

------------------------------------------------------------------------------------
-- 01) DACS-3580 - INSERT New Right for Time Recon
------------------------------------------------------------------------------------

GO

INSERT INTO dbo.DEFINED_RIGHT 
(
	DEFINED_RIGHT_ID, 
	NAME, 
	CREATION_DATE_TIME, 
	CREATING_USER_PROFILE_ID,
	CHANGED_DATE_TIME, 
	CHANGING_USER_PROFILE_ID, 
	ALLOW_INHERITANCE, 
	DEFINITION,
    IS_ADMIN
)
VALUES 
(
	168, 
	'Allow Access to Time Recon',
	GETDATE(), 
	10149, 
	GETDATE(), 
	10149, 
	1, 
	'Allow user access to Time Recon Menu',
    0
);
-- End of 01) DACS-3580 INSERT DEFINED_RIGHT.sql
GO

-- Start of 01) DACS-3174 - Script - Update Stored Proc - SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID.sql

----------------------------------------
-- 01) DACS-3174 - SQL Script will Update stored procedure [SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID] to remove Denial columns from select statement
----------------------------------------
GO

CREATE OR ALTER   PROCEDURE [dbo].[SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID]
 @SERVICE_AGREEMENT_ID INT    
AS    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
 SELECT [SERVICE_AGREEMENT_ID]    
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
  -- ,[EXPORT_E_CODE_849_9] -- DACS-2814 - 20231013 - pippin    
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
  ,[FACILITY_NPI]    
  ,[REQUIRE_DISPOSITION_WHEN_PENDING_CHART]    
  ,[REQUIRE_GENERIC_NAME_FOR_NON_OBS_CHARTS]    
  ,[SHOW_DO_NOT_APPLY_FACILITY_MODIFIER_25_CHECKBOX]    
  ,[ANESTHESIA_FIELD_AVOIDANCE_OPTION]    
  ,[DISPLAY_MODIFIER_CG_CHECKBOX]    
  ,[SHOW_FACILITY_ADMIN_CHART_ID]  -- 20231009 - pip - bugfix - were swapped in ServiceAgreementDAO FillFromReader(), Insert() and Update() ordering.    
  ,[CLEAR_PENDING_REASON_ON_MOVE_TO_WIP] --    
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
  ,[DISPLAY_MODIFIER_93_CHECKBOX]     -- added DACS-2475 - 20230619 - pippin    
  ,[DISPLAY_FACILITY_LOS_MODIFIER_93_CHECKBOX] -- added DACS-2475 - 20230619 - pippin    
  ,[DISPLAY_MODIFIER_FS_CHECKBOX]     -- added DACS-2485 - 20230626 - pippin    
  ,[EXPORT_PROCEDURE_ADJUSTMENTS]     -- added DACS-2557 - 20230717 - dillon    
  ,[REQUIRE_PHYSICIAN_WHEN_PENDING_CHART]   -- added DACS-2737 - 20230918 - pippin    
  ,[ADDITIONAL_COMPLAINT_MAXIMUM]     -- added DACS-2936 - 20240122 - pippin    
  ,[COLLECT_PATIENT_NAME]  -- MOVED AT BOTTOM DACS-3050 - kalpana  
  ,[SHOW_PATIENT_NAME]    -- MOVED AT BOTTOM DACS-3050 - kalpana  
 FROM  [dbo].[SERVICE_AGREEMENT] WITH (NOLOCK)    
 WHERE [SERVICE_AGREEMENT_ID] = @SERVICE_AGREEMENT_ID;    
GO
-- End of 01) DACS-3174 - Script - Update Stored Proc - SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID.sql
GO

-- Start of 02) DACS-3174 - Script - Update Stored Proc - SERVICE_AGREEMENT_SELECT_BY_FACILITY_ID.sql

----------------------------------------
-- 02) DACS-3174 - SQL Script will Update stored procedure [SERVICE_AGREEMENT_SELECT_BY_FACILITY_ID] to remove denial columns from select statement
----------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[SERVICE_AGREEMENT_SELECT_BY_FACILITY_ID]  
 @FACILITY_ID int  
AS  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
    SELECT   
        [SERVICE_AGREEMENT_ID]  
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
    FROM   
        [dbo].[SERVICE_AGREEMENT] WITH (NOLOCK)  
    WHERE  
        [FACILITY_ID] = @FACILITY_ID;  
-- End of 02) DACS-3174 - Script - Update Stored Proc - SERVICE_AGREEMENT_SELECT_BY_FACILITY_ID.sql
GO

-- Start of 03) DACS-3174 - Script - Update Stored Proc - CEP_PROJECT_RECORD_DIAGNOSIS_CODE_DELETE_BY_CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID.sql

----------------------------------------
-- 03) DACS-3174 - SQL Script will Update stored procedure CEP_PROJECT_RECORD_DIAGNOSIS_CODE_DELETE_BY_CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID to remove denial [DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_NORMALIZE] call
----------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[CEP_PROJECT_RECORD_DIAGNOSIS_CODE_DELETE_BY_CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID]  
 @CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID int  
AS  
  
DECLARE @CEP_PROJECT_RECORD_ID int  
  
SELECT @CEP_PROJECT_RECORD_ID = [CEP_PROJECT_RECORD_DIAGNOSIS_CODE].[CEP_PROJECT_RECORD_ID]  
FROM [CEP_PROJECT_RECORD_DIAGNOSIS_CODE]  
WHERE [CEP_PROJECT_RECORD_DIAGNOSIS_CODE].[CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID] = @CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID  
  
  
UPDATE [dbo].[CEP_PROJECT_RECORD_DIAGNOSIS_CODE]  
   SET [IS_DELETED] = 1,   
    [ORDINAL] = -1  
WHERE  
 [CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID] = @CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID   
  
-- End of 03) DACS-3174 - Script - Update Stored Proc - CEP_PROJECT_RECORD_DIAGNOSIS_CODE_DELETE_BY_CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID.sql
GO

-- Start of 04) DACS-3174 - Script - Drop Columns in Service agreement.sql

----------------------------------------
-- 04) DACS-3174 - SQL Script will DROP Denial columns from Service agreement table
----------------------------------------
GO

BEGIN TRY

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [ENABLE_DENIAL_MANAGEMENT]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_CLAIM_NUMBER]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_PATIENT_INSURED_RELATIONSHIP_TYPE]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_POLICY_HOLDER_FIRST_NAME]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_POLICY_HOLDER_LAST_NAME]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_POLICE_HOLDER_DATE_OF_BIRTH]

    COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
-- End of 04) DACS-3174 - Script - Drop Columns in Service agreement.sql
GO

-- Start of 05) DACS-3174 - Script - Delete Denial entry from TypeCode.sql

----------------------------------------
-- 04) DACS-3174 - SQL Script will DELETE Denial entry for type code
----------------------------------------
GO

DELETE FROM dbo.[TYPE_CODE] WHERE [KEY] = 'DenialClaim'
-- End of 05) DACS-3174 - Script - Delete Denial entry from TypeCode.sql
GO

-- Start of 01) DACS-3410 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3410 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
GO

GO

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
	
	IF @ShowDebug = 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;
END; -- end of SPROC

GO

/*
	this SPROC replaces the following method:
		public bool AreAny2024MipsRuleSatisfiedAtPresent(int serviceAgreementId, int chartId)

	var sql = $"PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type{pqrsNum.Replace("-A", "A").Replace("-B", "B")}";
	
testing:
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=121366953,@ShowDebug=1;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=121366953;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=122615466,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=122615466,@TestAll=1;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=2100113749,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=2100113749,@TestAll=1;

select top 20 * from chart order by chart_id desc;
EXEC [dbo].[AreAny2024MipsRuleSatisfiedByChart] @ChartId=2100114071;

EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] @ChartId=121366953,@PqrsNum=118-B,@Dos='';

*/
-- End of 01) DACS-3410 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
GO

-- Start of 02) DACS-3410 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3410 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
------------------------------------------------------------------------------------
GO

GO

GO


CREATE OR ALTER   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
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
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
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
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		--PRINT ('Age criteria satisfied to continue comparisons.');
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
	 
	--IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	--BEGIN
	--	PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;


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

	--IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	--BEGIN
	--	PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
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
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	-- IF @foundDenominatorQuestionsMatchCount <= 0
	-- BEGIN
		-- --PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		-- RETURN;
	-- END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for diabetes (ICD-10-CM) listing?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	IF (SELECT COUNT(*) FROM #tempDenominatorList tdl WHERE tdl.[CODING_SYSTEM] = 'DQ411' AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0) <= 0
		SELECT 'RESULT' = '411', 'QUESTION' = ' ', 'CODE' = '00001';
	ELSE
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


-- End of 02) DACS-3410 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
GO

-- Start of 01) DACS-3174 - Script - Update Stored Proc - SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID.sql

----------------------------------------
-- 01) DACS-3174 - SQL Script will Update stored procedure [SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID] to remove Denial columns from select statement
----------------------------------------
GO

CREATE OR ALTER   PROCEDURE [dbo].[SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID]
 @SERVICE_AGREEMENT_ID INT    
AS    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
 SELECT [SERVICE_AGREEMENT_ID]    
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
  -- ,[EXPORT_E_CODE_849_9] -- DACS-2814 - 20231013 - pippin    
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
  ,[FACILITY_NPI]    
  ,[REQUIRE_DISPOSITION_WHEN_PENDING_CHART]    
  ,[REQUIRE_GENERIC_NAME_FOR_NON_OBS_CHARTS]    
  ,[SHOW_DO_NOT_APPLY_FACILITY_MODIFIER_25_CHECKBOX]    
  ,[ANESTHESIA_FIELD_AVOIDANCE_OPTION]    
  ,[DISPLAY_MODIFIER_CG_CHECKBOX]    
  ,[SHOW_FACILITY_ADMIN_CHART_ID]  -- 20231009 - pip - bugfix - were swapped in ServiceAgreementDAO FillFromReader(), Insert() and Update() ordering.    
  ,[CLEAR_PENDING_REASON_ON_MOVE_TO_WIP] --    
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
  ,[DISPLAY_MODIFIER_93_CHECKBOX]     -- added DACS-2475 - 20230619 - pippin    
  ,[DISPLAY_FACILITY_LOS_MODIFIER_93_CHECKBOX] -- added DACS-2475 - 20230619 - pippin    
  ,[DISPLAY_MODIFIER_FS_CHECKBOX]     -- added DACS-2485 - 20230626 - pippin    
  ,[EXPORT_PROCEDURE_ADJUSTMENTS]     -- added DACS-2557 - 20230717 - dillon    
  ,[REQUIRE_PHYSICIAN_WHEN_PENDING_CHART]   -- added DACS-2737 - 20230918 - pippin    
  ,[ADDITIONAL_COMPLAINT_MAXIMUM]     -- added DACS-2936 - 20240122 - pippin    
  ,[COLLECT_PATIENT_NAME]  -- MOVED AT BOTTOM DACS-3050 - kalpana  
  ,[SHOW_PATIENT_NAME]    -- MOVED AT BOTTOM DACS-3050 - kalpana  
 FROM  [dbo].[SERVICE_AGREEMENT] WITH (NOLOCK)    
 WHERE [SERVICE_AGREEMENT_ID] = @SERVICE_AGREEMENT_ID;    
GO
-- End of 01) DACS-3174 - Script - Update Stored Proc - SERVICE_AGREEMENT_SELECT_BY_SERVICE_AGREEMENT_ID.sql
GO

-- Start of 02) DACS-3174 - Script - Update Stored Proc - SERVICE_AGREEMENT_SELECT_BY_FACILITY_ID.sql

----------------------------------------
-- 02) DACS-3174 - SQL Script will Update stored procedure [SERVICE_AGREEMENT_SELECT_BY_FACILITY_ID] to remove denial columns from select statement
----------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[SERVICE_AGREEMENT_SELECT_BY_FACILITY_ID]  
 @FACILITY_ID int  
AS  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
    SELECT   
        [SERVICE_AGREEMENT_ID]  
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
    FROM   
        [dbo].[SERVICE_AGREEMENT] WITH (NOLOCK)  
    WHERE  
        [FACILITY_ID] = @FACILITY_ID;  
-- End of 02) DACS-3174 - Script - Update Stored Proc - SERVICE_AGREEMENT_SELECT_BY_FACILITY_ID.sql
GO

-- Start of 03) DACS-3174 - Script - Update Stored Proc - CEP_PROJECT_RECORD_DIAGNOSIS_CODE_DELETE_BY_CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID.sql

----------------------------------------
-- 03) DACS-3174 - SQL Script will Update stored procedure CEP_PROJECT_RECORD_DIAGNOSIS_CODE_DELETE_BY_CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID to remove denial [DENIAL_CLAIM_PROCEDURE_DIAGNOSIS_CODE_NORMALIZE] call
----------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[CEP_PROJECT_RECORD_DIAGNOSIS_CODE_DELETE_BY_CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID]  
 @CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID int  
AS  
  
DECLARE @CEP_PROJECT_RECORD_ID int  
  
SELECT @CEP_PROJECT_RECORD_ID = [CEP_PROJECT_RECORD_DIAGNOSIS_CODE].[CEP_PROJECT_RECORD_ID]  
FROM [CEP_PROJECT_RECORD_DIAGNOSIS_CODE]  
WHERE [CEP_PROJECT_RECORD_DIAGNOSIS_CODE].[CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID] = @CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID  
  
  
UPDATE [dbo].[CEP_PROJECT_RECORD_DIAGNOSIS_CODE]  
   SET [IS_DELETED] = 1,   
    [ORDINAL] = -1  
WHERE  
 [CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID] = @CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID   
  
-- End of 03) DACS-3174 - Script - Update Stored Proc - CEP_PROJECT_RECORD_DIAGNOSIS_CODE_DELETE_BY_CEP_PROJECT_RECORD_DIAGNOSIS_CODE_ID.sql
GO

-- Start of 04) DACS-3174 - Script - Drop Columns in Service agreement.sql

----------------------------------------
-- 04) DACS-3174 - SQL Script will DROP Denial columns from Service agreement table
----------------------------------------
GO

BEGIN TRY

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [ENABLE_DENIAL_MANAGEMENT]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_CLAIM_NUMBER]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_PATIENT_INSURED_RELATIONSHIP_TYPE]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_POLICY_HOLDER_FIRST_NAME]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_POLICY_HOLDER_LAST_NAME]

    ALTER TABLE [dbo].[SERVICE_AGREEMENT]
    DROP COLUMN [COLLECT_DENIAL_PAYOR_POLICE_HOLDER_DATE_OF_BIRTH]

    COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
-- End of 04) DACS-3174 - Script - Drop Columns in Service agreement.sql
GO

-- Start of 05) DACS-3174 - Script - Delete Denial entry from TypeCode.sql

----------------------------------------
-- 04) DACS-3174 - SQL Script will DELETE Denial entry for type code
----------------------------------------
GO

DELETE FROM dbo.[TYPE_CODE] WHERE [KEY] = 'DenialClaim'
-- End of 05) DACS-3174 - Script - Delete Denial entry from TypeCode.sql
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
