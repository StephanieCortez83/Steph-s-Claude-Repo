SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CODER_QA_SCORECARD_GET_CODER_SUMMARY_dsTest_ResultsAsSubqueryUpdate] 
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

--select chart_ID into #ChartSubset from @ChartSubset


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
--option (recompile)	-- do not use here. It can reduce reads, but increases duration.  dsexton, 1/9/2025

--select Chart_ID, Is_COder_Correct, Exclude_From_QA_Report, Action, Procedure_Type into #TempChartQAS_PAA from @TempChartQAS_PAA
--create index ix_TempChartQASPAA on #TempChartQAS_PAA (Procedure_Type, Action, Exclude_From_QA_Report, Is_Coder_Correct) Include (Chart_ID) --INCLUDE (Chart_ID, Action, Exclude_From_QA_Report, Is_Coder_Correct)


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

-- modified the method of populating @Results since this is the section that still degrades in performance periodically.  dsexton, 1/9/2025
insert into @Results (Chart_ID)			--, service_agreement_ID, ServiceAgreementDescription, facility_chart_ID, approved_date, user_profile_ID, CoderName)
select c.chart_ID		--, c.service_agreement_ID, sa.description, c.facility_chart_ID, c.approved_date, up.user_profile_ID, up.CoderName
from @ChartSubset c 
	--LEFT OUTER JOIN @UserProfiles as up on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
	--LEFT OUTER JOIN @ServiceAgreements as sa on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID

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
	-- MERGE joins performed much better during testing for this particular query.  dsexton, 1/9/2025

	-- PLAA joins
	left MERGE join (select chart_ID, PhysicianLOSAttempted = count(*) from @TempChartQAS_PLAA group by chart_ID) as t24 on t1.chart_ID = t24.chart_ID
	left MERGE join (select chart_ID, PhysicianLOSCorrect = count(*) from @TempChartQAS_PLAA where is_coder_correct = 1 or exclude_from_QA_Report = 1 group by chart_ID) as t25 on t1.chart_ID = t25.chart_ID
	left MERGE join (select chart_ID, PhysicianLOSAdditions = count(*) from @TempChartQAS_PLAA where ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t26 on t1.chart_ID = t26.chart_ID
	left MERGE join (select chart_ID, PhysicianLOSRevisions = count(*) from @TempChartQAS_PLAA where ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t27 on t1.chart_ID = t27.chart_ID
	left MERGE join (select chart_ID, PhysicianLOSDeletions = count(*) from @TempChartQAS_PLAA where ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t28 on t1.chart_ID = t28.chart_ID
	left MERGE join (select chart_ID, PhysicianLOSAbstract = count(*) from @TempChartQAS_PLAA where ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t29 on t1.chart_ID = t29.chart_ID
	left MERGE join (select chart_ID, PhysicianLOSModifierChanges = count(*) from @TempChartQAS_PLAA where CODER_MODIFIER <> AUDITOR_MODIFIER and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t30 on t1.chart_ID = t30.chart_ID

	-- FLAA joins
	left MERGE join (select chart_ID, FacilityLOSAttempted = count(*) from @TempChartQAS_FLAA group by chart_ID) as t17 on t1.chart_ID = t17.chart_ID
	left MERGE join (select chart_ID, FacilityLOSCorrect = count(*) from @TempChartQAS_FLAA where is_coder_correct = 1 or exclude_from_QA_Report = 1 group by chart_ID) as t18 on t1.chart_ID = t18.chart_ID
	left MERGE join (select chart_ID, FacilityLOSAdditions = count(*) from @TempChartQAS_FLAA where ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t19 on t1.chart_ID = t19.chart_ID
	left MERGE join (select chart_ID, FacilityLOSRevisions = count(*) from @TempChartQAS_FLAA where ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t20 on t1.chart_ID = t20.chart_ID
	left MERGE join (select chart_ID, FacilityLOSDeletions = count(*) from @TempChartQAS_FLAA where ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t21 on t1.chart_ID = t21.chart_ID
	left MERGE join (select chart_ID, FacilityLOSAbstract = count(*) from @TempChartQAS_FLAA where ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t22 on t1.chart_ID = t22.chart_ID
	left MERGE join (select chart_ID, FacilityLOSModifierChanges = count(*) from @TempChartQAS_FLAA where CODER_MODIFIER <> AUDITOR_MODIFIER and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t23 on t1.chart_ID = t23.chart_ID

	-- DAA joins
	left MERGE join (select chart_ID, DxAttempted = count(*) from @TempChartQAS_DAA group by chart_ID) as t2 on t1.chart_ID = t2.chart_ID
	left MERGE join (select chart_ID, DxCorrect = count(*) from @TempChartQAS_DAA where is_coder_correct = 1 or exclude_from_QA_Report = 1 group by chart_ID) as t3 on t1.chart_ID = t3.chart_ID
	left MERGE join (select chart_ID, DxAdditions = count(*) from @TempChartQAS_DAA where ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t4 on t1.chart_ID = t4.chart_ID
	left MERGE join (select chart_ID, DxRevisions = count(*) from @TempChartQAS_DAA where ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t5 on t1.chart_ID = t5.chart_ID
	left MERGE join (select chart_ID, DxDeletions = count(*) from @TempChartQAS_DAA where ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t6 on t1.chart_ID = t6.chart_ID
	left MERGE join (select chart_ID, DxAbstract = count(*) from @TempChartQAS_DAA where ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t7 on t1.chart_ID = t7.chart_ID
	left MERGE join (select chart_ID, DxChiefComplaintChanges = count(*) from @TempChartQAS_DAA where IS_CHIEF_COMPLAINT_CHANGE = 1 and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t8 on t1.chart_ID = t8.chart_ID
	left MERGE join (select chart_ID, DxPrimaryDxChanges = count(*) from @TempChartQAS_DAA where IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t9 on t1.chart_ID = t9.chart_ID
	left MERGE join (select chart_ID, DxChartsSubmitted = count(*) from @TempChartQAS_DAA group by chart_ID) as t10 on t1.chart_ID = t10.chart_ID

	-- AAA joins
	left MERGE join (select chart_ID, AnesthesiaAttempted = count(*) from @TempChartQAS_AAA group by chart_ID) as t11 on t1.chart_ID = t11.chart_ID
	left MERGE join (select chart_ID, AnesthesiaCorrect = count(*) from @TempChartQAS_AAA where is_coder_correct = 1 or exclude_from_QA_Report = 1 group by chart_ID) as t12 on t1.chart_ID = t12.chart_ID
	left MERGE join (select chart_ID, AnesthesiaAdditions = count(*) from @TempChartQAS_AAA where ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t13 on t1.chart_ID = t13.chart_ID
	left MERGE join (select chart_ID, AnesthesiaRevisions = count(*) from @TempChartQAS_AAA where ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t14 on t1.chart_ID = t14.chart_ID
	left MERGE join (select chart_ID, AnesthesiaDeletions = count(*) from @TempChartQAS_AAA where ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t15 on t1.chart_ID = t15.chart_ID
	left MERGE join (select chart_ID, AnesthesiaAbstract = count(*) from @TempChartQAS_AAA where ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t16 on t1.chart_ID = t16.chart_ID

--select * into #Results from @Results

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
	t1.ObsHoursAttempted = isnull(t49.ObsHoursAttempted, 0)
	,
	t1.ObsHoursCorrect = isnull(t50.ObsHoursCorrect, 0),
	t1.ObsHoursAdditions = isnull(t51.ObsHoursAdditions, 0),
	t1.ObsHoursRevisions = isnull(t52.ObsHoursRevisions, 0),
	t1.ObsHoursDeletions = isnull(t53.ObsHoursDeletions, 0),
	t1.ObsHoursAbstract = isnull(t54.ObsHoursAbstract, 0),
	t1.ObsHoursChanges = case when isnull(t55.ObsHoursChanges, 0) > 0 then 1 else 0 end,
	t1.ObsHoursSubmitted = case when isnull(t56.ObsHoursSubmitted, 0) > 0 then 1 else 0 end
	,

	t1.ProcModifierChanges = case when isnull(t59.ProcModifierChanges, 0) > 0 then 1 else 0 end

from
	@Results as t1
	--#Results as t1
	--join #ChartSubset as t0 on t1.chart_ID = t0.chart_ID

	-- MERGE joins performed much better during testing for this particular query, and especially for this set of UPDATE queries referencing @TempChartQAS_PAA. Join hints are generally not recommended except for special cases.  dsexton, 1/9/2025

	left MERGE join (select chart_ID, ProcModifierChanges = count(*) from @TempChartQAS_PAA where CODER_MODIFIER <> AUDITOR_MODIFIER and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t59 on t1.chart_ID = t59.chart_ID

	-- PAA_TypeOB joins
	left MERGE join (select chart_ID, ObsHoursAttempted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' group by chart_ID) as t49 on t1.chart_ID = t49.chart_ID
	left MERGE join (select chart_ID, ObsHoursCorrect = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and (is_coder_correct = 1 or exclude_from_QA_Report = 1) group by chart_ID) as t50 on t1.chart_ID = t50.chart_ID
	left MERGE join (select chart_ID, ObsHoursAdditions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t51 on t1.chart_ID = t51.chart_ID
	left MERGE join (select chart_ID, ObsHoursRevisions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t52 on t1.chart_ID = t52.chart_ID
	left MERGE join (select chart_ID, ObsHoursDeletions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t53 on t1.chart_ID = t53.chart_ID
	left MERGE join (select chart_ID, ObsHoursAbstract = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t54 on t1.chart_ID = t54.chart_ID
	left MERGE join (select chart_ID, ObsHoursChanges = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' and IS_CODER_CORRECT = 0 and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t55 on t1.chart_ID = t55.chart_ID
	left MERGE join (select chart_ID, ObsHoursSubmitted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'OB' group by chart_ID) as t56 on t1.chart_ID = t56.chart_ID


	-- PAA_TypePP joins
	left MERGE join (select chart_ID, ProfProcAttempted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' group by chart_ID) as t43 on t1.chart_ID = t43.chart_ID
	left MERGE join (select chart_ID, ProfProcCorrect = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and (is_coder_correct = 1 or exclude_from_QA_Report = 1) group by chart_ID) as t44 on t1.chart_ID = t44.chart_ID
	left MERGE join (select chart_ID, ProfProcAdditions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t45 on t1.chart_ID = t45.chart_ID
	left MERGE join (select chart_ID, ProfProcRevisions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t46 on t1.chart_ID = t46.chart_ID
	left MERGE join (select chart_ID, ProfProcDeletions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t47 on t1.chart_ID = t47.chart_ID
	left MERGE join (select chart_ID, ProfProcAbstract = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'PP' and ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t48 on t1.chart_ID = t48.chart_ID

	-- PAA_TypeCI joins
	left MERGE join (select chart_ID, InfusionInjectionAttempted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' group by chart_ID) as t37 on t1.chart_ID = t37.chart_ID
	left MERGE join (select chart_ID, InfusionInjectionCorrect = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and (is_coder_correct = 1 or exclude_from_QA_Report = 1) group by chart_ID) as t38 on t1.chart_ID = t38.chart_ID
	left MERGE join (select chart_ID, InfusionInjectionAdditions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t39 on t1.chart_ID = t39.chart_ID
	left MERGE join (select chart_ID, InfusionInjectionRevisions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t40 on t1.chart_ID = t40.chart_ID
	left MERGE join (select chart_ID, InfusionInjectionDeletions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t41 on t1.chart_ID = t41.chart_ID
	left MERGE join (select chart_ID, InfusionInjectionAbstract = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t42 on t1.chart_ID = t42.chart_ID
	left MERGE join (select chart_ID, InfInjChanges = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' and IS_CODER_CORRECT = 0 and EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t57 on t1.chart_ID = t57.chart_ID
	left MERGE join (select chart_ID, InfInjSubmitted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'CI' group by chart_ID) as t58 on t1.chart_ID = t58.chart_ID

	-- PAA_TypeFP joins
	left MERGE join (select chart_ID, FacilityProcAttempted = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' group by chart_ID) as t31 on t1.chart_ID = t31.chart_ID
	left MERGE join (select chart_ID, FacilityProcCorrect = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and (is_coder_correct = 1 or exclude_from_QA_Report = 1) group by chart_ID) as t32 on t1.chart_ID = t32.chart_ID
	left MERGE join (select chart_ID, FacilityProcAdditions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t33 on t1.chart_ID = t33.chart_ID
	left MERGE join (select chart_ID, FacilityProcRevisions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t34 on t1.chart_ID = t34.chart_ID
	left MERGE join (select chart_ID, FacilityProcDeletions = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t35 on t1.chart_ID = t35.chart_ID
	left MERGE join (select chart_ID, FacilityProcAbstract = count(*) from @TempChartQAS_PAA where PROCEDURE_TYPE = 'FP' and ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT = 0 group by chart_ID) as t36 on t1.chart_ID = t36.chart_ID

select count(*) from @Results --order by chart_ID

END               

GO
