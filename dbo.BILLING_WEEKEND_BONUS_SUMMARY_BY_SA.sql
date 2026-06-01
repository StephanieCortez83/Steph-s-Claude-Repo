SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[BILLING_WEEKEND_BONUS_SUMMARY_BY_SA]
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
set		@billing_control_id = (Select billing_control_id from BILLING_CONTROL where STATUS_CD = 'A')

CREATE TABLE #tempWeekendBonus
(
	--tUID int, 
	--tName varchar(100),
	tThreshold int, 
	tProcessed varchar(8), 
	tTotal int, 
	tQualified int,
	tAmount decimal(11,2),
	tRate decimal(5,2),
	tServiceAgreementID int,
	tAggregateID int
)

insert into #tempWeekendBonus (tThreshold, tProcessed, tTotal, tQualified, tAmount, tRate, 
								tServiceAgreementID, tAggregateID)
(									
-- Weekend Bonus Program
select 
      Threshhold,
      Processed,
      Total,
      (case when Total >= Threshhold then Total else 0 end) Qualified,
      round((case when Total >= Threshhold then Total else 0 end) * .30,2) Amount,
      .30 Rate,
      Service_Agreement_id,     
      AggregateID
      
from (
select Processed, max(Threshhold) Threshhold, sum(Total) Total, Service_agreement_id, AggregateID 
from (
select 
                  convert(varchar, c.APPROVED_DATE, 112) Processed, 
                   sa.WEEKEND_BONUS_THRESHOLD_COUNT as Threshhold,
                   c.SERVICE_AGREEMENT_ID,
                  count(*) Total, sa.WEEKEND_BONUS_AGGREGATE_WITH_SERVICE_AGREEMENT_ID as AggregateID
from chart c, user_profile up, SERVICE_AGREEMENT sa
where c.CHART_STATUS_ID in (3,4,5)
		and   convert(varchar, c.APPROVED_DATE, 112) >= @from_date
		and   convert(varchar, c.APPROVED_DATE, 112) <= @to_date
and   datepart(weekday, c.APPROVED_DATE) in (1,7)
and   up.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
and	  up.USER_PROFILE_ID = @coder_user_profile_id	
and   up.USER_CLASS_CD = 2
and   c.SERVICE_AGREEMENT_ID not in (1, 93, 95)
and	  c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
group by convert(varchar, c.APPROVED_DATE, 112), c.SERVICE_AGREEMENT_ID, sa.WEEKEND_BONUS_THRESHOLD_COUNT, sa.WEEKEND_BONUS_AGGREGATE_WITH_SERVICE_AGREEMENT_ID

union
select 
                  convert(varchar, ln.CREATION_DATE_TIME, 112) Processed,    
                   sa.WEEKEND_BONUS_THRESHOLD_COUNT as Threshhold,  
                   c.SERVICE_AGREEMENT_ID,                              
                  count(*) Total, sa.WEEKEND_BONUS_AGGREGATE_WITH_SERVICE_AGREEMENT_ID as AggregateID
from  log_note ln, chart c, user_profile up, SERVICE_AGREEMENT sa
where ln.CATEGORY_ID = 2
and   convert(varchar, ln.CREATION_DATE_TIME, 112) >= @from_date
and   convert(varchar, ln.CREATION_DATE_TIME, 112) <= @to_date
and   datepart(weekday, ln.CREATION_DATE_TIME) in (1,7)
and   c.CHART_ID = ln.CHART_ID
and   c.CHART_STATUS_ID in (3,4,5)
and   c.SERVICE_AGREEMENT_ID not in (1, 93, 95)
and	  c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
and   up.USER_PROFILE_ID = ln.CREATING_USER_PROFILE_ID
and	  up.USER_PROFILE_ID = @coder_user_profile_id
and   up.USER_CLASS_CD = 2
and   ln.LOG_NOTE_ID in (select min(ln2.log_note_id) from log_note ln2
                  where ln2.CHART_ID = ln.CHART_ID
                  and   ln2.CATEGORY_ID = 2)
group by ln.CREATING_USER_PROFILE_ID, up.LAST_NAME + ', ' + up.FIRST_NAME, convert(varchar, ln.CREATION_DATE_TIME, 112), c.SERVICE_AGREEMENT_ID, sa.WEEKEND_BONUS_THRESHOLD_COUNT, sa.WEEKEND_BONUS_AGGREGATE_WITH_SERVICE_AGREEMENT_ID) x
group by Processed, AggregateID, x.SERVICE_AGREEMENT_ID) y

)

select x2.Threshold, x2.Processed, x2.Qualified, x2.Rate, x2.AggregateID, x2.Total, x2.Qualified * x2.Rate as Amount, x2.ServiceAgreementID from 
(
select	--tmp.tUID as UID,
		--tmp.tName as Name,
		tmp.tThreshold as Threshold,
		tmp.tProcessed as Processed,
		avg(tmp.tRate) as Rate,
		--tmp.tBillingControlID as BillingControlID,
		tmp.tAggregateID as AggregateID,
		sum(tmp.tTotal) as Total,
		sum(tmp.tQualified) as Qualified,
		sum(tmp.tAmount) as Amount,
		tmp.tServiceAgreementID as ServiceAgreementID				
from    #tempWeekendBonus tmp
where	tmp.tAggregateID <> -1 and tmp.tTotal >= tmp.tThreshold
group by tmp.tProcessed, tmp.tThreshold, tmp.tAggregateID, tmp.tServiceAgreementID

UNION 
select	--tmp.tUID as UID,
		--tmp.tName as Name,
		tmp.tThreshold as Threshold,
		tmp.tProcessed as Processed,
		avg(tmp.tRate) as Rate,
		--tmp.tBillingControlID as BillingControlID,
		tmp.tAggregateID as AggregateID,
		sum(tmp.tTotal) as Total,
		sum(tmp.tQualified) as Qualified,
		sum(tmp.tAmount) as Amount,
		tmp.tServiceAgreementID as ServiceAgreementID
from    #tempWeekendBonus tmp
where	(tmp.tAggregateID <> -1 and tmp.tTotal < tmp.tThreshold) or 
		(tmp.tAggregateID = -1)

group by tmp.tProcessed, tmp.tThreshold, tmp.tAggregateID, tmp.tServiceAgreementID
) x2								
END


GO
