SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[Refresh_Daily_Snapshot_CHART_SECOND_LEVEL_AUDIT]
WITH EXEC AS CALLER
AS

-- Drop Index and Truncate Table
-- CHART_SECOND_LEVEL_AUDIT_ACTION
      DROP INDEX [AI_CHART_SECOND_LEVEL_AUDIT_ACTION] ON [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION];

      TRUNCATE TABLE [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION];

IF object_id('RevCycleTransactionSnapshot.dbo.Chart2ndLevelSubset', 'U') is not null
BEGIN
	DROP TABLE [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset];
END;


Select 
	chart_ID, service_agreement_ID, Override_Facility_Level_ID, Facility_Level_ID, Completion_Date,
	Physician_Service_Proc_ID, Override_Physician_Service_Proc_ID, Physician_Critical_Care, time_of_service, NON_ER_PROCEDURES_OVERRIDE, FACILITY_LOS_27_MODIFIER, PHYSICIAN_SERVICE_MOD

	-- the columns below only need to be included if desired to leave the common CHART criteria in each query (minimizing the edits needed)
	, CHART_STATUS_ID, START_SECOND_LEVEL_QA_USER_PROFILE_ID, SENT_DATE, SECOND_LEVEL_QA_APPROVED_DATETIME
into [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset]
from 
	[RevCycleTransactionSnapshot].[dbo].[ChartSubset]
	--chart with (NOLOCK)
where 
	CHART_STATUS_ID in (4, 5)
	and START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
	and   ((case when SENT_DATE is null then '20080510'
                  else convert(varchar, SENT_DATE, 112) end) >= '20080510')
	and datediff(Day, SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

/*	-- when using CHART as source
Table 'CHART'. Scan count 17, logical reads 3257463, physical reads 35, read-ahead reads 26352, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
(26764 row(s) affected)
*/

/*	-- when using ChartSubset as source
Table 'ChartSubset'. Scan count 17, logical reads 201200, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
(26764 row(s) affected)
*/


-- Recreate Table Data
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
			select DISTINCT '1' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        (case when fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID > 0 then 
                                    (select fsi.description FROM FACILITY_SERVICE_SCHEDULE_ITEM fsi
                                    where fsi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)
                          else
                        (select fs.DESCRIPTION from facility_service fs with (NOLOCK)
                                    where fs.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID) end) 'Description'
      from  facility_service_second_audit_evaluation_history fseh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where fseh.CHART_ID not in (select fse.CHART_ID from facility_service_evaluation fse with (NOLOCK)
                        where fse.CHART_ID = fseh.CHART_ID
                        and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID)
               OR (fse.FACILITY_SERVICE_SCHEDULE_ID IS NOT NULL
                   AND fse.FACILITY_SERVICE_SCHEDULE_ID = fseh.FACILITY_SERVICE_SCHEDULE_ID
                   AND fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)))
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fseh.FACILITY_SVC_EVAL_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_SECOND_AUDIT_EVALUATION_HISTORY') = 0 
      and   c.CHART_ID = fseh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)	 
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select DISTINCT '1' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        (case when fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID > 0 then 
                                    (select fsi.description FROM FACILITY_SERVICE_SCHEDULE_ITEM fsi
                                    where fsi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID)
                          else
                        (select fs.DESCRIPTION from facility_service fs with (NOLOCK)
                                    where fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID) end) 'Description'
      from  facility_service_evaluation fse with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where fse.CHART_ID not in (select fseh.CHART_ID from facility_service_second_audit_evaluation_history fseh with (NOLOCK)
                        where fseh.CHART_ID = fse.CHART_ID
                        and   ((fse.FACILITY_SERVICE_ID IS NOT NULL AND fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID)
                OR (fse.FACILITY_SERVICE_SCHEDULE_ID IS NOT NULL
                    AND fse.FACILITY_SERVICE_SCHEDULE_ID = fseh.FACILITY_SERVICE_SCHEDULE_ID
                    AND fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID)))
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fse.FACILITY_SVC_EVAL_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION') = 0 
		and   c.CHART_ID = fse.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK),
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID               
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = fpe.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- Facility procedures modifiers
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + fpeh.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where 
	  fpeh.CHART_ID in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
	  and fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
						and   fpe.modifiers = fpeh.modifiers
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0  
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0     				                
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + fpe.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK),
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where 
	  fpe.CHART_ID  in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID                 
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
	  and fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                 		and   fpe.modifiers = fpeh.modifiers
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = fpe.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End facility procedures modifiers

-- Facility procedures quantity
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(fpeh.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0  
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0     				                
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(fpe.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK),
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where 
	  fpe.CHART_ID  in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID                 
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and   fpe.modifiers = fpeh.modifiers)
	  and fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and   fpe.modifiers = fpeh.modifiers
						and   fpe.QUANTITY = fpeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = fpe.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End facility procedures quantity

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 					
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK)
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
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- Additional Facility procedures modifiers

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + caph.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
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
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0        
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0     				          
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + cap.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 					
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID  in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
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
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End Additional Facility procedures modifiers

-- Additional Facility procedures quantity

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(caph.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   cap.MODIFIERS = caph.modifiers) 
	  and caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   cap.MODIFIERS = caph.modifiers
						and   cap.QUANTITY = caph.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0   
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0     				               
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(cap.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 					
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID  in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and     cap.MODIFIERS = caph.modifiers)
      and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and     cap.MODIFIERS = caph.modifiers
						and     cap.QUANTITY = caph.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End Additional Facility procedures quantity

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '3' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_second_audit_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
	  
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '3' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir, 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID not in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
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
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- Chart infusion results modifiers
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '3' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + cirh.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_second_audit_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
	  
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '3' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + cir.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir, 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
	  and cir.CHART_ID not in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.modifiers = cirh.modifiers
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End chart infusion result modifiers

-- Chart infusion results units
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '3' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Units: ' + Convert(varchar,COALESCE(cirh.UNITS,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_second_audit_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and   cir.modifiers = cirh.modifiers)
	  and cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and   cir.modifiers = cirh.modifiers
						and   cir.UNITS = cirh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
	  
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '3' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Units: ' + Convert(varchar,COALESCE(cir.UNITS,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir, 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and   cir.modifiers = cirh.modifiers)
	  and cir.CHART_ID not in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and   cir.modifiers = cirh.modifiers
						and   cir.UNITS = cirh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 0 
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End chart infusion result units

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '4' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        (select ps.DESCRIPTION from physician_service ps with (NOLOCK)
                                    where ps.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID) 'Description'
      from  physician_service_second_audit_eval_history pseh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where pseh.CHART_ID not in (select pse.CHART_ID from physician_service_eval pse with (NOLOCK)
                        where pse.CHART_ID = pseh.CHART_ID
                        and   pse.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = pseh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pseh.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_SECOND_AUDIT_EVAL_HISTORY') = 0                  
      and   c.CHART_ID = pseh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select DISTINCT '4' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        (select ps.DESCRIPTION from physician_service ps with (NOLOCK)
                                    where ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID) 'Description'
      from  physician_service_eval pse with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where pse.CHART_ID not in (select pseh.CHART_ID from physician_service_second_audit_eval_history pseh with (NOLOCK)
                        where pseh.CHART_ID = pse.CHART_ID
                        and   pseh.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = pse.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pse.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL') = 0                       
      and   c.CHART_ID = pse.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- Begin Multiple E&M Levels
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '4' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        (select Concat('(Level ', pseh.LEVEL_NUMBER, ') ')  +  ps.DESCRIPTION from physician_service ps with (NOLOCK)
                                    where ps.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID) 'Description'
      from  PHYSICIAN_SERVICE_SECOND_AUDIT_EVAL_ADDITIONAL_LEVEL_HISTORY pseh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where pseh.CHART_ID not in (select pse.CHART_ID from PHYSICIAN_SERVICE_EVAL_ADDITIONAL_LEVEL pse with (NOLOCK)
                        where pse.CHART_ID = pseh.CHART_ID
						and   pse.LEVEL_NUMBER = pseh.LEVEL_NUMBER
                        and   pse.PHYSICIAN_SERVICE_ID = pseh.PHYSICIAN_SERVICE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = pseh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pseh.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_SECOND_AUDIT_EVAL_HISTORY') = 0                  
      and   c.CHART_ID = pseh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select DISTINCT '4' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID,
                        (select Concat('(Level ', pse.LEVEL_NUMBER, ') ')  + ps.DESCRIPTION from physician_service ps with (NOLOCK)
                                    where ps.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID) 'Description'
      from  PHYSICIAN_SERVICE_EVAL_ADDITIONAL_LEVEL pse with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where pse.CHART_ID not in (select pseh.CHART_ID from PHYSICIAN_SERVICE_SECOND_AUDIT_EVAL_ADDITIONAL_LEVEL_HISTORY pseh with (NOLOCK)
                        where pseh.CHART_ID = pse.CHART_ID
						and   pseh.LEVEL_NUMBER = pse.LEVEL_NUMBER
                        and   pseh.PHYSICIAN_SERVICE_ID = pse.PHYSICIAN_SERVICE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = pse.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),pse.PHYSICIAN_SERVICE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_SERVICE_EVAL') = 0                       
      and   c.CHART_ID = pse.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End Multiple E&M Levels

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppeh.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_second_audit_evaluation_history ppeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where ppeh.CHART_ID not in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = ppeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppeh.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                     
      and   c.CHART_ID = ppeh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation ppe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where ppe.CHART_ID not in (select ppeh.CHART_ID from physician_procedure_second_audit_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = ppe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppe.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = ppe.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365


-- Physician procedure modifiers 
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + ppeh.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppeh.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_second_audit_evaluation_history ppeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where ppeh.CHART_ID in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and	ppeh.CHART_ID not in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = ppeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppeh.PHYSICIAN_PROCEDURE_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0              
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0  				         
      and   c.CHART_ID = ppeh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + ppe.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation ppe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where ppe.CHART_ID in (select ppeh.CHART_ID from physician_procedure_second_audit_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
	  and	ppe.CHART_ID not in (select ppeh.CHART_ID from physician_procedure_second_audit_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = ppe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppe.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = ppe.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End physician procedure modifiers

-- Physician procedure quantity
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(ppeh.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppeh.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_second_audit_evaluation_history ppeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where ppeh.CHART_ID in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS)
      and	ppeh.CHART_ID not in (select ppe.CHART_ID from physician_procedure_evaluation ppe with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS
						and   ppe.QUANTITY = ppeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = ppeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppeh.PHYSICIAN_PROCEDURE_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                     
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0  	
      and   c.CHART_ID = ppeh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(ppe.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from physician_procedure_evaluation ppe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where ppe.CHART_ID in (select ppeh.CHART_ID from physician_procedure_second_audit_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS)
	  and	ppe.CHART_ID not in (select ppeh.CHART_ID from physician_procedure_second_audit_evaluation_history ppeh with (NOLOCK)
                        where ppe.CHART_ID = ppeh.CHART_ID
                        and   ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
						and   ppe.MODIFIERS = ppeh.MODIFIERS
						and   ppe.QUANTITY = ppeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = ppe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),ppe.PHYSICIAN_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = ppe.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End physician procedure quantity

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c       
      where caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='PP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK)
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
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365


-- Additional physician procedures modifiers
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + caph.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c       
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='PP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
	  and	caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='PP'
						and   caph.MODIFIERS = cap.MODIFIERS
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0     
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0  					             
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + cap.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where cap.CHART_ADDITIONAL_PROCEDURE_ID in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from [CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK)
                        where caph.CLASS='PP'
                        and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
	  and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from [CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK)
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
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End Additional physician procedures modifiers

-- Additional physician procedures quantity
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(caph.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c       
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
                  --and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0  
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION') = 0  					                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='PP'
      and   c.CHART_STATUS_ID in (4, 5)
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '5' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Quantity: ' + Convert(varchar,COALESCE(cap.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		    [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where cap.CHART_ADDITIONAL_PROCEDURE_ID in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from [CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK)
                        where caph.CLASS='PP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   caph.MODIFIERS = cap.MODIFIERS)
	  and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from [CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK)
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
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End Additional physician procedures quantity


insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '6' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select ic.icd9_code + ', ' + ic.short_description from icd_9_cm ic with (NOLOCK)
                          where ic.icd9_code = cdch.ICD9_CODE
                              and   ic.effective_date <= c.time_of_service
                              and   ic.expiration_date >= c.time_of_service) 'Description'
      from chart_second_audit_diagnosis_code_history cdch with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where cdch.CHART_ID not in (select cdc.CHART_ID from chart_diagnosis_code cdc with (NOLOCK)
                        where cdc.CHART_ID = cdch.CHART_ID
                        and   cdc.ICD9_CODE = cdch.ICD9_CODE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cdch.CHART_ID and qa.KEY_VALUE_2 = cdch.ICD9_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DIAGNOSIS_CODE_HISTORY') = 0                  
      and   c.CHART_ID = cdch.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   c.TIME_OF_SERVICE < '2015-10-01'         
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '6' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select ic.icd9_code + ', ' + ic.short_description from icd_9_cm ic with (NOLOCK)
                          where ic.icd9_code = cdc.ICD9_CODE
                              and   ic.effective_date <= c.time_of_service
                              and   ic.expiration_date >= c.time_of_service) 'Description'
      from chart_diagnosis_code cdc with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where cdc.CHART_ID not in (select cdch.CHART_ID from chart_second_audit_diagnosis_code_history cdch with (NOLOCK)
                        where cdc.CHART_ID = cdch.CHART_ID
                        and   cdc.ICD9_CODE = cdch.ICD9_CODE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cdc.CHART_ID and qa.KEY_VALUE_2 = cdc.ICD9_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE') = 0                   
      and   c.CHART_ID = cdc.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   c.TIME_OF_SERVICE < '2015-10-01'         
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
select 'D' as 'Class',
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
      from chart_second_audit_diagnosis_code_history_ICD10 cdch with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where cdch.CHART_ID not in (select cdc.CHART_ID from chart_diagnosis_code_ICD10 cdc with (NOLOCK)
                        where cdc.CHART_ID = c.CHART_ID
                        and   cdc.ICD10_CODE = cdch.ICD10_CODE
						and   cdc.LEVEL_NUMBER = cdch.LEVEL_NUMBER)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cdch.CHART_ID and qa.KEY_VALUE_2 = cdch.ICD10_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = '-') = 0                  
      and   c.CHART_ID = cdch.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 'D' as 'Class',
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
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where cdc.CHART_ID not in (select cdch.CHART_ID from chart_second_audit_diagnosis_code_history_ICD10 cdch with (NOLOCK)
                        where c.CHART_ID = cdch.CHART_ID
                        and   cdc.ICD10_CODE = cdch.ICD10_CODE
						and   cdc.LEVEL_NUMBER = cdch.LEVEL_NUMBER)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = c.CHART_ID and qa.KEY_VALUE_2 = cdc.ICD10_CODE
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_DIAGNOSIS_CODE_ICD10') = 0                   
      and   c.CHART_ID = cdc.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
      and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '7' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        fl.DESCRIPTION Description
      from  chart_second_audit_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		facility_level fl with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5) 
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_LOS_HISTORY') = 0                      
      and   fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   fl.FACILITY_LEVEL_ID = (case when clh.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then clh.FACILITY_LEVEL_ID else clh.OVERRIDE_FACILITY_LEVEL_ID end)
      and   fl.CPT_CODE <> (isnull((select fl2.CPT_CODE from facility_level fl2 with (NOLOCK) 
                              where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then c.FACILITY_LEVEL_ID else c.OVERRIDE_FACILITY_LEVEL_ID end) = fl2.FACILITY_LEVEL_ID)), ''))
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '7' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         fl.DESCRIPTION Description
      from chart_second_audit_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		facility_level fl with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'FLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY') = 0                            
      and   fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   fl.FACILITY_LEVEL_ID = (case when c.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then c.FACILITY_LEVEL_ID else c.OVERRIDE_FACILITY_LEVEL_ID end)
      and   fl.CPT_CODE <> (isnull((select fl2.CPT_CODE from facility_level fl2 with (NOLOCK) 
                              where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when clh.OVERRIDE_FACILITY_LEVEL_ID = -1 
                                    then clh.FACILITY_LEVEL_ID else clh.OVERRIDE_FACILITY_LEVEL_ID end) = fl2.FACILITY_LEVEL_ID)), ''))
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

 -- Facility service modifier changes 
insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'7' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        'Fac Services Modifier 25 or 27 checkbox' Description
      from chart_second_audit_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
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
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select 
	  DISTINCT
		'7' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                        'Fac Services Modifier 25 or 27 checkbox' Description
      from chart_second_audit_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
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
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End Facility service modifier changes 

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        psp.DESCRIPTION Description
      from  chart_second_audit_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		physician_service_procedure psp with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'PLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_LOS_HISTORY') = 0                            
      and   psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   psp.PHYSICIAN_SERVICE_PROC_ID = (case when clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
                                    then clh.PHYSICIAN_SERVICE_PROC_ID else clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
      and   psp.CPT_CODE <> (select psp2.CPT_CODE from physician_service_procedure psp2 with (NOLOCK) 
                              where psp2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
                                    then c.PHYSICIAN_SERVICE_PROC_ID else c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end) = psp2.PHYSICIAN_SERVICE_PROC_ID))
      and   clh.PHYSICIAN_CRITICAL_CARE <> 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         psp.DESCRIPTION Description
      from chart_second_audit_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		physician_service_procedure psp with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'PLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_LOS_HISTORY') = 0                            
      and   psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   psp.PHYSICIAN_SERVICE_PROC_ID = (case when c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
                                    then c.PHYSICIAN_SERVICE_PROC_ID else c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
      and   psp.CPT_CODE <> (select psp2.CPT_CODE from physician_service_procedure psp2 with (NOLOCK)
                              where psp2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
                                    then clh.PHYSICIAN_SERVICE_PROC_ID else clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end) = psp2.PHYSICIAN_SERVICE_PROC_ID))
      and   c.PHYSICIAN_CRITICAL_CARE <> 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        'Critical Care' Description
      from  chart_second_audit_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   clh.PHYSICIAN_CRITICAL_CARE = 1
      and   c.PHYSICIAN_CRITICAL_CARE <> 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         'Critical Care' Description
      from chart_second_audit_los_history clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   c.PHYSICIAN_CRITICAL_CARE = 1
      and   clh.PHYSICIAN_CRITICAL_CARE <> 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365      
	
	  
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select 
	DISTINCT
		'8' as 'Class',
		'A' as 'Action',
		t.CHART_ID,
		'Phys Service Modifiers changed from: ' + 
			case when t.PHYSICIAN_SERVICE_MOD > '' then t.PHYSICIAN_SERVICE_MOD else 'None' end + ' to ' + 
			case when c.PHYSICIAN_SERVICE_MOD > '' then c.PHYSICIAN_SERVICE_MOD else 'None' end as Description
	from chart_second_audit_los_history as t, 
		 [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
	where c.chart_id = t.chart_id
	and	convert(varchar, c.COMPLETION_DATE, 112) >= '20170123'
	and (CASE WHEN c.PHYSICIAN_SERVICE_MOD IS NULL THEN '' ELSE c.PHYSICIAN_SERVICE_MOD END) <> (CASE WHEN t.PHYSICIAN_SERVICE_MOD IS NULL THEN '' ELSE t.PHYSICIAN_SERVICE_MOD END)   
  

-- Begin Additional E&M Level of Service changes
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
   select DISTINCT '8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        Concat('(Level ', clh.LEVEL_NUMBER, ') ')  + psp.DESCRIPTION Description
      from  CHART_SECOND_AUDIT_PHYSICIAN_ADDITIONAL_LOS_HISTORY clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHART_PHYSICIAN_ADDITIONAL_LOS_HISTORY c2 with (NOLOCK),
		Chart_Physician_Level_of_Service cc with (NOLOCK),
		physician_service_procedure psp with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   clh.CHART_ID = c2.CHART_ID
	  and   clh.LEVEL_NUMBER = c2.LEVEL_NUMBER
	  and   cc.CHART_ID = c.chart_id
	  and   cc.LEVEL_NUMBER = c2.LEVEL_NUMBER
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'PLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_LOS_HISTORY') = 0                            
      and   psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   psp.PHYSICIAN_SERVICE_PROC_ID = (case when clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
                                    then clh.PHYSICIAN_SERVICE_PROC_ID else clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
      and   psp.CPT_CODE <> (select psp2.CPT_CODE from physician_service_procedure psp2 with (NOLOCK) 
                              where psp2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when cc.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
                                    then cc.PHYSICIAN_SERVICE_PROC_ID else cc.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end) = psp2.PHYSICIAN_SERVICE_PROC_ID))
      and   clh.PHYSICIAN_CRITICAL_CARE <> 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                        Concat('(Level ', clh.LEVEL_NUMBER, ') ') + psp.DESCRIPTION Description
      from CHART_SECOND_AUDIT_PHYSICIAN_ADDITIONAL_LOS_HISTORY clh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		Chart_Physician_Level_of_Service cc with (NOLOCK),
		CHART_PHYSICIAN_ADDITIONAL_LOS_HISTORY c2 with (NOLOCK),
		physician_service_procedure psp with (NOLOCK)
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   clh.CHART_ID = c2.CHART_ID
	  and   clh.LEVEL_NUMBER = c2.LEVEL_NUMBER
	  and   cc.CHART_ID = c.chart_id
	  and   cc.LEVEL_NUMBER = c2.LEVEL_NUMBER
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = clh.CHART_ID and qa.KEY_VALUE_2 = 'PLOS'
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_LOS_HISTORY') = 0                            
      and   psp.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and   psp.PHYSICIAN_SERVICE_PROC_ID = (case when cc.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
                                    then cc.PHYSICIAN_SERVICE_PROC_ID else cc.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end)
      and   psp.CPT_CODE <> (select psp2.CPT_CODE from physician_service_procedure psp2 with (NOLOCK)
                              where psp2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                              and   ((case when clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1 
                                    then clh.PHYSICIAN_SERVICE_PROC_ID else clh.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID end) = psp2.PHYSICIAN_SERVICE_PROC_ID))
      and   c2.PHYSICIAN_CRITICAL_CARE <> 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '8' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID,
                        Concat('(Level ', clh.LEVEL_NUMBER, ') ')  + 'Critical Care' Description
      from  CHART_SECOND_AUDIT_PHYSICIAN_ADDITIONAL_LOS_HISTORY clh with (NOLOCK), 
			CHART_PHYSICIAN_ADDITIONAL_LOS_HISTORY c2 with (NOLOCK),
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   clh.CHART_ID = c2.CHART_ID
	  and   clh.LEVEL_NUMBER = c2.LEVEL_NUMBER
      and   clh.PHYSICIAN_CRITICAL_CARE = 1
      and   c2.PHYSICIAN_CRITICAL_CARE <> 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '8' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                        Concat('(Level ', clh.LEVEL_NUMBER, ') ') + 'Critical Care' Description
      from CHART_SECOND_AUDIT_PHYSICIAN_ADDITIONAL_LOS_HISTORY clh with (NOLOCK), 
		CHART_PHYSICIAN_ADDITIONAL_LOS_HISTORY c2 with (NOLOCK),
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where c.CHART_ID = clh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   clh.CHART_ID = c2.CHART_ID
	  and   clh.LEVEL_NUMBER = c2.LEVEL_NUMBER
      and   c2.PHYSICIAN_CRITICAL_CARE = 1
      and   clh.PHYSICIAN_CRITICAL_CARE <> 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365      
	
	  
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select 
	DISTINCT
		'8' as 'Class',
		'A' as 'Action',
		t.CHART_ID,
		Concat('(Level ', t.LEVEL_NUMBER, ') ') +  'Phys Service Modifiers changed from: ' + 
			case when t.PHYSICIAN_SERVICE_MOD > '' then t.PHYSICIAN_SERVICE_MOD else 'None' end + ' to ' + 
			case when c.PHYSICIAN_SERVICE_MOD > '' then c.PHYSICIAN_SERVICE_MOD else 'None' end as Description
	from CHART_SECOND_AUDIT_PHYSICIAN_ADDITIONAL_LOS_HISTORY as t, 
		CHART_PHYSICIAN_ADDITIONAL_LOS_HISTORY c2 with (NOLOCK),
		 [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
	where c.chart_id = t.chart_id
	  and   t.CHART_ID = c2.CHART_ID
	  and   t.LEVEL_NUMBER = c2.LEVEL_NUMBER
	and	convert(varchar, c.COMPLETION_DATE, 112) >= '20170123'
	and (CASE WHEN c.PHYSICIAN_SERVICE_MOD IS NULL THEN '' ELSE c.PHYSICIAN_SERVICE_MOD END) <> (CASE WHEN t.PHYSICIAN_SERVICE_MOD IS NULL THEN '' ELSE t.PHYSICIAN_SERVICE_MOD END)   
  

-- End Additional E&M Level of Service changes


-- Observation Phase II changes
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'A' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        --and   cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'
                        --and   (select COUNT(*) from CHARGE_MASTER cm2 where cm2.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm2.CPT_CODE <> 'SUPLY') = 0
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'A' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = fpe.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
	  
	  -- Facility procedures with modifiers
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'A' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + fpeh.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where fpeh.CHART_ID in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and	fpeh.CHART_ID not in (select fpe.CHART_ID from facility_procedure_evaluation fpe with (NOLOCK)
                        where fpe.CHART_ID = fpeh.CHART_ID
						and	  fpe.MODIFIERS = fpeh.MODIFIERS
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'A' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + fpe.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID                 
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
	  and	fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID   
						and	  fpe.MODIFIERS = fpeh.MODIFIERS              
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = fpe.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
		
	-- End Facility procedures with modifiers

	  -- Facility procedures quantity
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'A' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(fpeh.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpeh.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpeh.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = fpeh.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'A' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(fpe.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from facility_procedure_evaluation fpe with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where fpe.CHART_ID in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID                 
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and	  fpe.MODIFIERS = fpeh.MODIFIERS)
	  and	fpe.CHART_ID not in (select fpeh.CHART_ID from facility_procedure_second_audit_evaluation_history fpeh with (NOLOCK)        
                        where fpe.CHART_ID = fpeh.CHART_ID   
                        and   fpe.FACILITY_PROCEDURE_ID = fpeh.FACILITY_PROCEDURE_ID
						and	  fpe.MODIFIERS = fpeh.MODIFIERS
						and   fpe.QUANTITY = fpeh.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = fpe.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),fpe.FACILITY_PROCEDURE_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = fpe.CHART_ID
      and     cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
		
	-- End Facility procedures quantity

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                            and cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 					
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK)
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
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- Additional Facility procedures modifiers

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + caph.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
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
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Modifiers: ' + cap.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 					
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID  in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID)
      and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
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
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End Additional Facility procedures modifiers

-- Additional Facility procedures quantity

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(caph.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from [dbo].[CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY] caph with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)          
      where caph.CHART_ADDITIONAL_PROCEDURE_ID in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   cap.MODIFIERS = caph.modifiers) 
	  and caph.CHART_ADDITIONAL_PROCEDURE_ID not in (select cap.CHART_ADDITIONAL_PROCEDURE_ID from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK)
                        where caph.CLASS='FP'
                        and   cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and   cap.MODIFIERS = caph.modifiers
						and   cap.QUANTITY = caph.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
                  where qa.KEY_VALUE_1 = caph.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),caph.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_SECOND_AUDIT_EVALUATION_HISTORY') = 0                
      and   c.CHART_ID = caph.CHART_ID
      and   caph.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = caph.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY' 
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '2' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION  + ', Quantity: ' + Convert(varchar,COALESCE(cap.QUANTITY,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from CHART_ADDITIONAL_PROCEDURE cap with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c, 					
		CHARGE_MASTER cm with (NOLOCK), CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cap.CHART_ADDITIONAL_PROCEDURE_ID  in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and     cap.MODIFIERS = caph.modifiers)
      and	cap.CHART_ADDITIONAL_PROCEDURE_ID not in (select caph.CHART_ADDITIONAL_PROCEDURE_ID from CHART_SECOND_AUDIT_ADDITIONAL_PROCEDURE_HISTORY caph with (NOLOCK)
                        where	caph.CLASS='FP'
                        and		cap.CHART_ADDITIONAL_PROCEDURE_ID = caph.CHART_ADDITIONAL_PROCEDURE_ID
						and     cap.MODIFIERS = caph.modifiers
						and     cap.QUANTITY = caph.QUANTITY)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK) 
                  where qa.KEY_VALUE_1 = cap.CHART_ID and qa.KEY_VALUE_2 = CONVERT(varchar(15),cap.CHARGE_MASTER_ID)
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION') = 0                  
      and   c.CHART_ID = cap.CHART_ID
      and   cap.CLASS='FP'
      and   cm.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY'  
      and   c.CHART_STATUS_ID in (4, 5)
      and   cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
      and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

-- End Additional Facility procedures quantity

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select DISTINCT 'B' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_second_audit_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cirh.CHART_ID not in (select cir.CHART_ID from chart_infusion_result cir with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
        and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
	  
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'B' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir, 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID not in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
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
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365      
	  
	-- Chart infusion results with modifiers
	
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select DISTINCT 'B' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + cirh.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_second_audit_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
	  
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'B' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Modifiers: ' + cir.modifiers from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir, 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
	  and	cir.CHART_ID not in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
						and	  cir.MODIFIERS = cirh.MODIFIERS
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365    

	-- End Chart infusion results with modifiers

	-- Chart infusion results units
	
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select DISTINCT 'B' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Units: ' + Convert(varchar,COALESCE(cirh.UNITS,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_second_audit_infusion_result_history cirh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
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
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_INFUSION_RESULT_HISTORY') = 0                  
      and   c.CHART_ID = cirh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365
	  
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT 'B' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', Units: ' + Convert(varchar,COALESCE(cir.UNITS,0)) from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_infusion_result cir, 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c,
		CHARGE_MASTER_DEPARTMENT cmd with (NOLOCK)
      where cir.CHART_ID in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and	  cir.MODIFIERS = cirh.MODIFIERS)
	  and	cir.CHART_ID not in (select cirh.CHART_ID from chart_second_audit_infusion_result_history cirh with (NOLOCK)
                        where cir.CHART_ID = cirh.CHART_ID
                        and   cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
						and   cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
						and	  cir.MODIFIERS = cirh.MODIFIERS
						and   cir.UNITS = cirh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT') = 0                        
      and   c.CHART_ID = cir.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
      and   cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and   cmd.OBSERVATION_IND = 1 
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365    

	-- End Chart infusion results units

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION) 
      select DISTINCT '9' as 'Class',
                        'R' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', ' + CONVERT(VARCHAR, corh.UNITS) + ' Units' from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_second_audit_observation_encounter_result_history corh with (NOLOCK), 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where corh.CHART_ID not in (select cor.CHART_ID from chart_observation_encounter_result cor with (NOLOCK)
                        where cor.CHART_ID = corh.CHART_ID
                        and   cor.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID
						and   cor.DATE_OF_SERVICE = corh.DATE_OF_SERVICE
                        and   cor.UNITS = corh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = corh.CHART_OBSERVATION_ENCOUNTER_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_OBSERVATION_ENCOUNTER_RESULT_HISTORY') = 0                 
      and   c.CHART_ID = corh.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      select DISTINCT '9' as 'Class',
                        'A' as 'Action',
                        c.CHART_ID, 
                         (select cm.CPT_CODE + ', ' + cm.BILLING_CODE + ', ' + cm.DESCRIPTION + ', ' + CONVERT(VARCHAR, cor.UNITS) + ' Units' from charge_master cm with (NOLOCK)
                          where cm.CHARGE_MASTER_ID = cor.CHARGE_MASTER_ID and cm.CPT_CODE <> 'SUPLY') 'Description'
      from chart_observation_encounter_result cor, 
		[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset] as c
      where cor.CHART_ID not in (select corh.CHART_ID from chart_second_audit_observation_encounter_result_history corh with (NOLOCK)
                        where cor.CHART_ID = corh.CHART_ID
                        and   cor.CHARGE_MASTER_ID = corh.CHARGE_MASTER_ID
						and   cor.DATE_OF_SERVICE = corh.DATE_OF_SERVICE
                        and   cor.UNITS = corh.UNITS)
      and     (select COUNT(*) from CODER_QA_REPORT_EXCLUSION qa 
                  where qa.KEY_VALUE_1 = cor.CHART_OBSERVATION_ENCOUNTER_RESULT_ID
                  and     qa.SOURCE_RECORD_TABLE_NAME = 'CHART_OBSERVATION_ENCOUNTER_RESULT') = 0                     
      and   c.CHART_ID = cor.CHART_ID
      and   c.CHART_STATUS_ID in (4, 5)
	  and   c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 
      and   ((case when c.SENT_DATE is null then '20080510'
                  else convert(varchar, c.SENT_DATE, 112) end) >= '20080510')
	  and   datediff(Day, c.SECOND_LEVEL_QA_APPROVED_DATETIME, getdate()) <= 365


-- declare variables used in the queries below taken from udf_GetChartDemographicSecondAuditAction
declare @ApprovedSince DATETIME = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)-365
declare @DemographicQaPhase2 DATETIME = '1/30/2015'


-- Populate an additional subset table (Chart2ndLevelSubset2) to be referenced by queries below taken and modified from udf_GetChartDemographicSecondAuditAction.
IF object_id('RevCycleTransactionSnapshot.dbo.Chart2ndLevelSubset2', 'U') is not null
BEGIN
	DROP TABLE [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2];
END;

SELECT	
	c.CHART_ID, c.service_agreement_id, c.physician_id, c.Medical_Record_Num, c.Admission_Date_Time,
	c.Service_Agreement_Arrival_Mode_ID, c.Arrival_Date_Time, c.Patient_Disposition_Map_ID,
	c.Time_To_Room, c.Service_Agreement_Triage_Acuity_ID, c.Gender, c.Resident_Participated_In_Care,
	c.Completion_Date, c.Financial_Class_CD, c.Patient_DOB, c.Nurse_Practitioner_ID, c.Time_Of_Service,
	c.Patient_Disposition_ID, c.Facility_Admin_Chart_ID, c.Time_Of_DIS, c.Condition_Of_Accident_ID, c.Clinic_ID,
	c.Attestation_Signed_By_Attending, c.Scribe_ID, c.Last_Encounter_Date, c.Last_Menstrual_Period, c.Patient_Age,
	c.Time_Of_Phys_Eval, c.Time_Of_Triage, c.Medical_Examiner_Notified, c.Organ_Donation, 
	c.Seen_In_ED_Within_48_Hours_Of_OR, c.Provider_Eval_Performed_By_Ind, c.NON_ER_PROCEDURES_OVERRIDE, c.FACILITY_LOS_27_MODIFIER, c.PHYSICIAN_SERVICE_MOD

	-- columns below only need to be included if desired to leave the common CHART criteria in each query (minimizing the edits needed)
	, c.CHART_STATUS_ID, c.APPROVED_DATE, c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
  -- Added for Physician query in chart demographic section
  ,c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
 INTO [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2]
FROM 
	[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
	--CHART c WITH (NOLOCK)
WHERE c.CHART_STATUS_ID IN (4, 5)
	AND c.APPROVED_DATE >= @ApprovedSince
	AND c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0 -- Exclude charts that were system approved


insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'MRN: ' + ISNULL(c.MEDICAL_RECORD_NUM, 'Not Set') [Description]
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'MRN: ' + ISNULL(cdh.MEDICAL_RECORD_NUM, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Admission Date: ' + ISNULL(convert(VARCHAR, c.ADMISSION_DATE_TIME, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Admission Date: ' + ISNULL(convert(VARCHAR, cdh.ADMISSION_DATE_TIME, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Arrival Mode: ' + ISNULL(saam.DESCRIPTION, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Arrival Mode: ' + ISNULL(saam.DESCRIPTION, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Arrival Date: ' + ISNULL(convert(VARCHAR, cdh.ARRIVAL_DATE_TIME, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Arrival Date: ' + ISNULL(convert(VARCHAR, cdh.ARRIVAL_DATE_TIME, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Patient Disposition: ' + ISNULL(pdm.DESCRIPTION + '(' + pdm.FACILITY_PATIENT_DISPOSITION + ')', 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Patient Disposition: ' + ISNULL(pdm.DESCRIPTION + '(' + pdm.FACILITY_PATIENT_DISPOSITION + ')', 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Physician: ' + ISNULL((ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Physician: ' + ISNULL((ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Time to Room: ' + ISNULL(convert(VARCHAR, c.TIME_TO_ROOM, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Time to Room: ' + ISNULL(convert(VARCHAR, cdh.TIME_TO_ROOM, 110), 'Not Set')
		FROM
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c 
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Triage Accuity: ' + ISNULL(sata.DESCRIPTION, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Triage Accuity: ' + ISNULL(sata.DESCRIPTION, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Gender: ' + ISNULL(c.GENDER, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Gender: ' + ISNULL(cdh.GENDER, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Financial Class: ' + ISNULL(ffc.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Financial Class: ' + ISNULL(ffc.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'DOB: ' + ISNULL(CONVERT(VARCHAR, c.PATIENT_DOB, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'DOB: ' + ISNULL(CONVERT(VARCHAR, cdh.PATIENT_DOB, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'NP/PA: ' + ISNULL((ltrim(rtrim(np.LAST_NAME)) + ', ' + ltrim(rtrim(np.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(np.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
      		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'NP/PA: ' + ISNULL((ltrim(rtrim(np.LAST_NAME)) + ', ' + ltrim(rtrim(np.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(np.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'DOS: ' + ISNULL(CONVERT(VARCHAR, c.TIME_OF_SERVICE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
      	
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'DOS: ' + ISNULL(CONVERT(VARCHAR, cdh.TIME_OF_SERVICE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Patient Disposition: ' + ISNULL(pd.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
      		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Patient Disposition: ' + ISNULL(pd.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Facility Admin Chart ID: ' + ISNULL(c.FACILITY_ADMIN_CHART_ID, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Facility Admin Chart ID: ' + ISNULL(cdh.FACILITY_ADMIN_CHART_ID, 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Time of Discharge: ' + ISNULL(CONVERT(VARCHAR, c.TIME_OF_DIS, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Time of Discharge: ' + ISNULL(CONVERT(VARCHAR, cdh.TIME_OF_DIS, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Condition of Accident: ' + ISNULL(coa.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Condition of Accident: ' + ISNULL(coa.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Clinic: ' + ISNULL(cl.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Clinic: ' + ISNULL(cl.[DESCRIPTION], 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Scribe: ' + ISNULL((ltrim(rtrim(s.LAST_NAME)) + ', ' + ltrim(rtrim(s.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(s.MIDDLE_NAME)), '')), 'Not Set')
		FROM
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Scribe: ' + ISNULL((ltrim(rtrim(s.LAST_NAME)) + ', ' + ltrim(rtrim(s.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(s.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Last Encounter Date: ' + ISNULL(CONVERT(VARCHAR, c.LAST_ENCOUNTER_DATE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Last Encounter Date: ' + ISNULL(CONVERT(VARCHAR, cdh.LAST_ENCOUNTER_DATE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'LMP: ' + ISNULL(CONVERT(VARCHAR, c.LAST_MENSTRUAL_PERIOD, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'LMP: ' + ISNULL(CONVERT(VARCHAR, cdh.LAST_MENSTRUAL_PERIOD, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Patient Age: ' + ISNULL(CONVERT(VARCHAR, c.PATIENT_AGE), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Patient Age: ' + ISNULL(CONVERT(VARCHAR, cdh.PATIENT_AGE), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Physician Eval: ' + ISNULL(CONVERT(VARCHAR, c.TIME_OF_PHYS_EVAL, 110), 'Not Set')
		FROM
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Physician Eval: ' + ISNULL(CONVERT(VARCHAR, cdh.TIME_OF_PHYS_EVAL, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Time of Triage: ' + ISNULL(CONVERT(VARCHAR, c.TIME_OF_TRIAGE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
      		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
			'R' AS 'Action',
			c.CHART_ID,
			'Time of Triage: ' + ISNULL(CONVERT(VARCHAR, cdh.TIME_OF_TRIAGE, 110), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
      		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
      		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)		
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
      		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved
		
insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
		select DISTINCT 'C' AS 'Class',
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
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		INNER JOIN CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
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
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0-- Exclude charts that were system approved

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
      SELECT DISTINCT 'C' AS 'Class',
			'A' AS 'Action',
			c.CHART_ID,
			'Consulting Physician: ' + ISNULL((ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), '')), 'Not Set')
		FROM 
			[RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
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
        from [dbo].[CHART_SECOND_AUDIT_CONSULTING_PHYSICIAN_HISTORY] with (nolock)
        where CHART_ID = ccp.CHART_ID
          and FACILITY_PROFESSIONAL_ID = ccp.FACILITY_PROFESSIONAL_ID
      )
			AND (
				SELECT COUNT(*)
				FROM CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
				WHERE qa.KEY_VALUE_1 = ccp.CHART_ID
					AND qa.KEY_VALUE_2 = '35'
					AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				) = 0
			AND c.APPROVED_DATE >= @ApprovedSince
			AND sa.COMPANY_ID NOT IN (
				1,
				2
				)
			AND sa.DEMO_TEST_SITE_IND = 0
			AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0 -- Exclude charts that were system approved

insert into [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION] (CLASS, ACTION, CHART_ID, DESCRIPTION)
  SELECT DISTINCT 'C' AS 'Class',
			  'R' AS 'Action',
			  c.CHART_ID,
			  'Consulting Physician: ' + ISNULL((ltrim(rtrim(fp.LAST_NAME)) + ', ' + ltrim(rtrim(fp.FIRST_NAME)) + ' ' + ISNULL(ltrim(rtrim(fp.MIDDLE_NAME)), '')), 'Not Set')
		  FROM 
			  [RevCycleTransactionSnapshot].[dbo].[Chart2ndLevelSubset2] as c
		  INNER JOIN [dbo].[CHART_SECOND_AUDIT_CONSULTING_PHYSICIAN_HISTORY] ccph WITH (NOLOCK) ON c.CHART_ID = ccph.CHART_ID
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
					  AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_SECOND_AUDIT_DEMOGRAPHIC_HISTORY'
				  ) = 0
			  AND c.APPROVED_DATE >= @ApprovedSince
			  AND sa.COMPANY_ID NOT IN (
				  1,
				  2
				  )
			  AND sa.DEMO_TEST_SITE_IND = 0
			  AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 0 -- Exclude charts that were system approved

      -- Recreate Index
      CREATE NONCLUSTERED INDEX [AI_CHART_SECOND_LEVEL_AUDIT_ACTION] ON [dbo].[CHART_SECOND_LEVEL_AUDIT_ACTION]
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
      


      
 -- CHART_SECOND_LEVEL_AUDIT_RESULTS

-- Create an empty copy of CHART_SECOND_LEVEL_AUDIT_RESULTS to refresh			-- added 8/16/2016 by dsexton
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartSecondLevelAuditResult_OLD', 'U') is not null DROP TABLE RevCycleTransactionSnapshot.dbo.ChartSecondLevelAuditResult_OLD;
	IF object_id('RevCycleTransactionSnapshot.dbo.ChartSecondLevelAuditResult_New', 'U') is not null DROP TABLE RevCycleTransactionSnapshot.dbo.ChartSecondLevelAuditResult_New;
	SELECT * INTO RevCycleTransactionSnapshot.dbo.ChartSecondLevelAuditResult_New FROM RevCycleTransactionSnapshot.dbo.Chart_Second_Level_Audit_Result WHERE 1 = 0

-- Populate an additional subset table (PreProcess2ndLevelX), sourced from PreProcessX
	IF object_id('RevCycleTransactionSnapshot.dbo.PreProcess2ndLevelX', 'U') is not null
	BEGIN
		DROP TABLE [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX];
	END;

	SELECT px.*, AUDITOR_FLOSE = 0, AUDITOR_FPROCE = 0, AUDITOR_FINJE=0, AUDITOR_PLOSE=0, AUDITOR_PPROCE=0, AUDITOR_DE=0,
			AUDITOR_OHE=0, AUDITOR_OIE=0, AUDITOR_OPE=0, AUDITOR_DEME=0
	 INTO [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
	FROM [RevCycleTransactionSnapshot].[dbo].[PreProcessX] px
	WHERE START_SECOND_LEVEL_QA_USER_PROFILE_ID is not null


	  -- Update Auditor Earned values based on CHART_SECOND_AUDIT_ACTION
		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_FLOSE = 1
		where APPROVAL_REASON_CODE = 3 
			and EVALUATE_FACILITY_SVC = 1
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS IN ('1', '7')
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_FPROCE = 1
		where APPROVAL_REASON_CODE = 3 
			and EVALUATE_FACILITY_PROCEDURES = 1
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS = '2'
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_FINJE = 1
		where APPROVAL_REASON_CODE = 3 
			and INFUSION_INJECTION_METHOD_ID <> -1 
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS = '3'
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_PLOSE = 1
		where APPROVAL_REASON_CODE = 3 
			and EVALUATE_PHYSICIAN_SVC = 1
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS = '8'
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_PPROCE = 1
		where APPROVAL_REASON_CODE = 3 
			and EVALUATE_PHYSICIAN_PROCEDURES = 1
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS = '5'
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_DE = 1
		where APPROVAL_REASON_CODE = 3 
			and PERFORM_DIAGNOSIS_CODING = 1
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS In ('6','D')
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_OHE = 1
		where APPROVAL_REASON_CODE = 3 
			and EVALUATE_OBSERVATION_DEPARTMENTS = 1 
			and PATIENT_DISPOSITION_ID = 5
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS = '9'
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_OIE = 1
		where APPROVAL_REASON_CODE = 3 
			and EVALUATE_OBSERVATION_DEPARTMENTS = 1 
			and PATIENT_DISPOSITION_ID = 5
			and INFUSION_INJECTION_METHOD_ID <> -1
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS = 'B'
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_OPE = 1
		where APPROVAL_REASON_CODE = 3 
			and EVALUATE_OBSERVATION_DEPARTMENTS = 1 
			and PATIENT_DISPOSITION_ID = 5
			and EVALUATE_FACILITY_PROCEDURES = 1
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS = 'A'
		)

		update [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX]
		set AUDITOR_DEME = 1
		where APPROVAL_REASON_CODE = 3
		and NOT EXISTS (
		  SELECT *
		  FROM CHART_SECOND_LEVEL_AUDIT_ACTION WITH (NOLOCK)
		  WHERE CHART_ID = [PreProcess2ndLevelX].CHART_ID
			AND CLASS = 'C'
		) 			


-- update "Comment" columns with values from CHART_SECOND_LEVEL_AUDIT_COMMENTS
UPDATE x
SET 
	x.FLOS_COMMENT = csc.SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT,
	x.FINJ_COMMENT = csc.SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT,
	x.FPROC_COMMENT = csc.SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT,
	x.PLOS_COMMENT = csc.SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT,
	x.PPROC_COMMENT = csc.SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT,
	x.DIAG_COMMENT = csc.SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT,
	x.OBSERVATION_AUDITOR_REVIEW_FEEDBACK = csc.SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK,
	x.OPROC_COMMENT = '',
	x.OINJ_COMMENT = csc.SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT,
	x.DEMO_COMMENT = csc.SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT
FROM	
	[RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX] as x
	left join CHART_SECOND_LEVEL_AUDIT_COMMENTS as csc on x.chart_ID = csc.chart_ID

-- Recreate Table Data
	-- populate Chart_Second_Level_Audit_Result by joining to PreProcess2ndLevelX
	insert into RevCycleTransactionSnapshot.dbo.ChartSecondLevelAuditResult_New										-- modified 8/16/2016 by dsexton
		  (FACILITY_ID, FNAME, MANAGER_ID, CUID,  CNAME, AUID, ANAME, SECOND_AUID, SECOND_ANAME, obsUID, obsName, 
			APPROVED_DATE, SECOND_APPROVED_DATE, FACILITY_CHART_ID, CHART_ID, DOS, FLOS_COMMENT,
			FINJ_COMMENT, FPROC_COMMENT, PLOS_COMMENT, PPROC_COMMENT, DIAG_COMMENT, AUDITED, FA, FPA, FIA, FLOSE, 
			FINJE, FPROCE, PA, PPA, PLOSE, PPROCE, DA, DE, OBSERVATION_AUDITOR_REVIEW_FEEDBACK, OINJ_COMMENT,
			OPROC_COMMENT, OHA, OHE, OIA, OIE, OPA, OPE, DEMA, DEME, DEMO_COMMENT,
			AUDITOR_FLOSE, AUDITOR_FINJE, AUDITOR_FPROCE, AUDITOR_PLOSE, AUDITOR_PPROCE, AUDITOR_DE, AUDITOR_OHE,
			AUDITOR_OPE, AUDITOR_OIE, AUDITOR_DEME)
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
    x.START_SECOND_LEVEL_QA_USER_PROFILE_ID Second_AUID,
    aup2.LAST_NAME + ', ' + aup2.FIRST_NAME Second_ANAME,   
		x.ObsUID, 
		oup.LAST_NAME + ', ' + oup.FIRST_NAME obsNAME,
		x.APPROVED_DATE,
	x.SECOND_LEVEL_QA_APPROVED_DATETIME Second_Approved_Date,
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
		x.DEMO_COMMENT,
		x.AUDITOR_FLOSE, 
		x.AUDITOR_FINJE, 
		x.AUDITOR_FPROCE, 
		x.AUDITOR_PLOSE, 
		x.AUDITOR_PPROCE, 
		x.AUDITOR_DE, 
		x.AUDITOR_OHE,
		x.AUDITOR_OPE, 
		x.AUDITOR_OIE, 
		x.AUDITOR_DEME		                         
	from 
		facility f with (NOLOCK) 
		join [RevCycleTransactionSnapshot].[dbo].[PreProcess2ndLevelX] as x ON f.FACILITY_ID = x.Facility_ID
		join user_profile up with (NOLOCK) ON up.USER_PROFILE_ID = x.CUID
		join user_profile aup with (NOLOCK) ON aup.USER_PROFILE_ID = x.AUID
		join user_profile aup2 with (NOLOCK) on aup2.User_Profile_ID = x.START_SECOND_LEVEL_QA_USER_PROFILE_ID
			LEFT OUTER JOIN 
		USER_PROFILE oup 
				on x.obsUID = oup.USER_PROFILE_ID


	-- Create PK		-- added 8/16/2016 by dsexton
	ALTER TABLE RevCycleTransactionSnapshot.dbo.ChartSecondLevelAuditResult_New 
		ADD PRIMARY KEY CLUSTERED (SEQ)


      -- Create Indexes			-- modified 8/16/2016 by dsexton 
      CREATE NONCLUSTERED INDEX [AI_SECOND_LEVEL_CAR_APPROVEDT_CUID_FACILITY_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[ChartSecondLevelAuditResult_New]
      ([APPROVED_DATE] , [CUID] , [FACILITY_ID] , [AUID] , [CNAME] , [SEQ])
      WITH (FILLFACTOR = 100)

      CREATE NONCLUSTERED INDEX [AI_SECOND_LEVEL_CAR_APPROVEDT_CUID_MANAGER_FACILITY_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[ChartSecondLevelAuditResult_New]
      ([APPROVED_DATE] , [CUID] , [MANAGER_ID] , [FACILITY_ID] , [AUID] , [CNAME] , [SEQ])
      WITH (FILLFACTOR = 100)

      CREATE NONCLUSTERED INDEX [AI_SECOND_LEVEL_CAR_APPROVEDT_FACILITY_CUID_CNAME] ON [RevCycleTransactionSnapshot].[dbo].[ChartSecondLevelAuditResult_New]
      ([APPROVED_DATE] , [CUID] , [FACILITY_ID] , [AUID] , [CNAME] , [SEQ])
      WITH (FILLFACTOR = 100)

      CREATE NONCLUSTERED INDEX [AI_SECOND_LEVEL_CAR_APPROVEDT_AUID_FACILITY_CUID] ON [RevCycleTransactionSnapshot].[dbo].[ChartSecondLevelAuditResult_New]
      ([APPROVED_DATE] , [AUID] , [ANAME], [FACILITY_ID] , [CUID] , [CNAME] , [SEQ])
      WITH (FILLFACTOR = 100)


	-- Create Statistics			-- added 8/16/2016 by dsexton
CREATE STATISTICS Stat_AUID ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AUID]) WITH FULLSCAN
CREATE STATISTICS Stat_SecondApprovedDate ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([SECOND_APPROVED_DATE]) WITH FULLSCAN
CREATE STATISTICS Stat_ChartID ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([CHART_ID]) WITH FULLSCAN
CREATE STATISTICS Stat_FA ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([FA]) WITH FULLSCAN
CREATE STATISTICS Stat_FPA ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([FPA]) WITH FULLSCAN
CREATE STATISTICS Stat_FIA ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([FIA]) WITH FULLSCAN
CREATE STATISTICS Stat_PA ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([PA]) WITH FULLSCAN
CREATE STATISTICS Stat_PPA ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([PPA]) WITH FULLSCAN
CREATE STATISTICS Stat_DA ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([DA]) WITH FULLSCAN
CREATE STATISTICS Stat_DEMA ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([DEMA]) WITH FULLSCAN
CREATE STATISTICS Stat_AuditorFLOSE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AUDITOR_FLOSE]) WITH FULLSCAN
CREATE STATISTICS Stat_AuditorFINJE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AUDITOR_FINJE]) WITH FULLSCAN
CREATE STATISTICS Stat_AuditorFPROCE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AUDITOR_FPROCE]) WITH FULLSCAN
CREATE STATISTICS Stat_AuditorPLOSE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AUDITOR_PLOSE]) WITH FULLSCAN
CREATE STATISTICS Stat_AuditorPPROCE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AUDITOR_PPROCE]) WITH FULLSCAN
CREATE STATISTICS Stat_AuditorDE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AUDITOR_DE]) WITH FULLSCAN
CREATE STATISTICS Stat_AuditorDEME ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AUDITOR_DEME]) WITH FULLSCAN

CREATE STATISTICS Stat_Facility_ID ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([Facility_ID]) WITH FULLSCAN
CREATE STATISTICS Stat_FName ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([FName]) WITH FULLSCAN
CREATE STATISTICS Stat_CUID ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([CUID]) WITH FULLSCAN
CREATE STATISTICS Stat_AName ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([AName]) WITH FULLSCAN
CREATE STATISTICS Stat_oha ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([oha]) WITH FULLSCAN
CREATE STATISTICS Stat_opa ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([opa]) WITH FULLSCAN
CREATE STATISTICS Stat_oia ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([oia]) WITH FULLSCAN
CREATE STATISTICS Stat_obsUID ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([obsUID]) WITH FULLSCAN
CREATE STATISTICS Stat_Auditor_OHE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([Auditor_OHE]) WITH FULLSCAN
CREATE STATISTICS Stat_Auditor_OPE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([Auditor_OPE]) WITH FULLSCAN
CREATE STATISTICS Stat_Auditor_OIE ON RevCycleTransactionSnapshot.[dbo].[ChartSecondLevelAuditResult_New]([Auditor_OIE]) WITH FULLSCAN



GO
