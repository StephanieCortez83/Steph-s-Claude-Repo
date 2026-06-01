SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE PROCEDURE [dbo].[BILLING_SUMMARY_BY_FACILITY_FINANCE]
	@billing_period int


WITH EXEC AS CALLER
AS

BEGIN




SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- testing parameter
-- declare @billing_period int = 227     -- 226 SEP/2024  

declare @billingperiod int
set @billingperiod = @billing_period

declare @p_StartDate date
set @p_StartDate = (select START_DATE from billing_control
					where BILLING_CONTROL_ID = @BillingPeriod );

declare @region_map_us_census table
([Region] varchar(25), [State] varchar(2))

insert into @region_map_us_census values('West', 'AK')
insert into @region_map_us_census values('South', 'AL')
insert into @region_map_us_census values('South', 'AR')
insert into @region_map_us_census values('West', 'AZ')
insert into @region_map_us_census values('West', 'CA')
insert into @region_map_us_census values('West', 'CO')
insert into @region_map_us_census values('Northeast', 'CT')
insert into @region_map_us_census values('South', 'DC')
insert into @region_map_us_census values('South', 'DE')
insert into @region_map_us_census values('South', 'FL')
insert into @region_map_us_census values('South', 'GA')
insert into @region_map_us_census values('West', 'HI')
insert into @region_map_us_census values('Midwest', 'IA')
insert into @region_map_us_census values('West', 'ID')
insert into @region_map_us_census values('Midwest', 'IL')
insert into @region_map_us_census values('Midwest', 'IN')
insert into @region_map_us_census values('Midwest', 'KS')
insert into @region_map_us_census values('South', 'KY')
insert into @region_map_us_census values('South', 'LA')
insert into @region_map_us_census values('Northeast', 'MA')
insert into @region_map_us_census values('South', 'MD')
insert into @region_map_us_census values('Northeast', 'ME')
insert into @region_map_us_census values('Midwest', 'MI')
insert into @region_map_us_census values('Midwest', 'MN')
insert into @region_map_us_census values('Midwest', 'MO')
insert into @region_map_us_census values('South', 'MS')
insert into @region_map_us_census values('West', 'MT')
insert into @region_map_us_census values('South', 'NC')
insert into @region_map_us_census values('Midwest', 'ND')
insert into @region_map_us_census values('Midwest', 'NE')
insert into @region_map_us_census values('Northeast', 'NH')
insert into @region_map_us_census values('Northeast', 'NJ')
insert into @region_map_us_census values('West', 'NM')
insert into @region_map_us_census values('West', 'NV')
insert into @region_map_us_census values('Northeast', 'NY')
insert into @region_map_us_census values('Midwest', 'OH')
insert into @region_map_us_census values('South', 'OK')
insert into @region_map_us_census values('West', 'OR')
insert into @region_map_us_census values('Northeast', 'PA')
insert into @region_map_us_census values('Northeast', 'RI')
insert into @region_map_us_census values('South', 'SC')
insert into @region_map_us_census values('Midwest', 'SD')
insert into @region_map_us_census values('South', 'TN')
insert into @region_map_us_census values('South', 'TX')
insert into @region_map_us_census values('West', 'UT')
insert into @region_map_us_census values('South', 'VA')
insert into @region_map_us_census values('Northeast', 'VT')
insert into @region_map_us_census values('West', 'WA')
insert into @region_map_us_census values('Midwest', 'WI')
insert into @region_map_us_census values('South', 'WV')
insert into @region_map_us_census values('West', 'WY')

--select * from @region_map_us_census

if object_id('TempDB..#PrelimResults', 'U') is not null DROP TABLE #PrelimResults;
select * 
into #PrelimResults		-- new temp table for tuning (to support breaking out the complex CASE statements of subquery X in order to eliminate blocking)
from
(
	select
	    sa.Company_ID,
		c.FACILITY_ID,
		c.SERVICE_AGREEMENT_ID,
		sa.ORGANIZATION_ID,
		sa.SERVICE_MODEL_CD,
		c.OBSERVATION_BILLING_METHOD_CD,

		ltrim(rtrim(coalesce(
								stuff(
									(
									select 
										',' + es.[DESCRIPTION]
									from
									--	SERVICE_AGREEMENT sa
									--	inner join 
										SERVICE_AGREEMENT_EMR_SYSTEM saes 
										inner join EMR_SYSTEM_TYPE est on saes.emr_system_type_id = est.emr_system_type_id
										inner join EMR_SYSTEM es on saes.emr_system_id = es.emr_system_id
									where
									saes.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID 
									and est.EMR_SYSTEM_TYPE_ID = 5	--Documentation	
									order by es.[DESCRIPTION]
									for xml path('')
									)
									,1
									,1
									,''
										)
								,'N/A'
							)
					)
				) as EMR_SYSTEM,


		(
			select pcl.physician_service_class_cd 
			from PATIENT_CLASS pcl 
			where pcl.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
		) as PHYSICIAN_SERVICE_CLASS_CD,

		case 
			when sa.RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
			when sa.RATE_METHOD_CD = 2 then c.SENT_DATE
			--when sa.RATE_METHOD_CD = 2 then isnull(c.SENT_DATE, getdate()) -- testing ONLY, not all records in QA are sent ******** 
			else bctl.END_DATE end RATE_DATE,
      	c.CHART_ID,

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
			when sa.BILL_CODER_METHOD_CD = 1 and c.CHART_ID in		
				(
					select ln.CHART_ID 
					from LOG_NOTE ln  WITH (NOLOCK)
      				where 
						c.CHART_ID = ln.CHART_ID
      					and   ln.CATEGORY_ID = 2
				) then 
					(
						select ln.CREATING_USER_PROFILE_ID 
						from LOG_NOTE ln WITH (NOLOCK)
      					where 
							ln.CHART_ID = c.CHART_ID
      						and   ln.CATEGORY_ID = 2
      						and   ln.LOG_NOTE_ID = 
								(
									select min(ln2.LOG_NOTE_ID) 
									from log_note ln2  WITH (NOLOCK)
      								where 
										ln2.CHART_ID = c.CHART_ID
      									and   ln2.CATEGORY_ID = 2
								)
					)
				else c.COMPLETED_BY_USER_PROFILE_ID end CODED_BY_ID,

CODER_USER_CLASS = cast(null as int),	

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
		sa.RATE_METHOD_CD,
		RATE_TYPE_CD = cast(null as varchar(2)),

		-- new columns for tuning
		sa.TURNAROUND_HOURS_REPORTING_METHOD,	
		sa.TURNAROUND_START_TIME_IN_MINUTES,
        sa.SLA_HOURS MAX_SLA_HOURS,	
		c.creation_date_time,
		c.sent_date,
		c.approved_date,
		c.TIME_OF_SERVICE,
		c.date_received

		-- new columns for tuning on 1/4/2016
		, c.facility_level_ID
		, c.OVERRIDE_FACILITY_LEVEL_ID
		, c.PATIENT_DISPOSITION_ID
		, c.FINANCIAL_CLASS_CD
		, c.Patient_Class_ID
		, c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
		, PatientClass = cast(null as varchar(50))
		, PCLength = cast(null as int)

		-- new columns for tuning on 1/5/2016  (these will be populated in subsequent steps)
		, SLA_Hours = cast(null as int)	
		, SLARate_Turnaround = cast(null as money)
		, SLARate_Else = cast(null as money)
		, MultiDept_Rate = cast(null as money)
		, SaaS_Obs_Only_Rate = cast(null as money)
		, CCS_Obs_Only_Rate = cast(null as money)
		, SaaS_Obs_With_CCS_ED_Rate = cast(null as money)
		, FS_With_Obs_Rate = cast(null as money)
		, FS_Inpatient_Rate = cast(null as money)
		, SelfPay_Rate = cast(null as money)
		, EMIncrementRate = cast(null as money)

		, Inpatient_LengthOfStay1_Rate = cast(null as money)
		, Inpatient_LengthOfStay2_Rate = cast(null as money)
		, Inpatient_LengthOfStay3_Rate = cast(null as money)
		, Inpatient_LengthOfStay4_Rate = cast(null as money)
		, Inpatient_LengthOfStay5_Rate = cast(null as money)
		, Inpatient_LengthOfStay6_Rate = cast(null as money)
		, Inpatient_LengthOfStay7_Rate = cast(null as money)
		, Inpatient_LengthOfStay8_Rate = cast(null as money)
		, Inpatient_LengthOfStay9_Rate = cast(null as money)
		, Inpatient_LengthOfStay10_Rate = cast(null as money)

		, Tenet_Rate = cast(null as money)
		, Tenet_Rate_Type = cast(null as varchar(50))

		, PatientClass_Rate = cast(null as money)


		,cast(c.arrival_date_time as date) as Arrival_Date
		,cast(c.ADMISSION_DATE_TIME as date) as Admission_Date
		,cast(c.time_of_dis as date) as Dis_Date		
		,case when c.arrival_date_time is not null then (datediff(day, cast(c.arrival_date_time as date) ,cast(c.time_of_dis as date)) +1)
			      when c.ADMISSION_DATE_TIME is not null then (datediff(day, cast(c.ADMISSION_DATE_TIME as date) ,cast(c.time_of_dis as date)) +1) 
				  else (datediff(day, cast(c.TIME_OF_SERVICE as date) ,cast(c.time_of_dis as date)) +1)
			 end as StayDayCnt

		,r.Region
		,f.[STATE]
		,fc.[DESCRIPTION] [FACILITY_CLASSIFICATION]
		,case when fc.[DESCRIPTION] = 'Clinic-Specialty' then 'Clinic'
				when sa.FACILITY_TYPE_CD = 1 then 'ED'
				when sa.FACILITY_TYPE_CD = 2 then 'Urgent Care' 
			end as FACILITY_TYPE,
		
		sa.AUTOMATION_CODING_ENABLED,  
		c.FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME,
		c.PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME,
		case when c.FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL
			or c.PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL then 1 else 0 end as Automation
       ,Automation_Rate = cast(0 as int)
	   ,Automation_Exclude = cast(0 as int)
	from  
		billed_chart bc WITH (NOLOCK),  
		chart c WITH (NOLOCK)
		, billing_control bctl WITH (NOLOCK) 
		, service_agreement sa WITH (NOLOCK)
		left join SERVICE_AGREEMENT_CLIENT_SPECIFICS sacs on sa.SERVICE_AGREEMENT_ID = sacs.SERVICE_AGREEMENT_ID
		left join FACILITY_CLASSIFICATION fc on sacs.FACILITY_CLASSIFICATION_ID = fc.FACILITY_CLASSIFICATION_ID
		, FACILITY f with (nolock)
		left join @region_map_us_census r on f.[STATE] = r.[State]
	where 
		bctl.BILLING_CONTROL_ID = bc.BILLING_CONTROL_ID  
		and	
		bctl.BILLING_CONTROL_ID = @billingPeriod
		and bc.TYPE_CD = 'B'						   
		and c.CHART_ID = bc.CHART_ID                 
		and sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		
		and sa.DEMO_TEST_SITE_IND <> 1
		and sa.FACILITY_ID = f.FACILITY_ID
		and sa.company_id not in (196, 134, 223, 19, 298) -- 03/19/2025 RAP-929 DAH - exclude MultiCare Health System,  04/23/25 RAP-1014 DAH exclude R1 Ascension, 05/21/25 RAP-1094 Exclude Tenet, Conifer 		

		-- Testing specific items listed below

		-- and sa.ORGANIZATION_ID = 8   -- testing only / remove



		-- and c.facility_id = 2642 --in ( 2639, 2640)  -- test only -- Envision MIPS CC Offshore - Not in billed chart table 
		-- and c.facility_id = 1044 -- test only -- Torrance Memorial Medical Center
		
		-- and c.facility_id = 1783 -- Testing Only -- Tenet - AHH - Abrazo Arizona Heart Hospital    -   FS Auto Example 
		--and c.facility_id = 2242	-- Testing Only -- Altus Lake Jackson GoRev1783					  -   SaaS Rate Auto Example
		--   and c.facility_id = 2462	-- Testing Only -- Neighbors - TEMP Pearland GoRev					  -   SaaS Auto Example
		-- and c.facility_id = 2611  --  SaaS

		--  and c.facility_id = 2352	-- Testing Only -- CHOA - Arthur M Blank					      -   Patient Class Rate Example	
--		 and c.facility_id = 2296	-- Testing Only -- Tenet OP 6 - Alabama					          -   Tenet Rate Example	
		
--		and c.facility_id = 1782 -- 1782/1783 -- FS Auto   (1783 - FS Automation Rate ) 1782 FS Auto 

-- 		 and c.facility_id = 2035 -- Conifer test Tenet reassign to Conifer

		-- test only -- Envision MIPS CC Offshore - Not in billed chart table  QA - Saas Auto
		--2352
		-- Additional conditions needed for QA Database
		--and chart_status_id in ( 3,4,5)
		--and (c.COMPLETED_BY_USER_PROFILE_ID is not null and c.COMPLETED_BY_USER_PROFILE_ID <> -1) -- get completed charts

		

		
) as t



-- select * from #PrelimResults	



-- RAP-442 DAH - 06/03/24
-- Correction to one chart that was incorrect for specific billing period

update t
set CODED_BY_ID = 14534
FROM #PrelimResults as t
where 
chart_id = 119562882 
and @billingPeriod = 222;


--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------


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

-- *********************************
-- Update #PrelimResults Fields


	UPDATE x
	SET x.CODER_USER_CLASS = t.USER_CLASS_CD
	FROM 
	#PrelimResults as x
	join USER_PROFILE as t 
	ON x.CODED_BY_ID = t.USER_PROFILE_ID;


	UPDATE x
	SET x.PatientClass = pc.description,
	    x.PCLength = len(pc.description)
	FROM 	
	#PrelimResults as x
	join PATIENT_CLASS as pc 
	ON x.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID;

	-- not working correctly, SA's will have multi rate types
--UPDATE x
--	SET x.RATE_TYPE_CD = sar.RATE_TYPE_CD
--	FROM 	
--	#PrelimResults as x
--	join SERVICE_AGREEMENT_RATE as sar on x.service_agreement_id = sar.service_agreement_id    
--	where 
--	sar.RATE_CLASS_CD = 'B';


    UPDATE x
	SET x.Automation_Rate = 1
	FROM 	
	#PrelimResults as x
	join SERVICE_AGREEMENT_RATE as sar on x.service_agreement_id = sar.service_agreement_id    
	where 
	sar.RATE_CLASS_CD = 'B'
	and sar.RATE_TYPE_CD in ('FA', 'SQ');

		UPDATE x
	SET x.Automation_Exclude = 1
	FROM 	
	#PrelimResults as x
	join SERVICE_AGREEMENT as sa on x.service_agreement_id = sa.service_agreement_id    
	where 
	sa.COMPANY_ID = 296; --Legacy - Envision  

	
-- 	select * from SERVICE_AGREEMENT_RATE where service_agreement_id = 2578

-- *********************************
-- *********************************
-- *********************************


 if object_id('TempDB..#Inpatient_LOS_Rates', 'U') is not null
    begin
        drop table #Inpatient_LOS_Rates;
    end;


select 
sar.SERVICE_AGREEMENT_RATE_ID,
sar.SERVICE_AGREEMENT_ID,
sar.RATE_CLASS_CD,
sar.RATE_TYPE_CD,
sar.RATE,
sar.EFFECTIVE_DATE,
sar.EXPIRATION_DATE,
sar.FREQUENCY,
sar.STAY_RANGE_START,
sar.STAY_RANGE_END,

sa.COLLECT_ARRIVAL_DATE,
sa.COLLECT_ADMISSION_DATE, 
sa.COLLECT_DATE_OF_SERVICE,  
sa.COLLECT_DATE_OF_DIS,
sa.EFFECTIVE_DATE as SA_EFFECTIVE_DATE,
sa.EXPIRATION_DATE as SA_EXPIRATION_DATE,

        RANK () OVER (
		PARTITION BY sar.SERVICE_AGREEMENT_ID
		ORDER BY sar.STAY_RANGE_START ASC
					  ) STAY_RANK
into #Inpatient_LOS_Rates					  
			from 
				SERVICE_AGREEMENT_RATE as sar
				inner JOIN SERVICE_AGREEMENT as sa 
				on sar.service_agreement_id = sa.service_agreement_id 
			where 			    
				    sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B';	


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

-- *******************************************************

			if object_id('TempDB..#FSInpatientRate', 'U') is not null DROP TABLE #FSInpatientRate;
	select *
	 INTO #FSInpatientRate
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
				and sar.RATE_TYPE_CD = 'IN'
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID = 9
				and x.PATIENT_DISPOSITION_ID in (2,3,4) 				
          ) as t; 


		  	UPDATE x
	SET x.FS_Inpatient_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #FSInpatientRate as t 
			ON x.chart_ID = t.chart_ID; 


-- *******************************************************

if object_id('TempDB..#Inpatient_LengthOfStay1', 'U') is not null DROP TABLE #Inpatient_LengthOfStay1;

	select *
	 INTO #Inpatient_LengthOfStay1
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =1
          ) as t; 


		 

		 UPDATE x
	SET x.Inpatient_LengthOfStay1_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay1 as t 
			ON x.chart_ID = t.chart_ID; 




-- ****


if object_id('TempDB..#Inpatient_LengthOfStay2', 'U') is not null DROP TABLE #Inpatient_LengthOfStay2;

	select *
	 INTO #Inpatient_LengthOfStay2
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =2
          ) as t; 

		  		 

		 UPDATE x
	SET x.Inpatient_LengthOfStay2_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay2 as t 
			ON x.chart_ID = t.chart_ID; 



-- ****


if object_id('TempDB..#Inpatient_LengthOfStay3', 'U') is not null DROP TABLE #Inpatient_LengthOfStay3;

	select *
	 INTO #Inpatient_LengthOfStay3
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =3
          ) as t; 



		 UPDATE x
	SET x.Inpatient_LengthOfStay3_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay3 as t 
			ON x.chart_ID = t.chart_ID; 



-- ****


if object_id('TempDB..#Inpatient_LengthOfStay4', 'U') is not null DROP TABLE #Inpatient_LengthOfStay4;

	select *
	 INTO #Inpatient_LengthOfStay4
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =4
          ) as t; 


		
		 UPDATE x
	SET x.Inpatient_LengthOfStay4_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay4 as t 
			ON x.chart_ID = t.chart_ID; 


-- ****


if object_id('TempDB..#Inpatient_LengthOfStay5', 'U') is not null DROP TABLE #Inpatient_LengthOfStay5;

	select *
	 INTO #Inpatient_LengthOfStay5
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =5
          ) as t; 


	
		 UPDATE x
	SET x.Inpatient_LengthOfStay5_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay5 as t 
			ON x.chart_ID = t.chart_ID; 


-- ****



if object_id('TempDB..#Inpatient_LengthOfStay6', 'U') is not null DROP TABLE #Inpatient_LengthOfStay6;

	select *
	 INTO #Inpatient_LengthOfStay6
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =6
          ) as t; 

		  		

		 UPDATE x
	SET x.Inpatient_LengthOfStay6_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay6 as t 
			ON x.chart_ID = t.chart_ID; 


-- ****


if object_id('TempDB..#Inpatient_LengthOfStay7', 'U') is not null DROP TABLE #Inpatient_LengthOfStay7;

	select *
	 INTO #Inpatient_LengthOfStay7
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =7
          ) as t; 



		 UPDATE x
	SET x.Inpatient_LengthOfStay7_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay7 as t 
			ON x.chart_ID = t.chart_ID; 



-- ****


if object_id('TempDB..#Inpatient_LengthOfStay8', 'U') is not null DROP TABLE #Inpatient_LengthOfStay8;

	select *
	 INTO #Inpatient_LengthOfStay8
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =8
          ) as t; 



		 UPDATE x
	SET x.Inpatient_LengthOfStay8_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay8 as t 
			ON x.chart_ID = t.chart_ID; 


-- ****


if object_id('TempDB..#Inpatient_LengthOfStay9', 'U') is not null DROP TABLE #Inpatient_LengthOfStay9;

	select *
	 INTO #Inpatient_LengthOfStay9
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =9
          ) as t; 


		 UPDATE x
	SET x.Inpatient_LengthOfStay9_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay9 as t 
			ON x.chart_ID = t.chart_ID; 



-- ****


if object_id('TempDB..#Inpatient_LengthOfStay10', 'U') is not null DROP TABLE #Inpatient_LengthOfStay10;

	select *
	 INTO #Inpatient_LengthOfStay10
	from
		(
select 
        x.chart_ID,
		sar.RATE -- 12/13/2023 DAH RACS-3296
		--case when sar.frequency = 1 then sar.RATE -- Length Of Stay
		--	 when sar.frequency = 0 then (( x.StayDayCnt - sar.STAY_RANGE_START) * sar.RATE ) -- Per Day
		--end  as RATE
			from 
				#Inpatient_LOS_Rates as sar,
				#PrelimResults as x					
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))  
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
				and sar.RATE_CLASS_CD = 'B'
				and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				and sar.COLLECT_DATE_OF_DIS = 'R'
				and x.StayDayCnt between sar.STAY_RANGE_START and sar.STAY_RANGE_END				
				and sar.STAY_RANK =10
          ) as t; 


		 UPDATE x
	SET x.Inpatient_LengthOfStay10_Rate = t.rate
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay10 as t 
			ON x.chart_ID = t.chart_ID; 

-- *******************************************************


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


-- *******************************************************
	

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



-- ***
-- Tenet_Rate 


if object_id('TempDB..#Tenet_Rate', 'U') is not null DROP TABLE #Tenet_Rate;	


 select  
  c.Chart_ID
 ,sar.RATE as Rate
 ,sart.description as RateType
 ,sar.RATE_TYPE_CD
INTO #Tenet_Rate 
 from #PrelimResults c,
 SERVICE_AGREEMENT_RATE as sar,
 SERVICE_AGREEMENT_RATE_TYPE sart
 where 
 c.service_agreement_id = sar.service_agreement_id
 and sar.rate_type_cd = sart.rate_type_cd
 and sar.RATE_CLASS_CD = 'B'
 and sar.RATE_TYPE_CD in ( 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'TO', 'TI' )
 and convert(varchar, c.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
 and convert(varchar, c.RATE_DATE, 112) <= sar.EXPIRATION_DATE
 and c.PatientClass not in ('OUTPATIENT',  'Edit', 'Denial') -- <> 'OUTPATIENT' 
 and c.PatientClass = substring(sart.description, 1, c.PCLength)
 and c.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
;

		 UPDATE x
	SET x.Tenet_Rate = t.Rate,
		x.Tenet_Rate_Type = t.RateType,
		x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_Rate as t 
			ON x.Chart_ID = t.Chart_ID; 



if object_id('TempDB..#Tenet_Rate_OP', 'U') is not null DROP TABLE #Tenet_Rate_OP;	


 select  
  c.Chart_ID
 ,sar.RATE as Rate
 ,sart.description as RateType
 ,sar.RATE_TYPE_CD
INTO #Tenet_Rate_OP 
 from #PrelimResults c,
 SERVICE_AGREEMENT_RATE as sar,
 SERVICE_AGREEMENT_RATE_TYPE sart
 where 
 c.service_agreement_id = sar.service_agreement_id
 and sar.rate_type_cd = sart.rate_type_cd
 and sar.RATE_CLASS_CD = 'B'
 and convert(varchar, c.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
 and convert(varchar, c.RATE_DATE, 112) <= sar.EXPIRATION_DATE
and c.PatientClass = 'OUTPATIENT'
and sart.rate_type_cd = 'T6'
and c.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer



		 UPDATE x
	SET x.Tenet_Rate = t.Rate,
		x.Tenet_Rate_Type = t.RateType,
		x.RATE_TYPE_CD    = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_Rate_OP as t 
			ON x.Chart_ID = t.Chart_ID; 





if object_id('TempDB..#Tenet_Rate_CB', 'U') is not null DROP TABLE #Tenet_Rate_CB;	


 select  
  c.Chart_ID
 ,sar.RATE as Rate
 ,sart.description as RateType
 ,sar.RATE_TYPE_CD
INTO #Tenet_Rate_CB 
 from #PrelimResults c,
 SERVICE_AGREEMENT_RATE as sar,
 SERVICE_AGREEMENT_RATE_TYPE sart
 where 
 c.service_agreement_id = sar.service_agreement_id
 and sar.rate_type_cd = sart.rate_type_cd
 and sar.RATE_CLASS_CD = 'B'

 and convert(varchar, c.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
 and convert(varchar, c.RATE_DATE, 112) <= sar.EXPIRATION_DATE

and c.PatientClass = 'Edit'
and sart.rate_type_cd = 'CB'
and c.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer



		 UPDATE x
	SET x.Tenet_Rate = t.Rate,
		x.Tenet_Rate_Type = t.RateType,
		x.RATE_TYPE_CD    = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_Rate_CB as t 
			ON x.Chart_ID = t.Chart_ID; 




if object_id('TempDB..#Tenet_Rate_DM', 'U') is not null DROP TABLE #Tenet_Rate_DM;	


 select  
  c.Chart_ID
 ,sar.RATE as Rate
 ,sart.description as RateType
 ,sar.RATE_TYPE_CD
INTO #Tenet_Rate_DM 
 from #PrelimResults c,
 SERVICE_AGREEMENT_RATE as sar,
 SERVICE_AGREEMENT_RATE_TYPE sart
 where 
 c.service_agreement_id = sar.service_agreement_id
 and sar.rate_type_cd = sart.rate_type_cd
 and sar.RATE_CLASS_CD = 'B'
 and convert(varchar, c.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
 and convert(varchar, c.RATE_DATE, 112) <= sar.EXPIRATION_DATE
and c.PatientClass = 'Denial'
and sart.rate_type_cd = 'DM'
and c.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer



		 UPDATE x
	SET x.Tenet_Rate = t.Rate,
		x.Tenet_Rate_Type = t.RateType,
		x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_Rate_DM as t 
			ON x.Chart_ID = t.Chart_ID; 

-- ****



if object_id('TempDB..#PatientClass_Rate', 'U') is not null DROP TABLE #PatientClass_Rate;	


 select  
  c.Chart_ID
 ,sar.RATE as Rate
 ,sart.description as RateType
 ,c.Patient_Class_ID
 ,sar.RATE_TYPE_CD
 INTO #PatientClass_Rate
 from #PrelimResults c,
 SERVICE_AGREEMENT_RATE as sar,
 SERVICE_AGREEMENT_RATE_TYPE sart
 where 
 c.service_agreement_id = sar.service_agreement_id
 and sar.rate_type_cd = sart.rate_type_cd
 and sar.RATE_CLASS_CD = 'B'

 and convert(varchar, c.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
 and convert(varchar, c.RATE_DATE, 112) <= sar.EXPIRATION_DATE



and c.Patient_Class_ID = sar.Patient_Class_ID
and sart.rate_type_cd = 'PC';



	UPDATE x
	SET x.PatientClass_Rate = t.Rate,
	    x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #PatientClass_Rate as t 
			ON x.Chart_ID = t.Chart_ID
			and x.Patient_Class_ID = t.Patient_Class_ID; 


--  select * from #PatientClass_Rate
 --select * from #PrelimResults


-- End of performance improvements from 1/5/2016
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------





if object_id('TempDB..#Temp1', 'U') is not null DROP TABLE #temp1;

select 																		
										    x.company_id,
											x.RATE_DATE,
											x.FACILITY_ID,
											x.SERVICE_MODEL_CD,
											x.EMR_SYSTEM,
											x.OBSERVATION_BILLING_METHOD_CD,
											x.PHYSICIAN_SERVICE_CLASS_CD,
											x.ED_Ind, 
											x.OBS_Ind, 
											x.SLA_RATE_METHOD_IND,
											x.RATE_TYPE_CD,
											x.CODED_BY_ID,
											x.CODER_USER_CLASS,
											x.OBS_CCS_User,
											x.OBS_Client_User,
											x.SERVICE_AGREEMENT_ID,

											x.CHART_ID,

											case 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
												when x.CODER_USER_CLASS = 4 then 0
												when x.Automation_Exclude = 1  then 0  
												else 1 end CCS, 
											case 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
												when x.CODER_USER_CLASS = 4 then 0 
												when x.CODER_USER_CLASS = 5 then 0
												when x.CODER_USER_CLASS = 1 and x.Automation = 0 and x.Automation_Exclude = 0 then 1 												
												else 0 end CCS_NonVendor, 
											case 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
												when x.CODER_USER_CLASS = 4 then 0 
												when x.CODER_USER_CLASS = 5 and x.Automation = 0 and x.Automation_Exclude = 0 then 1												
												else 0 end CCS_Vendor, 

											case 
												when x.BILL_PRO_FEE_IND = 1 then 1 else 0 end ProFee,										

											
                                            case 
												when x.CODER_USER_CLASS = 4 and x.Automation = 0 then 1 												
												when x.Automation_Exclude = 1  then 1                   
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 and x.Automation = 0 then 1												
												when x.SERVICE_MODEL_CD = 'ASP' and x.CODER_USER_CLASS is null and x.Automation = 0 then 1
												when x.SERVICE_MODEL_CD = 'ASP' and x.CODER_USER_CLASS = 4 and x.Automation = 0 then 1
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
												when x.CODER_USER_CLASS = 4 then 0
												when x.CODER_USER_CLASS <> 4 and x.SLA_HOURS = 0 then 0
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
											x.FS_Inpatient_Rate,
											x.SelfPay_Rate,
											x.EMIncrementRate,
											x.Inpatient_LengthOfStay1_Rate,
											x.Inpatient_LengthOfStay2_Rate,
											x.Inpatient_LengthOfStay3_Rate,
											x.Inpatient_LengthOfStay4_Rate,
											x.Inpatient_LengthOfStay5_Rate,
											x.Inpatient_LengthOfStay6_Rate,
											x.Inpatient_LengthOfStay7_Rate,
											x.Inpatient_LengthOfStay8_Rate,
											x.Inpatient_LengthOfStay9_Rate,
											x.Inpatient_LengthOfStay10_Rate,
											x.Tenet_Rate_Type,
											x.Tenet_Rate,	
											x.PatientClass_Rate,									

											x.REGION,
											x.[STATE],
											x.FACILITY_CLASSIFICATION,
											x.FACILITY_TYPE,
											x.ORGANIZATION_ID,		
									        x.PATIENT_DISPOSITION_ID,
											case when x.StayDayCnt > 120 then 1 else 0 end as StayDayCnt,

											x.AUTOMATION_CODING_ENABLED, 
											x.Automation,
											x.Automation_Rate,
                                            x.Automation_Exclude,
											
											case when (x.SERVICE_MODEL_CD <> 'ASP' OR x.AUTOMATION_CODING_ENABLED <> 1 OR x.CODER_USER_CLASS <> 4) AND x.Automation = 1  AND Automation_Exclude = 0  then 1 --and x.Automation_Rate = 1 then 1 											     
												 else 0
											 END as FS_Auto,

											case when x.SERVICE_MODEL_CD = 'ASP' AND x.AUTOMATION_CODING_ENABLED = 1 AND x.Automation = 1  AND Automation_Exclude = 0  AND x.CODER_USER_CLASS = 4  then 1 -- and x.Automation_Rate = 1     then 1 											     
											     when x.SERVICE_MODEL_CD = 'ASP' AND x.AUTOMATION_CODING_ENABLED = 1 AND x.Automation = 1  AND Automation_Exclude = 0  AND x.CODER_USER_CLASS IS NULL  then 1 -- and x.Automation_Rate = 1 then 1 											     
												 else 0
											 END as SaaS_Auto,							 

											

											(
												select case when count(*) > 0 then 'Y' else 'N' End
												from #Inpatient_LOS_Rates sar												
												where 
												sar.service_agreement_id = x.service_agreement_id
												and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
												and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
												and convert(varchar, x.RATE_DATE, 112) >= sar.SA_EFFECTIVE_DATE 
												and convert(varchar, x.RATE_DATE, 112) <= sar.SA_EXPIRATION_DATE												
												and sar.RATE_TYPE_CD = 'IL' -- Inpatient Length of Stay 
												and sar.RATE_CLASS_CD = 'B'
												and (sar.COLLECT_ARRIVAL_DATE = 'R' OR sar.COLLECT_ADMISSION_DATE = 'R' OR sar.COLLECT_DATE_OF_SERVICE = 'R') 
				                                and sar.COLLECT_DATE_OF_DIS = 'R'												
												and (x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20)) 
												) as Inpatient_LengthOfStay_IND

										into #temp1	
										from											
											(
												select * from #PrelimResults as t		-- new temp table
											) x


-- select * from #Temp1


-- ***********************************************

if object_id('TempDB..#Temp2', 'U') is not null DROP TABLE #temp2;

select 
								    y.company_id,
									y.RATE_DATE,
									y.FACILITY_ID,
									y.SERVICE_MODEL_CD,
									y.EMR_SYSTEM,
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
									y.RATE_TYPE_CD,


									case 
								when y.SLA_RATE <> 0 and y.SLA_RATE is not null and (y.SLA_RATE_METHOD_IND = 0 or y.SLA_RATE_METHOD_IND is null) 
								then y.SLA_RATE  -- SLA rate triggered and is a discount amount
								else round
									(
										(
											select sum(sar.RATE) 
											from SERVICE_AGREEMENT_RATE sar 
											where sar.SERVICE_AGREEMENT_ID = y.SERVICE_AGREEMENT_ID
												and sar.RATE_CLASS_CD = 'B'
												and   
												(
													sar.RATE_TYPE_CD in ('C')
													or (y.SelfPay_Rate <> 0 and y.SelfPay_Rate is not null and sar.RATE_TYPE_CD = '5')
												)
												and convert(varchar, y.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
												and convert(varchar, y.RATE_DATE, 112) <= sar.EXPIRATION_DATE
										) *
													--and   z.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE) * 
										(1 - 
											(
												case 
													when y.SLA_RATE <> 0 and y.SLA_RATE is not null and y.SLA_RATE_METHOD_IND = 1 
													then y.SLA_RATE/100 
													else 0 end
											)
										), 5
									) -- Reduce rate by SLA discount percent if triggered
								end CCSRate,


							(
								select sar.RATE 
								from SERVICE_AGREEMENT_RATE sar
								where 
									sar.SERVICE_AGREEMENT_ID = y.SERVICE_AGREEMENT_ID
									and sar.RATE_CLASS_CD = 'B'
									and sar.RATE_TYPE_CD = 'P'
									and convert(varchar, y.RATE_DATE, 112) >= sar.EFFECTIVE_DATE and convert(varchar, y.RATE_DATE, 112) <= sar.EXPIRATION_DATE
							) ProFeeRate,





									(
								select sum(sar.RATE) 
								from SERVICE_AGREEMENT_RATE sar
								where 
									sar.SERVICE_AGREEMENT_ID = y.SERVICE_AGREEMENT_ID
									and sar.RATE_CLASS_CD = 'B'
									and 
									(
										sar.RATE_TYPE_CD in ('S')
										or (y.MultiDept_Rate <> 0 and y.MultiDept_Rate is not null and sar.RATE_TYPE_CD = 'O')
										or (y.SelfPay_Rate <>0 and y.SelfPay_Rate is not null and sar.RATE_TYPE_CD = '6')
									)
									and convert(varchar, y.RATE_DATE, 112) >= sar.EFFECTIVE_DATE and convert(varchar, y.RATE_DATE, 112) <= sar.EXPIRATION_DATE

									and (y.SaaS > 0 or ( SaaS_Auto > 0 and Automation_Rate = 0))
							) SaaSRate,


							(
								select sum(sar.RATE) 
								from SERVICE_AGREEMENT_RATE sar
								where 
									sar.SERVICE_AGREEMENT_ID = y.SERVICE_AGREEMENT_ID
									and sar.RATE_CLASS_CD = 'B'
									and sar.RATE_TYPE_CD in ('SQ')																		
									and convert(varchar, y.RATE_DATE, 112) >= sar.EFFECTIVE_DATE and convert(varchar, y.RATE_DATE, 112) <= sar.EXPIRATION_DATE

									and y.SaaS_Auto > 0
							) SaaSAutoRate,
						
							(
								select sum(sar.RATE) 
								from SERVICE_AGREEMENT_RATE sar
								where 
									sar.SERVICE_AGREEMENT_ID = y.SERVICE_AGREEMENT_ID
									and sar.RATE_CLASS_CD = 'B'
									and sar.RATE_TYPE_CD = 'FA'								
									and convert(varchar, y.RATE_DATE, 112) >= sar.EFFECTIVE_DATE and convert(varchar, y.RATE_DATE, 112) <= sar.EXPIRATION_DATE
							) FSAutoRate,  

								    y.MultiDept_Rate,
									y.SelfPay_Rate,
									y.EMIncrementRate,
									y.Inpatient_LengthOfStay1_Rate,
									y.Inpatient_LengthOfStay2_Rate,
									y.Inpatient_LengthOfStay3_Rate,
									y.Inpatient_LengthOfStay4_Rate,
									y.Inpatient_LengthOfStay5_Rate,
									y.Inpatient_LengthOfStay6_Rate,
									y.Inpatient_LengthOfStay7_Rate,
									y.Inpatient_LengthOfStay8_Rate,
									y.Inpatient_LengthOfStay9_Rate,
									y.Inpatient_LengthOfStay10_Rate,
									y.Tenet_Rate_Type,
									y.Tenet_Rate,
									y.PatientClass_Rate,								
									y.FS_With_Obs_Rate,
									y.FS_Inpatient_Rate,
									y.SaaS_Obs_Only_Rate,
									y.CCS_Obs_Only_Rate,
									y.Saas_Obs_With_CCS_ED_Rate,       
							(y.CCS) TotCCS,
								    y.ORGANIZATION_ID,
									y.PATIENT_DISPOSITION_ID,
									y.StayDayCnt,
									y.Inpatient_LengthOfStay_IND,
							(y.FS_Auto) as Automation_FS, 
							(y.SaaS_Auto) as Automation_SaaS,
							(y.CCS_NonVendor) TotCCSNonVendor,
							(y.CCS_Vendor) TotCCSVendor,

							(y.ProFee) TotProFee,
							(y.SaaS) TotSaaS,
							(y.EMChart) TotEM,							
							1 as TotCharts,
									y.REGION,
									y.[STATE],
									y.FACILITY_CLASSIFICATION,
									y.FACILITY_TYPE,
									y.Automation_Rate,
							        y.Automation_Exclude

into #temp2	
from #Temp1 y


-- select * from #Temp2

-- ***********************************************

if object_id('TempDB..#Temp3', 'U') is not null DROP TABLE #temp3;


select	
						    z.company_id,
							z.FACILITY_ID,
							z.SERVICE_MODEL_CD,
							z.EMR_SYSTEM,
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
								when z.ORGANIZATION_ID = 9	and z.PATIENT_DISPOSITION_ID in (2,3,4) then 11 -- FS_Inpatient
								when z.Inpatient_LengthOfStay_IND = 'Y' then 12 -- Inpatient_LOS
								when z.company_id in (19, 298)  and (z.RATE_TYPE_CD like'T%' OR z.RATE_TYPE_CD in ('CB', 'DM') ) then 13 -- Tenet, Conifer Rates								 
								when z.RATE_TYPE_CD = 'PC' then 14 -- Patient Class Rates
								else 0 end Rate_Class,  -- Std Rate

							sum(z.TotCCS)TotCCS,
							sum(z.TotCCSNonVendor)TotCCSNonVendor,
							sum(z.TotCCSVendor)TotCCSVendor,
							sum(z.TotProFee)TotProFee, 
						    sum(z.TotSaaS)TotSaaS, 
							sum(z.TotEM)TotEM, 
						    sum(z.Automation_FS) Automation_FS,
						    sum(z.Automation_SaaS) Automation_SaaS, 
							sum(z.TotCharts)TotCharts, 
							
							CCSRate,
							ProFeeRate,							
							SaaSRate,
							SaaSAutoRate,							
							FSAutoRate,   
							 
							z.EMIncrementRate, 
							z.FS_With_Obs_Rate,
							z.FS_Inpatient_Rate,
							z.SaaS_Obs_Only_Rate, 
							z.CCS_Obs_Only_Rate, 
							z.Saas_Obs_With_CCS_ED_Rate,
							z.Inpatient_LengthOfStay1_Rate,
							z.Inpatient_LengthOfStay2_Rate,
							z.Inpatient_LengthOfStay3_Rate,
							z.Inpatient_LengthOfStay4_Rate,
							z.Inpatient_LengthOfStay5_Rate,
							z.Inpatient_LengthOfStay6_Rate,
							z.Inpatient_LengthOfStay7_Rate,
							z.Inpatient_LengthOfStay8_Rate,
							z.Inpatient_LengthOfStay9_Rate,
							z.Inpatient_LengthOfStay10_Rate,
							z.Tenet_Rate_Type,
							z.Tenet_Rate,	
							z.PatientClass_Rate,						
							z.StayDayCnt,
							z.REGION,
							z.[STATE],
							z.FACILITY_CLASSIFICATION,
							z.FACILITY_TYPE,
							z.Automation_Rate,
							z.Automation_Exclude,
							z.SERVICE_AGREEMENT_ID,
							z.RATE_DATE
into #temp3
						from #Temp2 z 
						group by 
						 z.company_id,
							z.FACILITY_ID,
							z.SERVICE_MODEL_CD,
							z.EMR_SYSTEM,
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
								when z.ORGANIZATION_ID = 9	and z.PATIENT_DISPOSITION_ID in (2,3,4) then 11 -- FS_Inpatient
								when z.Inpatient_LengthOfStay_IND = 'Y' then 12 -- Inpatient_LOS
								when z.company_id in (19, 298) and (z.RATE_TYPE_CD like'T%' OR z.RATE_TYPE_CD in ('CB', 'DM') ) then 13 -- Tenet, Conifer Rates								
								when z.RATE_TYPE_CD = 'PC' then 14 -- Patient Class Rates
								else 0 end, 

							
							
							CCSRate,
							ProFeeRate,							
							SaaSRate,
							SaaSAutoRate,							
							FSAutoRate,   
							 
							z.EMIncrementRate, 
							z.FS_With_Obs_Rate,
							z.FS_Inpatient_Rate,
							z.SaaS_Obs_Only_Rate, 
							z.CCS_Obs_Only_Rate, 
							z.Saas_Obs_With_CCS_ED_Rate,
							z.Inpatient_LengthOfStay1_Rate,
							z.Inpatient_LengthOfStay2_Rate,
							z.Inpatient_LengthOfStay3_Rate,
							z.Inpatient_LengthOfStay4_Rate,
							z.Inpatient_LengthOfStay5_Rate,
							z.Inpatient_LengthOfStay6_Rate,
							z.Inpatient_LengthOfStay7_Rate,
							z.Inpatient_LengthOfStay8_Rate,
							z.Inpatient_LengthOfStay9_Rate,
							z.Inpatient_LengthOfStay10_Rate,
							z.Tenet_Rate_Type,
							z.Tenet_Rate,	
							z.PatientClass_Rate,						
							z.StayDayCnt,
							z.REGION,
							z.[STATE],
							z.FACILITY_CLASSIFICATION,
							z.FACILITY_TYPE,
							z.Automation_Rate,
							z.Automation_Exclude,
							z.SERVICE_AGREEMENT_ID,
							z.RATE_DATE


-- select * from #temp3 where rate_class = 1


-- ***********************************************

if object_id('TempDB..#Temp4', 'U') is not null DROP TABLE #temp4;



select 
				    w.company_id,
					w.FACILITY_ID,
					w.SERVICE_MODEL_CD,
					w.EMR_SYSTEM,
					w.Rate_Class,
					
					sum(w.TotCCS)TotCCS, 
					sum(w.TotCCSNonVendor)TotCCSNonVendor,
					sum(w.TotCCSVendor)TotCCSVendor,
					sum(w.TotProFee)TotProFee,  
					sum(w.TotSaaS)TotSaaS,										
					sum(w.Automation_FS) as Automation_FS,
					sum(w.Automation_SaaS) as Automation_SaaS,
					case when w.EMIncrementRate > 0 then sum(w.TotEM) else 0 end TotEM,  
					sum(w.TotCharts)TotCharts,
					
					    
					case when w.Rate_Class IN (6,7,8) then 0 when w.Rate_Class = 11 then w.FS_Inpatient_Rate else isnull(w.CCSRate, 0) end CCSRate,
					case when w.SaaSRate is null OR w.Rate_Class = 9 then 0 else w.SaaSRate end SaaSRate,
					case when w.SaaSAutoRate is null then 0 else w.SaaSAutoRate end as SaaSAutoRate,

					case when w.Rate_Class = 1 and w.CCSRate > 0 then w.CCSRate    -- ************
					     when w.Rate_Class = 11 and w.FS_Inpatient_Rate > 0 then w.FS_Inpatient_Rate    -- ************
					     when w.FSAutoRate is null then 0 
						 else w.FSAutoRate end as FSAutoRate,

					

					case when w.ProFeeRate is null then 0 else w.ProFeeRate end ProFeeRate,
					case when w.EMIncrementRate is null then 0 else w.EMIncrementRate end EMIncrementRate,
					case when w.Rate_Class = 5  then isnull(w.FS_With_Obs_Rate, 0) else 0 end FS_With_Obs_Rate,
					case when w.FS_Inpatient_Rate is null then 0 else w.FS_Inpatient_Rate end as FS_Inpatient_Rate,
					case when (w.Rate_Class = 6 OR w.Rate_Class = 9 OR w.Rate_Class = 10) then isnull(w.SaaS_Obs_Only_Rate,0) else 0 end SaasObsOnlyRate, 
					case when w.Rate_Class = 8 then isnull(w.CCS_Obs_Only_Rate, 0) else 0 end  CCSObsOnlyRate,
					case when w.Rate_Class = 7 then isnull(w.Saas_Obs_With_CCS_ED_Rate,0) else 0 end Saas_Obs_With_CCS_ED_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay1_Rate, 0) else 0 end Inpatient_LengthOfStay1_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay2_Rate, 0) else 0 end Inpatient_LengthOfStay2_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay3_Rate, 0) else 0 end Inpatient_LengthOfStay3_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay4_Rate, 0) else 0 end Inpatient_LengthOfStay4_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay5_Rate, 0) else 0 end Inpatient_LengthOfStay5_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay6_Rate, 0) else 0 end Inpatient_LengthOfStay6_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay7_Rate, 0) else 0 end Inpatient_LengthOfStay7_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay8_Rate, 0) else 0 end Inpatient_LengthOfStay8_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay9_Rate, 0) else 0 end Inpatient_LengthOfStay9_Rate,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay10_Rate, 0) else 0 end Inpatient_LengthOfStay10_Rate,
					case when w.Rate_Class = 13 then isnull(w.Tenet_Rate, 0) else 0 end Tenet_Rate,
					case when w.Rate_Class = 14 then isnull(w.PatientClass_Rate, 0) else 0 end PatientClass_Rate,

					
					
					
					w.Tenet_Rate_Type,
					w.REGION,
					w.[STATE],
					w.FACILITY_CLASSIFICATION,
					w.FACILITY_TYPE
					
					into #temp4
					from  #temp3 w

					group by 
					w.company_id,
					w.FACILITY_ID,
					w.SERVICE_MODEL_CD,
					w.EMR_SYSTEM,
					w.Rate_Class,							
					w.EMIncrementRate,
					    
					case when w.Rate_Class IN (6,7,8) then 0 when w.Rate_Class = 11 then w.FS_Inpatient_Rate else isnull(w.CCSRate, 0) end ,
					case when w.SaaSRate is null OR w.Rate_Class = 9 then 0 else w.SaaSRate end,
					case when w.SaaSAutoRate is null then 0 else w.SaaSAutoRate end,
					case when w.Rate_Class = 1 and w.CCSRate > 0 then w.CCSRate    -- ************
					     when w.Rate_Class = 11 and w.FS_Inpatient_Rate > 0 then w.FS_Inpatient_Rate    -- ************
					     when w.FSAutoRate is null then 0 
						 else w.FSAutoRate end,

					case when w.ProFeeRate is null then 0 else w.ProFeeRate end ,
					case when w.EMIncrementRate is null then 0 else w.EMIncrementRate end ,
					case when w.Rate_Class = 5  then isnull(w.FS_With_Obs_Rate, 0) else 0 end ,
					case when w.FS_Inpatient_Rate is null then 0 else w.FS_Inpatient_Rate end ,
					case when (w.Rate_Class = 6 OR w.Rate_Class = 9 OR w.Rate_Class = 10) then isnull(w.SaaS_Obs_Only_Rate,0) else 0 end , 
					case when w.Rate_Class = 8 then isnull(w.CCS_Obs_Only_Rate, 0) else 0 end  ,
					case when w.Rate_Class = 7 then isnull(w.Saas_Obs_With_CCS_ED_Rate,0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay1_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay2_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay3_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay4_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay5_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay6_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay7_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay8_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay9_Rate, 0) else 0 end ,
					case when w.Rate_Class = 12 then isnull(w.Inpatient_LengthOfStay10_Rate, 0) else 0 end ,
					case when w.Rate_Class = 13 then isnull(w.Tenet_Rate, 0) else 0 end ,
					case when w.Rate_Class = 14 then isnull(w.PatientClass_Rate, 0) else 0 end, 
					
					
					w.Tenet_Rate_Type,
					w.REGION,
					w.[STATE],
					w.FACILITY_CLASSIFICATION,
					w.FACILITY_TYPE

 -- select * from #temp4

-- ***********************************************

if object_id('TempDB..#Temp5', 'U') is not null DROP TABLE #temp5;


			select 
			sa.ORGANIZATION_ID,
			o.[DESCRIPTION] [ORGANIZATION],
			v.company_id,
			f.FACILITY_ID,
			v.SERVICE_MODEL_CD,
			v.EMR_SYSTEM,
			isnull(nullif(f.ACCOUNTING_FACILITY_CODE, ''), f.FACILITY_NUMBER) Facility,
			f.NAME FacilityName,
			v.Rate_Class,
			v.CCSRate,
			v.ProFeeRate,
			v.SaaSRate,
			v.SaaSAutoRate,
			v.FSAutoRate,
			v.EMIncrementRate,
			v.FS_With_Obs_Rate,
			v.FS_Inpatient_Rate,
			v.SaasObsOnlyRate,
			v.CCSObsOnlyRate,
			v.Saas_Obs_With_CCS_ED_Rate,
			v.Inpatient_LengthOfStay1_Rate,
			v.Inpatient_LengthOfStay2_Rate,
			v.Inpatient_LengthOfStay3_Rate,
			v.Inpatient_LengthOfStay4_Rate,
			v.Inpatient_LengthOfStay5_Rate,
			v.Inpatient_LengthOfStay6_Rate,
			v.Inpatient_LengthOfStay7_Rate,
			v.Inpatient_LengthOfStay8_Rate,
			v.Inpatient_LengthOfStay9_Rate,
			v.Inpatient_LengthOfStay10_Rate,
			v.Tenet_Rate_Type,
			v.Tenet_Rate,	
			v.PatientClass_Rate,
			sum(v.TotCCS) TotCCS,
			sum(v.TotCCSNonVendor) as TotCCSNonVendor ,
			sum(v.TotCCSVendor) TotCCSVendor,
			sum(v.TotSaaS) TotSaaS,
			SUM(v.TotEM) TotEM,
			sum(v.Automation_FS) as TotAuto_FS,
			sum(v.Automation_SaaS) as TotAuto_SaaS,
			sum(v.TotCharts) TotCharts, 
			SUM(v.TotProFee) TotProFee,

			round(sum(v.TotCCSNonVendor) * v.Tenet_Rate, 2)  as Tenet_TOTNonVenRev, -- separated because of multi rates
            round(sum(v.TotCCSVendor) * v.Tenet_Rate, 2)     as Tenet_TOTVenRev, 	-- separated because of multi rates	

			v.REGION,
			v.[STATE],
			v.FACILITY_CLASSIFICATION,
			v.FACILITY_TYPE
			into #temp5
			from  
			#temp4 v,
			FACILITY f 
			inner join SERVICE_AGREEMENT sa on f.FACILITY_ID = sa.FACILITY_ID
			inner join ORGANIZATION o on sa.ORGANIZATION_ID = o.ORGANIZATION_ID
			where v.Facility_ID = f.FACILITY_ID
			group by 
			sa.ORGANIZATION_ID,
			o.[DESCRIPTION], 
			v.company_id,
			f.FACILITY_ID,
			v.SERVICE_MODEL_CD,
			v.EMR_SYSTEM,
			isnull(nullif(f.ACCOUNTING_FACILITY_CODE, ''), f.FACILITY_NUMBER) ,
			f.NAME ,
			v.Rate_Class,
			v.CCSRate,
			v.ProFeeRate,
			v.SaaSRate,
			v.SaaSAutoRate,
			v.FSAutoRate,
			v.EMIncrementRate,
			v.FS_With_Obs_Rate,
			v.FS_Inpatient_Rate,
			v.SaasObsOnlyRate,
			v.CCSObsOnlyRate,
			v.Saas_Obs_With_CCS_ED_Rate,
			v.Inpatient_LengthOfStay1_Rate,
			v.Inpatient_LengthOfStay2_Rate,
			v.Inpatient_LengthOfStay3_Rate,
			v.Inpatient_LengthOfStay4_Rate,
			v.Inpatient_LengthOfStay5_Rate,
			v.Inpatient_LengthOfStay6_Rate,
			v.Inpatient_LengthOfStay7_Rate,
			v.Inpatient_LengthOfStay8_Rate,
			v.Inpatient_LengthOfStay9_Rate,
			v.Inpatient_LengthOfStay10_Rate,
			v.Tenet_Rate_Type,
			v.Tenet_Rate,	
			v.PatientClass_Rate,
			v.REGION,
			v.[STATE],
			v.FACILITY_CLASSIFICATION,
			v.FACILITY_TYPE

			
			
			
-- ***********************************************			
			
			
			
			
		select 
	u.ORGANIZATION_ID,
	u.ORGANIZATION,
	(select name from company with (NOLOCK) where company_id = u.company_id) as ParentCompany,
	(select description from service_model where SERVICE_MODEL_CD = u.SERVICE_MODEL_CD) as ServiceModel,
	u.Facility,
	u.Facility_ID,
	u.FacilityName,
	u.Rate_Class 'Rate Class',

	u.REGION,
	u.[STATE],
	u.FACILITY_TYPE,
	u.FACILITY_CLASSIFICATION,
	u.EMR_SYSTEM,
    

	case when u.Rate_Class = 14 then 0 else u.CCSRate end 'CCS Rate',
	u.FS_With_Obs_Rate 'FS with Obs Increment',   
	u.ProFeeRate 'Pro-Fee Rate',
	u.EMIncrementRate 'E&M Increment rate',
	u.CCSObsOnlyRate 'CCS Obs Only (Direct to Obs)',
	u.Tenet_Rate_Type,
	u.Tenet_Rate,	
	u.PatientClass_Rate,

	u.TotCCSNonVendor as  TotCCSNonVendor,
	u.TotCCSVendor as TotCCSVendor,
    
    u.TotSaaS 'SaaS Count',

    
	u.TotAuto_FS as 'Total FS Auto Count',
	u.TotAuto_SaaS as 'Total SaaS Auto Count',
    u.TotCharts 'Total Count',	





	
	round(u.TotCCSNonVendor * u.CCSObsOnlyRate, 2) + 
	round(u.TotCCSNonVendor * u.FS_With_Obs_Rate, 2) + round((u.TotProFee + TotCCSNonVendor ) * u.ProFeeRate, 2) + 
	round(u.TotCCSNonVendor  * u.Saas_Obs_With_CCS_ED_Rate, 2) + round(u.TotEM * u.EMIncrementRate, 2) +
	round(u.TotCCSNonVendor * (u.Inpatient_LengthOfStay1_Rate + u.Inpatient_LengthOfStay2_Rate + u.Inpatient_LengthOfStay3_Rate
	     + u.Inpatient_LengthOfStay4_Rate + u.Inpatient_LengthOfStay5_Rate + u.Inpatient_LengthOfStay6_Rate
		 + u.Inpatient_LengthOfStay7_Rate + u.Inpatient_LengthOfStay8_Rate + u.Inpatient_LengthOfStay9_Rate
		 + u.Inpatient_LengthOfStay10_Rate ) , 2) 
		  + round(case when u.PatientClass_Rate > 0 then u.PatientClass_Rate else u.CCSRate end * u.TotCCSNonVendor, 2 ) +
         + u.Tenet_TOTNonVenRev -- Tenet is calculated in table V below	
		 as TOTNonVenRev ,
	
	     
		   round(u.TotCCSVendor * u.CCSObsOnlyRate, 2) + ROUND(u.TotCCSVendor * u.FS_With_Obs_Rate, 2) + 
	       round((u.TotProFee + u.TotCCSVendor) * u.ProFeeRate, 2) +round(u.TotCCSVendor * u.Saas_Obs_With_CCS_ED_Rate, 2)
	     + round(u.TotCCSVendor * (u.Inpatient_LengthOfStay1_Rate + u.Inpatient_LengthOfStay2_Rate + u.Inpatient_LengthOfStay3_Rate
	     + u.Inpatient_LengthOfStay4_Rate + u.Inpatient_LengthOfStay5_Rate + u.Inpatient_LengthOfStay6_Rate
		 + u.Inpatient_LengthOfStay7_Rate + u.Inpatient_LengthOfStay8_Rate + u.Inpatient_LengthOfStay9_Rate
		 + u.Inpatient_LengthOfStay10_Rate ) , 2) 
		 + round(case when u.PatientClass_Rate > 0 then u.PatientClass_Rate else u.CCSRate end * u.TotCCSVendor, 2 ) +
         + u.Tenet_TOTVenRev   -- Tenet is calculated in table V below
		 as TOTVenRev ,


	
round(u.TotSaaS * u.SaaSRate, 2) + round(u.TotSaaS * u.SaasObsOnlyRate, 2) + round(u.TotSaaS * SaaSAutoRate, 2) as TOTSaaSRev,


round(case when u.SaaSAutoRate > 0 then u.SaaSAutoRate else u.SaaSRate end * u.TotAuto_SaaS, 2 ) + round(u.TotAuto_SaaS * u.SaasObsOnlyRate, 2) as 'Total SaaS Auto Rev', 





round(case when u.FSAutoRate > 0 then u.FSAutoRate else u.CCSRate end * u.TotAuto_FS, 2 ) +
round(u.TotAuto_FS * u.FS_With_Obs_Rate, 2) + 
round(u.TotAuto_FS * u.ProFeeRate, 2) + 
round(u.TotAuto_FS * u.SaasObsOnlyRate, 2) + 
round(u.TotAuto_FS * u.Saas_Obs_With_CCS_ED_Rate, 2) + 
round(u.TotAuto_FS * u.CCSObsOnlyRate, 2) + 
round(u.TotAuto_FS * u.EMIncrementRate, 2) +
round(u.TotAuto_FS * u.PatientClass_Rate, 2) as 'Total FS Auto Rev',







round((u.TotCCSNonVendor + u.TotCCSVendor) * u.FS_With_Obs_Rate, 2) + 
round((u.TotProFee + TotCCSNonVendor + u.TotCCSVendor) * u.ProFeeRate, 2) + 
round(u.TotSaaS * u.SaaSRate, 2) + round(u.TotSaaS * u.SaasObsOnlyRate, 2) + round(u.TotSaaS * SaaSAutoRate, 2) +
round((u.TotCCSNonVendor + u.TotCCSVendor) * u.Saas_Obs_With_CCS_ED_Rate, 2) + 
round((u.TotCCSNonVendor + u.TotCCSVendor) * u.CCSObsOnlyRate, 2)   + 
round(u.TotEM * u.EMIncrementRate, 2) + 
round(case when u.FSAutoRate > 0 then u.FSAutoRate else u.CCSRate end * u.TotAuto_FS, 2 ) +
round(u.TotAuto_FS * u.FS_With_Obs_Rate, 2) + 
round(u.TotAuto_FS * u.ProFeeRate, 2) + 
round(u.TotAuto_FS * u.SaasObsOnlyRate, 2) + 
round(u.TotAuto_FS * u.Saas_Obs_With_CCS_ED_Rate, 2) + 
round(u.TotAuto_FS * u.CCSObsOnlyRate, 2)   + 
round(u.TotAuto_FS * u.EMIncrementRate, 2) + --round(u.TotAuto_FS * u.FSAutoRate, 2) +
round(u.TotCCSVendor * (u.Inpatient_LengthOfStay1_Rate + u.Inpatient_LengthOfStay2_Rate + u.Inpatient_LengthOfStay3_Rate
	     + u.Inpatient_LengthOfStay4_Rate + u.Inpatient_LengthOfStay5_Rate + u.Inpatient_LengthOfStay6_Rate
		 + u.Inpatient_LengthOfStay7_Rate + u.Inpatient_LengthOfStay8_Rate + u.Inpatient_LengthOfStay9_Rate
		 + u.Inpatient_LengthOfStay10_Rate ) , 2) +
round(u.TotCCSNonVendor * (u.Inpatient_LengthOfStay1_Rate + u.Inpatient_LengthOfStay2_Rate + u.Inpatient_LengthOfStay3_Rate
	     + u.Inpatient_LengthOfStay4_Rate + u.Inpatient_LengthOfStay5_Rate + u.Inpatient_LengthOfStay6_Rate
		 + u.Inpatient_LengthOfStay7_Rate + u.Inpatient_LengthOfStay8_Rate + u.Inpatient_LengthOfStay9_Rate
		 + u.Inpatient_LengthOfStay10_Rate ) , 2)  
 + round(case when u.SaaSAutoRate > 0 then u.SaaSAutoRate else u.SaaSRate end * u.TotAuto_SaaS, 2 ) + round(u.TotAuto_SaaS * u.SaasObsOnlyRate, 2)
 + u.Tenet_TOTNonVenRev + u.Tenet_TOTVenRev  -- Tenet is calculated in table V below
 + round(case when u.PatientClass_Rate > 0 then u.PatientClass_Rate else u.CCSRate end * (u.TotCCSNonVendor + u.TotCCSVendor), 2 ) 

as 'Total Billed'

			from #temp5 u


    END






GO
GRANT EXECUTE ON  [dbo].[BILLING_SUMMARY_BY_FACILITY_FINANCE] TO [dbx_ExecuteReportProcs]
GO
