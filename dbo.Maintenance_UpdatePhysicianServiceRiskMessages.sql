SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_UpdatePhysicianServiceRiskMessages]
     @RiskSearchString varchar(100) 		-- uses a LIKE statement so make sure to format as required
    ,@NewRiskMessage varchar(4000) = ''
	,@BackupPhysicianServiceTable bit = 0
	,@TestMode bit = 0 						-- Just returns first found string
AS
BEGIN
/*
Suggested search statements:
'<b>Minimal%'
'<b>Low%'
'<b>Moderate%'
'<b>High Risk%'
*/

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @BackupPhysicianServiceTable <> 0
	BEGIN
		DECLARE @DestTable varchar(512) = 'PHYSICIAN_SERVICE_BACKUP-';
		SET @DestTable = @DestTable + CAST(datediff(day, '1899-12-30T00:00:00', getdate()) AS varchar(50));
		
		PRINT('Backing up PHYSICIAN_SERVICE Table to @DestTable:' + @DestTable);
		
		exec [dbo].[Maintenance_BackupTable] @SrcTable = 'PHYSICIAN_SERVICE'
			, @DestTable = @DestTable ;
	END;
	
	DECLARE @countFound INT;
		
	PRINT('finding rows with [' + @RiskSearchString + '] to update.');
	SET @countFound = (
		SELECT COUNT(*) FROM [RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
	WHERE 
		[CATEGORY_ID] = 3 AND [SUBCATEGORY_ID] = 3 AND [MINOR_CATEGORY] = 1
		AND [PLAN_ID] = 1 AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = 8 AND ([EFFECTIVE_DATE] <= GETDATE() AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE()))
		AND [DESCRIPTION] LIKE @RiskSearchString
		);

	IF @TestMode <> 0 OR (@NewRiskMessage IS NULL OR LEN(@NewRiskMessage) <= 0)
	BEGIN
		PRINT('Found record count: ' + CAST(@countFound AS varchar(30)));
		
		PRINT('Test Mode Results for [' + @RiskSearchString + ']:');

		SELECT TOP 1 [DESCRIPTION] FROM [RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
		WHERE 
			[CATEGORY_ID] = 3 AND [SUBCATEGORY_ID] = 3 AND [MINOR_CATEGORY] = 1
			AND [PLAN_ID] = 1 AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = 8 AND ([EFFECTIVE_DATE] <= GETDATE() AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE()))
			AND [DESCRIPTION] LIKE @RiskSearchString;
	
		RETURN;
	END;

	IF @countFound > 0
	BEGIN
		PRINT('updating record count: ' + CAST(@countFound AS varchar(30)));
		
		UPDATE [RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
			SET [DESCRIPTION] = @NewRiskMessage
		WHERE 
			[CATEGORY_ID] = 3 AND [SUBCATEGORY_ID] = 3 AND [MINOR_CATEGORY] = 1 
			AND [PLAN_ID] = 1 AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = 8 AND ([EFFECTIVE_DATE] <= GETDATE() AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE()))
			AND [DESCRIPTION] LIKE @RiskSearchString;

		SELECT 'Result' = @countFound;
		RETURN;
	END
	ELSE
	BEGIN
		PRINT('No rows to update for: ' + @RiskSearchString);
	END;

	SELECT 'Result' = 0;
END
GO
