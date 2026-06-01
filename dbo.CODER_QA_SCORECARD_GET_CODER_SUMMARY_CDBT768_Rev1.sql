SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create PROCEDURE [dbo].[CODER_QA_SCORECARD_GET_CODER_SUMMARY_CDBT768_Rev1] 
	@StartDate datetime,
	@EndDate datetime,
	@CODER_USER_PROFILE_ID int
AS
BEGIN

SET NOCOUNT ON											-- added 1/5/2025, dsexton
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		-- added 1/5/2025, dsexton

-- parameters for testing:
/*
declare
	@StartDate datetime = '10/1/2022',
	@EndDate datetime = '3/1/2023',
	@CODER_USER_PROFILE_ID int = 11236
*/

-- Replaced all #temp tables with @table variables since the data sets are relatively small. This eliminates periodic delays from statistics updates by STATMAN on #temp tables.  dsexton, 1/5/2025

/*	-- Add this index before deploying the tuned sproc. In tests this index reduced LReads by as much as 99% for inserts to @ChartSubset in the tuned version (eg., 100 reads vs 100K). dsexton, 1/5/2025
-- To avoid blocking of queries, temporarily change AG to asynchronous mode when creating this index.
create index ix_Chart_CompBy_INCLx2 on CHART (Completed_By_User_Profile_ID)		-- 03:49 (mm:ss) on trcmsqlaz05
INCLUDE (Approved_Date, Approval_Reason_Code)
with (online = on, resumable = on)
on FGIndex1
*/

-- converted #temp table to @table variable.  dsexton, 1/5/2025
declare @ChartSubset TABLE (
	Chart_ID int,
	completed_by_user_profile_id int,
	Approval_Reason_Code int,
	time_of_service datetime, 
	service_agreement_id int, 
	facility_chart_id varchar(40), 
	APPROVED_DATE datetime, 
	approved_by_user_profile_id int,
	Chart_Status_ID int
)

-- Populating many columns on the INSERT would require a large covering index with a questionable cost-benefit ratio since this sproc executes on the order of 2K times daily rather than 100K-level executions.  dsexton, 1/5/2025
-- The subsequent UPDATE uses a clustered index seek, so it performs well enough and is a reasonable alternative to adding a large covering index.  dsexton, 1/5/2025
insert into @ChartSubset
SELECT	
	c.chart_id, 
	c.completed_by_user_profile_id, 
	c.Approval_Reason_Code,								-- can populate on the INSERT with good performance due to new index.  dsexton, 1/5/2025
	time_of_service = cast(null as datetime), 
	service_agreement_id = cast(null as int), 
	facility_chart_id = cast(null as varchar(20)), 
	APPROVED_DATE = cast(null as datetime), 
	approved_by_user_profile_id = cast(null as int)
	--, Approval_Reason_Code = cast(null as int)		-- can populate on the INSERT with good performance due to new index.  dsexton, 1/5/2025
	, chart_Status_ID = cast(null as int)				-- Moved from INSERT criteria to DELETE criteria in order to eliminate the need for this column in the new index.  dsexton, 1/5/2025
FROM	chart as c with (NOLOCK)
WHERE	
	--c.CHART_STATUS_ID in (4, 5) and		-- Moved from INSERT criteria to DELETE criteria in order to eliminate the need for this column in the new index. Most (all?) charts have status 4 or 5 after being "completed" and "approved".  dsexton, 1/5/2025
	c.COMPLETED_BY_USER_PROFILE_ID = @CODER_USER_PROFILE_ID		
	--and c.completion_date between DateAdd(day, -7, @StartDate) and DateAdd(second, 86399, @EndDate)	-- replaced below by Approved_Date to match user input and to significantly reduce INSERT and UPDATE count.  dsexton, 1/5/2025
	and c.approved_date between @StartDate and DateAdd(second, 86399, @EndDate)			-- replaces Completion_Date above to match user input and to significantly reduce INSERT and UPDATE count.  dsexton, 1/5/2025
	and approval_reason_code = 3	-- Moved from DELETE criteria to INSERT criteria to reduce INSERT and UPDATE count by as much as 90%. New index allows good performance.  dsexton, 1/5/2025

update t
set t.time_of_service = c.time_of_service,
	t.service_agreement_id = c.service_agreement_id, 
	t.facility_chart_id = c.facility_chart_id, 
	t.APPROVED_DATE = c.APPROVED_DATE, 
	t.approved_by_user_profile_id = c.approved_by_user_profile_id
	--, t.Approval_Reason_Code = c.approval_reason_code					-- Moved from DELETE criteria to INSERT criteria to reduce INSERT and UPDATE count by as much as 90%. New index allows good performance.  dsexton, 1/5/2025
	, t.chart_Status_ID = c.chart_Status_ID								-- Moved from INSERT criteria to DELETE criteria in order to eliminate the need for this column in the new index.  dsexton, 1/5/2025
from @ChartSubset as t join chart as c with(nolock) on t.chart_ID = c.chart_ID

delete from @ChartSubset 
where 
	--NOT convert(varchar, APPROVED_DATE, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)		-- Moved from DELETE criteria to INSERT criteria in order to match user input and to significantly reduce INSERT and UPDATE count.  dsexton, 1/5/2025
	--or 
	APPROVED_BY_USER_PROFILE_ID <= 2	
	--or Approval_Reason_Code <> 3			-- Moved from DELETE criteria to INSERT criteria to reduce INSERT and UPDATE count by as much as 90%. New index allows good performance.  dsexton, 1/5/2025
	or chart_Status_ID not in (4, 5)		-- Moved from INSERT criteria to DELETE criteria in order to eliminate the need for this column in the new index. Most (all?) charts have status 4 or 5 after being "completed" and "approved".  dsexton, 1/5/2025
--*/

-- added @ServiceAgreements subset table to improve performance of populating @Results as well as the many inserts to @DemoAuditChartIDs.  dsexton, 1/5/2025
declare @ServiceAgreements TABLE (
	service_agreement_ID int,
	Description	varchar	(100),
	COLLECT_MEDICAL_RECORD_NUMBER varchar(5),
	INCLUDE_MRN_AS_QA_ELEMENT bit,
	COLLECT_ADMISSION_DATE varchar(5),
	INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT bit,
	COLLECT_ARRIVAL_MODE varchar(5),
	INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT bit,
	COLLECT_ARRIVAL_DATE varchar(5),
	INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT bit,
	INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT bit,
	COLLECT_PHYSICIAN varchar(5),
	INCLUDE_PROVIDER_AS_QA_ELEMENT bit,
	COLLECT_DATE_TO_ROOM varchar(5),
	INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT bit,
	COLLECT_TRIAGE_ACUITY varchar(5),
	INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT bit,
	COLLECT_GENDER varchar(5),
	INCLUDE_GENDER_AS_QA_ELEMENT bit,
	COLLECT_RESIDENT_PARTICIPATED_IN_CARE varchar(5),
	INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT bit,
	COLLECT_FINANCIAL_CLASS varchar(5),
	INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT bit,
	COLLECT_DATE_OF_BIRTH varchar(5),
	INCLUDE_DOB_AS_QA_ELEMENT bit,
	COLLECT_NURSE_PRACTITIONER varchar(5),
	INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT bit,
	COLLECT_DATE_OF_SERVICE varchar(5),
	INCLUDE_DOS_AS_QA_ELEMENT bit,
	COLLECT_PATIENT_DISPOSITION varchar(5),
	INCLUDE_DISPOSITION_AS_QA_ELEMENT bit,
	COLLECT_FACILITY_ADMIN_CHART_ID varchar(5),
	INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT bit,
	COLLECT_DATE_OF_DIS varchar(5),
	INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT bit,
	COLLECT_CONDITION_OF_ACCIDENT bit,
	INCLUDE_COA_AS_QA_ELEMENT bit,
	COLLECT_CLINIC varchar(5),
	INCLUDE_CLINIC_AS_QA_ELEMENT bit,
	COLLECT_ATTESTATION_SIGNED_BY_ATTENDING varchar(5),
	INCLUDE_ATTESTATION_AS_QA_ELEMENT bit,
	COLLECT_SCRIBE bit,
	INCLUDE_SCRIBE_AS_QA_ELEMENT bit,
	COLLECT_UC_LAST_ENCOUNTER_DATE varchar(5),
	INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT bit,
	COLLECT_LAST_MENSTRUAL_PERIOD bit,
	INCLUDE_LMP_AS_QA_ELEMENT bit,
	COLLECT_PATIENT_AGE varchar(5),
	INCLUDE_AGE_AS_QA_ELEMENT bit,
	COLLECT_DATE_OF_PHYS_EVAL varchar(5),
	INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT bit,
	COLLECT_DATE_OF_TRIAGE varchar(5),
	INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT bit,
	COLLECT_MEDICAL_EXAMINER_NOTIFIED varchar(5),
	INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT bit,
	COLLECT_ORGAN_DONATION varchar(5),
	INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT bit,
	ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE bit,
	COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR varchar(5),
	INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT bit,
	COLLECT_CONSULTING_PHYSICIANS varchar(5),
	INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT bit
	)

insert into @ServiceAgreements
select
	service_agreement_ID,
	Description,
	COLLECT_MEDICAL_RECORD_NUMBER,
	INCLUDE_MRN_AS_QA_ELEMENT,
	COLLECT_ADMISSION_DATE,
	INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT,
	COLLECT_ARRIVAL_MODE,
	INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT,
	COLLECT_ARRIVAL_DATE,
	INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT,
	INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT,
	COLLECT_PHYSICIAN,
	INCLUDE_PROVIDER_AS_QA_ELEMENT,
	COLLECT_DATE_TO_ROOM,
	INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT,
	COLLECT_TRIAGE_ACUITY,
	INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT,
	COLLECT_GENDER,
	INCLUDE_GENDER_AS_QA_ELEMENT,
	COLLECT_RESIDENT_PARTICIPATED_IN_CARE,
	INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT,
	COLLECT_FINANCIAL_CLASS,
	INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT,
	COLLECT_DATE_OF_BIRTH,
	INCLUDE_DOB_AS_QA_ELEMENT,
	COLLECT_NURSE_PRACTITIONER,
	INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT,
	COLLECT_DATE_OF_SERVICE,
	INCLUDE_DOS_AS_QA_ELEMENT,
	COLLECT_PATIENT_DISPOSITION,
	INCLUDE_DISPOSITION_AS_QA_ELEMENT,
	COLLECT_FACILITY_ADMIN_CHART_ID,
	INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT,
	COLLECT_DATE_OF_DIS,
	INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT,
	COLLECT_CONDITION_OF_ACCIDENT,
	INCLUDE_COA_AS_QA_ELEMENT,
	COLLECT_CLINIC,
	INCLUDE_CLINIC_AS_QA_ELEMENT,
	COLLECT_ATTESTATION_SIGNED_BY_ATTENDING,
	INCLUDE_ATTESTATION_AS_QA_ELEMENT,
	COLLECT_SCRIBE,
	INCLUDE_SCRIBE_AS_QA_ELEMENT,
	COLLECT_UC_LAST_ENCOUNTER_DATE,
	INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT,
	COLLECT_LAST_MENSTRUAL_PERIOD,
	INCLUDE_LMP_AS_QA_ELEMENT,
	COLLECT_PATIENT_AGE,
	INCLUDE_AGE_AS_QA_ELEMENT,
	COLLECT_DATE_OF_PHYS_EVAL,
	INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT,
	COLLECT_DATE_OF_TRIAGE,
	INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT,
	COLLECT_MEDICAL_EXAMINER_NOTIFIED,
	INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT,
	COLLECT_ORGAN_DONATION,
	INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT,
	ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE,
	COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR,
	INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT,
	COLLECT_CONSULTING_PHYSICIANS,
	INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT
from Service_Agreement
where Service_agreement_ID in (select service_agreement_ID from @ChartSubset)


-- added @UserProfiles subset table to improve performance of populating @Results.  dsexton, 1/5/2025
declare @UserProfiles TABLE
(
	user_profile_ID int,
	CoderName varchar(100)
)

insert into @UserProfiles
select user_profile_ID, LAST_NAME + ', ' + FIRST_NAME as CoderName
from user_profile as up
where user_profile_ID in (select COMPLETED_BY_USER_PROFILE_ID from @ChartSubset)


-- Added five tables like #TempChartQAS_PAA to support tuning efforts by dsexton, 2/14/2022 ---------------------------------------------------------------------------------------------------------------
-- converted #temp tables to @table variables.  dsexton, 1/5/2025

declare @TempChartQAS_PAA TABLE 
(
	Chart_ID int,
	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID bigint,
	IS_CODER_CORRECT bit,
	EXCLUDE_FROM_QA_REPORT bit,
	ACTION varchar(5),
	PROCEDURE_TYPE varchar(5),
	CODER_MODIFIER varchar(150),
	AUDITOR_MODIFIER varchar(150),
	CODER_CPT_CODE varchar(20),
	AUDITOR_CPT_CODE varchar(20),
	CODER_CHARGE_MASTER_DEPT_ID int,
	AUDITOR_CHARGE_MASTER_DEPT_ID int
)

insert into @TempChartQAS_PAA
select c.Chart_ID, CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, PROCEDURE_TYPE, CODER_MODIFIER, 
		AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE, CODER_CHARGE_MASTER_DEPT_ID, AUDITOR_CHARGE_MASTER_DEPT_ID
from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION as c join @ChartSubset as t on c.chart_ID = t.chart_ID



declare @TempChartQAS_AAA TABLE
(
	Chart_ID int,
	CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION_ID int,
	IS_CODER_CORRECT bit,
	EXCLUDE_FROM_QA_REPORT bit,
	ACTION varchar(5),
	CODER_ANESTHESIA_CODE varchar(20),
	AUDITOR_ANESTHESIA_CODE varchar(20)
)

insert into @TempChartQAS_AAA
select c.Chart_ID, CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION,  
		CODER_ANESTHESIA_CODE, AUDITOR_ANESTHESIA_CODE
from CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION as c join @ChartSubset as t on c.chart_ID = t.chart_ID


declare @TempChartQAS_FLAA TABLE 
(
	Chart_ID int,
	IS_CODER_CORRECT bit,
	EXCLUDE_FROM_QA_REPORT bit,
	ACTION varchar(5),
	CODER_MODIFIER varchar(150),
	AUDITOR_MODIFIER varchar(150),
	CODER_CPT_CODE varchar(20),
	AUDITOR_CPT_CODE varchar(20)
)

insert into @TempChartQAS_FLAA
select c.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION as c join @ChartSubset as t on c.chart_ID = t.chart_ID


declare @TempChartQAS_PLAA TABLE 
(
	Chart_ID int,
	IS_CODER_CORRECT bit,
	EXCLUDE_FROM_QA_REPORT bit,
	ACTION varchar(5),
	CODER_MODIFIER varchar(150),
	AUDITOR_MODIFIER varchar(150),
	CODER_CPT_CODE varchar(20),
	AUDITOR_CPT_CODE varchar(20)
)

insert into @TempChartQAS_PLAA
select c.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION as c join @ChartSubset as t on c.chart_ID = t.chart_ID


declare @TempChartQAS_DAA TABLE 
(
	Chart_ID int,
	IS_CODER_CORRECT bit,
	EXCLUDE_FROM_QA_REPORT bit,
	ACTION varchar(5),
	IS_CHIEF_COMPLAINT_CHANGE bit,
	IS_PRIMARY_DIAGNOSIS_CHANGE bit
)

insert into @TempChartQAS_DAA 
select c.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, IS_CHIEF_COMPLAINT_CHANGE, IS_PRIMARY_DIAGNOSIS_CHANGE
from CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION as c join @ChartSubset as t on c.chart_ID = t.chart_ID

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*	-- Might want to add this index to help performance of inserts to @Mips.  dsexton, 1/5/2025
create index ix_ChargeMaster_said_cmuc_INCL on CHARGE_MASTER (service_agreement_ID, charge_master_usage_code)		-- 00:10 on trcmsqlaz05
INCLUDE (effective_date, expiration_date, cpt_code, charge_master_dept_ID)
with (online = on, resumable = on)
on FGIndex1
*/

declare @Mips table 
(
Chart_ID int, 
Chart_QA_Scorecard_Procedure_Audit_Action_ID int, 
Is_Coder_Correct bit, 
Exclude_From_QA_Report bit
)

insert into @Mips
select pr.chart_ID, pr.Chart_QA_Scorecard_Procedure_Audit_Action_ID, pr.Is_Coder_Correct, pr.Exclude_From_QA_Report
from @TempChartQAS_PAA as pr
	join @ChartSubset as c on c.chart_ID = pr.chart_ID
	Inner Join CHARGE_MASTER cm 
		on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID 
		and c.TIME_OF_SERVICE between cm.EFFECTIVE_DATE AND cm.EXPIRATION_DATE
		and cm.CHARGE_MASTER_USAGE_CODE = 9 
		and cm.CPT_CODE > ''
where 
	pr.PROCEDURE_TYPE = 'PP' 
	and pr.CODER_CPT_CODE = cm.CPT_CODE									-- criteria 1A
	and pr.CODER_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID		-- criteria 2A
	and pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID not in (Select CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID from @Mips)

insert into @Mips
select pr.chart_ID, pr.Chart_QA_Scorecard_Procedure_Audit_Action_ID, pr.Is_Coder_Correct, pr.Exclude_From_QA_Report
from @TempChartQAS_PAA as pr
	join @ChartSubset as c on c.chart_ID = pr.chart_ID
	Inner Join CHARGE_MASTER cm 
		on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID 
		and c.TIME_OF_SERVICE between cm.EFFECTIVE_DATE AND cm.EXPIRATION_DATE
		and cm.CHARGE_MASTER_USAGE_CODE = 9 
		and cm.CPT_CODE > ''
where 
	pr.PROCEDURE_TYPE = 'PP' 
	and pr.CODER_CPT_CODE = cm.CPT_CODE									-- criteria 1A
	and pr.AUDITOR_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID		-- criteria 2B
	and pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID not in (Select CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID from @Mips)

insert into @Mips
select pr.chart_ID, pr.Chart_QA_Scorecard_Procedure_Audit_Action_ID, pr.Is_Coder_Correct, pr.Exclude_From_QA_Report
from @TempChartQAS_PAA as pr
	join @ChartSubset as c on c.chart_ID = pr.chart_ID
	Inner Join CHARGE_MASTER cm 
		on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID 
		and c.TIME_OF_SERVICE between cm.EFFECTIVE_DATE AND cm.EXPIRATION_DATE
		and cm.CHARGE_MASTER_USAGE_CODE = 9 
		and cm.CPT_CODE > ''
where 
	pr.PROCEDURE_TYPE = 'PP' 
	and pr.AUDITOR_CPT_CODE = cm.CPT_CODE								-- criteria 1B
	and pr.CODER_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID		-- criteria 2A
	and pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID not in (Select CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID from @Mips)

insert into @Mips
select pr.chart_ID, pr.Chart_QA_Scorecard_Procedure_Audit_Action_ID, pr.Is_Coder_Correct, pr.Exclude_From_QA_Report
from @TempChartQAS_PAA as pr
	join @ChartSubset as c on c.chart_ID = pr.chart_ID
	Inner Join CHARGE_MASTER cm 
		on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID 
		and c.TIME_OF_SERVICE between cm.EFFECTIVE_DATE AND cm.EXPIRATION_DATE
		and cm.CHARGE_MASTER_USAGE_CODE = 9 
		and cm.CPT_CODE > ''
where 
	pr.PROCEDURE_TYPE = 'PP' 
	and pr.AUDITOR_CPT_CODE = cm.CPT_CODE								-- criteria 1B
	and pr.AUDITOR_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID		-- criteria 2B
	and pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID not in (Select CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID from @Mips)


/*	-- Might want to add this index to help performance of insert to @DI.  dsexton, 1/5/2025
create index ix_ChartQAScorecardDocumentationInequityAuditAction_ChartID_INCL	
on CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION (Chart_ID)
INCLUDE (Is_Coder_Correct, Exclude_From_QA_Report)
with (online = on, resumable = on)
on FGIndex1
*/

declare @DI table 
(
	Chart_ID int, 
	Is_Coder_Correct bit, 
	Exclude_From_QA_Report bit
)

insert into @DI
select di.chart_ID, di.Is_Coder_Correct, di.Exclude_From_QA_Report
from CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION as di
	join @ChartSubset as c on c.chart_ID = di.chart_ID


declare @Results TABLE			-- converted #temp table to @table variable.  dsexton, 1/5/2025
(
	service_agreement_id int,
	ServiceAgreementDescription	varchar(150),
	chart_id int,
	facility_chart_id varchar(80),
	APPROVED_DATE datetime,
	USER_PROFILE_ID int,
	CoderName varchar(150),
	TotalCodesCount int,
	TotalCorrectCodesCount int,
	TotalRevisedCodesCount int,
	TotalAddedCodesCount int,
	TotalDeletedCodesCount int,
	DxCorrect int,
	DxAttempted int,
	DxAdditions int,
	DxRevisions int,
	DxDeletions int,
	DxAbstract int,
	FacilityProcCorrect int,
	FacilityProcAttempted int,
	FacilityProcAdditions int,
	FacilityProcRevisions int,
	FacilityProcDeletions int,
	FacilityProcAbstract int,
	InfusionInjectionCorrect int,
	InfusionInjectionAttempted int,
	InfusionInjectionAdditions int,
	InfusionInjectionRevisions int,
	InfusionInjectionDeletions int,
	InfusionInjectionAbstract int,
	ProfProcCorrect int,
	ProfProcAttempted int,
	ProfProcAdditions int,
	ProfProcRevisions int,
	ProfProcDeletions int,
	ProfProcAbstract int,
	AnesthesiaCorrect int,
	AnesthesiaAttempted int,
	AnesthesiaAdditions int,
	AnesthesiaRevisions int,
	AnesthesiaDeletions int,
	AnesthesiaAbstract int,
	ObsHoursCorrect int,
	ObsHoursAttempted int,
	ObsHoursAdditions int,
	ObsHoursRevisions int,
	ObsHoursDeletions int,
	ObsHoursAbstract int,
	FacilityLOSCorrect int,
	FacilityLOSAttempted int,
	FacilityLOSAdditions int,
	FacilityLOSRevisions int,
	FacilityLOSDeletions int,
	FacilityLOSAbstract int,
	PhysicianLOSCorrect int,
	PhysicianLOSAttempted int,
	PhysicianLOSAdditions int,
	PhysicianLOSRevisions int,
	PhysicianLOSDeletions int,
	PhysicianLOSAbstract int,
	DxChiefComplaintChanges int,
	DxPrimaryDxChanges int,
	DxChartsSubmitted int,
	InfInjChanges int,
	InfInjSubmitted int,
	ObsHoursChanges int,
	ObsHoursSubmitted int,
	ProcModifierChanges int,
	FacilityLOSModifierChanges int,
	PhysicianLOSModifierChanges int,
	DemographicChanges int,
	MIPSChanges int,
	MIPSSubmitted int,
	DocumentationDeficiencyChanges int,
	DocumentationDeficiencySubmitted int
)

-- modified the method of populating @Results since this is the section that still degrades in performance periodically.  dsexton, 1/9/2025
insert into @Results (Chart_ID, service_agreement_ID, ServiceAgreementDescription, facility_chart_ID, approved_date, user_profile_ID, CoderName)
select c.chart_ID, c.service_agreement_ID, sa.description, c.facility_chart_ID, c.approved_date, up.user_profile_ID, up.CoderName
from @ChartSubset c 
	LEFT OUTER JOIN @UserProfiles as up on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
	LEFT OUTER JOIN @ServiceAgreements as sa on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID

-- this performs much better (in both reads and duration) than using separate UPDATE queries for each column		-- dsexton, 1/9/2025
update t1
set 
	-- DAA counts
	t1.DxAttempted = isnull(t2.DxAttempted, 0),
	t1.DxCorrect = isnull(t3.DxCorrect, 0),
	t1.DxAdditions = isnull(t4.DxAdditions, 0),
	t1.DxRevisions = isnull(t5.DxRevisions, 0),
	t1.DxDeletions = isnull(t6.DxDeletions, 0),
	t1.DxAbstract = isnull(t7.DxAbstract, 0),
	t1.DxChiefComplaintChanges = case when isnull(t8.DxChiefComplaintChanges, 0) > 0 then 1 else 0 end,
	t1.DxPrimaryDxChanges = case when isnull(t9.DxPrimaryDxChanges, 0) > 0 then 1 else 0 end,
	t1.DxChartsSubmitted = case when isnull(t10.DxChartsSubmitted, 0) > 0 then 1 else 0 end,		
	
	-- AAA counts
	t1.AnesthesiaAttempted = isnull(t11.AnesthesiaAttempted, 0),
	t1.AnesthesiaCorrect = isnull(t12.AnesthesiaCorrect, 0),
	t1.AnesthesiaAdditions = isnull(t13.AnesthesiaAdditions, 0),
	t1.AnesthesiaRevisions = isnull(t14.AnesthesiaRevisions, 0),
	t1.AnesthesiaDeletions = isnull(t15.AnesthesiaDeletions, 0),
	t1.AnesthesiaAbstract = isnull(t16.AnesthesiaAbstract, 0),

	-- FLAA counts	
	t1.FacilityLOSAttempted = isnull(t17.FacilityLOSAttempted, 0),
	t1.FacilityLOSCorrect = isnull(t18.FacilityLOSCorrect, 0),
	t1.FacilityLOSAdditions = isnull(t19.FacilityLOSAdditions, 0),
	t1.FacilityLOSRevisions = isnull(t20.FacilityLOSRevisions, 0),
	t1.FacilityLOSDeletions = isnull(t21.FacilityLOSDeletions, 0),
	t1.FacilityLOSAbstract = isnull(t22.FacilityLOSAbstract, 0),
	t1.FacilityLOSModifierChanges = case when isnull(t23.FacilityLOSModifierChanges, 0) > 0 then 1 else 0 end,

	-- PLAA counts	
	t1.PhysicianLOSAttempted = isnull(t24.PhysicianLOSAttempted, 0),
	t1.PhysicianLOSCorrect = isnull(t25.PhysicianLOSCorrect, 0),
	t1.PhysicianLOSAdditions = isnull(t26.PhysicianLOSAdditions, 0),
	t1.PhysicianLOSRevisions = isnull(t27.PhysicianLOSRevisions, 0),
	t1.PhysicianLOSDeletions = isnull(t28.PhysicianLOSDeletions, 0),
	t1.PhysicianLOSAbstract = isnull(t29.PhysicianLOSAbstract, 0),
	t1.PhysicianLOSModifierChanges = case when isnull(t30.PhysicianLOSModifierChanges, 0) > 0 then 1 else 0 end

from
	@Results as t1

	-- PLAA joins
	left join (select chart_ID, PhysicianLOSAttempted = count(*) from @TempChartQAS_PLAA group by chart_ID) as t24 on t1.chart_ID = t24.chart_ID
	left join (select chart_ID, PhysicianLOSCorrect = count(*) from @TempChartQAS_PLAA where is_coder_correct = 1 or exclude_from_QA_Report = 1 group by chart_ID) as t25 on t1.chart_ID = t25.chart_ID
	left join (select chart_ID, PhysicianLOSAdditions = count(*) from @TempChartQAS_PLAA where ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t26 on t1.chart_ID = t26.chart_ID
	left join (select chart_ID, PhysicianLOSRevisions = count(*) from @TempChartQAS_PLAA where ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t27 on t1.chart_ID = t27.chart_ID
	left join (select chart_ID, PhysicianLOSDeletions = count(*) from @TempChartQAS_PLAA where ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t28 on t1.chart_ID = t28.chart_ID
	left join (select chart_ID, PhysicianLOSAbstract = count(*) from @TempChartQAS_PLAA where ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t29 on t1.chart_ID = t29.chart_ID
	left join (select chart_ID, PhysicianLOSModifierChanges = count(*) from @TempChartQAS_PLAA where CODER_MODIFIER <> AUDITOR_MODIFIER and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t30 on t1.chart_ID = t30.chart_ID

	-- FLAA joins
	left join (select chart_ID, FacilityLOSAttempted = count(*) from @TempChartQAS_FLAA group by chart_ID) as t17 on t1.chart_ID = t17.chart_ID
	left join (select chart_ID, FacilityLOSCorrect = count(*) from @TempChartQAS_FLAA where is_coder_correct = 1 or exclude_from_QA_Report = 1 group by chart_ID) as t18 on t1.chart_ID = t18.chart_ID
	left join (select chart_ID, FacilityLOSAdditions = count(*) from @TempChartQAS_FLAA where ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t19 on t1.chart_ID = t19.chart_ID
	left join (select chart_ID, FacilityLOSRevisions = count(*) from @TempChartQAS_FLAA where ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t20 on t1.chart_ID = t20.chart_ID
	left join (select chart_ID, FacilityLOSDeletions = count(*) from @TempChartQAS_FLAA where ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t21 on t1.chart_ID = t21.chart_ID
	left join (select chart_ID, FacilityLOSAbstract = count(*) from @TempChartQAS_FLAA where ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t22 on t1.chart_ID = t22.chart_ID
	left join (select chart_ID, FacilityLOSModifierChanges = count(*) from @TempChartQAS_FLAA where CODER_MODIFIER <> AUDITOR_MODIFIER and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t23 on t1.chart_ID = t23.chart_ID

	-- DAA joins
	left join (select chart_ID, DxAttempted = count(*) from @TempChartQAS_DAA group by chart_ID) as t2 on t1.chart_ID = t2.chart_ID
	left join (select chart_ID, DxCorrect = count(*) from @TempChartQAS_DAA where is_coder_correct = 1 or exclude_from_QA_Report = 1 group by chart_ID) as t3 on t1.chart_ID = t3.chart_ID
	left join (select chart_ID, DxAdditions = count(*) from @TempChartQAS_DAA where ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t4 on t1.chart_ID = t4.chart_ID
	left join (select chart_ID, DxRevisions = count(*) from @TempChartQAS_DAA where ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t5 on t1.chart_ID = t5.chart_ID
	left join (select chart_ID, DxDeletions = count(*) from @TempChartQAS_DAA where ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t6 on t1.chart_ID = t6.chart_ID
	left join (select chart_ID, DxAbstract = count(*) from @TempChartQAS_DAA where ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t7 on t1.chart_ID = t7.chart_ID
	left join (select chart_ID, DxChiefComplaintChanges = count(*) from @TempChartQAS_DAA where IS_CHIEF_COMPLAINT_CHANGE = 1 and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t8 on t1.chart_ID = t8.chart_ID
	left join (select chart_ID, DxPrimaryDxChanges = count(*) from @TempChartQAS_DAA where IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t9 on t1.chart_ID = t9.chart_ID
	left join (select chart_ID, DxChartsSubmitted = count(*) from @TempChartQAS_DAA group by chart_ID) as t10 on t1.chart_ID = t10.chart_ID

	-- AAA joins
	left join (select chart_ID, AnesthesiaAttempted = count(*) from @TempChartQAS_AAA group by chart_ID) as t11 on t1.chart_ID = t11.chart_ID
	left join (select chart_ID, AnesthesiaCorrect = count(*) from @TempChartQAS_AAA where is_coder_correct = 1 or exclude_from_QA_Report = 1 group by chart_ID) as t12 on t1.chart_ID = t12.chart_ID
	left join (select chart_ID, AnesthesiaAdditions = count(*) from @TempChartQAS_AAA where ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t13 on t1.chart_ID = t13.chart_ID
	left join (select chart_ID, AnesthesiaRevisions = count(*) from @TempChartQAS_AAA where ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t14 on t1.chart_ID = t14.chart_ID
	left join (select chart_ID, AnesthesiaDeletions = count(*) from @TempChartQAS_AAA where ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t15 on t1.chart_ID = t15.chart_ID
	left join (select chart_ID, AnesthesiaAbstract = count(*) from @TempChartQAS_AAA where ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t16 on t1.chart_ID = t16.chart_ID

-- a separate UPDATE is used here for columns populated from @TempChartQAS_PAA since joins to this table variable seem to be the root cause of periodic performance issues.  dsexton, 1/9/2025
update t1
set 
	-- PAA_TypeFP counts	
	t1.FacilityProcAttempted = isnull(t31.FacilityProcAttempted, 0),
	t1.FacilityProcCorrect = isnull(t32.FacilityProcCorrect, 0),
	t1.FacilityProcAdditions = isnull(t33.FacilityProcAdditions, 0),
	t1.FacilityProcRevisions = isnull(t34.FacilityProcRevisions, 0),
	t1.FacilityProcDeletions = isnull(t35.FacilityProcDeletions, 0),
	t1.FacilityProcAbstract = isnull(t36.FacilityProcAbstract, 0),

	-- PAA_TypeCI counts	
	t1.InfusionInjectionAttempted = isnull(t37.InfusionInjectionAttempted, 0),
	t1.InfusionInjectionCorrect = isnull(t38.InfusionInjectionCorrect, 0),
	t1.InfusionInjectionAdditions = isnull(t39.InfusionInjectionAdditions, 0),
	t1.InfusionInjectionRevisions = isnull(t40.InfusionInjectionRevisions, 0),
	t1.InfusionInjectionDeletions = isnull(t41.InfusionInjectionDeletions, 0),
	t1.InfusionInjectionAbstract = isnull(t42.InfusionInjectionAbstract, 0),
	t1.InfInjChanges = case when isnull(t57.InfInjChanges, 0) > 0 then 1 else 0 end,
	t1.InfInjSubmitted = case when isnull(t58.InfInjSubmitted, 0) > 0 then 1 else 0 end,

	-- PAA_TypePP counts	
	t1.ProfProcAttempted = isnull(t43.ProfProcAttempted, 0),
	t1.ProfProcCorrect = isnull(t44.ProfProcCorrect, 0),
	t1.ProfProcAdditions = isnull(t45.ProfProcAdditions, 0),
	t1.ProfProcRevisions = isnull(t46.ProfProcRevisions, 0),
	t1.ProfProcDeletions = isnull(t47.ProfProcDeletions, 0),
	t1.ProfProcAbstract = isnull(t48.ProfProcAbstract, 0),

	-- PAA_TypeOB counts	
	t1.ObsHoursAttempted = isnull(t49.ObsHoursAttempted, 0),
	t1.ObsHoursCorrect = isnull(t50.ObsHoursCorrect, 0),
	t1.ObsHoursAdditions = isnull(t51.ObsHoursAdditions, 0),
	t1.ObsHoursRevisions = isnull(t52.ObsHoursRevisions, 0),
	t1.ObsHoursDeletions = isnull(t53.ObsHoursDeletions, 0),
	t1.ObsHoursAbstract = isnull(t54.ObsHoursAbstract, 0),
	t1.ObsHoursChanges = case when isnull(t55.ObsHoursChanges, 0) > 0 then 1 else 0 end,
	t1.ObsHoursSubmitted = case when isnull(t56.ObsHoursSubmitted, 0) > 0 then 1 else 0 end,

	t1.ProcModifierChanges = case when isnull(t59.ProcModifierChanges, 0) > 0 then 1 else 0 end

from
	@Results as t1

	left join (select chart_ID, ProcModifierChanges = count(*) from @TempChartQAS_PAA where CODER_MODIFIER <> AUDITOR_MODIFIER and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t59 on t1.chart_ID = t59.chart_ID

	-- PAA_TypeOB joins
	left join (select chart_ID, ObsHoursAttempted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' group by chart_ID) as t49 on t1.chart_ID = t49.chart_ID
	left join (select chart_ID, ObsHoursCorrect = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and (is_coder_correct = 1 or exclude_from_QA_Report = 1) group by chart_ID) as t50 on t1.chart_ID = t50.chart_ID
	left join (select chart_ID, ObsHoursAdditions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t51 on t1.chart_ID = t51.chart_ID
	left join (select chart_ID, ObsHoursRevisions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t52 on t1.chart_ID = t52.chart_ID
	left join (select chart_ID, ObsHoursDeletions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t53 on t1.chart_ID = t53.chart_ID
	left join (select chart_ID, ObsHoursAbstract = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t54 on t1.chart_ID = t54.chart_ID
	left join (select chart_ID, ObsHoursChanges = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and IS_CODER_CORRECT = 0 and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t55 on t1.chart_ID = t55.chart_ID
	left join (select chart_ID, ObsHoursSubmitted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' group by chart_ID) as t56 on t1.chart_ID = t56.chart_ID

	-- PAA_TypePP joins
	left join (select chart_ID, ProfProcAttempted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' group by chart_ID) as t43 on t1.chart_ID = t43.chart_ID
	left join (select chart_ID, ProfProcCorrect = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and (is_coder_correct = 1 or exclude_from_QA_Report = 1) group by chart_ID) as t44 on t1.chart_ID = t44.chart_ID
	left join (select chart_ID, ProfProcAdditions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t45 on t1.chart_ID = t45.chart_ID
	left join (select chart_ID, ProfProcRevisions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t46 on t1.chart_ID = t46.chart_ID
	left join (select chart_ID, ProfProcDeletions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t47 on t1.chart_ID = t47.chart_ID
	left join (select chart_ID, ProfProcAbstract = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t48 on t1.chart_ID = t48.chart_ID

	-- PAA_TypeCI joins
	left join (select chart_ID, InfusionInjectionAttempted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' group by chart_ID) as t37 on t1.chart_ID = t37.chart_ID
	left join (select chart_ID, InfusionInjectionCorrect = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and (is_coder_correct = 1 or exclude_from_QA_Report = 1) group by chart_ID) as t38 on t1.chart_ID = t38.chart_ID
	left join (select chart_ID, InfusionInjectionAdditions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t39 on t1.chart_ID = t39.chart_ID
	left join (select chart_ID, InfusionInjectionRevisions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t40 on t1.chart_ID = t40.chart_ID
	left join (select chart_ID, InfusionInjectionDeletions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t41 on t1.chart_ID = t41.chart_ID
	left join (select chart_ID, InfusionInjectionAbstract = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t42 on t1.chart_ID = t42.chart_ID
	left join (select chart_ID, InfInjChanges = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and IS_CODER_CORRECT = 0 and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t57 on t1.chart_ID = t57.chart_ID
	left join (select chart_ID, InfInjSubmitted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' group by chart_ID) as t58 on t1.chart_ID = t58.chart_ID

	-- PAA_TypeFP joins
	left join (select chart_ID, FacilityProcAttempted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' group by chart_ID) as t31 on t1.chart_ID = t31.chart_ID
	left join (select chart_ID, FacilityProcCorrect = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and (is_coder_correct = 1 or exclude_from_QA_Report = 1) group by chart_ID) as t32 on t1.chart_ID = t32.chart_ID
	left join (select chart_ID, FacilityProcAdditions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t33 on t1.chart_ID = t33.chart_ID
	left join (select chart_ID, FacilityProcRevisions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t34 on t1.chart_ID = t34.chart_ID
	left join (select chart_ID, FacilityProcDeletions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t35 on t1.chart_ID = t35.chart_ID
	left join (select chart_ID, FacilityProcAbstract = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t36 on t1.chart_ID = t36.chart_ID

-- The TOTALS columns are now populated from existing values in the table rather than the old inefficient method which summed the results of queries duplicated from above.  dsexton, 1/9/2025
update @Results
set 	
	TotalCodesCount = DxAttempted + AnesthesiaAttempted + FacilityLOSAttempted + PhysicianLOSAttempted + FacilityProcAttempted + InfusionInjectionAttempted + ProfProcAttempted + ObsHoursAttempted,
	TotalCorrectCodesCount = DxCorrect + AnesthesiaCorrect + FacilityLOSCorrect + PhysicianLOSCorrect + FacilityProcCorrect + InfusionInjectionCorrect + ProfProcCorrect + ObsHoursCorrect,
	TotalRevisedCodesCount = DxRevisions + AnesthesiaRevisions + FacilityLOSRevisions + PhysicianLOSRevisions + FacilityProcRevisions + InfusionInjectionRevisions + ProfProcRevisions + ObsHoursRevisions,
	TotalAddedCodesCount = DxAdditions + AnesthesiaAdditions + FacilityLOSAdditions + PhysicianLOSAdditions + FacilityProcAdditions + InfusionInjectionAdditions + ProfProcAdditions + ObsHoursAdditions,
	TotalDeletedCodesCount = DxDeletions + AnesthesiaDeletions + FacilityLOSDeletions + PhysicianLOSDeletions + FacilityProcDeletions + InfusionInjectionDeletions + ProfProcDeletions + ObsHoursDeletions


-- tuning which uses @Mips in the four UPDATE queries below.  dsexton, 1/5/2025
update t1
set t1.MipsChanges = isnull(t2.MipsChanges, 0)
from @Results as t1
	left join (select chart_ID, MipsChanges = count(*) from @Mips where Is_Coder_Correct = 0 and Exclude_From_QA_Report <> 1 group by Chart_ID) as t2 
	on t1.chart_ID = t2.chart_ID

update t1
set t1.MipsSubmitted = isnull(t2.MipsSubmitted, 0)
from @Results as t1
	left join (select chart_ID, MipsSubmitted = count(*) from @Mips group by Chart_ID) as t2 
	on t1.chart_ID = t2.chart_ID


update t1
set t1.DocumentationDeficiencyChanges = isnull(t2.DocumentationDeficiencyChanges, 0)
from @Results as t1
	left join (select chart_ID, DocumentationDeficiencyChanges = count(*) from @DI where Is_Coder_Correct = 0 and Exclude_From_QA_Report <> 1 group by Chart_ID) as t2 
	on t1.chart_ID = t2.chart_ID

update t1
set t1.DocumentationDeficiencySubmitted = isnull(t2.DocumentationDeficiencySubmitted, 0)
from @Results as t1
	left join (select chart_ID, DocumentationDeficiencySubmitted = count(*) from @DI group by Chart_ID) as t2 
	on t1.chart_ID = t2.chart_ID
                   

------------------------------------------------------------------------------------------------------------------------------------------
-- Beginning of section that directly incorporates the query from function dbo.GetChartDemographicAuditActions.  dsexton, 2/14/2022


declare @ChartTable TABLE		-- converted from #temp table to @table variable.  dsexton, 1/5/2025
(
	Chart_ID int,
	Medical_Record_Num varchar(40),
	Service_Agreement_ID int,
	ADMISSION_DATE_TIME datetime,
	SERVICE_AGREEMENT_ARRIVAL_MODE_ID int,
	ARRIVAL_DATE_TIME datetime,
	PATIENT_DISPOSITION_MAP_ID int,
	PHYSICIAN_ID int,
	TIME_TO_ROOM datetime,
	SERVICE_AGREEMENT_TRIAGE_ACUITY_ID int,
	GENDER varchar(5),
	RESIDENT_PARTICIPATED_IN_CARE bit,
	FINANCIAL_CLASS_CD varchar(20),
	PATIENT_DOB datetime,
	NURSE_PRACTITIONER_ID int,
	Time_of_Service datetime,
	PATIENT_DISPOSITION_ID int,
	FACILITY_ADMIN_CHART_ID varchar(40),
	TIME_OF_DIS datetime,
	CONDITION_OF_ACCIDENT_ID int,
	CLINIC_ID varchar(20),
	ATTESTATION_SIGNED_BY_ATTENDING bit,
	SCRIBE_ID int,
	LAST_ENCOUNTER_DATE datetime,
	LAST_MENSTRUAL_PERIOD datetime,
	PATIENT_AGE int,
	TIME_OF_PHYS_EVAL datetime,
	TIME_OF_TRIAGE datetime,
	MEDICAL_EXAMINER_NOTIFIED bit,
	ORGAN_DONATION bit,
	USE_TIME_BASED_CHARGE_CAPTURE bit,
	SEEN_IN_ED_WITHIN_48_HOURS_OF_OR bit
)

insert into @ChartTable
Select 
	Chart_ID, 
	Medical_Record_Num,
	Service_Agreement_ID,
	ADMISSION_DATE_TIME,
	SERVICE_AGREEMENT_ARRIVAL_MODE_ID,
	ARRIVAL_DATE_TIME,
	PATIENT_DISPOSITION_MAP_ID,
	PHYSICIAN_ID,
	TIME_TO_ROOM,
	SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, 
	GENDER, 
	RESIDENT_PARTICIPATED_IN_CARE, 
	FINANCIAL_CLASS_CD, 
	PATIENT_DOB, 
	NURSE_PRACTITIONER_ID, 
	Time_of_Service, 
	PATIENT_DISPOSITION_ID,
	FACILITY_ADMIN_CHART_ID, 
	TIME_OF_DIS, 
	CONDITION_OF_ACCIDENT_ID, 
	CLINIC_ID, 
	ATTESTATION_SIGNED_BY_ATTENDING, 
	SCRIBE_ID, 
	LAST_ENCOUNTER_DATE, 
	LAST_MENSTRUAL_PERIOD,
	PATIENT_AGE, 
	TIME_OF_PHYS_EVAL, 
	TIME_OF_TRIAGE, 
	MEDICAL_EXAMINER_NOTIFIED, 
	ORGAN_DONATION, 
	USE_TIME_BASED_CHARGE_CAPTURE, 
	SEEN_IN_ED_WITHIN_48_HOURS_OF_OR 
from CHART with(nolock) 
where chart_ID in (Select Chart_ID from @ChartSubset)


declare @ChartDemoHX TABLE			-- converted from #temp table to @table variable.  dsexton, 1/5/2025
(
	Chart_ID int,
	Medical_Record_Num varchar(40),
	Admission_Date_Time datetime,
	SERVICE_AGREEMENT_ARRIVAL_MODE_ID int,
	Arrival_Date_Time datetime,
	PATIENT_DISPOSITION_MAP_ID int,
	PHYSICIAN_ID int,
	TIME_TO_ROOM datetime,
	SERVICE_AGREEMENT_TRIAGE_ACUITY_ID int,
	GENDER varchar(5),
	RESIDENT_PARTICIPATED_IN_CARE bit,
	FINANCIAL_CLASS_CD varchar(20),
	PATIENT_DOB datetime,
	NURSE_PRACTITIONER_ID int,
	Time_of_Service datetime,
	PATIENT_DISPOSITION_ID int,
	FACILITY_ADMIN_CHART_ID varchar(40),
	TIME_OF_DIS datetime,
	CONDITION_OF_ACCIDENT_ID int,
	CLINIC_ID varchar(20),
	ATTESTATION_SIGNED_BY_ATTENDING bit,
	SCRIBE_ID int,
	LAST_ENCOUNTER_DATE datetime,
	LAST_MENSTRUAL_PERIOD datetime,
	PATIENT_AGE int,
	TIME_OF_PHYS_EVAL datetime,
	TIME_OF_TRIAGE datetime,
	MEDICAL_EXAMINER_NOTIFIED bit,
	ORGAN_DONATION bit,
	USE_TIME_BASED_CHARGE_CAPTURE bit,
	SEEN_IN_ED_WITHIN_48_HOURS_OF_OR bit
)

insert into @ChartDemoHX
select Chart_ID, Medical_Record_Num, Admission_Date_Time, SERVICE_AGREEMENT_ARRIVAL_MODE_ID, Arrival_Date_Time, PATIENT_DISPOSITION_MAP_ID, PHYSICIAN_ID, TIME_TO_ROOM,
	SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, GENDER, RESIDENT_PARTICIPATED_IN_CARE, FINANCIAL_CLASS_CD, PATIENT_DOB, NURSE_PRACTITIONER_ID, Time_of_Service, PATIENT_DISPOSITION_ID,
	FACILITY_ADMIN_CHART_ID, TIME_OF_DIS, CONDITION_OF_ACCIDENT_ID, CLINIC_ID, ATTESTATION_SIGNED_BY_ATTENDING, SCRIBE_ID, LAST_ENCOUNTER_DATE, LAST_MENSTRUAL_PERIOD,
	PATIENT_AGE, TIME_OF_PHYS_EVAL, TIME_OF_TRIAGE, MEDICAL_EXAMINER_NOTIFIED, ORGAN_DONATION, USE_TIME_BASED_CHARGE_CAPTURE, SEEN_IN_ED_WITHIN_48_HOURS_OF_OR 
from CHART_DEMOGRAPHIC_HISTORY with(nolock)
where Chart_ID in (Select Chart_ID from @ChartSubset)


declare @DemoAuditChartIDs TABLE (Chart_ID int)			-- converted from #temp table to @table variable.  dsexton, 1/5/2025

insert into @DemoAuditChartIDs

		-- Add the SELECT statement with parameter references here
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
			AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM	

/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
			AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM	
*/
		UNION
	--insert into @DemoAuditChartIDs		-- kept UNION statements for inserts that involve joins only to @Table variables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0	
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0
*/		

		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0		
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0
*/		
		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0
*/		
		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')
				
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')
*/		
		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0
*/		
		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0

/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0
*/

		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')

/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')
*/		

		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0
*/	

		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')
*/
		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0
*/		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
			AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
			AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0
*/
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)
*/		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0
		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0
*/		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0
      		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0
*/		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')
      		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')
*/		
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')
      		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')
*/		
		---- Time Based Physician LOS 
		UNION 
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE, 0) <> 0
			AND ISNULL(c.USE_TIME_BASED_CHARGE_CAPTURE, '') <> ISNULL(cdh.USE_TIME_BASED_CHARGE_CAPTURE, '')
      		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE, 0) <> 0
			AND ISNULL(c.USE_TIME_BASED_CHARGE_CAPTURE, '') <> ISNULL(cdh.USE_TIME_BASED_CHARGE_CAPTURE, '')
*/
		UNION
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')
      		
/*		UNION	-- unnecessary since this is identical to the query above.  dsexton, 1/5/2025
		
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE 
			ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')
*/

		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
		WHERE 
			ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
		WHERE 
			ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)

		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON c.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID		
		WHERE 
			ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_MAP_ID, - 1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, - 1)
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025		
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON cdh.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
		WHERE 
			ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_MAP_ID, - 1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, - 1)
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON c.PHYSICIAN_ID = fp.FACILITY_PROF_ID			--here
		WHERE 
			ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON cdh.PHYSICIAN_ID = fp.FACILITY_PROF_ID
		WHERE 
			ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)

		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON c.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
		WHERE 
			ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)

		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON cdh.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
		WHERE 
			ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)

		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON c.SCRIBE_ID = s.FACILITY_PROF_ID
		WHERE 
			ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
			AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON cdh.SCRIBE_ID = s.FACILITY_PROF_ID
		WHERE 
			ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
			AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')


		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN CHART_CONSULTING_PHYSICIAN ccp WITH (NOLOCK) ON c.CHART_ID = ccp.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = ccp.FACILITY_PROFESSIONAL_ID
		WHERE 
			ISNULL(sa.COLLECT_CONSULTING_PHYSICIANS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT, 1) = 1
			AND NOT EXISTS (
							select *
							from CHART_CONSULTING_PHYSICIAN_HISTORY h with (nolock)
							where h.CHART_ID = ccp.CHART_ID							
							and h.FACILITY_PROFESSIONAL_ID = ccp.FACILITY_PROFESSIONAL_ID
      )

	  --UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
	  SELECT c.Chart_ID		-- joins are different than above
		FROM @ChartTable c 
		INNER JOIN CHART_CONSULTING_PHYSICIAN_HISTORY ccph WITH (NOLOCK) ON c.CHART_ID = ccph.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = ccph.FACILITY_PROFESSIONAL_ID
		WHERE 
			ISNULL(sa.COLLECT_CONSULTING_PHYSICIANS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT, 1) = 1
			AND NOT EXISTS (
							select *
							from [dbo].[CHART_CONSULTING_PHYSICIAN] with (nolock)
							where CHART_ID = ccph.CHART_ID
			and FACILITY_PROFESSIONAL_ID = ccph.FACILITY_PROFESSIONAL_ID
			)


		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE 
			ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
			AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
			AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE 
			ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
			AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
			AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)

		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- has additional join compared to above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE 
			ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')


		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND ffc.FINANCIAL_CLASS_CD = cdh.FINANCIAL_CLASS_CD
		WHERE 
			ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
		WHERE 
			ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')

		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		--INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID		-- can't see a need for this join, and it generates more than 3K LReads. dsexton, 1/5/2025
		WHERE 
			ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')
      		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		--INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = cdh.PATIENT_DISPOSITION_ID		-- can't see a need for this join, and it generates more than 3K LReads. dsexton, 1/5/2025
		WHERE 
			ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')

		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND coa.CONDITION_OF_ACCIDENT_ID = c.CONDITION_OF_ACCIDENT_ID
		WHERE 
			ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
			AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND coa.CONDITION_OF_ACCIDENT_ID = cdh.CONDITION_OF_ACCIDENT_ID
		WHERE 
			ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
			AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND cl.CLINIC_ID = c.CLINIC_ID
		WHERE 
			ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')
		
		--UNION
	insert into @DemoAuditChartIDs		-- replaced UNION with a separate INSERT to avoid transactional blocking behavior on permanent tables.  dsexton, 1/5/2025
		SELECT c.Chart_ID		-- join is different than above
		FROM @ChartTable c 
		INNER JOIN @ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN @ServiceAgreements sa  ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND cl.CLINIC_ID = cdh.CLINIC_ID
		WHERE 
			ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')


update @Results set DemographicChanges = 1 where chart_ID in (Select Chart_ID from @DemoAuditChartIDs)
update @Results set DemographicChanges = 0 where DemographicChanges is null

select * from @Results

-- end of section to replace the call to function dbo.GetChartDemographicAuditActions.  dsexton, 2/14/2022
---------------------------------------------------------------------------------------------------------------------------


END               

GO
