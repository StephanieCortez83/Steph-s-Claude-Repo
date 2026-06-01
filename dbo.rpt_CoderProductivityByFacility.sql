SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[rpt_CoderProductivityByFacility] 
	@TimeZone varchar(25),
	@Organization varchar(max),
	@Facility varchar(max),
	@StartDate datetime,
	@EndDate datetime,
	@ReportUser int,
	@UserGroup varchar(max),
	@ExcludeAutomation int
AS
BEGIN

	-- /Reports/Operations/Coder Productivity by Facility Report

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	print 'Section: 00 - Start' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	/* -- Sample Test Parameters:

	declare @TimeZone varchar(25) = 'Central Daylight Time'
	declare @Organization varchar(max) = '-1'
	declare @Facility varchar(max) = '-1'
	declare @StartDate datetime = '9/1/2021';
	declare @EndDate datetime =  '9/8/2021';
	declare @ReportUser int = 80;
	declare @UserGroup varchar(max) = '201,202,203'	
	declare @ExcludeAutomation int = 0;		--  1 Yes, 0 No  (default = 0)
	*/


	declare @CTOffSet VARCHAR(9) = (select CT_OFFSET from TIME_ZONE where DESCRIPTION=@TimeZone);
	declare @Operator varchar(1) = substring(@CTOffSet, 1, 1);
	declare @hms varchar(8) = substring(@CTOffSet, 2, LEN(@CTOffSet)-1) 
	declare @hours decimal(10,2) = datepart(hour, @hms)
	declare @minutes decimal(10,2) = datepart(minute, @hms)
	declare @HrsOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(hour, @hms)) as decimal(10,2))
	declare @MinOffSet decimal(10,2) = cast(@Operator + convert(varchar, datepart(minute, @hms)) as decimal(10,2))


	if object_id('TempDB..#UserGroup1', 'U') is not null drop table #UserGroup1;

				select t1.USER_PROFILE_ID, t1.USER_GROUP_ID
				into #UserGroup1
				from
				(
				SELECT USER_PROFILE_ID, USER_GROUP_ID							
				FROM USER_PROFILE				
				WHERE 
				--USER_GROUP_ID in (@UserGroup)														-- replaced with line below. dsexton 9/23/2022
					User_Group_ID in (select items from SplitString(@UserGroup, ','))				

				UNION											
				SELECT ugup.USER_PROFILE_ID, ugup.USER_GROUP_ID			
				FROM USER_GROUP_TO_USER_PROFILE ugup				
				where 
				--ugup.USER_GROUP_ID in (@UserGroup)												-- replaced with line below. dsexton 9/23/2022
					ugup.User_Group_ID in (select items from SplitString(@UserGroup, ','))			

				) t1				

	print 'Section: 01 - #UserGroup1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	if object_id('TempDB..#Facility1', 'U') is not null drop table #Facility1;

	select distinct 
	t1.facility_id,
	t1.NAME 
	into #Facility1
	from ( 

	select distinct f.facility_id, f.NAME 
	from SERVICE_AGREEMENT sa  WITH (NOLOCK),								
	FACILITY f  WITH (NOLOCK)								
	where 								
	f.facility_id = sa.facility_ID	
							
	--and ((-1 in (@Organization)) or (sa.company_id in (@Organization)) )									-- replaced with line below. dsexton 9/23/2022
	and (@Organization = '-1' or sa.company_id in (select items from SplitString(@Organization, ',')))		

	--and   ((f.FACILITY_ID in (@Facility)) or (-1 in (@Facility)) )										-- replaced with line below. dsexton 9/23/2022
	and (@Facility = '-1' or f.FACILITY_ID in (select items from SplitString(@Facility, ',')))				

	and sa.DEMO_TEST_SITE_IND = 0		
	  and ( @StartDate between sa.EFFECTIVE_DATE and DateAdd(second, 86399,sa.EXPIRATION_DATE)
		 or @EndDate between sa.EFFECTIVE_DATE and DateAdd(second, 86399,sa.EXPIRATION_DATE) )							
	and EXISTS (								
			SELECT *						
			FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
			USER_PROFILE UP	WITH (NOLOCK)					
			WHERE FUA.FACILITY_ID = f.FACILITY_ID						
			AND fua.user_profile_id = up.user_profile_id						
			AND UP.IS_ACTIVE = 'Y'						
			and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
			AND FUA.USER_PROFILE_ID = @ReportUser						
			)	

	union -- AAR-1694 include Tenet Practice Charts

	select distinct f.facility_id, f.NAME 
	from SERVICE_AGREEMENT sa  WITH (NOLOCK),								
	FACILITY f  WITH (NOLOCK)								
	where 								
	f.facility_id = sa.facility_ID
	and sa.company_id = 19	
							
	--and ((-1 in (@Organization)) or (sa.company_id in (@Organization)) )									-- replaced with line below. dsexton 9/23/2022
	and (@Organization = '-1' or sa.company_id in (select items from SplitString(@Organization, ',')))		
	
	--and   ((f.FACILITY_ID in (@Facility)) or (-1 in (@Facility)) )										-- replaced with line below. dsexton 9/23/2022
	and (@Facility = '-1' or f.FACILITY_ID in (select items from SplitString(@Facility, ',')))				

	  and ( @StartDate between sa.EFFECTIVE_DATE and DateAdd(second, 86399,sa.EXPIRATION_DATE)
		 or @EndDate between sa.EFFECTIVE_DATE and DateAdd(second, 86399,sa.EXPIRATION_DATE) )							
	and EXISTS (								
			SELECT *						
			FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),						
			USER_PROFILE UP	WITH (NOLOCK)					
			WHERE FUA.FACILITY_ID = f.FACILITY_ID						
			AND fua.user_profile_id = up.user_profile_id						
			AND UP.IS_ACTIVE = 'Y'						
			and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE						
			AND FUA.USER_PROFILE_ID = @ReportUser						
			)								
	) as t1

	print 'Section: 02 - #Facility1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- Pended - Pull

	if object_id('TempDB..#LogNote1', 'U') is not null drop table #LogNote1;

	SELECT *    
	INTO #LogNote1
	FROM (
	select 
	ln.chart_id,
	dateadd(day, datediff(day, 0, ln.completion_date), 0) ADate,
  
	  ln.completion_date ,
	  ln.creation_date_time,
	coder.LAST_NAME + ', ' + coder.FIRST_NAME Coder, 
	  ln.completed_by_user_id ,
	  ln.category_id,
	 -- ln.Summary as SUMMARY,						-- removed because this column is not subsequently used and it increases LReads by nearly 2M for large data sets.  9/23/2022, dsexton
	  1 as Pended

	from LOG_NOTE LN WITH (NOLOCK) 
	left join USER_PROFILE coder with(nolock) on coder.USER_PROFILE_ID=ln.COMPLETED_BY_USER_ID
	where 
	ln.category_id = 6  -- Chart pended

	-- and ln.CREATION_DATE_TIME between @StartDate and DateAdd(second, 86399,@EndDate)

	--and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, ln.CREATION_DATE_TIME ))), 0) >= @StartDate							-- replaced with lines below. 9/23/2022, dsexton
	--and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, ln.CREATION_DATE_TIME ))), 0) <= dateadd(second, 86399, @EndDate)

		and ln.CREATION_DATE_TIME between dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, @StartDate ))	-- 9/23/2022 dsexton: applying the date functions to the variables instead of the table column reduced LReads for this query by 99% (by 450K with large parameters).
			and dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, dateadd(second, 86399, @EndDate) ))

	)t2;


	print 'Section: 03 - #LogNote1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	if object_id('TempDB..#Detail1', 'U') is not null drop table #Detail1;

	create table #Detail1
	(			
		ADate		datetime,
		Facility	varchar(50),
		FacilityID  int,
		Coder       varchar(55),
		UserID      int,
		Completed   int,
		Audited		int,
		Pended		int
	)

	print 'Section: 04 - #Detail1 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	-- Pended - Insert

	 insert into #Detail1
	 select 
			 ln1.ADate,
			 f.[NAME] Facility,
			 f.FACILITY_ID FacilityID,
			 ln1.Coder,
			 ln1.completed_by_user_id UserID,
			 0 as Completed,
			 0 as Audited,
			 sum(ln1.Pended) as Pended
	  from 
	  #LogNote1 ln1,
	  chart c with(nolock)
	  join FACILITY f with(nolock) on f.FACILITY_ID = c.FACILITY_ID
	  where 
	  ln1.chart_id = c.chart_id
	AND  EXISTS (select 1 from #UserGroup1 where USER_PROFILE_ID = ln1.completed_by_user_id )   
	AND  EXISTS (select 1 from #Facility1 where facility_id = c.FACILITY_ID )

	  group by 
	   ln1.ADate,
	   f.[NAME] ,
	   f.FACILITY_ID ,
	   ln1.Coder,
	   ln1.completed_by_user_id  
    
	print 'Section: 05 - Pended ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- Completed - Pull

	if object_id('TempDB..#chart1', 'U') is not null drop table #chart1;
	if object_id('TempDB..#chart_list', 'U') is not null drop table #chart_list;

	select chart_id

		--, FacACNull = case when Facility_AUTOMATION_CODING_RECEIVED_DATE_TIME is null then 1 else 0 end		-- this tuning experiment didn't work: 9M LReads vs 9K	9/23/2022, dsexton
		--, PhysACNull = case when PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME is null then 1 else 0 end		-- this tuning experiment didn't work: 9M LReads vs 9K  9/23/2022, dsexton	

	into #chart_list
	from
		CHART c     
	where
		c.CHART_STATUS_ID in (3, 4, 5, 8) 	

	--and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.COMPLETION_DATE ))), 0) >= @StartDate			-- replaced as noted below.  9/23/2022, dsexton
	--and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.COMPLETION_DATE ))), 0) <= dateadd(second, 86399, @EndDate)

	and c.COMPLETION_DATE between dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, @StartDate ))	-- 9/23/2022 dsexton: applying the date functions to the variables instead of the table column reduced LReads by 50K for this part of the query.
	and dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, dateadd(second, 86399, @EndDate) ))


		create nonclustered index idx_CUID on #chart_list (chart_id)

	print 'Section: 06A - Completed Pull ' + convert(varchar, getdate(), 121)

	----------------------------------------------------------------------------------------------------

	-- Build the temp table													-- added 9/23/2022, dsexton
	select
		dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) ADate,  
		facility_id,
		COMPLETED_BY_USER_PROFILE_ID,
		Completed = sum(1) 
	into #chart1
	from
		CHART c     
	where chart_ID in (select TOP 1 chart_ID from #chart_list)
	group by 
		dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) ,  
		facility_id,
		COMPLETED_BY_USER_PROFILE_ID

	TRUNCATE TABLE #chart1													-- added 9/23/2022, dsexton

	if @ExcludeAutomation = 1		-- separating the INSERT through @ExcludeAutomation using IF statements instead of CASE reduces LReads by nearly 8M when @ExcludeAutomation = 0 (99% of executions).  9/23/2022, dsexton
		insert into #chart1
		select
			dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) ADate,  
			facility_id,
			COMPLETED_BY_USER_PROFILE_ID,

			-- this CASE is by far the most expensive section.  Without it, the INSERT query generates only 500K LReads vs 8M. But it can't be tuned unless other columns (already indexed) can be used for filtering instead of CODER_COMMENT and the two Automation columns.  9/23/2022, dsexton
			Completed = sum(
							case 
								when (c.TIME_OF_SERVICE < '11/06/2021' and CODER_COMMENT like '%**Automation**%') then 0
								when (c.TIME_OF_SERVICE >= '11/06/2021' 
										and (FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL
												or PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL)
										) then 0 
   								else 1 
							end
							) 
		from
			CHART c     
		where chart_ID in (select chart_ID from #chart_list)
			--exists( select chart_id from #chart_list where chart_id = c.chart_id)				-- replaced with line above. 9/23/2022, dsexton
		group by 
			dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) ,  
			facility_id,
			COMPLETED_BY_USER_PROFILE_ID

	ELSE
		insert into #chart1
		select
			dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) ADate,  
			facility_id,
			COMPLETED_BY_USER_PROFILE_ID,
			Completed = sum(1) 
		from
			CHART c     
		where chart_ID in (select chart_ID from #chart_list)
			--exists( select chart_id from #chart_list where chart_id = c.chart_id)				-- replaced with line above. 9/23/2022, dsexton
		group by 
			dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) ,  
			facility_id,
			COMPLETED_BY_USER_PROFILE_ID


	print 'Section: 06B - Complete Process ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------  

	-- Completed

	insert into #Detail1
	 select 
			 c.ADate,
			 f.[NAME] Facility,
			 c.FACILITY_ID FacilityID,
			 up.LAST_NAME + ', ' + up.FIRST_NAME as Coder,
			 c.COMPLETED_BY_USER_PROFILE_ID UserID,
			 sum(c.Completed) as Completed,
			 0 as Audited,
			 0 as Pended
	  from 
	  #chart1 c 
	  join FACILITY f with(nolock) on f.FACILITY_ID = c.FACILITY_ID
	  left join USER_PROFILE up  on up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
	  where 
		 EXISTS (select 1 from #UserGroup1 where USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID )  
	AND  EXISTS (select 1 from #Facility1 where facility_id = c.FACILITY_ID )

	  group by 
	   c.ADate,
	   f.[NAME] ,
	   c.FACILITY_ID ,
	   up.LAST_NAME + ', ' + up.FIRST_NAME,
	   c.COMPLETED_BY_USER_PROFILE_ID 


	print 'Section: 06C - Completed Insert ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------  


	-- Audited
	 insert into #Detail1
	  select dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0) ADate,
			 f.[NAME] Facility,
			 f.FACILITY_ID FacilityID,
			 auditor.LAST_NAME + ', ' + auditor.FIRST_NAME Coder,
			 auditor.USER_PROFILE_ID UserID,
			 0 as Completed,
			 sum(case when c.APPROVED_BY_USER_PROFILE_ID=auditor.USER_PROFILE_ID THEN 1 ELSE 0 end) Audited,
			 0 as Pended

	  from chart c with(nolock)
		join FACILITY f with(nolock) on f.FACILITY_ID = c.FACILITY_ID
		left join USER_PROFILE auditor with(nolock) on auditor.USER_PROFILE_ID=c.APPROVED_BY_USER_PROFILE_ID
	  where c.chart_status_id in (3, 4, 5, 8)
	AND c.[START_QA_DATE] is not null       -- excludes Pushed Charts
	and  c.APPROVED_BY_USER_PROFILE_ID <> 2 -- excludes Pushed Charts
	AND  EXISTS (select 1 from #UserGroup1 where USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID )  
	AND  EXISTS (select 1 from #Facility1 where facility_id = c.FACILITY_ID )

	--AND  c.APPROVED_DATE between @StartDate and DateAdd(second, 86399, @EndDate)

	--and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE ))), 0) >= @StartDate		-- replaced as stated below.  9/23/2022, dsexton
	--and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.APPROVED_DATE ))), 0) <= dateadd(second, 86399, @EndDate)

		and c.Approved_Date between dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, @StartDate ))		-- 9/23/2022 dsexton: applying the date functions to the variables instead of the table column reduced LReads by 20K for this part of the query.
			and dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, dateadd(second, 86399, @EndDate) ))

	group by 
	dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0), f.[NAME], 
	f.FACILITY_ID, auditor.USER_PROFILE_ID, auditor.LAST_NAME + ', ' + auditor.FIRST_NAME


	print 'Section: 07 - Audited ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	-- Output 

	select
		d.ADate
		,d.Coder
		,d.UserID
		,d.Facility
		,d.FacilityID
		,d.Completed
		,d.Audited
		,d.Pended
		,d.Completed + d.Audited + d.Pended as [Total]
		,o.[DESCRIPTION]					as [Organization]
	from
		#Detail1 d
		inner join dbo.SERVICE_AGREEMENT sa on d.FacilityID = sa.FACILITY_ID
		inner join dbo.ORGANIZATION o on sa.ORGANIZATION_ID = o.ORGANIZATION_ID
	where
		d.UserID <> 2
	order by
		d.Coder
		,d.Facility;

END
GO
