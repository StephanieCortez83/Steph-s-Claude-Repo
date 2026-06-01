SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CODER_QA_SCORECARD_GET_PBA_SUMMARY_dsTest]
    @StartDate datetime,
    @EndDate datetime,
	@USER_PROFILE_ID INT
AS
BEGIN

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

if object_id('TempDB..#ChartSubsetPBA', 'U') is not null drop table #ChartSubsetPBA
if object_id('TempDB..#TempChartPBA_PAA', 'U') is not null drop table #TempChartPBA_PAA
if object_id('TempDB..#TempChartPBA_FLAA', 'U') is not null drop table #TempChartPBA_FLAA
if object_id('TempDB..#TempChartPBA_PLAA', 'U') is not null drop table #TempChartPBA_PLAA
if object_id('TempDB..#TempChartPBA_DAA', 'U') is not null drop table #TempChartPBA_DAA
if object_id('TempDB..#TempChartPBA_AAA', 'U') is not null drop table #TempChartPBA_AAA
if object_id('TempDB..#ResultsPBA', 'U') is not null drop table #Results

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
	--AND c.COMPLETION_DATE between DateAdd(day, -7, @StartDate) AND DateAdd(second, 86399, @EndDate)
	and c.completion_date between @StartDate and DateAdd(second, 86399, @EndDate)	-- For PBA, don't expand the user-supplied value for @StartDate
	
update t
set t.time_of_service = c.time_of_service,
	t.service_agreement_id = c.service_agreement_id,
	t.facility_chart_id = c.facility_chart_id,
	t.APPROVED_DATE = c.APPROVED_DATE,
	t.approved_by_user_profile_id = c.approved_by_user_profile_id
	, t.Approval_Reason_Code = c.approval_reason_code
	,t.POST_BILL_AUDIT_COMPLETED = c.POST_BILL_AUDIT_COMPLETED
from #ChartSubsetPBA as t join chart as c with(nolock) on t.chart_ID = c.chart_ID


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
			
			--ISNULL(c.POST_BILL_AUDIT_COMPLETED,getdate()) as PostBillAuditCompletedDate		-- Using getdate() can be misleading?
			ISNULL(c.POST_BILL_AUDIT_COMPLETED, '1/1/1900') as PostBillAuditCompletedDate		-- Using a static date like '1/1/1900' makes it obvious that this is a derived value to replace null.
			
			INTO #ResultsPBA

			FROM	[#ChartSubsetPBA] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID


select * from #ResultsPBA


END
GO
