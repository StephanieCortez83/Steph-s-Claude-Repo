-------------------------------------------------------------
-- 07) DACS-2546 - Create Stored Procedure - FacilityServiceQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[FacilityServiceQualifyUpdateByServiceAgreementIds]
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
        ,[MAX_POINTS]
        ,[DESCRIPTION]
        ,[EXCLUSION_OPTION]
        ,[SEQUENCE]
        ,[CREATION_DATE_TIME]
        ,[CREATING_USER_PROFILE_ID]
        ,[CHANGED_DATE_TIME]
        ,[CHANGING_USER_PROFILE_ID]
        ,[LONG_DESCRIPTION]
        ,[EXPIRATION_DATE]
        ,[CRITICAL_CARE]
        ,[NOT_ALLOWED_FOR_INPATIENT]
        ,[REQUIRE_25_MODIFIER]
	INTO #TempRows
	FROM
		(SELECT 
			 @TargetSAId AS [SERVICE_AGREEMENT_ID]
			,[MAX_POINTS]
			,[DESCRIPTION]
			,[EXCLUSION_OPTION]
			,[SEQUENCE]
			,@InsDate AS [CREATION_DATE_TIME]
			,@UPId AS [CREATING_USER_PROFILE_ID]
			,@InsDate AS [CHANGED_DATE_TIME]
			,@UPId AS [CHANGING_USER_PROFILE_ID]
			,[LONG_DESCRIPTION]
			,@ExpirationDate AS [EXPIRATION_DATE]
			,[CRITICAL_CARE]
			,[NOT_ALLOWED_FOR_INPATIENT]
			,[REQUIRE_25_MODIFIER]
		FROM
			[RevCycleDB].[dbo].[FACILITY_SERVICE] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EXPIRATION_DATE] IS NOT NULL AND ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([DESCRIPTION])) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([DESCRIPTION])) ) 
						FROM [RevCycleDB].[dbo].[FACILITY_SERVICE] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
						AND ([EXPIRATION_DATE] IS NOT NULL AND ([EXPIRATION_DATE] >= GetDate()))
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

		INSERT INTO [RevCycleDB].[dbo].[FACILITY_SERVICE]
			(
			 [SERVICE_AGREEMENT_ID]
			,[MAX_POINTS]
			,[DESCRIPTION]
			,[EXCLUSION_OPTION]
			,[SEQUENCE]
			,[CREATION_DATE_TIME]
			,[CREATING_USER_PROFILE_ID]
			,[CHANGED_DATE_TIME]
			,[CHANGING_USER_PROFILE_ID]
			,[LONG_DESCRIPTION]
			,[EXPIRATION_DATE]
			,[CRITICAL_CARE]
			,[NOT_ALLOWED_FOR_INPATIENT]
			,[REQUIRE_25_MODIFIER]
			)
			SELECT TOP (@MaxToProcess)
				 #TempRows.[SERVICE_AGREEMENT_ID]
				,#TempRows.[MAX_POINTS]
				,#TempRows.[DESCRIPTION]
				,#TempRows.[EXCLUSION_OPTION]
				,#TempRows.[SEQUENCE]
				,#TempRows.[CREATION_DATE_TIME]
				,#TempRows.[CREATING_USER_PROFILE_ID]
				,#TempRows.[CHANGED_DATE_TIME]
				,#TempRows.[CHANGING_USER_PROFILE_ID]
				,#TempRows.[LONG_DESCRIPTION]
				,#TempRows.[EXPIRATION_DATE]
				,#TempRows.[CRITICAL_CARE]
				,#TempRows.[NOT_ALLOWED_FOR_INPATIENT]
				,#TempRows.[REQUIRE_25_MODIFIER]
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


	DECLARE @resultCount INT = (SELECT COUNT([FACILITY_SERVICE_ID]) FROM [RevCycleDB].[dbo].[FACILITY_SERVICE] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO