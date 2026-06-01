SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[LogNotesCheckForAdditionalPBAFlagByChartId]
	  @ChartId int
	
AS
	DECLARE @LastLogNoteSummary VARCHAR(256) = (SELECT TOP 1 [SUMMARY] FROM LOG_NOTE WITH (NOLOCK) WHERE [CHART_ID] = @ChartId ORDER BY [LOG_NOTE_ID] DESC);
	
	IF @LastLogNoteSummary = 'Flagged for additional post-bill audit'
		SELECT 'Result' = 1
	ELSE
		SELECT 'Result' = 0

GO
