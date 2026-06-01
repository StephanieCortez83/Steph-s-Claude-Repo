--------------------------------------------------------------------------------------------------
-- 01) DACS-3039 - create or alter stored procedure - SelectQABeginCodingStateIsSetByChartIdAsBoolean.SQL
--------------------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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


