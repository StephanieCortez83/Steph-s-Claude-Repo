SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CHART_ACCESS_INSERT]
    @USER_PROFILE_ID                        INT 
   ,@CHART_ID                               INT
   ,@ACCESS_DATE_TIME                       DATETIME
   ,@CHART_ACCESS_EVENT_TYPE_CODE           VARCHAR(1)    = NULL
   ,@EVENT_COMPLETION_DATE_TIME             DATETIME      = NULL
   ,@CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE VARCHAR(1)    = NULL
   ,@SECONDARY_EVENT_COMPLETION_DATE_TIME   DATETIME      = NULL
   ,@LogNoteCategoryId						INT			  = 0
   ,@LogNoteSummary							VARCHAR(256)  = NULL
   ,@LogNoteDetail							VARCHAR(4000) = NULL
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	INSERT INTO [CHART_ACCESS]
	(
		[USER_PROFILE_ID]
	   ,[CHART_ID]
	   ,[ACCESS_DATE_TIME]
	   ,[CHART_ACCESS_EVENT_TYPE_CODE]
	   ,[EVENT_COMPLETION_DATE_TIME]
	   ,[CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE]
	   ,[SECONDARY_EVENT_COMPLETION_DATE_TIME]    
	)
	VALUES
	(
		@USER_PROFILE_ID
	   ,@CHART_ID
	   ,@ACCESS_DATE_TIME
	   ,@CHART_ACCESS_EVENT_TYPE_CODE
	   ,@EVENT_COMPLETION_DATE_TIME
	   ,@CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE
	   ,@SECONDARY_EVENT_COMPLETION_DATE_TIME 
	);

	IF @LogNoteCategoryId IS NULL OR @LogNoteCategoryId <= 0
		RETURN;
		
	DECLARE @dos DATETIME = GETDATE();
		
	INSERT INTO [LOG_NOTE]
	(
		 [CHART_ID]
		,[COMPLETION_DATE]
		,[COMPLETED_BY_USER_ID]
		,[SUMMARY]
		,[DETAIL]
		,[CATEGORY_ID]
		,[SYSTEM_DEFINED]
		,[CHART_ADJUSTMENT_ID]
		,[CREATION_DATE_TIME]
		,[CREATING_USER_PROFILE_ID]
		,[CHANGED_DATE_TIME]
		,[CHANGING_USER_PROFILE_ID]
	)
	VALUES
	(
		 @CHART_ID
		,@dos
		,@USER_PROFILE_ID
		,@LogNoteSummary
		,@LogNoteDetail
		,@LogNoteCategoryId
		,1
		,-1
		,@dos
		,@USER_PROFILE_ID
		,@dos
		,@USER_PROFILE_ID
	);
END
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4895 SPROC variant within ChartAccessDAO.cs'))
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
			'ApplicationFeatureTypeCode'                                       	--NAME
		   ,'CAB_4895'                                                    		--KEY
		   ,6                                                                  	--VALUE
		   ,'CAB_4895'                                                    		--DISPLAY_NAME
		   ,'CAB_4895'                                                         	--SHORT_NAME
		   ,'Enable/Disables DACS-4895 SPROC variant within ChartAccessDAO.cs' 	--DESCRIPTION
		)
ELSE
	PRINT('Type Code already exists.  Action skipped.');
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 6)
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
			,2147483647															--ALL
			,6
		)
ELSE
	PRINT('Application Feature already exists.  Action skipped.');
GO

