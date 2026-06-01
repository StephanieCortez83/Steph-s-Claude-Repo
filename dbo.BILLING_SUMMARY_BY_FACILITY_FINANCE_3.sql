SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[BILLING_SUMMARY_BY_FACILITY_FINANCE_3]
	@billing_period int

WITH EXEC AS CALLER
AS

BEGIN
declare @billingperiod int
set @billingperiod = @billing_period

if object_id('TempDB..#PrelimResults', 'U') is not null DROP TABLE #PrelimResults;
select * 
into #PrelimResults		-- new temp table for tuning (to support breaking out the complex CASE statements of subquery X in order to eliminate blocking)
from
(
	select
		sa.company_id, 
		c.FACILITY_ID,
		c.SERVICE_AGREEMENT_ID,
		c.OBSERVATION_BILLING_METHOD_CD,

		(
			select pcl.physician_service_class_cd 
			from PATIENT_CLASS pcl 
			where pcl.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
		) as PHYSICIAN_SERVICE_CLASS_CD,

		case 
			when sa.RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
			when sa.RATE_METHOD_CD = 2 then c.SENT_DATE
			else bctl.END_DATE end RATE_DATE,
      	bc.CHART_ID,

		case 
			when sa.BILL_PRO_FEE_METHOD_CD = 1 and c.CHART_ID in 
				(
					select sp.chart_id 
					from SENT_PROCEDURE sp  WITH (NOLOCK)
					where 
						c.CHART_ID = sp.chart_id
						and   sp.class in ('PL', 'PP')
				) then 1 
			else 0 end BILL_PRO_FEE_IND,

		case 
			when sa.BILL_CODER_METHOD_CD = 1 and bc.CHART_ID in		
				(
					select ln.CHART_ID 
					from LOG_NOTE ln  WITH (NOLOCK)
      				where 
						bc.CHART_ID = ln.CHART_ID
      					and   ln.CATEGORY_ID = 2
				) then 
					(
						select ln.CREATING_USER_PROFILE_ID 
						from LOG_NOTE ln WITH (NOLOCK)
      					where 
							ln.CHART_ID = bc.CHART_ID
      						and   ln.CATEGORY_ID = 2
      						and   ln.LOG_NOTE_ID = 
								(
									select min(ln2.LOG_NOTE_ID) 
									from log_note ln2  WITH (NOLOCK)
      								where 
										ln2.CHART_ID = bc.CHART_ID
      									and   ln2.CATEGORY_ID = 2
								)
					)
				else c.COMPLETED_BY_USER_PROFILE_ID end CODED_BY_ID,

		case 
			when c.PATIENT_DISPOSITION_ID <> 5 then 1
      		when c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID =
				(
					SELECT sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID  
      				FROM  SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao 
      				WHERE 
						sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 1 
      					AND sao.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				) then 1		
				else 0 end ED_Ind,  

		case 
			when c.INITIAL_CHARGE_MASTER_DEPT_ID is null then 0 
			when c.INITIAL_CHARGE_MASTER_DEPT_ID = -1 then 0
			when c.INITIAL_CHARGE_MASTER_DEPT_ID = 0 then 0
			when c.INITIAL_CHARGE_MASTER_DEPT_ID is not null 
				and c.INITIAL_CHARGE_MASTER_DEPT_ID <> -1 
				and c.INITIAL_CHARGE_MASTER_DEPT_ID <> 0
				and 
				(
					select distinct 1 
					from charge_master_department cmd 
					where  
						cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
						and    c.TIME_OF_DIS not between cmd.EFFECTIVE_DATE and cmd.EXPIRATION_DATE
				) = 1 then 0
				else 1 end OBS_Ind,

		case 
			when 
			(
				select distinct 1 
				from USER_PROFILE up 
				where  
					up.USER_PROFILE_ID = c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID
					and    up.USER_CLASS_CD = 4
			) = 1 then 1 
				else 0 end OBS_Client_User,

		case 
			when c.observation_completed_by_user_profile_id = -1 
      			and sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 
      			and c.PATIENT_DISPOSITION_ID = 5 then 1 
				else 0 end OBS_CCS_User,
		
		case 
			when 
			(
				select distinct 'Y' 
				from LOG_NOTE ln WITH (NOLOCK) 
				where 
					ln.CHART_ID = c.CHART_ID 
					and ln.CATEGORY_ID = 6
			) = 'Y' then 'Y' 
			else 'N' end Pended,

		sa.SLA_RATE_METHOD_IND,

		-- new columns for tuning
		sa.TURNAROUND_HOURS_REPORTING_METHOD,	
		sa.TURNAROUND_START_TIME_IN_MINUTES,
    sa.SLA_HOURS MAX_SLA_HOURS,	
		c.creation_date_time,
		c.sent_date,
		c.approved_date,
		c.date_received

		-- new columns for tuning on 1/4/2016
		, c.facility_level_ID
		, c.OVERRIDE_FACILITY_LEVEL_ID
		, c.PATIENT_DISPOSITION_ID
		, c.FINANCIAL_CLASS_CD
		, c.Patient_Class_ID
		, c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID

		-- new columns for tuning on 1/5/2016  (these will be populated in subsequent steps)
		, SLA_Hours = cast(null as int)	
		, SLARate_Turnaround = cast(null as money)
		, SLARate_Else = cast(null as money)
		, MultiDept_Rate = cast(null as money)
		, SaaS_Obs_Only_Rate = cast(null as money)
		, CCS_Obs_Only_Rate = cast(null as money)
		, SaaS_Obs_With_CCS_ED_Rate = cast(null as money)
		, FS_With_Obs_Rate = cast(null as money)
		, SelfPay_Rate = cast(null as money)
		, EMIncrementRate = cast(null as money)
	from  
		billed_chart bc WITH (NOLOCK)
		, chart c WITH (NOLOCK)
		, billing_control bctl WITH (NOLOCK) 
		, service_agreement sa WITH (NOLOCK)
	where 
		bctl.BILLING_CONTROL_ID = bc.BILLING_CONTROL_ID
		and   bctl.BILLING_CONTROL_ID = @billingPeriod
		and   bc.TYPE_CD = 'B'
		and   c.CHART_ID = bc.CHART_ID
		and   sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		and   sa.ORGANIZATION_ID = 1
		and   sa.DEMO_TEST_SITE_IND <> 1
		and   sa.company_id not in (196, 134, 223, 19, 298) -- 03/19/2025 RAP-929 DAH - exclude MultiCare Health System,  04/23/25 RAP-1014 DAH exclude R1 Ascension,  05/21/25 RAP-1094 Exclude Tenet, Conifer
		

--		and sa.facility_id in ( 409,410, 1044, 876 ) -- testing only / remove line ******************

		--and c.approved_date > DateAdd(day, -30, bctl.Start_Date)		-- Do not use. Does not improve performance, and results are off by one row
) as t


if object_id('TempDB..#CompletionDates', 'U') is not null DROP TABLE #CompletionDates;
select *						-- performs better when broken out to two steps
 INTO #CompletionDates
from
	(
		select ln.chart_id, ln.completion_date, ln.category_id, 
			summary = left(ln.summary, 68), detail = left(ln.detail, 68)
		from 
			log_note as ln with(nolock)
				inner join 
			#PrelimResults as t 
					on t.chart_id = ln.chart_id and t.TURNAROUND_HOURS_REPORTING_METHOD in (6,7)
		where 
			ln.CATEGORY_ID = 8
			AND left(ln.SUMMARY,40) = 'Chart status changed to Work in Progress'

		UNION
		select ln.chart_id, ln.completion_date, ln.category_id, 
			summary = left(ln.summary, 68), detail = left(ln.detail, 68)
		from 
			log_note as ln with(nolock)
				inner join 
			#PrelimResults as t 
					on t.chart_id = ln.chart_id and t.TURNAROUND_HOURS_REPORTING_METHOD in (6,7)
		where
			ln.CATEGORY_ID = 8
			AND left(ln.DETAIL,40) = 'Chart status changed to Work in Progress'
	) as t


INSERT INTO #CompletionDates
select ln.chart_id, ln.completion_date, ln.category_id, 
	summary = left(ln.summary, 68), detail = left(ln.detail, 68)
from 
	log_note as ln with(nolock)
		inner join 
	#PrelimResults as t 
			on t.chart_id = ln.chart_id and t.TURNAROUND_HOURS_REPORTING_METHOD in (6,7)
where
	ln.CATEGORY_ID = 5
	AND ln.DETAIL LIKE 'Chart status moved to work in progress.  Previous status was Pending%'


update t
set SLA_Hours = case
	when t.TURNAROUND_HOURS_REPORTING_METHOD in (1) then datediff(minute, t.DATE_RECEIVED, t.SENT_DATE)/60
	when t.TURNAROUND_HOURS_REPORTING_METHOD in (2) then datediff(minute, t.DATE_RECEIVED, t.APPROVED_DATE)/60
	when t.TURNAROUND_HOURS_REPORTING_METHOD in (3) then datediff(minute, t.CREATION_DATE_TIME, t.SENT_DATE)/60
	when t.TURNAROUND_HOURS_REPORTING_METHOD in (4) then datediff(minute, t.CREATION_DATE_TIME, t.APPROVED_DATE)/60
	when t.TURNAROUND_HOURS_REPORTING_METHOD = 5 
		then datediff(minute, dateadd(minute, t.TURNAROUND_START_TIME_IN_MINUTES, convert(datetime, convert(varchar, t.CREATION_DATE_TIME, 112), 112)), t.APPROVED_DATE)/60
	when t.TURNAROUND_HOURS_REPORTING_METHOD IN (6,7)
		then DATEDIFF
			(
				MINUTE, COALESCE
				(
					(
						select MAX(COMPLETION_DATE)
						from #CompletionDates
						where CHART_ID = t.CHART_ID
					), 
					t.creation_date_time
				), case 
						when t.TURNAROUND_HOURS_REPORTING_METHOD = 6 then t.SENT_DATE
						else t.APPROVED_DATE
						end
			) / 60
	when t.TURNAROUND_HOURS_REPORTING_METHOD = 8
		THEN datediff(minute, 
				(SELECT MAX(ii.CREATION_DATE_TIME)
				FROM   vwImportImage ii WITH(NOLOCK)
				WHERE  ii.CHART_ID = t.CHART_ID)
      				, t.APPROVED_DATE)/60	
	when t.TURNAROUND_HOURS_REPORTING_METHOD = 9
		THEN datediff(minute, 
				(SELECT MAX(ii.CREATION_DATE_TIME)
				FROM   vwImportImage ii WITH(NOLOCK)
				WHERE  ii.CHART_ID = t.CHART_ID)
      				, t.APPROVED_DATE)/60																		        
	else 0 
	end
FROM #PrelimResults as t	


-------------------------------------------------------------------------------------------------------------------------------------------------
/*  1/5/2016 - significant improvement in performance comes by preprocessing values for the 8 columns listed below from subquery X.   
	-- Tuned performance stats (RCMSQL02\ACSDW01) = 27M reads; 140 secs (cold), 35 secs (warm)
	-- Original performance stats (RCMSQL02\ACSDW01) = 501M reads; 960 secs (cold), 785 secs (warm)

SLA_RATE
MultiDept_Rate,
SaaS_Obs_Only_Rate,           
CCS_Obs_Only_Rate,
SaaS_Obs_With_CCS_ED_Rate,
FS_With_Obs_Rate,    
SelfPay_Rate,
EMIncrementRate
*/											 

	if object_id('TempDB..#SLARate_TurnaroundRptMethod', 'U') is not null DROP TABLE #SLARate_TurnaroundRptMethod;
	select *
	 INTO #SLARate_TurnaroundRptMethod
	from
		(
			select 
				x.chart_ID,
				sla.SLA_DIFFERENTIAL_RATE 
			from 
				SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE as sla WITH (NOLOCK)
				join #PrelimResults as x
					ON sla.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
			where 
				convert(varchar, x.RATE_DATE, 112) >= sla.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sla.EXPIRATION_DATE
				and x.SLA_HOURS >= sla.SLA_DIFFERENTIAL_HOURS
				and sla.SLA_DIFFERENTIAL_HOURS = 
					(
						select max(sla2.SLA_DIFFERENTIAL_HOURS) 
						from SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE sla2 WITH (NOLOCK)
						where 
							sla2.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
							and convert(varchar, x.RATE_DATE, 112) >= sla2.EFFECTIVE_DATE 
							and convert(varchar, x.RATE_DATE, 112) <= sla2.EXPIRATION_DATE
							and sla2.SLA_DIFFERENTIAL_HOURS <= x.SLA_HOURS
					)
		) as t				

	UPDATE x
	SET x.SLARate_Turnaround = t.SLA_DIFFERENTIAL_RATE
	FROM 
		#PrelimResults as x
		join #SLARate_TurnaroundRptMethod as t 
			ON x.chart_ID = t.chart_ID


	if object_id('TempDB..#SLARate_ELSE', 'U') is not null DROP TABLE #SLARate_ELSE;
	select *
	 INTO #SLARate_ELSE
	from
		(
			select 
				x.chart_ID,
				sla.SLA_DIFFERENTIAL_RATE 
			from 
				SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE as sla WITH (NOLOCK)
				join #PrelimResults as x
					ON sla.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
			where 
				convert(varchar, x.RATE_DATE, 112) >= sla.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sla.EXPIRATION_DATE
				and x.SLA_HOURS >= sla.SLA_DIFFERENTIAL_HOURS
				and sla.SLA_DIFFERENTIAL_HOURS = 
					(
						select max(sla2.SLA_DIFFERENTIAL_HOURS) 
						from SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE sla2 WITH (NOLOCK)
						where 
							sla2.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
							and convert(varchar, x.RATE_DATE, 112) >= sla2.EFFECTIVE_DATE 
							and convert(varchar, x.RATE_DATE, 112) <= sla2.EXPIRATION_DATE
							and sla2.SLA_DIFFERENTIAL_HOURS <= x.SLA_HOURS
							and (
									x.Pended <> 'Y' 
									or x.Pended is null
								)
					) 
		) as t

	UPDATE x
	SET x.SLARate_Else = t.SLA_DIFFERENTIAL_RATE
	FROM 
		#PrelimResults as x
		join #SLARate_ELSE as t 
			ON x.chart_ID = t.chart_ID


	if object_id('TempDB..#MultiDeptRate', 'U') is not null DROP TABLE #MultiDeptRate;
	select *
	 INTO #MultiDeptRate
	from
		(
			select 
				x.chart_ID,
				sar.RATE 
			from 
				SERVICE_AGREEMENT_RATE as sar  WITH (NOLOCK)
				join #PrelimResults as x ON sar.service_agreement_id = x.service_agreement_id
			where 
    			convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'O'
				and sar.RATE_CLASS_CD = 'B'
				and 
					(
						select count(*) Tot
						from 
							(
								select distinct 
									sp.CHART_ID, 
									cm.CHARGE_MASTER_DEPT_ID
								from 
									SENT_PROCEDURE as sp WITH (NOLOCK) 
									join CHARGE_MASTER as cm WITH (NOLOCK)
										ON cm.CHARGE_MASTER_ID = sp.charge_master_id
								where  
									x.CHART_ID = sp.CHART_ID
									and 
										(
											SELECT COUNT(*) 
											FROM LOG_NOTE ln WITH (NOLOCK) 
											WHERE  
												ln.CHART_ID = sp.CHART_ID 
												AND ln.CATEGORY_ID = 26
										) = 0	        -- 26 = OBS Complete            
								group by sp.CHART_ID, cm.CHARGE_MASTER_DEPT_ID
							) as xx
					) > 1
		) as t

	UPDATE x
	SET x.MultiDept_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #MultiDeptRate as t 
			ON x.chart_ID = t.chart_ID


	if object_id('TempDB..#SaaSObsOnlyRate', 'U') is not null DROP TABLE #SaaSObsOnlyRate;
	select *
	 INTO #SaaSObsOnlyRate
	from
		(
			select 
				x.chart_ID,
				sar.RATE 
			from 
				SERVICE_AGREEMENT_RATE sar  WITH (NOLOCK)
				join #PrelimResults as x ON sar.service_agreement_id = x.service_agreement_id
				join SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE as sap  WITH (NOLOCK)
					ON x.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID				
			where 
    			convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = '8'
				and sar.RATE_CLASS_CD = 'B'
				and x.PATIENT_DISPOSITION_ID = 5  -- Observation
				and sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 2  -- Direct to Observation				
				and x.chart_id in 
					(
						select c.chart_id
						from  
							#PrelimResults as c
							join user_profile as up with (NOLOCK)
								ON up.user_profile_id = c.CODED_BY_ID
						where 
							c.PATIENT_DISPOSITION_ID = 5
							and up.user_class_cd = 4
							and (
							SELECT COUNT(*) 
							FROM LOG_NOTE ln2 WITH (NOLOCK) 
							where 
								ln2.CATEGORY_ID = 26   -- Observation Code Complete
								and ln2.chart_id = x.chart_id
							) > 0
													
					)
			UNION
			select 
				x.chart_ID,
				SumRate = sum(sar.RATE) 
			from 
				SERVICE_AGREEMENT_RATE sar  WITH (NOLOCK)
				join #PrelimResults as x ON sar.service_agreement_id = x.service_agreement_id
				join SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE as sap  WITH (NOLOCK)
					ON x.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID				
			where 
    			convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD in ('8')
				and sar.RATE_CLASS_CD = 'B'
				and x.PATIENT_DISPOSITION_ID = 5  -- Observation
				and sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 1  -- ED to Observation				
				and x.chart_id in 
					(
						select c.chart_id
						from  
							#PrelimResults as c
							join user_profile as up with (NOLOCK)
								ON up.user_profile_id = c.CODED_BY_ID
						where 
							c.PATIENT_DISPOSITION_ID = 5
							and up.user_class_cd = 4
							and (
							SELECT COUNT(*) 
							FROM LOG_NOTE ln2 WITH (NOLOCK) 
							where 
								ln2.CATEGORY_ID = 26   -- Observation Code Complete
								and ln2.chart_id = x.chart_id
							) > 0													
					)
				group by x.chart_ID	

		) as t

	UPDATE x
	SET x.SaaS_Obs_Only_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #SaaSObsOnlyRate as t 
			ON x.chart_ID = t.chart_ID


	if object_id('TempDB..#CCSObsOnlyRate', 'U') is not null DROP TABLE #CCSObsOnlyRate;
	select *
	 INTO #CCSObsOnlyRate
	from
		(				-- 95M reads
			select 
				x.chart_ID,
				sar.RATE 
			from 
				SERVICE_AGREEMENT_RATE as sar  WITH (NOLOCK)
				join #PrelimResults as x
					ON sar.service_agreement_id = x.service_agreement_id
				join SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE as sap  WITH (NOLOCK)
					ON x.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
			where 
				convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = '7'
				and sar.RATE_CLASS_CD = 'B'
				and x.PATIENT_DISPOSITION_ID = 5  -- Observation
				and sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 2  -- Direct to Observation
				and 
					(
						(
							(
								SELECT up.USER_CLASS_CD 
								from USER_PROFILE up  WITH (NOLOCK)
								where  up.USER_PROFILE_ID = 
									(
										SELECT ln2.COMPLETED_BY_USER_ID 
										from LOG_NOTE ln2 WITH (NOLOCK) 
										where ln2.LOG_NOTE_ID = 
											(
												SELECT MIN(ln3.LOG_NOTE_ID) 
												from LOG_NOTE ln3  WITH (NOLOCK)
												WHERE  
													ln3.CHART_ID = x.CHART_ID 
													AND ln3.CATEGORY_ID = 26
											)
									)
							) <> 4
						)  -- Not a client coder
						or 
						(
							SELECT COUNT(*) 
							FROM LOG_NOTE ln2 WITH (NOLOCK) 
							where 
								ln2.CATEGORY_ID = 26   -- Observation Code Complete
								and ln2.chart_id = x.chart_id
						) = 0
					)	-- No log note records					
		) as t

	UPDATE x
	SET x.CCS_Obs_Only_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #CCSObsOnlyRate as t 
			ON x.chart_ID = t.chart_ID


	if object_id('TempDB..#SaaSObsWithCCSEDRate', 'U') is not null DROP TABLE #SaaSObsWithCCSEDRate;
	select *
	 INTO #SaaSObsWithCCSEDRate
	from
		(
			select
				x.chart_ID,
				SumRate = sum(sar.RATE) 
			from 
				SERVICE_AGREEMENT_RATE as sar  WITH (NOLOCK)
				join #PrelimResults as x 
					ON sar.service_agreement_id = x.service_agreement_id 
				join SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE as sap WITH (NOLOCK)
					ON sap.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
					and x.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
			where 
				convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD IN ('C','8')
				and sar.RATE_CLASS_CD = 'B'
				and x.PATIENT_DISPOSITION_ID = 5   -- Observation
				and sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD <> 2   -- Other than Direct to Observation
				and 
					(
						SELECT up.USER_CLASS_CD 
						from USER_PROFILE up  WITH (NOLOCK)
						WHERE up.USER_PROFILE_ID = 
							(
								SELECT ln2.COMPLETED_BY_USER_ID 
								from LOG_NOTE ln2  WITH (NOLOCK) 
								where ln2.LOG_NOTE_ID = 
									(
										SELECT MIN(ln3.LOG_NOTE_ID) 
										from LOG_NOTE ln3  WITH (NOLOCK)
										WHERE  
											ln3.CHART_ID = x.CHART_ID 
											AND ln3.CATEGORY_ID = 2
									)
							)
					) <> 4		 -- Not a client coder	
			group by x.chart_ID							
		) as t

	UPDATE x
	SET x.SaaS_Obs_With_CCS_ED_Rate = t.SumRate
	FROM 
		#PrelimResults as x
		join #SaaSObsWithCCSEDRate as t 
			ON x.chart_ID = t.chart_ID


	if object_id('TempDB..#FSWithObsRate', 'U') is not null DROP TABLE #FSWithObsRate;
	select *
	 INTO #FSWithObsRate
	from
		(
			select 
				x.chart_ID,
				sar.RATE 
			from 
				SERVICE_AGREEMENT_RATE as sar WITH (NOLOCK)
				join SERVICE_AGREEMENT as sa WITH (NOLOCK)
					on sar.SERVICE_AGREEMENT_ID = sa.service_agreement_ID
				join #PrelimResults as x
					ON sar.service_agreement_id = x.service_agreement_id
				LEFT OUTER JOIN PATIENT_CLASS as pc 
					on x.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID 
			where 
				convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = '7'
				and sar.RATE_CLASS_CD = 'B'
				and x.PATIENT_DISPOSITION_ID = 5 
				AND sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1

			UNION
			select 
				x.chart_ID,
				sar.RATE 
			from 
				SERVICE_AGREEMENT_RATE as sar WITH (NOLOCK)
				join SERVICE_AGREEMENT as sa WITH (NOLOCK)
					on sar.SERVICE_AGREEMENT_ID = sa.service_agreement_ID
				join #PrelimResults as x
					ON sar.service_agreement_id = x.service_agreement_id
				LEFT OUTER JOIN PATIENT_CLASS as pc 
					on x.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID 
			where 
				convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = '7'
				and sar.RATE_CLASS_CD = 'B'
				and pc.PHYSICIAN_SERVICE_CLASS_CD = 5 
				AND sa.EVALUATE_PHYSICIAN_OBSERVATION = 1
		) as t

	UPDATE x
	SET x.FS_With_Obs_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #FSWithObsRate as t 
			ON x.chart_ID = t.chart_ID


	if object_id('TempDB..#SelfPayRate', 'U') is not null DROP TABLE #SelfPayRate;
	select *
		INTO #SelfPayRate
	from
		(
			select 
				x.chart_ID,
				sar.RATE 
			from 
				SERVICE_AGREEMENT_RATE as sar WITH (NOLOCK)
				join #PrelimResults as x 
					ON sar.service_agreement_id = x.service_agreement_id
				join FACILITY_FINANCIAL_CLASS as ffc WITH (NOLOCK)
					ON ffc.FINANCIAL_CLASS_CD = x.FINANCIAL_CLASS_CD
					AND x.service_agreement_id = ffc.SERVICE_AGREEMENT_ID
			where 
				convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = '5'
				and sar.RATE_CLASS_CD = 'B'
				and ffc.PAYOR_METHOD_CD = 4
		) as t

	UPDATE x
	SET x.SelfPay_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #SelfPayRate as t 
			ON x.chart_ID = t.chart_ID
	

	if object_id('TempDB..#EMIncrementRate', 'U') is not null DROP TABLE #EMIncrementRate;
	select *
	 INTO #EMIncrementRate
	from
		(
			select 
				x.chart_ID,
				sar.RATE 
			from  
				#PrelimResults as x
				join SERVICE_AGREEMENT_RATE as sar WITH (NOLOCK)
					on x.service_agreement_ID = sar.SERVICE_AGREEMENT_ID 
				join FACILITY_LEVEL as fl WITH (NOLOCK)
					on fl.FACILITY_LEVEL_ID = x.Facility_Level_ID
					and x.override_facility_level_ID = -1
			where 
				convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'E'
				and sar.RATE_CLASS_CD = 'B'
				and fl.LEVEL_NUMBER > 0  -- Billable

			UNION
			select 
				x.chart_ID,
				sar.RATE 
			from  
				#PrelimResults as x
				join SERVICE_AGREEMENT_RATE as sar WITH (NOLOCK)
					on x.service_agreement_ID = sar.SERVICE_AGREEMENT_ID 
				join FACILITY_LEVEL as fl WITH (NOLOCK)
					on fl.FACILITY_LEVEL_ID = x.override_Facility_Level_ID
					and x.override_facility_level_ID <> -1
			where 
				convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'E'
				and sar.RATE_CLASS_CD = 'B'
				and fl.LEVEL_NUMBER > 0  -- Billable
		) as t

	UPDATE x
	SET x.EMIncrementRate = t.rate
	FROM 
		#PrelimResults as x
		join #EMIncrementRate as t 
			ON x.chart_ID = t.chart_ID

-- End of performance improvements from 1/5/2016
--------------------------------------------------------------------------------------------------------------------------------------------------------


select
f.Organization,
f.Facility,
sum(f.TotCCSNonVendor) as TotCCSNonVendor,
sum(f.TotCCSVendor) as TotCCSVendor,
sum(f.[SaaS Count]) as [SaaS Count],
sum(f.[Total Count]) as [Total Count],
sum(f.TOTNonVenRev) as TOTNonVenRev ,
sum(f.TOTVenRev) as TOTVenRev,
sum(f.TOTSaaSRev) as TOTSaaSRev,
sum(f.[Total Billed]) as [Total Billed]
from (

select 
	(select name from company with (NOLOCK) where company_id = u.company_id) as Organization,
	u.Facility,
	u.FacilityName,
	u.TotCCSNonVendor as  TotCCSNonVendor,
	u.TotCCSVendor as TotCCSVendor,
    u.TotSaaS 'SaaS Count',
    u.TotCharts 'Total Count'	,
	round(u.TotCCSNonVendor  * u.CCSRate, 2) + round(u.TotCCSNonVendor * u.CCSObsOnlyRate, 2) + ROUND(u.TotCCSNonVendor * u.FS_With_Obs_Rate, 2) + round((u.TotProFee + TotCCSNonVendor ) * u.ProFeeRate, 2) + round(u.TotCCSNonVendor  * u.Saas_Obs_With_CCS_ED_Rate, 2) + round(u.TotEM * u.EMIncrementRate, 2) as TOTNonVenRev ,
	round(u.TotCCSVendor * u.CCSRate, 2) + round(u.TotCCSVendor * u.CCSObsOnlyRate, 2) + ROUND(u.TotCCSVendor * u.FS_With_Obs_Rate, 2) + round((u.TotProFee + u.TotCCSVendor) * u.ProFeeRate, 2) +round(u.TotCCSVendor * u.Saas_Obs_With_CCS_ED_Rate, 2)  as TOTVenRev ,
	round(u.TotSaaS * u.SaaSRate, 2) + round(u.TotSaaS * u.SaasObsOnlyRate, 2) as TOTSaaSRev,
    round((u.TotCCSNonVendor + u.TotCCSVendor) * u.CCSRate, 2) + ROUND((u.TotCCSNonVendor + u.TotCCSVendor) * u.FS_With_Obs_Rate, 2) + round((u.TotProFee + TotCCSNonVendor + u.TotCCSVendor) * u.ProFeeRate, 2) + round(u.TotSaaS * u.SaaSRate, 2) + round(u.TotSaaS * u.SaasObsOnlyRate, 2) +round((u.TotCCSNonVendor + u.TotCCSVendor) * u.Saas_Obs_With_CCS_ED_Rate, 2) + round((u.TotCCSNonVendor + u.TotCCSVendor) * u.CCSObsOnlyRate, 2)   + round(u.TotEM * u.EMIncrementRate, 2) 'Total Billed'
from 
	(-- begin subquery v
		select 
			v.company_id, 
			f.FACILITY_ID,
			isnull(nullif(f.ACCOUNTING_FACILITY_CODE, ''), f.FACILITY_NUMBER) Facility,
			f.NAME FacilityName,
			v.Rate_Class,
			v.CCSRate,
			v.ProFeeRate,
			v.SaaSRate,
			v.EMIncrementRate,
			v.FS_With_Obs_Rate,
			v.SaasObsOnlyRate,
			v.CCSObsOnlyRate,
			v.Saas_Obs_With_CCS_ED_Rate,
--			sum(v.TotCCS) TotCCS,
			sum(v.TotCCSNonVendor) as TotCCSNonVendor ,
			sum(v.TotCCSVendor) TotCCSVendor,
			sum(v.TotSaaS) TotSaaS,
			SUM(v.TotEM) TotEM,
			sum(v.TotCharts) TotCharts ,
			SUM(v.TotProFee) TotProFee
		from   
			FACILITY f with (NOLOCK), 
			(-- begin subquery w
				select 
					w.company_id,
					w.FACILITY_ID,
					w.Rate_Class,
					--w.TotCCS, 
					w.TotCCSNonVendor,
					w.TotCCSVendor,
					w.TotProFee,        
					case when w.Rate_Class IN (6,7,8) then 0 else isnull(w.CCSRate, 0) end CCSRate,
					case when w.ProFeeRate is null then 0 else w.ProFeeRate end ProFeeRate,
					case when w.EMIncrementRate is null then 0 else w.EMIncrementRate end EMIncrementRate,
					case when w.Rate_Class = 5  then isnull(w.FS_With_Obs_Rate, 0) else 0 end FS_With_Obs_Rate,
					case when (w.Rate_Class = 6 OR w.Rate_Class = 9 OR w.Rate_Class = 10) then isnull(w.SaaS_Obs_Only_Rate,0) else 0 end SaasObsOnlyRate, 
					case when w.Rate_Class = 8 then isnull(w.CCS_Obs_Only_Rate, 0) else 0 end  CCSObsOnlyRate,
					case when w.Rate_Class = 7 then isnull(w.Saas_Obs_With_CCS_ED_Rate,0) else 0 end Saas_Obs_With_CCS_ED_Rate,
					w.TotSaaS,
					case when w.SaaSRate is null OR w.Rate_Class = 9 then 0 else w.SaaSRate end SaaSRate,
					w.TotCharts,
					case when w.EMIncrementRate > 0 then w.TotEM else 0 end TotEM
				from 
					(-- begin subquery z
						select	
							z.company_id,
							z.FACILITY_ID,				
							case 
								when z.SLA_RATE <> 0 and z.SLA_RATE is not null then 1 --SLA Rate         
								when z.MultiDept_Rate <> 0 and z.MultiDept_Rate is not null then 2  --Multi-Dept Rate
								when z.SelfPay_Rate <> 0 and z.SelfPay_Rate is not null then 3  --Self-Pay Rate
								when z.EMIncrementRate <> 0 and z.EMIncrementRate is not null then 4  --E&M Increment Rate            
								when z.OBSERVATION_BILLING_METHOD_CD = 4 then 6 -- SaaS Obs Only
								when z.OBSERVATION_BILLING_METHOD_CD = 2 then 7 -- SaaS Obs with CCS ED
								when z.OBSERVATION_BILLING_METHOD_CD = 3 then 8 -- CCS Obs Only 
								when z.OBSERVATION_BILLING_METHOD_CD = 1 then 5 -- CCS ED and Obs
								when z.PHYSICIAN_SERVICE_CLASS_CD = 5 then 5	-- Profee obs = CCS ED and Obs
								when z.SaaS_Obs_Only_Rate <> 0 and z.ED_Ind = 1 then 10 -- SaaS ED and Obs
								when z.SaaS_Obs_Only_Rate <> 0 then 9           -- Saas Obs Only
								else 0 end Rate_Class,  -- Std Rate
							--z.TotCCS,
							z.TotCCSNonVendor,
							z.TotCCSVendor,
							z.TotProFee,   
							case 
								when z.SLA_RATE <> 0 and z.SLA_RATE is not null and (z.SLA_RATE_METHOD_IND = 0 or z.SLA_RATE_METHOD_IND is null) 
								then z.SLA_RATE  -- SLA rate triggered and is a discount amount
								else round
									(
										(
											select sum(sar.RATE) 
											from SERVICE_AGREEMENT_RATE sar 
											where sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
												and sar.RATE_CLASS_CD = 'B'
												and   
												(
													sar.RATE_TYPE_CD in ('C')
													or (z.SelfPay_Rate <> 0 and z.SelfPay_Rate is not null and sar.RATE_TYPE_CD = '5')
												)
												and convert(varchar, z.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
												and convert(varchar, z.RATE_DATE, 112) <= sar.EXPIRATION_DATE
										) *
													--and   z.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE) * 
										(1 - 
											(
												case 
													when z.SLA_RATE <> 0 and z.SLA_RATE is not null and z.SLA_RATE_METHOD_IND = 1 
													then z.SLA_RATE/100 
													else 0 end
											)
										), 5
									) -- Reduce rate by SLA discount percent if triggered
								end CCSRate,
							(
								select sar.RATE 
								from SERVICE_AGREEMENT_RATE sar
								where 
									sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
									and sar.RATE_CLASS_CD = 'B'
									and sar.RATE_TYPE_CD = 'P'
									and convert(varchar, z.RATE_DATE, 112) >= sar.EFFECTIVE_DATE and convert(varchar, z.RATE_DATE, 112) <= sar.EXPIRATION_DATE
							) ProFeeRate,
									--and   z.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE) ProFeeRate,
							z.TotSaaS,       
							(
								select sum(sar.RATE) 
								from SERVICE_AGREEMENT_RATE sar
								where 
									sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
									and sar.RATE_CLASS_CD = 'B'
									and 
									(
										sar.RATE_TYPE_CD in ('S')
										or (z.MultiDept_Rate <> 0 and z.MultiDept_Rate is not null and sar.RATE_TYPE_CD = 'O')
										or (z.SelfPay_Rate <>0 and z.SelfPay_Rate is not null and sar.RATE_TYPE_CD = '6')
									)
									and convert(varchar, z.RATE_DATE, 112) >= sar.EFFECTIVE_DATE and convert(varchar, z.RATE_DATE, 112) <= sar.EXPIRATION_DATE
							) SaaSRate,
							   --and   z.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE) SaaSRate,
							z.TotCharts, 
							z.TotEM, 
							z.EMIncrementRate, 
							z.FS_With_Obs_Rate, 
							z.SaaS_Obs_Only_Rate, 
							z.CCS_Obs_Only_Rate, 
							z.Saas_Obs_With_CCS_ED_Rate
						from   
							(-- begin subquery y
								select 
									y.company_id,
									y.RATE_DATE,
									y.FACILITY_ID,
									y.ED_Ind, 
									y.OBS_Ind,
									y.CODED_BY_ID, 
									y.OBS_CCS_User, 
									y.OBS_Client_User,
									y.OBSERVATION_BILLING_METHOD_CD,
									y.PHYSICIAN_SERVICE_CLASS_CD,
									y.SERVICE_AGREEMENT_ID,
									y.SLA_RATE_METHOD_IND,
									y.SLA_RATE,
									y.MultiDept_Rate,
									y.SelfPay_Rate,
									y.EMIncrementRate,
									y.FS_With_Obs_Rate,
									y.SaaS_Obs_Only_Rate,
									y.CCS_Obs_Only_Rate,
									y.Saas_Obs_With_CCS_ED_Rate,       
								--	sum(y.CCS) TotCCS,
								sum(y.CCS_NonVendor) TotCCSNonVendor,
								sum(y.CCS_Vendor) TotCCSVendor,

									sum(y.ProFee) TotProFee,
									sum(y.SaaS) TotSaaS,
									SUM(y.EMChart) TotEM,
									count(*) TotCharts
								from 
									(-- begin subquery x    (now uses preprocessed values for 8 columns per changes of 1/5/2016)
										select 
											x.company_id,
											x.RATE_DATE,
											x.FACILITY_ID,
											x.OBSERVATION_BILLING_METHOD_CD,
											x.PHYSICIAN_SERVICE_CLASS_CD,
											x.ED_Ind, 
											x.OBS_Ind, 
											x.SLA_RATE_METHOD_IND,
											x.CODED_BY_ID,
											x.OBS_CCS_User,
											x.OBS_Client_User,
											x.SERVICE_AGREEMENT_ID,
											x.CHART_ID,
										--	case 
										--		when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
										--		when up.USER_CLASS_CD = 4 then 0 
										--		else 1 end CCS, 

                                            case 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
												when up.USER_CLASS_CD = 4 then 0 
												when up.USER_CLASS_CD = 5 then 0 
												else 1 end CCS_NonVendor, 
											case 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
												when up.USER_CLASS_CD = 4 then 0 
												when up.USER_CLASS_CD = 5 then 1 
												else 0 end CCS_Vendor, 
											case 
												when x.BILL_PRO_FEE_IND = 1 then 1 else 0 end ProFee,
											case 
												when up.USER_CLASS_CD = 4 then 1 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 1
												else 0 end SaaS,
           
											case 
												when 
												(
													select distinct 1 
													from FACILITY_LEVEL fl WITH (NOLOCK)
													where 
														fl.FACILITY_LEVEL_ID = 
															(
																case 
																	when x.OVERRIDE_FACILITY_LEVEL_ID <> -1 then x.OVERRIDE_FACILITY_LEVEL_ID 
																	else x.FACILITY_LEVEL_ID 
																	end
															)				   
														and fl.LEVEL_NUMBER > 0
												) = 1 then 1 
												else 0 end EMChart,
											-- The 8 columns below now reference preprocessed values per changes on 1/5/2016 -------------------------------------
											SLA_RATE = case 
												when up.USER_CLASS_CD = 4 then 0
												when up.USER_CLASS_CD <> 4 and x.SLA_HOURS = 0 then 0
												when x.SLA_HOURS <= x.MAX_SLA_HOURS then 0 -- Penalized when elpsed SLA_HOURS exceeds the SLA
												when x.TURNAROUND_HOURS_REPORTING_METHOD IN (6,7) 
													then x.SLARate_Turnaround
													else x.SLARate_Else
													end, 
											x.MultiDept_Rate,
											x.SaaS_Obs_Only_Rate,           
											x.CCS_Obs_Only_Rate,
											x.SaaS_Obs_With_CCS_ED_Rate,
											x.FS_With_Obs_Rate,    
											x.SelfPay_Rate,
											x.EMIncrementRate
											------------------------------------------------------------------------------------------------------------------------
							-- End of SELECT statement of subquery x
										from 
											USER_PROFILE up  WITH (NOLOCK), 
										-- subquery X now incorporates prepopulated temp tables in order to eliminate blocking other queries against CHART and LOG_NOTE
											(
												select * from #PrelimResults as t		-- new temp table
											) x
										where x.CODED_BY_ID = up.USER_PROFILE_ID
									) as y
								group by 
									y.company_id,
									y.RATE_DATE,
									y.FACILITY_ID,
									y.SERVICE_AGREEMENT_ID,
									y.SLA_RATE_METHOD_IND,
									y.SLA_RATE,
									y.MultiDept_Rate,
									y.SelfPay_Rate,
									y.FS_With_Obs_Rate,
									y.SaaS_Obs_Only_Rate,
									y.CCS_Obs_Only_Rate,
									y.Saas_Obs_With_CCS_ED_Rate,
									y.ED_Ind,
									y.OBS_Ind,
									y.CODED_BY_ID,
									y.OBS_CCS_User,
									y.OBS_Client_User,
									y.OBSERVATION_BILLING_METHOD_CD,
									y.PHYSICIAN_SERVICE_CLASS_CD,
									y.EMIncrementRate
							) as z
					) as w
			) as v
		where v.Facility_ID = f.FACILITY_ID
		group by 
			v.company_id, f.FACILITY_ID, isnull(nullif(f.ACCOUNTING_FACILITY_CODE, ''), f.FACILITY_NUMBER), f.NAME, 
			v.Rate_Class, v.CCSRate, v.ProFeeRate, v.SaaSRate, v.EMIncrementRate, v.FS_With_Obs_Rate, v.SaasObsOnlyRate, v.CCSObsOnlyRate, v.Saas_Obs_With_CCS_ED_Rate
			

	) as u


)f

group by 
    f.Organization,
	f.Facility	
order by f.FACILITY  

option (maxdop 2)		-- protects from runaway parallelism and improves performance 
END









GO
GRANT EXECUTE ON  [dbo].[BILLING_SUMMARY_BY_FACILITY_FINANCE_3] TO [dbx_ExecuteReportProcs]
GO
