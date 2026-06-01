SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO















CREATE PROCEDURE [dbo].[rpt_Post_Bill_Audit_Report_NEW] 
	@ReportUser INT,
	@DateType INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@CUID VARCHAR(MAX),
	@COMPANY_ID VARCHAR(MAX),
	@FACILITY_ID VARCHAR(MAX),
	@AuditReason VARCHAR(MAX),
	@Clinic VARCHAR(MAX)


AS
BEGIN



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;


-- test parameters
 -- declare
 -- @ReportUser INT = 80,
 -- @DateType INT = 3, -- 0 Approved, 1 DOS, 2 Sent, 3 PostAudit
	--@StartDate DATETIME = '10/05/2023',
	--@EndDate DATETIME   = '10/05/2023',
	--@CUID VARCHAR(MAX)        = -1,  -- -1 All 
	--@FACILITY_ID VARCHAR(MAX) = -1,  -- -1 All 
	--@AuditReason varchar(max) = -1,         -- -1 All,  1 Client Requested Review, 2 Focused Quality Review
	--@Clinic varchar(max) = '-1'; --  'PBG';  -- '-1' ALL

  

	DECLARE @m_ReportUser INT
	DECLARE @m_StartDate DATETIME
	DECLARE @m_EndDate DATETIME
	DECLARE @m_FACILITY_ID VARCHAR(MAX)
	Set @m_ReportUser = @ReportUser
	Set @m_StartDate = @StartDate
	Set @m_EndDate = @EndDate
	Set @m_FACILITY_ID = @FACILITY_ID
	DECLARE @m_COMPANY_ID VARCHAR(MAX) = @COMPANY_ID;
 	DECLARE @m_CUID VARCHAR(MAX) = @CUID;
	DECLARE @m_DateType INT = @DateType;
	DECLARE @m_AuditReason VARCHAR(MAX) = @AuditReason;
	DECLARE @m_Clinic varchar(max) = @Clinic;


if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#ChartSubset1', 'U') is not null drop table #ChartSubset1;
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
if object_id('TempDB..#CodedCharts', 'U') is not null drop table #CodedCharts;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#Scorecard_2', 'U') is not null drop table #Scorecard_2;
if object_id('TempDB..#AuditGrid1', 'U') is not null drop table #AuditGrid1;
if object_id('TempDB..#AuditNotes1', 'U') is not null drop table #AuditNotes1;
if object_id('TempDB..#AuditNotes2', 'U') is not null drop table #AuditNotes2;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;


-- *****************************************************************************************************************************************
-- AuthorizedFacilities

SELECT *
INTO #AuthorizedFacilities
FROM (
  SELECT DISTINCT fua.FACILITY_ID
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id 
	and up.IS_ACTIVE = 'Y'						
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.company_id <> 19 -- Exclude - Tenet Healthcare Corporation 
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser
		    and  ( sa.COMPANY_ID in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ',')) )
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		) af;


-- *****************************************************************************************************************************************


SELECT	c.chart_id, c.service_agreement_id, c.facility_chart_id, c.Time_Of_Service, c.APPROVED_DATE, c.completed_by_user_profile_id, c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID,
c.START_QA_DATE, c.POST_BILL_AUDIT_STARTED, c.PATIENT_CLASS_ID, c.CLINIC_ID, c.facility_id,
FACILITY_SERVICE_LEVEL_AUDIT_COMMENT, FACILITY_PROCEDURES_AUDIT_COMMENT, PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT, PHYSICIAN_PROCEDURES_AUDIT_COMMENT,
DIAGNOSIS_CODING_AUDIT_COMMENT, INFUSION_INJECTION_AUDIT_COMMENT, AUDITOR_REVIEW_FEEDBACK, OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT,
OBSERVATION_PROCEDURES_AUDIT_COMMENT, OBSERVATION_AUDITOR_REVIEW_FEEDBACK, DEMOGRAPHIC_AUDIT_COMMENT, ANESTHESIA_CODING_AUDIT_COMMENT




INTO	[#ChartSubset1]
FROM	chart as c 
WHERE	
        c.CHART_STATUS_ID in (4, 5) 
AND   
( c.COMPLETED_BY_USER_PROFILE_ID in (SELECT * FROM SPLITSTRING(@m_CUID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_CUID, ',')) )



and	 
		(									
		(@m_DateType = 0 and c.APPROVED_DATE between @m_StartDate and DateAdd(second, 86399, @m_EndDate) )						
		or					
		(@m_DateType = 1 and c.TIME_OF_SERVICE between @m_StartDate and DateAdd(second, 86399, @m_EndDate) )									
		or 									
		(@m_DateType = 2 and c.sent_date between @m_StartDate and  DateAdd(second, 86399, @m_EndDate) )
		or 
		(@m_DateType = 3 and c.POST_BILL_AUDIT_COMPLETED between @m_StartDate and  DateAdd(second, 86399, @m_EndDate) )
		) 
AND	    c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
;


-- Reduces dataset to NEW PBA only 

select 
c.* 
INTO [#ChartSubset]
from 
[#ChartSubset1] c,
ChartPostBillAudit pba, -- this table includes records from both new and old PBA engine 
ChartAuditVersion cav  -- records in version table will be new PBA engine
where c.chart_id = pba.chartID
and pba.ChartPostBillAuditId = cav.ChartAuditId
AND pba.ChartPostBillAuditStatusTypeCode = 3 -- Completed
AND cav.VersionNumber = 2 -- PBA Complete Version




-- *****************************************************************************************************************************************
-- Correction to Split Dx Types


	select 
		dx.CHART_ID
		,dx.FACILITY_CHART_ID
		,dx.ACTION
		,dx.CODER_DIAGNOSIS_TYPE_DESCRIPTION
		--,dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		,case when dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION = 'Primary Dx' and dx.AUDITOR_ICD10_CODE <> '' then
				case when icd.DIAGNOSIS_TYPE_ID = 1 and icd.IS_PRIMARY = 1 then 'Chief Complaint'
						when icd.DIAGNOSIS_TYPE_ID = 1 and icd.IS_PRIMARY = 0 then 'Additional Complaint'
						when icd.DIAGNOSIS_TYPE_ID = 2 and icd.IS_PRIMARY = 1 then 'Primary Dx'
						when icd.DIAGNOSIS_TYPE_ID = 2 and icd.IS_PRIMARY = 0 then 'Secondary Dx'
						when icd.DIAGNOSIS_TYPE_ID = 3 and icd.IS_PRIMARY = 1 then 'Chief Complaint and Primary Dx'
						when icd.DIAGNOSIS_TYPE_ID = 5 and icd.IS_PRIMARY = 0 then 'Chief Complaint and Secondary Dx'
					else '' end
				else dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION end AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		,dx.IS_CHIEF_COMPLAINT_CHANGE
		,dx.IS_PRIMARY_DIAGNOSIS_CHANGE
		,dx.IS_CODER_CORRECT
		,dx.CODER_ICD10_CODE
		,dx.AUDITOR_ICD10_CODE
		,dx.EXCLUDE_FROM_QA_REPORT
	into #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION
	from
		#ChartSubset c
		inner join CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
		left join CHART_DIAGNOSIS_CODE_ICD10 icd on dx.CHART_ID = icd.CHART_ID and dx.AUDITOR_ICD10_CODE = icd.ICD10_CODE
	where
		dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION not like '%and%'

	
	----------------------------------------------------------------------------------------------------------------------------------

	select 
		dx.CHART_ID
		,dx.FACILITY_CHART_ID
		,dx.[ACTION]
		,dx.CODER_DIAGNOSIS_TYPE_DESCRIPTION
		,dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		,substring(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION,0,charindex(' and ',dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)) [FIRST_DT_DESC]
		,substring(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION,charindex(' and ',dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)+5,len(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)) [SECOND_DT_DESC]
		,dx.IS_CHIEF_COMPLAINT_CHANGE
		,dx.IS_PRIMARY_DIAGNOSIS_CHANGE
		,dx.IS_CODER_CORRECT
		,dx.CODER_ICD10_CODE
		,dx.AUDITOR_ICD10_CODE
		,dx.EXCLUDE_FROM_QA_REPORT
		,0 as [Split]
	into #combined
	from
		#ChartSubset c
		inner join dbo.CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
	where
		dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION like '%and%'

		
	----------------------------------------------------------------------------------------------------------------------------------


	declare @chart int

	while exists (select * from #combined where Split = 0)
	begin
		
		set @chart = (select top 1 CHART_ID from #combined where Split = 0)


		insert into #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION
		select 
			c.CHART_ID
		   ,c.FACILITY_CHART_ID
		   ,c.ACTION
		   ,c.CODER_DIAGNOSIS_TYPE_DESCRIPTION
		   ,c.FIRST_DT_DESC
		   ,case when c.ACTION = 'A' then 0 
					when c.FIRST_DT_DESC like '%Chief%' and c.IS_CHIEF_COMPLAINT_CHANGE = 1 then 1 
				else 0 end IS_CHIEF_COMPLAINT_CHANGE
		   ,case when c.ACTION = 'A' then 0 
					when c.FIRST_DT_DESC like '%Primary%' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 then 1 
				else 0 end IS_PRIMARY_DIAGNOSIS_CHANGE
		   ,case when c.EXCLUDE_FROM_QA_REPORT = 1 then 1 else c.IS_CODER_CORRECT end IS_CODER_CORRECT
		   ,c.CODER_ICD10_CODE
		   ,c.AUDITOR_ICD10_CODE
		   ,c.EXCLUDE_FROM_QA_REPORT
		from
			#combined c
		where
			c.CHART_ID = @chart

		union all

		select 
			c.CHART_ID
		   ,c.FACILITY_CHART_ID
		   ,c.ACTION
		   ,c.CODER_DIAGNOSIS_TYPE_DESCRIPTION
		   ,c.SECOND_DT_DESC
		   ,case when c.ACTION = 'A' then 0 
					when c.SECOND_DT_DESC like '%Chief%' and c.IS_CHIEF_COMPLAINT_CHANGE = 1 then 1 
				else 0 end IS_CHIEF_COMPLAINT_CHANGE
		   ,case when c.ACTION = 'A' then 0 
					when c.SECOND_DT_DESC like '%Primary%' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 then 1 
				else 0 end IS_PRIMARY_DIAGNOSIS_CHANGE
		   ,case when c.EXCLUDE_FROM_QA_REPORT = 1 then 1 else c.IS_CODER_CORRECT end IS_CODER_CORRECT
		   ,c.CODER_ICD10_CODE
		   ,c.AUDITOR_ICD10_CODE
		   ,c.EXCLUDE_FROM_QA_REPORT
		from
			#combined c
		where
			c.CHART_ID = @chart

		
		update #combined
		set Split = 1
		where CHART_ID = @chart


	end






-- *****************************************************************************************************************************************

SELECT		
c.service_agreement_id, -- sa.DESCRIPTION as ServiceAgreementDescription, 
f.name as ServiceAgreementDescription,
c.chart_id, c.facility_chart_id, c.Time_Of_Service, c.APPROVED_DATE, up.USER_PROFILE_ID,  up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,
c.PATIENT_CLASS_ID, c.CLINIC_ID,

-- PBA Audit Reason
            (select pba.ChartPostBillAuditReasonTypeCode from ChartPostBillAudit pba where pba.ChartPostBillAuditStatusTypeCode = 3 AND pba.ChartId = c.CHART_ID) as AuditReasonCode,

--Dx Post	
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as DxAdditions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as DxRevisions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as DxDeletions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as DxAbstract_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as DxNoChange_Post,

	
-- Facility Procedures Post
            (select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as FacilityProcAdditions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as FacilityProcRevisions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as FacilityProcDeletions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as FacilityProcAbstract_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as FacilityProcNoChange_Post,

	
-- Procedures I/I Post
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAdditions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionRevisions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionDeletions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAbstract_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionNoChange_Post,

	
-- Prof Procedures Post
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as ProfProcAdditions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as ProfProcRevisions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as ProfProcDeletions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as ProfProcAbstract_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as ProfProcNoChange_Post,
			
	
-- Obs Procedures Post			
            
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as ObsHoursAdditions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as ObsHoursRevisions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as ObsHoursDeletions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as ObsHoursAbstract_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursNoChange_Post,
			
			

--Facility LOS Post			
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAdditions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as FacilityLOSRevisions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as FacilityLOSDeletions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAbstract_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as FacilityLOSNoChange_Post,
				
--Physician LOS Post
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAdditions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSRevisions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSDeletions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAbstract_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSNoChange_Post,

	
			
			case when sa.EVALUATE_FACILITY_SVC = 1 then 'Y' else 'N' end as FacilityLOSService,
			case when (sa.INFUSION_INJECTION_METHOD_ID = 1 or sa.INFUSION_INJECTION_METHOD_ID = 2) then 'Y' else 'N' end as InfusionInjectionService,
			case when sa.EVALUATE_FACILITY_PROCEDURES = 1 then 'Y' else 'N' end as FacilityProcService,
			case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 'Y' else 'N' end as PhysicianLOSService,
			case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 'Y' else 'N' end as ProfProcService,
			case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 'Y' else 'N' end as DxService,
 			case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 and c.PATIENT_DISPOSITION_ID = 5 then 'Y' else 'N' end as ObsHoursService,
			
	
			
-- Post Attempted and Action
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAttempted_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAttempted_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID)  as ProfProcAttempted_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND pba.ChartId = c.CHART_ID)  as ObsHoursAttempted_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAttempted_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as DxAttempted_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID)  as FacilityProcAttempted_Post,

			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as FacilityLOSActions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionActions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ProfProcActions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursActions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSActions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as DxActions_Post,
			(select count(*) FROM ChartPostBillAudit pba, ChartAuditVersion cav, ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as FacilityProcActions_Post

into #Scorecard_1
			FROM	[#ChartSubset] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID    
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
					LEFT OUTER JOIN FACILITY f on c.facility_id = f.facility_id 
-- 			WHERE		c.approved_by_user_profile_id > 2	




-- *****************************************************************************************************************************************
-- Auditor Grid Temp 

select
chart_id,

FacilityLOSService,                                                                                                                         
case when s.FacilityLOSAdditions_Post > 0 then cast(s.FacilityLOSAdditions_Post as varchar(5)) + ' Additions_Post'end as FacilityLOSAdditionPostError,
case when s.FacilityLOSRevisions_Post > 0 then cast(s.FacilityLOSRevisions_Post as varchar(5)) + ' Revisions_Post'end as FacilityLOSRevisionPostError,
case when s.FacilityLOSDeletions_Post > 0 then cast(s.FacilityLOSDeletions_Post as varchar(5)) + ' Deletions_Post'end as FacilityLOSDeletionPostError,
case when s.FacilityLOSAbstract_Post > 0 then cast(s.FacilityLOSAbstract_Post as varchar(5)) + ' Abstract_Post'end as FacilityLOSAbstractPostError,
s.FacilityLOSNoChange_Post,
s.FacilityLOSAttempted_Post,
s.FacilityLOSActions_Post,

InfusionInjectionService,
case when s.InfusionInjectionAdditions_Post > 0 then cast(s.InfusionInjectionAdditions_Post as varchar(5)) + ' Additions_Post'end as InfusionInjectionAdditionPostError,
case when s.InfusionInjectionRevisions_Post > 0 then cast(s.InfusionInjectionRevisions_Post as varchar(5)) + ' Revisions_Post'end as InfusionInjectionRevisionPostError,
case when s.InfusionInjectionDeletions_Post > 0 then cast(s.InfusionInjectionDeletions_Post as varchar(5)) + ' Deletions_Post'end as InfusionInjectionDeletionPostError,
case when s.InfusionInjectionAbstract_Post > 0 then cast(s.InfusionInjectionAbstract_Post as varchar(5)) + ' Abstract_Post'end as InfusionInjectionAbstractPostError,
s.InfusionInjectionNoChange_Post,
s.InfusionInjectionAttempted_Post,
s.InfusionInjectionActions_Post,

FacilityProcService,
case when s.FacilityProcAdditions_Post > 0 then cast(s.FacilityProcAdditions_Post as varchar(5)) + ' Additions_Post'end as FacilityProcAdditionPostError,
case when s.FacilityProcRevisions_Post > 0 then cast(s.FacilityProcRevisions_Post as varchar(5)) + ' Revisions_Post'end as FacilityProcRevisionPostError,
case when s.FacilityProcDeletions_Post > 0 then cast(s.FacilityProcDeletions_Post as varchar(5)) + ' Deletions_Post'end as FacilityProcDeletionPostError,
case when s.FacilityProcAbstract_Post > 0 then cast(s.FacilityProcAbstract_Post as varchar(5)) + ' Abstract_Post'end as FacilityProcAbstractPostError,
s.FacilityProcNoChange_Post,
s.FacilityProcAttempted_Post,
s.FacilityProcActions_Post,

PhysicianLOSService,
case when s.PhysicianLOSAdditions_Post > 0 then cast(s.PhysicianLOSAdditions_Post as varchar(5)) + ' Additions_Post'end as PhysicianLOSAdditionPostError,
case when s.PhysicianLOSRevisions_Post > 0 then cast(s.PhysicianLOSRevisions_Post as varchar(5)) + ' Revisions_Post'end as PhysicianLOSRevisionPostError,
case when s.PhysicianLOSDeletions_Post > 0 then cast(s.PhysicianLOSDeletions_Post as varchar(5)) + ' Deletions_Post'end as PhysicianLOSDeletionPostError,
case when s.PhysicianLOSAbstract_Post > 0 then cast(s.PhysicianLOSAbstract_Post as varchar(5)) + ' Abstract_Post'end as PhysicianLOSAbstractPostError,
s.PhysicianLOSNoChange_Post,
s.PhysicianLOSAttempted_Post,
s.PhysicianLOSActions_Post,


ProfProcService,
case when s.ProfProcAdditions_Post > 0 then cast(s.ProfProcAdditions_Post as varchar(5)) + ' Additions_Post'end as ProfProcAdditionPostError,
case when s.ProfProcRevisions_Post > 0 then cast(s.ProfProcRevisions_Post as varchar(5)) + ' Revisions_Post'end as ProfProcRevisionPostError,
case when s.ProfProcDeletions_Post > 0 then cast(s.ProfProcDeletions_Post as varchar(5)) + ' Deletions_Post'end as ProfProcDeletionPostError,
case when s.ProfProcAbstract_Post > 0 then cast(s.ProfProcAbstract_Post as varchar(5)) + ' Abstract_Post'end as ProfProcAbstractPostError,
s.ProfProcNoChange_Post,
s.ProfProcAttempted_Post,
s.ProfProcActions_Post,


DxService,
case when s.DxAdditions_Post > 0 then cast(s.DxAdditions_Post as varchar(5)) + ' Additions_Post'end as DxAdditionPostError,
case when s.DxRevisions_Post > 0 then cast(s.DxRevisions_Post as varchar(5)) + ' Revisions_Post'end as DxRevisionPostError,
case when s.DxDeletions_Post > 0 then cast(s.DxDeletions_Post as varchar(5)) + ' Deletions_Post'end as DxDeletionPostError,
case when s.DxAbstract_Post > 0 then cast(s.DxAbstract_Post as varchar(5)) + ' Abstract_Post'end as DxAbstractPostError,
s.DxNoChange_Post,
s.DxAttempted_Post,
s.DxActions_Post,



ObsHoursService,
case when s.ObsHoursAdditions_Post > 0 then cast(s.ObsHoursAdditions_Post as varchar(5)) + ' Additions_Post'end as ObsHoursAdditionPostError,
case when s.ObsHoursRevisions_Post > 0 then cast(s.ObsHoursRevisions_Post as varchar(5)) + ' Revisions_Post'end as ObsHoursRevisionPostError,
case when s.ObsHoursDeletions_Post > 0 then cast(s.ObsHoursDeletions_Post as varchar(5)) + ' Deletions_Post'end as ObsHoursDeletionPostError,
case when s.ObsHoursAbstract_Post > 0 then cast(s.ObsHoursAbstract_Post as varchar(5)) + ' Abstract_Post'end as ObsHoursAbstractPostError,
s.ObsHoursNoChange_Post,
s.ObsHoursAttempted_Post,
s.ObsHoursActions_Post



into #AuditGrid1
from
#Scorecard_1 s




-- *****************************************************************************************************************************************

-- Post Bill Audit Comments

select 
cs.chart_id,

(select distinct 
'FacilityProcedure: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 1 -- FacilityProcedure
WHERE 
ca.ChartId = cs.chart_id  
) as FacProc,

(select distinct 
'PhysicianProcedure: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 2 -- PhysicianProcedure
WHERE 
ca.ChartId = cs.chart_id 
) as PhyProc,

(select distinct 
'Observation: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 3 -- ObservationProcedure
WHERE 
ca.ChartId = cs.chart_id 
) as Obs,

(select distinct 
'InfusionInjection: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 4 -- InfusionInjectionProcedure
WHERE 
ca.ChartId = cs.chart_id 
) as InfInj,

(select distinct
'FacilityService: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 5 -- FacilityService
WHERE 
ca.ChartId = cs.chart_id  
) as FacService,

(select distinct 
'PhysicianService: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 6 -- PhysicianService
WHERE 
ca.ChartId = cs.chart_id 
) as PhyService,

(
SELECT distinct 
'Demographics: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 7 -- Demo
WHERE 
ca.ChartId = cs.chart_id 
) as Demo,

(select distinct 
'Anesthesia: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 9 -- Anesthesia
WHERE 
ca.ChartId = cs.chart_id 
) as Anesthesia,

(select distinct 
'Diagnosis: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 10 -- Dx
WHERE 
ca.ChartId = cs.chart_id  
) as Diagnosis,

(
SELECT distinct 
'General: ' + c.comment +'; '
FROM ChartPostBillAudit ca 
INNER JOIN ChartAuditVersion av ON av.ChartAuditId = ca.ChartPostBillAuditId AND av.VersionNumber = 2
INNER JOIN ChartAuditVersionComment c ON c.ChartAuditVersionId = av.ChartAuditVersionId AND c.ChartAuditSectionTypeCode = 11 -- General
WHERE 
ca.ChartId = cs.chart_id 
) as General

into #AuditNotes2
from [#ChartSubset] cs



-- *****************************************************************************************************************************************
--calculations

select 
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, s.facility_chart_id, s.Time_Of_Service as DATE_OF_SERVICE, s.APPROVED_DATE, 
s.USER_PROFILE_ID,  s.CoderName, s.AuditReasonCode, s.PATIENT_CLASS_ID, s.CLINIC_ID


into #Scorecard_2
from #Scorecard_1 s
where 
  ( s.AuditReasonCode in (SELECT * FROM SPLITSTRING(@m_AuditReason, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_AuditReason, ',')) )
AND ( s.CLINIC_ID in (SELECT * FROM SPLITSTRING(@m_Clinic, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_Clinic, ',')) )
group by 
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, s.facility_chart_id, s.Time_Of_Service, s.APPROVED_DATE, s.USER_PROFILE_ID,  s.CoderName,
s.user_profile_id, s.CoderName, s.AuditReasonCode, s.PATIENT_CLASS_ID, s.CLINIC_ID


-- *****************************************************************************************************************************************
-- Output

select 
*,

(select description from ChartPostBillAuditReasonTypeCode where ChartPostBillAuditReasonTypeCode = s.AuditReasonCode) as AuditReason,
(select description from PATIENT_CLASS where patient_class_id = s.PATIENT_CLASS_ID) as PatientClass,
(Select description from SERVICE_AGREEMENT_CLINIC where service_agreement_id = s.service_agreement_id and  CLINIC_ID = s.CLINIC_ID) as Clinic, 


(select 
case 
when FacilityLOSService = 'N' then '-' 
when FacilityLOSService = 'Y' and FacilityLOSAttempted_Post = 0 then '-' 

when (FacilityLOSService = 'Y' and FacilityLOSAttempted_Post > 0 and FacilityLOSActions_Post > 0)  then 
   coalesce(FacilityLOSAdditionPostError +';', '') + coalesce(FacilityLOSRevisionPostError +';', '') 
   + coalesce(FacilityLOSDeletionPostError +';', '') + coalesce(FacilityLOSAbstractPostError +';', '')

when (FacilityLOSService = 'Y' and FacilityLOSActions_Post = 0 and FacilityLOSAttempted_Post > 0 ) then 'Correct' 

end
from #AuditGrid1
where chart_id = s.chart_id ) as FacilityLOSError, 





( select case 
when InfusionInjectionService = 'N' then '-' 
when InfusionInjectionService = 'Y' and InfusionInjectionAttempted_Post = 0 then '-' 

when (InfusionInjectionService = 'Y' and InfusionInjectionAttempted_Post > 0 and InfusionInjectionActions_Post > 0)  then 
     coalesce(InfusionInjectionAdditionPostError +';', '') + coalesce(InfusionInjectionRevisionPostError +';', '') 
   + coalesce(InfusionInjectionDeletionPostError +';', '') + coalesce(InfusionInjectionAbstractPostError +';', '')

when  (InfusionInjectionService = 'Y' and InfusionInjectionActions_Post = 0 and InfusionInjectionAttempted_Post > 0) then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as InfusionInjectionError,







( select case 
when FacilityProcService = 'N' then '-' 
when (FacilityProcService = 'Y' and FacilityProcAttempted_Post = 0) then '-' 

when (FacilityProcService = 'Y' and FacilityProcAttempted_Post > 0 and FacilityProcActions_Post > 0)  then 
     coalesce(FacilityProcAdditionPostError +';', '') + coalesce(FacilityProcRevisionPostError +';', '') 
   + coalesce(FacilityProcDeletionPostError +';', '') + coalesce(FacilityProcAbstractPostError +';', '')

when  (FacilityProcService = 'Y' and FacilityProcActions_Post = 0 and FacilityProcAttempted_Post > 0 ) then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as FacilityProcError,






(select 
case 
when PhysicianLOSService = 'N' then '-' 
when PhysicianLOSService = 'Y' and PhysicianLOSAttempted_Post = 0 then '-' 

when (PhysicianLOSService = 'Y' and PhysicianLOSAttempted_Post > 0 and PhysicianLOSActions_Post > 0) then 
     coalesce(PhysicianLOSAdditionPostError +';', '') + coalesce(PhysicianLOSRevisionPostError +';', '') 
   + coalesce(PhysicianLOSDeletionPostError +';', '') + coalesce(PhysicianLOSAbstractPostError +';', '')

when (PhysicianLOSService = 'Y' and PhysicianLOSActions_Post = 0 and PhysicianLOSAttempted_Post > 0 ) then 'Correct' 

end
from #AuditGrid1
where chart_id = s.chart_id ) as PhysicianLOSError,



( select case 
when ProfProcService = 'N' then '-' 
when ProfProcService = 'Y' and ProfProcAttempted_Post = 0 then '-' 

when (ProfProcService = 'Y' and ProfProcAttempted_Post > 0 and ProfProcActions_Post > 0) then 
     coalesce(ProfProcAdditionPostError +';', '') + coalesce(ProfProcRevisionPostError +';', '') 
   + coalesce(ProfProcDeletionPostError +';', '') + coalesce(ProfProcAbstractPostError +';', '')

when  (ProfProcService = 'Y' and ProfProcActions_Post = 0 and ProfProcAttempted_Post > 0 ) then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as ProfProcError,




(select 
case 
when DxService = 'N' then '-' 
when DxService = 'Y' and DxAttempted_Post = 0 then '-' 

when (DxService = 'Y' and DxAttempted_Post > 0 and DxActions_Post > 0)  then 
     coalesce(DxAdditionPostError +';', '') + coalesce(DxRevisionPostError +';', '') 
   + coalesce(DxDeletionPostError +';', '') + coalesce(DxAbstractPostError +';', '')

when (DxService = 'Y' and DxActions_Post = 0 and DxAttempted_Post > 0 ) then 'Correct' 

end
from #AuditGrid1
where chart_id = s.chart_id ) as DxError, 


( select case 
when ObsHoursService = 'N' then '-' 
when ObsHoursService = 'Y' and ObsHoursAttempted_Post = 0 then '-'  

when (ObsHoursService = 'Y' and ObsHoursAttempted_Post > 0 and ObsHoursActions_Post > 0) then 
     coalesce(ObsHoursAdditionPostError +';', '') + coalesce(ObsHoursRevisionPostError +';', '') 
   + coalesce(ObsHoursDeletionPostError +';', '') + coalesce(ObsHoursAbstractPostError +';', '')

when  (ObsHoursService = 'Y' and ObsHoursActions_Post = 0 and ObsHoursAttempted_Post > 0)  then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as ObsHoursError,


(select 
coalesce(Demo, '') + coalesce(PhyService, '') + coalesce(FacService, '') + coalesce(FacProc, '') +
coalesce(PhyProc, '') + coalesce(Diagnosis, '') + coalesce(InfInj, '') + coalesce(General, '') +
coalesce(Anesthesia, '') + coalesce(Obs, '') as AuditNotes
from #AuditNotes2
where chart_id = s.chart_id ) as PostAuditNotes


from

#Scorecard_2 s

END













GO
