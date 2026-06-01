----------------------------------------------------------------
-- 02) DACS-2647 - Alter Procedure - dbo.LogNotesCheckForAdditionalPBAFlagByChartId.SQL
----------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[LogNotesCheckForAdditionalPBAFlagByChartId]
	  @ChartId int
	
AS
	DECLARE @LastLogNoteSummary VARCHAR(256) = (SELECT TOP 1 [SUMMARY] FROM LOG_NOTE WITH (NOLOCK) WHERE [CHART_ID] = @ChartId ORDER BY [LOG_NOTE_ID] DESC);
	
	IF @LastLogNoteSummary = 'Flagged for additional post-bill audit'
		SELECT 'Result' = 1
	ELSE
		SELECT 'Result' = 0

GO

/*
test:
exec [dbo].[LogNotesCheckForAdditionalPBAFlagByChartId] @ChartId= 2100101604
*/
