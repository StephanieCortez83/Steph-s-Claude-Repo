----------------------------------------------------------------------------------------
-- 01) DACS-3037 - Alter Procedure - [dbo].[PhysicianServiceProcedureQualifyUpdateByServiceAgreementIds].SQL
----------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[PhysicianServiceProcedureQualifyUpdateByServiceAgreementIds]
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

	DECLARE @dos datetime = GETDATE();
	DECLARE @defaultPatClassId INT = 
		(
			SELECT TOP(1) [PATIENT_CLASS_ID] 
			FROM [PATIENT_CLASS] WITH (NOLOCK) 
			WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId 
			AND [DEFAULT_IND] = 1 
			AND ([EFFECTIVE_DATE] < @dos) 
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @dos)
		)

	--	SELECT '@defaultPatClassId =' = @defaultPatClassId; -- testing

	-- Fill temp table with our data
	SELECT DISTINCT
         [SERVICE_AGREEMENT_ID]
        ,[SERVICE_LEVEL_CD]
        ,[CPT_CODE]
        ,[BILLING_CODE]
        ,[OVERRIDE_ONLY_IND]
        ,[DESCRIPTION]
        ,[CREATION_DATE_TIME]
        ,[CREATING_USER_PROFILE_ID]
        ,[CHANGED_DATE_TIME]
        ,[CHANGING_USER_PROFILE_ID]
        ,[REPORTING_COLUMN]
        --,[DEPARTMENT]	-- Appears no longer used
        ,[PATIENT_CLASS_ID] 
        ,[MODIFIER]
        ,[PROCEDURES]
        ,[ALIAS_BILLING_CODE]
        ,[ALLOW_WITH_NO_PHYSICIAN_SERVICES]
        ,[CRITICAL_CARE]
        ,[EFFECTIVE_DATE]
        ,[EXPIRATION_DATE]
        ,[PREVENTATIVE_MEDICINE]
	INTO #TempRows
	FROM
		(SELECT 
				 @TargetSAId AS [SERVICE_AGREEMENT_ID]
				,[SERVICE_LEVEL_CD]
				,[CPT_CODE]
				,[BILLING_CODE]
				,[OVERRIDE_ONLY_IND]
				,[DESCRIPTION]
				,@InsDate AS [CREATION_DATE_TIME]
				,@UPId AS [CREATING_USER_PROFILE_ID]
				,@InsDate AS [CHANGED_DATE_TIME]
				,@UPId AS [CHANGING_USER_PROFILE_ID]
				,[REPORTING_COLUMN]
				--,ISNULL((SELECT TOP(1) [CHARGE_MASTER_DEPT_ID] FROM [CHARGE_MASTER_DEPARTMENT] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId AND [COPIED_FROM_DEPT_ID] = src.[DEPARTMENT]), -1) AS [DEPARTMENT]
				,ISNULL(
					(SELECT TOP(1) [PATIENT_CLASS_ID] FROM [PATIENT_CLASS] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId AND [COPIED_FROM_PATIENT_CLASS_ID] = src.[PATIENT_CLASS_ID])
					, ISNULL(@defaultPatClassId	, -1)) AS [PATIENT_CLASS_ID]
				,[MODIFIER]
				,[PROCEDURES]
				,[ALIAS_BILLING_CODE]
				,[ALLOW_WITH_NO_PHYSICIAN_SERVICES]
				,[CRITICAL_CARE]
				,@EffectiveDate AS [EFFECTIVE_DATE]
				,@ExpirationDate AS [EXPIRATION_DATE]
				,[PREVENTATIVE_MEDICINE]
		FROM
			[RevCycleDB].[dbo].[PHYSICIAN_SERVICE_PROCEDURE] src WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
		AND [EFFECTIVE_DATE] < @dos
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @dos)
		AND 
		
			CAST([SERVICE_LEVEL_CD] AS VARCHAR(20)) + ',' +  
			RTRIM([CPT_CODE]) + ',' +  
			RTRIM([BILLING_CODE]) + ',' +  
			CAST([OVERRIDE_ONLY_IND] AS VARCHAR(20)) + ',' +  
			RTRIM([DESCRIPTION]) + ',' + 
			CAST([REPORTING_COLUMN] AS VARCHAR(20)) + ',' +  
			--CAST([PATIENT_CLASS_ID] AS VARCHAR(20)) + ',' +    -- cannot care about the patient_class_id because they will be different from source to target unless == -1
			CAST([PROCEDURES] AS VARCHAR(20)) + ',' +  
			CAST([ALLOW_WITH_NO_PHYSICIAN_SERVICES] AS VARCHAR(20)) + ',' +  
			CAST([CRITICAL_CARE] AS VARCHAR(20)) 
			
			NOT IN 
				(
					SELECT DISTINCT 
					
						CAST([SERVICE_LEVEL_CD] AS VARCHAR(20)) + ',' +  
						RTRIM([CPT_CODE]) + ',' +  
						RTRIM([BILLING_CODE]) + ',' +  
						CAST([OVERRIDE_ONLY_IND] AS VARCHAR(20)) + ',' +  
						RTRIM([DESCRIPTION]) + ',' + 
						CAST([REPORTING_COLUMN] AS VARCHAR(20)) + ',' +  
						--CAST([PATIENT_CLASS_ID] AS VARCHAR(20)) + ',' +    -- cannot care about the patient_class_id because they will be different from source to target unless == -1
						CAST([PROCEDURES] AS VARCHAR(20)) + ',' +  
						CAST([ALLOW_WITH_NO_PHYSICIAN_SERVICES] AS VARCHAR(20)) + ',' +  
						CAST([CRITICAL_CARE] AS VARCHAR(20)) 

					FROM [RevCycleDB].[dbo].[PHYSICIAN_SERVICE_PROCEDURE] WITH (NOLOCK)
					WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
					AND [EFFECTIVE_DATE] < @dos
					AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @dos)
				)
		) AS sourceList

	-- check our data if needed
	-- SELECT COUNT(*) FROM #TempRows;
	-- SELECT * FROM #TempRows;

	DECLARE @tempTableRowCount INT = (SELECT COUNT(*) FROM #TempRows);

	IF @tempTableRowCount <= 0
	BEGIN
		SELECT Result = 0, Error = 'No new data rows to insert';
		RETURN;
	END;

	-- select '@tempTableRowCount = ' = @tempTableRowCount; -- testing

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[PHYSICIAN_SERVICE_PROCEDURE]
			(
				 [SERVICE_AGREEMENT_ID]
				,[SERVICE_LEVEL_CD]
				,[CPT_CODE]
				,[BILLING_CODE]
				,[OVERRIDE_ONLY_IND]
				,[DESCRIPTION]
				,[CREATION_DATE_TIME]
				,[CREATING_USER_PROFILE_ID]
				,[CHANGED_DATE_TIME]
				,[CHANGING_USER_PROFILE_ID]
				,[REPORTING_COLUMN]
				--,[DEPARTMENT]
				,[PATIENT_CLASS_ID]
				,[MODIFIER]
				,[PROCEDURES]
				,[ALIAS_BILLING_CODE]
				,[ALLOW_WITH_NO_PHYSICIAN_SERVICES]
				,[CRITICAL_CARE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[PREVENTATIVE_MEDICINE]
			)
			SELECT TOP (@MaxToProcess)
				 #TempRows.[SERVICE_AGREEMENT_ID]
				,#TempRows.[SERVICE_LEVEL_CD]
				,#TempRows.[CPT_CODE]
				,#TempRows.[BILLING_CODE]
				,#TempRows.[OVERRIDE_ONLY_IND]
				,#TempRows.[DESCRIPTION]
				,#TempRows.[CREATION_DATE_TIME]
				,#TempRows.[CREATING_USER_PROFILE_ID]
				,#TempRows.[CHANGED_DATE_TIME]
				,#TempRows.[CHANGING_USER_PROFILE_ID]
				,#TempRows.[REPORTING_COLUMN]
				--,#TempRows.[DEPARTMENT]
				,#TempRows.[PATIENT_CLASS_ID]
				,#TempRows.[MODIFIER]
				,#TempRows.[PROCEDURES]
				,#TempRows.[ALIAS_BILLING_CODE]
				,#TempRows.[ALLOW_WITH_NO_PHYSICIAN_SERVICES]
				,#TempRows.[CRITICAL_CARE]
				,#TempRows.[EFFECTIVE_DATE]
				,#TempRows.[EXPIRATION_DATE]
				,#TempRows.[PREVENTATIVE_MEDICINE]
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


	DECLARE @resultCount INT = (SELECT COUNT([PHYSICIAN_SERVICE_PROC_ID]) FROM [RevCycleDB].[dbo].[PHYSICIAN_SERVICE_PROCEDURE] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO


