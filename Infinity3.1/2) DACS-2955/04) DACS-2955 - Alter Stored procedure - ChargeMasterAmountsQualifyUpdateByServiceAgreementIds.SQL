-------------------------------------------------------------------------------------
-- DACS-2955 - Alter Stored procedure - ChargeMasterAmountsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[ChargeMasterAmountsQualifyUpdateByServiceAgreementIds]
	 @SourceSAId INT
	,@TargetSAId INT
	,@UPId INT
	,@InsDate DATETIME = NULL
	,@MaxToProcess INT = 100000
	,@ShowProcessListOnly BIT = 0
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @MaxToSources INT = 200000;		-- for testing

	IF @SourceSAId IS NULL OR @SourceSAId <= 0
	BEGIN
		SELECT Result = -1, Error = 'Error: Source SA Id is invalid.';
		RETURN;
	END;

	IF @TargetSAId IS NULL OR @TargetSAId <= 0
	BEGIN
		SELECT Result = -2, Error = 'Error: Target SA Id is invalid.';
		RETURN;
	END;

	IF @UPId IS NULL OR @UPId <= 0
	BEGIN
		SELECT Result = -3, Error = 'Error: UP Id is invalid.';
		RETURN;
	END;

	IF @InsDate IS NULL
		SET @InsDate = CONVERT (date, GETDATE());

	IF @MaxToProcess IS NULL OR @MaxToProcess <= 0
		SET @MaxToProcess = 1000;

	IF OBJECT_ID('tempdb..#TempRows') IS NOT NULL
		DROP TABLE #TempRows;

	-- populate #TempRows table with all charge master amounts that already exist for the source said
	SELECT
		 [CPT_CODE_AMOUNT_TEST]
		,[CPT_CODE]
		,[CHARGE_MASTER_ID_SRC]
		,[CHARGE_MASTER_ID_TARGET]
		,[CHARGE_AMOUNT]
		,[EFFECTIVE_DATE]
		,[EXPIRATION_DATE]
		,[SAID_SOURCE]
		,[SAID_TARGET]
		,[CHARGE_MASTER_USAGE_CODE]
	INTO #TempRows
	FROM
	(
		SELECT TOP (@MaxToSources)
			 (CM.[CPT_CODE] + ',' + CAST(CMA.[CHARGE_AMOUNT] AS VARCHAR(30)) + ',' + CAST(CM.CHARGE_MASTER_USAGE_CODE AS VARCHAR(30))) AS [CPT_CODE_AMOUNT_TEST]
			,CM.[CPT_CODE]
			,CMA.[CHARGE_MASTER_ID] AS [CHARGE_MASTER_ID_SRC]
			,-2 AS [CHARGE_MASTER_ID_TARGET]
			,CMA.[CHARGE_AMOUNT]
			,CMA.[EFFECTIVE_DATE]
			,CMA.[EXPIRATION_DATE]
			,CM.[SERVICE_AGREEMENT_ID] AS [SAID_SOURCE]
			,-2 AS [SAID_TARGET]
			,CM.[CHARGE_MASTER_USAGE_CODE]
		FROM
			[RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT] CMA WITH (NOLOCK)
			INNER JOIN [RevCycleDB].[dbo].[CHARGE_MASTER] CM WITH (NOLOCK) ON CMA.[CHARGE_MASTER_ID] = CM.[CHARGE_MASTER_ID]
		WHERE 
			CM.[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND (CM.[CHARGE_MASTER_ID] IS NOT NULL AND CM.[CHARGE_MASTER_ID] > 0)
			AND (CMA.[CHARGE_AMOUNT] IS NOT NULL AND (CMA.[CHARGE_AMOUNT] > 0.0000 OR CMA.[CHARGE_AMOUNT] < 0.0000))
			AND (CMA.[EFFECTIVE_DATE] <= GetDate())
			AND (CMA.[EXPIRATION_DATE] IS NULL OR (CMA.[EXPIRATION_DATE] >= GetDate()))
			AND (CM.[EFFECTIVE_DATE] <= GetDate())
			AND (CM.[EXPIRATION_DATE] IS NULL OR (CM.[EXPIRATION_DATE] >= GetDate()))
		ORDER BY CM.[CPT_CODE], CMA.[EFFECTIVE_DATE]
	) AS sourceList;

	-- select * from #TempRows; -- testing -- remove when done !!!!!!	
	DECLARE @countTempRowsFromSource INT = (select count(*) from #TempRows)
	PRINT('@countTempRowsFromSource = ' + CAST(@countTempRowsFromSource AS VARCHAR(20)));

	-- remove all CPT_CODES that do not have a matching target said
	DELETE FROM #TempRows
	WHERE 
		[CPT_CODE] NOT IN
		(
			SELECT 
				CM.[CPT_CODE]
			FROM
				[CHARGE_MASTER] CM WITH (NOLOCK)
			WHERE 
				CM.[SERVICE_AGREEMENT_ID] = @TargetSAId
				AND (CM.[CHARGE_MASTER_ID] IS NOT NULL AND CM.[CHARGE_MASTER_ID] > 0)
				AND (CM.[EFFECTIVE_DATE] <= GetDate())
				AND (CM.[EXPIRATION_DATE] IS NULL OR (CM.[EXPIRATION_DATE] >= GetDate()))
		)

	-- select * from #TempRows; -- testing -- remove when done !!!!!!	
	DECLARE @countTempRowsAfterRemoveNoTargetCptCodes INT = (select count(*) from #TempRows)
	PRINT('@countTempRowsAfterRemoveNoTargetCptCodes = ' + CAST(@countTempRowsAfterRemoveNoTargetCptCodes AS VARCHAR(20)));
			 
	-- update the target charge master id
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = (select count(*) from #TempRows);
	DECLARE @FetchTestColumn VARCHAR(100);
	DECLARE @FetchCptColumn VARCHAR(100);
	DECLARE @FetchCMSrcColumn INT;
	DECLARE @FetchCMUsageColumn INT;
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [CPT_CODE_AMOUNT_TEST], [CHARGE_MASTER_ID_SRC], [CHARGE_MASTER_USAGE_CODE], [CPT_CODE] FROM #TempRows;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchTestColumn, @FetchCMSrcColumn, @FetchCMUsageColumn, @FetchCptColumn;
			
	PRINT('------------------- Cleanup while loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT('Cleanup ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): ' + IIF(@FetchTestColumn IS NULL, 'NULL', CAST(@FetchTestColumn AS VARCHAR(50)))
			+ ' CMSrc = ' + IIF(@FetchCMSrcColumn IS NULL, 'NULL', CAST(@FetchCMSrcColumn AS VARCHAR(50)))
			+ ' CMUsage = ' + IIF(@FetchCMUsageColumn IS NULL, 'NULL', CAST(@FetchCMUsageColumn AS VARCHAR(50)))
			+ ' Cpt = ' + IIF(@FetchCptColumn IS NULL, 'NULL', CAST(@FetchCptColumn AS VARCHAR(50)))
			);

		DECLARE @loopTargetCMId INT = ISNULL( 
			(
				SELECT TOP 1 CM.[CHARGE_MASTER_ID] 
				FROM
					[CHARGE_MASTER] CM WITH (NOLOCK)
				WHERE 
					@FetchCMUsageColumn = CM.[CHARGE_MASTER_USAGE_CODE]
					AND @FetchCptColumn = CM.[CPT_CODE]
					AND	CM.[SERVICE_AGREEMENT_ID] = @TargetSAId
				ORDER BY CM.[CHARGE_MASTER_ID]
			),-3);

		PRINT('  info ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): @loopTargetCMId = ' + IIF(@loopTargetCMId IS NULL, 'NULL', CAST(@loopTargetCMId AS VARCHAR(50)))
			);

		UPDATE #TempRows
		SET [CHARGE_MASTER_ID_TARGET] = @loopTargetCMId
		WHERE [CPT_CODE_AMOUNT_TEST] = @FetchTestColumn AND [CHARGE_MASTER_ID_SRC] = @FetchCMSrcColumn;

		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchTestColumn, @FetchCMSrcColumn, @FetchCMUsageColumn, @FetchCptColumn;		   

	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 

	-- select * from #TempRows; -- testing -- remove when done !!!!!!	
	DECLARE @countTempRowsAfterUpdateTargetIds INT = (select count(*) from #TempRows)
	PRINT('@countTempRowsAfterUpdateTargetIds = ' + CAST(@countTempRowsAfterUpdateTargetIds AS VARCHAR(20)));

	-- update the target SA id.  should ONLY ever be the target SAID.  extra checks added to gaurantee this
	UPDATE #TempRows
	SET [SAID_TARGET] = ISNULL( 
		(
			SELECT TOP 1 CM.[SERVICE_AGREEMENT_ID] 
			FROM
				[CHARGE_MASTER] CM WITH (NOLOCK)
			WHERE 
				CM.[SERVICE_AGREEMENT_ID] = @TargetSAId
				AND (CM.[CHARGE_MASTER_ID] = #TempRows.[CHARGE_MASTER_ID_TARGET])
				AND (CM.[CHARGE_MASTER_ID] IS NOT NULL AND CM.[CHARGE_MASTER_ID] > 0)
				AND (CM.[EFFECTIVE_DATE] <= GetDate())
				AND (CM.[EXPIRATION_DATE] IS NULL OR (CM.[EXPIRATION_DATE] >= GetDate()))
			ORDER BY CM.[CHARGE_MASTER_ID]
		),-4);

	-- select * from #TempRows; -- testing -- remove when done !!!!!!	
	DECLARE @countTempRowsAfterUpdateTargetSAIds INT = (select count(*) from #TempRows)
	PRINT('@countTempRowsAfterUpdateTargetSAIds = ' + CAST(@countTempRowsAfterUpdateTargetSAIds AS VARCHAR(20)));

	-- cleanup our temp table
	DECLARE @countTempRowsThatNeededToBeCleaned INT = (select count(*) from #TempRows WHERE [CHARGE_MASTER_ID_TARGET] <= 0 OR [SAID_TARGET] <= 0 OR [CHARGE_MASTER_ID_TARGET] = [CHARGE_MASTER_ID_SRC])
	PRINT('@countTempRowsThatNeededToBeCleaned = ' + CAST(@countTempRowsThatNeededToBeCleaned AS VARCHAR(20)));

	IF @countTempRowsThatNeededToBeCleaned > 0
	BEGIN
		DELETE FROM #TempRows WHERE [CHARGE_MASTER_ID_TARGET] <= 0 OR [SAID_TARGET] <= 0 OR [CHARGE_MASTER_ID_TARGET] = [CHARGE_MASTER_ID_SRC]
	END;

	-- select * from #TempRows; -- testing -- remove when done !!!!!!	
	DECLARE @countTempRowsAfterCleanup1 INT = (select count(*) from #TempRows)
	PRINT('@countTempRowsAfterCleanup1 = ' + CAST(@countTempRowsAfterCleanup1 AS VARCHAR(20)));

	-- filter out inserts that will cause constraint EXCEPTIONS : no matching CMIds with overlapping date ranges
	DELETE FROM #TempRows
	WHERE
		[CHARGE_MASTER_ID_TARGET] IN
		(
			SELECT DISTINCT
				CMA.[CHARGE_MASTER_ID]
			FROM
				[RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT] CMA WITH (NOLOCK)
				INNER JOIN [RevCycleDB].[dbo].[CHARGE_MASTER] CM WITH (NOLOCK) ON CMA.[CHARGE_MASTER_ID] = CM.[CHARGE_MASTER_ID]
			WHERE 
				CM.[SERVICE_AGREEMENT_ID] = @TargetSAId
				AND (CMA.[EFFECTIVE_DATE] <= GetDate())
				AND (CMA.[EXPIRATION_DATE] IS NULL OR (CMA.[EXPIRATION_DATE] >= GetDate()))
		)

	-- select * from #TempRows; -- testing -- remove when done !!!!!!	
	DECLARE @countTempRowsAfterCleanup2 INT = (select count(*) from #TempRows)
	PRINT('@countTempRowsAfterCleanup2 = ' + CAST(@countTempRowsAfterCleanup2 AS VARCHAR(20)));

	-- setup for final actions
	DECLARE @tempTableRowCount INT = (SELECT COUNT(*) FROM #TempRows);

	IF @tempTableRowCount <= 0
	BEGIN
		SELECT Result = 0, Error = 'No new data rows to insert';
		RETURN;
	END;

	DECLARE @preProcessingCount INT = 
	(
		SELECT COUNT([ID]) 
		FROM [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT] WITH (NOLOCK) 
		WHERE [CHARGE_MASTER_ID] IN (SELECT DISTINCT [CHARGE_MASTER_ID] FROM [CHARGE_MASTER] WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)
	)

	IF @ShowProcessListOnly <> 0
	BEGIN
		PRINT(' Processing:');
		SELECT TOP (@MaxToProcess) -- !!!!!! remove after testing!!!!!!
				 #TempRows.[CHARGE_MASTER_ID_TARGET] AS [CHARGE_MASTER_ID]
				,#TempRows.[CHARGE_AMOUNT] AS [CHARGE_AMOUNT]
				,#TempRows.[EFFECTIVE_DATE] AS [EFFECTIVE_DATE]
				,#TempRows.[EXPIRATION_DATE] AS [EXPIRATION_DATE]
				,*
			FROM #TempRows
			ORDER BY [CHARGE_MASTER_ID_TARGET];
		RETURN;
	END;
	
	-- Perform insert action here
	-- update the target charge master id
	SET @ProcessCount = 1;
	SET @TotalToProcessCount = (select count(*) from #TempRows);
	DECLARE @countExceptions INT = 0;
	DECLARE @countSkipInserts INT = 0;
	DECLARE @FetchCHARGE_MASTER_ID INT;
	DECLARE @FetchCHARGE_AMOUNT MONEY;
	DECLARE @FetchEFFECTIVE_DATE DATE;
	DECLARE @FetchEXPIRATION_DATE DATE;
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [CHARGE_MASTER_ID_TARGET], [CHARGE_AMOUNT], [EFFECTIVE_DATE], [EXPIRATION_DATE] FROM #TempRows;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchCHARGE_MASTER_ID, @FetchCHARGE_AMOUNT, @FetchEFFECTIVE_DATE, @FetchEXPIRATION_DATE;
			
	PRINT('------------------- Final while loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT('Inserting ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): CMID = ' + IIF(@FetchCHARGE_MASTER_ID IS NULL, 'NULL', CAST(@FetchCHARGE_MASTER_ID AS VARCHAR(50)))
			+ ' CMA = ' + IIF(@FetchCHARGE_AMOUNT IS NULL, 'NULL', CAST(@FetchCHARGE_AMOUNT AS VARCHAR(50)))
			+ ' EFFECTIVE = ' + IIF(@FetchEFFECTIVE_DATE IS NULL, 'NULL', CAST(@FetchEFFECTIVE_DATE AS VARCHAR(50)))
			+ ' EXPIRATION = ' + IIF(@FetchEXPIRATION_DATE IS NULL, 'NULL', CAST(@FetchEXPIRATION_DATE AS VARCHAR(50)))
			);

		BEGIN TRY
		
			DECLARE @countExistingItem INT = 
				(
					SELECT COUNT(*) 
					FROM [CHARGE_MASTER_CHARGE_AMOUNT] 
					WHERE [CHARGE_MASTER_ID] = @FetchCHARGE_MASTER_ID
					AND ([EFFECTIVE_DATE] <= GetDate())
					AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))
				);
		
			IF @countExistingItem > 0
			BEGIN
				SET @countSkipInserts = @countSkipInserts + 1;
				PRINT('  INFO: Overlapping item detected for [' + CAST(@FetchCHARGE_MASTER_ID AS VARCHAR(30)) + ']. skipping.');
			END
			ELSE
				INSERT INTO [CHARGE_MASTER_CHARGE_AMOUNT]
					(
						 [CHARGE_MASTER_ID]
						,[CHARGE_AMOUNT]
						,[EFFECTIVE_DATE]
						,[EXPIRATION_DATE]
					)
				VALUES
					(
						 @FetchCHARGE_MASTER_ID
						,@FetchCHARGE_AMOUNT
						,@FetchEFFECTIVE_DATE
						,@FetchEXPIRATION_DATE
					);

		END TRY
		BEGIN CATCH
			PRINT('  EXCEPTION: ' + CAST(ERROR_NUMBER() AS VARCHAR(30)) + ' :: ' + CAST(ERROR_MESSAGE() AS VARCHAR(4000)) );
			SET @countExceptions = @countExceptions + 1;
		END CATCH;
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchCHARGE_MASTER_ID, @FetchCHARGE_AMOUNT, @FetchEFFECTIVE_DATE, @FetchEXPIRATION_DATE;		   

	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 

	DECLARE @resultCount INT = 
	(
		SELECT COUNT([ID]) 
		FROM [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT] WITH (NOLOCK) 
		WHERE [CHARGE_MASTER_ID] IN (SELECT DISTINCT [CHARGE_MASTER_ID] FROM [CHARGE_MASTER] WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)
	)
	
	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20)) 
						+ ' :: Insert # = ' + CAST((@resultCount - @preProcessingCount) AS VARCHAR(20))
						+ ' :: All Target CPT#,To Insert Target CPT# = ' + CAST(@countTempRowsAfterRemoveNoTargetCptCodes AS VARCHAR(20)) + ',' + CAST(@countTempRowsAfterCleanup2 AS VARCHAR(20))
						+ ' :: Exception # = ' + CAST(@countExceptions AS VARCHAR(20))
						+ ' :: Insert Skip # = ' + CAST(@countSkipInserts AS VARCHAR(20))
						;

END -- end of stored procedure

GO
