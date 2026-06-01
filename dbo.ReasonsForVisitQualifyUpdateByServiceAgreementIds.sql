SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ReasonsForVisitQualifyUpdateByServiceAgreementIds]
	 @SourceSAId INT
	,@TargetSAId INT
	,@UPId INT
	,@EffectiveDate DATETIME
	,@ExpirationDate DATETIME
	,@InsDate DATETIME = NULL
	,@MaxToProcess INT = 1000
AS
BEGIN

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
	BEGIN
		SET @InsDate = CONVERT (date, GETDATE());
	END;

	IF @MaxToProcess IS NULL OR @MaxToProcess <= 0
	BEGIN
		SET @MaxToProcess = 1000;
	END;

	IF OBJECT_ID('tempdb..#TempRows') IS NOT NULL
	BEGIN
		DROP TABLE #TempRows
	END;

	-- Fill temp table with our data
	SELECT 
		   [SERVICE_AGREEMENT_ID]
		  ,[DESCRIPTION]
		  ,[CREATION_DATE_TIME]
		  ,[CREATING_USER_PROFILE_ID]
		  ,[CHANGED_DATE_TIME]
		  ,[CHANGING_USER_PROFILE_ID]	
	INTO #TempRows
	FROM
		(SELECT 
			   @TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,[DESCRIPTION]
			  ,@InsDate AS [CREATION_DATE_TIME]
			  ,@UPId AS [CREATING_USER_PROFILE_ID]
			  ,@InsDate AS [CHANGED_DATE_TIME]
			  ,@UPId AS [CHANGING_USER_PROFILE_ID]
		FROM
			[RevCycleDB].[dbo].[SERVICE_AGREEMENT_REASON_FOR_VISIT_CATEGORY] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([DESCRIPTION])) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([DESCRIPTION])) ) 
						FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_REASON_FOR_VISIT_CATEGORY] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
				)
		) AS sourceList

	DECLARE @tempTableRowCount INT = (SELECT COUNT(*) FROM #TempRows);

	IF @tempTableRowCount <= 0
	BEGIN
		SELECT Result = 0, Error = 'No new data rows to insert';
		RETURN;
	END;

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_REASON_FOR_VISIT_CATEGORY]
			(
			   [SERVICE_AGREEMENT_ID]
			  ,[DESCRIPTION]
			  ,[CREATION_DATE_TIME]
			  ,[CREATING_USER_PROFILE_ID]
			  ,[CHANGED_DATE_TIME]
			  ,[CHANGING_USER_PROFILE_ID]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[DESCRIPTION]
				  ,#TempRows.[CREATION_DATE_TIME]
				  ,#TempRows.[CREATING_USER_PROFILE_ID]
				  ,#TempRows.[CHANGED_DATE_TIME]
				  ,#TempRows.[CHANGING_USER_PROFILE_ID]
			From #TempRows;

		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		SELECT Result = -4, 
			Error = 'Error: Exception occurred.  Rollback Processed. Error = ' 
				+ CAST(ERROR_NUMBER() AS VARCHAR(30)) 
				+ ' :: ' + CAST(ERROR_MESSAGE() AS VARCHAR(4000));
		ROLLBACK TRANSACTION;
	END CATCH;


	DECLARE @resultCount INT = (SELECT COUNT([REASON_FOR_VISIT_CATEGORY_ID]) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_REASON_FOR_VISIT_CATEGORY] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
