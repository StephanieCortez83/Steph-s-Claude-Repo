SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE PROCEDURE [dbo].[rpt_CorroHealth_Coder_QA_Detail_Summary] 
    @ReportUser INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@CUID VARCHAR(MAX),
	@Company VARCHAR(MAX),
	@FACILITY_ID VARCHAR(MAX)





AS
BEGIN



-- Test Parameters ----- 
--declare 
--@ReportUser int = 80
--,@StartDate datetime = '02/01/2024'
--,@EndDate datetime =   '02/10/2024'
--,@Company VARCHAR(MAX) = '-1'
--,@FACILITY_ID VARCHAR(MAX) = '2175'
--,@CUID VARCHAR(MAX) = '13772';


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
	DECLARE @m_CUID VARCHAR(MAX) = @CUID;
	DECLARE @m_Company VARCHAR(MAX) = @Company;
 


if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
if object_id('TempDB..#CodedCharts1', 'U') is not null drop table #CodedCharts1;
if object_id('TempDB..#CodedCharts', 'U') is not null drop table #CodedCharts;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;


-- **********************************************************************
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
	and  ( sa.company_id in (SELECT * FROM SPLITSTRING(@m_Company, ','))
            OR	'-1' in (SELECT * FROM SPLITSTRING(@m_Company, ',')) )
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		) af;

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
				OR '-1' in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') ) )			
			) t1


	create nonclustered index idx_USER_PROFILE_ID on #coder (USER_PROFILE_ID);

declare @CNT_Facility int = (select count(*) from #AuthorizedFacilities);
declare @CNT_CUID int = (SELECT count(*) FROM #coder);
declare @CNT_CO int = (SELECT count(*) FROM SPLITSTRING(@m_Company, ','));

-- ******************************************************************
-- Parameter Check


-- Date Range: 10, Org: All, Facility: All, Coder: All 
IF (datediff(day,@m_StartDate,@m_EndDate) > 10 
AND ( '-1' in (@m_FACILITY_ID) OR @CNT_Facility > 10 )
AND ('-1' in (@m_CUID) OR @CNT_CUID > 10  ) 
AND ('-1' in (@m_Company) OR @CNT_CO > 10 )
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
datediff(day,@m_StartDate,@m_EndDate)
end;

-- Date Range: 31, Org: 1 , Facility: All, Coder: All, 
ELSE
IF (datediff(day,@m_StartDate,@m_EndDate) > 31
AND ('-1' in (@m_Company) OR @CNT_CO > 1 ) 
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
datediff(day,@m_StartDate,@m_EndDate)
end;

ELSE -- 90 Days, 1 Coder,  All Company/Facilities
IF (datediff(day,@m_StartDate,@m_EndDate) > 90 
AND ( '-1' in (@m_CUID) OR @CNT_CUID > 1   ) )
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
datediff(day,@m_StartDate,@m_EndDate)
end;

-- Default 90 Max
ELSE
IF (datediff(day,@m_StartDate,@m_EndDate) > 90 ) 
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
datediff(day,@m_StartDate,@m_EndDate)
end;

ELSE	
BEGIN 


-- ************************************************************************

-- Coded Charts   -- Move Coded Charts up, when no other data , these records were not being counted

SELECT	
c.chart_id, c.service_agreement_id, c.facility_chart_id, 
c.APPROVED_DATE, c.completed_by_user_profile_id, 
c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID,
c.CHART_STATUS_ID,
c.APPROVAL_REASON_CODE, START_QA_DATE

INTO	[#CodedCharts1]
FROM	chart as c  with (NOLOCK)
WHERE	
c.CHART_STATUS_ID in (4, 5) -- Approved, Sent
AND    c.COMPLETED_BY_USER_PROFILE_ID in ( select USER_PROFILE_ID from #coder)
AND	convert(varchar, c.APPROVED_DATE, 112) BETWEEN convert(varchar, @m_StartDate, 112) AND convert(varchar, @m_EndDate, 112)
AND	c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
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
AND     c.APPROVAL_REASON_CODE = 3
AND     c.APPROVED_BY_USER_PROFILE_ID <> 2			
AND 	c.START_QA_DATE is not null


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




-- old loop below ********
/*
select 
		
		dx.CHART_ID
		,dx.FACILITY_CHART_ID
		,dx.ACTION
		,dx.CODER_DIAGNOSIS_TYPE_DESCRIPTION
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
		
		,dx.CODER_ICD10_CODE
		,dx.AUDITOR_ICD10_CODE
		,dx.EXCLUDE_FROM_QA_REPORT
		,IS_CODER_CORRECT
	into #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION
	from
		#ChartSubset c
		inner join CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
		left join CHART_DIAGNOSIS_CODE_ICD10 icd on dx.CHART_ID = icd.CHART_ID and dx.AUDITOR_ICD10_CODE = icd.ICD10_CODE
	where
		dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION not like '%and%'




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
		,dx.CODER_ICD10_CODE
		,dx.AUDITOR_ICD10_CODE
		,dx.EXCLUDE_FROM_QA_REPORT
		,IS_CODER_CORRECT
		,0 as [Split]
	into #combined
	from
		#ChartSubset c
		inner join dbo.CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
	where
		dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION like '%and%'





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
		   ,case when c.ACTION = 'A' and c.IS_CHIEF_COMPLAINT_CHANGE = 1 then 0 
					when c.ACTION = 'R' and c.IS_CHIEF_COMPLAINT_CHANGE = 0 then 0
				else c.IS_CHIEF_COMPLAINT_CHANGE end IS_CHIEF_COMPLAINT_CHANGE
		   ,case when c.ACTION = 'A' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 then 0 
					when c.ACTION = 'R' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 0 then 0
				else c.IS_PRIMARY_DIAGNOSIS_CHANGE end IS_PRIMARY_DIAGNOSIS_CHANGE
		   ,c.CODER_ICD10_CODE
		   ,c.AUDITOR_ICD10_CODE
		   ,c.EXCLUDE_FROM_QA_REPORT
		   ,IS_CODER_CORRECT
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
		   ,case when c.ACTION = 'A' and c.IS_CHIEF_COMPLAINT_CHANGE = 1 then 0 
					when c.ACTION = 'R' and c.IS_CHIEF_COMPLAINT_CHANGE = 0 then 0
				else c.IS_CHIEF_COMPLAINT_CHANGE end IS_CHIEF_COMPLAINT_CHANGE
		   ,case when c.ACTION = 'A' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 then 0 
					when c.ACTION = 'R' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 0 then 0
				else c.IS_PRIMARY_DIAGNOSIS_CHANGE end IS_PRIMARY_DIAGNOSIS_CHANGE
		   ,c.CODER_ICD10_CODE
		   ,c.AUDITOR_ICD10_CODE
		   ,c.EXCLUDE_FROM_QA_REPORT
		   ,IS_CODER_CORRECT
		from
			#combined c
		where
			c.CHART_ID = @chart

		
		update #combined
		set Split = 1
		where CHART_ID = @chart


	end

*/

-- *****************************************************************************************************************************************

SELECT		c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, c.chart_id, c.facility_chart_id, 
			c.APPROVED_DATE, 
			up.USER_PROFILE_ID,  
			up.LAST_NAME + ', ' + up.FIRST_NAME  as CoderName,


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

			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxAttempted,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
--			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAbstract,
            (select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
				    AND dx.chart_id not in (select chart_id from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx2 WHERE dx2.CHART_ID = dx.CHART_ID AND dx2.ACTION in ('D','R','A') AND dx2.EXCLUDE_FROM_QA_REPORT <> 1 )	) as DxAbstract,

			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionDeletions,
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAbstract,
            (select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
									AND pr.chart_id not in (select chart_id from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr2 
											WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'CI' AND pr2.ACTION in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as InfusionInjectionAbstract,

			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract,
			
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions, 							 
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAbstract, 									 
            (select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
                    AND pr.chart_id not in (select chart_id from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr2 WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'OB' AND pr2.ACTION in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as ObsHoursAbstract, 	

			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted, 
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,	
			
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect ,-- PA
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted, 	
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,

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
			
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcActions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcActions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursActions 							 
			

  into #Scorecard_1
			FROM				
			[#ChartSubset] c with (NOLOCK) 
					 LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID    
					LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
 			WHERE		c.approved_by_user_profile_id > 2		    
			




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



0	 as TotalCodesCount,

0	 as TotalCorrectCodesCount,

0	 as TotalRevisedCodesCount,

0	 as TotalAddedCodesCount,

0	 as TotalDeletedCodesCount,

0	 as DxCorrect,
0	 as DxAttempted,
0	 as DxAdditions,
0	 as DxRevisions,
0	 as DxDeletions,
0	 as DxAbstract,

0	 as FacilityProcCorrect,
0    as FacilityProcAttempted,
0	 as FacilityProcAdditions,
0	 as FacilityProcRevisions,
0	 as FacilityProcDeletions,
0	 as FacilityProcAbstract,
0	 as InfusionInjectionCorrect,
0	 as InfusionInjectionAttempted,
0    as InfusionInjectionAdditions,
0	 as InfusionInjectionRevisions,
0	 as InfusionInjectionDeletions,
0	 as InfusionInjectionAbstract,

0			 as ProfProcCorrect,
0			 as ProfProcAttempted, 
0			 as ProfProcAdditions, 							 
0			 as ProfProcRevisions, 							 
0			 as ProfProcDeletions, 							 
0			 as ProfProcAbstract,
			
0			 as ObsHoursCorrect,
0			 as ObsHoursAttempted, 
0			 as ObsHoursAdditions, 							 
0			 as ObsHoursRevisions, 							 
0			 as ObsHoursDeletions, 							 
0			 as ObsHoursAbstract, 									 
0			 as FacilityLOSCorrect,
0			 as FacilityLOSAttempted, 
0			 as FacilityLOSAdditions,
0			 as FacilityLOSRevisions,
0			 as FacilityLOSDeletions,
0			 as FacilityLOSAbstract,	
			
0			 as PhysicianLOSCorrect ,
0			 as PhysicianLOSAttempted, 	
0			 as PhysicianLOSAdditions,
0			 as PhysicianLOSRevisions,
0			 as PhysicianLOSDeletions,
0			 as PhysicianLOSAbstract,

0			 as DxChiefComplaintChanges,
0			 as DxPrimaryDxChanges,	
0			 as DxChartsSubmitted,
			
0			 as InfInjChanges,
0			 as InfInjSubmitted,
0			 as ObsHoursChanges,
0			 as ObsHoursSubmitted, 
0			 as ProcModifierChanges, 
0			 as FacilityLOSModifierChanges,  																															 
0			 as PhysicianLOSModifierChanges,
0			 as DemographicChanges, 
			
0			 as FacilityLOSService,
0			 as InfusionInjectionService,
0			 as FacilityProcService,
0			 as PhysicianLOSService,
0			 as ProfProcService,
0			 as DxService,
0			 as ObsHoursService,
			
0			 as FacilityLOSActions,
0			 as InfusionInjectionActions,
0			 as FacilityProcActions,
0			 as PhysicianLOSActions,
0			 as ProfProcActions,
0			 as DxActions,
0			 as ObsHoursActions 							 
			

from #CodedCharts c
LEFT OUTER JOIN USER_PROFILE up with (NOLOCK) on c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID  

end



-- select * from [#CodedCharts]     -- testing / remove ******

-- select * from #Scorecard_1



-- *****************************************************************************************************************************************
--calculations

select 
s.USER_PROFILE_ID,
s.CoderName,

sum(s.TotalCorrectCodesCount) as AccurateCount,
sum(s.TotalRevisedCodesCount) as RevisedCount,
sum(s.TotalAddedCodesCount) as AddedCount,
sum(s.TotalDeletedCodesCount) as DeletedCount,



case when Sum(s.TotalCorrectCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) = 0 then 0
else  1 - cast(Sum(s.TotalDeletedCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount)as float)  / 
            cast(Sum(s.TotalCorrectCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) as float) end as CoderAccuracy,

case when (select sum(Number_of_Charts_Coded) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0 
else (select sum(Number_of_Charts_Coded) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) end as ChartsCoded, 



(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where service_agreement_id <> 0 and user_profile_id = s.user_profile_id ) as ChartsReviewed,



case when (select sum(Number_of_Charts_Coded) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0 
else
(select cast(count(s2.chart_id) as float) from #Scorecard_1 s2 where 
service_agreement_id <> 0 and user_profile_id = s.user_profile_id ) / 
(select cast(sum(Number_of_Charts_Coded) as float) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) end as PercentReviewed,




 

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

--case when sum(s.ObsHoursSubmitted) = 0 then 0 
--else 1 - cast(Sum(s.ObsHoursChanges)as float)  / 
--         cast(sum(s.ObsHoursSubmitted) as float) end as ObsHours ,
case when sum(s.ObsHoursSubmitted) = 0 then 0 
else 1 - cast(Sum(s.ObsHoursChanges) + sum(s.ObsHoursAbstract) as float)  / 
         cast(sum(s.ObsHoursSubmitted) as float) end as ObsHours, 
		 sum(s.ObsHoursSubmitted) as ObsHours_D,

--case when sum(s.DxChartsSubmitted) = 0 then 0
--else 1 - cast(sum(s.DxChiefComplaintChanges) as float) / cast(sum(s.DxChartsSubmitted) as float) end as ChiefComplaint,
case when sum(s.DxChartsSubmitted) = 0 then 0
else 1 - cast(sum(s.DxChiefComplaintChanges) + sum(s.DxAbstract) as float) / cast(sum(s.DxChartsSubmitted) as float) end as ChiefComplaint,
sum(s.DxChartsSubmitted) as ChiefComplaint_D,

--case when sum(s.DxChartsSubmitted) = 0 then 0
--else 1 - cast(sum(s.DxPrimaryDxChanges) as float) / cast(sum(s.DxChartsSubmitted) as float) end as Principal,
case when sum(s.DxChartsSubmitted) = 0 then 0
else 1 - cast(sum(s.DxPrimaryDxChanges) + sum(s.DxAbstract) as float) / cast(sum(s.DxChartsSubmitted) as float) end as Principal,
sum(s.DxChartsSubmitted) as Principal_D,


-- AAR-1674 10/29/21 remove I/I Abstract from calcaulation ****

--case when sum(s.InfInjSubmitted) = 0 then 0
--else 1 - cast(sum(s.InfInjChanges)+sum(s.InfusionInjectionAbstract) as float) / cast(sum(s.InfInjSubmitted) as float) end as InfInj,

case when sum(s.InfInjSubmitted) = 0 then 0
else 1 - cast(sum(s.InfInjChanges) as float) / cast(sum(s.InfInjSubmitted) as float) end as InfInj,
sum(s.InfInjSubmitted) as InfInj_D,

/*
case when (select cast(sum(Number_of_Charts_Coded) as float) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) = 0 then 0
     when (select cast(sum(Number_of_Charts_Coded) as float) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0
	 when sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) = 0 then 1
else 1 - (cast(sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) as float) / 
			(select cast(sum(Number_of_Charts_Coded) as float) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id )) end as ModifierUsage,
*/

case when (select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.service_agreement_id <> 0 and s2.USER_PROFILE_ID = s.user_profile_id ) = 0 then 0
     when (select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.service_agreement_id <> 0 and s2.USER_PROFILE_ID = s.user_profile_id ) is null then 0
	 when sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) = 0 then 1
else 1 - (cast(sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) as float) / 
			(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 where s2.service_agreement_id <> 0 and s2.USER_PROFILE_ID = s.user_profile_id )) end as ModifierUsage,



/*
case when (select cast(sum(Number_of_Charts_Coded) as float) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) = 0 then 0
     when (select cast(sum(Number_of_Charts_Coded) as float) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id ) is null then 0
	 when sum(s.DemographicChanges) = 0 then 0
else 1 - (cast(sum(s.DemographicChanges) as float) / 
    (select cast(sum(Number_of_Charts_Coded) as float) from #CodedCharts where COMPLETED_BY_USER_PROFILE_ID = s.user_profile_id )) end as Demographic
*/

case when (select count(s2.chart_id) from #Scorecard_1 s2 where service_agreement_id <> 0 ) = 0 then 0
     when (select count(s2.chart_id) from #Scorecard_1 s2 where service_agreement_id <> 0 ) is null then 0
	 when sum(s.DemographicChanges) = 0 then 1
else 1 - (cast(sum(s.DemographicChanges) as float) / 
    (select count(s2.chart_id) from #Scorecard_1 s2 where service_agreement_id <> 0 )) end as Demographic


from #Scorecard_1 s

group by 
s.user_profile_id,
s.CoderName




END     

END









GO
GRANT EXECUTE ON  [dbo].[rpt_CorroHealth_Coder_QA_Detail_Summary] TO [dbx_ExecuteReportProcs]
GO
