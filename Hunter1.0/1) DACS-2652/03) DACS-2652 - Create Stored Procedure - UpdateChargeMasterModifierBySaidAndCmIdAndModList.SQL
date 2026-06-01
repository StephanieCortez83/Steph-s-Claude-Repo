---------------------------------------------------------------------------------
-- 03) DACS-2652 - Create Stored Procedure - UpdateChargeMasterModifierBySaidAndCmIdAndModList.SQL
---------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
COMMIT TRAN;\
ROLLBACK TRAN;
*/