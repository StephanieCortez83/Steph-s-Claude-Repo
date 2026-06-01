SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ChargeMasterCategoriesQualifyUpdateByServiceAgreementIds]
	 @SourceSAId INT
	,@TargetSAId INT
	,@UPId INT
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


	IF OBJECT_ID('tempdb..#TempCategories') IS NOT NULL
	BEGIN
		DROP TABLE #TempCategories
	END;

	-- Fill temp table with our data
	SELECT 
		 [SERVICE_AGREEMENT_ID]
		,[VISIBLE]
		,[SORT_ORDER]
		,[DESCRIPTION]
		,[INFUSION_CATEGORY]
		,[CREATION_DATE_TIME]
		,[CREATING_USER_PROFILE_ID]
		,[CHANGED_DATE_TIME]
		,[CHANGING_USER_PROFILE_ID]
		,[OBSERVATION_CATEGORY]
		,[SUPPLY_CATEGORY]
		,[COPIED_FROM_CATEGORY_ID]
	INTO #TempCategories
	FROM
		(SELECT 
				 @TargetSAId AS [SERVICE_AGREEMENT_ID]
				,[VISIBLE]
				,[SORT_ORDER]
				,[DESCRIPTION]
				,[INFUSION_CATEGORY]
				,@InsDate AS [CREATION_DATE_TIME]
				,@UPId AS [CREATING_USER_PROFILE_ID]
				,@InsDate AS [CHANGED_DATE_TIME]
				,@UPId AS [CHANGING_USER_PROFILE_ID]
				,[OBSERVATION_CATEGORY]
				,[SUPPLY_CATEGORY]
				,[CHARGE_MASTER_CATEGORY_ID] AS [COPIED_FROM_CATEGORY_ID]
		FROM
			[RevCycleDB].[dbo].[CHARGE_MASTER_CATEGORY] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND LOWER(RTRIM([DESCRIPTION])) NOT IN 
				(
					SELECT DISTINCT LOWER(RTRIM([DESCRIPTION])) 
						FROM [RevCycleDB].[dbo].[CHARGE_MASTER_CATEGORY] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
				)
		) AS sourceList

	DECLARE @tempTableRowCount INT = (SELECT COUNT(*) FROM #TempCategories);

	IF @tempTableRowCount <= 0
	BEGIN
		SELECT Result = 0, Error = 'No new data rows to insert';
		RETURN;
	END;

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[CHARGE_MASTER_CATEGORY]
			(
			 [SERVICE_AGREEMENT_ID]
			,[VISIBLE]
			,[SORT_ORDER]
			,[DESCRIPTION]
			,[INFUSION_CATEGORY]
			,[CREATION_DATE_TIME]
			,[CREATING_USER_PROFILE_ID]
			,[CHANGED_DATE_TIME]
			,[CHANGING_USER_PROFILE_ID]
			,[OBSERVATION_CATEGORY]
			,[SUPPLY_CATEGORY]
			,[COPIED_FROM_CATEGORY_ID]
			)
			SELECT TOP (@MaxToProcess)
				 #TempCategories.[SERVICE_AGREEMENT_ID]
				,#TempCategories.[VISIBLE]
				,#TempCategories.[SORT_ORDER]
				,#TempCategories.[DESCRIPTION]
				,#TempCategories.[INFUSION_CATEGORY]
				,#TempCategories.[CREATION_DATE_TIME]
				,#TempCategories.[CREATING_USER_PROFILE_ID]
				,#TempCategories.[CHANGED_DATE_TIME]
				,#TempCategories.[CHANGING_USER_PROFILE_ID]
				,#TempCategories.[OBSERVATION_CATEGORY]
				,#TempCategories.[SUPPLY_CATEGORY]
				,#TempCategories.[COPIED_FROM_CATEGORY_ID]
			From #TempCategories;

		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		SELECT Result = -4, 
			Error = 'Error: Exception occurred.  Rollback Processed. Error = ' 
				+ CAST(ERROR_NUMBER() AS VARCHAR(30)) 
				+ ' :: ' + CAST(ERROR_MESSAGE() AS VARCHAR(4000));
		ROLLBACK TRANSACTION;
	END CATCH;


	DECLARE @resultCount INT = (SELECT COUNT([CHARGE_MASTER_CATEGORY_ID]) FROM [RevCycleDB].[dbo].[CHARGE_MASTER_CATEGORY] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
