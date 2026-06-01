SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[Refresh_Daily_Snapshot_Tables_TEST]
WITH EXEC AS CALLER
AS
-- Sent Procedure Table
-- Drop Indexes and Truncate Table
DROP INDEX [AI_SP_FACILITY_PHYSICIAN] ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AX_SP_CLASS_PATIENT_DISP_SA_PATIENT_CLASS_DOS] ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_SP_SA_SENTDT] ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_SP_SA_DOS] ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_SP_CHARTID] ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE];
TRUNCATE TABLE [CCSTransactionSnapshot].[DBO].[SENT_PROCEDURE];
-- Recreate Table Data
insert into SENT_PROCEDURE
(CLASS, CHART_ID, FACILITY_CHART_ID, SERVICE_AGREEMENT_ID, TIME_OF_SERVICE, SENT_DATE, PATIENT_DISPOSITION_ID, PHYSICIAN_ID, BILLING_CODE, CPT_CODE, QUANTITY, FACILITY_ID, PATIENT_CLASS_ID, ADJUSTMENT_IND, CHARGE_MASTER_ID, LEVEL_ID)
select 'FP' as CLASS, 
				c.CHART_ID,
				c.FACILITY_CHART_ID,
				c.SERVICE_AGREEMENT_ID,
				coalesce(fpe.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
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
        cm.CHARGE_MASTER_ID,
        0 as LEVEL_ID
from   facility_procedure_evaluation fpe with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = fpe.CHART_ID
and    c.CHART_STATUS_ID = 5 
and    cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa
				where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
union all
select 'FP' as CLASS,   -- Package Items (e.g. generated supplies)
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
				cpi.UNITS Quantity,
				c.facility_id,
				case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
					(select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
						where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
						and   pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
        cm.CHARGE_MASTER_ID,
        0 as LEVEL_ID
from   CHART_PACKAGE_ITEM cpi with (NOLOCK), CHARGE_PACKAGE_ITEM ci with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = cpi.CHART_ID
and    c.CHART_STATUS_ID = 5 
and    ci.CHARGE_PACKAGE_ITEM_ID = cpi.CHARGE_PACKAGE_ITEM_ID
and    cm.CHARGE_MASTER_ID = ci.CHARGE_MASTER_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa
				where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
union all
select 'IP' as CLASS, 
				c.CHART_ID,
				c.FACILITY_CHART_ID,
				c.SERVICE_AGREEMENT_ID,
				coalesce(cir.DATE_OF_SERVICE,c.TIME_OF_SERVICE) TIME_OF_SERVICE,
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
        cm.CHARGE_MASTER_ID,
        0 as LEVEL_ID
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
				coalesce(ppe.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
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
        cm.CHARGE_MASTER_ID,
        0 as LEVEL_ID
from   physician_procedure_evaluation ppe with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = ppe.CHART_ID
and    c.CHART_STATUS_ID = 5
and    cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa with (NOLOCK)
				where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
union all  --Adjustments
select case when cm.CHARGE_MASTER_USAGE_CODE = 2 then 'FL' 
            when cm.CHARGE_MASTER_USAGE_CODE = 3 then 'FP' 
	     	when cm.CHARGE_MASTER_USAGE_CODE = 4 then 'PL'
	    	when cm.CHARGE_MASTER_USAGE_CODE = 5 then 'PP'
	   else 'CA' end	as Class,
			 c.CHART_ID,
			 c.FACILITY_CHART_ID,
			 c.SERVICE_AGREEMENT_ID,
			 coalesce(ca.REVISED_DATE_OF_SERVICE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
			 c.SENT_DATE,
       (case when c.PATIENT_DISPOSITION_ID in (-1, 0) then 
              coalesce((select distinct 4 
               from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs
               where fse.CHART_ID = c.chart_id
               and   fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
               and   (left(fs.DESCRIPTION,9) = 'Admission' or left(fs.DESCRIPTION,5) = 'Admit')),1)
             when c.PATIENT_DISPOSITION_ID is null then 1
	           else c.PATIENT_DISPOSITION_ID end)  PATIENT_DISPOSITION_ID,
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
        cm.CHARGE_MASTER_ID,
        case when cm.CHARGE_MASTER_USAGE_CODE = 2 then (select max(fl.FACILITY_LEVEL_ID) from FACILITY_LEVEL fl
              where fl.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
              and   fl.BILLING_CODE = cm.BILLING_CODE)
             when cm.CHARGE_MASTER_USAGE_CODE = 4 and cm.cpt_code not in ('99291', '99292') then 
               (select max(psp.PHYSICIAN_SERVICE_PROC_ID) from PHYSICIAN_SERVICE_PROCEDURE psp with (NOLOCK)
                where psp.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
                and   psp.BILLING_CODE = cm.BILLING_CODE)
             when cm.CHARGE_MASTER_USAGE_CODE = 4 and cm.cpt_code in ('99291', '99292') then -1  --Critical Care
             else 0 end as LEVEL_ID
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
       (case when c.PATIENT_DISPOSITION_ID in (-1, 0) then 
              coalesce((select distinct 4 
               from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs
               where fse.CHART_ID = c.chart_id
               and   fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
               and   (left(fs.DESCRIPTION,9) = 'Admission' or left(fs.DESCRIPTION,5) = 'Admit')),1)
             when c.PATIENT_DISPOSITION_ID is null then 1
	           else c.PATIENT_DISPOSITION_ID end)  PATIENT_DISPOSITION_ID,
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
        and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) as charge_master_id,
       (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
            when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
            else c.OVERRIDE_FACILITY_LEVEL_ID end) LEVEL_ID
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
       (case when c.PATIENT_DISPOSITION_ID in (-1, 0) then 
              coalesce((select distinct 4 
               from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs
               where fse.CHART_ID = c.chart_id
               and   fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
               and   (left(fs.DESCRIPTION,9) = 'Admission' or left(fs.DESCRIPTION,5) = 'Admit')),1)
             when c.PATIENT_DISPOSITION_ID is null then 1
	           else c.PATIENT_DISPOSITION_ID end)  PATIENT_DISPOSITION_ID,
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
            and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) as charge_master_id,
				case when c.PHYSICIAN_CRITICAL_CARE = 1 then -1 
             else (select psp.PHYSICIAN_SERVICE_PROC_ID 
                   from   physician_service_procedure psp with (NOLOCK)
						       where  psp.PHYSICIAN_SERVICE_PROC_ID = 
								          (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
													           and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
											               then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
											          else c.PHYSICIAN_SERVICE_PROC_ID end)) 
				end as LEVEL_ID
from chart c with (NOLOCK), service_agreement sa with (NOLOCK)
where		c.CHART_STATUS_ID = 5
and     sa.service_agreement_id = c.service_agreement_id
and     sa.evaluate_physician_svc = 1
and    c.TIME_OF_SERVICE >= sa.EFFECTIVE_DATE
and	    (c.NO_PHYSICIAN_SERVICES is null
or    c.NO_PHYSICIAN_SERVICES = 0);
-- Recreate Indexes
CREATE NONCLUSTERED INDEX [AI_SP_FACILITY_PHYSICIAN]
ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([class] , [patient_disposition_id] , [facility_id] , [service_agreement_id] , [physician_id] , [time_of_service] , [cpt_code] , [chart_id] , [seq])
WITH
(PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
MAXDOP = 0)
ON [PRIMARY];
CREATE NONCLUSTERED INDEX [AX_SP_CLASS_PATIENT_DISP_SA_PATIENT_CLASS_DOS]
ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([class] , [patient_disposition_id] , [facility_id] , [service_agreement_id] , [patient_class_id] , [time_of_service] , [cpt_code] , [chart_id] , [seq])
WITH
(PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
MAXDOP = 0)
ON [PRIMARY];
CREATE NONCLUSTERED INDEX [AI_SP_SA_SENTDT]
ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([service_agreement_id] , [sent_date] , [chart_id] , [facility_chart_id] , [time_of_service] , [billing_code] , [cpt_code] , [quantity] , [facility_id] , [adjustment_ind])
WITH
(PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
MAXDOP = 0)
ON [PRIMARY];
CREATE NONCLUSTERED INDEX [AI_SP_SA_DOS]
ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([service_agreement_id] , [time_of_service] , [chart_id] , [cpt_code] , [physician_id] , [billing_code] , [class] , [quantity])
WITH
(PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
MAXDOP = 0)
ON [PRIMARY];
CREATE NONCLUSTERED INDEX [AI_SP_CHARTID]
ON [CCSTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([chart_id] , [service_agreement_id] , [facility_chart_id] , [charge_master_id] , [seq])
WITH
(PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
MAXDOP = 0)
ON [PRIMARY];
-- CHART_AUDIT_ACTION
-- Drop Index and Truncate Table
-- CHART_AUDIT_ACTION
	DROP INDEX [AI_CHART_AUDIT_ACTION] ON [dbo].[CHART_AUDIT_ACTION];
	TRUNCATE TABLE [dbo].[CHART_AUDIT_ACTION];
	-- Recreate Table Data
	insert into CHART_AUDIT_ACTION
	(CLASS, ACTION, CHART_ID, DESCRIPTION)
	select '1' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID,
				 (select fs.DESCRIPTION from facility_service fs with (NOLOCK)
						where fs.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID) 'Description'
	from  facility_service_evaluation_history fseh with (NOLOCK), chart c with (NOLOCK)
	where fseh.CHART_ID not in (select fse.CHART_ID from facility_service_evaluation fse with (NOLOCK)
				where fse.CHART_ID = fseh.CHART_ID
				and   fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = fseh.FACILITY_SVC_EVAL_ID
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION_HISTORY') = 0 
	and   c.CHART_ID = fseh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union 
	select '1' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID,
				 (select fs.DESCRIPTION from facility_service fs with (NOLOCK)
						where fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID) 'Description'
	from  facility_service_evaluation fse with (NOLOCK), chart c with (NOLOCK)
	where fse.CHART_ID not in (select fseh.CHART_ID from facility_service_evaluation_history fseh with (NOLOCK)
				where fseh.CHART_ID = fse.CHART_ID
				and   fseh.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = fse.FACILITY_SVC_EVAL_ID
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION') = 0 and   c.CHART_ID = fse.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '2' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID, 
				 (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
				  where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
	from facility_procedure_evaluation_history fpeh with (NOLOCK), chart c with (NOLOCK), CHARGE_MASTER cm with (NOLOCK)
	where fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
				where fpe.CHART_ID = fpeh.CHART_ID
				--and	  cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'
				--and	  (select COUNT(*) from CHARGE_MASTER cm2 where cm2.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm2.CPT_CODE <> 'SUPLY') = 0
				and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0			
	and   c.CHART_ID = fpeh.CHART_ID
	and	  cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'	
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '2' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID, 
				 (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
				  where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
	from facility_procedure_evaluation fpe with (NOLOCK), chart c with (NOLOCK), CHARGE_MASTER cm with (NOLOCK)
	where fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK), CHARGE_MASTER cm with (NOLOCK)
				where fpe.CHART_ID = fpeh.CHART_ID
				--and   cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'
				--and	  (select COUNT(*) from CHARGE_MASTER cm2 where cm2.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm2.CPT_CODE <> 'SUPLY') = 0				
				and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0			
	and   c.CHART_ID = fpe.CHART_ID
	and	  cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'	
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '3' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID, 
				 (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
				  where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
	from chart_infusion_result_history cirh with (NOLOCK), chart c with (NOLOCK)
	where cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
				where cir.CHART_ID = cirh.CHART_ID
				and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0			
	and   c.CHART_ID = cirh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '3' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID, 
				 (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
				  where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
	from chart_infusion_result cir, chart c
	where cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
				where cir.CHART_ID = cirh.CHART_ID
				and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0				
	and   c.CHART_ID = cir.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '4' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID,
				 (select ps.DESCRIPTION from physician_service ps with (NOLOCK)
						where ps.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID) 'Description'
	from  physician_service_eval_history pseh with (NOLOCK), chart c with (NOLOCK)
	where pseh.CHART_ID not in (select pse.CHART_ID from physician_service_eval pse with (NOLOCK)
				where pse.CHART_ID = pseh.CHART_ID
				and   pse.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = pseh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pseh.PHYSICIAN_SERVICE_ID)
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL_HISTORY') = 0			
	and   c.CHART_ID = pseh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union 
	select '4' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID,
				 (select ps.DESCRIPTION from physician_service ps with (NOLOCK)
						where ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID) 'Description'
	from  physician_service_eval pse with (NOLOCK), chart c with (NOLOCK)
	where pse.CHART_ID not in (select pseh.CHART_ID from physician_service_eval_history pseh with (NOLOCK)
				where pseh.CHART_ID = pse.CHART_ID
				and   pseh.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = pse.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pse.PHYSICIAN_SERVICE_ID)
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL') = 0				
	and   c.CHART_ID = pse.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '5' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID, 
				 (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
				  where cm.CHARGE_MASTER_ID = ppeh.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
	from physician_procedure_evaluation_history ppeh with (NOLOCK), chart c with (NOLOCK)
	where ppeh.CHART_ID not in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
				where ppe.CHART_ID = ppeh.CHART_ID
				and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = ppeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppeh.PHYSICIAN_PROCEDURE_ID)
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY') = 0				
	and   c.CHART_ID = ppeh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '5' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID, 
				 (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
				  where cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
	from physician_procedure_evaluation ppe with (NOLOCK), chart c with (NOLOCK)
	where ppe.CHART_ID not in (select ppeh.CHART_ID from physician_procedure_evaluation_history ppeh with (NOLOCK)
				where ppe.CHART_ID = ppeh.CHART_ID
				and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = ppe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppe.PHYSICIAN_PROCEDURE_ID)
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0			
	and   c.CHART_ID = ppe.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '6' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID, 
				 (select ic.icd9_code + ', ' + ic.short_description from icd_9_cm ic with (NOLOCK)
				  where ic.icd9_code = cdch.ICD9_CODE
					and   ic.effective_date <= c.time_of_service
					and   ic.expiration_date >= c.time_of_service) 'Description'
	from chart_diagnosis_code_history cdch with (NOLOCK), chart c with (NOLOCK)
	where cdch.CHART_ID not in (select cdc.CHART_ID from chart_diagnosis_code cdc with (NOLOCK)
				where cdc.CHART_ID = cdch.CHART_ID
				and   cdc.ICD9_CODE = cdch.ICD9_CODE)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = cdch.CHART_ID and qa.KEY_VALUE_2 = cdch.ICD9_CODE
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE_HISTORY') = 0			
	and   c.CHART_ID = cdch.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '6' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID, 
				 (select ic.icd9_code + ', ' + ic.short_description from icd_9_cm ic with (NOLOCK)
				  where ic.icd9_code = cdc.ICD9_CODE
					and   ic.effective_date <= c.time_of_service
					and   ic.expiration_date >= c.time_of_service) 'Description'
	from chart_diagnosis_code cdc with (NOLOCK), chart c with (NOLOCK)
	where cdc.CHART_ID not in (select cdch.CHART_ID from chart_diagnosis_code_history cdch with (NOLOCK)
				where cdc.CHART_ID = cdch.CHART_ID
				and   cdc.ICD9_CODE = cdch.ICD9_CODE)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = cdc.CHART_ID and qa.KEY_VALUE_2 = cdc.ICD9_CODE
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE') = 0				
	and   c.CHART_ID = cdc.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '7' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID,
				 fl.DESCRIPTION Description
	from  chart_los_history clh with (NOLOCK), chart c with (NOLOCK), facility_level fl with (NOLOCK)
	where c.CHART_ID = clh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0				
	and   fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
	and   fl.FACILITY_LEVEL_ID = (case when clh.OVERRIDE_FACILITY_LEVEL_ID = -1 
						then clh.FACILITY_LEVEL_ID else clh.OVERRIDE_FACILITY_LEVEL_ID end)
	and   fl.CPT_CODE <> (select fl2.CPT_CODE from facility_level fl2 with (NOLOCK) 
					where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
					and   ((case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 
						then c.FACILITY_LEVEL_ID else c.OVERRIDE_FACILITY_LEVEL_ID end) = fl2.FACILITY_LEVEL_ID))
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '7' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID, 
				 fl.DESCRIPTION Description
	from chart_los_history clh with (NOLOCK), chart c with (NOLOCK), facility_level fl with (NOLOCK)
	where c.CHART_ID = clh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0					
	and   fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
	and   fl.FACILITY_LEVEL_ID = (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 
						then c.FACILITY_LEVEL_ID else c.OVERRIDE_FACILITY_LEVEL_ID end)
	and   fl.CPT_CODE <> (select fl2.CPT_CODE from facility_level fl2 with (NOLOCK) 
					where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
					and   ((case when clh.OVERRIDE_FACILITY_LEVEL_ID = -1 
						then clh.FACILITY_LEVEL_ID else clh.OVERRIDE_FACILITY_LEVEL_ID end) = fl2.FACILITY_LEVEL_ID))
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	union
	select '8' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID,
				 psp.DESCRIPTION Description
	from  chart_los_history clh with (NOLOCK), chart c with (NOLOCK), physician_service_procedure psp with (NOLOCK)
	where c.CHART_ID = clh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'PLOS'
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0					
	and   psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
	and   psp.PHYSICIAN_SERVICE_PROC_ID = (case when clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
						then clh.PHYSICIAN_SERVICE_PROC_ID else clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
	and   psp.CPT_CODE <> (select psp2.CPT_CODE from physician_service_procedure psp2 with (NOLOCK) 
					where psp2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
					and   ((case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
						then c.PHYSICIAN_SERVICE_PROC_ID else c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end) = psp2.PHYSICIAN_SERVICE_PROC_ID))
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	and   clh.PHYSICIAN_CRITICAL_CARE <> 1
	union
	select '8' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID, 
				 psp.DESCRIPTION Description
	from chart_los_history clh with (NOLOCK), chart c with (NOLOCK), physician_service_procedure psp with (NOLOCK)
	where c.CHART_ID = clh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and	  (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
			where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'PLOS'
			and	  qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0					
	and   psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
	and   psp.PHYSICIAN_SERVICE_PROC_ID = (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
						then c.PHYSICIAN_SERVICE_PROC_ID else c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
	and   psp.CPT_CODE <> (select psp2.CPT_CODE from physician_service_procedure psp2 with (NOLOCK)
					where psp2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
					and   ((case when clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
						then clh.PHYSICIAN_SERVICE_PROC_ID else clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end) = psp2.PHYSICIAN_SERVICE_PROC_ID))
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	and   c.PHYSICIAN_CRITICAL_CARE <> 1
	union
	select '8' as 'Class',
				 'R' as 'Action',
				 c.CHART_ID,
				 'Critical Care' Description
	from  chart_los_history clh with (NOLOCK), chart c with (NOLOCK)
	where c.CHART_ID = clh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	and   clh.PHYSICIAN_CRITICAL_CARE = 1
	and   c.PHYSICIAN_CRITICAL_CARE <> 1
	union
	select '8' as 'Class',
				 'A' as 'Action',
				 c.CHART_ID, 
				 'Critical Care' Description
	from chart_los_history clh with (NOLOCK), chart c with (NOLOCK)
	where c.CHART_ID = clh.CHART_ID
	and   c.CHART_STATUS_ID in (4, 5)
	and   ((case when c.SENT_DATE is null then '20080510'
			else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	and   c.PHYSICIAN_CRITICAL_CARE = 1
	and   clh.PHYSICIAN_CRITICAL_CARE <> 1;
	-- Recreate Index
	CREATE NONCLUSTERED INDEX [AI_CHART_AUDIT_ACTION] ON [dbo].[CHART_AUDIT_ACTION]
	([CHART_ID] , [CLASS] , [ACTION] , [SEQ])
	WITH
	(PAD_INDEX = OFF,
	FILLFACTOR = 100,
	IGNORE_DUP_KEY = OFF,
	STATISTICS_NORECOMPUTE = OFF,
	ALLOW_ROW_LOCKS = ON,
	ALLOW_PAGE_LOCKS = ON,
	MAXDOP = 0)
	ON [PRIMARY];
	-- CHART_AUDIT_RESULTS
	-- Drop Indexes and Truncate Table
	DROP INDEX [AI_CAR_APPROVEDT_CUID_FACILITY_CNAME] ON [CCSTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT];
	DROP INDEX [AI_CAR_APPROVEDT_CUID_MANAGER_FACILITY_CNAME] ON [CCSTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT];
	DROP INDEX [AI_CAR_APPROVEDT_FACILITY_CUID_CNAME] ON [CCSTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT];
	TRUNCATE TABLE [CCSTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT];
	-- Recreate Table Data
	insert into CHART_AUDIT_RESULT
	(FACILITY_ID, FNAME, MANAGER_ID, CUID, CNAME, AUID, ANAME, APPROVED_DATE, FACILITY_CHART_ID, CHART_ID, DOS, FLOS_COMMENT,
		FINJ_COMMENT, FPROC_COMMENT, PLOS_COMMENT, PPROC_COMMENT, DIAG_COMMENT, AUDITED, FA, FPA, FIA, FLOSE, 
		FINJE, FPROCE, PA, PPA, PLOSE, PPROCE, DA, DE)
	select x.FACILITY_ID,
				 f.NAME FNAME,
				 (select max(fua.user_profile_id) from facility_user_authorization fua with (NOLOCK)
			 					where fua.facility_id = x.facility_id
								and   fua.account_manager_ind = 1) MANAGER_ID,
				 x.CUID,
				 up.LAST_NAME + ', ' + up.FIRST_NAME CNAME,
				 x.AUID,
				 aup.LAST_NAME + ', ' + aup.FIRST_NAME ANAME,
				 x.APPROVED_DATE,
				 x.FACILITY_CHART_ID,
				 x.CHART_ID,
				 x.DOS,
				 x.FLOS_COMMENT,
				 x.FINJ_COMMENT,
				 x.FPROC_COMMENT,
				 x.PLOS_COMMENT,
				 x.PPROC_COMMENT,
				 x.DIAG_COMMENT,
				 X.AUDITED,
				 x.FA,
				 x.FPA,
				 x.FIA,
				 x.FLOSE,
				 x.FINJE,
				 x.FPROCE,
				 x.PA,
				 x.PPA,
				 x.PLOSE,
				 x.PPROCE,
				 x.DA,
				 x.DE			 
	from facility f with (NOLOCK), user_profile up with (NOLOCK), user_profile aup with (NOLOCK),
	(select c.FACILITY_ID, 
				 (select ln.COMPLETED_BY_USER_ID from log_note ln with (NOLOCK)
	where  ln.LOG_NOTE_ID = (select min(ln2.LOG_NOTE_ID) from log_note ln2 with (NOLOCK)
							where  ln2.CHART_ID = c.CHART_ID
							and    ln2.CATEGORY_ID = 2)) CUID,
				 c.APPROVED_BY_USER_PROFILE_ID AUID,
				 c.APPROVED_DATE,
				 c.FACILITY_CHART_ID,
				 c.CHART_ID,
				 c.TIME_OF_SERVICE DOS,
				 c.FACILITY_SERVICE_LEVEL_AUDIT_COMMENT FLOS_COMMENT,
				 c.INFUSION_INJECTION_AUDIT_COMMENT FINJ_COMMENT,
				 c.FACILITY_PROCEDURES_AUDIT_COMMENT FPROC_COMMENT,
				 c.PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT PLOS_COMMENT,
				 c.PHYSICIAN_PROCEDURES_AUDIT_COMMENT PPROC_COMMENT,
				 c.DIAGNOSIS_CODING_AUDIT_COMMENT DIAG_COMMENT,
				 case when c.APPROVAL_REASON_CODE = 3 then 1 else 0 end AUDITED,
				 case when c.APPROVAL_REASON_CODE = 3 then 
			 			(case when sa.EVALUATE_FACILITY_SVC = 1 then 1 else 0 end) else 0 end as FA,
				 case when c.APPROVAL_REASON_CODE = 3 then 
			 			(case when sa.EVALUATE_FACILITY_PROCEDURES = 1 then 1 else 0 end) else 0 end as FPA,
				 case when c.APPROVAL_REASON_CODE = 3 then 
			 			(case when sa.INFUSION_INJECTION_METHOD_ID <> -1 then 1 else 0 end) else 0 end as FIA,
  			 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.EVALUATE_FACILITY_SVC = 1 then 
						  (case when (select distinct 1 from chart_audit_action caa with (NOLOCK) where caa.CHART_ID = c.CHART_ID
			      		and  caa.Class = '7') = 1 then 0 else 1 end) else 0 end) else 0 end as FLOSE,
				 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.EVALUATE_FACILITY_PROCEDURES = 1 then 
							(case when (select distinct 1 from chart_audit_action caa with (NOLOCK) where caa.CHART_ID = c.CHART_ID
			      		and  caa.Class in ('2')) = 1 then 0 else 1 end) else 0 end) else 0 end as FPROCE,
				 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.INFUSION_INJECTION_METHOD_ID <> -1 then 
							(case when (select distinct 1 from chart_audit_action caa with (NOLOCK) where caa.CHART_ID = c.CHART_ID
			      		and  caa.Class in ('3')) = 1 then 0 else 1 end) else 0 end) else 0 end as FINJE,
				 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 1 else 0 end) else 0 end as PA,
				 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 1 else 0 end) else 0 end as PPA,
				 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 
			 				(case when (select distinct 1 from chart_audit_action caa with (NOLOCK) where caa.chart_id = c.chart_id
			 						and  caa.Class = '8') = 1 then 0 else 1 end) else 0 end) else 0 end as PLOSE,
				 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 
			 				(case when (select distinct 1 from chart_audit_action caa with (NOLOCK)where caa.chart_id = c.chart_id
			 						and  caa.Class = '5') = 1 then 0 else 1 end) else 0 end) else 0 end as PPROCE,
				 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 1 else 0 end) else 0 end as DA,
				 case when c.APPROVAL_REASON_CODE = 3 then
			 			(case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 
			 				(case when (select distinct 1 from chart_audit_action caa with (NOLOCK) where caa.chart_id = c.chart_id
			 				and  caa.Class = '6') = 1 then 0 else 1 end) else 0 end) else 0 end as DE
	from  chart c with (NOLOCK), service_agreement sa with (NOLOCK)
	where c.CHART_STATUS_ID in (4, 5)
	and   sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
	and   sa.AUDIT_ENABLED = 1
	and   sa.COMPANY_ID not in (1, 2)) x
	where f.FACILITY_ID = x.Facility_ID
	and   up.USER_PROFILE_ID = x.CUID
	and   aup.USER_PROFILE_ID = x.AUID;
	-- Recreate Indexes
	CREATE NONCLUSTERED INDEX [AI_CAR_APPROVEDT_CUID_FACILITY_CNAME] ON [CCSTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT]
	([APPROVED_DATE] , [CUID] , [FACILITY_ID] , [AUID] , [CNAME] , [SEQ])
	WITH
	(PAD_INDEX = OFF,
	FILLFACTOR = 100,
	IGNORE_DUP_KEY = OFF,
	STATISTICS_NORECOMPUTE = OFF,
	ALLOW_ROW_LOCKS = ON,
	ALLOW_PAGE_LOCKS = ON,
	MAXDOP = 0)
	ON [PRIMARY];
	CREATE NONCLUSTERED INDEX [AI_CAR_APPROVEDT_CUID_MANAGER_FACILITY_CNAME] ON [CCSTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT]
	([APPROVED_DATE] , [CUID] , [MANAGER_ID] , [FACILITY_ID] , [AUID] , [CNAME] , [SEQ])
	WITH
	(PAD_INDEX = OFF,
	FILLFACTOR = 100,
	IGNORE_DUP_KEY = OFF,
	STATISTICS_NORECOMPUTE = OFF,
	ALLOW_ROW_LOCKS = ON,
	ALLOW_PAGE_LOCKS = ON,
	MAXDOP = 0)
	ON [PRIMARY];
	CREATE NONCLUSTERED INDEX [AI_CAR_APPROVEDT_FACILITY_CUID_CNAME] ON [CCSTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT]
	([APPROVED_DATE] , [CUID] , [FACILITY_ID] , [AUID] , [CNAME] , [SEQ])
	WITH
	(PAD_INDEX = OFF,
	FILLFACTOR = 100,
	IGNORE_DUP_KEY = OFF,
	STATISTICS_NORECOMPUTE = OFF,
	ALLOW_ROW_LOCKS = ON,
	ALLOW_PAGE_LOCKS = ON,
	MAXDOP = 0)
	ON [PRIMARY];
GO
