SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[BILLING_SUMMARY_BY_FACILITY_SAVE_EF]
@billing_period int
WITH EXEC AS CALLER
AS
BEGIN

declare @billingPeriod int = @billing_period;


select u.Facility,
	     u.Facility_ID,
       u.Rate_Class 'Rate Class',
       u.TotCCS 'CCS Count',
       u.CCSRate 'CCS Rate',
       u.FS_With_Obs_Rate 'FS with Obs Increment',   
       u.SaasObsOnlyRate 'SaaS Rate Obs Only',  
       u.CCSObsOnlyRate 'CCS Obs Only (Direct to Obs)',
       u.Saas_Obs_With_CCS_ED_Rate 'SaaS Obs with CCS ED Coding rate',  
       u.ProFeeRate 'Pro-Fee Rate',
       u.TotSaaS 'SaaS Count',
       u.TotProFee 'SaaS ProFee Count',
       u.SaaSRate 'SaaS Rate',
       u.TotEM 'EM Increment Count',
       u.EMIncrementRate 'E&M Increment rate',
       u.TotCharts 'Total Count',
       round(u.TotCCS * u.CCSRate, 2) + ROUND(u.TotCCS * u.FS_With_Obs_Rate, 2) + round((u.TotProFee + u.TotCCS) * u.ProFeeRate, 2) + round(u.TotSaaS * u.SaaSRate, 2) + round(u.TotSaaS * u.SaasObsOnlyRate, 2) +round(u.TotCCS * u.Saas_Obs_With_CCS_ED_Rate, 2) + round(u.TotCCS * u.CCSObsOnlyRate, 2)   + round(u.TotEM * u.EMIncrementRate, 2) 'Total Billed'
from (

select f.FACILITY_ID,
       isnull(nullif(f.ACCOUNTING_FACILITY_CODE, ''), f.FACILITY_NUMBER) Facility,
       v.Rate_Class,
       v.CCSRate,
       v.ProFeeRate,
       v.SaaSRate,
       v.EMIncrementRate,
       v.FS_With_Obs_Rate,
       v.SaasObsOnlyRate,
       v.CCSObsOnlyRate,
       v.Saas_Obs_With_CCS_ED_Rate,
       sum(v.TotCCS) TotCCS,
       sum(v.TotSaaS) TotSaaS,
       SUM(v.TotEM) TotEM,
       sum(v.TotCharts) TotCharts, 
       SUM(v.TotProFee) TotProFee
from   FACILITY f with (NOLOCK), (

select w.FACILITY_ID,
       w.Rate_Class,
       w.TotCCS, 
       w.TotProFee,        
       case when w.Rate_Class IN (6,7,8) then 0 else w.CCSRate end CCSRate,
       case when w.ProFeeRate is null then 0 else w.ProFeeRate end ProFeeRate,
       case when w.EMIncrementRate is null then 0 else w.EMIncrementRate end EMIncrementRate,
       case when w.Rate_Class = 5  then w.FS_With_Obs_Rate else 0 end FS_With_Obs_Rate,
       case when (w.Rate_Class = 6 OR w.Rate_Class = 9 OR w.Rate_Class = 10) then w.SaaS_Obs_Only_Rate else 0 end SaasObsOnlyRate, 
       case when w.Rate_Class = 8 then w.CCS_Obs_Only_Rate else 0 end  CCSObsOnlyRate,
       case when w.Rate_Class = 7 then w.Saas_Obs_With_CCS_ED_Rate else 0 end Saas_Obs_With_CCS_ED_Rate,
       w.TotSaaS,
       case when w.SaaSRate is null OR w.Rate_Class = 9 then 0 else w.SaaSRate end SaaSRate,
       w.TotCharts,
       case when w.EMIncrementRate > 0 then w.TotEM else 0 end TotEM
from (
select	z.FACILITY_ID,				
		   case when z.SLA_RATE <> 0 and z.SLA_RATE is not null then 1 --SLA Rate         
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
       z.TotCCS,
       z.TotProFee,   
       case when z.SLA_RATE <> 0 and z.SLA_RATE is not null and (z.SLA_RATE_METHOD_IND = 0 or z.SLA_RATE_METHOD_IND is null) then z.SLA_RATE  -- SLA rate triggered and is a discount amount
            else round((select sum(sar.RATE) from SERVICE_AGREEMENT_RATE sar 
               where sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
               and   sar.RATE_CLASS_CD = 'B'
               and   (sar.RATE_TYPE_CD in ('C')
                  or (z.SelfPay_Rate <> 0 and z.SelfPay_Rate is not null and sar.RATE_TYPE_CD = '5'))
               and   z.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE) * 
             (1 - (case when z.SLA_RATE <> 0 and z.SLA_RATE is not null and z.SLA_RATE_METHOD_IND = 1 then z.SLA_RATE/100 else 0 end)),5) -- Reduce rate by SLA discount percent if triggered
            end CCSRate,
       (select sar.RATE from SERVICE_AGREEMENT_RATE sar
               where sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
               and   sar.RATE_CLASS_CD = 'B'
               and   sar.RATE_TYPE_CD = 'P'
               and   z.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE) ProFeeRate,
       z.TotSaaS,       
       (select sum(sar.RATE) from SERVICE_AGREEMENT_RATE sar
               where sar.SERVICE_AGREEMENT_ID = z.SERVICE_AGREEMENT_ID
               and   sar.RATE_CLASS_CD = 'B'
               and   (sar.RATE_TYPE_CD in ('S')
                  or (z.MultiDept_Rate <> 0 and z.MultiDept_Rate is not null and sar.RATE_TYPE_CD = 'O')
                  or (z.SelfPay_Rate <>0 and z.SelfPay_Rate is not null and sar.RATE_TYPE_CD = '6'))
               and   z.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE) SaaSRate,
       z.TotCharts, 
       z.TotEM, 
       z.EMIncrementRate, 
       z.FS_With_Obs_Rate, 
       z.SaaS_Obs_Only_Rate, 
       z.CCS_Obs_Only_Rate, 
       z.Saas_Obs_With_CCS_ED_Rate
from   (
select y.RATE_DATE,
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
       sum(y.CCS) TotCCS,
       sum(y.ProFee) TotProFee,
       sum(y.SaaS) TotSaaS,
       SUM(y.EMChart) TotEM,
       count(*) TotCharts
from (
select x.RATE_DATE,
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
	     case when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 0 
		        when up.USER_CLASS_CD = 4 then 0 
		        else 1 end CCS, 
            
       case when x.BILL_PRO_FEE_IND = 1 then 1 else 0 end ProFee,
       
       case when up.USER_CLASS_CD = 4 then 1 
			      when x.OBS_Client_User = 1 and x.ED_Ind = 0 then 1
			      else 0 end SaaS,
            
       case when (select distinct 1 from CHART c WITH (NOLOCK), FACILITY_LEVEL fl WITH (NOLOCK)
				        where c.chart_id = x.CHART_ID 
                and   fl.FACILITY_LEVEL_ID = (case when c.OVERRIDE_FACILITY_LEVEL_ID <> -1 then c.OVERRIDE_FACILITY_LEVEL_ID else c.FACILITY_LEVEL_ID end)				   
				        and   fl.LEVEL_NUMBER > 0) = 1
				        then 1 
		        else 0 end EMChart,
            
       case when up.USER_CLASS_CD = 4 then 0
            when up.USER_CLASS_CD <> 4 and x.SLA_HOURS = 0 then 0
            else (select sla.SLA_DIFFERENTIAL_RATE from SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE sla WITH (NOLOCK)
                      where sla.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
                      and   x.RATE_DATE between sla.EFFECTIVE_DATE and sla.EXPIRATION_DATE
                      and   x.SLA_HOURS >= sla.SLA_DIFFERENTIAL_HOURS
                      and   sla.SLA_DIFFERENTIAL_HOURS = (select max(sla2.SLA_DIFFERENTIAL_HOURS) 
                          from  SERVICE_AGREEMENT_SLA_DIFFERENTIAL_RATE sla2 WITH (NOLOCK)
                          where sla2.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
                          and   x.RATE_DATE between sla2.EFFECTIVE_DATE and sla2.EXPIRATION_DATE
                          and   sla2.SLA_DIFFERENTIAL_HOURS <= x.SLA_HOURS
                          and (x.Pended <> 'Y' or x.Pended is null)
                           )) end SLA_RATE,
                           
       (select sar.RATE from SERVICE_AGREEMENT_RATE sar  WITH (NOLOCK)
            where sar.service_agreement_id = x.service_agreement_id
            and   x.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
            and   sar.RATE_TYPE_CD = 'O'
            and   sar.RATE_CLASS_CD = 'B'
            and   (select count(*) Tot
                    from (
                    select distinct sp.CHART_ID, cm.CHARGE_MASTER_DEPT_ID
                    from   SENT_PROCEDURE sp WITH (NOLOCK), 
                           CHARGE_MASTER cm WITH (NOLOCK)
                    where  x.CHART_ID = sp.CHART_ID
					          and    (SELECT COUNT(*) 
                            FROM   LOG_NOTE ln WITH (NOLOCK) 
                            WHERE  ln.CHART_ID = sp.CHART_ID 
                            AND    ln.CATEGORY_ID = 26) = 0	        -- 26 = OBS Complete            
                    AND    cm.CHARGE_MASTER_ID = sp.charge_master_id
                    group by sp.CHART_ID, cm.CHARGE_MASTER_DEPT_ID) xx) > 1
          ) MultiDept_Rate,
           
       (select sar.RATE from SERVICE_AGREEMENT_RATE sar  WITH (NOLOCK)
            where sar.service_agreement_id = x.service_agreement_id
            and   x.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
            and   sar.RATE_TYPE_CD = '8'
            and   sar.RATE_CLASS_CD = 'B'
            and   x.chart_id in (select c.chart_id
                    from  chart c WITH (NOLOCK),
                          log_note ln with (NOLOCK),
                          user_profile up with (NOLOCK)
                    where c.CHART_ID = x.CHART_ID
						        and	  c.PATIENT_DISPOSITION_ID = 5
                    and   ln.chart_id = x.chart_id
                    and   ln.category_id = 26
                    and   up.user_profile_id = ln.completed_by_user_id
                    and   up.user_class_cd = 4)
        ) SaaS_Obs_Only_Rate,           

       (select sar.RATE from SERVICE_AGREEMENT_RATE sar  WITH (NOLOCK), CHART c WITH (NOLOCK), SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sap  WITH (NOLOCK)
            where sar.service_agreement_id = x.service_agreement_id
            and   x.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
            and   sar.RATE_TYPE_CD = '7'
            and   sar.RATE_CLASS_CD = 'B'
            and   x.chart_id = c.CHART_ID
					  and	  c.PATIENT_DISPOSITION_ID = 5  -- Observation
					  and   c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
					  and   sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 2  -- Direct to Observation
					  and   (((SELECT up.USER_CLASS_CD 
                     from   USER_PROFILE up  WITH (NOLOCK)
							       where  up.USER_PROFILE_ID = (SELECT ln2.COMPLETED_BY_USER_ID 
                                from  LOG_NOTE ln2 WITH (NOLOCK) 
                                where ln2.LOG_NOTE_ID = 
														        (SELECT MIN(ln3.LOG_NOTE_ID) from LOG_NOTE ln3  WITH (NOLOCK)
														         WHERE  ln3.CHART_ID = c.CHART_ID AND ln3.CATEGORY_ID = 26))) <> 4)  -- Not a client coder
							   or (SELECT COUNT(*) FROM LOG_NOTE ln2 WITH (NOLOCK) 
                     where  ln2.CATEGORY_ID = 26   -- Observation Code Complete
                     and    ln2.chart_id = c.chart_id) = 0)	-- No log note records					
					) CCS_Obs_Only_Rate,   

       (select sum(sar.RATE) 
            from SERVICE_AGREEMENT_RATE sar  WITH (NOLOCK),
                 CHART c  WITH (NOLOCK),
                 SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sap WITH (NOLOCK)
            where sar.service_agreement_id = x.service_agreement_id
            and   x.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
            and   sar.RATE_TYPE_CD IN ('C','8')
            and   sar.RATE_CLASS_CD = 'B'
            and   x.chart_id = c.CHART_ID
            and   sap.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID
					  and	  c.PATIENT_DISPOSITION_ID = 5   -- Observation
					  and   c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
					  and   sap.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD <> 2   -- Other than Direct to Observation
					  and   (SELECT up.USER_CLASS_CD from USER_PROFILE up  WITH (NOLOCK)
							     WHERE up.USER_PROFILE_ID = (SELECT ln2.COMPLETED_BY_USER_ID from LOG_NOTE ln2  WITH (NOLOCK) 
                          where ln2.LOG_NOTE_ID = 
														 (SELECT MIN(ln3.LOG_NOTE_ID) from LOG_NOTE ln3  WITH (NOLOCK)
														  WHERE  ln3.CHART_ID = c.CHART_ID AND ln3.CATEGORY_ID = 2))) <> 4		 -- Not a client coder								
					) SaaS_Obs_With_CCS_ED_Rate, 
                    
       (select sar.RATE from SERVICE_AGREEMENT_RATE sar WITH (NOLOCK), SERVICE_AGREEMENT sa WITH (NOLOCK), CHART c WITH (NOLOCK)
			LEFT OUTER JOIN PATIENT_CLASS pc on c.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID 
            where sar.service_agreement_id = x.service_agreement_id
            and   x.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
            and   sar.RATE_TYPE_CD = '7'
            and   sar.RATE_CLASS_CD = 'B'
            and   x.chart_id = c.CHART_ID
            and   c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
			and	  ((c.PATIENT_DISPOSITION_ID = 5 AND sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1) or (pc.PHYSICIAN_SERVICE_CLASS_CD = 5 AND sa.EVALUATE_PHYSICIAN_OBSERVATION = 1))
			) FS_With_Obs_Rate,      
                                                      
       (select sar.RATE from SERVICE_AGREEMENT_RATE sar WITH (NOLOCK)
            where sar.service_agreement_id = x.service_agreement_id
            and   x.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
            and   sar.RATE_TYPE_CD = '5'
            and   sar.RATE_CLASS_CD = 'B'
            and   x.chart_id in (select c.CHART_ID from CHART c WITH (NOLOCK), FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK)
                  where x.chart_id = c.CHART_ID
                  and   ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
                  and   x.service_agreement_id = ffc.SERVICE_AGREEMENT_ID
                  and   ffc.PAYOR_METHOD_CD = 4)
            
          ) SelfPay_Rate,

		(select sar.RATE 
            from  SERVICE_AGREEMENT_RATE sar WITH (NOLOCK), 
                  CHART c WITH (NOLOCK), 
                  FACILITY_LEVEL fl WITH (NOLOCK)
            where sar.service_agreement_id = x.service_agreement_id
            and   x.RATE_DATE between sar.EFFECTIVE_DATE and sar.EXPIRATION_DATE
            and   sar.RATE_TYPE_CD = 'E'
            and   sar.RATE_CLASS_CD = 'B'
            and   x.chart_id = c.CHART_ID
            and   fl.FACILITY_LEVEL_ID = (case when c.OVERRIDE_FACILITY_LEVEL_ID <> -1 then c.OVERRIDE_FACILITY_LEVEL_ID else c.FACILITY_LEVEL_ID end)
            and   fl.LEVEL_NUMBER > 0  -- Billable
                   
          ) EMIncrementRate
                          
from USER_PROFILE up  WITH (NOLOCK), (
      select c.FACILITY_ID,
             c.SERVICE_AGREEMENT_ID,
             c.OBSERVATION_BILLING_METHOD_CD,
             (select pcl.physician_service_class_cd from PATIENT_CLASS pcl where pcl.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID) as PHYSICIAN_SERVICE_CLASS_CD,
             case when sa.RATE_METHOD_CD = 1 then c.TIME_OF_SERVICE
                  when sa.RATE_METHOD_CD = 2 then c.SENT_DATE
                  else bctl.END_DATE end RATE_DATE,
      			 bc.CHART_ID,
             case when sa.BILL_PRO_FEE_METHOD_CD = 1 and c.CHART_ID in (select sp.chart_id from SENT_PROCEDURE sp  WITH (NOLOCK)
                          where c.CHART_ID = sp.chart_id
                          and   sp.class in ('PL', 'PP')) then 1 
                 else 0 end BILL_PRO_FEE_IND,
             case when sa.BILL_CODER_METHOD_CD = 1 and bc.CHART_ID in		(select ln.CHART_ID from LOG_NOTE ln  WITH (NOLOCK)
      																	where bc.CHART_ID = ln.CHART_ID
      																	and   ln.CATEGORY_ID = 2) then (select ln.CREATING_USER_PROFILE_ID from LOG_NOTE ln WITH (NOLOCK)
      																	where ln.CHART_ID = bc.CHART_ID
      																	and   ln.CATEGORY_ID = 2
      																	and   ln.LOG_NOTE_ID = (select min(ln2.LOG_NOTE_ID) from log_note ln2  WITH (NOLOCK)
      																		where ln2.CHART_ID = bc.CHART_ID
      																		and   ln2.CATEGORY_ID = 2))
                 else c.COMPLETED_BY_USER_PROFILE_ID end CODED_BY_ID,
             
             case when c.PATIENT_DISPOSITION_ID <> 5 then 1
      			      when c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID =(SELECT sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID  
      														  FROM  SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao 
      														  WHERE sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD = 1 
      														  AND sao.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID) then 1		
                  else 0 end ED_Ind,   
                             
             case when c.INITIAL_CHARGE_MASTER_DEPT_ID is null then 0 
                  when c.INITIAL_CHARGE_MASTER_DEPT_ID = -1 then 0
                  when c.INITIAL_CHARGE_MASTER_DEPT_ID = 0 then 0
                  when c.INITIAL_CHARGE_MASTER_DEPT_ID is not null 
                     and c.INITIAL_CHARGE_MASTER_DEPT_ID <> -1 
                     and c.INITIAL_CHARGE_MASTER_DEPT_ID <> 0
                     and (select distinct 1 from charge_master_department cmd 
                          where  cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
                          and    c.TIME_OF_DIS not between cmd.EFFECTIVE_DATE and cmd.EXPIRATION_DATE) = 1 then 0
                  else 1 end OBS_Ind,
                  
             case when (select distinct 1 from USER_PROFILE up 
                        where  up.USER_PROFILE_ID = c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID
                        and    up.USER_CLASS_CD = 4) = 1 then 1 else 0 end OBS_Client_User,
                        
             case when c.observation_completed_by_user_profile_id = -1 
      					      and sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 
      					      and c.PATIENT_DISPOSITION_ID = 5 then 1 
                  else 0 end OBS_CCS_User,
                      
             case when sa.TURNAROUND_HOURS_REPORTING_METHOD in (1) then datediff(minute, c.DATE_RECEIVED, c.SENT_DATE)/60
				  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (2) then datediff(minute, c.DATE_RECEIVED, c.APPROVED_DATE)/60
                  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (3) then datediff(minute, c.CREATION_DATE_TIME, c.SENT_DATE)/60
                  when sa.TURNAROUND_HOURS_REPORTING_METHOD in (4) then datediff(minute, c.CREATION_DATE_TIME, c.APPROVED_DATE)/60
                  when sa.TURNAROUND_HOURS_REPORTING_METHOD = 5 then datediff(minute, dateadd(minute, sa.TURNAROUND_START_TIME_IN_MINUTES, convert(datetime, convert(varchar, c.CREATION_DATE_TIME, 112), 112)), c.APPROVED_DATE)/60
                  when sa.TURNAROUND_HOURS_REPORTING_METHOD = 6
                        THEN 
							case when (select count(*) from LOG_NOTE l where l.CHART_ID = c.CHART_ID and 
										l.CATEGORY_ID = 8 and (l.SUMMARY LIKE 'Chart status changed to Work in Progress%' OR
      									l.DETAIL LIKE 'Chart status changed to Work in Progress%')) > 0 
      							THEN
								datediff(minute, 
								(SELECT MAX(ln.COMPLETION_DATE)
								   FROM   LOG_NOTE ln WITH(NOLOCK)
								   WHERE  ln.CHART_ID = c.CHART_ID AND (ln.CATEGORY_ID = 1 OR (ln.CATEGORY_ID = 8
									 AND (ln.SUMMARY LIKE 'Chart status changed to Work in Progress%' OR
      									ln.DETAIL LIKE 'Chart status changed to Work in Progress%'))))
      									, c.SENT_DATE)/60
      							ELSE
      							datediff(minute, c.CREATION_DATE_TIME, c.SENT_DATE)/60
      							END
                  when sa.TURNAROUND_HOURS_REPORTING_METHOD = 7
                        THEN 
							case when (select count(*) from LOG_NOTE l where l.CHART_ID = c.CHART_ID and 
										l.CATEGORY_ID = 8 and (l.SUMMARY LIKE 'Chart status changed to Work in Progress%' OR
      									l.DETAIL LIKE 'Chart status changed to Work in Progress%')) > 0 
      							THEN
								datediff(minute, 
								(SELECT MAX(ln.COMPLETION_DATE)
								   FROM   LOG_NOTE ln WITH(NOLOCK)
								   WHERE  ln.CHART_ID = c.CHART_ID AND (ln.CATEGORY_ID = 1 OR (ln.CATEGORY_ID = 8
									 AND (ln.SUMMARY LIKE 'Chart status changed to Work in Progress%' OR
      									ln.DETAIL LIKE 'Chart status changed to Work in Progress%'))))
      									, c.APPROVED_DATE)/60
      							ELSE
      							datediff(minute, c.CREATION_DATE_TIME, c.APPROVED_DATE)/60
      							END
                  when sa.TURNAROUND_HOURS_REPORTING_METHOD = 8
                        THEN datediff(minute, 
                          (SELECT MAX(ii.CREATION_DATE_TIME)
                           FROM   IMPORT_IMAGE ii WITH(NOLOCK)
                           WHERE  ii.CHART_ID = c.CHART_ID)
      						    , c.APPROVED_DATE)/60	
                  when sa.TURNAROUND_HOURS_REPORTING_METHOD = 9
                        THEN datediff(minute, 
                                              (SELECT MAX(ii.CREATION_DATE_TIME)
                           FROM   IMPORT_IMAGE ii WITH(NOLOCK)
                           WHERE  ii.CHART_ID = c.CHART_ID)
      						    , c.APPROVED_DATE)/60																		        
                  else 0 end SLA_HOURS,
                  
             case when (select distinct 'Y' 
                        from LOG_NOTE ln WITH (NOLOCK) 
                        where ln.CHART_ID = c.CHART_ID 
                        and ln.CATEGORY_ID = 6) = 'Y' then 'Y' 
                  else 'N' end Pended,
                  
             sa.SLA_RATE_METHOD_IND
                  
      from  billed_chart bc WITH (NOLOCK), 
            chart c WITH (NOLOCK), 
            billing_control bctl WITH (NOLOCK), 
            service_agreement sa WITH (NOLOCK)
      where bctl.BILLING_CONTROL_ID = bc.BILLING_CONTROL_ID
      and   bctl.BILLING_CONTROL_ID = @billingPeriod
      and   bc.TYPE_CD = 'B'
      and   c.CHART_ID = bc.CHART_ID
      and   sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   sa.ORGANIZATION_ID = 1
      and   sa.DEMO_TEST_SITE_IND <> 1) x
where x.CODED_BY_ID = up.USER_PROFILE_ID) y
group by y.RATE_DATE,
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
         y.EMIncrementRate) z) w) v
where v.Facility_ID = f.FACILITY_ID
group by f.FACILITY_ID, isnull(nullif(f.ACCOUNTING_FACILITY_CODE, ''), f.FACILITY_NUMBER), v.Rate_Class, v.CCSRate, v.ProFeeRate, v.SaaSRate, v.EMIncrementRate, v.FS_With_Obs_Rate, v.SaasObsOnlyRate, v.CCSObsOnlyRate, v.Saas_Obs_With_CCS_ED_Rate) u
order by u.FACILITY, u.Rate_Class


END




GO
