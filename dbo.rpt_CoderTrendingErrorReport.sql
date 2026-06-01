SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 6/6/2016
-- Description:	SQL for the Coder Trending Error Report
-- =============================================
CREATE procedure [dbo].[rpt_CoderTrendingErrorReport]
    -- Add the parameters for the stored procedure here
    @TopN        int = 5
    ,@Facility   varchar(max)
    ,@DateType   int = 0
    ,@From       datetime
    ,@To         datetime
    ,@Grouping   int = 1
    ,@UserGroup  varchar(max)
    ,@Coder      varchar(max)
    ,@ReportUser int
as
    begin
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        set nocount on;
		set transaction isolation level read uncommitted

        ---- TEST PARMS --
        --declare
        --	@TopN        int          = 5
        --	,@Facility   varchar(max) = '-1'
        --	,@DateType   int          = 0
        --	,@From       datetime     = '08/1/2018'
        --	,@To         datetime     = '08/31/2018'
        --	,@Grouping   int          = 0
        --	,@UserGroup  varchar(max) = '183,184,185'
        --	,@Coder      varchar(max) = '-1'  --8703,8707,8705,8706,8702
        --	,@ReportUser int          = 80;
        ---- TEST PARMS --

        -- Insert statements for procedure here
        declare
            @m_TopN        int          = @TopN
            ,@m_Facility   varchar(max) = @Facility
            ,@m_DateType   int          = @DateType
            ,@m_From       datetime     = @From
            ,@m_To         datetime     = dateadd(day, 1, @To)
            ,@m_Grouping   int          = @Grouping
            ,@m_UserGroup varchar(max) = @UserGroup
            ,@m_Coder      varchar(max) = @Coder
            ,@m_ReportUser int          = @ReportUser;

        -- Fill the GroupingCTE with Weeks or Months (based on @Grouping) between @From and @To
        with GroupingCTE
            (aDate)
        as
        (select
             @m_From
         union all
         select
             case @m_Grouping
                 when 1 then dateadd(month, datediff(month, 0, dateadd(month, 1, aDate)), 0)
                 else dateadd(week, datediff(week, 0, dateadd(week, 1, aDate)), 0)end
         from
             GroupingCTE
         where
             case @m_Grouping
                 when 1 then dateadd(month, datediff(month, 0, dateadd(month, 1, aDate)), 0)
                 else dateadd(week, datediff(week, 0, dateadd(week, 1, aDate)), 0)end <= @m_To
		)
        ,ChartSubset
        as
        (select d.*
			from
				[RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] d
			where
				case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end >= @m_From
				and case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end < @m_To
				and (@m_Facility = '-1'
						or (exists (
									select *
									from
										[dbo].[SplitString](@m_Facility, ',')
									where
										items = d.FACILITY_ID
									)
							)
						)
				and exists
				(
				select
					FUA.FACILITY_ID
				from
					FACILITY_USER_AUTHORIZATION FUA with (nolock)
					,USER_PROFILE UP with (nolock)
				where
					FUA.FACILITY_ID = d.FACILITY_ID and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID and UP.IS_ACTIVE = 'Y'
					and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE and FUA.USER_PROFILE_ID = @m_ReportUser
				)
				and exists
				(
				select
					1
				from
					USER_PROFILE
				where
					USER_GROUP_ID in
						(
						select * from dbo.SplitString(@UserGroup, ',')
						) and IS_ACTIVE = 'Y' and USER_PROFILE_ID = COMPLETED_BY_USER_PROFILE_ID
				union
				select
					1
				from
					USER_GROUP_TO_USER_PROFILE ugup
					,USER_PROFILE up
				where
					up.USER_PROFILE_ID = ugup.USER_PROFILE_ID and up.USER_PROFILE_ID = COMPLETED_BY_USER_PROFILE_ID
					and up.IS_ACTIVE = 'Y' and ugup.USER_GROUP_ID in
												   (
												   select * from dbo.SplitString(@UserGroup, ',')
												   )
				)
				and (@m_Coder = '-1'
						or (exists
								(
								select
									*
								from
									[dbo].[SplitString](@m_Coder, ',')
								where
									items = d.COMPLETED_BY_USER_PROFILE_ID
								)
							)
						)
		)
        ,[Procedures]
        as
        (select
             FACILITY_ID
             ,[CLASS]
             ,[ACTION]
             ,[CPT_CODE]
             ,[DESCRIPTION]
             ,count(*) TOTAL
             ,case @m_Grouping
                  when 1 then
                      dateadd(
                                 month
                                 ,datediff(month, 0, case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end)
                                 ,0
                             )
                  else
                      dateadd(
                                 week
                                 ,datediff(week, 0, case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end)
                                 ,0
                             )end MyDate
         from
             ChartSubset
         where
             CLASS in ('2', '3', '5') and [DESCRIPTION] is not null
         group by
             case @m_Grouping
                 when 1 then
                     dateadd(
                                month
                                ,datediff(month, 0, case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end)
                                ,0
                            )
                 else
                     dateadd(
                                week
                                ,datediff(week, 0, case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end)
                                ,0
                            )end
             ,[CLASS]
             ,[ACTION]
             ,[CPT_CODE]
             ,[DESCRIPTION]
             ,FACILITY_ID
		)
        ,Diagnosis
        as
        (select
             FACILITY_ID
             ,[CLASS]
             ,[ACTION]
             ,[CPT_CODE]
             ,count(*) TOTAL
             ,case @m_Grouping
                  when 1 then
                      dateadd(
                                 month
                                 ,datediff(month, 0, case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end)
                                 ,0
                             )
                  else
                      dateadd(
                                 week
                                 ,datediff(week, 0, case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end)
                                 ,0
                             )end MyDate
         from
             ChartSubset
         where
             CLASS = 'D'
         group by
             case @m_Grouping
                 when 1 then
                     dateadd(
                                month
                                ,datediff(month, 0, case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end)
                                ,0
                            )
                 else
                     dateadd(
                                week
                                ,datediff(week, 0, case @m_DateType when 0 then TIME_OF_SERVICE else SENT_DATE end)
                                ,0
                            )end
             ,[CLASS]
             ,[ACTION]
             ,[CPT_CODE]
             ,FACILITY_ID
		)
        select distinct
               aDate
               ,t.*
               ,(
                select Region from vw_AccountManager_Region where ID = am.user_profile_id
                ) as [REGION]
        --case --when @ACCT_MANAGER = 0 then 'All Regions'
        --	when am.user_profile_id = 92 then 'Community'
        --	when am.user_profile_id = 646 then 'Regional'
        --	when am.user_profile_id = 2257 then 'National-LifePoint'
        --	when am.user_profile_id = 5419 then 'National-Ascension'
        --	when am.user_profile_id = 6793 then 'National-PeaceHealth'
        --	when am.user_profile_id = 4794 then 'Pediatric'
        --else null end as [REGION]
        from
            GroupingCTE g
            cross apply
					(
					select top (@m_TopN)
							c.[DESCRIPTION] [CLASS]
							,[ACTION]
							,[CPT_CODE]
							,p.[DESCRIPTION]
							,[TOTAL]
							,FACILITY_ID
					from
						[Procedures] p
						inner join [dbo].[CHART_AUDIT_ACTION_CLASS] c on c.CLASS = p.CLASS
					where
						p.CLASS = '2' and [ACTION] = 'A' and p.MyDate = aDate
					order by
						[TOTAL] desc
					union
					select top (@m_TopN)
							c.[DESCRIPTION] [CLASS]
							,[ACTION]
							,[CPT_CODE]
							,p.[DESCRIPTION]
							,[TOTAL]
							,FACILITY_ID
					from
						[Procedures] p
						inner join [dbo].[CHART_AUDIT_ACTION_CLASS] c on c.CLASS = p.CLASS
					where
						p.CLASS = '2' and [ACTION] = 'R' and p.MyDate = aDate
					order by
						[TOTAL] desc
					union
					select top (@m_TopN)
							c.[DESCRIPTION] [CLASS]
							,[ACTION]
							,[CPT_CODE]
							,p.[DESCRIPTION]
							,[TOTAL]
							,FACILITY_ID
					from
						[Procedures] p
						inner join [dbo].[CHART_AUDIT_ACTION_CLASS] c on c.CLASS = p.CLASS
					where
						p.CLASS = '3' and [ACTION] = 'A' and p.MyDate = aDate
					order by
						[TOTAL] desc
					union
					select top (@m_TopN)
							c.[DESCRIPTION] [CLASS]
							,[ACTION]
							,[CPT_CODE]
							,p.[DESCRIPTION]
							,[TOTAL]
							,FACILITY_ID
					from
						[Procedures] p
						inner join [dbo].[CHART_AUDIT_ACTION_CLASS] c on c.CLASS = p.CLASS
					where
						p.CLASS = '3' and [ACTION] = 'R' and p.MyDate = aDate
					order by
						[TOTAL] desc
					union
					select top (@m_TopN)
							c.[DESCRIPTION] [CLASS]
							,[ACTION]
							,[CPT_CODE]
							,p.[DESCRIPTION]
							,[TOTAL]
							,FACILITY_ID
					from
						[Procedures] p
						inner join [dbo].[CHART_AUDIT_ACTION_CLASS] c on c.CLASS = p.CLASS
					where
						p.CLASS = '5' and [ACTION] = 'A' and p.MyDate = aDate
					order by
						[TOTAL] desc
					union
					select top (@m_TopN)
							c.[DESCRIPTION] [CLASS]
							,[ACTION]
							,[CPT_CODE]
							,p.[DESCRIPTION]
							,[TOTAL]
							,FACILITY_ID
					from
						[Procedures] p
						inner join [dbo].[CHART_AUDIT_ACTION_CLASS] c on c.CLASS = p.CLASS
					where
						p.CLASS = '5' and [ACTION] = 'R' and p.MyDate = aDate
					order by
						[TOTAL] desc
					union
					select top (@m_TopN)
							c.[DESCRIPTION] [CLASS]
							,[ACTION]
							,[CPT_CODE]
							,(
							select
								[SHORT_DESCRIPTION]
							from
								[dbo].[ICD_10_CM] with (nolock)
							where
								ICD_10_CODE = replace(d.CPT_CODE, '.', '') and d.MyDate between EFFECTIVE_DATE and EXPIRATION_DATE
							) [DESCRIPTION]
							,[TOTAL]
							,FACILITY_ID
					from
						Diagnosis d
						inner join [dbo].[CHART_AUDIT_ACTION_CLASS] c on c.CLASS = d.CLASS
					where
						d.CLASS = 'D' and [ACTION] = 'A' and d.MyDate = aDate
					order by
						[TOTAL] desc
					union
					select top (@m_TopN)
							c.[DESCRIPTION] [CLASS]
							,[ACTION]
							,[CPT_CODE]
							,(
							select
								[SHORT_DESCRIPTION]
							from
								[dbo].[ICD_10_CM] with (nolock)
							where
								ICD_10_CODE = replace(d.CPT_CODE, '.', '') and d.MyDate between EFFECTIVE_DATE and EXPIRATION_DATE
							) [DESCRIPTION]
							,[TOTAL]
							,FACILITY_ID
					from
						Diagnosis d
						inner join [dbo].[CHART_AUDIT_ACTION_CLASS] c on c.CLASS = d.CLASS
					where
						d.CLASS = 'D' and [ACTION] = 'R' and d.MyDate = aDate
					order by
						[TOTAL] desc
					) t
            inner join SERVICE_AGREEMENT sa on t.FACILITY_ID = sa.FACILITY_ID
            left join SERVICE_AGREEMENT_MANAGEMENT_TEAM samt1 on sa.SERVICE_AGREEMENT_ID = samt1.SERVICE_AGREEMENT_ID and samt1.MANAGEMENT_TEAM_ROLE_ID = 1
            left join USER_PROFILE am on samt1.USER_PROFILE_ID = am.USER_PROFILE_ID and am.IS_ACTIVE = 'Y';
    end;
GO
GRANT EXECUTE ON  [dbo].[rpt_CoderTrendingErrorReport] TO [dbx_ExecuteReportProcs]
GO
