SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[rpt_CorroHealth_Coder_Production_Log]
(
    @Organization varchar(max)
    ,@Facility    varchar(max)
    ,@StartDate   datetime
    ,@EndDate     datetime
    ,@ReportUser  int
	,@Supervisor  varchar(max) = '-9999'
)
as

begin



	set transaction isolation level read uncommitted;

	--declare
	--	@Organization varchar(max) = 121
	--	,@Facility    varchar(max) = 724
	--	,@StartDate   datetime     = '20211208'
	--	,@EndDate     datetime     = '20211216'
	--	,@ReportUser  int          = 80
	--	,@Supervisor  varchar(max) = '-9999'; -- -9999 = bypass


	declare
		@m_ChartAccessEventType varchar(10)  = 'C'                      --@ChartAccessEventType
		,@m_Coder                varchar(max) = -1                       --@Coder
		,@m_DateGrouping         int          = 1                        --@DateGrouping
		,@m_Disposition          varchar(max) = '99,4,5'                 --@Disposition;
		,@m_TimeZone             varchar(30)  = 'Central Daylight Time'; --@TimeZone


	/* TIME ZONE */
	--declare @CTOffSet VARCHAR(9) = (select CT_OFFSET from TIME_ZONE where DESCRIPTION=@TimeZone);
	--declare @Operator varchar(1) = substring(@CTOffSet, 1, 1);
	--declare @hms varchar(8) = substring(@CTOffSet, 2, LEN(@CTOffSet)-1) 
	--declare @hours decimal(10,2) = datepart(hour, @hms)
	--declare @minutes decimal(10,2) = datepart(minute, @hms)
	--declare @HrsOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(hour, @hms)) as decimal(10,2))
	--declare @MinOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(minute, @hms)) as decimal(10,2))


	----------------------------------------------------------------------------------------------------------------------------------

	if object_id('TempDB..#Facility', 'U') is not null drop table #Facility;
	if object_id('TempDB..#User', 'U') is not null drop table #User;
	if object_id('TempDB..#Details', 'U') is not null drop table #Details;
	if object_id('TempDB..#CoderProductivitySummarybyTimetoEnter', 'U') is not null drop table #CoderProductivitySummarybyTimetoEnter;
	if object_id('TempDB..#CoderQATrending', 'U') is not null drop table #CoderQATrending;
	if object_id('TempDB..#CoderProductivitySummarybyTimetoEnter_summary', 'U') is not null drop table #CoderProductivitySummarybyTimetoEnter_summary;


	----------------------------------------------------------------------------------------------------------------------------------

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
			and exists
            (
            select
                *
            from
                [dbo].SplitString(@Organization, ',')
            where
                items = sa.COMPANY_ID
            union
            select
                *
            from
                [dbo].SplitString(@Organization, ',')
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
                and FUA.USER_PROFILE_ID = @ReportUser and exists
                (
                select
                    *
                from
                    [dbo].SplitString(@Facility, ',')
                where
                    items = sa.FACILITY_ID
                union
                select
                    *
                from
                    [dbo].SplitString(@Facility, ',')
                where
                    items = -1
                )
            )
        ) t1;


	----------------------------------------------------------------------------------------------------------------------------------

	select 
		up.USER_PROFILE_ID 
		,up.FIRST_NAME
		,up.LAST_NAME
		,up.SUPERVISOR_USER_PROFILE_ID [SUPERVISOR_ID]
		,sup.FIRST_NAME + ' ' + sup.LAST_NAME [SUPERVISOR]
		,up.EMPLOYEE_ID
	into #User
	from
		(
			select
				USER_PROFILE.USER_PROFILE_ID
				,USER_PROFILE.EMPLOYEE_ID
				,FIRST_NAME
				,LAST_NAME
				,USER_PROFILE.SUPERVISOR_USER_PROFILE_ID
			from
				USER_PROFILE with (nolock)
			where
				exists
					(
						select * from [dbo].SplitString(@m_Coder, ',') where items = -1
					)
				and USER_PROFILE.USER_PROFILE_ID not in (2, 5, 80)
				and USER_PROFILE.USER_CLASS_CD in (1, 5)
				and exists
			(
				select * from #Facility where FACILITY_ID = #Facility.FACILITY_ID
			)
			union
			select
				USER_PROFILE.USER_PROFILE_ID
				,USER_PROFILE.EMPLOYEE_ID
				,FIRST_NAME
				,LAST_NAME
				,USER_PROFILE.SUPERVISOR_USER_PROFILE_ID
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
					)
				and USER_PROFILE_ID <> -1
		) up
		left join dbo.USER_PROFILE sup on up.SUPERVISOR_USER_PROFILE_ID = sup.USER_PROFILE_ID
	where
		(@Supervisor = '-9999' or up.SUPERVISOR_USER_PROFILE_ID in ( select items from dbo.SplitString(@Supervisor, ',') ));


	----------------------------------------------------------------------------------------------------------------------------------

	select
		ce.CHART_ACCESS_EVENT_TYPE_DESC                                           [Event]
		,f.NAME                                                                   as Facility
		,EMPLOYEE_ID
		,up.LAST_NAME + ', ' + up.FIRST_NAME                                      UserName
		,case @m_DateGrouping
			 when 0 then dateadd(month, datediff(month, 0, ca.EVENT_COMPLETION_DATE_TIME), 0)
		 else dateadd(day, datediff(day, 0, ca.EVENT_COMPLETION_DATE_TIME), 0)end CompletionDate
		,(sum(   case
					 when datediff(second, ca.ACCESS_DATE_TIME, ca2.EVENT_COMPLETION_DATE_TIME) > 3600 then null
				 else datediff(second, ca.ACCESS_DATE_TIME, ca2.EVENT_COMPLETION_DATE_TIME)end
			 ) * 1.0
		 ) / 60.0                                                                 ElapsedTime
		,count(*)                                                                 ChartsIncluded
		,f.FACILITY_ID                                                            FacilityID
		,up.USER_PROFILE_ID                                                       UserProfileID
		,ca.CHART_ACCESS_EVENT_TYPE_CODE                                          ChartAccessEventType
		,case
			 when c.PATIENT_DISPOSITION_ID = 4 then 'Inpatient'
			 when c.PATIENT_DISPOSITION_ID = 5 then 'Observation'
			 when c.PATIENT_DISPOSITION_ID >= 1 then 'ER'
		 else 'Unknown' end                                                       as Disposition
	into #Details
	from
		CHART_ACCESS ca
		,CHART_ACCESS ca2
		,CHART_ACCESS_EVENT_TYPE ce
		,CHART c
		,FACILITY f
		,USER_PROFILE up
	where
		ca.CHART_ACCESS_EVENT_TYPE_CODE = ce.CHART_ACCESS_EVENT_TYPE_CODE
		--and dateadd(dd,datediff(dd,0,dateadd(hh,@HrsOffSet,dateadd(mi,@MinOffSet,dateadd(day,datediff(day, 0, ca.EVENT_COMPLETION_DATE_TIME),0)))),0) between @StartDate and dateadd(second, 86399, @EndDate)
		and ca.EVENT_COMPLETION_DATE_TIME between @StartDate and dateadd(second, 86399, @EndDate)
		and c.CHART_ID = ca.CHART_ID
		and c.FACILITY_ID = f.FACILITY_ID
		and ca.USER_PROFILE_ID = up.USER_PROFILE_ID
		and ca2.CHART_ACCESS_ID = ca.CHART_ACCESS_ID
		--and c.PATIENT_DISPOSITION_ID in
		--	(
		--		select
		--			PATIENT_DISPOSITION_ID
		--		from
		--			PATIENT_DISPOSITION
		--		where
		--			PATIENT_DISPOSITION_ID in (4, 5)
		--			and PATIENT_DISPOSITION_ID in
		--				(
		--					select * from SplitString(@m_Disposition, ',')
		--				)
		--		union
		--		select
		--			PATIENT_DISPOSITION_ID
		--		from
		--			PATIENT_DISPOSITION
		--		where
		--			PATIENT_DISPOSITION_ID not in (4, 5)
		--			and 99 in
		--				(
		--					select * from SplitString(@m_Disposition, ',')
		--				)
		--	)
		and ca2.CHART_ACCESS_ID =
		(
			select
				max(ca3.CHART_ACCESS_ID)
			from
				CHART_ACCESS ca3
			where
				ca3.CHART_ACCESS_EVENT_TYPE_CODE = ca.CHART_ACCESS_EVENT_TYPE_CODE
				and ca3.CHART_ID = ca.CHART_ID
		)
		and ca.EVENT_COMPLETION_DATE_TIME is not null
		and ca.CHART_ACCESS_EVENT_TYPE_CODE in
			(
				select items from [dbo].SplitString(@m_ChartAccessEventType, ',')
			)
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
		,up.EMPLOYEE_ID
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
		 else 'Unknown' end;


	--select
	--	f.COMPANY_ID         [ORG_ID]
	--	,f.ORGANIZATION
	--	,d.[Event]
	--	,d.FacilityID
	--	,d.Facility
	--	,d.UserProfileID
	--	,d.UserName
	--	,d.CompletionDate
	--	,d.ElapsedTime
	--	,d.ChartsIncluded
	--	,d.ChartAccessEventType
	--	,d.Disposition
	--	,row_number() over (partition by d.[Event],d.UserName,d.Facility,d.CompletionDate order by d.Disposition) [RowId]
	--	,row_number() over (partition by d.[Event],f.COMPANY_ID,d.UserName order by d.CompletionDate,FacilityID,Disposition) [OverallRowId]
	--into #CoderProductivitySummarybyTimetoEnter
	--from
	--	#Details as d
	--	inner join #Facility f on d.Facility = f.Facility;


	select
		d.UserProfileID
		,d.UserName
		,d.CompletionDate
		,sum(d.ElapsedTime) [ElapsedTime]
		,sum(d.ChartsIncluded) [ChartsIncluded]
	into #CoderProductivitySummarybyTimetoEnter
	from
		#Details as d
		inner join #Facility f on d.Facility = f.Facility
	group by 
		d.UserProfileID
		,d.UserName
		,d.CompletionDate;

		
	----------------------------------------------------------------------------------------------------------------------------------

	create table #CoderQATrending
	(
	[User_Profile_ID]	[int] null,
	[Facility_ID]		[int] null,
	[Date]				[Date] null,
	[TotalCharts]		[int] null,
	[TotalAudits]		[int] null,
	[CoderAccuracy_N]	[int] null,
	[CoderAccuracy_D]	[int] null
	);

	declare @coders varchar(max);
	select @coders = coalesce(@coders,'') + convert(varchar,x.UserProfileID) + ','
	--from (select USER_PROFILE_ID from #User) x;
	from (select distinct UserProfileID from #CoderProductivitySummarybyTimetoEnter) x;

	insert into #CoderQATrending
	exec [dbo].[rpt_CorroHealth_Coder_Performance_Metrics] 
	@ReportUser  = @ReportUser,
	@StartDate =  @StartDate, 
	@EndDate = @EndDate, 
	@Coder =  @coders, -- '-1', -- try the parameter from line 1138
	@Organization = @Organization,
	@FACILITY_ID = @Facility,
	@UserGroup =  '1,89,125,130,164,165,169,201,202',
	@TimeZone = @m_TimeZone;


	----------------------------------------------------------------------------------------------------------------------------------
	
	select 
		UserProfileID
		,UserName
		,sum(ElapsedTime) ElapsedTime
		,sum(ChartsIncluded) ChartsIncluded
	into #CoderProductivitySummarybyTimetoEnter_summary
	from
		#CoderProductivitySummarybyTimetoEnter
	group by 
		UserProfileID
		,UserName


	----------------------------------------------------------------------------------------------------------------------------------

	select 
		u.USER_PROFILE_ID
		,u.EMPLOYEE_ID
		,u.FIRST_NAME
		,u.LAST_NAME
		,u.SUPERVISOR_ID
		,u.SUPERVISOR
		--,cpste.CompletionDate [DATE]
		--,cpste.ElapsedTime [ELAPSED_TIME_MINUTES]
		,cast(cast((cpste.ElapsedTime / 60) as int) as varchar) 
			+ ':' + right('00'+cast(cast(( (cpste.ElapsedTime / 60) - cast((cpste.ElapsedTime / 60) as int) ) * 60 as int) as varchar),2) [PROD_HOURS]
		,cpste.ChartsIncluded [CHARTS_INCLUDED]
		,ct1.Charts
		,ct1.Audits
		,ct1.CoderAccuracy_N
		,ct1.CoderAccuracy_D
		,obs.[Num_OBS_Charts_CompletedDuringPayPeriod]
	from
		#User u
		inner join #CoderProductivitySummarybyTimetoEnter_summary cpste on u.USER_PROFILE_ID = cpste.UserProfileID
		left join ( select 
						ct.User_profile_ID
						--,ct.[DATE]
						,sum(ct.TotalCharts) [Charts]
						,sum(ct.TotalAudits) [Audits]												
						,sum(ct.CoderAccuracy_N) as CoderAccuracy_N
						,sum(ct.CoderAccuracy_D) as CoderAccuracy_D
					from 
						#CoderQATrending ct
					group by ct.User_profile_ID--, ct.[DATE] 
					) ct1 on u.USER_PROFILE_ID = ct1.User_profile_ID --and cpste.CompletionDate = ct1.[DATE]
		outer apply ( select c.COMPLETED_BY_USER_PROFILE_ID, count(1) [Num_OBS_Charts_CompletedDuringPayPeriod]
					  from
					 	dbo.CHART c
					 	inner join dbo.SERVICE_AGREEMENT sa on c.FACILITY_ID = sa.FACILITY_ID
					  where
					 	c.FACILITY_ID in ( select FACILITY_ID from #Facility )
							--in ( select items from dbo.SplitString(@Facility, ',') )
					 	and c.COMPLETION_DATE between @StartDate and dateadd(second,86399,@EndDate)
					 	and c.PATIENT_DISPOSITION_ID = 5	-- OBS ONLY
					 	and isnull(sa.EVALUATE_PHYSICIAN_OBSERVATION,0) = 1
						and u.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
					  group by c.COMPLETED_BY_USER_PROFILE_ID
					) obs


end;
GO
