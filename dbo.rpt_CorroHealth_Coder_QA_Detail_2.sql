SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[rpt_CorroHealth_Coder_QA_Detail_2] 
	@ReportUser INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@UserGroup VARCHAR(MAX),
	@CUID VARCHAR(MAX),
	@Company VARCHAR(MAX),
	@FACILITY_ID VARCHAR(MAX)


/*
	declare
		 @ReportUser   int          = 11473				
		,@StartDate   datetime     = '10/1/2021'		
		,@EndDate     datetime     = '10/16/2021'		
		,@UserGroup VARCHAR(MAX) = '-2'
		,@CUID        varchar(max) = '-1'
		,@Company	  varchar(max) = '-1'				
		,@FACILITY_ID varchar(max) = '-1'
		;
*/

AS
BEGIN

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
	DECLARE @m_CUID VARCHAR(MAX) = @CUID
	DECLARE @m_Company VARCHAR(MAX) = @Company
	DECLARE @m_UserGroup VARCHAR(MAX) = @UserGroup;



if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
if object_id('TempDB..#CodedCharts', 'U') is not null drop table #CodedCharts;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#Scorecard_2', 'U') is not null drop table #Scorecard_2;
if object_id('TempDB..#AuditGrid1', 'U') is not null drop table #AuditGrid1;
if object_id('TempDB..#AuditNotes1', 'U') is not null drop table #AuditNotes1;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;

-- added to support tuning by dsexton 2/2022 (reduces logical reads and duration by 70-95% depending on parameters used)
if object_id('TempDB..#TempChartQAS_PAA', 'U') is not null drop table #TempChartQAS_PAA;
if object_id('TempDB..#TempChartQAS_FLAA', 'U') is not null drop table #TempChartQAS_FLAA;
if object_id('TempDB..#TempChartQAS_PLAA', 'U') is not null drop table #TempChartQAS_PLAA;

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
		and (sa.company_id in (SELECT * FROM SPLITSTRING(@m_Company, ','))
	    OR	-1 in (SELECT * FROM SPLITSTRING(@m_Company, ',')) )
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		) fa;


-- *****************************************************************************************************************************************
-- Coders/Usergroup


if object_id('TempDB..#coder', 'U') is not null drop table #coder


select distinct t1.USER_PROFILE_ID 
into #coder				
from  				
		(
		SELECT USER_PROFILE_ID 
		FROM USER_PROFILE				
		WHERE  USER_PROFILE_ID <> 2
		and password_last_changed_date > convert(date, DATEADD(month, -9, GETDATE()))
		and (USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') )
			OR -1 in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') ) )
		and (
		(USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') )
			OR -1 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) )
        OR ( -2 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) 
			and USER_GROUP_ID in (201,202,203,208,212) )
		)
			
		UNION				
				
		SELECT up.USER_PROFILE_ID 
		FROM USER_GROUP_TO_USER_PROFILE ugup,				
		user_profile up				
		where up.user_profile_id = ugup.user_profile_id
		and UP.USER_PROFILE_ID <> 2
		and up.password_last_changed_date > convert(date, DATEADD(month, -9, GETDATE())) 				
		and (ugup.USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') )
			OR -1 in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') ) )
		and (
		(ugup.USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') )		
		    OR -1 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) )
        OR ( -2 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) 
			and ugup.USER_GROUP_ID in (201,202,203,208,212) )
			)
		) t1


create nonclustered index idx_USER_PROFILE_ID on #coder (USER_PROFILE_ID);



-- *****************************************************************************************************************************************


SELECT	c.chart_id, c.service_agreement_id, c.facility_chart_id, c.APPROVED_DATE, c.completed_by_user_profile_id, c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID,

FACILITY_SERVICE_LEVEL_AUDIT_COMMENT, FACILITY_PROCEDURES_AUDIT_COMMENT, PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT, PHYSICIAN_PROCEDURES_AUDIT_COMMENT,
DIAGNOSIS_CODING_AUDIT_COMMENT, INFUSION_INJECTION_AUDIT_COMMENT, AUDITOR_REVIEW_FEEDBACK, OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT,
OBSERVATION_PROCEDURES_AUDIT_COMMENT, OBSERVATION_AUDITOR_REVIEW_FEEDBACK, DEMOGRAPHIC_AUDIT_COMMENT, ANESTHESIA_CODING_AUDIT_COMMENT,
SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT,SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT,SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT,
SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT,SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT,SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT,
SECOND_LEVEL_QA_AUDITOR_REVIEW_FEEDBACK,SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT,SECOND_LEVEL_QA_OBSERVATION_FACILITY_PROCEDURE_AUDIT_COMMENT,
SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK,SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT,SECOND_LEVEL_QA_ANESTHESIA_CODING_AUDIT_COMMENT



INTO	[#ChartSubset]
FROM	chart as c 
LEFT OUTER JOIN CHART_SECOND_LEVEL_AUDIT_COMMENTS sl ON c.CHART_ID = sl.CHART_ID  
WHERE	c.CHART_STATUS_ID in (4, 5)
AND c.COMPLETED_BY_USER_PROFILE_ID  in ( select USER_PROFILE_ID from #coder)
AND     c.APPROVAL_REASON_CODE = 3
AND     c.APPROVED_BY_USER_PROFILE_ID <> 2	
AND 	c.START_QA_DATE is not null
AND		convert(varchar, c.APPROVED_DATE, 112) BETWEEN convert(varchar, @m_StartDate, 112) AND convert(varchar, @m_EndDate, 112)
AND	    c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
;

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

	/*	-- Commented out by dsexton, 2/2022.  There's no reason to do RBAR processing here which is very inefficient.
	declare @chart int

	while exists (select * from #combined where Split = 0)
	begin
		
		set @chart = (select top 1 CHART_ID from #combined where Split = 0)
	*/

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

		/*		-- commented out by dsexton, 2/2022.
		where
			c.CHART_ID = @chart
		*/

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

		/*		-- commented out by dsexton, 2/2022.
		where
			c.CHART_ID = @chart

		update #combined
		set Split = 1
		where CHART_ID = @chart

	end
		*/


-- *****************************************************************************************************************************************


-- changes to support tuning by dsexton, 2/2022 -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, PROCEDURE_TYPE, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE, CODER_CHARGE_MASTER_DEPT_ID, AUDITOR_CHARGE_MASTER_DEPT_ID
  into #TempChartQAS_PAA
from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
  into #TempChartQAS_FLAA
from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
  into #TempChartQAS_PLAA
from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- All subqueries below were modified to reference the new temp tables (above) which contain small subsets of data from the base tables.  dsexton, 2/2022
SELECT		c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, c.APPROVED_DATE, up.USER_PROFILE_ID,  up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND (pr.IS_CODER_CORRECT = 1 OR pr.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR flos.EXCLUDE_FROM_QA_REPORT = 1))  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 or PLOS.EXCLUDE_FROM_QA_REPORT = 1)) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 ) 
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,

			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount,

			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxAttempted,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAbstract,

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
			
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect ,-- PA
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted, 	
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,

			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,	
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,
			
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted, 
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges, 
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_FLAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,  																															 
			(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PLAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,
			

			-- Bypass this call to function dbo.GetChartDemographicAuditActions since it is expensive and not needed. DemographicChanges is not subsequently referred to.  dsexton, 2/2022
			--(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges,

			case when sa.EVALUATE_FACILITY_SVC = 1 then 'Y' else 'N' end as FacilityLOSService,
			case when (sa.INFUSION_INJECTION_METHOD_ID = 1 or sa.INFUSION_INJECTION_METHOD_ID = 2) then 'Y' else 'N' end as InfusionInjectionService,
			case when sa.EVALUATE_FACILITY_PROCEDURES = 1 then 'Y' else 'N' end as FacilityProcService,
			case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 'Y' else 'N' end as PhysicianLOSService,
			case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 'Y' else 'N' end as ProfProcService,
			case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 'Y' else 'N' end as DxService,
 			case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 and c.PATIENT_DISPOSITION_ID = 5 then 'Y' else 'N' end as ObsHoursService,
			
			(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSActions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionActions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcActions,
			(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSActions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcActions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxActions,
			(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursActions 							 
			

into #Scorecard_1
			FROM	[#ChartSubset] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID    
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
			WHERE		c.approved_by_user_profile_id > 2		                   




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


InfusionInjectionService,
InfusionInjectionAttempted,
InfusionInjectionActions, 
case when s.InfusionInjectionAdditions > 0 then cast(s.InfusionInjectionAdditions as varchar(5)) + ' Additions'end as InfusionInjectionAdditionError,
case when s.InfusionInjectionRevisions > 0 then cast(s.InfusionInjectionRevisions as varchar(5)) + ' Revisions'end as InfusionInjectionRevisionError,
case when s.InfusionInjectionDeletions > 0 then cast(s.InfusionInjectionDeletions as varchar(5)) + ' Deletions'end as InfusionInjectionDeletionError,
case when s.InfusionInjectionAbstract > 0 then cast(s.InfusionInjectionAbstract as varchar(5)) + ' Abstract'end as InfusionInjectionAbstractError,


FacilityProcService,
FacilityProcAttempted,
FacilityProcActions,
case when s.FacilityProcAdditions > 0 then cast(s.FacilityProcAdditions as varchar(5)) + ' Additions'end as FacilityProcAdditionError,
case when s.FacilityProcRevisions > 0 then cast(s.FacilityProcRevisions as varchar(5)) + ' Revisions'end as FacilityProcRevisionError,
case when s.FacilityProcDeletions > 0 then cast(s.FacilityProcDeletions as varchar(5)) + ' Deletions'end as FacilityProcDeletionError,
case when s.FacilityProcAbstract > 0 then cast(s.FacilityProcAbstract as varchar(5)) + ' Abstract'end as FacilityProcAbstractError,


PhysicianLOSService,
PhysicianLOSAttempted, 
PhysicianLOSActions,
case when s.PhysicianLOSAdditions > 0 then cast(s.PhysicianLOSAdditions as varchar(5)) + ' Additions'end as PhysicianLOSAdditionError,
case when s.PhysicianLOSRevisions > 0 then cast(s.PhysicianLOSRevisions as varchar(5)) + ' Revisions'end as PhysicianLOSRevisionError,
case when s.PhysicianLOSDeletions > 0 then cast(s.PhysicianLOSDeletions as varchar(5)) + ' Deletions'end as PhysicianLOSDeletionError,
case when s.PhysicianLOSAbstract > 0 then cast(s.PhysicianLOSAbstract as varchar(5)) + ' Abstract'end as PhysicianLOSAbstractError,


ProfProcService,
ProfProcAttempted, 
ProfProcActions,
case when s.ProfProcAdditions > 0 then cast(s.ProfProcAdditions as varchar(5)) + ' Additions'end as ProfProcAdditionError,
case when s.ProfProcRevisions > 0 then cast(s.ProfProcRevisions as varchar(5)) + ' Revisions'end as ProfProcRevisionError,
case when s.ProfProcDeletions > 0 then cast(s.ProfProcDeletions as varchar(5)) + ' Deletions'end as ProfProcDeletionError,
case when s.ProfProcAbstract > 0 then cast(s.ProfProcAbstract as varchar(5)) + ' Abstract'end as ProfProcAbstractError,


DxService,
DxAttempted,
DxActions,
case when s.DxAdditions > 0 then cast(s.DxAdditions as varchar(5)) + ' Additions'end as DxAdditionError,
case when s.DxRevisions > 0 then cast(s.DxRevisions as varchar(5)) + ' Revisions'end as DxRevisionError,
case when s.DxDeletions > 0 then cast(s.DxDeletions as varchar(5)) + ' Deletions'end as DxDeletionError,
case when s.DxAbstract > 0 then cast(s.DxAbstract as varchar(5)) + ' Abstract'end as DxAbstractError,


ObsHoursService,
ObsHoursAttempted,
ObsHoursActions,
case when s.ObsHoursAdditions > 0 then cast(s.ObsHoursAdditions as varchar(5)) + ' Additions'end as ObsHoursAdditionError,
case when s.ObsHoursRevisions > 0 then cast(s.ObsHoursRevisions as varchar(5)) + ' Revisions'end as ObsHoursRevisionError,
case when s.ObsHoursDeletions > 0 then cast(s.ObsHoursDeletions as varchar(5)) + ' Deletions'end as ObsHoursDeletionError,
case when s.ObsHoursAbstract > 0 then cast(s.ObsHoursAbstract as varchar(5)) + ' Abstract'end as ObsHoursAbstractError

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




-- *****************************************************************************************************************************************
--calculations

select 
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, s.facility_chart_id, s.APPROVED_DATE, s.USER_PROFILE_ID,  s.CoderName


into #Scorecard_2
from #Scorecard_1 s
group by 
s.service_agreement_id, s.ServiceAgreementDescription, s.chart_id, s.facility_chart_id, s.APPROVED_DATE, s.USER_PROFILE_ID,  s.CoderName,
s.user_profile_id, s.CoderName


-- *****************************************************************************************************************************************
-- Output


-- indexes added by dsexton, 2/2022.  Reduces logical reads for this section by 85% (eg 1M vs 7M).
create unique clustered index ix_CLU_UNQ on #AuditGrid1 (chart_ID) 
create unique clustered index ix_CLU_UNQ2 on #Scorecard_2 (chart_ID) 


select 
*,
(select 
case 
when FacilityLOSService = 'N' then '-' 
when FacilityLOSService = 'Y' and FacilityLOSAttempted = 0 then '-' 
when FacilityLOSService = 'Y' and FacilityLOSActions = 0 and FacilityLOSAttempted > 0 then 'Correct' 
when FacilityLOSService = 'Y' and FacilityLOSActions <> 0 then 
coalesce(FacilityLOSAdditionError +';', '') + coalesce(FacilityLOSRevisionError +';', '') 
   + coalesce(FacilityLOSDeletionError +';', '') + coalesce(FacilityLOSAbstractError +';', '')
end
from #AuditGrid1
where chart_id = s.chart_id ) as FacilityLOSError, 


( select case 
when InfusionInjectionService = 'N' then '-' 
when InfusionInjectionService = 'Y' and InfusionInjectionAttempted = 0 then '-' 
when InfusionInjectionService = 'Y' and InfusionInjectionActions = 0 and InfusionInjectionAttempted > 0 then 'Correct' 
when InfusionInjectionService = 'Y' and InfusionInjectionActions <> 0 then 
coalesce(InfusionInjectionAdditionError +';', '') + coalesce(InfusionInjectionRevisionError +';', '') 
  + coalesce(InfusionInjectionDeletionError +';', '') + coalesce(InfusionInjectionAbstractError +';', '')
end 
from #AuditGrid1
where chart_id = s.chart_id ) as InfusionInjectionError,


( select case 
when FacilityProcService = 'N' then '-' 
when FacilityProcService = 'Y' and FacilityProcAttempted = 0 then '-' 
when FacilityProcService = 'Y' and FacilityProcActions = 0 and FacilityProcAttempted > 0 then 'Correct' 
when FacilityProcService = 'Y' and FacilityProcActions <> 0 then 
coalesce(FacilityProcAdditionError +';', '') + coalesce(FacilityProcRevisionError +';', '') 
  + coalesce(FacilityProcDeletionError +';', '') + coalesce(FacilityProcAbstractError +';', '')
end 
from #AuditGrid1
where chart_id = s.chart_id ) as FacilityProcError,


( select case 
when PhysicianLOSService = 'N' then '-' 
when PhysicianLOSService = 'Y' and PhysicianLOSAttempted = 0 then '-' 
when PhysicianLOSService = 'Y' and PhysicianLOSActions = 0 and PhysicianLOSAttempted > 0 then 'Correct' 
when PhysicianLOSService = 'Y' and PhysicianLOSActions <> 0 then 
coalesce(PhysicianLOSAdditionError +';', '') + coalesce(PhysicianLOSRevisionError +';', '') 
  + coalesce(PhysicianLOSDeletionError +';', '') + coalesce(PhysicianLOSAbstractError +';', '')
end 
from #AuditGrid1
where chart_id = s.chart_id )as PhysicianLOSError,




( select case 
when ProfProcService = 'N' then '-' 
when ProfProcService = 'Y' and ProfProcAttempted = 0 then '-' 
when ProfProcService = 'Y' and ProfProcActions = 0 and ProfProcAttempted > 0 then 'Correct' 
when ProfProcService = 'Y' and ProfProcActions <> 0 then 
coalesce(ProfProcAdditionError +';', '') + coalesce(ProfProcRevisionError +';', '') 
  + coalesce(ProfProcDeletionError +';', '') + coalesce(ProfProcAbstractError +';', '')
end 
from #AuditGrid1
where chart_id = s.chart_id ) as ProfProcError,




( select case 
when DxService = 'N' then '-' 
when DxService = 'Y' and DxAttempted = 0 then '-' 
when DxService = 'Y' and DxActions = 0 and DxAttempted > 0 then 'Correct' 
when DxService = 'Y' and DxActions <> 0 then 
coalesce(DxAdditionError +';', '') + coalesce(DxRevisionError +';', '') 
  + coalesce(DxDeletionError +';', '') + coalesce(DxAbstractError +';', '')
end 
from #AuditGrid1
where chart_id = s.chart_id ) as DxError,


( select case 
when ObsHoursService = 'N' then '-' 
when ObsHoursService = 'Y' and ObsHoursAttempted = 0 then '-' 
when ObsHoursService = 'Y' and ObsHoursActions = 0 and ObsHoursAttempted > 0 then 'Correct' 
when ObsHoursService = 'Y' and ObsHoursActions <> 0 then 
coalesce(ObsHoursAdditionError +';', '') + coalesce(ObsHoursRevisionError +';', '') 
  + coalesce(ObsHoursDeletionError +';', '') + coalesce(ObsHoursAbstractError +';', '')
end from #AuditGrid1
where chart_id = s.chart_id )as ObsHoursError,


(select 

coalesce(Demo, '') + coalesce(PhyService, '') + coalesce(FacService, '') + coalesce(FacProc, '') +
coalesce(PhyProc, '') + coalesce(Diagnosis, '') + coalesce(InfInj, '') + coalesce(General, '') +
coalesce(Anesthesia, '') + coalesce(Obs, '') as AuditNotes
from #AuditNotes1
where chart_id = s.chart_id ) as AuditNotes

from

#Scorecard_2 s

END               

GO
GRANT EXECUTE ON  [dbo].[rpt_CorroHealth_Coder_QA_Detail_2] TO [dbx_ExecuteReportProcs]
GO
