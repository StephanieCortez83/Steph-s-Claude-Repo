SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [dbo].[rpt_Operations_Summary_OPS_Mgmt_Edition]
   @ReportDate DATE,
   @AccountManager INT = -1
   --@MonthsBack int = 24			-- added 6/11/2018, dsexton (only takes effect if @AccountManager = -1)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @m_ReportDate DATE = @ReportDate;
    DECLARE @m_AccountManager INT = @AccountManager;
	DECLARE @m_StartDate DATE 
	
	IF @AccountManager = -1		-- added 6/11/2018, dsexton
		SET @m_StartDate = DATEADD(Month, -24, @m_ReportDate);		-- added 6/11/2018, dsexton (only takes effect if @AccountManager = -1)
	ELSE
		SET @m_StartDate = DATEADD(Day, -60, @m_ReportDate);

	if object_id('TempDB..#CAR_Sum', 'U') is not null drop table #CAR_Sum
	CREATE TABLE #CAR_Sum (Facility_ID int, SumX Decimal(12, 10))


	if object_id('TempDB..#VENDOR_GROUP', 'U') is not null drop table #VENDOR_GROUP

	select * 
	into #VENDOR_GROUP
	from
	(
	select 
	sa.service_agreement_id,
	sa.description, 
	LTRIM(RTRIM(COALESCE(STUFF((
					SELECT ',' + cpy.[NAME] 
					FROM [dbo].[SERVICE_AGREEMENT_SERVICE_LOCATION_ASSIGNMENT] sla WITH (NOLOCK)
          INNER JOIN [dbo].[SERVICE_LOCATION] sl WITH (NOLOCK) ON sl.SERVICE_LOCATION_ID = sla.SERVICE_LOCATION_ID
					INNER JOIN [dbo].[COMPANY] cpy WITH (NOLOCK) ON cpy.COMPANY_ID = sl.COMPANY_ID
					WHERE sla.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
						AND @m_ReportDate BETWEEN sla.EFFECTIVE_DATE AND sla.EXPIRATION_DATE
					ORDER BY cpy.[NAME]
					FOR XML PATH('')
					), 1, 1, ''), 'N/A'))) VENDOR_GROUP_NAME
	from 
	service_agreement sa WITH (NOLOCK)
	where @m_ReportDate BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
	)T1;



	if object_id('TempDB..#OpSummary', 'U') is not null drop table #OpSummary;
	CREATE TABLE #OpSummary
	(
		Service_Agreement_ID int,
		Service varchar(100),
		Organization varchar(300),
		Account varchar(300),
		ReceivedITD int,
		CompletedITD int,
		ReceivedToday int,
		CompletedToday int,
		ApprovedToday int,
		SentToday int,
		ReceivedMTD int,
		CompletedMTD int,
		Volume int,
		DocumentsToday int,
		LastDocumentRecd datetime,
		WIP int,
		WIP0_24 int,
		WIP24_48 int,
		WIP48_72 int,
		WIP72 int,
		Complete int,
		Complete0_24 int,
		Complete24_48 int,
		Complete48_72 int,
		Complete72 int,
		Pended int,
		Pended24 int,
		Pended24_48 int,
		Pended48h_30d int,
		Pended30_60 int,
		Pended60_90 int,
		Pended90 int,
		OldestDOS datetime,
		TotalMinutes  bigint,
		TotalCompleted_DOS30 int,
		TotalMinutes_CompleteToApproved30 int,
		TotalCompleted_Recd30 bigint,
		TotalMinutes_Recd30 bigint,
		TotalMinutes_RecdToSent30 bigint,
		--AccuracyRate decimal(9,4),
		AccuracyRate decimal(12,10),
		PERCENT_EXCEEDING_SLA decimal(15,14),
		TOTAL_EXCEEDING_SLA int,
		TOTAL_CHARTS int
	);


	IF @m_AccountManager = -1
	BEGIN
		-- too many rows (27 million) to use #ChartSubset when AcctMgr = -1

		INSERT INTO #CAR_Sum (Facility_ID, SumX)
		SELECT 
			car.Facility_ID,
			CASE 
				WHEN SUM(car.FA) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.oha) + SUM(car.oia) + SUM(car.opa) + SUM(car.DEMA) <> 0
					THEN (SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) + SUM(car.ohe) + SUM(car.oie) + SUM(car.ope) + SUM(car.DEME)) / CONVERT(DECIMAL(12, 4), (SUM(car.FA) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.oha) + SUM(car.oia) + SUM(car.opa) + SUM(car.DEMA)))
				ELSE 0
				END as Sumx
		FROM CHART_AUDIT_RESULT car WITH (NOLOCK)
		WHERE DATEADD(DAY, DATEDIFF(DAY, 0, car.APPROVED_DATE), 0) BETWEEN DATEADD(DAY, - 30, @m_ReportDate) AND @m_ReportDate
		GROUP BY car.Facility_ID;


		WITH ClockStarted AS 
		(
			SELECT 
				ChartID, 
				Sent, 
				LastImageReceived, 
				LastTransitionWIP,
				ClockStarted = CASE
					WHEN LastImageReceived > LastTransitionWIP
						AND Sent > LastImageReceived
					THEN LastImageReceived
					ELSE LastTransitionWIP
					END
				, chart_status_id
				, service_agreement_ID
				, sent_date
				, APPROVED_DATE
				, COMPLETION_DATE
				, DATE_RECEIVED
				, time_of_service
			FROM
			(
				SELECT 
					ChartID = c.CHART_ID,
					Sent = c.SENT_DATE,
					LastImageReceived = IsNull(t1.Clock_Started, c.Date_Received),
					LastTransitionWIP = ISNULL(t2.LastTransitionWIP, c.Date_Received)
					, chart_status_id
					, service_agreement_ID
					, sent_date
					, APPROVED_DATE
					, COMPLETION_DATE
					, DATE_RECEIVED
					, time_of_service
				FROM 
					CHART c WITH (NOLOCK)
					left join
					(
						Select chart_ID, Clock_Started = max(creation_date_time)
						From (
								SELECT c.chart_ID,	ii.creation_date_time
								FROM 
									RevCycleImages..Import_Image as ii WITH (NOLOCK)
									join Chart as c with (NOLOCK) on ii.chart_ID = c.chart_ID
										AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
																				-- including the date filter in each of these subqueries reduces duration by 40% even though LReads increase by 10%.
								WHERE c.chart_Status_ID = 5 and ii.CREATION_DATE_TIME <= c.sent_date

								UNION
								SELECT c.chart_ID,	ii.creation_date_time
								FROM 
									RevCycleImages..Import_Image as ii WITH (NOLOCK)
									join Chart as c with (NOLOCK) on ii.chart_ID = c.chart_ID
										AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
								WHERE c.chart_Status_ID = 4 and ii.CREATION_DATE_TIME <= c.approved_date

								UNION
								SELECT c.chart_ID,	ii.creation_date_time
								FROM 
									RevCycleImages..Import_Image as ii WITH (NOLOCK)
									join Chart as c with (NOLOCK) on ii.chart_ID = c.chart_ID
										AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
								WHERE c.chart_Status_ID in (3, 8) and ii.CREATION_DATE_TIME <= c.completion_date

								UNION
								SELECT c.chart_ID,	ii.creation_date_time
								FROM 
									RevCycleImages..Import_Image as ii WITH (NOLOCK)
									join Chart as c with (NOLOCK) on ii.chart_ID = c.chart_ID
										AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
								WHERE c.chart_Status_ID in (1, 2) and ii.CREATION_DATE_TIME <= c.date_received
							
							------  This query performs better when vwImportImage is broken out to UNIONS against the explicit databases
							
								UNION
								SELECT c.chart_ID,	ii.creation_date_time
								FROM 
									RevCycleImages_Archive..Import_Image as ii WITH (NOLOCK)
									join Chart as c with (NOLOCK) on ii.chart_ID = c.chart_ID
										AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
								WHERE c.chart_Status_ID = 5 and ii.CREATION_DATE_TIME <= c.sent_date

								UNION
								SELECT c.chart_ID,	ii.creation_date_time
								FROM 
									RevCycleImages_Archive..Import_Image as ii WITH (NOLOCK)
									join Chart as c with (NOLOCK) on ii.chart_ID = c.chart_ID
										AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
								WHERE c.chart_Status_ID = 4 and ii.CREATION_DATE_TIME <= c.approved_date

								UNION
								SELECT c.chart_ID,	ii.creation_date_time
								FROM 
									RevCycleImages_Archive..Import_Image as ii WITH (NOLOCK)
									join Chart as c with (NOLOCK) on ii.chart_ID = c.chart_ID
										AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
								WHERE c.chart_Status_ID in (3, 8) and ii.CREATION_DATE_TIME <= c.completion_date

								UNION
								SELECT c.chart_ID,	ii.creation_date_time
								FROM 
									RevCycleImages_Archive..Import_Image as ii WITH (NOLOCK)
									join Chart as c with (NOLOCK) on ii.chart_ID = c.chart_ID
										AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
								WHERE c.chart_Status_ID in (1, 2) and ii.CREATION_DATE_TIME <= c.date_received
							) as x 
						Group By chart_ID
					) as t1 on c.chart_ID = t1.chart_ID

					left join
					(
						Select chart_ID, LastTransitionWIP = max(Completion_Date)
						From
							(
								SELECT cs.chart_ID, ln.COMPLETION_DATE
								FROM 
									LOG_NOTE ln WITH (NOLOCK)
									join Chart as cs with (NOLOCK) on ln.chart_ID = cs.chart_ID
										AND cs.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
								WHERE ln.CATEGORY_ID = 5

								UNION
								SELECT t.Chart_ID, t.COMPLETION_DATE
								FROM 
									Log_Note as ln2 WITH (NOLOCK)
									join
									(	-- Reduces logical reads 90% on LOG_NOTE by using a subquery here without criteria on SUMMARY, putting that criteria in the outer query instead.
										Select ln.log_note_ID, cs.chart_ID, ln.Completion_Date
										From
											LOG_NOTE ln WITH (NOLOCK)
											join Chart as cs with (NOLOCK) on ln.chart_ID = cs.chart_ID
												AND cs.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
										Where ln.CATEGORY_ID = 8
									) as t on ln2.log_note_ID = t.log_Note_ID
								WHERE ln2.SUMMARY LIKE 'Chart status changed to Work in Progress%'
							) as x
						Group By Chart_ID
					) as t2 on c.Chart_ID = t2.Chart_ID
				WHERE c.CHART_STATUS_ID IN (1,2,3,4,5,8)
					AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
			) as z
			)

		INSERT INTO #OpSummary
		SELECT 
			sa.service_agreement_ID,

			Service = CASE 
				WHEN sa.[RCP_BILLING_IND] = 1 
					THEN 'Billing'
				WHEN sa.SERVICE_MODEL_CD = 'ASP'
					THEN 'Software as a Service (SaaS)'
                when vg.VENDOR_GROUP_NAME = 'T-System, Inc.'
			  	THEN 'Full Service - RevCycle+'
					Else 'Full Service - Vendor'
				END ,
			
			cpy.[NAME] Organization,
			sa.DESCRIPTION Account,
			x.ReceivedITD,
			x.CompletedITD,
			x.ReceivedToday,
			x.CompletedToday,
			x.ApprovedToday,
			x.SentToday,
			x.ReceivedMTD,
			x.CompletedMTD,
			sa.ANNUAL_VOLUME Volume,

			DocumentsToday = cast(null as int),			-- Initially insert as NULL.  Update #OpSummary in final step to improve performance.
			LastDocumentRecd = cast(null as datetime),	-- Initially insert as NULL.  Update #OpSummary in final step to improve performance.

			x.WIP,
			x.WIP0_24,
			x.WIP24_48,
			x.WIP48_72,
			x.WIP72,
			x.Complete,
			x.Complete0_24,
		    x.Complete24_48,
		    x.Complete48_72,
		    x.Complete72,
			x.Pended,
			x.Pended24,
			x.Pended24_48,
			x.Pended48h_30d,
			x.Pended30_60,
			x.Pended60_90,
			x.Pended90,
			x.OldestDOS,
			x.TotalMinutes,
			x.TotalCompleted_DOS30,
			x.TotalMinutes_CompleteToApproved30,
			x.TotalCompleted_Recd30,
			x.TotalMinutes_Recd30,
			x.TotalMinutes_RecdToSent30,
			AccuracyRate = IsNull((
				Select Sumx
				From #CAR_Sum as car
				Where (car.FACILITY_ID = sa.FACILITY_ID)
				), cast(0 as decimal(12,4))),
			T3.TOTAL_EXCEEDING_SLA / (T3.TOTAL_CHARTS * 1.0) PERCENT_EXCEEDING_SLA ,
			T3.TOTAL_EXCEEDING_SLA,
			T3.TOTAL_CHARTS
		FROM 
			SERVICE_AGREEMENT sa WITH (NOLOCK)
			--INNER JOIN 
				Left join	--optional, but helps performance (duration reduced by 50%, CPU reduced by 30%)
			COMPANY cpy WITH (NOLOCK) on cpy.COMPANY_ID = sa.COMPANY_ID 
			--INNER JOIN
				left join	-- changing to Left Join for #Vendor_Group is critical to good performance.
			#VENDOR_GROUP vg on vg.service_agreement_id = sa.service_agreement_id
			--INNER JOIN
				left join	--optional, but helps performance (duration reduced by 50%, CPU reduced by 30%)
			(
				SELECT 
					c.SERVICE_AGREEMENT_ID,
					count(*) ReceivedITD,
					sum(CASE 
							WHEN c.CHART_STATUS_ID IN (3,4,5,8)
								THEN 1
							ELSE 0
							END) CompletedITD,
					SUM(CASE 
							WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.DATE_RECEIVED), 0) BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, @m_ReportDate), 0) AND @m_ReportDate
								THEN 1
							ELSE 0
							END) ReceivedMTD,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID IN (3,4,5,8) AND DATEADD(DAY, DATEDIFF(DAY, 0, c.COMPLETION_DATE), 0) BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, @m_ReportDate), 0) AND @m_ReportDate
								THEN 1
							ELSE 0
							END) CompletedMTD,
					sum(CASE 
							WHEN dateadd(dd, datediff(dd, 0, c.DATE_RECEIVED), 0) = @m_ReportDate
								THEN 1
							ELSE 0
							END) ReceivedToday,
					sum(CASE 
							WHEN dateadd(dd, datediff(dd, 0, c.COMPLETION_DATE), 0) = @m_ReportDate
								THEN 1
							ELSE 0
							END) CompletedToday,
					sum(CASE 
							WHEN dateadd(dd, datediff(dd, 0, c.APPROVED_DATE), 0) = @m_ReportDate
								THEN 1
							ELSE 0
							END) ApprovedToday,
					sum(CASE 
							WHEN dateadd(dd, datediff(dd, 0, c.SENT_DATE), 0) = @m_ReportDate
								THEN 1
							ELSE 0
							END) SentToday,
					sum(CASE 
							WHEN c.chart_status_id = 1
								THEN 1
							ELSE 0
							END) WIP,
                    SUM(CASE 
							WHEN c.CHART_STATUS_ID = 1
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, c.ClockStarted, @m_ReportDate) < 24
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) WIP0_24,
					sum(CASE 
							WHEN c.chart_status_id = 1
								THEN (
										CASE 
											WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) <= - 24
												THEN (
														CASE 
															WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) > - 48
																THEN 1
															ELSE 0
															END
														)
											ELSE 0
											END
										)
							ELSE 0
							END) WIP24_48,
					sum(CASE 
							WHEN c.chart_status_id = 1
								THEN (
										CASE 
											WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) <= - 48
												THEN (
														CASE 
															WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) > - 72
																THEN 1
															ELSE 0
															END
														)
											ELSE 0
											END
										)
							ELSE 0
							END) WIP48_72,
					sum(CASE 
							WHEN c.chart_status_id = 1
								THEN (
										CASE 
											WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) <= - 72
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) WIP72,

					sum(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN 1
							ELSE 0
							END) Complete,


					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, c.ClockStarted, @m_ReportDate) < 24
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Complete0_24,


					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, c.ClockStarted, @m_ReportDate) BETWEEN 24 AND 47
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Complete24_48,



					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, c.ClockStarted, @m_ReportDate) BETWEEN 48 AND 71
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Complete48_72,



					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, c.ClockStarted, @m_ReportDate) >= 72
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Complete72,

	
					sum(CASE 
							WHEN c.chart_status_id = 2
								THEN 1
							ELSE 0
							END) Pended,
					sum(CASE 
							WHEN c.chart_status_id = 2
								THEN (
										CASE 
											WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) > - 24
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Pended24,
					sum(CASE 
							WHEN c.chart_status_id = 2
								THEN (
										CASE 
											WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) <= - 24
												THEN (
														CASE 
															WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) > - 48
																THEN 1
															ELSE 0
															END
														)
											ELSE 0
											END
										)
							ELSE 0
							END) Pended24_48,
					sum(CASE 
							WHEN c.chart_status_id = 2
								THEN (
										CASE 
											WHEN DATEDIFF(hh, @m_ReportDate, c.ClockStarted) <= - 48
												THEN (
														CASE 
															WHEN DATEDIFF(dd, @m_ReportDate, c.ClockStarted) > - 30
																THEN 1
															ELSE 0
															END
														)
											ELSE 0
											END
										)
							ELSE 0
							END) Pended48h_30d,
					sum(CASE 
							WHEN c.chart_status_id = 2
								THEN (
										CASE 
											WHEN DATEDIFF(dd, @m_ReportDate, c.ClockStarted) <= - 30
												THEN (
														CASE 
															WHEN DATEDIFF(dd, @m_ReportDate, c.ClockStarted) > - 60
																THEN 1
															ELSE 0
															END
														)
											ELSE 0
											END
										)
							ELSE 0
							END) Pended30_60,
					sum(CASE 
							WHEN c.chart_status_id = 2
								THEN (
										CASE 
											WHEN DATEDIFF(dd, @m_ReportDate, c.ClockStarted) <= - 60
												THEN (
														CASE 
															WHEN DATEDIFF(dd, @m_ReportDate, c.ClockStarted) > - 90
																THEN 1
															ELSE 0
															END
														)
											ELSE 0
											END
										)
							ELSE 0
							END) Pended60_90,
					sum(CASE 
							WHEN c.chart_status_id = 2
								THEN (
										CASE 
											WHEN DATEDIFF(dd, @m_ReportDate, c.ClockStarted) <= - 90
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Pended90,
					min(CASE 
							WHEN c.CHART_STATUS_ID IN (1,2)
								THEN c.time_of_service
							ELSE @m_ReportDate
							END) OldestDOS,
					sum(convert(BIGINT, CASE 
								WHEN c.CHART_STATUS_ID IN (3,4,5,8)
									THEN datediff(mi, c.date_received, completion_date)
								ELSE 0
								END)) TotalMinutes,
					sum(convert(BIGINT, CASE 
								WHEN c.CHART_STATUS_ID IN (3,4,5,8)
									THEN (
											CASE 
												WHEN datediff(dd, c.time_of_service, @m_ReportDate) <= 30
													THEN 1
												ELSE 0
												END
											)
								ELSE 0
								END)) TotalCompleted_DOS30,
					sum(convert(BIGINT, CASE 
								WHEN c.CHART_STATUS_ID IN (3,4,5,8)
									THEN (
											CASE 
												WHEN datediff(dd, c.COMPLETION_DATE, @m_ReportDate) <= 30
													THEN datediff(mi, c.completion_date, c.approved_date)
												ELSE 0
												END
											)
								ELSE 0
								END)) TotalMinutes_CompleteToApproved30,
					sum(convert(BIGINT, CASE 
								WHEN c.CHART_STATUS_ID IN (3,4,5,8)
									THEN (
											CASE 
												WHEN datediff(dd, c.COMPLETION_DATE, @m_ReportDate) <= 30
													THEN 1
												ELSE 0
												END
											)
								ELSE 0
								END)) TotalCompleted_Recd30,
					sum(convert(BIGINT, CASE 
								WHEN c.CHART_STATUS_ID IN (3,4,5,8)
									THEN (
											CASE 
												WHEN datediff(dd, c.COMPLETION_DATE, @m_ReportDate) <= 30
													THEN datediff(mi, c.ClockStarted, c.completion_date)
												ELSE 0
												END
											)
								ELSE 0
								END)) TotalMinutes_Recd30,
					sum(convert(BIGINT, CASE 
								WHEN c.chart_status_id = 5
									THEN (
											CASE 
												WHEN datediff(dd, c.SENT_DATE, @m_ReportDate) <= 30
													THEN datediff(mi, c.ClockStarted, c.SENT_DATE)
												ELSE 0
												END
											)
								ELSE 0
								END)) TotalMinutes_RecdToSent30
				FROM ClockStarted as c 
				--WHERE c.CHART_STATUS_ID IN (1,2,3,4,5,8)	-- this criteria not needed here since it is used in CTE ClockStarted
				GROUP BY c.SERVICE_AGREEMENT_ID
			) x on x.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID

			left outer join 
			(	-- T3 starts here
				SELECT 
					T2.SERVICE_AGREEMENT_ID,
					COUNT(*) TOTAL_CHARTS,
					SUM(CASE WHEN T2.HOURS_ELAPSED >= (1 + T2.SLA_HOURS) 
								THEN 1
								ELSE 0
								END) TOTAL_EXCEEDING_SLA
				FROM 
				(	-- T2 starts here
					SELECT 
						*,
						CASE 
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (1,2) THEN T1.DATE_RECEIVED
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (3,4) THEN T1.CREATION_DATE_TIME
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD = 5
								THEN DATEADD(MINUTE, TURNAROUND_START_TIME_IN_MINUTES, CONVERT(DATETIME, CONVERT(VARCHAR, T1.CREATION_DATE_TIME, 112), 112))
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (6,7)
								THEN ISNULL((SELECT MAX(ln.COMPLETION_DATE)FROM LOG_NOTE ln WITH (NOLOCK)
											WHERE ln.CHART_ID = T1.CHART_ID
												AND ((ln.CATEGORY_ID = 5 AND ln.DETAIL LIKE 'Chart status moved to work in progress.  Previous status was Pending%' )
													OR (ln.CATEGORY_ID = 8 AND ( ln.SUMMARY LIKE 'Chart status changed to Work in Progress%' OR ln.DETAIL LIKE 'Chart status changed to Work in Progress%' ) ) ) ), T1.CREATION_DATE_TIME)
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (8,9)
								THEN (SELECT MAX(CREATION_DATE_TIME) FROM vwImportImage WITH (NOLOCK) WHERE CHART_ID = T1.CHART_ID)  
							END AS CLOCK_STARTED,

						CASE 
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (1,2)
								THEN DATEDIFF(MINUTE, T1.DATE_RECEIVED, ISNULL(CASE WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD = 1
													THEN T1.SENT_DATE ELSE T1.APPROVED_DATE END, GETDATE())) / 60.0                                    
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (3,4) THEN DATEDIFF(MINUTE, T1.CREATION_DATE_TIME, ISNULL(CASE 
												WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD = 3 THEN T1.SENT_DATE ELSE T1.APPROVED_DATE END, GETDATE())) / 60.0
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD = 5
								THEN DATEDIFF(MINUTE, DATEADD(mi, T1.TURNAROUND_START_TIME_IN_MINUTES, CONVERT(DATETIME, CONVERT(VARCHAR, T1.CREATION_DATE_TIME, 112), 112)), ISNULL(T1.APPROVED_DATE, GETDATE())) / 60.0
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN ( 6, 7)
								THEN DATEDIFF(MINUTE, ISNULL(( SELECT MAX(ln.COMPLETION_DATE) FROM LOG_NOTE ln WITH (NOLOCK) WHERE ln.CHART_ID = T1.CHART_ID AND ( (
															ln.CATEGORY_ID = 5 AND ln.DETAIL LIKE 'Chart status moved to work in progress.  Previous status was Pending%' ) OR ( ln.CATEGORY_ID = 8
															AND (ln.SUMMARY LIKE 'Chart status changed to Work in Progress%' OR ln.DETAIL LIKE 'Chart status changed to Work in Progress%' ) ) )
												), T1.CREATION_DATE_TIME), CASE WHEN TURNAROUND_HOURS_REPORTING_METHOD = 6 THEN ISNULL(T1.SENT_DATE, GETDATE())  ELSE ISNULL(T1.APPROVED_DATE, GETDATE()) END) / 60.0
							WHEN TURNAROUND_HOURS_REPORTING_METHOD IN (8,9)
								THEN DATEDIFF(MINUTE, ( SELECT MAX(CREATION_DATE_TIME) FROM vwImportImage WITH (NOLOCK) WHERE CHART_ID = T1.CHART_ID ), ISNULL(CASE 
												WHEN TURNAROUND_HOURS_REPORTING_METHOD = 8  THEN T1.SENT_DATE   ELSE T1.APPROVED_DATE  END, GETDATE())) / 60.0
							END AS HOURS_ELAPSED
					FROM 
					(	-- T1 starts here
						SELECT 
							sa.SERVICE_AGREEMENT_ID,
							cpy.COMPANY_ID,
							cpy.NAME ORGANIZATION,
							f.FACILITY_ID,
							f.NAME FACILITY,
							c.CHART_ID,
							sa.SLA_HOURS,
							c.CREATION_DATE_TIME,
							c.DATE_RECEIVED,
							( SELECT MAX(ln.CREATION_DATE_TIME) FROM LOG_NOTE ln WITH (NOLOCK) WHERE ln.CATEGORY_ID = 6 AND ln.CHART_ID = c.CHART_ID
							) AS LAST_PENDED,
							c.TIME_OF_SERVICE,
							c.COMPLETION_DATE,
							c.APPROVED_DATE,
							( SELECT MIN(COMPLETION_DATE) FROM [dbo].[LOG_NOTE] WITH (NOLOCK) WHERE CHART_ID = c.CHART_ID
							AND CATEGORY_ID = 4 ) AS SENT_DATE,
							sa.TURNAROUND_HOURS_REPORTING_METHOD,
							sa.TURNAROUND_START_TIME_IN_MINUTES
						FROM 
							[dbo].[FACILITY] f WITH (NOLOCK)
								INNER JOIN [dbo].[SERVICE_AGREEMENT] sa WITH (NOLOCK) ON f.FACILITY_ID = sa.FACILITY_ID
								INNER JOIN [dbo].[COMPANY] cpy WITH (NOLOCK) ON cpy.COMPANY_ID = sa.COMPANY_ID
								INNER JOIN [dbo].[CHART] c WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
									AND c.DATE_RECEIVED >= @m_StartDate		-- added 6/11/2018, dsexton
						WHERE   
							c.CHART_STATUS_ID NOT IN (2, 6, 7 )
							AND sa.TURNAROUND_HOURS_REPORTING_METHOD IS NOT NULL
							AND sa.TURNAROUND_HOURS_REPORTING_METHOD > 0
							AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) = case 
								when @m_ReportDate = DATEADD(day,DATEDIFF(day,0,GETDATE())-1,0)
									then  (DATEADD(day,DATEDIFF(day,0,GETDATE())-4,0) )
								else  DATEADD(day, -4, @m_ReportDate )
								end 
					) T1
				) T2
				GROUP BY T2.SERVICE_AGREEMENT_ID  
			) T3
				on sa.SERVICE_AGREEMENT_ID = T3.SERVICE_AGREEMENT_ID
		WHERE 
			sa.DEMO_TEST_SITE_IND <> 1
			AND sa.COMPANY_ID <> 1
			AND @m_ReportDate BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
		ORDER BY	-- keep the ORDER BY for this INSERT - it improves performance (not sure why)
			sa.SERVICE_MODEL_CD DESC,
			cpy.[NAME],
			sa.DESCRIPTION
		--option (maxdop 4)	-- maxdop not helpful for this query


		UPDATE t
		SET t.DocumentsToday = x.RecCount
		FROM
			#OpSummary as t
			JOIN 
			(
				SELECT t1.service_agreement_ID, RecCount = Count(*)
				FROM
					(
						SELECT ii.service_agreement_ID
						FROM 
							RevCycleImages..Import_Image ii WITH (NOLOCK)
							join #OpSummary as os on ii.SERVICE_AGREEMENT_ID = os.SERVICE_AGREEMENT_ID
						WHERE convert(VARCHAR, ii.CREATION_DATE_TIME, 112) = convert(VARCHAR, @m_ReportDate, 112)

						UNION ALL
						SELECT ii.service_agreement_ID
						FROM 
							RevCycleImages_Archive..Import_Image ii WITH (NOLOCK)
							join #OpSummary as os on ii.SERVICE_AGREEMENT_ID = os.SERVICE_AGREEMENT_ID
						WHERE convert(VARCHAR, ii.CREATION_DATE_TIME, 112) = convert(VARCHAR, @m_ReportDate, 112)
					) as t1
				GROUP BY t1.SERVICE_AGREEMENT_ID
			) as x ON t.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID

		UPDATE t
		SET t.LastDocumentRecd = y.MaxCreateDT
		FROM
			#OpSummary as t
			JOIN  	
			(
				SELECT t2.service_Agreement_ID, MaxCreateDT = MAX(t2.CREATION_DATE_TIME)
				FROM
					(
						SELECT ii.SERVICE_AGREEMENT_ID, ii.CREATION_DATE_TIME
						FROM 
							RevCycleImages..Import_Image ii WITH (NOLOCK)
							join #OpSummary as os on ii.SERVICE_AGREEMENT_ID = os.SERVICE_AGREEMENT_ID 

						UNION
						SELECT ii.SERVICE_AGREEMENT_ID, ii.CREATION_DATE_TIME
						FROM 
							RevCycleImages_Archive..Import_Image ii WITH (NOLOCK)
							join #OpSummary as os on ii.SERVICE_AGREEMENT_ID = os.SERVICE_AGREEMENT_ID 
					) as t2
				GROUP BY t2.SERVICE_AGREEMENT_ID
			) as y ON t.SERVICE_AGREEMENT_ID = y.SERVICE_AGREEMENT_ID

		-- if using a LEFT join (to improve performance) for the ClockStarted CTE, then you must delete certain rows from the final results which don't qualify based on Chart_Status_ID:
			DELETE FROM #OpSummary WHERE service_agreement_ID not in (select service_agreement_ID from chart with(nolock) WHERE CHART_STATUS_ID IN (1,2,3,4,5,8))

		SELECT 
			Service, Organization, Account, ReceivedITD, CompletedITD, ReceivedToday, CompletedToday, ApprovedToday, SentToday, ReceivedMTD,
			CompletedMTD, Volume, DocumentsToday = IsNull(DocumentsToday, 0), LastDocumentRecd, WIP, WIP0_24, WIP24_48, WIP48_72, WIP72, 
			Complete, Complete0_24, Complete24_48, Complete48_72, Complete72,
			Pended, Pended24, Pended24_48, Pended48h_30d,
			Pended30_60, Pended60_90, Pended90, OldestDOS, TotalMinutes, TotalCompleted_DOS30, TotalMinutes_CompleteToApproved30, 
			TotalCompleted_Recd30, TotalMinutes_Recd30, TotalMinutes_RecdToSent30, AccuracyRate, PERCENT_EXCEEDING_SLA,
			TOTAL_EXCEEDING_SLA, TOTAL_CHARTS
		FROM #OpSummary
		ORDER BY 
			Service,
			Organization,
			Account

	END
	ELSE	------------------------------------------------------- ELSE -----------------------------------------------------------------------------------------
	BEGIN

		if object_id('TempDB..#CHARTS', 'U') is not null drop table #CHARTS		-- This needs to be done here, before the CTE is defined below.

		if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset
		SELECT 
			chart_ID, facility_ID, CHART_STATUS_ID, SENT_DATE, APPROVED_DATE, COMPLETION_DATE, DATE_RECEIVED, 
			c.service_agreement_ID, Time_Of_Service, creation_date_time
		 INTO #ChartSubset
		FROM 
			CHART c WITH (NOLOCK)
			join [SERVICE_AGREEMENT_MANAGEMENT_TEAM] as sat with (NOLOCK) 
				on sat.service_Agreement_ID = c.service_Agreement_ID 
				and sat.user_Profile_ID = @m_AccountManager
		WHERE 
			CHART_STATUS_ID IN (1,2,3,4,5,8)
			AND c.DATE_RECEIVED >= @m_StartDate


		INSERT INTO #CAR_Sum (Facility_ID, SumX)
		SELECT 
			car.Facility_ID,
			CASE 
				WHEN SUM(car.FA) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.oha) + SUM(car.oia) + SUM(car.opa) + SUM(car.DEMA) <> 0
					THEN (SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) + SUM(car.ohe) + SUM(car.oie) + SUM(car.ope) + SUM(car.DEME)) / CONVERT(DECIMAL(12, 4), (SUM(car.FA) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.oha) + SUM(car.oia) + SUM(car.opa) + SUM(car.DEMA)))
				ELSE 0
				END as Sumx
		FROM CHART_AUDIT_RESULT car WITH (NOLOCK)
		WHERE 
			car.facility_ID in (select distinct facility_ID from #ChartSubset)
			AND DATEADD(DAY, DATEDIFF(DAY, 0, car.APPROVED_DATE), 0) BETWEEN DATEADD(DAY, - 30, @m_ReportDate) AND @m_ReportDate
		GROUP BY car.Facility_ID;


--------------------------------------------------------------
-- new section added 6/4/2018, dsexton
-- using #ImportImage and #ImportImageArchive reduces logical reads of the CHARTS cte by 50%  (1.1M vs 2.1M)
if object_id('TempDB..#ImportImage', 'U') is not null drop table #ImportImage
if object_id('TempDB..#ImportImageArchive', 'U') is not null drop table #ImportImageArchive

select ii.import_image_ID, c.chart_ID, creation_date_time = cast(null as datetime)
into #ImportImage
from RevCycleImages..Import_Image as ii
	join #ChartSubset as c on ii.chart_ID = c.chart_ID

select ii.import_image_ID, c.chart_ID, creation_date_time = cast(null as datetime)
into #ImportImageArchive
from RevCycleImages_Archive..Import_Image as ii
	join #ChartSubset as c on ii.chart_ID = c.chart_ID

update t
set t.creation_date_time = ii.creation_date_time 
from #ImportImage as t
	join RevCycleImages..Import_Image as ii on t.import_image_ID = ii.import_image_ID

update t
set t.creation_date_time = ii.creation_date_time 
from #ImportImageArchive as t
	join RevCycleImages_Archive..Import_Image as ii on t.import_image_ID = ii.import_image_ID


-----
if object_id('TempDB..#LogNote1', 'U') is not null drop table #LogNote1
if object_id('TempDB..#LogNote2', 'U') is not null drop table #LogNote2


select ln.log_note_ID, c.chart_ID, ln.completion_date		-- only 70K if grab completion_date on the INSERT vs 326K reads using UPDATE
into #LogNote1
from LOG_NOTE as ln
	join #ChartSubset as c on ln.chart_ID = c.chart_ID
WHERE ln.CATEGORY_ID = 5

select ln.log_note_ID, c.chart_ID, ln.completion_date		--, ln.Summary		--completion_date = cast(null as datetime)
into #LogNote2
from LOG_NOTE as ln
	join #ChartSubset as c on ln.chart_ID = c.chart_ID
WHERE ln.CATEGORY_ID = 8

delete from #LogNote2 where log_note_ID not in (select log_note_ID from LOG_NOTE WHERE category_ID = 8 and SUMMARY LIKE 'Chart status changed to Work in Progress%')
--------------------------------------------------------------

		;
		WITH CHARTS AS 
		(
			SELECT 
				c.chart_ID, 
				CLOCK_STARTED = IsNull(MAX(cs.CLOCK_STARTED), c.Date_Received)
			FROM 
				#ChartSubset as c
				left join
				(
					Select chart_ID, Clock_Started = max(creation_date_time)
					From 
						(
							SELECT c.chart_ID, ii.CREATION_DATE_TIME
							FROM 
								--RevCycleImages..Import_Image as ii WITH (NOLOCK)		
								#ImportImage as ii		-- using #ImportImage and #ImportImageArchive reduces logical reads of the CHARTS cte by 50%  (1.1M vs 2.1M)
								join #ChartSubset as c on ii.chart_ID = c.chart_ID
							WHERE 
								c.Chart_Status_ID = 5 
								and ii.CREATION_DATE_TIME <= c.SENT_DATE

							UNION
							SELECT c.chart_ID, ii.CREATION_DATE_TIME
							FROM 
								--RevCycleImages..Import_Image as ii WITH (NOLOCK)
								#ImportImage as ii
								join #ChartSubset as c on ii.chart_ID = c.chart_ID
							WHERE 
								c.Chart_Status_ID = 4 
								and ii.CREATION_DATE_TIME <= c.APPROVED_DATE

							UNION
							SELECT c.chart_ID, ii.CREATION_DATE_TIME
							FROM 
								--RevCycleImages..Import_Image as ii WITH (NOLOCK)
								#ImportImage as ii
								join #ChartSubset as c on ii.chart_ID = c.chart_ID
							WHERE 
								c.Chart_Status_ID IN (3, 8) 
								and ii.CREATION_DATE_TIME <= c.COMPLETION_DATE

							UNION
							SELECT c.chart_ID, ii.CREATION_DATE_TIME
							FROM 
								--RevCycleImages..Import_Image as ii WITH (NOLOCK)
								#ImportImage as ii
								join #ChartSubset as c on ii.chart_ID = c.chart_ID
							WHERE 
								c.Chart_Status_ID IN (1, 2) 
								and ii.CREATION_DATE_TIME <= c.DATE_RECEIVED

						----

							UNION
							SELECT c.chart_ID, ii.CREATION_DATE_TIME
							FROM 
								--RevCycleImages_Archive..Import_Image as ii WITH (NOLOCK)
								#ImportImageArchive as ii
								join #ChartSubset as c on ii.chart_ID = c.chart_ID
							WHERE 
								c.Chart_Status_ID = 5 
								and ii.CREATION_DATE_TIME <= c.SENT_DATE

							UNION
							SELECT c.chart_ID, ii.CREATION_DATE_TIME
							FROM 
								--RevCycleImages_Archive..Import_Image as ii WITH (NOLOCK)
								#ImportImageArchive as ii
								join #ChartSubset as c on ii.chart_ID = c.chart_ID
							WHERE 
								c.Chart_Status_ID = 4 
								and ii.CREATION_DATE_TIME <= c.APPROVED_DATE

							UNION
							SELECT c.chart_ID, ii.CREATION_DATE_TIME
							FROM 
								--RevCycleImages_Archive..Import_Image as ii WITH (NOLOCK)
								#ImportImageArchive as ii
								join #ChartSubset as c on ii.chart_ID = c.chart_ID
							WHERE 
								c.Chart_Status_ID IN (3, 8) 
								and ii.CREATION_DATE_TIME <= c.COMPLETION_DATE

							UNION
							SELECT c.chart_ID, ii.CREATION_DATE_TIME
							FROM 
								--RevCycleImages_Archive..Import_Image as ii WITH (NOLOCK)
								#ImportImageArchive as ii
								join #ChartSubset as c on ii.chart_ID = c.chart_ID
							WHERE 
								c.Chart_Status_ID IN (1, 2) 
								and ii.CREATION_DATE_TIME <= c.DATE_RECEIVED

						-----

							UNION
							--SELECT c.chart_ID, Creation_Date_Time = ln.COMPLETION_DATE
							SELECT ln.chart_ID, Creation_Date_Time = ln.COMPLETION_DATE
							FROM 
								--LOG_NOTE as ln WITH (NOLOCK)
								#LogNote1 as ln
								--join #ChartSubset as c on ln.chart_ID = c.chart_ID
							--WHERE ln.CATEGORY_ID = 5


							UNION
							--SELECT t.Chart_ID, Creation_Date_Time = t.COMPLETION_DATE
							SELECT ln2.Chart_ID, Creation_Date_Time = ln2.COMPLETION_DATE
							FROM 
								--Log_Note as ln2 WITH (NOLOCK)
								#LogNote2 as ln2
								--join
								/*
								(	-- Reduces logical reads on LOG_NOTE by using a subquery here without criteria on SUMMARY, putting that criteria in the outer query instead.
									Select ln.log_note_ID, cs.chart_ID, ln.Completion_Date
									From
										LOG_NOTE ln WITH (NOLOCK)
										join #ChartSubset as cs with (NOLOCK) on ln.chart_ID = cs.chart_ID
									Where ln.CATEGORY_ID = 8
								) as t on ln2.log_note_ID = t.log_Note_ID
							WHERE ln2.SUMMARY LIKE 'Chart status changed to Work in Progress%'
							*/
						) as x
					Group By chart_ID
				) as cs on c.chart_ID = cs.chart_ID
			GROUP BY c.chart_ID, c.date_received
		)


		SELECT * INTO #CHARTS FROM CHARTS WITH (NOLOCK) ORDER BY chart_ID;

		INSERT INTO #OpSummary
		SELECT 
			sa.service_agreement_ID,
			
			Service = CASE 
				WHEN sa.[RCP_BILLING_IND] = 1 
					THEN 'Billing'
				WHEN sa.SERVICE_MODEL_CD = 'ASP'
					THEN 'Software as a Service (SaaS)'
                when vg.VENDOR_GROUP_NAME = 'T-System, Inc.'
					THEN 'Full Service - RevCycle+'
					Else 'Full Service - Vendor'
				END ,

			cpy.[NAME] Organization,
			sa.[DESCRIPTION] Account,
			x.ReceivedITD,
			x.CompletedITD,
			x.ReceivedToday,
			x.CompletedToday,
			x.ApprovedToday,
			x.SentToday,
			x.ReceivedMTD,
			x.CompletedMTD,
			sa.ANNUAL_VOLUME Volume,

			DocumentsToday = cast(null as int),			-- Initially insert as NULL.  Update #OpSummary in final step to improve performance.
			LastDocumentRecd = cast(null as datetime),	-- Initially insert as NULL.  Update #OpSummary in final step to improve performance.

			x.WIP,
			x.WIP0_24,
			x.WIP24_48,
			x.WIP48_72,
			x.WIP72,
			x.Complete,
			x.Complete0_24,
		    x.Complete24_48,
		    x.Complete48_72,
		    x.Complete72,
			x.Pended,
			x.Pended24,
			x.Pended24_48,
			x.Pended48h_30d,
			x.Pended30_60,
			x.Pended60_90,
			x.Pended90,
			x.OldestDOS,
			x.TotalMinutes,
			x.TotalCompleted_DOS30,
			x.TotalMinutes_CompleteToApproved30,
			x.TotalCompleted_Recd30,
			x.TotalMinutes_Recd30,
			x.TotalMinutes_RecdToSent30,
			IsNull((
				SELECT Sumx
				from #CAR_Sum as car
				WHERE (car.FACILITY_ID = sa.FACILITY_ID)
				), cast(0 as decimal(12,4))) AS AccuracyRate ,
			T3.TOTAL_EXCEEDING_SLA / (T3.TOTAL_CHARTS * 1.0) PERCENT_EXCEEDING_SLA,
			T3.TOTAL_EXCEEDING_SLA,
			T3.TOTAL_CHARTS
		FROM 
			SERVICE_AGREEMENT sa WITH (NOLOCK)
			INNER JOIN 
			COMPANY cpy WITH (NOLOCK) on cpy.COMPANY_ID = sa.COMPANY_ID 
			--INNER JOIN
				left join	-- changing to Left Join for #Vendor_Group is critical to good performance when @AcctMgr = -1, but doesn't seem necessary here.  Even so, should probably use Left join here just in case, and to be consistent.
			#VENDOR_GROUP vg on vg.service_agreement_id = sa.service_agreement_id
			INNER JOIN
			(
				SELECT 
					c.SERVICE_AGREEMENT_ID,
					COUNT(*) ReceivedITD,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID IN (3,4,5,8)
								THEN 1
							ELSE 0
							END) CompletedITD,
					SUM(CASE 
							WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.DATE_RECEIVED), 0) BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, @m_ReportDate), 0) AND @m_ReportDate
								THEN 1
							ELSE 0
							END) ReceivedMTD,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID IN (3,4,5,8) AND DATEADD(DAY, DATEDIFF(DAY, 0, c.COMPLETION_DATE), 0) BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, @m_ReportDate), 0) AND @m_ReportDate
								THEN 1
							ELSE 0
							END) CompletedMTD,
					SUM(CASE 
							WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.DATE_RECEIVED), 0) = @m_ReportDate
								THEN 1
							ELSE 0
							END) ReceivedToday,
					SUM(CASE 
							WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.COMPLETION_DATE), 0) = @m_ReportDate
								THEN 1
							ELSE 0
							END) CompletedToday,
					SUM(CASE 
							WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.APPROVED_DATE), 0) = @m_ReportDate
								THEN 1
							ELSE 0
							END) ApprovedToday,
					SUM(CASE 
							WHEN DATEADD(DAY, DATEDIFF(DAY, 0, c.SENT_DATE), 0) = @m_ReportDate
								THEN 1
							ELSE 0
							END) SentToday,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 1
								THEN 1
							ELSE 0
							END) WIP,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 1
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) < 24
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) WIP0_24,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 1
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) BETWEEN 24 AND 47
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) WIP24_48,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 1
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) BETWEEN 48 AND 71
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) WIP48_72,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 1
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) >= 72
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) WIP72,



					sum(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN 1
							ELSE 0
							END) Complete,


					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) < 24
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Complete0_24,


					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) BETWEEN 24 AND 47
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Complete24_48,



					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) BETWEEN 48 AND 71
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Complete48_72,



					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 3
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) >= 72
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Complete72,



					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 2
								THEN 1
							ELSE 0
							END) Pended,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 2
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) < 24
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Pended24,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 2
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) BETWEEN 24 AND 47
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Pended24_48,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 2
								THEN (
										CASE 
											WHEN DATEDIFF(HOUR, cs.CLOCK_STARTED, @m_ReportDate) >= 48
												THEN CASE 
														WHEN DATEDIFF(DAY, cs.CLOCK_STARTED, @m_ReportDate) < 30
															THEN 1
														ELSE 0
														END
											ELSE 0
											END
										)
							ELSE 0
							END) Pended48h_30d,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 2
								THEN (
										CASE 
											WHEN DATEDIFF(DAY, cs.CLOCK_STARTED, @m_ReportDate) BETWEEN 30 AND 59
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Pended30_60,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 2
								THEN (
										CASE 
											WHEN DATEDIFF(DAY, cs.CLOCK_STARTED, @m_ReportDate) BETWEEN 60 AND 89
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Pended60_90,
					SUM(CASE 
							WHEN c.CHART_STATUS_ID = 2
								THEN (
										CASE 
											WHEN DATEDIFF(DAY, cs.CLOCK_STARTED, @m_ReportDate) >= 90
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) Pended90,
					min(CASE 
							WHEN c.CHART_STATUS_ID IN (1,2)
								THEN c.TIME_OF_SERVICE
							ELSE @m_ReportDate
							END) OldestDOS,
					SUM(CONVERT(BIGINT, CASE 
							WHEN c.CHART_STATUS_ID IN (3,4,5,8)
								THEN DATEDIFF(MINUTE, c.DATE_RECEIVED, c.COMPLETION_DATE)
							ELSE 0
							END)) TotalMinutes,
					SUM(CASE
							WHEN c.CHART_STATUS_ID IN (3,4,5,8)
								THEN (
										CASE 
											WHEN DATEDIFF(DAY, c.TIME_OF_SERVICE, @m_ReportDate) <= 30
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END) TotalCompleted_DOS30,
					SUM(CONVERT(BIGINT, CASE 
							WHEN c.CHART_STATUS_ID IN (3,4,5,8)
								THEN (
										CASE 
											WHEN DATEDIFF(DAY, c.COMPLETION_DATE, @m_ReportDate) <= 30
												THEN DATEDIFF(MINUTE, c.COMPLETION_DATE, c.APPROVED_DATE)
											ELSE 0
											END
										)
							ELSE 0
							END)) TotalMinutes_CompleteToApproved30,
					SUM(CONVERT(BIGINT, CASE 
							WHEN c.CHART_STATUS_ID IN (3,4,5,8)
								THEN (
										CASE 
											WHEN DATEDIFF(DAY, c.COMPLETION_DATE, @m_ReportDate) <= 30
												THEN 1
											ELSE 0
											END
										)
							ELSE 0
							END)) TotalCompleted_Recd30,
					SUM(CONVERT(BIGINT, CASE 
							WHEN c.CHART_STATUS_ID IN (3,4,5,8)
								THEN (
										CASE 
											WHEN DATEDIFF(DAY, c.COMPLETION_DATE, @m_ReportDate) <= 30
												THEN DATEDIFF(MINUTE, cs.CLOCK_STARTED, c.COMPLETION_DATE)
											ELSE 0
											END
										)
							ELSE 0
							END)) TotalMinutes_Recd30,
					SUM(CONVERT(BIGINT, CASE 
							WHEN c.CHART_STATUS_ID = 5
								THEN (
										CASE 
											WHEN DATEDIFF(DAY, c.SENT_DATE, @m_ReportDate) <= 30
												THEN DATEDIFF(MINUTE, cs.CLOCK_STARTED, c.SENT_DATE)
											ELSE 0
											END
										)
							ELSE 0
							END)) TotalMinutes_RecdToSent30
				FROM 
					#ChartSubset as c
					INNER JOIN #CHARTS as cs on cs.chart_ID = c.chart_ID
				GROUP BY c.SERVICE_AGREEMENT_ID
			) x ON x.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID

			left outer join 
			(	-- T3 starts
				SELECT 
					T2.SERVICE_AGREEMENT_ID,
					COUNT(*) TOTAL_CHARTS,
					SUM(CASE WHEN T2.HOURS_ELAPSED >= (1 + T2.SLA_HOURS) 
							 THEN 1
							 ELSE 0
							 END) TOTAL_EXCEEDING_SLA
				FROM 
				(	-- T2 starts
					SELECT 
						*,
						CASE 
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (1,2) THEN T1.DATE_RECEIVED
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (3,4) THEN T1.CREATION_DATE_TIME
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD = 5
								THEN DATEADD(MINUTE, TURNAROUND_START_TIME_IN_MINUTES, CONVERT(DATETIME, CONVERT(VARCHAR, T1.CREATION_DATE_TIME, 112), 112))
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (6,7)
								THEN ISNULL((SELECT MAX(ln.COMPLETION_DATE)FROM LOG_NOTE ln WITH (NOLOCK)
											WHERE ln.CHART_ID = T1.CHART_ID
												AND ((ln.CATEGORY_ID = 5 AND ln.DETAIL LIKE 'Chart status moved to work in progress.  Previous status was Pending%' )
													OR (ln.CATEGORY_ID = 8 AND ( ln.SUMMARY LIKE 'Chart status changed to Work in Progress%' OR ln.DETAIL LIKE 'Chart status changed to Work in Progress%' ) ) ) ), T1.CREATION_DATE_TIME)
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (8,9)
								THEN ( SELECT MAX(CREATION_DATE_TIME) FROM vwImportImage WITH (NOLOCK) WHERE CHART_ID = T1.CHART_ID
										)  END AS CLOCK_STARTED,

						CASE 
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (1,2)
								THEN DATEDIFF(MINUTE, T1.DATE_RECEIVED, ISNULL(CASE WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD = 1
													THEN T1.SENT_DATE ELSE T1.APPROVED_DATE END, GETDATE())) / 60.0                                    
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN (3,4) THEN DATEDIFF(MINUTE, T1.CREATION_DATE_TIME, ISNULL(CASE 
												WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD = 3 THEN T1.SENT_DATE ELSE T1.APPROVED_DATE END, GETDATE())) / 60.0
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD = 5
								THEN DATEDIFF(MINUTE, DATEADD(mi, T1.TURNAROUND_START_TIME_IN_MINUTES, CONVERT(DATETIME, CONVERT(VARCHAR, T1.CREATION_DATE_TIME, 112), 112)), ISNULL(T1.APPROVED_DATE, GETDATE())) / 60.0
							WHEN T1.TURNAROUND_HOURS_REPORTING_METHOD IN ( 6, 7)
								THEN DATEDIFF(MINUTE, ISNULL(( SELECT MAX(ln.COMPLETION_DATE) FROM LOG_NOTE ln WITH (NOLOCK) WHERE ln.CHART_ID = T1.CHART_ID AND ( (
															ln.CATEGORY_ID = 5 AND ln.DETAIL LIKE 'Chart status moved to work in progress.  Previous status was Pending%' ) OR ( ln.CATEGORY_ID = 8
															AND (ln.SUMMARY LIKE 'Chart status changed to Work in Progress%' OR ln.DETAIL LIKE 'Chart status changed to Work in Progress%' ) ) )
												), T1.CREATION_DATE_TIME), CASE WHEN TURNAROUND_HOURS_REPORTING_METHOD = 6 THEN ISNULL(T1.SENT_DATE, GETDATE())  ELSE ISNULL(T1.APPROVED_DATE, GETDATE()) END) / 60.0
							WHEN TURNAROUND_HOURS_REPORTING_METHOD IN (8,9)
								THEN DATEDIFF(MINUTE, ( SELECT MAX(CREATION_DATE_TIME) FROM vwImportImage WITH (NOLOCK) WHERE CHART_ID = T1.CHART_ID ), ISNULL(CASE 
												WHEN TURNAROUND_HOURS_REPORTING_METHOD = 8  THEN T1.SENT_DATE   ELSE T1.APPROVED_DATE  END, GETDATE())) / 60.0
							END AS HOURS_ELAPSED
					FROM 
					(	-- T1 starts
						 SELECT 
							sa.SERVICE_AGREEMENT_ID,
							cpy.COMPANY_ID,
							cpy.NAME ORGANIZATION,
							f.FACILITY_ID,
							f.NAME FACILITY,
							c.CHART_ID,
							sa.SLA_HOURS,
							c.CREATION_DATE_TIME,
							c.DATE_RECEIVED,
							( SELECT MAX(ln.CREATION_DATE_TIME) FROM LOG_NOTE ln WITH (NOLOCK) WHERE ln.CATEGORY_ID = 6 AND ln.CHART_ID = c.CHART_ID
							) AS LAST_PENDED,
							c.TIME_OF_SERVICE,
							c.COMPLETION_DATE,
							c.APPROVED_DATE,
							( SELECT MIN(COMPLETION_DATE) FROM [dbo].[LOG_NOTE] WITH (NOLOCK) WHERE CHART_ID = c.CHART_ID
							AND CATEGORY_ID = 4 ) AS SENT_DATE,
							sa.TURNAROUND_HOURS_REPORTING_METHOD,
							sa.TURNAROUND_START_TIME_IN_MINUTES
						FROM 
							[dbo].[FACILITY] f WITH (NOLOCK)
							INNER JOIN [dbo].[SERVICE_AGREEMENT] sa WITH (NOLOCK) ON f.FACILITY_ID = sa.FACILITY_ID
							INNER JOIN [dbo].[COMPANY] cpy WITH (NOLOCK) ON cpy.COMPANY_ID = sa.COMPANY_ID
							INNER JOIN #ChartSubset as c WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
						WHERE   
							c.CHART_STATUS_ID NOT IN (2, 6, 7 )
							AND sa.TURNAROUND_HOURS_REPORTING_METHOD IS NOT NULL
							AND sa.TURNAROUND_HOURS_REPORTING_METHOD > 0
							AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) = case when @m_ReportDate = DATEADD(day,DATEDIFF(day,0,GETDATE())-1,0)
								then  (DATEADD(day,DATEDIFF(day,0,GETDATE())-4,0) )
								else  DATEADD(day, -4, @m_ReportDate )
								end 
					) T1
				) T2
				GROUP BY T2.SERVICE_AGREEMENT_ID  
			) T3 on sa.SERVICE_AGREEMENT_ID = T3.SERVICE_AGREEMENT_ID

		WHERE 
			sa.DEMO_TEST_SITE_IND <> 1
			AND sa.COMPANY_ID <> 1
			AND @m_ReportDate BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
		ORDER BY 
			sa.SERVICE_MODEL_CD DESC,
			cpy.[NAME],
			sa.DESCRIPTION


		UPDATE t
		SET t.DocumentsToday = x.RecCount
		FROM
			#OpSummary as t
			JOIN 
			(
				SELECT t1.service_agreement_ID, RecCount = Count(*)
				FROM
					(
						SELECT ii.service_agreement_ID
						FROM 
							RevCycleImages..Import_Image ii WITH (NOLOCK)
							join #OpSummary as os on ii.SERVICE_AGREEMENT_ID = os.SERVICE_AGREEMENT_ID
						WHERE DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) = @m_ReportDate

						UNION ALL
						SELECT ii.service_agreement_ID
						FROM 
							RevCycleImages_Archive..Import_Image ii WITH (NOLOCK)
							join #OpSummary as os on ii.SERVICE_AGREEMENT_ID = os.SERVICE_AGREEMENT_ID
						WHERE DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) = @m_ReportDate
					) as t1
				GROUP BY t1.SERVICE_AGREEMENT_ID
			) as x ON t.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID

		UPDATE t
		SET t.LastDocumentRecd = y.MaxCreateDT
		FROM
			#OpSummary as t
			JOIN  	
			(
				SELECT t2.service_Agreement_ID, MaxCreateDT = MAX(t2.CREATION_DATE_TIME)
				FROM
					(
						SELECT ii.SERVICE_AGREEMENT_ID, ii.CREATION_DATE_TIME
						FROM 
							RevCycleImages..Import_Image ii WITH (NOLOCK)
							join #OpSummary as os on ii.SERVICE_AGREEMENT_ID = os.SERVICE_AGREEMENT_ID 
						WHERE DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) <= @m_ReportDate

						UNION
						SELECT ii.SERVICE_AGREEMENT_ID, ii.CREATION_DATE_TIME
						FROM 
							RevCycleImages_Archive..Import_Image ii WITH (NOLOCK)
							join #OpSummary as os on ii.SERVICE_AGREEMENT_ID = os.SERVICE_AGREEMENT_ID 
						WHERE DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) <= @m_ReportDate
					) as t2
				GROUP BY t2.SERVICE_AGREEMENT_ID
			) as y ON t.SERVICE_AGREEMENT_ID = y.SERVICE_AGREEMENT_ID

		SELECT 
			Service, Organization, Account, ReceivedITD, CompletedITD, ReceivedToday, CompletedToday, ApprovedToday, SentToday, ReceivedMTD,
			CompletedMTD, Volume, DocumentsToday = IsNull(DocumentsToday, 0), LastDocumentRecd, WIP, WIP0_24, WIP24_48, WIP48_72, WIP72, 
			Complete, Complete0_24, Complete24_48,Complete48_72,Complete72,
			Pended, Pended24, Pended24_48, Pended48h_30d,
			Pended30_60, Pended60_90, Pended90, OldestDOS, TotalMinutes, TotalCompleted_DOS30, TotalMinutes_CompleteToApproved30, 
			TotalCompleted_Recd30, TotalMinutes_Recd30, TotalMinutes_RecdToSent30, AccuracyRate, PERCENT_EXCEEDING_SLA,
			TOTAL_EXCEEDING_SLA, TOTAL_CHARTS
		FROM #OpSummary
		ORDER BY 
			Service,
			Organization,
			Account
	END
END




GO
GRANT EXECUTE ON  [dbo].[rpt_Operations_Summary_OPS_Mgmt_Edition] TO [dbx_ExecuteReportProcs]
GO
