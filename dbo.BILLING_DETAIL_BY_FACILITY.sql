SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE procedure [dbo].[BILLING_DETAIL_BY_FACILITY]
    @billingPeriod int
    ,@facilityID   int
with recompile
as
begin




-- test paramters ****
   --declare 
   --      @billingPeriod int = 227  -- 227 Oct/2024
		 --,@facilityID int = 1184



		
		                           

    declare @P_billingPeriod int;
    declare @P_facilityID int;
    set @P_billingPeriod = @billingPeriod;
    set @P_facilityID = @facilityID;

    -- new temp tables
    if object_id('TempDB..#PrelimResults', 'U') is not null
    begin
        drop table #PrelimResults;
    end;

    if object_id('TempDB..#CompletionDates', 'U') is not null
    begin
        drop table #CompletionDates;
    end;





    select
        *
    into
        #PrelimResults -- new temp table for tuning (to support breaking out the complex CASE statements of subquery X in order to eliminate blocking)
    from
    (
        select
             c.FACILITY_ID
            ,sa.COMPANY_ID
            ,c.SERVICE_AGREEMENT_ID
			,sa.ORGANIZATION_ID
			,sa.SERVICE_MODEL_CD
			,sa.AUTOMATION_CODING_ENABLED
			,c.FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME
		    ,c.PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME
		    ,case when c.FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL
			 or c.PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL then 1 else 0 end as Automation
            ,c.OBSERVATION_BILLING_METHOD_CD
			,c.PATIENT_DISPOSITION_ID
			,c.PATIENT_CLASS_ID
			, PatientClass = cast(null as varchar(50))
			, PCLength = cast(null as int)
            ,(
                 select
                     pcl.PHYSICIAN_SERVICE_CLASS_CD
                 from
                     PATIENT_CLASS pcl
                 where
                     pcl.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
             )                                       as PHYSICIAN_SERVICE_CLASS_CD
            
			
			, sa.RATE_METHOD_CD   
			,case
                 when sa.RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
                 when sa.RATE_METHOD_CD = 2 then c.SENT_DATE
			  else bctl.END_DATE end                  RATE_DATE
			 
            ,c.CHART_ID
            ,case
                 when sa.BILL_PRO_FEE_METHOD_CD = 1
                      and c.CHART_ID in
                          (
                              select
                                  sp.chart_id
                              from
                                  SENT_PROCEDURE sp with (nolock)
                              where
                                  c.CHART_ID = sp.chart_id
                                  and sp.class in ('PL', 'PP')
                          ) then 1
             else 0 end                              BILL_PRO_FEE_IND
            ,case
                 when sa.BILL_CODER_METHOD_CD = 1
                      and c.CHART_ID in
                          (
                              select
                                  ln.CHART_ID
                              from
                                  LOG_NOTE ln with (nolock)
                              where
                                  c.CHART_ID = ln.CHART_ID
                                  and ln.CATEGORY_ID = 2
                          ) then
                 (
                     select
                         ln.CREATING_USER_PROFILE_ID
                     from
                         LOG_NOTE ln with (nolock)
                     where
                         ln.CHART_ID = c.CHART_ID
                         and ln.CATEGORY_ID = 2
                         and ln.LOG_NOTE_ID =
                         (
                             select
                                 min(ln2.LOG_NOTE_ID)
                             from
                                 LOG_NOTE ln2 with (nolock)
                             where
                                 ln2.CHART_ID = c.CHART_ID
                                 and ln2.CATEGORY_ID = 2
                         )
                 )
             else c.COMPLETED_BY_USER_PROFILE_ID end CODED_BY_ID
             ,CODER_USER_CLASS = cast(null as int)

            ,c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID	
            ,case
                 when c.PATIENT_DISPOSITION_ID <> 5 then 1
                 when c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID =
                 (
                     select
                         sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
                     from
                         SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao
                     where
                         sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 1
                         and sao.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                 ) then 1
             else 0 end                              ED_Ind
            ,case
                 when c.INITIAL_CHARGE_MASTER_DEPT_ID is null then 0
                 when c.INITIAL_CHARGE_MASTER_DEPT_ID = -1 then 0
                 when c.INITIAL_CHARGE_MASTER_DEPT_ID = 0 then 0
                 when c.INITIAL_CHARGE_MASTER_DEPT_ID is not null
                      and c.INITIAL_CHARGE_MASTER_DEPT_ID <> -1
                      and c.INITIAL_CHARGE_MASTER_DEPT_ID <> 0
                      and
                      (
                          select distinct
                              1
                          from
                              CHARGE_MASTER_DEPARTMENT cmd
                          where
                              cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
                              and c.TIME_OF_DIS not between cmd.EFFECTIVE_DATE and cmd.EXPIRATION_DATE
                      ) = 1 then 0
             else 1 end                              OBS_Ind
            ,case
                 when
                 (
                     select distinct
                         1
                     from
                         USER_PROFILE up
                     where
                         up.USER_PROFILE_ID = c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID
                         and up.USER_CLASS_CD = 4
                 ) = 1 then 1
             else 0 end                              OBS_Client_User
            ,case
                 when c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = -1
                      and sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1
                      and c.PATIENT_DISPOSITION_ID = 5 then 1
             else 0 end                              OBS_CCS_User
            ,case
                 when
                 (
                     select distinct
                         'Y'
                     from
                         LOG_NOTE ln with (nolock)
                     where
                         ln.CHART_ID = c.CHART_ID
                         and ln.CATEGORY_ID = 6
                 ) = 'Y' then 'Y'
             else 'N' end                            Pended
            ,sa.SLA_RATE_METHOD_IND
            
            ,sa.TURNAROUND_HOURS_REPORTING_METHOD
            ,sa.TURNAROUND_START_TIME_IN_MINUTES
            ,c.CREATION_DATE_TIME
            ,c.SENT_DATE
            ,c.APPROVED_DATE
            ,c.DATE_RECEIVED
            ,c.FACILITY_CHART_ID
            ,c.PATIENT_LAST_NAME
            ,c.PATIENT_FIRST_NAME
            ,c.TIME_OF_SERVICE
            ,cmd.NAME                                as Dept_Name
            ,sa.SLA_HOURS                            MAX_SLA_HOURS
			,c.CLINIC_ID
			,c.FINANCIAL_CLASS_CD
			, c.facility_level_ID
		    , c.OVERRIDE_FACILITY_LEVEL_ID
			,c.LONG_PATIENT_ID2
			,cast(c.arrival_date_time as date) as Arrival_Date
			,cast(c.ADMISSION_DATE_TIME as date) as Admission_Date			
			,cast(c.time_of_dis as date) as Dis_Date	
			,case when c.arrival_date_time is not null then (datediff(day, cast(c.arrival_date_time as date) ,cast(c.time_of_dis as date)) +1)
			      when c.ADMISSION_DATE_TIME is not null then (datediff(day, cast(c.ADMISSION_DATE_TIME as date) ,cast(c.time_of_dis as date)) +1)
				  else (datediff(day, cast(c.TIME_OF_SERVICE as date) ,cast(c.time_of_dis as date)) +1)
			 end as StayDayCnt
			 , SaaS_Obs_Only_Rate = cast(null as money)
			 , SaaS_Obs_With_CCS_ED_Rate = cast(null as money)
			 , CCS_Obs_Only_Rate = cast(null as money)
			 , FS_With_Obs_Rate = cast(null as money)
			 , PatientClass_Rate = cast(null as money)
			 , MultiDept_Rate = cast(null as money)
			 , FS_Inpatient_Rate = cast(null as money)
			 , SelfPay_Rate = cast(null as money)
			 , EMIncrementRate = cast(null as money)

			 , Inpatient_LengthOfStay_IND   = cast(null as varchar(1))
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

			 , Tenet_MultiRate_IND = cast(null as varchar(1))
			 , Tenet_MultiRate1_Rate = cast(null as money)
			 , Tenet_MultiRate2_Rate = cast(null as money)
			 , Tenet_MultiRate3_Rate = cast(null as money)
			 , Tenet_MultiRate4_Rate = cast(null as money)
			 , Tenet_MultiRate5_Rate = cast(null as money)
			 , Tenet_MultiRate6_Rate = cast(null as money)
			 , Tenet_MultiRate7_Rate = cast(null as money)
			 , Tenet_MultiRate8_Rate = cast(null as money)
			 , Tenet_MultiRate9_Rate = cast(null as money)
			 , Tenet_MultiRate10_Rate = cast(null as money)
			 , Tenet_MultiRate11_Rate = cast(null as money)

			 ,Tenet_Claim_Rate = cast(null as money)
			 ,Tenet_Denial_Rate = cast(null as money)


			 ,RATE_TYPE_CD = cast(null as varchar(2))
			 ,IncrementRate_TYPE_CD = cast(null as varchar(2))
			 ,Automation_Rate_Ind = cast(0 as int)
			 ,Automation_Exclude = cast(0 as int)
        from
        BILLED_CHART         bc with (nolock) 
        inner join
        CHART                      c with (nolock) on c.CHART_ID = bc.CHART_ID 
        inner join
        BILLING_CONTROL          bctl with (nolock) on bctl.BILLING_CONTROL_ID = bc.BILLING_CONTROL_ID 
        inner join
        SERVICE_AGREEMENT        sa with (nolock) on sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
        left outer join
        CHARGE_MASTER_DEPARTMENT cmd with (nolock) on cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
        where
        bctl.BILLING_CONTROL_ID = @P_billingPeriod   
        and bc.TYPE_CD = 'B'						
        and c.FACILITY_ID = @P_facilityID
        and sa.DEMO_TEST_SITE_IND <> 1
		and sa.company_id not in (196, 134, 223, 19, 298) -- 03/19/2025 RAP-929 DAH - exclude MultiCare Health System,  04/23/25 RAP-1014 DAH exclude R1 Ascension, 05/21/25 RAP-1094 Exclude Tenet, Conifer 
				

    ) as t;



--  select * from #PrelimResults 



-- Note: BILLED_CHART table created by stored procedure "BILLING_EXTRACT_CREATE"

	UPDATE x
	SET x.PatientClass = pc.description,
	    x.PCLength = len(pc.description)
	FROM 	
	#PrelimResults as x
	join PATIENT_CLASS as pc 
	ON x.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID;

	UPDATE x
	SET x.CODER_USER_CLASS = t.USER_CLASS_CD
	FROM 
	#PrelimResults as x
	join USER_PROFILE as t 
	ON x.CODED_BY_ID = t.USER_PROFILE_ID;

	
	UPDATE x
	SET x.Automation_Rate_Ind = 1
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


 

if object_id('TempDB..#LogNote1', 'U') is not null DROP TABLE #LogNote1;

select 
ln.CHART_ID
        ,ln.COMPLETION_DATE
        ,ln.CATEGORY_ID
        ,ln.SUMMARY
        ,ln.DETAIL
into #LogNote1
from LOG_NOTE   as ln
where chart_id in ( select chart_id from #PrelimResults 
                    where TURNAROUND_HOURS_REPORTING_METHOD in (6, 7) )
and ln.CATEGORY_ID IN ( 5, 8); 
 

    -- new temp table for tuning
    select
        ln.CHART_ID
        ,ln.COMPLETION_DATE
        ,ln.CATEGORY_ID
        ,summary = left(ln.SUMMARY, 68)
        ,detail  = left(ln.DETAIL, 68)
    into
        #CompletionDates
    from
        #LogNote1   as ln with (nolock)
    inner join
    #PrelimResults as t on t.CHART_ID = ln.CHART_ID
                           and t.TURNAROUND_HOURS_REPORTING_METHOD in (6, 7)
    where
        (
            ln.CATEGORY_ID = 8 -- Chart status changed
            and
            (
                left(ln.SUMMARY, 40) = 'Chart status changed to Work in Progress'
                or left(ln.DETAIL, 40) = 'Chart status changed to Work in Progress'
            )
        )
        or
        (
            ln.CATEGORY_ID = 5 -- Chart opened
            and ln.DETAIL like 'Chart status moved to work in progress.  Previous status was Pending%'
        );


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
				and sar.RATE_CLASS_CD = 'B'


-- *****


if object_id('TempDB..#SaaSObsOnlyRate', 'U') is not null DROP TABLE #SaaSObsOnlyRate;
	select *
	 INTO #SaaSObsOnlyRate
	from
		(
			select 
				x.chart_ID
				,sar.RATE
				,sar.RATE_TYPE_CD
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
				x.chart_ID
				,SumRate = sum(sar.RATE) 
				,sar.RATE_TYPE_CD
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
				group by x.chart_ID, sar.RATE_TYPE_CD	

		) as t



	UPDATE x
	SET x.SaaS_Obs_Only_Rate = t.rate
	    ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #SaaSObsOnlyRate as t 
			ON x.chart_ID = t.chart_ID

-- *****

if object_id('TempDB..#SaaSObsWithCCSEDRate', 'U') is not null DROP TABLE #SaaSObsWithCCSEDRate;
	select *
	 INTO #SaaSObsWithCCSEDRate
	from
		(
			select
				x.chart_ID
				,SumRate = sum(sar.RATE) 
				,sar.RATE_TYPE_CD
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
			group by x.chart_ID, sar.RATE_TYPE_CD							
		) as t



	UPDATE x
	SET x.SaaS_Obs_With_CCS_ED_Rate = t.SumRate
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #SaaSObsWithCCSEDRate as t 
			ON x.chart_ID = t.chart_ID


-- *****

if object_id('TempDB..#CCSObsOnlyRate', 'U') is not null DROP TABLE #CCSObsOnlyRate;
	select *
	 INTO #CCSObsOnlyRate
	from
		(				-- 95M reads
			select 
				x.chart_ID
				,sar.RATE
				,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #CCSObsOnlyRate as t 
			ON x.chart_ID = t.chart_ID


-- *****


if object_id('TempDB..#FSWithObsRate', 'U') is not null DROP TABLE #FSWithObsRate;
	select *
	 INTO #FSWithObsRate
	from
		(
			select 
				 x.chart_ID
				,sar.RATE 
				,sar.RATE_TYPE_CD
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
				x.chart_ID
				,sar.RATE 
				,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #FSWithObsRate as t 
			ON x.chart_ID = t.chart_ID

-- select * from #FSWithObsRate

-- *****

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

-- *****

	if object_id('TempDB..#FSInpatientRate', 'U') is not null DROP TABLE #FSInpatientRate;

	select *
	 INTO #FSInpatientRate
	from
		(
           select 
				x.chart_ID
				,sar.RATE
				,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #FSInpatientRate as t 
			ON x.chart_ID = t.chart_ID; 


		
-- ****

if object_id('TempDB..#SelfPayRate', 'U') is not null DROP TABLE #SelfPayRate;
	select *
		INTO #SelfPayRate
	from
		(
			select 
				x.chart_ID
			   ,sar.RATE 
			   ,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #SelfPayRate as t 
			ON x.chart_ID = t.chart_ID


-- ****


if object_id('TempDB..#EMIncrementRate', 'U') is not null DROP TABLE #EMIncrementRate;
	select *
	 INTO #EMIncrementRate
	from
		(
			select 
				x.chart_ID
				,sar.RATE 
				,sar.RATE_TYPE_CD
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
				x.chart_ID
				,sar.RATE 
				,sar.RATE_TYPE_CD
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
	   ,x.IncrementRate_TYPE_CD  = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #EMIncrementRate as t 
			ON x.chart_ID = t.chart_ID

 -- select * from #EMIncrementRate

-- ****

if object_id('TempDB..#MultiDeptRate', 'U') is not null DROP TABLE #MultiDeptRate;

	select *
	 INTO #MultiDeptRate
	from
		(
			select 
				x.chart_ID
				,sar.RATE 
				,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #MultiDeptRate as t 
			ON x.chart_ID = t.chart_ID

-- ****

if object_id('TempDB..#Inpatient_LengthOfStay_IND', 'U') is not null DROP TABLE #Inpatient_LengthOfStay_IND;

	select *
	 INTO #Inpatient_LengthOfStay_IND
	from
		(
select 
         x.chart_ID,
		(select case when count(*) > 0 then 'Y' else 'N' End) as Inpatient_LengthOfStay_IND
		
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
				and ( x.PATIENT_DISPOSITION_ID in (2,3,4,5) OR x.PHYSICIAN_SERVICE_CLASS_CD in (7,8,9,10,16,17,18,19,20))	
				
				
          ) as t; 


		 

	UPDATE x
	SET x.Inpatient_LengthOfStay_IND = t.Inpatient_LengthOfStay_IND
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay_IND as t 
			ON x.chart_ID = t.chart_ID; 



-- ****

if object_id('TempDB..#Inpatient_LengthOfStay1', 'U') is not null DROP TABLE #Inpatient_LengthOfStay1;

	select *
	 INTO #Inpatient_LengthOfStay1
	from
		(
select 
        x.chart_ID
		,sar.RATE
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE 
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE 
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE 
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE 
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE 
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE 
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
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
        x.chart_ID
		,sar.RATE 
		,sar.RATE_TYPE_CD
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
	   ,x.RATE_TYPE_CD      = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Inpatient_LengthOfStay10 as t 
			ON x.chart_ID = t.chart_ID; 


-- ******

if object_id('TempDB..#Tenet_MultiRate_IND', 'U') is not null DROP TABLE #Tenet_MultiRate_IND;

	select *
	 INTO #Tenet_MultiRate_IND
	from
		(

select 
			 x.chart_ID,
			(case when count(*) > 0 then 'Y' else 'N' End) as Tenet_MultiRate_IND
			
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD in ( 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'TO', 'TI' )
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
			group by x.chart_id	
) as Tenet_MultiRate_IND


		 UPDATE x
	SET x.Tenet_MultiRate_IND = t.Tenet_MultiRate_IND	   
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate_IND as t 
			ON x.chart_ID = t.chart_ID; 




-- ******

if object_id('TempDB..#Tenet_MultiRate1', 'U') is not null DROP TABLE #Tenet_MultiRate1;

	select *
	 INTO #Tenet_MultiRate1
	from
		(

select 
            x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T1' -- Ancillary (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
				
) as Tenet_MultiRate1


		 UPDATE x
	SET x.Tenet_MultiRate1_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate1 as t 
			ON x.chart_ID = t.chart_ID; 

-- *****


if object_id('TempDB..#Tenet_MultiRate2', 'U') is not null DROP TABLE #Tenet_MultiRate2;

	select *
	 INTO #Tenet_MultiRate2
	from
		(

select 
			x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T2' -- Series without CPT (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate2


		 UPDATE x
	SET x.Tenet_MultiRate2_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate2 as t 
			ON x.chart_ID = t.chart_ID; 



-- *****


if object_id('TempDB..#Tenet_MultiRate3', 'U') is not null DROP TABLE #Tenet_MultiRate3;

	select *
	 INTO #Tenet_MultiRate3
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T3' -- Series with CPT (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate3


		 UPDATE x
	SET x.Tenet_MultiRate3_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate3 as t 
			ON x.chart_ID = t.chart_ID; 





-- *****


if object_id('TempDB..#Tenet_MultiRate4', 'U') is not null DROP TABLE #Tenet_MultiRate4;

	select *
	 INTO #Tenet_MultiRate4
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T4' -- Clinic Office Visit (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate4


		 UPDATE x
	SET x.Tenet_MultiRate4_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate4 as t 
			ON x.chart_ID = t.chart_ID; 



-- *****


if object_id('TempDB..#Tenet_MultiRate5', 'U') is not null DROP TABLE #Tenet_MultiRate5;

	select *
	 INTO #Tenet_MultiRate5
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T5' -- Infusion Therapy with I&I (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate5


		 UPDATE x
	SET x.Tenet_MultiRate5_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate5 as t 
			ON x.chart_ID = t.chart_ID; 




-- *****

if object_id('TempDB..#Tenet_MultiRate6', 'U') is not null DROP TABLE #Tenet_MultiRate6;

	select *
	 INTO #Tenet_MultiRate6
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T6' -- Professional Office: E/M and Dx only(Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate6


		 UPDATE x
	SET x.Tenet_MultiRate6_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate6 as t 
			ON x.chart_ID = t.chart_ID; 



-- *****


if object_id('TempDB..#Tenet_MultiRate7', 'U') is not null DROP TABLE #Tenet_MultiRate7;

	select *
	 INTO #Tenet_MultiRate7
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T7' -- Professional Office: E/M, Dx and Surgical CPT(Ten)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate7


		 UPDATE x
	SET x.Tenet_MultiRate7_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate7 as t 
			ON x.chart_ID = t.chart_ID; 





-- *****


if object_id('TempDB..#Tenet_MultiRate8', 'U') is not null DROP TABLE #Tenet_MultiRate8;

	select *
	 INTO #Tenet_MultiRate8
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T8' -- Surgery (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate8


		 UPDATE x
	SET x.Tenet_MultiRate8_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate8 as t 
			ON x.chart_ID = t.chart_ID; 



-- *****

if object_id('TempDB..#Tenet_MultiRate9', 'U') is not null DROP TABLE #Tenet_MultiRate9;

	select *
	 INTO #Tenet_MultiRate9
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'T9' -- Interventional Radiology (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate9


		 UPDATE x
	SET x.Tenet_MultiRate9_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate9 as t 
			ON x.chart_ID = t.chart_ID; 



-- *****

if object_id('TempDB..#Tenet_MultiRate10', 'U') is not null DROP TABLE #Tenet_MultiRate10;

	select *
	 INTO #Tenet_MultiRate10
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'TO' --  Observation (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate10


		 UPDATE x
	SET x.Tenet_MultiRate10_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate10 as t 
			ON x.chart_ID = t.chart_ID; 



-- *****


if object_id('TempDB..#Tenet_MultiRate11', 'U') is not null DROP TABLE #Tenet_MultiRate11;

	select *
	 INTO #Tenet_MultiRate11
	from
		(

select 
			 x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			    #PrelimResults as x,
				SERVICE_AGREEMENT_RATE as sar 				
			where 
			        sar.service_agreement_id = x.service_agreement_id
                and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'TI' --  Inpatient (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.ORGANIZATION_ID in (8,9) -- 9	Tenet Healthcare
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as Tenet_MultiRate11


		 UPDATE x
	SET x.Tenet_MultiRate11_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_MultiRate11 as t 
			ON x.chart_ID = t.chart_ID; 




-- *****


if object_id('TempDB..#Tenet_Claim_Rate', 'U') is not null DROP TABLE #Tenet_Claim_Rate;

	select *
	 INTO #Tenet_Claim_Rate
	from
		(


select 
			x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			 #PrelimResults as x,
			 SERVICE_AGREEMENT_RATE as sar WITH (NOLOCK)								
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'CB' -- Claim (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.PatientClass = 'Edit'
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as  Tenet_Claim_Rate



		 UPDATE x
	SET x.Tenet_Claim_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_Claim_Rate as t 
			ON x.chart_ID = t.chart_ID; 

-- *****
if object_id('TempDB..#Tenet_Denial_Rate', 'U') is not null DROP TABLE #Tenet_Denial_Rate;

	select *
	 INTO #Tenet_Denial_Rate
	from
		(

select 
			x.chart_ID
		   ,sar.RATE
		   ,sar.RATE_TYPE_CD
			from 
			 #PrelimResults as x,
			 SERVICE_AGREEMENT_RATE as sar WITH (NOLOCK)								
			where 
			        sar.service_agreement_id = x.service_agreement_id
				and sar.PATIENT_CLASS_ID = x.PATIENT_CLASS_ID 
				and convert(varchar, x.RATE_DATE, 112) >= sar.EFFECTIVE_DATE 
				and convert(varchar, x.RATE_DATE, 112) <= sar.EXPIRATION_DATE
				and sar.RATE_TYPE_CD = 'DM' -- Denial (Tenet)
				and sar.RATE_CLASS_CD = 'B'
				and x.PatientClass = 'Denial'
				and x.COMPANY_ID in ( 19, 298)  --	Tenet Healthcare, Conifer
) as  Tenet_Denial_Rate


		 UPDATE x
	SET x.Tenet_Denial_Rate = t.RATE
	   ,x.RATE_TYPE_CD     = t.RATE_TYPE_CD
	FROM 
		#PrelimResults as x
		join #Tenet_Denial_Rate as t 
			ON x.chart_ID = t.chart_ID;








-- select * from #PrelimResults

-- *********************************
-- *********************************
-- *********************************
-- *********************************
-- *********************************


if object_id('TempDB..#Temp1', 'U') is not null DROP TABLE #temp1;

select
                                  x.RATE_DATE
                                 ,x.FACILITY_ID
								 ,x.COMPANY_ID
                                 ,x.OBSERVATION_BILLING_METHOD_CD
                                 ,x.PHYSICIAN_SERVICE_CLASS_CD
                                 ,x.ED_Ind
                                 ,x.SLA_RATE_METHOD_IND
                                 ,x.OBS_Ind
                                 ,x.CODED_BY_ID
                                 ,x.OBS_CCS_User
                                 ,x.OBS_Client_User
                                 ,x.SERVICE_AGREEMENT_ID
								 ,x.ORGANIZATION_ID 
								 ,x.PATIENT_DISPOSITION_ID
                                 ,x.CHART_ID
                                 ,x.FACILITY_CHART_ID
                                 ,x.PATIENT_LAST_NAME
                                 ,x.PATIENT_FIRST_NAME
                                 ,x.TIME_OF_SERVICE
                                 ,x.Dept_Name
								 ,x.CLINIC_ID
								 ,x.LONG_PATIENT_ID2
								 ,x.StayDayCnt
								 ,x.RATE_TYPE_CD
								 
								 ,case 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
												when up.USER_CLASS_CD = 4 then 0
												when x.Automation_Exclude = 1  then 0  
												else 1 end CCS 
								 ,case 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
												when x.CODER_USER_CLASS = 4 then 0 
												when x.CODER_USER_CLASS = 5 then 0
												when x.CODER_USER_CLASS = 1 and x.Automation = 0 and x.Automation_Exclude = 0 then 1 												
												else 0 end CCS_NonVendor 
								 ,case 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
												when x.CODER_USER_CLASS = 4 then 0 
												when x.CODER_USER_CLASS = 5 and x.Automation = 0 and x.Automation_Exclude = 0 then 1												
												else 0 end CCS_Vendor

								 ,case 
												when x.BILL_PRO_FEE_IND = 1 then 1 else 0 end ProFee									

											
                                  ,case 
												when x.CODER_USER_CLASS = 4 and x.Automation = 0 then 1 												
												when x.Automation_Exclude = 1  then 1                                 
												when x.OBS_Client_User = 1 and x.ED_Ind = 0 and x.Automation = 0 then 1												
												when x.SERVICE_MODEL_CD = 'ASP' and x.CODER_USER_CLASS is null and x.Automation = 0 then 1
												when x.SERVICE_MODEL_CD = 'ASP' and x.CODER_USER_CLASS = 4 and x.Automation = 0 then 1
												else 0 end SaaS
                                 

                                 ,case
                                      when
                                      (
                                          select
                                              count(*)
                                          from
                                              FACILITY_PROCEDURE_EVALUATION fpe with (nolock)
                                              ,CHARGE_MASTER cm with (nolock)
                                          where
                                              fpe.CHART_ID = x.CHART_ID
                                              and fpe.FACILITY_PROCEDURE_ID = cm.CHARGE_MASTER_ID
                                              and cm.CPT_CODE in ('99291', '99281', '99282', '99283', '99284', '99285')
                                      ) > 0 then 1
                                      when
                                      (
                                          select
                                              count(*)
                                          from
                                              CHART_ADJUSTMENT ca with (nolock)
                                              ,CHARGE_MASTER cm with (nolock)
                                          where
                                              ca.CHART_ID = x.CHART_ID
                                              and ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
                                              and cm.CPT_CODE in ('99291', '99281', '99282', '99283', '99284', '99285')
                                      ) > 0 then 1
                                  else 0 end                                         EMChart

								  

                                 ,case
                                      when up.USER_CLASS_CD = 4 then 0
                                      when up.USER_CLASS_CD <> 4
                                           and x.SLA_HOURS = 0 then 0
                                      when x.SLA_HOURS <= x.MAX_SLA_HOURS then 0 -- Penalized when elpsed SLA_HOURS exceeds the SLA
                                  else
                                  (
                                      select
                                          sla.SLA_DIFFERENTIAL_RATE
                                      from
                                          SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE sla with (nolock)
                                      where
                                          sla.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
                                          and convert(varchar, x.RATE_DATE, 112) >= sla.EFFECTIVE_DATE
                                          and convert(varchar, x.RATE_DATE, 112) <= sla.EXPIRATION_DATE
                                          --and   x.RATE_DATE between sla.EFFECTIVE_DATE and sla.EXPIRATION_DATE
                                          and x.SLA_HOURS >= sla.SLA_DIFFERENTIAL_HOURS
                                          and sla.SLA_DIFFERENTIAL_HOURS =
                                          (
                                              select
                                                  max(sla2.SLA_DIFFERENTIAL_HOURS)
                                              from
                                                  SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE sla2 with (nolock)
                                              where
                                                  sla2.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
                                                  and convert(varchar, x.RATE_DATE, 112) >= sla2.EFFECTIVE_DATE
                                                  and convert(varchar, x.RATE_DATE, 112) <= sla2.EXPIRATION_DATE
                                                  --and   x.RATE_DATE between sla2.EFFECTIVE_DATE and sla2.EXPIRATION_DATE
                                                  and sla2.SLA_DIFFERENTIAL_HOURS <= x.SLA_HOURS
                                                  and
                                                  (
                                                      x.TURNAROUND_HOURS_REPORTING_METHOD in (6, 7) -- It doesn't matter if the chart was previously pended when using last transitioned to WIP reporting methods
                                                      or
                                                      (
                                                          x.Pended <> 'Y'
                                                          or x.Pended is null
                                                      )
                                                  )
                                          )
                                  ) end                                              SLA_RATE




           ,x.SaaS_Obs_Only_Rate
		   ,x.SaaS_Obs_With_CCS_ED_Rate 
		   ,x.CCS_Obs_Only_Rate		   
		   ,x.FS_With_Obs_Rate
		   ,x.PatientClass_Rate
		   ,x.MultiDept_Rate
		   ,x.FS_Inpatient_Rate
		   ,x.SelfPay_Rate
		   ,x.EMIncrementRate 
		   ,x.Inpatient_LengthOfStay_IND
           ,x.Inpatient_LengthOfStay1_Rate
		   ,x.Inpatient_LengthOfStay2_Rate
		   ,x.Inpatient_LengthOfStay3_Rate
		   ,x.Inpatient_LengthOfStay4_Rate
		   ,x.Inpatient_LengthOfStay5_Rate
		   ,x.Inpatient_LengthOfStay6_Rate
	       ,x.Inpatient_LengthOfStay7_Rate
		   ,x.Inpatient_LengthOfStay8_Rate
		   ,x.Inpatient_LengthOfStay9_Rate
	       ,x.Inpatient_LengthOfStay10_Rate

		   ,x.Tenet_MultiRate_IND
		   ,x.Tenet_MultiRate1_Rate
		   ,x.Tenet_MultiRate2_Rate
		   ,x.Tenet_MultiRate3_Rate
		   ,x.Tenet_MultiRate4_Rate
		   ,x.Tenet_MultiRate5_Rate
		   ,x.Tenet_MultiRate6_Rate
		   ,x.Tenet_MultiRate7_Rate
		   ,x.Tenet_MultiRate8_Rate
		   ,x.Tenet_MultiRate9_Rate
		   ,x.Tenet_MultiRate10_Rate
		   ,x.Tenet_MultiRate11_Rate

		   ,x.Tenet_Claim_Rate
		   ,x.Tenet_Denial_Rate 

		   ,x.FS_Auto
		   ,x.SaaS_Auto
		   ,x.Automation_Rate_Ind
		   ,x.Automation_Exclude

into #temp1	
                             from
                                 USER_PROFILE up with (nolock)
                                 -- subquery X now incorporates prepopulated temp tables in order to eliminate blocking other queries against CHART and LOG_NOTE
                                 ,(


-- ******** Inner Most Query - Begin 


                                      select
                                          t.*
										  
										    ,case when (t.SERVICE_MODEL_CD <> 'ASP' OR t.AUTOMATION_CODING_ENABLED <> 1 OR t.CODER_USER_CLASS <> 4) AND t.Automation = 1 AND Automation_Exclude = 0  then 1 											     
												 else 0
											 END as FS_Auto

											,case when t.SERVICE_MODEL_CD = 'ASP' AND t.AUTOMATION_CODING_ENABLED = 1 AND t.Automation = 1  AND Automation_Exclude = 0 AND t.CODER_USER_CLASS = 4 then 1 											     
											      when t.SERVICE_MODEL_CD = 'ASP' AND t.AUTOMATION_CODING_ENABLED = 1 AND t.Automation = 1  AND Automation_Exclude = 0 AND t.CODER_USER_CLASS IS NULL then 1 											     
												 else 0
											 END as SaaS_Auto
                                          ,case
                                               when t.TURNAROUND_HOURS_REPORTING_METHOD in (1) then
                                                   datediff(minute, t.DATE_RECEIVED, t.SENT_DATE) / 60
                                               when t.TURNAROUND_HOURS_REPORTING_METHOD in (2) then
                                                   datediff(minute, t.DATE_RECEIVED, t.APPROVED_DATE) / 60
                                               when t.TURNAROUND_HOURS_REPORTING_METHOD in (3) then
                                                   datediff(minute, t.CREATION_DATE_TIME, t.SENT_DATE) / 60
                                               when t.TURNAROUND_HOURS_REPORTING_METHOD in (4) then
                                                   datediff(minute, t.CREATION_DATE_TIME, t.APPROVED_DATE) / 60
                                               when t.TURNAROUND_HOURS_REPORTING_METHOD = 5 then
                                                   datediff(
                                                               minute
                                                               ,dateadd(
                                                                           minute
                                                                           ,t.TURNAROUND_START_TIME_IN_MINUTES
                                                                           ,convert(
                                                                                       datetime
                                                                                       ,convert(
                                                                                                   varchar
                                                                                                   ,t.CREATION_DATE_TIME
                                                                                                   ,112
                                                                                               )
                                                                                       ,112
                                                                                   )
                                                                       )
                                                               ,t.APPROVED_DATE
                                                           ) / 60
                                               when t.TURNAROUND_HOURS_REPORTING_METHOD in (6, 7) then
                                                   datediff(
                                                               minute
                                                               ,coalesce(
                                                                (
                                                                    select
                                                                        max(COMPLETION_DATE)
                                                                    from
                                                                        #CompletionDates
                                                                    where
                                                                        CHART_ID = t.CHART_ID
                                                                )
                                                                            ,t.CREATION_DATE_TIME
                                                                        )
                                                               ,case
                                                                    when t.TURNAROUND_HOURS_REPORTING_METHOD = 6 then
                                                                        t.SENT_DATE
                                                                else t.APPROVED_DATE end
                                                           ) / 60
                                               when t.TURNAROUND_HOURS_REPORTING_METHOD = 8 then
                                                   datediff(
                                                               minute
                                                               ,(
                                                                    select
                                                                        max(ii.CREATION_DATE_TIME)
                                                                    from
                                                                        VWImportImage ii with (nolock) -- modified 9/2015 to use vwImportImage instead of IMPORT_IMAGE
                                                                    where
                                                                        ii.CHART_ID = t.CHART_ID
                                                                )
                                                               ,t.APPROVED_DATE
                                                           ) / 60
                                               when t.TURNAROUND_HOURS_REPORTING_METHOD = 9 then
                                                   datediff(
                                                               minute
                                                               ,(
                                                                    select
                                                                        max(ii.CREATION_DATE_TIME)
                                                                    from
                                                                        VWImportImage ii with (nolock) -- modified 9/2015 to use vwImportImage instead of IMPORT_IMAGE
                                                                    where
                                                                        ii.CHART_ID = t.CHART_ID
                                                                )
                                                               ,t.APPROVED_DATE
                                                           ) / 60
                                           else 0 end SLA_HOURS
                                     from
                                          #PrelimResults as t -- new temp table
 
-- ********Inner Most Query End


                                  ) x
                             where
                                 x.CODED_BY_ID = up.USER_PROFILE_ID



-- select * from #temp1


-- *****************************************

if object_id('TempDB..#Temp3', 'U') is not null DROP TABLE #temp3;

select
					      z.ORGANIZATION_ID
					     ,z.PATIENT_DISPOSITION_ID
                         ,z.FACILITY_ID
						 ,z.COMPANY_ID
						 ,z.SERVICE_AGREEMENT_ID
                         ,z.CHART_ID
                         ,z.FACILITY_CHART_ID
                         ,z.PATIENT_LAST_NAME
                         ,z.PATIENT_FIRST_NAME
                         ,z.TIME_OF_SERVICE
                         ,z.Dept_Name
						 ,z.StayDayCnt						 
	                     ,z.CLINIC_ID
						 ,z.LONG_PATIENT_ID2
                         ,case
                              when z.SLA_RATE <> 0
                                   and z.SLA_RATE is not null then 1          --SLA Rate         
                              when z.MultiDept_Rate <> 0
                                   and z.MultiDept_Rate is not null then 2    --Multi-Dept Rate
                              when z.SelfPay_Rate <> 0
                                   and z.SelfPay_Rate is not null then 3      --Self-Pay Rate
                              when z.EMIncrementRate <> 0
                                   and z.EMIncrementRate is not null then 4   --E&M Increment Rate                          
                              when z.OBSERVATION_BILLING_METHOD_CD = 4 then 6 -- SaaS Obs Only
                              when z.OBSERVATION_BILLING_METHOD_CD = 2 then 7 -- SaaS Obs with CCS ED
                              when z.OBSERVATION_BILLING_METHOD_CD = 3 then 8 -- CCS Obs Only 
                              when z.OBSERVATION_BILLING_METHOD_CD = 1 then 5 -- CCS ED and Obs
                              when z.PHYSICIAN_SERVICE_CLASS_CD = 5 then 5    -- Profee obs = CCS ED and Obs            
                              when z.SaaS_Obs_Only_Rate <> 0 and z.ED_Ind = 1 then 10 -- SaaS ED and Obs
							  when z.ORGANIZATION_ID = 9 and z.PATIENT_DISPOSITION_ID in (2,3,4) then 11 -- FS_Inpatient
							  when z.Inpatient_LengthOfStay_IND = 'Y' then 12 -- Inpatient_LOS  
							  when z.COMPANY_ID in (19, 298) and z.Tenet_MultiRate_IND = 'Y' then 13 -- Tenet Multirate
							  when z.RATE_TYPE_CD = 'PC' then 14 -- Patient Class Rates
                              when z.SaaS_Obs_Only_Rate <> 0 then 9           -- Saas Obs Only            
                          else 0 end Rate_Class -- Std Rate
                                                --z.TotCCS,
                                                
                         
						  

                         ,case
                              when z.SLA_RATE <> 0
                                   and z.SLA_RATE is not null
								   and 	z.CCS = 1  	 -- Purpose: Only CCS charts will populate CCS Rate -  NEW **********************	
                                   and
                                   (
                                       z.SLA_RATE_METHOD_IND = 0
                                       or z.SLA_RATE_METHOD_IND is null
                                   ) then z.SLA_RATE -- SLA rate triggered and is a discount amount
                          else round(   (
                                            select
                                             sum(sar.RATE)
                                         from
                                             SERVICE_AGREEMENT_RATE sar
                                         where
                                             sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
                                             and sar.RATE_CLASS_CD = 'B'
                                             and
                                             (
                                                  sar.RATE_TYPE_CD in ('C')
												  
                                                 or
                                                 (
                                                     z.SelfPay_Rate <> 0
                                                     and z.SelfPay_Rate is not null
                                                     and sar.RATE_TYPE_CD = '5'
                                                 )
                                             )
											 
                                             and convert(varchar, z.RATE_DATE, 112) >= sar.EFFECTIVE_DATE
                                             and convert(varchar, z.RATE_DATE, 112) <= sar.EXPIRATION_DATE
											 and isnull(z.Inpatient_LengthOfStay_IND, 'N') = 'N' 
											 and 	z.CCS = 1 -- Purpose: Only CCS charts will populate CCS Rate -  NEW **********************	
											     
                                        )  *                                        
                                        (1 - (case
                                                  when z.SLA_RATE <> 0
                                                       and z.SLA_RATE is not null
                                                       and z.SLA_RATE_METHOD_IND = 1 													   
													   and isnull(z.Inpatient_LengthOfStay_IND, 'N') = 'N'  
													   then z.SLA_RATE / 100
                                              else 0 end
                                             )
                                        )
                                        ,5
                                    )                -- Reduce rate by SLA discount percent if triggered
                          end        CCSRate


                         ,(
                              select
                                  sar.RATE
                              from
                                  SERVICE_AGREEMENT_RATE sar
                              where
                                  sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
                                  and sar.RATE_CLASS_CD = 'B'
                                  and sar.RATE_TYPE_CD = 'P'
                                  and convert(varchar, sar.EFFECTIVE_DATE, 112) <= convert(varchar, z.RATE_DATE, 112)
                                  and convert(varchar, sar.EXPIRATION_DATE, 112) >= convert(varchar, z.RATE_DATE, 112)
                          )          ProFeeRate
                                                --z.TotSaaS,       
                         ,(
                              select
                                  sum(sar.RATE)
                              from
                                  SERVICE_AGREEMENT_RATE sar
                              where
                                  sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
                                  and sar.RATE_CLASS_CD = 'B'
                                  and
                                  (
                                      sar.RATE_TYPE_CD in ('S')
                                      or
                                      (
                                          z.MultiDept_Rate <> 0
                                          and z.MultiDept_Rate is not null
                                          and sar.RATE_TYPE_CD = 'O'
                                      )
                                      or
                                      (
                                          z.SelfPay_Rate <> 0
                                          and z.SelfPay_Rate is not null
                                          and sar.RATE_TYPE_CD = '6'
                                      )
                                  )
                                  and convert(varchar, sar.EFFECTIVE_DATE, 112) <= convert(varchar, z.RATE_DATE, 112)
                                  and convert(varchar, sar.EXPIRATION_DATE, 112) >= convert(varchar, z.RATE_DATE, 112)
								  --and z.SaaS = 1 -- Purpose: Only SaaS charts will populate SaaS Rate -  NEW **********************	
								  and (z.SaaS > 0 or ( z.SaaS_Auto > 0 and z.Automation_Rate_Ind = 0))
                          )          SaaSRate



                         ,(
								select sum(sar.RATE) 
								from SERVICE_AGREEMENT_RATE sar
								where 
									sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
									and sar.RATE_CLASS_CD = 'B'
									and sar.RATE_TYPE_CD in ('SQ')									
									and convert(varchar, z.RATE_DATE, 112) >= sar.EFFECTIVE_DATE and convert(varchar, z.RATE_DATE, 112) <= sar.EXPIRATION_DATE
									and z.SaaS_Auto > 0
							) SaaSAutomationRate
							
						--,(
						--		select sum(sar.RATE) 
						--		from SERVICE_AGREEMENT_RATE sar
						--		where 
						--			sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
						--			and sar.RATE_CLASS_CD = 'B'
						--			and sar.RATE_TYPE_CD = 'FA'								
						--			and convert(varchar, z.RATE_DATE, 112) >= sar.EFFECTIVE_DATE and convert(varchar, z.RATE_DATE, 112) <= sar.EXPIRATION_DATE
						--	) FSAutomationRate

						,case
                              when z.SLA_RATE <> 0
                                   and z.SLA_RATE is not null
								   and z.CCS > 0  	 -- Purpose: Only CCS charts will populate CCS Rate 
                                   and
                                   (
                                       z.SLA_RATE_METHOD_IND = 0
                                       or z.SLA_RATE_METHOD_IND is null
                                   ) then z.SLA_RATE -- SLA rate triggered and is a discount amount
                          else round(   (
                                            select
                                             sum(sar.RATE)
                                         from
                                             SERVICE_AGREEMENT_RATE sar
                                         where
                                             sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
                                             and sar.RATE_CLASS_CD = 'B'
                                             and sar.RATE_TYPE_CD in ('FA')											 
                                             and convert(varchar, z.RATE_DATE, 112) >= sar.EFFECTIVE_DATE
                                             and convert(varchar, z.RATE_DATE, 112) <= sar.EXPIRATION_DATE
											 and isnull(z.Inpatient_LengthOfStay_IND, 'N') = 'N' 
											 and z.FS_Auto > 0
											     
                                        )  *                                        
                                        (1 - (case
                                                  when z.SLA_RATE <> 0
                                                       and z.SLA_RATE is not null
                                                       and z.SLA_RATE_METHOD_IND = 1 													   
													   and isnull(z.Inpatient_LengthOfStay_IND, 'N') = 'N'  
													   then z.SLA_RATE / 100
                                              else 0 end
                                             )
                                        )
                                        ,5
                                    )                -- Reduce rate by SLA discount percent if triggered
                          end       FSAutomationRate

                         ,z.EMIncrementRate
                         ,z.FS_With_Obs_Rate
                         ,z.SaaS_Obs_Only_Rate
                         ,z.CCS_Obs_Only_Rate
                         ,z.SaaS_Obs_With_CCS_ED_Rate
						 ,z.FS_Inpatient_Rate
						 
						 ,z.Inpatient_LengthOfStay1_Rate
		                 ,z.Inpatient_LengthOfStay2_Rate
		                 ,z.Inpatient_LengthOfStay3_Rate
		                 ,z.Inpatient_LengthOfStay4_Rate
		                 ,z.Inpatient_LengthOfStay5_Rate
		                 ,z.Inpatient_LengthOfStay6_Rate
	                     ,z.Inpatient_LengthOfStay7_Rate
		                 ,z.Inpatient_LengthOfStay8_Rate
		                 ,z.Inpatient_LengthOfStay9_Rate
	                     ,z.Inpatient_LengthOfStay10_Rate
						 
						 ,z.Tenet_MultiRate1_Rate
						 ,z.Tenet_MultiRate2_Rate
						 ,z.Tenet_MultiRate3_Rate
						 ,z.Tenet_MultiRate4_Rate
						 ,z.Tenet_MultiRate5_Rate
						 ,z.Tenet_MultiRate6_Rate
						 ,z.Tenet_MultiRate7_Rate
		                 ,z.Tenet_MultiRate8_Rate
		                 ,z.Tenet_MultiRate9_Rate
		                 ,z.Tenet_MultiRate10_Rate
		                 ,z.Tenet_MultiRate11_Rate
						 ,z.PatientClass_Rate
						 ,z.Tenet_Claim_Rate
     		             ,z.Tenet_Denial_Rate

						 ,z.Inpatient_LengthOfStay_IND
						 ,z.Tenet_MultiRate_IND
                         ,z.CODED_BY_ID
						 ,z.RATE_TYPE_CD
						 ,z.RATE_DATE

						 ,z.CCS
						 ,z.CCS_NonVendor
						 ,z.CCS_Vendor
                         ,z.ProFee
                         ,z.SaaS
                         ,z.EMChart
						 ,z.FS_Auto
						 ,z.SaaS_Auto

						 ,z.Automation_Rate_Ind
						 ,z.Automation_Exclude

                     
					 into #temp3	
                         from
                         #temp1 z


-- select * from #temp3 where rate_class = 11

-- *****************************************

if object_id('TempDB..#Temp4', 'U') is not null DROP TABLE #temp4;

select
                     w.FACILITY_ID
                     ,w.FACILITY_CHART_ID
                     ,w.PATIENT_LAST_NAME
                     ,w.PATIENT_FIRST_NAME
                     ,w.TIME_OF_SERVICE
                     ,w.Dept_Name
					 ,w.SERVICE_AGREEMENT_ID							 
	                 ,w.CLINIC_ID
                     ,w.Rate_Class
					 ,w.StayDayCnt
                   
				    ,case when w.Rate_Class in (6, 7, 8, 10, 11, 14) then 0 
					       when w.Rate_Class = 0 and w.FS_Auto > 0 and w.Automation_Rate_Ind = 1 then 0 
						   when w.Rate_Class = 1 and w.FS_Auto > 0 and w.Automation_Rate_Ind = 1 then 0 
						   when w.Rate_Class = 5 and w.FS_Auto > 0 and w.Automation_Rate_Ind = 1 then 0  
						   else isnull(w.CCSRate, 0) 
					       end CCSRate  -- Finance Report combines multiple rates like FS_Inpatient into CCS, this report seperates them
					 
					 ,case when w.Rate_Class = 1  and w.FS_Inpatient_Rate > 0 then 0
					      when w.Rate_Class = 11 and w.FS_Inpatient_Rate > 0 then isnull(w.FS_Inpatient_Rate, 0) -- and FS_Auto > 0 - Fac 1782
					 	  when w.FS_Inpatient_Rate > 0 then isnull(w.FS_Inpatient_Rate, 0) else 0 end as FS_Inpatient_Rate

                     ,case when w.ProFeeRate is null then 0 else isnull(w.ProFeeRate, 0) end            ProFeeRate
                     ,case when w.EMIncrementRate is null then 0 else isnull(w.EMIncrementRate, 0) end  EMIncrementRate
                     ,case when w.Rate_Class = 5 then isnull(w.FS_With_Obs_Rate, 0) else 0 end          FS_With_Obs_Rate
                     ,case when w.Rate_Class in ( 6, 9, 10 ) then isnull(w.SaaS_Obs_Only_Rate,0) else 0 end SaasObsOnlyRate
                    
                    
					,case when w.SaaSRate is null OR w.Rate_Class = 9 then 0 
					     when w.Rate_Class = 10 and SaaS_Auto > 0  and w.Automation_Rate_Ind > 0 then 0 
					else isnull(w.SaaSRate,0) end SaaSRate

					,case when w.SaaSAutomationRate is null then 0 
					     when w.Rate_Class = 10 and SaaS > 0 and w.Automation_Rate_Ind > 0 then 0  
						 when SaaS_Auto > 0 then isnull(w.SaaSAutomationRate,0)
					else isnull(w.SaaSAutomationRate,0) end as SaaSAutomationRate 

					,case  when w.Rate_Class = 1 and w.CCSRate > 0 and FS_Auto > 0 and w.Automation_Rate_Ind = 0 then 0 -- isnull(w.CCSRate, 0)    
					      when FS_Auto = 0 and w.Automation_Rate_Ind = 0 then 0    					      
						  when w.Rate_Class = 11 and w.FS_Inpatient_Rate > 0 then 0   
					      when FS_Auto > 0  and w.Automation_Rate_Ind > 0 then isnull(w.FSAutomationRate, 0) 
						  else 0
						  end as FSAutomationRate
					 
					,case when w.Rate_Class = 8 then isnull(w.CCS_Obs_Only_Rate, 0) else 0 end  CCSObsOnlyRate
					,case when w.Rate_Class = 7 then isnull(w.Saas_Obs_With_CCS_ED_Rate, 0) else 0 end Saas_Obs_With_CCS_ED_Rate

					
					
									

                     ,case
                          when
                          (
                              select distinct
                                  1
                              from
                                  USER_PROFILE up2
                              where
                                  up2.USER_PROFILE_ID = w.CODED_BY_ID
                                  and up2.USER_CLASS_CD = 4
                          ) = 1 then 'Y'
                      else 'N' end  SaaSInd
					
					 ,w.CCS_NonVendor
					 ,w.CCS_Vendor
					 ,w.FS_Auto as FS_Auto
					 ,w.SaaS_Auto as SaaS_Auto
					 ,w.Automation_Rate_Ind
					 ,w.Automation_Exclude

					  

					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay1_Rate else 0 end as Inpatient_LengthOfStay1_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay2_Rate else 0 end as Inpatient_LengthOfStay2_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay3_Rate else 0 end as Inpatient_LengthOfStay3_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay4_Rate else 0 end as Inpatient_LengthOfStay4_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay5_Rate else 0 end as Inpatient_LengthOfStay5_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay6_Rate else 0 end as Inpatient_LengthOfStay6_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay7_Rate else 0 end as Inpatient_LengthOfStay7_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay8_Rate else 0 end as Inpatient_LengthOfStay8_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay9_Rate else 0 end as Inpatient_LengthOfStay9_Rate
					  ,case when w.Rate_Class = 12 then w.Inpatient_LengthOfStay10_Rate else 0 end as Inpatient_LengthOfStay10_Rate

					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate1_Rate else 0 end as Tenet_MultiRate1_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate2_Rate else 0 end as Tenet_MultiRate2_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate3_Rate else 0 end as Tenet_MultiRate3_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate4_Rate else 0 end as Tenet_MultiRate4_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate5_Rate else 0 end as Tenet_MultiRate5_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate6_Rate else 0 end as Tenet_MultiRate6_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate7_Rate else 0 end as Tenet_MultiRate7_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate8_Rate else 0 end as Tenet_MultiRate8_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate9_Rate else 0 end as Tenet_MultiRate9_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate10_Rate else 0 end as Tenet_MultiRate10_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_MultiRate11_Rate else 0 end as Tenet_MultiRate11_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_Claim_Rate else 0 end as Tenet_Claim_Rate
					  ,case when w.Rate_Class = 13 then w.Tenet_Denial_Rate else 0 end as Tenet_Denial_Rate
					  
					  ,case when w.Rate_Class = 14 then isnull(w.PatientClass_Rate, 0) else 0 end PatientClass_Rate
					  ,w.LONG_PATIENT_ID2
                 
				      
					  
				 into #temp4	
                         from
                         #temp3 w




-- select * from #temp4 where rate_class = 1


-- *****************************************

if object_id('TempDB..#Temp5', 'U') is not null DROP TABLE #temp5;

select
             f.ACCOUNTING_FACILITY_CODE Facility
            ,v.FACILITY_CHART_ID
            ,v.PATIENT_LAST_NAME
            ,v.PATIENT_FIRST_NAME
            ,v.TIME_OF_SERVICE
            ,v.Dept_Name
			,sac.description as Clinic
            ,v.Rate_Class
			,v.StayDayCnt             
            ,v.CCSRate as CCSRate
			,v.FS_Inpatient_Rate
            ,v.ProFeeRate
        ,case when v.SaaS_Auto = 1 and v.SaaSAutomationRate > 0 then 0 else v.SaaSRate end as SaaSRate		
		,case when v.SaaS_Auto = 1 and v.SaaSAutomationRate > 0 then v.SaaSAutomationRate
			  when v.Automation_Exclude = 1 and  v.SaaSAutomationRate > 0 then v.SaaSAutomationRate
			  else  0 end as SaaSAutomationRate
		,case when v.FS_Auto = 1   and v.FSAutomationRate > 0   then v.FSAutomationRate   else 0 end as FSAutomationRate
            ,v.EMIncrementRate
            ,v.FS_With_Obs_Rate
            ,v.SaasObsOnlyRate
            ,v.CCSObsOnlyRate
            ,v.Saas_Obs_With_CCS_ED_Rate
			,v.CCS_NonVendor
			,v.CCS_Vendor
            ,v.SaasInd
		    ,v.FS_Auto
		    ,v.SaaS_Auto
		    ,v.Inpatient_LengthOfStay1_Rate
			,v.Inpatient_LengthOfStay2_Rate
			,v.Inpatient_LengthOfStay3_Rate
			,v.Inpatient_LengthOfStay4_Rate
			,v.Inpatient_LengthOfStay5_Rate
			,v.Inpatient_LengthOfStay6_Rate
			,v.Inpatient_LengthOfStay7_Rate
			,v.Inpatient_LengthOfStay8_Rate
			,v.Inpatient_LengthOfStay9_Rate
			,v.Inpatient_LengthOfStay10_Rate
			,v.Tenet_MultiRate1_Rate
		    ,v.Tenet_MultiRate2_Rate
		    ,v.Tenet_MultiRate3_Rate
		    ,v.Tenet_MultiRate4_Rate
		    ,v.Tenet_MultiRate5_Rate
		    ,v.Tenet_MultiRate6_Rate
		    ,v.Tenet_MultiRate7_Rate
		    ,v.Tenet_MultiRate8_Rate
		    ,v.Tenet_MultiRate9_Rate
		    ,v.Tenet_MultiRate10_Rate
		    ,v.Tenet_MultiRate11_Rate
			,v.Tenet_Claim_Rate
     		,v.Tenet_Denial_Rate
			,v.PatientClass_Rate
			,v.LONG_PATIENT_ID2
		into #temp5	
        from
        FACILITY f,
		#temp4 v        
		left outer join SERVICE_AGREEMENT_CLINIC sac on 
        v.service_agreement_id = sac.service_agreement_id
        and v.CLINIC_ID = sac.CLINIC_ID
        where
        v.FACILITY_ID = f.FACILITY_ID



-- select * from #temp5

-- *****************************************

if object_id('TempDB..#Output1', 'U') is not null DROP TABLE #Output1;

select
	     u.Facility
	    ,u.Clinic        
        ,u.FACILITY_CHART_ID
        ,u.PATIENT_LAST_NAME
        ,u.PATIENT_FIRST_NAME
        ,u.TIME_OF_SERVICE
        ,u.Rate_Class                --'Rate Class'
		,u.StayDayCnt 
        ,u.CCSRate                   --'CCS Rate'
		,u.FS_Inpatient_Rate
        ,u.FS_With_Obs_Rate          --'FS with Obs Increment'
        ,u.SaasObsOnlyRate           --'SaaS Rate Obs Only'
        ,u.CCSObsOnlyRate            --'CCS Obs Only (Direct to Obs)'
        ,u.Saas_Obs_With_CCS_ED_Rate --'SaaS Obs with CCS ED Coding rate'
        ,u.ProFeeRate                --'Pro-Fee Rate'
        ,u.SaaSRate                  --'SaaS Rate'
	    ,u.SaaSAutomationRate
	    ,u.FSAutomationRate
        ,u.EMIncrementRate           --'E&M Increment rate'
		,isnull(u.Inpatient_LengthOfStay1_Rate, 0) as Inpatient_LengthOfStay1
		,isnull(u.Inpatient_LengthOfStay2_Rate, 0) as Inpatient_LengthOfStay2
		,isnull(u.Inpatient_LengthOfStay3_Rate, 0) as Inpatient_LengthOfStay3
		,isnull(u.Inpatient_LengthOfStay4_Rate, 0) as Inpatient_LengthOfStay4
		,isnull(u.Inpatient_LengthOfStay5_Rate, 0) as Inpatient_LengthOfStay5
		,isnull(u.Inpatient_LengthOfStay6_Rate, 0) as Inpatient_LengthOfStay6
		,isnull(u.Inpatient_LengthOfStay7_Rate, 0) as Inpatient_LengthOfStay7
		,isnull(u.Inpatient_LengthOfStay8_Rate, 0) as Inpatient_LengthOfStay8
		,isnull(u.Inpatient_LengthOfStay9_Rate, 0) as Inpatient_LengthOfStay9
		,isnull(u.Inpatient_LengthOfStay10_Rate, 0) as Inpatient_LengthOfStay10

		

		
		,u.Tenet_MultiRate1_Rate  as Tenet_MultiRate1 --as Tenet_Ancillary
		,u.Tenet_MultiRate2_Rate  as Tenet_MultiRate2  --as Tenet_Series_WO_CPT 
		,u.Tenet_MultiRate3_Rate  as Tenet_MultiRate3  --as Tenet_Series_W_CPT
		,u.Tenet_MultiRate4_Rate  as Tenet_MultiRate4  --as Tenet_Clinic_Office_Visit
		,u.Tenet_MultiRate5_Rate  as Tenet_MultiRate5  --as Tenet_Infusion_Therapy
		,u.Tenet_MultiRate6_Rate  as Tenet_MultiRate6  --as Tenet_Professional_Office_EM_Dx_Only
		,u.Tenet_MultiRate7_Rate  as Tenet_MultiRate7  --as Tenet_Professional_Office_EM_Dx_Surgical_CPT
		,u.Tenet_MultiRate8_Rate  as Tenet_MultiRate8  --as Tenet_Surgery
		,u.Tenet_MultiRate9_Rate  as Tenet_MultiRate9  --as Tenet_Interventional_Radiology
		,u.Tenet_MultiRate10_Rate   as Tenet_MultiRate10 --as Tenet_Observation
		,u.Tenet_MultiRate11_Rate   as Tenet_MultiRate11 --as Tenet_Inpatient
		,isnull(u.PatientClass_Rate, 0) as PatientClass_Rate
		,u.Tenet_Claim_Rate
		,u.Tenet_Denial_Rate
		,u.CCS_NonVendor
		,u.CCS_Vendor
        ,u.SaasInd           --        'Saas'
		,u.FS_Auto as FS_Auto_Ind
		,u.SaaS_Auto as SaaS_Auto_Ind
        ,u.Dept_Name
		,u.LONG_PATIENT_ID2 -- [MRN Export]

		into #Output1
        from        
		#temp5 u  


-- select * from #Output1

-- *****************************************
-- Output 


select 
         o.Facility
	    ,o.Clinic        
        ,o.FACILITY_CHART_ID
        ,o.PATIENT_LAST_NAME
        ,o.PATIENT_FIRST_NAME
        ,o.TIME_OF_SERVICE
        ,o.Rate_Class                'Rate Class'
		,o.StayDayCnt 
        ,o.CCSRate                   'CCS Rate'
		,o.FS_Inpatient_Rate
        ,o.FS_With_Obs_Rate          'FS with Obs Increment'
        ,o.SaasObsOnlyRate           'SaaS Rate Obs Only'
        ,o.CCSObsOnlyRate            'CCS Obs Only (Direct to Obs)'
        ,o.Saas_Obs_With_CCS_ED_Rate 'SaaS Obs with CCS ED Coding rate'
        ,o.ProFeeRate                'Pro-Fee Rate'
        ,o.SaaSRate                  'SaaS Rate'
		,o.SaaSAutomationRate
		,o.FSAutomationRate
        ,o.EMIncrementRate           'E&M Increment rate'
		,o.PatientClass_Rate as PatientClass_Rate
		,isnull(o.Inpatient_LengthOfStay1, 0) as Inpatient_LengthOfStay1
		,(select sum(Inpatient_LengthOfStay1) from #Output1) as Inpatient_LOS1_Visible
		,isnull(o.Inpatient_LengthOfStay2, 0) as Inpatient_LengthOfStay2
		,(select sum(Inpatient_LengthOfStay2) from #Output1) as Inpatient_LOS2_Visible
		,isnull(o.Inpatient_LengthOfStay3, 0) as Inpatient_LengthOfStay3
		,(select sum(Inpatient_LengthOfStay3) from #Output1) as Inpatient_LOS3_Visible
		,isnull(o.Inpatient_LengthOfStay4, 0) as Inpatient_LengthOfStay4
		,(select sum(Inpatient_LengthOfStay4) from #Output1) as Inpatient_LOS4_Visible
		,isnull(o.Inpatient_LengthOfStay5, 0) as Inpatient_LengthOfStay5
		,(select sum(Inpatient_LengthOfStay5) from #Output1) as Inpatient_LOS5_Visible
		,isnull(o.Inpatient_LengthOfStay6, 0) as Inpatient_LengthOfStay6
		,(select sum(Inpatient_LengthOfStay6) from #Output1) as Inpatient_LOS6_Visible
		,isnull(o.Inpatient_LengthOfStay7, 0) as Inpatient_LengthOfStay7
		,(select sum(Inpatient_LengthOfStay7) from #Output1) as Inpatient_LOS7_Visible
		,isnull(o.Inpatient_LengthOfStay8, 0) as Inpatient_LengthOfStay8
		,(select sum(Inpatient_LengthOfStay8) from #Output1) as Inpatient_LOS8_Visible
		,isnull(o.Inpatient_LengthOfStay9, 0) as Inpatient_LengthOfStay9
		,(select sum(Inpatient_LengthOfStay9) from #Output1) as Inpatient_LOS9_Visible
		,isnull(o.Inpatient_LengthOfStay10, 0) as Inpatient_LengthOfStay10
		,(select sum(Inpatient_LengthOfStay10) from #Output1) as Inpatient_LOS10_Visible
		
		,isnull(o.Tenet_MultiRate1, 0) as Tenet_Ancillary
		,(select sum(Tenet_MultiRate1) from #Output1) as Tenet_MultiRate1_Visible
		,isnull(o.Tenet_MultiRate2, 0) as Tenet_Series_WO_CPT 
		,(select sum(Tenet_MultiRate2) from #Output1) as Tenet_MultiRate2_Visible
		,isnull(o.Tenet_MultiRate3, 0) as Tenet_Series_W_CPT
		,(select sum(Tenet_MultiRate3) from #Output1) as Tenet_MultiRate3_Visible
		,isnull(o.Tenet_MultiRate4, 0) as Tenet_Clinic_Office_Visit
		,(select sum(Tenet_MultiRate4) from #Output1) as Tenet_MultiRate4_Visible
		,isnull(o.Tenet_MultiRate5, 0) as Tenet_Infusion_Therapy
		,(select sum(Tenet_MultiRate5) from #Output1) as Tenet_MultiRate5_Visible
		,isnull(o.Tenet_MultiRate6, 0) as Tenet_Professional_Office_EM_Dx_Only
		,(select sum(Tenet_MultiRate6) from #Output1) as Tenet_MultiRate6_Visible
		,isnull(o.Tenet_MultiRate7, 0) as Tenet_Professional_Office_EM_Dx_Surgical_CPT
		,(select sum(Tenet_MultiRate7) from #Output1) as Tenet_MultiRate7_Visible
		,isnull(o.Tenet_MultiRate8, 0) as Tenet_Surgery
		,(select sum(Tenet_MultiRate8) from #Output1) as Tenet_MultiRate8_Visible
		,isnull(o.Tenet_MultiRate9, 0) as Tenet_Interventional_Radiology
		,(select sum(Tenet_MultiRate9) from #Output1) as Tenet_MultiRate9_Visible
		,isnull(o.Tenet_MultiRate10, 0) as Tenet_Observation
		,(select sum(Tenet_MultiRate10) from #Output1) as Tenet_MultiRate10_Visible
		,isnull(o.Tenet_MultiRate11, 0) as Tenet_Inpatient
		,(select sum(Tenet_MultiRate11) from #Output1) as Tenet_MultiRate11_Visible	
		,o.Tenet_Claim_Rate
		,(select case when sum(Tenet_Claim_Rate) > 0 then 'Y' Else 'N' End from #Output1) as Tenet_Claim_Visible
		,o.Tenet_Denial_Rate
		,(select case when sum(Tenet_Denial_Rate) > 0 then 'Y' Else 'N' End from #Output1) as Tenet_Denial_Visible	
		,o.CCS_NonVendor
		,o.CCS_Vendor
        ,o.SaasInd           as 'SaaS'
		,o.FS_Auto_Ind
		,o.SaaS_Auto_Ind
        ,o.Dept_Name
		,o.LONG_PATIENT_ID2 as [MRN Export]


 from #Output1 o
 group by 
	     o.Facility
	    ,o.Clinic        
        ,o.FACILITY_CHART_ID
        ,o.PATIENT_LAST_NAME
        ,o.PATIENT_FIRST_NAME
        ,o.TIME_OF_SERVICE
        ,o.Rate_Class 
		,o.StayDayCnt 
        ,o.CCSRate  
		,o.FS_Inpatient_Rate
        ,o.FS_With_Obs_Rate
        ,o.SaasObsOnlyRate 
        ,o.CCSObsOnlyRate 
        ,o.Saas_Obs_With_CCS_ED_Rate
        ,o.ProFeeRate               
        ,o.SaaSRate 
		,o.SaaSAutomationRate
		,o.FSAutomationRate                
        ,o.EMIncrementRate 
		,o.PatientClass_Rate         
		,isnull(o.Inpatient_LengthOfStay1, 0) 
		,isnull(o.Inpatient_LengthOfStay2, 0) 
		,isnull(o.Inpatient_LengthOfStay3, 0) 
		,isnull(o.Inpatient_LengthOfStay4, 0) 
		,isnull(o.Inpatient_LengthOfStay5, 0) 
		,isnull(o.Inpatient_LengthOfStay6, 0) 
		,isnull(o.Inpatient_LengthOfStay7, 0) 
		,isnull(o.Inpatient_LengthOfStay8, 0) 
		,isnull(o.Inpatient_LengthOfStay9, 0) 
		,isnull(o.Inpatient_LengthOfStay10, 0)
		,isnull(o.Tenet_MultiRate1, 0)
		,isnull(o.Tenet_MultiRate2, 0)
		,isnull(o.Tenet_MultiRate3, 0)
		,isnull(o.Tenet_MultiRate4, 0)
		,isnull(o.Tenet_MultiRate5, 0)
		,isnull(o.Tenet_MultiRate6, 0)
		,isnull(o.Tenet_MultiRate7, 0)
		,isnull(o.Tenet_MultiRate8, 0)
		,isnull(o.Tenet_MultiRate9, 0)
		,isnull(o.Tenet_MultiRate10, 0)
		,isnull(o.Tenet_MultiRate11, 0)
		,o.Tenet_Claim_Rate
		,o.Tenet_Denial_Rate
		,o.CCS_NonVendor
		,o.CCS_Vendor 
        ,o.SaasInd 
		,o.FS_Auto_Ind
		,o.SaaS_Auto_Ind
        ,o.Dept_Name
		,o.LONG_PATIENT_ID2  






  end;










GO
GRANT EXECUTE ON  [dbo].[BILLING_DETAIL_BY_FACILITY] TO [dbx_ExecuteReportProcs]
GO
