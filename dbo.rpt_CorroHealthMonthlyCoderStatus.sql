SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE procedure [dbo].[rpt_CorroHealthMonthlyCoderStatus]
(
	 @ReportUser int
	,@BillingPeriod int 
)
as
begin



	
	
	set transaction isolation level read uncommitted

	set nocount on;

---- Test Parameters
	--declare 
	--     @ReportUser int = 80
 --       ,@BillingPeriod int = 219 -- Feb 2024
 	



	
	----------------------------------------------------------------------------------------------------
-- Clear Temp Tables

	if object_id('TempDB..#chart_pre', 'U') is not null drop table #chart_pre
	if object_id('TempDB..#chart_pre2', 'U') is not null drop table #chart_pre2	
	if object_id('TempDB..#Created_Chart', 'U') is not null drop table #Created_Chart
	if object_id('TempDB..#Created_Chart_2', 'U') is not null drop table #Created_Chart_2
	if object_id('TempDB..#Created_Chart_3', 'U') is not null drop table #Created_Chart_3
	
	if object_id('TempDB..#Chart_Access1', 'U') is not null	drop table #Chart_Access1
	if object_id('TempDB..#Chart_Access2', 'U') is not null	drop table #Chart_Access2
	if object_id('TempDB..#Chart_Access3', 'U') is not null	drop table #Chart_Access3
	if object_id('TempDB..#Chart_Access4_1', 'U') is not null drop table #Chart_Access4_1
	if object_id('TempDB..#Chart_Access4_2', 'U') is not null drop table #Chart_Access4_2
	if object_id('TempDB..#Chart_Access4', 'U') is not null	drop table #Chart_Access4
	if object_id('TempDB..#Chart_Access5', 'U') is not null	drop table #Chart_Access5
	if object_id('TempDB..#Chart_Access5_2', 'U') is not null	drop table #Chart_Access5_2
--	if object_id('TempDB..#Chart_Access6', 'U') is not null	drop table #Chart_Access6

print 'Section: 01 ' + convert(varchar, getdate(), 121)

	----------------------------------------------------------------------------------------------------
-- Billed Charts

	select 
		 c.chart_id
    into #CHART_pre				
	from
		  billed_chart bc 
		, chart c 
		, billing_control bctl 
	where 
			  bctl.BILLING_CONTROL_ID = bc.BILLING_CONTROL_ID
		and   bctl.BILLING_CONTROL_ID = @BillingPeriod
		and   bc.TYPE_CD = 'B'
		and   c.CHART_ID = bc.CHART_ID

		--  and facility_id = 1517 
		-- and c.chart_id = 115241925 
		


		



print 'Section: 02 ' + convert(varchar, getdate(), 121)

	----------------------------------------------------------------------------------------------------
-- Field Lookup


-- Note: can edit query for testing if needed ****

    select 
		 c.chart_id
		,c.COMPLETED_BY_USER_PROFILE_ID
		,c.facility_id
	--	,sa.SERVICE_MODEL_CD
    into #CHART_pre2	
	from
		CHART c
	--	,service_agreement sa
    where 
	    chart_id in ( select chart_id from #CHART_pre	)
	--	and c.facility_id = sa.facility_id
	-- and sa.organization_id = 1 -- testing only ****

	
	print 'Section: 02.1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------



-- Chart Access ********
-- Step 1 Pull	



	select 
	CHART_ACCESS_ID,
	USER_PROFILE_ID,
	CHART_ID,
	ACCESS_DATE_TIME,
	CHART_ACCESS_EVENT_TYPE_CODE,
	EVENT_COMPLETION_DATE_TIME,
	CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	SECONDARY_EVENT_COMPLETION_DATE_TIME, 
	CAST( ROUND((DATEDIFF(SECOND, ACCESS_DATE_TIME, SECONDARY_EVENT_COMPLETION_DATE_TIME)) * 1.00 / 60, 2) AS FLOAT) as Event_Time_In_Minutes,
	CAST( ROUND((DATEDIFF(SECOND, ACCESS_DATE_TIME, SECONDARY_EVENT_COMPLETION_DATE_TIME)) * 1.00, 2) AS FLOAT) as Event_Time_In_Seconds 
	into #Chart_Access1
    from chart_access
    where chart_id in (select distinct d1.CHART_ID from #CHART_pre2 d1)  
    and (CHART_ACCESS_EVENT_TYPE_CODE in ( 'B', 'C')
	OR
	CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE in ( 'C','D','I') )


print 'Section: 03.0 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------


-- Restrict table to Completed Users Only



	select 
	ca1.CHART_ACCESS_ID,
	ca1.USER_PROFILE_ID,
	ca1.CHART_ID,
	ca1.ACCESS_DATE_TIME,
	ca1.CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.EVENT_COMPLETION_DATE_TIME,
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME, 
	CAST( ROUND((DATEDIFF(SECOND, ACCESS_DATE_TIME, SECONDARY_EVENT_COMPLETION_DATE_TIME)) * 1.00 / 60, 2) AS FLOAT) as Event_Time_In_Minutes,
	CAST( ROUND((DATEDIFF(SECOND, ACCESS_DATE_TIME, SECONDARY_EVENT_COMPLETION_DATE_TIME)) * 1.00, 2) AS FLOAT) as Event_Time_In_Seconds 
	into #Chart_Access2
    from #Chart_Access1 ca1,
    #CHART_pre2 c	
	where 
	ca1.chart_id = c.chart_id
	and ca1.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
    

print 'Section: 03.1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------


-- Step 2 Process
-- Create Shell 

	
		
		create table #chart_access3
	(
		CHART_ACCESS_ID   bigint,
        [USER_PROFILE_ID] int,
        [CHART_ID]        int,
		[ACCESS_DATE_TIME] datetime,		
        [CHART_ACCESS_EVENT_TYPE_CODE]			  varchar(1),
		EVENT_COMPLETION_DATE_TIME				  datetime, 	
        [CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE]  varchar(1),
		[SECONDARY_EVENT_COMPLETION_DATE_TIME]    datetime,		
		Event_Time_In_Minutes float,
	    Event_Time_In_Seconds float,
	    Coder_Time_In_Minutes float,
	    Coder_Time_In_Seconds float,
		Process_Type		  varchar(2),
		Process_SubType		  varchar(2)		
	);


print 'Section: 04.0 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------



-- Pended Records
insert into #Chart_Access3
select 
	ca1.CHART_ACCESS_ID,
	ca1.USER_PROFILE_ID,
	ca1.CHART_ID,
	ca1.ACCESS_DATE_TIME,	
	ca1.CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.EVENT_COMPLETION_DATE_TIME,
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME,
	ca1.Event_Time_In_Minutes,
	ca1.Event_Time_In_Seconds,
	ca1.Event_Time_In_Minutes as Coder_Time_In_Minutes,
	ca1.Event_Time_In_Seconds as Coder_Time_In_Seconds,
	'P' as Process_Type,
	''  as Process_SubType
    from 
	#chart_access2 ca1
	where 
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE = 'I'



print 'Section: 04.1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

		
-- 	select * from #Chart_Access2


-- Demographics -- 


insert into #Chart_Access3
select 
	ca1.CHART_ACCESS_ID,
	ca1.USER_PROFILE_ID,
	ca1.CHART_ID,
	ca1.ACCESS_DATE_TIME,	
	ca1.CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.EVENT_COMPLETION_DATE_TIME,
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME, 	
	ca1.Event_Time_In_Minutes,
	ca1.Event_Time_In_Seconds,	
	CAST( ROUND((DATEDIFF(SECOND, ACCESS_DATE_TIME, SECONDARY_EVENT_COMPLETION_DATE_TIME)) * 1.00 / 60, 2) AS FLOAT)  as Event_Time_In_Minutes,
	CAST( ROUND((DATEDIFF(SECOND, ACCESS_DATE_TIME, SECONDARY_EVENT_COMPLETION_DATE_TIME)) * 1.00, 2) AS FLOAT)       as Event_Time_In_Seconds,
	'D' as Process_Type,
	''  as Process_SubType	
    from 
	#chart_access2 ca1
	where 	
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE =  'D'
	and ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME is not null



print 'Section: 04.1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------






-- check c / d records
 

 insert into #Chart_Access3
 select 
 	ca1.CHART_ACCESS_ID,
	ca1.USER_PROFILE_ID,
	ca1.CHART_ID,
	ca1.ACCESS_DATE_TIME,	
	ca1.CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.EVENT_COMPLETION_DATE_TIME,
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME,
	ca1.Event_Time_In_Minutes,
	ca1.Event_Time_In_Seconds,
	--ca1.Event_Time_In_Minutes as Coder_Time_In_Minutes,
	--ca1.Event_Time_In_Seconds as Coder_Time_In_Seconds,
	CAST( ROUND((DATEDIFF(SECOND, ca1.ACCESS_DATE_TIME, ca1.EVENT_COMPLETION_DATE_TIME)) * 1.00 / 60, 2) AS FLOAT) as Coder_Time_In_Minutes,
	CAST( ROUND((DATEDIFF(SECOND, ca1.ACCESS_DATE_TIME, ca1.EVENT_COMPLETION_DATE_TIME)) * 1.00, 2) AS FLOAT) as Coder_Time_In_Seconds, 
	'C' as Process_Type,
	'Y' as Process_SubType
 from 
 #Chart_Access2	ca1,
 #Chart_Access2	ca2
 where 
	ca1.chart_id = ca2.chart_id
and ca1.user_profile_id = ca2.user_profile_id
--  and ca1.chart_id = 114060779 
and ca1.CHART_ACCESS_EVENT_TYPE_CODE = 'C'
and ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE = 'D'

-- and ca1.access_date_time between dateadd(minute, -1, ca2.access_date_time) and ca2.access_date_time 
and ca1.EVENT_COMPLETION_DATE_TIME between dateadd(second, -2, ca2.SECONDARY_EVENT_COMPLETION_DATE_TIME) and ca2.SECONDARY_EVENT_COMPLETION_DATE_TIME 


print 'Section: 05.0 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------




-- check c / NULL records
 insert into #Chart_Access3
 select 
 	ca1.CHART_ACCESS_ID,
	ca1.USER_PROFILE_ID,
	ca1.CHART_ID,
	ca1.ACCESS_DATE_TIME,	
	ca1.CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.EVENT_COMPLETION_DATE_TIME,
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME,
	ca1.Event_Time_In_Minutes,
	ca1.Event_Time_In_Seconds,
	CAST( ROUND((DATEDIFF(SECOND, ca1.ACCESS_DATE_TIME, ca1.EVENT_COMPLETION_DATE_TIME)) * 1.00 / 60, 2) AS FLOAT) as Coder_Time_In_Minutes,
	CAST( ROUND((DATEDIFF(SECOND, ca1.ACCESS_DATE_TIME, ca1.EVENT_COMPLETION_DATE_TIME)) * 1.00, 2) AS FLOAT) as Coder_Time_In_Seconds, 
	--ca1.Event_Time_In_Minutes as Coder_Time_In_Minutes,
	--ca1.Event_Time_In_Seconds as Coder_Time_In_Seconds,
	'C' as Process_Type,
	'Y' as Process_SubType
 from 
 #Chart_Access2	ca1,
 #Chart_Access2	ca2
 where 
	ca1.chart_id = ca2.chart_id
and ca1.user_profile_id = ca2.user_profile_id
--  and ca1.chart_id = 114060779 
and ca1.CHART_ACCESS_EVENT_TYPE_CODE = 'C'
and ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE IS NULL

-- and ca1.access_date_time between dateadd(minute, -1, ca2.access_date_time) and ca2.access_date_time 
and ca1.EVENT_COMPLETION_DATE_TIME between dateadd(second, -2, ca2.SECONDARY_EVENT_COMPLETION_DATE_TIME) and ca2.SECONDARY_EVENT_COMPLETION_DATE_TIME 
and ca1.CHART_ID not in ( select CHART_ID from #chart_access3 where Process_Type = 'C' and Process_SubType = 'Y')


print 'Section: 05.1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

-- dups in chart access
-- id multi C records
 
  insert into #Chart_Access3
 select 
 	ca1.CHART_ACCESS_ID,
	ca1.USER_PROFILE_ID,
	ca1.CHART_ID,
	ca1.ACCESS_DATE_TIME,	
	ca1.CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.EVENT_COMPLETION_DATE_TIME,
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME,
	ca1.Event_Time_In_Minutes,
	ca1.Event_Time_In_Seconds,
	ca1.Event_Time_In_Minutes as Coder_Time_In_Minutes,
	ca1.Event_Time_In_Seconds as Coder_Time_In_Seconds,
	'C' as Process_Type,
	'N' as Process_SubType
 from 
 #Chart_Access2 ca1,
 #Chart_Access2	ca2
 where 
	ca1.chart_id = ca2.chart_id
and ca1.user_profile_id = ca2.user_profile_id
-- and ca1.chart_id = 114060779 
and ca1.CHART_ACCESS_EVENT_TYPE_CODE = 'B'
and ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE = 'C'

--and ca1.access_date_time between  ca2.access_date_time and dateadd(minute, 1, ca2.access_date_time) 
and ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME between ca2.EVENT_COMPLETION_DATE_TIME and dateadd(second, 2, ca2.EVENT_COMPLETION_DATE_TIME) 


print 'Section: 05.2 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------


-- try to collect valid multi completions
  insert into #Chart_Access3
 select 
 	ca1.CHART_ACCESS_ID,
	ca1.USER_PROFILE_ID,
	ca1.CHART_ID,
	ca1.ACCESS_DATE_TIME,	
	ca1.CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.EVENT_COMPLETION_DATE_TIME,
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME,
	ca1.Event_Time_In_Minutes,
	ca1.Event_Time_In_Seconds,
	CAST( ROUND((DATEDIFF(SECOND, ca1.ACCESS_DATE_TIME, ca1.EVENT_COMPLETION_DATE_TIME)) * 1.00 / 60, 2) AS FLOAT) as Coder_Time_In_Minutes,
	CAST( ROUND((DATEDIFF(SECOND, ca1.ACCESS_DATE_TIME, ca1.EVENT_COMPLETION_DATE_TIME)) * 1.00, 2) AS FLOAT) as Coder_Time_In_Seconds, 
	--ca1.Event_Time_In_Minutes as Coder_Time_In_Minutes,
	--ca1.Event_Time_In_Seconds as Coder_Time_In_Seconds,
	'C' as Process_Type,
	'Y' as Process_SubType
 from 
 #Chart_Access2 ca1
 where  
 ca1.CHART_ACCESS_EVENT_TYPE_CODE = 'C'  
--  and chart_id = 114060779 
 -- ca1.CHART_ID not in ( select CHART_ID from #chart_access3 where Process_Type = 'C' and Process_SubType = 'Y')
and    ca1.CHART_ACCESS_ID not in ( select CHART_ACCESS_ID from #chart_access3 where Process_Type = 'C')


print 'Section: 05.3 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------


 insert into #Chart_Access3
 select 
 	ca1.CHART_ACCESS_ID,
	ca1.USER_PROFILE_ID,
	ca1.CHART_ID,
	ca1.ACCESS_DATE_TIME,	
	ca1.CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.EVENT_COMPLETION_DATE_TIME,
	ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME,
	ca1.Event_Time_In_Minutes,
	ca1.Event_Time_In_Seconds,
	CAST( ROUND((DATEDIFF(SECOND, ca1.ACCESS_DATE_TIME, ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME)) * 1.00 / 60, 2) AS FLOAT) as Coder_Time_In_Minutes,
	CAST( ROUND((DATEDIFF(SECOND, ca1.ACCESS_DATE_TIME, ca1.SECONDARY_EVENT_COMPLETION_DATE_TIME)) * 1.00, 2) AS FLOAT) as Coder_Time_In_Seconds, 
	--ca1.Event_Time_In_Minutes as Coder_Time_In_Minutes,
	--ca1.Event_Time_In_Seconds as Coder_Time_In_Seconds,
	'C' as Process_Type,
	'Y' as Process_SubType
 from 
 #Chart_Access2 ca1
 where  
 ca1.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE = 'C'
--  and chart_id = 114060779 
 -- ca1.CHART_ID not in ( select CHART_ID from #chart_access3 where Process_Type = 'C' and Process_SubType = 'Y')
and    ca1.CHART_ACCESS_ID not in ( select CHART_ACCESS_ID from #chart_access3 where Process_Type = 'C')


print 'Section: 05.4 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------




delete from #Chart_Access3 
where 
process_type = 'C'
and process_subtype = 'N'



print 'Section: 05.5 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------



	
-- Charts with No Chart Access Records
-- Some Created Charts will not have Chart Access Records
-- The following steps will go to Log Note to account for these charts

select chart_id
into #Created_Chart
from 
#CHART_pre2
where 
chart_id not in ( select CHART_ID from #chart_access3 where Process_Type = 'C')


print 'Section: 06.0 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------






select 
LOG_NOTE_ID, CHART_ID, SUMMARY, COMPLETION_DATE, COMPLETED_BY_USER_ID, CATEGORY_ID
into #Created_Chart_2
 from log_note
where chart_id in (select chart_id from #Created_Chart )
and category_id in ( 1,2)



print 'Section: 06.1 ' + convert(varchar, getdate(), 121)


select 
chart_id, 
max(case when category_id = 1 then COMPLETED_BY_USER_ID else NULL end) as CreatedUser,
max(case when category_id = 1 then COMPLETION_DATE else NULL end) as CreatedDate,
max(case when category_id = 2 then COMPLETED_BY_USER_ID else NULL end) as CompletedUser,
max(case when category_id = 2 then COMPLETION_DATE else NULL end) as CompletedDate
into #Created_Chart_3
from #Created_Chart_2
group by chart_id



print 'Section: 06.2 ' + convert(varchar, getdate(), 121)




   insert into #Chart_Access3
    select 
	ca1.CHART_ID as CHART_ACCESS_ID,
	ca1.CreatedUser, -- The Created and Completed User should be the same
	ca1.CHART_ID,
	ca1.CreatedDate as ACCESS_DATE_TIME,	
	NULL as CHART_ACCESS_EVENT_TYPE_CODE,
	ca1.CompletedDate as EVENT_COMPLETION_DATE_TIME,	
	NULL CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE,
	NULL SECONDARY_EVENT_COMPLETION_DATE_TIME, 	
	NULL Event_Time_In_Minutes,
	NULL Event_Time_In_Seconds,
	CAST( ROUND((DATEDIFF(SECOND, ca1.CreatedDate, ca1.CompletedDate)) * 1.00 / 60, 2) AS FLOAT) as Coder_Time_In_Minutes,
	CAST( ROUND((DATEDIFF(SECOND, ca1.CreatedDate, ca1.CompletedDate)) * 1.00, 2) AS FLOAT) as Coder_Time_In_Seconds, 
	'C' as Process_Type,
	'Y' as Process_SubType
    from 
	#Created_Chart_3 ca1
	where 
	CreatedUser = CompletedUser
	
	


print 'Section: 06.3 ' + convert(varchar, getdate(), 121)


 

	----------------------------------------------------------------------------------------------------

-- Summarize

	select 
	ca.USER_PROFILE_ID, 
	d.FACILITY_ID,
	sum(ca.Coder_Time_In_Minutes) as TotalTimeInMinutes,
	sum(ca.Coder_Time_In_Seconds) as TotalTimeInSeconds,
	FacilityMedian = cast(null as decimal(8,1)),	
	0 as ChartCompletionDates,
    0 as CompleteChartCount
 	into #Chart_Access4
	from #Chart_Access3 ca,	 
	#CHART_pre2	d				
	where ca.chart_id = d.chart_id
	and ca.USER_PROFILE_ID = d.COMPLETED_BY_USER_PROFILE_ID 		
	group by 
	ca.USER_PROFILE_ID, 
	d.FACILITY_ID


	

print 'Section: 07.0 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	 

	

		select 
	ca.USER_PROFILE_ID, 
	d.FACILITY_ID,		
	count(distinct(cast(isnull(secondary_event_completion_date_time, EVENT_COMPLETION_DATE_TIME) as date))) as ChartCompletionDates,
	count(distinct(ca.chart_id)) as CompleteChartCount	-- count distinct, charts can be completed multi times
 	into #Chart_Access4_1
	from #Chart_Access3 ca
	,	 
	#CHART_pre2	d				
	where ca.chart_id = d.chart_id
	and ca.USER_PROFILE_ID = d.COMPLETED_BY_USER_PROFILE_ID 
	and 
	ca.process_type = 'C'
	group by 
	ca.USER_PROFILE_ID, 
	d.FACILITY_ID


print 'Section: 07.1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	
	    SELECT	DISTINCT
		Facility_id,
		--ChartCompletionDates,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ChartCompletionDates) OVER(PARTITION BY Facility_id) as Median
		into #Chart_Access4_2
        FROM	#Chart_Access4_1;
	


print 'Section: 07.2 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	        update						
            t						
        set						
             t.ChartCompletionDates = t1.ChartCompletionDates
            ,t.CompleteChartCount = t1.CompleteChartCount						            
        from						
            #Chart_Access4 as t						
            join #Chart_Access4_1 as t1 on t.USER_PROFILE_ID = t1.USER_PROFILE_ID
			and t.FACILITY_ID = t1.FACILITY_ID;						

			
			update						
            t						
        set						
             t.FacilityMedian = t1.Median
            
        from						
            #Chart_Access4 as t						
            join #Chart_Access4_2 as t1 on t.FACILITY_ID = t1.FACILITY_ID;						



	print 'Section: 07.3 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

-- SA Look up

select 
ca.*,
(select last_name + ', ' + first_name from user_profile where user_profile_id = ca.USER_PROFILE_ID) as Coder,
sa.company_id,
sa.ORGANIZATION_ID,
sa.SERVICE_MODEL_CD,
case when fc.[DESCRIPTION] = 'Clinic-Specialty' then 'Clinic'
	 when sa.FACILITY_TYPE_CD = 1 then 'ED'
	 when sa.FACILITY_TYPE_CD = 2 then 'Urgent Care' 
end as FACILITY_TYPE
into #Chart_Access5
from 
#Chart_Access4 ca,
SERVICE_AGREEMENT SA
left join SERVICE_AGREEMENT_CLIENT_SPECIFICS sacs on sa.SERVICE_AGREEMENT_ID = sacs.SERVICE_AGREEMENT_ID
left join FACILITY_CLASSIFICATION fc on sacs.FACILITY_CLASSIFICATION_ID = fc.FACILITY_CLASSIFICATION_ID
where 
ca.FACILITY_ID = sa.FACILITY_ID
and sa.DEMO_TEST_SITE_IND <> 1 -- Exclude Demo Sites

-- and sa.organization_id = 1 -- test only ****



print 'Section: 08.0 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------


--	select * from #Chart_Access5_2

        SELECT	DISTINCT
		company_id,
		-- ChartCompletionDates,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ChartCompletionDates) OVER(PARTITION BY company_id) as Median
		into #Chart_Access5_2
        FROM #Chart_Access5;




print 'Section: 08.1 ' + convert(varchar, getdate(), 121)
----------------------------------------------------------------------------------------------------



select 
ca.Facility_ID,
(select name from facility where facility_id = ca.facility_id) as Facility,
ca.Company_ID, 
(select name from company where company_id = ca.company_id) as ParentCompany,
ca.Organization_ID,
( select description from ORGANIZATION where organization_ID = ca.Organization_ID) as Organization,
(select description from service_model where SERVICE_MODEL_CD = ca.SERVICE_MODEL_CD) as ServiceModel,
ca.FACILITY_TYPE as FacilityType,
ca.User_Profile_ID,
ca.Coder,
ca.TotalTimeInMinutes,
ca.TotalTimeInSeconds,
ca.ChartCompletionDates,
ca.CompleteChartCount,
ca.FacilityMedian,
(select median from #Chart_Access5_2 where company_id = ca.COMPANY_ID) as CompanyMedian
--   into #Chart_Access6
from #Chart_Access5 ca
where  
EXISTS (								
		SELECT *						
		FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
		USER_PROFILE UP	WITH (NOLOCK)					
		WHERE FUA.FACILITY_ID = ca.FACILITY_ID						
		AND fua.user_profile_id = up.user_profile_id						
		AND UP.IS_ACTIVE = 'Y'						
		and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
		AND FUA.USER_PROFILE_ID = @ReportUser						
		)						


print 'Section: 09.0 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------



 end




GO
