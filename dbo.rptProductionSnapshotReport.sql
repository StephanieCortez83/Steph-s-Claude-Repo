SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









-- ==========================================================
-- Author:		Daniel Bonebrake
-- Create date: 5/10/2013
-- Description:	Production Snapshot Report
-- Updated By Vishal Parikh for Introducing Billing
-- Updated Procedure for SentYesterday  Count  on 12/17/2013
--
-- Modified | 08/18/2020 | JHerrera | JIRA AAR-807 | Added ORGANIZATION_ID and ORGANIZATION to result set. 
-- Modified | 06/16/2022 | JHerrera | JIRA AAR-2020 | Changed Avg Daily Volume calculation to use DATE_RECEIVED instead of TIME_OF_SERVICE.
-- Modified | 01/25/2024 | DHutton	| JIRA RAP-222 | Adjusted column 'DOS in WIP', Line 608 ( at tme of modification).
-- ==========================================================


CREATE PROCEDURE [dbo].[rptProductionSnapshotReport]
	-- Add the parameters for the stored procedure here
	@AcctMgrID INT = - 1,
	@ReportUser int 

as

begin

    set transaction isolation level read uncommitted;
	set nocount on;

	--declare
	--	@AcctMgrID   int = -1
	--	,@ReportUser int = 80;
	
	
	----------------------------------------------------------------------------------------------------
	
	declare
        @m_AcctMgrID   int  = @AcctMgrID
        ,@m_ReportUser int  = @ReportUser
        ,@Today        date = getdate()
        ,@TodayM60     date = getdate() - 7;

    if object_id('TempDB..#FACILITY1', 'U') is not null drop table #FACILITY1;
    if object_id('TempDB..#SAIDs', 'U') is not null drop table #SAIDs;
    if object_id('TempDB..#Charts', 'U') is not null drop table #Charts;
    if object_id('TempDB..#Snapshot', 'U') is not null drop table #Snapshot;
    if object_id('TempDB..#Counts', 'U') is not null drop table #Counts;


    if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
    if object_id('TempDB..#ChartSubset_2', 'U') is not null drop table #ChartSubset_2;
    if object_id('TempDB..#LogNote', 'U') is not null drop table #LogNote;
    if object_id('TempDB..#Aging', 'U') is not null drop table #Aging;
    if object_id('TempDB..#Aging_2', 'U') is not null drop table #Aging_2;

    if object_id('TempDB..#LogNote_PreProcess', 'U') is not null drop table #LogNote_PreProcess; -- added 1/3/2019 by dsexton
	
	
	----------------------------------------------------------------------------------------------------
	-- preprocess #Facility1

    select *
    into #FACILITY1
    from
        (
        select
            FACILITY_ID
        from
            FACILITY_USER_AUTHORIZATION fua with (nolock)
        where
            fua.USER_PROFILE_ID = @m_ReportUser and getdate() between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
        ) T1;

    create nonclustered index idx_FACILITY_ID on #FACILITY1 (FACILITY_ID);

	delete from #FACILITY1
	where facility_id in (select facility_id 
						  from service_agreement 
						  where company_id in ( 196, 134, 223, 19, 298) 
						  );  -- RAP-929 3/19/25 MultiCare Health System, RAP-1014 04/23/25 exclude R1 Ascension, RAP-1094 05/21/25 Exclude Tenet, Conifer 		
							  
	
	----------------------------------------------------------------------------------------------------
	-- preprocess #SAIDs
    
	select
        SERVICE_AGREEMENT_ID
        ,RecCount = cast(null as int)
        ,MaxDT = cast(null as datetime)
        ,LastCensusDT = cast(null as datetime)
    into #SAIDs
    from
        SERVICE_AGREEMENT as sa
    where
        isnull(sa.DEMO_TEST_SITE_IND, 0) = 0 
		and @Today between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
		and company_id not in ( 196, 134, 223)  -- RAP-929 3/19/25 MultiCare Health System, RAP-1014 04/23/25 exclude R1 Ascension	
        and
            (
            @m_AcctMgrID in (-1, -2, -3, -4) or sa.[SERVICE_AGREEMENT_ID] in
                                                    (
                                                    select
                                                        [SERVICE_AGREEMENT_ID]
                                                    from
                                                        [SERVICE_AGREEMENT_MANAGEMENT_TEAM] with (nolock)
                                                    where
                                                        [USER_PROFILE_ID] = @m_AcctMgrID
                                                    )
            );

    update
        sa
    set
        sa.MaxDT = t.MaxDT
    from
        #SAIDs as sa
        join
            (
            select
                SERVICE_AGREEMENT_ID
                ,MaxDT = max(Creation_Date_Time)
            from
                IMPORT_IMAGE as ii
            where
                SERVICE_AGREEMENT_ID in
                    (
                    select SERVICE_AGREEMENT_ID from #SAIDs
                    )
            group by
                SERVICE_AGREEMENT_ID
            ) as t on sa.SERVICE_AGREEMENT_ID = t.SERVICE_AGREEMENT_ID;


    update
        sa
    set
        sa.RecCount = t.RecCount
    from
        #SAIDs as sa
        join
            (
            select
                SERVICE_AGREEMENT_ID
                ,RecCount = count(*)
            from
                IMPORT_IMAGE as ii
            where
                SERVICE_AGREEMENT_ID in
                    (
                    select SERVICE_AGREEMENT_ID from #SAIDs
                    )
                --and DATEADD(DAY, DATEDIFF(DAY, 0, CREATION_DATE_TIME), 0) = @Today
                and cast(Creation_date_Time as date) = @Today -- performance improves slightly using this method to trim the time portion of the date
            group by
                SERVICE_AGREEMENT_ID
            ) as t on sa.SERVICE_AGREEMENT_ID = t.SERVICE_AGREEMENT_ID;


    update
        sa
    set
        sa.LastCensusDT = t.LastCensusDT
    from
        #SAIDs as sa
        join
            (
            select
                SERVICE_AGREEMENT_ID
                ,LastCensusDT = max(CREATION_DATE_TIME)
            from
                IMPORT_BATCH with (nolock)
            where
                SERVICE_AGREEMENT_ID in
                    (
                    select SERVICE_AGREEMENT_ID from #SAIDs
                    )
            group by
                SERVICE_AGREEMENT_ID
            ) as t on sa.SERVICE_AGREEMENT_ID = t.SERVICE_AGREEMENT_ID;


    create nonclustered index idx_service_agreement_ID on #SAIDs (SERVICE_AGREEMENT_ID);
	
	
	----------------------------------------------------------------------------------------------------
	-- WIP *****

    select
        c.CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,c.FACILITY_ID
        ,c.CHART_STATUS_ID
        ,c.FACILITY_CHART_ID
        ,c.TIME_OF_SERVICE
        ,c.CREATION_DATE_TIME
        ,c.DATE_RECEIVED
        ,sa.TURNAROUND_HOURS_REPORTING_METHOD
        ,sa.TURNAROUND_START_TIME_IN_MINUTES
        ,sa.DEMO_TEST_SITE_IND
        ,sa.EXPIRATION_DATE
    into #ChartSubset
    from
        CHART as c with (nolock)
        join SERVICE_AGREEMENT as sa with (nolock) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
    where
        c.CHART_STATUS_ID = 1; -- ACS-13480 change to Chart Status 1 only ***
    --(
    --(
    --sa.TURNAROUND_HOURS_REPORTING_METHOD in (1, 2, 6, 7, 8, 9) and c.CHART_STATUS_ID in (1, 3, 8) -- Work in Progress, Completed and 2nd Audit only 

    --)
    --or
    --	(
    --	sa.TURNAROUND_HOURS_REPORTING_METHOD in (3, 4) and c.CHART_STATUS_ID in (1, 3, 4) -- Work in Progress, Completed and Approved only

    --	)
    --or
    --	(
    --	sa.TURNAROUND_HOURS_REPORTING_METHOD = 5 and c.CHART_STATUS_ID in (1, 3) -- Work in Progress and Completed only

    --	)
    --)


    create nonclustered index idx_CHART_ID on #ChartSubset (CHART_ID);
    create nonclustered index idx_SERVICE_AGREEMENT_ID on #ChartSubset (SERVICE_AGREEMENT_ID);
    create nonclustered index idx_FACILITY_ID on #ChartSubset (FACILITY_ID);
	
	
	----------------------------------------------------------------------------------------------------
	
	select
        c.CHART_ID
        ,c.SERVICE_AGREEMENT_ID
        ,c.FACILITY_ID
        ,c.CHART_STATUS_ID
        ,c.FACILITY_CHART_ID
        ,c.TIME_OF_SERVICE
        ,c.CREATION_DATE_TIME
        ,c.DATE_RECEIVED
        ,c.TURNAROUND_HOURS_REPORTING_METHOD
        ,c.TURNAROUND_START_TIME_IN_MINUTES
        ,c.DEMO_TEST_SITE_IND
        ,c.EXPIRATION_DATE
    into #ChartSubset_2
    from
        #ChartSubset as c with (nolock)
    where
        c.SERVICE_AGREEMENT_ID in
            (
            select distinct SERVICE_AGREEMENT_ID from #SAIDs
            ) and exists
        (
        select * from #FACILITY1 where FACILITY_ID = c.FACILITY_ID
        )
        and c.CHART_ID not in
                (
                select
                    ln.CHART_ID
                from
                    LOG_NOTE ln with (nolock)
                where
                    ln.CHART_ID = c.CHART_ID and ln.CATEGORY_ID = 6
                    and c.TURNAROUND_HOURS_REPORTING_METHOD not in (6, 7)
                ) -- Ignore accounts that were ever in pending state

    ;



    create nonclustered index idx_TURNAROUND_HOURS_REPORTING_METHOD on #ChartSubset_2 (TURNAROUND_HOURS_REPORTING_METHOD);
    create nonclustered index idx_CHART_STATUS_ID on #ChartSubset_2 (CHART_STATUS_ID);
    create nonclustered index idx_FACILITY_ID on #ChartSubset_2 (FACILITY_ID);


    ---------------------------------------------------------------------------------------
    -- Beginning of section modified 1/3/2019 by dsexton
    -- Populate #LogNote_Preprocessing, then populate #LogNote
    -- This method reduced logical reads by 13 million and reduced duration to 10 seconds vs. 4 minutes (using a warm buffer)

    select
        CHART_ID
        ,COMPLETION_DATE
        ,CATEGORY_ID
        ,Detail = cast(null as varchar(2000))
        ,Summary = cast(null as varchar(256))
    into #LogNote_PreProcess
    from
        (
        select
            c.CHART_ID
            ,ln.COMPLETION_DATE
            ,ln.CATEGORY_ID
        from
            LOG_NOTE ln with (nolock)
            join #ChartSubset_2 as c on ln.CHART_ID = c.CHART_ID
        where
            ln.CATEGORY_ID = 5
        union
        select
            c.CHART_ID
            ,ln.COMPLETION_DATE
            ,ln.CATEGORY_ID
        from
            LOG_NOTE ln with (nolock)
            join #ChartSubset_2 as c on ln.CHART_ID = c.CHART_ID
        where
            ln.CATEGORY_ID = 8
        ) as x;

    update
        t1
    set
        t1.Detail = ln.DETAIL
    from
        #LogNote_PreProcess as t1
        join LOG_NOTE as ln with (nolock) on t1.CHART_ID = ln.CHART_ID and t1.CATEGORY_ID = ln.CATEGORY_ID
                                             and t1.COMPLETION_DATE = ln.COMPLETION_DATE;

    update
        t1
    set
        t1.Summary = ln.SUMMARY
    from
        #LogNote_PreProcess as t1
        join LOG_NOTE as ln with (nolock) on t1.CHART_ID = ln.CHART_ID and t1.CATEGORY_ID = ln.CATEGORY_ID
                                             and t1.COMPLETION_DATE = ln.COMPLETION_DATE;

    delete from #LogNote_PreProcess
    where
        CATEGORY_ID = 5 and Detail not like 'Chart status moved to work in progress.  Previous status was Pending%';

    delete from #LogNote_PreProcess
    where
        CATEGORY_ID = 8 and Detail not like 'Chart status changed to Work in Progress%'
        and Summary not like 'Chart status changed to Work in Progress%';

    select
        CHART_ID
        ,Completion_Date = max(COMPLETION_DATE)
    into #LogNote
    from
        #LogNote_PreProcess
    group by
        CHART_ID;

    -- end of section modified by dsexton
    -------------------------------------------------------------------------------------------------

	select
        c.FACILITY_ID
        ,f.[NAME] Facility
        ,c.FACILITY_CHART_ID Account
        ,c.TIME_OF_SERVICE TOS
        ,case
             when c.TURNAROUND_HOURS_REPORTING_METHOD in (1, 2) then datediff(minute, c.DATE_RECEIVED, getdate()) / 60
             when c.TURNAROUND_HOURS_REPORTING_METHOD in (3, 4) then
                 datediff(minute, c.CREATION_DATE_TIME, getdate()) / 60
             when c.TURNAROUND_HOURS_REPORTING_METHOD = 5 then
                 datediff(
                             minute
                             ,dateadd(
                                         minute
                                         ,c.TURNAROUND_START_TIME_IN_MINUTES
                                         ,dateadd(dd, datediff(dd, 0, c.CREATION_DATE_TIME), 0)
                                     )
                             ,getdate()
                         ) / 60
             when c.TURNAROUND_HOURS_REPORTING_METHOD in (6, 7) then
                 datediff(minute
                          ,isnull((
                                  select
                                      max(ln.Completion_Date)
                                  from
                                      #LogNote as ln
                                  where
                                      ln.CHART_ID = c.CHART_ID
                                  )
                                  ,c.CREATION_DATE_TIME
                                 )
                          ,getdate()
                         ) / 60
             when c.TURNAROUND_HOURS_REPORTING_METHOD in (8, 9) then
                 datediff(minute
                          ,(
                           select
                               max(CREATION_DATE_TIME)
                           from
                               VWImportImage with (nolock) -- view performs OK  4/14/2017
                           where
                               CHART_ID = c.CHART_ID
                           )
                          ,getdate()
                         ) / 60 end 'Hours Elapsed'
    into #Aging
    from
        #ChartSubset_2 as c
        inner join FACILITY f with (nolock) on c.FACILITY_ID = f.FACILITY_ID
    where
        c.DEMO_TEST_SITE_IND <> 1
        and c.EXPIRATION_DATE > getdate() -- 3-20-2015 DanielB: Ignore expired accounts
        -- ACS-13480 change to Chart Status 1 only ***
        --and 
        -- (
        -- (
        -- c.TURNAROUND_HOURS_REPORTING_METHOD in (1, 2, 6, 7, 8, 9) and c.CHART_STATUS_ID in (1, 3) -- Work in Progress and Completed only

        -- )
        -- or
        --	 (
        --	 c.TURNAROUND_HOURS_REPORTING_METHOD in (3, 4) and c.CHART_STATUS_ID in (1, 3, 4) -- Work in Progress, Completed and Approved only

        --	 )
        -- or
        --	 (
        --	 c.TURNAROUND_HOURS_REPORTING_METHOD = 5 and c.CHART_STATUS_ID in (1, 3) -- Work in Progress and Completed only

        --	 )
        -- ) 
        and f.FACILITY_ID = c.FACILITY_ID;
	
	
	----------------------------------------------------------------------------------------------------
	
	select
        max(FACILITY_ID) as Facility_ID
        ,max(Facility) as Facility
        ,max([Hours Elapsed]) as Hours_Elapsed
    into #Aging_2
    from
        #Aging
    group by
        FACILITY_ID;
	
	
	----------------------------------------------------------------------------------------------------
	-- preprocess #Charts
    
	select
        c.SERVICE_AGREEMENT_ID
        ,DOS = cast(c.DATE_RECEIVED as date) -- performance improves slightly using this method to trim the time portion of the date
        ,count(*) TOTAL
    into #Charts
    from
        CHART as c with (nolock)
        join
            (select distinct SERVICE_AGREEMENT_ID from #SAIDs) as t on c.SERVICE_AGREEMENT_ID = t.SERVICE_AGREEMENT_ID
    where
        c.DATE_RECEIVED < @Today and CHART_STATUS_ID in (1, 2, 3, 4, 5, 8)
        and datediff(day, @TodayM60, cast(c.DATE_RECEIVED as date)) > 0 -- performance improves slightly using this method to trim the time portion of the date
    group by
        c.SERVICE_AGREEMENT_ID
        ,cast(c.DATE_RECEIVED as date);
	
	
	----------------------------------------------------------------------------------------------------
	-- preprocess #Snapshot

    select
        sa.SERVICE_AGREEMENT_ID
        ,f.FACILITY_ID
        ,case
             when sa.[RCP_BILLING_IND] = 1 then 'Billing'
             when sa.[SERVICE_MODEL_CD] = 'ASP' then 'Software as a Service (SaaS)'
             else 'Full Service' end [Service]
        ,f.[NAME] Faclity
        ,(
         select
             LastCensusDT
         from
             #SAIDs
         where
             SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
         ) 'Last Census Rec''d'
        ,(
         select
             isnull(RecCount, 0)
         from
             #SAIDs as t
         where
             t.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
         ) 'Images Rec''d'
        ,(
         select
             MaxDT
         from
             #SAIDs as t
         where
             t.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
         ) 'Last Image Rec''d'
        ,(
         select
             sum(TOTAL) / count(*)
         from
             #Charts
         where
             SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
         ) 'Avg Daily Volume'
        ,ltrim(rtrim(coalesce(
                                 stuff(
                                     (
                                     select
                                         ',' + cpy.[NAME]
                                     from
                                         [dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla with (nolock)
                                         inner join [dbo].[SERVICE_LOCATION] sl with (nolock) on sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
                                         inner join [dbo].[COMPANY] cpy with (nolock) on cpy.COMPANY_ID = sl.COMPANY_ID
                                     where
                                         SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
                                         and @Today between EFFECTIVE_DATE and EXPIRATION_DATE
                                     order by
                                         cpy.[NAME]
                                     for xml path('')
                                     )
                                     ,1
                                     ,1
                                     ,''
                                      )
                                 ,'N/A'
                             )
                    )
              ) Vendor
    into #Snapshot
    from
        SERVICE_AGREEMENT sa with (nolock)
        inner join SERVICE_MODEL sm with (nolock) on sa.SERVICE_MODEL_CD = sm.SERVICE_MODEL_CD
        inner join FACILITY f with (nolock) on f.FACILITY_ID = sa.FACILITY_ID
    where
        isnull(sa.DEMO_TEST_SITE_IND, 0) = 0 and @Today between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
        and
            (
            @m_AcctMgrID in (-1, -2, -3, -4) or sa.[SERVICE_AGREEMENT_ID] in
                                                    (
                                                    select distinct SERVICE_AGREEMENT_ID from #SAIDs
                                                    )
            )
    group by
        f.FACILITY_ID
        ,sa.SERVICE_MODEL_CD
        ,f.[NAME]
        ,sa.[SERVICE_AGREEMENT_ID]
        ,sa.[EFFECTIVE_DATE]
        ,sa.[ACCT_MANAGER_USER_PROFILE_ID]
        ,sa.[ACCT_MANAGER_ASST_USER_PROFILE_ID]
        ,sa.[RCP_BILLING_IND];
	
	
	----------------------------------------------------------------------------------------------------
	-- preprocess #Counts

    select
        t1.SERVICE_AGREEMENT_ID
        ,sum(case when c.CHART_STATUS_ID = 1 then 1 else 0 end) 'Work in Process'
        ,sum(case when c.CHART_STATUS_ID = 2 then 1 else 0 end) 'Pending'
        ,sum(case when c.CHART_STATUS_ID = 3 then 1 else 0 end) 'Complete'
        ,sum(case when c.CHART_STATUS_ID = 4 then 1 else 0 end) 'Approved'
        ,sum(case when c.CHART_STATUS_ID = 8 then 1 else 0 end) 'SecondAudit'
        ,sum(   case
                    when cast(c.CREATION_DATE_TIME as date) = @Today -- performance improves slightly using this method to trim the time portion of the date
                then    1
                    else 0 end
            ) 'Received'
        ,sum(   case
                    when cast(c.SENT_DATE as date) = @Today -- performance improves slightly using this method to trim the time portion of the date
                then    1
                    else 0 end
            ) 'Sent'
        ,sum(   case
                    when cast(c.SENT_DATE as date) = dateadd(DD, -1, @Today) -- performance improves slightly using this method to trim the time portion of the date
                then    1
                    else 0 end
            ) 'SentYestrday'
    into #Counts
    from
        (select distinct SERVICE_AGREEMENT_ID from #Snapshot) as t1
        join CHART as c with (nolock) on t1.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    group by
        t1.SERVICE_AGREEMENT_ID;
	
	
	----------------------------------------------------------------------------------------------------
	-- final results

    select
        sa.ORGANIZATION_ID
		,o.[DESCRIPTION] [ORGANIZATION]
		,p.FACILITY_ID
        ,[Service]
        ,Faclity
        ,[Work in Process]
        ,Pending
        ,Complete
        ,Approved
        ,SecondAudit
        ,Received
        ,[Sent]
        ,SentYestrday
        ,[Last Census Rec'd]
        ,[Images Rec'd]
        ,[Last Image Rec'd]
        ,[Avg Daily Volume]
        ,Vendor
        ,cast([Work in Process] as decimal) / [Avg Daily Volume] 'WIP_ADV'
        ,(
         select -- JIRA RAP-222 01/25/2024 DAH
		 cast(Hours_Elapsed/cast(24 as float) as decimal(7,2))
             --case
             --    when Hours_Elapsed > 0 and Hours_Elapsed <= 24 then 1
             --    when Hours_Elapsed > 24 and Hours_Elapsed <= 36 then 1.5
             --    when Hours_Elapsed > 36 and Hours_Elapsed <= 48 then 2
             --    when Hours_Elapsed > 48 and Hours_Elapsed <= 60 then 2.5
             --    when Hours_Elapsed > 60 and Hours_Elapsed <= 72 then 3
             --    when Hours_Elapsed > 72 and Hours_Elapsed <= 84 then 3.5
             --    when Hours_Elapsed > 84 and Hours_Elapsed <= 96 then 4
             --    when Hours_Elapsed > 96 and Hours_Elapsed <= 108 then 4.5
             --    when Hours_Elapsed > 108 and Hours_Elapsed <= 120 then 5
             --    when Hours_Elapsed > 120 and Hours_Elapsed <= 132 then 5.5
             --    when Hours_Elapsed > 132 and Hours_Elapsed <= 144 then 6
             --    when Hours_Elapsed > 144 and Hours_Elapsed <= 156 then 6.5
             --    when Hours_Elapsed > 156 and Hours_Elapsed <= 168 then 7
             --    when Hours_Elapsed > 168 then 7.5
             --    else 0 end
         from
             #Aging_2
         where
             Facility_ID = p.Facility_ID
         ) as 'DOS in WIP'
    from
        #Snapshot as p
        join #Counts as t on p.SERVICE_AGREEMENT_ID = t.SERVICE_AGREEMENT_ID
		inner join SERVICE_AGREEMENT sa on p.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID and p.FACILITY_ID = sa.FACILITY_ID
		inner join ORGANIZATION o on sa.ORGANIZATION_ID = o.ORGANIZATION_ID
    where
        exists
        (
        select 1 from #FACILITY1 f1 where p.FACILITY_ID = f1.FACILITY_ID
        )
    order by
        [Service]
        ,[Faclity];
	
	
	----------------------------------------------------------------------------------------------------
	
	
end;





GO
GRANT EXECUTE ON  [dbo].[rptProductionSnapshotReport] TO [dbx_ExecuteReportProcs]
GO
