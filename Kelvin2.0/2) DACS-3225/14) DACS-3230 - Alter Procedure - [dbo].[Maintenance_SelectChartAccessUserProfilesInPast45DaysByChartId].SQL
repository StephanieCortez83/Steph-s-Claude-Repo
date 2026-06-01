----------------------------------------------------------------------------------------
-- 04) DACS-3230 - Alter Procedure - [dbo].[Maintenance_SelectChartAccessUserProfilesInPast45DaysByChartId].SQL
----------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [dbo].[Maintenance_SelectChartAccessUserProfilesInPast45DaysByChartId]  
	@chartId Int
AS  
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DROP TABLE IF EXISTS #TmpResultsMSCAUPIP45DC;

	SELECT DISTINCT TOP 10 
		[USER_PROFILE_ID]
		, [SIGN_ON_ID] = cast(null as varchar(100))
	INTO 
		#TmpResultsMSCAUPIP45DC
	FROM 
		[dbo].[CHART_ACCESS]
	WHERE
		[CHART_ID] = @chartId
		AND DATEDIFF(day,[ACCESS_DATE_TIME],GETDATE()) BETWEEN 0 AND 45;

	IF (SELECT COUNT(*) FROM #TmpResultsMSCAUPIP45DC) <= 0
	BEGIN
		PRINT ('no data');
		RETURN
	END;

	UPDATE #TmpResultsMSCAUPIP45DC
		SET SIGN_ON_ID = u.SIGN_ON_ID
	FROM
		[USER_PROFILE] as u
		JOIN #TmpResultsMSCAUPIP45DC as t ON t.[USER_PROFILE_ID] = u.[USER_PROFILE_ID];
		
	SELECT
		*
	FROM
		#TmpResultsMSCAUPIP45DC;

GO

/*
Testing:
-- exec [dbo].[Maintenance_SelectChartAccessUserProfilesInPast45DaysByChartId] @chartId=2100111810
select DISTINCT top 10 USER_PROFILE_ID from chart_Access where chart_id = 2100111810
*/



