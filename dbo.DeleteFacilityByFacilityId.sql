SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [dbo].[DeleteFacilityByFacilityId]  
	 @FacilityId INT
	,@TestMode INT = 0  -- 1 = in test mode: no deletes performed, 0 = will perform deletes
	,@ThrowException INT = 1
AS  
	--------------------------------
	-- remove transaction from SPROC - DACS-4317 - 20250317 - pippin
	--------------------------------

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	PRINT('TestMode = ' + CAST(@TestMode AS VARCHAR(20)));

	IF @FacilityId IS NULL OR @FacilityId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'Error: Facility Id is invalid.';
		RETURN;
	END;

	-- See if we have any FACILITY data.  if NOT, why are we even here?
	DECLARE @FRecordCount INT = (SELECT COUNT([FACILITY_ID]) FROM [dbo].[FACILITY] WITH (NOLOCK) WHERE [FACILITY_ID] = @FacilityId);
	IF @FRecordCount <= 0
	BEGIN
		SELECT 'Error' = -2, 'Message' = 'Error: FACILITY table has [' + CAST(@FRecordCount AS VARCHAR(20)) + '] present records.  No Facility to remove.';
		RETURN;
	END;

	-- See if we have any SERVICE_AGREEMENT data.  if so, cannot delete facility.
	DECLARE @SaRecordCount INT = (SELECT COUNT([SERVICE_AGREEMENT_ID]) FROM [dbo].[SERVICE_AGREEMENT] WITH (NOLOCK) WHERE [FACILITY_ID] = @FacilityId);
	IF @SaRecordCount > 0
	BEGIN
		SELECT 'Error' = -2, 'Message' = 'Error: SERVICE_AGREEMENT table has [' + CAST(@SaRecordCount AS VARCHAR(20)) + '] present records.  Cannot remove Facility linked to any SA.';
		RETURN;
	END;

	-- See if we have any chart data.  if so, cannot delete facility.
	DECLARE @CRecordCount INT = (SELECT COUNT([FACILITY_ID]) FROM [dbo].[CHART] WITH (NOLOCK) WHERE [FACILITY_ID] = @FacilityId);
	IF @CRecordCount > 0
	BEGIN
		SELECT 'Error' = -2, 'Message' = 'Error: CHART table has [' + CAST(@CRecordCount AS VARCHAR(20)) + '] present records.  Cannot remove Facility linked to any Charts.';
		RETURN;
	END;


	IF OBJECT_ID('tempdb..#tmpFKeys') IS NOT NULL
	BEGIN
		DROP TABLE #tmpFKeys
	END;
	
	IF OBJECT_ID('tempdb..#tmpFKTables') IS NOT NULL
	BEGIN
		DROP TABLE #tmpFKTables
	END;

	-- BEGIN TRANSACTION  -- remove transaction from SPROC - DACS-4317 - 20250317 - pippin
	BEGIN TRY  

		-- find Foreign Keys specified thru linked objects.  deleting these tables should remove any FK exceptions!!
		CREATE TABLE #tmpFKeys(
			PKTABLE_QUALIFIER	[nvarchar](255) NULL
			,PKTABLE_OWNER		[nvarchar](255) NULL
			,PKTABLE_NAME		[nvarchar](255) NULL
			,PKCOLUMN_NAME		[nvarchar](255) NULL
			,FKTABLE_QUALIFIER	[nvarchar](255) NULL
			,FKTABLE_OWNER		[nvarchar](255) NULL
			,FKTABLE_NAME		[nvarchar](255) NULL
			,FKCOLUMN_NAME		[nvarchar](255) NULL
			,KEY_SEQ			INT
			,UPDATE_RULE		INT	
			,DELETE_RULE		INT
			,FK_NAME			[nvarchar](255) NULL
			,PK_NAME			[nvarchar](255) NULL
			,DEFERRABILITY		INT
		)

		INSERT INTO #tmpFKeys
			EXEC sp_fkeys @pktable_name = 'FACILITY'
		
		SELECT [FKTABLE_NAME] INTO #tmpFKTables
			FROM (SELECT DISTINCT [FKTABLE_NAME] FROM #tmpFKeys) AS FKSource;
		
		IF OBJECT_ID('tempdb..#tmpFKeys') IS NOT NULL
		BEGIN
			DROP TABLE #tmpFKeys
		END;
		
		-- just in case removals from processing list
		DELETE FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'CHART';
		DELETE FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'CHART_HISTORY';

		-- add our manually deleted tables to the list.  good to have, non-FK exception generating
		
		-- 20230915 - pippin - added several tables listed within Mr. Sexton's orphaned row report output:
		IF (SELECT COUNT([FKTABLE_NAME]) FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'FACILITY_USER_AUTHORIZATION'  ) <= 0 AND
			(SELECT COUNT([FACILITY_ID]) FROM FACILITY_USER_AUTHORIZATION WHERE [FACILITY_ID] = @FacilityId ) > 0
				INSERT INTO #tmpFKTables ([FKTABLE_NAME]) VALUES ('FACILITY_USER_AUTHORIZATION');

		IF (SELECT COUNT([FKTABLE_NAME]) FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'FACILITY_TO_PORTAL_REPORT'  ) <= 0 AND
			(SELECT COUNT([FACILITY_ID]) FROM FACILITY_TO_PORTAL_REPORT WHERE [FACILITY_ID] = @FacilityId ) > 0
				INSERT INTO #tmpFKTables ([FKTABLE_NAME]) VALUES ('FACILITY_TO_PORTAL_REPORT');

		IF (SELECT COUNT([FKTABLE_NAME]) FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'FACILITY_TO_ANALYTICAL_REPORT'  ) <= 0 AND
			(SELECT COUNT([FACILITY_ID]) FROM FACILITY_TO_ANALYTICAL_REPORT WHERE [FACILITY_ID] = @FacilityId ) > 0
				INSERT INTO #tmpFKTables ([FKTABLE_NAME]) VALUES ('FACILITY_TO_ANALYTICAL_REPORT');

		IF (SELECT COUNT([FKTABLE_NAME]) FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'FACILITY_INFUSION'  ) <= 0 AND
			(SELECT COUNT([FACILITY_ID]) FROM FACILITY_INFUSION WHERE [FACILITY_ID] = @FacilityId ) > 0
				INSERT INTO #tmpFKTables ([FKTABLE_NAME]) VALUES ('FACILITY_INFUSION');


		IF @TestMode = 1
			SELECT DISTINCT * FROM #tmpFKTables;

		-- we may want to add additional table deletes for non-FK fields.  See below comment for how to get full list of 147 objects.

		PRINT('------------------------');
		PRINT('');
		PRINT('------------------------');
		PRINT('--  Foreign Key Deletion Processing --');
		PRINT('------------------------');
		PRINT('');

		-- delete for loop here:
		DECLARE @TotalToProcessCount INT = (SELECT COUNT(*) FROM #tmpFKTables);
		DECLARE @FetchTableNameToDelete VARCHAR(255);
		DECLARE @ProcessCount INT = 1;

		DECLARE cursorFKTables CURSOR LOCAL FOR  
			SELECT [FKTABLE_NAME] FROM #tmpFKTables
			ORDER BY [FKTABLE_NAME] ASC;  
		
		OPEN cursorFKTables;
		FETCH NEXT FROM cursorFKTables
			INTO @FetchTableNameToDelete;
		
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			PRINT('Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) + ' ): Table= ' + @FetchTableNameToDelete);
			
			-- see if there is anything to delete first
			DECLARE @SelectSQL nvarchar(MAX) = N'SELECT COUNT(FACILITY_ID) FROM dbo.' + QUOTENAME(@FetchTableNameToDelete) + N' WITH (NOLOCK) WHERE FACILITY_ID=' + CAST(@FacilityId AS NVARCHAR(20)) + ';'; 
			PRINT(CAST(@ProcessCount AS NVARCHAR(20)) + N' ) SELECTING ROW COUNT FOR: ' + @SelectSQL);
			EXEC sys.sp_executesql @SelectSQL;
			
			IF @TestMode = 0
			BEGIN
				-- perform the delete
				DECLARE @DeleteSQL nvarchar(MAX) = 
						  N'IF (SELECT COUNT(FACILITY_ID) FROM dbo.' + QUOTENAME(@FetchTableNameToDelete) + N' WITH (NOLOCK) WHERE FACILITY_ID=' + CAST(@FacilityId AS NVARCHAR(20)) + N' ) > 0 ' 
						+ N'BEGIN DELETE FROM dbo.' + QUOTENAME(@FetchTableNameToDelete) + N' WHERE FACILITY_ID=' + CAST(@FacilityId AS NVARCHAR(20)) + N' END;'; 
				PRINT(CAST(@ProcessCount AS NVARCHAR(20)) + N' ) DELETING ROWS FOR: ' + @DeleteSQL);

				EXEC sys.sp_executesql @DeleteSQL;
				
			END
			ELSE
			BEGIN
				PRINT(CAST(@ProcessCount AS NVARCHAR(20)) + N' ) TESTMODE.  SKIPPING DELETE.');
			END;

			PRINT('------------------------');

			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorFKTables
				INTO @FetchTableNameToDelete;		   
		END  -- end fetch while loop
		 
		-- cleanup our cursor
		CLOSE cursorFKTables;  
		DEALLOCATE cursorFKTables; 
		
		
		IF @TestMode = 0
		BEGIN 
			PRINT('------------------------');
			PRINT('--  Deleting FACILITY Table entries --');
			PRINT('------------------------');
			PRINT('');
			
			DELETE FROM [dbo].[FACILITY] WHERE FACILITY_ID= @FacilityId;
		END
		ELSE
		BEGIN
			PRINT('Test Mode skipping delete of FACILITY entries.');
		END;
		
		-- COMMIT TRANSACTION;   -- remove transaction from SPROC - DACS-4317 - 20250317 - pippin
	END TRY  
	BEGIN CATCH  
		-- ROLLBACK TRANSACTION;    -- remove transaction from SPROC - DACS-4317 - 20250317 - pippin
		DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
		SELECT 'Error' = -3, 'Message' =	'Exception: SAId [' + CAST(@FacilityId AS VARCHAR(20)) 
											+ ']. Item [' + CAST(@ProcessCount AS VARCHAR(20)) + '/'
											+ CAST(@TotalToProcessCount AS VARCHAR(20)) + '] ' 
											+ 'for table [' + @FetchTableNameToDelete + '].'
											+ ' Exception = ' + @ERROR_MESSAGE;
		IF @ThrowException <> 0									
			THROW 50001 , @ERROR_MESSAGE, 1  
	END CATCH  
	
	DECLARE @CheckSaCount INT = (SELECT COUNT(*) FROM [dbo].[FACILITY] WITH (NOLOCK) WHERE [FACILITY_ID] = @FacilityId);
	PRINT('Facility count for [' + CAST(@FacilityId AS VARCHAR(20)) + '] = ' + CAST(@CheckSaCount AS VARCHAR(20)) );

	SET @ProcessCount = @ProcessCount - 1;
	
	IF @TestMode <> 0
		SELECT 'Error' = 0, 'Message' = 'TEST Mode Success: Delete would have been SAId [' + CAST(@FacilityId AS VARCHAR(20)) + '] from [' + CAST(@ProcessCount AS VARCHAR(20)) + '] of [' + CAST(@TotalToProcessCount AS VARCHAR(20)) + '] tables.';
	ELSE
	BEGIN
		IF @CheckSaCount = 0 
			SELECT 'Error' = 0, 'Message' = 'Success: Delete FId [' + CAST(@FacilityId AS VARCHAR(20)) + '] from [' + CAST(@ProcessCount AS VARCHAR(20)) + '] of [' + CAST(@TotalToProcessCount AS VARCHAR(20)) + '] tables.';
		ELSE
			SELECT 'Error' = -4, 'Message' = 'Failure: No exceptions but ' + CAST(@CheckSaCount AS VARCHAR(20)) + ' FACILITY records remain after delete of FId [' + CAST(@FacilityId AS VARCHAR(20)) + '] from [' + CAST(@ProcessCount AS VARCHAR(20)) + '] of [' + CAST(@TotalToProcessCount AS VARCHAR(20)) + '] tables.';
	END;

GO
