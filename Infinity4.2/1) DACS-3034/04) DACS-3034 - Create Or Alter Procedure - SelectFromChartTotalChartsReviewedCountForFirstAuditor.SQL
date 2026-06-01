-----------------------------------------------------------------------------------
-- 04) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsReviewedCountForFirstAuditor.SQL
-----------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFromChartTotalChartsReviewedCountForFirstAuditor]
      @UserProfileId INT
	, @FromDate DATE
	, @ToDate DATE
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @UserProfileId IS NULL OR @UserProfileId <= 0
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @FromDate IS NULL
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @ToDate IS NULL
	BEGIN
		SET @ToDate = GETDATE();
		RETURN;
	END;

	-- these could be handled differently but are as is due to reverse compatibility with the original inline C# programming.
	DECLARE @testFromDate DATETIME = (CAST(@FromDate AS DATETIME));
	DECLARE @testToDate DATETIME = (CAST(@ToDate AS DATETIME));

	SELECT COUNT(*) 
		FROM CHART WITH (NOLOCK) 
		WHERE CHART_STATUS_ID in (4,5) 
		AND APPROVED_BY_USER_PROFILE_ID = @UserProfileId
		AND (SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 2 AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> @UserProfileId)
		AND START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0
		AND SECOND_LEVEL_QA_APPROVED_DATETIME BETWEEN @testFromDate AND @testToDate;

END -- end of procedure
GO
