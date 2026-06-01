SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

















-- ==========================================================
-- Author:		Don Hutton
-- Create date: 1/07/2016
-- Description:	Based on Production Snapshot Report Stored Procedure

-- ==========================================================
CREATE PROCEDURE [dbo].[rptProductionSnapshotByManagerReport]
	-- Add the parameters for the stored procedure here
	@AcctMgrID varchar(MAX) ,
	@ReportUser int
AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @m_AcctMgrID varchar(MAX) = @AcctMgrID,
		@Today DATE = GETDATE() ,
		@TodayM60 DATE = GETDATE() - 7,
		@m_ReportUser int = @ReportUser;

if object_id('TempDB..#FACILITY1', 'U') is not null	DROP TABLE #FACILITY1;
if object_ID('TempDB..#SAIDs', 'U') is not null DROP TABLE #SAIDs;
if object_id('TempDB..#ADV', 'U') is not null drop table #ADV; 
if object_id('TempDB..#ChartPreWork', 'U') is not null drop table #ChartPreWork; 
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset; 
if object_id('TempDB..#ChartSubset_2', 'U') is not null	drop table #ChartSubset_2; 
if object_id('TempDB..#LogNote', 'U') is not null drop table #LogNote;
if object_id('TempDB..#Aging', 'U') is not null	drop table #Aging;
if object_id('TempDB..#Aging_2', 'U') is not null drop table #Aging_2;
	


-- preprocess #SAIDs
select service_agreement_ID
into #SAIDs
from service_agreement as sa
WHERE ISNULL(sa.DEMO_TEST_SITE_IND, 0) = 0
	AND @Today BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
	AND (
		sa.[SERVICE_AGREEMENT_ID] IN (
			SELECT [SERVICE_AGREEMENT_ID]
			FROM [SERVICE_AGREEMENT_MANAGEMENT_TEAM] WITH (NOLOCK)
			WHERE [USER_PROFILE_ID] IN (SELECT * FROM SPLITSTRING(@m_AcctMgrID, ','))
			)
		)

		create nonclustered index idx_service_agreement_ID on #SAIDs (service_agreement_ID)


-- preprocess #Facility1
select * 					
into #FACILITY1				
from					
(
SELECT fua.FACILITY_ID, f.NAME 													
						FROM 
						FACILITY_USER_AUTHORIZATION fua WITH (NOLOCK) ,
						FACILITY f							
						WHERE fua.facility_id = f.facility_id
						AND GETDATE() BETWEEN fua.EFFECTIVE_DATE AND fua.EXPIRATION_DATE	
						AND fua.USER_PROFILE_ID=@m_ReportUser							
) T1;


       create nonclustered index idx_FACILITY_ID on #FACILITY1 (FACILITY_ID)


-- Average Daily Volume
	   
				SELECT 
				SERVICE_AGREEMENT_ID,
				SUM(TOTAL) / COUNT(*) as Avg_Daily_Volume
				into #ADV
				FROM (
					SELECT 
					SERVICE_AGREEMENT_ID,
					cast(TIME_OF_SERVICE as date) as DOS,
					COUNT(*) TOTAL
					FROM CHART WITH (NOLOCK)
					WHERE SERVICE_AGREEMENT_ID IN ( select distinct service_agreement_ID from #SAIDs) 
            AND CHART_STATUS_ID IN (1,2,3,4,5,8)
			AND TIME_OF_SERVICE < @Today
			AND DATEDIFF(DAY, @TodayM60, DATEADD(DAY, DATEDIFF(DAY, 0, TIME_OF_SERVICE), 0)) > 0            	
					GROUP BY 
					SERVICE_AGREEMENT_ID,
					cast(TIME_OF_SERVICE as date)
					) x
					group by 
					SERVICE_AGREEMENT_ID



select * into #ChartPreWork from (

select
		 c.CHART_ID
		,c.SERVICE_AGREEMENT_ID
		,c.FACILITY_ID
		,c.CHART_STATUS_ID
		,c.FACILITY_CHART_ID
		,c.TIME_OF_SERVICE
		,c.CREATION_DATE_TIME
		,c.DATE_RECEIVED
		,c.SENT_DATE
		,sa.TURNAROUND_HOURS_REPORTING_METHOD
		,sa.TURNAROUND_START_TIME_IN_MINUTES
		,sa.DEMO_TEST_SITE_IND	
		,sa.EXPIRATION_DATE
		,sa.[RCP_BILLING_IND]	
		,sa.[SERVICE_MODEL_CD]
	from
		CHART as c with (nolock)
		join SERVICE_AGREEMENT as sa with (nolock) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		
	where   c.CHART_STATUS_ID in (1, 2, 3, 4, 6, 7, 8)
	        and c.SERVICE_AGREEMENT_ID IN ( select distinct service_agreement_ID from #SAIDs) 
			and exists ( select * from #FACILITY1 where facility_id = c.facility_ID)


union

	select
		 c.CHART_ID
		,c.SERVICE_AGREEMENT_ID
		,c.FACILITY_ID
		,c.CHART_STATUS_ID
		,c.FACILITY_CHART_ID
		,c.TIME_OF_SERVICE
		,c.CREATION_DATE_TIME
		,c.DATE_RECEIVED
		,c.SENT_DATE
		,sa.TURNAROUND_HOURS_REPORTING_METHOD
		,sa.TURNAROUND_START_TIME_IN_MINUTES
		,sa.DEMO_TEST_SITE_IND	
		,sa.EXPIRATION_DATE
		,sa.[RCP_BILLING_IND]	
		,sa.[SERVICE_MODEL_CD]
		
	from
		CHART as c with (nolock)
		join SERVICE_AGREEMENT as sa with (nolock) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		
	where   c.CHART_STATUS_ID = 5 
	        and c.SENT_DATE >= DATEADD(DD, - 1, @Today)
	        and c.SERVICE_AGREEMENT_ID IN ( select distinct service_agreement_ID from #SAIDs) 
			and exists ( select * from #FACILITY1 where facility_id = c.facility_ID)

			
)t1;

			create nonclustered index idx_CHART_ID on #ChartPreWork (CHART_ID)
			create nonclustered index idx_SERVICE_AGREEMENT_ID on #ChartPreWork (SERVICE_AGREEMENT_ID)
			create nonclustered index idx_FACILITY_ID on #ChartPreWork (FACILITY_ID)




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
		,c.TURNAROUND_HOURS_REPORTING_METHOD
		,c.TURNAROUND_START_TIME_IN_MINUTES
		,c.DEMO_TEST_SITE_IND	
		,c.EXPIRATION_DATE	
	into
		#ChartSubset
	from
		#ChartPreWork as c with (nolock)		
		
	where 
	-- ACS-13480 request 'DOS in WIP' column is CHART_STATUS_ID = 1 only ***
	c.CHART_STATUS_ID = 1
			--(
			--(
			--c.TURNAROUND_HOURS_REPORTING_METHOD in (1, 2, 6, 7, 8, 9) and c.CHART_STATUS_ID in (1, 3, 8) -- Work in Progress, Completed and 2nd Audit only 
			
			--)
			--or
			--	(
			--	c.TURNAROUND_HOURS_REPORTING_METHOD in (3, 4) and c.CHART_STATUS_ID in (1, 3, 4) -- Work in Progress, Completed and Approved only
			
			--	)
			--or
			--	(
			--	c.TURNAROUND_HOURS_REPORTING_METHOD = 5 and c.CHART_STATUS_ID in (1, 3) -- Work in Progress and Completed only
			
			--	)
			--)

			
			create nonclustered index idx_CHART_ID on #ChartSubset (CHART_ID)
			create nonclustered index idx_SERVICE_AGREEMENT_ID on #ChartSubset (SERVICE_AGREEMENT_ID)
			create nonclustered index idx_FACILITY_ID on #ChartSubset (FACILITY_ID)







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
	into
		#ChartSubset_2
	from
		#ChartSubset as c with (nolock)
where
 	c.CHART_ID not in
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



		create nonclustered index idx_TURNAROUND_HOURS_REPORTING_METHOD on #ChartSubset_2 (TURNAROUND_HOURS_REPORTING_METHOD)
		create nonclustered index idx_CHART_STATUS_ID on #ChartSubset_2 (CHART_STATUS_ID)
		create nonclustered index idx_FACILITY_ID on #ChartSubset_2 (FACILITY_ID)



	select
		CHART_ID
		,Completion_Date = max(COMPLETION_DATE)
	into
		#LogNote
	from
		(
		select
			c.CHART_ID
			,ln.COMPLETION_DATE
		from
			LOG_NOTE ln with (nolock)
			join #ChartSubset_2 as c on ln.CHART_ID = c.CHART_ID
		where
			ln.CATEGORY_ID = 5 and ln.DETAIL like 'Chart status moved to work in progress.  Previous status was Pending%'
		union
		select
			c.CHART_ID
			,ln.COMPLETION_DATE
		from
			LOG_NOTE ln with (nolock)
			join #ChartSubset_2 as c on ln.CHART_ID = c.CHART_ID
		where
			ln.CATEGORY_ID = 8
			and
				(
				ln.SUMMARY like 'Chart status changed to Work in Progress%'
				or ln.DETAIL like 'Chart status changed to Work in Progress%'
				)
		) as x
	group by
		CHART_ID;




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

into
		#Aging
		 
	 from		 
		 #ChartSubset_2 as c
		 inner join FACILITY f with (nolock) on c.FACILITY_ID = f.FACILITY_ID
	 where
		 c.DEMO_TEST_SITE_IND <> 1 
		and c.EXPIRATION_DATE > getdate() -- 3-20-2015 DanielB: Ignore expired accounts
		-- ACS-13480 request 'DOS in WIP' column is CHART_STATUS_ID = 1 only ***
		 and c.CHART_STATUS_ID = 1
			 --(
			 --(
			 --c.TURNAROUND_HOURS_REPORTING_METHOD in (1, 2, 6, 7, 8, 9) and c.CHART_STATUS_ID in (1, 3) -- Work in Progress and Completed only
	
			 --)
			 --or
				-- (
				-- c.TURNAROUND_HOURS_REPORTING_METHOD in (3, 4) and c.CHART_STATUS_ID in (1, 3, 4) -- Work in Progress, Completed and Approved only
	
				-- )
			 --or
				-- (
				-- c.TURNAROUND_HOURS_REPORTING_METHOD = 5 and c.CHART_STATUS_ID in (1, 3) -- Work in Progress and Completed only
	
				-- )
			 --) 
			 and f.FACILITY_ID = c.FACILITY_ID 
			 

	

	 	 select 
		 max(facility_id) as Facility_ID, 
		 max(Facility) as Facility, 
		 max([Hours Elapsed]) as Hours_Elapsed
		 into #Aging_2
		 from #Aging
		 group by facility_id;


-- ****************************************************************************



		WITH ProductionSnapshot
	AS (
		SELECT 
		sa.SERVICE_AGREEMENT_ID,
		sa.FACILITY_ID,
		CASE 
				WHEN sa.[RCP_BILLING_IND] = 1
					THEN 'Billing'
				WHEN sa.[SERVICE_MODEL_CD] = 'ASP'
					THEN 'Software as a Service (SaaS)'
				ELSE 'Full Service'
				END [Service],
			f.[NAME] Faclity,
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 1
						THEN 1
					ELSE 0
					END) 'Work in Process',
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 2
						THEN 1
					ELSE 0
					END) 'Pending',
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 3
						THEN 1
					ELSE 0
					END) 'Complete',
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 4
						THEN 1
					ELSE 0
					END) 'Approved',
			SUM(CASE 
					WHEN c.CHART_STATUS_ID = 8
						THEN 1
					ELSE 0
					END) 'SecondAudit',					
			SUM(CASE 
					WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.CREATION_DATE_TIME), 0) = @Today
						THEN 1
					ELSE 0
					END) 'Received',
			SUM(CASE 
					WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.SENT_DATE), 0) = @Today
						THEN 1
					ELSE 0
					END) 'Sent',
			SUM(CASE 
					WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.SENT_DATE), 0) = DATEADD(DD, - 1, @Today)
						THEN 1
					ELSE 0
					END) 'SentYestrday',
			(
				SELECT MAX(CREATION_DATE_TIME)
				FROM IMPORT_BATCH WITH (NOLOCK)
				WHERE SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				) 'Last Census Rec''d',
			(
				SELECT COUNT(*)
				FROM [dbo].[vwImportImage] WITH (NOLOCK)
				WHERE SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
					AND DATEADD(DAY, DATEDIFF(DAY, 0, CREATION_DATE_TIME), 0) = @Today
				) 'Images Rec''d',
			(
				SELECT MAX(CREATION_DATE_TIME)
				FROM [dbo].[vwImportImage] WITH (NOLOCK)
				WHERE SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				) 'Last Image Rec''d',	

     	(
				SELECT Avg_Daily_Volume
				FROM #ADV 
				WHERE SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				) 'Avg Daily Volume',



      LTRIM(RTRIM(COALESCE(STUFF((
					SELECT ',' + cpy.[NAME] 
					FROM [dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla WITH (NOLOCK)
          INNER JOIN [dbo].[SERVICE_LOCATION] sl WITH (NOLOCK) ON sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
					INNER JOIN [dbo].[COMPANY] cpy WITH (NOLOCK) ON cpy.COMPANY_ID = sl.COMPANY_ID
					WHERE SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
						AND @Today BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
					ORDER BY cpy.[NAME]
					FOR XML PATH('')
					), 1, 1, ''), 'N/A'))) Vendor
		FROM 
		SERVICE_AGREEMENT sa WITH (NOLOCK)
		INNER JOIN #FACILITY1 f WITH (NOLOCK) ON f.FACILITY_ID = sa.FACILITY_ID
		LEFT JOIN #ChartPreWork c WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		WHERE ISNULL(sa.DEMO_TEST_SITE_IND, 0) = 0
			AND @Today BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE

			and     sa.SERVICE_AGREEMENT_ID IN ( select distinct service_agreement_ID from #SAIDs) 
					
			
		GROUP BY 
		sa.SERVICE_AGREEMENT_ID,
		sa.FACILITY_ID,
		sa.SERVICE_MODEL_CD,
		f.NAME,
		sa.EFFECTIVE_DATE,
		sa.RCP_BILLING_IND
		)
	SELECT p.*,
--		CAST([Work in Process] AS DECIMAL) / [Avg Daily Volume] 'DOS in WIP'


	( select 
	case when Hours_Elapsed > 0 and Hours_Elapsed <= 24 then 1
     when Hours_Elapsed > 24 and Hours_Elapsed <= 36 then 1.5
     when Hours_Elapsed > 36 and Hours_Elapsed <= 48 then 2
	 when Hours_Elapsed > 48 and Hours_Elapsed <= 60 then 2.5
     when Hours_Elapsed > 60 and Hours_Elapsed <= 72 then 3
	 when Hours_Elapsed > 72 and Hours_Elapsed <= 84 then 3.5	 
	 when Hours_Elapsed > 84 and Hours_Elapsed <= 96 then 4
	 when Hours_Elapsed > 96 and Hours_Elapsed <= 108 then 4.5
	 when Hours_Elapsed > 108 and Hours_Elapsed <= 120 then 5
	 when Hours_Elapsed > 120 and Hours_Elapsed <= 132 then 5.5
	 when Hours_Elapsed > 132 and Hours_Elapsed <= 144 then 6
	 when Hours_Elapsed > 144 and Hours_Elapsed <= 156 then 6.5
	 when Hours_Elapsed > 156 and Hours_Elapsed <= 168 then 7
	 when Hours_Elapsed > 168 then 7.5
    else 0 end
	from  #Aging_2
	where facility_id = p.facility_id) as 'DOS in WIP'

	FROM ProductionSnapshot p
	
	ORDER BY p.[Service],
		p.[Faclity]


	
END







GO
GRANT EXECUTE ON  [dbo].[rptProductionSnapshotByManagerReport] TO [dbx_ExecuteReportProcs]
GO
