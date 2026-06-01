SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[CalcBusinessDateDifference]
(	@holiday_schedule_id int, 
	@startDateTime datetime, 
	@endDateTime datetime
)

RETURNS int
AS 

BEGIN
	declare @diff int
	declare @testDate datetime
	set @diff = 0	
	set @testDate = @startDateTime
	set @diff = DATEDIFF(mi, @startDateTime, @endDateTime)
	
	if DATEPART(DW, @startDateTime) in (1,7) 
		or  DATEPART(DY, @startDateTime) in 
										(SELECT  DATEPART(DY, HOLIDAY_DATE) FROM HOLIDAY_SCHEDULE		
										WHERE HOLIDAY_SCHEDULE_ID = @holiday_schedule_id
										AND   DATEPART(YEAR, HOLIDAY_DATE) = DATEPART(YEAR, @startDateTime))									
	BEGIN
		SET @diff = @diff - (1440 - (DATEPART(hh, @startDateTime) * 60) + DATEPART(mi, @startDateTime))	
	END
	
	WHILE (Convert(int, DATEADD(dd, 1, @testDate), 112)) < (CONVERT(int, @endDateTime, 112))
	BEGIN 
		set @testDate = DATEADD(dd, 1, @testDate) 
		IF (DATEPART(dw, @testDate) IN (1,7) 
			OR  DATEPART(DY, @testDate) IN 
										(SELECT  DATEPART(DY, HOLIDAY_DATE) FROM HOLIDAY_SCHEDULE		
										WHERE HOLIDAY_SCHEDULE_ID = @holiday_schedule_id
										AND   DATEPART(YEAR, HOLIDAY_DATE) = DATEPART(YEAR, @testDate)))
			SET @diff = @diff - 1440
	END
		
	if DATEPART(dw, @endDateTime) in (1,7)
				OR  DATEPART(DY, @endDateTime) IN 										
										(SELECT  DATEPART(DY, HOLIDAY_DATE) FROM HOLIDAY_SCHEDULE		
										WHERE HOLIDAY_SCHEDULE_ID = @holiday_schedule_id
										AND   DATEPART(YEAR, HOLIDAY_DATE) = DATEPART(YEAR, @startDateTime))
	BEGIN
		set @diff = @diff - (DATEPART(hh, @endDateTime) * 60 + DATEPART(mi, @endDateTime))
	END
	
	IF @diff < 0 SET @diff = 0 
	return @diff
END
GO
