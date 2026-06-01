SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[NETSUITE_BILLING_SUMMARY]
	@billing_period int

WITH EXEC AS CALLER
AS

BEGIN

if object_id('TempDB..#PrelimResults', 'U') is not null DROP TABLE #PrelimResults;

declare @billingperiod int
set @billingperiod = @billing_period	


select * 
into #PrelimResults		-- new temp table for tuning (to support breaking out the complex CASE statements of subquery X in order to eliminate blocking)
from
(
	select
		c.FACILITY_ID,
		c.SERVICE_AGREEMENT_ID,
		c.OBSERVATION_BILLING_METHOD_CD,
		(
			select top 1 brc.NETSUITE_ID  from SERVICE_AGREEMENT_BILLING_RATE_CLASS src WITH (NOLOCK), BILLING_RATE_CLASS brc WITH (NOLOCK)
			where src.EFFECTIVE_DATE <= c.SENT_DATE
			and   src.EXPIRATION_DATE > c.SENT_DATE
			and   src.BILLING_RATE_TYPE_ID = 1 --Base Rate
			and	  src.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
			and   src.BILLING_RATE_CLASS_ID = brc.BILLING_RATE_CLASS_ID
		) as BaseNetSuiteID,

		(
			select top 1 brc.NETSUITE_ID  from SERVICE_AGREEMENT_BILLING_RATE_CLASS src WITH (NOLOCK), BILLING_RATE_CLASS brc WITH (NOLOCK)
			where src.EFFECTIVE_DATE <= c.SENT_DATE
			and   src.EXPIRATION_DATE > c.SENT_DATE
			and   src.BILLING_RATE_TYPE_ID = 2 --Obs Add on Rate
			and	  src.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
			and   src.BILLING_RATE_CLASS_ID = brc.BILLING_RATE_CLASS_ID
		) as ObsAddOnNetSuiteID,
		
		(
			select top 1 brc.NETSUITE_ID  from SERVICE_AGREEMENT_BILLING_RATE_CLASS src WITH (NOLOCK), BILLING_RATE_CLASS brc WITH (NOLOCK)
			where src.EFFECTIVE_DATE <= c.SENT_DATE
			and   src.EXPIRATION_DATE > c.SENT_DATE
			and   src.BILLING_RATE_TYPE_ID = 3 --Direct to Obs Rate
			and	  src.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
			and   src.BILLING_RATE_CLASS_ID = brc.BILLING_RATE_CLASS_ID
		) as DirectToObsNetSuiteID,

		(
			select top 1 brc.NETSUITE_ID  from SERVICE_AGREEMENT_BILLING_RATE_CLASS src WITH (NOLOCK), BILLING_RATE_CLASS brc WITH (NOLOCK)
			where src.EFFECTIVE_DATE <= c.SENT_DATE
			and   src.EXPIRATION_DATE > c.SENT_DATE
			and   src.BILLING_RATE_TYPE_ID = 4 --Additional Profee Add on Rate
			and	  src.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
			and   src.BILLING_RATE_CLASS_ID = brc.BILLING_RATE_CLASS_ID
		) as AddtlProfeeAddOnNetSuiteID,

		(
			select pcl.physician_service_class_cd 
			from PATIENT_CLASS pcl WITH (NOLOCK)
			where pcl.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
		) as PHYSICIAN_SERVICE_CLASS_CD,

		case 
			when sa.RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
			when sa.RATE_METHOD_CD = 2 then c.SENT_DATE
			else bctl.END_DATE end RATE_DATE,
      	bc.CHART_ID,
		case
			when c.PATIENT_DISPOSITION_ID = 5 -- Observation
				then (select 1 from SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sap where sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
						AND sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 2) 
				else 0 end DirectToObsInd,
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
      				FROM  SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao WITH (NOLOCK)
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
					from charge_master_department cmd WITH (NOLOCK)
					where  
						cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
						and    c.TIME_OF_DIS not between cmd.EFFECTIVE_DATE and cmd.EXPIRATION_DATE
				) = 1 then 0
				else 1 end OBS_Ind,

		case 
			when 
			(
				select distinct 1 
				from USER_PROFILE up WITH (NOLOCK)
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
		sa.description as ServiceAgreementDescription,
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
		, SLA_Hours = cast(null as int)	
		, SLARate_Turnaround_ID = cast(null as int)
		, SLARate_Else_ID = cast(null as int)
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

) x 

update #PrelimResults set DirectToObsInd = 0 where DirectToObsInd is null

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

	if object_id('TempDB..#SLARate_TurnaroundRptMethod', 'U') is not null DROP TABLE #SLARate_TurnaroundRptMethod;
	select *
	 INTO #SLARate_TurnaroundRptMethod
	from
		(
			select 
				x.chart_ID,
				slabc.BILLING_SLA_RATE_CLASS_ID, 
				slabc.SERVICE_AGREEMENT_BILLING_BASE_RATE_CLASS_ID 
			from 
				SERVICE_AGREEMENT_BILLING_SLA_RATE_CLASS as slabc WITH (NOLOCK)
				join #PrelimResults as x
					ON slabc.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
				join SERVICE_AGREEMENT_BILLING_RATE_CLASS sbc 
					ON slabc.SERVICE_AGREEMENT_BILLING_BASE_RATE_CLASS_ID = sbc.SERVICE_AGREEMENT_BILLING_RATE_CLASS_ID
			where 
				((x.BaseNetSuiteID = sbc.BILLING_RATE_CLASS_ID and x.DirectToObsInd = 0) 
				  or (x.DirectToObsNetSuiteID = sbc.BILLING_RATE_CLASS_ID and x.DirectToObsInd = 1))
				and convert(varchar, x.RATE_DATE, 112) >= slabc.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= slabc.EXPIRATION_DATE
				and x.SLA_HOURS >= slabc.SLA_HOURS
				and slabc.SLA_HOURS = 
					(
						select max(slabc2.SLA_HOURS) 
						from SERVICE_AGREEMENT_BILLING_SLA_RATE_CLASS slabc2 WITH (NOLOCK)
						where 
							slabc2.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
							and convert(varchar, x.RATE_DATE, 112) >= slabc2.EFFECTIVE_DATE 
							and convert(varchar, x.RATE_DATE, 112) <= slabc2.EXPIRATION_DATE
							and slabc2.SLA_HOURS <= x.SLA_HOURS
					)
		) as t				

	UPDATE x
	SET x.SLARate_Turnaround_ID = t.BILLING_SLA_RATE_CLASS_ID
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
				slabc.BILLING_SLA_RATE_CLASS_ID, 
				slabc.SERVICE_AGREEMENT_BILLING_BASE_RATE_CLASS_ID
			from 
				SERVICE_AGREEMENT_BILLING_SLA_RATE_CLASS as slabc WITH (NOLOCK)
				join #PrelimResults as x
					ON slabc.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
			where 
				convert(varchar, x.RATE_DATE, 112) >= slabc.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= slabc.EXPIRATION_DATE
				and x.SLA_HOURS >= slabc.SLA_HOURS
				and slabc.SLA_HOURS = 
					(
						select max(slabc2.SLA_HOURS) 
						from SERVICE_AGREEMENT_BILLING_SLA_RATE_CLASS slabc2 WITH (NOLOCK)
						where 
							slabc2.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
							and convert(varchar, x.RATE_DATE, 112) >= slabc2.EFFECTIVE_DATE 
							and convert(varchar, x.RATE_DATE, 112) <= slabc2.EXPIRATION_DATE
							and slabc2.SLA_HOURS <= x.SLA_HOURS
							and (
									x.Pended <> 'Y' 
									or x.Pended is null
								)
					) 
		) as t

	UPDATE x
	SET x.SLARate_Else_ID = t.BILLING_SLA_RATE_CLASS_ID
	FROM 
		#PrelimResults as x
		join #SLARate_ELSE as t 
			ON x.chart_ID = t.chart_ID

select y.ServiceAgreementDescription, y.Facility_ID as FacilityID,  f.Accounting_Facility_Code, y.RateType, y.NetSuiteID, y.RateClassDescription, sum(y.incr) as RateClassCount, 
	case when y.SLARate_Turnaround_ID is not NULL then y.SLARate_Turnaround_ID
		else '' end as SLA_Discount_ID, 
	case when y.SLA_RATE_METHOD_IND = 0 then 'Amount'
		 when y.SLA_RATE_METHOD_IND = 1 then 'Percent'
		 else '' end as SLA_Rate_Type,
	case when y.SLARate_Turnaround_ID is not NULL then (select bc.BILLING_RATE_CLASS_DESCRIPTION from BILLING_RATE_CLASS bc where bc.BILLING_RATE_CLASS_ID = y.SLARate_Turnaround_ID)
		else '' end as SLA_Description 		 
from 
(
	select r.ServiceAgreementDescription, Facility_ID, '1 - Base Rate' as RateType, r.BaseNetSuiteID as NetSuiteID, 1 as incr ,bc.BILLING_RATE_CLASS_DESCRIPTION as RateClassDescription, 
	r.SLARate_Turnaround_ID, r.SLA_RATE_METHOD_IND
	from #PrelimResults r, BILLING_RATE_CLASS bc 
	where r.BaseNetSuiteID is not null 
	and r.BaseNetSuiteID > 0 and r.ED_ind =1 and r.BaseNetSuiteID = bc.NetSuite_ID 
	
	UNION ALL
	select r.ServiceAgreementDescription, facility_id,  '2 - Obs Add-On Rate' as RateType, ObsAddOnNetSuiteID as NetSuiteID, 1 as incr, bc.BILLING_RATE_CLASS_DESCRIPTION as RateClassDescription,
	 r.SLARate_Turnaround_ID, r.SLA_RATE_METHOD_IND
	from #PrelimResults r, BILLING_RATE_CLASS bc  where ObsAddOnNetSuiteID is not null AND ObsAddOnNetSuiteID > 0 and ObsAddOnNetSuiteID = bc.NetSuite_ID
	and r.patient_disposition_id = 5 and (DirectToObsInd is null OR DirectToObsInd = 0)
	UNION ALL
	select r.ServiceAgreementDescription, facility_id,  '3- Direct to Obs Rate' as RateType, DirectToObsNetSuiteID as NetSuiteID, 1 as incr, bc.BILLING_RATE_CLASS_DESCRIPTION as RateClassDescription,
	r.SLARate_Turnaround_ID, r.SLA_RATE_METHOD_IND
	from #PrelimResults r, BILLING_RATE_CLASS bc where DirectToObsNetSuiteID is not null  AND DirectToObsNetSuiteID > 0 and DirectToObsNetSuiteID = bc.NetSuite_ID
	and DirectToObsNetSuiteID > 0 and r.DirectToObsInd = 1
	
	--UNION ALL
	--select r.ServiceAgreementDescription, facility_id,  '4 - Addtl ProFee Add-on Rate' as RateType,  AddtlProfeeAddOnNetSuiteID as NetSuiteID, 1 as incr, bc.BILLING_RATE_CLASS_DESCRIPTION as RateClassDescription 
	--	from #PrelimResults r where AddtlProfeeAddOnNetSuiteID is not null 
	--	and AddtlProfeeAddOnNetSuiteID > 0
	)  y, FACILITY f

	where f.FACILITY_ID = y.FACILITY_ID
	group by y.serviceAgreementDescription, y.facility_id,  f.Accounting_Facility_Code,  y.NetSuiteID, y.RateClassDescription, y.SLA_RATE_METHOD_IND, y.RateType, y.SLARate_Turnaround_ID
	order by y.serviceAgreementDescription, y.RateType, y.RateClassDescription, SLA_Discount_ID

END
 

GO
EXEC sp_addextendedproperty N'MS_Description', N'Billing Control ID', 'SCHEMA', N'dbo', 'PROCEDURE', N'NETSUITE_BILLING_SUMMARY', 'PARAMETER', N'@billing_period'
GO
