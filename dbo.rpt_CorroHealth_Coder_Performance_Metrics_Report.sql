SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO














CREATE procedure [dbo].[rpt_CorroHealth_Coder_Performance_Metrics_Report]
(
			@Facility varchar(max),
			@Organization varchar(max),
	@Coder varchar(max),
			@StartDate datetime,
			@EndDate datetime,
			@ReportUser int,
			@TimeZone varchar(30),
	@Tenure int = -1
)

as

begin


-- test parameters	 (dsexton, 5/22/2019)
		
		-- Prod version 
				-- cold buffer: duration = 05:24, reads = 38M 
				-- warm buffer: duration = 00:58, reads = 36M

		-- Tuned version
				-- cold buffer: duration = 01:28, reads = 16.6M  
				-- warm buffer: duration = 00:32, reads = 16.3M
		

/*
declare
	@Facility varchar(max) = '1122',	-- PeaceHealth - Cottage Grove Community Med Cntr	-- '916,597,596,598,595,841,1226,1224,1225',
	@Organization varchar(max) = '198',      --  '38,209',
	@Coder varchar(max) = -1,
	@StartDate datetime = '11/1/2019',
	@EndDate datetime = '11/1/2019',
	@ReportUser int = 80,
	@TimeZone VARCHAR(50) = 'Central Daylight Time',
	@Tenure int = -1


-- runtime 2:56 92 rows
*/
    set transaction isolation level read uncommitted;
    set nocount on;
	set ansi_warnings off;
	

	print 'Section: 00 ' + convert(varchar, getdate(), 121)	
	----------------------------------------------------------------------------------------------------
		
	
	--Reassign parameters, default parameter values

	declare
        @m_Facility              varchar(max) = @Facility
        ,@m_Organization         varchar(max) = @Organization
        ,@m_ChartAccessEventType varchar(10)  = 'C'			--@ChartAccessEventType
        ,@m_Coder				 varchar(max) = @Coder
        ,@m_StartDate            datetime     = @StartDate
        ,@m_EndDate              datetime     = @EndDate
        ,@m_DateGrouping         int          = 1			--@DateGrouping
        ,@m_ReportUser           int          = @ReportUser
        ,@m_Disposition          varchar(max) = '99,4,5'	--@Disposition;
		,@m_TimeZone			varchar(30) = @TimeZone


	/* TIME ZONE */
	declare @CTOffSet VARCHAR(9) = (select CT_OFFSET from TIME_ZONE where DESCRIPTION=@TimeZone);
	declare @Operator varchar(1) = substring(@CTOffSet, 1, 1);
	declare @hms varchar(8) = substring(@CTOffSet, 2, LEN(@CTOffSet)-1) 
	declare @hours decimal(10,2) = datepart(hour, @hms)
	declare @minutes decimal(10,2) = datepart(minute, @hms)
	declare @HrsOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(hour, @hms)) as decimal(10,2))
	declare @MinOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(minute, @hms)) as decimal(10,2))


	/*
	-- RAP-330 4/11/24 DAH
	-- Do not think this section of code is needed, spoke with Jay he thought is was used when this query was embedded in the rdl file.
	-- This facility_check section seems to be cutting off Facility ID's being loaded into the #Facility temp table when -1 is used as  @Organization parameter.

	declare @facility_check varchar(max)
	if @m_Facility = '-1'
	begin

		select @facility_check = coalesce(@facility_check,'') + convert(varchar,x.FACILITY_ID) + ','
		from 
		(select distinct f.FACILITY_ID
		from 
			FACILITY f
			,SERVICE_AGREEMENT sa
			,COMPANY c
		where 
			f.FACILITY_ID = sa.FACILITY_ID
			and sa.COMPANY_ID = c.COMPANY_ID
			and (sa.COMPANY_ID in (select items from dbo.SplitString(@m_Organization,',')) or @m_Organization = '-1')
		) x

		set @m_Facility = @facility_check

	end

	*/

	----------------------------------------------------------------------------------------------------

	if object_id('TempDB..#calendar', 'U') is not null begin drop table #calendar; end;
	if object_id('TempDB..#Facility', 'U') is not null begin drop table #Facility; end;
    if object_id('TempDB..#User', 'U') is not null begin drop table #User; end;

	if object_id('TempDB..#CoderProductivitySummarybyTimetoEnter', 'U') is not null begin drop table #CoderProductivitySummarybyTimetoEnter; end;
	if object_id('TempDB..#FacilityAverageChartsPerHour_data', 'U') is not null begin drop table #FacilityAverageChartsPerHour_data; end;
	if object_id('TempDB..#FacilityAverageChartsPerHour', 'U') is not null begin drop table #FacilityAverageChartsPerHour; end;
	if object_id('TempDB..#FacilityAverageChartsPerHour_byCoder', 'U') is not null begin drop table #FacilityAverageChartsPerHour_byCoder; end;

	if object_id('TempDB..#PrelimResults', 'U') is not null begin drop table #PrelimResults; end;
	if object_id('TempDB..#Facility1', 'U') is not null begin drop table #Facility1; end;
	if object_id('TempDB..#ACSUserLogin', 'U') is not null begin drop table #ACSUserLogin; end;

	
	if object_id('TempDB..#CoderQATrending', 'U') is not null begin drop table #CoderQATrending; end;
--	if object_id('TempDB..#CoderScorecard', 'U') is not null begin drop table #CoderScorecard; end;    -- Is this still needed  ?????

	if object_id('TempDB..#USER_SESSION', 'U') is not null begin drop table #USER_SESSION; end;

	if object_id('TempDB..#StartTimes', 'U') is not null drop table #StartTimes;
	if object_id('TempDB..#EndTimes', 'U') is not null drop table #EndTimes;
	if object_id('TempDB..#SessionGroups', 'U') is not null drop table #SessionGroups;
	if object_id('TempDB..#ChartsCompleted', 'U') is not null drop table #ChartsCompleted;
	if object_id('TempDB..#ChartsApproved', 'U') is not null drop table #ChartsApproved;
	if object_id('TempDB..#Totals', 'U') is not null drop table #Totals;

	if object_id('TempDB..#ChartAccess', 'U') is not null drop table #ChartAccess;

	if object_id('TempDB..#first_comp_date', 'U') is not null drop table #first_comp_date;
	if object_id('TempDB..#FINAL', 'U') is not null drop table #FINAL; 
	
	
	----------------------------------------------------------------------------------------------------
	-- Build calendar table on the fly using @StartDate and @EndDate
	
	create table #calendar ([Date] datetime)
	insert into #calendar select @m_StartDate

	declare @maxDate datetime

	--while not exists (select * from #calendar where [Date] = @EndDate)	-- this line was causing ReportBuilder to hang since it validates by executing the proc with NULL parameters
	while exists (select * from #calendar where @EndDate > (select max([Date]) from #calendar))
	begin
		
		set @maxDate = (select max([Date]) from #calendar)

		insert into #calendar
		select dateadd(dd,1,@maxDate)

	end
	
	
	----------------------------------------------------------------------------------------------------
	-- Build Coder Scorecard temp table to populate with data results from existing stored procedure


-- Replace CoderScorecard section with new CorroHealth_Coder_Performance_Metrics / Coder QA Trending
-- Create Temp and populate with Stored Procedure  -- rpt_CorroHealth_Coder_Performance_Metrics


create table #CoderQATrending
	(
	[User_Profile_ID]	[int] null,
	[Facility_ID]		[int] null,
	[Date]				[Date] null,
	[TotalCharts]		[int] null,
	[TotalAudits]		[int] null,
	[CoderAccuracy_N]	[int] null,
	[CoderAccuracy_D]	[int] null
	)

	print 'Section: 01 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- Begin "Coder Productivity Summary by Time to Enter without Exclusions" report code as of June 2018

	select *
    into #Facility
    from
        (
        select distinct
				c.COMPANY_ID
				,c.[NAME] [ORGANIZATION]
				,sa.FACILITY_ID
				,f.[NAME] [FACILITY]
        from
            SERVICE_AGREEMENT sa
            ,FACILITY f
			,COMPANY c
        where
			sa.COMPANY_ID = c.COMPANY_ID
            and f.FACILITY_ID = sa.FACILITY_ID and sa.DEMO_TEST_SITE_IND = 0
            --and getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE -- jherrera ACS-14263
			and exists
            (
            select
                *
            from
                [dbo].SplitString(@m_Organization, ',')
            where
                items = sa.COMPANY_ID
            union
            select
                *
            from
                [dbo].SplitString(@m_Organization, ',')
            where
                items = -1
            )
            and exists
            (
            select
                *
            from
                FACILITY_USER_AUTHORIZATION FUA with
                (nolock)
                ,USER_PROFILE UP with
                (nolock)
            where
                FUA.FACILITY_ID = f.FACILITY_ID and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID and UP.IS_ACTIVE = 'Y'
                and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
                and FUA.USER_PROFILE_ID = @m_ReportUser and exists
                (
                select
                    *
                from
                    [dbo].SplitString(@m_Facility, ',')
                where
                    items = sa.FACILITY_ID
                union
                select
                    *
                from
                    [dbo].SplitString(@m_Facility, ',')
                where
                    items = -1
                )
            )
        ) t1;
	
	
	print 'Section: 02 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
-- performance edit BEGIN (dsexton, 5/22/2019)
	-- As suggested in the 4/10/2019 tuning version, populate #ChartAccess here instead of Section #4 so that #ChartAccessUsers can be used in Section #2 for a big improvement in performance (especially with large date ranges)		(dsexton, 5/22/2019)
	if object_id('TempDB..#ChartAccess', 'U') is not null begin drop table #ChartAccess; end;
	select c.facility_ID, ca.*
	into #ChartAccess
	from 
		chart as c with(nolock) 
		join 
		chart_Access as ca with(nolock) 
			on c.chart_ID = ca.chart_ID
	where 
		--cast(ca.EVENT_COMPLETION_DATE_TIME as date) 
		dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, ca.EVENT_COMPLETION_DATE_TIME))), 0) between @m_StartDate and dateadd(second,86399,@m_EndDate)
		and c.Facility_ID in (Select Facility_ID from #Facility)

	create index ix_TChartAccess_ChartID on #ChartAccess (Chart_ID, User_Profile_ID, Chart_Access_Event_Type_Code) INCLUDE (Chart_Access_ID, Event_Completion_Date_Time, Secondary_Event_Completion_Date_Time, Access_Date_Time)
	create index ix_TChartAccess_UserProfileID on #ChartAccess (User_Profile_ID)

	if object_id('TempDB..#ChartAccessUsers', 'U') is not null begin drop table #ChartAccessUsers; end;
	select distinct ca.User_Profile_ID
	into #ChartAccessUsers
	from 
		chart as c with(nolock) 
		join #ChartAccess as ca on c.chart_ID = ca.Chart_ID
	where 
		c.CHART_STATUS_ID in (3, 4, 5)
		and c.Facility_ID in (Select Facility_ID from #Facility)
-- performance edit END (dsexton, 5/22/2019) 


    select
        *
    into
        #User
    from
        (
        select
            USER_PROFILE.USER_PROFILE_ID
        from
            USER_PROFILE with
            (nolock)
        where
            exists
            (
            select * from [dbo].SplitString(@m_Coder, ',') where items = -1
            ) and USER_PROFILE.USER_PROFILE_ID not in (2, 5, 80) and USER_PROFILE.USER_CLASS_CD in (1,5) 
			and exists
            (
            select * from #Facility where FACILITY_ID = #Facility.FACILITY_ID
            )
            and exists

-- performance edit BEGIN (dsexton, 5/22/2019)
	-- As suggested in 4/10/2019 tuning version, using #ChartAccessUsers here reduces reads to 1M vs 16M, and duration to 2 secs vs 12 secs for Section #2 (warm buffer)  (dsexton, 5/22/2019)
			(select 1 from #ChartAccessUsers where User_Profile_ID = User_Profile.User_Profile_ID)	-- performance edit (dsexton, 5/22/2019) 
	/*
            (
            select
                *
            from
                CHART_ACCESS with
                (nolock)
                inner join CHART with
                (nolock) on CHART.CHART_ID = CHART_ACCESS.CHART_ID
            where
                CHART_ACCESS.USER_PROFILE_ID = USER_PROFILE.USER_PROFILE_ID and exists
                (
                select * from #Facility where CHART.FACILITY_ID = #Facility.FACILITY_ID
                ) and CHART_STATUS_ID in (3, 4, 5)
                and cast(EVENT_COMPLETION_DATE_TIME as date) between @m_StartDate and @m_EndDate
            )
	*/
-- performance edit END (dsexton, 5/22/2019) 

        union
        select
            USER_PROFILE_ID
        from
            USER_PROFILE
        where
            exists
            (
            select
                *
            from
                [dbo].SplitString(@m_Coder, ',')
            where
                items = USER_PROFILE_ID
            ) and USER_PROFILE_ID <> -1
        ) t2;


	
	print 'Section: 03 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	--;with Details
    --as
    --(

	-- using temp table instead of CTE here reduces duration by 5 secs (warm buffer) and reduces reads by 400K  (dsexton, 5/22/2019)

	if object_id('TempDB..#Details', 'U') is not null DROP TABLE #Details;		--(dsexton, 5/22/2019)

		select
         ce.CHART_ACCESS_EVENT_TYPE_DESC [Event]
         ,f.NAME as Facility
         ,up.LAST_NAME + ', ' + up.FIRST_NAME UserName
         ,case @m_DateGrouping
              when 0 then dateadd(month, datediff(month, 0, ca.EVENT_COMPLETION_DATE_TIME), 0)
              else dateadd(day, datediff(day, 0, ca.EVENT_COMPLETION_DATE_TIME), 0)end CompletionDate
         ,(sum(   case
                      when datediff(second, ca.ACCESS_DATE_TIME, ca2.EVENT_COMPLETION_DATE_TIME) > 3600 then null
                      else datediff(second, ca.ACCESS_DATE_TIME, ca2.EVENT_COMPLETION_DATE_TIME)end
              ) * 1.0
          ) / 60.0 ElapsedTime
         ,count(*) ChartsIncluded
         ,f.FACILITY_ID FacilityID
         ,up.USER_PROFILE_ID UserProfileID
         ,ca.CHART_ACCESS_EVENT_TYPE_CODE ChartAccessEventType
         ,case
              when c.PATIENT_DISPOSITION_ID = 4 then 'Inpatient'
              when c.PATIENT_DISPOSITION_ID = 5 then 'Observation'
              when c.PATIENT_DISPOSITION_ID >= 1 then 'ER'
              else 'Unknown' end as Disposition

 into #Details		-- (dsexton, 5/22/2019)

     from
         CHART_ACCESS ca 
		 --#ChartAccess as ca		-- verified that using #ChartAccess here does not help performance (dsexton, 5/22/2019)
         ,CHART_ACCESS ca2 
         ,CHART_ACCESS_EVENT_TYPE ce 
         ,CHART c 
         ,FACILITY f 
         ,USER_PROFILE up 
     where
         ca.CHART_ACCESS_EVENT_TYPE_CODE = ce.CHART_ACCESS_EVENT_TYPE_CODE
         --and dateadd(day, datediff(day, 0, ca.EVENT_COMPLETION_DATE_TIME), 0) 
		 and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, dateadd(day, datediff(day, 0, ca.EVENT_COMPLETION_DATE_TIME), 0)))), 0) between @m_StartDate and dateadd(second,86399,@m_EndDate)
         and c.CHART_ID = ca.CHART_ID and c.FACILITY_ID = f.FACILITY_ID and ca.USER_PROFILE_ID = up.USER_PROFILE_ID
         and ca2.CHART_ACCESS_ID = ca.CHART_ACCESS_ID
         and c.PATIENT_DISPOSITION_ID in
                 (
                 select
                     PATIENT_DISPOSITION_ID
                 from
                     PATIENT_DISPOSITION
                 where
                     PATIENT_DISPOSITION_ID in (4, 5) and PATIENT_DISPOSITION_ID in
                                                              (
                                                              select * from SplitString(@m_Disposition, ',')
                                                              )
                 union
                 select
                     PATIENT_DISPOSITION_ID
                 from
                     PATIENT_DISPOSITION
                 where
                     PATIENT_DISPOSITION_ID not in (4, 5) and 99 in
                                                                  (
                                                                  select * from SplitString(@m_Disposition, ',')
                                                                  )
                 )
         and ca2.CHART_ACCESS_ID =
             (
             select
                 max(ca3.CHART_ACCESS_ID)
             from
                 CHART_ACCESS ca3 
             where
                 ca3.CHART_ACCESS_EVENT_TYPE_CODE = ca.CHART_ACCESS_EVENT_TYPE_CODE 
				 and ca3.CHART_ID = ca.CHART_ID
              --   and ca3.USER_PROFILE_ID = ca.USER_PROFILE_ID  -- AAR-1279 to get max id per chart, not chart, coder
             ) 
		
		 and ca.EVENT_COMPLETION_DATE_TIME is not null
         and ca.CHART_ACCESS_EVENT_TYPE_CODE in
                 (
                 select items from [dbo].SplitString(@m_ChartAccessEventType, ',')
                 ) 
		 --and
			--(
			--	(
			--	ca.CHART_ACCESS_EVENT_TYPE_CODE = 'A' and ca.SECONDARY_EVENT_COMPLETION_DATE_TIME is null
			--	) or (ca.CHART_ACCESS_EVENT_TYPE_CODE = 'C') --and ca.SECONDARY_EVENT_COMPLETION_DATE_TIME is not null)
			--)
		 and exists
         (
         select * from #Facility where f.FACILITY_ID = #Facility.FACILITY_ID
         ) 
		 and exists
         (
         select * from #User where ca.USER_PROFILE_ID = #User.USER_PROFILE_ID
         )
     group by
         ce.CHART_ACCESS_EVENT_TYPE_DESC
         ,up.USER_PROFILE_ID
         ,up.LAST_NAME + ', ' + up.FIRST_NAME
         ,f.FACILITY_ID
         ,f.NAME
         ,case @m_DateGrouping
              when 0 then dateadd(month, datediff(month, 0, ca.EVENT_COMPLETION_DATE_TIME), 0)
              else dateadd(day, datediff(day, 0, ca.EVENT_COMPLETION_DATE_TIME), 0)end
         ,ca.CHART_ACCESS_EVENT_TYPE_CODE
         ,case
              when c.PATIENT_DISPOSITION_ID = 4 then 'Inpatient'
              when c.PATIENT_DISPOSITION_ID = 5 then 'Observation'
              when c.PATIENT_DISPOSITION_ID >= 1 then 'ER'
              else 'Unknown' end
	--)

    select
		f.COMPANY_ID [ORG_ID]
		,f.ORGANIZATION
        ,d.[Event]
		,d.FacilityID
        ,d.Facility
		,d.UserProfileID
        ,d.UserName
        ,d.CompletionDate
        ,d.ElapsedTime
        ,d.ChartsIncluded
        ,d.ChartAccessEventType
        ,d.Disposition
		,row_number()over(partition by d.[Event], d.UserName, d.Facility, d.CompletionDate order by d.Disposition) [RowId]

		--,row_number()over(partition by d.[Event], f.COMPANY_ID, d.UserName order by d.CompletionDate) [OverallRowId]		-- (dsexton, 5/22/2019)
		,row_number()over(partition by d.[Event], f.COMPANY_ID, d.UserName order by d.CompletionDate, FacilityID, Disposition) [OverallRowId]		-- (dsexton, 5/22/2019)
			-- Added FacilityID and Disposition to ORDER BY because of a small number of mismatched rows in validation due to ordering issues.  Not critical to performance or ultimate accuracy, but recommended to facilitate easier validation  (dsexton, 5/22/2019)

	into #CoderProductivitySummarybyTimetoEnter
    from
       -- Details d		-- (dsexton, 5/22/2019)
 #Details as d			-- (dsexton, 5/22/2019)
		inner join #Facility f on d.Facility = f.FACILITY
    --order by
    --    [Event]
    --    ,UserName
    --    ,Facility
    --    ,CompletionDate;
	

	print 'Section: 04 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- Beging "Facility Average Charts Per Hour" code as of June 2018. 
	-- Code is referenced twice below, once for entire Facility and once for coder. 

	-- moved the population of #ChartAccess to section #2 for performance improvement	(dsexton, 5/22/2019)
/*
	select
		c.FACILITY_ID
		,ca.CHART_ACCESS_ID
		,ca.USER_PROFILE_ID
		,ca.CHART_ID
		,ca.ACCESS_DATE_TIME
		,ca.CHART_ACCESS_EVENT_TYPE_CODE
		,ca.EVENT_COMPLETION_DATE_TIME
		,ca.CHART_ACCESS_SECONDARY_EVENT_TYPE_CODE
		,ca.SECONDARY_EVENT_COMPLETION_DATE_TIME
	into #ChartAccess
	from
		CHART as c 
		inner join #Facility f on c.FACILITY_ID = f.FACILITY_ID
		inner join CHART_ACCESS as ca  on c.CHART_ID = ca.CHART_ID
	where
		ca.EVENT_COMPLETION_DATE_TIME between @m_StartDate and dateadd(second, 86399, @m_EndDate);

	create index ix_TChartAccess_ChartID on #ChartAccess (Chart_ID, User_Profile_ID, Chart_Access_Event_Type_Code) INCLUDE (Chart_Access_ID, Event_Completion_Date_Time, Secondary_Event_Completion_Date_Time, Access_Date_Time)
	create index ix_TChartAccess_UserProfileID on #ChartAccess (User_Profile_ID)
*/

	print 'Section: 05 ' + convert(varchar, getdate(), 121)


	select distinct
		   f.COMPANY_ID [ORG_ID]
		   ,f.ORGANIZATION
		   ,x.CHART_ACCESS_EVENT_TYPE_DESC
		   ,x.FACILITY_ID
		   ,x.Facility
		   ,x.USER_PROFILE_ID
		   ,x.UserName
		   ,x.CHART_ID
		   ,x.ElapsedTime
		   --,cast(round(count(CHART_ID) * 1.00 / sum(   case
					--									   when ElapsedTime > 3600 then null
					--									   else (ElapsedTime * 1.00 / 3600) end
					--							   )
					--   ,2
					--  ) as float) as AVG_HR
	into #FacilityAverageChartsPerHour_data 
	from
		(
		select
			ce.CHART_ACCESS_EVENT_TYPE_DESC
			,fac.FACILITY_ID
			,fac.NAME as Facility
			,ca.CHART_ID
			,ca.ACCESS_DATE_TIME
			,ca.EVENT_COMPLETION_DATE_TIME
			--,(
			-- select
			--	 max(ca2.EVENT_COMPLETION_DATE_TIME)
			-- from
			--	 CHART_ACCESS ca2 with
			--	 (nolock)
			-- where
			--	 ca2.CHART_ID = ca.CHART_ID and ca.USER_PROFILE_ID = ca2.USER_PROFILE_ID
			-- ) as MaxCompletionDateTime
			,ca.CHART_ACCESS_EVENT_TYPE_CODE
			,cast(ca.EVENT_COMPLETION_DATE_TIME as date) as CompletionDate
			,cast(ca.SECONDARY_EVENT_COMPLETION_DATE_TIME as date) as DemographicsCompletionDate
			,ca.USER_PROFILE_ID
			,up.LAST_NAME + ', ' + up.FIRST_NAME as UserName			
			--,datediff(second, ca.ACCESS_DATE_TIME, ca2.EVENT_COMPLETION_DATE_TIME) as ElapsedTime
			,datediff(second, ca.ACCESS_DATE_TIME, ca.EVENT_COMPLETION_DATE_TIME) as ElapsedTime
			,datediff(second, ca.ACCESS_DATE_TIME, ca.SECONDARY_EVENT_COMPLETION_DATE_TIME) as ElapsedTimeDemographics
		from
			#ChartAccess ca
			--,CHART_ACCESS ca2
			,CHART_ACCESS_EVENT_TYPE ce 
			,FACILITY fac 
			,USER_PROFILE up 
			
		where			
			ca.CHART_ACCESS_EVENT_TYPE_CODE in (select items from dbo.SplitString(@m_ChartAccessEventType, ',')) 
			and ca.CHART_ACCESS_EVENT_TYPE_CODE = ce.CHART_ACCESS_EVENT_TYPE_CODE			
			and ca.FACILITY_ID = fac.FACILITY_ID 
			and ca.USER_PROFILE_ID = up.USER_PROFILE_ID
			and up.USER_PROFILE_ID not in (2, 5, 80) and up.IS_ACTIVE = 'Y' and up.USER_GROUP_ID <> 87
			--and ca2.CHART_ACCESS_ID =
			--	(
			--	select
			--		max(ca3.CHART_ACCESS_ID)
			--	from
			--		CHART_ACCESS ca3 with
			--		(nolock)
			--	where
			--		ca3.CHART_ACCESS_EVENT_TYPE_CODE = ca.CHART_ACCESS_EVENT_TYPE_CODE and ca3.CHART_ID = ca.CHART_ID
			--		and ca3.USER_PROFILE_ID = ca.USER_PROFILE_ID
			--	) 
			and ca.EVENT_COMPLETION_DATE_TIME is not null
			and
				(
				(
				ca.CHART_ACCESS_EVENT_TYPE_CODE = 'A' and ca.SECONDARY_EVENT_COMPLETION_DATE_TIME is null
				) or
					  (
					  ca.CHART_ACCESS_EVENT_TYPE_CODE = 'C' --and ca.SECONDARY_EVENT_COMPLETION_DATE_TIME is not null -- jherrera ACS-14263
					  ) or
							(
							ca.CHART_ACCESS_EVENT_TYPE_CODE = 'S' and ca.SECONDARY_EVENT_COMPLETION_DATE_TIME is null
							)
				)
		) x
		inner join #Facility f on x.Facility = f.FACILITY
	

	print 'Section: 06 ' + convert(varchar, getdate(), 121)


	select 
		x.[ORG_ID]
		,x.ORGANIZATION
		,x.CHART_ACCESS_EVENT_TYPE_DESC
		,x.FACILITY_ID
		,x.Facility
		,cast(round(count(distinct x.CHART_ID) * 1.00 / sum(   case
														when x.ElapsedTime > 3600 then null
														else (x.ElapsedTime * 1.00 / 3600) end
												)
					,2
					) as float) as AVG_HR
		,o.ORG_AVG_HR
	into #FacilityAverageChartsPerHour
	from 
		#FacilityAverageChartsPerHour_data x
		inner join ( select 
						ORG_ID
						,cast(round(count(distinct CHART_ID) * 1.00 / sum(   case
																		when ElapsedTime > 3600 then null
																		else (ElapsedTime * 1.00 / 3600) end
																)
									,2
									) as float) as ORG_AVG_HR
					  from #FacilityAverageChartsPerHour_data
					  group by ORG_ID
					) o on x.ORG_ID = o.ORG_ID
	group by 
		x.ORG_ID
		,x.ORGANIZATION
		,x.CHART_ACCESS_EVENT_TYPE_DESC
		,x.FACILITY_ID
		,x.Facility
		,o.ORG_AVG_HR


	print 'Section: 07 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	select distinct
		   f.COMPANY_ID [ORG_ID]
		   ,f.ORGANIZATION
		   ,x.CHART_ACCESS_EVENT_TYPE_DESC
		   ,x.FACILITY_ID
		   ,x.Facility
		   ,x.USER_PROFILE_ID
		   ,x.UserName
		   ,cast(round(count(distinct CHART_ID) * 1.00 / sum(   case
														   when ElapsedTime > 3600 then null
														   else (ElapsedTime * 1.00 / 3600) end
												   )
					   ,2
					  ) as float) as AVG_HR
	into #FacilityAverageChartsPerHour_byCoder
	from 
		#FacilityAverageChartsPerHour_data x
	--from
	--	(
	--	select
	--		ce.CHART_ACCESS_EVENT_TYPE_DESC
	--		,fac.FACILITY_ID
	--		,fac.NAME as Facility
	--		,ca.CHART_ID
	--		,ca.ACCESS_DATE_TIME
	--		,ca.EVENT_COMPLETION_DATE_TIME
	--		,(
	--		 select
	--			 max(ca2.EVENT_COMPLETION_DATE_TIME)
	--		 from
	--			 CHART_ACCESS ca2 with
	--			 (nolock)
	--		 where
	--			 ca2.CHART_ID = ca.CHART_ID and ca.USER_PROFILE_ID = ca2.USER_PROFILE_ID
	--		 ) as MaxCompletionDateTime
	--		,ca.CHART_ACCESS_EVENT_TYPE_CODE
	--		,cast(ca.EVENT_COMPLETION_DATE_TIME as date) as CompletionDate
	--		,cast(ca.SECONDARY_EVENT_COMPLETION_DATE_TIME as date) as DemographicsCompletionDate
	--		,ca.USER_PROFILE_ID
	--		,up.LAST_NAME + ', ' + up.FIRST_NAME as UserName
	--		,c.FACILITY_CHART_ID
	--		,c.PATIENT_DISPOSITION_ID
	--		,pd.DESCRIPTION as PatientDisposition
	--		,datediff(second, ca.ACCESS_DATE_TIME, ca2.EVENT_COMPLETION_DATE_TIME) as ElapsedTime
	--		,datediff(second, ca.ACCESS_DATE_TIME, ca.SECONDARY_EVENT_COMPLETION_DATE_TIME) as ElapsedTimeDemographics
	--	from
	--		CHART_ACCESS ca
	--		,CHART_ACCESS ca2
	--		,CHART_ACCESS_EVENT_TYPE ce 
	--		,CHART c 
	--		,FACILITY fac 
	--		,USER_PROFILE up 
	--		,PATIENT_DISPOSITION pd 
	--	where
	--		(
	--		c.FACILITY_ID in
	--			(
	--			select items from dbo.SplitString(@m_Facility, ',')
	--			) or -1 in
	--					 (
	--					 select items from dbo.SplitString(@m_Facility, ',')
	--					 )
	--		)
	--		and
	--			(
	--			ca.USER_PROFILE_ID in
	--				(
	--				select items from dbo.SplitString(@m_Coder, ',')
	--				) or -1 in
	--						 (
	--						 select items from dbo.SplitString(@m_Coder, ',')
	--						 )
	--			)
	--		and ca.CHART_ACCESS_EVENT_TYPE_CODE in
	--					  (
	--					  select items from dbo.SplitString(@m_ChartAccessEventType, ',')
	--					  ) 
	--		and ca.CHART_ACCESS_EVENT_TYPE_CODE = ce.CHART_ACCESS_EVENT_TYPE_CODE
	--		and c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
	--		and convert(date, ca.EVENT_COMPLETION_DATE_TIME) between @m_StartDate and @m_EndDate
	--		and c.CHART_ID = ca.CHART_ID and c.FACILITY_ID = fac.FACILITY_ID and ca.USER_PROFILE_ID = up.USER_PROFILE_ID
	--		and up.USER_PROFILE_ID not in (2, 5, 80) and up.IS_ACTIVE = 'Y' and up.USER_GROUP_ID <> 87
	--		and ca2.CHART_ACCESS_ID =
	--			(
	--			select
	--				max(ca3.CHART_ACCESS_ID)
	--			from
	--				CHART_ACCESS ca3 with
	--				(nolock)
	--			where
	--				ca3.CHART_ACCESS_EVENT_TYPE_CODE = ca.CHART_ACCESS_EVENT_TYPE_CODE and ca3.CHART_ID = ca.CHART_ID
	--				and ca3.USER_PROFILE_ID = ca.USER_PROFILE_ID
	--			) and ca.EVENT_COMPLETION_DATE_TIME is not null
	--		and
	--			(
	--			(
	--			ca.CHART_ACCESS_EVENT_TYPE_CODE = 'A' and ca.SECONDARY_EVENT_COMPLETION_DATE_TIME is null
	--			) or
	--				  (
	--				  ca.CHART_ACCESS_EVENT_TYPE_CODE = 'C' and ca.SECONDARY_EVENT_COMPLETION_DATE_TIME is not null
	--				  ) or
	--						(
	--						ca.CHART_ACCESS_EVENT_TYPE_CODE = 'S' and ca.SECONDARY_EVENT_COMPLETION_DATE_TIME is null
	--						)
	--			)
	--	) x
		inner join #Facility f on x.Facility = f.FACILITY
	where
		(
		x.USER_PROFILE_ID in
			(
			select items from dbo.SplitString(@m_Coder, ',')
			) or -1 in
						(
						select items from dbo.SplitString(@m_Coder, ',')
						)
		)
	group by
		f.COMPANY_ID
		,f.ORGANIZATION
		,x.CHART_ACCESS_EVENT_TYPE_DESC
		,x.FACILITY_ID
		,x.Facility
		,x.USER_PROFILE_ID
		,x.UserName;


	print 'Section: 08 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- Begin "ACS User Login Report" code as of June 2018

	select
		t1.*
	into
		#Facility1
	from
		(
		select
			FUA.facility_id
		from
			FACILITY_USER_AUTHORIZATION FUA 
			,USER_PROFILE UP 
		where
			FUA.user_profile_id = UP.user_profile_id and UP.IS_ACTIVE = 'Y' and FUA.USER_PROFILE_ID = @m_ReportUser
		) T1
		inner join SERVICE_AGREEMENT sa on T1.FACILITY_ID = sa.FACILITY_ID
	where
		sa.DEMO_TEST_SITE_IND = 0
		--and getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE; -- jherrera ACS-14263

	print 'Section: 09 ' + convert(varchar, getdate(), 121)


	select
		*
	into
		#PrelimResults
	from
		(
		select
			c.FACILITY_ID
			,c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID as USER_PROFILE_ID
			,c.SECOND_LEVEL_QA_APPROVED_DATETIME
		from
			CHART c 
			inner join #Facility1 f on c.FACILITY_ID = f.FACILITY_ID
		where
			--exists
			--(
			--select
			--	*
			--from
			--	#Facility1
			--where
			--	c.facility_id = facility_id and FACILITY_ID in (select items from dbo.SplitString(@m_Facility,','))
			--) and 
			c.CHART_STATUS_ID in (4, 5) and c.APPROVAL_REASON_CODE = 3 -- excludes Pushed Charts
			and (c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID in (select items from dbo.SplitString(@m_Coder,',')) or '-1' = @m_Coder)
			--and c.SECOND_LEVEL_QA_APPROVED_DATETIME 
			and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.SECOND_LEVEL_QA_APPROVED_DATETIME))), 0) between @m_StartDate and (@m_EndDate + 1)
		) x;


	print 'Section: 10 ' + convert(varchar, getdate(), 121)


	select *
	into #USER_SESSION
	from
		 USER_SESSION o 
	 where
		o.USER_PROFILE_ID in (select USER_PROFILE_ID from #User)

	
	print 'Section: 11 ' + convert(varchar, getdate(), 121)


	select distinct
		o.USER_PROFILE_ID
		,SESSION_START
		,o.USER_SESSION_ID
	into #StartTimes
	from
		#USER_SESSION o 
	where
		o.USER_PROFILE_ID in (select USER_PROFILE_ID from #User)
		--and o.session_start >= @m_StartDate
		and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, o.session_start))), 0) >= @m_StartDate
		and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, o.last_request))), 0) <= DateAdd(second, 86399, @m_EndDate)
		and not exists
		(
		select
			1
		from
			#USER_SESSION i 
		where
			i.USER_PROFILE_ID = o.USER_PROFILE_ID 
			and o.SESSION_START > i.SESSION_START
			and o.SESSION_START <= i.LAST_REQUEST
			
			and i.USER_PROFILE_ID in (select USER_PROFILE_ID from #User)
			--and o.session_start >= @m_StartDate
			and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, o.session_start))), 0) >= @m_StartDate
			and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, o.last_request))), 0) <= DateAdd(second, 86399, @m_EndDate)
		)

	print 'Section: 12 ' + convert(varchar, getdate(), 121)
	
	select distinct
		   USER_SESSION_ID
		   ,o.USER_PROFILE_ID
		   ,LAST_REQUEST
	into #EndTimes
	from
		#USER_SESSION o 
		inner join USER_PROFILE on USER_PROFILE.USER_PROFILE_ID = o.USER_PROFILE_ID
	where
		USER_PROFILE.USER_PROFILE_ID in (select USER_PROFILE_ID from #User)
		--and o.session_start >= @m_StartDate
		and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, o.session_start))), 0) >= @m_StartDate
		and not exists
		(
		select
			1
		from
			#USER_SESSION i 
		where
			i.USER_PROFILE_ID = o.USER_PROFILE_ID 
			and o.LAST_REQUEST >= i.SESSION_START 
			and o.LAST_REQUEST < i.LAST_REQUEST
				
			and i.user_profile_ID in (select USER_PROFILE_ID from #User)
			--and o.session_start >= @m_StartDate
			and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, o.session_start))), 0) >= @m_StartDate
		)
	
	print 'Section: 13 ' + convert(varchar, getdate(), 121)
	
	select
		USER_SESSION_ID
		,USER_PROFILE_ID
		,LOGON = SESSION_START
		,LOGOFF =
			 (
			 select
				 min(LAST_REQUEST)
			 from
				 #EndTimes et
			 where
				 et.USER_PROFILE_ID = st.USER_PROFILE_ID and LAST_REQUEST >= SESSION_START
			 )
	into #SessionGroups 
	from #StartTimes st
	--where
	--	(
	--	USER_PROFILE_ID in
	--		(
	--		select items from dbo.SplitString(@m_Coder, ',')
	--		) or '-1' = @m_Coder
	--	)
	
	print 'Section: 14 ' + convert(varchar, getdate(), 121)

	select 
		sg.User_Profile_ID
		,c.Completion_Date
	into #ChartsCompleted
	from 
		CHART c
		inner join #Facility1 f on c.FACILITY_ID = f.FACILITY_ID
		inner join #SessionGroups sg on sg.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
	where 
		c.COMPLETION_DATE between sg.LOGON and dateadd(mi, 1, sg.LOGOFF)

	select 
		sg.User_Profile_ID
		,c.Approved_Date
	into #ChartsApproved
	from 
		CHART c 
		inner join #Facility1 f on c.FACILITY_ID = f.FACILITY_ID
		inner join #SessionGroups as sg on sg.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
	where 
		c.APPROVED_DATE between sg.LOGON and dateadd(mi, 1, sg.LOGOFF)
		and c.APPROVAL_REASON_CODE = 3 -- excludes Pushed Charts
		and
			(
				c.second_level_qa_approved_by_user_profile_id is null -- added 4/25/16 to eliminate overstating approved counts
				or c.second_level_qa_approved_by_user_profile_id <> c.APPROVED_BY_USER_PROFILE_ID
			)
	
	select
		sg.USER_SESSION_ID
		,sg.USER_PROFILE_ID
		,up.LAST_NAME + ', ' + up.FIRST_NAME as [NAME]
		,up.SIGN_ON_ID
		,LOGON
		,case
			 when us.SIGNED_OUT is null or us.SIGNED_OUT <> 1 and datediff(mi, us.LAST_REQUEST, getdate()) < 30 then null
			 else LOGOFF end as LOGOFF
		,us.LAST_REQUEST
		,TIME_IN_SECONDS = datediff(
									   s
									   ,LOGON
									   ,isnull(
												  case
													  when us.SIGNED_OUT is null or us.SIGNED_OUT <> 1
																					and datediff(
																									mi
																									,us.LAST_REQUEST
																									,getdate()
																								) < 30 then null
													  else LOGOFF end
												  ,getdate()
											  )
								   )
		,us.SIGNED_OUT
		--,(
		-- select
		--	 count(c.CHART_ID)
		-- from
		--	 CHART c 
		--	 inner join #Facility1 f on c.FACILITY_ID = f.FACILITY_ID
		-- where
		--	 sg.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
		--	 and c.COMPLETION_DATE between LOGON and dateadd(mi, 1, LOGOFF) -- DAH 10/28/16 Added 1 minute to logoff time to catch records in system

		-- --example: chart_id - 35479037	 approved datetime - 2016-10-26 14:26:11.000 logoff_datetime- 2016-10-26 14:26:04.577, record not counted
		-- ) as COMPLETED
		--,(
		-- select
		--	 count(c.CHART_ID)
		-- from
		--	 CHART c 
		--	 inner join #Facility1 f on c.FACILITY_ID = f.FACILITY_ID
		-- where
		--	 sg.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
		--	 and c.APPROVED_DATE between LOGON and dateadd(mi, 1, LOGOFF)
		--	 and c.APPROVAL_REASON_CODE = 3 -- excludes Pushed Charts
		--	 and
		--		 (
		--		 c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID is null -- added 4/25/16 to eliminate overstating approved counts
		--		 or c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> c.APPROVED_BY_USER_PROFILE_ID
		--		 )
		-- ) as APPROVED
		,(Select Count(*) from #ChartsCompleted as cc where sg.User_Profile_ID = cc.User_Profile_ID and cc.COMPLETION_DATE between sg.LOGON and dateadd(mi, 1, sg.LOGOFF)) as COMPLETED		-- performance edit (dsexton, 4/10/2019) 
		,(Select Count(*) from #ChartsApproved as ca where sg.User_Profile_ID = ca.User_Profile_ID and ca.Approved_Date between sg.LOGON and dateadd(mi, 1, sg.LOGOFF)) as APPROVED			-- performance edit (dsexton, 4/10/2019) 
		,(
		 select
			 count(*)
		 from
			 #PrelimResults P 
		 where
			 sg.USER_PROFILE_ID = P.USER_PROFILE_ID
			 and P.SECOND_LEVEL_QA_APPROVED_DATETIME between LOGON and dateadd(mi, 1, LOGOFF)
		 ) as SECOND_APPROVED
		,day(LOGON) as LOGON_DAY
		,month(LOGON) as LOGON_MONTH
		,year(LOGON) as LOGON_YEAR
		,up.EMAIL_ADDRESS
	into #Totals
	from
		#SessionGroups sg
		inner join USER_PROFILE up on sg.USER_PROFILE_ID = up.USER_PROFILE_ID
		inner join #USER_SESSION us on us.USER_SESSION_ID = sg.USER_SESSION_ID
	where
		up.USER_CLASS_CD in (1,5) --in (@m_UserClass)
	--)
	select
		USER_PROFILE_ID
		,[NAME]
		,convert(date, LOGON) as LOGON_DATE
		,SIGN_ON_ID
		,EMAIL_ADDRESS
		,LOGON
		,LOGOFF
		,COMPLETED
		,APPROVED
		,SECOND_APPROVED
		,TIME_IN_SECONDS / 60 TIME_IN_MINUTES
	into #ACSUserLogin
	from
		#Totals t
	where
		--t.LOGON >= @m_StartDate 
		dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, t.LOGON))), 0) >= @m_StartDate
		and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, dateadd(dd, datediff(dd, 0, t.LAST_REQUEST), 0)))), 0) <= @m_EndDate
	--order by
	--	[NAME]
	--	,convert(date, LOGON) asc;
	
	
	print 'Section: 15 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- Being "Coder Scorecard", results are obtained from existing stored procedure. 

	declare @coders varchar(max)
	select @coders = coalesce(@coders,'') + convert(varchar,x.USER_PROFILE_ID) + ','
	from (select USER_PROFILE_ID from #User) x



insert into #CoderQATrending
exec [dbo].[rpt_CorroHealth_Coder_Performance_Metrics] 
@ReportUser  = @m_ReportUser,
@StartDate =  @m_StartDate, 
@EndDate = @m_EndDate, 
@Coder =  @coders, -- '-1', -- try the parameter from line 1138
@Organization = @m_Organization,
@FACILITY_ID = @m_Facility,
@UserGroup =  '1,89,125,130,164,165,169,201,202',
@TimeZone = @m_TimeZone


--  select * from #CoderQATrending
	
	print 'Section: 16 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- Final Results
	
 if object_id('TempDB..#Base', 'U') is not null DROP TABLE #Base;		-- (dsexton, 5/22/2019)

	--;with base		
	--as
	--(

	-- using temp table instead of CTE reduces duration by 7 secs (warm buffer) and reduces reads by 1M   (dsexton, 5/22/2019)

	select distinct ORG_ID, ORGANIZATION, Facility_ID, Facility, USER_PROFILE_ID, UserName, [Date]		
	into #Base
	from 
		#FacilityAverageChartsPerHour_byCoder, #calendar
	--)

	----------------------------------------------------------------------------------------------------------------------------------

	select 
		c.COMPLETED_BY_USER_PROFILE_ID, c.FACILITY_ID, min(c.COMPLETION_DATE) [FIRST_COMPLETION_DATE]
		,datediff(day,min(c.COMPLETION_DATE),getdate()) [DaysSinceFirstCompleteDate]
		,case when datediff(day,min(c.COMPLETION_DATE),getdate()) between 0 and 90 then 1
				when datediff(day,min(c.COMPLETION_DATE),getdate()) between 91 and 180 then 2
				when datediff(day,min(c.COMPLETION_DATE),getdate()) between 181 and 270 then 3
				when datediff(day,min(c.COMPLETION_DATE),getdate()) between 271 and 365 then 4
			else 5 end [TenureId]
		,case when datediff(day,min(c.COMPLETION_DATE),getdate()) between 0 and 90 then '0 - 3 Months'
				when datediff(day,min(c.COMPLETION_DATE),getdate()) between 91 and 180 then '3 - 6 Months'
				when datediff(day,min(c.COMPLETION_DATE),getdate()) between 181 and 270 then '6 - 9 Months'
				when datediff(day,min(c.COMPLETION_DATE),getdate()) between 271 and 365 then '9 - 12 Months'
			else '12+ Months' end [Tenure]
	into #first_comp_date
	from
		dbo.CHART c
	where
		c.FACILITY_ID in (select Facility_ID from #Facility)
		and c.COMPLETED_BY_USER_PROFILE_ID in (select USER_PROFILE_ID from #Base)
	group by c.COMPLETED_BY_USER_PROFILE_ID, c.FACILITY_ID


	----------------------------------------------------------------------------------------------------------------------------------

	select 
		 b.[Date]
		,b.ORG_ID
		,b.ORGANIZATION
		,b.Facility_ID [FacilityID]
		,b.Facility
		,b.USER_PROFILE_ID [UserProfileID]
		,b.UserName
		,isnull(cps.[Event],'Chart Completed') [Event]
		,isnull(cps.CompletionDate, b.[Date] ) as CompletionDate		
		,cps.ElapsedTime
		,cps.ChartsIncluded
	    ,UserProfileID2 = cps.UserProfileID
		,cps.ChartAccessEventType
		,cps.Disposition
		,fcph_bc.AVG_HR [Coder_Avg_Hr]
		,fcph.AVG_HR [Facility_Avg_Hr]
		,aul.LOGON_DATE [ACS_LOGON_DATE]
		,isnull(aul.TIME_IN_MINUTES,0) [TIME_IN_MINUTES]
		,isnull(aul.COMPLETED,0) [COMPLETED]
		,ct1.Charts
		,ct1.Audits
        ,ct1.CoderAccuracy_N
        ,ct1.CoderAccuracy_D
		,fcph.ORG_AVG_HR
		,isnull(aul2.TIME_IN_MINUTES,0) [OVERALL_TIME_IN_MINUTES]
		,isnull(aul2.COMPLETED,0) [OVERALL_COMPLETED]
		,fcd.FIRST_COMPLETION_DATE [First_Complete_Date]
		,fcd.Tenure
		,nof.Num_of_Facilities
		,noc.Num_of_Companies
		,rank() over(partition by b.USER_PROFILE_ID, b.Facility_ID, b.[Date] order by b.[Date], cps.ElapsedTime ) as Rank					

into #FINAL
	from 
		--base b			-- (dsexton, 5/22/2019)
		#Base as b			-- (dsexton, 5/22/2019)
		left join #CoderProductivitySummarybyTimetoEnter cps on b.FACILITY_ID = cps.FacilityID and b.USER_PROFILE_ID = cps.UserProfileID and b.[Date] = cps.CompletionDate
		left join #FacilityAverageChartsPerHour fcph on cps.FacilityID = fcph.Facility_ID
		left join #FacilityAverageChartsPerHour_byCoder fcph_bc on cps.FacilityID = fcph_bc.FACILITY_ID and cps.UserProfileID = fcph_bc.USER_PROFILE_ID
		left join (	select 
						USER_PROFILE_ID
						--,[NAME]
						,convert(datetime,LOGON_DATE) [LOGON_DATE]
						--,SIGN_ON_ID
						--,EMAIL_ADDRESS
						--,LOGON
						--,LOGOFF
						,sum(COMPLETED) [COMPLETED]
						--,APPROVED
						--,SECOND_APPROVED
						,sum(TIME_IN_MINUTES) [TIME_IN_MINUTES]
						,1 as [RowId]
					from 
						#ACSUserLogin
					group by USER_PROFILE_ID, LOGON_DATE 
					) aul on b.USER_PROFILE_ID = aul.USER_PROFILE_ID and b.[Date] = aul.LOGON_DATE and cps.RowId = aul.RowId
		left join (	select 
						USER_PROFILE_ID
						,sum(COMPLETED) [COMPLETED]
						,sum(TIME_IN_MINUTES) [TIME_IN_MINUTES]
						,1 as [RowId]
					from 
						#ACSUserLogin
					group by USER_PROFILE_ID
					) aul2 on b.USER_PROFILE_ID = aul2.USER_PROFILE_ID and cps.OverallRowId = aul2.RowId
		left join
		

		( select 
						ct.User_profile_ID
						,ct.facility_id
						,ct.[DATE]
						,sum(ct.TotalCharts) [Charts]
						,sum(ct.TotalAudits) [Audits]												
						,sum(ct.CoderAccuracy_N) as CoderAccuracy_N
						,sum(ct.CoderAccuracy_D) as CoderAccuracy_D
					from 
					#CoderQATrending	ct
					group by ct.User_profile_ID, ct.facility_id, ct.[DATE] 
					) ct1					
					on b.USER_PROFILE_ID = ct1.User_profile_ID 
					and b.[Date] = ct1.[DATE]
					and b.FACILITY_ID = ct1.facility_id

		left join #first_comp_date fcd on b.FACILITY_ID = fcd.FACILITY_ID and b.USER_PROFILE_ID = fcd.COMPLETED_BY_USER_PROFILE_ID

		left join (select b.USER_PROFILE_ID, b.UserName, count(distinct b.FACILITY_ID) [Num_of_Facilities]
					from #base b
					group by b.USER_PROFILE_ID, b.UserName
					) nof on b.USER_PROFILE_ID = nof.USER_PROFILE_ID

		left join (select b.USER_PROFILE_ID, b.UserName, count(distinct b.ORGANIZATION) [Num_of_Companies]
					from #base b
					group by b.USER_PROFILE_ID, b.UserName
					) noc on b.USER_PROFILE_ID = noc.USER_PROFILE_ID
	where 
	-- 	cps.CompletionDate is not null
    	(cps.CompletionDate is not null
		or ct1.Charts  is not null 
		or ct1.Audits  is not null
        or ct1.CoderAccuracy_N is not null
        or ct1.CoderAccuracy_D is not null )
		and (@Tenure = -1 or fcd.TenureId = @Tenure);
-- 	order by cps.Facility, cps.UserName, b.[Date] --, cps.CompletionDate
	
	



-- The Rank id's one record per day for Coder/Facility/Day
-- The Update sets CoderQATrending data to Null when multiple records exist per Coder/Facility/Day, to avoid overstating.

update #FINAL
set Charts = NULL,
Audits = NULL,
CoderAccuracy_N = NULL,
CoderAccuracy_D = NULL
where Rank <> 1;




-- Output ***************

select * from 
#FINAL
order by Facility, UserName, [Date]
;	

	
--	print 'Section: 17 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------



end;








GO
GRANT EXECUTE ON  [dbo].[rpt_CorroHealth_Coder_Performance_Metrics_Report] TO [dbx_ExecuteReportProcs]
GO
