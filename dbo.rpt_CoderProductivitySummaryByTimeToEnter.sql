SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 9/12/2014
-- Description:	SQL for the Coder Productivity Summary by Time to Enter report
-- Modifications: 
--				05/01/2019 | JHerrera | ACS-14280 | Allow report to run for inactive facilities.
--				03/02/2020 | JHerrera | AAR-400 | Add IsAdminCodeAppInt.
-- =============================================
CREATE procedure [dbo].[rpt_CoderProductivitySummaryByTimeToEnter]
    -- Add the parameters for the stored procedure here
    @Facility              varchar(max)
    ,@Organization         varchar(max)
    ,@ChartAccessEventType varchar(10)
    ,@UserProfile          varchar(max)
    ,@FromDate             datetime
    ,@ToDate               datetime
    ,@Disposition          varchar(max)
    ,@ReportUser           int
    ,@DateGrouping         int = 0 -- 0: Month, 1: Day
as
    begin
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        set nocount on;

        -- Insert statements for procedure here
        declare
            @m_Facility              varchar(max) = @Facility
            ,@m_Organization         varchar(max) = @Organization
            ,@m_ChartAccessEventType varchar(10)  = @ChartAccessEventType
            ,@m_UserProfile          varchar(max) = @UserProfile
            ,@m_FromDate             datetime     = @FromDate
            ,@m_ToDate               datetime     = @ToDate
            ,@m_DateGrouping         int          = @DateGrouping
            ,@m_ReportUser           int          = @ReportUser
            ,@m_Disposition          varchar(max) = @Disposition;




        if object_id('TempDB..#Facility', 'U') is not null
            begin
                drop table #Facility;
            end;

        if object_id('TempDB..#User', 'U') is not null
            begin
                drop table #User;
            end;


        select
            *
        into
            #Facility
        from
            (
            select distinct
                   sa.FACILITY_ID
            from
                SERVICE_AGREEMENT sa with (nolock)
                ,FACILITY f with (nolock)
            where
                f.FACILITY_ID = sa.FACILITY_ID and sa.DEMO_TEST_SITE_IND = 0
                --and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE	
                and exists
                (
                select
                    *
                from
                    [dbo].SplitString(@m_Organization, ',')
                where
                    items = sa.company_ID
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
                    FACILITY_USER_AUTHORIZATION FUA with (nolock)
                    ,USER_PROFILE UP with (nolock)
                where
                    FUA.FACILITY_ID = f.FACILITY_ID and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID and UP.IS_ACTIVE = 'Y'
                    and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
                    and FUA.USER_PROFILE_ID = @m_ReportUser
                    --and   ((fua.FACILITY_ID in (@m_Facility)) or (-1 in (@m_Facility)) )					

                    and exists
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


        select
            *
        into
            #User
        from
            (
            select
                USER_PROFILE.USER_PROFILE_ID
            from
                USER_PROFILE with (nolock)
            where
                exists
                (
                select * from [dbo].SplitString(@m_UserProfile, ',') where items = -1
                ) and USER_PROFILE.USER_PROFILE_ID not in (2, 5, 80)
                and USER_PROFILE.USER_CLASS_CD = 1 --Corporate Employee
                and exists
                (
                select * from #Facility where FACILITY_ID = #Facility.FACILITY_ID
                )
                and exists
                (
                select
                    *
                from
                    CHART_ACCESS with (nolock)
                    inner join CHART with (nolock) on CHART.CHART_ID = CHART_ACCESS.CHART_ID
                where
                    CHART_ACCESS.USER_PROFILE_ID = USER_PROFILE.USER_PROFILE_ID and exists
                    (
                    select * from #Facility where CHART.FACILITY_ID = #Facility.FACILITY_ID
                    ) and CHART_STATUS_ID in (3, 4, 5)
                    and cast(EVENT_COMPLETION_DATE_TIME as date) between @m_FromDate and @m_ToDate
                )
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
                    [dbo].SplitString(@m_UserProfile, ',')
                where
                    items = USER_PROFILE_ID
                ) and USER_PROFILE_ID <> -1
            ) t2;



        with Details
        as
        (select
             ce.CHART_ACCESS_EVENT_TYPE_DESC [Event]
             ,f.NAME as Facility
             ,up.LAST_NAME + ', ' + up.FIRST_NAME UserName
			 ,up.USER_GROUP_ID
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
         from
             CHART_ACCESS ca with (nolock)
             ,CHART_ACCESS ca2 with (nolock)
             ,CHART_ACCESS_EVENT_TYPE ce with (nolock)
             ,CHART c with (nolock)
             ,FACILITY f with (nolock)
             ,USER_PROFILE up with (nolock)
         where
             ca.CHART_ACCESS_EVENT_TYPE_CODE = ce.CHART_ACCESS_EVENT_TYPE_CODE
             and dateadd(day, datediff(day, 0, ca.EVENT_COMPLETION_DATE_TIME), 0) between @m_FromDate and @m_ToDate
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
                     CHART_ACCESS ca3 with (nolock)
                 where
                     ca3.CHART_ACCESS_EVENT_TYPE_CODE = ca.CHART_ACCESS_EVENT_TYPE_CODE and ca3.CHART_ID = ca.CHART_ID
                     and ca3.USER_PROFILE_ID = ca.USER_PROFILE_ID
                 ) and ca.EVENT_COMPLETION_DATE_TIME is not null
             --AND (
             --	(
             --		ca.CHART_ACCESS_EVENT_TYPE_CODE = 'A'
             --		AND ca.SECONDARY_EVENT_COMPLETION_DATE_TIME IS NULL
             --		)
             --	OR (
             --		ca.CHART_ACCESS_EVENT_TYPE_CODE = 'C'
             --		AND ca.SECONDARY_EVENT_COMPLETION_DATE_TIME IS NOT NULL
             --		)
             --	)
             and ca.CHART_ACCESS_EVENT_TYPE_CODE in
                     (
                     select items from [dbo].SplitString(@m_ChartAccessEventType, ',')
                     ) and exists
             (
             select * from #Facility where f.FACILITY_ID = #Facility.FACILITY_ID
             ) and exists
             (
             select * from #User where ca.USER_PROFILE_ID = #User.USER_PROFILE_ID
             )
         group by
             ce.CHART_ACCESS_EVENT_TYPE_DESC
             ,up.USER_PROFILE_ID
             ,up.LAST_NAME + ', ' + up.FIRST_NAME
			 ,up.USER_GROUP_ID
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
                  else 'Unknown' end)
        select
            [Event]
            ,Facility
            ,UserName
			,ug.[NAME] [USER_GROUP]
            ,CompletionDate
            ,ElapsedTime
            ,ChartsIncluded
            ,FacilityID
            ,UserProfileID
            ,ChartAccessEventType
            ,Disposition
			,case when acai.USER_PROFILE_ID is not null then 1 else 0 end [IsAdminCodeAppInt]
        from
            Details
			inner join USER_GROUP ug on Details.USER_GROUP_ID = ug.USER_GROUP_ID
			outer apply (select up.USER_PROFILE_ID
						from 
							USER_PROFILE up
							inner join USER_GROUP ug on up.USER_GROUP_ID = ug.USER_GROUP_ID
						where
							ug.USER_GROUP_ID in (1,89)	-- Administrators, CodeApproveInternal
							and Details.UserProfileID = up.USER_PROFILE_ID
						union
						select up.USER_PROFILE_ID
						from 
							USER_PROFILE up
							inner join USER_GROUP_TO_USER_PROFILE ugup on up.USER_PROFILE_ID = ugup.USER_PROFILE_ID
						where
							ugup.USER_GROUP_ID in (1,89)	-- Administrators, CodeApproveInternal
							and Details.UserProfileID = up.USER_PROFILE_ID
						) acai
        order by
            [Event]
            ,UserName
            ,Facility
            ,CompletionDate;
    end;

GO
GRANT EXECUTE ON  [dbo].[rpt_CoderProductivitySummaryByTimeToEnter] TO [dbx_ExecuteReportProcs]
GO
