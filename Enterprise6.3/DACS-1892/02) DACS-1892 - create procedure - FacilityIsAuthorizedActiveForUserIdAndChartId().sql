---------------------------------------------------------
-- 02) DACS-1892 - create procedure - FacilityIsAuthorizedActiveForUserIdAndChartId().sql
---------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[FacilityIsAuthorizedActiveForUserIdAndChartId]
	 @UserId int
	,@ChartId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF EXISTS(
	SELECT TOP 1 [FACILITY_AUTH_ID]
		FROM  
			[dbo].[FACILITY_USER_AUTHORIZATION] f WITH(NOLOCK)
			LEFT JOIN [CHART] c WITH(NOLOCK) ON f.[FACILITY_ID] = c.[FACILITY_ID]
		WHERE
			[USER_PROFILE_ID] = @UserId
			AND [CHART_ID] = @ChartId
	)
	SELECT 1
ELSE
	SELECT 0
