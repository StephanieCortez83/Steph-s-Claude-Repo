-------------------------------------------------------------
-- 17) DACS-2546 - Create Stored Procedure - FacilityInfusionsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[FacilityInfusionsQualifyUpdateByServiceAgreementIds]
	 @SourceFId INT
	,@TargetSAId INT
	,@UPId INT
	,@EffectiveDate DATETIME
	,@ExpirationDate DATETIME
	,@InsDate DATETIME = NULL
	,@MaxToProcess INT = 1000
AS
BEGIN

	IF @SourceFId IS NULL OR @SourceFId <= 0
	BEGIN
		SELECT Result = -1, Error = 'Error: Source Facility Id is invalid.';
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

	-- Get the Target Facility ID from the Target SAID
	DECLARE @TargetFId INT = (SELECT TOP 1 [FACILITY_ID] FROM [SERVICE_AGREEMENT] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId AND [FACILITY_ID] IS NOT NULL ORDER BY EFFECTIVE_DATE DESC)
	
	IF @TargetFId IS NULL OR @TargetFId <= 0
	BEGIN
		SELECT Result = -2, Error = 'Error: Target Facility Id is invalid.';
		RETURN;
	END;

	IF OBJECT_ID('tempdb..#TempRows') IS NOT NULL
	BEGIN
		DROP TABLE #TempRows
	END;


	-- Fill temp table with our data
	SELECT 
		   [FACILITY_ID]
		  ,[INFUSION_TYPE]
		  ,[EFFECTIVE_DATE]
		  ,[EXPIRATION_DATE]
		  ,[CREATION_DATE_TIME]
		  ,[CREATING_USER_PROFILE_ID]
		  ,[CHANGED_DATE_TIME]
		  ,[CHANGING_USER_PROFILE_ID]
	INTO #TempRows
	FROM
		(SELECT 
			   @TargetFId AS [FACILITY_ID]
			  ,[INFUSION_TYPE]
			  ,@EffectiveDate AS [EFFECTIVE_DATE]
			  ,@ExpirationDate AS [EXPIRATION_DATE]
			  ,@InsDate AS [CREATION_DATE_TIME]
			  ,@UPId AS [CREATING_USER_PROFILE_ID]
			  ,@InsDate AS [CHANGED_DATE_TIME]
			  ,@UPId AS [CHANGING_USER_PROFILE_ID]
		FROM
			[RevCycleDB].[dbo].[FACILITY_INFUSION] WITH (NOLOCK)
		WHERE 
			[FACILITY_ID] = @SourceFId

			-- The following must match to be counted as a row to skip
			AND ([INFUSION_TYPE]) NOT IN 
				(
					SELECT DISTINCT ([INFUSION_TYPE]) 
						FROM [RevCycleDB].[dbo].[FACILITY_INFUSION] WITH (NOLOCK)
						WHERE [FACILITY_ID] = @TargetFId
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

		INSERT INTO [RevCycleDB].[dbo].[FACILITY_INFUSION]
			(
			   [FACILITY_ID]
			  ,[INFUSION_TYPE]
			  ,[EFFECTIVE_DATE]
			  ,[EXPIRATION_DATE]
			  ,[CREATION_DATE_TIME]
			  ,[CREATING_USER_PROFILE_ID]
			  ,[CHANGED_DATE_TIME]
			  ,[CHANGING_USER_PROFILE_ID]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[FACILITY_ID]
				  ,#TempRows.[INFUSION_TYPE]
				  ,#TempRows.[EFFECTIVE_DATE]
				  ,#TempRows.[EXPIRATION_DATE]
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


	DECLARE @resultCount INT = (SELECT COUNT([FACILITY_INFUSION_ID]) FROM [RevCycleDB].[dbo].[FACILITY_INFUSION] WITH (NOLOCK) WHERE [FACILITY_ID] = @TargetFId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO