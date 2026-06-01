SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 6/20/2013
-- Description:	SQL for the Daily Aged Accounts Report

-- 07/02/2024 Don Hutton Added Chart Identifier per RAP-467
-- 11/08/2016 Don Hutton Added @HoursElapsed per ACS-8604 
-- New version tuned by David Sexton on 04/26/17, previous version in ACS-9338
-- New version tuned by David Sexton on 8/18/2020
-- 03/16/2021 Don Hutton AAR-1167 added Patient Disposition and Patient Class
-- =============================================


CREATE procedure [dbo].[rpt_DailyAgedAccountsReport]
  @AccountManagerId int = -1,
  @ReportUser int = 80,
  @ChartStatus int,
  @HoursElapsed int,
  @UserGroup varchar(max)

as
begin

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	set transaction isolation level read uncommitted

--	---- TEST PARMS --
--	declare
--		@AccountManagerId int = 2219 -- Jen Tarum
--		@AccountManagerId int = 6793  -- vallie
--		@AccountManagerId int = -1  -- all


--		--,@ReportUser      int = 10594   -- Visionary
--		--,@ReportUser      int = 6611      -- Access Health
--		,@ReportUser      int = 80      -- Admin
--		,@ChartStatus     int = -1
--		,@HoursElapsed    int = 48
--		,@UserGroup       int = -1;
--	---- TEST PARMS --

  DECLARE @MgrID INT = @AccountManagerId;
  DECLARE @m_ReportUser INT = @ReportUser;
  DECLARE @m_ChartStatus INT = @ChartStatus;
  DECLARE @m_HoursElapsed INT = @HoursElapsed;
  DECLARE @m_UserGroup varchar(max) = @UserGroup;


 Declare @m_ReportUserClass INT =  (select User_Class_cd from user_profile where user_profile_id = @ReportUser);

if object_ID('TempDB..#Pre_ChartSubset', 'U') is not null DROP TABLE #Pre_ChartSubset;		-- for tuning 4/14/2017
if object_ID('TempDB..#ChartSubset', 'U') is not null DROP TABLE #ChartSubset;
if object_ID('TempDB..#LogNote', 'U') is not null DROP TABLE #LogNote;


if object_ID('TempDB..#LogNote_Cat5', 'U') is not null DROP TABLE #LogNote_Cat5;		-- for section tuned 8/18/2020
if object_ID('TempDB..#LogNote_Cat8', 'U') is not null DROP TABLE #LogNote_Cat8;		-- for section tuned 8/18/2020

if object_id('TempDB..#UserGroup1', 'U') is not null drop table #UserGroup1;

			select t1.USER_PROFILE_ID, t1.USER_GROUP_ID
			into #UserGroup1
			from
			(
					SELECT USER_PROFILE_ID, USER_GROUP_ID							
					FROM USER_PROFILE				
					WHERE USER_GROUP_ID in ( select * from [dbo].[SplitString](@m_UserGroup, ',') )
			
					UNION											
			
					SELECT ugup.USER_PROFILE_ID, ugup.USER_GROUP_ID			
					FROM USER_GROUP_TO_USER_PROFILE ugup				
					where 
					ugup.USER_GROUP_ID in ( select * from [dbo].[SplitString](@m_UserGroup, ',') )
			) t1	



-- new section to populate #ChartSubset -- for tuning 4/14/2017
select 
	c.chart_ID,
	sa.service_agreement_ID,
	c.facility_ID,
	c.chart_Status_ID,
	c.Facility_Chart_ID,
	c.Time_Of_Service,
	c.Creation_Date_Time,
	c.Date_Received,
	c.Completion_Date,
	c.Approved_Date,
	c.Coder_Comment,
	c.Assigned_To_ID,
	c.COMPLETED_BY_USER_PROFILE_ID,
	c.Approved_By_User_Profile_ID,
	c.Pending_Reason_ID,
	c.patient_disposition_id, 
    c.patient_class_id
 INTO #Pre_ChartSubset
from 
	chart as c with(nolock)
	join service_agreement as sa with(nolock) on c.service_agreement_ID = sa.service_agreement_ID
WHERE 
	sa.DEMO_TEST_SITE_IND <> 1
	AND (c.CHART_STATUS_ID = @m_ChartStatus
	       OR -1 = @m_ChartStatus )
	AND sa.EXPIRATION_DATE > GETDATE() -- 3-20-2015 DanielB: Ignore expired accounts
	AND (
			(
				  sa.TURNAROUND_HOURS_REPORTING_METHOD IN (1,2,6,7,8,9)
				  AND c.CHART_STATUS_ID IN (1,3,8) -- Work in Progress, Completed and 2nd Audit only 
				  -- Added 2nd Audit per JIRA ACS-11499 on 01/29/2018			  
				  AND DATEDIFF(MINUTE, CASE 
						  WHEN sa.TURNAROUND_HOURS_REPORTING_METHOD IN (1,2)
							  THEN c.DATE_RECEIVED
						  WHEN sa.TURNAROUND_HOURS_REPORTING_METHOD IN (6,7)
							  THEN isnull((
										  SELECT MAX(LOG_NOTE.COMPLETION_DATE)									  
										  FROM LOG_NOTE WITH (NOLOCK)
										  WHERE LOG_NOTE.CHART_ID = c.CHART_ID
											  AND (								
                                        (
                                            LOG_NOTE.CATEGORY_ID = 5
                                            AND LOG_NOTE.DETAIL LIKE 'Chart status moved to work in progress.  Previous status was Pending%'
                                            )
                                        OR (
                                            LOG_NOTE.CATEGORY_ID = 8
                                            AND (
                                                LOG_NOTE.SUMMARY LIKE 'Chart status changed to Work in Progress%'
                                                OR LOG_NOTE.DETAIL LIKE 'Chart status changed to Work in Progress%'
                                                )
                                            )
                                        )
										  ), c.CREATION_DATE_TIME)
						  ELSE (
								  SELECT MAX(CREATION_DATE_TIME)
								  FROM vwImportImage WITH (NOLOCK)	-- In this case the view performs OK
								  WHERE CHART_ID = c.CHART_ID
								  )
						  END, GETDATE()) / 60 >= @m_HoursElapsed
				  )
			  OR (
				  sa.TURNAROUND_HOURS_REPORTING_METHOD IN (3,4)
				  AND c.CHART_STATUS_ID IN (1,3,4) -- Work in Progress, Completed and Approved only
				  AND DATEDIFF(minute, c.CREATION_DATE_TIME, GETDATE()) / 60 >= @m_HoursElapsed
				  )
			  OR (
				  sa.TURNAROUND_HOURS_REPORTING_METHOD = 5
				  AND c.CHART_STATUS_ID IN (1,3) -- Work in Progress and Completed only
				  AND DATEDIFF(minute, DATEADD(minute, sa.TURNAROUND_START_TIME_IN_MINUTES, DATEADD(dd, DATEDIFF(dd, 0, c.CREATION_DATE_TIME), 0)), GETDATE()) / 60 >= @m_HoursElapsed
				  )
			  )
		  AND c.CHART_ID NOT IN (
			  SELECT ln.CHART_ID
			  FROM LOG_NOTE ln WITH (NOLOCK)
			  WHERE ln.chart_id = c.CHART_ID
				  AND ln.CATEGORY_ID = 6
				  AND (sa.TURNAROUND_HOURS_REPORTING_METHOD NOT IN (6,7) and sa.company_id <> 149) -- RAP-417 DAH 06/18/24, Include Miami Children's Hospital Pended Charts				  
			  ) -- Ignore accounts that were ever in pending state
		  AND (
			  @MgrID = - 1
			  OR sa.[SERVICE_AGREEMENT_ID] IN (
				  SELECT [SERVICE_AGREEMENT_ID]
				  FROM [dbo].[SERVICE_AGREEMENT_MANAGEMENT_TEAM] WITH (NOLOCK)
				  WHERE [USER_PROFILE_ID] = @MgrID
				  )
			  )
      AND EXISTS (
        SELECT *
        FROM [dbo].[FACILITY_USER_AUTHORIZATION] WITH (NOLOCK)
        WHERE USER_PROFILE_ID = @m_ReportUser
          AND FACILITY_ID = c.FACILITY_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) <= EXPIRATION_DATE



      );



-- ****************************************************
-- Count by Rec'd Date
-- RAP-392 04/30/24 DAH

if object_id('TempDB..#RecdCount1', 'U') is not null drop table #RecdCount1;
if object_id('TempDB..#RecdCount2', 'U') is not null drop table #RecdCount2;

select 
c.Facility_ID,
cast(c.DATE_RECEIVED as DATE) as DateRecd,
count(c.CHART_ID) as Count1
into #RecdCount1
from [CHART] c 
where
c.facility_id in ( select distinct(facility_id) from #Pre_ChartSubset)
and c.DATE_RECEIVED > cast(getDate()-7 as date)
group by 
c.Facility_ID,
cast(c.DATE_RECEIVED as DATE) 
order by cast(c.DATE_RECEIVED as DATE); 



 

select Facility_ID, 
sum(case when DateRecd = cast(GetDate() as Date) then Count1 end) as [Count_0],
sum(case when DateRecd = cast(GetDate()-1 as Date) then Count1 end) as [Count_1],
sum(case when DateRecd = cast(GetDate()-2 as Date) then Count1 end) as [Count_2],
sum(case when DateRecd = cast(GetDate()-3 as Date) then Count1 end) as [Count_3],
sum(case when DateRecd = cast(GetDate()-4 as Date) then Count1 end) as [Count_4],
sum(case when DateRecd = cast(GetDate()-5 as Date) then Count1 end) as [Count_5],
sum(case when DateRecd = cast(GetDate()-6 as Date) then Count1 end) as [Count_6]
into #RecdCount2
from #RecdCount1
group by Facility_ID;


-- ****************************************************





create table #ChartSubset		
(	
chart_ID				int
,service_agreement_ID	int
,facility_ID			int
,chart_Status_ID		int
,Facility_Chart_ID		varchar(20)
,Time_Of_Service		datetime
,Creation_Date_Time		datetime
,Date_Received			datetime
,Completion_Date		datetime
,Approved_Date			datetime
,Coder_Comment			varchar(2000) 
,Assigned_To_ID			int
,COMPLETED_BY_USER_PROFILE_ID	int
,Approved_By_User_Profile_ID	int
,Pending_Reason_ID				int
,patient_disposition_id			int
,patient_class_id				int	

)

	
	

-- Removed Rpeort User Class Condition RAP-444 DAH 07/01/2024
-- IF @m_ReportUserClass in ( 1,5) -- = 1
-- BEGIN	


INSERT INTO #ChartSubset	
select 
chart_ID 
,service_agreement_ID 
,facility_ID 
,chart_Status_ID
,Facility_Chart_ID
,Time_Of_Service
,Creation_Date_Time
,Date_Received	
,Completion_Date
,Approved_Date	
,Coder_Comment	
,Assigned_To_ID	
,COMPLETED_BY_USER_PROFILE_ID
,Approved_By_User_Profile_ID
,Pending_Reason_ID
,patient_disposition_id
,patient_class_id


from
( 
-- Work in progress
select 
 chart_ID 
,service_agreement_ID 
,facility_ID 
,chart_Status_ID
,Facility_Chart_ID
,Time_Of_Service
,Creation_Date_Time
,Date_Received	
,Completion_Date
,Approved_Date	
,Coder_Comment	
,Assigned_To_ID	
,COMPLETED_BY_USER_PROFILE_ID
,Approved_By_User_Profile_ID
,Pending_Reason_ID 
,patient_disposition_id
,patient_class_id
from #Pre_ChartSubset
where 
chart_status_id = 1

union all
-- NOT - Work in progress
select
chart_ID 
,service_agreement_ID 
,facility_ID 
,chart_Status_ID
,Facility_Chart_ID
,Time_Of_Service
,Creation_Date_Time
,Date_Received	
,Completion_Date
,Approved_Date	
,Coder_Comment	
,Assigned_To_ID	
,COMPLETED_BY_USER_PROFILE_ID
,Approved_By_User_Profile_ID
,Pending_Reason_ID
,patient_disposition_id
,patient_class_id
from #Pre_ChartSubset
where 
chart_status_id <> 1
and 		   (
		  '-1' in (@m_UserGroup) 
		  or 
		  EXISTS (select 1 from #UserGroup1 where USER_PROFILE_ID = COMPLETED_BY_USER_PROFILE_ID )
			)
)t1

-- END;
-- ELSE

/*

IF @m_ReportUserClass = 5
BEGIN	


INSERT INTO #ChartSubset		

select 
chart_ID 
,service_agreement_ID 
,facility_ID 
,chart_Status_ID
,Facility_Chart_ID
,Time_Of_Service
,Creation_Date_Time
,Date_Received	
,Completion_Date
,Approved_Date	
,Coder_Comment	
,Assigned_To_ID	
,COMPLETED_BY_USER_PROFILE_ID
,Approved_By_User_Profile_ID
,Pending_Reason_ID 
,patient_disposition_id
,patient_class_id

from ( 
-- Work in progress
select 
chart_ID 
,service_agreement_ID 
,facility_ID 
,chart_Status_ID
,Facility_Chart_ID
,Time_Of_Service
,Creation_Date_Time
,Date_Received	
,Completion_Date
,Approved_Date	
,Coder_Comment	
,Assigned_To_ID	
,COMPLETED_BY_USER_PROFILE_ID
,Approved_By_User_Profile_ID
,Pending_Reason_ID
,patient_disposition_id
,patient_class_id
from #Pre_ChartSubset
where 
chart_status_id = 1
and service_agreement_id in ( 
				select sa.SERVICE_AGREEMENT_ID
				from 
				 SERVICE_AGREEMENT sa,
				[dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla with (nolock)
                inner join [dbo].[SERVICE_LOCATION] sl with (nolock) on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
				inner join [dbo].[COMPANY] cpy with (nolock) on cpy.COMPANY_ID = sl.COMPANY_ID
				where sla.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				and getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
				and getdate() between sla.EFFECTIVE_DATE and sla.EXPIRATION_DATE

				and EXISTS (								
								SELECT *						
								FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
								USER_PROFILE UP	WITH (NOLOCK)					
								WHERE FUA.FACILITY_ID = sa.FACILITY_ID						
								AND fua.user_profile_id = up.user_profile_id						
								AND UP.IS_ACTIVE = 'Y'						
								and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
								AND FUA.USER_PROFILE_ID = @ReportUser						
							)
				)
union all

-- NOT - Work in progress
select 
chart_ID 
,service_agreement_ID 
,facility_ID 
,chart_Status_ID
,Facility_Chart_ID
,Time_Of_Service
,Creation_Date_Time
,Date_Received	
,Completion_Date
,Approved_Date	
,Coder_Comment	
,Assigned_To_ID	
,COMPLETED_BY_USER_PROFILE_ID
,Approved_By_User_Profile_ID
,Pending_Reason_ID
,patient_disposition_id
,patient_class_id
from #Pre_ChartSubset
where 
chart_status_id <> 1
and 		   (
		  '-1' in (@m_UserGroup) 
		  or 
		  EXISTS (select 1 from #UserGroup1 where USER_PROFILE_ID = COMPLETED_BY_USER_PROFILE_ID )
			)
and service_agreement_id in ( 
				select sa.SERVICE_AGREEMENT_ID
				from 
				 SERVICE_AGREEMENT sa,
				[dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla with (nolock)
                inner join [dbo].[SERVICE_LOCATION] sl with (nolock) on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
				inner join [dbo].[COMPANY] cpy with (nolock) on cpy.COMPANY_ID = sl.COMPANY_ID
				where sla.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				and getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
				and getdate() between sla.EFFECTIVE_DATE and sla.EXPIRATION_DATE

				and EXISTS (								
								SELECT *						
								FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
								USER_PROFILE UP	WITH (NOLOCK)					
								WHERE FUA.FACILITY_ID = sa.FACILITY_ID						
								AND fua.user_profile_id = up.user_profile_id						
								AND UP.IS_ACTIVE = 'Y'						
								and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
								AND FUA.USER_PROFILE_ID = @ReportUser						
							)
				)

)t1

END;



--New

-- Purpose: During Visionary Conversion, facilities were being coded by multiple Vendors.
-- this is to limit Vendor's from seeing Coders that are not theirs.

IF @m_ReportUserClass = 5
BEGIN



if object_ID('TempDB..#ReportUSerGroup', 'U') is not null DROP TABLE #ReportUSerGroup;

select t4.USER_GROUP_ID
into #ReportUSerGroup
from
(
SELECT USER_GROUP_ID 
FROM USER_PROFILE				
WHERE USER_PROFILE_ID = @ReportUser				
	AND USER_CLASS_CD = 5
	AND is_active = 'Y'			
				
UNION				
				
SELECT ugup.USER_GROUP_ID			
FROM USER_GROUP_TO_USER_PROFILE ugup,				
user_profile up				
where up.user_profile_id = ugup.user_profile_id				
AND up.is_active = 'Y'				
AND up.USER_CLASS_CD = 5				
AND ugup.USER_PROFILE_ID = @ReportUser				
)t4






if object_ID('TempDB..#NameCheck1', 'U') is not null DROP TABLE #NameCheck1;
if object_ID('TempDB..#NameCheck2', 'U') is not null DROP TABLE #NameCheck2;
if object_ID('TempDB..#NameCheck3', 'U') is not null DROP TABLE #NameCheck3;

select
user_profile_id
into #NameCheck1
from
(
select assigned_to_id as user_profile_id  from #ChartSubset
union
select completed_by_user_profile_id as user_profile_id from #ChartSubset
union
select approved_by_user_profile_id as user_profile_id from #ChartSubset
)t2;



select 
t3.user_profile_id,
t3.USER_GROUP_ID
into #NameCheck2
from
		(
		SELECT 
		n.user_profile_id ,
		USER_GROUP_ID 
		FROM 
		#NameCheck1 n,
		USER_PROFILE up				
		WHERE 
        up.USER_PROFILE_ID = n.USER_PROFILE_ID
		AND up.USER_CLASS_CD = 5
		AND up.is_active = 'Y'			
				
		UNION				
				
		SELECT 
		n.user_profile_id ,
		ugup.USER_GROUP_ID			
		FROM 
		#NameCheck1 n,
		USER_GROUP_TO_USER_PROFILE ugup,				
		user_profile up				
		where up.user_profile_id = ugup.user_profile_id				
		AND up.is_active = 'Y'				
		AND up.USER_CLASS_CD = 5				
		AND ugup.USER_PROFILE_ID = n.USER_PROFILE_ID
		)t3;


	  select
	  c2.USER_PROFILE_ID, 
	  case when rug.user_group_id = 203 and c2.user_group_id = 201 then 'Y'
		   when rug.user_group_id = 203 and c2.user_group_id = 202 then 'Y'
	       when rug.user_group_id = 203 and c2.user_group_id = 203 then 'Y'

		   when rug.user_group_id = 136 and c2.user_group_id = 125 then 'Y'
		   when rug.user_group_id = 136 and c2.user_group_id = 130 then 'Y'
		   when rug.user_group_id = 136 and c2.user_group_id = 136 then 'Y'

		   when rug.user_group_id = 166 and c2.user_group_id = 164 then 'Y'
		   when rug.user_group_id = 166 and c2.user_group_id = 165 then 'Y'
		   when rug.user_group_id = 166 and c2.user_group_id = 166 then 'Y'

		   when rug.user_group_id = 185 and c2.user_group_id = 183 then 'Y'
		   when rug.user_group_id = 185 and c2.user_group_id = 184 then 'Y'
		   when rug.user_group_id = 185 and c2.user_group_id = 185 then 'Y'

	  else 'N' end as Name_Check
	  into #NameCheck3
      from
      #ReportUSerGroup rug,
      #NameCheck2 c2




 update t								
set 								
	t.assigned_to_id = ''								
from								
	#ChartSubset as t							
	join #NameCheck3 as c3 with(NOLOCK) on t.assigned_to_id = c3.USER_PROFILE_ID
	where c3.Name_Check = 'N'; 


update t								
set 								
	t.completed_by_user_profile_id = ''								
from								
	#ChartSubset as t							
	join #NameCheck3 as c3 with(NOLOCK) on t.completed_by_user_profile_id = c3.USER_PROFILE_ID
	where c3.Name_Check = 'N'; 

								
update t								
set 								
	t.approved_by_user_profile_id = ''								
from								
	#ChartSubset as t							
	join #NameCheck3 as c3 with(NOLOCK) on t.approved_by_user_profile_id = c3.USER_PROFILE_ID
	where c3.Name_Check = 'N'; 





END;

*/
--------------------------------------------------------------------------------
-- replacement section for LOG_NOTE section below: dsexton, 8/18/2020
	select ln.log_note_ID, ln.chart_ID, ln.Completion_Date
	  into #LogNote_Cat5
	FROM LOG_NOTE ln WITH (NOLOCK)
		JOIN #ChartSubset as c on ln.chart_ID = c.chart_ID
	WHERE LN.CATEGORY_ID = 5


	select ln.log_note_ID, ln.chart_ID, ln.Completion_Date
	  into #LogNote_Cat8
	FROM LOG_NOTE ln WITH (NOLOCK)
		JOIN #ChartSubset as c on ln.chart_ID = c.chart_ID
	WHERE LN.CATEGORY_ID = 8

delete 
from #LogNote_Cat5
from #LogNote_Cat5 as t join Log_Note as ln on t.log_note_id = ln.log_note_ID
where ln.Detail not like 'Chart status moved to work in progress.  Previous status was Pending%'
 and  ln.Detail not like 'Chart status moved to work in progress.  Previous status was Bypassed%'  -- Added per JIRA-RACS-2156 09/12/2022 Don Hutton.
 and  ln.Detail not like 'Chart status moved to work in progress.  Previous status was Removed%'   -- Added per JIRA RAP-114 01/23/24 Don Hutton.

delete
from #LogNote_Cat8
from #LogNote_Cat8 as t join Log_Note as ln on t.log_note_id = ln.log_note_ID
where ln.Detail not like 'Chart status changed to Work in Progress%%'
	and ln.Summary not like 'Chart status changed to Work in Progress%'


SELECT Chart_ID, Completion_Date = MAX(COMPLETION_DATE)
	into #LogNote
FROM
(
	Select chart_ID, completion_date
	FROM #LogNote_Cat5

	UNION

	Select chart_ID, completion_date
	FROM #LogNote_Cat8 
) as x
GROUP BY chart_ID
;
-------------------------------------------------------------------------------------


/*  -- replaced this section with section above: dsexton, 8/18/2020
SELECT Chart_ID, Completion_Date = MAX(COMPLETION_DATE)
	into #LogNote
FROM
(
	Select c.chart_ID, ln.completion_date
	FROM LOG_NOTE ln WITH (NOLOCK)
		JOIN #ChartSubset as c on ln.chart_ID = c.chart_ID
	WHERE
		LN.CATEGORY_ID = 5
		AND LN.DETAIL LIKE 'Chart status moved to work in progress.  Previous status was Pending%'

	UNION

	Select c.chart_ID, ln.completion_date
	FROM LOG_NOTE ln WITH (NOLOCK)
		JOIN #ChartSubset as c on ln.chart_ID = c.chart_ID
	WHERE
			LN.CATEGORY_ID = 8
			AND (
				LN.SUMMARY LIKE 'Chart status changed to Work in Progress%'
				OR LN.DETAIL LIKE 'Chart status changed to Work in Progress%'
				)
) as x
GROUP BY chart_ID
;
*/


  with ChartTurnaroundAging
  as (
	  select case 
			  when samt.USER_PROFILE_ID is null
				  then '--Not Set--'
			  else am.LAST_NAME + ', ' + am.FIRST_NAME
			  end 'Account Mgr',
		  samt.USER_PROFILE_ID MGR_ID,
		  f.[NAME] Facility,
		  c.FACILITY_ID,
		  t.DESCRIPTION + ' '+ cast(@m_HoursElapsed as varchar) +' Reporting Basis' as 'Reporting Basis', 
		  c.CHART_ID, 
		  c.FACILITY_CHART_ID as Chart_Identifier,
		  c.TIME_OF_SERVICE TOS,
		  c.CREATION_DATE_TIME 'File Created',
		  case 
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (1,2)
				  then c.DATE_RECEIVED
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (3,4)
				  then c.CREATION_DATE_TIME
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD = 5
				  then dateadd(minute, sa.TURNAROUND_START_TIME_IN_MINUTES, dateadd(dd, datediff(dd, 0, c.CREATION_DATE_TIME), 0))
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (6,7)
				  then isnull((
							  select max(ln.COMPLETION_DATE)
							  --FROM LOG_NOTE ln WITH (NOLOCK)
							  from #LogNote as ln
							  where ln.CHART_ID = c.CHART_ID
							  ), c.CREATION_DATE_TIME)
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (8,9)
				  then (
						  select max(CREATION_DATE_TIME)
						  from vwImportImage with (nolock)		-- view performs OK 4/14/2017
						  where CHART_ID = c.CHART_ID
						  )
			  end 'Clock Started',
		  cs.DESCRIPTION STATUS,

		  --case when @m_ReportUserClass = 5 and at.user_class_cd <> 5 then ''
		  -- else at.LAST_NAME + ', ' + at.FIRST_NAME end as 'Assigned To',

		  at.LAST_NAME + ', ' + at.FIRST_NAME as 'Assigned To',
          
		  c.COMPLETION_DATE Completed,

		  --case when @m_ReportUserClass = 5 and cb.user_class_cd <> 5 then ''
		  --else cb.LAST_NAME + ', ' + cb.FIRST_NAME end as 'Completed By',
		  cb.LAST_NAME + ', ' + cb.FIRST_NAME as 'Completed By',
		  
		  c.APPROVED_DATE Approved,

		  --case when @m_ReportUserClass = 5 and ab.user_class_cd <> 5 then ''
		  --else ab.LAST_NAME + ', ' + ab.FIRST_NAME end as 'Approved By',
		  ab.LAST_NAME + ', ' + ab.FIRST_NAME as 'Approved By',
		  
		  case 
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (1,2)
				  then datediff(minute, c.DATE_RECEIVED, getdate()) / 60
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (3,4)
				  then datediff(minute, c.CREATION_DATE_TIME, getdate()) / 60
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD = 5
				  then datediff(minute, dateadd(minute, sa.TURNAROUND_START_TIME_IN_MINUTES, dateadd(dd, datediff(dd, 0, c.CREATION_DATE_TIME), 0)), getdate()) / 60
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (6,7)
				  then datediff(minute, isnull((
								  select max(ln.COMPLETION_DATE)
								  --FROM LOG_NOTE ln WITH (NOLOCK)
								  from #LogNote as ln
								  where ln.CHART_ID = c.CHART_ID
								  ), c.CREATION_DATE_TIME), getdate()) / 60
			  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (8,9)
				  then datediff(minute, (
							  select max(CREATION_DATE_TIME)
							  from vwImportImage with (nolock)		-- view performs OK  4/14/2017
							  where CHART_ID = c.CHART_ID
							  ), getdate()) / 60
			  end 'Hours Elapsed',
		  (
			  select min(sla.SLA_DIFFERENTIAL_HOURS)
			  from SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE sla with (nolock)
			  where sla.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				  and getdate() between sla.EFFECTIVE_DATE
					  and sla.EXPIRATION_DATE
			  ) 'SLA Allowance',
		  pr.DESCRIPTION 'Pending Reason',
		  c.CODER_COMMENT 'Coder Comments',
      ltrim(rtrim(coalesce(stuff((
				select ',' + cpy.[NAME] 
				from [dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla with (nolock)
        inner join [dbo].[SERVICE_LOCATION] sl with (nolock) on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
				inner join [dbo].[COMPANY] cpy with (nolock) on cpy.COMPANY_ID = sl.COMPANY_ID
				where SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
					and getdate() between EFFECTIVE_DATE and EXPIRATION_DATE
				order by cpy.[NAME]
				for xml path('')
				), 1, 1, ''), 'N/A'))) Vendor,
		case when sa.[RCP_BILLING_IND] = 1 then 'Billing'
				when sa.[SERVICE_MODEL_CD] = 'ASP' then 'Software as a Service (SaaS)'
			else 'Full Service' end [Service],
			pd.description as Patient_Disposition,
			pc.description as Patient_Class
	  from 
	  --CHART c WITH (NOLOCK)  -- replaced below with #ChartSubset for tuning 4/14/2017
	  #ChartSubset as c
	    inner join SERVICE_AGREEMENT sa with (nolock) 
        on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
	    left join SERVICE_AGREEMENT_MANAGEMENT_TEAM samt with (nolock) 
        on samt.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
			    and samt.MANAGEMENT_TEAM_ROLE_ID = 1
	    inner join TURNAROUND_HOURS_REPORTING_METHOD t with (nolock)
		    on t.TURNAROUND_HOURS_REPORTING_METHOD = sa.TURNAROUND_HOURS_REPORTING_METHOD
	    left join USER_PROFILE am with (nolock)
		    on samt.USER_PROFILE_ID = am.USER_PROFILE_ID
	    inner join FACILITY f with (nolock)
		    on c.FACILITY_ID = f.FACILITY_ID
	    inner join dbo.CHART_STATUS cs with (nolock)
		    on cs.CHART_STATUS_ID = c.CHART_STATUS_ID
	    left join USER_PROFILE at with (nolock)
		    on c.ASSIGNED_TO_ID = at.USER_PROFILE_ID
	    left join USER_PROFILE cb with (nolock)
		    on c.COMPLETED_BY_USER_PROFILE_ID = cb.USER_PROFILE_ID
	    left join USER_PROFILE ab with (nolock)
		    on c.APPROVED_BY_USER_PROFILE_ID = ab.USER_PROFILE_ID
	    left join PENDING_REASON pr
		    on c.PENDING_REASON_ID = pr.PENDING_REASON_ID
        inner join PATIENT_DISPOSITION pd
		    on c.patient_disposition_id = pd.patient_disposition_id
        left join PATIENT_CLASS pc
            on c.patient_class_id = pc.patient_class_id
	  where sa.DEMO_TEST_SITE_IND <> 1
	  and (c.CHART_STATUS_ID = @m_ChartStatus
	       or -1 = @m_ChartStatus )
      and sa.EXPIRATION_DATE > getdate() -- 3-20-2015 DanielB: Ignore expired accounts
		  and (
			  (
				  sa.TURNAROUND_HOURS_REPORTING_METHOD in (1,2,6,7,8,9)
				  and c.CHART_STATUS_ID in (1,3) -- Work in Progress and Completed only
				  and datediff(minute, case 
						  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (1,2)
							  then c.DATE_RECEIVED
						  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (6,7)
							  then isnull((
										  select max(ln.COMPLETION_DATE)		
										  --FROM LOG_NOTE WITH (NOLOCK)
										  from #LogNote as ln
										  where ln.CHART_ID = c.CHART_ID
										  ), c.CREATION_DATE_TIME)
						  else (
								  select max(CREATION_DATE_TIME)
								  from vwImportImage with (nolock)		-- view performs OK  4/14/2017
								  where CHART_ID = c.CHART_ID
								  )
						  end, getdate()) / 60 >= @m_HoursElapsed
				  )
			  or (
				  sa.TURNAROUND_HOURS_REPORTING_METHOD in (3,4)
				  and c.CHART_STATUS_ID in (1,3,4) -- Work in Progress, Completed and Approved only
				  and datediff(minute, c.CREATION_DATE_TIME, getdate()) / 60 >= @m_HoursElapsed
				  )
			  or (
				  sa.TURNAROUND_HOURS_REPORTING_METHOD = 5
				  and c.CHART_STATUS_ID in (1,3) -- Work in Progress and Completed only
				  and datediff(minute, dateadd(minute, sa.TURNAROUND_START_TIME_IN_MINUTES, dateadd(dd, datediff(dd, 0, c.CREATION_DATE_TIME), 0)), getdate()) / 60 >= @m_HoursElapsed
				  )
			  )		
		  and f.FACILITY_ID = c.FACILITY_ID
		  and cs.CHART_STATUS_ID = c.CHART_STATUS_ID

		-- additional criteria no longer needed here since it is used to populate #ChartSubset
	  )





  select c.*,
  c2.Count_0, c2.Count_1, c2.Count_2, c2.Count_3, c2.Count_4, c2.Count_5, c2.Count_6
  from ChartTurnaroundAging c
  left join #RecdCount2 c2 on 
  c.FACILITY_ID = c2.FACILITY_ID
	  



end











GO
GRANT EXECUTE ON  [dbo].[rpt_DailyAgedAccountsReport] TO [dbx_ExecuteReportProcs]
GO
