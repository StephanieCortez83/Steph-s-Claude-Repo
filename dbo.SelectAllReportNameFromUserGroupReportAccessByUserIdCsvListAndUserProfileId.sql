SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvListAndUserProfileId]
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
