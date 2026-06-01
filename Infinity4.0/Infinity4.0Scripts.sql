USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2992 - Create Stored Procedure - SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId.SQL

----------------------------------------
-- 01) DACS-2992 - Create Stored Procedure - SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId.SQL
----------------------------------------
GO

GO

GO
 
CREATE OR ALTER PROCEDURE [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId]
	 @Uid INT
	,@CsvListGroupIds varchar(4000)
AS
BEGIN
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @Uid IS NULL OR @Uid <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;

	IF @CsvListGroupIds IS NULL OR LEN(@CsvListGroupIds) <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;
	
	DECLARE @dos datetime = getdate();
	
	-- load temp table with csv data
	DECLARE @tempUserGroupIds TABLE	( UGID INT );

	INSERT @tempUserGroupIds(UGID)
		SELECT 
			CAST(RTRIM(LTRIM(value)) AS INT) AS UGID
		FROM STRING_SPLIT (@CsvListGroupIds, ',')
	
	DECLARE @countToProcess INT = (SELECT COUNT(*) FROM @tempUserGroupIds);

	IF @countToProcess <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;

	IF OBJECT_ID('tempdb..#TempRows') IS NOT NULL
	BEGIN
		DROP TABLE #TempRows
	END;

	SELECT DISTINCT TOP (1000) 
		pr.[NAME]
		,ugpr.[PORTAL_REPORT_ID]
	INTO #TempRows
	FROM 
		[RevCycleDB].[dbo].[USER_GROUP_TO_PORTAL_REPORT] ugpr
		INNER JOIN PORTAL_REPORT pr ON pr.PORTAL_REPORT_ID = ugpr.PORTAL_REPORT_ID
	where 
		ugpr.[USER_GROUP_ID] IN (SELECT DISTINCT UGID FROM @tempUserGroupIds)
		AND [EFFECTIVE_DATE] <= @dos
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @dos)

	DECLARE @countUserGroupReports INT = (SELECT COUNT(*) FROM #TempRows);

	IF @countUserGroupReports <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;

	IF OBJECT_ID('tempdb..#TempAuthFacRpts') IS NOT NULL
	BEGIN
		DROP TABLE #TempAuthFacRpts
	END;

	SELECT DISTINCT TOP (100000) 
		fpr.[PORTAL_REPORT_ID]
	INTO #TempAuthFacRpts
	FROM 
		[RevCycleDB].[dbo].[FACILITY_TO_PORTAL_REPORT] fpr
	WHERE 
		fpr.[FACILITY_ID] IN (SELECT DISTINCT TOP (10000) [FACILITY_ID] FROM [FACILITY_USER_AUTHORIZATION] WHERE [USER_PROFILE_ID] = @Uid);

	DECLARE @countFacilityReports INT = (SELECT COUNT(*) FROM #TempAuthFacRpts);

	IF @countFacilityReports <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;

	DELETE FROM #TempRows
		WHERE [PORTAL_REPORT_ID] NOT IN (SELECT DISTINCT [PORTAL_REPORT_ID] FROM #TempAuthFacRpts)

	SELECT DISTINCT [NAME] AS [ReportName] FROM #TempRows
		

END; -- end of stored procedure

GO 

/*
testing 
exec [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId] @Uid = 7157, @CsvListGroupIds = '1,2,203,4'
exec [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId] @Uid = 10281, @CsvListGroupIds = '1,2,203,4'
exec [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId] @Uid = 7157, @CsvListGroupIds = '1,2,203,4asdad'
exec [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId] @Uid = 7157, @CsvListGroupIds = ''

exec [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId] @Uid = 7157, @CsvListGroupIds = '203,201,202,277'
exec [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId] @Uid = 10281, @CsvListGroupIds = '203,201,202,277'
*/
-- End of 01) DACS-2992 - Create Stored Procedure - SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId.SQL
GO

-- Start of 01) DACS-3018 - Alter Procedure - [dbo].[PhysicianServiceProcedureQualifyUpdateByServiceAgreementIds].SQL

----------------------------------------------------------------------------------------
-- 01) DACS-3018 - Alter Procedure - [dbo].[PhysicianServiceProcedureQualifyUpdateByServiceAgreementIds].SQL
----------------------------------------------------------------------------------------
GO

GO

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

	-- Fill temp table with our data
	SELECT 
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
				,ISNULL((SELECT TOP(1) [PATIENT_CLASS_ID] FROM [PATIENT_CLASS] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId AND [COPIED_FROM_PATIENT_CLASS_ID] = src.[PATIENT_CLASS_ID]), -1) AS [PATIENT_CLASS_ID]
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
		AND 
		
			CAST([SERVICE_LEVEL_CD] AS VARCHAR(20)) + ',' +  
			RTRIM([CPT_CODE]) + ',' +  
			RTRIM([BILLING_CODE]) + ',' +  
			CAST([OVERRIDE_ONLY_IND] AS VARCHAR(20)) + ',' +  
			RTRIM([DESCRIPTION]) + ',' + 
			CAST([REPORTING_COLUMN] AS VARCHAR(20)) + ',' +  
			--CAST([PATIENT_CLASS_ID] AS VARCHAR(20)) + ',' +  
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
						--CAST([PATIENT_CLASS_ID] AS VARCHAR(20)) + ',' +  
						CAST([PROCEDURES] AS VARCHAR(20)) + ',' +  
						CAST([ALLOW_WITH_NO_PHYSICIAN_SERVICES] AS VARCHAR(20)) + ',' +  
						CAST([CRITICAL_CARE] AS VARCHAR(20)) 

					FROM [RevCycleDB].[dbo].[PHYSICIAN_SERVICE_PROCEDURE] WITH (NOLOCK)
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


-- End of 01) DACS-3018 - Alter Procedure - [dbo].[PhysicianServiceProcedureQualifyUpdateByServiceAgreementIds].SQL
GO

-- Start of 02) DACS-3018 - Alter Procedure - [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName].SQL

----------------------------------------------------------------------------------------
-- 02) DACS-3018 - Alter Procedure - [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName].SQL
----------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROC [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName]  
	 @TableName VARCHAR(1024)
AS  
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @TableName IS NULL OR LEN(@TableName) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'Error: TableName is invalid.';
		RETURN;
	END;

	PRINT('TableName = ' + @TableName);

	IF OBJECT_ID('tempdb..#tmpFKeys') IS NOT NULL
	BEGIN
		DROP TABLE #tmpFKeys
	END;
	
	IF OBJECT_ID('tempdb..#tmpFKTables') IS NOT NULL
	BEGIN
		DROP TABLE #tmpFKTables
	END;

	-- find Foreign Keys specified thru linked objects.  deleting these tables should remove any FK exceptions!!
	CREATE TABLE #tmpFKeys(
		PKTABLE_QUALIFIER	[nvarchar](255) NULL
		,PKTABLE_OWNER		[nvarchar](255) NULL
		,PKTABLE_NAME		[nvarchar](255) NULL
		,PKCOLUMN_NAME		[nvarchar](255) NULL
		,FKTABLE_QUALIFIER	[nvarchar](255) NULL
		,FKTABLE_OWNER		[nvarchar](255) NULL
		,FKTABLE_NAME		[nvarchar](255) NULL
		,FKCOLUMN_NAME		[nvarchar](255) NULL
		,KEY_SEQ			INT
		,UPDATE_RULE		INT	
		,DELETE_RULE		INT
		,FK_NAME			[nvarchar](255) NULL
		,PK_NAME			[nvarchar](255) NULL
		,DEFERRABILITY		INT
	)

	INSERT INTO #tmpFKeys
		EXEC sp_fkeys @pktable_name = @TableName
	
	SELECT [FKTABLE_NAME] INTO #tmpFKTables
		FROM (SELECT DISTINCT [FKTABLE_NAME] FROM #tmpFKeys) AS FKSource;

	SELECT * FROM #tmpFKTables;

GO


/*
test:
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = 'FACILITY'
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = 'SERVICE_AGREEMENT'
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = 'CHARGE_MASTER'
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = ''
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = NULL
*/


-- End of 02) DACS-3018 - Alter Procedure - [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName].SQL
GO

-- Start of 01) DACS-3000 - Create Stored Procedure - QualifyAbandonQABeginCodingStateByChartId.SQL

----------------------------------------
-- 01) DACS-3000 - Create Stored Procedure - QualifyAbandonQABeginCodingStateByChartId.SQL
----------------------------------------
GO

GO

GO
 
CREATE OR ALTER PROCEDURE [dbo].[QualifyAbandonQABeginCodingStateByChartId]
	@ChartId INT
AS
BEGIN
 
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;
	
	DECLARE @dos datetime = GETDATE();
	DECLARE @dosMin datetime = DATEADD(day, -14, @dos);
	
	-- check to see if the given ChartId is in an open "begin QA" session state.
	-- limit this search as the chart access table has lots of records
	DECLARE @countFound INT = 
	(
		SELECT COUNT(*) 
		FROM [CHART_ACCESS] 
		WHERE [CHART_ID] = @ChartId
			AND [CHART_ACCESS_EVENT_TYPE_CODE] = 'Q' 
			AND [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] IS NULL
			AND [ACCESS_DATE_TIME] BETWEEN @dosMin AND @dos
	);

	IF @countFound <= 0
	BEGIN
		SELECT Result = 0;
		RETURN;
	END;

	-- do the update for the found records
	UPDATE [CHART_ACCESS]
	SET  
		 [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] = 'X'
		,[SECONDARY_EVENT_COMPLETION_DATE_TIME] = @dos
	WHERE [CHART_ID] = @ChartId
		AND [CHART_ACCESS_EVENT_TYPE_CODE] = 'Q' 
		AND [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] IS NULL
		AND [ACCESS_DATE_TIME] BETWEEN @dosMin AND @dos;
		
	-- double check our work	
	DECLARE @countFoundAfter INT = 
	(
		SELECT COUNT(*) 
		FROM [CHART_ACCESS] 
		WHERE [CHART_ID] = @ChartId
			AND [CHART_ACCESS_EVENT_TYPE_CODE] = 'Q' 
			AND [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] IS NULL
			AND [ACCESS_DATE_TIME] BETWEEN @dosMin AND @dos
	);

	SELECT IIF(@countFoundAfter <= 0, @countFound, (0 - @countFoundAfter));

END; -- end of stored procedure

GO 

/*
testing QA
  begin tran ;
  exec [dbo].[QualifyAbandonQABeginCodingStateByChartId] @ChartId= 112708244
  rollback tran;
  commit tran;
*/
-- End of 01) DACS-3000 - Create Stored Procedure - QualifyAbandonQABeginCodingStateByChartId.SQL
GO

-- Start of 02) DACS-3000 - Create Stored Procedure - SelectQABeginCodingStateIsSetByChartIdAsBoolean.SQL

----------------------------------------
-- 02) DACS-3000 - Create Stored Procedure - SelectQABeginCodingStateIsSetByChartIdAsBoolean.SQL
----------------------------------------
GO

GO

GO
 
CREATE OR ALTER PROCEDURE [dbo].[SelectQABeginCodingStateIsSetByChartIdAsBoolean]
	@ChartId INT
AS
BEGIN
 
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;
	
	DECLARE @dos datetime = GETDATE();
	DECLARE @dosMin datetime = DATEADD(day, -60, @dos);
	
	SELECT 
		CAST(IIF((
				SELECT COUNT(*) 
				FROM [CHART_ACCESS] 
				WHERE [CHART_ID] = @ChartId
					AND [CHART_ACCESS_EVENT_TYPE_CODE] = 'Q' 
					AND [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] IS NULL
					AND [ACCESS_DATE_TIME] BETWEEN @dosMin AND @dos
				) > 0, 1, 0) AS BIT);
	
END; -- end of stored procedure

GO 

/*
testing QA
CHART_ID	ACCESS_DATE_TIME	CHART_ACCESS_EVENT_TYPE_CODE	EVENT_COMPLETION_DATE_TIME	CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE
106674477	2023-08-29 06:49:15.620	Q	2023-08-29 06:49:15.620	A
115026478	2024-01-24 06:12:21.530	Q	2024-01-24 06:12:21.530	A
114912296	2024-01-29 05:49:27.300	Q	2024-01-29 05:49:27.300	A
114913030	2024-01-29 05:51:36.417	Q	2024-01-29 05:51:36.417	A
114913145	2024-01-29 05:52:41.000	Q	2024-01-29 05:52:41.000	A
114913224	2024-01-29 05:55:00.413	Q	2024-01-29 05:55:00.413	A

CHART_ID	ACCESS_DATE_TIME	CHART_ACCESS_EVENT_TYPE_CODE	EVENT_COMPLETION_DATE_TIME	CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE
112708244	2024-02-14 05:08:58.020	Q	2024-02-14 05:08:58.020	NULL
115815753	2024-02-15 00:57:05.903	Q	2024-02-15 00:57:05.903	NULL
116028171	2024-02-15 01:05:27.430	Q	2024-02-15 01:05:27.430	NULL
116029668	2024-02-15 01:21:35.693	Q	2024-02-15 01:21:35.693	NULL
115921890	2024-02-15 01:35:50.130	Q	2024-02-15 01:35:50.130	NULL
115802503	2024-02-15 01:36:37.387	Q	2024-02-15 01:36:37.387	NULL

exec [dbo].[SelectQABeginCodingStateIsSetByChartIdAsBoolean] @ChartId= 106674477
exec [dbo].[SelectQABeginCodingStateIsSetByChartIdAsBoolean] @ChartId= 115026478
exec [dbo].[SelectQABeginCodingStateIsSetByChartIdAsBoolean] @ChartId= 112708244
exec [dbo].[SelectQABeginCodingStateIsSetByChartIdAsBoolean] @ChartId= 115815753
*/
-- End of 02) DACS-3000 - Create Stored Procedure - SelectQABeginCodingStateIsSetByChartIdAsBoolean.SQL
GO

-- Start of 01) DACS-2795 - CREATE or Alter FUNCTION - udfGetAllowedFacilityIdsForUserId.SQL

----------------------------------------
-- 01) DACS-2795 - CREATE or Alter FUNCTION - udfGetAllowedFacilityIdsForUserId.SQL
----------------------------------------
GO

GO

GO

-- retrieves the facility_id access List for a specifed user on a specific DATE
-- The iTVF has not included BEGIN/END block in their syntax and the SELECT statement is the output of this type of functions

CREATE or Alter FUNCTION [dbo].[udfGetAllowedFacilityIdsForUserId]
	(
		@UserProfileId INT
		,@DateOfService datetime
	)
RETURNS TABLE
AS
RETURN
(
	SELECT 
		[FUA].[FACILITY_ID]
	FROM  
		[USER_PROFILE] AS [UP] WITH (NOLOCK)
		JOIN [FACILITY_USER_AUTHORIZATION] AS [FUA] WITH (NOLOCK) ON [UP].[USER_PROFILE_ID] = [FUA].[USER_PROFILE_ID]
	WHERE  
		[UP].[USER_PROFILE_ID] = @UserProfileId 
 		AND [FUA].[EFFECTIVE_DATE] <= @DateOfService
		AND ([FUA].[EXPIRATION_DATE] >= @DateOfService OR [FUA].EXPIRATION_DATE IS NULL)
)
 
-- End of 01) DACS-2795 - CREATE or Alter FUNCTION - udfGetAllowedFacilityIdsForUserId.SQL
GO

-- Start of 02) DACS-2795 - Create or Alter Stored Procedure - CHART_SELECT_TOP_20_MOST_RECENT_BY_USER_PROFILE_ID.SQL

----------------------------------------
-- 02) DACS-2795 - Create or Alter Stored Procedure - CHART_SELECT_TOP_20_MOST_RECENT_BY_USER_PROFILE_ID.SQL
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[CHART_SELECT_TOP_20_MOST_RECENT_BY_USER_PROFILE_ID]
	@USER_PROFILE_ID INT = NULL
AS

-- adaptation of original stored procedure [dbo].[CHART_SELECT_TOP_50_MOST_RECENT_BY_USER_PROFILE_ID]

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('TEMPDB..#FACILITYLIST', 'U') IS NOT NULL DROP TABLE #FACILITYLIST 
IF OBJECT_ID('TEMPDB..#RESULTS', 'U') IS NOT NULL DROP TABLE #RESULTS 

DECLARE @DateOfService datetime = GETDATE();
DECLARE @DateThru datetime = CAST(CAST(@DateOfService AS date) AS datetime)
      , @DateFrom datetime = DATEADD(SECOND, -1, DATEADD(DAY, -60, CAST(CAST(@DateOfService AS date) AS datetime)));

-- GET TOP 20 CHARTS BASED ON USER'S AUTHORIZED FACILITIES AND LAST ACCESS DATE
-- SET FACILITY_CHART_ID AND PATIENT_LAST_NAME = NULL. THEY'RE PULLED IN THE NEXT SUB-QUERY
SELECT TOP 20 
	[C].[CHART_ID]
   ,[F].[NAME]
   ,[CA].[ACCESS_DATE_TIME]
   ,[FACILITY_CHART_ID] = CAST(NULL AS VARCHAR(50))
   ,[PATIENT_LAST_NAME] = CAST(NULL AS VARCHAR(100)) 
INTO
	[#RESULTS]
FROM 
	[CHART] AS [C] WITH (NOLOCK)
	JOIN [CHART_ACCESS] AS [CA] WITH (NOLOCK) ON [C].[CHART_ID] = [CA].[CHART_ID]
	JOIN [FACILITY] AS [F] WITH (NOLOCK) ON [C].[FACILITY_ID] = [F].[FACILITY_ID]
WHERE 
	[CA].[USER_PROFILE_ID] = @USER_PROFILE_ID
	AND [CA].[ACCESS_DATE_TIME] BETWEEN @DateFrom AND @DateThru
	AND EXISTS (
        SELECT
            [FACILITY_ID]
        FROM
            [dbo].[udfGetAllowedFacilityIdsForUserId](@USER_PROFILE_ID, @DateThru) [U]
        WHERE
            [U].[FACILITY_ID] = [F].[FACILITY_ID]
    )
ORDER BY
	[CA].[ACCESS_DATE_TIME] DESC  

-- GET FACILITY_CHART_ID AND PATIENT_LAST_NAME FOR ALL ROWS IN #RESULT
UPDATE 
	[T]
SET 
	[T].[FACILITY_CHART_ID] = [C].[FACILITY_CHART_ID]
   ,[T].[PATIENT_LAST_NAME] = [C].[PATIENT_LAST_NAME]
FROM 
	[#RESULTS] AS [T] WITH (NOLOCK)
	JOIN [CHART] AS [C] WITH (NOLOCK) ON [T].[CHART_ID] = [C].[CHART_ID]
 
-- FINALLY, RETURN THE COMPLETE RESULT SET FROM #RESULTS
SELECT 
	[CHART_ID]
   ,[FACILITY_CHART_ID]
   ,[PATIENT_LAST_NAME]
   ,[NAME]
   ,[ACCESS_DATE_TIME]
FROM 
	[#RESULTS] WITH (NOLOCK)
ORDER BY 
	[ACCESS_DATE_TIME] DESC 

GO

/*
testing
set statistics io on;  -- will show stats for a query window
exec [dbo].[CHART_SELECT_TOP_50_MOST_RECENT_BY_USER_PROFILE_ID] @USER_PROFILE_ID = 6172
set statistics io on;  -- will show stats for a query window
exec [dbo].[CHART_SELECT_TOP_20_MOST_RECENT_BY_USER_PROFILE_ID] @USER_PROFILE_ID = 6172
*/

-- End of 02) DACS-2795 - Create or Alter Stored Procedure - CHART_SELECT_TOP_20_MOST_RECENT_BY_USER_PROFILE_ID.SQL
GO

-- Start of 01) DACS-3037 - Alter Procedure - [dbo].[PhysicianServiceProcedureQualifyUpdateByServiceAgreementIds].SQL

----------------------------------------------------------------------------------------
-- 01) DACS-3037 - Alter Procedure - [dbo].[PhysicianServiceProcedureQualifyUpdateByServiceAgreementIds].SQL
----------------------------------------------------------------------------------------
GO

GO

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


-- End of 01) DACS-3037 - Alter Procedure - [dbo].[PhysicianServiceProcedureQualifyUpdateByServiceAgreementIds].SQL
GO

-- Start of 01) DACS-3039 - create or alter stored procedure - SelectQABeginCodingStateIsSetByChartIdAsBoolean.SQL

--------------------------------------------------------------------------------------------------
-- 01) DACS-3039 - create or alter stored procedure - SelectQABeginCodingStateIsSetByChartIdAsBoolean.SQL
--------------------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER   PROCEDURE [dbo].[SelectQABeginCodingStateIsSetByChartIdAsBoolean]
	@ChartId INT
AS
BEGIN
 
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;
	
	DECLARE @dos datetime = GETDATE();
	DECLARE @dosMin datetime = DATEADD(day, -60, @dos);
	
	SELECT 
		CAST(IIF((
				SELECT COUNT(*) 
				FROM [CHART_ACCESS] 
				WHERE [CHART_ID] = @ChartId
					AND [CHART_ACCESS_EVENT_TYPE_CODE] = 'Q' 
					AND [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] IS NULL
					AND [EVENT_COMPLETION_DATE_TIME] IS NULL
					AND [ACCESS_DATE_TIME] BETWEEN @dosMin AND @dos
				) > 0, 1, 0) AS BIT);
	
END; -- end of stored procedure

GO


-- End of 01) DACS-3039 - create or alter stored procedure - SelectQABeginCodingStateIsSetByChartIdAsBoolean.SQL
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
