USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2652 - Create Stored Procedure - Maintenance_FindObjectsByName.SQL

---------------------------------------------------------------------------------
-- 01) DACS-2652 - Create Stored Procedure - Maintenance_FindObjectsByName.SQL
---------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_FindObjectsByName]
    @SearchString VARCHAR(255)
AS
BEGIN
	-- Adapted from SQL Script provided from Marcus Ferrell

	IF @SearchString IS NULL OR LEN(@SearchString) <= 1
	BEGIN
		SELECT 'Result' = 'Search String is too short';
		RETURN;
	END;

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT DISTINCT 
		  sysobjects.name AS [ObjectName] 
		, sysobjects.xtype AS [ObjectBaseType]
		, CASE WHEN sysobjects.xtype = 'P' THEN 'Stored Proc'
			WHEN sysobjects.xtype = 'TF' THEN 'Function'
			WHEN sysobjects.xtype = 'TR' THEN 'Trigger'
			WHEN sysobjects.xtype = 'V' THEN 'View'
			WHEN sysobjects.xtype = 'T' THEN 'TABLE'
		END AS [ObjectType]
	FROM 
		sysobjects,syscomments
	WHERE 
		sysobjects.id = syscomments.id
		AND sysobjects.type IN ('P','TF','TR','V','T')
		AND CHARINDEX(@SearchString, syscomments.text) > 0;
END
GO	

/*
testing:
	exec [dbo].[Maintenance_FindObjectsByName] @SearchString = 'sp_Get_DashboardPendingReport';
	exec [dbo].[Maintenance_FindObjectsByName] @SearchString = 'sp';
	exec [dbo].[Maintenance_FindObjectsByName] @SearchString = 's';
*/
-- End of 01) DACS-2652 - Create Stored Procedure - Maintenance_FindObjectsByName.SQL
GO

-- Start of 02) DACS-2652 - Create Stored Procedure - UpdateChargeMasterModifierBySaidAndCptAndModList.SQL

---------------------------------------------------------------------------------
-- 02) DACS-2652 - Create Stored Procedure - UpdateChargeMasterModifierBySaidAndCptAndModList.SQL
---------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[UpdateChargeMasterModifierBySaidAndCptAndModList]
      @SaId INT					-- Service Agreement affected by this stored procedure
    , @CptCode VARCHAR(100)		-- Single CPT Code
    , @ModList VARCHAR(1023)	-- Comma delimited list of CPT Code Modifiers
	, @Uid INT = 10149 			-- User performing action.  Marcus Ferrel
AS
BEGIN

	IF @SaId <= 0
	BEGIN
		SELECT 'Error' = 'Service Agreement Id is Invalid';
		RETURN;
	END;
	
	DECLARE @CountSaid INT = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT] WHERE [SERVICE_AGREEMENT_ID]= @SaId)
	IF @CountSaid <= 0
	BEGIN
		SELECT 'Error' = 'Service Agreement Id not found';
		RETURN;
	END;

	IF @CptCode IS NULL OR LEN(@CptCode) < 5 OR LEN(@CptCode) > 5
	BEGIN
		SELECT 'Error' = 'CPT Code is invalid';
		RETURN;
	END;

	IF @ModList IS NULL OR LEN(@ModList) < 2
	BEGIN
		SELECT 'Error' = 'Modifier List is invalid';
		RETURN;
	END;
	
	DECLARE @DoInsert DATETIME = GETDATE();

	PRINT('@SaId = ' + CAST(@SaId AS VARCHAR(20)));
	PRINT('@CptCode = ' + @CptCode);
	PRINT('@ModList = ' + @ModList);
	PRINT('@Uid = ' + CAST(@Uid AS VARCHAR(20)));
	PRINT('@DoInsert = ' + CAST(@DoInsert AS VARCHAR(50)));

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @CountCMRecords INT = (
									SELECT count([CHARGE_MASTER_ID]) 
									FROM [RevCycleDB].[dbo].[CHARGE_MASTER] 
									WHERE 
										[SERVICE_AGREEMENT_ID]= @SaId 
										AND [CPT_CODE]= @CptCode
										AND [EFFECTIVE_DATE] <= GETDATE() AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
								  )
	IF @CountCMRecords <= 0
	BEGIN
		SELECT 'Error' = 'No specified CPT Codes present';
		RETURN;
	END;
	
	-- Get the affected unique charge_master_ids related to the specified CPT Code
	IF OBJECT_ID('tempdb..#TmpFetchCptIds') IS NOT NULL
		DROP TABLE #TmpFetchCptIds;

	CREATE TABLE #TmpFetchCptIds ([CMId] INT);
	DECLARE @FetchCptCode VARCHAR(5);

	INSERT INTO #TmpFetchCptIds ([CMId]) 
		SELECT TOP 100 [CHARGE_MASTER_ID] AS [CMId] 
		FROM [dbo].[CHARGE_MASTER] 
		WHERE 
			[CPT_CODE] = @CptCode 
			AND [SERVICE_AGREEMENT_ID] = @SAId
			AND [EFFECTIVE_DATE] <= GETDATE() AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE());

	-- breakup the modifiers and insert each one into cm modifiertable individually for the CM cpt code,and @SaId
	IF OBJECT_ID('tempdb..#TmpFetchMods') IS NOT NULL
		DROP TABLE #TmpFetchMods;

	CREATE TABLE #TmpFetchMods ([Mods] varchar(5));
	INSERT INTO #TmpFetchMods ([Mods]) SELECT * FROM STRING_SPLIT(@ModList,',') ;
	DELETE FROM #TmpFetchMods WHERE ([Mods] IS NULL OR LEN([Mods]) <= 0)

	DECLARE @TotalToProcessCount INT = (SELECT COUNT(*) from #TmpFetchCptIds);
	DECLARE @ProcessCount INT = 1;
	DECLARE @WorkingCptId INT;
	
	DECLARE cursorCptIds CURSOR LOCAL FOR SELECT * FROM #TmpFetchCptIds;
	OPEN cursorCptIds;
	FETCH NEXT FROM cursorCptIds INTO @WorkingCptId;

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT('Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) + ' ): Cpt= [' + CAST(@WorkingCptId AS VARCHAR(20)) + ']');
		
		INSERT INTO [dbo].[CHARGE_MASTER_MODIFIER] ([SERVICE_AGREEMENT_ID],[CHARGE_MASTER_ID],[MODIFIER],[CREATION_DATE_TIME],[CREATING_USER_PROFILE_ID],[CHANGED_DATE_TIME],[CHANGING_USER_PROFILE_ID])
			SELECT @SAId, @WorkingCptId, LTRIM(RTRIM(tfm.[Mods])), @DoInsert, @Uid, @DoInsert, @Uid
			FROM #TmpFetchMods tfm
			WHERE [Mods] NOT IN (SELECT DISTINCT [MODIFIER] FROM [dbo].[CHARGE_MASTER_MODIFIER] WHERE [SERVICE_AGREEMENT_ID] = @SAId AND [CHARGE_MASTER_ID] = @WorkingCptId );

		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorCptIds INTO @WorkingCptId;
	END  -- end fetch cursorCptIds while loop

	-- cleanup our cursor
	CLOSE cursorCptIds;  
	DEALLOCATE cursorCptIds; 
	
	SET @CountCMRecords = (
							SELECT count(*) 
							FROM [RevCycleDB].[dbo].[CHARGE_MASTER_MODIFIER] 
							WHERE 
								[SERVICE_AGREEMENT_ID] = @SAId 
								AND [CHARGE_MASTER_ID] IN (SELECT [CMId] FROM #TmpFetchCptIds)
						  );
	
	SELECT 'Result' = 'Count CMM Inserted Records =' + CAST(@CountCMRecords AS VARCHAR(20));


END
GO	

/*
testing:
BEGIN TRAN;
	exec [dbo].[UpdateChargeMasterModifierBySaidAndCptAndModList] @SaId= 555208 , @CptCode= '0001U', @ModList= 'XA,XB,XC,XD,XE,';
	exec [dbo].[UpdateChargeMasterModifierBySaidAndCptAndModList] @SaId= 555208 , @CptCode= '0002A', @ModList= 'XF,XG,XH,XI,XJ,', @Uid= 12089;
*/
-- End of 02) DACS-2652 - Create Stored Procedure - UpdateChargeMasterModifierBySaidAndCptAndModList.SQL
GO

-- Start of 03) DACS-2652 - Create Stored Procedure - UpdateChargeMasterModifierBySaidAndCmIdAndModList.SQL

---------------------------------------------------------------------------------
-- 03) DACS-2652 - Create Stored Procedure - UpdateChargeMasterModifierBySaidAndCmIdAndModList.SQL
---------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[UpdateChargeMasterModifierBySaidAndCmIdAndModList]
      @SaId INT					-- Service Agreement affected by this stored procedure
    , @ChargeMasterId INT		-- Single Charge Master Id
    , @ModList VARCHAR(1023)	-- Comma delimited list of CPT Code Modifiers
	, @Uid INT = 10149 			-- User performing action.  Marcus Ferrel
AS
BEGIN

	IF @SaId <= 0
	BEGIN
		SELECT 'Error' = 'Service Agreement Id is Invalid';
		RETURN;
	END;
	
	DECLARE @CountSaid INT = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT] WHERE [SERVICE_AGREEMENT_ID]= @SaId)
	IF @CountSaid <= 0
	BEGIN
		SELECT 'Error' = 'Service Agreement Id not found';
		RETURN;
	END;

	IF @ChargeMasterId <= 0
	BEGIN
		SELECT 'Error' = 'Charge Master Id is invalid';
		RETURN;
	END;

	IF @ModList IS NULL OR LEN(@ModList) < 2
	BEGIN
		SELECT 'Error' = 'Modifier List is invalid';
		RETURN;
	END;
	
	DECLARE @DoInsert DATETIME = GETDATE();

	PRINT('@SaId = ' + CAST(@SaId AS VARCHAR(20)));
	PRINT('@ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(20)));
	PRINT('@ModList = ' + @ModList);
	PRINT('@Uid = ' + CAST(@Uid AS VARCHAR(20)));
	PRINT('@DoInsert = ' + CAST(@DoInsert AS VARCHAR(50)));

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @CountCMRecords INT = (
									SELECT count([CHARGE_MASTER_ID]) 
									FROM [RevCycleDB].[dbo].[CHARGE_MASTER] 
									WHERE 
										[SERVICE_AGREEMENT_ID]= @SaId 
										AND [CHARGE_MASTER_ID]= @ChargeMasterId
								  )
	IF @CountCMRecords <= 0
	BEGIN
		SELECT 'Error' = 'No specified Charge Master Id present';
		RETURN;
	END;

	-- breakup the modifiers and insert each one into cm modifiertable individually for the CM cpt code,and @SaId
	IF OBJECT_ID('tempdb..#TmpFetchMods') IS NOT NULL
		DROP TABLE #TmpFetchMods;

	CREATE TABLE #TmpFetchMods ([Mods] varchar(5));
	INSERT INTO #TmpFetchMods ([Mods]) SELECT * FROM STRING_SPLIT(@ModList,',') ;
	DELETE FROM #TmpFetchMods WHERE ([Mods] IS NULL OR LEN([Mods]) <= 0)
	
	PRINT('Processing Charge Master Id [' + CAST(@ChargeMasterId AS VARCHAR(20)) + ']');
		
	INSERT INTO [dbo].[CHARGE_MASTER_MODIFIER] ([SERVICE_AGREEMENT_ID],[CHARGE_MASTER_ID],[MODIFIER],[CREATION_DATE_TIME],[CREATING_USER_PROFILE_ID],[CHANGED_DATE_TIME],[CHANGING_USER_PROFILE_ID])
		SELECT @SAId, @ChargeMasterId, LTRIM(RTRIM(tfm.[Mods])), @DoInsert, @Uid, @DoInsert, @Uid
		FROM #TmpFetchMods tfm
		WHERE [Mods] NOT IN (SELECT DISTINCT [MODIFIER] FROM [dbo].[CHARGE_MASTER_MODIFIER] WHERE [SERVICE_AGREEMENT_ID] = @SAId AND [CHARGE_MASTER_ID] = @ChargeMasterId );
	
	SET @CountCMRecords = (
							SELECT count(*) 
							FROM [RevCycleDB].[dbo].[CHARGE_MASTER_MODIFIER] 
							WHERE 
								[SERVICE_AGREEMENT_ID] = @SAId 
								AND [CHARGE_MASTER_ID]= @ChargeMasterId
						  );
	
	SELECT 'Result' = 'SUCCESS: Count CMM Inserted Records =' + CAST(@CountCMRecords AS VARCHAR(20));

END
GO	

/*
testing:
BEGIN TRAN;
	exec [dbo].[UpdateChargeMasterModifierBySaidAndCmIdAndModList] @SaId= 555208 , @ChargeMasterId= 2100641413, @ModList= 'XA,XB,XC,XD,XE,';
	exec [dbo].[UpdateChargeMasterModifierBySaidAndCmIdAndModList] @SaId= 555208 , @ChargeMasterId= 2100641415, @ModList= 'XF,XG,XH,XI,XJ,', @Uid= 12089;
*/
-- End of 03) DACS-2652 - Create Stored Procedure - UpdateChargeMasterModifierBySaidAndCmIdAndModList.SQL
GO

-- Start of 04) DACS-2652 - Create Stored Procedure - InsertChargeMasterForImport.SQL

---------------------------------------------------------------------------------
-- 04) DACS-2652 - Create Stored Procedure - InsertChargeMasterForImport.SQL
---------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[InsertChargeMasterForImport]
      @SaId INT					-- Service Agreement affected by this stored procedure
	, @Uid INT = 10149 			-- User performing action.  Marcus Ferrel
	, @CMCategoryId INT 
	, @Description VARCHAR(100)
	, @CptCode VARCHAR(5)
	, @BillingCode VARCHAR(20)
	, @ModifierRequired BIT
	, @CMDeptartmentId INT
	, @CMUsageCode INT
	, @EffectiveDate DATETIME = NULL
	, @ExpirationDate DATETIME= NULL
	, @DisplaySeq INT
	, @LongDescription VARCHAR(1100)
	, @MaxQuantity INT
	, @PatientClassId INT
	, @AliasBillingCode VARCHAR(20)
	, @BypassAutoApproval BIT
	, @ObsPatientArrivalSourceId INT
	, @ObsHourTypeId INT
	, @ObsTelemetry BIT
	, @AllowNegativeUnitsInd BIT
	, @SpecialHandlingInstructions VARCHAR(2000)
	, @AgeMinimum INT
	, @AgeMaximum INT
AS
BEGIN

	IF @SaId IS NULL OR @SaId <= 0
	BEGIN
		SELECT 'Error' = -2 ,'Message' = 'Service Agreement Id is Invalid';
		RETURN;
	END;
	
	IF @Uid IS NULL OR @Uid <= 0
	BEGIN
		SELECT 'Error' = -3 ,'Message' = 'User Profile Id is Invalid';
		RETURN;
	END;
	
	IF @EffectiveDate IS NULL
		SET @EffectiveDate = GETDATE();

	IF @ExpirationDate IS NULL
		SET @ExpirationDate = DATEADD(yy,100,@EffectiveDate);
	

	DECLARE @DOS DATETIME = GETDATE();

	INSERT INTO [dbo].[CHARGE_MASTER]
		(	 
			 [SERVICE_AGREEMENT_ID]
            ,[CHARGE_MASTER_CATEGORY_ID]
            ,[DESCRIPTION]
			,[CPT_CODE]
            ,[BILLING_CODE]
            ,[MODIFIER_REQUIRED]
            ,[CHARGE_MASTER_DEPT_ID]
            ,[CHARGE_MASTER_USAGE_CODE]
            ,[EFFECTIVE_DATE]
            ,[EXPIRATION_DATE]
            ,[DISPLAY_SEQ]
            ,[LONG_DESCRIPTION]
            ,[MAX_QUANTITY]
            ,[PATIENT_CLASS_ID]
            ,[ALIAS_BILLING_CODE]
            ,[CREATION_DATE_TIME]
            ,[CREATING_USER_PROFILE_ID]
            ,[CHANGED_DATE_TIME]
            ,[CHANGING_USER_PROFILE_ID]
            ,[BYPASS_AUTO_APPROVAL]
            ,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
            ,[OBSERVATION_HOUR_TYPE_ID]
            ,[OBSERVATION_TELEMETRY]
            ,[ALLOW_NEGATIVE_UNITS_IND]
            ,[SPECIAL_HANDLING_INSTRUCTIONS]
            ,[AGE_MINIMUM]
            ,[AGE_MAXIMUM]
		)
	VALUES
		(
			 @SaId
            ,@CMCategoryId
            ,@Description
			,@CptCode
            ,@BillingCode
            ,@ModifierRequired
            ,@CMDeptartmentId
            ,@CMUsageCode
            ,@EffectiveDate
            ,@ExpirationDate
            ,@DisplaySeq
            ,@LongDescription
            ,@MaxQuantity
            ,@PatientClassId
            ,@AliasBillingCode
            ,@DOS
            ,@Uid
            ,@DOS
            ,@Uid
            ,@BypassAutoApproval
            ,@ObsPatientArrivalSourceId
            ,@ObsHourTypeId
            ,@ObsTelemetry
            ,@AllowNegativeUnitsInd
            ,@SpecialHandlingInstructions
            ,@AgeMinimum
            ,@AgeMaximum
		)
		
	SELECT SCOPE_IDENTITY()

END
GO	

/*
testing:
BEGIN TRAN;
	exec [dbo].[UpdateChargeMasterModifierBySaidAndCptAndModList] @SaId= 555208 , @CptCode= '0001U', @ModList= 'XA,XB,XC,XD,XE,';
	exec [dbo].[UpdateChargeMasterModifierBySaidAndCptAndModList] @SaId= 555208 , @CptCode= '0002A', @ModList= 'XF,XG,XH,XI,XJ,', @Uid= 12089;
*/
-- End of 04) DACS-2652 - Create Stored Procedure - InsertChargeMasterForImport.SQL
GO

-- Start of 05) DACS-2652 - Create Stored Procedure - ModifyChargeMasterAmountByCMIdAndAmount.SQL

---------------------------------------------------------------------------------
-- 05) DACS-2652 - Create Stored Procedure - ModifyChargeMasterAmountByCMIdAndAmount.SQL
---------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ModifyChargeMasterAmountByCMIdAndAmount]
      @ChargeMasterId INT		-- Single Charge Master Id
    , @Amount money
AS
BEGIN

	IF @ChargeMasterId IS NULL OR @ChargeMasterId <= 0
	BEGIN
		SELECT 'Error' = 'Charge Master Id is invalid';
		RETURN;
	END;

	IF @Amount IS NULL OR @Amount < 0.0
	BEGIN
		SELECT 'Error' = 'Amount is invalid';
		RETURN;
	END;
	
	DECLARE @DoInsert DATETIME = GETDATE();
	DECLARE @DoExpirePrev DATETIME = DATEADD(dd,-1,@DoInsert);
	DECLARE @DoExpire DATETIME =  DATEADD(yy,100,@DoInsert);

	PRINT('@ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(20)));
	PRINT('@Amount = ' + CAST(@Amount AS VARCHAR(50)));
	PRINT('@DoInsert = ' + CAST(@DoInsert AS VARCHAR(50)));
	PRINT('@DoExpirePrev = ' + CAST(@DoExpirePrev AS VARCHAR(50)));
	PRINT('@DoExpire = ' + CAST(@DoExpire AS VARCHAR(50)));

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @CountCMAmount INT = (SELECT COUNT(*) FROM [CHARGE_MASTER_CHARGE_AMOUNT] WHERE [charge_master_id] = @ChargeMasterId);
	
	IF @CountCMAmount > 0
	BEGIN
		UPDATE [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT]
			SET [EXPIRATION_DATE] = @DoExpirePrev
		WHERE 
			[CHARGE_MASTER_ID] = @ChargeMasterId
			AND [EFFECTIVE_DATE] < @DoInsert
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @DoInsert);
	END;

	SET @CountCMAmount = (
			SELECT COUNT(*) 
			FROM 
				[CHARGE_MASTER_CHARGE_AMOUNT] 
			WHERE 
				[charge_master_id] = @ChargeMasterId
				AND [EFFECTIVE_DATE] <= @DoInsert
				AND [EXPIRATION_DATE] > @DoInsert	
			);
	
	IF @CountCMAmount > 0
	BEGIN
		SELECT 'Error' = 'Overlapping effective dates.';
		RETURN;
	END;


	BEGIN TRANSACTION;

	BEGIN TRY
		INSERT INTO [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT]
			([CHARGE_MASTER_ID], [CHARGE_AMOUNT], [EFFECTIVE_DATE], [EXPIRATION_DATE])
		VALUES
			(@ChargeMasterId, @Amount, @DoInsert, @DoExpire);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		SELECT 'Error' = 'Insert exception: ' + CAST( ERROR_NUMBER() AS VARCHAR(50)) + ' : ' + CAST( ERROR_MESSAGE() AS VARCHAR(5000));
		ROLLBACK TRANSACTION;
		RETURN;
	END CATCH;

	SELECT 'Success' = 'SUCCESS';

END
GO	

-- End of 05) DACS-2652 - Create Stored Procedure - ModifyChargeMasterAmountByCMIdAndAmount.SQL
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
