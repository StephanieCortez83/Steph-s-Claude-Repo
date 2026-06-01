SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [dbo].[DeleteServiceAgreementByServiceAgreementId]  
	 @ServiceAgreementId INT
	,@TestMode INT = 0  -- 1 = in test mode: no deletes performed, 0 = will perform deletes
	,@ThrowException INT = 1
AS  
	--------------------------------
	-- remove transaction from SPROC - DACS-4317 - 20250317 - pippin
	--------------------------------

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	PRINT('TestMode = ' + CAST(@TestMode AS VARCHAR(20)));

	IF @ServiceAgreementId IS NULL OR @ServiceAgreementId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'Error: Source SA Id is invalid.';
		RETURN;
	END;

	-- See if we have any SERVICE_AGREEMENT data.  if NOT, why are we even here?
	DECLARE @SaRecordCount INT = (SELECT COUNT([SERVICE_AGREEMENT_ID]) FROM [dbo].[SERVICE_AGREEMENT] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @ServiceAgreementId);
	IF @SaRecordCount <= 0
	BEGIN
		SELECT 'Error' = -2, 'Message' = 'Error: SERVICE_AGREEMENT table has [' + CAST(@SaRecordCount AS VARCHAR(20)) + '] present records.  Cannot remove SA that does NOT exist.';
		RETURN;
	END;
	
	-- See if we have any chart data.  if so, we cannot proceed with delete in this stored procedure
	DECLARE @ChartRecordCount INT = (SELECT COUNT([CHART_ID]) FROM [dbo].[CHART] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @ServiceAgreementId);
	IF @ChartRecordCount > 0
	BEGIN
		SELECT 'Error' = -2, 'Message' = 'Error: CHART table has [' + CAST(@ChartRecordCount AS VARCHAR(20)) + '] present records.  Cannot remove SA.';
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
			EXEC sp_fkeys @pktable_name = 'SERVICE_AGREEMENT'
		
		SELECT [FKTABLE_NAME] INTO #tmpFKTables
			FROM (SELECT DISTINCT [FKTABLE_NAME] FROM #tmpFKeys) AS FKSource;
		
		IF OBJECT_ID('tempdb..#tmpFKeys') IS NOT NULL
		BEGIN
			DROP TABLE #tmpFKeys
		END;

		-- add our manually deleted tables to the list.  good to have, non-FK exception generating
		INSERT INTO #tmpFKTables ([FKTABLE_NAME]) 
			VALUES
			-- FK in list already --  ('FACILITY_CRITICAL_CARE')
			 ('FACILITY_LEVEL')
			,('CHARGE_MASTER_CATEGORY')
			,('CHARGE_MASTER_DEPARTMENT')
			,('CHARGE_MASTER_INCLUSIVE')
			,('CHARGE_MASTER_MODIFIER')
			,('CHARGE_MASTER')
			-- FK in list already -- ,('FACILITY_PROFESSIONAL')
			-- FK in list already -- ,('FACILITY_SERVICE')
			-- FK in list already -- ,('PHYSICIAN_CRITICAL_CARE')
			,('PHYSICIAN_SERVICE_PROCEDURE')
			-- FK in list already -- ,('SERVICE_AGREEMENT_TRIAGE_ACUITY')
			-- FK in list already -- ,('SERVICE_AGREEMENT_ARRIVAL_MODE')
			,('CHART_MENU')
			,('DIAGNOSIS_CODE_BYPASS_AUTO_APPROVAL')
			,('DOCUMENTATION_ITEM')
			,('FACILITY_FINANCIAL_CLASS')
			,('FACILITY_SERVICE_SCHEDULE_ASSIGNMENT')
			,('PATIENT_CLASS')
			,('PATIENT_DISPOSITION_MAP')
			,('SERVICE_AGREEMENT_CHART_STATUS_CHANGE_CRITERIA')
			,('SERVICE_AGREEMENT_CLIENT_SPECIFICS')
			,('SERVICE_AGREEMENT_CLINIC')
			,('SERVICE_AGREEMENT_CMS_LCD')
			,('SERVICE_AGREEMENT_DOCUMENT')
			,('SERVICE_AGREEMENT_EMR_SYSTEM')
			,('SERVICE_AGREEMENT_EXPORT')
			,('SERVICE_AGREEMENT_EXPORT_TIME')
			,('SERVICE_AGREEMENT_FACILITY_EM_METHOD')
			,('SERVICE_AGREEMENT_MANAGEMENT_TEAM')
			,('SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE')
			,('SERVICE_AGREEMENT_PAYOR')
			,('SERVICE_AGREEMENT_PENDING_REASON')
			,('SERVICE_AGREEMENT_PQRS')
			,('SERVICE_AGREEMENT_PREVIOUS_LEVEL_DISTRIBUTION')
			,('SERVICE_AGREEMENT_RATE')
			,('SERVICE_AGREEMENT_ROI_ASSESSMENT_SUMMARY')
			,('SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT');
			-- FK in list already -- ,('SERVICE_AGREEMENT_AUTOMATION_CODING')
			-- FK in list already -- ,('SERVICE_AGREEMENT_ADMIT_TYPE')
			-- ,('')

			DELETE FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'ServiceAgreementAutomationWarningFlags'; -- does not have a SERVICE_AGREEMENT_ID field.  has ServiceAgreementId field instead
			DELETE FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'FHIRSettings'; -- does not have a SERVICE_AGREEMENT_ID field.  has ServiceAgreementId field instead
			DELETE FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'ServiceAgreementAutomationNurseNamePretext'; -- does not have a SERVICE_AGREEMENT_ID field.  has ServiceAgreementId field instead

			-- just in case removals from processing list
			DELETE FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'CHART';
			DELETE FROM #tmpFKTables WHERE [FKTABLE_NAME] = 'CHART_HISTORY';

			-- we may want to add additional table deletes for non-FK fields.  See below comment for how to get full list of 147 objects.

		IF @TestMode = 1
			SELECT DISTINCT * FROM #tmpFKTables;

		-- handle 'odd' deletes here
		IF @TestMode = 0
		BEGIN 
			PRINT('Processing Manual DELETE statements...');
			
			PRINT('[ServiceAgreementAutomationWarningFlags] ->');
			DELETE FROM [dbo].[ServiceAgreementAutomationWarningFlags] WHERE [ServiceAgreementId] = @ServiceAgreementId; 
			
			PRINT('[FHIRSettings] ->');
			DELETE FROM [dbo].[FHIRSettings] WHERE [ServiceAgreementId] = @ServiceAgreementId; 

			PRINT('[ServiceAgreementAutomationNurseNamePretext] ->');
			DELETE FROM [dbo].[ServiceAgreementAutomationNurseNamePretext] WHERE [ServiceAgreementId] = @ServiceAgreementId; 

			PRINT('[F FROM FACILITY_INFUSION F INNER...] ->');
			DELETE F FROM FACILITY_INFUSION F INNER JOIN SERVICE_AGREEMENT S ON F.FACILITY_ID = S.FACILITY_ID WHERE S.FACILITY_ID != -1 AND S.SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
		END

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
			DECLARE @SelectSQL nvarchar(MAX) = N'SELECT COUNT(SERVICE_AGREEMENT_ID) FROM dbo.' + QUOTENAME(@FetchTableNameToDelete) + N' WITH (NOLOCK) WHERE SERVICE_AGREEMENT_ID=' + CAST(@ServiceAgreementId AS NVARCHAR(20)) + ';'; 
			PRINT(CAST(@ProcessCount AS NVARCHAR(20)) + N' ) SELECTING ROW COUNT FOR: ' + @SelectSQL);
			EXEC sys.sp_executesql @SelectSQL;
			
			IF @TestMode = 0
			BEGIN
				-- perform the delete
				DECLARE @DeleteSQL nvarchar(MAX) = 
						  N'IF (SELECT COUNT(SERVICE_AGREEMENT_ID) FROM dbo.' + QUOTENAME(@FetchTableNameToDelete) + N' WITH (NOLOCK) WHERE SERVICE_AGREEMENT_ID=' + CAST(@ServiceAgreementId AS NVARCHAR(20)) + N' ) > 0 ' 
						+ N'BEGIN DELETE FROM dbo.' + QUOTENAME(@FetchTableNameToDelete) + N' WHERE SERVICE_AGREEMENT_ID=' + CAST(@ServiceAgreementId AS NVARCHAR(20)) + N' END;'; 
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
			PRINT('--  Deleting SERVICE_AGREEMENT Table entries --');
			PRINT('------------------------');
			PRINT('');
			
			DELETE FROM [dbo].[SERVICE_AGREEMENT] WHERE SERVICE_AGREEMENT_ID= @ServiceAgreementId;
		END
		ELSE
		BEGIN
			PRINT('Test Mode skipping delete of SERVICE_AGREEMENT entries.');
		END;
		
		-- COMMIT TRANSACTION;   -- remove transaction from SPROC - DACS-4317 - 20250317 - pippin
	END TRY  
	BEGIN CATCH  
		-- ROLLBACK TRANSACTION;    -- remove transaction from SPROC - DACS-4317 - 20250317 - pippin
		DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
		SELECT 'Error' = -3, 'Message' =	'Exception: SAId [' + CAST(@ServiceAgreementId AS VARCHAR(20)) 
											+ ']. Item [' + CAST(@ProcessCount AS VARCHAR(20)) + '/'
											+ CAST(@TotalToProcessCount AS VARCHAR(20)) + '] ' 
											+ 'for table [' + @FetchTableNameToDelete + '].'
											+ ' Exception = ' + @ERROR_MESSAGE;
		IF @ThrowException <> 0									
			THROW 50001 , @ERROR_MESSAGE, 1  
	END CATCH  
	
	DECLARE @CheckSaCount INT = (SELECT COUNT(*) FROM [dbo].[SERVICE_AGREEMENT] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @ServiceAgreementId);
	PRINT('SA Count for [' + CAST(@ServiceAgreementId AS VARCHAR(20)) + '] = ' + CAST(@CheckSaCount AS VARCHAR(20)) );

	SET @ProcessCount = @ProcessCount - 1;
	
	IF @TestMode <> 0
		SELECT 'Error' = 0, 'Message' = 'TEST Mode Success: Delete would have been SAId [' + CAST(@ServiceAgreementId AS VARCHAR(20)) + '] from [' + CAST(@ProcessCount AS VARCHAR(20)) + '] of [' + CAST(@TotalToProcessCount AS VARCHAR(20)) + '] tables.';
	ELSE
	BEGIN
		IF @CheckSaCount = 0 
			SELECT 'Error' = 0, 'Message' = 'Success: Delete SAId [' + CAST(@ServiceAgreementId AS VARCHAR(20)) + '] from [' + CAST(@ProcessCount AS VARCHAR(20)) + '] of [' + CAST(@TotalToProcessCount AS VARCHAR(20)) + '] tables.';
		ELSE
			SELECT 'Error' = -4, 'Message' = 'Failure: No exceptions but ' + CAST(@CheckSaCount AS VARCHAR(20)) + ' SERVICE_AGREEMENT records remain after delete of SAId [' + CAST(@ServiceAgreementId AS VARCHAR(20)) + '] from [' + CAST(@ProcessCount AS VARCHAR(20)) + '] of [' + CAST(@TotalToProcessCount AS VARCHAR(20)) + '] tables.';
	END;


/*
usage example:
exec [dbo].[DeleteServiceAgreementByServiceAgreementId]  
	 @ServiceAgreementId = 2481  -- 2481, 2560 Humana PI RN DRG
	,@TestMode = 1  -- 1 = in test mode: no deletes performed, 0 = will perform deletes
	,@ThrowException = 1
*/
GO
