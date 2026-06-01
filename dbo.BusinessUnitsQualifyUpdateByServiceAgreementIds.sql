SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[BusinessUnitsQualifyUpdateByServiceAgreementIds]
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
      ,[BUSINESS_UNIT_NAME]
      ,[EFFECTIVE_DATE]
      ,[EXPIRATION_DATE]
      ,[REPORT_AS_PERFORMING_PROVIDER]
      ,[REPORT_AS_ORDERED_BY_PHYSICIAN]
	INTO #TempRows
	FROM
		(SELECT 
			   @TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,[BUSINESS_UNIT_NAME]
			  ,@EffectiveDate AS [EFFECTIVE_DATE]
			  ,@ExpirationDate AS [EXPIRATION_DATE]
			  ,[REPORT_AS_PERFORMING_PROVIDER]
			  ,[REPORT_AS_ORDERED_BY_PHYSICIAN]
		FROM
			[RevCycleDB].[dbo].[PROVIDER_BUSINESS_UNIT] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([BUSINESS_UNIT_NAME])) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([BUSINESS_UNIT_NAME])) ) 
						FROM [RevCycleDB].[dbo].[PROVIDER_BUSINESS_UNIT] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
						AND ([EFFECTIVE_DATE] <= GetDate())
						AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))
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

		INSERT INTO [RevCycleDB].[dbo].[PROVIDER_BUSINESS_UNIT]
			(
			   [SERVICE_AGREEMENT_ID]
			  ,[BUSINESS_UNIT_NAME]
			  ,[EFFECTIVE_DATE]
			  ,[EXPIRATION_DATE]
			  ,[REPORT_AS_PERFORMING_PROVIDER]
			  ,[REPORT_AS_ORDERED_BY_PHYSICIAN]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[BUSINESS_UNIT_NAME]
				  ,#TempRows.[EFFECTIVE_DATE]
				  ,#TempRows.[EXPIRATION_DATE]
				  ,#TempRows.[REPORT_AS_PERFORMING_PROVIDER]
				  ,#TempRows.[REPORT_AS_ORDERED_BY_PHYSICIAN]
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


	DECLARE @resultCount INT = (SELECT COUNT([PROVIDER_BUSINESS_UNIT_ID]) FROM [RevCycleDB].[dbo].[PROVIDER_BUSINESS_UNIT] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
