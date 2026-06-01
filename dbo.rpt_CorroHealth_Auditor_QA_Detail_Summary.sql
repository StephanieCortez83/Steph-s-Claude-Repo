SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


















CREATE PROCEDURE [dbo].[rpt_CorroHealth_Auditor_QA_Detail_Summary]  
	@ReportUser INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@CUID INT,
	@FACILITY_ID VARCHAR(MAX)

AS
BEGIN

/*
-- testing parameters ****
declare 
 @CUID int = 10501,	            --Adla Akhila
 @StartDate date = '03/18/2021',
 @EndDate date = '03/18/2021',
 @FACILITY_ID VARCHAR(MAX) = '-1',
 @ReportUser INT = 80
 ;
*/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


    DECLARE @m_ReportUser INT
	DECLARE @m_StartDate DATETIME
	DECLARE @m_EndDate DATETIME
	DECLARE @m_FACILITY_ID VARCHAR(MAX)
	Set @m_ReportUser = @ReportUser
	Set @m_StartDate = @StartDate
	Set @m_EndDate = @EndDate
	Set @m_FACILITY_ID = @FACILITY_ID
	DECLARE @m_CUID INT = @CUID;


if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
if object_id('TempDB..#ApprovedCharts1', 'U') is not null drop table #ApprovedCharts1;
if object_id('TempDB..#ApprovedCharts', 'U') is not null drop table #ApprovedCharts;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;

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
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		) fa;

-- *****************************************************************************************************************************************

-- Approved Charts   


SELECT	
c.chart_id, c.service_agreement_id, c.facility_chart_id, 
c.APPROVED_DATE, c.completed_by_user_profile_id, 
c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID,
c.CHART_STATUS_ID,
c.APPROVAL_REASON_CODE, START_QA_DATE

INTO	[#ApprovedCharts1]
FROM	chart as c  with (NOLOCK)
WHERE	
c.CHART_STATUS_ID in (4, 5) -- Approved, Sent
AND c.APPROVED_BY_USER_PROFILE_ID = @m_CUID
AND	convert(varchar, c.APPROVED_DATE, 112) BETWEEN convert(varchar, @m_StartDate, 112) AND convert(varchar, @m_EndDate, 112)
AND	c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
; 


-- select * from #ApprovedCharts1



SELECT	
c.APPROVED_BY_USER_PROFILE_ID,
count(*) as ApprovedNumber
INTO	[#ApprovedCharts]
FROM	#ApprovedCharts1 c
where c.START_QA_DATE is not null
group by c.APPROVED_BY_USER_PROFILE_ID

-- select * from #ApprovedCharts


-- *****************************************************************************************************************************************



SELECT	c.chart_id, c.service_agreement_id, c.facility_chart_id, c.APPROVED_DATE, c.completed_by_user_profile_id, c.approved_by_user_profile_id
INTO	[#ChartSubset]
FROM	chart as c with (NOLOCK)
WHERE	c.CHART_STATUS_ID in (4, 5)
AND		c.APPROVED_BY_USER_PROFILE_ID = @m_CUID
AND     c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 2	
AND		convert(varchar, c.SECOND_LEVEL_QA_APPROVED_DATETIME, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)
AND	c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
AND c.START_SECOND_LEVEL_QA_DATETIME is not null
AND c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2 
;


-- *****************************************************************************************************************************************

-- Correction to Split Dx Types


select 
		
		dx.CHART_ID
		,dx.FACILITY_CHART_ID
		,dx.ACTION
		,dx.FIRST_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		,case when dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION = 'Primary Dx' and dx.SECOND_AUDITOR_ICD10_CODE <> '' then
				case when icd.DIAGNOSIS_TYPE_ID = 1 and icd.IS_PRIMARY = 1 then 'Chief Complaint'
						when icd.DIAGNOSIS_TYPE_ID = 1 and icd.IS_PRIMARY = 0 then 'Additional Complaint'
						when icd.DIAGNOSIS_TYPE_ID = 2 and icd.IS_PRIMARY = 1 then 'Primary Dx'
						when icd.DIAGNOSIS_TYPE_ID = 2 and icd.IS_PRIMARY = 0 then 'Secondary Dx'
						when icd.DIAGNOSIS_TYPE_ID = 3 and icd.IS_PRIMARY = 1 then 'Chief Complaint and Primary Dx'
						when icd.DIAGNOSIS_TYPE_ID = 5 and icd.IS_PRIMARY = 0 then 'Chief Complaint and Secondary Dx'
					else '' end
				else dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION end SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		
		,dx.IS_CHIEF_COMPLAINT_CHANGE
		,dx.IS_PRIMARY_DIAGNOSIS_CHANGE
		
		,dx.FIRST_AUDITOR_ICD10_CODE
		,dx.SECOND_AUDITOR_ICD10_CODE
		,dx.EXCLUDE_FROM_QA_REPORT
		,IS_FIRST_AUDITOR_CORRECT
	into #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION
	from
		#ChartSubset c		           
		inner join CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
		left join CHART_DIAGNOSIS_CODE_ICD10 icd on dx.CHART_ID = icd.CHART_ID and dx.SECOND_AUDITOR_ICD10_CODE = icd.ICD10_CODE
	where
		dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION not like '%and%'




select 
		dx.CHART_ID
		,dx.FACILITY_CHART_ID
		,dx.[ACTION]
		,dx.FIRST_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		,dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		,substring(dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION,0,charindex(' and ',dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)) [FIRST_DT_DESC]
		,substring(dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION,charindex(' and ',dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)+5,len(dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)) [SECOND_DT_DESC]
		,dx.IS_CHIEF_COMPLAINT_CHANGE
		,dx.IS_PRIMARY_DIAGNOSIS_CHANGE
		,dx.FIRST_AUDITOR_ICD10_CODE
		,dx.SECOND_AUDITOR_ICD10_CODE
		,dx.EXCLUDE_FROM_QA_REPORT
		,IS_FIRST_AUDITOR_CORRECT
		,0 as [Split]
	into #combined
	from
		#ChartSubset c
		inner join dbo.CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
	where
		dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION like '%and%'




	declare @chart int

	while exists (select * from #combined where Split = 0) 
	begin
		
		set @chart = (select top 1 CHART_ID from #combined where Split = 0)



		insert into #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION
		select 
			c.CHART_ID
		   ,c.FACILITY_CHART_ID
		   ,c.ACTION
		   ,c.FIRST_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		   ,c.FIRST_DT_DESC
		 
           ,case when c.ACTION = 'A' then 0 
					when c.FIRST_DT_DESC like '%Chief%' and c.IS_CHIEF_COMPLAINT_CHANGE = 1 then 1 
				else 0 end IS_CHIEF_COMPLAINT_CHANGE

		   ,case when c.ACTION = 'A' then 0 
					when c.FIRST_DT_DESC like '%Primary%' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 then 1 
				else 0 end IS_PRIMARY_DIAGNOSIS_CHANGE

		   


		   ,c.FIRST_AUDITOR_ICD10_CODE
		   ,c.SECOND_AUDITOR_ICD10_CODE
		   ,c.EXCLUDE_FROM_QA_REPORT		   
		   ,case when c.EXCLUDE_FROM_QA_REPORT = 1 then 1 else IS_FIRST_AUDITOR_CORRECT end IS_FIRST_AUDITOR_CORRECT
		from
			#combined c
		where
			c.CHART_ID = @chart

		union all

		select 
			c.CHART_ID
		   ,c.FACILITY_CHART_ID
		   ,c.ACTION
		   ,c.FIRST_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
		   ,c.SECOND_DT_DESC		  

			,case when c.ACTION = 'A' then 0 
					when c.SECOND_DT_DESC like '%Chief%' and c.IS_CHIEF_COMPLAINT_CHANGE = 1 then 1 
				else 0 end IS_CHIEF_COMPLAINT_CHANGE

		   ,case when c.ACTION = 'A' then 0 
					when c.SECOND_DT_DESC like '%Primary%' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 then 1 
				else 0 end IS_PRIMARY_DIAGNOSIS_CHANGE
		   

		   ,c.FIRST_AUDITOR_ICD10_CODE
		   ,c.SECOND_AUDITOR_ICD10_CODE
		   ,c.EXCLUDE_FROM_QA_REPORT		   
		   ,case when c.EXCLUDE_FROM_QA_REPORT = 1 then 1 else IS_FIRST_AUDITOR_CORRECT end IS_FIRST_AUDITOR_CORRECT

		from
			#combined c
		where
			c.CHART_ID = @chart

		
		update #combined
		set Split = 1
		where CHART_ID = @chart


	end


-- *****************************************************************************************************************************************


SELECT		
c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, c.APPROVED_DATE, 
up.USER_PROFILE_ID,  up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND (pr.IS_FIRST_AUDITOR_CORRECT = 1 or pr.EXCLUDE_FROM_QA_REPORT = 1))
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_FIRST_AUDITOR_CORRECT = 1 or flos.EXCLUDE_FROM_QA_REPORT = 1))  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_FIRST_AUDITOR_CORRECT = 1or plos.EXCLUDE_FROM_QA_REPORT = 1)) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_FIRST_AUDITOR_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION_VS_FIRST_AUDITOR = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION_VS_FIRST_AUDITOR = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 ) 
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION_VS_FIRST_AUDITOR = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'D' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'D' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_FIRST_AUDITOR_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxAttempted,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
--			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAbstract,
			 (select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
				    AND dx.chart_id not in (select chart_id from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx2 WHERE dx2.CHART_ID = dx.CHART_ID AND dx2.ACTION in ('D','R','A') AND dx2.EXCLUDE_FROM_QA_REPORT <> 1 )	) as DxAbstract,
			                     
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_FIRST_AUDITOR_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION_VS_FIRST_AUDITOR = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION_VS_FIRST_AUDITOR = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION_VS_FIRST_AUDITOR = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION_VS_FIRST_AUDITOR = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_FIRST_AUDITOR_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION_VS_FIRST_AUDITOR = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION_VS_FIRST_AUDITOR = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION_VS_FIRST_AUDITOR = 'D AND EXCLUDE_FROM_QA_REPORT <> 1') as InfusionInjectionDeletions,
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION_VS_FIRST_AUDITOR = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAbstract,
            (select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION_VS_FIRST_AUDITOR = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
									AND pr.chart_id not in (select chart_id from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr2 WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'CI' AND pr2.ACTION_VS_FIRST_AUDITOR in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as InfusionInjectionAbstract,

			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_FIRST_AUDITOR_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION_VS_FIRST_AUDITOR = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION_VS_FIRST_AUDITOR = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION_VS_FIRST_AUDITOR = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION_VS_FIRST_AUDITOR = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract, 		
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_FIRST_AUDITOR_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION_VS_FIRST_AUDITOR = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION_VS_FIRST_AUDITOR = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION_VS_FIRST_AUDITOR = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions, 							 
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION_VS_FIRST_AUDITOR = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAbstract, 
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION_VS_FIRST_AUDITOR = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
                    AND pr.chart_id not in (select chart_id from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr2 WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'OB' AND pr2.ACTION_VS_FIRST_AUDITOR in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as ObsHoursAbstract, 
														 
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_FIRST_AUDITOR_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted, 
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,									 					
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_FIRST_AUDITOR_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as PhysicianLOSCorrect,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted, 	
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,	
			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,	
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_FIRST_AUDITOR_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_FIRST_AUDITOR_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted, 
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and FIRST_AUDITOR_MODIFIER <> SECOND_AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges, 
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_FACILITY_LOS_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and FIRST_AUDITOR_MODIFIER <> SECOND_AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,  																															 
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PHYSICIAN_LOS_SECOND_LEVEL_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and FIRST_AUDITOR_MODIFIER <> SECOND_AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,
			(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicSecondLevelAuditActions(c.CHART_ID)) as DemographicChanges
  into #Scorecard_1			
			FROM	[#ChartSubset] c with (NOLOCK)
					LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.approved_by_user_profile_id = up.USER_PROFILE_ID    
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   	                   


--select * from [#ChartSubset]
--select * from #ApprovedCharts
-- *****************************************************************************************************************************************



select 
t1.user_profile_id,
sum(t1.AccurateCount) as AccurateCount,
sum(t1.RevisedCount) as RevisedCount,
sum(t1.AddedCount) as AddedCount,
sum(t1.DeletedCount) as DeletedCount,
sum(t1.CoderAccuracy) as CoderAccuracy,
sum(t1.ChartsApproved) as ChartsApproved,
sum(t1.ChartsReviewed) as ChartsReviewed,
sum(t1.PercentReviewed) as PercentReviewed,
sum(t1.Diagnosis) as Diagnosis,
sum(t1.Diagnosis_D) as Diagnosis_D,
sum(t1.FacilityProc) as FacilityProc,
sum(t1.FacilityProc_D) as FacilityProc_D,
sum(t1.PhysicianLOS_EM) as PhysicianLOS_EM,
sum(t1.PhysicianLOS_EM_D) as PhysicianLOS_EM_D,
sum(t1.FacilityLOS_EM) as FacilityLOS_EM,
sum(t1.FacilityLOS_EM_D) as FacilityLOS_EM_D,
sum(t1.ProfProc) as ProfProc,
sum(t1.ProfProc_D)as ProfProc_D,
sum(t1.ObsHours) as ObsHours,
sum(t1.ObsHours_D) as ObsHours_D,
sum(t1.ChiefComplaint) as ChiefComplaint,
sum(t1.ChiefComplaint_D) as ChiefComplaint_D,
sum(t1.Principal) as Principal,
sum(t1.Principal_D) as Principal_D,
sum(t1.InfInj) as InfInj,
sum(t1.InfInj_D) as InfInj_D,
sum(t1.ModifierUsage) as ModifierUsage,
sum(t1.Demographic) as Demographic

from 
(
select
s.user_profile_id,
 
sum(s.TotalCorrectCodesCount) as AccurateCount,
sum(s.TotalRevisedCodesCount) as RevisedCount,
sum(s.TotalAddedCodesCount) as AddedCount,
sum(s.TotalDeletedCodesCount) as DeletedCount,


case when Sum(s.TotalCorrectCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) = 0 then 0
else  1 - cast(Sum(s.TotalDeletedCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount)as float)  / 
            cast(Sum(s.TotalCorrectCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) as float) end as CoderAccuracy,


--case when (select (ApprovedNumber) from #ApprovedCharts where APPROVED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0 
--else (select (ApprovedNumber) from #ApprovedCharts where APPROVED_BY_USER_PROFILE_ID = s.user_profile_id ) end as ChartsApproved, 
0 as ChartsApproved, 

(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where service_agreement_id <> 0 ) as ChartsReviewed,



case when (select sum(ApprovedNumber) from #ApprovedCharts where APPROVED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0 
else
(select cast(count(s2.chart_id) as float)  from #Scorecard_1 s2 where 
service_agreement_id <> 0 ) / 
(select cast(ApprovedNumber as float ) from #ApprovedCharts where APPROVED_BY_USER_PROFILE_ID = s.user_profile_id ) end as PercentReviewed,



case when sum(s.DxCorrect)+sum(s.DxRevisions)+sum(s.DxAdditions) = 0 then 0 
else 1 - cast(Sum(s.DxDeletions)+sum(s.DxRevisions)+sum(s.DxAdditions)as float)  / 
            cast(Sum(s.DxCorrect)+sum(s.DxRevisions)+sum(s.DxAdditions) as float) end as Diagnosis,
Sum(s.DxCorrect)+sum(s.DxRevisions)+sum(s.DxAdditions) as Diagnosis_D,

case when Sum(s.FacilityProcCorrect)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+Sum(s.InfusionInjectionCorrect)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) = 0 then 0
else 1 - cast(Sum(s.FacilityProcDeletions)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+sum(s.InfusionInjectionDeletions)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions)as float)  / 
            cast(Sum(s.FacilityProcCorrect)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+Sum(s.InfusionInjectionCorrect)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as float) end as FacilityProc,
Sum(s.FacilityProcCorrect)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+Sum(s.InfusionInjectionCorrect)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as FacilityProc_D,

case when sum(s.PhysicianLOSCorrect)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions) = 0 then 0 
else 1 - cast(Sum(s.PhysicianLOSDeletions)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions)as float)  / 
            cast(sum(s.PhysicianLOSCorrect)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions) as float) end as PhysicianLOS_EM,
			sum(s.PhysicianLOSCorrect)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions) as PhysicianLOS_EM_D,

case when sum(s.FacilityLOSCorrect)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions) = 0 then 0
else 1 - cast(Sum(s.FacilityLOSDeletions)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions)as float)  / 
            cast(sum(s.FacilityLOSCorrect)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions) as float) end as FacilityLOS_EM,
			sum(s.FacilityLOSCorrect)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions) as FacilityLOS_EM_D,

case when sum(s.ProfProcCorrect)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions) = 0 then 0
else 1 - cast(Sum(s.ProfProcDeletions)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions)as float)  / 
            cast(sum(s.ProfProcCorrect)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions) as float) end as ProfProc,
sum(s.ProfProcCorrect)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions) as ProfProc_D,


case when sum(s.ObsHoursSubmitted) = 0 then 0 
else 1 - cast(Sum(s.ObsHoursChanges) + sum(s.ObsHoursAbstract) as float)  / 
         cast(sum(s.ObsHoursSubmitted) as float) end as ObsHours ,
		 sum(s.ObsHoursSubmitted) as ObsHours_D,


case when sum(s.DxChartsSubmitted) = 0 then 0
else 1 - cast(sum(s.DxChiefComplaintChanges) + sum(s.DxAbstract) as float) / cast(sum(s.DxChartsSubmitted) as float) end as ChiefComplaint,
sum(s.DxChartsSubmitted) as ChiefComplaint_D,


case when sum(s.DxChartsSubmitted) = 0 then 0
else 1 - cast(sum(s.DxPrimaryDxChanges) + sum(s.DxAbstract) as float) / cast(sum(s.DxChartsSubmitted) as float) end as Principal,
sum(s.DxChartsSubmitted) as Principal_D,

-- AAR-1674 10/29/21 remove I/I Abstract from calcaulation ****
-- case when sum(s.InfInjSubmitted) = 0 then 0
-- else 1 - cast(sum(s.InfInjChanges)+sum(InfusionInjectionAbstract) as float) / cast(sum(s.InfInjSubmitted) as float) end as InfInj,
 case when sum(s.InfInjSubmitted) = 0 then 0
 else 1 - cast(sum(s.InfInjChanges) as float) / cast(sum(s.InfInjSubmitted) as float) end as InfInj,
sum(s.InfInjSubmitted) as InfInj_D ,



case when (select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.service_agreement_id <> 0 and s2.USER_PROFILE_ID = s.user_profile_id ) = 0 then 0
     when (select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.service_agreement_id <> 0 and s2.USER_PROFILE_ID = s.user_profile_id ) is null then 0
	 when sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) = 0 then 1
else 1 - (cast(sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) as float) / 
			(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.service_agreement_id <> 0 and s2.USER_PROFILE_ID = s.user_profile_id )) end as ModifierUsage,






case when (select count(s2.chart_id) from #Scorecard_1 s2 where service_agreement_id <> 0 ) = 0 then 0
     when (select count(s2.chart_id) from #Scorecard_1 s2 where service_agreement_id <> 0 ) is null then 0
	 when sum(s.DemographicChanges) = 0 then 1
else 1 - (cast(sum(s.DemographicChanges) as float) / 
    (select count(s2.chart_id) from #Scorecard_1 s2 where service_agreement_id <> 0 ) ) end as Demographic

from #Scorecard_1 s
group by s.user_profile_id

union all


select
s.APPROVED_BY_USER_PROFILE_ID as user_profile_id,
 
NULL as AccurateCount,
NULL as RevisedCount,
NULL as AddedCount,
NULL as DeletedCount,
NULL as CoderAccuracy,


--case when (select (ApprovedNumber) from #ApprovedCharts where APPROVED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0 
--else (select (ApprovedNumber) from #ApprovedCharts where APPROVED_BY_USER_PROFILE_ID = s.user_profile_id ) end as ChartsApproved, 
ApprovedNumber as ChartsApproved,

NULL as ChartsReviewed,
NULL as PercentReviewed,
NULL as Diagnosis,
NULL as Diagnosis_D,
NULL as FacilityProc,
NULL as FacilityProc_D,
NULL as PhysicianLOS_EM,
NULL as PhysicianLOS_EM_D,
NULL as FacilityLOS_EM,
NULL as FacilityLOS_EM_D,
NULL as ProfProc,
NULL as ProfProc_D,
NULL as ObsHours ,
NULL as ObsHours_D,
NULL as ChiefComplaint,
NULL as ChiefComplaint_D,
NULL as Principal,
NULL as Principal_D,
NULL as InfInj,
NULL as InfInj_D ,
NULL as ModifierUsage,
NULL as Demographic

from #ApprovedCharts s

) t1

group by 
t1.user_profile_id




END               















GO
GRANT EXECUTE ON  [dbo].[rpt_CorroHealth_Auditor_QA_Detail_Summary] TO [dbx_ExecuteReportProcs]
GO
