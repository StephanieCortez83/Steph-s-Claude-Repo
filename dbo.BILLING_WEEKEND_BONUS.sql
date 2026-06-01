SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[BILLING_WEEKEND_BONUS]
	-- Add the parameters for the stored procedure here
  @coder_user_profile_id int,
  @from_date varchar(8),
  @to_date varchar(8)
  
AS
BEGIN

declare @billing_year int
declare @billing_month int
declare @billing_control_id int

set @billing_year = Cast(SUBSTRING(@from_date, 1,4) as int)
set @billing_month = Cast(SUBSTRING(@from_date, 5,2) as int)

	set		@billing_control_id = 
		(Select billing_control_id from BILLING_CONTROL bc where bc.BILLING_PERIOD_MONTH = @billing_month AND bc.BILLING_PERIOD_YEAR = @billing_year)
									
-- Weekend Bonus Program
select UID, 
                   Name,
                  Threshhold,
                  Processed,
                  Total,
                  (case when Total >= Threshhold then Total else 0 end) Qualified,
                  round((case when Total >= Threshhold then Total else 0 end) * .30,2) Amount,
                  .30 Rate,
                  0 Service_Agreement_id,
                  @billing_control_id BILLING_CONTROL_ID
                  
from (
select UID, Name, Processed, max(Threshhold) Threshhold, sum(Total) Total 
from (
select c.APPROVED_BY_USER_PROFILE_ID UID, up.LAST_NAME + ', ' + up.FIRST_NAME Name,
                  convert(varchar, c.APPROVED_DATE, 112) Processed, 
                   --case when c.SERVICE_AGREEMENT_ID in (109, 110, 111, 112, 113) then 50 else 75 end Threshhold,                  
                   sa.WEEKEND_BONUS_THRESHOLD_COUNT as Threshhold, 
                  count(*) Total, c.SERVICE_AGREEMENT_ID
from chart c WITH (NOLOCK), user_profile up WITH (NOLOCK), SERVICE_AGREEMENT sa
where c.CHART_STATUS_ID in (3,4,5,8) and c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		and   convert(varchar, c.APPROVED_DATE, 112) >= @from_date
		and   convert(varchar, c.APPROVED_DATE, 112) <= @to_date
and   datepart(weekday, c.APPROVED_DATE) in (1,7)
and   up.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
and	  up.USER_PROFILE_ID = @coder_user_profile_id	
and   up.USER_CLASS_CD = 2
and   c.SERVICE_AGREEMENT_ID not in (1, 93, 95)

group by c.APPROVED_BY_USER_PROFILE_ID, up.LAST_NAME + ', ' + up.FIRST_NAME, convert(varchar, c.APPROVED_DATE, 112), c.SERVICE_AGREEMENT_ID, sa.WEEKEND_BONUS_THRESHOLD_COUNT
union
select ln.CREATING_USER_PROFILE_ID UID, up.LAST_NAME + ', ' + up.FIRST_NAME Name,
                  convert(varchar, ln.CREATION_DATE_TIME, 112) Processed, 
                   --case when c.SERVICE_AGREEMENT_ID in (109, 110, 111, 112, 113) then 50 else 75 end Threshhold,
				  sa.WEEKEND_BONUS_THRESHOLD_COUNT as Threshhold,                  
                  count(*) Total, c.SERVICE_AGREEMENT_ID
from  log_note ln WITH (NOLOCK), chart c WITH (NOLOCK), user_profile up WITH (NOLOCK), SERVICE_AGREEMENT sa
where c.CHART_ID = ln.CHART_ID and ln.CATEGORY_ID = 2 and c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
and   convert(varchar, ln.CREATION_DATE_TIME, 112) >= @from_date
and   convert(varchar, ln.CREATION_DATE_TIME, 112) <= @to_date
and   datepart(weekday, ln.CREATION_DATE_TIME) in (1,7)
and   c.CHART_STATUS_ID in (3,4,5,8)
and   c.SERVICE_AGREEMENT_ID not in (1, 93, 95)
and   up.USER_PROFILE_ID = ln.CREATING_USER_PROFILE_ID
and	  up.USER_PROFILE_ID = @coder_user_profile_id
and   up.USER_CLASS_CD = 2
and   ln.LOG_NOTE_ID in (select min(ln2.log_note_id) from log_note ln2, USER_PROFILE up2
                  where ln2.CHART_ID = ln.CHART_ID
                  and   ln2.CATEGORY_ID = 2
                  and	ln2.CREATING_USER_PROFILE_ID = up2.USER_PROFILE_ID
                  and   up2.USER_CLASS_CD = 2)
group by ln.CREATING_USER_PROFILE_ID, up.LAST_NAME + ', ' + up.FIRST_NAME, convert(varchar, ln.CREATION_DATE_TIME, 112), c.SERVICE_AGREEMENT_ID, WEEKEND_BONUS_THRESHOLD_COUNT) x
group by UID, Name, Processed, Threshhold) y
order by Name, UID, Processed




END











GO
