SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[rpt_AutomationFLOSSelectionAnalysis_Points]
(
@ReportUser    int
,@Organization varchar(max)
,@Facility     varchar(max)
,@DateType     int
,@StartDate    datetime
,@EndDate      datetime
,@FacSvcMethod int
)
as

begin

	set transaction isolation level read uncommitted;

	--declare
	--	@ReportUser    int      = 80
	--	,@Organization int      = 228
	--	,@Facility     int      = 1341        -- -1 All
	--	,@DateType     int      = 0          -- 0 DOS, 1 Sent
	--	,@StartDate    datetime = '20231001'
	--	,@EndDate      datetime = '20231031' --;
	--	,@FacSvcMethod int      = 1;         -- 0=Points Method, 1=Intervention


	-------------------------------------------------------------------------------------

	if object_id('TempDB..#temp', 'U') is not null drop table #temp;
	if object_id('TempDB..#chart_temp', 'U') is not null drop table #chart_temp;
	if object_id('TempDB..#Level', 'U') is not null drop table #Level;
	if object_id('TempDB..#Total_POINT_PROD', 'U') is not null drop table #Total_POINT_PROD;
	if object_id('TempDB..#Final1', 'U') is not null drop table #Final1;
	if object_id('TempDB..#Final2', 'U') is not null drop table #Final2;
	if object_id('TempDB..#Final3', 'U') is not null drop table #Final3;
	if object_id('TempDB..#Total_POINT_CHART', 'U') is not null drop table #Total_POINT_CHART;
	if object_id('TempDB..#LogNote1', 'U') is not null drop table #LogNote1;


	--------------------------------------------------------------------------------------
	-- Temp Level Table

	select
		t1.Level
		,t1.Level_Min
		,t1.Level_Max
	into
		#Level
	from
	(
		select
			1  as Level
			,0 as Level_Min
			,2 as Level_Max
		union all
		select
			2  as Level
			,3 as Level_Min
			,5 as Level_Max
		union all
		select
			3   as Level
			,6  as Level_Min
			,12 as Level_Max
		union all
		select
			4   as Level
			,13 as Level_Min
			,20 as Level_Max
		union all
		select
			5   as Level
			,21 as Level_Min
			,99 as Level_Max
	) t1;




	----------------------------------------------------------------------------


	if object_id('TempDB..#Facility', 'U') is not null
		drop table #Facility;

	select distinct
		f.FACILITY_ID
	into
		#Facility
	from
		dbo.FACILITY                     f
		inner join dbo.SERVICE_AGREEMENT                sa on f.FACILITY_ID = sa.FACILITY_ID
		inner join dbo.SERVICE_AGREEMENT_FACILITY_EM_METHOD saf on sa.SERVICE_AGREEMENT_ID = saf.SERVICE_AGREEMENT_ID
	where
		sa.DEMO_TEST_SITE_IND = 0
		and getdate() between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
		and saf.FACILITY_EM_METHOD_ID = @FacSvcMethod -- 0=Points Method, 1=Intervention
		and sa.COMPANY_ID in ( select items from dbo.SplitString(@Organization, ',') ) --in (@Organization)
		and
		(
			sa.FACILITY_ID in ( select items from dbo.SplitString(@Facility, ',') ) --in (@Facility)
			or -1 in ( select items from dbo.SplitString(@Facility, ',') ) --in (@Facility)
		)
		and exists
	(
		select
			*
		from
			FACILITY_USER_AUTHORIZATION FUA with (nolock)
			,USER_PROFILE UP with (nolock)
		where
			FUA.FACILITY_ID = sa.FACILITY_ID
			and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
			and ( UP.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR UP.IS_ACTIVE = 'Y' ) 
			and FUA.USER_PROFILE_ID = @ReportUser
	);



	create nonclustered index idx_FACILITY_ID on #Facility (FACILITY_ID);
	----------------------------------------------------------------------------

	select
		c.FACILITY_ID
		,c.CHART_ID
		,c.FACILITY_CHART_ID
		,c.TIME_OF_SERVICE
		,c.SENT_DATE
		,c.FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT
		,c.Coder_Comment
	into #chart_temp
	from
		dbo.CHART c
	where
		c.FACILITY_ID in
		(
			select FACILITY_ID from #Facility
		)
		and isnull(c.FACILITY_AUTOMATION_CODING_COMPLETE, 0) > 0
		and
		(
			@DateType = 0
			and c.TIME_OF_SERVICE between @StartDate and dateadd(second, 86399, @EndDate)
			or @DateType = 1
			   and c.SENT_DATE between @StartDate and dateadd(second, 86399, @EndDate)
		)
		/*** check to validate that a CHART_AUTOMATION record exists ***/
		and exists
		(
			select
				c_auto.CHART_ID
			from
				dbo.CHART_AUTOMATION c_auto
			where
				c.CHART_ID = c_auto.CHART_ID
		);

		---- TESTING ----
		--and c.CHART_ID = '110870822'


	-------------------------------------------------------------------------------

	select
		'Prod'              as 'Source'
		,fse.[CHART_ID]
		,fse.[FACILITY_SERVICE_ID]
		,fse.[FACILITY_SERVICE_SCHEDULE_ID]
		,fse.[FACILITY_SERVICE_SCHEDULE_ITEM_ID]
		,fssi.[DESCRIPTION] [ITEM]
		,fssi.POINTS
		,1                  [COUNT]
		,ct.FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT
	into #temp
	from
		#chart_temp                    ct
		inner join dbo.FACILITY_SERVICE_EVALUATION    fse on ct.CHART_ID = fse.CHART_ID
		left join dbo.FACILITY_SERVICE_SCHEDULE_ITEM fssi on fssi.[FACILITY_SERVICE_SCHEDULE_ID] = fse.[FACILITY_SERVICE_SCHEDULE_ID]
											   and fssi.[FACILITY_SERVICE_SCHEDULE_ITEM_ID] = fse.[FACILITY_SERVICE_SCHEDULE_ITEM_ID]
	union all
	select
		'Log'               as 'Source'
		,fse_auto.[CHART_ID]
		,fse_auto.[FACILITY_SERVICE_ID]
		,fse_auto.[FACILITY_SERVICE_SCHEDULE_ID]
		,fse_auto.[FACILITY_SERVICE_SCHEDULE_ITEM_ID]
		,fssi.[DESCRIPTION] [ITEM]
		,fssi.POINTS
		,1                  [COUNT]
		,ct.FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT
	from
		#chart_temp                            ct
		inner join dbo.FACILITY_SERVICE_EVALUATION_AUTOMATION fse_auto on ct.CHART_ID = fse_auto.CHART_ID
		left join dbo.FACILITY_SERVICE_SCHEDULE_ITEM         fssi on fssi.[FACILITY_SERVICE_SCHEDULE_ID] = fse_auto.[FACILITY_SERVICE_SCHEDULE_ID]
													   and fssi.[FACILITY_SERVICE_SCHEDULE_ITEM_ID] = fse_auto.[FACILITY_SERVICE_SCHEDULE_ITEM_ID];






	select
		CHART_ID
		,sum(POINTS) as Points
	into #Total_POINT_PROD
	from
		#temp
	where
		[Source] = 'Prod'
	group by
		CHART_ID;

		




	----------------------------------------------------------------------------------

	select
		CHART_ID
		,LOG_NOTE_ID
		,COMPLETION_DATE
		,substring(DETAIL, charindex('CC Min', DETAIL) - 10, 20)                           as Detail
		,rank() over (partition by CHART_ID order by COMPLETION_DATE asc, LOG_NOTE_ID asc) ln_rank
	into #LogNote1
	from
		[dbo].[LOG_NOTE]
	where
		CATEGORY_ID = 16
		and charindex('CC minutes', Detail, 1) > 0
		and CHART_ID in
			(
				select CHART_ID from #chart_temp
			);

	delete #LogNote1
	where
		ln_rank <> 1;






	select
		1                                                                                                              as All_Data
		,ct.FACILITY_ID
		,f.[NAME]                                                                                                      [FACILITY]
		,substring(f.NAME, charindex('-', f.NAME) + 2, 20)                                                             as TabName
		,a.CHART_ID
		,ct.FACILITY_CHART_ID
		,ct.TIME_OF_SERVICE                                                                                            [DOS]
		,ct.SENT_DATE
		,a.FACILITY_SERVICE_SCHEDULE_ITEM_ID
		,a.ITEM
		,a.[CHANGES]
		,(
			 select
				 count(1)
			 from
				 #temp t
			 where
				 a.CHART_ID = t.CHART_ID
				 and a.FACILITY_SERVICE_SCHEDULE_ITEM_ID = t.FACILITY_SERVICE_SCHEDULE_ITEM_ID
				 and t.[Source] = 'Log'
		 )                                                                                                             [Automation_Sent]
		,case when b.[Source] = 'Prod' then 1 else 0 end                                                               [Coder_Added]
		,case when b.[Source] = 'Log' then 1 else 0 end                                                                [Coder_Removed]
		,a.POINTS
		,(
			 select Points from #Total_POINT_PROD where CHART_ID = a.CHART_ID
		 )                                                                                                             TotalBeforePoints
		,case
			 when b.[Source] = 'Log' then ((
											   select Points from #Total_POINT_PROD where CHART_ID = a.CHART_ID
										   ) - case when @FacSvcMethod = 0 then a.POINTS 
													when @FacSvcMethod = 1 and b.[COUNT] = 1 then a.POINTS
												else 0 end
										  )
		 else 0 end                                                                                                    as NewTotalAfterRemoved
		,case
			 when b.[Source] = 'Prod' then
		((
			 select Points from #Total_POINT_PROD where CHART_ID = a.CHART_ID
		 ) + case when @FacSvcMethod = 0 then a.POINTS 
					when @FacSvcMethod = 1 and b.[COUNT] = 1 then a.POINTS
				else 0 end
		)
		 else 0 end                                                                                                    as NewTotalAfterAdded
		,ct.FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT
		,substring(ct.Coder_Comment, charindex('DOCUMENT QUALITY (DEPART SUMMARY MISSING)', ct.Coder_Comment) - 3, 49) as CoderComment
		,case
			 when charindex('DOCUMENT QUALITY (DEPART SUMMARY MISSING)', ct.Coder_Comment, 1) > 0 then 1
		 else 0 end                                                                                                    as CoderComment_ExcludeChart
		,(
			 select ln.Detail from #LogNote1 ln where ln.CHART_ID = ct.CHART_ID
		 )                                                                                                             as LN_Details
	into #Final1
	from
	(
		select
			t.CHART_ID
			,t.FACILITY_SERVICE_SCHEDULE_ITEM_ID
			,t.ITEM
			,t.POINTS
			,sum(t.[COUNT]) [CHANGES]
		from
			#temp t
		group by
			t.CHART_ID
			,t.FACILITY_SERVICE_SCHEDULE_ITEM_ID
			,t.ITEM
			,t.POINTS
	)            a
	inner join #chart_temp  ct on a.CHART_ID = ct.CHART_ID
	inner join dbo.FACILITY f on ct.FACILITY_ID = f.FACILITY_ID
	left join #temp        b on a.CHART_ID = b.CHART_ID
					  and a.FACILITY_SERVICE_SCHEDULE_ITEM_ID = b.FACILITY_SERVICE_SCHEDULE_ITEM_ID
					  and a.[CHANGES] = 1;


	update
		#Final1
	set
		CoderComment = null
	where
		CoderComment_ExcludeChart = 0;



	----------------------------------------------------------------------------------

	create table #Total_POINT_CHART
	(
	CHART_ID int
	,FACILITY_SERVICE_SCHEDULE_ITEM_ID int
	,TotalBeforePoints int
	,AddedTotal int
	,RemovedTotal int
	,TotalChartAfterPoints int
	)


	if @FacSvcMethod = 0
	begin

		insert into #Total_POINT_CHART
		select
			CHART_ID
			,null
			,TotalBeforePoints
			,sum(case when Coder_Added = 1 then POINTS else 0 end)     as AddedTotal
			,sum(case when Coder_Removed = 1 then POINTS else 0 end)   as RemovedTotal
			,TotalBeforePoints + sum(case when Coder_Added = 1 then POINTS else 0 end)
			 - sum(case when Coder_Removed = 1 then POINTS else 0 end) as TotalChartAfterPoints
		from
			#Final1
		group by
			CHART_ID
			,TotalBeforePoints;

	end
	else
	begin

		insert into #Total_POINT_CHART
		select
			CHART_ID
			,FACILITY_SERVICE_SCHEDULE_ITEM_ID
			,POINTS TotalBeforePoints
			,null as AddedTotal
			,null as RemovedTotal
			,POINTS TotalChartAfterPoints
		from
			#Final1
		--group by
		--	CHART_ID
		--	,TotalBeforePoints;

	end

		
	




	select
		f.*
		,(
			 select
				 --Level
				 case when @FacSvcMethod = 1 then f.POINTS else Level end Level
			 from
				 #Level l
			 where
				 f.TotalBeforePoints between Level_Min and Level_Max
		 )             as Before_Level
		,tpc.TotalChartAfterPoints
		,(
			 select
				 --Level
				 case when @FacSvcMethod = 1 then tpc.TotalChartAfterPoints else Level end Level
			 from
				 #Level l
			 where
				 tpc.TotalChartAfterPoints between Level_Min and Level_Max
		 )             as After_Level
		,case
			 when Coder_Added = 1 then
			 (
				 select
					 Level
				 from
					 #Level l
				 where
					 f.NewTotalAfterAdded between Level_Min and Level_Max
			 )
		 else null end as New_Level_Add
		,case
			 when Coder_Removed = 1 then
			 (
				 select
					 Level
				 from
					 #Level l
				 where
					 f.NewTotalAfterRemoved between Level_Min and Level_Max
			 )
		 else null end as New_Level_Remove
	into #Final2
	from
		#Final1        f
		left outer join #Total_POINT_CHART tpc on f.CHART_ID = tpc.CHART_ID--;
			and f.FACILITY_SERVICE_SCHEDULE_ITEM_ID = tpc.FACILITY_SERVICE_SCHEDULE_ITEM_ID

--select * from #Level
--select * from #temp
--select * from #Total_POINT_CHART
--select * from #Final1



--select * from #temp order by FACILITY_SERVICE_SCHEDULE_ITEM_ID, [Source]
--select * from #Final2

	select
		All_Data
		,FACILITY_ID
		,FACILITY
		,TabName
		,CHART_ID
		,FACILITY_CHART_ID
		,DOS
		,SENT_DATE
		,ITEM
		,[CHANGES]
		,Automation_Sent
		,Coder_Added
		,Coder_Removed
		,POINTS
		,TotalBeforePoints                                                        as PreviousTotal
		,TotalChartAfterPoints                                                    as NewTotal
		,NewTotalAfterRemoved
		,NewTotalAfterAdded
		,Before_Level                                                             as PreviousChartLevel
		,After_Level                                                              as NewChartLevel
		,case when Before_Level = After_Level then 'N' else 'Y' end               as ChartLevelChange
		,New_Level_Add
		,New_Level_Remove
		--,case
		--	 when Coder_Added = 1
		--		  and f.Before_Level <> f.New_Level_Add then 'Y'
		--	 when Coder_Removed = 1
		--		  and f.Before_Level <> f.New_Level_Remove then 'Y'
		--	 when Coder_Added = 0
		--		  and Coder_Removed = 0 then 'N' --NULL 
		-- else 'N' end                                                             as New_Level
		---- new logic for New_Level RACS-2559 JHerrera
		,case when @FacSvcMethod = 0 then
			case
				 when Coder_Added = 1
					  and f.Before_Level <> f.New_Level_Add then 'Y'
				 when Coder_Removed = 1
					  and f.Before_Level <> f.New_Level_Remove then 'Y'
				 when Coder_Added = 0
					  and Coder_Removed = 0 then 'N' --NULL 
			 else 'N' end
		when @FacSvcMethod = 1 then
			case
				 when Coder_Added = 1
					  and f.Before_Level <> --f.POINTS then 'Y'
							(select max(POINTS) from #Final2 f2 where f.CHART_ID = f2.CHART_ID and f2.Coder_Added = 0) then 'Y'
				 when Coder_Removed = 1
					  and f.Before_Level <> --f.POINTS then 'Y'
							(select max(POINTS) from #Final2 f2 where f.CHART_ID = f2.CHART_ID and f2.Coder_Removed = 0) then 'Y'
				 when Coder_Added = 0
					  and Coder_Removed = 0 then 'N' --NULL 
			 else 'N' end
		else 'N' end                                                             as New_Level
		,(
			 select count(distinct (CHART_ID))from #temp
		 )                                                                        as Total_Chart_In_Search
		,f.FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT
		,f.CoderComment
		,f.CoderComment_ExcludeChart
		,f.LN_Details
		,case when charindex('CC minutes', f.LN_Details, 1) > 0 then 1 else 0 end as LN_Details_ExcludeChart
	into #Final3
	from
		#Final2 f;


--select * from #Final3


	select
		All_Data
		,FACILITY_ID
		,FACILITY
		,TabName
		,CHART_ID
		,FACILITY_CHART_ID
		,DOS
		,SENT_DATE
		,ITEM
		,[CHANGES]
		,Automation_Sent
		,Coder_Added
		,Coder_Removed
		,POINTS
		,PreviousTotal
		,NewTotalAfterRemoved
		,NewTotalAfterAdded
		,PreviousChartLevel
		,NewChartLevel
		,ChartLevelChange
		,New_Level_Add
		,New_Level_Remove
		,New_Level
		,Total_Chart_In_Search
		,FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT
		,CoderComment
		,CoderComment_ExcludeChart
		,LN_Details
		,LN_Details_ExcludeChart
		,case
			 when FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT = 0
				  and CoderComment_ExcludeChart = 0
				  and LN_Details_ExcludeChart = 0
				  --and ChartLevelChange = 'N' then 'Y'
				  and New_Level = 'N' then 'Y'
		 else 'N' end as No_Audit_No_Level_Change
		,case
			 when FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT = 0
				  and CoderComment_ExcludeChart = 0
				  and LN_Details_ExcludeChart = 0
				  --and ChartLevelChange = 'Y' then 'Y'
				  and New_Level = 'Y' then 'Y'
		 else 'N' end as No_Audit_Level_Change
		,case
			 when FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT = 1
				  and CoderComment_ExcludeChart = 0
				  and LN_Details_ExcludeChart = 0
				  --and ChartLevelChange = 'N' then 'Y'
				  and New_Level = 'N' then 'Y'
		 else 'N' end as Audit_No_Level_Change
		,case
			 when FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT = 1
				  and CoderComment_ExcludeChart = 0
				  and LN_Details_ExcludeChart = 0
				  --and ChartLevelChange = 'Y' then 'Y'
				  and New_Level = 'Y' then 'Y'
		 else 'N' end as Audit_Level_Change
		,case
			 when CoderComment_ExcludeChart = 1
				  or LN_Details_ExcludeChart = 1 then 'Y'
		 else 'N' end as Exclude_Chart
	from
		#Final3 f
	order by
		2
		,3;

end
GO
