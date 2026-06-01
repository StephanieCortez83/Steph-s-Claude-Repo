SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[IsMipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@PqrsCodeToTest VARCHAR(20)
	,@ShowResults BIT = 0
	,@ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-----------------------------------
	-- still in MIPS 2024 upgrade step 1 testing
	-----------------------------------

	IF @ChartId IS NULL OR @ChartId <= 0 
		RETURN;

	IF @PqrsCodeToTest IS NULL OR LEN(LTRIM(RTRIM(@PqrsCodeToTest))) <= 0 
		RETURN;
	
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

	--PRINT('serviceAgreementId = ' + CAST(@serviceAgreementId AS VARCHAR(64)));
	--PRINT('dateOfService = ' + CAST(@dateOfService AS VARCHAR(64)));

	
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
	-- check the single criteria question response MIPS
	-----------------------------------
	DECLARE @FetchResultsTable TABLE ( [RESULT] INT NULL, [QUESTION] VARCHAR(1024) NULL, [CODE] VARCHAR(32) NULL);
	DECLARE @mipsToCheck VARCHAR(10);
	
	SET @mipsToCheck = '001';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------
	
	SET @mipsToCheck = '007-A';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '007-B';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '047';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '066';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '116';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '118-A';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '118-B';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '134';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '187';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '326';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '331';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type331] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '332';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '415';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '416';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'ECPR39';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'ECPR46';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'ECPR51';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'HCPR24';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'HCPR27';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'THEPQR1';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'THEPQR2';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'THEPQR3';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'THEPQR4';
	IF @PqrsCodeToTest = @mipsToCheck AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	DECLARE @haveException BIT = 0;
	
	-----------------------------------
	-- load our dual criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	
	IF @PqrsCodeToTest LIKE '005%' AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '005')
	BEGIN
		--PRINT('Processing: 005-A');
		DELETE FROM @FetchResultsTable;

		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A @ChartId=@ChartId,@PqrsNum='005-A',@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A');
			SET @haveException = 1;
		END CATCH  

		
		IF @haveException = 0 AND EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='005-A', 'Cid' = @ChartId;
			RETURN 1;
		END;
		
		--PRINT('-------------------');		
		--PRINT('Processing: 005-B');
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B @ChartId=@ChartId,@PqrsNum='005-B',@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B');
			SET @haveException = 1;
		END CATCH  
		
		IF @haveException = 0 AND EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '005-B', 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	
	IF @PqrsCodeToTest LIKE '008%' AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '008')
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: 008-A');
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A @ChartId=@ChartId,@PqrsNum='008-A',@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008A');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='008-A', 'Cid' = @ChartId;
			RETURN 1;
		END;
		
		--PRINT('-------------------');		
		--PRINT('Processing: 008-B');
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B @ChartId=@ChartId,@PqrsNum='008-B',@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type008B');
			SET @haveException = 1;
		END CATCH  
		
		IF @haveException = 0 AND EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN 
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '008-B', 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;
	
	-----------------------------------
	-- load our PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	DECLARE @MipsNameToTest VARCHAR(32) = 'PQRANES1';
	IF @MipsNameToTest = @PqrsCodeToTest AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest)
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypePQRANES1');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;

	SET @MipsNameToTest = 'ACEP60';
	IF @MipsNameToTest = @PqrsCodeToTest AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest)
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP60');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;

	SET @MipsNameToTest = 'ACEP61';
	IF @MipsNameToTest = @PqrsCodeToTest AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest)
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP61');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;

	SET @MipsNameToTest = 'ACEP64';
	IF @MipsNameToTest = @PqrsCodeToTest AND EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest)
	BEGIN
		--PRINT('-------------------');		
		--PRINT('Processing: ' + @MipsNameToTest);
		DELETE FROM @FetchResultsTable;
		SET @haveException = 0;
		
		BEGIN TRY 
			INSERT INTO 
				@FetchResultsTable
			EXEC PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64 @ChartId=@ChartId,@PqrsNum=@MipsNameToTest,@Dos=@dateOfService;
		END TRY
		BEGIN CATCH
			PRINT(' Exception Calling --> PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64');
			SET @haveException = 1;
		END CATCH  

		IF @haveException = 0 AND EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '1')
		BEGIN 
			IF @ShowResults = 1 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			RETURN 1;
		END;
	END;

	-----------------------------------
	-- all done
	-----------------------------------
	--PRINT('-------------------');		
	IF @ShowDebug = 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;

/*
EXEC [dbo].[IsMipsRuleSatisfiedByChart] 
	 @ChartId=2100117073
	,@PqrsCodeToTest='066'
	,@ShowDebug = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] 
	 @ChartId=2100117073
	,@PqrsCodeToTest='ECPR39';
EXEC [dbo].[IsMipsRuleSatisfiedByChart] 
	 @ChartId=2100117073
	,@PqrsCodeToTest='ACEP60';

EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='001',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='007-A',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='007-B',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='047',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='066',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='116',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='118-A',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='118-B',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='134',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='187',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='326',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='331',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='332',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='415',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='416',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='ECPR39',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='ECPR46',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='ECPR51',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='HCPR24',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='HCPR27',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='THEPQR1',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='THEPQR2',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='THEPQR3',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='THEPQR4',@ShowResults = 1;

-- simple
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='PQRANES1',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='ACEP60',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='ACEP61',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='ACEP64',@ShowResults = 1;

-- 2 criteria
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='005-A',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='005-B',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='008-A',@ShowResults = 1;
EXEC [dbo].[IsMipsRuleSatisfiedByChart] @ChartId=2100117073,@PqrsCodeToTest='008-B',@ShowResults = 1;

*/
END; -- end of SPROC

GO
