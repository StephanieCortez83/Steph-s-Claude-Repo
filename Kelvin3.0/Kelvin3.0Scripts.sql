USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 1) DACS-2308 - Create or Alter Stored Procedure - [dbo].[CODER_QA_SCORECARD_GET_USER_AUDITOR_RESPONSES].SQL

GO

/****** Object:  StoredProcedure [dbo].[CODER_QA_SCORECARD_GET_USER_AUDITOR_RESPONSES]    Script Date: 7/12/2024 4:33:30 PM ******/
GO

GO

EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'CODER_QA_SCORECARD_GET_USER_AUDITOR_RESPONSES', @DestProc = 'CODER_QA_SCORECARD_GET_USER_AUDITOR_RESPONSES-2308';
GO

CREATE OR ALTER PROCEDURE [dbo].[CODER_QA_SCORECARD_GET_USER_AUDITOR_RESPONSES]
    @CHECK_DATE date,--coder response feature implementation date
	@USER_PROFILE_ID INT
AS
BEGIN

-- temp tables to support tuning by dsexton, 2/14/2022   -------------------------------------------
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset
if object_id('TempDB..#TempChartQAS_PAA', 'U') is not null drop table #TempChartQAS_PAA
if object_id('TempDB..#TempChartQAS_FLAA', 'U') is not null drop table #TempChartQAS_FLAA
if object_id('TempDB..#TempChartQAS_PLAA', 'U') is not null drop table #TempChartQAS_PLAA
if object_id('TempDB..#TempChartQAS_DAA', 'U') is not null drop table #TempChartQAS_DAA
if object_id('TempDB..#ChartTable', 'U') is not null drop table #ChartTable
if object_id('TempDB..#ChartDemoHX', 'U') is not null drop table #ChartDemoHX
if object_id('TempDB..#DemoAuditChartIDs', 'U') is not null drop table #DemoAuditChartIDs
if object_id('TempDB..#Results', 'U') is not null drop table #Results
----------------------------------------------------------------------------------------------------

SELECT	c.chart_id, c.completed_by_user_profile_id,
	time_of_service = cast(null as datetime),
	service_agreement_id = cast(null as int),
	facility_chart_id = cast(null as varchar(20)),
	APPROVED_DATE = cast(null as datetime),
	approved_by_user_profile_id = cast(null as int)
	, Approval_Reason_Code = cast(null as int)
INTO	#ChartSubset
FROM	chart as c with (NOLOCK)
WHERE	c.CHART_STATUS_ID in (4, 5)
AND		(c.COMPLETED_BY_USER_PROFILE_ID = @USER_PROFILE_ID 
or c.APPROVED_BY_USER_PROFILE_ID = @USER_PROFILE_ID
-- DACS-2308 Add Second Level auditor as a valid user profile for this result set.
or c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID = @USER_PROFILE_ID)
-- end DACS-2308 ---------------------------------------------------------------------
AND     c.CODER_ERROR_RESPONSE = 2
AND     c.AUDITOR_ERROR_RESPONSE is null

update t
set t.time_of_service = c.time_of_service,
	t.service_agreement_id = c.service_agreement_id,
	t.facility_chart_id = c.facility_chart_id,
	t.APPROVED_DATE = c.APPROVED_DATE,
	t.approved_by_user_profile_id = c.approved_by_user_profile_id
	, t.Approval_Reason_Code = c.approval_reason_code
from #ChartSubset as t join chart as c with(nolock) on t.chart_ID = c.chart_ID

delete from #ChartSubset
where APPROVED_BY_USER_PROFILE_ID <= 2
	or Approval_Reason_Code <> 3


-- changes to support tuning by dsexton, 2/14/2022 ---------------------------------------------------------------------------------------------------------------
select t.Chart_ID, CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, PROCEDURE_TYPE, CODER_MODIFIER,
		AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE, CODER_CHARGE_MASTER_DEPT_ID, AUDITOR_CHARGE_MASTER_DEPT_ID
  into #TempChartQAS_PAA
from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

-- StartChgs anesthesia coding ---------------
select t.Chart_ID, CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION,
		CODER_ANESTHESIA_CODE, AUDITOR_ANESTHESIA_CODE
  into #TempChartQAS_AAA
from CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID
-- EndChgs anesthesia coding -----------------

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
  into #TempChartQAS_FLAA
from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
  into #TempChartQAS_PLAA
from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, IS_CHIEF_COMPLAINT_CHANGE, IS_PRIMARY_DIAGNOSIS_CHANGE
  into #TempChartQAS_DAA
from CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- All subqueries below were modified to reference the new temp tables (above) which contain small subsets of data from the base tables.  dsexton, 2/14/2022
SELECT
	c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, c.APPROVED_DATE, up.USER_PROFILE_ID,  up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID)
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID)
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND (pr.IS_CODER_CORRECT = 1 OR pr.EXCLUDE_FROM_QA_REPORT = 1))
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND (ac.IS_CODER_CORRECT = 1 OR ac.EXCLUDE_FROM_QA_REPORT = 1))
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR flos.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 or PLOS.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0)
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND ac.EXCLUDE_FROM_QA_REPORT = 0)
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 )
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND ac.EXCLUDE_FROM_QA_REPORT = 0)
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0)
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND ac.EXCLUDE_FROM_QA_REPORT = 0)
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND flos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND plos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount,

			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxAttempted,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAbstract,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionDeletions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAbstract,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract,

			-- StartChgs anesthesia coding ---------------
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND (ac.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as AnesthesiaCorrect,
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID) as AnesthesiaAttempted,
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAdditions,
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaRevisions,
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaDeletions,
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAbstract,
			-- EndChgs anesthesia coding -----------------

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAbstract,

			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,

			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,

			(select count(DISTINCT dx.CHART_ID) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
			(select count(DISTINCT dx.CHART_ID) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,
			(select count(DISTINCT dx.CHART_ID) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,

			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges,

			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_FLAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,

			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PLAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,

			-- Functions can perform poorly (especially with large data sets) due to their inherent RBAR processing (row-by-agonizing-row).
			-- The query behind this function (dbo.GetChartDemographicAuditActions) has now been incorporated below directly into this proc so the data can be processed as a set instead of RBAR.  dsexton, 2/14/2022

			--(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges,		-- replaced 2/14/2022 by dsexton
			DemographicChanges = cast(null as int),		-- This value is now populated at the very end of the proc.  dsexton, 2/14/2022

			(select count(DISTINCT pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID) from #TempChartQAS_PAA pr with (NOLOCK)
				Inner Join CHARGE_MASTER cm on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
						and (pr.CODER_CPT_CODE = cm.CPT_CODE OR pr.AUDITOR_CPT_CODE = cm.CPT_CODE)
						and (pr.CODER_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID OR pr.AUDITOR_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID)
						and c.TIME_OF_SERVICE >= cm.EFFECTIVE_DATE AND c.TIME_OF_SERVICE <= cm.EXPIRATION_DATE
						and cm.CHARGE_MASTER_USAGE_CODE = 9 and cm.CPT_CODE > ''
						where c.CHART_ID = pr.CHART_ID and pr.PROCEDURE_TYPE = 'PP' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1
			) as MIPSChanges,

			(select count(DISTINCT pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID) from #TempChartQAS_PAA pr with (NOLOCK)
				Inner Join CHARGE_MASTER cm on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
						and (pr.CODER_CPT_CODE = cm.CPT_CODE OR pr.AUDITOR_CPT_CODE = cm.CPT_CODE)
						and (pr.CODER_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID OR pr.AUDITOR_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID)
						and c.TIME_OF_SERVICE >= cm.EFFECTIVE_DATE AND c.TIME_OF_SERVICE <= cm.EXPIRATION_DATE
						and cm.CHARGE_MASTER_USAGE_CODE = 9 and cm.CPT_CODE > ''
						where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'PP'
			) as MIPSSubmitted,

			(select count(DISTINCT di.CHART_ID) from CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION di with (NOLOCK) where c.CHART_ID = di.CHART_ID and di.IS_CODER_CORRECT = 0 and di.EXCLUDE_FROM_QA_REPORT <> 1) as DocumentationDeficiencyChanges,

			(select count(DISTINCT di.CHART_ID) from CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION di with (NOLOCK) where c.CHART_ID = di.CHART_ID) as DocumentationDeficiencySubmitted

		INTO #Results		-- part of tuning by dsexton, 2/14/2022

			FROM	[#ChartSubset] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
			WHERE		c.approved_by_user_profile_id > 2



------------------------------------------------------------------------------------------------------------------------------------------
-- Beginning of section that directly incorporates the query from function dbo.GetChartDemographicAuditActions.  dsexton, 2/14/2022

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
 INTO #ChartTable
from CHART with(nolock)
where chart_ID in (Select Chart_ID from #ChartSubset)


select Chart_ID, Medical_Record_Num, Admission_Date_Time, SERVICE_AGREEMENT_ARRIVAL_MODE_ID, Arrival_Date_Time, PATIENT_DISPOSITION_MAP_ID, PHYSICIAN_ID, TIME_TO_ROOM,
	SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, GENDER, RESIDENT_PARTICIPATED_IN_CARE, FINANCIAL_CLASS_CD, PATIENT_DOB, NURSE_PRACTITIONER_ID, Time_of_Service, PATIENT_DISPOSITION_ID,
	FACILITY_ADMIN_CHART_ID, TIME_OF_DIS, CONDITION_OF_ACCIDENT_ID, CLINIC_ID, ATTESTATION_SIGNED_BY_ATTENDING, SCRIBE_ID, LAST_ENCOUNTER_DATE, LAST_MENSTRUAL_PERIOD,
	PATIENT_AGE, TIME_OF_PHYS_EVAL, TIME_OF_TRIAGE, MEDICAL_EXAMINER_NOTIFIED, ORGAN_DONATION, USE_TIME_BASED_CHARGE_CAPTURE, SEEN_IN_ED_WITHIN_48_HOURS_OF_OR
 INTO #ChartDemoHX
from CHART_DEMOGRAPHIC_HISTORY with(nolock)
where Chart_ID in (Select Chart_ID from #ChartSubset)


create table #DemoAuditChartIDs (Chart_ID int)

insert into #DemoAuditChartIDs

		-- Add the SELECT statement with parameter references here
		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
			AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
			AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM
		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
		WHERE
			ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
		WHERE
			ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON c.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
		WHERE
			ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_MAP_ID, - 1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON cdh.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
		WHERE
			ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_MAP_ID, - 1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON c.PHYSICIAN_ID = fp.FACILITY_PROF_ID			--here
		WHERE
			ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON cdh.PHYSICIAN_ID = fp.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE
			ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
			AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
			AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE
			ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
			AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
			AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE
			ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND ffc.FINANCIAL_CLASS_CD = cdh.FINANCIAL_CLASS_CD
		WHERE
			ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
		WHERE
			ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON c.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON cdh.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		WHERE
			ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = cdh.PATIENT_DISPOSITION_ID
		WHERE
			ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND coa.CONDITION_OF_ACCIDENT_ID = c.CONDITION_OF_ACCIDENT_ID
		WHERE
			ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
			AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND coa.CONDITION_OF_ACCIDENT_ID = cdh.CONDITION_OF_ACCIDENT_ID
		WHERE
			ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
			AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND cl.CLINIC_ID = c.CLINIC_ID
		WHERE
			ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND cl.CLINIC_ID = cdh.CLINIC_ID
		WHERE
			ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON c.SCRIBE_ID = s.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
			AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON cdh.SCRIBE_ID = s.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
			AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
			AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
			AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')

		---- Time Based Physician LOS
		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE, 0) <> 0
			AND ISNULL(c.USE_TIME_BASED_CHARGE_CAPTURE, '') <> ISNULL(cdh.USE_TIME_BASED_CHARGE_CAPTURE, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE, 0) <> 0
			AND ISNULL(c.USE_TIME_BASED_CHARGE_CAPTURE, '') <> ISNULL(cdh.USE_TIME_BASED_CHARGE_CAPTURE, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN CHART_CONSULTING_PHYSICIAN ccp WITH (NOLOCK) ON c.CHART_ID = ccp.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
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

	  UNION
	  SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN CHART_CONSULTING_PHYSICIAN_HISTORY ccph WITH (NOLOCK) ON c.CHART_ID = ccph.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
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


update #Results set DemographicChanges = 1 where chart_ID in (Select Chart_ID from #DemoAuditChartIDs)
update #Results set DemographicChanges = 0 where DemographicChanges is null

select * from #Results r

-- end of section to replace the call to function dbo.GetChartDemographicAuditActions.  dsexton, 2/14/2022
---------------------------------------------------------------------------------------------------------------------------


END
GO
-- End of 1) DACS-2308 - Create or Alter Stored Procedure - [dbo].[CODER_QA_SCORECARD_GET_USER_AUDITOR_RESPONSES].SQL
GO

-- Start of 01) DACS-3228- Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR2.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3228 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR2.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR2';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Process'
			,@PqrsCd + ' : Deprescribing Proton Pump Inhibitors for patients who do not meet criteria for long-term utilization : The percentage of patients on a Proton Pump Inhibitor with an appropriately documented indication or an order for discontinuation for not meeting criteria for long-term utilization. '
			,'B'
			,50
			,999
			,@Dos
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR2' -- = 219
*/
-- End of 01) DACS-3228- Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR2.SQL
GO

-- Start of 02) DACS-3228 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR2.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3228 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR2.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR2';
	DECLARE @Dos DATETIME = '01-01-2024';

	DECLARE @MeasureId INT = 
		(
			SELECT [CMS_PQRI_MEASURE_ID]
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('No Measure loaded for [' + @PqrsCd + '].  Cannot continue.');
		SELECT 'Error' = -1;
		RETURN;
	END;

	PRINT('@MeasureId = ' + CAST(@MeasureId AS VARCHAR(30)));

	DECLARE @countPQRSCodes INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodes' = @countPQRSCodes; -- testing


	IF @countPQRSCodes > 0
	BEGIN 
		PRINT('Found Measure Codes.  Expiring existing.');
	
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [END_DATE] = DATEADD(minute,-1,CAST(CAST(@Dos AS DATE) AS DATETIME))
		WHERE
			[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND [START_DATE] <= @Dos
			AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
			AND [CODE] IS NOT NULL
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	END;

	DECLARE @countPQRSCodesAfterExpiration INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- DENOMINATOR EXCLUSION: Patients who have an active diagnosis that meets criteria for long-term utilization of Proton Pump Inhibitors.  CANNOT have any of these
		 (@MeasureId,'DG1P1','B37.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','B37.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','B96.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C16.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','D47.Z1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.Z2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.Z9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.3',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','E27.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I85.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I85.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I85.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I85.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.03',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.114',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.115',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.116',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.117',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.170',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.178',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.841',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.842',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.843',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.848',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.91',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K21.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K21.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K21.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.4',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','K22.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.70',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.710',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','K22.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.61',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.71',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.91',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.819',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A13',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A14',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A15',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.29',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','K52.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.831',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.832',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.838',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.839',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.03',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.04',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','N18.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Q40.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z85.020',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z85.09',NULL,@Dos,NULL)

		-- denominator/numerator group 2
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		 
		-- measure code numerators
		-- SELECTIONS
		,(@MeasureId,'HCPCS','DG002',NULL,@Dos,'Performance Met: (Inpatient): Proton Pump Inhibitors discontinued by discharge OR (PAC/SNF): Proton Pump Inhibitors discontinued. ')
		,(@MeasureId,'HCPCS','DG003',NULL,@Dos,'Performance Not Met: Proton Pump Inhibitors not discontinued; reason not given. ')
		,(@MeasureId,'HCPCS','DG004',NULL,@Dos,'Denominator Exception: <ul><li>Documented medical reason for exclusion</li><li>Patient refusal</li><li>Eloped or left AMA</li><li>Expired</li><li>Discharged to hospice</li></ul> ')
		,(@MeasureId,'HCPCS','QR201',NULL,@Dos,'Denominator Exception: Documentation indicating patient has an active diagnosis or a history of diagnosis that meets criteria for long-term utilization of Proton Pump Inhibitors. (PQR201) <p><img src="/WebPages/Images/MIPS/MIPS_THEPQR2_PQR201_DenominatorExclustionTable.png" alt="(PQR201) Exception table image"></p> ')
				
		-- PQRS Question for response by coder within ACS		
		-- QUESTIONS		
		,(@MeasureId,'DQ411','DG847',NULL,@Dos,'Was a Proton Pump Inhibitor (PPI) Medication DG847 used? <ul><li>Omeprazole (Prilosec, Prilosec OTC, Zegerid)</li><li>Lansoprazole (Prevacid)</li><li>Pantoprazole (Protonix)</li><li>Rebeprazole (Aciphex)</li><li>Esomeprazole (Nexium)</li><li>Dexlansoprazole (Dexilant, Kapidex)</li></ul>')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 225 total inserts
		
		
	DECLARE @countPQRSCodesFinal INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesFinal' = @countPQRSCodesFinal;

	-- testing:
	SELECT 
		*
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR2' -- = 219
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 219
*/
-- End of 02) DACS-3228 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR2.SQL
GO

-- Start of 03) DACS-3228 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3228 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data or failed USE_TELEHEALTH field check.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF NOT EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('7','8','9','12','13') OR [LOCATION_OF_SERVICE] IN ('21','31','32'))
		)
	BEGIN 
		PRINT('@ChartId does not have a valid PHYSICIAN_SERVICE_CLASS_CD of (7,8,9,12,13) or LOCATION_OF_SERVICE of (21,31,32) to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid PHYSICIAN_SERVICE_CLASS_CD of (7,8,9,12,13) or LOCATION_OF_SERVICE of (21,31,32) to test further', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Denominator Exclusion Diagnosis List?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount > 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Denominator Exclusion Diagnosis List item found)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR2' -- = 219

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2
	@ChartId = 2100112610
	,@PqrsNum = 'THEPQR2'
	,@Dos = '7/10/2024 4:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3228 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR2].SQL
GO

-- Start of 1) DACS-3403 - Create or Alter Proc CODER_QA_SCORECARD_GET_CHART_SUMMARY.SQL

GO

/****** Object:  StoredProcedure [dbo].[CODER_QA_SCORECARD_GET_CHART_SUMMARY]    Script Date: 7/9/2024 4:20:23 PM ******/
GO

GO


-- [CODER_QA_SCORECARD_GET_CHART_SUMMARY]
--CREATE OR ALTER   PROCEDURE [dbo].[CODER_QA_SCORECARD_GET_CHART_SUMMARY-DACS-2950]
--CREATE OR ALTER   PROCEDURE [dbo].[CODER_QA_SCORECARD_GET_CHART_SUMMARY-DACS-3403]

EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'CODER_QA_SCORECARD_GET_CHART_SUMMARY', @DestProc = 'CODER_QA_SCORECARD_GET_CHART_SUMMARY_DACS-3403';
GO

CREATE OR ALTER         PROCEDURE [dbo].[CODER_QA_SCORECARD_GET_CHART_SUMMARY]
    @StartDate datetime,
    @EndDate datetime,
	@USER_PROFILE_ID INT
AS
BEGIN

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- temp tables to support tuning by dsexton, 2/14/2022   -------------------------------------------
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset
if object_id('TempDB..#TempChartQAS_PAA', 'U') is not null drop table #TempChartQAS_PAA
if object_id('TempDB..#TempChartQAS_FLAA', 'U') is not null drop table #TempChartQAS_FLAA
if object_id('TempDB..#TempChartQAS_PLAA', 'U') is not null drop table #TempChartQAS_PLAA
if object_id('TempDB..#TempChartQAS_DAA', 'U') is not null drop table #TempChartQAS_DAA
if object_id('TempDB..#ChartTable', 'U') is not null drop table #ChartTable
if object_id('TempDB..#ChartDemoHX', 'U') is not null drop table #ChartDemoHX
if object_id('TempDB..#DemoAuditChartIDs', 'U') is not null drop table #DemoAuditChartIDs
-- StartChgs anesthesia coding ---------------
if object_id('TempDB..#TempChartQAS_AAA', 'U') is not null drop table #TempChartQAS_AAA
-- EndChgs anesthesia coding -----------------
if object_id('TempDB..#Results', 'U') is not null drop table #Results

-- PBAChanges ----------------------------------------------------
if object_id('TempDB..#ChartSubsetPBA', 'U') is not null drop table #ChartSubsetPBA
if object_id('TempDB..#TempChartPBA_PAA', 'U') is not null drop table #TempChartPBA_PAA
if object_id('TempDB..#TempChartPBA_FLAA', 'U') is not null drop table #TempChartPBA_FLAA
if object_id('TempDB..#TempChartPBA_PLAA', 'U') is not null drop table #TempChartPBA_PLAA
if object_id('TempDB..#TempChartPBA_DAA', 'U') is not null drop table #TempChartPBA_DAA
if object_id('TempDB..#TempChartPBA_AAA', 'U') is not null drop table #TempChartPBA_AAA
if object_id('TempDB..#ResultsPBA', 'U') is not null drop table #Results

-- End PBAChanges ----------------------------------------------------

----------------------------------------------------------------------------------------------------

select * into #ChartSubset from							-- part of tuning 10/4/2023 (dsexton)
(
SELECT	c.chart_id, c.completed_by_user_profile_id,
	time_of_service = cast(null as datetime),
	service_agreement_id = cast(null as int),
	facility_chart_id = cast(null as varchar(20)),
	APPROVED_DATE = cast(null as datetime),
	approved_by_user_profile_id = cast(null as int)
	, Approval_Reason_Code = cast(null as int)
	, POST_BILL_AUDIT_COMPLETED = cast(null as datetime)		-- DACS-2912 - Pippin - Post-Bill Audit inclusion changes
	--, c.completion_date
FROM	chart as c with (NOLOCK)
WHERE	c.CHART_STATUS_ID in (4, 5)
AND
	(--coder charts that have an auditor response
		(
			(c.COMPLETED_BY_USER_PROFILE_ID = @USER_PROFILE_ID or c.APPROVED_BY_USER_PROFILE_ID = @USER_PROFILE_ID)
			AND
			(
				c.CODER_ERROR_RESPONSE = 1
				OR
				(c.CODER_ERROR_RESPONSE = 2 AND c.AUDITOR_ERROR_RESPONSE is not null)
			)
			AND c.COMPLETION_DATE between DateAdd(day, -7, @StartDate) AND DateAdd(second, 86399, @EndDate)
		)
		-- OR ...		-- tuning 10/4/2023 moves an OR statement that was here to the UNION below, reducing LReads by 95% from 650K to 30K (dsexton). 
	)

UNION	-- tuning 10/4/2023 moves an OR statement to this UNION, reducing LReads by 95% from 650K to 30K (dsexton). 

SELECT	c.chart_id, c.completed_by_user_profile_id,
	time_of_service = cast(null as datetime),
	service_agreement_id = cast(null as int),
	facility_chart_id = cast(null as varchar(20)),
	APPROVED_DATE = cast(null as datetime),
	approved_by_user_profile_id = cast(null as int)
	, Approval_Reason_Code = cast(null as int)
	, POST_BILL_AUDIT_COMPLETED = cast(null as datetime)		-- DACS-2912 - Pippin - Post-Bill Audit inclusion changes
FROM	chart as c with (NOLOCK)
WHERE	c.CHART_STATUS_ID in (4, 5)
AND
	(--coder charts that have an auditor response
		(-- auditor charts that have a second level audit			-- This was an OR statement that was moved to this UNION for tuning 10/4/2023 (dsexton)
			c.START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0 -- Do not include "pushed" charts where 2nd audit wasn't started.
			AND c.APPROVED_BY_USER_PROFILE_ID = @USER_PROFILE_ID
			AND (c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 2	AND c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> @USER_PROFILE_ID) -- Do not include charts where there was no first auditor
			AND convert(varchar, c.SECOND_LEVEL_QA_APPROVED_DATETIME, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)
		)
	)
) as x

update t
set t.time_of_service = c.time_of_service,
	t.service_agreement_id = c.service_agreement_id,
	t.facility_chart_id = c.facility_chart_id,
	t.APPROVED_DATE = c.APPROVED_DATE,
	t.approved_by_user_profile_id = c.approved_by_user_profile_id
	, t.Approval_Reason_Code = c.approval_reason_code
from #ChartSubset as t join chart as c with(nolock) on t.chart_ID = c.chart_ID

-- PBAChanges ----------------------------------------------------
-- Get PBA charts where there has been a PBA started.

SELECT 	
	  c.chart_id
	, c.completed_by_user_profile_id
	, time_of_service = cast(null as datetime)
	, service_agreement_id = cast(null as int)
	, facility_chart_id = cast(null as varchar(20))
	, APPROVED_DATE = cast(null as datetime)
	, approved_by_user_profile_id = cast(null as int)
	, Approval_Reason_Code = cast(null as int)
	, POST_BILL_AUDIT_COMPLETED = cast(null as datetime)
	INTO #ChartSubsetPBA
FROM	
	chart as c
WHERE	
	c.CHART_STATUS_ID = 5 -- Sent
	AND c.POST_BILL_AUDIT_STARTED IS NOT NULL
	AND c.COMPLETED_BY_USER_PROFILE_ID = @USER_PROFILE_ID
	AND c.COMPLETION_DATE between DateAdd(day, -7, @StartDate) AND DateAdd(second, 86399, @EndDate)
	
update t
set t.time_of_service = c.time_of_service,
	t.service_agreement_id = c.service_agreement_id,
	t.facility_chart_id = c.facility_chart_id,
	t.APPROVED_DATE = c.APPROVED_DATE,
	t.approved_by_user_profile_id = c.approved_by_user_profile_id
	, t.Approval_Reason_Code = c.approval_reason_code
	,t.POST_BILL_AUDIT_COMPLETED = c.POST_BILL_AUDIT_COMPLETED
from #ChartSubsetPBA as t join chart as c with(nolock) on t.chart_ID = c.chart_ID
-- End PBAChanges ----------------------------------------------------

--DEBUG select * from #ChartSubset
--DEBUG select * from #ChartSubsetPBA

--delete from #ChartSubset
--where 
--	APPROVED_BY_USER_PROFILE_ID <= 2 
--	or Approval_Reason_Code <> 3


-- changes to support tuning by dsexton, 2/14/2022 ---------------------------------------------------------------------------------------------------------------
select t.Chart_ID, CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, PROCEDURE_TYPE, CODER_MODIFIER,
		AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE, CODER_CHARGE_MASTER_DEPT_ID, AUDITOR_CHARGE_MASTER_DEPT_ID
  into #TempChartQAS_PAA
from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

-- StartChgs anesthesia coding ---------------
select t.Chart_ID, CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION,  
		CODER_ANESTHESIA_CODE, AUDITOR_ANESTHESIA_CODE
  into #TempChartQAS_AAA
from CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID
-- EndChgs anesthesia coding -----------------

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
  into #TempChartQAS_FLAA
from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
  into #TempChartQAS_PLAA
from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, IS_CHIEF_COMPLAINT_CHANGE, IS_PRIMARY_DIAGNOSIS_CHANGE
  into #TempChartQAS_DAA
from CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

-- PBAChanges ----------------------------------------------------
-- PBA Procedure Codes
select pba.[ChartId] 
  ,vi.[ChartAuditProcedureVersionItemId]
  ,vi.[IsPreviousVersionCorrect]
  ,vi.[ExcludeFromQA]
  ,vi.[ChartAuditActionTypeCode]
  ,vi.[ProcedureType]
  ,vip.[Modifier] As PrevModifier
  ,vi.[Modifier]
  ,vip.[CptCode] As PrevCptCode
  ,vi.[CptCode]
  ,vip.[ChargeMasterDeptId] As PrevChargeMasterDeptId
  ,vi.[ChargeMasterDeptId]
  into #TempChartPBA_PAA
from #ChartSubsetPBA c
INNER JOIN [dbo].[ChartPostBillAudit] pba ON pba.[ChartId] = c.chart_ID AND pba.[ChartPostBillAuditStatusTypeCode] in (2,3)
INNER JOIN [dbo].[ChartAuditVersion] v ON pba.[ChartPostBillAuditId] = v.[ChartAuditId] AND v.[VersionNumber] = 2
INNER JOIN [dbo].[ChartAuditProcedureVersionItem] vi ON vi.[ChartAuditVersionId] = v.[ChartAuditVersionId]
LEFT OUTER JOIN [dbo].[ChartAuditProcedureVersionItem] vip ON vi.[PrevChartAuditProcedureVersionItemId] = vip.[ChartAuditProcedureVersionItemId]

-- PBA Anesthesia Codes
select pba.[ChartId] 
  ,vi.[ChartAuditAnesthesiaVersionItemId]
  ,vi.[IsPreviousVersionCorrect]
  ,vi.[ExcludeFromQA]
  ,vi.[ChartAuditActionTypeCode]
  ,vip.[AnesthesiaCode] As PrevAnesthesiaCode
  ,vi.[AnesthesiaCode]
  into #TempChartPBA_AAA
from #ChartSubsetPBA c
INNER JOIN [dbo].[ChartPostBillAudit] pba ON pba.[ChartId] = c.chart_ID AND pba.[ChartPostBillAuditStatusTypeCode] in (2,3)
INNER JOIN [dbo].[ChartAuditVersion] v ON pba.[ChartPostBillAuditId] = v.[ChartAuditId] AND v.[VersionNumber] = 2
INNER JOIN [dbo].[ChartAuditAnesthesiaVersionItem] vi ON vi.[ChartAuditVersionId] = v.[ChartAuditVersionId]
LEFT OUTER JOIN [dbo].[ChartAuditAnesthesiaVersionItem] vip ON vi.[PrevChartAuditAnesthesiaVersionItemId] = vip.[ChartAuditAnesthesiaVersionItemId]

-- PBA Facility LOS
select pba.[ChartId] 
  ,vi.[ChartAuditFacilityLosVersionItemId]
  ,vi.[IsPreviousVersionCorrect]
  ,vi.[ExcludeFromQA]
  ,vi.[ChartAuditActionTypeCode]
  ,vip.[Modifier] As PrevModifier
  ,vi.[Modifier]
  ,vip.[CptCode] As PrevCptCode
  ,vi.[CptCode]
  into #TempChartPBA_FLAA
from #ChartSubsetPBA c
INNER JOIN [dbo].[ChartPostBillAudit] pba ON pba.[ChartId] = c.chart_ID AND pba.[ChartPostBillAuditStatusTypeCode] in (2,3)
INNER JOIN [dbo].[ChartAuditVersion] v ON pba.[ChartPostBillAuditId] = v.[ChartAuditId] AND v.[VersionNumber] = 2
INNER JOIN [dbo].[ChartAuditFacilityLosVersionItem] vi ON vi.[ChartAuditVersionId] = v.[ChartAuditVersionId]
LEFT OUTER JOIN [dbo].[ChartAuditFacilityLosVersionItem] vip ON vi.[PrevChartAuditFacilityLosVersionItemId] = vip.[ChartAuditFacilityLosVersionItemId]

-- PBA Physician LOS
select pba.[ChartId] 
  ,vi.[ChartAuditPhysicianLosVersionItemId]
  ,vi.[IsPreviousVersionCorrect]
  ,vi.[ExcludeFromQA]
  ,vi.[ChartAuditActionTypeCode]
  ,vip.[Modifier] As PrevModifier
  ,vi.[Modifier]
  ,vip.[CptCode] As PrevCptCode
  ,vi.[CptCode]
  into #TempChartPBA_PLAA
from #ChartSubsetPBA c
INNER JOIN [dbo].[ChartPostBillAudit] pba ON pba.[ChartId] = c.chart_ID AND pba.[ChartPostBillAuditStatusTypeCode] in (2,3)
INNER JOIN [dbo].[ChartAuditVersion] v ON pba.[ChartPostBillAuditId] = v.[ChartAuditId] AND v.[VersionNumber] = 2
INNER JOIN [dbo].[ChartAuditPhysicianLosVersionItem] vi ON vi.[ChartAuditVersionId] = v.[ChartAuditVersionId]
LEFT OUTER JOIN [dbo].[ChartAuditPhysicianLosVersionItem] vip ON vi.[PrevChartAuditPhysicianLosVersionItemId] = vip.[ChartAuditPhysicianLosVersionItemId]

-- PBA Diagnosis Codes
select pba.[ChartId] 
  ,vi.[ChartAuditDiagnosisVersionItemId]
  ,vi.[IsPreviousVersionCorrect]
  ,vi.[ExcludeFromQA]
  ,vi.[ChartAuditActionTypeCode]
  ,vip.[IsPrimary] As PrevIsPrimary
  ,vi.[IsPrimary]
  ,vip.[ICDCode] As PrevICDCode
  ,vi.[ICDCode]
  into #TempChartPBA_DAA
from #ChartSubsetPBA c
INNER JOIN [dbo].[ChartPostBillAudit] pba ON pba.[ChartId] = c.chart_ID AND pba.[ChartPostBillAuditStatusTypeCode] in (2,3)
INNER JOIN [dbo].[ChartAuditVersion] v ON pba.[ChartPostBillAuditId] = v.[ChartAuditId] AND v.[VersionNumber] = 2
INNER JOIN [dbo].[ChartAuditDiagnosisVersionItem] vi ON vi.[ChartAuditVersionId] = v.[ChartAuditVersionId]
LEFT OUTER JOIN [dbo].[ChartAuditDiagnosisVersionItem] vip ON vi.[PrevChartAuditDiagnosisVersionItemId] = vip.[ChartAuditDiagnosisVersionItemId]
-- End PBAChanges ----------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- All subqueries below were modified to reference the new temp tables (above) which contain small subsets of data from the base tables.  dsexton, 2/14/2022
SELECT
	c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, c.APPROVED_DATE, up.USER_PROFILE_ID,  up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID)
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID)
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND (pr.IS_CODER_CORRECT = 1 OR pr.EXCLUDE_FROM_QA_REPORT = 1))
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND (ac.IS_CODER_CORRECT = 1 OR ac.EXCLUDE_FROM_QA_REPORT = 1))
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR flos.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 or PLOS.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0)
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND ac.EXCLUDE_FROM_QA_REPORT = 0)
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 )
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND ac.EXCLUDE_FROM_QA_REPORT = 0) 
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0)
-- StartChgs anesthesia coding ---------------
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND ac.EXCLUDE_FROM_QA_REPORT = 0)  
-- EndChgs anesthesia coding -----------------
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND flos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND plos.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount,

			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxAttempted,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
			(select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAbstract,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionDeletions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAbstract,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract,

			-- StartChgs anesthesia coding ---------------
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND (ac.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as AnesthesiaCorrect,
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID) as AnesthesiaAttempted, 
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAdditions, 							 
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaRevisions, 							 
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaDeletions, 							 
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAbstract, 		
			-- EndChgs anesthesia coding -----------------	

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAbstract,

			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,

			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,

			(select count(DISTINCT dx.CHART_ID) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
			(select count(DISTINCT dx.CHART_ID) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,
			(select count(DISTINCT dx.CHART_ID) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,

			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges,

			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_FLAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,

			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PLAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,

			-- Functions can perform poorly (especially with large data sets) due to their inherent RBAR processing (row-by-agonizing-row).
			-- The query behind this function (dbo.GetChartDemographicAuditActions) has now been incorporated below directly into this proc so the data can be processed as a set instead of RBAR.  dsexton, 2/14/2022

			--(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges,		-- replaced 2/14/2022 by dsexton
			DemographicChanges = cast(null as int),		-- This value is now populated at the very end of the proc.  dsexton, 2/14/2022

			(select count(DISTINCT pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID) from #TempChartQAS_PAA pr with (NOLOCK)
				Inner Join CHARGE_MASTER cm on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
						and (pr.CODER_CPT_CODE = cm.CPT_CODE OR pr.AUDITOR_CPT_CODE = cm.CPT_CODE)
						and (pr.CODER_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID OR pr.AUDITOR_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID)
						and c.TIME_OF_SERVICE >= cm.EFFECTIVE_DATE AND c.TIME_OF_SERVICE <= cm.EXPIRATION_DATE
						and cm.CHARGE_MASTER_USAGE_CODE = 9 and cm.CPT_CODE > ''
						where c.CHART_ID = pr.CHART_ID and pr.PROCEDURE_TYPE = 'PP' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1
			) as MIPSChanges,

			(select count(DISTINCT pr.CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID) from #TempChartQAS_PAA pr with (NOLOCK)
				Inner Join CHARGE_MASTER cm on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
						and (pr.CODER_CPT_CODE = cm.CPT_CODE OR pr.AUDITOR_CPT_CODE = cm.CPT_CODE)
						and (pr.CODER_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID OR pr.AUDITOR_CHARGE_MASTER_DEPT_ID = cm.CHARGE_MASTER_DEPT_ID)
						and c.TIME_OF_SERVICE >= cm.EFFECTIVE_DATE AND c.TIME_OF_SERVICE <= cm.EXPIRATION_DATE
						and cm.CHARGE_MASTER_USAGE_CODE = 9 and cm.CPT_CODE > ''
						where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'PP'
			) as MIPSSubmitted,

			(select count(DISTINCT di.CHART_ID) from CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION di with (NOLOCK) where c.CHART_ID = di.CHART_ID and di.IS_CODER_CORRECT = 0 and di.EXCLUDE_FROM_QA_REPORT <> 1) as DocumentationDeficiencyChanges,

			(select count(DISTINCT di.CHART_ID) from CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION di with (NOLOCK) where c.CHART_ID = di.CHART_ID) as DocumentationDeficiencySubmitted

			, null as PostBillAuditCompletedDate
		INTO #Results		-- part of tuning by dsexton, 2/14/2022

			FROM	[#ChartSubset] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
			WHERE		c.approved_by_user_profile_id > 2

------------------------------------------------------------------------------------------------------------------------------------------
-- Beginning of section that directly incorporates the query from function dbo.GetChartDemographicAuditActions.  dsexton, 2/14/2022

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
 INTO #ChartTable
from CHART with(nolock)
where chart_ID in (Select Chart_ID from #ChartSubset)

select Chart_ID, Medical_Record_Num, Admission_Date_Time, SERVICE_AGREEMENT_ARRIVAL_MODE_ID, Arrival_Date_Time, PATIENT_DISPOSITION_MAP_ID, PHYSICIAN_ID, TIME_TO_ROOM,
	SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, GENDER, RESIDENT_PARTICIPATED_IN_CARE, FINANCIAL_CLASS_CD, PATIENT_DOB, NURSE_PRACTITIONER_ID, Time_of_Service, PATIENT_DISPOSITION_ID,
	FACILITY_ADMIN_CHART_ID, TIME_OF_DIS, CONDITION_OF_ACCIDENT_ID, CLINIC_ID, ATTESTATION_SIGNED_BY_ATTENDING, SCRIBE_ID, LAST_ENCOUNTER_DATE, LAST_MENSTRUAL_PERIOD,
	PATIENT_AGE, TIME_OF_PHYS_EVAL, TIME_OF_TRIAGE, MEDICAL_EXAMINER_NOTIFIED, ORGAN_DONATION, USE_TIME_BASED_CHARGE_CAPTURE, SEEN_IN_ED_WITHIN_48_HOURS_OF_OR
 INTO #ChartDemoHX
from CHART_DEMOGRAPHIC_HISTORY with(nolock)
where Chart_ID in (Select Chart_ID from #ChartSubset)

create table #DemoAuditChartIDs (Chart_ID int)

insert into #DemoAuditChartIDs

		-- Add the SELECT statement with parameter references here
		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
			AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
			AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM
		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
		WHERE
			ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
		WHERE
			ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON c.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
		WHERE
			ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_MAP_ID, - 1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON cdh.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
		WHERE
			ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_MAP_ID, - 1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON c.PHYSICIAN_ID = fp.FACILITY_PROF_ID			--here
		WHERE
			ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON cdh.PHYSICIAN_ID = fp.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE
			ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
			AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
			AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE
			ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
			AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
			AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
		WHERE
			ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND ffc.FINANCIAL_CLASS_CD = cdh.FINANCIAL_CLASS_CD
		WHERE
			ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
		WHERE
			ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON c.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON cdh.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		WHERE
			ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = cdh.PATIENT_DISPOSITION_ID
		WHERE
			ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND coa.CONDITION_OF_ACCIDENT_ID = c.CONDITION_OF_ACCIDENT_ID
		WHERE
			ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
			AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND coa.CONDITION_OF_ACCIDENT_ID = cdh.CONDITION_OF_ACCIDENT_ID
		WHERE
			ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
			AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND cl.CLINIC_ID = c.CLINIC_ID
		WHERE
			ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			AND cl.CLINIC_ID = cdh.CLINIC_ID
		WHERE
			ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON c.SCRIBE_ID = s.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
			AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON cdh.SCRIBE_ID = s.FACILITY_PROF_ID
		WHERE
			ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
			AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
			AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
			AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
			AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')

		---- Time Based Physician LOS
		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE, 0) <> 0
			AND ISNULL(c.USE_TIME_BASED_CHARGE_CAPTURE, '') <> ISNULL(cdh.USE_TIME_BASED_CHARGE_CAPTURE, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE, 0) <> 0
			AND ISNULL(c.USE_TIME_BASED_CHARGE_CAPTURE, '') <> ISNULL(cdh.USE_TIME_BASED_CHARGE_CAPTURE, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		WHERE
			ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
			AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
			AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')

		UNION

		SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN CHART_CONSULTING_PHYSICIAN ccp WITH (NOLOCK) ON c.CHART_ID = ccp.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
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

	  UNION
	  SELECT c.Chart_ID
		FROM #ChartTable c
		INNER JOIN CHART_CONSULTING_PHYSICIAN_HISTORY ccph WITH (NOLOCK) ON c.CHART_ID = ccph.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
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


update #Results set DemographicChanges = 1 where chart_ID in (Select Chart_ID from #DemoAuditChartIDs)
update #Results set DemographicChanges = 0 where DemographicChanges is null

--- Add PBA rows.-----------------------------------------------------------------------------------------
-- PBAChanges ----------------------------------------------------

SELECT 
	c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, 
	c.APPROVED_DATE, up.USER_PROFILE_ID,  up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId)
			+ (select count(*) from #TempChartPBA_AAA ac with (NOLOCK)  where c.CHART_ID = ac.ChartId)
			+ (select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId)
			+ (select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId)
			+ (select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId) as TotalCodesCount,

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND (pr.IsPreviousVersionCorrect = 1 OR pr.ExcludeFromQA = 1))
			+ (select count(*) from #TempChartPBA_AAA ac with (NOLOCK)  where c.CHART_ID = ac.ChartId  AND (ac.IsPreviousVersionCorrect = 1 OR ac.ExcludeFromQA = 1))
			+ (select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId  AND (flos.IsPreviousVersionCorrect = 1 OR flos.ExcludeFromQA = 1))
			+ (select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND (plos.IsPreviousVersionCorrect = 1 or PLOS.ExcludeFromQA = 1))
			+ (select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId AND (dx.IsPreviousVersionCorrect = 1 OR dx.ExcludeFromQA = 1)) as TotalCorrectCodesCount,

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 1 AND pr.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_AAA ac with (NOLOCK)  where c.CHART_ID = ac.ChartId  AND ac.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 1 AND ac.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId  AND flos.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 1 AND flos.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND plos.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 1  AND plos.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId AND dx.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 1 AND dx.ExcludeFromQA = 0) as TotalRevisedCodesCount,

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 2 AND pr.ExcludeFromQA = 0 )
			+ (select count(*) from #TempChartPBA_AAA ac with (NOLOCK)  where c.CHART_ID = ac.ChartId  AND ac.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 2 AND ac.ExcludeFromQA = 0) 
			+ (select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId  AND flos.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 2 AND flos.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND plos.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 2 AND plos.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId AND dx.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 2 AND dx.ExcludeFromQA = 0) as TotalAddedCodesCount,

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 5 AND pr.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_AAA ac with (NOLOCK)  where c.CHART_ID = ac.ChartId  AND ac.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 5 AND ac.ExcludeFromQA = 0)  
			+ (select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId  AND flos.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 5 AND flos.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND plos.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 5 AND plos.ExcludeFromQA = 0)
			+ (select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId AND dx.IsPreviousVersionCorrect = 0 AND ChartAuditActionTypeCode = 5 AND dx.ExcludeFromQA = 0) as TotalDeletedCodesCount,

			(select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId AND (dx.IsPreviousVersionCorrect = 1 OR dx.ExcludeFromQA = 1)) as DxCorrect,
			(select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId) as DxAttempted,
			(select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId and dx.ChartAuditActionTypeCode = 2 AND dx.ExcludeFromQA <> 1) as DxAdditions,
			(select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId and dx.ChartAuditActionTypeCode = 1 AND dx.ExcludeFromQA <> 1) as DxRevisions,
			(select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId and dx.ChartAuditActionTypeCode = 5 AND dx.ExcludeFromQA <> 1) as DxDeletions,
			(select count(*) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId and dx.ChartAuditActionTypeCode = 3 AND dx.ExcludeFromQA <> 1) as DxAbstract,

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'FP' AND (pr.IsPreviousVersionCorrect = 1 OR pr.ExcludeFromQA = 1)) as FacilityProcCorrect,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'FP') as FacilityProcAttempted,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'FP' AND pr.ChartAuditActionTypeCode = 2 AND ExcludeFromQA <> 1) as FacilityProcAdditions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'FP' AND pr.ChartAuditActionTypeCode = 1 AND ExcludeFromQA <> 1) as FacilityProcRevisions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'FP' AND pr.ChartAuditActionTypeCode = 5 AND ExcludeFromQA <> 1) as FacilityProcDeletions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'FP' AND pr.ChartAuditActionTypeCode = 3 AND ExcludeFromQA <> 1) as FacilityProcAbstract,

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'CI' AND (pr.IsPreviousVersionCorrect = 1 OR pr.ExcludeFromQA = 1)) as InfusionInjectionCorrect,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'CI') as InfusionInjectionAttempted,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'CI' AND pr.ChartAuditActionTypeCode = 2 AND pr.ExcludeFromQA <> 1) as InfusionInjectionAdditions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'CI' AND pr.ChartAuditActionTypeCode = 1 AND pr.ExcludeFromQA <> 1) as InfusionInjectionRevisions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'CI' AND pr.ChartAuditActionTypeCode = 5 AND pr.ExcludeFromQA <> 1) as InfusionInjectionDeletions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'CI' AND pr.ChartAuditActionTypeCode = 3 AND pr.ExcludeFromQA <> 1) as InfusionInjectionAbstract,

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'PP' AND (pr.IsPreviousVersionCorrect = 1 OR pr.ExcludeFromQA = 1)) as ProfProcCorrect,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'PP') as ProfProcAttempted,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'PP' AND pr.ChartAuditActionTypeCode = 2 AND pr.ExcludeFromQA <> 1) as ProfProcAdditions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'PP' AND pr.ChartAuditActionTypeCode = 1 AND pr.ExcludeFromQA <> 1) as ProfProcRevisions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'PP' AND pr.ChartAuditActionTypeCode = 5 AND pr.ExcludeFromQA <> 1) as ProfProcDeletions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'PP' AND pr.ChartAuditActionTypeCode = 3 AND pr.ExcludeFromQA <> 1) as ProfProcAbstract,

			(select count(*) from #TempChartPBA_AAA ac with (NOLOCK) where c.CHART_ID = ac.ChartId AND (ac.IsPreviousVersionCorrect = 1 OR ac.ExcludeFromQA = 1)) as AnesthesiaCorrect,
			(select count(*) from #TempChartPBA_AAA ac with (NOLOCK) where c.CHART_ID = ac.ChartId) as AnesthesiaAttempted, 
			(select count(*) from #TempChartPBA_AAA ac with (NOLOCK) where c.CHART_ID = ac.ChartId AND ac.ChartAuditActionTypeCode = 2 AND ac.ExcludeFromQA <> 1) as AnesthesiaAdditions, 							 
			(select count(*) from #TempChartPBA_AAA ac with (NOLOCK) where c.CHART_ID = ac.ChartId AND ac.ChartAuditActionTypeCode = 1 AND ac.ExcludeFromQA <> 1) as AnesthesiaRevisions, 							 
			(select count(*) from #TempChartPBA_AAA ac with (NOLOCK) where c.CHART_ID = ac.ChartId AND ac.ChartAuditActionTypeCode = 5 AND ac.ExcludeFromQA <> 1) as AnesthesiaDeletions, 							 
			(select count(*) from #TempChartPBA_AAA ac with (NOLOCK) where c.CHART_ID = ac.ChartId AND ac.ChartAuditActionTypeCode = 3 AND ac.ExcludeFromQA <> 1) as AnesthesiaAbstract, 			

			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'OB' AND (pr.IsPreviousVersionCorrect = 1 OR pr.ExcludeFromQA = 1)) as ObsHoursCorrect,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'OB') as ObsHoursAttempted,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'OB' AND pr.ChartAuditActionTypeCode = 2 AND pr.ExcludeFromQA <> 1) as ObsHoursAdditions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'OB' AND pr.ChartAuditActionTypeCode = 1 AND pr.ExcludeFromQA <> 1) as ObsHoursRevisions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'OB' AND pr.ChartAuditActionTypeCode = 5 AND pr.ExcludeFromQA <> 1) as ObsHoursDeletions,
			(select count(*) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId AND pr.ProcedureType = 'OB' AND pr.ChartAuditActionTypeCode = 3 AND pr.ExcludeFromQA <> 1) as ObsHoursAbstract,

			(select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId  AND (flos.IsPreviousVersionCorrect = 1 OR flos.ExcludeFromQA = 1)) as FacilityLOSCorrect,
			(select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId) as FacilityLOSAttempted,
			(select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId AND flos.ChartAuditActionTypeCode = 2 AND flos.ExcludeFromQA <> 1) as FacilityLOSAdditions,
			(select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId AND flos.ChartAuditActionTypeCode = 1 AND flos.ExcludeFromQA <> 1) as FacilityLOSRevisions,
			(select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId AND flos.ChartAuditActionTypeCode = 5 AND flos.ExcludeFromQA <> 1) as FacilityLOSDeletions,
			(select count(*) from #TempChartPBA_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.ChartId AND flos.ChartAuditActionTypeCode = 3 AND flos.ExcludeFromQA <> 1) as FacilityLOSAbstract,

			(select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND (plos.IsPreviousVersionCorrect = 1 OR plos.ExcludeFromQA = 1))  as PhysicianLOSCorrect,
			(select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId) as PhysicianLOSAttempted,
			(select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND plos.ChartAuditActionTypeCode = 2 AND plos.ExcludeFromQA <> 1) as PhysicianLOSAdditions,
			(select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND plos.ChartAuditActionTypeCode = 1 AND plos.ExcludeFromQA <> 1) as PhysicianLOSRevisions,
			(select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND plos.ChartAuditActionTypeCode = 5 AND plos.ExcludeFromQA <> 1) as PhysicianLOSDeletions,
			(select count(*) from #TempChartPBA_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.ChartId  AND plos.ChartAuditActionTypeCode = 3 AND plos.ExcludeFromQA <> 1) as PhysicianLOSAbstract,

			-- for PBA, we are not currently tracking if the chief complaint or dx code changed between versions.
			0 as DxChiefComplaintChanges,
			0 as DxPrimaryDxChanges,

			(select count(DISTINCT dx.ChartId) from #TempChartPBA_DAA dx with (NOLOCK) where c.CHART_ID = dx.ChartId) as DxChartsSubmitted,

			(select count(DISTINCT pr.ChartId) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId and ProcedureType = 'CI' and pr.IsPreviousVersionCorrect = 0 and pr.ExcludeFromQA <> 1) as InfInjChanges,
			(select count(DISTINCT pr.ChartId) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId and ProcedureType = 'CI') as InfInjSubmitted,
			(select count(DISTINCT pr.ChartId) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId and ProcedureType = 'OB' and pr.IsPreviousVersionCorrect = 0 and pr.ExcludeFromQA <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.ChartId) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId and ProcedureType = 'OB') as ObsHoursSubmitted,
			(select count(DISTINCT pr.ChartId) from #TempChartPBA_PAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId and pr.PrevModifier <> pr.Modifier and pr.ExcludeFromQA <> 1) as ProcModifierChanges,

			(select count(DISTINCT pr.ChartId) from #TempChartPBA_FLAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId and pr.PrevModifier <> pr.Modifier and pr.ExcludeFromQA <> 1) as FacilityLOSModifierChanges,

			(select count(DISTINCT pr.ChartId) from #TempChartPBA_PLAA pr with (NOLOCK) where c.CHART_ID = pr.ChartId and pr.PrevModifier <> pr.Modifier and pr.ExcludeFromQA <> 1) as PhysicianLOSModifierChanges,

			DemographicChanges = cast(null as int),		-- This value is now populated at the very end of the proc.  dsexton, 2/14/2022

			(select count(DISTINCT pr.ChartAuditProcedureVersionItemId) from #TempChartPBA_PAA pr with (NOLOCK)
				Inner Join CHARGE_MASTER cm on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
						and (pr.PrevCptCode = cm.CPT_CODE OR pr.CptCode = cm.CPT_CODE)
						and (pr.PrevChargeMasterDeptId = cm.CHARGE_MASTER_DEPT_ID OR pr.ChargeMasterDeptId = cm.CHARGE_MASTER_DEPT_ID)
						and c.TIME_OF_SERVICE >= cm.EFFECTIVE_DATE AND c.TIME_OF_SERVICE <= cm.EXPIRATION_DATE
						and cm.CHARGE_MASTER_USAGE_CODE = 9 and cm.CPT_CODE > ''
						where c.CHART_ID = pr.ChartId and pr.ProcedureType = 'PP' and pr.IsPreviousVersionCorrect = 0 and pr.ExcludeFromQA <> 1
			) as MIPSChanges,

			(select count(DISTINCT pr.ChartAuditProcedureVersionItemId) from #TempChartPBA_PAA pr with (NOLOCK)
				Inner Join CHARGE_MASTER cm on c.SERVICE_AGREEMENT_ID = cm.SERVICE_AGREEMENT_ID
						and (pr.PrevCptCode = cm.CPT_CODE OR pr.CptCode = cm.CPT_CODE)
						and (pr.PrevChargeMasterDeptId = cm.CHARGE_MASTER_DEPT_ID OR pr.ChargeMasterDeptId = cm.CHARGE_MASTER_DEPT_ID)
						and c.TIME_OF_SERVICE >= cm.EFFECTIVE_DATE AND c.TIME_OF_SERVICE <= cm.EXPIRATION_DATE
						and cm.CHARGE_MASTER_USAGE_CODE = 9 and cm.CPT_CODE > ''
						where c.CHART_ID = pr.ChartId and pr.ProcedureType = 'PP'
			) as MIPSSubmitted,
			0 as DocumentationDeficiencyChanges,
			--(select count(DISTINCT di.[ChartAuditDocumentationVersionItemId] from [dbo].[ChartAuditDocumentationVersionItem] di with (NOLOCK) where c.CHART_ID = di.CHART_ID and di.IS_CODER_CORRECT = 0 and di.EXCLUDE_FROM_QA_REPORT <> 1) as DocumentationDeficiencyChanges,
			0 as DocumentationDeficiencySubmitted,
			--(select count(DISTINCT di.CHART_ID) from CHART_QA_SCORECARD_DOCUMENTATION_INEQUITY_AUDIT_ACTION di with (NOLOCK) where c.CHART_ID = di.CHART_ID) as DocumentationDeficiencySubmitted,
			--null as PostBillAuditCompletedDate
			ISNULL(c.POST_BILL_AUDIT_COMPLETED,getdate()) as PostBillAuditCompletedDate

			INTO #ResultsPBA

			FROM	[#ChartSubsetPBA] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID

--DEBUG select * from #Results2
---End PBAChanges -----------------

select * from #Results r
UNION
select * from #ResultsPBA

--where r.TotalAddedCodesCount + r.TotalDeletedCodesCount + r.TotalRevisedCodesCount > 0 --only charts with errors

-- end of section to replace the call to function dbo.GetChartDemographicAuditActions.  dsexton, 2/14/2022
---------------------------------------------------------------------------------------------------------------------------


END
GO


-- End of 1) DACS-3403 - Create or Alter Proc CODER_QA_SCORECARD_GET_CHART_SUMMARY.SQL
GO

-- Start of 01) DACS-3453 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 187 (old).SQL

------------------------------------------------------------------------------------
-- 01) DACS-3453 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 187 (old).SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '187';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
			,'MIPS# ' + @PqrsCd + ' : Stroke and Stroke Rehabilitation: Thrombolytic Therapy : Percentage of patients aged 18 years and older with a diagnosis of acute ischemic stroke who arrive at the hospital within 3.5 hours of time last known well and for whom IV thrombolytic therapy was initiated within 4.5 hours of time last known well. '	
			,'B'
			,18
			,999
			,'2024-01-01'
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '187' -- = 214
*/
-- End of 01) DACS-3453 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 187 (old).SQL
GO

-- Start of 02) DACS-3453 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 187.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3453 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 187.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '187';
	DECLARE @Dos DATETIME = '01-01-2024';

	DECLARE @MeasureId INT = 
		(
			SELECT [CMS_PQRI_MEASURE_ID]
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('No Measure loaded for 187.  Cannot continue.');
		SELECT 'Error' = -1;
		RETURN;
	END;

	PRINT('@MeasureId = ' + CAST(@MeasureId AS VARCHAR(30)));

	DECLARE @countPQRSCodes INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodes' = @countPQRSCodes; -- testing


	IF @countPQRSCodes > 0
	BEGIN 
		PRINT('Found Measure Codes.  Expiring existing.');
	
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [END_DATE] = DATEADD(minute,-1,CAST(CAST(@Dos AS DATE) AS DATETIME))
		WHERE
			[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND [START_DATE] <= @Dos
			AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
			AND [CODE] IS NOT NULL
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	END;

	DECLARE @countPQRSCodesAfterExpiration INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- Diagnosis for ischemic stroke (ICD-10-CM)
		 (@MeasureId,'DG1P1','I63.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.013',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.031',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.032',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.033',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.039',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.131',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.132',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.133',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.139',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.321',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.322',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.323',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.329',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.331',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.332',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.333',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.339',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.343',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.421',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.422',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.423',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.429',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.431',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.432',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.433',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.439',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.441',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.442',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.443',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.449',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.9',NULL,@Dos,NULL)

		-- Patient encounter during performance period (CPT)
		,(@MeasureId,'DG1P2','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)

		-- WITHOUT Telehealth Modifier (including but not limited to)
		,(@MeasureId,'DG2P1',NULL,'GQ',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'GT',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'95',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'POS 02',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'POS 10',@Dos,NULL)
		 
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8600',NULL,@Dos,'Performance Met: IV thrombolytic therapy initiated within 4.5 hours (≤ 270 minutes) of time last known well. ')
		,(@MeasureId,'HCPCS','G8602',NULL,@Dos,'Performance Not Met: IV thrombolytic therapy not initiated within 4.5 hours (≤ 270 minutes) of time last known well, reason not given. ')
		,(@MeasureId,'HCPCS','G8601',NULL,@Dos,'Denominator Exception: IV thrombolytic therapy not initiated within 4.5 hours (≤ 270 minutes) of time last known well for reasons documented by clinician (e.g. patient enrolled in clinical trial for stroke, patient admitted for elective carotid intervention). ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Was time last known well to hospital arrival less than or equal to 3.5 hours (≤ 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p> ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 113 total inserts
		
		
	DECLARE @countPQRSCodesFinal INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesFinal' = @countPQRSCodesFinal;

	-- testing:
	SELECT 
		*
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '187' -- = 214
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 214
*/
-- End of 02) DACS-3453 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 187.SQL
GO

-- Start of 03) DACS-3453 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3453 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of 187, there are 1 valid decision paths.  the data is stored by PQRS# '187' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH = 0); -- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data or failed USE_TELEHEALTH field check.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND [LOCATION_OF_SERVICE] IN ('02','10')
		)
	BEGIN 
		PRINT('@ChartId has an excluded telehealth Location of Service value of (02 or 10) : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [MODIFIERS] IN (SELECT [MODIFIER] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup1Pick2MatchCount > 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '187' -- = 214

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187
	@ChartId = 2100112304
	,@PqrsNum = '187'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3453 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type187].SQL
GO

-- Start of 01) DACS-3221 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR39.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3221 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR39.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ECPR39';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Process'
			,@PqrsCd + ' : Avoid Head CT for Patients with Uncomplicated Syncope : Percentage of Adult Syncope Patients Who Did Not Receive a Head CT Scan Ordered by the Provider. '
			,'B'
			,18
			,999
			,@Dos
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR39' -- = 223
*/
-- End of 01) DACS-3221 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR39.SQL
GO

-- Start of 02) DACS-3221 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR39.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3221 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR39.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ECPR39';
	DECLARE @Dos DATETIME = '01-01-2024';

	DECLARE @MeasureId INT = 
		(
			SELECT [CMS_PQRI_MEASURE_ID]
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('No Measure loaded for [' + @PqrsCd + '].  Cannot continue.');
		SELECT 'Error' = -1;
		RETURN;
	END;

	PRINT('@MeasureId = ' + CAST(@MeasureId AS VARCHAR(30)));

	DECLARE @countPQRSCodes INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodes' = @countPQRSCodes; -- testing


	IF @countPQRSCodes > 0
	BEGIN 
		PRINT('Found Measure Codes.  Expiring existing.');
	
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [END_DATE] = DATEADD(minute,-1,CAST(CAST(@Dos AS DATE) AS DATETIME))
		WHERE
			[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND [START_DATE] <= @Dos
			AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
			AND [CODE] IS NOT NULL
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	END;

	DECLARE @countPQRSCodesAfterExpiration INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- Diagnosis of Syncope (ICD‐10)
		 (@MeasureId,'DG1P1','R55',NULL,@Dos,NULL)

		-- Inpatient or Observation Status settings (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99292',NULL,@Dos,NULL)
		 
		-- measure code numerators
		-- SELECTION
		--,(@MeasureId,'HCPCS','V0700',NULL,@Dos,'DENOMINATOR EXCLUSION: Was the patient Transferred, eloped or AMA patients are excluded (V0700). ')
		,(@MeasureId,'HCPCS','VE250',NULL,@Dos,'Performance Met: Patients who did not have a head CT ordered. ')
		,(@MeasureId,'HCPCS','VE252',NULL,@Dos,'Performance Not Met: Patients who did have a Head CT ordered; reason not given. ')
		,(@MeasureId,'HCPCS','VE251',NULL,@Dos,'Denominator Exception:  Patients who did have a heat CT ordered for medical reason documented by the eligible professional (i.e., Seizure; alcohol/drug intoxication; vomiting; altered mental status; abnormal neurologic exam; concern for intracranial injury/hemorrhage, stroke, or mass lesion). ')
				
		-- PQRS Question for response by coder within ACS		
		-- QUESTION
		,(@MeasureId,'DQ411','V0700',NULL,@Dos,'Patient did NOT Transfer, elope and not an AMA patient (these are excluded) (V0700)? ')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 32 total inserts
		
		
	DECLARE @countPQRSCodesFinal INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesFinal' = @countPQRSCodesFinal;

	-- testing:
	SELECT 
		*
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR39' -- = 223
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 223
*/
-- End of 02) DACS-3221 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR39.SQL
GO

-- Start of 03) DACS-3221 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3221 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		--AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data check.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF NOT EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('1','2','3','6','7','8','9','11') OR [LOCATION_OF_SERVICE] IN ('02','11','19','20','21','22','23'))
		)
	BEGIN 
		PRINT('@ChartId does not have a valid patient class type of (1,2,3,6,7,8,9,11) OR Location of Service of (02, 11, 19, 20, 21, 22 or 23) to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid patient class type of (1,2,3,6,7,8,9,11) OR Location of Service of (02, 11, 19, 20, 21, 22 or 23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have an (ICD-10)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of Syncope (ICD‐10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Inpatient or Observation Status settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR39' -- = 223
select top 200 * from CMS_PQRI_MEASURE_code where CMS_PQRI_MEASURE_ID = 223

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39
	@ChartId = 2100112637
	,@PqrsNum = 'ECPR39'
	,@Dos = '7/11/2024 2:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3221 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR39].SQL
GO

-- Start of 01) DACS-3205 Insert Table Type_Code.sql

------------------------------------------------------------------------------------
-- 01) DACS-3205 - Insert record into Table [TYPE_CODE] for ApplicationFeature for Provider Cache
------------------------------------------------------------------------------------

GO

INSERT INTO 
    [TYPE_CODE]
(
    [TYPE_CODE].[NAME]
   ,[TYPE_CODE].[KEY]
   ,[TYPE_CODE].[VALUE]
   ,[TYPE_CODE].[DISPLAY_NAME]
   ,[TYPE_CODE].[SHORT_NAME]
   ,[TYPE_CODE].[DESCRIPTION]
)
VALUES
(
    'ApplicationFeatureTypeCode'                                                --NAME
   ,'ProviderCache'                                                             --KEY
   ,3                                                                           --VALUE
   ,'Provider Cache'                                                            --DISPLAY_NAME
   ,'PC'                                                                        --SHORT_NAME
   ,'Turns On/Off Provider Cache for SimpleFacilityProfessionalsListDAO'        --DESCRIPTION
)
-- End of 01) DACS-3205 Insert Table Type_Code.sql
GO

-- Start of 02) DACS-3205 Insert Table Application_Feature.sql

------------------------------------------------------------------------------------
-- 02) DACS-3205 - Insert record into Table [ApplicationFeature] For limited facilities that starts with "PeaceHealth"
------------------------------------------------------------------------------------

GO

INSERT INTO [dbo].[ApplicationFeature]
           ([DateTimeCreated]
           ,[CreatedByUserProfileId]
           ,[DateTimeLastUpdated]
           ,[LastUpdatedByUserProfileId]
           ,[ApplicationFeatureDomainObjectTypeCode]
           ,[DomainObjectId]
           ,[ApplicationFeatureTypeCode])
     SELECT
	       GETDATE(), 10149, GETDATE(), 10149, 2, Facility_Id, 3
	 FROM [Facility]
	 WHERE
		facility_number <> ''
		AND name LIKE 'PeaceHealth -%'
GO


-- End of 02) DACS-3205 Insert Table Application_Feature.sql
GO

-- Start of 03) DACS-3205 Stored Proc SelectFacilityProfessionalByChartDateOfServiceAndFacilityIdAndRoleIdList.sql

------------------------------------------------------------------------------------
-- 03) DACS-3205 - Created New stored procedure to get Facility Professionals
------------------------------------------------------------------------------------

Go

CREATE OR ALTER PROCEDURE dbo.SelectFacilityProfessionalByChartDateOfServiceAndFacilityIdAndRoleIdList
@ChartDateOfService DATETIME,
@FacilityId INT,
@RoleIdList VARCHAR(4000)
AS
BEGIN
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		 fp.FACILITY_PROF_ID
		,fp.FIRST_NAME
		,fp.MIDDLE_NAME
		,fp.LAST_NAME
		,fp.NAME_SUFFIX
		,fp.EMPLOYEE_IDENTIFIER
		,fp.UPIR_ID
		,fp.ROLE_ID
		,fp.PROVIDER_BUSINESS_UNIT_ID 
	FROM 
		FACILITY_PROFESSIONAL fp 
		LEFT OUTER JOIN FACILITY_PROFESSIONAL_LOCUM_ASSIGNMENT fpla
		ON fpla.LOCUM_PHYSICIAN_ID = fp.FACILITY_PROF_ID 
		AND @ChartDateOfService BETWEEN fpla.EFFECTIVE_DATE AND fpla.EXPIRATION_DATE
	WHERE 
		fp.FACILITY_ID = @FacilityId
		AND 
		(
			@ChartDateOfService IS NULL 
			OR 
			@ChartDateOfService BETWEEN fp.EFFECTIVE_DATE AND ISNULL(fp.EXPIRATION_DATE, GETDATE())
		)
		AND
		(
			fp.ROLE_ID <> 9
			OR
			fpla.LOCUM_PHYSICIAN_ID IS NOT NULL
		)
		AND 
		(
			@RoleIdList = '-1'
			OR
			fp.ROLE_ID IN (SELECT * FROM dbo.SplitString(@RoleIdList, ','))
		)
	ORDER BY 
		fp.LAST_NAME, fp.FIRST_NAME
END
GO
-- End of 03) DACS-3205 Stored Proc SelectFacilityProfessionalByChartDateOfServiceAndFacilityIdAndRoleIdList.sql
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
