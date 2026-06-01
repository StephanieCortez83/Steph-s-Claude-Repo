USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 1) DACS-2499 Stored Proc DeleteServiceAgreementByServiceAgreementId.sql

GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteServiceAgreementByServiceAgreementId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROC dbo.DeleteServiceAgreementByServiceAgreementId  
 @ServiceAgreementId int  
AS  
  BEGIN TRANSACTION  
  BEGIN TRY  
    
    DELETE FROM FACILITY_CRITICAL_CARE WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM FACILITY_LEVEL WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
                DELETE FROM CHARGE_MASTER_CATEGORY WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
                DELETE FROM CHARGE_MASTER_DEPARTMENT WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
                DELETE FROM CHARGE_MASTER_INCLUSIVE WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
                DELETE FROM CHARGE_MASTER_MODIFIER WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM FACILITY_PROFESSIONAL WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM FACILITY_SERVICE WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM PHYSICIAN_CRITICAL_CARE WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM PHYSICIAN_SERVICE_PROCEDURE WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM [SERVICE_AGREEMENT_TRIAGE_ACUITY] WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM [SERVICE_AGREEMENT_ARRIVAL_MODE] WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE F FROM FACILITY_INFUSION F INNER JOIN SERVICE_AGREEMENT S ON F.FACILITY_ID = S.FACILITY_ID WHERE S.FACILITY_ID != -1 AND S.SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
  
    DELETE FROM CHART_MENU WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM DIAGNOSIS_CODE_BYPASS_AUTO_APPROVAL WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM DOCUMENTATION_ITEM WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM FACILITY_FINANCIAL_CLASS WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM FACILITY_SERVICE_SCHEDULE_ASSIGNMENT WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM PATIENT_CLASS WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM PATIENT_DISPOSITION_MAP WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_CHART_STATUS_CHANGE_CRITERIA WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_CLIENT_SPECIFICS WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_CLINIC WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_CMS_LCD WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_DOCUMENT WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_EMR_SYSTEM WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_EXPORT WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_EXPORT_TIME WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_FACILITY_EM_METHOD WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_MANAGEMENT_TEAM WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_PAYOR WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_PENDING_REASON WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_PQRS WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_PREVIOUS_LEVEL_DISTRIBUTION WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_RATE WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_ROI_ASSESSMENT_SUMMARY WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
    DELETE FROM SERVICE_AGREEMENT WHERE SERVICE_AGREEMENT_ID=@ServiceAgreementId;  
  
    COMMIT TRANSACTION;   
   END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
   END CATCH  
-- End of 1) DACS-2499 Stored Proc DeleteServiceAgreementByServiceAgreementId.sql
GO

-- Start of 01) DACS-2546 - Create Stored Procedure - ServiceAgreementAdmitTypesQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 01) DACS-2546 - Create Stored Procedure - ServiceAgreementAdmitTypesQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ServiceAgreementAdmitTypesQualifyUpdateByServiceAgreementIds]
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
	    ,[ADMIT_TYPE_CD]
		,[DESCRIPTION]
		,[EFFECTIVE_DATE]
		,[EXPIRATION_DATE]
		,[USE_AUTO_APPEND_XU_MODIFIER_ON_ADMIT]
	INTO #TempRows
	FROM
		(SELECT 
				 @TargetSAId AS [SERVICE_AGREEMENT_ID]
				,[ADMIT_TYPE_CD]
				,[DESCRIPTION]
				,@EffectiveDate AS [EFFECTIVE_DATE]
				,@ExpirationDate AS [EXPIRATION_DATE]
				,[USE_AUTO_APPEND_XU_MODIFIER_ON_ADMIT]
		FROM
			[RevCycleDB].[dbo].[SERVICE_AGREEMENT_ADMIT_TYPE] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([DESCRIPTION]))  + ',' + [ADMIT_TYPE_CD] + ',' + CAST([USE_AUTO_APPEND_XU_MODIFIER_ON_ADMIT] AS varchar(5)) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([DESCRIPTION])) + ',' + [ADMIT_TYPE_CD] + ',' + CAST([USE_AUTO_APPEND_XU_MODIFIER_ON_ADMIT] AS varchar(5))) 
						FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_ADMIT_TYPE] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
						AND ([EFFECTIVE_DATE] <= GetDate())
						AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))
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

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_ADMIT_TYPE]
			(
			 [SERVICE_AGREEMENT_ID]
			,[ADMIT_TYPE_CD]
			,[DESCRIPTION]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[USE_AUTO_APPEND_XU_MODIFIER_ON_ADMIT]
			)
			SELECT TOP (@MaxToProcess)
				 #TempRows.[SERVICE_AGREEMENT_ID]
				,#TempRows.[ADMIT_TYPE_CD]
				,#TempRows.[DESCRIPTION]
				,#TempRows.[EFFECTIVE_DATE]
				,#TempRows.[EXPIRATION_DATE]
				,#TempRows.[USE_AUTO_APPEND_XU_MODIFIER_ON_ADMIT]
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


	DECLARE @resultCount INT = (SELECT COUNT([SERVICE_AGREEMENT_ADMIT_TYPE_ID]) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_ADMIT_TYPE] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 01) DACS-2546 - Create Stored Procedure - ServiceAgreementAdmitTypesQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 02) DACS-2546 - Create Stored Procedure - ServiceAgreementArrivalModesQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 02) DACS-2546 - Create Stored Procedure - ServiceAgreementArrivalModesQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ServiceAgreementArrivalModesQualifyUpdateByServiceAgreementIds]
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
        ,[ARIVAL_MODE_CD]
        ,[DESCRIPTION]
        ,[EFFECTIVE_DATE]
        ,[EXPIRATION_DATE]
	INTO #TempRows
	FROM
		(SELECT 
				 @TargetSAId AS [SERVICE_AGREEMENT_ID]
				,[ARIVAL_MODE_CD]
				,[DESCRIPTION]
				,@EffectiveDate AS [EFFECTIVE_DATE]
				,@ExpirationDate AS [EXPIRATION_DATE]
		FROM
			[RevCycleDB].[dbo].[SERVICE_AGREEMENT_ARRIVAL_MODE] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([DESCRIPTION])) + ',' + [ARIVAL_MODE_CD] ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([DESCRIPTION])) + ',' + [ARIVAL_MODE_CD] ) 
						FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_ARRIVAL_MODE] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
						AND ([EFFECTIVE_DATE] <= GetDate())
						AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))
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

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_ARRIVAL_MODE]
			(
			 [SERVICE_AGREEMENT_ID]
			,[ARIVAL_MODE_CD]
			,[DESCRIPTION]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			)
			SELECT TOP (@MaxToProcess)
				 #TempRows.[SERVICE_AGREEMENT_ID]
				,#TempRows.[ARIVAL_MODE_CD]
				,#TempRows.[DESCRIPTION]
				,#TempRows.[EFFECTIVE_DATE]
				,#TempRows.[EXPIRATION_DATE]
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


	DECLARE @resultCount INT = (SELECT COUNT([SERVICE_AGREEMENT_ARRIVAL_MODE_ID]) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_ARRIVAL_MODE] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 02) DACS-2546 - Create Stored Procedure - ServiceAgreementArrivalModesQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 03) DACS-2546 - Create Stored Procedure - ServiceAgreementFacilityEMMethodQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 03) DACS-2546 - Create Stored Procedure - ServiceAgreementFacilityEMMethodQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ServiceAgreementFacilityEMMethodQualifyUpdateByServiceAgreementIds]
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
	  ,[FACILITY_EM_METHOD_ID]
	  ,[EFFECTIVE_DATE]
	  ,[EXPIRATION_DATE]
	  ,[CREATION_DATE_TIME]
	  ,[CREATING_USER_PROFILE_ID]
	  ,[CHANGED_DATE_TIME]
	  ,[CHANGING_USER_PROFILE_ID]
	INTO #TempRows
	FROM
		(SELECT 
			   @TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,[FACILITY_EM_METHOD_ID]
			  ,@EffectiveDate AS [EFFECTIVE_DATE]
			  ,@ExpirationDate AS [EXPIRATION_DATE]
			  ,@InsDate AS [CREATION_DATE_TIME]
			  ,@UPId AS [CREATING_USER_PROFILE_ID]
			  ,@InsDate AS [CHANGED_DATE_TIME]
			  ,@UPId AS [CHANGING_USER_PROFILE_ID]
		FROM
			[RevCycleDB].[dbo].[SERVICE_AGREEMENT_FACILITY_EM_METHOD] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (FACILITY_EM_METHOD_ID ) NOT IN 
				(
					SELECT DISTINCT (FACILITY_EM_METHOD_ID ) 
						FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_FACILITY_EM_METHOD] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
						AND ([EFFECTIVE_DATE] <= GetDate())
						AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))
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

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_FACILITY_EM_METHOD]
			(
			   [SERVICE_AGREEMENT_ID]
			  ,[FACILITY_EM_METHOD_ID]
			  ,[EFFECTIVE_DATE]
			  ,[EXPIRATION_DATE]
			  ,[CREATION_DATE_TIME]
			  ,[CREATING_USER_PROFILE_ID]
			  ,[CHANGED_DATE_TIME]
			  ,[CHANGING_USER_PROFILE_ID]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[FACILITY_EM_METHOD_ID]
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


	DECLARE @resultCount INT = (SELECT COUNT([SERVICE_AGREEMENT_FACILITY_EM_METHOD_ID]) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_FACILITY_EM_METHOD] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 03) DACS-2546 - Create Stored Procedure - ServiceAgreementFacilityEMMethodQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 04) DACS-2546 - Create Stored Procedure - ServiceAgreementObservationPatientArrivalSourceQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 04) DACS-2546 - Create Stored Procedure - ServiceAgreementObservationPatientArrivalSourceQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ServiceAgreementObservationPatientArrivalSourceQualifyUpdateByServiceAgreementIds]
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
		,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD]
		,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC]
	INTO #TempRows
	FROM
		(SELECT 
				 @TargetSAId AS [SERVICE_AGREEMENT_ID]
				,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD]
				,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC]
		FROM
			[RevCycleDB].[dbo].[SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId

			-- The following must match to be counted as a row to skip
			AND ([OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD] ) NOT IN 
				(
					SELECT DISTINCT ([OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD] ) 
						FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
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

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE]
			(
				 [SERVICE_AGREEMENT_ID]
				,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD]
				,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC]
			)
			SELECT TOP (@MaxToProcess)
				 #TempRows.[SERVICE_AGREEMENT_ID]
				,#TempRows.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD]
				,#TempRows.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC]
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


	DECLARE @resultCount INT = (SELECT COUNT([OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 04) DACS-2546 - Create Stored Procedure - ServiceAgreementObservationPatientArrivalSourceQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 05) DACS-2546 - Create Stored Procedure - ServiceAgreementConditionsOfAccidentQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 05) DACS-2546 - Create Stored Procedure - ServiceAgreementConditionsOfAccidentQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ServiceAgreementConditionsOfAccidentQualifyUpdateByServiceAgreementIds]
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
		,[EFFECTIVE_DATE]
		,[EXPIRATION_DATE]
		,[ACCIDENT_TYPE_ID]
		,[ACCIDENT_CD]
	INTO #TempRows
	FROM
		(SELECT 
				 @TargetSAId AS [SERVICE_AGREEMENT_ID]
				,[DESCRIPTION]
				,@EffectiveDate AS [EFFECTIVE_DATE]
				,@ExpirationDate AS [EXPIRATION_DATE]
				,[ACCIDENT_TYPE_ID]
				,[ACCIDENT_CD]
		FROM
			[RevCycleDB].[dbo].[SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([DESCRIPTION])) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([DESCRIPTION])) ) 
						FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
						AND ([EFFECTIVE_DATE] <= GetDate())
						AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))
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

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT]
			(
			 [SERVICE_AGREEMENT_ID]
			,[DESCRIPTION]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[ACCIDENT_TYPE_ID]
			,[ACCIDENT_CD]
			)
			SELECT TOP (@MaxToProcess)
				 #TempRows.[SERVICE_AGREEMENT_ID]
				,#TempRows.[DESCRIPTION]
				,#TempRows.[EFFECTIVE_DATE]
				,#TempRows.[EXPIRATION_DATE]
				,#TempRows.[ACCIDENT_TYPE_ID]
				,#TempRows.[ACCIDENT_CD]
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


	DECLARE @resultCount INT = (SELECT COUNT([CONDITION_OF_ACCIDENT_ID]) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 05) DACS-2546 - Create Stored Procedure - ServiceAgreementConditionsOfAccidentQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 06) DACS-2546 - Create Stored Procedure - ServiceAgreementPayorsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 06) DACS-2546 - Create Stored Procedure - ServiceAgreementPayorsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ServiceAgreementPayorsQualifyUpdateByServiceAgreementIds]
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
        ,[FACILITY_PAYOR_ID]
        ,[FACILITY_PAYOR_NAME]
        ,[EFFECTIVE_DATE]
        ,[EXPIRATION_DATE]
        ,[PAYOR_METHOD_CD]
        ,[PHYSICIAN_SERVICE_GUIDELINE_ID]
        ,[COLLECT_DATA_FOR_CORE_MEASURES_REPORTING]
        ,[APPLY_Q6_MODIFIER]
        ,[APPLY_MICHIGAN_PROFEE_MEDICAID_MODIFIERS]
        ,[PAYOR_CLASS_ID]
        ,[FINANCIAL_CLASS_ID]
        ,[APPLY_57_MODIFIER_IF_PROCEDURE_QUALIFIES_90_DAY_GLOBAL]
        ,[COLLECT_ACCIDENT_DATE]
        ,[DO_NOT_EXPORT_MODIFIERS_IND]
        ,[COLLECT_SUBSEQUENT_VISIT_IND]
        ,[ALLOW_PHYSICIAN_SERVICE_OBSERVATION]
        ,[ALLOW_MIDLEVEL_BILLING_OF_EM_SERVICES_IND]
        ,[REQUIRE_AUDIT]
        ,[CLINIC_PAYOR_RULE_ID]
        ,[APPLY_UA_MOD_TO_SURGICAL_FAC_PROCS]
        ,[USE_MEDICARE_ANESTHESIA_RULES]
        ,[DISABLE_ANESTHESIA_PHYSICAL_STATUS]
        ,[DISABLE_ANESTHESIA_QUALIFYING_CIRCUMSTANCES]
        ,[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_TIME_CALCULATION]
        ,[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_EFFECTIVE_DATE]
	INTO #TempRows
	FROM
		(SELECT 
				 @TargetSAId AS [SERVICE_AGREEMENT_ID]
				,[FACILITY_PAYOR_ID]
				,[FACILITY_PAYOR_NAME]
				,@EffectiveDate AS [EFFECTIVE_DATE]
				,@ExpirationDate AS [EXPIRATION_DATE]
				,[PAYOR_METHOD_CD]
				,[PHYSICIAN_SERVICE_GUIDELINE_ID]
				,[COLLECT_DATA_FOR_CORE_MEASURES_REPORTING]
				,[APPLY_Q6_MODIFIER]
				,[APPLY_MICHIGAN_PROFEE_MEDICAID_MODIFIERS]
				,[PAYOR_CLASS_ID]
				,(SELECT [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WITH (NOLOCK)
                        WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId AND [COPIED_FROM_FINANCIAL_CLASS_ID] = [FINANCIAL_CLASS_ID]) AS [FINANCIAL_CLASS_ID]
				,[APPLY_57_MODIFIER_IF_PROCEDURE_QUALIFIES_90_DAY_GLOBAL]
				,[COLLECT_ACCIDENT_DATE]
				,[DO_NOT_EXPORT_MODIFIERS_IND]
				,[COLLECT_SUBSEQUENT_VISIT_IND]
				,[ALLOW_PHYSICIAN_SERVICE_OBSERVATION]
				,[ALLOW_MIDLEVEL_BILLING_OF_EM_SERVICES_IND]
				,[REQUIRE_AUDIT]
				,[CLINIC_PAYOR_RULE_ID]
				,[APPLY_UA_MOD_TO_SURGICAL_FAC_PROCS]
				,[USE_MEDICARE_ANESTHESIA_RULES]
				,[DISABLE_ANESTHESIA_PHYSICAL_STATUS]
				,[DISABLE_ANESTHESIA_QUALIFYING_CIRCUMSTANCES]
				,[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_TIME_CALCULATION]
				,[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_EFFECTIVE_DATE]
		FROM
			[RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([FACILITY_PAYOR_ID])) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([FACILITY_PAYOR_ID])) ) 
						FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] WITH (NOLOCK)
						WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId
						AND ([EFFECTIVE_DATE] <= GetDate())
						AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))
				)
		) AS sourceList

	-- if (item.UseGovernmentRulesForClinicProfeeEffectiveDate == DateTime.MinValue) set to null
	UPDATE #TempRows
		SET [USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_EFFECTIVE_DATE] = null
	WHERE
		[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_EFFECTIVE_DATE] IS NOT null
		AND [USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_EFFECTIVE_DATE] <= CONVERT(DATETIME, '1900-01-01');
		

	DECLARE @tempTableRowCount INT = (SELECT COUNT(*) FROM #TempRows);

	IF @tempTableRowCount <= 0
	BEGIN
		SELECT Result = 0, Error = 'No new data rows to insert';
		RETURN;
	END;

	-- Perform insert action here
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
			(
			 [SERVICE_AGREEMENT_ID]
			,[FACILITY_PAYOR_ID]
			,[FACILITY_PAYOR_NAME]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[PAYOR_METHOD_CD]
			,[PHYSICIAN_SERVICE_GUIDELINE_ID]
			,[COLLECT_DATA_FOR_CORE_MEASURES_REPORTING]
			,[APPLY_Q6_MODIFIER]
			,[APPLY_MICHIGAN_PROFEE_MEDICAID_MODIFIERS]
			,[PAYOR_CLASS_ID]
			,[FINANCIAL_CLASS_ID]
			,[APPLY_57_MODIFIER_IF_PROCEDURE_QUALIFIES_90_DAY_GLOBAL]
			,[COLLECT_ACCIDENT_DATE]
			,[DO_NOT_EXPORT_MODIFIERS_IND]
			,[COLLECT_SUBSEQUENT_VISIT_IND]
			,[ALLOW_PHYSICIAN_SERVICE_OBSERVATION]
			,[ALLOW_MIDLEVEL_BILLING_OF_EM_SERVICES_IND]
			,[REQUIRE_AUDIT]
			,[CLINIC_PAYOR_RULE_ID]
			,[APPLY_UA_MOD_TO_SURGICAL_FAC_PROCS]
			,[USE_MEDICARE_ANESTHESIA_RULES]
			,[DISABLE_ANESTHESIA_PHYSICAL_STATUS]
			,[DISABLE_ANESTHESIA_QUALIFYING_CIRCUMSTANCES]
			,[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_TIME_CALCULATION]
			,[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_EFFECTIVE_DATE]
			)
			SELECT TOP (@MaxToProcess)
				 #TempRows.[SERVICE_AGREEMENT_ID]
				,#TempRows.[FACILITY_PAYOR_ID]
				,#TempRows.[FACILITY_PAYOR_NAME]
				,#TempRows.[EFFECTIVE_DATE]
				,#TempRows.[EXPIRATION_DATE]
				,#TempRows.[PAYOR_METHOD_CD]
				,#TempRows.[PHYSICIAN_SERVICE_GUIDELINE_ID]
				,#TempRows.[COLLECT_DATA_FOR_CORE_MEASURES_REPORTING]
				,#TempRows.[APPLY_Q6_MODIFIER]
				,#TempRows.[APPLY_MICHIGAN_PROFEE_MEDICAID_MODIFIERS]
				,#TempRows.[PAYOR_CLASS_ID]
				,#TempRows.[FINANCIAL_CLASS_ID]
				,#TempRows.[APPLY_57_MODIFIER_IF_PROCEDURE_QUALIFIES_90_DAY_GLOBAL]
				,#TempRows.[COLLECT_ACCIDENT_DATE]
				,#TempRows.[DO_NOT_EXPORT_MODIFIERS_IND]
				,#TempRows.[COLLECT_SUBSEQUENT_VISIT_IND]
				,#TempRows.[ALLOW_PHYSICIAN_SERVICE_OBSERVATION]
				,#TempRows.[ALLOW_MIDLEVEL_BILLING_OF_EM_SERVICES_IND]
				,#TempRows.[REQUIRE_AUDIT]
				,#TempRows.[CLINIC_PAYOR_RULE_ID]
				,#TempRows.[APPLY_UA_MOD_TO_SURGICAL_FAC_PROCS]
				,#TempRows.[USE_MEDICARE_ANESTHESIA_RULES]
				,#TempRows.[DISABLE_ANESTHESIA_PHYSICAL_STATUS]
				,#TempRows.[DISABLE_ANESTHESIA_QUALIFYING_CIRCUMSTANCES]
				,#TempRows.[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_TIME_CALCULATION]
				,#TempRows.[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_EFFECTIVE_DATE]
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


	DECLARE @resultCount INT = (SELECT COUNT([SERVICE_AGREEMENT_PAYOR_ID]) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 06) DACS-2546 - Create Stored Procedure - ServiceAgreementPayorsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 07) DACS-2546 - Create Stored Procedure - FacilityServiceQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 07) DACS-2546 - Create Stored Procedure - FacilityServiceQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

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
-- End of 07) DACS-2546 - Create Stored Procedure - FacilityServiceQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 08) DACS-2546 - Create Stored Procedure - CriticalCareQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 08) DACS-2546 - Create Stored Procedure - CriticalCareQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[CriticalCareQualifyUpdateByServiceAgreementIds]
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
		  ,[CRITICAL_CARE_CODE_ID]
		  ,[BILLING_CODE]
		  ,[CREATION_DATE_TIME]
		  ,[CREATING_USER_PROFILE_ID]
		  ,[CHANGED_DATE_TIME]
		  ,[CHANGING_USER_PROFILE_ID]
		  ,[DEPARTMENT]
	INTO #TempRows
	FROM
		(SELECT 
			   @TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,[CRITICAL_CARE_CODE_ID]
			  ,[BILLING_CODE]
			  ,@InsDate AS [CREATION_DATE_TIME]
			  ,@UPId AS [CREATING_USER_PROFILE_ID]
			  ,@InsDate AS [CHANGED_DATE_TIME]
			  ,@UPId AS [CHANGING_USER_PROFILE_ID]
			  ,[DEPARTMENT]
		FROM
			[RevCycleDB].[dbo].[FACILITY_CRITICAL_CARE] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId

			-- The following must match to be counted as a row to skip
			AND ([CRITICAL_CARE_CODE_ID]) NOT IN 
				(
					SELECT DISTINCT ([CRITICAL_CARE_CODE_ID]) 
						FROM [RevCycleDB].[dbo].[FACILITY_CRITICAL_CARE] WITH (NOLOCK)
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

		INSERT INTO [RevCycleDB].[dbo].[FACILITY_CRITICAL_CARE]
			(
			  [SERVICE_AGREEMENT_ID]
			  ,[CRITICAL_CARE_CODE_ID]
			  ,[BILLING_CODE]
			  ,[CREATION_DATE_TIME]
			  ,[CREATING_USER_PROFILE_ID]
			  ,[CHANGED_DATE_TIME]
			  ,[CHANGING_USER_PROFILE_ID]
			  ,[DEPARTMENT]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[CRITICAL_CARE_CODE_ID]
				  ,#TempRows.[BILLING_CODE]
				  ,#TempRows.[CREATION_DATE_TIME]
				  ,#TempRows.[CREATING_USER_PROFILE_ID]
				  ,#TempRows.[CHANGED_DATE_TIME]
				  ,#TempRows.[CHANGING_USER_PROFILE_ID]
				  ,#TempRows.[DEPARTMENT]
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


	DECLARE @resultCount INT = (SELECT COUNT([CRITICAL_CARE_CODE_ID]) FROM [RevCycleDB].[dbo].[FACILITY_CRITICAL_CARE] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 08) DACS-2546 - Create Stored Procedure - CriticalCareQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 09) DACS-2546 - Create Stored Procedure - ClinicsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 09) DACS-2546 - Create Stored Procedure - ClinicsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ClinicsQualifyUpdateByServiceAgreementIds]
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
		  ,[CLINIC_ID]
		  ,[DESCRIPTION]
		  ,[SERVICE_LINE_ID]
		  -- ,[NEW_PATIENT_CLASS_ID]
		  -- ,[ESTABLISHED_PATIENT_CLASS_ID]
    INTO #TempRows
	FROM
		(SELECT 
			   @TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,[CLINIC_ID]
			  ,[DESCRIPTION]
			  ,[SERVICE_LINE_ID]
			  -- ,[NEW_PATIENT_CLASS_ID]
			  -- ,[ESTABLISHED_PATIENT_CLASS_ID]
		FROM
			[RevCycleDB].[dbo].[SERVICE_AGREEMENT_CLINIC] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([CLINIC_ID]))) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([CLINIC_ID]))) 
						FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_CLINIC] WITH (NOLOCK)
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

		INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_CLINIC]
			(
			   [SERVICE_AGREEMENT_ID]
			  ,[CLINIC_ID]
			  ,[DESCRIPTION]
			  ,[SERVICE_LINE_ID]
			  -- ,[NEW_PATIENT_CLASS_ID]
			  -- ,[ESTABLISHED_PATIENT_CLASS_ID]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[CLINIC_ID]
				  ,#TempRows.[DESCRIPTION]
				  ,#TempRows.[SERVICE_LINE_ID]
				  -- ,#TempRows.[NEW_PATIENT_CLASS_ID]
				  -- ,#TempRows.[ESTABLISHED_PATIENT_CLASS_ID]
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


	DECLARE @resultCount INT = (SELECT COUNT([CLINIC_ID]) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_CLINIC] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 09) DACS-2546 - Create Stored Procedure - ClinicsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 10) DACS-2546 - Create Stored Procedure - CptChangeReasonsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 10) DACS-2546 - Create Stored Procedure - CptChangeReasonsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[CptChangeReasonsQualifyUpdateByServiceAgreementIds]
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
		   [DISPLAY_NAME]
		  ,[DESCRIPTION]
		  ,[CREATION_DATE_TIME]
		  ,[CREATING_USER_PROFILE_ID]
		  ,[CHANGED_DATE_TIME]
		  ,[CHANGING_USER_PROFILE_ID]
		  ,[SERVICE_AGREEMENT_ID]
		  ,[EFFECTIVE_DATE]
		  ,[EXPIRATION_DATE]
	INTO #TempRows
	FROM
		(SELECT 
			   [DISPLAY_NAME]
			  ,[DESCRIPTION]
			  ,@InsDate AS [CREATION_DATE_TIME]
			  ,@UPId AS [CREATING_USER_PROFILE_ID]
			  ,@InsDate AS [CHANGED_DATE_TIME]
			  ,@UPId AS [CHANGING_USER_PROFILE_ID]
			  ,@TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,@EffectiveDate AS [EFFECTIVE_DATE]
			  ,@ExpirationDate AS [EXPIRATION_DATE]
		FROM
			[RevCycleDB].[dbo].[CPT_CHANGE_REASON] WITH (NOLOCK)
		WHERE 
			([SERVICE_AGREEMENT_ID] = @SourceSAId AND [SERVICE_AGREEMENT_ID] IS NOT NULL) -- do NOT copy records with a null in this field - These are universal values available to ALL SAIds.
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([DISPLAY_NAME])) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([DISPLAY_NAME])) ) 
						FROM [RevCycleDB].[dbo].[CPT_CHANGE_REASON] WITH (NOLOCK)
						WHERE ([SERVICE_AGREEMENT_ID] = @TargetSAId AND [SERVICE_AGREEMENT_ID] IS NOT NULL) -- do NOT copy records with a null in this field - These are universal values available to ALL SAIds.
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

		INSERT INTO [RevCycleDB].[dbo].[CPT_CHANGE_REASON]
			(
			   [DISPLAY_NAME]
			  ,[DESCRIPTION]
			  ,[CREATION_DATE_TIME]
			  ,[CREATING_USER_PROFILE_ID]
			  ,[CHANGED_DATE_TIME]
			  ,[CHANGING_USER_PROFILE_ID]
			  ,[SERVICE_AGREEMENT_ID]
			  ,[EFFECTIVE_DATE]
			  ,[EXPIRATION_DATE]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[DISPLAY_NAME]
				  ,#TempRows.[DESCRIPTION]
				  ,#TempRows.[CREATION_DATE_TIME]
				  ,#TempRows.[CREATING_USER_PROFILE_ID]
				  ,#TempRows.[CHANGED_DATE_TIME]
				  ,#TempRows.[CHANGING_USER_PROFILE_ID]
				  ,#TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[EFFECTIVE_DATE]
				  ,#TempRows.[EXPIRATION_DATE]
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


	DECLARE @resultCount INT = (SELECT COUNT([CPT_CHANGE_REASON_ID]) FROM [RevCycleDB].[dbo].[CPT_CHANGE_REASON] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 10) DACS-2546 - Create Stored Procedure - CptChangeReasonsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 11) DACS-2546 - Create Stored Procedure - ReasonsForVisitQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 11) DACS-2546 - Create Stored Procedure - ReasonsForVisitQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ReasonsForVisitQualifyUpdateByServiceAgreementIds]
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
-- End of 11) DACS-2546 - Create Stored Procedure - ReasonsForVisitQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 12) DACS-2546 - Create Stored Procedure - BusinessUnitsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 12) DACS-2546 - Create Stored Procedure - BusinessUnitsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[BusinessUnitsQualifyUpdateByServiceAgreementIds]
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
-- End of 12) DACS-2546 - Create Stored Procedure - BusinessUnitsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 13) DACS-2546 - Create Stored Procedure - ProviderRoleDefinitionsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 13) DACS-2546 - Create Stored Procedure - ProviderRoleDefinitionsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ProviderRoleDefinitionsQualifyUpdateByServiceAgreementIds]
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
		  ,[ROLE_NAME]
		  ,[ORDERING_PROVIDER_LIST_IND]
		  ,[MIDLEVEL_PROVIDER_LIST_IND]
		  ,[PERFORMING_PROVIDER_LIST_IND]
		  ,[TRIAGE_PROVIDER_LIST_IND]
		  ,[FACILITY_ORDERING_PROVIDER_EXPORT_IND]
		  ,[FACILITY_PERFORMING_PROVIDER_EXPORT_IND]
		  ,[PROFEE_ORDERING_PROVIDER_EXPORT_IND]
		  ,[PROFEE_PERFORMING_PROVIDER_EXPORT_IND]
		  ,[EFFECTIVE_DATE]
		  ,[EXPIRATION_DATE]
    INTO #TempRows
	FROM
		(SELECT 
			   @TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,[ROLE_NAME]
			  ,[ORDERING_PROVIDER_LIST_IND]
			  ,[MIDLEVEL_PROVIDER_LIST_IND]
			  ,[PERFORMING_PROVIDER_LIST_IND]
			  ,[TRIAGE_PROVIDER_LIST_IND]
			  ,[FACILITY_ORDERING_PROVIDER_EXPORT_IND]
			  ,[FACILITY_PERFORMING_PROVIDER_EXPORT_IND]
			  ,[PROFEE_ORDERING_PROVIDER_EXPORT_IND]
			  ,[PROFEE_PERFORMING_PROVIDER_EXPORT_IND]
			  ,@EffectiveDate AS [EFFECTIVE_DATE]
			  ,@ExpirationDate AS [EXPIRATION_DATE]
		FROM
			[RevCycleDB].[dbo].[PROVIDER_ROLE_DEFINITION] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([ROLE_NAME])) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([ROLE_NAME])) ) 
						FROM [RevCycleDB].[dbo].[PROVIDER_ROLE_DEFINITION] WITH (NOLOCK)
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

		INSERT INTO [RevCycleDB].[dbo].[PROVIDER_ROLE_DEFINITION]
			(
			   [SERVICE_AGREEMENT_ID]
			  ,[ROLE_NAME]
			  ,[ORDERING_PROVIDER_LIST_IND]
			  ,[MIDLEVEL_PROVIDER_LIST_IND]
			  ,[PERFORMING_PROVIDER_LIST_IND]
			  ,[TRIAGE_PROVIDER_LIST_IND]
			  ,[FACILITY_ORDERING_PROVIDER_EXPORT_IND]
			  ,[FACILITY_PERFORMING_PROVIDER_EXPORT_IND]
			  ,[PROFEE_ORDERING_PROVIDER_EXPORT_IND]
			  ,[PROFEE_PERFORMING_PROVIDER_EXPORT_IND]
			  ,[EFFECTIVE_DATE]
			  ,[EXPIRATION_DATE]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[ROLE_NAME]
				  ,#TempRows.[ORDERING_PROVIDER_LIST_IND]
				  ,#TempRows.[MIDLEVEL_PROVIDER_LIST_IND]
				  ,#TempRows.[PERFORMING_PROVIDER_LIST_IND]
				  ,#TempRows.[TRIAGE_PROVIDER_LIST_IND]
				  ,#TempRows.[FACILITY_ORDERING_PROVIDER_EXPORT_IND]
				  ,#TempRows.[FACILITY_PERFORMING_PROVIDER_EXPORT_IND]
				  ,#TempRows.[PROFEE_ORDERING_PROVIDER_EXPORT_IND]
				  ,#TempRows.[PROFEE_PERFORMING_PROVIDER_EXPORT_IND]
				  ,#TempRows.[EFFECTIVE_DATE]
				  ,#TempRows.[EXPIRATION_DATE]
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


	DECLARE @resultCount INT = (SELECT COUNT([PROVIDER_ROLE_DEFINITION_ID]) FROM [RevCycleDB].[dbo].[PROVIDER_ROLE_DEFINITION] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 13) DACS-2546 - Create Stored Procedure - ProviderRoleDefinitionsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 14) DACS-2546 - Create Stored Procedure - BypassAutoApprovalsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 14) DACS-2546 - Create Stored Procedure - BypassAutoApprovalsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[BypassAutoApprovalsQualifyUpdateByServiceAgreementIds]
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
      ,[ICD10_CODE]
    INTO #TempRows
	FROM
		(SELECT 
		   @TargetSAId AS [SERVICE_AGREEMENT_ID]
		  ,[ICD10_CODE]
		FROM
			[RevCycleDB].[dbo].[DIAGNOSIS_CODE_ICD10_BYPASS_AUTO_APPROVAL] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId

			-- The following must match to be counted as a row to skip
			AND (LOWER(RTRIM([ICD10_CODE])) ) NOT IN 
				(
					SELECT DISTINCT (LOWER(RTRIM([ICD10_CODE])) ) 
						FROM [RevCycleDB].[dbo].[DIAGNOSIS_CODE_ICD10_BYPASS_AUTO_APPROVAL] WITH (NOLOCK)
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

		INSERT INTO [RevCycleDB].[dbo].[DIAGNOSIS_CODE_ICD10_BYPASS_AUTO_APPROVAL]
			(
			   [SERVICE_AGREEMENT_ID]
			  ,[ICD10_CODE]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[ICD10_CODE]
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


	DECLARE @resultCount INT = (SELECT COUNT([DIAGNOSIS_CODE_ICD10_BYPASS_AUTO_APPROVAL_ID]) FROM [RevCycleDB].[dbo].[DIAGNOSIS_CODE_ICD10_BYPASS_AUTO_APPROVAL] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 14) DACS-2546 - Create Stored Procedure - BypassAutoApprovalsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 15) DACS-2546 - Create Stored Procedure - ChargePackageItemsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 15) DACS-2546 - Create Stored Procedure - ChargePackageItemsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ChargePackageItemsQualifyUpdateByServiceAgreementIds]
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
		  ,[PACKAGE_TYPE_CD]
		  ,[PACKAGE_EVENT_ID]
		  ,[CHARGE_MASTER_ID]
		  ,[UNITS]
		  ,[REQUIRED]
		  ,[EFFECTIVE_DATE]
		  ,[EXPIRATION_DATE]
		  ,[CREATION_DATE_TIME]
		  ,[CREATING_USER_PROFILE_ID]
		  ,[CHANGED_DATE_TIME]
		  ,[CHANGING_USER_PROFILE_ID]
		  ,[FACILITY_SERVICE_SCHEDULE_ID]
		  ,[SUPPLY_IND]    
	INTO #TempRows
	FROM
		(SELECT 
			   [SERVICE_AGREEMENT_ID]
			  ,[PACKAGE_TYPE_CD]
			  ,[PACKAGE_EVENT_ID]
			  ,[CHARGE_MASTER_ID]
			  ,[UNITS]
			  ,[REQUIRED]
			  ,@EffectiveDate AS [EFFECTIVE_DATE]
			  ,@ExpirationDate AS [EXPIRATION_DATE]
			  ,@InsDate AS [CREATION_DATE_TIME]
			  ,@UPId AS [CREATING_USER_PROFILE_ID]
			  ,@InsDate AS [CHANGED_DATE_TIME]
			  ,@UPId AS [CHANGING_USER_PROFILE_ID]
			  ,[FACILITY_SERVICE_SCHEDULE_ID]
			  ,[SUPPLY_IND]   
		FROM
			[RevCycleDB].[dbo].[CHARGE_PACKAGE_ITEM] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId
			AND ([EFFECTIVE_DATE] <= GetDate())
			AND ([EXPIRATION_DATE] IS NULL OR ([EXPIRATION_DATE] >= GetDate()))
			
			-- The following must match to be counted as a row to skip
			AND ([PACKAGE_EVENT_ID]) NOT IN 
				(
					SELECT DISTINCT ([PACKAGE_EVENT_ID]) 
						FROM [RevCycleDB].[dbo].[CHARGE_PACKAGE_ITEM] WITH (NOLOCK)
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

		INSERT INTO [RevCycleDB].[dbo].[CHARGE_PACKAGE_ITEM]
			(
			   [SERVICE_AGREEMENT_ID]
			  ,[PACKAGE_TYPE_CD]
			  ,[PACKAGE_EVENT_ID]
			  ,[CHARGE_MASTER_ID]
			  ,[UNITS]
			  ,[REQUIRED]
			  ,[EFFECTIVE_DATE]
			  ,[EXPIRATION_DATE]
			  ,[CREATION_DATE_TIME]
			  ,[CREATING_USER_PROFILE_ID]
			  ,[CHANGED_DATE_TIME]
			  ,[CHANGING_USER_PROFILE_ID]
			  ,[FACILITY_SERVICE_SCHEDULE_ID]
			  ,[SUPPLY_IND]   			
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[PACKAGE_TYPE_CD]
				  ,#TempRows.[PACKAGE_EVENT_ID]
				  ,#TempRows.[CHARGE_MASTER_ID]
				  ,#TempRows.[UNITS]
				  ,#TempRows.[REQUIRED]
				  ,#TempRows.[EFFECTIVE_DATE]
				  ,#TempRows.[EXPIRATION_DATE]
				  ,#TempRows.[CREATION_DATE_TIME]
				  ,#TempRows.[CREATING_USER_PROFILE_ID]
				  ,#TempRows.[CHANGED_DATE_TIME]
				  ,#TempRows.[CHANGING_USER_PROFILE_ID]
				  ,#TempRows.[FACILITY_SERVICE_SCHEDULE_ID]
				  ,#TempRows.[SUPPLY_IND]   	
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


	DECLARE @resultCount INT = (SELECT COUNT([CHARGE_PACKAGE_ITEM_ID]) FROM [RevCycleDB].[dbo].[CHARGE_PACKAGE_ITEM] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 15) DACS-2546 - Create Stored Procedure - ChargePackageItemsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 16) DACS-2546 - Create Stored Procedure - PhysicianCriticalCareQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 16) DACS-2546 - Create Stored Procedure - PhysicianCriticalCareQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PhysicianCriticalCareQualifyUpdateByServiceAgreementIds]
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
		  ,[CRITICAL_CARE_CODE_ID]
		  ,[BILLING_CODE]
		  ,[CREATION_DATE_TIME]
		  ,[CREATING_USER_PROFILE_ID]
		  ,[CHANGED_DATE_TIME]
		  ,[CHANGING_USER_PROFILE_ID]
		  ,[DEPARTMENT]
		  ,[ALIAS_BILLING_CODE]
	INTO #TempRows
	FROM
		(SELECT 
			   @TargetSAId AS [SERVICE_AGREEMENT_ID]
			  ,[CRITICAL_CARE_CODE_ID]
			  ,[BILLING_CODE]
			  ,@InsDate AS [CREATION_DATE_TIME]
			  ,@UPId AS [CREATING_USER_PROFILE_ID]
			  ,@InsDate AS [CHANGED_DATE_TIME]
			  ,@UPId AS [CHANGING_USER_PROFILE_ID]
			  ,[DEPARTMENT]
			  ,[ALIAS_BILLING_CODE]		
		FROM
			[RevCycleDB].[dbo].[PHYSICIAN_CRITICAL_CARE] WITH (NOLOCK)
		WHERE 
			[SERVICE_AGREEMENT_ID] = @SourceSAId

			-- The following must match to be counted as a row to skip
			AND ([CRITICAL_CARE_CODE_ID]) NOT IN 
				(
					SELECT DISTINCT ([CRITICAL_CARE_CODE_ID]) 
						FROM [RevCycleDB].[dbo].[PHYSICIAN_CRITICAL_CARE] WITH (NOLOCK)
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

		INSERT INTO [RevCycleDB].[dbo].[PHYSICIAN_CRITICAL_CARE]
			(
			   [SERVICE_AGREEMENT_ID]
			  ,[CRITICAL_CARE_CODE_ID]
			  ,[BILLING_CODE]
			  ,[CREATION_DATE_TIME]
			  ,[CREATING_USER_PROFILE_ID]
			  ,[CHANGED_DATE_TIME]
			  ,[CHANGING_USER_PROFILE_ID]
			  ,[DEPARTMENT]
			  ,[ALIAS_BILLING_CODE]
			)
			SELECT TOP (@MaxToProcess)
				   #TempRows.[SERVICE_AGREEMENT_ID]
				  ,#TempRows.[CRITICAL_CARE_CODE_ID]
				  ,#TempRows.[BILLING_CODE]
				  ,#TempRows.[CREATION_DATE_TIME]
				  ,#TempRows.[CREATING_USER_PROFILE_ID]
				  ,#TempRows.[CHANGED_DATE_TIME]
				  ,#TempRows.[CHANGING_USER_PROFILE_ID]
				  ,#TempRows.[DEPARTMENT]
				  ,#TempRows.[ALIAS_BILLING_CODE]
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


	DECLARE @resultCount INT = (SELECT COUNT([CRITICAL_CARE_CODE_ID]) FROM [RevCycleDB].[dbo].[PHYSICIAN_CRITICAL_CARE] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)

	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20));

END -- end of stored procedure

GO
-- End of 16) DACS-2546 - Create Stored Procedure - PhysicianCriticalCareQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 17) DACS-2546 - Create Stored Procedure - FacilityInfusionsQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 17) DACS-2546 - Create Stored Procedure - FacilityInfusionsQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

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
-- End of 17) DACS-2546 - Create Stored Procedure - FacilityInfusionsQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 18) DACS-2546 - Create Stored Procedure - ProvidersQualifyUpdateByServiceAgreementIds.SQL

-------------------------------------------------------------
-- 18) DACS-2546 - Create Stored Procedure - ProvidersQualifyUpdateByServiceAgreementIds.SQL
-------------------------------------------------------------
GO

GO

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
-- End of 18) DACS-2546 - Create Stored Procedure - ProvidersQualifyUpdateByServiceAgreementIds.SQL
GO

-- Start of 01) DACS-2581 - Alter Table - dbo.SERVICE_AGREEMENT_CLINIC.SQL

----------------------------------------------------------------
-- 01) DACS-2581 - Alter Table - dbo.SERVICE_AGREEMENT_CLINIC.SQL
----------------------------------------------------------------
GO

GO

GO

ALTER TABLE [dbo].[SERVICE_AGREEMENT_CLINIC]
	ADD [DEFAULT_SELECTION] bit NULL;
-- End of 01) DACS-2581 - Alter Table - dbo.SERVICE_AGREEMENT_CLINIC.SQL
GO

-- Start of 02) DACS-2581 - Alter Procedure - dbo.spGetServiceAgreementClinics.SQL

----------------------------------------------------------------
-- 02) DACS-2581 - Alter Procedure - dbo.spGetServiceAgreementClinics.SQL
----------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[spGetServiceAgreementClinics]
	  @ServiceAgreementId int = null
	, @ClinicId varchar(10) = null

-- added field DEFAULT_SELECTION 20230720 - DACS-2581
	
WITH EXEC AS CALLER
AS
	DECLARE @service_agreement_id int = @ServiceAgreementId;
	DECLARE @clinic_id datetime = @ClinicId;

	SELECT 
		 [SERVICE_AGREEMENT_ID] 
		,[CLINIC_ID]
		,[DESCRIPTION]
		,[SERVICE_LINE_ID]
		,[NEW_PATIENT_CLASS_ID]
		,[ESTABLISHED_PATIENT_CLASS_ID]
		,[DEFAULT_SELECTION]
	FROM 
		[dbo].[SERVICE_AGREEMENT_CLINIC] WITH (NOLOCK)
	WHERE
		(@service_agreement_id IS NULL OR [SERVICE_AGREEMENT_ID] = @service_agreement_id)
		AND (@clinic_id IS NULL OR [CLINIC_ID] = @clinic_id)
	ORDER BY 
		[DESCRIPTION]; -- add ordering 20230607 - DACS-2457

GO


-- End of 02) DACS-2581 - Alter Procedure - dbo.spGetServiceAgreementClinics.SQL
GO

-- Start of 03) DACS-2581 - Alter Procedure - dbo.spSaveServiceAgreementClinic.SQL

----------------------------------------------------------------
-- 03) DACS-2581 - Alter Procedure - dbo.spSaveServiceAgreementClinic.SQL
----------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[spSaveServiceAgreementClinic]
	  @ServiceAgreementId int = null
	, @ClinicId varchar(10) = null
	, @Description varchar(100) = null
	, @NewClinicId varchar(10) = null
	, @DefaultSelection bit = null
	
-- added field DEFAULT_SELECTION 20230720 - DACS-2581
	
WITH EXEC AS CALLER
AS
	UPDATE 
		[dbo].[SERVICE_AGREEMENT_CLINIC]
	SET
		 [SERVICE_AGREEMENT_ID] = @ServiceAgreementId 
		,[CLINIC_ID] = @NewClinicId
		,[DESCRIPTION] = @Description
		,[DEFAULT_SELECTION] = @DefaultSelection
	WHERE 
		[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND [CLINIC_ID] = @ClinicId
		
	IF @@ROWCOUNT = 0
	BEGIN
	  INSERT INTO [dbo].[SERVICE_AGREEMENT_CLINIC] ( 
		 [SERVICE_AGREEMENT_ID]
		,[CLINIC_ID]
		,[DESCRIPTION]
		,[SERVICE_LINE_ID]
		,[DEFAULT_SELECTION]
	  )
	  VALUES 
	  (
		 @ServiceAgreementId
		,@ClinicId
		,@Description
		,-1
		,@DefaultSelection
	  )
	END
GO


-- End of 03) DACS-2581 - Alter Procedure - dbo.spSaveServiceAgreementClinic.SQL
GO

-- Start of 1) DACS-1652 Add Facilities to User.sql

--ONLY Run in Production for this user

EXEC [dbo].[Maintenance_GrantUserAccessToAllFacilities] @UserProfileId = 12139, @AdministratorUsername = 'MFERRELL', @EffectiveDate = '7/24/2023 12:00:00 AM', @ExpirationDate = '12/30/2099 12:00:00 AM'  
-- End of 1) DACS-1652 Add Facilities to User.sql
GO

-- Start of 1) DACS-1934 Add Facilities to User.sql

--ONLY Run in Production for this user

EXEC [dbo].[Maintenance_GrantUserAccessToAllFacilities] @UserProfileId = 10245, @AdministratorUsername = 'MFERRELL', @EffectiveDate = '7/24/2023 12:00:00 AM', @ExpirationDate = '12/30/2099 12:00:00 AM'  
-- End of 1) DACS-1934 Add Facilities to User.sql
GO

-- Start of 1) DACS-2604 Add Facilities to User.sql

--ONLY Run in Production for this user

EXEC [dbo].[Maintenance_GrantUserAccessToAllFacilities] @UserProfileId = 14064, @AdministratorUsername = 'MFERRELL', @EffectiveDate = '7/24/2023 12:00:00 AM', @ExpirationDate = '12/30/2099 12:00:00 AM'  
-- End of 1) DACS-2604 Add Facilities to User.sql
GO

-- Start of 01) DACS-2606 - Alter Procedure - dbo.ChartSelectFlaggedForPbaByChartId.SQL

----------------------------------------------------------------
-- 01) DACS-2606 - Alter Procedure - dbo.ChartSelectFlaggedForPbaByChartId.SQL
----------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ChartSelectFlaggedForPbaByChartId]
	  @ChartId int
	
AS
	SELECT 
		count([CHART_ID])
	FROM
		[dbo].[CHART] WITH (NOLOCK)
	WHERE
		[CHART_ID] = @ChartId
		AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] IS NOT NULL
		AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] >= DATEADD(day, -14, GETDATE())

GO

/*
test:
exec [dbo].[ChartSelectFlaggedForPbaByChartId] @ChartId= 2100101604

set the date for testing as needed on QA:
begin tran;
update
	[dbo].[CHART]
SET 
	[FLAGGED_FOR_POST_BILL_AUDIT_DT] = NULL
WHERE
	[CHART_ID] = 2100101604
	AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] IS NOT NULL
	AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] >= DATEADD(day, -14, GETDATE())
--commit tran;
--rollback tran;
*/
-- End of 01) DACS-2606 - Alter Procedure - dbo.ChartSelectFlaggedForPbaByChartId.SQL
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
