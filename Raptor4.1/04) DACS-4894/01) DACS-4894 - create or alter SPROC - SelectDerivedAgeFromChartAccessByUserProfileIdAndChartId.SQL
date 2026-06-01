----------------------------------------
-- 01) DACS-4894 - create or alter SPROC - SelectDerivedAgeFromChartAccessByUserProfileIdAndChartId.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectDerivedAgeFromChartAccessByUserProfileIdAndChartId]
	 @ChartId INT
	,@UserProfileId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	SELECT TOP 1 
		DATEDIFF(hour, [ACCESS_DATE_TIME], GETDATE())
	FROM
		[dbo].[CHART_ACCESS]
	WHERE
		[USER_PROFILE_ID] = @UserProfileId
		AND [CHART_ID] = @ChartId 
		AND [CHART_ACCESS_EVENT_TYPE_CODE] = 'Q'
		AND [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] IS NULL;
END;
GO

IF OBJECT_ID('dbo.SelectDerivedAgeFromChartAccessByUserProfileIdAndChartId', 'P') IS NOT NULL
	PRINT ('SPROC SelectDerivedAgeFromChartAccessByUserProfileIdAndChartId created');
ELSE
	PRINT ('failed to create SPROC SelectDerivedAgeFromChartAccessByUserProfileIdAndChartId');
GO