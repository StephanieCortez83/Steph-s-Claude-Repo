SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- adjust the create or alter commands as required for target database should an error occur.  
--CREATE OR 
CREATE PROCEDURE [dbo].[CHART_STATS_BY_CHART_ASSIGNED_TO_ID]
	 @CHART_ASSIGNED_TO_ID int
	,@StartDate date = NULL
AS

-- testing
-- DECLARE @CHART_ASSIGNED_TO_ID int = 7157;
-- DECLARE @StartDate date = CAST(GETDATE() AS date);

IF @StartDate IS NULL
    Set @StartDate = CAST(GETDATE() AS date);

--  Base script provided by SQL Team
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @TemplateServiceAgreementTable Table (
	 [Status]				[varchar](64)
 	,[CountTotal]			[int] default 0
	,[CountPastWeek]		[int] default 0
	,[CountSinceYesterday]	[int] default 0 -- not needed presently, but kept so as not to modify ACS UI usage
	,[CountToday]			[int] default 0
);

Insert  
	@TemplateServiceAgreementTable ([Status], [CountTotal])
SELECT 
	 [DESCRIPTION] as [Status]
	,(SELECT COUNT(ASSIGNED_TO_ID) 
		FROM 
			[dbo].[CHART] WITH (NOLOCK)
		WHERE 
			[CHART].[CHART_STATUS_ID] = [CHART_STATUS].[CHART_STATUS_ID] 
			and [CHART].[ASSIGNED_TO_ID] = @CHART_ASSIGNED_TO_ID
	 ) AS [CountTotal]
FROM 
	[dbo].[CHART_STATUS] WITH (NOLOCK)
ORDER BY 
	[DESCRIPTION];

-- if sum <= 0 no since in continuing
IF (select sum([CountTotal]) from @TemplateServiceAgreementTable) <= 0
BEGIN
	-- PRINT( 'sum Temp Counts <= 0');
	SELECT [Status], [CountTotal], [CountPastWeek], [CountSinceYesterday], [CountToday] FROM @TemplateServiceAgreementTable;
	RETURN;
END;

-- disallow automation users from continuing
IF @CHART_ASSIGNED_TO_ID in (80,2)
BEGIN
	-- PRINT( 'High use account, leaving');
	SELECT [Status], [CountTotal], [CountPastWeek], [CountSinceYesterday], [CountToday] FROM @TemplateServiceAgreementTable;
	RETURN;
END;


-- Log_note info
-- Cat_Id	summary
-- 2		Chart completed.
-- 3		Chart approved.
-- 4		Chart sent.
-- 6		Chart pended.
-- 7		Chart removed.
-- 19		Chart bypassed.
-- 31		Chart approved by 2nd level auditor.
-- 34		Coding began.

DECLARE  @ChangedDateTimeOneWeek SMALLDATETIME = cast(DATEADD(day, -1*(DATEPART(WEEKDAY, @StartDate)-2), @StartDate) as DATE) --DATEADD(wk,DATEDIFF(wk,7,@StartDate),0)
		-- ,@ChangedDateTimeYesterday SMALLDATETIME = DATEADD(day, -1, CAST(@StartDate AS date))
		,@ChangedDateTimeToday SMALLDATETIME = CAST(@StartDate AS date)
		;

declare @RowCnt int

if object_id('TempDB..#Results_OneWeek', 'U') is not null DROP TABLE #Results_OneWeek;
-- if object_id('TempDB..#Results_Yesterday', 'U') is not null DROP TABLE #Results_Yesterday;
if object_id('TempDB..#Results_Today', 'U') is not null DROP TABLE #Results_Today;


select category_ID, CategoryDesc = cast(null as varchar(64)), RowCnt = count(*) into #Results_OneWeek from Log_Note where CREATING_USER_PROFILE_ID = @CHART_ASSIGNED_TO_ID and CHANGED_DATE_TIME >= @ChangedDateTimeOneWeek group by Category_ID
--select category_ID, CategoryDesc = cast(null as varchar(64)), RowCnt = count(*) into #Results_Yesterday from Log_Note where CREATING_USER_PROFILE_ID = @CHART_ASSIGNED_TO_ID and CHANGED_DATE_TIME >= @ChangedDateTimeYesterday group by Category_ID
select category_ID, CategoryDesc = cast(null as varchar(64)), RowCnt = count(*) into #Results_Today from Log_Note where CREATING_USER_PROFILE_ID = @CHART_ASSIGNED_TO_ID and CHANGED_DATE_TIME >= @ChangedDateTimeToday group by Category_ID

update #Results_OneWeek
set CategoryDesc = case 
	when category_ID = 2 then 'Complete'
	when category_ID = 3 then 'Approved'
	when category_ID = 4 then 'Sent'
	when category_ID = 6 then 'Pending'
	when category_ID = 7 then 'Removed'
	when category_ID = 19 then 'Bypassed'
	when category_ID = 31 then '2nd Audit'
	end


update #Results_Today
set CategoryDesc = case 
	when category_ID = 2 then 'Complete'
	when category_ID = 3 then 'Approved'
	when category_ID = 4 then 'Sent'
	when category_ID = 6 then 'Pending'
	when category_ID = 7 then 'Removed'
	when category_ID = 19 then 'Bypassed'
	when category_ID = 31 then '2nd Audit'
	end



UPDATE t1 set t1.CountPastWeek = t2.RowCnt from @TemplateServiceAgreementTable as t1 join #Results_OneWeek as t2 on t1.Status = t2.CategoryDesc
UPDATE t1 set t1.CountToday = t2.RowCnt from @TemplateServiceAgreementTable as t1 join #Results_Today as t2 on t1.Status = t2.CategoryDesc

DECLARE @countAssignedUserChanged int
DECLARE @countPrimaryCategories int

select @countAssignedUserChanged = RowCnt from #Results_OneWeek where category_ID = 25
select @countPrimaryCategories = Sum(RowCnt) from #Results_OneWeek where category_ID in (2,3,4,6,7,19,31)
update @TemplateServiceAgreementTable set CountPastWeek = case 
	when @countAssignedUserChanged >= @countPrimaryCategories
		then @countAssignedUserChanged - @countPrimaryCategories
	else 0 
	end
where Status = 'Work in progress'


select @countAssignedUserChanged = RowCnt from #Results_Today where category_ID = 25
select @countPrimaryCategories = Sum(RowCnt) from #Results_Today where category_ID in (2,3,4,6,7,19,31)
update @TemplateServiceAgreementTable set CountToday = case 
	when @countAssignedUserChanged >= @countPrimaryCategories
		then @countAssignedUserChanged - @countPrimaryCategories
	else 0 
	end
where Status = 'Work in progress'

SELECT [Status], [CountTotal], [CountPastWeek], [CountSinceYesterday], [CountToday] FROM @TemplateServiceAgreementTable;

GO
