USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2987 - Add Defined Right - Analytic Reports - Distribution.sql

----------------------------------------
-- 01) DACS-2987 - Add Defined Right - Analytic Reports - Distribution.sql
----------------------------------------
GO

----------------------------------------
-- Step 1)  Get the needed variables in order to perform the task
----------------------------------------
DECLARE	@DEFINED_RIGHT_ID int =						164;  -- DEFINED_RIGHT_ID to be created
DECLARE	@DEFINED_RIGHT_NAME varchar(50) =			'Analytic Reports - Distribution';
DECLARE	@DEFINED_RIGHT_DEFINITION varchar(2000) =	NULL;  -- If null, the stored procedure will use the @DEFINED_RIGHT_NAME value
DECLARE	@CREATING_USER_ID int =						10149; -- Marcus Ferrell
DECLARE @USER_GROUP_NAME varchar(35) =				'Analytic Reports - Distribution';

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

-- End of 01) DACS-2987 - Add Defined Right - Analytic Reports - Distribution.sql
GO

-- Start of 02) DACS-2987 - Add Defined Right - Analytic Reports - Subscription.sql

----------------------------------------
-- 02) DACS-2987 - Add Defined Right - Analytic Reports - Subscription.sql
----------------------------------------
GO

----------------------------------------
-- Step 1)  Get the needed variables in order to perform the task
----------------------------------------
DECLARE	@DEFINED_RIGHT_ID int =						165;  -- DEFINED_RIGHT_ID to be created
DECLARE	@DEFINED_RIGHT_NAME varchar(50) =			'Analytic Reports - Subscription';
DECLARE	@DEFINED_RIGHT_DEFINITION varchar(2000) =	NULL;  -- If null, the stored procedure will use the @DEFINED_RIGHT_NAME value
DECLARE	@CREATING_USER_ID int =						10149; -- Marcus Ferrell
DECLARE @USER_GROUP_NAME varchar(35) =				'Analytic Reports - Subscription';

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

-- End of 02) DACS-2987 - Add Defined Right - Analytic Reports - Subscription.sql
GO

-- Start of 01) DACS-2955 - Delete all CDM debug adjustment - Alter SPROC - Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId.sql

----------------------------------------
-- 01) DACS-2955 - Delete all CDM debug adjustment - Alter SPROC - Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId.sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId]
      @SAId INT
	, @BackupDestTableSuffix VARCHAR(128) = NULL
	, @ForceDelete BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @BackupDestTableSuffix IS NULL OR LEN(@BackupDestTableSuffix) <= 0
	BEGIN
		PRINT('Table Suffix is invalid.  Skipping backup of tables.');
		SET @BackupDestTableSuffix = NULL;
		--RETURN;
	END;

	DECLARE @countCharts INT = (SELECT COUNT(*) FROM CHART WHERE SERVICE_AGREEMENT_ID = @SAId);
	IF @countCharts > 0 AND @ForceDelete <> 1
	BEGIN
		SELECT 'ERROR' = (CAST(@countCharts AS VARCHAR(30)) + ' Charts FOUND for @SAId ' + CAST(@SAId AS VARCHAR(30)) + '. Terminating process.');
		RETURN;
	END;
	
	DECLARE @countCM  INT = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId);
	DECLARE @countCMM INT = (SELECT COUNT(*) FROM CHARGE_MASTER_MODIFIER WHERE SERVICE_AGREEMENT_ID = @SAId);
	DECLARE @countCMA INT = (SELECT COUNT(*) FROM CHARGE_MASTER_CHARGE_AMOUNT WHERE CHARGE_MASTER_ID IN (SELECT CHARGE_MASTER_ID FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId));

	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));
	PRINT('Starting @countCMM = ' + CAST(@countCMM AS varchar(20)));
	PRINT('Starting @countCMA = ' + CAST(@countCMA AS varchar(20)));

	DECLARE @Nsql   NVARCHAR(MAX),
		    @Result INT;

	PRINT('------------------------------------------');
	PRINT('     Process Charge Master Charge Master Amount');
	PRINT('------------------------------------------');
	
	IF @countCMA > 0
	BEGIN
		DECLARE @CMABackupTarget VARCHAR(512) = 'CHARGE_MASTER_CHARGE_AMOUNT_' + @BackupDestTableSuffix;
		PRINT('Backup CM [CHARGE_MASTER_CHARGE_AMOUNT to ' + @CMABackupTarget + ']...');
		
		IF @BackupDestTableSuffix IS NOT NULL
			EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CHARGE_MASTER_CHARGE_AMOUNT', @DestTable = @CMABackupTarget;
		
		SET @Nsql = N'SELECT @Result = COUNT(*) FROM ' + QUOTENAME(@CMABackupTarget);
		PRINT(N'count CMA SQL :: ' + @Nsql)
		EXEC sp_executesql
			  @Nsql,
			  N'@Result INT OUTPUT',
			  @Result = @Result OUTPUT; 
		PRINT(N'count CMA :: ' + CAST(@Result AS VARCHAR(30)));
		
		IF @Result <= 0 AND @BackupDestTableSuffix IS NOT NULL
		BEGIN
			PRINT(N'Charge Master Charge Amount backup failed.  adjust and try again.');
		END
		ELSE
		BEGIN
			DELETE FROM CHARGE_MASTER_CHARGE_AMOUNT WHERE CHARGE_MASTER_ID IN (SELECT CHARGE_MASTER_ID FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId);
			SET @countCMA  = (SELECT COUNT(*) FROM CHARGE_MASTER_CHARGE_AMOUNT WHERE CHARGE_MASTER_ID IN (SELECT CHARGE_MASTER_ID FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId));
			PRINT('Resulting CMA Count for SAId  = ' + CAST(@countCMA AS varchar(20)));
		END;		
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Charge Amount Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;

	PRINT('------------------------------------------');
	PRINT('      Process Charge Master Modifier');
	PRINT('------------------------------------------');

	IF @countCMM > 0
	BEGIN
		DECLARE @CMMBackupTarget VARCHAR(512) = 'CHARGE_MASTER_MODIFIER_' + @BackupDestTableSuffix;
		PRINT('Backup CM [CHARGE_MASTER_MODIFIER to ' + @CMMBackupTarget + ']...');
		
		IF @BackupDestTableSuffix IS NOT NULL
			EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CHARGE_MASTER_MODIFIER', @DestTable = @CMMBackupTarget;
		
		SET @Nsql = N'SELECT @Result = COUNT(*) FROM ' + QUOTENAME(@CMMBackupTarget);
		PRINT(N'count CMM SQL :: ' + @Nsql)
		EXEC sp_executesql
			  @Nsql,
			  N'@Result INT OUTPUT',
			  @Result = @Result OUTPUT; 
		PRINT(N'count CMM :: ' + CAST(@Result AS VARCHAR(30)));
		
		IF @Result <= 0 AND @BackupDestTableSuffix IS NOT NULL
		BEGIN
			PRINT(N'Charge Master Modifier backup failed.  adjust and try again.');
		END
		ELSE
		BEGIN
			DELETE FROM CHARGE_MASTER_MODIFIER WHERE SERVICE_AGREEMENT_ID = @SAId;
			SET @countCMM  = (SELECT COUNT(*) FROM CHARGE_MASTER_MODIFIER WHERE SERVICE_AGREEMENT_ID = @SAId);
			PRINT('Resulting CMM Count for SAId  = ' + CAST(@countCMM AS varchar(20)));
		END;		
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Modifier Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		DECLARE @CMBackupTarget VARCHAR(512) = 'CHARGE_MASTER_' + @BackupDestTableSuffix;
		PRINT('Backup CM [CHARGE_MASTER to ' + @CMBackupTarget + ']...');
		
		IF @BackupDestTableSuffix IS NOT NULL
			EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CHARGE_MASTER', @DestTable = @CMBackupTarget;
		
		SET @Nsql = N'SELECT @Result = COUNT(*) FROM ' + QUOTENAME(@CMBackupTarget);
		PRINT(N'count CM SQL :: ' + @Nsql)
		EXEC sp_executesql
			  @Nsql,
			  N'@Result INT OUTPUT',
			  @Result = @Result OUTPUT; 
		PRINT(N'count CM :: ' + CAST(@Result AS VARCHAR(30)));
		
		IF @Result <= 0 AND @BackupDestTableSuffix IS NOT NULL
		BEGIN
			PRINT(N'Charge Master backup failed.  adjust and try again.');
		END
		ELSE
		BEGIN
			DELETE FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId;
			SET @countCM  = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId);
			PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
		END;		
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	SELECT 'Processing complete for SAId' = CAST(@SAId AS VARCHAR(20));
END

GO


/*
testing - 
begin tran;
exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = 555114;
-- rollback tran
-- commit tran;

select count(*) from chart where service_agreement_id = 555114
-- select top 1000 * from chart where service_agreement_id = 555114

*/
-- End of 01) DACS-2955 - Delete all CDM debug adjustment - Alter SPROC - Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId.sql
GO

-- Start of 02) DACS-2955 - Alter SPROC - Adjust to only expire non-expired records - Maintenance_ExpireChargeMasterByServiceAgreementId.sql

----------------------------------------
-- 02) DACS-2955 - Alter SPROC - Adjust to only expire non-expired records - Maintenance_ExpireChargeMasterByServiceAgreementId.sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_ExpireChargeMasterByServiceAgreementId]
      @SAId INT
	, @ExpireDate DATETIME = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @ExpireDate IS NULL
	BEGIN
		SET @ExpireDate = GETDATE();
	END;
	
	DECLARE @countCM  INT = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate));

	PRINT('@SAId  = ' + CAST(@SAId AS varchar(20)));
	PRINT('@ExpireDate  = ' + CAST(@ExpireDate AS varchar(40)));
	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));


	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		UPDATE CHARGE_MASTER 
			SET EXPIRATION_DATE = @ExpireDate
		WHERE SERVICE_AGREEMENT_ID = @SAId AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate);
		
		SET @countCM  = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId AND EXPIRATION_DATE = @ExpireDate);
		PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	--SELECT 'Processing complete for SAId' = CAST(@SAId AS VARCHAR(20));
END

GO


-- End of 02) DACS-2955 - Alter SPROC - Adjust to only expire non-expired records - Maintenance_ExpireChargeMasterByServiceAgreementId.sql
GO

-- Start of 03) DACS-2955 - Alter SPROC - Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId.sql

----------------------------------------
-- 03) DACS-2955 - Alter SPROC - Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId.sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId]
      @SAId INT
	, @ResultAsStrings BIT = 0  
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @ResultAsStrings = 1
	BEGIN
	
		SELECT TOP 100 
			cm.[CPT_CODE] + '\t' + cmm.[MODIFIER] + '\t' + cmm.[BILLING_CODE] AS RESULT
			FROM [CHARGE_MASTER_MODIFIER] cmm 
			INNER JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID] = cmm.[CHARGE_MASTER_ID]
		WHERE 
			cmm.[SERVICE_AGREEMENT_ID] = @SAId 
			AND cmm.[SERVICE_AGREEMENT_ID] = cm.[SERVICE_AGREEMENT_ID]
			AND (cmm.[BILLING_CODE] IS NOT NULL AND LEN(cmm.[BILLING_CODE]) > 0)
		ORDER BY cm.[cpt_code] ASC;

		RETURN;
	END;
	
	SELECT TOP 100 
		  cm.[CPT_CODE]
		, cmm.[MODIFIER]
		, cmm.[BILLING_CODE]
		FROM [CHARGE_MASTER_MODIFIER] cmm 
		INNER JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID] = cmm.[CHARGE_MASTER_ID]
	WHERE 
		cmm.[SERVICE_AGREEMENT_ID] = @SAId 
		AND cmm.[SERVICE_AGREEMENT_ID] = cm.[SERVICE_AGREEMENT_ID]
		AND (cmm.[BILLING_CODE] IS NOT NULL AND LEN(cmm.[BILLING_CODE]) > 0)
	ORDER BY cm.[cpt_code] ASC;

END

GO


/*
testing - 
begin tran;
exec [dbo].[Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId] @SAId = 1739; -- Prod
exec [dbo].[Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId] @SAId = 535; -- QA
exec [dbo].[Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId] @SAId = 535, @ResultAsStrings = 1; -- QA
-- rollback tran
-- commit tran;

*/
-- End of 03) DACS-2955 - Alter SPROC - Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId.sql
GO

-- Start of 04) DACS-2955 - Alter Stored procedure - ChargeMasterAmountsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------------------------------
-- DACS-2955 - Alter Stored procedure - ChargeMasterAmountsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------------------------------
GO

GO

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
-- End of 04) DACS-2955 - Alter Stored procedure - ChargeMasterAmountsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 05) DACS-2955 - SQL Create alter procedure - Maintenance_DeveloperTestRefresh.sql

----------------------------------------
-- 05) DACS-2955 - SQL Create alter procedure - Maintenance_DeveloperTestRefresh.sql
----------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_DeveloperTestRefresh]
	@TableList VARCHAR(MAX)
AS
BEGIN
	/*
		Original source provided by J. Burge 20240131
		Turned into procedure by W. Pippin 20240202
	*/

	SET NOCOUNT ON;

	--determine table list
	DECLARE @tables TABLE
	(
		ID INT IDENTITY(1, 1)
	   ,SchemaName sysname
	   ,TableName sysname
	);
	INSERT @tables
	(
		SchemaName
	   ,TableName
	)
	VALUES
		('dbo', 'CHARGE_MASTER')
		,('dbo', 'SERVICE_AGREEMENT');

	IF @TableList IS NULL OR LEN(@TableList) <= 0
	BEGIN
		PRINT('@TableList is empty.  Only copying CHARGE_MASTER AND SERVICE_AGREEMENT tables');
	END
	ELSE
	BEGIN
		INSERT @tables(SchemaName,TableName)
			SELECT 
				'dbo' AS SchemaName
				, RTRIM(LTRIM(value)) AS TableName
			FROM STRING_SPLIT (@TableList, ',')
		
		-- select * from @tables -- testing
	END;

	--validation
	--drop all tables
	DECLARE @sql NVARCHAR(MAX)
		   ,@SchemaName sysname
		   ,@TableName sysname
		   ,@rowcount INT
		   ,@b VARCHAR(100) = CHAR(13) + '--------------------------' + CHAR(13)
		   ,@error BIT = 0;

	IF @@SERVERNAME <> 'dRCMSQLaz03'
	BEGIN
		RAISERROR('SCRIPT MUST BE RAN ON dRCMSQLaz03', 16, -1);
		SET @error = 1;
	END;
	IF @error = 0
	BEGIN

		PRINT @b + 'DROPPING TABLES' + @b;

		DECLARE cr_drop CURSOR LOCAL FOR SELECT name FROM DeveloperTest.sys.tables;

		OPEN cr_drop;
		FETCH NEXT FROM cr_drop
		INTO @TableName;

		WHILE @@FETCH_STATUS = 0 AND @error = 0
		BEGIN

			SET @sql
				= N'
	IF DB_NAME() <> ''DeveloperTest''
	BEGIN
		RAISERROR(''FATAL ERROR: Must BE RAN IN DeveloperTest DATABASE'',16,-1)
		set @error =1 
		return
	END

	DROP TABLE IF EXISTS ' + @TableName;
			EXECUTE DeveloperTest.dbo.sp_executesql @sql
											  ,N'@error bit output'
											  ,@error = @error OUTPUT;
			PRINT 'Dropped Table ' + @TableName;
			FETCH NEXT FROM cr_drop
			INTO @TableName;
		END;
		CLOSE cr_drop;
		DEALLOCATE cr_drop;


		--create tables
		IF @error = 0
		BEGIN
			PRINT @b + 'CREATING TABLES' + @b;
			DECLARE cr_create CURSOR LOCAL FOR
			SELECT SchemaName
				  ,TableName
			FROM @tables;

			OPEN cr_create;
			FETCH NEXT FROM cr_create
			INTO @SchemaName
				,@TableName;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @sql
					= N'SELECT * INTO DeveloperTest.' + @SchemaName + N'.' + @TableName + N' FROM RevCycleDB.' + @SchemaName
					  + N'.' + @TableName + N' SET @rowcount=@@ROWCOUNT';
				PRINT '--' + CHAR(13) + 'Creating table: ' + @SchemaName + '.' + @TableName;

				EXECUTE DeveloperTest.dbo.sp_executesql @sql
												  ,N'@rowcount int output'
												  ,@rowcount = @rowcount OUTPUT;
				PRINT CAST(@rowcount AS VARCHAR(20)) + ' rows inserted';

				FETCH NEXT FROM cr_create
				INTO @SchemaName
					,@TableName;
			END;
			CLOSE cr_create;
			DEALLOCATE cr_create;
		END;

		PRINT @b + 'DeveloperTest REFRESH SUCCESSFULLY COMPLETED' + @b;
	END;


END -- end of stored procedure
GO

/*
testing
begin tran;
exec [dbo].[Maintenance_DeveloperTestRefresh] @TableList = 'blah, blah2, blah3'
*/
-- End of 05) DACS-2955 - SQL Create alter procedure - Maintenance_DeveloperTestRefresh.sql
GO

-- Start of 01) DACS-2993 - Update PATIENT_DISPOSITION Table.sql

----------------------------------------
-- 01) DACS-2993 - SQL Script - Update Patient Disposition for Left Without Being Seen from False to true
----------------------------------------
GO

UPDATE
	PATIENT_DISPOSITION
SET
	OUTPATIENT_IND = 1
WHERE
	PATIENT_DISPOSITION_ID = 11
-- End of 01) DACS-2993 - Update PATIENT_DISPOSITION Table.sql
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
