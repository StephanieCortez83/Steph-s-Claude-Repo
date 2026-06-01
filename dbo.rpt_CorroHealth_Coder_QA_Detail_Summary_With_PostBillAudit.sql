SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[rpt_CorroHealth_Coder_QA_Detail_Summary_With_PostBillAudit] 
 	@ReportUser int,
	@DateType int,
	@StartDate datetime,
	@EndDate datetime,
	@ACCT_MGR    varchar(max),
	@COMPANY_ID  varchar(max),
	@FACILITY_ID varchar(max),
	@UserClass   varchar(max),
	@CUID varchar(max),
	@TimeZone VARCHAR(50)
as
begin


-- --test parameters
--declare
--    @ReportUser INT = 80,
--    @DateType INT = 0, -- 0 Approved, 1 DOS, 2 Sent, 3 PostAudit
--	@StartDate DATETIME = '12/01/2024',
--	@EndDate DATETIME   = '12/31/2024',
--	@ACCT_MGR    VARCHAR(MAX) = '13437', 
--	@COMPANY_ID  VARCHAR(MAX) = '284', 
--	@FACILITY_ID VARCHAR(MAX) = '-1',
--	@UserClass   VARCHAR(MAX) = '-1',  -- -1 All, 1 Corp Employee, 4 Client, 5 Vendor
--	@CUID        VARCHAR(MAX) = '15248',
--	@TimeZone VARCHAR(50) =	'Central Daylight Time';   --'India Standard Time'; 

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;
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
	DECLARE @m_ACCT_MGR VARCHAR(MAX) = @ACCT_MGR
	DECLARE @m_UserClass VARCHAR(MAX) = @UserClass;
			DECLARE @CTOffSet VARCHAR(9) = (
			SELECT CT_OFFSET
			FROM TIME_ZONE
			WHERE [DESCRIPTION] = @TimeZone
			)
	DECLARE @Operator VARCHAR(1) = SUBSTRING(@CTOffSet, 1, 1)
	DECLARE @hms VARCHAR(8) = SUBSTRING(@CTOffSet, 2, LEN(@CTOffSet) - 1)
	DECLARE @HOURs DECIMAL(10, 2) = DATEPART(HOUR, @hms)
	DECLARE @MINUTEs DECIMAL(10, 2) = DATEPART(MINUTE, @hms)
	DECLARE @HrsOffSet DECIMAL(10, 2) = CAST(@Operator + CONVERT(VARCHAR, DATEPART(HOUR, @hms)) AS DECIMAL(10, 2))
	DECLARE @MinOffSet DECIMAL(10, 2) = CAST(@Operator + CONVERT(VARCHAR, DATEPART(MINUTE, @hms)) AS DECIMAL(10, 2))
if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
if object_id('TempDB..#CodedCharts1', 'U') is not null drop table #CodedCharts1;
if object_id('TempDB..#CodedCharts', 'U') is not null drop table #CodedCharts;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#Scorecard_2', 'U') is not null drop table #Scorecard_2;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;
if object_id('TempDB..#TempChartQAS_AAA', 'U') is not null drop table #TempChartQAS_AAA;
if object_id('TempDB..#Unit_Mod_1', 'U') is not null drop table #Unit_Mod_1;
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
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser
    and  ( SA.COMPANY_ID in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ','))
				OR	-1 in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ',')) )
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
	and
				(
				-1 in (SELECT * FROM SPLITSTRING(@m_ACCT_MGR, ',')) 
				or (sa.SERVICE_AGREEMENT_ID in
						(
						select distinct
							   samt.SERVICE_AGREEMENT_ID
						from
							SERVICE_AGREEMENT_MANAGEMENT_TEAM samt
							,USER_PROFILE up
						where
							samt.USER_PROFILE_ID = up.USER_PROFILE_ID and samt.MANAGEMENT_TEAM_ROLE_ID = 1
							and up.USER_PROFILE_ID in (SELECT * FROM SPLITSTRING(@m_ACCT_MGR, ',')) 
						)
				   )
				)	
) af
		;
-- *************************************************************************
-- Coders/UserClass
	if object_id('TempDB..#coder', 'U') is not null drop table #coder
	select distinct t1.USER_PROFILE_ID 
	into #coder				
	from  				
			(
			SELECT USER_PROFILE_ID 
			FROM USER_PROFILE				
			WHERE  USER_PROFILE_ID <> 2
			and ( CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR IS_ACTIVE = 'Y' )			
			and (USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') )
				OR -1 in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') ) )
			and (USER_CLASS_CD in ( SELECT items FROM dbo.SplitString(@m_UserClass, ',') )
				OR -1 in ( SELECT items FROM dbo.SplitString(@m_UserClass, ',') ) )			
			) t1
	create nonclustered index idx_USER_PROFILE_ID on #coder (USER_PROFILE_ID);
-- ****************************************************************************
declare @CNT_Facility int = (select count(*) from #AuthorizedFacilities);
declare @CNT_ACCT_MGR int = (SELECT count(*) FROM SPLITSTRING(@m_ACCT_MGR, ','));
declare @CNT_CO int = (SELECT count(*) FROM SPLITSTRING(@m_COMPANY_ID, ','));
declare @CNT_CUID int = (SELECT count(*) FROM #coder);
-- Parameter Check
-- Date Range: 31, Acct Mgr: 1 
--IF (datediff(day,@m_StartDate,@m_EndDate) > 31
----AND ('-1' in (@m_ACCT_MGR) OR @CNT_ACCT_MGR > 1 ) 
----AND ('-1' in (@m_COMPANY_ID) OR @CNT_CO > 1 )
----AND ( '-1' in (@m_FACILITY_ID) OR @CNT_Facility > 10 )
--AND ( '-1' in (@m_CUID) OR @CNT_CUID > 1   ) 
--)
--BEGIN
--select 
--0  as service_agreement_id, 
--'' as ServiceAgreementDescription, 
--0  as chart_id, 
--'' as facility_chart_id, 
--'' as APPROVED_DATE, 
--0  as USER_PROFILE_ID,  
--'' as CoderName,
--'' as FacilityLOSError,
--'' as InfusionInjectionError,
--'' as FacilityProcError,
--'' as PhysicianLOSError,
--'' as ProfProcError,
--'' as DxError,
--'' as ObsHoursError,
--'' as AuditNotes,
--'' as PostAuditNotes,
--datediff(day,@m_StartDate,@m_EndDate)
--end;
-- Date Range: 10, Org: All, Facility: All, Coder: All 
-- ELSE
IF (datediff(day,@m_StartDate,@m_EndDate) >= 10 
AND ('-1' in (@m_ACCT_MGR) OR @CNT_ACCT_MGR > 1 ) 
--AND ('-1' in (@m_COMPANY_ID) OR @CNT_CO > 1 )
--AND ( '-1' in (@m_FACILITY_ID) OR @CNT_Facility > 10 )
AND ( '-1' in (@m_CUID) OR @CNT_CUID > 1   ) 
   ) 
BEGIN
select 
0  as service_agreement_id, 
'' as ServiceAgreementDescription, 
0  as chart_id, 
'' as facility_chart_id, 
'' as APPROVED_DATE, 
0  as USER_PROFILE_ID,  
'' as CoderName,
'' as FacilityLOSError,
'' as InfusionInjectionError,
'' as FacilityProcError,
'' as PhysicianLOSError,
'' as ProfProcError,
'' as DxError,
'' as ObsHoursError,
'' as AuditNotes,
'' as PostAuditNotes,
datediff(day,@m_StartDate,@m_EndDate)
end;
-- Default 31 Max
ELSE
IF (datediff(day,@m_StartDate,@m_EndDate) > 31 ) 
BEGIN
select 
0  as service_agreement_id, 
'' as ServiceAgreementDescription, 
0  as chart_id, 
'' as facility_chart_id, 
'' as APPROVED_DATE, 
0  as USER_PROFILE_ID,  
'' as CoderName,
'' as FacilityLOSError,
'' as InfusionInjectionError,
'' as FacilityProcError,
'' as PhysicianLOSError,
'' as ProfProcError,
'' as DxError,
'' as ObsHoursError,
'' as AuditNotes,
'' as PostAuditNotes,
datediff(day,@m_StartDate,@m_EndDate)
end;
ELSE	
BEGIN 
-- ************************************************************************************
-- Coded Charts   -- Move Coded Charts up, when no other data , these records were not being counted
SELECT	
c.chart_id, c.service_agreement_id, c.facility_chart_id, 
c.APPROVED_DATE, c.completed_by_user_profile_id, 
c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID,
c.CHART_STATUS_ID,
c.APPROVAL_REASON_CODE, c.START_QA_DATE, c.POST_BILL_AUDIT_STARTED
INTO	[#CodedCharts1]
FROM	chart as c  with (NOLOCK)
WHERE	
       c.CHART_STATUS_ID in (4, 5) -- Approved, Sent 
AND    c.COMPLETED_BY_USER_PROFILE_ID in ( select USER_PROFILE_ID from #coder) -- = @m_CUID
AND	 
		(									
		(@m_DateType = 0 and DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.APPROVED_DATE ))), 0) BETWEEN @m_StartDate AND @m_EndDate )						
		or					
		(@m_DateType = 1 and DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.TIME_OF_SERVICE ))), 0) BETWEEN @m_StartDate AND @m_EndDate )									
		or 									
		(@m_DateType = 2 and DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.sent_date ))), 0) BETWEEN @m_StartDate AND @m_EndDate )
		or 
		(@m_DateType = 3 and DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.POST_BILL_AUDIT_COMPLETED ))), 0) BETWEEN @m_StartDate AND @m_EndDate )
		) 
AND    c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
; 
SELECT	
c.COMPLETED_BY_USER_PROFILE_ID,
count(*) as Number_of_Charts_Coded
INTO	[#CodedCharts]
FROM	#CodedCharts1 c
group by c.COMPLETED_BY_USER_PROFILE_ID;
-- *****************************************************************************************************************************************
SELECT	c.chart_id, c.service_agreement_id, c.facility_chart_id, 
c.APPROVED_DATE, c.completed_by_user_profile_id, 
c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID
,c.APPROVAL_REASON_CODE
INTO	[#ChartSubset]
FROM	#CodedCharts1 as c 
WHERE	c.CHART_STATUS_ID in (4, 5)  
--AND     c.APPROVAL_REASON_CODE = 3
--AND     c.APPROVED_BY_USER_PROFILE_ID <> 2
AND c.START_QA_DATE is not null or c.POST_BILL_AUDIT_STARTED is not null			
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
----------------------------------------------------------------------------------------------------------------------------------
select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_ANESTHESIA_CODE, AUDITOR_ANESTHESIA_CODE
  into #TempChartQAS_AAA
from CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID
----------------------------------------------------------------------------------------------------------------------------------
if object_id('TempDB..#ChartPostBillAudit', 'U') is not null drop table #ChartPostBillAudit;
select pba.*
into #ChartPostBillAudit
from
	dbo.ChartPostBillAudit pba
	inner join #ChartSubset cs on pba.ChartId = cs.CHART_ID
----------------------------------------------------------------------------------------------------------------------------------
if object_id('TempDB..#ChartAuditVersion', 'U') is not null drop table #ChartAuditVersion;
select cav.*
into #ChartAuditVersion
from
	dbo.ChartAuditVersion cav
where
	cav.ChartAuditId in (select distinct ChartPostBillAuditId from #ChartPostBillAudit)
create nonclustered index [tIDX_ChartAuditVersion_ChartAuditId_Include] 
on #ChartAuditVersion ([ChartAuditId] asc)
include([ChartAuditVersionId],[VersionNumber])
if object_id('TempDB..#ChartAuditFacilityLosVersionItem', 'U') is not null drop table #ChartAuditFacilityLosVersionItem;
select caflos.*
into #ChartAuditFacilityLosVersionItem
from
	dbo.ChartAuditFacilityLosVersionItem caflos
where
	caflos.ChartId in (select distinct ChartId from #ChartPostBillAudit)
	and caflos.ExcludeFromQA <> 1
CREATE NONCLUSTERED INDEX [tIDX_ChartAuditFacilityLosVersionItem__ChartAuditActionTypeCode_ExcludeFromQA__include]
ON #ChartAuditFacilityLosVersionItem ([ChartAuditActionTypeCode],[ExcludeFromQA])
INCLUDE ([ChartAuditVersionId])
if object_id('TempDB..#ChartAuditPhysicianLosVersionItem', 'U') is not null drop table #ChartAuditPhysicianLosVersionItem;
select caplos.*
into #ChartAuditPhysicianLosVersionItem
from
	dbo.ChartAuditPhysicianLosVersionItem caplos
where
	caplos.ChartId in (select distinct ChartId from #ChartPostBillAudit)
	and caplos.ExcludeFromQA <> 1
CREATE NONCLUSTERED INDEX [tIDX_ChartAuditPhysicianLosVersionItem__ChartAuditActionTypeCode_ExcludeFromQA__include]
ON #ChartAuditPhysicianLosVersionItem ([ChartAuditActionTypeCode],[ExcludeFromQA])
INCLUDE ([ChartAuditVersionId])
if object_id('TempDB..#ChartAuditProcedureVersionItem', 'U') is not null drop table #ChartAuditProcedureVersionItem;
select cap.*
into #ChartAuditProcedureVersionItem
from
	dbo.ChartAuditProcedureVersionItem cap
where
	cap.ChartAuditVersionId in (select distinct ChartAuditVersionId from #ChartAuditVersion)
	--and cap.CptCode in (select distinct sp.cpt_code
	--					from
	--						#ChartSubset cs
	--						inner join dbo.SENT_PROCEDURE sp on cs.CHART_ID = sp.chart_id)
	and cap.ExcludeFromQA <> 1
CREATE NONCLUSTERED INDEX [tIDX_ChartAuditProcedureVersionItem_VersionIdProcType] 
ON #ChartAuditProcedureVersionItem
(
	[ChartAuditVersionId] ASC,
	[ProcedureType] ASC
)
if object_id('TempDB..#ChartAuditDiagnosisVersionItem', 'U') is not null drop table #ChartAuditDiagnosisVersionItem;
select cad.*
into #ChartAuditDiagnosisVersionItem
from
	dbo.ChartAuditDiagnosisVersionItem cad
where
	cad.ExcludeFromQA <> 1
create nonclustered index [tIDX_ChartAuditDiagnosisVersionItem]
on #ChartAuditDiagnosisVersionItem ([ChartAuditVersionId] asc)
include (
            [ChartAuditActionTypeCode]
            ,[ExcludeFromQA]
        )
if object_id('TempDB..#ChartAuditAnesthesiaVersionItem', 'U') is not null drop table #ChartAuditAnesthesiaVersionItem;
select caa.*
into #ChartAuditAnesthesiaVersionItem
from
	dbo.ChartAuditAnesthesiaVersionItem caa
where
	caa.ChartAuditVersionId in (select distinct ChartAuditVersionId from #ChartAuditVersion)
	and caa.ExcludeFromQA <> 1
CREATE NONCLUSTERED INDEX [tIDX_ChartAuditAnesthesiaVersionItem_VersionIdTypeCode] 
ON #ChartAuditAnesthesiaVersionItem
(
	[ChartAuditVersionId] ASC,
	[ChartAuditActionTypeCode] ASC
)
-- *****************************************************************************************************************************************
SELECT		c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, 
			c.APPROVED_DATE, 
			up.USER_PROFILE_ID,  
			up.LAST_NAME + ', ' + up.FIRST_NAME  as CoderName,
-- Facility LOS
(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where  flos.CHART_ID = c.CHART_ID AND (flos.CODER_MODIFIER <> '' OR flos.AUDITOR_MODIFIER <> '' ) AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOS_ModOpp, 
(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where  flos.CHART_ID = c.CHART_ID AND flos.CODER_MODIFIER <> flos.AUDITOR_MODIFIER AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOS_ModRev,		
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSActions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,			 
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,	
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,
--Facility LOS Post	
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditFacilityLosVersionItemId is null) x )  as FacilityLOS_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditFacilityLosVersionItem i2 where i2.ChartAuditFacilityLosVersionItemId = i.PrevChartAuditFacilityLosVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID ) x ) as FacilityLOS_ModRev_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as FacilityLOSActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as FacilityLOSNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as FacilityLOSRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as FacilityLOSDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAbstract_Post,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i, #ChartAuditFacilityLosVersionItem i2 WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND i.PrevChartAuditFacilityLosVersionItemId = i2.PrevChartAuditFacilityLosVersionItemId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND i.ExcludeFromQA <> 1 AND i2.ExcludeFromQA <> 1 AND (isnull(i.Modifier, '0') <> isnull(i2.Modifier, '0')) AND pba.ChartId = c.CHART_ID)   as FacilityLOSModifierChanges_Post,
-- I/I		
(select count(*) as CNT  from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'CI' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_QUANTITY > 0 OR pro.AUDITOR_QUANTITY > 0) ) as InfusionInjection_UnitOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'CI' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_QUANTITY <> pro.AUDITOR_QUANTITY ) as InfusionInjection_UnitRev,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'CI' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_MODIFIER <> '' OR pro.AUDITOR_MODIFIER <> '') ) as InfusionInjection_ModOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'CI' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_MODIFIER <> pro.AUDITOR_MODIFIER) as InfusionInjection_ModRev,
            (select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,			
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionDeletions,
            (select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1 AND pr.chart_id not in (select chart_id from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr2 	WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'CI' AND pr2.ACTION in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as InfusionInjectionAbstract,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
-- I/I Post
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as InfusionInjection_UnitOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Quantity,0) = (select isnull(i2.Quantity,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID ) x ) as InfusionInjection_UnitRev_Post,
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as InfusionInjection_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID ) x ) as InfusionInjection_ModRev_Post,
            (select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAbstract_Post,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionChanges_Post,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID)  as InfusionInjectionSubmitted_Post,
-- Facility Procedures
(select count(*) as CNT  from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'FP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_QUANTITY > 0 OR pro.AUDITOR_QUANTITY > 0) ) as FacilityProc_UnitOpp,
(select count(*) as CNT  from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'FP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_QUANTITY <> pro.AUDITOR_QUANTITY ) as FacilityProc_UnitRev,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'FP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_MODIFIER <> '' OR pro.AUDITOR_MODIFIER <> '') ) as FacilityProc_ModOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'FP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_MODIFIER <> pro.AUDITOR_MODIFIER) as FacilityProc_ModRev,
            (select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,			
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,
-- Facility Procedures Post
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as FacilityProc_UnitOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Quantity,0) = (select isnull(i2.Quantity,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID ) x ) as FacilityProc_UnitRev_Post,
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as FacilityProc_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID ) x ) as FacilityProc_ModRev_Post,
            (select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID)  as FacilityProcAttempted_Post,
            (select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as FacilityProcActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as FacilityProcNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as FacilityProcAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as FacilityProcRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as FacilityProcDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as FacilityProcAbstract_Post,
--Physician LOS  	
(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where  plos.CHART_ID = c.CHART_ID AND (plos.CODER_MODIFIER <> '' OR plos.AUDITOR_MODIFIER <> '' ) AND plos.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOS_ModOpp, 
(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where  plos.CHART_ID = c.CHART_ID AND plos.CODER_MODIFIER <> plos.AUDITOR_MODIFIER AND plos.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOS_ModRev,
            (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted, 	
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSActions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect ,		
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,  																															 
--Physician LOS Post
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditPhysicianLosVersionItemId is null) x )  as PhysicianLOS_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditPhysicianLosVersionItem i2 where i2.ChartAuditPhysicianLosVersionItemId = i.PrevChartAuditPhysicianLosVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID ) x ) as PhysicianLOS_ModRev_Post,
            (select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAbstract_Post,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i, #ChartAuditPhysicianLosVersionItem i2 WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND i.PrevChartAuditPhysicianLosVersionItemId = i2.PrevChartAuditPhysicianLosVersionItemId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND i.ExcludeFromQA <> 1 AND i2.ExcludeFromQA <> 1 AND (isnull(i.Modifier, '0') <> isnull(i2.Modifier, '0')) AND pba.ChartId = c.CHART_ID) as PhysicianLOSModifierChanges_Post,
--Physician Procedure
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'PP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_QUANTITY > 0 OR pro.AUDITOR_QUANTITY > 0) ) as ProfProc_UnitOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'PP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_QUANTITY <> pro.AUDITOR_QUANTITY ) as ProfProc_UnitRev,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'PP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_MODIFIER <> '' OR pro.AUDITOR_MODIFIER <> '') ) as ProfProc_ModOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'PP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_MODIFIER <> pro.AUDITOR_MODIFIER ) as ProfProc_ModRev,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,			
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract,
--Physician Procedure Post 
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as ProfProc_UnitOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Quantity,0) = (select isnull(i2.Quantity,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID ) x ) as ProfProc_UnitRev_Post,
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as ProfProc_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID ) x ) as ProfProc_ModRev_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID)  as ProfProcAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ProfProcActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as ProfProcNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as ProfProcAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as ProfProcRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as ProfProcDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as ProfProcAbstract_Post,
-- Dx
            (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxAttempted,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxActions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,			
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
            (select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1	AND dx.chart_id not in (select chart_id from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx2 WHERE dx2.CHART_ID = dx.CHART_ID AND dx2.ACTION in ('D','R','A') AND dx2.EXCLUDE_FROM_QA_REPORT <> 1 )	) as DxAbstract,
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,	
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxSubmitted,
-- Dx Post	
            (select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as DxAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID) as DxActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as DxNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as DxAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as DxRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as DxDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as DxAbstract_Post,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND DiagnosisTypeID in (2,3) AND IsPrimary = 1 AND pba.ChartId = c.CHART_ID)  as DxPrimaryDxChanges_Post,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND IsPrimary = 1 AND pba.ChartId = c.CHART_ID)  as DxChiefComplaintChanges_Post,
            (select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND pba.ChartId = c.CHART_ID)  as DxSubmitted_Post,
-- Obs Hours
            (select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursActions, 
            (select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions, 							 
            (select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1 AND pr.chart_id not in (select chart_id from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr2 WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'OB' AND pr2.ACTION in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as ObsHoursAbstract, 	
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted, 
-- Obs Hours Post	
            (select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND pba.ChartId = c.CHART_ID)  as ObsHoursAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as ObsHoursAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as ObsHoursRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as ObsHoursDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as ObsHoursAbstract_Post,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursChanges_Post,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ProcedureType = 'OB' AND pba.ChartId = c.CHART_ID)  as ObsHoursSubmitted_Post,
-- Procedure Modifier
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges, 
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i, #ChartAuditProcedureVersionItem i2 WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND i.PrevChartAuditProcedureVersionItemId = i2.ChartAuditProcedureVersionItemId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND i.ExcludeFromQA <> 1 AND i2.ExcludeFromQA <> 1 AND (isnull(i.Modifier, '0') <> isnull(i2.Modifier, '0')) AND pba.ChartId = c.CHART_ID)       as ProcModifierChanges_Post,
-- Demographic Changes
			(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges,
			(select count(distinct pba.ChartId) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CD' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as DemographicChanges_Post,
-- Anesthesia		
			(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND (aaa.IS_CODER_CORRECT = 1 OR aaa.EXCLUDE_FROM_QA_REPORT = 1))  as AnesthesiaCorrect,
			(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID) as AnesthesiaAttempted,
			(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID AND aaa.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaActions, 	
			(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAdditions,
			(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaRevisions,
			(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaDeletions,	
			(select count(DISTINCT aaa.CHART_ID) from #TempChartQAS_AAA aaa with (NOLOCK) where c.CHART_ID = aaa.CHART_ID and aaa.ACTION = 'C' AND aaa.EXCLUDE_FROM_QA_REPORT <> 1
				    AND aaa.chart_id not in (select chart_id from #TempChartQAS_AAA aaa2 WHERE aaa2.CHART_ID = aaa.CHART_ID AND aaa2.ACTION in ('D','R','A') AND aaa2.EXCLUDE_FROM_QA_REPORT <> 1 )	) as AnesthesiaAbstract,
--Anesthesia Post			
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditAnesthesiaVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as AnesthesiaAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditAnesthesiaVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as AnesthesiaActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditAnesthesiaVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as AnesthesiaNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditAnesthesiaVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as AnesthesiaAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditAnesthesiaVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as AnesthesiaRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditAnesthesiaVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as AnesthesiaDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditAnesthesiaVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as AnesthesiaAbstract_Post
  into #Scorecard_1
			FROM				
			[#ChartSubset] c with (NOLOCK) 
					 LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID    
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
 			--WHERE		c.approved_by_user_profile_id > 2		    
-- select * from [#ChartSubset]
-- select * from #Scorecard_1
/*
select s.chart_id, 
s.FacilityProc_UnitOpp, s.InfusionInjection_UnitOpp, s.ProfProc_UnitOpp,
s.FacilityProc_UnitRev, s.InfusionInjection_UnitRev, s.ProfProc_UnitRev, 
s.FacilityProc_UnitOpp_Post, s.InfusionInjection_UnitOpp_Post, s.ProfProc_UnitOpp_Post,
s.FacilityProc_UnitRev_Post, s.InfusionInjection_UnitRev_Post, s.ProfProc_UnitRev_Post
from #Scorecard_1 s
*/
-- *****************************************************************************************************************************************
-- Coded Charts
declare @ScoreCardCnt int = 0
declare @CodedChartsCnt int = 0
set @ScoreCardCnt = (select count(*) from #Scorecard_1)
set @CodedChartsCnt = (select count(*) from #CodedCharts)
-- select @ScoreCardCnt, @CodedChartsCnt
if @ScoreCardCnt = 0 and @CodedChartsCnt > 0
BEGIN
insert into #Scorecard_1
select 
distinct 
0 as service_agreement_id, 
'' as ServiceAgreementDescription, 
0 as chart_id, 
0 as facility_chart_id, 
'' as APPROVED_DATE, 
completed_by_user_profile_id as USER_PROFILE_ID,
up.LAST_NAME + ', ' + up.FIRST_NAME  as CoderName,
--Facility LOS 
0        as FacilityLOS_ModOpp, 
0        as FacilityLOS_ModRev,
0		 as FacilityLOSAttempted,
0		 as FacilityLOSActions,
0		 as FacilityLOSCorrect, 
0		 as FacilityLOSAdditions,
0		 as FacilityLOSRevisions,
0		 as FacilityLOSDeletions,
0		 as FacilityLOSAbstract,
0        as FacilityLOSModifierChanges,
--Facility LOS Post	
0         as FacilityLOS_ModOpp_Post,
0         as FacilityLOS_ModRev_Post,		
0		  as FacilityLOSAttempted_Post,
0		  as FacilityLOSActions_Post,
0		  as FacilityLOSNoChange_Post,
0		  as FacilityLOSAdditions_Post,
0		  as FacilityLOSRevisions_Post,
0		  as FacilityLOSDeletions_Post,
0		  as FacilityLOSAbstract_Post,
0         as FacilityLOSModifierChanges_Post,
-- I/I
0         as InfusionInjection_UnitOpp,
0         as InfusionInjection_UnitRev,
0         as InfusionInjection_ModOpp,
0         as InfusionInjection_ModRev,
0	      as InfusionInjectionAttempted,
0	      as InfusionInjectionActions,
0	      as InfusionInjectionCorrect,
0         as InfusionInjectionAdditions,
0	      as InfusionInjectionRevisions,
0	      as InfusionInjectionDeletions,
0	      as InfusionInjectionAbstract,
0 		  as InfInjChanges,
0		  as InfInjSubmitted,
-- I/I Post
0         as InfusionInjection_UnitOpp_Post,
0         as InfusionInjection_UnitRev_Post,
0         as InfusionInjection_ModOpp_Post,
0         as InfusionInjection_ModRev_Post,
0		  as InfusionInjectionAttempted_Post,
0		  as InfusionInjectionActions_Post,
0		  as InfusionInjectionNoChange_Post,
0		  as InfusionInjectionAdditions_Post,
0		  as InfusionInjectionRevisions_Post,
0		  as InfusionInjectionDeletions_Post,
0		  as InfusionInjectionAbstract_Post,
0         as InfusionInjectionChanges_Post,
0         as InfusionInjectionSubmitted_Post,
-- Facility Proc
0         as FacilityProc_UnitOpp,
0         as FacilityProc_UnitRev,
0         as FacilityProc_ModOpp,
0         as FacilityProc_ModRev,
0		  as FacilityProcAttempted,
0		  as FacilityProcActions,
0		  as FacilityProcCorrect,
0		  as FacilityProcAdditions,
0		  as FacilityProcRevisions,
0		  as FacilityProcDeletions,
0		  as FacilityProcAbstract,
-- Facility Procedures Post
0         as FacilityProc_UnitOpp_Post,
0         as FacilityProc_UnitRev_Post,
0         as FacilityProc_ModOpp_Post,
0         as FacilityProc_ModRev_Post,
0         as FacilityProcAttempted_Post,
0         as FacilityProcActions_Post,
0		  as FacilityProcNoChange_Post,	
0         as FacilityProcAdditions_Post,
0 	      as FacilityProcRevisions_Post,
0		  as FacilityProcDeletions_Post,
0		  as FacilityProcAbstract_Post,
-- Physician LOS
0         as PhysicianLOS_ModOpp,
0         as PhysicianLOS_ModRev,
0		  as PhysicianLOSAttempted, 	
0		  as PhysicianLOSActions,
0		  as PhysicianLOSCorrect ,
0		  as PhysicianLOSAdditions,
0		  as PhysicianLOSRevisions,
0		  as PhysicianLOSDeletions,
0		  as PhysicianLOSAbstract,
0	 	  as PhysicianLOSModifierChanges,
--Physician LOS Post
0         as PhysicianLOS_ModOpp_Post,
0         as PhysicianLOS_ModRev_Post,
0		  as PhysicianLOSAttempted_Post,
0		  as PhysicianLOSActions_Post,
0		  as PhysicianLOSNoChange_Post,
0 		  as PhysicianLOSAdditions_Post,
0		  as PhysicianLOSRevisions_Post,
0		  as PhysicianLOSDeletions_Post,
0		  as PhysicianLOSAbstract_Post,
0         as PhysicianLOSModifierChanges_Post,
-- Physician Procedure
0        as ProfProc_UnitOpp,
0        as ProfProc_UnitRev,
0        as ProfProc_ModOpp,
0        as ProfProc_ModRev,
0		 as ProfProcAttempted, 
0		 as ProfProcActions,
0		 as ProfProcCorrect,
0		 as ProfProcAdditions, 							 
0		 as ProfProcRevisions, 							 
0		 as ProfProcDeletions, 							 
0		 as ProfProcAbstract,
-- Physician Procedure Post
0         as ProfProc_UnitOpp_Post,
0         as ProfProc_UnitRev_Post,
0         as ProfProc_ModOpp_Post,
0         as ProfProc_ModRev_Post,
0		  as ProfProcAttempted_Post,
0		  as ProfProcActions_Post,
0		  as ProfProcNoChange_Post,
0		  as ProfProcAdditions_Post,
0		  as ProfProcRevisions_Post,
0		  as ProfProcDeletions_Post,
0		  as ProfProcAbstract_Post,
-- Dx
0	      as DxAttempted,
0		  as DxActions,
0	      as DxCorrect,
0	      as DxAdditions,
0	      as DxRevisions,
0	      as DxDeletions,
0	      as DxAbstract,
0         as DxPrimaryDxChanges,
0         as DxChiefComplaintChanges,
0         as DxSubmitted,
-- Dx Post
0         as DxAttempted_Post,
0		  as DxActions_Post,
0		  as DxNoChange_Post,
0         as DxAdditions_Post,
0		  as DxRevisions_Post,
0		  as DxDeletions_Post,
0		  as DxAbstract_Post,
0         as DxPrimaryDxChanges_Post,
0         as DxChiefComplaintChanges_Post,
0         as DxSubmitted_Post,
-- Obs Hours
0		  as ObsHoursAttempted,
0		  as ObsHoursActions,
0		  as ObsHoursCorrect, 
0		  as ObsHoursAdditions, 							 
0		  as ObsHoursRevisions, 							 
0		  as ObsHoursDeletions, 							 
0		  as ObsHoursAbstract, 
0		  as ObsHoursChanges,
0		  as ObsHoursSubmitted, 
-- Obs Hours Post
0	      as ObsHoursAttempted_Post,
0		  as ObsHoursActions_Post,
0		  as ObsHoursNoChange_Post,
0		  as ObsHoursAdditions_Post,
0		  as ObsHoursRevisions_Post,
0		  as ObsHoursDeletions_Post,
0		  as ObsHoursAbstract_Post,
0		  as ObsHoursChanges_Post,
0		  as ObsHoursSubmitted_Post, 
--Procedure Modifier
0		  as ProcModifierChanges, 
0         as ProcModifierChanges_Post,
-- Demographic Changes
0		  as DemographicChanges, 
0         as DemographicChanges_Post,
-- Anesthesia
0 as AnesthesiaCorrect,	
0 as AnesthesiaAttempted,
0 as AnesthesiaActions, 	
0 as AnesthesiaAdditions,
0 as AnesthesiaRevisions,
0 as AnesthesiaDeletions,	
0 as AnesthesiaAbstract,
--Anesthesia Post			
0 as AnesthesiaAttempted_Post,
0   as AnesthesiaActions_Post,
0  as AnesthesiaNoChange_Post,
0  as AnesthesiaAdditions_Post,
0  as AnesthesiaRevisions_Post,
0  as AnesthesiaDeletions_Post,
0  as AnesthesiaAbstract_Post
from #CodedCharts c
LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID  
end
-- *****************************************************************************************************************************************
--calculations
select 
chart_id,
sum(isnull(s.FacilityProc_UnitOpp, 0) + isnull(s.InfusionInjection_UnitOpp, 0) + isnull(s.ProfProc_UnitOpp, 0) ) as UnitOpportunities, 
sum(isnull(s.FacilityProc_UnitRev, 0) + isnull(s.InfusionInjection_UnitRev, 0) + isnull(s.ProfProc_UnitRev, 0) ) as UnitRevisions,
sum(isnull(s.FacilityProc_UnitOpp_Post, 0) + isnull(s.InfusionInjection_UnitOpp_Post, 0) + isnull(s.ProfProc_UnitOpp_Post, 0) ) as UnitOpportunities_Post,
sum(isnull(s.FacilityProc_UnitRev_Post, 0) + isnull(s.InfusionInjection_UnitRev_Post, 0) + isnull(s.ProfProc_UnitRev_Post, 0) )as UnitRevisions_Post,
sum(isnull(s.FacilityProc_ModOpp, 0) + isnull(s.InfusionInjection_ModOpp, 0) + isnull(s.ProfProc_ModOpp, 0) + isnull(s.FacilityLOS_ModOpp, 0) + isnull(s.PhysicianLOS_ModOpp, 0) ) as ModifierOpportunities,
sum(isnull(s.FacilityProc_ModRev, 0) + isnull(s.InfusionInjection_ModRev, 0) + isnull(s.ProfProc_ModRev, 0) + isnull(s.FacilityLOS_ModRev, 0) + isnull(s.PhysicianLOS_ModRev, 0) ) as ModifierRevisions,
sum(s.FacilityProc_ModOpp_Post + s.InfusionInjection_ModOpp_Post + s.ProfProc_ModOpp_Post + s.FacilityLOS_ModOpp_Post + s.PhysicianLOS_ModOpp_Post ) as ModifierOpportunities_Post,
sum(isnull(s.FacilityProc_ModRev_Post,0) + isnull(s.InfusionInjection_ModRev_Post,0) + isnull(s.ProfProc_ModRev_Post,0) + isnull(s.FacilityLOS_ModRev_Post,0) + isnull(s.PhysicianLOS_ModRev_Post,0) ) as ModifierRevisions_Post
into #Unit_Mod_1
from #Scorecard_1 s
group by chart_id
select -- (only user profile id and chart id are needed)
chart_id, 
USER_PROFILE_ID,
CoderName,

 case when s.FacilityLOSAttempted_Post > 0  then s.FacilityLOSAdditions_Post else s.FacilityLOSAdditions end as FacilityLOSAdditions,
 case when s.FacilityLOSAttempted_Post > 0  then s.FacilityLOSRevisions_Post else s.FacilityLOSRevisions end as FacilityLOSRevisions,
 case when s.FacilityLOSAttempted_Post > 0  then s.FacilityLOSDeletions_Post else s.FacilityLOSDeletions end as FacilityLOSDeletions,
 case when s.FacilityLOSAttempted_Post > 0  then s.FacilityLOSNoChange_Post else s.FacilityLOSCorrect end as FacilityLOSCorrect,
 case when s.FacilityLOSAttempted_Post > 0  then s.FacilityLOSModifierChanges_Post else s.FacilityLOSModifierChanges end as FacilityLOSModifierChanges,
-- I/I
 case when s.InfusionInjectionAttempted_Post > 0  then s.InfusionInjectionAdditions_Post else s.InfusionInjectionAdditions end as InfusionInjectionAdditions,
 case when s.InfusionInjectionAttempted_Post > 0  then s.InfusionInjectionRevisions_Post else s.InfusionInjectionRevisions end as InfusionInjectionRevisions,
 case when s.InfusionInjectionAttempted_Post > 0  then s.InfusionInjectionDeletions_Post else s.InfusionInjectionDeletions end as InfusionInjectionDeletions,
 case when s.InfusionInjectionAttempted_Post > 0  then s.InfusionInjectionNoChange_Post else s.InfusionInjectionCorrect end as InfusionInjectionCorrect,
 case when s.InfusionInjectionChanges_Post > 0 then s.InfusionInjectionChanges_Post else s.InfInjChanges end as InfInjChanges,
 case when s.InfusionInjectionSubmitted_Post > 0 then s.InfusionInjectionSubmitted_Post else s.InfInjSubmitted end as InfInjSubmitted,
-- Facility Proc
 case when s.FacilityProcAttempted_Post > 0  then s.FacilityProcAdditions_Post else s.FacilityProcAdditions end as FacilityProcAdditions,
 case when s.FacilityProcAttempted_Post > 0  then s.FacilityProcRevisions_Post else s.FacilityProcRevisions end as FacilityProcRevisions,
 case when s.FacilityProcAttempted_Post > 0  then s.FacilityProcDeletions_Post else s.FacilityProcDeletions end as FacilityProcDeletions,
 case when s.FacilityProcAttempted_Post > 0  then s.FacilityProcNoChange_Post else s.FacilityProcCorrect end as FacilityProcCorrect,
-- Physician LOS
 case when s.PhysicianLOSAttempted_Post > 0  then s.PhysicianLOSAdditions_Post else s.PhysicianLOSAdditions end as PhysicianLOSAdditions,
 case when s.PhysicianLOSAttempted_Post > 0  then s.PhysicianLOSRevisions_Post else s.PhysicianLOSRevisions end as PhysicianLOSRevisions,
 case when s.PhysicianLOSAttempted_Post > 0  then s.PhysicianLOSDeletions_Post else s.PhysicianLOSDeletions end as PhysicianLOSDeletions,
 case when s.PhysicianLOSAttempted_Post > 0  then s.PhysicianLOSNoChange_Post else s.PhysicianLOSCorrect end as PhysicianLOSCorrect,
 case when s.PhysicianLOSAttempted_Post > 0  then s.PhysicianLOSModifierChanges_Post else s.PhysicianLOSModifierChanges end as PhysicianLOSModifierChanges,
-- Physician Procedure
 case when s.ProfProcAttempted_Post > 0  then s.ProfProcAdditions_Post else s.ProfProcAdditions end as ProfProcAdditions,
 case when s.ProfProcAttempted_Post > 0  then s.ProfProcRevisions_Post else s.ProfProcRevisions end as ProfProcRevisions,
 case when s.ProfProcAttempted_Post > 0  then s.ProfProcDeletions_Post else s.ProfProcDeletions end as ProfProcDeletions,
 case when s.ProfProcAttempted_Post > 0  then s.ProfProcNoChange_Post else s.ProfProcCorrect end as ProfProcCorrect,
-- Dx 
 case when s.DxAttempted_Post > 0  then s.DxAdditions_Post else s.DxAdditions end as DxAdditions,
 case when s.DxAttempted_Post > 0  then s.DxRevisions_Post else s.DxRevisions end as DxRevisions,
 case when s.DxAttempted_Post > 0  then s.DxDeletions_Post else s.DxDeletions end as DxDeletions,
 case when s.DxAttempted_Post > 0  then s.DxNoChange_Post else s.DxCorrect end as DxCorrect,
 case when s.DxAttempted_Post > 0  then s.DxAbstract_Post else s.DxAbstract end as DxAbstract,
 case when s.DxAttempted_Post > 0  then s.DxPrimaryDxChanges_Post else s.DxPrimaryDxChanges end as DxPrimaryDxChanges,
 case when DxChiefComplaintChanges_Post > 0 then DxChiefComplaintChanges_Post else DxChiefComplaintChanges end as DxChiefComplaintChanges,
 case when s.DxSubmitted_Post > 0 then s.DxSubmitted_Post else DxSubmitted end as DxSubmitted,
-- Obs

 case when s.ObsHoursAttempted_Post > 0  then s.ObsHoursAbstract_Post else s.ObsHoursAbstract end as ObsHoursAbstract,
 case when s.ObsHoursChanges_Post > 0 then s.ObsHoursChanges_Post else s.ObsHoursChanges end as ObsHoursChanges,
 case when s.ObsHoursSubmitted_Post > 0 then s.ObsHoursSubmitted_Post else s.ObsHoursSubmitted end ObsHoursSubmitted, 
-- Procedure Modifier
case when ProcModifierChanges_Post > 0 then ProcModifierChanges_Post else ProcModifierChanges end as ProcModifierChanges,
-- Demographic Changes
case when DemographicChanges_Post > 0 then DemographicChanges_Post else DemographicChanges end as DemographicChanges,
-- Totals
  (case when s.FacilityLOSAdditions_Post > 0 then s.FacilityLOSAdditions_Post else s.FacilityLOSAdditions end
+ case when s.PhysicianLOSAdditions_Post > 0 then s.PhysicianLOSAdditions_Post else s.PhysicianLOSAdditions end
+ case when s.DxAdditions_Post > 0 then s.DxAdditions_Post else s.DxAdditions end
+ case when s.InfusionInjectionAdditions_Post > 0 then s.InfusionInjectionAdditions_Post else s.InfusionInjectionAdditions end
+ case when s.FacilityProcAdditions_Post > 0 then s.FacilityProcAdditions_Post else s.FacilityProcAdditions end
+ case when s.ProfProcAdditions_Post > 0 then s.ProfProcAdditions_Post else s.ProfProcAdditions end
+ case when s.ObsHoursAdditions_Post > 0 then s.ObsHoursAdditions_Post else s.ObsHoursAdditions end
  ) as AddedCount,
  (case when s.FacilityLOSRevisions_Post > 0 then s.FacilityLOSRevisions_Post else s.FacilityLOSRevisions end
+ case when s.PhysicianLOSRevisions_Post > 0 then s.PhysicianLOSRevisions_Post else s.PhysicianLOSRevisions end
+ case when s.DxRevisions_Post > 0 then s.DxRevisions_Post else s.DxRevisions end
+ case when s.InfusionInjectionRevisions_Post > 0 then s.InfusionInjectionRevisions_Post else s.InfusionInjectionRevisions end
+ case when s.FacilityProcRevisions_Post > 0 then s.FacilityProcRevisions_Post else s.FacilityProcRevisions end
+ case when s.ProfProcRevisions_Post > 0 then s.ProfProcRevisions_Post else s.ProfProcRevisions end
+ case when s.ObsHoursRevisions_Post > 0 then s.ObsHoursRevisions_Post else s.ObsHoursRevisions end
  ) as RevisedCount,
  (case when s.FacilityLOSDeletions_Post > 0 then s.FacilityLOSDeletions_Post else s.FacilityLOSDeletions end
+ case when s.PhysicianLOSDeletions_Post > 0 then s.PhysicianLOSDeletions_Post else s.PhysicianLOSDeletions end
+ case when s.DxDeletions_Post > 0 then s.DxDeletions_Post else s.DxDeletions end
+ case when s.InfusionInjectionDeletions_Post > 0 then s.InfusionInjectionDeletions_Post else s.InfusionInjectionDeletions end
+ case when s.FacilityProcDeletions_Post > 0 then s.FacilityProcDeletions_Post else s.FacilityProcDeletions end
+ case when s.ProfProcDeletions_Post > 0 then s.ProfProcDeletions_Post else s.ProfProcDeletions end
+ case when s.ObsHoursDeletions_Post > 0 then s.ObsHoursDeletions_Post else s.ObsHoursDeletions end
  ) as DeletedCount,
   (case when s.FacilityLOSNoChange_Post > 0 then s.FacilityLOSNoChange_Post else s.FacilityLOSCorrect end
+ case when s.PhysicianLOSNoChange_Post > 0 then s.PhysicianLOSNoChange_Post else s.PhysicianLOSCorrect end
+ case when s.DxNoChange_Post > 0 then s.DxNoChange_Post else s.DxCorrect end
+ case when s.InfusionInjectionNoChange_Post > 0 then s.InfusionInjectionNoChange_Post else s.InfusionInjectionCorrect end
+ case when s.FacilityProcNoChange_Post > 0 then s.FacilityProcNoChange_Post else s.FacilityProcCorrect end
+ case when s.ProfProcNoChange_Post > 0 then s.ProfProcNoChange_Post else s.ProfProcCorrect end
+ case when s.ObsHoursNoChange_Post > 0 then s.ObsHoursNoChange_Post else s.ObsHoursCorrect end
  ) as CorrectCount,
-- Anesthesia
 case when s.AnesthesiaAttempted_Post > 0  then s.AnesthesiaAdditions_Post else s.AnesthesiaAdditions end as AnesthesiaAdditions,
 case when s.AnesthesiaAttempted_Post > 0  then s.AnesthesiaRevisions_Post else s.AnesthesiaRevisions end as AnesthesiaRevisions,
 case when s.AnesthesiaAttempted_Post > 0  then s.AnesthesiaDeletions_Post else s.AnesthesiaDeletions end as AnesthesiaDeletions,
 case when s.AnesthesiaAttempted_Post > 0  then s.AnesthesiaNoChange_Post else s.AnesthesiaCorrect end as AnesthesiaCorrect
into #Scorecard_2
from #Scorecard_1 s
-- *****************************************************************************************************************************************
--Output
select 
s.USER_PROFILE_ID,
s.CoderName,
'Coder ' + cast(DENSE_RANK() OVER (ORDER BY s.User_Profile_ID)  as varchar) as HiddenName,
sum(s.AddedCount) as  AddedCount,
sum(s.RevisedCount) as  RevisedCount,
sum(s.DeletedCount) as  DeletedCount,
sum(s.CorrectCount) as  AccurateCount,
sum(s.DeletedCount)+sum(s.RevisedCount)+sum(s.AddedCount) as CoderAccuracy_N,
sum(s.CorrectCount)+sum(s.RevisedCount)+sum(s.AddedCount) as CoderAccuracy_D,
sum(s.DeletedCount)+sum(s.CorrectCount)+sum(s.RevisedCount)+sum(s.AddedCount) as CoderAccuracy_Total,
case when (select sum(Number_of_Charts_Coded) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0 
else (select sum(Number_of_Charts_Coded) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) end as ChartsCoded, 
(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.user_profile_id = s.user_profile_id and service_agreement_id <> 0 ) as ChartsReviewed,
case when (select sum(Number_of_Charts_Coded) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0 
else
(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.user_profile_id = s.user_profile_id and service_agreement_id <> 0 ) / 
(select cast(sum(Number_of_Charts_Coded) as float) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) end as PercentReviewed,
-- Units / Modifiers
sum(case when u.UnitOpportunities_Post > 0 then u.UnitOpportunities_Post else u.UnitOpportunities end) as UnitOpportunities,
sum(case when u.UnitRevisions_Post > 0 then u.UnitRevisions_Post else u.UnitRevisions end) as UnitRevisions,
sum(case when u.ModifierOpportunities_Post > 0 then u.ModifierOpportunities_Post else u.ModifierOpportunities end) as ModifierOpportunities,
sum(case when u.ModifierRevisions_Post > 0 then u.ModifierRevisions_Post else u.ModifierRevisions end) as ModifierRevisions,
-- Facility LOS
sum(s.FacilityLOSDeletions)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions) as FacilityLOS_EM_N,
sum(s.FacilityLOSCorrect)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions) as FacilityLOS_EM_D,
sum(s.FacilityLOSDeletions)+sum(s.FacilityLOSCorrect)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions) as FacilityLOS_EM_Total,
-- I/I
sum(s.InfInjChanges) as InfInj_N,
sum(s.InfInjSubmitted) as InfInj_D,
-- Facility Procedure 
sum(s.FacilityProcDeletions)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+sum(s.InfusionInjectionDeletions)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as FacilityProc_N,
sum(s.FacilityProcCorrect)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+Sum(s.InfusionInjectionCorrect)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as FacilityProc_D,
sum(s.FacilityProcDeletions)+sum(s.FacilityProcCorrect)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+Sum(s.InfusionInjectionCorrect)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as FacilityProc_Total,
-- Physician LOS 
sum(s.PhysicianLOSDeletions)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions) as PhysicianLOS_EM_N,
sum(s.PhysicianLOSCorrect)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions) as PhysicianLOS_EM_D,
sum(s.PhysicianLOSDeletions)+sum(s.PhysicianLOSCorrect)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions) as PhysicianLOS_EM_Total,
-- Physician Procedure
sum(s.ProfProcDeletions)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions) as ProfProc_N,
sum(s.ProfProcCorrect)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions) as ProfProc_D,
sum(s.ProfProcDeletions)+sum(s.ProfProcCorrect)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions) as ProfProc_Total,
-- Dx
sum(s.DxDeletions)+sum(s.DxRevisions)+sum(s.DxAdditions) as Diagnosis_N,
sum(s.DxCorrect)+sum(s.DxRevisions)+sum(s.DxAdditions) as Diagnosis_D,
sum(s.DxDeletions)+sum(s.DxCorrect)+sum(s.DxRevisions)+sum(s.DxAdditions) as Diagnosis_Total,
-- Obs
sum(s.ObsHoursChanges) + sum(s.ObsHoursAbstract) as ObsHours_N,
sum(s.ObsHoursSubmitted) as ObsHours_D,
-- Chief Complaint
sum(s.DxChiefComplaintChanges) + sum(s.DxAbstract) as ChiefComplaint_N,
sum(s.DxSubmitted) as ChiefComplaint_D,
-- Principal
sum(s.DxPrimaryDxChanges) + sum(s.DxAbstract) as Principal_N,
sum(s.DxSubmitted) as Principal_D,
-- Modifier
sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) as ModifierUsage_N,
(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.service_agreement_id <> 0 and s2.USER_PROFILE_ID = s.user_profile_id ) as ModifierUsage_D,
-- Demographics
sum(s.DemographicChanges) as Demographic_N,
(select count(s2.chart_id) from #Scorecard_1 s2 where service_agreement_id <> 0 ) as Demographic_D,
-- Anesthesia 
Sum(s.AnesthesiaDeletions)+sum(s.AnesthesiaRevisions)+sum(s.AnesthesiaAdditions) as Anesthesia_N,
Sum(s.AnesthesiaCorrect)+sum(s.AnesthesiaRevisions)+sum(s.AnesthesiaAdditions) as Anesthesia_D
from 
#Scorecard_2 s,
#Unit_Mod_1 u
where 
s.chart_id = u.chart_id
group by 
s.user_profile_id, s.CoderName
 
 END
  		END

GO
