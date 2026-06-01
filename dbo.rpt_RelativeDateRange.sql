SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
-- Created By: Jay Herrera
-- Created Date: 4/26/2022
-- Description: 
-- Stored Procedure to auto populate Start/End date range with selected relative date range
*/


create procedure [dbo].[rpt_RelativeDateRange]
    @RelativeDate int
    ,@SDate       datetime = null
    ,@EDate       datetime = null
    ,@StartDate   datetime output
    ,@EndDate     datetime output
as
begin
    set nocount on;

	--declare
	--	@RelativeDate int      = 8
	--	,@SDate       datetime = ''
	--	,@EDate       datetime = ''
	--	,@StartDate   datetime = ''
	--	,@EndDate     datetime = '';

    declare @UTC datetime;
    set @UTC = getdate();

    if @RelativeDate = 0
    begin
        set @StartDate = isnull(@SDate, getdate());
        set @EndDate = dateadd(day, 1, isnull(@EDate, getdate()));
    end;
    if @RelativeDate = 1 --Today
    begin
        set @StartDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -1, @UTC), 0);
    end;
    if @RelativeDate = 2 --Yesterday
    begin
        set @StartDate = dateadd(dd, datediff(dd, 1, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
    end;
    --if @RelativeDate = 3 --Tomorrow
    --begin
    --    set @StartDate = dateadd(dd, datediff(dd, -1, @UTC), 0);
    --    set @EndDate = dateadd(dd, datediff(dd, -2, @UTC), 0);
    --end;
    if @RelativeDate = 4 --Week to Date (Sunday to Today)
    begin
        set @StartDate = dateadd(wk, datediff(wk, 0, @UTC), -1);
        set @EndDate = dateadd(dd, datediff(dd, -1, @UTC), 0);
    end;
    if @RelativeDate = 5 --This Week (Sunday to Saturday)
    begin
        set @StartDate = dateadd(wk, datediff(wk, 0, @UTC), -1);
        set @EndDate = dateadd(wk, datediff(wk, 0, @UTC) + 1, -1);
    end;
    if @RelativeDate = 6 --Last Week (Sunday to Saturday)
    begin
        set @StartDate = dateadd(wk, datediff(wk, 0, @UTC) - 1, -1);
        set @EndDate = dateadd(wk, datediff(wk, 0, @UTC), -2);
    end;
    --if @RelativeDate = 7 --Next Week
    --begin
    --    set @StartDate = dateadd(wk, datediff(wk, 0, @UTC) + 1, -1);
    --    set @EndDate = dateadd(wk, datediff(wk, 0, @UTC) + 2, -2);
    --end;
    if @RelativeDate = 8 --Month to Date
    begin
        set @StartDate = dateadd(mm, datediff(mm, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -1, @UTC), 0);
    end;
    if @RelativeDate = 9 --This Month
    begin
        set @StartDate = dateadd(mm, datediff(mm, 0, @UTC), 0);
        set @EndDate = dateadd(mm, datediff(mm, 0, @UTC) + 1, 0);
    end;
    if @RelativeDate = 10 --Last Month
    begin
        set @StartDate = dateadd(dd, 1, dateadd(mm, datediff(mm, 0, @UTC) - 1, -1));
        set @EndDate = dateadd(mm, datediff(mm, 0, @UTC), 0);
    end;
    --if @RelativeDate = 11 --Next Month
    --begin
    --    set @StartDate = dateadd(dd, 1, dateadd(mm, datediff(mm, 0, @UTC) + 1, -1));
    --    set @EndDate = dateadd(mm, datediff(mm, 0, @UTC) + 2, 0);
    --end;
    /*
	if @RelativeDate = 12 --Quarter to Date
    begin
        set @StartDate = dateadd(qq, datediff(qq, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -1, @UTC), 0);
    end;
    if @RelativeDate = 13 --This Quarter
    begin
        set @StartDate = dateadd(qq, datediff(qq, 0, @UTC), 0);
        set @EndDate = dateadd(qq, datediff(qq, 0, @UTC) + 1, 0);
    end;
    if @RelativeDate = 14 --Last Quarter
    begin
        set @StartDate = dateadd(dd, 1, dateadd(qq, datediff(qq, 0, @UTC) - 1, -1));
        set @EndDate = dateadd(qq, datediff(qq, 0, @UTC), 0);
    end;
    if @RelativeDate = 15 --Next Quarter
    begin
        set @StartDate = dateadd(dd, 1, dateadd(qq, datediff(qq, 0, @UTC) + 1, -1));
        set @EndDate = dateadd(qq, datediff(qq, 0, @UTC) + 2, 0);
    end;
    if @RelativeDate = 16 --Year to Date
    begin
        set @StartDate = dateadd(yy, datediff(yy, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -1, @UTC), 0);
    end;
    if @RelativeDate = 17 --This Year
    begin
        set @StartDate = dateadd(yy, datediff(yy, 0, @UTC), 0);
        set @EndDate = dateadd(yy, datediff(yy, 0, @UTC) + 1, 0);
    end;
    if @RelativeDate = 18 --Last Year
    begin
        set @StartDate = dateadd(yy, datediff(yy, 0, (dateadd(yy, datediff(yy, 0, @UTC), -1))), 0);
        set @EndDate = dateadd(yy, datediff(yy, 0, @UTC), 0);
    end;
    if @RelativeDate = 19 --Next Year
    begin
        set @StartDate = dateadd(yy, datediff(yy, 0, @UTC) + 1, 0);
        set @EndDate = dateadd(yy, datediff(yy, 0, @UTC) + 2, 0);
    end;
    if @RelativeDate = 20 --Previous 90 Days
    begin
        set @StartDate = dateadd(d, datediff(d, 0, @UTC) - 90, 0);
        set @EndDate = dateadd(d, datediff(d, 0, @UTC), 0);
    end;
    if @RelativeDate = 21 --Previous 180 Days
    begin
        set @StartDate = dateadd(d, datediff(d, 0, @UTC) - 180, 0);
        set @EndDate = dateadd(d, datediff(d, 0, @UTC), 0);
    end;
    if @RelativeDate = 22 --Next 14 days
    begin
        set @StartDate = dateadd(d, datediff(d, 0, @UTC), 0);
        set @EndDate = dateadd(d, datediff(d, 0, @UTC) + 14, 0);
    end;
    if @RelativeDate = 23 --Previous 3 Months
    begin
        set @StartDate = dateadd(dd, 1, dateadd(mm, datediff(mm, 0, @UTC) - 2, -1));
        set @EndDate = dateadd(mm, datediff(mm, 0, @UTC) + 1, 0);
    end;
    if @RelativeDate = 24 --Previous 6 Months
    begin
        set @StartDate = dateadd(dd, 1, dateadd(mm, datediff(mm, 0, @UTC) - 5, -1));
        set @EndDate = dateadd(mm, datediff(mm, 0, @UTC) + 1, 0);
    end;
    if @RelativeDate = 25 --All Time
    begin
        set @StartDate = '1/1/1900';
        set @EndDate = dateadd(dd, datediff(dd, -1, @UTC), 0);
    end;
    if @RelativeDate = 26 --Next 7 Days
    begin
        set @StartDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -7, @UTC), 0);
    end;
    if @RelativeDate = 27 --Next 30 Days
    begin
        set @StartDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -30, @UTC), 0);
    end;
    if @RelativeDate = 28 --Next 60 Days
    begin
        set @StartDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -60, @UTC), 0);
    end;
    if @RelativeDate = 29 --Next 90 Days
    begin
        set @StartDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -90, @UTC), 0);
    end;
    if @RelativeDate = 30 --Next 120 Days
    begin
        set @StartDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -120, @UTC), 0);
    end;
    if @RelativeDate = 31 --Previous 30 Days
    begin
        set @StartDate = dateadd(dd, datediff(dd, 31, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
    end;
    if @RelativeDate = 32 --Previous 365 Days
    begin
        set @StartDate = dateadd(dd, datediff(dd, 366, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
    end;
    if @RelativeDate = 33 --Next 365 Days
    begin
        set @StartDate = dateadd(dd, datediff(dd, 0, @UTC), 0);
        set @EndDate = dateadd(dd, datediff(dd, -365, @UTC), 0);
    end;
    if @RelativeDate = 34 --This Week (Monday to Sunday)
    begin
        set @StartDate = dateadd(wk, datediff(wk, 0, @UTC), 0);
        set @EndDate = dateadd(wk, datediff(wk, 0, @UTC) + 1, 0);
    end;
    if @RelativeDate = 35 --Previous 12 Months
    begin
        set @StartDate = dateadd(dd, 1, dateadd(mm, datediff(mm, 0, @UTC) - 11, -1));
        set @EndDate = dateadd(mm, datediff(mm, 0, @UTC) + 1, 0);
    end;
    if @RelativeDate = 36 --This Month and Next Month
    begin
        set @StartDate = dateadd(mm, datediff(mm, 0, @UTC), 0);
        set @EndDate = dateadd(mm, datediff(mm, 0, @UTC) + 2, 0);
    end;
    if @RelativeDate = 37 --Last Week (Monday to Sunday)
    begin
        set @StartDate = dateadd(wk, datediff(wk, 0, @UTC) - 1, 0);
        set @EndDate = dateadd(wk, datediff(wk, 0, @UTC), 0);
    end;
    if @RelativeDate = 38 --Fiscal Year To Date
    begin
        set @StartDate = cast('10/1/' + case
                                            when month(@UTC) < 10 then convert(varchar(4), year(@UTC) - 1)
                                        else convert(varchar(4), year(@UTC))end as datetime);
        set @EndDate = dateadd(dd, datediff(dd, -1, @UTC), 0);
    end;
    if @RelativeDate = 39 --Current Fiscal Year
    begin
        set @StartDate = cast('10/1/' + case
                                            when month(@UTC) < 10 then convert(varchar(4), year(@UTC) - 1)
                                        else convert(varchar(4), year(@UTC))end as datetime);
        set @EndDate = cast('10/1/' + case
                                          when month(@UTC) < 10 then convert(varchar(4), year(@UTC))
                                      else convert(varchar(4), year(@UTC) + 1)end as datetime);
    end;


    if @RelativeDate = 40 --Previous 7 Days
    begin
        set @StartDate = dateadd(d, datediff(d, 0, @UTC) - 7, 0);
        set @EndDate = dateadd(d, datediff(d, 0, @UTC), 0);
    end;

    if @RelativeDate = 41 --Next Fiscal Year
    begin
        set @StartDate = cast('10/1/' + case
                                            when month(@UTC) < 10 then convert(varchar(4), year(@UTC))
                                        else convert(varchar(4), year(@UTC) + 1)end as datetime);
        set @EndDate = cast('10/1/' + case
                                          when month(@UTC) < 10 then convert(varchar(4), year(@UTC) + 1)
                                      else convert(varchar(4), year(@UTC) + 2)end as datetime);
    end;

    if @RelativeDate = 42 --Last Fiscal Year
    begin
        set @StartDate = cast('10/1/' + case
                                            when month(@UTC) < 10 then convert(varchar(4), year(@UTC) - 2)
                                        else convert(varchar(4), year(@UTC) - 1)end as datetime);
        set @EndDate = cast('10/1/' + case
                                          when month(@UTC) < 10 then convert(varchar(4), year(@UTC) - 1)
                                      else convert(varchar(4), year(@UTC))end as datetime);
    end;

    if @RelativeDate = 44 --3rd Month Out
    begin
        set @StartDate
            = cast(case
                       when month(@UTC) + 2 < 13 then convert(varchar(2), month(@UTC) + 2)
                   else convert(varchar(2), (month(@UTC) + 2) - 12)end + '/1/'
                   + case
                         when month(@UTC) + 2 < 13 then convert(varchar(4), year(@UTC))
                     else convert(varchar(4), year(@UTC) + 1)end as datetime);
        set @EndDate
            = cast(case
                       when month(@UTC) + 3 < 13 then convert(varchar(2), month(@UTC) + 3)
                   else convert(varchar(2), (month(@UTC) + 3) - 12)end + '/1/'
                   + case
                         when month(@UTC) + 3 < 13 then convert(varchar(4), year(@UTC))
                     else convert(varchar(4), year(@UTC) + 1)end as datetime);
    end;

    if @RelativeDate = 45 --This Month and Next 2 Months
    begin
        set @StartDate = dateadd(mm, datediff(mm, 0, @UTC), 0);
        set @EndDate = dateadd(mm, datediff(mm, 0, @UTC) + 3, 0);
    end;

    if @RelativeDate = 46 --Prior 3 Months (not including current)
    begin
        set @StartDate = dateadd(dd, 1, dateadd(mm, datediff(mm, 0, @UTC) - 3, -1));
        set @EndDate = dateadd(mm, datediff(mm, 0, @UTC), 0);
    end;
	*/

select @StartDate 'StartDate', @EndDate 'EndDate'

end;
GO
