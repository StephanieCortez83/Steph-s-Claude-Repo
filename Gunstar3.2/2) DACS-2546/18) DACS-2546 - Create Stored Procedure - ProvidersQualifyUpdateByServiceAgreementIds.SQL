-------------------------------------------------------------
-- 18) DACS-2546 - Create Stored Procedure - ProvidersQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[ProvidersQualifyUpdateByServiceAgreementIds]
	 @SourceSAId INT
	,@TargetSAId INT
	,@UPId INT
	,@EffectiveDate DATETIME
	,@ExpirationDate DATETIME
	,@InsDate DATETIME = NULL
	,@MaxToProcess INT = 20000
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
		  ,[SERVICE_AGREEMENT_ID]
		  ,[ROLE_ID]
		  ,[TITLE]
		  ,[FIRST_NAME]
		  ,[MIDDLE_NAME]
		  ,[LAST_NAME]
		  ,[NAME_SUFFIX]
		  ,[ADDR_LINE_1]
		  ,[ADDR_LINE_2]
		  ,[CITY]
		  ,[STATE]
		  ,[POSTAL_CODE]
		  ,[PHONE_AREA_CODE]
		  ,[PHONE_NUMBER]
		  ,[PHONE_EXT]
		  ,[FAX_AREA_CODE]
		  ,[FAX_NUMBER]
		  ,[EMAIL_ADDRESS]
		  ,[EMPLOYEE_IDENTIFIER]
		  ,[CREATION_DATE_TIME]
		  ,[CREATING_USER_PROFILE_ID]
		  ,[CHANGED_DATE_TIME]
		  ,[CHANGING_USER_PROFILE_ID]
		  ,[INACTIVE_IND]
		  ,[UPIR_ID]
		  ,[PROVIDER_BUSINESS_UNIT_ID]
		  ,[SPECIALTY]
		  ,[SECONDARY_EMPLOYEE_ID]
		  ,[LOCUM_TENENS]
		  ,[SUPERVISING_EMPLOYEE_ID]
		  ,[EFFECTIVE_DATE]
		  ,[EXPIRATION_DATE]
		  ,[UNSPECIFIED_PROVIDER_IND]
		  ,[CREDENTIALS]
	INTO #TempRows
	FROM
		(SELECT 
			   @TargetFId AS [FACILITY_ID]
			  ,@TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,[ROLE_ID]
			  ,[TITLE]
			  ,[FIRST_NAME]
			  ,[MIDDLE_NAME]
			  ,[LAST_NAME]
			  ,[NAME_SUFFIX]
			  ,[ADDR_LINE_1]
			  ,[ADDR_LINE_2]
			  ,[CITY]
			  ,[STATE]
			  ,[POSTAL_CODE]
			  ,[PHONE_AREA_CODE]
			  ,[PHONE_NUMBER]
			  ,[PHONE_EXT]
			  ,[FAX_AREA_CODE]
			  ,[FAX_NUMBER]
			  ,[EMAIL_ADDRESS]
			  ,[EMPLOYEE_IDENTIFIER]
			  ,@InsDate  AS [CREATION_DATE_TIME]
			  ,@UPId AS [CREATING_USER_PROFILE_ID]
			  ,@InsDate  AS [CHANGED_DATE_TIME]
			  ,@UPId AS [CHANGING_USER_PROFILE_ID]
			  ,[INACTIVE_IND]
			  ,[UPIR_ID]
			  ,[PROVIDER_BUSINESS_UNIT_ID]
			  ,[SPECIALTY]
			  ,[SECONDARY_EMPLOYEE_ID]
			  ,[LOCUM_TENENS]
			  ,[SUPERVISING_EMPLOYEE_ID]
			  ,@EffectiveDate AS [EFFECTIVE_DATE]
			  ,@ExpirationDate AS [EXPIRATION_DATE]
			  ,[UNSPECIFIED_PROVIDER_IND]
			  ,[CREDENTIALS]
		FROM
			[RevCycleDB].[dbo].[FACILITY_PROFESSIONAL] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (	LOWER(RTRIM( 
						[TITLE] + ',' +
						[FIRST_NAME] + ',' +
						[MIDDLE_NAME] + ',' +
						[LAST_NAME] + ',' +
						[NAME_SUFFIX]
					)) ) NOT IN 
				(
					SELECT DISTINCT (	LOWER(RTRIM(
											[TITLE] + ',' +
											[FIRST_NAME] + ',' +
											[MIDDLE_NAME] + ',' +
											[LAST_NAME] + ',' +
											[NAME_SUFFIX]
										)) ) 
						FROM [RevCycleDB].[dbo].[FACILITY_PROFESSIONAL] WITH (NOLOCK)
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

		INSERT INTO [RevCycleDB].[dbo].[FACILITY_PROFESSIONAL]
			(
			   [FACILITY_ID]
			  ,[SERVICE_AGREEMENT_ID]
			  ,[ROLE_ID]
			  ,[TITLE]
			  ,[FIRST_NAME]
			  ,[MIDDLE_NAME]
			  ,[LAST_NAME]
			  ,[NAME_SUFFIX]
			  ,[ADDR_LINE_1]
			  ,[ADDR_LINE_2]
			  ,[CITY]
			  ,[STATE]
			  ,[POSTAL_CODE]
			  ,[PHONE_AREA_CODE]
			  ,[PHONE_NUMBER]
			  ,[PHONE_EXT]
			  ,[FAX_AREA_CODE]
			  ,[FAX_NUMBER]
			  ,[EMAIL_ADDRESS]
			  ,[EMPLOYEE_IDENTIFIER]
			  ,[CREATION_DATE_TIME]
			  ,[CREATING_USER_PROFILE_ID]
			  ,[CHANGED_DATE_TIME]
			  ,[CHANGING_USER_PROFILE_ID]
			  ,[INACTIVE_IND]
			  ,[UPIR_ID]
			  ,[PROVIDER_BUSINESS_UNIT_ID]
			  ,[SPECIALTY]
			  ,[SECONDARY_EMPLOYEE_ID]
			  ,[LOCUM_TENENS]
			  ,[SUPERVISING_EMPLOYEE_ID]
			  ,[EFFECTIVE_DATE]
			  ,[EXPIRATION_DATE]
			  ,[UNSPECIFIED_PROVIDER_IND]
			  ,[CREDENTIALS]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[FACILITY_ID]
				  ,#TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[ROLE_ID]
				  ,#TempRows.[TITLE]
				  ,#TempRows.[FIRST_NAME]
				  ,#TempRows.[MIDDLE_NAME]
				  ,#TempRows.[LAST_NAME]
				  ,#TempRows.[NAME_SUFFIX]
				  ,#TempRows.[ADDR_LINE_1]
				  ,#TempRows.[ADDR_LINE_2]
				  ,#TempRows.[CITY]
				  ,#TempRows.[STATE]
				  ,#TempRows.[POSTAL_CODE]
				  ,#TempRows.[PHONE_AREA_CODE]
				  ,#TempRows.[PHONE_NUMBER]
				  ,#TempRows.[PHONE_EXT]
				  ,#TempRows.[FAX_AREA_CODE]
				  ,#TempRows.[FAX_NUMBER]
				  ,#TempRows.[EMAIL_ADDRESS]
				  ,#TempRows.[EMPLOYEE_IDENTIFIER]
				  ,#TempRows.[CREATION_DATE_TIME]
				  ,#TempRows.[CREATING_USER_PROFILE_ID]
				  ,#TempRows.[CHANGED_DATE_TIME]
				  ,#TempRows.[CHANGING_USER_PROFILE_ID]
				  ,#TempRows.[INACTIVE_IND]
				  ,#TempRows.[UPIR_ID]
				  ,#TempRows.[PROVIDER_BUSINESS_UNIT_ID]
				  ,#TempRows.[SPECIALTY]
				  ,#TempRows.[SECONDARY_EMPLOYEE_ID]
				  ,#TempRows.[LOCUM_TENENS]
				  ,#TempRows.[SUPERVISING_EMPLOYEE_ID]
				  ,#TempRows.[EFFECTIVE_DATE]
				  ,#TempRows.[EXPIRATION_DATE]
				  ,#TempRows.[UNSPECIFIED_PROVIDER_IND]
				  ,#TempRows.[CREDENTIALS]
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


	DECLARE @resultCount INT = (SELECT COUNT([FACILITY_PROF_ID]) FROM [RevCycleDB].[dbo].[FACILITY_PROFESSIONAL] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO