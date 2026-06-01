SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE proc [dbo].[rpt_PointDistributionComparison]
    (
    @ReportUser     int
    ,@Code          int
    ,@Facility      varchar(8000)
    ,@Coder         varchar(max)
    ,@StartRangeOne datetime
    ,@EndRangeOne   datetime
    ,@FacilityTwo      varchar(8000)
    ,@StartRangeTwo datetime
    ,@EndRangeTwo   datetime
    ,@FacilityThree      varchar(8000)
    ,@StartRangeThree datetime
    ,@EndRangeThree   datetime
    )
as

begin

    set transaction isolation level read uncommitted;
    set nocount on;

	--declare
	--	@ReportUser       int           = 80
	--	,@Code            int           = 0
	--	,@Facility        varchar(8000) = '466'
	--	--,@Status        varchar(15)  = '3,5'
	--	,@Coder           varchar(max)  = '-1'
	--	,@StartRangeOne   datetime      = '20191201'
	--	,@EndRangeOne     datetime      = '20191231'
	--	,@FacilityTwo     varchar(8000) = '-1'
	--	,@StartRangeTwo   datetime      = ''
	--	,@EndRangeTwo     datetime      = ''
	--	,@FacilityThree   varchar(8000) = '-1'
	--	,@StartRangeThree datetime      = ''
	--	,@EndRangeThree   datetime      = '';

	declare
		@m_ReportUser int           = @ReportUser
		,@m_Code      int           = @Code
		,@m_Facility  varchar(8000) = @Facility
		,@m_Facility2 varchar(8000) = @FacilityTwo
		,@m_Facility3 varchar(8000) = @FacilityThree
		,@m_Status    varchar(15)   = '3,5' --@Status
		,@m_Coder     varchar(max)  = @Coder
		,@m_StartDate date          = null
		,@m_EndDate   date          = null;

	
	----------------------------------------------------------------------------------------------------
	
	declare @dates table
	(
		Facility_Id int
		,StartDate datetime
		,EndDate datetime
		,Complete int default 0
		,[PERIOD] int
	)

	insert into @dates (Facility_Id, StartDate, EndDate, [PERIOD])
	select items, @StartRangeOne, @EndRangeOne, 1
	from [dbo].[SplitString](@m_Facility,',')

	insert into @dates (Facility_Id, StartDate, EndDate, [PERIOD])
	select items, @StartRangeTwo, @EndRangeTwo, 2
	from [dbo].[SplitString](@m_Facility2,',')

	insert into @dates (Facility_Id, StartDate, EndDate, [PERIOD])
	select items, @StartRangeThree, @EndRangeThree, 3
	from [dbo].[SplitString](@m_Facility3,',')

	
	delete from @dates
	where (
			(StartDate is null or EndDate is null)
				or Facility_Id = -1
			)


	--insert into @dates
	--	(Facility_Id, StartDate, EndDate, [PERIOD])
	--values 
	--	(@m_Facility, @StartRangeOne, @EndRangeOne, 1)
	--	,(@m_Facility2, @StartRangeTwo, @EndRangeTwo, 2)
	--	,(@m_Facility3, @StartRangeThree, @EndRangeThree, 3)

	--declare @m_Period int, @w_Facility int
	
	--delete from @dates
	--where (StartDate is null or EndDate is null)

	--if exists (select * from @dates where Facility_Id = '-1')
	--begin
	--	update @dates
	--	set Facility_Id = @m_Facility
	--	where Facility_Id = '-1'
	--end	
	
	
	----------------------------------------------------------------------------------------------------
	
	declare @m_Period int, @w_Facility int

	create table #ChartSubset
        (
        chart_ID                            int
        ,facility_ID                        int
        ,chart_status_ID                    int
        ,approved_date                      datetime
        ,sent_date                          datetime
        ,SECOND_LEVEL_QA_APPROVED_DATETIME  datetime
        ,time_of_service                    datetime
        ,facility_level_ID                  int
        ,OVERRIDE_FACILITY_LEVEL_ID         int
        ,NON_ER_PROCEDURES_OVERRIDE         bit
        ,physician_service_proc_ID          int
        ,override_physician_service_proc_ID int
        ,physician_service_mod              varchar(150)
        ,patient_class_ID                   int
        ,physician_history_ID               int
        ,physician_exam_ID                  int
        ,physician_mdm_ID                   int
        ,chief_complaint                    varchar(20)
        ,primary_complaint                  varchar(20)
        ,COMPLETED_BY_USER_PROFILE_ID       int
        ,FACILITY_CHART_ID                  varchar(50)
        ,PATIENT_NAME                       varchar(100)
        ,DOS                                datetime
        ,COMPLETION_DATE                    datetime
        ,FACILITY                           varchar(100)
        ,CODER                              varchar(100)
        ,USER_CLASS_CD                      int
		,[PERIOD]							int
		,[PERIOD_DESC]						varchar(100)
		,[CODE]								varchar(20)
        );
	
	
	--print 'Section: 01 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	while exists (select * from @dates d where d.Complete = 0 
					and (@EndRangeOne <= (select max([EndDate]) from @dates) 
							or @EndRangeTwo <= (select max([EndDate]) from @dates)
							or @EndRangeThree <= (select max([EndDate]) from @dates)
						)
					)
	begin
		
		set @w_Facility = (select top 1 Facility_Id from @dates where Complete = 0 order by StartDate)
		set @m_StartDate = (select top 1 StartDate from @dates where Complete = 0 and Facility_Id = @w_Facility)
		set @m_EndDate = (select top 1 EndDate from @dates where StartDate = @m_StartDate and Facility_Id = @w_Facility)
		set @m_Period = (select top 1 [PERIOD] from @dates where StartDate = @m_StartDate and Facility_Id = @w_Facility)


		insert into #ChartSubset
		select
			c.CHART_ID
			,c.FACILITY_ID
			,c.CHART_STATUS_ID
			,c.APPROVED_DATE
			,c.SENT_DATE
			,c.SECOND_LEVEL_QA_APPROVED_DATETIME
			,c.TIME_OF_SERVICE
			,c.FACILITY_LEVEL_ID
			,c.OVERRIDE_FACILITY_LEVEL_ID
			,c.NON_ER_PROCEDURES_OVERRIDE
			,c.PHYSICIAN_SERVICE_PROC_ID
			,c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
			,c.PHYSICIAN_SERVICE_MOD
			,c.PATIENT_CLASS_ID
			,c.PHYSICIAN_HISTORY_ID
			,c.PHYSICIAN_EXAM_ID
			,c.PHYSICIAN_MDM_ID
			,c.CHIEF_COMPLAINT
			,c.PRIMARY_COMPLAINT
			,c.COMPLETED_BY_USER_PROFILE_ID
			,c.FACILITY_CHART_ID
			,c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME PATIENT_NAME
			,c.TIME_OF_SERVICE DOS
			,c.COMPLETION_DATE
			,f.NAME FACILITY
			,coder.LAST_NAME + ', ' + coder.FIRST_NAME CODER
			,coder.USER_CLASS_CD
			,@m_Period
			,convert(varchar(10),@m_StartDate,1) + ' - ' + convert(varchar(10),@m_EndDate,1) [PERIOD_DESC]
			,case c.OVERRIDE_FACILITY_LEVEL_ID
				 when -1 then case @m_Code when 0 then fl.CPT_CODE else fl.BILLING_CODE end
				 else case @m_Code when 0 then ofl.CPT_CODE else ofl.BILLING_CODE end end [CODE]
		from
			CHART c with (nolock)
			inner join FACILITY f with (nolock) on f.FACILITY_ID = c.FACILITY_ID
			inner join USER_PROFILE coder with (nolock) on coder.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
			inner join FACILITY_LEVEL fl on c.FACILITY_LEVEL_ID = fl.FACILITY_LEVEL_ID and fl.LEVEL_NUMBER in (1,2,3,4,5)
			left join FACILITY_LEVEL ofl on (ofl.FACILITY_LEVEL_ID = c.OVERRIDE_FACILITY_LEVEL_ID)
		where
			c.FACILITY_ID in
				(
				select items from SplitString(@w_Facility, ',')
				) 
			and c.CHART_STATUS_ID in
				(
				select items from SplitString(@m_Status, ',')
				) 
			and dateadd(day, datediff(day, 0, c.TIME_OF_SERVICE), 0) between @m_StartDate and @m_EndDate
			and
				(
				c.COMPLETED_BY_USER_PROFILE_ID in
					(
					select items from SplitString(@m_Coder, ',')
					) or -1 in
							 (
							 select items from SplitString(@m_Coder, ',')
							 )
				) and exists
			(
			select
				1
			from
				FACILITY_USER_AUTHORIZATION with (nolock)
			where
				USER_PROFILE_ID = @m_ReportUser and FACILITY_ID = c.FACILITY_ID
			)


		update @dates
		set Complete = 1
		where StartDate = @m_StartDate
		 and Facility_Id = @w_Facility

	end
	
	
	--print 'Section: 02 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select
        c.FACILITY_ID
		,c.FACILITY
        ,c.COMPLETED_BY_USER_PROFILE_ID
		,c.CHART_ID
        ,c.FACILITY_CHART_ID
        ,c.PATIENT_NAME
        ,convert(datetime,(convert(varchar(10),c.TIME_OF_SERVICE,101))) [DATE_OF_SERVICE]
		,c.COMPLETED_BY_USER_PROFILE_ID [CODER_ID]
        ,c.CODER
        ,convert(datetime,(convert(varchar(10),c.COMPLETION_DATE,101))) [COMPLETION_DATE]
        ,'Facility Level' [TYPE]
        ,'Points' [SUB_TYPE]
        --,null CODE
		,c.CODE
        ,null MODIFIER
        ,isnull(fssi.POINTS, fs.MAX_POINTS) UNITS
        ,isnull(fssi.[DESCRIPTION], fs.[DESCRIPTION]) [DESCRIPTION]
        ,null [START_DATE]
        ,null [END_DATE]
        ,isnull(fssi.PRESENTATION_SEQUENCE, fs.SEQUENCE) SEQ
        ,2 TYPE_SEQ
        ,null DEPARTMENT
		,c.[PERIOD]
		,c.PERIOD_DESC
    into #results
	from
        #ChartSubset c
        inner join FACILITY_SERVICE_EVALUATION fse on fse.CHART_ID = c.chart_ID
        left join FACILITY_SERVICE fs on fs.[FACILITY_SERVICE_ID] = fse.[FACILITY_SERVICE_ID]
        left join FACILITY_SERVICE_SCHEDULE_ITEM fssi on fssi.[FACILITY_SERVICE_SCHEDULE_ID] = fse.[FACILITY_SERVICE_SCHEDULE_ID]
                                                         and fssi.[FACILITY_SERVICE_SCHEDULE_ITEM_ID] = fse.[FACILITY_SERVICE_SCHEDULE_ITEM_ID]
  --  union
  --  select
  --      c.FACILITY_ID
		--,c.FACILITY
  --      ,c.COMPLETED_BY_USER_PROFILE_ID
		--,c.CHART_ID
  --      ,c.FACILITY_CHART_ID
  --      ,c.PATIENT_NAME
  --      ,convert(datetime,(convert(varchar(10),c.TIME_OF_SERVICE,101))) [DATE_OF_SERVICE]
		--,c.COMPLETED_BY_USER_PROFILE_ID [CODER_ID]
  --      ,c.CODER
  --      ,convert(datetime,(convert(varchar(10),c.COMPLETION_DATE,101))) [COMPLETION_DATE]
  --      ,'Facility Level' [TYPE]
  --      ,null [SUB_TYPE]
  --      ,case c.OVERRIDE_FACILITY_LEVEL_ID
  --           when -1 then case @m_Code when 0 then fl.CPT_CODE else fl.BILLING_CODE end
  --           else case @m_Code when 0 then ofl.CPT_CODE else ofl.BILLING_CODE end end [CODE]
  --      ,case
  --           when c.NON_ER_PROCEDURES_OVERRIDE = 1 then '25'
  --           when isnull(c.OVERRIDE_FACILITY_LEVEL_ID, -1) = -1 then fl.MODIFIER
  --           else ofl.MODIFIER end [MODIFIER]
  --      --CASE c.NON_ER_PROCEDURES_OVERRIDE
  --      --	WHEN 1
  --      --		THEN '25'
  --      --	ELSE NULL
  --      --	END [MODIFIER],
  --      ,null UNITS
  --      ,case c.OVERRIDE_FACILITY_LEVEL_ID
  --           when null then fl.[DESCRIPTION]
  --           when -1 then fl.[DESCRIPTION]
  --           else ofl.[DESCRIPTION] end [DESCRIPTION]
  --      ,null [START_DATE]
  --      ,null [END_DATE]
  --      ,1 SEQ
  --      ,1 TYPE_SEQ
  --      ,null DEPARTMENT
		--,c.[PERIOD]
		--,c.PERIOD_DESC
  --  from
  --      #ChartSubset c
  --      inner join SERVICE_AGREEMENT sa on sa.FACILITY_ID = c.facility_ID
  --      left join FACILITY_LEVEL fl on (fl.FACILITY_LEVEL_ID = c.facility_level_ID)
  --      left join FACILITY_LEVEL ofl on (ofl.FACILITY_LEVEL_ID = c.OVERRIDE_FACILITY_LEVEL_ID)
  --  where
  --      sa.EVALUATE_FACILITY_SVC = 1
	
	
	--print 'Section: 03 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	alter table #results
	add [YEAR] int, [MONTH] varchar(3)

	update #results
	set 
		[YEAR] = year(DATE_OF_SERVICE)
		,[MONTH] = left(datename(month,DATE_OF_SERVICE),3)
	
	
	--print 'Section: 04 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	--;with p1
	--as
	--(
	select 
		r.FACILITY_ID
		,r.FACILITY
		,r.FACILITY_CHART_ID
		,r.DATE_OF_SERVICE
		,r.CODER_ID
		,r.CODER
		,r.COMPLETION_DATE
		,r.[TYPE]
		,r.SUB_TYPE
		,r.CODE
		,r.MODIFIER
		,r.UNITS 
		,r.[DESCRIPTION]
		,r.[START_DATE]
		,r.END_DATE
		,r.DEPARTMENT
		,r.[YEAR]
		,r.[MONTH]
		,r.[PERIOD]
		,r.PERIOD_DESC
	into #p1
	from 
		#results r
	where
		--r.[YEAR] = 2017
		r.[PERIOD] = 1
		and r.CODE is not null
		--and r.CODE = '99285'  --in (99284,99285)
	--)
	--select 
	--	r1.FACILITY_ID
	--	,r1.FACILITY
	--	,r1.FACILITY_CHART_ID
	--	,r1.DATE_OF_SERVICE
	--	,r1.CODER_ID
	--	,r1.CODER
	--	,r1.COMPLETION_DATE
	--	,r1.[TYPE]
	--	,r1.SUB_TYPE
	--	,isnull(r1.CODE,p1.CODE) [CODE]
	--	,r1.UNITS
	--	,r1.[DESCRIPTION]
	--	,r1.[YEAR]
	--	,r1.[MONTH]
	--	,r1.[PERIOD]
	--	,r1.PERIOD_DESC
	--into #P1
	--from 
	--	p1 p1
	--	inner join #results r1
	--		on p1.[PERIOD] = r1.[PERIOD] --r1.[YEAR] = 2017 
	--			and p1.FACILITY_CHART_ID = r1.FACILITY_CHART_ID
	
	
	--print 'Section: 05 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	--;with p2
	--as
	--(
	select 
		r.FACILITY_ID
		,r.FACILITY
		,r.FACILITY_CHART_ID
		,r.DATE_OF_SERVICE
		,r.CODER_ID
		,r.CODER
		,r.COMPLETION_DATE
		,r.[TYPE]
		,r.SUB_TYPE
		,r.CODE
		,r.MODIFIER
		,r.UNITS 
		,r.[DESCRIPTION]
		,r.[START_DATE]
		,r.END_DATE
		,r.DEPARTMENT
		,r.[YEAR]
		,r.[MONTH]
		,r.[PERIOD]
		,r.PERIOD_DESC
	into #p2
	from 
		#results r
	where
		--r.[YEAR] = 2018
		r.[PERIOD] = 2
		and r.CODE is not null
		--and r.CODE = '99285'  --in (99284,99285)
	--)
	--select 
	--	r1.FACILITY_ID
	--	,r1.FACILITY
	--	,r1.FACILITY_CHART_ID
	--	,r1.DATE_OF_SERVICE
	--	,r1.CODER_ID
	--	,r1.CODER
	--	,r1.COMPLETION_DATE
	--	,r1.[TYPE]
	--	,r1.SUB_TYPE
	--	,isnull(r1.CODE,p2.CODE) [CODE]
	--	,r1.UNITS
	--	,r1.[DESCRIPTION]
	--	,r1.[YEAR]
	--	,r1.[MONTH]
	--	,r1.[PERIOD]
	--	,r1.PERIOD_DESC
	--into #P2
	--from 
	--	p2 p2
	--	inner join #results r1
	--		on p2.[PERIOD] = r1.[PERIOD] --r1.[YEAR] = 2018 
	--			and p2.FACILITY_CHART_ID = r1.FACILITY_CHART_ID
	
	
	--print 'Section: 06 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	--;with p3
	--as
	--(
	select 
		r.FACILITY_ID
		,r.FACILITY
		,r.FACILITY_CHART_ID
		,r.DATE_OF_SERVICE
		,r.CODER_ID
		,r.CODER
		,r.COMPLETION_DATE
		,r.[TYPE]
		,r.SUB_TYPE
		,r.CODE
		,r.MODIFIER
		,r.UNITS 
		,r.[DESCRIPTION]
		,r.[START_DATE]
		,r.END_DATE
		,r.DEPARTMENT
		,r.[YEAR]
		,r.[MONTH]
		,r.[PERIOD]
		,r.PERIOD_DESC
	into #p3
	from 
		#results r
	where
		--r.[YEAR] = 2018
		r.[PERIOD] = 3
		and r.CODE is not null
		--and r.CODE = '99285'  --in (99284,99285)
	--)
	--select 
	--	r1.FACILITY_ID
	--	,r1.FACILITY
	--	,r1.FACILITY_CHART_ID
	--	,r1.DATE_OF_SERVICE
	--	,r1.CODER_ID
	--	,r1.CODER
	--	,r1.COMPLETION_DATE
	--	,r1.[TYPE]
	--	,r1.SUB_TYPE
	--	,isnull(r1.CODE,p3.CODE) [CODE]
	--	,r1.UNITS
	--	,r1.[DESCRIPTION]
	--	,r1.[YEAR]
	--	,r1.[MONTH]
	--	,r1.[PERIOD]
	--	,r1.PERIOD_DESC
	--into #P3
	--from 
	--	p3 p3
	--	inner join #results r1
	--		on p3.[PERIOD] = r1.[PERIOD] --r1.[YEAR] = 2018 
	--			and p3.FACILITY_CHART_ID = r1.FACILITY_CHART_ID
	
	
	--print 'Section: 06 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------
	
	select 
		FACILITY_ID
		,FACILITY
		,FACILITY_CHART_ID
		,DATE_OF_SERVICE
		,CODER_ID
		,CODER
		,COMPLETION_DATE
		,[TYPE]
		,SUB_TYPE
		,CODE
		,UNITS
		,[DESCRIPTION]
		,[PERIOD]
		,PERIOD_DESC
		,case when [PERIOD] = 1 then 1 else 0 end [RANGE_ONE]
		,case when [PERIOD] = 2 then 1 else 0 end [RANGE_TWO]
		,case when [PERIOD] = 3 then 1 else 0 end [RANGE_THREE]
	into #final_results
	from 
		#p1

	union all

	select 
		FACILITY_ID
		,FACILITY
		,FACILITY_CHART_ID
		,DATE_OF_SERVICE
		,CODER_ID
		,CODER
		,COMPLETION_DATE
		,[TYPE]
		,SUB_TYPE
		,CODE
		,UNITS
		,[DESCRIPTION]
		,[PERIOD]
		,PERIOD_DESC
		,case when [PERIOD] = 1 then 1 else 0 end [RANGE_ONE]
		,case when [PERIOD] = 2 then 1 else 0 end [RANGE_TWO]
		,case when [PERIOD] = 3 then 1 else 0 end [RANGE_THREE]
	from 
		#p2

	union all

	select 
		FACILITY_ID
		,FACILITY
		,FACILITY_CHART_ID
		,DATE_OF_SERVICE
		,CODER_ID
		,CODER
		,COMPLETION_DATE
		,[TYPE]
		,SUB_TYPE
		,CODE
		,UNITS
		,[DESCRIPTION]
		,[PERIOD]
		,PERIOD_DESC
		,case when [PERIOD] = 1 then 1 else 0 end [RANGE_ONE]
		,case when [PERIOD] = 2 then 1 else 0 end [RANGE_TWO]
		,case when [PERIOD] = 3 then 1 else 0 end [RANGE_THREE]
	from 
		#p3
	
	
	----------------------------------------------------------------------------------------------------
	
	select 
		FACILITY_ID
		,FACILITY
		,FACILITY_CHART_ID
		,DATE_OF_SERVICE
		,CODER_ID
		,CODER
		,COMPLETION_DATE
		,[TYPE]
		,SUB_TYPE
		,CODE
		,UNITS
		,[DESCRIPTION]
		,[PERIOD]
		,PERIOD_DESC
		,isnull(RANGE_ONE,0) [RANGE_ONE]
		,isnull(RANGE_TWO,0) [RANGE_TWO]
		,isnull(RANGE_THREE,0) [RANGE_THREE]
		,( isnull(RANGE_ONE,0) + isnull(RANGE_TWO,0) + isnull(RANGE_THREE,0) ) [OVERALL_TOTAL]
		,case when len(@m_Facility) > 3 then (select top 1 [NAME] from FACILITY where FACILITY_ID in (select items from dbo.SplitString(@m_Facility,',')) order by [NAME])
			else (select [NAME] from FACILITY where FACILITY_ID = @m_Facility) end [FACILITY_ONE]
		,case when len(@m_Facility2) > 3 then (select top 1 [NAME] from FACILITY where FACILITY_ID in (select items from dbo.SplitString(@m_Facility2,',')) order by [NAME])
			else (select [NAME] from FACILITY where FACILITY_ID = @m_Facility2) end [FACILITY_TWO]
		,case when len(@m_Facility3) > 3 then (select top 1 [NAME] from FACILITY where FACILITY_ID in (select items from dbo.SplitString(@m_Facility3,',')) order by [NAME])
			else (select [NAME] from FACILITY where FACILITY_ID = @m_Facility3) end [FACILITY_THREE]
	from 
		#final_results
    order by
		[FACILITY]
		,[PERIOD]
        ,[FACILITY_CHART_ID]
        ,[SUB_TYPE];
	
	
	--print 'Section: 07 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------

	drop table #ChartSubset;
	drop table #results;
	drop table #P1;
	drop table #P2;
	drop table #P3;
	drop table #final_results
	
	


end;




GO
GRANT EXECUTE ON  [dbo].[rpt_PointDistributionComparison] TO [dbx_ExecuteReportProcs]
GO
