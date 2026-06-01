SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 6/6/2016
-- Description:	Populate the ChartAuditActionDetail the Coder Trending Error Report
-- =============================================
CREATE PROCEDURE [dbo].[Refresh_Daily_Snapshot_ChartAuditActionDetail]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  -- drop and recreate the ChartAuditActionDetail table
  if object_id('RevCycleTransactionSnapshot.dbo.ChartAuditActionDetail', 'U') is not null
  begin
	  drop table [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail];
  end;

  create table [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail](
	  [CLASS] [varchar](1) NOT NULL,
	  [ACTION] [varchar](1) NOT NULL,
	  [CHART_ID] [int] NOT NULL,
	  [DESCRIPTION] [varchar](500) NULL,
	  [SERVICE_AGREEMENT_ID] [int] NULL,
	  [CPT_CODE] [varchar](15) NULL,
	  [FACILITY_ID] [int] NULL,
	  [SENT_DATE] [datetime] NULL,
    [TIME_OF_SERVICE] [datetime] NULL,
    [COMPLETED_BY_USER_PROFILE_ID] [int] null,
    [APPROVED_BY_USER_PROFILE_ID] [int] null
  ) on [PRIMARY];
 
  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '1' as 'Class'
      ,'R' as 'Action'
      ,c.CHART_ID
      ,(
          case 
              when fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID > 0
                  then (
                          select fsi.description
                          from FACILITY_SERVICE_SCHEDULE_ITEM fsi with (nolock)
                          where fsi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID
                          )
              else (
                      select fs.DESCRIPTION
                      from facility_service fs with (nolock)
                      where fs.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID
                      )
              end
          ) 'Description'
          ,c.SERVICE_AGREEMENT_ID
          ,null CPT_CODE
          ,c.FACILITY_ID
          ,c.SENT_DATE
          ,c.[TIME_OF_SERVICE]
          ,c.[APPROVED_BY_USER_PROFILE_ID]
  from facility_service_evaluation_history fseh with (nolock)
      join FACILITY_SERVICE fs with (nolock) on fs.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
  where fseh.CHART_ID not in (
          select fse.CHART_ID
          from facility_service_evaluation fse with (nolock)
          where fse.CHART_ID = fseh.CHART_ID
              and (
                  (
                      fse.FACILITY_SERVICE_ID is not null
                      and fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID
                      )
                  or (
                      fse.FACILITY_SERVICE_SCHEDULE_ID is not null
                      and fse.FACILITY_SERVICE_SCHEDULE_ID = fseh.FACILITY_SERVICE_SCHEDULE_ID
                      and fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID
                      )
                  )
          )
      and (
          select COUNT(*)
          from CODER_QA_REPORT_EXCLUSION qa with (nolock)
          where qa.KEY_VALUE_1 = fseh.FACILITY_SVC_EVAL_ID
              and qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION_HISTORY'
          ) = 0
      and c.CHART_ID = fseh.CHART_ID;

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '1' as 'Class'
      ,'A' as 'Action'
      ,c.CHART_ID
      ,(
          case 
              when fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID > 0
                  then (
                          select fsi.description
                          from FACILITY_SERVICE_SCHEDULE_ITEM fsi with (nolock)
                          where fsi.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID
                          )
              else (
                      select fs.DESCRIPTION
                      from facility_service fs with (nolock)
                      where fs.FACILITY_SERVICE_ID = fse.FACILITY_SERVICE_ID
                      )
              end
          ) 'Description'
          ,c.SERVICE_AGREEMENT_ID
          ,null CPT_CODE
          ,c.FACILITY_ID
          ,c.SENT_DATE
          ,c.[TIME_OF_SERVICE]
          ,c.[APPROVED_BY_USER_PROFILE_ID]
  from facility_service_evaluation fse with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
  where fse.CHART_ID not in (
          select fseh.CHART_ID
          from facility_service_evaluation_history fseh with (nolock)
          where fseh.CHART_ID = fse.CHART_ID
              and (
                  (
                      fse.FACILITY_SERVICE_ID is not null
                      and fse.FACILITY_SERVICE_ID = fseh.FACILITY_SERVICE_ID
                      )
                  or (
                      fse.FACILITY_SERVICE_SCHEDULE_ID is not null
                      and fse.FACILITY_SERVICE_SCHEDULE_ID = fseh.FACILITY_SERVICE_SCHEDULE_ID
                      and fse.FACILITY_SERVICE_SCHEDULE_ITEM_ID = fseh.FACILITY_SERVICE_SCHEDULE_ITEM_ID
                      )
                  )
          )
      and (
          select COUNT(*)
          from CODER_QA_REPORT_EXCLUSION qa with (nolock)
          where qa.KEY_VALUE_1 = fse.FACILITY_SVC_EVAL_ID
              and qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_SERVICE_EVALUATION'
          ) = 0
      and c.CHART_ID = fse.CHART_ID;

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '2' as 'Class'
      ,'R' as 'Action'
      ,c.CHART_ID
      ,(
          select cm.DESCRIPTION
          from charge_master cm with (nolock)
          where cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID
              and cm.CPT_CODE <> 'SUPLY'
          ) 'Description'
      ,c.SERVICE_AGREEMENT_ID
      ,cm.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from [dbo].[FACILITY_PROCEDURE_EVALUATION_HISTORY] fpeh with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      ,[dbo].[CHARGE_MASTER] cm with (nolock)
      ,[dbo].[CHARGE_MASTER_DEPARTMENT] cmd with (nolock)
  where fpeh.CHART_ID not in (
          select fpe.CHART_ID
          from [dbo].[SENT_PROCEDURE] fpe with (nolock)
          where fpe.CHART_ID = fpeh.CHART_ID
              and class = 'FP'
              and fpe.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID
          )
      and (
          select COUNT(*)
          from [dbo].[CODER_QA_REPORT_EXCLUSION] qa with (nolock)
          where qa.KEY_VALUE_1 = fpeh.CHART_ID
              and qa.KEY_VALUE_2 = CONVERT(varchar(15), fpeh.FACILITY_PROCEDURE_ID)
              and qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION_HISTORY'
          ) = 0
      and c.CHART_ID = fpeh.CHART_ID
      and cm.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID
      and cm.CPT_CODE <> 'SUPLY'
      and c.CHART_STATUS_ID = 5
      and cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and cmd.OBSERVATION_IND = 0;

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '2' as 'Class'
      ,'A' as 'Action'
      ,c.CHART_ID
      ,(
          select top 1 SHORT_DESCRIPTION
          from [dbo].[CMS_HCPC_CODE] cms with (nolock)
          inner join [dbo].[CHARGE_MASTER] cm with (nolock) on cm.CPT_CODE = cms.[HCPC_CODE_ID]
          where cm.CHARGE_MASTER_ID = fpe.CHARGE_MASTER_ID
              and cm.CPT_CODE <> 'SUPLY'
          order by [HCPC_CODE_VERSION] desc
          ) 'Description'
      ,c.SERVICE_AGREEMENT_ID
      ,fpe.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from [dbo].[SENT_PROCEDURE] fpe with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      ,[dbo].[CHARGE_MASTER] cm with (nolock)
      ,[dbo].[CHARGE_MASTER_DEPARTMENT] cmd with (nolock)
  where class = 'FP'
      and fpe.CHART_ID not in (
          select fpeh.CHART_ID
          from facility_procedure_evaluation_history fpeh with (nolock)
          where fpe.CHART_ID = fpeh.CHART_ID
              and fpe.CHARGE_MASTER_ID = fpeh.FACILITY_PROCEDURE_ID
          )
      and (
          select COUNT(*)
          from [dbo].[CODER_QA_REPORT_EXCLUSION] qa with (nolock)
          where qa.KEY_VALUE_1 = fpe.CHART_ID
              and qa.KEY_VALUE_2 = CONVERT(varchar(15), fpe.CHARGE_MASTER_ID)
              and qa.SOURCE_RECORD_TABLE_NAME = 'FACILITY_PROCEDURE_EVALUATION'
          ) = 0
      and c.CHART_ID = fpe.CHART_ID
      and cm.CHARGE_MASTER_ID = fpe.CHARGE_MASTER_ID
      and cm.CPT_CODE <> 'SUPLY'
      and c.CHART_STATUS_ID = 5
      and cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and cmd.OBSERVATION_IND = 0;

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '3' as 'Class'
      ,'R' as 'Action'
      ,c.CHART_ID
      ,(
          select top 1 SHORT_DESCRIPTION
          from [dbo].[CMS_HCPC_CODE] cms with (nolock)
          where [HCPC_CODE_ID] = cm.CPT_CODE
          order by [HCPC_CODE_VERSION] desc
          ) 'Description'
      ,c.SERVICE_AGREEMENT_ID
      ,cm.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from chart_infusion_result_history cirh with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      ,[dbo].[CHARGE_MASTER] cm with (nolock)
      ,[dbo].[CHARGE_MASTER_DEPARTMENT] cmd with (nolock)
  where cm.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
      and cirh.CHART_ID not in (
          select cir.CHART_ID
          from chart_infusion_result cir with (nolock)
          where cir.CHART_ID = cirh.CHART_ID
              and cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
              and cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
          )
      and (
          select COUNT(*)
          from [dbo].[CODER_QA_REPORT_EXCLUSION] qa with (nolock)
          where qa.KEY_VALUE_1 = cirh.CHART_INFUSION_RESULT_ID
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT_HISTORY'
          ) = 0
      and c.CHART_ID = cirh.CHART_ID
      and c.CHART_STATUS_ID = 5
      and cirh.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and cmd.OBSERVATION_IND = 0;

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '3' as 'Class'
      ,'A' as 'Action'
      ,c.CHART_ID
      ,(
          select top 1 SHORT_DESCRIPTION
          from [dbo].[CMS_HCPC_CODE] cms with (nolock)
          where [HCPC_CODE_ID] = cm.CPT_CODE
          order by [HCPC_CODE_VERSION] desc
          ) 'Description'
      ,c.SERVICE_AGREEMENT_ID
      ,cm.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from chart_infusion_result cir with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      ,[dbo].[CHARGE_MASTER] cm with (nolock)
      ,[dbo].[CHARGE_MASTER_DEPARTMENT] cmd with (nolock)
  where cm.CHARGE_MASTER_ID = cir.CHARGE_MASTER_ID
      and cir.CHART_ID not in (
          select cirh.CHART_ID
          from chart_infusion_result_history cirh with (nolock)
          where cir.CHART_ID = cirh.CHART_ID
              and cir.CHARGE_MASTER_ID = cirh.CHARGE_MASTER_ID
              and cir.DATE_OF_SERVICE = cirh.DATE_OF_SERVICE
          )
      and (
          select COUNT(*)
          from [dbo].[CODER_QA_REPORT_EXCLUSION] qa with (nolock)
          where qa.KEY_VALUE_1 = cir.CHART_INFUSION_RESULT_ID
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_INFUSION_RESULT'
          ) = 0
      and c.CHART_ID = cir.CHART_ID
      and c.CHART_STATUS_ID = 5
      and cir.OBS_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
      and cmd.OBSERVATION_IND = 0;

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '5' as 'Class'
      ,'R' as 'Action'
      ,c.CHART_ID
      ,(
          select top 1 SHORT_DESCRIPTION
          from [dbo].[CMS_HCPC_CODE] cms with (nolock)
          where [HCPC_CODE_ID] = cm.CPT_CODE
          order by [HCPC_CODE_VERSION] desc
          ) 'Description'
      ,c.SERVICE_AGREEMENT_ID
      ,cm.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from physician_procedure_evaluation_history ppeh with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      ,[dbo].[CHARGE_MASTER] cm with (nolock)
  where cm.CHARGE_MASTER_ID = ppeh.PHYSICIAN_PROCEDURE_ID
      and ppeh.CHART_ID not in (
          select ppe.CHART_ID
          from physician_procedure_evaluation ppe with (nolock)
          where ppe.CHART_ID = ppeh.CHART_ID
              and ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
          )
      and (
          select COUNT(*)
          from [dbo].[CODER_QA_REPORT_EXCLUSION] qa with (nolock)
          where qa.KEY_VALUE_1 = ppeh.CHART_ID
              and qa.KEY_VALUE_2 = CONVERT(varchar(15), ppeh.PHYSICIAN_PROCEDURE_ID)
              and qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION_HISTORY'
          ) = 0
      and c.CHART_ID = ppeh.CHART_ID;

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '5' as 'Class'
      ,'A' as 'Action'
      ,c.CHART_ID
      ,(
          select top 1 SHORT_DESCRIPTION
          from [dbo].[CMS_HCPC_CODE] cms with (nolock)
          where [HCPC_CODE_ID] = cm.CPT_CODE
          order by [HCPC_CODE_VERSION] desc
          ) 'Description'
      ,c.SERVICE_AGREEMENT_ID
      ,cm.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from physician_procedure_evaluation ppe with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      ,[dbo].[CHARGE_MASTER] cm with (nolock)
  where cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
      and ppe.CHART_ID not in (
          select ppeh.CHART_ID
          from physician_procedure_evaluation_history ppeh with (nolock)
          where ppe.CHART_ID = ppeh.CHART_ID
              and ppe.PHYSICIAN_PROCEDURE_ID = ppeh.PHYSICIAN_PROCEDURE_ID
          )
      and (
          select COUNT(*)
          from [dbo].[CODER_QA_REPORT_EXCLUSION] qa with (nolock)
          where qa.KEY_VALUE_1 = ppe.CHART_ID
              and qa.KEY_VALUE_2 = CONVERT(varchar(15), ppe.PHYSICIAN_PROCEDURE_ID)
              and qa.SOURCE_RECORD_TABLE_NAME = 'PHYSICIAN_PROCEDURE_EVALUATION'
          ) = 0
      and c.CHART_ID = ppe.CHART_ID;

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct a.CLASS
      ,a.ACTION
      ,c.CHART_ID
      ,a.DESCRIPTION
      ,c.SERVICE_AGREEMENT_ID
      ,SUBSTRING(a.DESCRIPTION, 0, CHARINDEX(',', a.DESCRIPTION)) CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from [dbo].[CHART_AUDIT_ACTION] a with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
  where c.CHART_ID = a.CHART_ID
      and a.Class = 'D';

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '7' as 'CLASS'
      ,'R' as 'ACTION'
      ,c.CHART_ID
      ,fl.DESCRIPTION
      ,c.SERVICE_AGREEMENT_ID
      ,fl.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from CHART_LOS_HISTORY clh with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      ,FACILITY_LEVEL fl with (nolock)
  where c.CHART_ID = clh.CHART_ID
      and (
          select COUNT(*)
          from [dbo].[CODER_QA_REPORT_EXCLUSION] qa with (nolock)
          where qa.KEY_VALUE_1 = clh.CHART_ID
              and qa.KEY_VALUE_2 = 'FLOS'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY'
          ) = 0
      and fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and fl.FACILITY_LEVEL_ID = (
          case 
              when clh.OVERRIDE_FACILITY_LEVEL_ID = - 1
                  then clh.FACILITY_LEVEL_ID
              else clh.OVERRIDE_FACILITY_LEVEL_ID
              end
          )
      and fl.CPT_CODE <> (
          COALESCE((
                  select fl2.CPT_CODE
                  from FACILITY_LEVEL fl2 with (nolock)
                  where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                      and (
                          (
                              case 
                                  when c.OVERRIDE_FACILITY_LEVEL_ID = - 1
                                      then c.FACILITY_LEVEL_ID
                                  else c.OVERRIDE_FACILITY_LEVEL_ID
                                  end
                              ) = fl2.FACILITY_LEVEL_ID
                          )
                  ), '')
          );

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '7' as 'Class'
      ,'A' as 'ACTION'
      ,c.CHART_ID
      ,fl.DESCRIPTION Description
      ,c.SERVICE_AGREEMENT_ID
      ,fl.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from CHART_LOS_HISTORY clh with (nolock)
      ,[RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c
      ,FACILITY_LEVEL fl with (nolock)
  where c.CHART_ID = clh.CHART_ID
      and (
          select COUNT(*)
          from [dbo].[CODER_QA_REPORT_EXCLUSION] qa with (nolock)
          where qa.KEY_VALUE_1 = clh.CHART_ID
              and qa.KEY_VALUE_2 = 'FLOS'
              and qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY'
          ) = 0
      and fl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      and fl.FACILITY_LEVEL_ID = (
          case 
              when c.OVERRIDE_FACILITY_LEVEL_ID = - 1
                  then c.FACILITY_LEVEL_ID
              else c.OVERRIDE_FACILITY_LEVEL_ID
              end
          )
      and fl.CPT_CODE <> (
          COALESCE((
                  select fl2.CPT_CODE
                  from FACILITY_LEVEL fl2 with (nolock)
                  where fl2.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                      and (
                          (
                              case 
                                  when clh.OVERRIDE_FACILITY_LEVEL_ID = - 1
                                      then clh.FACILITY_LEVEL_ID
                                  else clh.OVERRIDE_FACILITY_LEVEL_ID
                                  end
                              ) = fl2.FACILITY_LEVEL_ID
                          )
                  ), '')
          );

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '8' as 'Class'
      ,'R' as 'ACTION'
      ,t.CHART_ID
      ,t.DESCRIPTION Description
      ,t.SERVICE_AGREEMENT_ID
      ,t.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_R8] as t
  inner join [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c on c.CHART_ID = t.CHART_ID
  where t.CPT_CODE <> (
          select psp.CPT_CODE
          from PHYSICIAN_SERVICE_PROCEDURE as psp
          where t.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
              and psp.PHYSICIAN_SERVICE_PROC_ID = case 
                  when t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = - 1
                      then t.PHYSICIAN_SERVICE_PROC_ID
                  else t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                  end
          );

  insert into [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] (
      CLASS
      ,ACTION
      ,CHART_ID
      ,DESCRIPTION
      ,SERVICE_AGREEMENT_ID
      ,CPT_CODE
      ,FACILITY_ID
      ,SENT_DATE
      ,TIME_OF_SERVICE
      ,APPROVED_BY_USER_PROFILE_ID
      )
  select distinct '8' as 'Class'
      ,'A' as 'ACTION'
      ,t.CHART_ID
      ,t.DESCRIPTION
      ,t.SERVICE_AGREEMENT_ID
      ,t.CPT_CODE
      ,c.FACILITY_ID
      ,c.SENT_DATE
      ,c.[TIME_OF_SERVICE]
      ,c.[APPROVED_BY_USER_PROFILE_ID]
  from [RevCycleTransactionSnapshot].[dbo].[ChartSubset_A8] as t
  inner join [RevCycleTransactionSnapshot].[dbo].[ChartSubset] as c on c.CHART_ID = t.CHART_ID
  where t.CPT_CODE <> (
          select psp.CPT_CODE
          from PHYSICIAN_SERVICE_PROCEDURE as psp
          where t.SERVICE_AGREEMENT_ID = psp.SERVICE_AGREEMENT_ID
              and psp.PHYSICIAN_SERVICE_PROC_ID = case 
                  when t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = - 1
                      then t.PHYSICIAN_SERVICE_PROC_ID
                  else t.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                  end
          );

   CREATE NONCLUSTERED INDEX [ix_ChartAuditActionDetail] ON [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail]
        ([CHART_ID] , [CLASS] , [ACTION])
        WITH
        (PAD_INDEX = OFF,
        FILLFACTOR = 100,
        IGNORE_DUP_KEY = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON,
        MAXDOP = 0)
        ON [PRIMARY];

  update [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] set
    COMPLETED_BY_USER_PROFILE_ID = CHART.COMPLETED_BY_USER_PROFILE_ID
  from [RevCycleTransactionSnapshot].[dbo].[ChartAuditActionDetail] c
  join CHART on CHART.CHART_ID = c.CHART_ID;

END
GO
