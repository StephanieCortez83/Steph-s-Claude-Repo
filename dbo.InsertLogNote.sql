SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------
-- alter stored procedure
----------------
CREATE   PROCEDURE [dbo].[InsertLogNote] 
	 @ChartId INT NULL
	,@Summary VARCHAR(256) NULL
	,@Detail VARCHAR(4000) NULL
	,@SystemDefined BIT NULL
	,@CompletionDate DATETIME NULL
	,@CompletedByUserId INT NULL
	,@CategoryId INT NULL
	,@ChartAdjustmentId INT NULL
	,@CreatingUserProfileId INT NULL
WITH EXEC AS CALLER AS
BEGIN
	DECLARE @creationDate DATETIME = GETDATE();
	
	INSERT INTO [dbo].[LOG_NOTE]
	(
		 [CHART_ID]
		,[SUMMARY]
		,[DETAIL]
		,[SYSTEM_DEFINED]
		,[COMPLETION_DATE]
		,[COMPLETED_BY_USER_ID]
		,[CATEGORY_ID]
		,[CHART_ADJUSTMENT_ID]
		,[CREATION_DATE_TIME]
		,[CREATING_USER_PROFILE_ID]
		,[CHANGED_DATE_TIME]
		,[CHANGING_USER_PROFILE_ID]
	)
	VALUES
	(
		 @ChartId
		,@Summary
		,@Detail
		,@SystemDefined
		,@CompletionDate
		,@CompletedByUserId
		,@CategoryId
		,@ChartAdjustmentId
		,@creationDate
		,@CreatingUserProfileId
		,@creationDate
		,@CreatingUserProfileId
	);

	SELECT @@IDENTITY;
	
END -- end SPROC
GO
