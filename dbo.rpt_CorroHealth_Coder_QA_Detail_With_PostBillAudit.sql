SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[rpt_CorroHealth_Coder_QA_Detail_With_PostBillAudit] 
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
--	@StartDate DATETIME = '06/03/2024',
--	@EndDate DATETIME   = '06/03/2024',
--	@ACCT_MGR    VARCHAR(MAX) = '-1', 
--	@COMPANY_ID  VARCHAR(MAX) = '-1', 
--	@FACILITY_ID VARCHAR(MAX) = '2366',
--	@UserClass   VARCHAR(MAX) = '-1', -- -1 All, 1 Corp Employee, 4 Client, 5 Vendor
--	@CUID        VARCHAR(MAX) = '14905',
--	@TimeZone    VARCHAR(50)  =	'Central Daylight Time';			--'India Standard Time'; 


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
if object_id('TempDB..#CodedCharts', 'U') is not null drop table #CodedCharts;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#Scorecard_2', 'U') is not null drop table #Scorecard_2;
if object_id('TempDB..#AuditGrid1', 'U') is not null drop table #AuditGrid1;
if object_id('TempDB..#AuditNotes1', 'U') is not null drop table #AuditNotes1;
if object_id('TempDB..#AuditNotes2', 'U') is not null drop table #AuditNotes2;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;
if object_id('TempDB..#TempChartQAS_AAA', 'U') is not null drop table #TempChartQAS_AAA;



-- ********************************************************************************
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


-- select * from #AuthorizedFacilities



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


-- ************************************************************************************



declare @CNT_Facility int = (select count(*) from #AuthorizedFacilities);
declare @CNT_ACCT_MGR int = (SELECT count(*) FROM SPLITSTRING(@m_ACCT_MGR, ','));
declare @CNT_CO int = (SELECT count(*) FROM SPLITSTRING(@m_COMPANY_ID, ','));
declare @CNT_CUID int = (SELECT count(*) FROM #coder);




-- Parameter Check


-- Date Range: 31, Acct Mgr: 1 

--IF (datediff(day,@m_StartDate,@m_EndDate) >= 31

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


SELECT	c.chart_id, c.service_agreement_id, c.facility_chart_id, c.APPROVED_DATE, c.completed_by_user_profile_id, 
c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID,
c.START_QA_DATE, c.POST_BILL_AUDIT_STARTED,
c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,
c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID,
FACILITY_SERVICE_LEVEL_AUDIT_COMMENT, FACILITY_PROCEDURES_AUDIT_COMMENT, PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT, PHYSICIAN_PROCEDURES_AUDIT_COMMENT,
DIAGNOSIS_CODING_AUDIT_COMMENT, INFUSION_INJECTION_AUDIT_COMMENT, AUDITOR_REVIEW_FEEDBACK, OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT,
OBSERVATION_PROCEDURES_AUDIT_COMMENT, OBSERVATION_AUDITOR_REVIEW_FEEDBACK, DEMOGRAPHIC_AUDIT_COMMENT, ANESTHESIA_CODING_AUDIT_COMMENT,
SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT,
SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT,SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT,
SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT,SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT,SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT,
SECOND_LEVEL_QA_AUDITOR_REVIEW_FEEDBACK,SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT,SECOND_LEVEL_QA_OBSERVATION_FACILITY_PROCEDURE_AUDIT_COMMENT,
SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK,SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT,SECOND_LEVEL_QA_ANESTHESIA_CODING_AUDIT_COMMENT



INTO	[#ChartSubset]
FROM	chart as c 
LEFT OUTER JOIN CHART_SECOND_LEVEL_AUDIT_COMMENTS sl ON c.CHART_ID = sl.CHART_ID  
WHERE	
        c.CHART_STATUS_ID in (4, 5) 
AND     c.COMPLETED_BY_USER_PROFILE_ID in ( select USER_PROFILE_ID from #coder) 
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

AND	    c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
;


delete [#ChartSubset]
where START_QA_DATE is null and POST_BILL_AUDIT_STARTED is null;


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

SELECT		
c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, 
c.APPROVED_DATE, up.USER_PROFILE_ID,  up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,

c.approved_by_user_profile_id, 
c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID,
c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID,
-- PBA Audit Reason
            (select pba.ChartPostBillAuditReasonTypeCode from #ChartPostBillAudit pba where pba.ChartPostBillAuditStatusTypeCode = 3 AND pba.ChartId = c.CHART_ID) as AuditReasonCode,
-- Not used in detail
/*
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,

			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND (pr.IS_CODER_CORRECT = 1 OR pr.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR flos.EXCLUDE_FROM_QA_REPORT = 1))  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 or PLOS.EXCLUDE_FROM_QA_REPORT = 1)) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,

			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,

			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 ) 
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,

			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount,
*/
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
-- Facility Procedures
(select count(*) as CNT  from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'FP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_QUANTITY > 0 OR pro.AUDITOR_QUANTITY > 0) ) as FacilityProc_UnitOpp,
(select count(*) as CNT  from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'FP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_QUANTITY <> pro.AUDITOR_QUANTITY ) as FacilityProc_UnitRev,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'FP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_MODIFIER <> '' OR pro.AUDITOR_MODIFIER <> '') ) as FacilityProc_ModOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'FP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_MODIFIER <> pro.AUDITOR_MODIFIER) as FacilityProc_ModRev,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,
-- Facility Procedures Post
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as FacilityProc_UnitOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Quantity,0) = (select isnull(i2.Quantity,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID ) x ) as FacilityProc_UnitRev_Post,
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as FacilityProc_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID ) x ) as FacilityProc_ModRev_Post,
            (select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as FacilityProcNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as FacilityProcAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as FacilityProcRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as FacilityProcDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as FacilityProcAbstract_Post,
-- Procedures I/I
(select count(*) as CNT  from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'CI' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_QUANTITY > 0 OR pro.AUDITOR_QUANTITY > 0) ) as InfusionInjection_UnitOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'CI' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_QUANTITY <> pro.AUDITOR_QUANTITY ) as InfusionInjection_UnitRev,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'CI' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_MODIFIER <> '' OR pro.AUDITOR_MODIFIER <> '') ) as InfusionInjection_ModOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'CI' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_MODIFIER <> pro.AUDITOR_MODIFIER) as InfusionInjection_ModRev,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionDeletions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAbstract,
-- Procedures I/I Post
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as InfusionInjection_UnitOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Quantity,0) = (select isnull(i2.Quantity,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID ) x ) as InfusionInjection_UnitRev_Post,
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as InfusionInjection_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID ) x ) as InfusionInjection_ModRev_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAbstract_Post,
-- Prof Procedures
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'PP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_QUANTITY > 0 OR pro.AUDITOR_QUANTITY > 0) ) as ProfProc_UnitOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'PP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_QUANTITY <> pro.AUDITOR_QUANTITY ) as ProfProc_UnitRev,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'PP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND (pro.CODER_MODIFIER <> '' OR pro.AUDITOR_MODIFIER <> '') ) as ProfProc_ModOpp,
(select count(*) as CNT from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro where pro.CHART_ID = c.CHART_ID AND pro.PROCEDURE_TYPE = 'PP' AND pro.EXCLUDE_FROM_QA_REPORT <> 1 AND pro.CODER_MODIFIER <> pro.AUDITOR_MODIFIER ) as ProfProc_ModRev,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract,
-- Prof Procedures Post
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID AND i.Quantity is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as ProfProc_UnitOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Quantity,0) = (select isnull(i2.Quantity,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID ) x ) as ProfProc_UnitRev_Post,
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditProcedureVersionItemId is null) x )  as ProfProc_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditProcedureVersionItem i2 where i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID ) x ) as ProfProc_ModRev_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as ProfProcNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as ProfProcAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as ProfProcRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as ProfProcDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as ProfProcAbstract_Post,
-- Obs Procedures			
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAbstract, 
-- Obs Procedures Post			
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as ObsHoursAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as ObsHoursRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as ObsHoursDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as ObsHoursAbstract_Post,
--Facility LOS	
(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where  flos.CHART_ID = c.CHART_ID AND (flos.CODER_MODIFIER <> '' OR flos.AUDITOR_MODIFIER <> '' ) AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOS_ModOpp, 
(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where  flos.CHART_ID = c.CHART_ID AND flos.CODER_MODIFIER <> flos.AUDITOR_MODIFIER AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOS_ModRev,		
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted, 
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,	
--Facility LOS Post
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditFacilityLosVersionItemId is null) x )  as FacilityLOS_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditFacilityLosVersionItem i2 where i2.ChartAuditFacilityLosVersionItemId = i.PrevChartAuditFacilityLosVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID ) x ) as FacilityLOS_ModRev_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as FacilityLOSNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as FacilityLOSRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as FacilityLOSDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAbstract_Post,
--Physician LOS
(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where  plos.CHART_ID = c.CHART_ID AND (plos.CODER_MODIFIER <> '' OR plos.AUDITOR_MODIFIER <> '' ) AND plos.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOS_ModOpp, 
(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where  plos.CHART_ID = c.CHART_ID AND plos.CODER_MODIFIER <> plos.AUDITOR_MODIFIER AND plos.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOS_ModRev,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect ,-- PA
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted, 	
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,
--Physician LOS Post
(select sum(x.cnt) from (select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 1 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID AND i.Modifier is not null union all select count(*) as cnt FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID AND i.Modifier is not null and i.PrevChartAuditPhysicianLosVersionItemId is null) x )  as PhysicianLOS_ModOpp_Post,
(select sum(isnull(x.RevCNT, 0)) from (select case when isnull(i.Modifier,0) = (select isnull(i2.Modifier,0) from #ChartAuditPhysicianLosVersionItem i2 where i2.ChartAuditPhysicianLosVersionItemId = i.PrevChartAuditPhysicianLosVersionItemId ) then 0 else 1 end as RevCNT FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID ) x ) as PhysicianLOS_ModRev_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 4 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSNoChange_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 2 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAdditions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 1 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSRevisions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 5 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSDeletions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode = 3 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAbstract_Post,

			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,	
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,
			
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted, 
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges, 
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,  																															 
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,
			(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges, 
			
			case when sa.EVALUATE_FACILITY_SVC = 1 then 'Y' else 'N' end as FacilityLOSService,
			case when (sa.INFUSION_INJECTION_METHOD_ID = 1 or sa.INFUSION_INJECTION_METHOD_ID = 2) then 'Y' else 'N' end as InfusionInjectionService,
			case when sa.EVALUATE_FACILITY_PROCEDURES = 1 then 'Y' else 'N' end as FacilityProcService,
			case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 'Y' else 'N' end as PhysicianLOSService,
			case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 'Y' else 'N' end as ProfProcService,
			case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 'Y' else 'N' end as DxService,
 			case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 and c.PATIENT_DISPOSITION_ID = 5 then 'Y' else 'N' end as ObsHoursService,
			case when sa.COLLECT_ANESTHESIA in ('R','O') then 'Y' else 'N' end as AnesthesiaService,
			
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcActions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcActions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursActions, 							 
			
-- Post Attempted and Action
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as FacilityLOSAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND pba.ChartId = c.CHART_ID)  as InfusionInjectionAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND pba.ChartId = c.CHART_ID)  as ProfProcAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND pba.ChartId = c.CHART_ID)  as ObsHoursAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND pba.ChartId = c.CHART_ID)  as DxAttempted_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND pba.ChartId = c.CHART_ID)  as FacilityProcAttempted_Post,

			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditFacilityLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as FacilityLOSActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'CI' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as InfusionInjectionActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'PP' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ProfProcActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'OB' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as ObsHoursActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditPhysicianLosVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as PhysicianLOSActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditDiagnosisVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as DxActions_Post,
			(select count(*) FROM #ChartPostBillAudit pba, #ChartAuditVersion cav, #ChartAuditProcedureVersionItem i WHERE pba.ChartPostBillAuditId = cav.ChartAuditId AND cav.ChartAuditVersionId = i.ChartAuditVersionId AND pba.ChartPostBillAuditStatusTypeCode = 3 AND cav.VersionNumber = 2 AND i.ExcludeFromQA <> 1 AND i.ProcedureType = 'FP' AND i.ChartAuditActionTypeCode <> 4 AND pba.ChartId = c.CHART_ID)  as FacilityProcActions_Post,

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
			FROM	[#ChartSubset] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID    
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
-- 			WHERE		c.approved_by_user_profile_id > 2	



--			select * from #Scorecard_1 where chart_id = 117116795
-- 116219538
--  119821944



-- Note:
-- Make certain the UnitOpp and UnitRev counts are correct ( 12 fields total )
-- Review the count between a specific field and all fields (*) 
-- Determine the Audit / PBA logic so Counts calculate correctly, this calcultion should be done below, on line 1095 into #Scorecard_2


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
s.ObsHoursActions_Post,

s.AnesthesiaService,
AnesthesiaAttempted,
AnesthesiaActions,
case when s.AnesthesiaAdditions > 0 then cast(s.AnesthesiaAdditions as varchar(5)) + ' Additions'end as AnesthesiaAdditionError,
case when s.AnesthesiaRevisions > 0 then cast(s.AnesthesiaRevisions as varchar(5)) + ' Revisions'end as AnesthesiaRevisionError,
case when s.AnesthesiaDeletions > 0 then cast(s.AnesthesiaDeletions as varchar(5)) + ' Deletions'end as AnesthesiaDeletionError,
case when s.AnesthesiaAbstract > 0 then cast(s.AnesthesiaAbstract as varchar(5)) + ' Abstract'end as AnesthesiaAbstractError,

case when s.AnesthesiaAdditions_Post > 0 then cast(s.AnesthesiaAdditions_Post as varchar(5)) + ' Additions_Post'end as AnesthesiaAdditionPostError,
case when s.AnesthesiaRevisions_Post > 0 then cast(s.AnesthesiaRevisions_Post as varchar(5)) + ' Revisions_Post'end as AnesthesiaRevisionPostError,
case when s.AnesthesiaDeletions_Post > 0 then cast(s.AnesthesiaDeletions_Post as varchar(5)) + ' Deletions_Post'end as AnesthesiaDeletionPostError,
case when s.AnesthesiaAbstract_Post > 0 then cast(s.AnesthesiaAbstract_Post as varchar(5)) + ' Abstract_Post'end as AnesthesiaAbstractPostError,
s.AnesthesiaNoChange_Post,
s.AnesthesiaAttempted_Post,
s.AnesthesiaActions_Post


into #AuditGrid1
from
#Scorecard_1 s




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
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, s.facility_chart_id, s.APPROVED_DATE, s.USER_PROFILE_ID,  s.CoderName,
'Coder ' + cast(DENSE_RANK() OVER (ORDER BY s.User_Profile_ID)  as varchar) as HiddenName,
s.AuditReasonCode,
(select up1.last_name + ', ' + up1.first_name from user_profile as up1 where up1.user_profile_id = s.approved_by_user_profile_id) Auditor1, 
(select up2.last_name + ', ' + up2.first_name from user_profile as up2 where up2.user_profile_id = s.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID) Auditor2, 
(select up3.last_name + ', ' + up3.first_name from user_profile as up3 where up3.user_profile_id = s.POST_BILL_AUDIT_COMPLETED_BY_USER_ID) AuditorPost,

sum( isnull(s.FacilityProc_UnitOpp,0) + isnull(s.InfusionInjection_UnitOpp,0) + isnull(s.ProfProc_UnitOpp,0) ) as UnitOpportunities, 
sum( isnull(s.FacilityProc_UnitRev,0) + isnull(s.InfusionInjection_UnitRev,0) + isnull(s.ProfProc_UnitRev,0) ) as UnitRevisions,

sum( isnull(s.FacilityProc_UnitOpp_Post,0) + isnull(s.InfusionInjection_UnitOpp_Post,0) + isnull(s.ProfProc_UnitOpp_Post,0) ) as UnitOpportunities_Post,
sum( isnull(s.FacilityProc_UnitRev_Post,0) + isnull(s.InfusionInjection_UnitRev_Post,0) + isnull(s.ProfProc_UnitRev_Post,0) ) as UnitRevisions_Post,

sum( isnull(s.FacilityProc_ModOpp,0) + isnull(s.InfusionInjection_ModOpp,0) + isnull(s.ProfProc_ModOpp,0) + isnull(s.FacilityLOS_ModOpp,0) + isnull(s.PhysicianLOS_ModOpp,0) ) as ModifierOpportunities,
sum( isnull(s.FacilityProc_ModRev,0) + isnull(s.InfusionInjection_ModRev,0) + isnull(s.ProfProc_ModRev,0) + isnull(s.FacilityLOS_ModRev,0) + isnull(s.PhysicianLOS_ModRev,0) ) as ModifierRevisions,

sum( isnull(s.FacilityProc_ModOpp_Post,0) + isnull(s.InfusionInjection_ModOpp_Post,0) + isnull(s.ProfProc_ModOpp_Post,0) + isnull(s.FacilityLOS_ModOpp_Post,0) + isnull(s.PhysicianLOS_ModOpp_Post,0) ) as ModifierOpportunities_Post,
sum( isnull(s.FacilityProc_ModRev_Post,0) + isnull(s.InfusionInjection_ModRev_Post,0) + isnull(s.ProfProc_ModRev_Post,0) + isnull(s.FacilityLOS_ModRev_Post,0) + isnull(s.PhysicianLOS_ModRev_Post,0) ) as ModifierRevisions_Post

into #Scorecard_2
from #Scorecard_1 s

-- where 

group by 
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, s.facility_chart_id, s.APPROVED_DATE, s.USER_PROFILE_ID,  
s.CoderName, s.AuditReasonCode,
s.approved_by_user_profile_id, s.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID, s.POST_BILL_AUDIT_COMPLETED_BY_USER_ID



-- Testing 
/*

-- Units
select
s.FacilityProc_UnitOpp, s.InfusionInjection_UnitOpp, s.ProfProc_UnitOpp,
s.FacilityProc_UnitRev, s.InfusionInjection_UnitRev, s.ProfProc_UnitRev, 

s.FacilityProc_UnitOpp_Post, s.InfusionInjection_UnitOpp_Post, s.ProfProc_UnitOpp_Post,
s.FacilityProc_UnitRev_Post, s.InfusionInjection_UnitRev_Post, s.ProfProc_UnitRev_Post
from #Scorecard_1 s
where chart_id = 121161496 

120093908     
121161496 

120093908     

116219538 --115998893



-- Mods 
select
s.FacilityProc_ModOpp, s.InfusionInjection_ModOpp, s.ProfProc_ModOpp, s.PhysicianLOS_ModOpp, s.FacilityLOS_ModOpp,
s.FacilityProc_ModRev, s.InfusionInjection_ModRev, s.ProfProc_ModRev, s.PhysicianLOS_ModRev, s.FacilityLOS_ModRev,

s.FacilityProc_ModOpp_Post, s.InfusionInjection_ModOpp_Post, s.ProfProc_ModOpp_Post, s.PhysicianLOS_ModOpp_Post, s.FacilityLOS_ModOpp_Post,
s.FacilityProc_ModRev_Post, s.InfusionInjection_ModRev_Post, s.ProfProc_ModRev_Post, s.PhysicianLOS_ModRev_Post, isnull(s.FacilityLOS_ModRev_Post, 0) as FacilityLOS_ModRev_Post
from #Scorecard_1 s
where chart_id =  121161496 

120093908  
121161496 


*/
-- *****************************************************************************************************************************************
-- Output

select 
 s.ServiceAgreementDescription
,s.SERVICE_AGREEMENT_ID
,s.CHART_ID
,s.FACILITY_CHART_ID
,s.APPROVED_DATE
,s.CoderName
,s.HiddenName
,s.AuditReasonCode
,s.Auditor1
,s.Auditor2
,s.AuditorPost
,case when s.UnitOpportunities_Post > 0 then s.UnitOpportunities_Post else s.UnitOpportunities end as UnitOpportunities
,case when s.UnitRevisions_Post > 0 then s.UnitRevisions_Post else s.UnitRevisions end as UnitRevisions

,case when s.ModifierOpportunities_Post > 0 then s.ModifierOpportunities_Post else s.ModifierOpportunities end as ModifierOpportunities
,case when s.ModifierRevisions_Post > 0 then s.ModifierRevisions_Post else s.ModifierRevisions end as ModifierRevisions,

(select description from ChartPostBillAuditReasonTypeCode where ChartPostBillAuditReasonTypeCode = s.AuditReasonCode) as AuditReason,

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






(select 
case 
when DxService = 'N' then '-' 
when DxService = 'Y' and DxAttempted = 0 and DxAttempted_Post = 0 then '-' 

when (DxService = 'Y' and DxAttempted_Post > 0 and DxActions_Post > 0)  then 
     coalesce(DxAdditionPostError +';', '') + coalesce(DxRevisionPostError +';', '') 
   + coalesce(DxDeletionPostError +';', '') + coalesce(DxAbstractPostError +';', '')

when (DxService = 'Y' and DxActions > 0 and DxActions_Post = 0) then
     coalesce(DxAdditionError +';', '') + coalesce(DxRevisionError +';', '') 
   + coalesce(DxDeletionError +';', '') + coalesce(DxAbstractError +';', '')

when (DxService = 'Y' and DxActions = 0 and DxAttempted > 0 
     OR DxActions_Post = 0 and DxAttempted_Post > 0 ) then 'Correct' 

end
from #AuditGrid1
where chart_id = s.chart_id ) as DxError, 




( select case 
when ObsHoursService = 'N' then '-' 
when ObsHoursService = 'Y' and ObsHoursAttempted = 0 and ObsHoursAttempted_Post = 0 then '-'  


when (ObsHoursService = 'Y' and ObsHoursAttempted_Post > 0 and ObsHoursActions_Post > 0) then 
     coalesce(ObsHoursAdditionPostError +';', '') + coalesce(ObsHoursRevisionPostError +';', '') 
   + coalesce(ObsHoursDeletionPostError +';', '') + coalesce(ObsHoursAbstractPostError +';', '')

when (ObsHoursService = 'Y' and ObsHoursActions > 0 and ObsHoursActions_Post = 0) then
     coalesce(ObsHoursAdditionError +';', '') + coalesce(ObsHoursRevisionError +';', '') 
   + coalesce(ObsHoursDeletionError +';', '') + coalesce(ObsHoursAbstractError +';', '')

when  (ObsHoursService = 'Y' and ObsHoursActions = 0 and ObsHoursAttempted > 0 
		OR ObsHoursActions_Post = 0 and ObsHoursAttempted_Post > 0)  then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as ObsHoursError,



( select case 
when AnesthesiaService = 'N' then '-' 
when AnesthesiaService = 'Y' and AnesthesiaAttempted = 0 and AnesthesiaAttempted_Post = 0 then '-'  


when (AnesthesiaService = 'Y' and AnesthesiaAttempted_Post > 0 and AnesthesiaActions_Post > 0) then 
     coalesce(AnesthesiaAdditionPostError +';', '') + coalesce(AnesthesiaRevisionPostError +';', '') 
   + coalesce(AnesthesiaDeletionPostError +';', '') + coalesce(AnesthesiaAbstractPostError +';', '')

when (AnesthesiaService = 'Y' and AnesthesiaActions > 0 and AnesthesiaActions_Post = 0) then
     coalesce(AnesthesiaAdditionError +';', '') + coalesce(AnesthesiaRevisionError +';', '') 
   + coalesce(AnesthesiaDeletionError +';', '') + coalesce(AnesthesiaAbstractError +';', '')

when  (AnesthesiaService = 'Y' and AnesthesiaActions = 0 and AnesthesiaAttempted > 0 
		OR AnesthesiaActions_Post = 0 and AnesthesiaAttempted_Post > 0)  then 'Correct' 

end 
from #AuditGrid1
where chart_id = s.chart_id ) as AnesthesiaError,




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


from

#Scorecard_2 s

 END



   END






GO
