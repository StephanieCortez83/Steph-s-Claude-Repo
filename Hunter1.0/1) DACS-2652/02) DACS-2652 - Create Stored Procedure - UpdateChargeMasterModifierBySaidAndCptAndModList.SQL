---------------------------------------------------------------------------------
-- 02) DACS-2652 - Create Stored Procedure - UpdateChargeMasterModifierBySaidAndCptAndModList.SQL
---------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
COMMIT TRAN;\
ROLLBACK TRAN;
*/