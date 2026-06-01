SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[Refresh_Daily_Snapshot_Tables_2]
WITH EXEC AS CALLER
AS
-- Sent Procedure 2 Table
-- Drop Indexes and Truncate Table
TRUNCATE TABLE [CCSTransactionSnapshot].[DBO].[SENT_PROCEDURE_2];
-- Recreate Table Data
insert into [CCSTransactionSnapshot].[DBO].SENT_PROCEDURE_2
(CLASS, CHART_ID, FACILITY_CHART_ID, SERVICE_AGREEMENT_ID, TIME_OF_SERVICE, SENT_DATE, PATIENT_DISPOSITION_ID, PHYSICIAN_ID, BILLING_CODE, CPT_CODE, QUANTITY, FACILITY_ID, PATIENT_CLASS_ID, ADJUSTMENT_IND, CHARGE_MASTER_ID)
select 'FP' as CLASS, 
				c.CHART_ID,
				c.FACILITY_CHART_ID,
				c.SERVICE_AGREEMENT_ID,
				c.TIME_OF_SERVICE,
				c.SENT_DATE,
				c.PATIENT_DISPOSITION_ID,
				case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						 end as PHYSICIAN_ID,
				cm.BILLING_CODE,
				cm.CPT_CODE,
				fpe.QUANTITY,
				c.facility_id,
				case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
        cm.CHARGE_MASTER_ID
from   facility_procedure_evaluation fpe with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = fpe.CHART_ID
and    c.CHART_STATUS_ID = 5 
and    cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa
				where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
union all
select 'IP' as CLASS, 
				c.CHART_ID,
				c.FACILITY_CHART_ID,
				c.SERVICE_AGREEMENT_ID,
				c.TIME_OF_SERVICE,
				c.SENT_DATE,
				c.PATIENT_DISPOSITION_ID,
				case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						 end as PHYSICIAN_ID,
				cm.BILLING_CODE,
				cm.CPT_CODE,
				cir.UNITS Quantity,
				c.facility_id,
				case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
        cm.CHARGE_MASTER_ID
from   chart_infusion_result cir with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = cir.CHART_ID
and    c.CHART_STATUS_ID = 5 
and    cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa with (NOLOCK)
				where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
union all
select 'PP' as Class, 
				c.CHART_ID,
				c.FACILITY_CHART_ID,
				c.SERVICE_AGREEMENT_ID,
				c.TIME_OF_SERVICE,
				c.SENT_DATE,
				c.PATIENT_DISPOSITION_ID,
				case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						 end as PHYSCISIAN_ID,
				cm.BILLING_CODE,
				cm.CPT_CODE,
				ppe.QUANTITY,
				c.facility_id,
				case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
        cm.CHARGE_MASTER_ID
from   physician_procedure_evaluation ppe with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = ppe.CHART_ID
and    c.CHART_STATUS_ID = 5
and    cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa with (NOLOCK)
				where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
union all
select case when cm.CHARGE_MASTER_USAGE_CODE = 2 then 'FL' 
            when cm.CHARGE_MASTER_USAGE_CODE = 3 then 'FP' 
	     	when cm.CHARGE_MASTER_USAGE_CODE = 4 then 'PL'
	    	when cm.CHARGE_MASTER_USAGE_CODE = 5 then 'PP'
	   else 'CA' end	as Class,
			 c.CHART_ID,
			 c.FACILITY_CHART_ID,
			 c.SERVICE_AGREEMENT_ID,
			 c.TIME_OF_SERVICE,
			 c.SENT_DATE,
				c.PATIENT_DISPOSITION_ID,
				case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						 end as PHYSCISIAN_ID,
			 cm.BILLING_CODE,
			 cm.CPT_CODE,
			 ca.QUANTITY,
			 c.facility_id,
				case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
        'Y' as ADJUSTMENT_IND,
        cm.CHARGE_MASTER_ID
from chart_adjustment ca with (NOLOCK), charge_master cm with (NOLOCK), chart c with (NOLOCK)
where  c.CHART_ID = ca.CHART_ID
and	   c.CHART_STATUS_ID = 5
and    cm.CHARGE_MASTER_ID = ca.CHARGE_MASTER_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa with (NOLOCK)
				where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
union all
select 'FL' as Class,
			 c.CHART_ID,
			 c.FACILITY_CHART_ID,
			 c.SERVICE_AGREEMENT_ID,
			 c.TIME_OF_SERVICE,
			 c.SENT_DATE,
			 c.PATIENT_DISPOSITION_ID,
				case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
						 end as PHYSCISIAN_ID,
			 fl.BILLING_CODE,
			 fl.CPT_CODE,
			 1 as QUANTITY,
			 c.facility_id,
				case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
        coalesce((select max(cm.charge_master_id) from charge_master cm with (nolock) 
        where cm.BILLING_CODE = fl.BILLING_CODE  
        AND    cm.CPT_CODE = fl.CPT_CODE
        AND    cm.SERVICE_AGREEMENT_ID = fl.SERVICE_AGREEMENT_ID
        AND    cm.CHARGE_MASTER_USAGE_CODE = 2
        and    cm.EFFECTIVE_DATE <= getdate()
        and    cm.EXPIRATION_DATE >= getdate()
        and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) as charge_master_id
from   chart c with (NOLOCK), facility_level fl with (NOLOCK), SERVICE_AGREEMENT sa with (NOLOCK)
where  c.CHART_STATUS_ID = 5
and    sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
and    (c.OVERRIDE_FACILITY_LEVEL_ID <> -1
    or  c.FACILITY_LEVEL_ID <> -1)
and		(case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
            when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
			 else c.OVERRIDE_FACILITY_LEVEL_ID
			 end) = fl.FACILITY_LEVEL_ID
and    c.TIME_OF_SERVICE >= sa.EFFECTIVE_DATE
union all
select  'PL' as Class,
				c.CHART_ID, 
				c.FACILITY_CHART_ID, 
				c.SERVICE_AGREEMENT_ID,
				c.TIME_OF_SERVICE,
				c.SENT_DATE,
				c.PATIENT_DISPOSITION_ID,
				case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end as PHYSICIAN_ID,
				case when c.PHYSICIAN_CRITICAL_CARE = 1 then 
					(select pcc.BILLING_CODE from physician_critical_care pcc with (NOLOCK)
											where pcc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID 
											and   pcc.CRITICAL_CARE_CODE_ID = 1)
				else
					(select psp.BILLING_CODE from physician_service_procedure psp with (NOLOCK)
											where psp.PHYSICIAN_SERVICE_PROC_ID = 
													(case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
						 						 				and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
																then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
																else c.PHYSICIAN_SERVICE_PROC_ID end))
				end as BILLING_CD,
				case when c.PHYSICIAN_CRITICAL_CARE = 1 then '99291' else
					(select psp.CPT_CODE from physician_service_procedure psp with (NOLOCK)
						where psp.PHYSICIAN_SERVICE_PROC_ID = 
								(case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
													and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
											then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
											else c.PHYSICIAN_SERVICE_PROC_ID end)) 
				end as CPT_CD,
				1 as Quantity,
				c.facility_id,
				case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
       coalesce((select max(cm.charge_master_id) from charge_master cm with (nolock) 
        where cm.BILLING_CODE = (case when c.PHYSICIAN_CRITICAL_CARE = 1 then 
				                    (select pcc.BILLING_CODE from physician_critical_care pcc with (NOLOCK)
											       where pcc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID 
											       and   pcc.CRITICAL_CARE_CODE_ID = 1)
				                    else (select psp.BILLING_CODE from physician_service_procedure psp with (NOLOCK)
											            where psp.PHYSICIAN_SERVICE_PROC_ID = 
													              (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
						 						 				         and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
																         then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
																         else c.PHYSICIAN_SERVICE_PROC_ID end))end)
AND cm.CPT_CODE = (case when c.PHYSICIAN_CRITICAL_CARE = 1 then '99291' else
                  (select psp.CPT_CODE from physician_service_procedure psp with (NOLOCK)
						       where psp.PHYSICIAN_SERVICE_PROC_ID = 
								         (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
													          and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
											         then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
											         else c.PHYSICIAN_SERVICE_PROC_ID end))end)
AND cm.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
and    cm.EFFECTIVE_DATE <= getdate()
and    cm.EXPIRATION_DATE >= getdate()
AND cm.CHARGE_MASTER_USAGE_CODE = 4
and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) as charge_master_id
from chart c with (NOLOCK), service_agreement sa with (NOLOCK)
where		c.CHART_STATUS_ID = 5
and     sa.service_agreement_id = c.service_agreement_id
and     sa.evaluate_physician_svc = 1
and    c.TIME_OF_SERVICE >= sa.EFFECTIVE_DATE
and	    (c.NO_PHYSICIAN_SERVICES is null
or    c.NO_PHYSICIAN_SERVICES = 0);
GO
