SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[Refresh_Daily_Snapshot_Tables]
WITH EXEC AS CALLER
AS


-- Create/Increment Sent Procedure Table
-- Drop Indexes
DROP INDEX [AI_SP_FACILITY_PHYSICIAN] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AX_SP_CLASS_PATIENT_DISP_SA_PATIENT_CLASS_DOS] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_SP_SA_SENTDT] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_SP_SA_DOS] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_SP_CHARTID] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AX_SENT_PROCEDURE_RVU_REPORTING] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_CLASS_FACILITY_PHYSICIAN_CPT] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_SP_FAC_CHART_ID] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [IDX_SENT_PROC_SEQ_CHARTID_FACILITYCHARTID_CPTCODE_QTY_FACILITY_CHARGEMASTERID] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [ncidx_mwm_SENT_PROCEDURE_61] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [SENT_PROCEDURE_PHYSICIAN_ID] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];
DROP INDEX [AI_CLASS_FACILITY_PHYSICIAN_CPT] ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE];


--TRUNCATE TABLE [RevCycleTransactionSnapshot].[DBO].[SENT_PROCEDURE];
-- Recreate Table Data
insert into [RevCycleTransactionSnapshot].[DBO].SENT_PROCEDURE
(CLASS, CHART_ID, FACILITY_CHART_ID, SERVICE_AGREEMENT_ID, TIME_OF_SERVICE, SENT_DATE, PATIENT_DISPOSITION_ID, PHYSICIAN_ID, BILLING_CODE, CPT_CODE, QUANTITY, FACILITY_ID, PATIENT_CLASS_ID, ADJUSTMENT_IND, CHARGE_MASTER_ID, LEVEL_ID, FACILITY_ADMIN_CHART_ID, SOURCE_ID, SOURCE_CD)
select 'FP' as CLASS, 
                        c.CHART_ID,
                        c.FACILITY_CHART_ID,
                        c.SERVICE_AGREEMENT_ID,
                        coalesce(fpe.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
                        c.SENT_DATE,
                        c.PATIENT_DISPOSITION_ID,
                        case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
                                    end as PHYSICIAN_ID,
                        ISNULL(NULLIF(cm.ALIAS_BILLING_CODE,''),cm.BILLING_CODE) BILLING_CODE,
                        cm.CPT_CODE,
                        fpe.QUANTITY,
                        c.facility_id,
                        case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
                              (select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
                                    where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                                    and   pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
        cm.CHARGE_MASTER_ID,
        0 as LEVEL_ID,
        c.FACILITY_ADMIN_CHART_ID,
        fpe.FACILITY_PROCEDURE_ID as source_id,
        'FP' as source_cd
from   facility_procedure_evaluation fpe with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = fpe.CHART_ID
and    c.CHART_STATUS_ID = 5 
and    cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa
                        where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
and    fpe.FACILITY_PROCEDURE_ID not in (select sp.source_id 
          from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp
          where fpe.CHART_ID = sp.chart_id
          and fpe.facility_procedure_id = sp.source_id
          and sp.source_cd = 'FP')
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
                        ISNULL(NULLIF(cm.ALIAS_BILLING_CODE,''),cm.BILLING_CODE) BILLING_CODE,
                        cm.CPT_CODE,
                        cpi.UNITS Quantity,
                        c.facility_id,
                        case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
                              (select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
                                    where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                                    and   pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
        cm.CHARGE_MASTER_ID,
        0 as LEVEL_ID,
        c.FACILITY_ADMIN_CHART_ID,
        cpi.CHART_PACKAGE_ITEM_ID source_id,
        'PI' as source_cd
from   CHART_PACKAGE_ITEM cpi with (NOLOCK), CHARGE_PACKAGE_ITEM ci with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = cpi.CHART_ID
and    c.CHART_STATUS_ID = 5 
and    ci.CHARGE_PACKAGE_ITEM_ID = cpi.CHARGE_PACKAGE_ITEM_ID
and    cm.CHARGE_MASTER_ID = ci.CHARGE_MASTER_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa
                        where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
and    cpi.CHART_PACKAGE_ITEM_ID not in (select sp.source_id 
          from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp with (NOLOCK)
          where cpi.CHART_ID = sp.chart_id
          and cpi.CHART_PACKAGE_ITEM_ID = sp.source_id
          and sp.source_cd = 'PI')
union all
select 'FP' as CLASS,   -- Additional Supplies
                        c.CHART_ID,
                        c.FACILITY_CHART_ID,
                        c.SERVICE_AGREEMENT_ID,
                        c.TIME_OF_SERVICE,
                        c.SENT_DATE,
                        c.PATIENT_DISPOSITION_ID,
                        case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID
                                    end as PHYSICIAN_ID,
                        ISNULL(NULLIF(cm.ALIAS_BILLING_CODE,''),cm.BILLING_CODE) BILLING_CODE,
                        cm.CPT_CODE,
                        cas.UNITS Quantity,
                        c.facility_id,
                        case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
                              (select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK)
                                    where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                                    and   pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
        cm.CHARGE_MASTER_ID,
        0 as LEVEL_ID,
        c.FACILITY_ADMIN_CHART_ID,
        cas.CHART_ADDITIONAL_SUPPLIES_ID as source_id,
        'AS' as source_cd
from   CHART_ADDITIONAL_SUPPLIES cas with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = cas.CHART_ID
and    c.CHART_STATUS_ID = 5 
and    cm.CHARGE_MASTER_ID = cas.CHARGE_MASTER_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa
                        where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
and    cas.CHART_ADDITIONAL_SUPPLIES_ID not in (select sp.source_id 
          from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp with (NOLOCK)
          where cas.CHART_ID = sp.chart_id
          and cas.CHART_ADDITIONAL_SUPPLIES_ID = sp.source_id
          and sp.source_cd = 'AS')
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
        0 as LEVEL_ID,
        c.FACILITY_ADMIN_CHART_ID,
        cir.CHART_INFUSION_RESULT_ID as source_id,
        'IP' as source_cd
from   chart_infusion_result cir with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = cir.CHART_ID
and    c.CHART_STATUS_ID = 5 
and    cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa with (NOLOCK)
                        where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
and    cir.CHART_INFUSION_RESULT_ID not in (select sp.source_id 
          from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp with (NOLOCK)
          where cir.CHART_ID = sp.chart_id
          and cir.CHART_INFUSION_RESULT_ID = sp.source_id
          and sp.source_cd = 'IP')
union all
select 'PP' as Class, 
                        c.CHART_ID,
                        c.FACILITY_CHART_ID,
                        c.SERVICE_AGREEMENT_ID,
                        coalesce(ppe.PROCEDURE_DATE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
                        c.SENT_DATE,
                        c.PATIENT_DISPOSITION_ID,
                        case when (ppe.PHYSICIAN_ID = -1 or ppe.PHYSICIAN_ID is null) then c.PHYSICIAN_ID
                                    else ppe.PHYSICIAN_ID
                              end as PHYSICIAN_ID,
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
        0 as LEVEL_ID,
        c.FACILITY_ADMIN_CHART_ID,
        ppe.PHYSICIAN_PROCEDURE_ID source_id,
        'PP' as source_cd
from   physician_procedure_evaluation ppe with (NOLOCK), chart c with (NOLOCK), charge_master cm with (NOLOCK)
where  c.CHART_ID = ppe.CHART_ID
and    c.CHART_STATUS_ID = 5
and    cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa with (NOLOCK)
                        where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
and    ppe.PHYSICIAN_PROCEDURE_ID not in (select sp.source_id 
          from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp with (NOLOCK)
          where ppe.CHART_ID = sp.chart_id
          and ppe.PHYSICIAN_PROCEDURE_ID = sp.source_id
          and sp.source_cd = 'PP')
union all  --Adjustments
select case when cm.CHARGE_MASTER_USAGE_CODE = 2 then 'FL' 
            when cm.CHARGE_MASTER_USAGE_CODE = 3 then 'FP' 
            when cm.CHARGE_MASTER_USAGE_CODE = 4 then 'PL'
            when cm.CHARGE_MASTER_USAGE_CODE = 5 then 'PP'
         else 'CA' end  as Class,
                  c.CHART_ID,
                  c.FACILITY_CHART_ID,
                  c.SERVICE_AGREEMENT_ID,
                  coalesce(ca.REVISED_DATE_OF_SERVICE, c.TIME_OF_SERVICE) TIME_OF_SERVICE,
                  c.SENT_DATE,
       (case when c.PATIENT_DISPOSITION_ID in (-1, 0) then 
              coalesce((select distinct 4 
               from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs, FACILITY_SERVICE_SCHEDULE_ITEM fssi
               where fse.CHART_ID = c.chart_id
               and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID) OR
                     (fse.FACILITY_SERVICE_SCHEDULE_ID = fssi.FACILITY_SERVICE_SCHEDULE_ID AND
                       fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID))
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
             else 0 end as LEVEL_ID,
       c.FACILITY_ADMIN_CHART_ID,
       ca.CHART_ADJUSTMENT_ID as source_id,
       'CA' as source_cd
from chart_adjustment ca with (NOLOCK), charge_master cm with (NOLOCK), chart c with (NOLOCK)
where  c.CHART_ID = ca.CHART_ID
and      c.CHART_STATUS_ID = 5
and    cm.CHARGE_MASTER_ID = ca.CHARGE_MASTER_ID
and    c.TIME_OF_SERVICE >= (select sa.EFFECTIVE_DATE from service_agreement sa with (NOLOCK)
                        where sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID)
and    ca.CHART_ADJUSTMENT_ID not in (select sp.source_id 
          from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp with (NOLOCK)
          where ca.CHART_ID = sp.chart_id
          and ca.CHART_ADJUSTMENT_ID = sp.source_id
          and sp.source_cd = 'CA')
union all
select 'FL' as Class,
                  c.CHART_ID,
                  c.FACILITY_CHART_ID,
                  c.SERVICE_AGREEMENT_ID,
                  c.TIME_OF_SERVICE,
                  c.SENT_DATE,
       (case when c.PATIENT_DISPOSITION_ID in (-1, 0) then 
              coalesce((select distinct 4 
               from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs, FACILITY_SERVICE_SCHEDULE_ITEM fssi
               where fse.CHART_ID = c.chart_id
               and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID) OR
                      (fse.FACILITY_SERVICE_SCHEDULE_ID = fssi.FACILITY_SERVICE_SCHEDULE_ID AND
                       fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID))
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
            else c.OVERRIDE_FACILITY_LEVEL_ID end) LEVEL_ID,
        c.FACILITY_ADMIN_CHART_ID,
        c.CHART_ID as source_id,
        'FL' as source_cd
from   chart c with (NOLOCK), facility_level fl with (NOLOCK), SERVICE_AGREEMENT sa with (NOLOCK)
where  c.CHART_STATUS_ID = 5
and    sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
and    (c.OVERRIDE_FACILITY_LEVEL_ID <> -1
    or  c.FACILITY_LEVEL_ID <> -1)
and         (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 then c.FACILITY_LEVEL_ID
            when c.OVERRIDE_FACILITY_LEVEL_ID = '' then c.FACILITY_LEVEL_ID
                  else c.OVERRIDE_FACILITY_LEVEL_ID
                  end) = fl.FACILITY_LEVEL_ID
and    c.TIME_OF_SERVICE >= sa.EFFECTIVE_DATE
and    c.CHART_ID not in (select sp.source_id 
          from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp with (NOLOCK)
          where c.CHART_ID = sp.chart_id
          and c.CHART_ID = sp.source_id
          and sp.source_cd = 'FL')
union all
select  'PL' as Class,
                        c.CHART_ID, 
                        c.FACILITY_CHART_ID, 
                        c.SERVICE_AGREEMENT_ID,
                        c.TIME_OF_SERVICE,
                        c.SENT_DATE,
       (case when c.PATIENT_DISPOSITION_ID in (-1, 0) then 
              coalesce((select distinct 4 
               from  FACILITY_SERVICE_EVALUATION fse, FACILITY_SERVICE fs, FACILITY_SERVICE_SCHEDULE_ITEM fssi
               where fse.CHART_ID = c.chart_id
               and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID) OR
                     (fse.FACILITY_SERVICE_SCHEDULE_ID = fssi.FACILITY_SERVICE_SCHEDULE_ID AND
                       fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fssi.FACILITY_SERVICE_SCHEDULE_ITEM_ID))
               and   (left(fs.DESCRIPTION,9) = 'Admission' or left(fs.DESCRIPTION,5) = 'Admit')),1)
             when c.PATIENT_DISPOSITION_ID is null then 1
                 else c.PATIENT_DISPOSITION_ID end)  PATIENT_DISPOSITION_ID,
                        case when c.PHYSICIAN_ID <> -1 then c.PHYSICIAN_ID end as PHYSICIAN_ID,
                        (select psp.BILLING_CODE from physician_service_procedure psp with (NOLOCK)
                        where psp.PHYSICIAN_SERVICE_PROC_ID = 
                                                                              (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
                                                                                                and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
                                                                                                then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                                                                                                else c.PHYSICIAN_SERVICE_PROC_ID end))
                        as BILLING_CD,
                        (select psp.CPT_CODE from physician_service_procedure psp with (NOLOCK)
                        where psp.PHYSICIAN_SERVICE_PROC_ID = 
                                            (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
                                                             and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
                                                            then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                                                            else c.PHYSICIAN_SERVICE_PROC_ID end)) 
                        as CPT_CD,
                        1 as Quantity,
                        c.facility_id,
                        case when c.patient_class_id <> -1 then c.PATIENT_CLASS_ID else
                              (select max(pc.PATIENT_CLASS_ID) from patient_class pc with (NOLOCK) 
                                    where pc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                                    and pc.DEFAULT_IND = 1) end as patient_class_id,
        'N' as ADJUSTMENT_IND,
       coalesce((select max(cm.charge_master_id) from charge_master cm with (nolock) 
        where cm.BILLING_CODE = (select psp.BILLING_CODE from physician_service_procedure psp with (NOLOCK)
                                                                             where psp.PHYSICIAN_SERVICE_PROC_ID = 
                                                                                            (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
                                                                                                         and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
                                                                                                         then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                                                                                                         else c.PHYSICIAN_SERVICE_PROC_ID end))
            AND cm.CPT_CODE = (select psp.CPT_CODE from physician_service_procedure psp with (NOLOCK)
                                                       where psp.PHYSICIAN_SERVICE_PROC_ID = 
                                                                        (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
                                                                                             and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
                                                                                     then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                                                                                     else c.PHYSICIAN_SERVICE_PROC_ID end))
            AND cm.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
            and    cm.EFFECTIVE_DATE <= getdate()
            and    cm.EXPIRATION_DATE >= getdate()
            AND cm.CHARGE_MASTER_USAGE_CODE = 4
            and (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID or cm.patient_class_id = -1)),null) as charge_master_id,
                  (select psp.PHYSICIAN_SERVICE_PROC_ID 
        from   physician_service_procedure psp with (NOLOCK)
                        where  psp.PHYSICIAN_SERVICE_PROC_ID = 
                                  (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID is not null 
                                           and  c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1
                                           then c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                                           else c.PHYSICIAN_SERVICE_PROC_ID end)) 
                        as LEVEL_ID,
        c.FACILITY_ADMIN_CHART_ID,
        c.CHART_ID as source_id,
        'PL' as source_cd
from chart c with (NOLOCK), service_agreement sa with (NOLOCK)
where       c.CHART_STATUS_ID = 5
and     sa.service_agreement_id = c.service_agreement_id
and     sa.evaluate_physician_svc = 1
and    c.TIME_OF_SERVICE >= sa.EFFECTIVE_DATE

--Changed per John on 03/13/2013 (LDH)
--and       (c.NO_PHYSICIAN_SERVICES is null or c.NO_PHYSICIAN_SERVICES = 0)
and (c.PHYSICIAN_SERVICE_PROC_ID <> -1 or c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID <> -1)

and    c.CHART_ID not in (select sp.source_id 
          from [RevCycleTransactionSnapshot].[dbo].SENT_PROCEDURE sp with (NOLOCK)
          where c.CHART_ID = sp.chart_id
          and c.CHART_ID = sp.source_id
          and sp.source_cd = 'PL');
          
-- Recreate Indexes
CREATE NONCLUSTERED INDEX [AI_CLASS_FACILITY_PHYSICIAN_CPT]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
(
[class] , [facility_id] , [physician_id] , [cpt_code] , [time_of_service] 
)
INCLUDE ([quantity], [seq])
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[AI_SP_CHARTID]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [AI_SP_CHARTID]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
(
[chart_id] , [service_agreement_id] , [facility_chart_id] , [charge_master_id] , [seq] 
)
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[AI_SP_FAC_CHART_ID]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [AI_SP_FAC_CHART_ID]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([class] , [facility_id] , [cpt_code])
INCLUDE (
[chart_id], [facility_chart_id], [service_agreement_id], [time_of_service], [sent_date], [patient_disposition_id], [physician_id], [billing_code], [quantity], [patient_class_id], [adjustment_ind] 
)
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[AI_SP_FACILITY_PHYSICIAN]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [AI_SP_FACILITY_PHYSICIAN]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
(
[class] , [patient_disposition_id] , [facility_id] , [service_agreement_id] , [physician_id] , [time_of_service] , [cpt_code] , [chart_id] , [seq] 
)
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[AI_SP_SA_DOS]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [AI_SP_SA_DOS]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
(
[service_agreement_id] , [time_of_service] , [chart_id] , [cpt_code] , [physician_id] , [billing_code] , [class] , [quantity] 
)
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[AI_SP_SA_SENTDT]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [AI_SP_SA_SENTDT]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
(
[service_agreement_id] , [sent_date] , [chart_id] , [facility_chart_id] , [time_of_service] , [billing_code] , [cpt_code] , [quantity] , [facility_id] , [adjustment_ind] 
)
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[AX_SENT_PROCEDURE_RVU_REPORTING]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [AX_SENT_PROCEDURE_RVU_REPORTING]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
(
[seq] , [chart_id] , [facility_chart_id] , [physician_id] , [cpt_code] , [quantity] , [charge_master_id] 
)
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[AX_SP_CLASS_PATIENT_DISP_SA_PATIENT_CLASS_DOS]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [AX_SP_CLASS_PATIENT_DISP_SA_PATIENT_CLASS_DOS]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
(
[class] , [patient_disposition_id] , [facility_id] , [service_agreement_id] , [patient_class_id] , [time_of_service] , [cpt_code] , [chart_id] , [seq] 
)
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[IDX_SENT_PROC_SEQ_CHARTID_FACILITYCHARTID_CPTCODE_QTY_FACILITY_CHARGEMASTERID]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [IDX_SENT_PROC_SEQ_CHARTID_FACILITYCHARTID_CPTCODE_QTY_FACILITY_CHARGEMASTERID]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([class] , [physician_id])
INCLUDE (
[seq], [chart_id], [facility_chart_id], [cpt_code], [quantity], [facility_id], [charge_master_id] 
)
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[ncidx_mwm_SENT_PROCEDURE_61]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [ncidx_mwm_SENT_PROCEDURE_61]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([facility_chart_id] , [cpt_code])
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
ON [PRIMARY];


/****** Object: Index [dbo].[SENT_PROCEDURE_PHYSICIAN_ID]   Script Date: 5/2/2012 3:31:57 PM ******/

CREATE NONCLUSTERED INDEX [SENT_PROCEDURE_PHYSICIAN_ID]
ON [RevCycleTransactionSnapshot].[dbo].[SENT_PROCEDURE]
([facility_id])
INCLUDE ([physician_id])
WITH
(
PAD_INDEX = OFF,
FILLFACTOR = 100,
IGNORE_DUP_KEY = OFF,
STATISTICS_NORECOMPUTE = OFF,
ONLINE = OFF,
ALLOW_ROW_LOCKS = ON,
ALLOW_PAGE_LOCKS = ON,
DATA_COMPRESSION = NONE
)
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
                        (case when fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID > 0 then 
                                    (select fsi.description FROM FACILITY_SERVICE_SCHEDULE_ITEM fsi
                                    where fsi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)
                          else
                        (select fs.DESCRIPTION from facility_service fs with (NOLOCK)
                                    where fs.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID) end) 'Description'
      from  facility_service_evaluation_history fseh with (NOLOCK), chart c with (NOLOCK)
      where fseh.CHART_ID not in (select fse.CHART_ID from facility_service_evaluation fse with (NOLOCK)
                        where fse.CHART_ID = fseh.CHART_ID
                        and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID)
               OR (fse.FACILITY_SERVICE_SCHEDULE_ID IS NOT NULL
                   AND fse.FACILITY_SERVICE_SCHEDULE_ID = fseh.FACILITY_SERVICE_SCHEDULE_ID
                   AND fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)))
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fseh.FACILITY_SVC_EVAL_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION_HISTORY') = 0 
      and   c.CHART_ID = fseh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union 
      select '1' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        (case when fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID > 0 then 
                                    (select fsi.description FROM FACILITY_SERVICE_SCHEDULE_ITEM fsi
                                    where fsi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID)
                          else
                        (select fs.DESCRIPTION from facility_service fs with (NOLOCK)
                                    where fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID) end) 'Description'
      from  facility_service_evaluation fse with (NOLOCK), chart c with (NOLOCK)
      where fse.CHART_ID not in (select fseh.CHART_ID from facility_service_evaluation_history fseh with (NOLOCK)
                        where fseh.CHART_ID = fse.CHART_ID
                        and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID)
                OR (fse.FACILITY_SERVICE_SCHEDULE_ID IS NOT NULL
                    AND fse.FACILITY_SERVICE_SCHEDULE_ID = fseh.FACILITY_SERVICE_SCHEDULE_ID
                    AND fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)))
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fse.FACILITY_SVC_EVAL_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION') = 0 and   c.CHART_ID = fse.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union
      select '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation_history fpeh with (NOLOCK), chart c with (NOLOCK), CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        --and   cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'
                        --and   (select COUNT(*) from CHARGE_MASTER cm2 where cm2.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm2.CPT_CODE <> 'SUPLY') = 0
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union
      select '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), chart c with (NOLOCK), CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK), CHARGE_MASTER cm with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        --and   cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'
                        --and   (select COUNT(*) from CHARGE_MASTER cm2 where cm2.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm2.CPT_CODE <> 'SUPLY') = 0                     
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = fpe.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union
      select '3' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result_history cirh with (NOLOCK), chart c with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
union
      select '3' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir, chart c, CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = pseh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pseh.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL_HISTORY') = 0                  
      and   c.CHART_ID = pseh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = pse.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pse.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL') = 0                       
      and   c.CHART_ID = pse.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = ppeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppeh.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY') = 0                     
      and   c.CHART_ID = ppeh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = ppe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppe.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = ppe.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cdch.CHART_ID and qa.KEY_VALUE_2 = cdch.ICD9_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE_HISTORY') = 0                  
      and   c.CHART_ID = cdch.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cdc.CHART_ID and qa.KEY_VALUE_2 = cdc.ICD9_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE') = 0                   
      and   c.CHART_ID = cdc.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union
      select '7' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        fl.DESCRIPTION Description
      from  chart_los_history clh with (NOLOCK), chart c with (NOLOCK), facility_level fl with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                      
      and   fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   fl.FACILITY_LEVEL_ID = (case when clh.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then clh.FACILITY_LEVEL_ID else clh.OVERRIDE_FACILITY_LEVEL_ID end)
      and   fl.CPT_CODE <> (select fl2.CPT_CODE from facility_level fl2 with (NOLOCK) 
                              where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then c.FACILITY_LEVEL_ID else c.OVERRIDE_FACILITY_LEVEL_ID end) = fl2.FACILITY_LEVEL_ID))
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union
      select '7' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         fl.DESCRIPTION Description
      from chart_los_history clh with (NOLOCK), chart c with (NOLOCK), facility_level fl with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                            
      and   fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   fl.FACILITY_LEVEL_ID = (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then c.FACILITY_LEVEL_ID else c.OVERRIDE_FACILITY_LEVEL_ID end)
      and   fl.CPT_CODE <> (select fl2.CPT_CODE from facility_level fl2 with (NOLOCK) 
                              where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when clh.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then clh.FACILITY_LEVEL_ID else clh.OVERRIDE_FACILITY_LEVEL_ID end) = fl2.FACILITY_LEVEL_ID))
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union
      select '8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        psp.DESCRIPTION Description
      from  chart_los_history clh with (NOLOCK), chart c with (NOLOCK), physician_service_procedure psp with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'PLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                            
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
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
union
      select '8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         psp.DESCRIPTION Description
      from chart_los_history clh with (NOLOCK), chart c with (NOLOCK), physician_service_procedure psp with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'PLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                            
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
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
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
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
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
      and   clh.PHYSICIAN_CRITICAL_CARE <> 1
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      -- Observation Phase II changes
      union
      select 'A' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation_history fpeh with (NOLOCK), chart c with (NOLOCK), CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        --and   cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'
                        --and   (select COUNT(*) from CHARGE_MASTER cm2 where cm2.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm2.CPT_CODE <> 'SUPLY') = 0
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
union
      select 'A' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), chart c with (NOLOCK), CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK), CHARGE_MASTER cm with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID
                        --and   cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'
                        --and   (select COUNT(*) from CHARGE_MASTER cm2 where cm2.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm2.CPT_CODE <> 'SUPLY') = 0                     
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = fpe.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
union 
      select 'B' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result_history cirh with (NOLOCK), chart c with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
union
      select 'B' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir, chart c, CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union 
      select '9' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_observation_encounter_result_history corh with (NOLOCK), chart c with (NOLOCK)
      where corh.CHART_ID not in (select cor.CHART_ID from chart_observation_encounter_result cor with (NOLOCK)
                        where cor.CHART_ID = corh.CHART_ID
                        and   cor.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = corh.CHART_OBSERVATION_ENCOUNTER_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_OBSERVATION_ENCOUNTER_RESULT_HISTORY') = 0                 
      and   c.CHART_ID = corh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      union
      select '9' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cor.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_observation_encounter_result cor, chart c
      where cor.CHART_ID not in (select corh.CHART_ID from chart_observation_encounter_result_history corh with (NOLOCK)
                        where cor.CHART_ID = corh.CHART_ID
                        and   cor.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cor.CHART_OBSERVATION_ENCOUNTER_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_OBSERVATION_ENCOUNTER_RESULT') = 0                     
      and   c.CHART_ID = cor.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
  -- Chart Demographic Audit -----------------------------------------------
  union
  select 'C' as 'Class',
         'R' as 'Action',
         c.CHART_ID,
         case 
           when isnull(cdh.MEDICAL_RECORD_NUM, '') <> isnull(c.MEDICAL_RECORD_NUM, '') then 'MRN: ' + cdh.MEDICAL_RECORD_NUM
           when isnull(cdh.ADMISSION_DATE_TIME, '') <> isnull(c.ADMISSION_DATE_TIME, '') then 'Admission Date: ' + convert(varchar, cdh.ADMISSION_DATE_TIME, 110)
           when isnull(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, '') <> isnull(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, '') then 'Arrival Mode: ' + saam.DESCRIPTION
           when isnull(cdh.ARRIVAL_DATE_TIME, '') <> isnull(c.ARRIVAL_DATE_TIME, '') then 'Arrival Date: ' + convert(varchar, cdh.ARRIVAL_DATE_TIME, 110)
           when isnull(cdh.PATIENT_DISPOSITION_MAP_ID, '') <> isnull(c.PATIENT_DISPOSITION_MAP_ID, '') then 'Patient Disposition: ' + pdm.DESCRIPTION + '(' + pdm.FACILITY_PATIENT_DISPOSITION + ')'
           when isnull(cdh.PHYSICIAN_ID, '') <> isnull(c.PHYSICIAN_ID, '') then 'Physician: ' + (ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), ''))
           when isnull(cdh.TIME_TO_ROOM, '') <> isnull(c.TIME_TO_ROOM, '') then 'Time to Room: ' + convert(varchar, cdh.TIME_TO_ROOM, 110)
           when isnull(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, '') <> isnull(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, '') then 'Triage Accuity: ' + sata.DESCRIPTION
           when isnull(cdh.GENDER, '') <> isnull(c.GENDER, '') then 'Gender: ' + cdh.GENDER
           else '' 
         end [Description]  
         --ISNULL(cdh.MEDICAL_RECORD_NUM, 'null') + '|' + ISNULL(CONVERT(VARCHAR, cdh.ADMISSION_DATE_TIME, 120), 'null') + '|' + ISNULL(saam.DESCRIPTION, 'null') + '|' + ISNULL(CONVERT(VARCHAR, cdh.ARRIVAL_DATE_TIME, 120), 'null') + '|' + ISNULL((pdm.DESCRIPTION + ' (' + pdm.FACILITY_PATIENT_DISPOSITION + ')'), 'null') + '|' + ISNULL((fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + ISNULL(fp.MIDDLE_NAME, '')), 'null') + '|' + ISNULL(CONVERT(VARCHAR, cdh.TIME_TO_ROOM, 120), 'null') + '|' + ISNULL(sata.DESCRIPTION, 'null') + '|' + ISNULL(cdh.GENDER, 'null') 'Description'
  from CHART_DEMOGRAPHIC_HISTORY cdh WITH(NOLOCK)
  join CHART c with (NOLOCK) on c.CHART_ID = cdh.CHART_ID
  left outer join PATIENT_DISPOSITION_MAP pdm with (NOLOCK) on cdh.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
  left outer join SERVICE_AGREEMENT_ARRIVAL_MODE saam with (NOLOCK) on cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
  left outer join SERVICE_AGREEMENT_TRIAGE_ACUITY sata with (NOLOCK) on cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
  left outer join FACILITY_PROFESSIONAL fp with (NOLOCK) on cdh.PHYSICIAN_ID = fp.FACILITY_PROF_ID
  where c.CHART_STATUS_ID in (4, 5)
    and exists
      (select 'x'
       from CHART c with (NOLOCK)
       join SERVICE_AGREEMENT sa with (NOLOCK) on sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
       where c.CHART_ID = cdh.CHART_ID
         and 1 = case when sa.COLLECT_MEDICAL_RECORD_NUMBER <> 'N'
         and sa.INCLUDE_MRN_AS_QA_ELEMENT = 1
         and c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '1'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when COLLECT_ADMISSION_DATE <> 'N'
         and sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT = 1
         and ISNULL(CONVERT(VARCHAR, c.ADMISSION_DATE_TIME, 120), '') <> ISNULL(CONVERT(VARCHAR, cdh.ADMISSION_DATE_TIME, 120), '')
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '2'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_ARRIVAL_MODE <> 'N'
         and sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT = 1
         and ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, -1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, -1)
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '3'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_ARRIVAL_DATE <> 'N'
         and sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT = 1
         and ISNULL(CONVERT(VARCHAR, c.ARRIVAL_DATE_TIME, 120), '') <> ISNULL(CONVERT(VARCHAR, cdh.ARRIVAL_DATE_TIME, 120), '')
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '4'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when COLLECT_FACILITY_PATIENT_DISPOSITION <> 'N'
         and sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT = 1
         and ISNULL(c.PATIENT_DISPOSITION_MAP_ID, -1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, -1)
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '5'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_PHYSICIAN <> 'N'
         and sa.INCLUDE_PROVIDER_AS_QA_ELEMENT = 1
         and ISNULL(c.PHYSICIAN_ID, -1) <> ISNULL(cdh.PHYSICIAN_ID, -1)
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '6'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_DATE_TO_ROOM <> 'N'
         and sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT = 1
         and ISNULL(CONVERT(VARCHAR, c.TIME_TO_ROOM, 120), '') <> ISNULL(CONVERT(VARCHAR, cdh.TIME_TO_ROOM, 120), '')
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '7'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_TRIAGE_ACUITY <> 'N'
         and sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
         and ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID , -1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, -1)
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '8'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_GENDER <> 'N'
         and sa.INCLUDE_GENDER_AS_QA_ELEMENT = 1
         and ISNULL(c.GENDER , '') <> ISNULL(cdh.GENDER, '')
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '9'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 else 0 end)
    and ((case when c.SENT_DATE is null then '20080510' else CONVERT(VARCHAR, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
  union
  select 'C' as 'Class',
         'A' as 'Action',
         c.CHART_ID,
         case 
           when isnull(cdh.MEDICAL_RECORD_NUM, '') <> isnull(c.MEDICAL_RECORD_NUM, '') then 'MRN: ' + c.MEDICAL_RECORD_NUM
           when isnull(cdh.ADMISSION_DATE_TIME, '') <> isnull(c.ADMISSION_DATE_TIME, '') then 'Admission Date: ' + convert(varchar, c.ADMISSION_DATE_TIME, 110)
           when isnull(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, '') <> isnull(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, '') then 'Arrival Mode: ' + saam.DESCRIPTION
           when isnull(cdh.ARRIVAL_DATE_TIME, '') <> isnull(c.ARRIVAL_DATE_TIME, '') then 'Arrival Date: ' + convert(varchar, c.ARRIVAL_DATE_TIME, 110)
           when isnull(cdh.PATIENT_DISPOSITION_MAP_ID, '') <> isnull(c.PATIENT_DISPOSITION_MAP_ID, '') then 'Patient Disposition: ' + pdm.DESCRIPTION + '(' + pdm.FACILITY_PATIENT_DISPOSITION + ')'
           when isnull(cdh.PHYSICIAN_ID, '') <> isnull(c.PHYSICIAN_ID, '') then 'Physician: ' + (ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), ''))
           when isnull(cdh.TIME_TO_ROOM, '') <> isnull(c.TIME_TO_ROOM, '') then 'Time to Room: ' + convert(varchar, c.TIME_TO_ROOM, 110)
           when isnull(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, '') <> isnull(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, '') then 'Triage Accuity: ' + sata.DESCRIPTION
           when isnull(cdh.GENDER, '') <> isnull(c.GENDER, '') then 'Gender: ' + c.GENDER
           else '' 
         end [Description]
         --ISNULL(c.MEDICAL_RECORD_NUM, 'null') + '|' + ISNULL(CONVERT(VARCHAR, c.ADMISSION_DATE_TIME, 120), 'null') + '|' + ISNULL(saam.DESCRIPTION, 'null') + '|' + ISNULL(CONVERT(VARCHAR, c.ARRIVAL_DATE_TIME, 120), 'null') + '|' + ISNULL((pdm.DESCRIPTION + ' (' + pdm.FACILITY_PATIENT_DISPOSITION + ')'), 'null') + '|' + ISNULL((fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + ISNULL(fp.MIDDLE_NAME, '')), 'null') + '|' + ISNULL(CONVERT(VARCHAR, c.TIME_TO_ROOM, 120), 'null') + '|' + ISNULL(sata.DESCRIPTION, 'null') + '|' + ISNULL(c.GENDER, 'null') 'Description'
  from CHART c with (NOLOCK)
  join CHART_DEMOGRAPHIC_HISTORY cdh with (NOLOCK) on c.CHART_ID = cdh.CHART_ID
  left outer join PATIENT_DISPOSITION_MAP pdm with (NOLOCK) on c.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
  left outer join SERVICE_AGREEMENT_ARRIVAL_MODE saam with (NOLOCK) on c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
  left outer join SERVICE_AGREEMENT_TRIAGE_ACUITY sata with (NOLOCK) on c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
  left outer join FACILITY_PROFESSIONAL fp with (NOLOCK) on c.PHYSICIAN_ID = fp.FACILITY_PROF_ID
  where c.CHART_STATUS_ID in (4, 5)
    and exists
      (select 'x'
       from CHART_DEMOGRAPHIC_HISTORY cdh with (NOLOCK)
       join SERVICE_AGREEMENT sa with (NOLOCK) on sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
       where c.CHART_ID = cdh.CHART_ID
         and 1 = case when sa.COLLECT_MEDICAL_RECORD_NUMBER <> 'N'
         and sa.INCLUDE_MRN_AS_QA_ELEMENT = 1
         and c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '1'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when COLLECT_ADMISSION_DATE <> 'N'
         and sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT = 1
         and ISNULL(CONVERT(VARCHAR, c.ADMISSION_DATE_TIME, 120), '') <> ISNULL(CONVERT(VARCHAR, cdh.ADMISSION_DATE_TIME, 120), '')
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '2'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_ARRIVAL_MODE <> 'N'
         and sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT = 1
         and ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, -1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, -1)
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '3'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_ARRIVAL_DATE <> 'N'
         and sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT = 1
         and ISNULL(CONVERT(VARCHAR, c.ARRIVAL_DATE_TIME, 120), '') <> ISNULL(CONVERT(VARCHAR, cdh.ARRIVAL_DATE_TIME, 120), '')
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '4'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when COLLECT_FACILITY_PATIENT_DISPOSITION <> 'N'
         and sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT = 1
         and ISNULL(c.PATIENT_DISPOSITION_MAP_ID, -1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, -1)
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '5'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_PHYSICIAN <> 'N'
         and sa.INCLUDE_PROVIDER_AS_QA_ELEMENT = 1
         and ISNULL(c.PHYSICIAN_ID, -1) <> ISNULL(cdh.PHYSICIAN_ID, -1)
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '6'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_DATE_TO_ROOM <> 'N'
         and sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT = 1
         and ISNULL(CONVERT(VARCHAR, c.TIME_TO_ROOM, 120), '') <> ISNULL(CONVERT(VARCHAR, cdh.TIME_TO_ROOM, 120), '')
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '7'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_TRIAGE_ACUITY <> 'N'
         and sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
         and ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID , -1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, -1)
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '8'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 when sa.COLLECT_GENDER <> 'N'
         and sa.INCLUDE_GENDER_AS_QA_ELEMENT = 1
         and ISNULL(c.GENDER , '') <> ISNULL(cdh.GENDER, '')
         and
           (select COUNT(*)
            from CODER_QA_REPORT_EXCLUSION qa with (NOLOCK)
            where qa.KEY_VALUE_1 = cdh.CHART_ID
              and qa.KEY_VALUE_2 = '9'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY') = 0 then 1 else 0 end)
    and ((case when c.SENT_DATE is null then '20080510' else CONVERT(VARCHAR, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
    -- End Chart Demographic Audit -------------------------------------------
      ;
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
      DROP INDEX [AI_CAR_APPROVEDT_CUID_FACILITY_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT];
      DROP INDEX [AI_CAR_APPROVEDT_CUID_MANAGER_FACILITY_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT];
      DROP INDEX [AI_CAR_APPROVEDT_FACILITY_CUID_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT];
      TRUNCATE TABLE [RevCycleTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT];
      -- Recreate Table Data
      insert into [RevCycleTransactionSnapshot].dbo.CHART_AUDIT_RESULT
      (FACILITY_ID, FNAME, MANAGER_ID, CUID,  CNAME, AUID, ANAME, obsUID, obsName, APPROVED_DATE, FACILITY_CHART_ID, CHART_ID, DOS, FLOS_COMMENT,
            FINJ_COMMENT, FPROC_COMMENT, PLOS_COMMENT, PPROC_COMMENT, DIAG_COMMENT, AUDITED, FA, FPA, FIA, FLOSE, 
            FINJE, FPROCE, PA, PPA, PLOSE, PPROCE, DA, DE, OBSERVATION_AUDITOR_REVIEW_FEEDBACK, OINJ_COMMENT,
                        OPROC_COMMENT, OHA, OHE, OIA, OIE, OPA, OPE, DEMA, DEME, DEMO_COMMENT)
      select x.FACILITY_ID,
                        f.NAME FNAME,
                        (select max(fua.user_profile_id) from facility_user_authorization fua with (NOLOCK)
                                               where fua.facility_id = x.facility_id
                                                and   fua.account_manager_ind = 1) MANAGER_ID,
                        x.CUID,
                        up.LAST_NAME + ', ' + up.FIRST_NAME CNAME,
                        x.AUID,
                        aup.LAST_NAME + ', ' + aup.FIRST_NAME ANAME,
                        x.ObsUID, 
                         oup.LAST_NAME + ', ' + oup.FIRST_NAME obsNAME,
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
                        x.DE, 
                         x.OBSERVATION_AUDITOR_REVIEW_FEEDBACK, 
                         x.OINJ_COMMENT,
                        x.OPROC_COMMENT, 
                         x.OHA, 
                         x.OHE, 
                         x.OIA,
                        x.OIE, 
                         x.OPA,
                        x.OPE,
         x.DEMA,
         CASE WHEN x.DEMA = 0 THEN 0 ELSE x.DEME END DEME,
         x.DEMO_COMMENT                               
      from facility f with (NOLOCK), user_profile up with (NOLOCK), user_profile aup with (NOLOCK),
                        (select c.FACILITY_ID, 
                         (select ln.COMPLETED_BY_USER_ID from log_note ln with (NOLOCK)
                              where  ln.LOG_NOTE_ID = (select min(ln2.LOG_NOTE_ID) from log_note ln2 with (NOLOCK)
                                                                  where  ln2.CHART_ID = c.CHART_ID
                                                                  and    ln2.CATEGORY_ID = 2)) CUID,   
                                    (select ln.COMPLETED_BY_USER_ID from log_note ln with (NOLOCK)
                                          where  ln.LOG_NOTE_ID = (select min(ln2.LOG_NOTE_ID) from log_note ln2 with (NOLOCK)
                                                                              where  ln2.CHART_ID = c.CHART_ID and ln2.CATEGORY_ID = 26))  ObsUID,                                                                                                                       
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
                                         and  caa.Class = '6') = 1 then 0 else 1 end) else 0 end) else 0 end as DE,

                        
      -- 09/14/2011 - EricF - Obs Phase II additions -----------------------------------------------
                  -- Observation hours
                        case when c.APPROVAL_REASON_CODE = 3 then
                                   (case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 then 1 else 0 end) else 0 end as OHA,      
                         case when c.APPROVAL_REASON_CODE = 3 then
                                   (case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 then 
                                          (case when (select distinct 1 from chart_audit_action caa with (NOLOCK) where caa.CHART_ID = c.CHART_ID
                                    and  caa.Class in ('9')) = 1 then 0 else 1 end) else 0 end) else 0 end as OHE,
                  
                  -- Observation Infusion/Injections
                        case when c.APPROVAL_REASON_CODE = 3 then
                                   (case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 
                                     AND sa.INFUSION_INJECTION_METHOD_ID <> -1 then 1 else 0 end) else 0 end as OIA, 
                         case when c.APPROVAL_REASON_CODE = 3 then
                                   (case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 AND sa.INFUSION_INJECTION_METHOD_ID <> -1 then 
                                          (case when (select distinct 1 from chart_audit_action caa with (NOLOCK) where caa.CHART_ID = c.CHART_ID
                                    and  caa.Class in ('B')) = 1 then 0 else 1 end) else 0 end) else 0 end as OIE,
                  
                  
                  -- Observation Facility Procedures              
                        case when c.APPROVAL_REASON_CODE = 3 then
                                   (case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 
                                     AND sa.EVALUATE_FACILITY_PROCEDURES = 1 then 1 else 0 end) else 0 end as OPA, 
                         case when c.APPROVAL_REASON_CODE = 3 then
                                   (case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 AND  sa.EVALUATE_FACILITY_PROCEDURES = 1 then 
                                          (case when (select distinct 1 from chart_audit_action caa with (NOLOCK) where caa.CHART_ID = c.CHART_ID
                                    and  caa.Class in ('A')) = 1 then 0 else 1 end) else 0 end) else 0 end as OPE,             
                  
                  -- Observation cooments 
                         c.DIAGNOSIS_CODING_AUDIT_COMMENT DIAG_COMMENT,
                        c.OBSERVATION_AUDITOR_REVIEW_FEEDBACK,
                        c.OBSERVATION_PROCEDURES_AUDIT_COMMENT OPROC_COMMENT, 
                         c.OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT OINJ_COMMENT,
      -- End of Obs changes     ------------------------------------------------
  -- Chart Demographic Audit -----------------------------------------------
        case
            when c.APPROVAL_REASON_CODE = 3 then (case
                                                      when sa.COLLECT_MEDICAL_RECORD_NUMBER <> 'N'
                                                           and sa.INCLUDE_MRN_AS_QA_ELEMENT = 1 then 1
                                                      when COLLECT_ADMISSION_DATE <> 'N'
                                                           and sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT = 1 then 1
                                                      when sa.COLLECT_ARRIVAL_MODE <> 'N'
                                                           and sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT = 1 then 1
                                                      when sa.COLLECT_ARRIVAL_DATE <> 'N'
                                                           and sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT = 1 then 1
                                                      when COLLECT_FACILITY_PATIENT_DISPOSITION <> 'N'
                                                           and sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT = 1 then 1
                                                      when sa.COLLECT_PHYSICIAN <> 'N'
                                                           and sa.INCLUDE_PROVIDER_AS_QA_ELEMENT = 1 then 1
                                                      when sa.COLLECT_DATE_TO_ROOM <> 'N'
                                                           and sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT = 1 then 1
                                                      when sa.COLLECT_TRIAGE_ACUITY <> 'N'
                                                           and sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1 then 1
                                                      when sa.COLLECT_GENDER <> 'N'
                                                           and sa.INCLUDE_GENDER_AS_QA_ELEMENT = 1 then 1
                                                      else 0
                                                  end)
            else 0        
        end as DEMA,
        case
            when c.APPROVAL_REASON_CODE = 3 then (case
                                                      when
                                                             (select distinct 1
                                                              from chart_audit_action caa with (NOLOCK)
                                                              where caa.CHART_ID = c.CHART_ID
                                                                and caa.Class in ('C')) = 1 then 0
                                                      else 1
                                                  end)
            else 0
        end as DEME,
        c.DEMOGRAPHIC_AUDIT_COMMENT DEMO_COMMENT
  -- End Chart Demographic Audit -------------------------------------------                         
      from  chart c with (NOLOCK), service_agreement sa with (NOLOCK)
      where c.CHART_STATUS_ID in (4, 5)
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
      and   sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   sa.AUDIT_ENABLED = 1
      and   sa.COMPANY_ID not in (1, 2)) x
      LEFT OUTER JOIN USER_PROFILE oup on x.obsUID = oup.USER_PROFILE_ID
      where f.FACILITY_ID = x.Facility_ID
      and   up.USER_PROFILE_ID = x.CUID
      and   aup.USER_PROFILE_ID = x.AUID
      --and   oup.USER_PROFILE_ID = x.obsUID;
      -- Recreate Indexes
      CREATE NONCLUSTERED INDEX [AI_CAR_APPROVEDT_CUID_FACILITY_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT]
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
      CREATE NONCLUSTERED INDEX [AI_CAR_APPROVEDT_CUID_MANAGER_FACILITY_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT]
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
      CREATE NONCLUSTERED INDEX [AI_CAR_APPROVEDT_FACILITY_CUID_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[CHART_AUDIT_RESULT]
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
