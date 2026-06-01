----------------------------------------
-- 02) DACS-4898 - create or alter SPROC - [dbo].[SelectLogNoteForPast2WeeksByDetail].SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectLogNoteForPast2WeeksByDetail]
	@Detail VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @endDay DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
	DECLARE @startDay DATETIME = DATEADD(DAY, (5 - DATEPART(WEEKDAY, @endDay) + @@DATEFIRST + 7) % 7 - 21, CAST(@endDay AS DATE));
		
	DECLARE @limitDate DATETIME;
	SET @limitDate = DATEADD(DAY, -5, @startDay);

	DECLARE @limitLogId INT = (select top 1 LOG_NOTE_ID from LOG_NOTE where CREATION_DATE_TIME < @limitDate order by log_note_id desc);
	DECLARE @limitChartId INT = (select top 1 chart_id from chart where CREATION_DATE_TIME < @limitDate order by chart_id desc);
	DECLARE @SearchStr VARCHAR(110) = ('%' + @Detail + '%');

	-- testing
	-- select '@startDay' = @startDay, '@endDay' = @endDay, '@limitDate' = @limitDate,
	--	   '@limitLogId' = @limitLogId, '@limitChartId' = @limitChartId, '@SearchStr' = @SearchStr;


	SELECT TOP 2000
		 c.[FACILITY_CHART_ID]
		,ln.[DETAIL]
	FROM
		[CHART] c
		INNER JOIN [LOG_NOTE] ln 
				ON c.[CHART_ID] = ln.[CHART_ID]
	WHERE 
		LN.[DETAIL] LIKE @SearchStr
		AND c.[TIME_OF_SERVICE] BETWEEN @startDay AND @endDay
		AND ln.[LOG_NOTE_ID] >= @limitLogId
		and c.[CHART_ID] >= @limitChartId;
END
GO

DECLARE @exp VARCHAR(50) = (SELECT CAST(modify_date AS VARCHAR(50)) FROM sys.objects WHERE type = 'P' AND name = 'SelectLogNoteForPast2WeeksByDetail');

IF OBJECT_ID('dbo.SelectLogNoteForPast2WeeksByDetail', 'P') IS NOT NULL
	PRINT ('SPROC SelectLogNoteForPast2WeeksByDetail last changed ' + @exp);
ELSE
	PRINT ('failed to create SPROC SelectLogNoteForPast2WeeksByDetail');
GO
