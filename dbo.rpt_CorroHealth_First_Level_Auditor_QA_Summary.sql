SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[rpt_CorroHealth_First_Level_Auditor_QA_Summary] 
    @ReportUser			INT,
	@Company            VARCHAR(MAX),
	@FACILITY_ID		VARCHAR(MAX),	
	@UserGroup			VARCHAR(MAX),
	@AUID				VARCHAR(MAX),	
	@StartDate			DATETIME,
	@EndDate			DATETIME,
	@TimeZone			VARCHAR(25),
	@MonthView			INT
	
	

AS
BEGIN

/*

-- testing parameters ****

-- Review for columns being selected that aer not needed *****

declare 
 @AUID int = -1,						-- 10501 --Adla Akhila, -1 All
 @UserGroup int = -1,
 @StartDate datetime = '4/1/2021',			-- make certain date/ datetime is working correctly	
 @EndDate datetime = '4/4/2021',
 @FACILITY_ID VARCHAR(MAX) = '-1',
 @ReportUser INT = 80,
 @TimeZone VARCHAR(25) = 'Central Daylight Time',
 @MonthView INT = 0 -- 0 Based on Start and End Date parameters
 ;

*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
	DECLARE @m_AUID VARCHAR(MAX) = @AUID;
	DECLARE @m_UserGroup VARCHAR(MAX) = @UserGroup;
	DECLARE @m_Company VARCHAR(MAX) = @Company;
	DECLARE @m_FACILITY_ID VARCHAR(MAX) = @FACILITY_ID;
	DECLARE @m_ReportUser INT = @ReportUser;


if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
if object_id('TempDB..#ApprovedCharts1', 'U') is not null drop table #ApprovedCharts1;
if object_id('TempDB..#ApprovedCharts', 'U') is not null drop table #ApprovedCharts;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;
if object_id('TempDB..#Scorecard_2', 'U') is not null drop table #Scorecard_2;



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
	DECLARE @m_StartDate DATE = CASE 
			WHEN @MonthView = 0
				THEN @StartDate
			ELSE DATEADD(DAY, - (DAY(@StartDate) - 1), @StartDate)
			END
	DECLARE @m_EndDate DATE = CASE 
			WHEN @MonthView = 0
				THEN @EndDate
			ELSE DATEADD(DAY, - (DAY(DATEADD(MONTH, 1, @StartDate))), DATEADD(MONTH, 1, @StartDate))
			END;





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
	and  ( sa.Company_ID in (SELECT * FROM SPLITSTRING(@m_Company, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_Company, ',')) )
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		) fa;

print 'Section: 01 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************
-- Auditor/Usergroup


if object_id('TempDB..#auditor', 'U') is not null drop table #auditor


select distinct t1.USER_PROFILE_ID 
into #auditor				
from  				
		(
		SELECT USER_PROFILE_ID 
		FROM USER_PROFILE				
		WHERE  USER_PROFILE_ID <> 2
		and ( CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR IS_ACTIVE = 'Y' )
		and (USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_AUID, ',') )
			OR -1 in ( SELECT items FROM dbo.SplitString(@m_AUID, ',') ) )
		and (USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') )
			OR -1 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) )
			
		UNION				
				
		SELECT up.USER_PROFILE_ID 
		FROM USER_GROUP_TO_USER_PROFILE ugup,				
		user_profile up				
		where up.user_profile_id = ugup.user_profile_id
		and UP.USER_PROFILE_ID <> 2
		and ( UP.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR UP.IS_ACTIVE = 'Y' ) 		
		and (ugup.USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_AUID, ',') )
			OR -1 in ( SELECT items FROM dbo.SplitString(@m_AUID, ',') ) )
		and (ugup.USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') )		
		    OR -1 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) )
		) t1


create nonclustered index idx_USER_PROFILE_ID on #auditor (USER_PROFILE_ID);




print 'Section: 02 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************

-- Approved Charts   


SELECT	
 c.chart_id 
INTO	[#ApprovedCharts1]
FROM	chart as c  with (NOLOCK)
WHERE	
c.CHART_STATUS_ID in (4, 5) -- Approved, Sent
--  and c.APPROVED_DATE between @m_StartDate and dateadd(second, 86399, @m_EndDate)	
AND DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.APPROVED_DATE ))), 0) BETWEEN @m_StartDate AND @m_EndDate	  	  	
AND	c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
AND c.APPROVED_BY_USER_PROFILE_ID  in ( select USER_PROFILE_ID from #auditor) 
;





alter table #ApprovedCharts1
	add
	[FACILITY_ID]					    INT,
    approved_by_user_profile_id			INT,
	[START_QA_DATE]						DATETIME; 



	update t
	set
	     t.facility_id = c.facility_id
		,t.approved_by_user_profile_id = c.approved_by_user_profile_id
		,t.START_QA_DATE = c.START_QA_DATE
	from
		#ApprovedCharts1 as t
		join CHART as c on t.chart_id = c.CHART_ID;






-- ****

SELECT	
c.APPROVED_BY_USER_PROFILE_ID,
c.facility_id,
count(*) as ApprovedNumber
INTO	[#ApprovedCharts]
FROM	#ApprovedCharts1 c
where c.START_QA_DATE is not null
group by 
 c.APPROVED_BY_USER_PROFILE_ID
,c.facility_id
;



print 'Section: 03 ' + convert(varchar, getdate(), 121);


-- select * from #ApprovedCharts


-- *****************************************************************************************************************************************



SELECT	
c.chart_id, 
c.facility_id,
c.service_agreement_id, c.facility_chart_id, c.APPROVED_DATE, c.completed_by_user_profile_id, c.approved_by_user_profile_id
INTO	[#ChartSubset]
FROM	chart as c with (NOLOCK)
WHERE	c.CHART_STATUS_ID in (4, 5)
AND c.APPROVED_BY_USER_PROFILE_ID  in ( select USER_PROFILE_ID from #auditor) 

AND     c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 2	


-- and c.SECOND_LEVEL_QA_APPROVED_DATETIME between @m_StartDate and dateadd(second, 86399, @m_EndDate)
AND DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.SECOND_LEVEL_QA_APPROVED_DATETIME ))), 0) BETWEEN @m_StartDate AND @m_EndDate	  	  	

AND	c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
AND c.START_SECOND_LEVEL_QA_DATETIME is not null
AND c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2 
;


print 'Section: 04 ' + convert(varchar, getdate(), 121);


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
c.chart_id, 
c.facility_id,
c.service_agreement_id, sa.DESCRIPTION as ServiceAgreementDescription, --c.chart_id, 
c.facility_chart_id, c.APPROVED_DATE, 
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



-- *****************************************************************************************************************************************



select 
t1.user_profile_id,
t1.facility_id,

sum(t1.AccurateCount) as AccurateCount,
sum(t1.RevisedCount) as RevisedCount,
sum(t1.AddedCount) as AddedCount,
sum(t1.DeletedCount) as DeletedCount,
sum(t1.ChartsApproved) as ChartsApproved,
sum(t1.ChartsReviewed) as ChartsReviewed,


sum(t1.CoderAccuracy_N) as CoderAccuracy_N,
sum(t1.CoderAccuracy_D) as CoderAccuracy_D,

sum(t1.Diagnosis_N) as Diagnosis_N,
sum(t1.Diagnosis_D) as Diagnosis_D,

sum(t1.FacilityProc_N) as FacilityProc_N,
sum(t1.FacilityProc_D) as FacilityProc_D,

sum(t1.PhysicianLOS_EM_N) as PhysicianLOS_EM_N,
sum(t1.PhysicianLOS_EM_D) as PhysicianLOS_EM_D,

sum(t1.FacilityLOS_EM_N) as FacilityLOS_EM_N,
sum(t1.FacilityLOS_EM_D) as FacilityLOS_EM_D,

sum(t1.ProfProc_N) as ProfProc_N,
sum(t1.ProfProc_D) as ProfProc_D,

sum(t1.ChiefComplaint_N) as ChiefComplaint_N, 
sum(t1.ChiefComplaint_D) as ChiefComplaint_D,

sum(t1.Principal_N) as Principal_N,
sum(t1.Principal_D) as Principal_D, 

sum(t1.InfInj_N) as InfInj_N,
sum(t1.InfInj_D) as InfInj_D,

sum(t1.ModifierUsage_N) as ModifierUsage_N,
-- ModifierUsage_D  = TotalAudits,

sum(t1.Demographic_N) as Demographic_N,
-- Demographic_D  = TotalAudits, 

sum(t1.ObsHours_N) as ObsHours_N,
sum(t1.ObsHours_D) as ObsHours_D


into #Scorecard_2	
from 
(

select
s.user_profile_id,
s.facility_id, 

sum(s.TotalCorrectCodesCount) as AccurateCount,
sum(s.TotalRevisedCodesCount) as RevisedCount,
sum(s.TotalAddedCodesCount) as AddedCount,
sum(s.TotalDeletedCodesCount) as DeletedCount,
0 as ChartsApproved, 

(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 
where s2.user_profile_id = s.user_profile_id 
and s2.facility_id = s.facility_id 
and s2.service_agreement_id <> 0 ) as ChartsReviewed,

Sum(s.TotalDeletedCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) as CoderAccuracy_N,
Sum(s.TotalCorrectCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) as CoderAccuracy_D,

Sum(s.DxDeletions)+sum(s.DxRevisions)+sum(s.DxAdditions) as Diagnosis_N,
Sum(s.DxCorrect)+sum(s.DxRevisions)+sum(s.DxAdditions) as Diagnosis_D,

Sum(s.FacilityProcDeletions)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+sum(s.InfusionInjectionDeletions)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as FacilityProc_N,            
Sum(s.FacilityProcCorrect)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+Sum(s.InfusionInjectionCorrect)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as FacilityProc_D,

sum(s.PhysicianLOSDeletions)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions)as PhysicianLOS_EM_N,
sum(s.PhysicianLOSCorrect)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions) as PhysicianLOS_EM_D,

sum(s.FacilityLOSDeletions)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions)as FacilityLOS_EM_N,
sum(s.FacilityLOSCorrect)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions) as FacilityLOS_EM_D,

sum(s.ProfProcDeletions)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions)as ProfProc_N,
sum(s.ProfProcCorrect)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions) as ProfProc_D,

sum(s.DxChiefComplaintChanges) + sum(s.DxAbstract) as ChiefComplaint_N,
sum(s.DxChartsSubmitted) as ChiefComplaint_D,

sum(s.DxPrimaryDxChanges) + sum(s.DxAbstract) as Principal_N,
sum(s.DxChartsSubmitted) as Principal_D,

sum(s.InfInjChanges)+sum(s.InfusionInjectionAbstract) as InfInj_N,
sum(s.InfInjSubmitted) as InfInj_D,

sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) as ModifierUsage_N,

sum(s.DemographicChanges) as Demographic_N,

sum(s.ObsHoursChanges) + sum(s.ObsHoursAbstract) as ObsHours_N,
sum(s.ObsHoursSubmitted) as ObsHours_D

from #Scorecard_1 s
group by 
 s.user_profile_id
,s.facility_id

union all


select
s.APPROVED_BY_USER_PROFILE_ID as user_profile_id,
s.facility_id,
 
NULL as AccurateCount,
NULL as RevisedCount,
NULL as AddedCount,
NULL as DeletedCount,
s.ApprovedNumber as ChartsApproved,
NULL as ChartsReviewed,

NULL as CoderAccuracy_N,
NULL as CoderAccuracy_D,

NULL as Diagnosis_N,
NULL as Diagnosis_D,

NULL as FacilityProc_N,
NULL as FacilityProc_D,

NULL as PhysicianLOS_EM_N,
NULL as PhysicianLOS_EM_D,

NULL as FacilityLOS_EM_N,
NULL as FacilityLOS_EM_D,

NULL as ProfProc_N,
NULL as ProfProc_D,

NULL as ChiefComplaint_N,
NULL as ChiefComplaint_D,

NULL as Principal_N,
NULL as Principal_D,

NULL as InfInj_N,
NULL as InfInj_D,

NULL as ModifierUsage_N,

NULL as Demographic_N,
NULL as ObsHours_N,
NULL as ObsHours_D

from #ApprovedCharts s

) t1

group by 
 t1.user_profile_id
,t1.facility_id




-- ******************************************************************
-- Output 

select 
1 as All_Data,
s.User_Profile_ID, 
up.LAST_NAME + ', ' + up.FIRST_NAME as AuditorName,
'Auditor ' + cast(DENSE_RANK() OVER (ORDER BY s.User_Profile_ID)  as varchar) as HiddenName,
s.Facility_ID, 
f.name as Facility,

s.user_profile_id,
s.facility_id,
 
s.AccurateCount,
s.RevisedCount,
s.AddedCount,
s.DeletedCount,
s.ChartsApproved,
s.ChartsReviewed,


s.CoderAccuracy_N,
s.CoderAccuracy_D,

s.Diagnosis_N,
s.Diagnosis_D,

s.FacilityProc_N,
s.FacilityProc_D,

s.PhysicianLOS_EM_N,
s.PhysicianLOS_EM_D,

s.FacilityLOS_EM_N,
s.FacilityLOS_EM_D,

s.ProfProc_N,
s.ProfProc_D,

s.ChiefComplaint_N,
s.ChiefComplaint_D,
s.Principal_N,
s.Principal_D,
s.InfInj_N,
s.InfInj_D,
s.ModifierUsage_N,
s.Demographic_N,
s.ObsHours_N,
s.ObsHours_D


from 
#Scorecard_2 s
LEFT OUTER JOIN USER_PROFILE up on s.user_profile_id = up.USER_PROFILE_ID   
inner join facility f on s.facility_id = f.facility_id


END               





GO
GRANT EXECUTE ON  [dbo].[rpt_CorroHealth_First_Level_Auditor_QA_Summary] TO [dbx_ExecuteReportProcs]
GO
