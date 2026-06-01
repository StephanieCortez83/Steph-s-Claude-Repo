SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[rpt_AutomationProfeeMDMAnalysisReport]
(@ReportUser int, @Facility_Id varchar(max), @StartDate datetime, @EndDate datetime)
as
begin
    set transaction isolation level read uncommitted;
	set nocount on;
    --declare
    --    @ReportUser   int          = 80
    --    ,@Facility_Id varchar(max) = '-1'
    --    ,@StartDate   datetime     = '20240821'
    --    ,@EndDate     datetime     = '20240831';
    ----------------------------------------------------------------------------------------------------------------------------------
    if object_id('TempDB..#CHART', 'U') is not null drop table #CHART;
    if object_id('TempDB..#PSEVAL', 'U') is not null drop table #PSEVAL;
    if object_id('TempDB..#PSEVAL_AUTO', 'U') is not null drop table #PSEVAL_AUTO;
    if object_id('TempDB..#results', 'U') is not null drop table #results;
	print 'Section: 00 ' + convert(varchar, getdate(), 121)
    ----------------------------------------------------------------------------------------------------------------------------------
    select
        c.FACILITY_ID
        ,c.CHART_ID
		,c.FACILITY_CHART_ID
        ,cast(c.TIME_OF_SERVICE as date) TIME_OF_SERVICE
    into #CHART
    from
        dbo.CHART c
    where
        (c.FACILITY_ID in ( select items from dbo.SplitString(@Facility_Id, ',') )
			or '-1' in ( select items from dbo.SplitString(@Facility_Id, ',') )
			)
        and c.TIME_OF_SERVICE between @StartDate and dateadd(second, 86399, @EndDate)
        and exists
			(
				select *
				from
					FACILITY_USER_AUTHORIZATION FUA with (nolock)
					,USER_PROFILE UP with (nolock)
				where
					FUA.FACILITY_ID = c.FACILITY_ID
					and FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
					and
					(
						UP.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate()))
						or UP.IS_ACTIVE = 'Y'
					)
					and getdate() between FUA.EFFECTIVE_DATE and FUA.EXPIRATION_DATE
					and FUA.USER_PROFILE_ID = @ReportUser
			)--;
		and exists
			(
				select *
				from
					dbo.PHYSICIAN_SERVICE_EVAL_AUTOMATION psea
				where
					c.CHART_ID = psea.CHART_ID
			)
	print 'Section: 01 ' + convert(varchar, getdate(), 121)
    ----------------------------------------------------------------------------------------------------------------------------------
    select
        c.FACILITY_ID
        ,c.CHART_ID
		,c.FACILITY_CHART_ID
        ,c.TIME_OF_SERVICE
        ,pse.PHYSICIAN_SERVICE_ID
        ,pse.LEVEL_NUMBER
        ,ps.CATEGORY_ID
        ,ps.SUBCATEGORY_ID
        ,case
             when ps.SUBCATEGORY_ID = 1 then 'Problem'
             when ps.SUBCATEGORY_ID = 2 then 'Data'
             when ps.SUBCATEGORY_ID = 3 then 'Risk'
         else 'N/A' end [SUBCATEGORY_DESC]
        ,pse.QUANTITY
        --,ps.MINOR_CATEGORY
        ,ps.[DESCRIPTION]
    into #PSEVAL
    from
        #CHART c
		inner join dbo.PHYSICIAN_SERVICE_EVAL pse on c.CHART_ID = pse.CHART_ID
		inner join dbo.PHYSICIAN_SERVICE ps on pse.PHYSICIAN_SERVICE_ID = ps.PHYSICIAN_SERVICE_ID
    where
        ps.CATEGORY_ID = 3;
	print 'Section: 02 ' + convert(varchar, getdate(), 121)
    ----------------------------------------------------------------------------------------------------------------------------------
    select
        c.FACILITY_ID
        ,c.CHART_ID
		,c.FACILITY_CHART_ID
        ,c.TIME_OF_SERVICE
        ,psea.PHYSICIAN_SERVICE_ID
        ,psea.LEVEL_NUMBER
        ,ps.CATEGORY_ID
        ,ps.SUBCATEGORY_ID
        ,case
             when ps.SUBCATEGORY_ID = 1 then 'Problem'
             when ps.SUBCATEGORY_ID = 2 then 'Data'
             when ps.SUBCATEGORY_ID = 3 then 'Risk'
         else 'N/A' end [SUBCATEGORY_DESC]
        ,psea.QUANTITY
        --,ps.MINOR_CATEGORY
        ,ps.[DESCRIPTION]
    into #PSEVAL_AUTO
    from
        #CHART c
		inner join dbo.PHYSICIAN_SERVICE_EVAL_AUTOMATION psea on c.CHART_ID = psea.CHART_ID
		inner join dbo.PHYSICIAN_SERVICE ps on psea.PHYSICIAN_SERVICE_ID = ps.PHYSICIAN_SERVICE_ID
    where
        ps.CATEGORY_ID = 3;
	print 'Section: 03 ' + convert(varchar, getdate(), 121)
    ----------------------------------------------------------------------------------------------------------------------------------
    delete from #PSEVAL
    from
        #PSEVAL a
    where
        not exists
		(
			select 1 from #PSEVAL_AUTO b where a.CHART_ID = b.CHART_ID
		);
	print 'Section: 04 ' + convert(varchar, getdate(), 121)
    ----------------------------------------------------------------------------------------------------------------------------------
    --select *
    --from
    --	#PSEVAL_AUTO a
    --where
    --	a.SUBCATEGORY_ID = 2
    --order by a.PHYSICIAN_SERVICE_ID
    --select *
    --from
    --	#PSEVAL b
    --where
    --	b.SUBCATEGORY_ID = 2
    --order by b.PHYSICIAN_SERVICE_ID
	print 'Section: 05 ' + convert(varchar, getdate(), 121)
    ----------------------------------------------------------------------------------------------------------------------------------
    select
        x.FACILITY_ID
        ,f.[NAME] [FACILITY]
        ,x.CHART_ID
		,x.FACILITY_CHART_ID
        ,x.TIME_OF_SERVICE
        ,x.PHYSICIAN_SERVICE_ID
        ,x.CATEGORY_ID
        ,x.SUBCATEGORY_ID
        ,x.SUBCATEGORY_DESC
        ,x.QUANTITY
        --,x.[DESCRIPTION]
        ,case
             when x.SUBCATEGORY_ID = 1 then replace(replace(x.[DESCRIPTION], '<i><strong>', ''), '</strong></i>', '')
             when x.SUBCATEGORY_ID = 2 then x.[DESCRIPTION]
             when x.SUBCATEGORY_ID = 3 then
                 replace(
                            replace(left(x.[DESCRIPTION], charindex('</b>', x.[DESCRIPTION], 0) + 3), '<b>', '')
                            ,'</b>'
                            ,''
                        )
         else x.[DESCRIPTION] end as [DESCRIPTION]
        ,1 [Auto_Sent]
        ,x.Added
        ,x.Removed
        ,case when (x.Added + x.Removed) > 0 then 1 else 0 end [Modified]
        ,case when (x.Added + x.Removed) = 0 then 1 else 0 end [No_Changes]
		--,x.LEVEL_NUMBER
    from
    (
        -- no changes
        select
            b.*
            ,0 [Added]
            ,0 [Removed]
        from
            #PSEVAL b
			left join #PSEVAL_AUTO a on b.CHART_ID = a.CHART_ID and b.PHYSICIAN_SERVICE_ID = a.PHYSICIAN_SERVICE_ID
        where
            a.CHART_ID is not null
            and b.QUANTITY = a.QUANTITY
        union all
        -- removed
        select
            a.*
            ,0
            ,1
        from
            #PSEVAL_AUTO a
			left join #PSEVAL b on a.CHART_ID = b.CHART_ID and a.PHYSICIAN_SERVICE_ID = b.PHYSICIAN_SERVICE_ID
        where
            b.CHART_ID is null
        union all
        -- added
        select
            b.*
            ,1
            ,0
        from
            #PSEVAL b
			left join #PSEVAL_AUTO a on b.CHART_ID = a.CHART_ID and b.PHYSICIAN_SERVICE_ID = a.PHYSICIAN_SERVICE_ID
        where
            a.CHART_ID is null
        union all
        -- difference in quantity
        select
            b.*
            ,case when b.QUANTITY > a.QUANTITY then b.QUANTITY - a.QUANTITY else 0 end
            ,case when a.QUANTITY > b.QUANTITY then a.QUANTITY - b.QUANTITY else 0 end
        from
            #PSEVAL b
			left join #PSEVAL_AUTO a on b.CHART_ID = a.CHART_ID and b.PHYSICIAN_SERVICE_ID = a.PHYSICIAN_SERVICE_ID
        where
            b.QUANTITY <> a.QUANTITY
    )            x
    inner join dbo.FACILITY f on x.FACILITY_ID = f.FACILITY_ID
    order by
        [FACILITY_ID]
        ,[TIME_OF_SERVICE]
        ,[CHART_ID]
		,[FACILITY_CHART_ID]
        ,[SUBCATEGORY_ID]
        ,[PHYSICIAN_SERVICE_ID];
	print 'Section: 06 ' + convert(varchar, getdate(), 121)
	----------------------------------------------------------------------------------------------------------------------------------
end;
GO
