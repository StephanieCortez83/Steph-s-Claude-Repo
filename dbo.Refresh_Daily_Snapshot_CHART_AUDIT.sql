SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[Refresh_Daily_Snapshot_CHART_AUDIT]
WITH EXEC AS CALLER
AS


-- CHART_AUDIT_ACTION
-- Drop Index and Truncate Table
-- CHART_AUDIT_ACTION
      DROP INDEX [AI_CHART_AUDIT_ACTION] ON [dbo].[CHART_AUDIT_ACTION];
      TRUNCATE TABLE [dbo].[CHART_AUDIT_ACTION];

IF object_id('RevCycleTransactionSnapshot.dbo.ChartSubset', 'U') is not null
BEGIN
	DROP TABLE [RevCycleTransactionSnapshot].[dbo].[ChartSubset];
END;

-- Populate ChartSubset with rows from CHART that meet the common criteria of all the queries.
	-- This helps reduce logical reads and duration by 80%.
SELECT 
	c.CHART_ID, c.service_agreement_id, c.Override_Facility_Level_ID, c.Facility_Level_ID,
	c.physician_id, c.Medical_Record_Num, c.Admission_Date_Time,
	c.Physician_Service_Proc_ID, c.Override_Physician_Service_Proc_ID, c.Physician_Critical_Care,
	c.Service_Agreement_Arrival_Mode_ID, c.Arrival_Date_Time, c.Patient_Disposition_Map_ID,
	c.Time_To_Room, c.Service_Agreement_Triage_Acuity_ID, c.Gender, c.Resident_Participated_In_Care,
	c.Completion_Date, c.Financial_Class_CD, c.Patient_DOB, c.Nurse_Practitioner_ID, c.Time_Of_Service,
	c.Patient_Disposition_ID, c.Facility_Admin_Chart_ID, c.Time_Of_DIS, c.Condition_Of_Accident_ID, c.Clinic_ID,
	c.Attestation_Signed_By_Attending, c.Scribe_ID, c.Last_Encounter_Date, c.Last_Menstrual_Period, c.Patient_Age,
	c.Time_Of_Phys_Eval, c.Time_Of_Triage, c.Medical_Examiner_Notified, c.Organ_Donation, 
	c.Seen_In_ED_Within_48_Hours_Of_OR, c.Provider_Eval_Performed_By_Ind,
	c.Facility_ID, c.Facility_Chart_ID, c.Facility_Service_Level_Audit_Comment, c.Infusion_Injection_Audit_Comment,
	c.Facility_Procedures_Audit_Comment, c.Physician_Service_Level_Audit_Comment, c.Physician_Procedures_Audit_Comment,
	c.Approval_Reason_Code, Diagnosis_Coding_Audit_Comment, c.Observation_Auditor_Review_Feedback, c.Observation_Procedures_Audit_Comment,
	c.Observation_Infusion_Injection_Audit_Comment, c.Demographic_Audit_Comment, c.NON_ER_PROCEDURES_OVERRIDE, c.FACILITY_LOS_27_MODIFIER, c.PHYSICIAN_SERVICE_MOD

	-- columns below only need to be included if desired to leave the common CHART criteria in each query (minimizing the edits needed)
	, chart_Status_ID, sent_date, approved_date, APPROVED_BY_USER_PROFILE_ID

	-- the two columns below will be subsequently used by the stored proc for SECOND_LEVEL processing
	, START_SECOND_LEVEL_QA_USER_PROFILE_ID, SECOND_LEVEL_QA_APPROVED_DATETIME, SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID

  -- Added for Physician query in chart demographic section
  ,OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
 INTO [RevCycleTransactionSnapshot].[dbo].[ChartSubset]
FROM chart as c with (NOLOCK)
WHERE 
	c.CHART_STATUS_ID in (4, 5)
	and datediff(Day, c.APPROVED_DATE, getdate()) <= 365
	and ((case when c.SENT_DATE is null then '20080510'
               else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')


-- Recreate Table Data
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select 
		DISTINCT
			'1' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        (case when fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID > 0 then 
                                    (select fsi.description FROM FACILITY_SERVICE_SCHEDULE_ITEM fsi WITH (NOLOCK)
                                    where fsi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)
                          else
                        (select fs.DESCRIPTION from facility_service fs with (NOLOCK)
                                    where fs.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID) end) 'Description'
      from  facility_service_evaluation_history fseh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where fseh.CHART_ID not in (select fse.CHART_ID from facility_service_evaluation fse with (NOLOCK)
                        where fse.CHART_ID = fseh.CHART_ID
                        and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID)
               OR (fse.FACILITY_SERVICE_SCHEDULE_ID IS NOT NULL
                   AND fse.FACILITY_SERVICE_SCHEDULE_ID = fseh.FACILITY_SERVICE_SCHEDULE_ID
                   AND fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)))
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = fseh.FACILITY_SVC_EVAL_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION_HISTORY') = 0 
      and   c.CHART_ID = fseh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select 
	  DISTINCT
		'1' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        (case when fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID > 0 then 
                                    (select fsi.description FROM FACILITY_SERVICE_SCHEDULE_ITEM fsi WITH (NOLOCK)
                                    where fsi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID)
                          else
                        (select fs.DESCRIPTION from facility_service fs with (NOLOCK)
                                    where fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID) end) 'Description'
      from  facility_service_evaluation fse with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where fse.CHART_ID not in (select fseh.CHART_ID from facility_service_evaluation_history fseh with (NOLOCK)
                        where fseh.CHART_ID = fse.CHART_ID
                        and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID)
                OR (fse.FACILITY_SERVICE_SCHEDULE_ID IS NOT NULL
                    AND fse.FACILITY_SERVICE_SCHEDULE_ID = fseh.FACILITY_SERVICE_SCHEDULE_ID
                    AND fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)))
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa  WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = fse.FACILITY_SVC_EVAL_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION') = 0 and   c.CHART_ID = fse.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        --and   cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'
                        --and   (select COUNT(*) from CHARGE_MASTER cm2 where cm2.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm2.CPT_CODE <> 'SUPLY') = 0
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
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

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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

-- Facility procedures modifiers
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + fpeh.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where 
	  fpeh.CHART_ID in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
	  and fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
						and   fpe.modifiers = fpeh.modifiers
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0 
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0      				                 
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                          (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + fpe.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where 
	  fpe.CHART_ID  in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID                 
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
	  and fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                 		and   fpe.modifiers = fpeh.modifiers
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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

-- End Facility Procedures modifiers

-- Facility procedures quantity
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(fpeh.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where 
	  fpeh.CHART_ID in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and   fpe.modifiers = fpeh.modifiers)
	  and fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and   fpe.modifiers = fpeh.modifiers
						and   fpe.QUANTITY = fpeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0    
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  				              
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                          (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(fpe.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where 
	  fpe.CHART_ID  in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID                 
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and   fpe.modifiers = fpeh.modifiers)
	  and fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and   fpe.modifiers = fpeh.modifiers
						and   fpe.QUANTITY = fpeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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

-- End Facility Procedures quantity

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
    select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where caph.CLASS='FP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- Additional Facility Procedures modifiers
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + caph.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID) 
	  and caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
						and cap.MODIFIERS = caph.modifiers
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0   
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0      				                 
				               
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
    select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + cap.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID  in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
						and		caph.modifiers = cap.modifiers
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Additional Facility Procedures modifiers

-- Additional Facility Procedures quantity
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(caph.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and cap.MODIFIERS = caph.modifiers) 
	  and caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
					    and cap.MODIFIERS = caph.modifiers
						and cap.QUANTITY = caph.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0   
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0   				               
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
    select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(cap.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID  in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and		caph.modifiers = cap.modifiers)
      and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
   					    and		caph.modifiers = cap.modifiers
                        and     caph.QUANTITY = cap.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Additional Facility Procedures quantity

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'3' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'3' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir WITH (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- Chart infusion results modifiers
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'3' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + cirh.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
	  and cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.modifiers = cirh.modifiers
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'3' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + cir.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir WITH (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
	  and cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.modifiers = cirh.modifiers
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Chart infusion result modifiers

-- Chart infusion results units
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'3' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Units: ' + Convert(varchar,COALESCE(cirh.UNITS,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and   cir.MODIFIERS = cirh.MODIFIERS)
	  and cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and   cir.MODIFIERS = cirh.MODIFIERS
						and   cir.UNITS = cirh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'3' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Units: ' + Convert(varchar,COALESCE(cir.UNITS,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir WITH (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and   cir.MODIFIERS = cirh.MODIFIERS)
	  and cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and   cir.MODIFIERS = cirh.MODIFIERS
						and   cir.UNITS = cirh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Chart infusion result units

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'4' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        (select ps.DESCRIPTION from physician_service ps with (NOLOCK)
                                    where ps.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID) 'Description'
      from  physician_service_eval_history pseh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where pseh.CHART_ID not in (select pse.CHART_ID from physician_service_eval pse with (NOLOCK)
                        where pse.CHART_ID = pseh.CHART_ID
                        and   pse.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = pseh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pseh.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL_HISTORY') = 0                  
      and   c.CHART_ID = pseh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select 
	  DISTINCT
		'4' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        (select ps.DESCRIPTION from physician_service ps with (NOLOCK)
                                    where ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID) 'Description'
      from  physician_service_eval pse with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where pse.CHART_ID not in (select pseh.CHART_ID from physician_service_eval_history pseh with (NOLOCK)
                        where pseh.CHART_ID = pse.CHART_ID
                        and   pseh.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = pse.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pse.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL') = 0                       
      and   c.CHART_ID = pse.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- Begin Additional LOS evaluation
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'4' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        (select concat('(Level ', pseh.LEVEL_NUMBER, ') ') + ps.DESCRIPTION from physician_service ps with (NOLOCK)
                                    where ps.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID) 'Description'
      from  PHYSICIAN_SERVICE_EVAL_ADDITIONAL_LEVEL_HISTORY pseh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where pseh.CHART_ID not in (select pse.CHART_ID from PHYSICIAN_SERVICE_EVAL_ADDITIONAL_LEVEL pse with (NOLOCK)
                        where pse.CHART_ID = pseh.CHART_ID
						and pse.LEVEL_NUMBER = pseh.LEVEL_NUMBER
                        and   pse.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = pseh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pseh.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL_HISTORY') = 0                  
      and   c.CHART_ID = pseh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
        and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select 
	  DISTINCT
		'4' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        (select concat('(Level ', pse.LEVEL_NUMBER, ') ') + ps.DESCRIPTION from physician_service ps with (NOLOCK)
                                    where ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID) 'Description'
      from  PHYSICIAN_SERVICE_EVAL_ADDITIONAL_LEVEL pse with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where pse.CHART_ID not in (select pseh.CHART_ID from PHYSICIAN_SERVICE_EVAL_ADDITIONAL_LEVEL_HISTORY pseh with (NOLOCK)
                        where pseh.CHART_ID = pse.CHART_ID
						and pse.LEVEL_NUMBER = pseh.LEVEL_NUMBER
                        and   pseh.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = pse.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pse.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL') = 0                       
      and   c.CHART_ID = pse.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Additional LOS evaluation

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppeh.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation_history ppeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where ppeh.CHART_ID not in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = ppeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppeh.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY') = 0                     
      and   c.CHART_ID = ppeh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation ppe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where ppe.CHART_ID not in (select ppeh.CHART_ID from physician_procedure_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = ppe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppe.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = ppe.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- Physician procedure modifiers 
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + ppeh.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppeh.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation_history ppeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where ppeh.CHART_ID in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and	ppeh.CHART_ID not in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = ppeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppeh.PHYSICIAN_PROCEDURE_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY') = 0    
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0       				                   
      and   c.CHART_ID = ppeh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + ppe.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation ppe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where ppe.CHART_ID in (select ppeh.CHART_ID from physician_procedure_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
	  and	ppe.CHART_ID not in (select ppeh.CHART_ID from physician_procedure_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = ppe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppe.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = ppe.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
  
-- End Physician procedure modifiers

-- Physician procedure quantity
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(ppeh.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppeh.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation_history ppeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where ppeh.CHART_ID in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS)
      and	ppeh.CHART_ID not in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS
						and   ppe.QUANTITY = ppeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = ppeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppeh.PHYSICIAN_PROCEDURE_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY') = 0         
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0     				              
      and   c.CHART_ID = ppeh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + 'Quantity: ' + Convert(varchar,COALESCE(ppe.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation ppe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where ppe.CHART_ID in (select ppeh.CHART_ID from physician_procedure_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS)
	  and	ppe.CHART_ID not in (select ppeh.CHART_ID from physician_procedure_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS
						and   ppe.QUANTITY = ppeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = ppe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppe.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = ppe.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
  
-- End Physician procedure quantity

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c      
      where caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='PP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where caph.CLASS='PP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365


-- Additional physician procedures modifiers
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + caph.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c      
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='PP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
	  and	caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='PP'
						and   caph.MODIFIERS = cap.MODIFIERS
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY') = 0          
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0  					        
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + cap.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where cap.CHART_ADDITIONAL_PROCEDURE_ID in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where caph.CLASS='PP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
	  and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where caph.CLASS='PP'
						and	  caph.MODIFIERS = cap.MODIFIERS
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Additional physician procedures modifiers

-- Additional physician procedures quantity
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(caph.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c      
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='PP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   caph.MODIFIERS = cap.MODIFIERS)
	  and	caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='PP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   caph.MODIFIERS = cap.MODIFIERS
						and   caph.QUANTITY = cap.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY') = 0   
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0  					               
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(cap.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where cap.CHART_ADDITIONAL_PROCEDURE_ID in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where caph.CLASS='PP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   caph.MODIFIERS = cap.MODIFIERS)
	  and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where caph.CLASS='PP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   caph.MODIFIERS = cap.MODIFIERS
						and   caph.QUANTITY = cap.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Additional physician procedures quantity

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'6' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select ic.icd9_code + ', ' + ic.short_description from icd_9_cm ic with (NOLOCK)
                          where ic.icd9_code = cdch.ICD9_CODE
                              and   ic.effective_date <= c.time_of_service
                              and   ic.expiration_date >= c.time_of_service) 'Description'
      from chart_diagnosis_code_history cdch with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where cdch.CHART_ID not in (select cdc.CHART_ID from chart_diagnosis_code cdc with (NOLOCK)
                        where cdc.CHART_ID = cdch.CHART_ID
                        and   cdc.ICD9_CODE = cdch.ICD9_CODE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cdch.CHART_ID and qa.KEY_VALUE_2 = cdch.ICD9_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE_HISTORY') = 0                  
      and   c.CHART_ID = cdch.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   c.TIME_OF_SERVICE < '2015-10-01'      
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'6' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select ic.icd9_code + ', ' + ic.short_description from icd_9_cm ic with (NOLOCK)
                          where ic.icd9_code = cdc.ICD9_CODE
                              and   ic.effective_date <= c.time_of_service
                              and   ic.expiration_date >= c.time_of_service) 'Description'
      from chart_diagnosis_code cdc with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where cdc.CHART_ID not in (select cdch.CHART_ID from chart_diagnosis_code_history cdch with (NOLOCK)
                        where cdc.CHART_ID = cdch.CHART_ID
                        and   cdc.ICD9_CODE = cdch.ICD9_CODE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cdc.CHART_ID and qa.KEY_VALUE_2 = cdc.ICD9_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE') = 0                   
      and   c.CHART_ID = cdc.CHART_ID
      and   c.TIME_OF_SERVICE < '2015-10-01'      
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
-- Begin ICD-10 Dx Coding
	select 
	DISTINCT
		'D' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cdch.ICD10_CODE + ', ' + ic.short_description from icd10_cm ic with (NOLOCK)
                          where ic.ICD10_CM = REPLACE(cdch.ICD10_CODE,'.','')
                          ) + ' (' + 
							(CASE
							 when cdch.DIAGNOSIS_TYPE_ID = 1 and cdch.IS_PRIMARY = 1 then 'Chief Complaint ' 
							 when cdch.DIAGNOSIS_TYPE_ID = 1 and cdch.IS_PRIMARY = 0 then 'Secondary Complaint ' 
							 when cdch.DIAGNOSIS_TYPE_ID = 2 and cdch.IS_PRIMARY = 1 then 'Primary Dx ' 
							 when cdch.DIAGNOSIS_TYPE_ID = 2 and cdch.IS_PRIMARY = 0 then 'Secondary Dx ' 
							 when cdch.DIAGNOSIS_TYPE_ID = 3 and cdch.IS_PRIMARY = 1 then 'Chief Complaint and Primary Dx ' 
							 when cdch.DIAGNOSIS_TYPE_ID = 3 and cdch.IS_PRIMARY = 0 then 'Complaint and Secondary Dx'
							 when cdch.DIAGNOSIS_TYPE_ID = 5  then 'Chief Complaint and Secondary Dx' 							  
							ELSE '' END) + ')' 'Description'
      from chart_diagnosis_code_history_ICD10 cdch with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where cdch.CHART_ID not in (select cdc.CHART_ID from chart_diagnosis_code_ICD10 cdc with (NOLOCK)
                        where cdc.CHART_ID = cdch.CHART_ID
                        and   cdc.ICD10_CODE = cdch.ICD10_CODE
                        and   cdc.DIAGNOSIS_TYPE_ID = cdch.DIAGNOSIS_TYPE_ID
						and   cdc.LEVEL_NUMBER = cdch.LEVEL_NUMBER)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cdch.CHART_ID and qa.KEY_VALUE_2 = cdch.ICD10_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE_HISTORY_ICD10') = 0                  
      and   c.CHART_ID = cdch.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'D' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cdc.ICD10_CODE + ', ' + ic.short_description from icd10_cm ic with (NOLOCK)
                          where ic.ICD10_CM = REPLACE(cdc.ICD10_CODE,'.','')
							) + ' (' + 
							(CASE
							 when cdc.DIAGNOSIS_TYPE_ID = 1 and cdc.IS_PRIMARY = 1 then 'Chief Complaint ' 
							 when cdc.DIAGNOSIS_TYPE_ID = 1 and cdc.IS_PRIMARY = 0 then 'Secondary Complaint ' 
							 when cdc.DIAGNOSIS_TYPE_ID = 2 and cdc.IS_PRIMARY = 1 then 'Primary Dx ' 
							 when cdc.DIAGNOSIS_TYPE_ID = 2 and cdc.IS_PRIMARY = 0 then 'Secondary Dx ' 
							 when cdc.DIAGNOSIS_TYPE_ID = 3 and cdc.IS_PRIMARY = 1 then 'Chief Complaint and Primary Dx ' 
							 when cdc.DIAGNOSIS_TYPE_ID = 3 and cdc.IS_PRIMARY = 0 then 'Complaint and Secondary Dx' 
							 when cdc.DIAGNOSIS_TYPE_ID = 5  then 'Chief Complaint and Secondary Dx' 
							ELSE '' END) + ')' 'Description'
      from chart_diagnosis_code_ICD10 cdc with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where cdc.CHART_ID not in (select cdch.CHART_ID from chart_diagnosis_code_history_ICD10 cdch with (NOLOCK)
                        where cdc.CHART_ID = cdch.CHART_ID
                        and   cdc.ICD10_CODE = cdch.ICD10_CODE
                        and   cdc.DIAGNOSIS_TYPE_ID = cdch.DIAGNOSIS_TYPE_ID
						and   cdc.LEVEL_NUMBER = cdch.LEVEL_NUMBER)                        
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cdc.CHART_ID and qa.KEY_VALUE_2 = cdc.ICD10_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE_ICD10') = 0                   
      and   c.CHART_ID = cdc.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End ICD-10 Dx Coding	  

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'7' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        fl.DESCRIPTION Description
      from  chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		facility_level fl with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                      
      and   fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   fl.FACILITY_LEVEL_ID = (case when clh.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then clh.FACILITY_LEVEL_ID else clh.OVERRIDE_FACILITY_LEVEL_ID end)
      and   fl.CPT_CODE <> (isnull((select fl2.CPT_CODE from facility_level fl2 with (NOLOCK) 
                              where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then c.FACILITY_LEVEL_ID else c.OVERRIDE_FACILITY_LEVEL_ID end) = fl2.FACILITY_LEVEL_ID)), ''))
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'7' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         fl.DESCRIPTION Description
      from chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		facility_level fl with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                            
      and   fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   fl.FACILITY_LEVEL_ID = (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then c.FACILITY_LEVEL_ID else c.OVERRIDE_FACILITY_LEVEL_ID end)
      and   fl.CPT_CODE <> (isnull((select fl2.CPT_CODE from facility_level fl2 with (NOLOCK) 
                              where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when clh.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then clh.FACILITY_LEVEL_ID else clh.OVERRIDE_FACILITY_LEVEL_ID end) = fl2.FACILITY_LEVEL_ID)), ''))
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

 -- Facility service modifier changes 
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'7' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        'Fac Services Modifier 25 or 27 checkbox' Description
      from  chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and	convert(varchar, c.COMPLETION_DATE, 112) >= '20170123'
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                      
	  and	(((c.FACILITY_LOS_27_MODIFIER is NULL or c.FACILITY_LOS_27_MODIFIER = 0) AND clh.FACILITY_LOS_27_MODIFIER = 1)
			or ((c.NON_ER_PROCEDURES_OVERRIDE is NULL or c.NON_ER_PROCEDURES_OVERRIDE = 0) AND clh.NON_ER_PROCEDURES_OVERRIDE = 1))
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'7' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                        'Fac Services Modifier 25 or 27 checkbox' Description
      from chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and	convert(varchar, c.COMPLETION_DATE, 112) >= '20170123'
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                            
	  and	(((clh.FACILITY_LOS_27_MODIFIER is NULL or clh.FACILITY_LOS_27_MODIFIER = 0) AND c.FACILITY_LOS_27_MODIFIER = 1)
			or ((clh.NON_ER_PROCEDURES_OVERRIDE is NULL or clh.NON_ER_PROCEDURES_OVERRIDE = 0) AND c.NON_ER_PROCEDURES_OVERRIDE = 1))
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Facility service modifier changes 


-- populate an additional subset table to improve performance when processing Action 'R', Class '8'
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartSubset_R8', 'U') is not null
	BEGIN
		DROP TABLE [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8];
	END;

	SELECT 
		'8' as 'Class',
		'R' as 'Action',
		c.CHART_ID
		, psp.DESCRIPTION Description
		, c.service_agreement_id
		, c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, c.PHYSICIAN_SERVICE_PROC_ID
		, psp.cpt_Code
		, c.PHYSICIAN_SERVICE_MOD
	 INTO [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8]
	FROM 
		chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		physician_service_procedure psp with (NOLOCK)
	WHERE 
		c.CHART_ID = clh.CHART_ID
		and c.CHART_STATUS_ID in (4, 5)
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = 'PLOS'
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY')     
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = c.chart_id
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART') 						                 
		and psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		and psp.PHYSICIAN_SERVICE_PROC_ID = (case
				when clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
				then clh.PHYSICIAN_SERVICE_PROC_ID 
				else clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
		and ((		case when c.SENT_DATE is null 
					then '20080510'
					else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
		and clh.PHYSICIAN_CRITICAL_CARE <> 1
		and datediff(Day, c.APPROVED_DATE, getdate()) <= 365


-- this insert statement sources from ChartSubset_R8
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
	select 
	DISTINCT
		'8' as 'Class',
		'R' as 'Action',
		t.CHART_ID,
		t.DESCRIPTION Description
	from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8] as t
	where isnull(t.cpt_code,'') <>
	isnull((
		select psp.cpt_code
		from physician_service_procedure as psp
		where t.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
			and psp.PHYSICIAN_SERVICE_PROC_ID = case
				when t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
				then t.PHYSICIAN_SERVICE_PROC_ID 
				else t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end
	),'')

	  option (maxdop 4)


-- populate an additional subset table to improve performance when processing Action 'A', Class '8'
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartSubset_A8', 'U') is not null
	BEGIN
		DROP TABLE [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8];
	END;

	SELECT 
		'8' as 'Class',
		'A' as 'Action',
		c.CHART_ID
		, psp.DESCRIPTION Description
		, c.service_agreement_id
		, clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, clh.PHYSICIAN_SERVICE_PROC_ID
		, psp.cpt_Code
		, clh.PHYSICIAN_SERVICE_MOD
	 INTO [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8]
	FROM 
		chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		physician_service_procedure psp with (NOLOCK)
	WHERE 
		c.CHART_ID = clh.CHART_ID 
		and c.CHART_STATUS_ID in (4, 5)
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = 'PLOS'
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY')    
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = c.chart_id
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART') 						        
		and psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		and psp.PHYSICIAN_SERVICE_PROC_ID = (case
				when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
				then c.PHYSICIAN_SERVICE_PROC_ID 
				else c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
		and ((		case when c.SENT_DATE is null 
					then '20080510'
					else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
		and c.PHYSICIAN_CRITICAL_CARE <> 1
		and datediff(Day, c.APPROVED_DATE, getdate()) <= 365


-- this insert statement sources from ChartSubset_A8
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
	select 
	DISTINCT
		'8' as 'Class',
		'A' as 'Action',
		t.CHART_ID,
		t.DESCRIPTION Description
	from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8] as t
	where isnull(t.cpt_code,'') <>
	isnull((
		select psp.cpt_code
		from physician_service_procedure as psp
		where t.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
			and psp.PHYSICIAN_SERVICE_PROC_ID = case
				when t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
				then t.PHYSICIAN_SERVICE_PROC_ID 
				else t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end
	),'')

	UNION
		select 
	DISTINCT
		'8' as 'Class',
		'A' as 'Action',
		t.CHART_ID,
		'Phys Service Modifiers changed from: ' + 
			case when t.PHYSICIAN_SERVICE_MOD > '' then t.PHYSICIAN_SERVICE_MOD else 'None' end + ' to ' + 
			case when c.PHYSICIAN_SERVICE_MOD > '' then c.PHYSICIAN_SERVICE_MOD else 'None' end as Description
	from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8] as t, 
		  [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
	where c.chart_id = t.chart_id
	and	convert(varchar, c.COMPLETION_DATE, 112) >= '20170123'
	and   c.PHYSICIAN_SERVICE_MOD <> t.PHYSICIAN_SERVICE_MOD



-- subsequent insert statements below source from ChartSubset

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        'Critical Care' Description
      from  chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = 'PLOS'
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   clh.PHYSICIAN_CRITICAL_CARE = 1
      and   c.PHYSICIAN_CRITICAL_CARE <> 1
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
  
	UNION
	  select 
	  DISTINCT
		'8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        '- No Level -' Description
      from  chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = 'PLOS'
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   clh.PHYSICIAN_SERVICE_PROC_ID = -1
      and   c.PHYSICIAN_SERVICE_PROC_ID > 0
	  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

	UNION
	  select 
	  DISTINCT
		'8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        '- No Level -' Description
      from  chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = 'PLOS'
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   c.PHYSICIAN_SERVICE_PROC_ID = -1
      and   clh.PHYSICIAN_SERVICE_PROC_ID > 0
	  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

	UNION
		select 
	DISTINCT
		'8' as 'Class',
		'A' as 'Action',
		t.CHART_ID,
		'Phys Service Modifiers changed from: ' + 
			case when t.PHYSICIAN_SERVICE_MOD > '' then t.PHYSICIAN_SERVICE_MOD else 'None' end + ' to ' + 
			case when c.PHYSICIAN_SERVICE_MOD > '' then c.PHYSICIAN_SERVICE_MOD else 'None' end as Description
	from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8] as t, 
		  [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
	where c.chart_id = t.chart_id
	and	convert(varchar, c.COMPLETION_DATE, 112) >= '20170123'
	and (CASE WHEN c.PHYSICIAN_SERVICE_MOD IS NULL THEN '' ELSE c.PHYSICIAN_SERVICE_MOD END) <> (CASE WHEN t.PHYSICIAN_SERVICE_MOD IS NULL THEN '' ELSE t.PHYSICIAN_SERVICE_MOD END)   
	  

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         'Critical Care' Description
      from chart_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = 'PLOS'
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   c.PHYSICIAN_CRITICAL_CARE = 1
      and   clh.PHYSICIAN_CRITICAL_CARE <> 1
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- Multiple E&M Level changes 
-- populate an additional subset table to improve performance when processing Action 'R', Class '8' for additional E&M levels of service
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartSubset_R8_LOS', 'U') is not null
	BEGIN
		DROP TABLE [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8_LOS];
	END;
	
	SELECT 
		'8' as 'Class',
		'R' as 'Action',
		c.CHART_ID
		,c2.LEVEL_NUMBER
		, psp.DESCRIPTION Description
		, c.service_agreement_id
		, c2.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, c2.PHYSICIAN_SERVICE_PROC_ID
		, psp.cpt_Code
		, c2.PHYSICIAN_SERVICE_MOD
	 INTO [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8_LOS]
	FROM 
		chart_physician_additional_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		Chart_Physician_Level_of_Service as c2,
		physician_service_procedure psp with (NOLOCK)
	WHERE 
		c.CHART_ID = clh.CHART_ID
		and c.CHART_ID = c2.CHART_ID
		and clh.LEVEL_NUMBER = c2.LEVEL_NUMBER
		and c.CHART_STATUS_ID in (4, 5)
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = 'PLOS'
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY')                      
		and psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		and psp.PHYSICIAN_SERVICE_PROC_ID = (case
				when clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
				then clh.PHYSICIAN_SERVICE_PROC_ID 
				else clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
		and ((		case when c.SENT_DATE is null 
					then '20080510'
					else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
		and clh.PHYSICIAN_CRITICAL_CARE <> 1
		and datediff(Day, c.APPROVED_DATE, getdate()) <= 365

		
-- this insert statement sources from ChartSubset_R8
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
	select 
	DISTINCT
		'8' as 'Class',
		'R' as 'Action',
		t.CHART_ID,
		Concat('(Level ', t.LEVEL_NUMBER, ') ') + t.DESCRIPTION Description
	from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8_LOS] as t
	where isnull(t.cpt_code,'') <>
	isnull((
		select psp.cpt_code
		from physician_service_procedure as psp
		where t.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
			and psp.PHYSICIAN_SERVICE_PROC_ID = case
				when t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
				then t.PHYSICIAN_SERVICE_PROC_ID 
				else t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end
	),'')

	  option (maxdop 4)


-- populate an additional subset table to improve performance when processing Action 'A', Class '8' for additional E&M levels of service
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartSubset_A8', 'U') is not null
	BEGIN
		DROP TABLE [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8_LOS];
	END;

	SELECT 
		'8' as 'Class',
		'A' as 'Action',
		c.CHART_ID
		,c2.LEVEL_NUMBER
		, psp.DESCRIPTION Description
		, c.service_agreement_id
		, clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, clh.PHYSICIAN_SERVICE_PROC_ID
		, psp.cpt_Code
		, clh.PHYSICIAN_SERVICE_MOD
	 INTO [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8_LOS]
	FROM 
		chart_physician_additional_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		Chart_Physician_Level_of_Service as c2,
		physician_service_procedure psp with (NOLOCK)
	WHERE 
		c.CHART_ID = clh.CHART_ID 
		and c.CHART_STATUS_ID in (4, 5)
		and c2.CHART_ID = c.CHART_ID
		and clh.LEVEL_NUMBER = c2.LEVEL_NUMBER
		and 0 = (select COUNT(*) 
			from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
			where 
					qa.KEY_VALUE_1 = clh.CHART_ID 
					and qa.KEY_VALUE_2 = 'PLOS'
					and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY')            
		and psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		and psp.PHYSICIAN_SERVICE_PROC_ID = (case
				when c2.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
				then c2.PHYSICIAN_SERVICE_PROC_ID 
				else c2.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
		and ((		case when c.SENT_DATE is null 
					then '20080510'
					else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
		and c2.PHYSICIAN_CRITICAL_CARE <> 1
		and datediff(Day, c.APPROVED_DATE, getdate()) <= 365


-- this insert statement sources from ChartSubset_A8_LOS
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
	select 
	DISTINCT
		'8' as 'Class',
		'A' as 'Action',
		t.CHART_ID,
		Concat('(Level ', t.LEVEL_NUMBER, ') ') + t.DESCRIPTION Description
	from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8_LOS] as t
	where isnull(t.cpt_code,'') <>
	isnull((
		select psp.cpt_code
		from physician_service_procedure as psp
		where t.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
			and psp.PHYSICIAN_SERVICE_PROC_ID = case
				when t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
				then t.PHYSICIAN_SERVICE_PROC_ID 
				else t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end
	),'')

	UNION
		select 
	DISTINCT
		'8' as 'Class',
		'A' as 'Action',
		t.CHART_ID,
		Concat('(Level ', t.LEVEL_NUMBER, ') ') + 'Phys Service Modifiers changed from: ' + 
			case when t.PHYSICIAN_SERVICE_MOD > '' then t.PHYSICIAN_SERVICE_MOD else 'None' end + ' to ' + 
			case when c2.PHYSICIAN_SERVICE_MOD > '' then c2.PHYSICIAN_SERVICE_MOD else 'None' end as Description
	from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8_LOS] as t, 
		  [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		Chart_Physician_Level_of_Service as c2
	where c.chart_id = t.chart_id
	and c2.chart_id = t.chart_id
	and c2.level_number = t.level_number
	and	convert(varchar, c.COMPLETION_DATE, 112) >= '20170123'
	and   c2.PHYSICIAN_SERVICE_MOD <> t.PHYSICIAN_SERVICE_MOD



-- subsequent insert statements below source from ChartSubset

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        'Critical Care' Description
      from  chart_physician_additional_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		Chart_Physician_Level_of_Service as c2
      where c.CHART_ID = clh.CHART_ID
	  and   c.CHART_ID = c2.CHART_ID
	  and   c2.LEVEL_NUMBER = clh.LEVEL_NUMBER
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   clh.PHYSICIAN_CRITICAL_CARE = 1
      and   c2.PHYSICIAN_CRITICAL_CARE <> 1
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
  
	UNION
	  select 
	  DISTINCT
		'8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        '- No Level -' Description
      from  chart_physician_additional_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		Chart_Physician_Level_of_Service as c2
      where c.CHART_ID = clh.CHART_ID
	  and   c.CHART_ID = c2.CHART_ID
	  and   c2.LEVEL_NUMBER = clh.LEVEL_NUMBER
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   clh.PHYSICIAN_SERVICE_PROC_ID = -1
      and   c2.PHYSICIAN_SERVICE_PROC_ID > 0
	  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

	UNION
	  select 
	  DISTINCT
		'8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        '- No Level -' Description
      from  chart_physician_additional_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		Chart_Physician_Level_of_Service as c2
      where c.CHART_ID = clh.CHART_ID
	  and   c.CHART_ID = c2.CHART_ID
	  and   c2.LEVEL_NUMBER = clh.LEVEL_NUMBER
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   c2.PHYSICIAN_SERVICE_PROC_ID = -1
      and   clh.PHYSICIAN_SERVICE_PROC_ID > 0
	  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

	UNION
		select 
	DISTINCT
		'8' as 'Class',
		'A' as 'Action',
		t.CHART_ID,
		'Phys Service Modifiers changed from: ' + 
			case when t.PHYSICIAN_SERVICE_MOD > '' then t.PHYSICIAN_SERVICE_MOD else 'None' end + ' to ' + 
			case when c2.PHYSICIAN_SERVICE_MOD > '' then c2.PHYSICIAN_SERVICE_MOD else 'None' end as Description
	from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8_LOS] as t, 
		  [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		Chart_Physician_Level_of_Service as c2
	where c.chart_id = t.chart_id
	  and   c.CHART_ID = c2.CHART_ID
	  and   c2.LEVEL_NUMBER = t.LEVEL_NUMBER
	and	convert(varchar, c.COMPLETION_DATE, 112) >= '20170123'
	and (CASE WHEN c2.PHYSICIAN_SERVICE_MOD IS NULL THEN '' ELSE c2.PHYSICIAN_SERVICE_MOD END) <> (CASE WHEN t.PHYSICIAN_SERVICE_MOD IS NULL THEN '' ELSE t.PHYSICIAN_SERVICE_MOD END)   
	  

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         'Critical Care' Description
      from chart_physician_additional_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		Chart_Physician_Level_of_Service as c2
      where c.CHART_ID = clh.CHART_ID
	  and   c.CHART_ID = c2.CHART_ID
	  and   c2.LEVEL_NUMBER = clh.LEVEL_NUMBER
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   c2.PHYSICIAN_CRITICAL_CARE = 1
      and   clh.PHYSICIAN_CRITICAL_CARE <> 1
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365


-- End Multiple E&M level changes


-- Observation Phase II changes
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'A' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'A' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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

	-- Facility procedures with modifiers
	insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'A' as 'Class',
        'R' as 'Action',
        c.CHART_ID, 
            (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + fpeh.modifiers from charge_master cm with (NOLOCK)
            where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and	fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
						and	  fpe.MODIFIERS = fpeh.MODIFIERS
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'A' as 'Class',
        'A' as 'Action',
        c.CHART_ID, 
            (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + fpe.modifiers from charge_master cm with (NOLOCK)
            where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID                 
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
	  and	fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID   
						and	  fpe.MODIFIERS = fpeh.MODIFIERS              
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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
	  
	-- End facility procedures with modifiers

	-- Facility procedures quantity
	insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'A' as 'Class',
        'R' as 'Action',
        c.CHART_ID, 
            (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(fpeh.QUANTITY,0)) from charge_master cm with (NOLOCK)
            where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and	  fpe.MODIFIERS = fpeh.MODIFIERS)
      and	fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and	  fpe.MODIFIERS = fpeh.MODIFIERS
						and   fpe.QUANTITY = fpeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'A' as 'Class',
        'A' as 'Action',
        c.CHART_ID, 
            (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(fpe.QUANTITY,0)) from charge_master cm with (NOLOCK)
            where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID                 
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and	  fpe.MODIFIERS = fpeh.MODIFIERS)
	  and	fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID   
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and	  fpe.MODIFIERS = fpeh.MODIFIERS
						and   fpe.QUANTITY = fpeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
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
	  
	-- End facility procedures quantity

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
    select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where caph.CLASS='FP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- Additional Facility Procedures modifiers
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + caph.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID) 
	  and caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
						and cap.MODIFIERS = caph.modifiers
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0   
				               
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
    select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + cap.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID  in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
						and		caph.modifiers = cap.modifiers
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Additional Facility Procedures modifiers

-- Additional Facility Procedures quantity
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
select 
	  DISTINCT
		'2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(caph.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and cap.MODIFIERS = caph.modifiers) 
	  and caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
					    and cap.MODIFIERS = caph.modifiers
						and cap.QUANTITY = caph.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY') = 0   
				               
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
    select 
	  DISTINCT
		'2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(cap.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,						
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID  in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and		caph.modifiers = cap.modifiers)
      and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
   					    and		caph.modifiers = cap.modifiers
                        and     caph.QUANTITY = cap.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

-- End Additional Facility Procedures quantity

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select 
	  DISTINCT
		'B' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'B' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir WITH (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

	-- Chart infusion results with modifiers
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select 
	  DISTINCT
		'B' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + cirh.modifiers  from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
	  and	 cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
						and	  cir.MODIFIERS = cirh.MODIFIERS
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
			'B' as 'Class',
            'A' as 'Action',
            c.CHART_ID, 
                (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + cir.modifiers from charge_master cm with (NOLOCK)
                where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir WITH (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
	  and	cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
						and	  cir.MODIFIERS = cirh.MODIFIERS
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

	-- End Chart infusion results with modifiers

	-- Chart infusion results with units
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select 
	  DISTINCT
		'B' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Units: ' + Convert(varchar,COALESCE(cirh.UNITS,0))  from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and	  cir.MODIFIERS = cirh.MODIFIERS)
	  and	 cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and	  cir.MODIFIERS = cirh.MODIFIERS
						and   cir.UNITS = cirh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
			'B' as 'Class',
            'A' as 'Action',
            c.CHART_ID, 
                (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Units: ' + Convert(varchar,COALESCE(cir.UNITS,0)) from charge_master cm with (NOLOCK)
                where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir WITH (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and	  cir.MODIFIERS = cirh.MODIFIERS)
	  and	cir.CHART_ID not in (select cirh.CHART_ID from chart_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
						and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and	  cir.MODIFIERS = cirh.MODIFIERS
						and   cir.UNITS = cirh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

	-- End Chart infusion results with units

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select 
	  DISTINCT
		'9' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', ' + CONVERT(VARCHAR, corh.UNITS) + ' Units' from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_observation_encounter_result_history corh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where corh.CHART_ID not in (select cor.CHART_ID from chart_observation_encounter_result cor with (NOLOCK)
                        where cor.CHART_ID = corh.CHART_ID
                        and   cor.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID
						and   cor.DATE_OF_SERVICE = corh.DATE_OF_SERVICE
                        and   cor.UNITS = corh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = corh.CHART_OBSERVATION_ENCOUNTER_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_OBSERVATION_ENCOUNTER_RESULT_HISTORY') = 0                 
      and   c.CHART_ID = corh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'9' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', ' + CONVERT(VARCHAR, cor.UNITS) + ' Units' from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cor.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_observation_encounter_result cor WITH (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      where cor.CHART_ID not in (select corh.CHART_ID from chart_observation_encounter_result_history corh with (NOLOCK)
                        where cor.CHART_ID = corh.CHART_ID
                        and   cor.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID
						and   cor.DATE_OF_SERVICE = corh.DATE_OF_SERVICE
                        and   cor.UNITS = corh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cor.CHART_OBSERVATION_ENCOUNTER_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_OBSERVATION_ENCOUNTER_RESULT') = 0                     
      and   c.CHART_ID = cor.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.APPROVED_DATE, getdate()) <= 365
  

-- Populate an additional subset table (ChartSubset2) to be referenced by queries below taken and modified from udf_GetChartDemographicAuditAction.
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartSubset2', 'U') is not null
	BEGIN
		DROP TABLE [RevCycleTransactionSnapshot].[dbo].[ChartSubset2];
	END;

	SELECT *
	 INTO [RevCycleTransactionSnapshot].[dbo].[ChartSubset2]
	FROM [RevCycleTransactionSnapshot].[dbo].[ChartSubset] 
	WHERE APPROVED_BY_USER_PROFILE_ID <> 2		-- Exclude charts that were system approved


-- declare variables used in the queries below taken from udf_GetChartDemographicAuditAction
DECLARE @ApprovedSince DATETIME = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)-365
DECLARE	@DemographicQaPhase2 DATETIME = '1/30/2015'


insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'MRN: ' + ISNULL(c.MEDICAL_RECORD_NUM, 'Not Set') [Description]
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
			AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '1'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'MRN: ' + ISNULL(cdh.MEDICAL_RECORD_NUM, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
			AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '1'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Admission Date: ' + ISNULL(convert(VARCHAR, c.ADMISSION_DATE_TIME, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '2'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Admission Date: ' + ISNULL(convert(VARCHAR, cdh.ADMISSION_DATE_TIME, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '2'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Arrival Mode: ' + ISNULL(saam.DESCRIPTION, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '3'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Arrival Mode: ' + ISNULL(saam.DESCRIPTION, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '3'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Arrival Date: ' + ISNULL(convert(VARCHAR, cdh.ARRIVAL_DATE_TIME, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '4'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Arrival Date: ' + ISNULL(convert(VARCHAR, cdh.ARRIVAL_DATE_TIME, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '4'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Patient Disposition: ' + ISNULL(pdm.DESCRIPTION + '(' + pdm.FACILITY_PATIENT_DISPOSITION + ')', 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON c.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '4'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Patient Disposition: ' + ISNULL(pdm.DESCRIPTION + '(' + pdm.FACILITY_PATIENT_DISPOSITION + ')', 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON cdh.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '4'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Physician: ' + ISNULL((ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON c.PHYSICIAN_ID = fp.FACILITY_PROF_ID
    LEFT JOIN [dbo].[SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE] oa WITH (NOLOCK) ON oa.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID] = c.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
      -- Exclude physician differences on OBS accounts when the arrival source is anything other than ED
      AND (c.PATIENT_DISPOSITION_ID <> 5 OR (oa.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD] IS NULL or (c.PATIENT_DISPOSITION_ID = 5 AND oa.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD] = 1)))
			AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '6'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Physician: ' + ISNULL((ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON cdh.PHYSICIAN_ID = fp.FACILITY_PROF_ID
    LEFT JOIN [dbo].[SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE] oa WITH (NOLOCK) ON oa.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID] = c.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
      -- Exclude physician differences on OBS accounts when the arrival source is anything other than ED
      AND (c.PATIENT_DISPOSITION_ID <> 5 OR (oa.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD] IS NULL or (c.PATIENT_DISPOSITION_ID = 5 AND oa.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD] = 1)))
			AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '6'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Time to Room: ' + ISNULL(convert(VARCHAR, c.TIME_TO_ROOM, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '7'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Time to Room: ' + ISNULL(convert(VARCHAR, cdh.TIME_TO_ROOM, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '7'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Triage Accuity: ' + ISNULL(sata.DESCRIPTION, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
			AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
			AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '8'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Triage Accuity: ' + ISNULL(sata.DESCRIPTION, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
			AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
			AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '8'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Gender: ' + ISNULL(c.GENDER, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '9'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Gender: ' + ISNULL(cdh.GENDER, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '9'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Resident Participated in Care: ' + CASE 
				WHEN c.RESIDENT_PARTICIPATED_IN_CARE IS NULL
					THEN 'Not Set'
				WHEN c.RESIDENT_PARTICIPATED_IN_CARE = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '10'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Resident Participated in Care: ' + CASE 
				WHEN cdh.RESIDENT_PARTICIPATED_IN_CARE IS NULL
					THEN 'Not Set'
				WHEN cdh.RESIDENT_PARTICIPATED_IN_CARE = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '10'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Financial Class: ' + ISNULL(ffc.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND ffc.FINANCIAL_CLASS_CD = cdh.FINANCIAL_CLASS_CD
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '11'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Financial Class: ' + ISNULL(ffc.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '11'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'DOB: ' + ISNULL(CONVERT(VARCHAR, c.PATIENT_DOB, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '12'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'DOB: ' + ISNULL(CONVERT(VARCHAR, cdh.PATIENT_DOB, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '12'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'NP/PA: ' + ISNULL((ltrim(rtrim(np.LAST_NAME)) + ', ' + ltrim(rtrim(np.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(np.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON c.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '13'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
      		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'NP/PA: ' + ISNULL((ltrim(rtrim(np.LAST_NAME)) + ', ' + ltrim(rtrim(np.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(np.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON cdh.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '13'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'DOS: ' + ISNULL(CONVERT(VARCHAR, c.TIME_OF_SERVICE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '14'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
      		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'DOS: ' + ISNULL(CONVERT(VARCHAR, cdh.TIME_OF_SERVICE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '14'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Patient Disposition: ' + ISNULL(pd.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '15'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
      		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Patient Disposition: ' + ISNULL(pd.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = cdh.PATIENT_DISPOSITION_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '15'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Facility Admin Chart ID: ' + ISNULL(c.FACILITY_ADMIN_CHART_ID, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '16'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Facility Admin Chart ID: ' + ISNULL(cdh.FACILITY_ADMIN_CHART_ID, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '16'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Time of Discharge: ' + ISNULL(CONVERT(VARCHAR, c.TIME_OF_DIS, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '17'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Time of Discharge: ' + ISNULL(CONVERT(VARCHAR, cdh.TIME_OF_DIS, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '17'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Condition of Accident: ' + ISNULL(coa.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND coa.CONDITION_OF_ACCIDENT_ID = c.CONDITION_OF_ACCIDENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
			AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '18'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Condition of Accident: ' + ISNULL(coa.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND coa.CONDITION_OF_ACCIDENT_ID = cdh.CONDITION_OF_ACCIDENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
			AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '18'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Clinic: ' + ISNULL(cl.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND cl.CLINIC_ID = c.CLINIC_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '19'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Clinic: ' + ISNULL(cl.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND cl.CLINIC_ID = cdh.CLINIC_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '19'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Attestation Signed by Attending: ' + CASE 
				WHEN c.ATTESTATION_SIGNED_BY_ATTENDING IS NULL
					THEN 'Not Set'
				WHEN c.ATTESTATION_SIGNED_BY_ATTENDING = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '20'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Attestation Signed by Attending: ' + CASE 
				WHEN cdh.ATTESTATION_SIGNED_BY_ATTENDING IS NULL
					THEN 'Not Set'
				WHEN cdh.ATTESTATION_SIGNED_BY_ATTENDING = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '20'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Scribe: ' + ISNULL((ltrim(rtrim(s.LAST_NAME)) + ', ' + ltrim(rtrim(s.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(s.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON c.SCRIBE_ID = s.FACILITY_PROF_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
			AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '21'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Scribe: ' + ISNULL((ltrim(rtrim(s.LAST_NAME)) + ', ' + ltrim(rtrim(s.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(s.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON cdh.SCRIBE_ID = s.FACILITY_PROF_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
			AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '21'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Last Encounter Date: ' + ISNULL(CONVERT(VARCHAR, c.LAST_ENCOUNTER_DATE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '22'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Last Encounter Date: ' + ISNULL(CONVERT(VARCHAR, cdh.LAST_ENCOUNTER_DATE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '22'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'LMP: ' + ISNULL(CONVERT(VARCHAR, c.LAST_MENSTRUAL_PERIOD, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
			AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '23'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'LMP: ' + ISNULL(CONVERT(VARCHAR, cdh.LAST_MENSTRUAL_PERIOD, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
			AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '23'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Patient Age: ' + ISNULL(CONVERT(VARCHAR, c.PATIENT_AGE), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '25'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Patient Age: ' + ISNULL(CONVERT(VARCHAR, cdh.PATIENT_AGE), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '25'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Physician Eval: ' + ISNULL(CONVERT(VARCHAR, c.TIME_OF_PHYS_EVAL, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '26'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Physician Eval: ' + ISNULL(CONVERT(VARCHAR, cdh.TIME_OF_PHYS_EVAL, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '26'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Time of Triage: ' + ISNULL(CONVERT(VARCHAR, c.TIME_OF_TRIAGE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '27'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
      		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Time of Triage: ' + ISNULL(CONVERT(VARCHAR, cdh.TIME_OF_TRIAGE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '27'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Medical Examiner Notified: ' + CASE 
				WHEN c.MEDICAL_EXAMINER_NOTIFIED IS NULL
					THEN 'Not Set'
				WHEN c.MEDICAL_EXAMINER_NOTIFIED = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '28'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
      		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Medical Examiner Notified: ' + CASE 
				WHEN cdh.MEDICAL_EXAMINER_NOTIFIED IS NULL
					THEN 'Not Set'
				WHEN cdh.MEDICAL_EXAMINER_NOTIFIED = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '28'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Organ Donation: ' + CASE 
				WHEN c.ORGAN_DONATION IS NULL
					THEN 'Not Set'
				WHEN c.ORGAN_DONATION = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '29'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
      		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Organ Donation: ' + CASE 
				WHEN cdh.ORGAN_DONATION IS NULL
					THEN 'Not Set'
				WHEN cdh.ORGAN_DONATION = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '29'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Seen in ED within 48 Hours of OR: ' + CASE 
				WHEN c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR IS NULL
					THEN 'Not Set'
				WHEN c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '30'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
      		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Seen in ED within 48 Hours of OR: ' + CASE 
				WHEN cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR IS NULL
					THEN 'Not Set'
				WHEN cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR = 1
					THEN 'Yes'
				ELSE 'No'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '30'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Physician E/M Provider: ' + CASE 
				WHEN c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
					THEN 'Not Set'
				WHEN c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
					THEN 'Mid-level'
				ELSE 'Attending'
				END [DESCRIPTION]
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(cdh.PROVIDER_EVAL_PERFORMED_BY_IND, '') <> ISNULL(c.PROVIDER_EVAL_PERFORMED_BY_IND, '')
						AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '31'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved
		
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		SELECT DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Physician E/M Provider: ' + CASE 
				WHEN cdh.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
					THEN 'Not Set'
				WHEN cdh.PROVIDER_EVAL_PERFORMED_BY_IND = 1
					THEN 'Mid-level'
				ELSE 'Attending'
				END
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN CHART_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND c.COMPLETION_DATE > @DemographicQaPhase2
			AND ISNULL(cdh.PROVIDER_EVAL_PERFORMED_BY_IND, '') <> ISNULL(c.PROVIDER_EVAL_PERFORMED_BY_IND, '')
						AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = cdh.CHART_ID
					AND qa.KEY_VALUE_2 = '31'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Consulting Physician: ' + ISNULL((ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		INNER JOIN [dbo].[CHART_CONSULTING_PHYSICIAN] ccp WITH (NOLOCK) ON c.CHART_ID = ccp.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = ccp.FACILITY_PROFESSIONAL_ID
		WHERE c.CHART_STATUS_ID IN (
				4,
				5
				)
			AND sa.AUDIT_ENABLED = 1
			AND ISNULL(sa.COLLECT_CONSULTING_PHYSICIANS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT, 1) = 1
			AND NOT EXISTS (
        select *
        from [dbo].[CHART_CONSULTING_PHYSICIAN_HISTORY] with (nolock)
        where CHART_ID = ccp.CHART_ID
          and FACILITY_PROFESSIONAL_ID = ccp.FACILITY_PROFESSIONAL_ID
      )
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = ccp.CHART_ID
					AND qa.KEY_VALUE_2 = '35'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
  SELECT DISTINCT 'C' AS 'Class',
			  'R' AS 'Action',
			  c.CHART_ID,
			  'Consulting Physician: ' + ISNULL((ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), '')), 'Not Set')
		  FROM 
			  [RevCycleTransactionSnapshot].[dbo].[ChartSubset2] as c
		  INNER JOIN [dbo].[CHART_CONSULTING_PHYSICIAN_HISTORY] ccph WITH (NOLOCK) ON c.CHART_ID = ccph.CHART_ID
		  INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = ccph.FACILITY_PROFESSIONAL_ID
		  WHERE c.CHART_STATUS_ID IN (
				  4,
				  5
				  )
			  AND sa.AUDIT_ENABLED = 1
			  AND ISNULL(sa.COLLECT_CONSULTING_PHYSICIANS, 'N') <> 'N'
			  AND ISNULL(sa.INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT, 1) = 1
			  AND NOT EXISTS (
          select *
          from [dbo].[CHART_CONSULTING_PHYSICIAN] with (nolock)
          where CHART_ID = ccph.CHART_ID
            and FACILITY_PROFESSIONAL_ID = ccph.FACILITY_PROFESSIONAL_ID
        )
			  AND (
				  SELECT COUNT(*)
				  FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				  WHERE qa.KEY_VALUE_1 = ccph.CHART_ID
					  AND qa.KEY_VALUE_2 = '35'
					  AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DEMOGRAPHIC_HISTORY'
				  ) = 0
			  AND c.APPROVED_DATE >= @ApprovedSince
			  AND sa.COMPANY_ID NOT IN (
				  1,
				  2
				  )
			  AND sa.DEMO_TEST_SITE_IND = 0
			  AND APPROVED_BY_USER_PROFILE_ID <> 2 -- Exclude charts that were system approved

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

-- Create an empty copy of CHART_AUDIT_RESULT
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartAuditResult_OLD', 'U') is not null DROP TABLE RevCycleTransactionSnapshot.dbo.ChartAuditResult_OLD		-- added 8/15/2016 by dsexton
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartAuditResult_New', 'U') is not null DROP TABLE RevCycleTransactionSnapshot.dbo.ChartAuditResult_New		-- added 8/15/2016 by dsexton
	SELECT * INTO RevCycleTransactionSnapshot.dbo.ChartAuditResult_New FROM RevCycleTransactionSnapshot.dbo.Chart_Audit_Result WHERE 1 = 0			-- added 8/15/2016 by dsexton
	
-- Populate an additional subset table (PreProcessX) by joining ChartSubset to Service_Agreement
	IF object_id('RevCycleTransactionSnapshot.dbo.PreProcessX', 'U') is not null
	BEGIN
		DROP TABLE [RevCycleTransactionSnapshot].[dbo].[PreProcessX];
	END;

	-- Some columns are initially populated below as NULL (or 0) for performance improvement.  They are subsequently updated with actual values.
	SELECT 
		c.FACILITY_ID,  
		CUID = cast(null as int),       
		ObsUID = cast(null as int),                  	
		c.Approval_Reason_Code,
		c.PATIENT_DISPOSITION_ID,
		sa.service_agreement_ID,
		sa.EVALUATE_FACILITY_SVC,
		sa.EVALUATE_FACILITY_PROCEDURES,
		sa.INFUSION_INJECTION_METHOD_ID,
		case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 
			(case when ISNULL(sa.CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE,0) = 0 then 1
				  when ISNULL(sa.CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.PHYSICIAN_SERVICES_START_DATE_OF_SERVICE, sa.EFFECTIVE_DATE) AND ISNULL(sa.PHYSICIAN_SERVICES_END_DATE_OF_SERVICE, '2099-12-31'))
						then 1 else 0 end) 
			else 0 end as EVALUATE_PHYSICIAN_SVC,
		--sa.EVALUATE_PHYSICIAN_SVC,
		case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 
			(case when ISNULL(sa.CONDITION_PHYSICIAN_PROCEDURES_ON_DATE_OF_SERVICE,0) = 0 then 1
				  when ISNULL(sa.CONDITION_PHYSICIAN_PROCEDURES_ON_DATE_OF_SERVICE,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.PHYSICIAN_SERVICES_START_DATE_OF_SERVICE, sa.EFFECTIVE_DATE) AND ISNULL(sa.PHYSICIAN_PROCEDURES_END_DATE_OF_SERVICE, '2099-12-31'))
						then 1 else 0 end) else 0 end as EVALUATE_PHYSICIAN_PROCEDURES,
		--sa.EVALUATE_PHYSICIAN_PROCEDURES,
		case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 
			(case when ISNULL(sa.CONDITION_DIAGNOSIS_CODING_ON_DATE_OF_SERVICE,0) = 0 then 1
				  when ISNULL(sa.CONDITION_DIAGNOSIS_CODING_ON_DATE_OF_SERVICE,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.DIAGNOSIS_CODING_START_DATE_OF_SERVICE, sa.EFFECTIVE_DATE) AND ISNULL(sa.DIAGNOSIS_CODING_END_DATE_OF_SERVICE, '2099-12-31'))
						then 1 else 0 end) else 0 end as PERFORM_DIAGNOSIS_CODING,
		--sa.PERFORM_DIAGNOSIS_CODING,
		case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 then 
			(case when ISNULL(sa.CONDITION_OBS_CHARGING_ON_DOS,0) = 0 then 1
				  when ISNULL(sa.CONDITION_OBS_CHARGING_ON_DOS,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.OBS_START_DOS, sa.EFFECTIVE_DATE) AND ISNULL(sa.OBS_END_DOS, '2099-12-31'))
						then 1 else 0 end) else 0 end as EVALUATE_OBSERVATION_DEPARTMENTS,
		--sa.EVALUATE_OBSERVATION_DEPARTMENTS,
		Class = cast(null as varchar(1)),                                                                                     
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
		FLOSE = 0,
		FPROCE = 0,
		FINJE = 0,
		--case when c.APPROVAL_REASON_CODE = 3 then
		--		(case when EVALUATE_PHYSICIAN_SVC = 1 then 1 else 0 end) else 0 end as PA,
		case when (c.APPROVAL_REASON_CODE = 3 and sa.EVALUATE_PHYSICIAN_SVC = 1) then
			(case when ISNULL(sa.CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE,0) = 0 then 1
				  when ISNULL(sa.CONDITION_PHYSICIAN_SERVICES_ON_DATE_OF_SERVICE,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.PHYSICIAN_SERVICES_START_DATE_OF_SERVICE, sa.EFFECTIVE_DATE) AND ISNULL(sa.PHYSICIAN_SERVICES_END_DATE_OF_SERVICE, '2099-12-31'))
						then 1 else 0 end) 
			else 0 end as PA,
		--case when c.APPROVAL_REASON_CODE = 3 then
		--			(case when EVALUATE_PHYSICIAN_PROCEDURES = 1 then 1 else 0 end) else 0 end as PPA,
		case when (c.APPROVAL_REASON_CODE = 3 and sa.EVALUATE_PHYSICIAN_PROCEDURES = 1) then
			(case when ISNULL(sa.CONDITION_PHYSICIAN_PROCEDURES_ON_DATE_OF_SERVICE,0) = 0 then 1
				  when ISNULL(sa.CONDITION_PHYSICIAN_PROCEDURES_ON_DATE_OF_SERVICE,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.PHYSICIAN_PROCEDURES_START_DATE_OF_SERVICE, sa.EFFECTIVE_DATE) AND ISNULL(sa.PHYSICIAN_PROCEDURES_END_DATE_OF_SERVICE, '2099-12-31'))
						then 1 else 0 end) 
			else 0 end as PPA,
		PLOSE = 0,
		PPROCE = 0,
		--case when c.APPROVAL_REASON_CODE = 3 then
		--			(case when PERFORM_DIAGNOSIS_CODING = 1 then 1 else 0 end) else 0 end as DA,
		case when (c.APPROVAL_REASON_CODE = 3 and sa.PERFORM_DIAGNOSIS_CODING = 1) then
			(case when ISNULL(sa.CONDITION_DIAGNOSIS_CODING_ON_DATE_OF_SERVICE,0) = 0 then 1
				  when ISNULL(sa.CONDITION_DIAGNOSIS_CODING_ON_DATE_OF_SERVICE,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.DIAGNOSIS_CODING_START_DATE_OF_SERVICE, sa.EFFECTIVE_DATE) AND ISNULL(sa.DIAGNOSIS_CODING_END_DATE_OF_SERVICE, '2099-12-31'))
						then 1 else 0 end) 
			else 0 end as DA,
		DE = 0,
                        
	-- 09/14/2011 - EricF - Obs Phase II additions -----------------------------------------------
		-- Observation hours
		--case when c.APPROVAL_REASON_CODE = 3 then
		--				(case when EVALUATE_OBSERVATION_DEPARTMENTS = 1 
		--					AND c.PATIENT_DISPOSITION_ID = 5 then 1 else 0 end) else 0 end as OHA, 
		case when (c.APPROVAL_REASON_CODE = 3 and sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 ) then
			(case when ISNULL(sa.CONDITION_OBS_CHARGING_ON_DOS,0) = 0 then 1
				  when ISNULL(sa.CONDITION_OBS_CHARGING_ON_DOS,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.OBS_START_DOS, sa.EFFECTIVE_DATE) AND ISNULL(sa.OBS_END_DOS, '2099-12-31'))
						then 1 else 0 end) 
			else 0 end as OHA,
		OHE = 0,
                  
		-- Observation Infusion/Injections
		--case when c.APPROVAL_REASON_CODE = 3 then
		--				(case when EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 
		--					AND sa.INFUSION_INJECTION_METHOD_ID <> -1 then 1 else 0 end) else 0 end as OIA, 
		case when (c.APPROVAL_REASON_CODE = 3 and sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1  AND c.PATIENT_DISPOSITION_ID = 5 AND sa.INFUSION_INJECTION_METHOD_ID <> -1) then
			(case when ISNULL(sa.CONDITION_OBS_CHARGING_ON_DOS,0) = 0 then 1
				  when ISNULL(sa.CONDITION_OBS_CHARGING_ON_DOS,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.OBS_START_DOS, sa.EFFECTIVE_DATE) AND ISNULL(sa.OBS_END_DOS, '2099-12-31'))
						then 1 else 0 end) 
			else 0 end as OIA,
		OIE = 0,
                  
		-- Observation Facility Procedures              
		--case when c.APPROVAL_REASON_CODE = 3 then
		--				(case when EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 
		--					AND sa.EVALUATE_FACILITY_PROCEDURES = 1 then 1 else 0 end) else 0 end as OPA, 
		case when (c.APPROVAL_REASON_CODE = 3 and sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 AND c.PATIENT_DISPOSITION_ID = 5 AND sa.EVALUATE_FACILITY_PROCEDURES = 1 ) then
			(case when ISNULL(sa.CONDITION_OBS_CHARGING_ON_DOS,0) = 0 then 1
				  when ISNULL(sa.CONDITION_OBS_CHARGING_ON_DOS,0) = 1 
								AND (c.TIME_OF_SERVICE BETWEEN ISNULL(sa.OBS_START_DOS, sa.EFFECTIVE_DATE) AND ISNULL(sa.OBS_END_DOS, '2099-12-31'))
						then 1 else 0 end) 
			else 0 end as OPA,
		OPE = 0,            
                  
		-- Observation cooments 
		c.DIAGNOSIS_CODING_AUDIT_COMMENT DIAG_COMMENT,
		c.OBSERVATION_AUDITOR_REVIEW_FEEDBACK,
		c.OBSERVATION_PROCEDURES_AUDIT_COMMENT OPROC_COMMENT, 
		c.OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT OINJ_COMMENT,
	-- End of Obs changes     ------------------------------------------------

	-- Chart Demographic Audit -----------------------------------------------
		case when c.APPROVAL_REASON_CODE = 3 then 
		(case
				when sa.COLLECT_MEDICAL_RECORD_NUMBER <> 'N'
					and ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1 then 1
				when COLLECT_ADMISSION_DATE <> 'N'
					and ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_ARRIVAL_MODE <> 'N'
					and ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_ARRIVAL_DATE <> 'N'
					and ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1 then 1
				when COLLECT_FACILITY_PATIENT_DISPOSITION <> 'N'
					and ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_PHYSICIAN <> 'N'
					and ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_DATE_TO_ROOM <> 'N'
					and ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_TRIAGE_ACUITY <> 'N'
					and ISNULL(sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_GENDER <> 'N'
					and ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE <> 'N'
					and ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1 then 1
				-- ACS-4171
				when sa.COLLECT_FINANCIAL_CLASS <> 'N'
					and ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_DATE_OF_BIRTH <> 'N'
					and ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_NURSE_PRACTITIONER <> 'N'
					and ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_DATE_OF_SERVICE <> 'N'
					and ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1 then 1
				when (sa.COLLECT_PATIENT_DISPOSITION <> 'N' OR sa.COLLECT_FACILITY_PATIENT_DISPOSITION <> 'N')
					and ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_FACILITY_ADMIN_CHART_ID <> 'N'
					and ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_DATE_OF_DIS <> 'N'
					and ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1 then 1
				when ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) = 1
					and ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_CLINIC <> 'N'
					and ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING <> 'N'
					and ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1 then 1
				when ISNULL(sa.COLLECT_SCRIBE, 0) = 1
					and ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_UC_LAST_ENCOUNTER_DATE <> 'N'
					and ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1 then 1
				when ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) = 1
					and ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1 then 1
				when ISNULL(sa.COLLECT_RESIDENT, 0) = 1
					and ISNULL(sa.INCLUDE_RESIDENT_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_PATIENT_AGE <> 'N'
					and ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_DATE_OF_PHYS_EVAL <> 'N'
					and ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_DATE_OF_TRIAGE <> 'N'
					and ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED <> 'N'
					and ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_ORGAN_DONATION <> 'N'
					and ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1 then 1
				when sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR <> 'N'
					and ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1 then 1
        when sa.COLLECT_CONSULTING_PHYSICIANS <> 'N'
			    and ISNULL(sa.INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT, 1) = 1 then 1
				else 0
				end
		)              
			else 0        
			end as DEMA,
		DEME = 0,
		c.DEMOGRAPHIC_AUDIT_COMMENT DEMO_COMMENT
		, c.START_SECOND_LEVEL_QA_USER_PROFILE_ID		-- this column will be used for subsequent SECOND_LEVEL processing
		, c.SECOND_LEVEL_QA_APPROVED_DATETIME			-- this column will be used for subsequent SECOND_LEVEL processing
		, Second_ANAME = cast(null as varchar(52))		-- this column will be used for subsequent SECOND_LEVEL processing
	-- End Chart Demographic Audit -------------------------------------------  
	 INTO [RevCycleTransactionSnapshot].[dbo].[PreProcessX]                         
	FROM  
		[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
		join service_agreement sa with (NOLOCK)
			on sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			and sa.AUDIT_ENABLED = 1
			and sa.COMPANY_ID not in (1, 2)


-- Update columns in PreProcessX which were initially inserted above with NULL (or 0) values (as part of performance improvements)

	UPDATE x
	set x.Class = caa.Class
	from
		[RevCycleTransactionSnapshot].[dbo].[PreProcessX] as x
		join [dbo].[CHART_AUDIT_ACTION] as caa on caa.chart_ID = x.chart_ID

	update x
	set x.CUID = ln.Completed_By_User_ID
	from
		[RevCycleTransactionSnapshot].[dbo].[PreProcessX] as x
			join
		(
			select chart_ID, MinLogNoteID = min(LOG_NOTE_ID) 
			from log_note with (NOLOCK) 
			where CATEGORY_ID = 2
			group by chart_ID
		) as t
				on x.chart_ID = t.chart_ID
			join
		log_note as ln with (nolock)
				on t.MinLogNoteID = ln.log_note_ID

	update x
	set x.obsUID = ln.Completed_By_User_ID
	from
		[RevCycleTransactionSnapshot].[dbo].[PreProcessX] as x
			join
		(
			select chart_ID, MinLogNoteID = min(LOG_NOTE_ID) 
			from log_note with (NOLOCK) 
			where CATEGORY_ID = 26
			group by chart_ID
		) as t
				on x.chart_ID = t.chart_ID
			join
		log_note as ln with (nolock)
				on t.MinLogNoteID = ln.log_note_ID


	-- wait until this point to create this index on PreProcessX
	CREATE NONCLUSTERED INDEX [ix_PreProcessX_ApprovalReasonCode_Class] 
		ON [RevCycleTransactionSnapshot].[dbo].[PreProcessX] ([Approval_Reason_Code],[Class])


	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set FLOSE = 1
	where APPROVAL_REASON_CODE = 3 
		and EVALUATE_FACILITY_SVC = 1
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS IN ('1', '7')
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set FPROCE = 1
	where APPROVAL_REASON_CODE = 3 
		and EVALUATE_FACILITY_PROCEDURES = 1
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS = '2'
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set FINJE = 1
	where APPROVAL_REASON_CODE = 3 
		and INFUSION_INJECTION_METHOD_ID <> -1 
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS = '3'
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set PLOSE = 1
	where APPROVAL_REASON_CODE = 3 
		and EVALUATE_PHYSICIAN_SVC = 1
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS = '8'
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set PPROCE = 1
	where APPROVAL_REASON_CODE = 3 
		and EVALUATE_PHYSICIAN_PROCEDURES = 1
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS = '5'
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set DE = 1
	where APPROVAL_REASON_CODE = 3 
		and PERFORM_DIAGNOSIS_CODING = 1
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS in ('6','D')
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set OHE = 1
	where APPROVAL_REASON_CODE = 3 
		and EVALUATE_OBSERVATION_DEPARTMENTS = 1 
		and PATIENT_DISPOSITION_ID = 5
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS = '9'
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set OIE = 1
	where APPROVAL_REASON_CODE = 3 
		and EVALUATE_OBSERVATION_DEPARTMENTS = 1 
		and PATIENT_DISPOSITION_ID = 5
		and INFUSION_INJECTION_METHOD_ID <> -1
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS = 'B'
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set OPE = 1
	where APPROVAL_REASON_CODE = 3 
		and EVALUATE_OBSERVATION_DEPARTMENTS= 1 
		and PATIENT_DISPOSITION_ID = 5
		and EVALUATE_FACILITY_PROCEDURES = 1
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS = 'A'
    )

	update [RevCycleTransactionSnapshot].[dbo].[PreProcessX]
	set DEME = 1
	where APPROVAL_REASON_CODE = 3
    and NOT EXISTS (
      SELECT *
      FROM CHART_AUDIT_ACTION WITH (NOLOCK)
      WHERE CHART_ID = [PreProcessX].CHART_ID
        AND CLASS = 'C'
    ) 			


-- now populate Chart_Audit_Result by joining to PreProcessX
	insert into RevCycleTransactionSnapshot.dbo.ChartAuditResult_New									-- modified 8/15/2016 by dsexton
		  (FACILITY_ID, FNAME, MANAGER_ID, CUID,  CNAME, AUID, ANAME, obsUID, obsName, 
			APPROVED_DATE, FACILITY_CHART_ID, CHART_ID, DOS, FLOS_COMMENT,
			FINJ_COMMENT, FPROC_COMMENT, PLOS_COMMENT, PPROC_COMMENT, DIAG_COMMENT, AUDITED, FA, FPA, FIA, FLOSE, 
			FINJE, FPROCE, PA, PPA, PLOSE, PPROCE, DA, DE, OBSERVATION_AUDITOR_REVIEW_FEEDBACK, OINJ_COMMENT,
			OPROC_COMMENT, OHA, OHE, OIA, OIE, OPA, OPE, DEMA, DEME, DEMO_COMMENT)
	select
		x.FACILITY_ID,
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
	from 
		facility f with (NOLOCK) 
		join [RevCycleTransactionSnapshot].[dbo].[PreProcessX] as x ON f.FACILITY_ID = x.Facility_ID
		join user_profile up with (NOLOCK) ON up.USER_PROFILE_ID = x.CUID
		join user_profile aup with (NOLOCK) ON aup.USER_PROFILE_ID = x.AUID
			LEFT OUTER JOIN 
		USER_PROFILE oup 
				on x.obsUID = oup.USER_PROFILE_ID


	-- Create PK	-- added 8/15/2016 by dsexton
	ALTER TABLE RevCycleTransactionSnapshot.dbo.ChartAuditResult_New 
		ADD PRIMARY KEY CLUSTERED (SEQ)


      -- Create Indexes  -- modified 8/15/2016 by dsexton
      CREATE NONCLUSTERED INDEX AI_CAR_APPROVEDT_CUID_FACILITY_CNAME ON RevCycleTransactionSnapshot.dbo.ChartAuditResult_New
      (APPROVED_DATE , CUID , FACILITY_ID , AUID , CNAME , SEQ)
	  WITH (FILLFACTOR = 100)
      
      CREATE NONCLUSTERED INDEX AI_CAR_APPROVEDT_CUID_MANAGER_FACILITY_CNAME ON RevCycleTransactionSnapshot.dbo.ChartAuditResult_New
      (APPROVED_DATE , CUID , MANAGER_ID , FACILITY_ID , AUID , CNAME , SEQ)
	  WITH (FILLFACTOR = 100)

      CREATE NONCLUSTERED INDEX AI_CAR_APPROVEDT_FACILITY_CUID_CNAME ON RevCycleTransactionSnapshot.dbo.ChartAuditResult_New
      (APPROVED_DATE , CUID , FACILITY_ID , AUID , CNAME , SEQ)
	  WITH (FILLFACTOR = 100)

      CREATE NONCLUSTERED INDEX ix_CAR_facID_ApprDT_INCL ON RevCycleTransactionSnapshot.dbo.ChartAuditResult_New 
      (facility_ID, approved_date) 
      INCLUDE 
      (FA, PA, DA, FPA, FIA, PPA, oha, oia, opa, DEMA, FLOSE, FPROCE, FINJE, PLOSE, PPROCE, DE, ohe, oie, ope, DEME)
	  WITH (FILLFACTOR = 100)
      

		CREATE NONCLUSTERED INDEX missing_index_14209 ON RevCycleTransactionSnapshot.dbo.ChartAuditResult_New
		(CUID)
		INCLUDE 
		(FACILITY_ID, CNAME, APPROVED_DATE, AUDITED, FA, FPA, FIA, FLOSE, FINJE, FPROCE, PA, PPA, PLOSE, PPROCE, DA, DE) 
		WITH (FILLFACTOR = 100)
		
		CREATE NONCLUSTERED INDEX missing_index_14221 ON RevCycleTransactionSnapshot.dbo.ChartAuditResult_New
		(CUID)
		INCLUDE 
		(FACILITY_ID, FNAME, CNAME, AUID, ANAME, APPROVED_DATE, FACILITY_CHART_ID, CHART_ID, FLOS_COMMENT, FINJ_COMMENT, FPROC_COMMENT,
			PLOS_COMMENT, PPROC_COMMENT, DIAG_COMMENT, FA, FPA, FIA, FLOSE, FINJE, FPROCE, PA, PPA, PLOSE, PPROCE, DA, DE, DEMA, DEME, DEMO_COMMENT) 
		WITH (FILLFACTOR = 100)

		CREATE NONCLUSTERED INDEX missing_index_18211 ON RevCycleTransactionSnapshot.dbo.ChartAuditResult_New
		(CUID)
		INCLUDE 
		(FACILITY_ID, FNAME, MANAGER_ID, APPROVED_DATE, AUDITED, FA, FPA, FIA, FLOSE, FINJE, FPROCE, PA, PPA, PLOSE, PPROCE, DA, DE, oha, ohe, opa, ope, oia, oie) 
		WITH (FILLFACTOR = 100)

		CREATE NONCLUSTERED INDEX missing_index_8713 ON RevCycleTransactionSnapshot.dbo.ChartAuditResult_New
		(CUID, APPROVED_DATE)
		INCLUDE 
		(CHART_ID, FA, FPA, FIA, PA, PPA, DA, oha, opa, oia, DEMA) 
		WITH (FILLFACTOR = 100)


	-- Create statistics	-- added 8/15/2016 by dsexton
CREATE STATISTICS Stat_AUID ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([AUID]) WITH FULLSCAN
CREATE STATISTICS Stat_CHART_ID ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([CHART_ID]) WITH FULLSCAN
CREATE STATISTICS Stat_FA ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([FA]) WITH FULLSCAN
CREATE STATISTICS Stat_FPA ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([FPA]) WITH FULLSCAN
CREATE STATISTICS Stat_FIA ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([FIA]) WITH FULLSCAN
CREATE STATISTICS Stat_FLOSE ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([FLOSE]) WITH FULLSCAN
CREATE STATISTICS Stat_FINJE ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([FINJE]) WITH FULLSCAN
CREATE STATISTICS Stat_FPROCE ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([FPROCE]) WITH FULLSCAN
CREATE STATISTICS Stat_PA ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([PA]) WITH FULLSCAN
CREATE STATISTICS Stat_PPA ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([PPA]) WITH FULLSCAN
CREATE STATISTICS Stat_PLOSE ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([PLOSE]) WITH FULLSCAN
CREATE STATISTICS Stat_PPROCE ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([PPROCE]) WITH FULLSCAN
CREATE STATISTICS Stat_DA ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([DA]) WITH FULLSCAN
CREATE STATISTICS Stat_DE ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([DE]) WITH FULLSCAN
CREATE STATISTICS Stat_DEMA ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([DEMA]) WITH FULLSCAN
CREATE STATISTICS Stat_DEME ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([DEME]) WITH FULLSCAN
CREATE STATISTICS Stat_FName ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([FName]) WITH FULLSCAN
CREATE STATISTICS Stat_CName ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([CName]) WITH FULLSCAN
CREATE STATISTICS Stat_obsUID ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([obsUID]) WITH FULLSCAN
CREATE STATISTICS Stat_obsName ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([obsName]) WITH FULLSCAN

CREATE STATISTICS Stat_Audited ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([Audited]) WITH FULLSCAN
CREATE STATISTICS Stat_oha ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([oha]) WITH FULLSCAN
CREATE STATISTICS Stat_opa ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([opa]) WITH FULLSCAN
CREATE STATISTICS Stat_oia ON RevCycleTransactionSnapshot.[dbo].[ChartAuditResult_New]([oia]) WITH FULLSCAN









GO
