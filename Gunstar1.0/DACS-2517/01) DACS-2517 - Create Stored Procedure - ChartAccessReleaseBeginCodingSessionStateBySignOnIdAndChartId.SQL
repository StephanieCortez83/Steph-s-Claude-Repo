-------------------------------------------------------------
-- 01) DACS-2517 - Create Stored Procedure - ChartAccessReleaseBeginCodingSessionStateBySignOnIdAndChartId.SQL
-------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   PROCEDURE [dbo].[ChartAccessReleaseBeginCodingSessionStateBySignOnIdAndChartId]
	 @SignOnId varchar(15)
	,@ChartId INT
AS
BEGIN
	-- testing on QA-ACS
	-- DECLARE	@SignOnId varchar(15) = 'LRENEGAR01'; -- = 6172
	-- DECLARE @ChartId INT = 95686103;
		
	SET @SignOnId = RTRIM(@SignOnId)

	IF LEN(@SignOnId) <= 0 OR LEN(@SignOnId) > 15
	BEGIN
		Select [Result] = -1, [Error] = 'Sign On Id is invalid.'
		RETURN;
	END;

	IF @ChartId <= 0
	BEGIN
		Select [Result] = -2, [Error] = 'Chart Id is invalid.'
		RETURN;
	END;

	DECLARE @userProfileId INT = (SELECT TOP 1 [USER_PROFILE_ID] FROM [dbo].[USER_PROFILE] WITH (NOLOCK) WHERE [SIGN_ON_ID] = @SignOnId);

	IF @userProfileId <= 0
	BEGIN
		Select [Result] = -3, [Error] = 'Unable to find User Profile Id From Sign On Id.'
		RETURN;
	END;

	DECLARE @foundCount INT = (SELECT 
							COUNT([CHART_ACCESS_ID]) 
							FROM 
								[dbo].[CHART_ACCESS] WITH (NOLOCK)
							WHERE
								[USER_PROFILE_ID] = @userProfileId
								AND [CHART_ID] = @chartId
								AND [CHART_ACCESS_EVENT_TYPE_CODE] = 'B' 
								AND [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] IS NULL
								AND DATEDIFF(day,[ACCESS_DATE_TIME],GETDATE()) BETWEEN 0 AND 45);

	-- SELECT SignOnId = @SignOnId, ChartId = @ChartId, userProfileId = @userProfileId, foundCount = @foundCount;

	IF @foundCount <= 0
	BEGIN
		Select [Result] = 0, [Error] = 'No records to process'
		RETURN;
	END;

	-- Perform the desired action
	UPDATE
		[dbo].[CHART_ACCESS]
	SET
		[CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] = 'I'
	WHERE
		[USER_PROFILE_ID] = @userProfileId
		AND [CHART_ID] = @chartId
		AND [CHART_ACCESS_EVENT_TYPE_CODE] = 'B'                			-- INDICATES A 'BEGIN CODING' EVENT
		AND [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE] IS NULL    			-- ONLY UPDATE ROWS WITH EMPTY SECONDARY EVENTS
		AND DATEDIFF(day,[ACCESS_DATE_TIME],GETDATE()) BETWEEN 0 AND 45; 	-- USED TO LIMIT POSSIBLE AFFECTED RANGE OF RECORDS
		
	SELECT [Result] = @foundCount, [Error] = '';

END

GO
