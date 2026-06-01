SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













CREATE PROCEDURE [dbo].[rpt_CorroHealth_Rebuttal_QA_Detail] 
	@ReportUser INT,
	@DateType   INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@CUID VARCHAR(MAX),
	@CoderResponse int,	
	@AuditorResponse int,
	@COMPANY_ID       VARCHAR(MAX),
	@FACILITY_ID      VARCHAR(MAX)
	



AS
BEGIN




    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SET NOCOUNT ON;


	-- Test parameters
	--declare 
	--@ReportUser  int        = 80,
	--@DateType   int         = 1,           -- 0 Approved, 1 Post Bill
	--@StartDate   datetime   = '01/01/2025',
	--@EndDate     datetime   = '04/04/2025',
	--@COMPANY_ID       VARCHAR(MAX)   = '296',          -- -1 All
	--@FACILITY_ID      VARCHAR(MAX)   = '-1',		  -- -1 All
	--@CUID        VARCHAR(MAX)		=  '-1',          -- -1 All -- 14166, -- 11584,      
	--@CoderResponse int		= -1,          -- 1Agree,2Disagree, -1All, -2 AwaitingResponse
	--@AuditorResponse int	= -1;		   -- 1Agree,2Disagree, -1All, -2 AwaitingResponse
	

	

	DECLARE @m_ReportUser INT
	DECLARE @m_StartDate DATETIME
	DECLARE @m_EndDate DATETIME
	DECLARE @m_FACILITY_ID VARCHAR(MAX)
	Set @m_ReportUser = @ReportUser
	Set @m_StartDate = @StartDate
	Set @m_EndDate = @EndDate
	Set @m_FACILITY_ID = @FACILITY_ID
	DECLARE @m_DateType INT = @DateType;
	DECLARE @m_CUID VARCHAR(MAX) = @CUID;	
	DECLARE @m_COMPANY_ID  VARCHAR(MAX) = @COMPANY_ID;
	
	



if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
if object_id('TempDB..#CodedCharts', 'U') is not null drop table #CodedCharts;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#Scorecard_2', 'U') is not null drop table #Scorecard_2;
if object_id('TempDB..#Scorecard_3', 'U') is not null drop table #Scorecard_3;
if object_id('TempDB..#Scorecard_4', 'U') is not null drop table #Scorecard_4;
if object_id('TempDB..#AuditGrid1', 'U') is not null drop table #AuditGrid1;
if object_id('TempDB..#AuditNotes1', 'U') is not null drop table #AuditNotes1;
if object_id('TempDB..#AuditNotes2', 'U') is not null drop table #AuditNotes2;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;


print 'Section: 00 ' + convert(varchar, getdate(), 121)

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
	and  ( sa.COMPANY_ID in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ',')) )
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		) fa;

print 'Section: 01 ' + convert(varchar, getdate(), 121)
-- *****************************************************************************************************************************************


SELECT	c.chart_id, c.service_agreement_id, c.facility_chart_id, c.APPROVED_DATE, c.POST_BILL_AUDIT_COMPLETED,
c.completed_by_user_profile_id, c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID,

FACILITY_SERVICE_LEVEL_AUDIT_COMMENT, FACILITY_PROCEDURES_AUDIT_COMMENT, PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT, PHYSICIAN_PROCEDURES_AUDIT_COMMENT,
DIAGNOSIS_CODING_AUDIT_COMMENT, INFUSION_INJECTION_AUDIT_COMMENT, AUDITOR_REVIEW_FEEDBACK, OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT,
OBSERVATION_PROCEDURES_AUDIT_COMMENT, OBSERVATION_AUDITOR_REVIEW_FEEDBACK, DEMOGRAPHIC_AUDIT_COMMENT, ANESTHESIA_CODING_AUDIT_COMMENT,

SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT,SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT,SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT,
SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT,SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT,SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT,
SECOND_LEVEL_QA_AUDITOR_REVIEW_FEEDBACK,SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT,SECOND_LEVEL_QA_OBSERVATION_FACILITY_PROCEDURE_AUDIT_COMMENT,
SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK,SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT,SECOND_LEVEL_QA_ANESTHESIA_CODING_AUDIT_COMMENT,

CODER_ERROR_RESPONSE,
CODER_ERROR_RESPONSE_COMMENTS,
CODER_RESPONSE_DATE,

AUDITOR_ERROR_RESPONSE,
AUDITOR_ERROR_RESPONSE_COMMENTS,
AUDITOR_RESPONSE_DATE


INTO	[#ChartSubset]
FROM	chart as c 
LEFT OUTER JOIN CHART_SECOND_LEVEL_AUDIT_COMMENTS sl ON c.CHART_ID = sl.CHART_ID  
WHERE	c.CHART_STATUS_ID in (4, 5)
AND	   (c.COMPLETED_BY_USER_PROFILE_ID in (SELECT * FROM SPLITSTRING(@m_CUID, ',') ) OR '-1' in (SELECT * FROM SPLITSTRING(@m_CUID, ',') ) )
AND    ((c.APPROVED_BY_USER_PROFILE_ID <> 2 AND 	c.START_QA_DATE is not null)
	OR  (c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID <> 2 AND c.POST_BILL_AUDIT_STARTED is not null )
	   )


AND		
        (		
		(@m_DateType = 0 and c.APPROVED_DATE BETWEEN @m_StartDate AND  DateAdd(second, 86399, @m_EndDate ) )
        or 
		(@m_DateType = 1 and c.POST_BILL_AUDIT_COMPLETED BETWEEN @m_StartDate AND  DateAdd(second, 86399, @m_EndDate ) )
		) 
AND	    c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
;



-- select * from #ChartSubset where chart_id = 138674501 138649503 138553140

print 'Section: 02 ' + convert(varchar, getdate(), 121)
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

-- create nonclustered index idx_CHART_ID on #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION (CHART_ID)

print 'Section: 03 ' + convert(varchar, getdate(), 121)	
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

print 'Section: 04 ' + convert(varchar, getdate(), 121)		
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

create nonclustered index idx_CHART_ID on #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION (CHART_ID)

print 'Section: 05 ' + convert(varchar, getdate(), 121)
------------------------------------------------------------------------------------
-- Temp Tables to create #Scorecard_1



if object_id('TempDB..#ChartPostBillAudit', 'U') is not null drop table #ChartPostBillAudit;
select pba.*
into #ChartPostBillAudit
from
	dbo.ChartPostBillAudit pba
	inner join #ChartSubset cs on pba.ChartId = cs.CHART_ID

create nonclustered index idx_CHART_ID on #ChartPostBillAudit (CHARTID)
create nonclustered index idx_ChartPostBillAuditId on #ChartPostBillAudit (ChartPostBillAuditId)
create nonclustered index idx_ChartPostBillAuditStatusTypeCode on #ChartPostBillAudit (ChartPostBillAuditStatusTypeCode)



print 'Section: 06.0 ' + convert(varchar, getdate(), 121)
-------------------------------------------------------------------------------------------

if object_id('TempDB..#ChartAuditVersion', 'U') is not null drop table #ChartAuditVersion;
select cav.*
into #ChartAuditVersion
from
	dbo.ChartAuditVersion cav
where
	cav.ChartAuditId in (select distinct ChartPostBillAuditId from #ChartPostBillAudit)

create nonclustered index idx_ChartAuditId on #ChartAuditVersion (ChartAuditId)
create nonclustered index idx_ChartAuditVersionId on #ChartAuditVersion (ChartAuditVersionId)
create nonclustered index idx_VersionNumber on #ChartAuditVersion (VersionNumber)

 

print 'Section: 06.1 ' + convert(varchar, getdate(), 121)

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

print 'Section: 06.2 ' + convert(varchar, getdate(), 121)

CREATE NONCLUSTERED INDEX [tIDX_ChartAuditFacilityLosVersionItem__ChartAuditActionTypeCode_ExcludeFromQA__include]
ON #ChartAuditFacilityLosVersionItem ([ChartAuditActionTypeCode],[ExcludeFromQA])
INCLUDE ([ChartAuditVersionId])

print 'Section: 06.3 ' + convert(varchar, getdate(), 121)

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

create nonclustered index idx_ChartAuditVersionId on #ChartAuditProcedureVersionItem (ChartAuditVersionId)
create nonclustered index idx_ExcludeFromQA on #ChartAuditProcedureVersionItem (ExcludeFromQA)
create nonclustered index idx_ProcedureType on #ChartAuditProcedureVersionItem (ProcedureType)
create nonclustered index idx_ChartAuditActionTypeCode on #ChartAuditProcedureVersionItem (ChartAuditActionTypeCode)



print 'Section: 06.4 ' + convert(varchar, getdate(), 121)

CREATE NONCLUSTERED INDEX [tIDX_ChartAuditProcedureVersionItem_VersionIdProcType] 
ON #ChartAuditProcedureVersionItem
(
	[ChartAuditVersionId] ASC,
	[ProcedureType] ASC
)

print 'Section: 06.5 ' + convert(varchar, getdate(), 121)

if object_id('TempDB..#ChartAuditPhysicianLosVersionItem', 'U') is not null drop table #ChartAuditPhysicianLosVersionItem;
select caplos.*
into #ChartAuditPhysicianLosVersionItem
from
	dbo.ChartAuditPhysicianLosVersionItem caplos
where
	caplos.ChartId in (select distinct ChartId from #ChartPostBillAudit)
	and caplos.ExcludeFromQA <> 1

print 'Section: 06.6 ' + convert(varchar, getdate(), 121)

CREATE NONCLUSTERED INDEX [tIDX_ChartAuditPhysicianLosVersionItem__ChartAuditActionTypeCode_ExcludeFromQA__include]
ON #ChartAuditPhysicianLosVersionItem ([ChartAuditActionTypeCode],[ExcludeFromQA])
INCLUDE ([ChartAuditVersionId])

print 'Section: 06.7 ' + convert(varchar, getdate(), 121)

if object_id('TempDB..#ChartAuditDiagnosisVersionItem', 'U') is not null drop table #ChartAuditDiagnosisVersionItem;
select cad.*
into #ChartAuditDiagnosisVersionItem
from
	dbo.ChartAuditDiagnosisVersionItem cad
where
	cad.ExcludeFromQA <> 1

print 'Section: 06.8 ' + convert(varchar, getdate(), 121)

create nonclustered index [tIDX_ChartAuditDiagnosisVersionItem]
on #ChartAuditDiagnosisVersionItem ([ChartAuditVersionId] asc)
include (
            [ChartAuditActionTypeCode]
            ,[ExcludeFromQA]
        )

print 'Section: 06.9 ' + convert(varchar, getdate(), 121)



if object_id('TempDB..#CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION;

select paa.* 
into #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION
from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION paa
inner join #ChartSubset cs on paa.Chart_Id = cs.CHART_ID

create nonclustered index idx_CHART_ID on #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION (CHART_ID)
create nonclustered index idx_PROCEDURE_TYPE on #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION (PROCEDURE_TYPE)
create nonclustered index idx_ACTION on #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION (ACTION)
create nonclustered index idx_EXCLUDE_FROM_QA_REPORT on #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION (EXCLUDE_FROM_QA_REPORT) 


if object_id('TempDB..#CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION;

select laa.*
into #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION
from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION laa
inner join #ChartSubset cs on laa.Chart_Id = cs.CHART_ID

create nonclustered index idx_CHART_ID on #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION (CHART_ID)
create nonclustered index idx_ACTION on #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION (ACTION)
create nonclustered index idx_EXCLUDE_FROM_QA_REPORT on #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION (EXCLUDE_FROM_QA_REPORT) 


if object_id('TempDB..#CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION;

select plaa.*
into #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION
from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plaa
inner join #ChartSubset cs on plaa.Chart_Id = cs.CHART_ID

create nonclustered index idx_CHART_ID on #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION (CHART_ID)
create nonclustered index idx_ACTION on #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION (ACTION)
create nonclustered index idx_EXCLUDE_FROM_QA_REPORT on #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION (EXCLUDE_FROM_QA_REPORT) 

print 'Section: 06.10 ' + convert(varchar, getdate(), 121)

-- ************************************************************************************

SELECT		c.service_agreement_id, 
			ServiceAgreementDescription = cast(null as varchar(50)), 			
			c.chart_id, c.facility_chart_id, c.PATIENT_DISPOSITION_ID,
			c.APPROVED_DATE, c.POST_BILL_AUDIT_COMPLETED, 			
			c.COMPLETED_BY_USER_PROFILE_ID as USER_PROFILE_ID,  
			CoderName = cast(null as varchar(50)), 			
			c.CODER_ERROR_RESPONSE, c.CODER_ERROR_RESPONSE_COMMENTS, c.AUDITOR_ERROR_RESPONSE, c.AUDITOR_ERROR_RESPONSE_COMMENTS,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
			+ (select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)  
			+ (select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND (pr.IS_CODER_CORRECT = 1 OR pr.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR flos.EXCLUDE_FROM_QA_REPORT = 1))  
			+ (select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 or PLOS.EXCLUDE_FROM_QA_REPORT = 1)) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 ) 
			+ (select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount,

			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxAttempted,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAbstract,
--Dx Post	

			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as DxNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as DxAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as DxRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as DxDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as DxAbstract_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as DxAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as DxActions_Post,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,

-- Facility Procedures Post
            (select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as FacilityProcNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as FacilityProcAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as FacilityProcRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as FacilityProcDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as FacilityProcAbstract_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID)  as FacilityProcAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as FacilityProcActions_Post,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionDeletions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAbstract,

-- Procedures I/I Post
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAbstract_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionActions_Post,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted, 
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions, 							 
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions, 							 
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions, 							 
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract,

-- Prof Procedures Post
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as ProfProcNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as ProfProcAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as ProfProcRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as ProfProcDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as ProfProcAbstract_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID)  as ProfProcAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ProfProcActions_Post,

			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted, 
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions, 							 
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions, 							 
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions, 							 
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAbstract, 	

-- Obs Procedures Post			
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as ObsHoursAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as ObsHoursRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as ObsHoursDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as ObsHoursAbstract_Post,			
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND pba.ChartId = c.CHART_ID)  as ObsHoursAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursActions_Post,
											 
			(select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,
			(select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted, 
			(select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
			(select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
			(select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
			(select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,	

--Facility LOS Post			
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as FacilityLOSNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as FacilityLOSRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as FacilityLOSDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAbstract_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as FacilityLOSActions_Post,
			
			(select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect ,-- PA
			(select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted, 	
			(select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,

--Physician LOS Post

			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAbstract_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSActions_Post,

			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,	
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,
			
			(select count(DISTINCT pr.CHART_ID) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
			(select count(DISTINCT pr.CHART_ID) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
			(select count(DISTINCT pr.CHART_ID) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted, 
			(select count(DISTINCT pr.CHART_ID) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges, 
			(select count(DISTINCT pr.CHART_ID) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,  																															 
			(select count(DISTINCT pr.CHART_ID) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,
--			(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges--,  Not Used
			
			FacilityLOSService = cast(null as varchar(1)),
			InfusionInjectionService = cast(null as varchar(1)),
			FacilityProcService = cast(null as varchar(1)),
			PhysicianLOSService = cast(null as varchar(1)),
			ProfProcService = cast(null as varchar(1)),
			DxService = cast(null as varchar(1)),
			ObsHoursService = cast(null as varchar(1)),


			
			(select count(*) from #CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSActions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionActions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcActions,
			(select count(*) from #CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSActions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcActions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxActions,
			(select count(*) from #CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursActions 							 
			

into #Scorecard_1
			FROM	[#ChartSubset] c with (NOLOCK)
			--		LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID    
			--		LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
			WHERE		c.approved_by_user_profile_id > 2		                   



	UPDATE x
	SET 	
	x.CoderName = t.LAST_NAME + ', ' + t.FIRST_NAME
	FROM 
	#Scorecard_1 as x
	join USER_PROFILE as t 
	ON x.USER_PROFILE_ID =  t.USER_PROFILE_ID;


	UPDATE x
	SET 	
	x.ServiceAgreementDescription = sa.description,
	x.FacilityLOSService = case when sa.EVALUATE_FACILITY_SVC = 1 then 'Y' else 'N' end,
	x.InfusionInjectionService = case when (sa.INFUSION_INJECTION_METHOD_ID = 1 or sa.INFUSION_INJECTION_METHOD_ID = 2) then 'Y' else 'N' end,
	x.FacilityProcService = case when sa.EVALUATE_FACILITY_PROCEDURES = 1 then 'Y' else 'N' end,
	x.PhysicianLOSService = case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 'Y' else 'N' end,
	x.ProfProcService = case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 'Y' else 'N' end,
	x.DxService = case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 'Y' else 'N' end,
	x.ObsHoursService = case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 and x.PATIENT_DISPOSITION_ID = 5 then 'Y' else 'N' end
	FROM 
	#Scorecard_1 as x
	join SERVICE_AGREEMENT as sa 
	ON x.SERVICE_AGREEMENT_ID =  sa.SERVICE_AGREEMENT_ID;


print 'Section: 07 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************
-- Auditor Grid Temp 

select
chart_id,

FacilityLOSService,
FacilityLOSAttempted,
FacilityLOSActions,
case when s.FacilityLOSAdditions > 0 then cast(s.FacilityLOSAdditions as varchar(5)) + ' Additions'end as FacilityLOSAdditionError,
case when s.FacilityLOSRevisions > 0 then cast(s.FacilityLOSRevisions as varchar(5)) + ' Revisions'end as FacilityLOSRevisionError,
case when s.FacilityLOSDeletions > 0 then cast(s.FacilityLOSDeletions as varchar(5)) + ' Deletions'end as FacilityLOSDeletionError,
case when s.FacilityLOSAbstract > 0 then cast(s.FacilityLOSAbstract as varchar(5)) + ' Abstract'end as FacilityLOSAbstractError,
case when s.FacilityLOSAdditions_Post > 0 then cast(s.FacilityLOSAdditions_Post as varchar(5)) + ' Additions_Post'end as FacilityLOSAdditionPostError,
case when s.FacilityLOSRevisions_Post > 0 then cast(s.FacilityLOSRevisions_Post as varchar(5)) + ' Revisions_Post'end as FacilityLOSRevisionPostError,
case when s.FacilityLOSDeletions_Post > 0 then cast(s.FacilityLOSDeletions_Post as varchar(5)) + ' Deletions_Post'end as FacilityLOSDeletionPostError,
case when s.FacilityLOSAbstract_Post > 0 then cast(s.FacilityLOSAbstract_Post as varchar(5)) + ' Abstract_Post'end as FacilityLOSAbstractPostError,
s.FacilityLOSNoChange_Post,
s.FacilityLOSAttempted_Post,
s.FacilityLOSActions_Post,

InfusionInjectionService,
InfusionInjectionAttempted,
InfusionInjectionActions, 
case when s.InfusionInjectionAdditions > 0 then cast(s.InfusionInjectionAdditions as varchar(5)) + ' Additions'end as InfusionInjectionAdditionError,
case when s.InfusionInjectionRevisions > 0 then cast(s.InfusionInjectionRevisions as varchar(5)) + ' Revisions'end as InfusionInjectionRevisionError,
case when s.InfusionInjectionDeletions > 0 then cast(s.InfusionInjectionDeletions as varchar(5)) + ' Deletions'end as InfusionInjectionDeletionError,
case when s.InfusionInjectionAbstract > 0 then cast(s.InfusionInjectionAbstract as varchar(5)) + ' Abstract'end as InfusionInjectionAbstractError,
case when s.InfusionInjectionAdditions_Post > 0 then cast(s.InfusionInjectionAdditions_Post as varchar(5)) + ' Additions_Post'end as InfusionInjectionAdditionPostError,
case when s.InfusionInjectionRevisions_Post > 0 then cast(s.InfusionInjectionRevisions_Post as varchar(5)) + ' Revisions_Post'end as InfusionInjectionRevisionPostError,
case when s.InfusionInjectionDeletions_Post > 0 then cast(s.InfusionInjectionDeletions_Post as varchar(5)) + ' Deletions_Post'end as InfusionInjectionDeletionPostError,
case when s.InfusionInjectionAbstract_Post > 0 then cast(s.InfusionInjectionAbstract_Post as varchar(5)) + ' Abstract_Post'end as InfusionInjectionAbstractPostError,
s.InfusionInjectionNoChange_Post,
s.InfusionInjectionAttempted_Post,
s.InfusionInjectionActions_Post,

FacilityProcService,
FacilityProcAttempted,
FacilityProcActions,
case when s.FacilityProcAdditions > 0 then cast(s.FacilityProcAdditions as varchar(5)) + ' Additions'end as FacilityProcAdditionError,
case when s.FacilityProcRevisions > 0 then cast(s.FacilityProcRevisions as varchar(5)) + ' Revisions'end as FacilityProcRevisionError,
case when s.FacilityProcDeletions > 0 then cast(s.FacilityProcDeletions as varchar(5)) + ' Deletions'end as FacilityProcDeletionError,
case when s.FacilityProcAbstract > 0 then cast(s.FacilityProcAbstract as varchar(5)) + ' Abstract'end as FacilityProcAbstractError,
case when s.FacilityProcAdditions_Post > 0 then cast(s.FacilityProcAdditions_Post as varchar(5)) + ' Additions_Post'end as FacilityProcAdditionPostError,
case when s.FacilityProcRevisions_Post > 0 then cast(s.FacilityProcRevisions_Post as varchar(5)) + ' Revisions_Post'end as FacilityProcRevisionPostError,
case when s.FacilityProcDeletions_Post > 0 then cast(s.FacilityProcDeletions_Post as varchar(5)) + ' Deletions_Post'end as FacilityProcDeletionPostError,
case when s.FacilityProcAbstract_Post > 0 then cast(s.FacilityProcAbstract_Post as varchar(5)) + ' Abstract_Post'end as FacilityProcAbstractPostError,
s.FacilityProcNoChange_Post,
s.FacilityProcAttempted_Post,
s.FacilityProcActions_Post,


PhysicianLOSService,
PhysicianLOSAttempted, 
PhysicianLOSActions,
case when s.PhysicianLOSAdditions > 0 then cast(s.PhysicianLOSAdditions as varchar(5)) + ' Additions'end as PhysicianLOSAdditionError,
case when s.PhysicianLOSRevisions > 0 then cast(s.PhysicianLOSRevisions as varchar(5)) + ' Revisions'end as PhysicianLOSRevisionError,
case when s.PhysicianLOSDeletions > 0 then cast(s.PhysicianLOSDeletions as varchar(5)) + ' Deletions'end as PhysicianLOSDeletionError,
case when s.PhysicianLOSAbstract > 0 then cast(s.PhysicianLOSAbstract as varchar(5)) + ' Abstract'end as PhysicianLOSAbstractError,
case when s.PhysicianLOSAdditions_Post > 0 then cast(s.PhysicianLOSAdditions_Post as varchar(5)) + ' Additions_Post'end as PhysicianLOSAdditionPostError,
case when s.PhysicianLOSRevisions_Post > 0 then cast(s.PhysicianLOSRevisions_Post as varchar(5)) + ' Revisions_Post'end as PhysicianLOSRevisionPostError,
case when s.PhysicianLOSDeletions_Post > 0 then cast(s.PhysicianLOSDeletions_Post as varchar(5)) + ' Deletions_Post'end as PhysicianLOSDeletionPostError,
case when s.PhysicianLOSAbstract_Post > 0 then cast(s.PhysicianLOSAbstract_Post as varchar(5)) + ' Abstract_Post'end as PhysicianLOSAbstractPostError,
s.PhysicianLOSNoChange_Post,
s.PhysicianLOSAttempted_Post,
s.PhysicianLOSActions_Post,

ProfProcService,
ProfProcAttempted, 
ProfProcActions,
case when s.ProfProcAdditions > 0 then cast(s.ProfProcAdditions as varchar(5)) + ' Additions'end as ProfProcAdditionError,
case when s.ProfProcRevisions > 0 then cast(s.ProfProcRevisions as varchar(5)) + ' Revisions'end as ProfProcRevisionError,
case when s.ProfProcDeletions > 0 then cast(s.ProfProcDeletions as varchar(5)) + ' Deletions'end as ProfProcDeletionError,
case when s.ProfProcAbstract > 0 then cast(s.ProfProcAbstract as varchar(5)) + ' Abstract'end as ProfProcAbstractError,
case when s.ProfProcAdditions_Post > 0 then cast(s.ProfProcAdditions_Post as varchar(5)) + ' Additions_Post'end as ProfProcAdditionPostError,
case when s.ProfProcRevisions_Post > 0 then cast(s.ProfProcRevisions_Post as varchar(5)) + ' Revisions_Post'end as ProfProcRevisionPostError,
case when s.ProfProcDeletions_Post > 0 then cast(s.ProfProcDeletions_Post as varchar(5)) + ' Deletions_Post'end as ProfProcDeletionPostError,
case when s.ProfProcAbstract_Post > 0 then cast(s.ProfProcAbstract_Post as varchar(5)) + ' Abstract_Post'end as ProfProcAbstractPostError,
s.ProfProcNoChange_Post,
s.ProfProcAttempted_Post,
s.ProfProcActions_Post,

DxService,
DxAttempted,
DxActions,
case when s.DxAdditions > 0 then cast(s.DxAdditions as varchar(5)) + ' Additions'end as DxAdditionError,
case when s.DxRevisions > 0 then cast(s.DxRevisions as varchar(5)) + ' Revisions'end as DxRevisionError,
case when s.DxDeletions > 0 then cast(s.DxDeletions as varchar(5)) + ' Deletions'end as DxDeletionError,
case when s.DxAbstract > 0 then cast(s.DxAbstract as varchar(5)) + ' Abstract'end as DxAbstractError,
case when s.DxAdditions_Post > 0 then cast(s.DxAdditions_Post as varchar(5)) + ' Additions_Post'end as DxAdditionPostError,
case when s.DxRevisions_Post > 0 then cast(s.DxRevisions_Post as varchar(5)) + ' Revisions_Post'end as DxRevisionPostError,
case when s.DxDeletions_Post > 0 then cast(s.DxDeletions_Post as varchar(5)) + ' Deletions_Post'end as DxDeletionPostError,
case when s.DxAbstract_Post > 0 then cast(s.DxAbstract_Post as varchar(5)) + ' Abstract_Post'end as DxAbstractPostError,
s.DxNoChange_Post,
s.DxAttempted_Post,
s.DxActions_Post,


ObsHoursService,
ObsHoursAttempted,
ObsHoursActions,
case when s.ObsHoursAdditions > 0 then cast(s.ObsHoursAdditions as varchar(5)) + ' Additions'end as ObsHoursAdditionError,
case when s.ObsHoursRevisions > 0 then cast(s.ObsHoursRevisions as varchar(5)) + ' Revisions'end as ObsHoursRevisionError,
case when s.ObsHoursDeletions > 0 then cast(s.ObsHoursDeletions as varchar(5)) + ' Deletions'end as ObsHoursDeletionError,
case when s.ObsHoursAbstract > 0 then cast(s.ObsHoursAbstract as varchar(5)) + ' Abstract'end as ObsHoursAbstractError,

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

print 'Section: 08 ' + convert(varchar, getdate(), 121)
-- *****************************************************************************************************************************************
-- Auditor Notes Temp
select 
chart_id, 

case when len(DEMOGRAPHIC_AUDIT_COMMENT) > 0 then  
coalesce('Demographics: (1st Auditor) ' + DEMOGRAPHIC_AUDIT_COMMENT +';', '')
else '' end 
+
case when len(SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT) > 0 then  
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT +';', '')
else '' end as Demo,

case when len(PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT) > 0 then  
coalesce('Phys E/M: (1st Auditor) ' + PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT +';', '') 
else  '' end 
+ 
case when len(SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT) > 0 then 
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT +';', '')
else '' end PhyService,

case when len(FACILITY_SERVICE_LEVEL_AUDIT_COMMENT) > 0 then 
coalesce('Fac Svcs: (1st Auditor) ' + FACILITY_SERVICE_LEVEL_AUDIT_COMMENT +';', '') 
else '' end 
+ 
case when len(SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT) > 0 then 
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT +';', '')
else '' end as FacService,


case when len(FACILITY_PROCEDURES_AUDIT_COMMENT) > 0 then 
coalesce('Fac Proc: (1st Auditor) ' + FACILITY_PROCEDURES_AUDIT_COMMENT +';', '') 
else '' end 
+ 
case when len(SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT) > 0 then 
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT +';', '')
else '' end as FacProc,

case when len(PHYSICIAN_PROCEDURES_AUDIT_COMMENT) > 0 then 
coalesce('Phy Proc: (1st Auditor) ' + PHYSICIAN_PROCEDURES_AUDIT_COMMENT +';', '') 
else '' end 
+ 
case when len(SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT) > 0 then 
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT +';', '')
else '' end as PhyProc,

case when len(DIAGNOSIS_CODING_AUDIT_COMMENT) > 0 then 
coalesce('Diagnosis: (1st Auditor) ' + DIAGNOSIS_CODING_AUDIT_COMMENT +';', '') 
else '' end 
+ 
case when len(SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT) > 0 then 
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT +';', '')
else '' end as Diagnosis,

case when len(INFUSION_INJECTION_AUDIT_COMMENT) > 0 then 
coalesce('Inf/Inj: (1st Auditor) ' + INFUSION_INJECTION_AUDIT_COMMENT +';', '') 
else '' end 
+ 
case when len(SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT) > 0 then 
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT +';', '')
else '' end as InfInj,

case when len(AUDITOR_REVIEW_FEEDBACK) > 0 then 
coalesce('General: (1st Auditor) ' + AUDITOR_REVIEW_FEEDBACK +';', '') 
else '' end 
+ 
case when len(SECOND_LEVEL_QA_AUDITOR_REVIEW_FEEDBACK) > 0 then 
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_AUDITOR_REVIEW_FEEDBACK +';', '')
else '' end as General,

case when len(ANESTHESIA_CODING_AUDIT_COMMENT) > 0 then 
coalesce('Anesthesia: (1st Auditor) ' + ANESTHESIA_CODING_AUDIT_COMMENT +';', '') 
else '' end 
+ 
case when len(SECOND_LEVEL_QA_ANESTHESIA_CODING_AUDIT_COMMENT) > 0 then 
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_ANESTHESIA_CODING_AUDIT_COMMENT +';', '')
else '' end as Anesthesia,


case when (len(OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT) > 0 or 
           len(OBSERVATION_PROCEDURES_AUDIT_COMMENT) > 0 or
		   len(OBSERVATION_AUDITOR_REVIEW_FEEDBACK) > 0 )
then 
coalesce('Obs: (1st Auditor) ' + OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT +
                                 OBSERVATION_PROCEDURES_AUDIT_COMMENT +
							     OBSERVATION_AUDITOR_REVIEW_FEEDBACK + ';', '') 
else '' end 
+ 
case when (len(SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT) > 0 or 
           len(SECOND_LEVEL_QA_OBSERVATION_FACILITY_PROCEDURE_AUDIT_COMMENT) > 0 or
		   len(SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK) > 0 )
then
coalesce('(2nd Auditor) ' + SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT +
							SECOND_LEVEL_QA_OBSERVATION_FACILITY_PROCEDURE_AUDIT_COMMENT +
							SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK + ';', '')
else '' end as Obs


into #AuditNotes1 
from [#ChartSubset]


print 'Section: 09 ' + convert(varchar, getdate(), 121)

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


print 'Section: 10 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************
--calculations

select 
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, s.facility_chart_id, s.APPROVED_DATE, s.POST_BILL_AUDIT_COMPLETED,
s.USER_PROFILE_ID,  s.CoderName,

s.CODER_ERROR_RESPONSE, s.CODER_ERROR_RESPONSE_COMMENTS, s.AUDITOR_ERROR_RESPONSE, s.AUDITOR_ERROR_RESPONSE_COMMENTS


into #Scorecard_2
from #Scorecard_1 s
where 
(s.CODER_ERROR_RESPONSE = (@CoderResponse) OR (@CoderResponse) in (-1, -2) )
and (s.AUDITOR_ERROR_RESPONSE = (@AuditorResponse) OR (@AuditorResponse) in (-1, -2) ) 
group by 
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, s.facility_chart_id, s.APPROVED_DATE, s.POST_BILL_AUDIT_COMPLETED,
s.USER_PROFILE_ID,  s.CoderName,
s.CODER_ERROR_RESPONSE, s.CODER_ERROR_RESPONSE_COMMENTS, s.AUDITOR_ERROR_RESPONSE, s.AUDITOR_ERROR_RESPONSE_COMMENTS


print 'Section: 11 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************
-- Output

select 
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, 
s.facility_chart_id, s.APPROVED_DATE, s.POST_BILL_AUDIT_COMPLETED,
s.USER_PROFILE_ID,  s.CoderName,

case when s.CODER_ERROR_RESPONSE = 1 then 'Agree' when s.CODER_ERROR_RESPONSE = 2 then 'Disagree' else '' end as CODER_ERROR_RESPONSE, 
s.CODER_ERROR_RESPONSE_COMMENTS, 
case when s.AUDITOR_ERROR_RESPONSE = 1 then 'Agree' when s.AUDITOR_ERROR_RESPONSE = 2 then 'Disagree' else '' end as AUDITOR_ERROR_RESPONSE, 
s.AUDITOR_ERROR_RESPONSE_COMMENTS,


(select 
case 
when FacilityLOSService = 'N' then '-' 
when FacilityLOSService = 'Y' and FacilityLOSAttempted = 0 and FacilityLOSAttempted_Post = 0 then '-' 

when (FacilityLOSService = 'Y' and FacilityLOSAttempted_Post > 0 and FacilityLOSActions_Post > 0)  then 
   coalesce(FacilityLOSAdditionPostError +';', '') + coalesce(FacilityLOSRevisionPostError +';', '') 
   + coalesce(FacilityLOSDeletionPostError +';', '') + coalesce(FacilityLOSAbstractPostError +';', '')

when (FacilityLOSService = 'Y' and FacilityLOSActions > 0 and FacilityLOSActions_Post = 0) then
     coalesce(FacilityLOSAdditionError +';', '') + coalesce(FacilityLOSRevisionError +';', '') 
   + coalesce(FacilityLOSDeletionError +';', '') + coalesce(FacilityLOSAbstractError +';', '')

when (FacilityLOSService = 'Y' and FacilityLOSActions = 0 and FacilityLOSAttempted > 0 
OR FacilityLOSActions_Post = 0 and FacilityLOSAttempted_Post > 0 ) then 'Correct' 

end
from #AuditGrid1
where chart_id = s.chart_id ) as FacilityLOSError, 



--(select 
--case 
--when FacilityLOSService = 'N' then 0 
--when FacilityLOSService = 'Y' and FacilityLOSAttempted = 0 then 0
--when FacilityLOSService = 'Y' and FacilityLOSActions = 0 and FacilityLOSAttempted > 0 then 0 
--when FacilityLOSService = 'Y' and FacilityLOSActions_Post > 0 then 1
--when FacilityLOSService = 'Y' and FacilityLOSActions <> 0 then 1
--end
--from #AuditGrid1
--where chart_id = s.chart_id ) as FacilityLOSErrorScore, 


( select case 
when InfusionInjectionService = 'N' then '-' 
when InfusionInjectionService = 'Y' and InfusionInjectionAttempted = 0 and InfusionInjectionAttempted_Post = 0 then '-' 


when (InfusionInjectionService = 'Y' and InfusionInjectionAttempted_Post > 0 and InfusionInjectionActions_Post > 0)  then 
     coalesce(InfusionInjectionAdditionPostError +';', '') + coalesce(InfusionInjectionRevisionPostError +';', '') 
   + coalesce(InfusionInjectionDeletionPostError +';', '') + coalesce(InfusionInjectionAbstractPostError +';', '')

when (InfusionInjectionService = 'Y' and InfusionInjectionActions > 0 and InfusionInjectionActions_Post = 0) then
     coalesce(InfusionInjectionAdditionError +';', '') + coalesce(InfusionInjectionRevisionError +';', '') 
   + coalesce(InfusionInjectionDeletionError +';', '') + coalesce(InfusionInjectionAbstractError +';', '')

when  (InfusionInjectionService = 'Y' and InfusionInjectionActions = 0 and InfusionInjectionAttempted > 0
       OR InfusionInjectionActions_Post = 0 and InfusionInjectionAttempted_Post > 0) then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as InfusionInjectionError,

--( select case 
--when InfusionInjectionService = 'N' then 0
--when InfusionInjectionService = 'Y' and InfusionInjectionAttempted = 0 then 0
--when InfusionInjectionService = 'Y' and InfusionInjectionActions = 0 and InfusionInjectionAttempted > 0 then 0
--when InfusionInjectionService = 'Y' and InfusionInjectionActions_Post > 0 then 1
--when InfusionInjectionService = 'Y' and InfusionInjectionActions <> 0 then 1
--end 
--from #AuditGrid1
--where chart_id = s.chart_id ) as InfusionInjectionErrorScore,


( select case 
when FacilityProcService = 'N' then '-' 
when (FacilityProcService = 'Y' and FacilityProcAttempted = 0 and FacilityProcAttempted_Post = 0) then '-' 


when (FacilityProcService = 'Y' and FacilityProcAttempted_Post > 0 and FacilityProcActions_Post > 0)  then 
     coalesce(FacilityProcAdditionPostError +';', '') + coalesce(FacilityProcRevisionPostError +';', '') 
   + coalesce(FacilityProcDeletionPostError +';', '') + coalesce(FacilityProcAbstractPostError +';', '')

when (FacilityProcService = 'Y' and FacilityProcActions > 0 and FacilityProcActions_Post = 0) then
     coalesce(FacilityProcAdditionError +';', '') + coalesce(FacilityProcRevisionError +';', '') 
   + coalesce(FacilityProcDeletionError +';', '') + coalesce(FacilityProcAbstractError +';', '')

when  (FacilityProcService = 'Y' and FacilityProcActions = 0 and FacilityProcAttempted > 0 
       OR FacilityProcActions_Post = 0 and FacilityProcAttempted_Post > 0 ) then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as FacilityProcError,

--( select case 
--when FacilityProcService = 'N' then 0
--when FacilityProcService = 'Y' and FacilityProcAttempted = 0 then 0
--when FacilityProcService = 'Y' and FacilityProcActions = 0 and FacilityProcAttempted > 0 then 0
--when FacilityProcService = 'Y' and FacilityProcActions_Post > 0 then 1
--when FacilityProcService = 'Y' and FacilityProcActions <> 0 then 1
--end 
--from #AuditGrid1
--where chart_id = s.chart_id ) as FacilityProcErrorScore,


(select 
case 
when PhysicianLOSService = 'N' then '-' 
when PhysicianLOSService = 'Y' and PhysicianLOSAttempted = 0 and PhysicianLOSAttempted_Post = 0 then '-' 


when (PhysicianLOSService = 'Y' and PhysicianLOSAttempted_Post > 0 and PhysicianLOSActions_Post > 0) then 
     coalesce(PhysicianLOSAdditionPostError +';', '') + coalesce(PhysicianLOSRevisionPostError +';', '') 
   + coalesce(PhysicianLOSDeletionPostError +';', '') + coalesce(PhysicianLOSAbstractPostError +';', '')

when (PhysicianLOSService = 'Y' and PhysicianLOSActions > 0 and PhysicianLOSActions_Post = 0) then
     coalesce(PhysicianLOSAdditionError +';', '') + coalesce(PhysicianLOSRevisionError +';', '') 
   + coalesce(PhysicianLOSDeletionError +';', '') + coalesce(PhysicianLOSAbstractError +';', '')

when (PhysicianLOSService = 'Y' and PhysicianLOSActions = 0 and PhysicianLOSAttempted > 0 
      OR PhysicianLOSActions_Post = 0 and PhysicianLOSAttempted_Post > 0 ) then 'Correct' 

end
from #AuditGrid1
where chart_id = s.chart_id ) as PhysicianLOSError,

--( select case 
--when PhysicianLOSService = 'N' then 0
--when PhysicianLOSService = 'Y' and PhysicianLOSAttempted = 0 then 0
--when PhysicianLOSService = 'Y' and PhysicianLOSActions = 0 and PhysicianLOSAttempted > 0 then 0
--when PhysicianLOSService = 'Y' and PhysicianLOSActions_Post > 0 then 1
--when PhysicianLOSService = 'Y' and PhysicianLOSActions <> 0 then 1
--end 
--from #AuditGrid1
--where chart_id = s.chart_id )as PhysicianLOSErrorScore,


( select case 
when ProfProcService = 'N' then '-' 
when ProfProcService = 'Y' and ProfProcAttempted = 0 and ProfProcAttempted_Post = 0 then '-' 


when (ProfProcService = 'Y' and ProfProcAttempted_Post > 0 and ProfProcActions_Post > 0) then 
     coalesce(ProfProcAdditionPostError +';', '') + coalesce(ProfProcRevisionPostError +';', '') 
   + coalesce(ProfProcDeletionPostError +';', '') + coalesce(ProfProcAbstractPostError +';', '')

when (ProfProcService = 'Y' and ProfProcActions > 0 and ProfProcActions_Post = 0 ) then
     coalesce(ProfProcAdditionError +';', '') + coalesce(ProfProcRevisionError +';', '') 
   + coalesce(ProfProcDeletionError +';', '') + coalesce(ProfProcAbstractError +';', '')

when  (ProfProcService = 'Y' and ProfProcActions = 0 and ProfProcAttempted > 0 
       OR ProfProcActions_Post = 0 and ProfProcAttempted_Post > 0 ) then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as ProfProcError,

--( select case 
--when ProfProcService = 'N' then 0
--when ProfProcService = 'Y' and ProfProcActions_Post > 0 then 1
--when ProfProcService = 'Y' and ProfProcAttempted = 0 then 0
--when ProfProcService = 'Y' and ProfProcActions = 0 and ProfProcAttempted > 0 then 0
--when ProfProcService = 'Y' and ProfProcActions <> 0 then 1
--end 
--from #AuditGrid1
--where chart_id = s.chart_id ) as ProfProcErrorScore,



( select case 
when DxService = 'N' then '-' 
when DxService = 'Y' and DxAttempted = 0 then '-' 
when DxService = 'Y' and DxActions = 0 and DxAttempted > 0 then 'Correct' 


when (DxService = 'Y' and DxAttempted_Post > 0 and DxActions_Post > 0) then 
     coalesce(DxAdditionPostError +';', '') + coalesce(DxRevisionPostError +';', '') 
   + coalesce(DxDeletionPostError +';', '') + coalesce(DxAbstractPostError +';', '')

when (DxService = 'Y' and DxActions > 0 and DxActions_Post = 0) then 
coalesce(DxAdditionError +';', '') + coalesce(DxRevisionError +';', '') 
  + coalesce(DxDeletionError +';', '') + coalesce(DxAbstractError +';', '')



end 
from #AuditGrid1
where chart_id = s.chart_id ) as DxError,

--( select case 
--when DxService = 'N' then 0
--when DxService = 'Y' and DxAttempted = 0 then 0
--when DxService = 'Y' and DxActions = 0 and DxAttempted > 0 then 0
--when DxService = 'Y' and DxActions_Post > 0 then 1
--when DxService = 'Y' and DxActions <> 0 then 1
--end 
--from #AuditGrid1
--where chart_id = s.chart_id ) as DxErrorScore,


( select case 
when ObsHoursService = 'N' then '-' 
when ObsHoursService = 'Y' and ObsHoursAttempted = 0 then '-' 
when ObsHoursService = 'Y' and ObsHoursActions = 0 and ObsHoursAttempted > 0 then 'Correct' 

when (ObsHoursService = 'Y' and ObsHoursAttempted_Post > 0 and ObsHoursActions_Post > 0) then 
coalesce(ObsHoursAdditionPostError +';', '') + coalesce(ObsHoursRevisionPostError +';', '') 
  + coalesce(ObsHoursDeletionPostError +';', '') + coalesce(ObsHoursAbstractPostError +';', '')

when (ObsHoursService = 'Y' and ObsHoursActions > 0 and ObsHoursActions_Post = 0) then 
coalesce(ObsHoursAdditionError +';', '') + coalesce(ObsHoursRevisionError +';', '') 
  + coalesce(ObsHoursDeletionError +';', '') + coalesce(ObsHoursAbstractError +';', '')
end from #AuditGrid1
where chart_id = s.chart_id )as ObsHoursError,


--( select case 
--when ObsHoursService = 'N' then 0
--when ObsHoursService = 'Y' and ObsHoursAttempted = 0 then 0
--when ObsHoursService = 'Y' and ObsHoursActions = 0 and ObsHoursAttempted > 0 then 0
--when ObsHoursService = 'Y' and ObsHoursActions_Post > 0 then 1
--when ObsHoursService = 'Y' and ObsHoursActions <> 0 then 1
--end from #AuditGrid1
--where chart_id = s.chart_id )as ObsHoursErrorScore,



(select 
coalesce(Demo, '') + coalesce(PhyService, '') + coalesce(FacService, '') + coalesce(FacProc, '') +
coalesce(PhyProc, '') + coalesce(Diagnosis, '') + coalesce(InfInj, '') + coalesce(General, '') +
coalesce(Anesthesia, '') + coalesce(Obs, '') as AuditNotes
from #AuditNotes1
where chart_id = s.chart_id ) as AuditNotes,

(select 
coalesce(Demo, '') + coalesce(PhyService, '') + coalesce(FacService, '') + coalesce(FacProc, '') +
coalesce(PhyProc, '') + coalesce(Diagnosis, '') + coalesce(InfInj, '') + coalesce(General, '') +
coalesce(Anesthesia, '') + coalesce(Obs, '') as AuditNotes
from #AuditNotes2
where chart_id = s.chart_id ) as PostAuditNotes

into #Scorecard_3
from
#Scorecard_2 s

print 'Section: 12 ' + convert(varchar, getdate(), 121)


select *
--, 
--(FacilityLOSErrorScore + InfusionInjectionErrorScore + FacilityProcErrorScore + PhysicianLOSErrorScore 
-- + ProfProcErrorScore + DxErrorScore + ObsHoursErrorScore ) as Rebuttal_Ind
 into #Scorecard_4
from #Scorecard_3

 -- select * from #Scorecard_4 where chart_id = 139086443 139098449 138553140

print 'Section: 13 ' + convert(varchar, getdate(), 121)

if object_ID('TempDB..#Scorecard_5', 'U') is not null DROP TABLE #Scorecard_5;							

create table #Scorecard_5
(							
	  SERVICE_AGREEMENT_ID	        int					
	, ServiceAgreementDescription   varchar(50)
	, CHART_ID	                    int					
	, FACILITY_CHART_ID	            varchar(20)
	, APPROVED_DATE					datetime
	, POST_BILL_AUDIT_COMPLETED     datetime
	, USER_PROFILE_ID				int
	, CoderName						varchar(100)
	, Coder_Error_Response			varchar(20)
	, Coder_Error_Response_Comments varchar(500)
	, Auditor_Error_Response		varchar(20)
	, Auditor_Error_Response_Comments varchar(500)
	, FacilityLOSError				varchar(100)
	, InfusionInjectionError		varchar(100)
	, FacilityProcError				varchar(100)
	, PhysicianLOSError				varchar(100)
	, ProfProcError					varchar(100)
	, DxError						varchar(100)
	, ObsHoursError					varchar(100)
	, AuditNotes					varchar(500)
	, PostAuditNotes				varchar(500)
--	, Rebuttal_Ind					int
)


print 'Section: 14 ' + convert(varchar, getdate(), 121)

IF @CoderResponse = -2
BEGIN			
	INSERT INTO #Scorecard_5
	SELECT 
	  SERVICE_AGREEMENT_ID	       
	, ServiceAgreementDescription   
	, CHART_ID	                    
	, FACILITY_CHART_ID	            
	, APPROVED_DATE	
	, POST_BILL_AUDIT_COMPLETED				
	, USER_PROFILE_ID				
	, CoderName						
	, Coder_Error_Response			
	, Coder_Error_Response_Comments 
	, Auditor_Error_Response		
	, Auditor_Error_Response_Comments 
	, FacilityLOSError				
	, InfusionInjectionError		
	, FacilityProcError				
	, PhysicianLOSError				
	, ProfProcError					
	, DxError						
	, ObsHoursError					
	, substring(AuditNotes, 1,485)
	, substring(PostAuditNotes, 1,485)
--	, Rebuttal_Ind		
from #Scorecard_4
where 
-- Rebuttal_Ind > 0 and 
 CODER_ERROR_RESPONSE = ''
END;
ELSE
IF @AuditorResponse = -2
BEGIN			
	INSERT INTO #Scorecard_5
	SELECT 
	  SERVICE_AGREEMENT_ID	       
	, ServiceAgreementDescription   
	, CHART_ID	                    
	, FACILITY_CHART_ID	            
	, APPROVED_DATE	
	, POST_BILL_AUDIT_COMPLETED				
	, USER_PROFILE_ID				
	, CoderName						
	, Coder_Error_Response			
	, Coder_Error_Response_Comments 
	, Auditor_Error_Response		
	, Auditor_Error_Response_Comments 
		
	, substring(AuditNotes, 1,485)
	, substring(PostAuditNotes, 1,485), FacilityLOSError				
	, InfusionInjectionError		
	, FacilityProcError				
	, PhysicianLOSError				
	, ProfProcError					
	, DxError						
	, ObsHoursError				
--	, Rebuttal_Ind		
from #Scorecard_4 s
where 
 -- Rebuttal_Ind > 0 and 
 Auditor_ERROR_RESPONSE = ''
 and not exists ( select * from #Scorecard_5 s5
				  where s5.CHART_ID = s.CHART_ID )	
END;
ELSE
BEGIN			
	INSERT INTO #Scorecard_5
	SELECT 
	  SERVICE_AGREEMENT_ID	       
	, ServiceAgreementDescription   
	, CHART_ID	                    
	, FACILITY_CHART_ID	            
	, APPROVED_DATE	
	, POST_BILL_AUDIT_COMPLETED				
	, USER_PROFILE_ID				
	, CoderName						
	, Coder_Error_Response			
	, Coder_Error_Response_Comments 
	, Auditor_Error_Response		
	, Auditor_Error_Response_Comments 
	, FacilityLOSError				
	, InfusionInjectionError		
	, FacilityProcError				
	, PhysicianLOSError				
	, ProfProcError					
	, DxError						
	, ObsHoursError					
	, substring(AuditNotes, 1,485)
	, substring(PostAuditNotes, 1,485)
--	, Rebuttal_Ind		
from #Scorecard_4 s
END;

print 'Section: 15 ' + convert(varchar, getdate(), 121)

select 
      SERVICE_AGREEMENT_ID	       
	, ServiceAgreementDescription   
	, CHART_ID	                    
	, FACILITY_CHART_ID	            
	, APPROVED_DATE		
	, POST_BILL_AUDIT_COMPLETED			
	, USER_PROFILE_ID				
	, CoderName						
	, Coder_Error_Response			
	, Coder_Error_Response_Comments 
	, Auditor_Error_Response		
	, Auditor_Error_Response_Comments 
	, FacilityLOSError				
	, InfusionInjectionError		
	, FacilityProcError				
	, PhysicianLOSError				
	, ProfProcError					
	, DxError						
	, ObsHoursError					
	, AuditNotes					
	, PostAuditNotes					
--	, Rebuttal_Ind
from #Scorecard_5


-- Note: The Rebuttal_Ind is not being used at this time.
-- More work is needed on the Scoring section to include the Post Bill Audit Scores lines 944 - 1136
-- Currently these scores are commented.


  END               





GO
