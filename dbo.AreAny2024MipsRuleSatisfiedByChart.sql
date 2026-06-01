SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[AreAny2024MipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
	,@ReturnNoRecords BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-----------------------------------
	-- still in MIPS 2024 upgrade step 1 testing
	-----------------------------------

	IF @ChartId IS NULL OR @ChartId <= 0 
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
	-- load our single criteria MIPS for testing
	-----------------------------------
	DECLARE @active2024MipsRules1CTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRules1CTable ([NAME]) 
	VALUES 
		 ('047')							-- DACS-4164 - pippin - moved to top because it is very often triggered
		,('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('HCPR24')							-- DACS-3593 - pippin - added
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('ACEP60')							-- DACS-4164 - pippin - added
		,('ACEP61')							-- DACS-4164 - pippin - added
		,('ACEP64')							-- DACS-4164 - pippin - added
		,('PQRANES1')						-- DACS-4164 - pippin - added
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('331')							-- DACS-3714 - pippin - added
		,('332')
		,('326')
		,('001')
		,('005-A')							-- DACS-4164 - pippin - added
		,('005-B')							-- DACS-4164 - pippin - added
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

	-----------------------------------
	-- check the single criteria question response MIPS
	-- order is not arbitrary.  most commonly found are listed first.
	-----------------------------------
	DECLARE @FetchResultsTable TABLE ( [RESULT] INT NULL, [QUESTION] VARCHAR(1024) NULL, [CODE] VARCHAR(32) NULL);
	DECLARE @mipsToCheck VARCHAR(10);

	SET @mipsToCheck = '047';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'THEPQR4';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '066';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '001';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------
	
	SET @mipsToCheck = '007-A';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '007-B';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '116';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '118-A';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '118-B';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '134';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '187';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '326';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '331';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type331] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '332';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '415';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = '416';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'ECPR39';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'ECPR46';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'ECPR51';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'HCPR24';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR24] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'HCPR27';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeHCPR27] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'THEPQR1';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'THEPQR2';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------

	SET @mipsToCheck = 'THEPQR3';
	IF EXISTS (SELECT TOP 1 1 FROM @active2024MipsRules1CTable WHERE [NAME] = @mipsToCheck )
	BEGIN
		DELETE FROM @FetchResultsTable;
		INSERT INTO @FetchResultsTable 
			EXEC [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3] @ChartId=@ChartId,@PqrsNum=@mipsToCheck,@Dos=@dateOfService;
		IF EXISTS(SELECT TOP 1 1 FROM @FetchResultsTable WHERE [RESULT] = '411')
		BEGIN
			IF @ShowDebug = 1 SELECT '  --> 2024 1 criteria Mips satisfied : ' = @mipsToCheck;
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @mipsToCheck, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	-----------------------------------------------------------
	
	DECLARE @haveException BIT = 0;

	-----------------------------------
	-- load our dual criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	
	IF EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '005') OR @TestAll = 1
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
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='005-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
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
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '005-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	
	IF EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = '008') OR @TestAll = 1
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
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' ='008-A', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
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
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = '008-B', 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;
	
	-----------------------------------
	-- load our PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type criteria MIPS for testing
	-- since so few, will not use a fetch loop
	-----------------------------------
	DECLARE @MipsNameToTest VARCHAR(32) = 'PQRANES1';
	IF EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
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
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;

	SET @MipsNameToTest = 'ACEP60';
	IF EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
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
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;

	SET @MipsNameToTest = 'ACEP61';
	IF EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
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
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;

	SET @MipsNameToTest = 'ACEP64';
	IF EXISTS (SELECT TOP 1 1 FROM @activeSAMipsRulesTable WHERE [NAME] = @MipsNameToTest) OR @TestAll = 1
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
			IF @ReturnNoRecords = 0 SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @MipsNameToTest, 'Cid' = @ChartId;
			IF @TestAll <> 1 RETURN 1;
		END;
	END;

	-----------------------------------
	-- all done
	-----------------------------------
	--PRINT('-------------------');		
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO 2024 Mips satisfied for chart ' = @ChartId;
	RETURN;
END; -- end of SPROC

GO
