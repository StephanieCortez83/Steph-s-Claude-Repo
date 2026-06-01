------------------------------------------------------------------------------------
-- 01) DACS-3410 - Create or Alter Stored Procedure - [dbo].[AreAny2024MipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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