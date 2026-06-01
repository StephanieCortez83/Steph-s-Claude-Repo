SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[CoderQAScorecard_MaintainHx_CoderSummary_dsTest] 
--declare		-- for testing
	@pStartDate datetime,			-- submit as NULL when calling the sproc unless a specific date range needs to be processed outside of automatic processing
	@pEndDate datetime,				-- submit as NULL if also submitting NULL for @pStartDate
	@Category int = 2,				-- 1 = capture only new entries for the Hx table; 2 (default) = capture new entries as well as updates for existing entries in the Hx table
	@RangeSecondsAdd int = 899,		-- 899 (default) = 15-minute range less one second; 299 = 5-minute range; 1799 = 30-minute range; 3599 = 60-minute range
	@HistoryDaysToRetain int = 35,	-- based on Approved_Date derived from the CHART table
	@UpdateControlDates int = 1		-- 1 (default) = yes; 0 = no.  Can use 0 to conditionally override the update if, for example, you want the SQL Agent job to process both Category 1 and Category 2 for the same date range.
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;	

	declare @StartDate datetime
	declare @EndDate datetime
	declare @RowsAffected int

if @Category not in (1, 2)
begin
	print '@Category must be either 1 (capture only new entries) or 2 (capture new and updated entries).'
	RETURN
end

if @HistoryDaysToRetain < 10 
begin
	print '@HistoryDaysToRetain is too low. Resetting @HistoryDaysToRetain to the required minimum value of 10. Processing will continue.'
	set @HistoryDaysToRetain = 10		-- ensure at least 10 days of history are retained
end

if @RangeSecondsAdd not in (299, 899, 1799, 3599)
begin
	print '@RangeSecondsAdd must be one of four allowed values: 299 (5-minutes), 899 (15 minutes), 1799 (30 minutes), or 3599 (60 minutes).'
	RETURN
end

if (@pStartDate is not null and @pEndDate is null)
	or (@pStartDate is null and @pEndDate is not null)
begin
	print 'If providing a non-NULL value for @pStartDate or @pEndDate, a non-NULL value must also be provided for the other date parameter.'
	RETURN
end

if @pStartDate is null
begin
	select @StartDate = DateAdd(second, 1, EndDate) from DBA..CoderQAScorecardHx_Control where Category = 'CoderSummary'
	select @EndDate = DateAdd(second, @RangeSecondsAdd, @StartDate) 
end
else
begin
	set @StartDate = @pStartDate
	set @EndDate = @pEndDate
end

if @StartDate >= @EndDate
begin
	print 'Invalid configuration. @StartDate must be > @EndDate.'
	RETURN
end

if datediff(day, @StartDate, @EndDate) > 1
begin
	print 'To minimize processing overhead, @StartDate and @EndDate should be no more than one day apart.'
	RETURN
end

--select @pStartDate, @StartDate, @pEndDate, @EndDate		-- for testing


if object_id('TempDB..#ChartIDs', 'U') is not null drop table #ChartIDs	
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset
if object_id('TempDB..#TempChartQAS_PAA', 'U') is not null drop table #TempChartQAS_PAA
if object_id('TempDB..#TempChartQAS_FLAA', 'U') is not null drop table #TempChartQAS_FLAA
if object_id('TempDB..#TempChartQAS_PLAA', 'U') is not null drop table #TempChartQAS_PLAA
if object_id('TempDB..#TempChartQAS_DAA', 'U') is not null drop table #TempChartQAS_DAA
if object_id('TempDB..#ChartTable', 'U') is not null drop table #ChartTable
if object_id('TempDB..#ChartDemoHX', 'U') is not null drop table #ChartDemoHX
if object_id('TempDB..#DemoAuditChartIDs', 'U') is not null drop table #DemoAuditChartIDs
if object_id('TempDB..#TempChartQAS_AAA', 'U') is not null drop table #TempChartQAS_AAA
if object_id('TempDB..#Results', 'U') is not null drop table #Results

if @category = 2
BEGIN
	create table #ChartIDs (Chart_ID int)

	insert into #ChartIDs
	select distinct Chart_ID from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION 
	where changed_date_time between @StartDate and @EndDate and Chart_ID not in (select Chart_ID from #ChartIDs)

	insert into #ChartIDs
	select distinct Chart_ID from CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION 
	where changed_date_time between @StartDate and @EndDate and Chart_ID not in (select Chart_ID from #ChartIDs)

	insert into #ChartIDs
	select distinct Chart_ID from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION 
	where changed_date_time between @StartDate and @EndDate and Chart_ID not in (select Chart_ID from #ChartIDs)

	insert into #ChartIDs
	select distinct Chart_ID from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION 
	where changed_date_time between @StartDate and @EndDate and Chart_ID not in (select Chart_ID from #ChartIDs)

	insert into #ChartIDs
	select distinct Chart_ID from CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION 
	where changed_date_time between @StartDate and @EndDate and Chart_ID not in (select Chart_ID from #ChartIDs)
END 

-- create an empty #ChartSubset temp table
	select
		chart_id = cast(null as int),	-- use this method to avoid inheriting the identity property
		completed_by_user_profile_id, 
		time_of_service, 
		service_agreement_id, 
		facility_chart_id, 
		APPROVED_DATE, 
		approved_by_user_profile_id,
		Approval_Reason_Code
	into #ChartSubset
	from CHART
	where 1 = 0

if @category = 1		-- capture new entries for the Hx table
BEGIN
	--This approach generates <300 LReads when processing a one-hour range for @StartDate and @EndDate.
	insert into #ChartSubset
	SELECT	
		chart_id, 
		completed_by_user_profile_id = null, 
		time_of_service = null, 
		service_agreement_id = null, 
		facility_chart_id = null, 
		APPROVED_DATE = null, 
		approved_by_user_profile_id = null,
		Approval_Reason_Code = null
	FROM chart
	WHERE CHART_STATUS_ID in (4, 5)	
		and APPROVED_BY_USER_PROFILE_ID > 2 
		and approval_reason_code = 3
		and approved_date between @StartDate and @EndDate	-- captures new entries for the Hx table
END
else if @category = 2		-- capture new entries as well as updates for existing entries in the Hx table
BEGIN
	insert into #ChartSubset
	SELECT
		chart_id, 
		completed_by_user_profile_id = null, 
		time_of_service = null, 
		service_agreement_id = null, 
		facility_chart_id = null, 
		APPROVED_DATE = null, 
		approved_by_user_profile_id = null,
		Approval_Reason_Code = null
	FROM chart 
	WHERE CHART_STATUS_ID in (4, 5)	
		and APPROVED_BY_USER_PROFILE_ID > 2 
		and approval_reason_code = 3
		and Chart_ID in (select Chart_ID from #ChartIDs)	-- captures new entries as well as updates for existing entries in the Hx table
END

update t		-- 15K LReads when processing a one-hour range for @StartDate and @EndDate.
set t.completed_by_user_profile_id = c.completed_by_user_profile_id,
	t.time_of_service = c.time_of_service,
	t.service_agreement_id = c.service_agreement_id, 
	t.facility_chart_id = c.facility_chart_id, 
	t.APPROVED_DATE = c.APPROVED_DATE, 
	t.approved_by_user_profile_id = c.approved_by_user_profile_id
	, t.Approval_Reason_Code = c.approval_reason_code
from #ChartSubset as t join chart as c with(nolock) on t.chart_ID = c.chart_ID


select t.Chart_ID, CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, PROCEDURE_TYPE, CODER_MODIFIER, 
		AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE, CODER_CHARGE_MASTER_DEPT_ID, AUDITOR_CHARGE_MASTER_DEPT_ID
	into #TempChartQAS_PAA
from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION,  
		CODER_ANESTHESIA_CODE, AUDITOR_ANESTHESIA_CODE
	into #TempChartQAS_AAA
from CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
	into #TempChartQAS_FLAA
from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
	into #TempChartQAS_PLAA
from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, IS_CHIEF_COMPLAINT_CHANGE, IS_PRIMARY_DIAGNOSIS_CHANGE
	into #TempChartQAS_DAA
from CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID


SELECT		
	c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, c.APPROVED_DATE, up.USER_PROFILE_ID,  up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID)
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) 
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND (pr.IS_CODER_CORRECT = 1 OR pr.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND (ac.IS_CODER_CORRECT = 1 OR ac.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR flos.EXCLUDE_FROM_QA_REPORT = 1))  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 or PLOS.EXCLUDE_FROM_QA_REPORT = 1)) 
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND ac.EXCLUDE_FROM_QA_REPORT = 0)
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 ) 
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND ac.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #TempChartQAS_DAA dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #TempChartQAS_AAA ac with (NOLOCK)  where c.CHART_ID = ac.CHART_ID  AND ac.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND ac.EXCLUDE_FROM_QA_REPORT = 0)  
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

			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND (ac.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as AnesthesiaCorrect,
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID) as AnesthesiaAttempted, 
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAdditions, 							 
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaRevisions, 							 
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaDeletions, 							 
			(select count(*) from #TempChartQAS_AAA ac with (NOLOCK) where c.CHART_ID = ac.CHART_ID AND ac.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAbstract, 		

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
			-- The query behind this function (dbo.GetChartDemographicAuditActions) has now been incorporated below directly into this sproc so the data can be processed as a set instead of RBAR.  dsexton, 2/14/2022

			DemographicChanges = cast(null as int),		-- This value is populated at the very end of the proc.
		
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

		INTO #Results

			FROM	[#ChartSubset] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID    
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
			WHERE		c.approved_by_user_profile_id > 2	

	                   

------------------------------------------------------------------------------------------------------------------------------------------
-- Beginning of section that directly incorporates the query from function dbo.GetChartDemographicAuditActions.  

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


update #Results set DemographicChanges = 1 where chart_ID in (Select Chart_ID from #DemoAuditChartIDs)	--12/12/2024 dsexton - 7 rows, 100 reads
update #Results set DemographicChanges = 0 where DemographicChanges is null		-- 12/12/2024 dsexton - 1756 rows, 100 reads

-- end of section to replace the call to function dbo.GetChartDemographicAuditActions
---------------------------------------------------------------------------------------------------------------------------


	-- update existing rows (if any) before inserting new rows (if any)
	update t1		
	set 
		  t1.service_agreement_id = t2.service_agreement_id
		, t1.ServiceAgreementDescription = t2.ServiceAgreementDescription
		, t1.chart_id = t2.chart_id
		, t1.facility_chart_id = t2.facility_chart_id
		, t1.APPROVED_DATE = t2.APPROVED_DATE
		, t1.USER_PROFILE_ID = t2.USER_PROFILE_ID
		, t1.CoderName = t2.CoderName
		, t1.TotalCodesCount = t2.TotalCodesCount
		, t1.TotalCorrectCodesCount = t2.TotalCorrectCodesCount
		, t1.TotalRevisedCodesCount = t2.TotalRevisedCodesCount
		, t1.TotalAddedCodesCount = t2.TotalAddedCodesCount
		, t1.TotalDeletedCodesCount = t2.TotalDeletedCodesCount
		, t1.DxCorrect = t2.DxCorrect
		, t1.DxAttempted = t2.DxAttempted
		, t1.DxAdditions = t2.DxAdditions
		, t1.DxRevisions = t2.DxRevisions
		, t1.DxDeletions = t2.DxDeletions
		, t1.DxAbstract = t2.DxAbstract
		, t1.FacilityProcCorrect = t2.FacilityProcCorrect
		, t1.FacilityProcAttempted = t2.FacilityProcAttempted
		, t1.FacilityProcAdditions = t2.FacilityProcAdditions
		, t1.FacilityProcRevisions = t2.FacilityProcRevisions
		, t1.FacilityProcDeletions = t2.FacilityProcDeletions
		, t1.FacilityProcAbstract = t2.FacilityProcAbstract
		, t1.InfusionInjectionCorrect = t2.InfusionInjectionCorrect
		, t1.InfusionInjectionAttempted = t2.InfusionInjectionAttempted
		, t1.InfusionInjectionAdditions = t2.InfusionInjectionAdditions
		, t1.InfusionInjectionRevisions = t2.InfusionInjectionRevisions
		, t1.InfusionInjectionDeletions = t2.InfusionInjectionDeletions
		, t1.InfusionInjectionAbstract = t2.InfusionInjectionAbstract
		, t1.ProfProcCorrect = t2.ProfProcCorrect
		, t1.ProfProcAttempted = t2.ProfProcAttempted
		, t1.ProfProcAdditions = t2.ProfProcAdditions
		, t1.ProfProcRevisions = t2.ProfProcRevisions
		, t1.ProfProcDeletions = t2.ProfProcDeletions
		, t1.ProfProcAbstract = t2.ProfProcAbstract
		, t1.AnesthesiaCorrect = t2.AnesthesiaCorrect
		, t1.AnesthesiaAttempted = t2.AnesthesiaAttempted
		, t1.AnesthesiaAdditions = t2.AnesthesiaAdditions
		, t1.AnesthesiaRevisions = t2.AnesthesiaRevisions
		, t1.AnesthesiaDeletions = t2.AnesthesiaDeletions
		, t1.AnesthesiaAbstract = t2.AnesthesiaAbstract
		, t1.ObsHoursCorrect = t2.ObsHoursCorrect
		, t1.ObsHoursAttempted = t2.ObsHoursAttempted
		, t1.ObsHoursAdditions = t2.ObsHoursAdditions
		, t1.ObsHoursRevisions = t2.ObsHoursRevisions
		, t1.ObsHoursDeletions = t2.ObsHoursDeletions
		, t1.ObsHoursAbstract = t2.ObsHoursAbstract
		, t1.FacilityLOSCorrect = t2.FacilityLOSCorrect
		, t1.FacilityLOSAttempted = t2.FacilityLOSAttempted
		, t1.FacilityLOSAdditions = t2.FacilityLOSAdditions
		, t1.FacilityLOSRevisions = t2.FacilityLOSRevisions
		, t1.FacilityLOSDeletions = t2.FacilityLOSDeletions
		, t1.FacilityLOSAbstract = t2.FacilityLOSAbstract
		, t1.PhysicianLOSCorrect = t2.PhysicianLOSCorrect
		, t1.PhysicianLOSAttempted = t2.PhysicianLOSAttempted
		, t1.PhysicianLOSAdditions = t2.PhysicianLOSAdditions
		, t1.PhysicianLOSRevisions = t2.PhysicianLOSRevisions
		, t1.PhysicianLOSDeletions = t2.PhysicianLOSDeletions
		, t1.PhysicianLOSAbstract = t2.PhysicianLOSAbstract
		, t1.DxChiefComplaintChanges = t2.DxChiefComplaintChanges
		, t1.DxPrimaryDxChanges = t2.DxPrimaryDxChanges
		, t1.DxChartsSubmitted = t2.DxChartsSubmitted
		, t1.InfInjChanges = t2.InfInjChanges
		, t1.InfInjSubmitted = t2.InfInjSubmitted
		, t1.ObsHoursChanges = t2.ObsHoursChanges
		, t1.ObsHoursSubmitted = t2.ObsHoursSubmitted
		, t1.ProcModifierChanges = t2.ProcModifierChanges
		, t1.FacilityLOSModifierChanges = t2.FacilityLOSModifierChanges
		, t1.PhysicianLOSModifierChanges = t2.PhysicianLOSModifierChanges
		, t1.DemographicChanges = t2.DemographicChanges
		, t1.MIPSChanges = t2.MIPSChanges
		, t1.MIPSSubmitted = t2.MIPSSubmitted
		, t1.DocumentationDeficiencyChanges = t2.DocumentationDeficiencyChanges
		, t1.DocumentationDeficiencySubmitted = t2.DocumentationDeficiencySubmitted
		, t1.RowModifiedDT = getdate()
	from DBA..CoderQAScorecardHx_CoderSummary as t1
		join #Results as t2 on t1.chart_ID = t2.chart_ID

	-- now insert new rows (if any)
	insert into DBA..CoderQAScorecardHx_CoderSummary 
	select *, RowInsertedDT = getdate(), RowModifiedDT = getdate() 
	from #Results
	where chart_ID not in (select chart_ID from DBA..CoderQAScorecardHx_CoderSummary)

	-- remove old records from the history table
	delete from DBA..CoderQAScorecardHx_CoderSummary where Approved_Date < dateadd(day, -@HistoryDaysToRetain, cast(getdate() as date))

	select @RowsAffected = count(*) from #Results

	if @pStartDate is null		-- indicates automatic processing was used based on date values in the control table, therefore update the control table.
	begin
		if @UpdateControlDates = 1		-- Can use 0 to conditionally override the update if, for example, you want the SQL Agent job to process both Category 1 and Category 2 for the same date range.
		begin
			update DBA..CoderQAScorecardHx_Control
			set 
				StartDate = @StartDate, 
				EndDate = @EndDate
				--RowsAffected = (select count(*) from #Results)
			where Category = 'CoderSummary'

			print 'Control dates have been updated.'
		end
		else print 'Control dates have *NOT* been updated.'

		if @Category = 1
		begin
			update DBA..CoderQAScorecardHx_Control
			set 
				RowsAffected = @RowsAffected,
				RowsAff_Cat1 = @RowsAffected
			where Category = 'CoderSummary'
		end

		if @Category = 2
		begin
			update DBA..CoderQAScorecardHx_Control
			set 
				RowsAffected = RowsAffected + @RowsAffected,
				RowsAff_Cat2 = @RowsAffected
			where Category = 'CoderSummary'
		end
	end

	print 'Processing completed for range @StartDate = ' + cast(isnull(@StartDate, '1/1/1900') as varchar) + ' to @EndDate = ' + cast(isnull(@EndDate, '1/1/1900') as varchar) + ', Category ' + cast(@Category as varchar) + ', RowsAffected = ' + cast(isnull(@RowsAffected, 0) as varchar) + '.'

END
GO
