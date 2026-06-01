SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Jay Herrera
-- Create date: 04/06/2021
-- Description:	Sproc for Global Coder Productivity Report
-- =============================================

CREATE procedure [dbo].[rpt_GlobalCoderProductivityReport]
	@TimeZone      varchar(25) 
	,@Organization varchar(max)         
	,@Facility     varchar(max)         
	,@StartDate    date        
	,@EndDate      date        
	,@ReportUser   int         
	,@UserGroup    varchar(max)         
	,@data_select  varchar(3) 
as

begin

	set transaction isolation level read uncommitted;
	set nocount on;

	
	----------------------------------------------------------------------------------------------------

	--declare
	--	@TimeZone      varchar(25)   = 'India Daylight Time'
	--	,@Organization int           = -1
	--	,@Facility     int           = 1785
	--	,@StartDate    date          = '20220403'
	--	,@EndDate      date          = '20220409'
	--	,@ReportUser   int           = 80
	--	,@UserGroup    varchar(1000) = '201,202,203,208,212'
	--	--,@data_select  varchar(3)    = 'C';		--C,A,DOW,P,D,DD

	----------------------------------------------------------------------------------------------------------------------------------

	declare @spid int = @@spid


	----------------------------------------------------------------------------------------------------------------------------------

	declare @CTOffSet varchar(9) =
			(
				select CT_OFFSET from TIME_ZONE where DESCRIPTION = @TimeZone
			);
	declare @Operator varchar(1) = substring(@CTOffSet, 1, 1);
	declare @hms varchar(8) = substring(@CTOffSet, 2, len(@CTOffSet) - 1);
	declare @hours decimal(10, 2) = datepart(hour, @hms);
	declare @minutes decimal(10, 2) = datepart(minute, @hms);
	declare @HrsOffSet decimal(10, 2) = cast(@Operator + convert(varchar, datepart(hour, @hms)) as decimal(10, 2));
	declare @MinOffSet decimal(10, 2) = cast(@Operator + convert(varchar, datepart(minute, @hms)) as decimal(10, 2));



	declare @LN_StartDate date = dateadd(day, -1, @StartDate);
	declare @LN_EndDate date = dateadd(day, 1, @EndDate);


	----------------------------------------------------------------------------------------------------------------------------------

	if object_id('TempDB..#LogNote1C', 'U') is not null drop table #LogNote1C;
	if object_id('TempDB..#UserGroup1', 'U') is not null drop table #UserGroup1;
	if object_id('TempDB..#Facility1', 'U') is not null drop table #Facility1;
	if object_id('TempDB..#LogNote1', 'U') is not null drop table #LogNote1;
	if object_id('TempDB..#Detail1', 'U') is not null drop table #Detail1;
	if object_id('TempDB..#LogNote2C', 'U') is not null drop table #LogNote2C;
	if object_id('TempDB..#results', 'U') is not null drop table #results;
	if object_id('TempDB..#audit_charts', 'U') is not null drop table #audit_charts;

	if object_id('TempDB..#LogNote1C_Domestic', 'U') is not null drop table #LogNote1C_Domestic;
	if object_id('TempDB..#LogNote2C_Domestic', 'U') is not null drop table #LogNote2C_Domestic;
	if object_id('TempDB..#Detail1_Domestic', 'U') is not null drop table #Detail1_Domestic;
	if object_id('TempDB..#results_Domestic', 'U') is not null drop table #results_Domestic;
	if object_id('TempDB..#audit_charts_Domestic', 'U') is not null drop table #audit_charts_Domestic;
	

	print 'Section: 00 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------------------------------------

	create table #LogNote1C
	(
		chart_id              int
		,ADate                date
		,ADate_TimeZone		  datetime
		,completion_date      datetime
		,completed_by_user_id int
		,category_id          int
		--,Summary              varchar(256)
		,log_note_id		  bigint
	);

	---- Completed Charts Pull from Log_Note, issue with data parameter not using index, used dynamic sql
	--declare @cmd varchar(1000);
	--set @cmd
	--	= ' 

	--	select
	--		ln.chart_id,
	--		dateadd(day, datediff(day, 0, ln.completion_date), 0) ADate,
	--		ln.completion_date ,
	--		ln.completed_by_user_id ,
	--		ln.category_id,
	--		ln.Summary as Summary
	--	from
	--		LOG_NOTE LN 
	--	where
	--		ln.category_id = 2  -- Chart completed.
	--		and ln.CREATION_DATE_TIME between ''' + cast(@LN_StartDate as varchar(20)) + ''' and ''' + cast(@LN_EndDate as varchar(20)) + '''
	--	';

	--insert into #LogNote1C
	--(chart_id,ADate,completion_date,completed_by_user_id,category_id,Summary)
	--exec (@cmd);


	--update #LogNote1C
	--set ADate_TimeZone = dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, completion_date))), 0)


	insert into #LogNote1C
		(category_id, completed_by_user_id, chart_id, log_note_id)
	select
		[CATEGORY_ID],
		[COMPLETED_BY_USER_ID],
		[CHART_ID],
		[LOG_NOTE_ID]
	from
		LOG_NOTE LN --with(index(AI_LOG_NOTE_CREATION_DATE))
	where
		ln.category_id = 2  -- Chart completed.
		and ln.CREATION_DATE_TIME between @LN_StartDate and @LN_EndDate


	update #LogNote1C
	set
		ADate = dateadd(day, datediff(day, 0, ln.completion_date), 0)
		,ADate_TimeZone = dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, ln.completion_date))), 0)
		,completion_date = ln.COMPLETION_DATE
		,completed_by_user_id = ln.COMPLETED_BY_USER_ID
	from
		#LogNote1C ln1c
		inner join LOG_NOTE ln on ln1c.log_note_id = ln.LOG_NOTE_ID


	print 'Section: 01 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------  

	select
		t1.USER_PROFILE_ID
		,t1.USER_GROUP_ID
	into #UserGroup1
	from
		(
			select
				USER_PROFILE_ID
				,USER_GROUP_ID
			from
				USER_PROFILE
			where
				USER_GROUP_ID in ( select items from dbo.SplitString(@UserGroup, ',') )
			union
			select
				ugup.USER_PROFILE_ID
				,ugup.USER_GROUP_ID
			from
				USER_GROUP_TO_USER_PROFILE ugup
			where
				ugup.USER_GROUP_ID in ( select items from dbo.SplitString(@UserGroup, ',') )
		) t1;


	print 'Section: 02 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------

	select distinct
		f.FACILITY_ID
		,f.NAME
	into #Facility1
	from
		SERVICE_AGREEMENT sa 
		,FACILITY f 
	where
		f.FACILITY_ID = sa.FACILITY_ID
		and
			(
				(-1 in ( select items from dbo.SplitString(@Organization, ',') ))
				or (sa.COMPANY_ID in ( select items from dbo.SplitString(@Organization, ',') ))
			)
		and
			(
				(f.FACILITY_ID in ( select items from dbo.SplitString(@Facility, ',') ))
				or (-1 in ( select items from dbo.SplitString(@Facility, ',') ))
			)
		and sa.DEMO_TEST_SITE_IND = 0
		--and @StartDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
		and (@StartDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
				or @EndDate between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE)
		and exists
	(
		select *
		from
			FACILITY_USER_AUTHORIZATION FUA 
			,USER_PROFILE UP 
		where
			FUA.FACILITY_ID = f.FACILITY_ID
			and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
			and UP.IS_ACTIVE = 'Y'
			and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
			and FUA.USER_PROFILE_ID = @ReportUser
	)
	order by f.NAME asc;


	print 'Section: 03 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------

	select *
	into #LogNote1
	from
	(
		select
			LN.CHART_ID
			,dateadd(day, datediff(day, 0, LN.COMPLETION_DATE), 0) as ADate
			,dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, LN.COMPLETION_DATE))), 0) as ADate_TimeZone
			,LN.COMPLETION_DATE
			,coder.LAST_NAME + ', ' + coder.FIRST_NAME             as Coder
			,LN.COMPLETED_BY_USER_ID
			,LN.CATEGORY_ID
			,LN.SUMMARY                                            as SUMMARY
			,1                                                     as Pended
		from
			LOG_NOTE LN 
			left join USER_PROFILE coder  on coder.USER_PROFILE_ID = LN.COMPLETED_BY_USER_ID
		where
			LN.CATEGORY_ID = 6 -- Chart pended
			and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, LN.CREATION_DATE_TIME))), 0) between @StartDate and @EndDate
	) t2;


	print 'Section: 04 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------

	create table #Detail1
	(
		ADate       datetime
		,ADate_TimeZone datetime
		,Facility   varchar(50)
		,FacilityID int
		,Coder      varchar(55)
		,UserID     int
		,Completed  int
		,Audited    int
		,Pended     int
	);


	print 'Section: 05 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------

	-- Pended
	insert into #Detail1
	select
		ln1.ADate
		,ln1.ADate_TimeZone
		,f.[NAME]                 as Facility
		,f.FACILITY_ID            as FacilityID
		,ln1.Coder
		,ln1.COMPLETED_BY_USER_ID as UserID
		,0                        as Completed
		,0                        as Audited
		,sum(ln1.Pended)          as Pended
	from 
		#LogNote1 ln1
		,CHART c 
		join FACILITY   f  on f.FACILITY_ID = c.FACILITY_ID
	where
		ln1.CHART_ID = c.CHART_ID
		--    and  c.APPROVAL_REASON_CODE = 3 -- excludes Pushed Charts     
		and exists
			(
				select 1 from #UserGroup1 where USER_PROFILE_ID = ln1.COMPLETED_BY_USER_ID
			)
		and exists
			(
				select 1 from #Facility1 where FACILITY_ID = c.FACILITY_ID
			)
	group by
		ln1.ADate
		,ln1.ADate_TimeZone
		,f.[NAME]
		,f.FACILITY_ID
		,ln1.Coder
		,ln1.COMPLETED_BY_USER_ID;


	print 'Section: 06 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------

	select distinct
		LN.chart_id
		,dateadd(day, datediff(day, 0, LN.completion_date), 0) as ADate
		,LN.ADate_TimeZone
		,LN.completion_date
		,coder.LAST_NAME + ', ' + coder.FIRST_NAME             as Coder
		,LN.completed_by_user_id
		,LN.category_id
		--,LN.Summary                                            as SUMMARY
		,1                                                     as Completed
	into #LogNote2C
	from
		#LogNote1C LN
		left join USER_PROFILE   coder  on coder.USER_PROFILE_ID = LN.completed_by_user_id
	where
		dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, LN.completion_date))), 0) between @StartDate and @EndDate
		-- this restricts to one completed chart per coder, per day
		and LN.completion_date =
		(
			select
				max(completion_date)
			from
				#LogNote1C
			where
				chart_id = LN.chart_id
				and completed_by_user_id = LN.completed_by_user_id
				and ADate = LN.ADate
		);


	create nonclustered index #LogNote2C_chart_id on #LogNote2C ( chart_id )


	print 'Section: 07 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------  
	-- Completed

	insert into #Detail1
	select
		ln1.ADate
		,ln1.ADate_TimeZone
		,f.[NAME]                 as Facility
		,f.FACILITY_ID            as FacilityID
		,ln1.Coder
		,ln1.completed_by_user_id as UserID
		,sum(ln1.Completed)       as Completed
		,0                        as Audited
		,0                        as Pended
	from
		#LogNote2C ln1
		,CHART c 
		join FACILITY   f  on f.FACILITY_ID = c.FACILITY_ID
	where
		ln1.chart_id = c.CHART_ID
		and c.CHART_STATUS_ID in (3, 4, 5, 8)
		and exists
			(
				select 1 from #UserGroup1 where USER_PROFILE_ID = ln1.completed_by_user_id
			)
		and exists
			(
				select 1 from #Facility1 where FACILITY_ID = c.FACILITY_ID
			)
	group by
		ln1.ADate
		,ln1.ADate_TimeZone
		,f.[NAME]
		,f.FACILITY_ID
		,ln1.Coder
		,ln1.completed_by_user_id;


	print 'Section: 08 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------
	-- Audited  

	select 
		c.CHART_ID
		,c.FACILITY_ID
		,c.APPROVED_DATE
		,c.APPROVED_BY_USER_PROFILE_ID
	into #audit_charts
	from
		CHART    c 
	where
		c.CHART_STATUS_ID in (3, 4, 5, 8)
		and exists
			(
				select
					1
				from
					#UserGroup1
				where
					USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
			)
		and exists
			(
				select 1 from #Facility1 where FACILITY_ID = c.FACILITY_ID
			)
		and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE))), 0) between @StartDate and @EndDate


	insert into #Detail1
	select
		dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0) as ADate
		,dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE))), 0) as ADate_TimeZone
		,f.[NAME]                                          as Facility
		,f.FACILITY_ID                                     as FacilityID
		,auditor.LAST_NAME + ', ' + auditor.FIRST_NAME     as Coder
		,auditor.USER_PROFILE_ID                           as UserID
		,0                                                 as Completed
		,sum(   case
					when c.APPROVED_BY_USER_PROFILE_ID = auditor.USER_PROFILE_ID then 1
				else 0 end
			)                                              as Audited
		,0                                                 as Pended
	from
		--CHART    c 
		#audit_charts c
		join FACILITY     f  on f.FACILITY_ID = c.FACILITY_ID
		left join USER_PROFILE auditor  on auditor.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
	--where
	--	c.CHART_STATUS_ID in (3, 4, 5, 8)
	--	--and c.[START_QA_DATE] is not null -- excludes Pushed Charts
	--	and exists
	--		(
	--			select
	--				1
	--			from
	--				#UserGroup1
	--			where
	--				USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
	--		)
	--	and exists
	--		(
	--			select 1 from #Facility1 where FACILITY_ID = c.FACILITY_ID
	--		)
	--	and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE))), 0) between @StartDate and @EndDate
	group by
		dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0)
		,dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE))), 0)
		,f.[NAME]
		,f.FACILITY_ID
		,auditor.USER_PROFILE_ID
		,auditor.LAST_NAME + ', ' + auditor.FIRST_NAME;


	print 'Section: 09 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------------------------------------
	-- Domestic Counts

	create table #LogNote1C_Domestic
	(
		chart_id              int
		,ADate                date
		,ADate_TimeZone		  datetime
		,completion_date      datetime
		,completed_by_user_id int
		,category_id          int
		--,Summary              varchar(256)
		,log_note_id		  bigint
	);


	insert into #LogNote1C_Domestic
		(category_id, completed_by_user_id, chart_id, log_note_id)
	select
		[CATEGORY_ID],
		[COMPLETED_BY_USER_ID],
		[CHART_ID],
		[LOG_NOTE_ID]
	from
		LOG_NOTE LN --with(index(AI_LOG_NOTE_CREATION_DATE))
	where
		ln.category_id = 2  -- Chart completed.
		and ln.CREATION_DATE_TIME between @LN_StartDate and @LN_EndDate


	update #LogNote1C_Domestic
	set
		ADate = dateadd(day, datediff(day, 0, ln.completion_date), 0)
		,ADate_TimeZone = dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, ln.completion_date))), 0)
		,completion_date = ln.COMPLETION_DATE
		,completed_by_user_id = ln.COMPLETED_BY_USER_ID
	from
		#LogNote1C_Domestic ln1c
		inner join LOG_NOTE ln on ln1c.log_note_id = ln.LOG_NOTE_ID


	----------------------------------------------------------------------------------------------------------------------------------
	
	select distinct
		LN.chart_id
		,dateadd(day, datediff(day, 0, LN.completion_date), 0) as ADate
		,LN.ADate_TimeZone
		,LN.completion_date
		,coder.LAST_NAME + ', ' + coder.FIRST_NAME             as Coder
		,LN.completed_by_user_id
		,LN.category_id
		--,LN.Summary                                            as SUMMARY
		,1                                                     as Completed
	into #LogNote2C_Domestic
	from
		#LogNote1C_Domestic LN
		left join USER_PROFILE   coder  on coder.USER_PROFILE_ID = LN.completed_by_user_id
	where
		dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, LN.completion_date))), 0) between @StartDate and @EndDate
		-- this restricts to one completed chart per coder, per day
		and LN.completion_date =
		(
			select
				max(completion_date)
			from
				#LogNote1C_Domestic
			where
				chart_id = LN.chart_id
				and completed_by_user_id = LN.completed_by_user_id
				and ADate = LN.ADate
		)
		and coder.USER_CLASS_CD = 1	--Domestic Only


	create nonclustered index #LogNote2C_chart_id on #LogNote2C_Domestic ( chart_id )


	----------------------------------------------------------------------------------------------------  
	
	create table #Detail1_Domestic
	(
		ADate       datetime
		,ADate_TimeZone datetime
		,Facility   varchar(50)
		,FacilityID int
		,Coder      varchar(55)
		,UserID     int
		,Completed  int
		,Audited    int
		,Pended     int
	);

	insert into #Detail1_Domestic
	select
		ln1.ADate
		,ln1.ADate_TimeZone
		,f.[NAME]                 as Facility
		,f.FACILITY_ID            as FacilityID
		,ln1.Coder
		,ln1.completed_by_user_id as UserID
		,sum(ln1.Completed)       as Completed
		,0                        as Audited
		,0                        as Pended
	from
		#LogNote2C_Domestic ln1
		,CHART c 
		join FACILITY   f  on f.FACILITY_ID = c.FACILITY_ID
		join SERVICE_AGREEMENT sa on f.FACILITY_ID = sa.FACILITY_ID
		inner join dbo.SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT sasla on sa.SERVICE_AGREEMENT_ID = sasla.SERVICE_AGREEMENT_ID
		inner join dbo.SERVICE_LOCATION sl on sasla.SERVICE_LOCATION_ID = sl.SERVICE_LOCATION_ID
	where
		ln1.chart_id = c.CHART_ID
		and c.CHART_STATUS_ID in (3, 4, 5, 8)
		and exists
			(
				select 1 from dbo.USER_PROFILE where USER_PROFILE_ID = ln1.completed_by_user_id and USER_CLASS_CD = 1	--Domestic Only
			)
		and exists
			(
				select 1 from #Facility1 where FACILITY_ID = c.FACILITY_ID
			)
		and sl.[NAME] <> 'T-KC'
	group by
		ln1.ADate
		,ln1.ADate_TimeZone
		,f.[NAME]
		,f.FACILITY_ID
		,ln1.Coder
		,ln1.completed_by_user_id;


	----------------------------------------------------------------------------------------------------------------------------------

	select 
		c.CHART_ID
		,c.FACILITY_ID
		,c.APPROVED_DATE
		,c.APPROVED_BY_USER_PROFILE_ID
	into #audit_charts_Domestic
	from
		CHART    c 
	where
		c.CHART_STATUS_ID in (3, 4, 5, 8) and c.APPROVAL_REASON_CODE = 3 -- excludes Pushed Charts
		and exists
			(
				select
					1
				from
					dbo.USER_PROFILE
				where
					USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
					 and USER_CLASS_CD = 1	--Domestic Only
			)
		and exists
			(
				select 1 from #Facility1 where FACILITY_ID = c.FACILITY_ID
			)
		and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE))), 0) between @StartDate and @EndDate


	insert into #Detail1_Domestic
	select
		dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0) as ADate
		,dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE))), 0) as ADate_TimeZone
		,f.[NAME]                                          as Facility
		,f.FACILITY_ID                                     as FacilityID
		,auditor.LAST_NAME + ', ' + auditor.FIRST_NAME     as Coder
		,auditor.USER_PROFILE_ID                           as UserID
		,0                                                 as Completed
		,sum(   case
					when c.APPROVED_BY_USER_PROFILE_ID = auditor.USER_PROFILE_ID then 1
				else 0 end
			)                                              as Audited
		,0                                                 as Pended
	from
		#audit_charts_Domestic c
		join FACILITY     f  on f.FACILITY_ID = c.FACILITY_ID
		join SERVICE_AGREEMENT sa on f.FACILITY_ID = sa.FACILITY_ID
		inner join dbo.SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT sasla on sa.SERVICE_AGREEMENT_ID = sasla.SERVICE_AGREEMENT_ID
		inner join dbo.SERVICE_LOCATION sl on sasla.SERVICE_LOCATION_ID = sl.SERVICE_LOCATION_ID
		left join USER_PROFILE auditor  on auditor.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
	where
		sl.[NAME] <> 'T-KC'
	group by
		dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0)
		,dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE))), 0)
		,f.[NAME]
		,f.FACILITY_ID
		,auditor.USER_PROFILE_ID
		,auditor.LAST_NAME + ', ' + auditor.FIRST_NAME;


	----------------------------------------------------------------------------------------------------------------------------------

	select
		ADate
		,ADate_TimeZone
		,Coder
		,UserID
		,Facility
		,FacilityID
		,Completed
		,Audited
		,Pended
		,Completed + Audited + Pended as Total
		--,case when up.USER_CLASS_CD = 1 then Completed else 0 end [Completed_Domestic]
		--,case when up.USER_CLASS_CD = 1 then Audited else 0 end [Audited_Domestic]
	into #results_Domestic
	from #Detail1_Domestic
	inner join dbo.USER_PROFILE up on UserID = up.USER_PROFILE_ID
	where
		UserID <> 2
	order by
		Coder
		,Facility;	


	----------------------------------------------------------------------------------------------------
	-- Output 

	select
		ADate
		,ADate_TimeZone
		,Coder
		,UserID
		,Facility
		,FacilityID
		,Completed
		,Audited
		,Pended
		,Completed + Audited + Pended as Total
		--,case when up.USER_CLASS_CD = 1 then Completed else 0 end [Completed_Domestic]
		--,case when up.USER_CLASS_CD = 1 then Audited else 0 end [Audited_Domestic]
	into #results
	from #Detail1
	inner join dbo.USER_PROFILE up on UserID = up.USER_PROFILE_ID
	where
		UserID <> 2
	order by
		Coder
		,Facility;
	

	print 'Section: 10 ' + convert(varchar, getdate(), 121);
	----------------------------------------------------------------------------------------------------------------------------------

	--if @data_select = 'C'
	--begin

		select 
			x.[Date]
			,x.[WeekDay]
			,x.Date_WeekDay
			,x.Coded
			,x.Audited
			,x.Coders
			,dom.Completed_Domestic
			--,x.NumOfCoders
			-- ,x.NumOfCoders * (x.Coded*1.00 / (x.Coded + x.Audited)) [NumOfCoders] -- RACS-2982 DAH 09/21/23 Correction of DIV by 0 Error.
			,case when (x.Coded + x.Audited) = 0 then 0 else x.NumOfCoders * (x.Coded*1.00 / (x.Coded + x.Audited)) end as [NumOfCoders]
		--into ##CodingProductivity
		from
			(
			select 
				r.ADate_TimeZone																				as [Date]
				,datename(weekday,r.ADate_TimeZone)																as [WeekDay]
				,convert(varchar(6),r.ADate_TimeZone,106) + ' - ' + left(datename(weekday,r.ADate_TimeZone),3)	as [Date_WeekDay]
				,sum(r.Completed)																				as [Coded]
				,sum(r.Audited)																					as [Audited]
				,[Coder_Contribution]																			as [Coders]
				--,sum(r.Completed_Domestic)																		as [Completed_Domestic]
				,count(distinct r.UserID)																		as [NumOfCoders]
			from
				#results r
				left join (select ADate_TimeZone, sum([Coder_Contribution]) [Coder_Contribution]
							from (
									select 
										r.ADate_TimeZone
										,r.Coder
										,sum(r.Completed) [Completed]
										,sum(r.Audited) [Audited]
										,case when (sum(Completed) + sum(Audited)) = 0 then 0 
												else (sum(Completed)*1.00 / (sum(Completed) + sum(Audited)))*1.00 end [Coder_Contribution]

									from
										#results r
									group by
										r.ADate_TimeZone
										,r.Coder
									) x
								group by ADate_TimeZone
							) ac on r.ADate_TimeZone = ac.ADate_TimeZone
			group by 
				r.ADate_TimeZone
				,[Coder_Contribution]
			--order by r.ADate_TimeZone
			) x
			left join (select 
							r.ADate_TimeZone																				as [Date]
							,datename(weekday,r.ADate_TimeZone)																as [WeekDay]
							,convert(varchar(6),r.ADate_TimeZone,106) + ' - ' + left(datename(weekday,r.ADate_TimeZone),3)	as [Date_WeekDay]
							,sum(r.Completed)																				as [Completed_Domestic]
						from
							#results_Domestic r
						group by 
							r.ADate_TimeZone) dom on x.[Date] = dom.[Date]
			order by x.[Date]

	--end

	--if @data_select = 'A'
	--begin

		if object_id('TempDB..##AuditProductivity', 'U') is null
		begin
			create table ##AuditProductivity
			(
				[Date] datetime
				,[WeekDay] nvarchar(15)
				,Date_WeekDay varchar(50)
				,Coded int
				,Audited int
				,Auditors decimal(18,6)
				,Audited_Domestic int
				,NumOfAuditors int
				,spid int
			)
		end

		if object_id('TempDB..##AuditProductivity', 'U') is not null
		delete from ##AuditProductivity
		where spid = @spid
		
		insert into ##AuditProductivity
		select 
			x.[Date]
			,x.[WeekDay]
			,x.Date_WeekDay
			,x.Coded
			,x.Audited
			,x.Auditors
			,dom.Audited_Domestic
			,x.NumOfAuditors
			--,(x.Audited*1.00 / (x.Coded + x.Audited))
			,@spid 'spid'
		from
			(
			select 
				r.ADate_TimeZone																				as [Date]
				,datename(weekday,r.ADate_TimeZone)																as [WeekDay]
				,convert(varchar(6),r.ADate_TimeZone,106) + ' - ' + left(datename(weekday,r.ADate_TimeZone),3)	as [Date_WeekDay]
				,sum(r.Completed)																				as [Coded]
				,sum(r.Audited)																					as [Audited]
				,ac.Audit_Contribution																			as [Auditors]
				--,sum(r.Audited_Domestic)																		as [Audited_Domestic]
				,count(distinct case when r.Audited > 0 then r.UserID else null end)							as [NumOfAuditors]
			from
				#results r
				left join (select ADate_TimeZone, sum([Audit_Contribution]) [Audit_Contribution]
							from (
									select 
										r.ADate_TimeZone
										,r.Coder
										,sum(r.Completed) [Completed]
										,sum(r.Audited) [Audited]
										,case when (sum(Completed) + sum(Audited)) = 0 then 0 
												else (sum(Audited)*1.00 / (sum(Completed) + sum(Audited)))*1.00 end [Audit_Contribution]

									from
										#results r
									group by
										r.ADate_TimeZone
										,r.Coder
									) x
								group by ADate_TimeZone
							) ac on r.ADate_TimeZone = ac.ADate_TimeZone
			group by 
				r.ADate_TimeZone
				,ac.Audit_Contribution
			) x
			left join (select 
							r.ADate_TimeZone																				as [Date]
							,datename(weekday,r.ADate_TimeZone)																as [WeekDay]
							,convert(varchar(6),r.ADate_TimeZone,106) + ' - ' + left(datename(weekday,r.ADate_TimeZone),3)	as [Date_WeekDay]
							,sum(r.Audited)																					as [Audited_Domestic]
						from
							#results_Domestic r
						group by 
							r.ADate_TimeZone) dom on x.[Date] = dom.[Date]

	--end

	--if @data_select = 'DOW'
	--begin

		if object_id('TempDB..##DOW_ProdTrending', 'U') is null
		begin
			create table ##DOW_ProdTrending
			(
				[Week] varchar(50)
				,[WeekStartSort] datetime
				,[WeekStart] datetime
				,[WeekDayPart] int
				,[WeekDay] nvarchar(50)
				,[Completed] int
				,spid int
			)
		end

		if object_id('TempDB..##DOW_ProdTrending', 'U') is not null
		delete from ##DOW_ProdTrending
		where spid = @spid
		
		insert into ##DOW_ProdTrending
		select 
			'Week ' + cast(dense_rank() over(order by dateadd(wk, datediff(wk, 0, r.ADate_TimeZone), -1)) as varchar)	as [Week]
			,dateadd(wk, datediff(wk, 0, r.ADate_TimeZone), -1)															as [WeekStartSort]
			,dateadd(wk, datediff(wk, 0, r.ADate_TimeZone), -1)															as [WeekStart]
			,datepart(weekday,r.ADate_TimeZone)																			as [WeekDayPart]
			,datename(weekday,r.ADate_TimeZone)																			as [WeekDay]
			,sum(r.Completed)																							as [Completed]
			,@spid 'spid'
		from
			#results r
		group by 
			datepart(week, r.ADate_TimeZone)
			,dateadd(wk, datediff(wk, 0, r.ADate_TimeZone), -1)
			,datepart(weekday, r.ADate_TimeZone)
			,datename(weekday, r.ADate_TimeZone)
		order by [WeekStart], WeekDayPart

	--end

	--if @data_select = 'P'
	--begin

		if object_id('TempDB..##ProductivityStatus', 'U') is null
		begin
			create table ##ProductivityStatus
			(
				[Date] datetime
				,Coder varchar(55)
				,[Completed] int
				,[Audited] int
				,[Pended] int
				,[Total] int
				,[Productivity_Status] decimal(18,6)
				,spid int
			)
		end

		if object_id('TempDB..##ProductivityStatus', 'U') is not null
		delete from ##ProductivityStatus
		where spid = @spid
		
		insert into ##ProductivityStatus
		select 
			r.ADate_TimeZone [Date]
			,r.Coder
			,sum(r.Completed) [Completed]
			,sum(r.Audited) [Audited]
			,sum(r.Pended) [Pended]
			,sum(r.Total) [Total]
			,case when (sum(r.Completed) / 80.00) + (sum(r.Audited) / 90.00) <= 0 
					then null else (sum(r.Completed) / 80.00) + (sum(r.Audited) / 90.00) end [Productivity_Status]
			,@spid 'spid'
		from
			#results r
		group by 
			r.ADate_TimeZone
			,r.Coder

	--end

	--if @data_select = 'D'
	--begin

		if object_id('TempDB..##ProductionDetails', 'U') is null
		begin
			create table ##ProductionDetails
			(
				Coder varchar(55)
				,[Coded] int
				,[Audited] int
				,[Pended] int
				,[Total] int
				,[Coder_Contribution] decimal(18,6)
				,[Audit_Contribution] decimal(18,6)
				,spid int
			)
		end

		if object_id('TempDB..##ProductionDetails', 'U') is not null
		delete from ##ProductionDetails
		where spid = @spid
		
		insert into ##ProductionDetails
		select 
			r.Coder
			,sum(r.Completed)																				as [Coded]
			,sum(r.Audited)																					as [Audited]
			,sum(r.Pended)																					as [Pended]
			,sum(r.Completed) + sum(r.Audited) + sum(r.Pended)												as [Total]
			,cast(cc.[Coder_Contribution] as decimal(18,6))													as [Coder_Contribution]
			,cast(ac.[Audit_Contribution] as decimal(18,6))													as [Audit_Contribution]
			,@spid 'spid'
		from
			#results r
			left join (select UserID, Coder, sum([Coder_Contribution]) [Coder_Contribution]
						from (
								select 
									r.UserID
									,r.Coder
									,sum(r.Completed) [Completed]
									,sum(r.Audited) [Audited]
									,case when (sum(Completed) + sum(Audited)) = 0 then 0 
											else (sum(Completed)*1.00 / (sum(Completed) + sum(Audited)))*1.00 end [Coder_Contribution]

								from
									#results r
								group by
									r.UserID
									,r.Coder
								) x
							group by UserID, Coder
						) cc on r.UserID = cc.UserID
			left join (select UserID, Coder, sum([Audit_Contribution]) [Audit_Contribution]
						from (
								select 
									r.UserID
									,r.Coder
									,sum(r.Completed) [Completed]
									,sum(r.Audited) [Audited]
									,case when (sum(Completed) + sum(Audited)) = 0 then 0 
											else (sum(Audited)*1.00 / (sum(Completed) + sum(Audited)))*1.00 end [Audit_Contribution]

								from
									#results r
								group by
									r.UserID
									,r.Coder
								) x
							group by UserID, Coder
						) ac on r.UserID = ac.UserID
		group by 
			r.Coder
			,cc.Coder_Contribution
			,ac.Audit_Contribution

	--end

	--if @data_select = 'DD'
	--begin

		if object_id('TempDB..##DomesticDetails', 'U') is null
		begin
			create table ##DomesticDetails
			(
				Coder varchar(55)
				,[Coded] int
				,[Audited] int
				,[Pended] int
				,[Total] int
				,[Coder_Contribution] decimal(18,6)
				,[Audit_Contribution] decimal(18,6)
				,spid int
			)
		end

		if object_id('TempDB..##DomesticDetails', 'U') is not null
		delete from ##DomesticDetails
		where spid = @spid

		insert into ##DomesticDetails
		select 
			r.Coder
			,sum(r.Completed)																				as [Coded]
			,sum(r.Audited)																					as [Audited]
			,sum(r.Pended)																					as [Pended]
			,sum(r.Completed) + sum(r.Audited) + sum(r.Pended)												as [Total]
			,cast(cc.[Coder_Contribution] as decimal(18,6))													as [Coder_Contribution]
			,cast(ac.[Audit_Contribution] as decimal(18,6))													as [Audit_Contribution]
			,@spid 'spid'
		from
			#results_Domestic r
			left join (select UserID, Coder, sum([Coder_Contribution]) [Coder_Contribution]
						from (
								select 
									r.UserID
									,r.Coder
									,sum(r.Completed) [Completed]
									,sum(r.Audited) [Audited]
									,case when (sum(Completed) + sum(Audited)) = 0 then 0 
											else (sum(Completed)*1.00 / (sum(Completed) + sum(Audited)))*1.00 end [Coder_Contribution]

								from
									#results_Domestic r
								group by
									r.UserID
									,r.Coder
								) x
							group by UserID, Coder
						) cc on r.UserID = cc.UserID
			left join (select UserID, Coder, sum([Audit_Contribution]) [Audit_Contribution]
						from (
								select 
									r.UserID
									,r.Coder
									,sum(r.Completed) [Completed]
									,sum(r.Audited) [Audited]
									,case when (sum(Completed) + sum(Audited)) = 0 then 0 
											else (sum(Audited)*1.00 / (sum(Completed) + sum(Audited)))*1.00 end [Audit_Contribution]

								from
									#results_Domestic r
								group by
									r.UserID
									,r.Coder
								) x
							group by UserID, Coder
						) ac on r.UserID = ac.UserID
		group by 
			r.Coder
			,cc.Coder_Contribution
			,ac.Audit_Contribution

	--end


	print 'Section: 11 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------

end


	----drop table ##CodingProductivity
	--drop table ##AuditProductivity
	--drop table ##DOW_ProdTrending
	--drop table ##ProductivityStatus
	--drop table ##ProductionDetails
	--drop table ##DomesticDetails


	----select * from ##CodingProductivity
	--select 
	--	Date
	--	,WeekDay
	--	,Date_WeekDay
	--	,Coded
	--	,Audited
	--	,Auditors
	--	,Audited_Domestic
	--	,NumOfAuditors
	--from 
	--	##AuditProductivity
	--where
	--	spid = @spid

	--select 
	--	Week
	--	,WeekStartSort
	--	,WeekStart
	--	,WeekDayPart
	--	,WeekDay
	--	,Completed
	--from 
	--	##DOW_ProdTrending
	--where
	--	spid = @spid
	
	--select 
	--	Date
	--	,Coder
	--	,Completed
	--	,Audited
	--	,Pended
	--	,Total
	--	,Productivity_Status
	--from 
	--	##ProductivityStatus
	--where
	--	spid = @spid
	
	--select 
	--	Coder
	--	,Coded
	--	,Audited
	--	,Pended
	--	,Total
	--	,Coder_Contribution
	--	,Audit_Contribution
	--from 
	--	##ProductionDetails
	--where
	--	spid = @spid
	
	--select 
	--	Coder
	--	,Coded
	--	,Audited
	--	,Pended
	--	,Total
	--	,Coder_Contribution
	--	,Audit_Contribution
	--from 
	--	##DomesticDetails
	--where
	--	spid = @spid

GO
GRANT EXECUTE ON  [dbo].[rpt_GlobalCoderProductivityReport] TO [dbx_ExecuteReportProcs]
GO
