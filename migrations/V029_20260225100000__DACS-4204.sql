SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @CabName VARCHAR(20) = 'CAB_4204';
DECLARE @CabDesc VARCHAR(200) = 'Enable/Disables DACS-4204 SPROC variant within LogNotesListDAO.cs';
DECLARE @CabValue INT = 26;
DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN (@CabDesc))
	INSERT INTO 
		[TYPE_CODE]
		(
			[NAME]
		   ,[KEY]
		   ,[VALUE]
		   ,[DISPLAY_NAME]
		   ,[SHORT_NAME]
		   ,[DESCRIPTION]
		)
		VALUES
		(
			'ApplicationFeatureTypeCode'    --NAME
		   ,@CabName						--KEY
		   ,@CabValue  						--VALUE
		   ,@CabName						--DISPLAY_NAME
		   ,@CabName  						--SHORT_NAME
		   ,@CabDesc 						--DESCRIPTION
		)
ELSE
	PRINT('Type Code already exists for [' + @CabName + '].  Action skipped.');

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = @CabValue)
	INSERT INTO 
		[dbo].[ApplicationFeature]
		(
			 [DateTimeCreated]
			,[CreatedByUserProfileId]
			,[DateTimeLastUpdated]
			,[LastUpdatedByUserProfileId]
			,[ApplicationFeatureDomainObjectTypeCode]
			,[DomainObjectId]
			,[ApplicationFeatureTypeCode]
		)
	VALUES
		(
			 @dtCreated
			,@Uid
			,@dtCreated
			,@Uid
			,5
			,2147483647	--ALL
			,@CabValue
		)
ELSE
	PRINT('Application Feature already exists for [' + @CabName + '].  Action skipped.');
GO

-- show some results for DBA/release verification logging
SELECT TOP 2 * FROM APPLICATIONFEATURE ORDER BY 1 DESC;
SELECT TOP 100 * FROM TYPE_CODE WHERE [NAME] = 'ApplicationFeatureTypeCode';
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectExistsLogNoteListDAOByChartIdAndLogNoteCategoryIdAndCompletedByUserProfileIDAndCompletionDate]
	 @ChartId INT	
    ,@LogNoteCategoryId INT	= NULL
    ,@CompletedByUserProfileID INT = NULL
    ,@CompletionDate DATETIME = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	-- script will not work well if @ChartID IS NULL AND @CompletionDate IS NOT NULL AND @CompletedByUserProfileID IS NULL.  ACS is handling this check for now.
	
	DECLARE @minDateTime DATETIME = CAST(CAST(DATEADD(MONTH, -42, GETDATE()) AS DATE) AS DATETIME);
	DECLARE @theDateTime DATETIME = @minDateTime;
	IF @CompletionDate IS NOT NULL AND @CompletionDate > @theDateTime
		SET @theDateTime = @CompletionDate
		
	SET @theDateTime = CAST(CAST(@theDateTime AS DATE) AS DATETIME);
	
	DECLARE @theDateTimeLimit DATETIME = GETDATE();
	IF @theDateTime > @minDateTime
		SET @theDateTimeLimit = DATEADD(second, 86399, @theDateTime);
	
	/* -- testing
	PRINT('@ChartId = ' + CAST(@ChartId AS VARCHAR(50)))
	PRINT('@LogNoteCategoryId = ' + CAST(@LogNoteCategoryId AS VARCHAR(50)))
	PRINT('@CompletedByUserProfileID = ' + CAST(@CompletedByUserProfileID AS VARCHAR(50)))
	PRINT('@CompletionDate = ' + CAST(@CompletionDate AS VARCHAR(50)))

	PRINT('@theDateTime = ' + CAST(@theDateTime AS VARCHAR(50)))
	PRINT('@theDateTimeLimit = ' + CAST(@theDateTimeLimit AS VARCHAR(50)))
	*/

	IF EXISTS
		(
			SELECT TOP 1 1
			FROM
				[LOG_NOTE]
			WHERE
				[CHART_ID] = @ChartId
				AND [COMPLETION_DATE] BETWEEN @theDateTime AND @theDateTimeLimit
				AND
				(
					@CompletedByUserProfileID IS NULL
					OR
					[COMPLETED_BY_USER_ID] = @CompletedByUserProfileID
				)
				AND
				(
					@LogNoteCategoryId IS NULL
					OR
					[CATEGORY_ID] = @LogNoteCategoryId
				)
		)
	RETURN 1;

END;
GO

DECLARE @exp VARCHAR(50) = (SELECT CAST(modify_date AS VARCHAR(50)) FROM sys.objects WHERE type = 'P' AND name = 'SelectExistsLogNoteListDAOByChartIdAndLogNoteCategoryIdAndCompletedByUserProfileIDAndCompletionDate');

IF OBJECT_ID('dbo.SelectExistsLogNoteListDAOByChartIdAndLogNoteCategoryIdAndCompletedByUserProfileIDAndCompletionDate', 'P') IS NOT NULL
	PRINT ('SPROC SelectExistsLogNoteListDAOByChartIdAndLogNoteCategoryIdAndCompletedByUserProfileIDAndCompletionDate last changed ' + @exp);
ELSE
	PRINT ('failed to create SPROC SelectExistsLogNoteListDAOByChartIdAndLogNoteCategoryIdAndCompletedByUserProfileIDAndCompletionDate');
GO