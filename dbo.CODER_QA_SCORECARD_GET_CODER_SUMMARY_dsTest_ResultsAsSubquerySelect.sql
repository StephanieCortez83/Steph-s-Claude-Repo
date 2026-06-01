SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CODER_QA_SCORECARD_GET_CODER_SUMMARY_dsTest_ResultsAsSubquerySelect] 
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


declare @Results TABLE			-- converted #temp table to @table variable.  dsexton, 1/5/2025
(
	--service_agreement_id int,
	--ServiceAgreementDescription	varchar(150),
	chart_id int,
	--facility_chart_id varchar(80),
	--APPROVED_DATE datetime,
	--USER_PROFILE_ID int,
	--CoderName varchar(150),
	--TotalCodesCount int,
	--TotalCorrectCodesCount int,
	--TotalRevisedCodesCount int,
	--TotalAddedCodesCount int,
	--TotalDeletedCodesCount int,
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


-- All subqueries below were modified to reference the new temp tables (above) which contain small subsets of data from the base tables.  dsexton, 2/14/2022
-- Tried alternative methods to populating all the COUNT columns in @Results, but did not find a method that performs better.  dsexton, 1/5/2025

insert into @Results 
(
Chart_ID,
	--TotalCodesCount,
	--TotalCorrectCodesCount,
	--TotalRevisedCodesCount,
	--TotalAddedCodesCount,
	--TotalDeletedCodesCount,
	DxCorrect,
	DxAttempted,
	DxAdditions,
	DxRevisions,
	DxDeletions,
	DxAbstract,
	FacilityProcCorrect,
	FacilityProcAttempted,
	FacilityProcAdditions,
	FacilityProcRevisions,
	FacilityProcDeletions,
	FacilityProcAbstract,
	InfusionInjectionCorrect,
	InfusionInjectionAttempted,
	InfusionInjectionAdditions,
	InfusionInjectionRevisions,
	InfusionInjectionDeletions,
	InfusionInjectionAbstract,
	ProfProcCorrect,
	ProfProcAttempted,
	ProfProcAdditions,
	ProfProcRevisions,
	ProfProcDeletions,
	ProfProcAbstract,
	AnesthesiaCorrect,
	AnesthesiaAttempted,
	AnesthesiaAdditions,
	AnesthesiaRevisions,
	AnesthesiaDeletions,
	AnesthesiaAbstract,
	ObsHoursCorrect,
	ObsHoursAttempted,
	ObsHoursAdditions,
	ObsHoursRevisions,
	ObsHoursDeletions,
	ObsHoursAbstract,
	FacilityLOSCorrect,
	FacilityLOSAttempted,
	FacilityLOSAdditions,
	FacilityLOSRevisions,
	FacilityLOSDeletions,
	FacilityLOSAbstract,
	PhysicianLOSCorrect,
	PhysicianLOSAttempted,
	PhysicianLOSAdditions,
	PhysicianLOSRevisions,
	PhysicianLOSDeletions,
	PhysicianLOSAbstract,
	DxChiefComplaintChanges,
	DxPrimaryDxChanges,
	DxChartsSubmitted,
	InfInjChanges,
	InfInjSubmitted,
	ObsHoursChanges,
	ObsHoursSubmitted,
	ProcModifierChanges,
	FacilityLOSModifierChanges,
	PhysicianLOSModifierChanges,
	DemographicChanges,
	MIPSChanges,
	MIPSSubmitted,
	DocumentationDeficiencyChanges,
	DocumentationDeficiencySubmitted
)
SELECT		
	c.chart_ID,

/*
			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID)
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from @TempChartQAS_AAA ac   where c.CHART_ID = ac.CHART_ID)
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID)  
			+ (select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID) 
			+ (select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,

			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND (pr.IS_CODER_CORRECT = 1 OR pr.EXCLUDE_FROM_QA_REPORT = 1))
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from @TempChartQAS_AAA ac   where c.CHART_ID = ac.CHART_ID  AND (ac.IS_CODER_CORRECT = 1 OR ac.EXCLUDE_FROM_QA_REPORT = 1))
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR flos.EXCLUDE_FROM_QA_REPORT = 1))  
			+ (select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 or PLOS.EXCLUDE_FROM_QA_REPORT = 1)) 
			+ (select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,

			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0)
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from @TempChartQAS_AAA ac   where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND ac.EXCLUDE_FROM_QA_REPORT = 0)
-- EndChgs anesthesia coding ----------------- 
			+ (select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,

			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 ) 
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from @TempChartQAS_AAA ac   where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND ac.EXCLUDE_FROM_QA_REPORT = 0) 
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,

			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from @TempChartQAS_AAA ac   where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND ac.EXCLUDE_FROM_QA_REPORT = 0)  
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount,
*/

			(select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,
			(select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID) as DxAttempted,
			(select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
			(select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
			(select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
			(select count(*) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAbstract,

			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,

			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionDeletions,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAbstract,

			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted, 
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions, 							 
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions, 							 
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions, 							 
			(select count(*) from @TempChartQAS_PAA pr  where c.Chart_ID = pr.Chart_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract,

-- StartChgs anesthesia coding ---------------
			(select count(*) from @TempChartQAS_AAA ac  where c.CHART_ID = ac.CHART_ID AND (ac.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as AnesthesiaCorrect,
			(select count(*) from @TempChartQAS_AAA ac  where c.CHART_ID = ac.CHART_ID) as AnesthesiaAttempted, 
			(select count(*) from @TempChartQAS_AAA ac  where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAdditions, 							 
			(select count(*) from @TempChartQAS_AAA ac  where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaRevisions, 							 
			(select count(*) from @TempChartQAS_AAA ac  where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaDeletions, 							 
			(select count(*) from @TempChartQAS_AAA ac  where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAbstract, 		
 -- EndChgs anesthesia coding -----------------		

			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted, 
			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions, 							 
			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions, 							 
			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions, 							 
			(select count(*) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAbstract, 			
									 
			(select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID AND (flos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,
			(select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted, 
			(select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID  AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
			(select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID  AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
			(select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID  AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
			(select count(*) from @TempChartQAS_FLAA flos   where c.CHART_ID = flos.CHART_ID  AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,		
										 					
			(select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect,
			(select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted, 	
			(select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from @TempChartQAS_PLAA plos   where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,

			(select count(DISTINCT dx.CHART_ID) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
			(select count(DISTINCT dx.CHART_ID) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,	
			(select count(DISTINCT dx.CHART_ID) from @TempChartQAS_DAA dx  where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,	

			(select count(DISTINCT pr.CHART_ID) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
			(select count(DISTINCT pr.CHART_ID) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
			(select count(DISTINCT pr.CHART_ID) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted, 
			(select count(DISTINCT pr.CHART_ID) from @TempChartQAS_PAA pr  where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges, 

			(select count(DISTINCT pr.CHART_ID) from @TempChartQAS_FLAA pr  where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,  			
																															 
			(select count(DISTINCT pr.CHART_ID) from @TempChartQAS_PLAA pr  where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,


			-- Functions can perform poorly (especially with large data sets) due to their inherent RBAR processing (row-by-agonizing-row).  
			-- The query behind this function (dbo.GetChartDemographicAuditActions) has now been incorporated below directly into this proc so the data can be processed as a set instead of RBAR.  dsexton, 2/14/2022

			--(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges,		-- replaced 2/14/2022 by dsexton
			DemographicChanges = cast(null as int),		-- This value is now populated at the very end of the proc.  dsexton, 2/14/2022
		
		/*
			(select count(DISTINCT pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID) from #TempChartQAS_PAA pr with (NOLOCK)	
				Inner Join CHARGE_MASTER cm on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID 
						and (pr.CODER_CPT_CODE = cm.CPT_CODE OR pr.AUDITOR_CPT_CODE = cm.CPT_CODE)
						and (pr.CODER_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID OR pr.AUDITOR_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID)
						and c.TIME_OF_SERVICE >= cm.EFFECTIVE_DATE AND c.TIME_OF_SERVICE <= cm.EXPIRATION_DATE
						and cm.CHARGE_MASTER_USAGE_CODE = 9 and cm.CPT_CODE > ''
						where c.CHART_ID = pr.CHART_ID and pr.PROCEDURE_TYPE = 'PP' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1
			) as MIPSChanges,
		*/
			MIPSChanges = cast(null as int),		-- This value is now populated in a subsequent step.  dsexton, 1/5/2025

		/*
			(select count(DISTINCT pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID) from #TempChartQAS_PAA pr with (NOLOCK) 
				Inner Join CHARGE_MASTER cm on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID 
						and (pr.CODER_CPT_CODE = cm.CPT_CODE OR pr.AUDITOR_CPT_CODE = cm.CPT_CODE)
						and (pr.CODER_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID OR pr.AUDITOR_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID)
						and c.TIME_OF_SERVICE >= cm.EFFECTIVE_DATE AND c.TIME_OF_SERVICE <= cm.EXPIRATION_DATE
						and cm.CHARGE_MASTER_USAGE_CODE = 9 and cm.CPT_CODE > ''
						where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'PP'
			) as MIPSSubmitted,
		*/
			MIPSSubmitted = cast(null as int),		-- This value is now populated in a subsequent step.  dsexton, 1/5/2025

			--(select count(DISTINCT di.CHART_ID) from CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION di with (NOLOCK) where c.CHART_ID = di.CHART_ID and di.IS_CODER_CORRECT = 0 and di.EXCLUDE_FROM_QA_REPORT <> 1) as DocumentationDeficiencyChanges,
			DocumentationDeficiencyChanges = cast(null as int),			-- This value is now populated in a subsequent step.  dsexton, 1/5/2025

			--(select count(DISTINCT di.CHART_ID) from CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION di with (NOLOCK) where c.CHART_ID = di.CHART_ID) as DocumentationDeficiencySubmitted
			DocumentationDeficiencySubmitted = cast(null as int)		-- This value is now populated in a subsequent step.  dsexton, 1/5/2025
			

		--INTO #Results		-- part of tuning by dsexton, 2/14/2022;  replaced with @table variable, 1/5/2025

			FROM	@ChartSubset c 
					--LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID    
					--LEFT OUTER JOIN @UserProfiles as up on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID					-- tuning to use @UserProfiles. 1/5/2025, dsexton
					--LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID       
					--LEFT OUTER JOIN @ServiceAgreements as sa on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID				-- tuning to use @ServiceAgreements. 1/5/2025, dsexton
			--WHERE		c.approved_by_user_profile_id > 2	


select count(*) from @Results --order by chart_ID


END               

GO
