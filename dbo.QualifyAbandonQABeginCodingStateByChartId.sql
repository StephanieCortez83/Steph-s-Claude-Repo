SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[QualifyAbandonQABeginCodingStateByChartId]
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
