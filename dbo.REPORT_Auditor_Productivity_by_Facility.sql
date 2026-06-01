SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Laura Hotalling	
-- Create date: 4/24/2013
-- Description:	Gets data for report: Auditor Productivity by Facility
-- Modified:
--				12/4/2020 | JHerrera | AAR-1020 
--
--
--
-- =============================================


CREATE procedure [dbo].[REPORT_Auditor_Productivity_by_Facility]
    --	 Add the parameters for the stored procedure here
    @Facility_ID varchar(8000)
    ,@ReportUser int
    ,@FromDate   datetime
    ,@ToDate     datetime
    ,@Auditor_ID int
    ,@Region     int
    ,@UserGroup  varchar(8000)
	,@ExcludeTrustSalesforceClients int
as
begin


    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    set nocount on;
    set transaction isolation level read uncommitted;



-- Test Parameters
    --declare
    --     @Facility_ID                   varchar(8000) = '-1' -- '276,529,741,1254,1418,1424'
    --    ,@ReportUser                    int           = 15242
    --    ,@Auditor_ID                    int           = -1
    --    ,@FromDate                      datetime      = '20240501'
    --    ,@ToDate                        datetime      = '20240515'
    --    ,@Region                        int           = 0
    --    ,@UserGroup                     int           = -1
    --    ,@ExcludeTrustSalesforceClients int           = 0;


    declare @m_FacilityID varchar(8000) = @Facility_ID;
    declare @m_ReportUser int = @ReportUser;
    declare @m_AuditorID int = @Auditor_ID;
    declare @m_FromDate datetime = @FromDate;
    declare @m_ToDate datetime = @ToDate;
    declare @m_UserGroup varchar(8000) = @UserGroup;








    if object_id('TempDB..#chart1', 'U') is not null
        drop table #chart1;
    if object_id('TempDB..#chart2', 'U') is not null
        drop table #chart2;

    if object_id('TempDB..#Audit1A', 'U') is not null
        drop table #Audit1A;
    if object_id('TempDB..#Audit1', 'U') is not null
        drop table #Audit1;
    if object_id('TempDB..#Audit1_ChartID', 'U') is not null
        drop table #Audit1_ChartID;
    if object_id('TempDB..#LogNote1', 'U') is not null
        drop table #LogNote1;
    if object_id('TempDB..#LogNote2A', 'U') is not null
        drop table #LogNote2A;
    if object_id('TempDB..#LogNote2B', 'U') is not null
        drop table #LogNote2B;
    if object_id('TempDB..#LogNote3', 'U') is not null
        drop table #LogNote3;

    if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;



		-- AuthorizedFacilities

SELECT *
INTO #AuthorizedFacilities
FROM (
  SELECT DISTINCT fua.FACILITY_ID
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id 
	and ( up.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR up.IS_ACTIVE = 'Y' )
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser	 

    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FacilityID, ','))
            OR	'-1' in (SELECT * FROM SPLITSTRING(@m_FacilityID, ',')) )

	and
			(
			0 = (@Region)
			or (sa.SERVICE_AGREEMENT_ID in
					(
					select distinct
						   samt.SERVICE_AGREEMENT_ID
					from
						SERVICE_AGREEMENT_MANAGEMENT_TEAM samt
						,USER_PROFILE up
					where
						samt.USER_PROFILE_ID = up.USER_PROFILE_ID and samt.MANAGEMENT_TEAM_ROLE_ID = 1
						and up.USER_PROFILE_ID = (@Region) 
					)
			   )
			)

   ) af;


--  select * from #AuthorizedFacilities			-- Testing Only - to review #AuthorizedFacilities temp table	


    -- ACS-15489, installed to production on 2/11/2020 to correct issue with First Auditor being over written.

    -- for reporting, audit data prior to 2/11/2020, some records will needed to be pulled from Log Notes to accurately report who did the first level audit. 
    -- Example Below - Second Level Auditor Push Overwrites First Level Auditor
    -- select  c.[START_QA_DATE], c.[START_QA_USER_PROFILE_ID], c.[APPROVED_DATE], c.[APPROVED_BY_USER_PROFILE_ID], c.START_SECOND_LEVEL_QA_DATETIME, c.SECOND_LEVEL_QA_APPROVED_DATETIME, c.[SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID], * from chart c where chart_id = 64136908 



    select
        c.CHART_ID
    into
        #Audit1A
    from
        CHART c
    where
        c.CHART_STATUS_ID in (4, 5, 8)
        and dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0) between @m_FromDate and @m_ToDate;


    select
        c.CHART_ID
        ,c.[FACILITY_ID]
        ,c.[SERVICE_AGREEMENT_ID]
        ,c.[APPROVED_DATE]
        ,c.[APPROVED_BY_USER_PROFILE_ID]
        ,c.[START_QA_DATE]
        ,c.[START_QA_USER_PROFILE_ID]
        ,c.[SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID]
    into
        #Audit1
    from
        CHART c
    where
        exists
    (
        select a1.CHART_ID from #Audit1A a1 where a1.CHART_ID = c.CHART_ID
    );


    if @m_FromDate < '02/11/2020'
    begin



        select
            CHART_ID
        into
            #Audit1_ChartID
        from
            #Audit1
        where
            cast(APPROVED_DATE as date) < '02/11/2020'
            and
            (
                SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID is not null
                and SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2
            );


        select
            *
        into
            #LogNote1
        from
        (
            select
                LN.LOG_NOTE_ID
                ,LN.CHART_ID
                ,LN.COMPLETION_DATE
                ,LN.COMPLETED_BY_USER_ID
                ,LN.CATEGORY_ID
                ,LN.SUMMARY as SUMMARY
            from
                LOG_NOTE LN with (nolock)
            where
                LN.CATEGORY_ID in (3, 9)
                and exists
            (
                select CHART_ID from #Audit1_ChartID where CHART_ID = LN.CHART_ID
            )
        ) t2;


        select
            *
        into
            #LogNote2A
        from
        (
            select
                ln1.LOG_NOTE_ID
                ,ln1.CHART_ID
                ,ln1.COMPLETION_DATE
                ,ln1.COMPLETED_BY_USER_ID
                ,ln1.CATEGORY_ID
                ,ln1.SUMMARY as SUMMARY
            from
                #LogNote1 ln1
            where
                ln1.CATEGORY_ID = 9
                and ln1.COMPLETION_DATE =
                (
                    select
                        max(COMPLETION_DATE)
                    from
                        #LogNote1
                    where
                        ln1.CHART_ID = CHART_ID
                        and CATEGORY_ID = 9
                )
        ) T2a;




        if object_id('TempDB..#LogNote2AA', 'U') is not null
            drop table #LogNote2AA;

        select
            ln2a.*
            ,l1.COMPLETED_BY_USER_ID as COMPLETED_BY
        into
            #LogNote2AA
        from
            #LogNote2A ln2a
        left join
        #LogNote1      l1 on ln2a.CHART_ID = l1.CHART_ID
                             and l1.CATEGORY_ID = 3
                             and ln2a.COMPLETED_BY_USER_ID = l1.COMPLETED_BY_USER_ID;




        delete
        #LogNote2A
        from
            #LogNote2AA AA
        where
            #LogNote2A.CHART_ID = AA.CHART_ID
            and #LogNote2A.COMPLETED_BY_USER_ID = AA.COMPLETED_BY_USER_ID
            and AA.COMPLETED_BY is null; -- No Starting QA record









        -- check for duplicate records

        if object_id('TempDB..#LogNote2AAA', 'U') is not null
            drop table #LogNote2AAA;

        select
            LOG_NOTE_ID
            ,CHART_ID
            ,CATEGORY_ID
            ,COMPLETED_BY_USER_ID
            ,COMPLETION_DATE
            ,rank() over (partition by
                              CHART_ID
                              ,CATEGORY_ID
                          order by
                              COMPLETION_DATE desc
                              ,LOG_NOTE_ID desc
                         ) as xRank
        into
            #LogNote2AAA
        from
        (select * from #LogNote2A) as t1;



        delete from
        #LogNote2A
        where
            LOG_NOTE_ID in
            (
                select LOG_NOTE_ID from #LogNote2AAA where xRank = 2
            );








        select
            *
        into
            #LogNote2B
        from
        (
            select
                ln1.CHART_ID               as CHART_ID
                ,ln1.COMPLETION_DATE       as COMPLETION_DATE
                ,ln1a.COMPLETED_BY_USER_ID as completed_by_user_id
                ,ln1.CATEGORY_ID           as category_id
                ,ln1.SUMMARY               as SUMMARY
            from
                #LogNote1 ln1
            join
            #LogNote2A    ln1a on ln1a.CHART_ID = ln1.CHART_ID
                                  and ln1.COMPLETED_BY_USER_ID = ln1a.COMPLETED_BY_USER_ID
            where
                ln1.CATEGORY_ID = 3
                and ln1.SUMMARY = 'Chart approved.'
                and ln1.COMPLETION_DATE =
                (
                    select
                        max(COMPLETION_DATE)
                    from
                        #LogNote1
                    where
                        ln1.CHART_ID = CHART_ID
                        and ln1.COMPLETED_BY_USER_ID = COMPLETED_BY_USER_ID
                        and CATEGORY_ID = 3
                        and SUMMARY = 'Chart approved.'
                )
        ) t2b;






        select
            *
        into
            #LogNote3
        from
        (
            select distinct
                c1.CHART_ID
                ,c1.FACILITY_ID
                ,c1.SERVICE_AGREEMENT_ID
                ,c1.APPROVED_DATE
                ,c1.APPROVED_BY_USER_PROFILE_ID
                ,LN1A.COMPLETION_DATE      as CAT9_COMP_DATE
                ,LN1A.COMPLETED_BY_USER_ID as CAT9_USER_ID
                ,LN1A.SUMMARY              as CAT9_SUMMARY
                ,(LN1B.COMPLETION_DATE)    as CAT3_COMP_DATE
                ,(case
                      when LN1A.COMPLETED_BY_USER_ID = LN1B.completed_by_user_id then LN1B.completed_by_user_id
                      when LN1A.COMPLETED_BY_USER_ID is null
                           and LN1B.completed_by_user_id is null then LN1B.completed_by_user_id
                      when LN1A.COMPLETED_BY_USER_ID is null
                           and LN1B.completed_by_user_id = 2 then LN1B.completed_by_user_id
                  else null end
                 )                         as CAT3_USER_ID
                ,LN1B.SUMMARY              as CAT3_SUMMARY
            from
                #Audit1 c1
            left outer join
            #LogNote2A  LN1A on c1.CHART_ID = LN1A.CHART_ID
            left outer join
            #LogNote2B  LN1B on c1.CHART_ID = LN1B.CHART_ID
            where
                exists
            (
                select CHART_ID from #Audit1_ChartID where CHART_ID = c1.CHART_ID
            )
        ) T3;





        update
            a1
        set
            a1.[APPROVED_BY_USER_PROFILE_ID] = ln3.CAT3_USER_ID
        from
            #Audit1 as a1
        join
        #LogNote3   as ln3 on a1.CHART_ID = ln3.CHART_ID;


    end;




    print 'Section: 01 ' + convert(varchar, getdate(), 121);

--	 select * from #chart1

    select
        *
    into
        #chart1
    from
    (
        --  Completed Charts 

        select
            c.FACILITY_ID
            ,c.CHART_ID
            ,c.SERVICE_AGREEMENT_ID
            ,null                                                 as START_QA_DATE
            ,c.COMPLETED_BY_USER_PROFILE_ID                       as CODER_USER_ID
            ,dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) PROCESSED
            ,'C'                                                  as TYPE_CD
        from
            CHART c
        where
            c.CHART_STATUS_ID in (3, 4, 5)
            and
            (
                @m_AuditorID = -1
                or c.COMPLETED_BY_USER_PROFILE_ID = @m_AuditorID
            )
            and c.FACILITY_ID in ( select FACILITY_ID from #AuthorizedFacilities )            
            and dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) between @m_FromDate and @m_ToDate
        union all
        ---- First Level Audit 



        select
            c.FACILITY_ID
            ,c.CHART_ID
            ,c.SERVICE_AGREEMENT_ID
            ,c.START_QA_DATE
            ,c.APPROVED_BY_USER_PROFILE_ID                      as CODER_USER_ID
            ,dateadd(day, datediff(day, 0, c.APPROVED_DATE), 0) PROCESSED
            ,'A'                                                as TYPE_CD
        from
            #Audit1 c
        where
            c.APPROVED_BY_USER_PROFILE_ID is not null
            and c.APPROVED_BY_USER_PROFILE_ID not in (-1, 2, 80)            
            and c.FACILITY_ID in ( select FACILITY_ID from #AuthorizedFacilities )
        --AND ( c.second_level_qa_approved_by_user_profile_id is null  -- added to eliminate overstating approved counts
        --	    or c.second_level_qa_approved_by_user_profile_id <> c.APPROVED_BY_USER_PROFILE_ID ) 



        union all
        -- Second Level Audit ****

        select
            c.FACILITY_ID
            ,c.CHART_ID
            ,c.SERVICE_AGREEMENT_ID
            ,c.APPROVAL_REASON_CODE
            ,c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID                          as CODER_USER_ID
            ,dateadd(day, datediff(day, 0, c.SECOND_LEVEL_QA_APPROVED_DATETIME), 0) PROCESSED
            ,'A2'                                                                   as TYPE_CD
        from
            CHART c
        where
            c.CHART_STATUS_ID in (4, 5)
            and c.START_SECOND_LEVEL_QA_DATETIME is not null
            and c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID is not null
            and c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID not in (-1, 2, 80)
            and
            (
                @m_AuditorID = -1
                or c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID = @m_AuditorID
            )
            and c.FACILITY_ID in ( select FACILITY_ID from #AuthorizedFacilities )
            and dateadd(day, datediff(day, 0, c.SECOND_LEVEL_QA_APPROVED_DATETIME), 0) between @m_FromDate and @m_ToDate
        union all
        -- Post Bill Audit ****

        select
            c.FACILITY_ID
            ,c.CHART_ID
            ,c.SERVICE_AGREEMENT_ID
            ,null                                                           as START_QA_DATE
            ,c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID                         as CODER_USER_ID
            ,dateadd(day, datediff(day, 0, c.POST_BILL_AUDIT_COMPLETED), 0) PROCESSED
            ,'P'                                                            as TYPE_CD
        from
            CHART c
        where
            c.CHART_STATUS_ID in (4, 5)
            and c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID not in (-1, 2, 80)
            and
            (
                @m_AuditorID = -1
                or c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID = @m_AuditorID
            )
            and c.FACILITY_ID in ( select FACILITY_ID from #AuthorizedFacilities )
            and c.POST_BILL_AUDIT_COMPLETED is not null
            and dateadd(day, datediff(day, 0, c.POST_BILL_AUDIT_COMPLETED), 0) between @m_FromDate and @m_ToDate
    ) T1;







    print 'Section: 02 ' + convert(varchar, getdate(), 121);

    select
        *
    into
        #chart2
    from
    (
        select
            f.[NAME] FACILITY
            ,c.FACILITY_ID
            ,c.CHART_ID
            ,c.START_QA_DATE
            ,c.CODER_USER_ID
            ,c.PROCESSED
            ,c.TYPE_CD
            ,sa.SERVICE_AGREEMENT_ID
        from
            #chart1       c
        inner join
        SERVICE_AGREEMENT sa on sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
        inner join
        FACILITY          f on f.FACILITY_ID = c.FACILITY_ID
        where
            sa.DEMO_TEST_SITE_IND <> 1
            and exists
        (
            select
                *
            from
                FACILITY_USER_AUTHORIZATION
            where
                FACILITY_ID = c.FACILITY_ID
                and USER_PROFILE_ID = @m_ReportUser
                and dateadd(day, datediff(day, 0, getdate()), 0) between EFFECTIVE_DATE and EXPIRATION_DATE
        )
            and
            (
                sa.BILL_ONLY_ACTIVE_PROCEDURES_IND <> 1
                or exists
        (
            select * from SENT_PROCEDURE where CHART_ID = c.CHART_ID
        )
            )
    ) T2;


    print 'Section: 03 ' + convert(varchar, getdate(), 121);


    select
        o.ORGANIZATION_ID
        ,o.[DESCRIPTION]                     [ORGANIZATION]
        ,X.FACILITY
        ,X.FACILITY_ID
        ,X.EMPLOYEE
        ,X.CODER_USER_ID
        ,X.ID
        ,X.PROCESSED
        ,X.Complete
        ,X.Audited_1
        ,X.Pushed_1
        ,X.Audited_2
        ,X.Post_Bill
        ,am.USER_PROFILE_ID                  [RegionId]
        ,(
             select Region from vw_AccountManager_Region where ID = am.USER_PROFILE_ID
         )                                   as REGION
        ,am.LAST_NAME + ', ' + am.FIRST_NAME as ACCT_MANAGER
    from
    (
        select
            c.FACILITY
            ,c.FACILITY_ID
            ,up.LAST_NAME + ', ' + up.FIRST_NAME                                            EMPLOYEE
            ,c.CODER_USER_ID
            ,up.SIGN_ON_ID                                                                  ID
            ,c.PROCESSED
            ,sum(case when TYPE_CD = 'C' then 1 else 0 end)                                 as Complete
            ,sum(case when TYPE_CD = 'A' and c.START_QA_DATE is not null then 1 else 0 end) as Audited_1
            ,sum(case when TYPE_CD = 'A' and c.START_QA_DATE is null then 1 else 0 end)     as Pushed_1
            ,sum(case when TYPE_CD = 'A2' then 1 else 0 end)                                as Audited_2
            ,sum(case when TYPE_CD = 'P' then 1 else 0 end)                                 as Post_Bill
            ,c.SERVICE_AGREEMENT_ID
        from
            #chart2  c
        inner join
        USER_PROFILE up on up.USER_PROFILE_ID = c.CODER_USER_ID
        where
            up.USER_CLASS_CD = 1 -- Corporate Employee      
            and
            (
                @m_UserGroup = '-1'
                or
                (
                    up.USER_GROUP_ID in
                    (
                        select items from dbo.SplitString(@m_UserGroup, ',')
                    )
                    or exists
        (
            select
                *
            from
                USER_GROUP_TO_USER_PROFILE
            where
                USER_PROFILE_ID = up.USER_PROFILE_ID
                and USER_GROUP_TO_USER_PROFILE.USER_GROUP_ID in
                    (
                        select items from dbo.SplitString(@m_UserGroup, ',')
                    )
        )
                )
            )
        group by
            c.FACILITY
            ,c.FACILITY_ID
            ,up.LAST_NAME + ', ' + up.FIRST_NAME
            ,c.CODER_USER_ID
            ,up.SIGN_ON_ID
            ,c.PROCESSED
            ,c.SERVICE_AGREEMENT_ID
    )                                 X
    inner join
    [SERVICE_AGREEMENT]               sa with (nolock) on X.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
    inner join
    ORGANIZATION                      o on sa.ORGANIZATION_ID = o.ORGANIZATION_ID
    left join
    SERVICE_AGREEMENT_MANAGEMENT_TEAM samt on X.SERVICE_AGREEMENT_ID = samt.SERVICE_AGREEMENT_ID
                                              and samt.MANAGEMENT_TEAM_ROLE_ID = 1
    left join
    USER_PROFILE                      am with (nolock) on samt.USER_PROFILE_ID = am.USER_PROFILE_ID
    where
        (X.Complete + X.Audited_1 + X.Pushed_1 + X.Audited_2 + X.Post_Bill > 0)
		and (@ExcludeTrustSalesforceClients = 0 or o.ORGANIZATION_ID != 5);



    print 'Section: 04 ' + convert(varchar, getdate(), 121);


 end;




GO
GRANT EXECUTE ON  [dbo].[REPORT_Auditor_Productivity_by_Facility] TO [dbx_ExecuteReportProcs]
GO
