SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

















CREATE PROCEDURE [dbo].[rpt_CorroHealth_Facility_QA_Summary] 
    @ReportUser INT,
	@DateType INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@AccountManager INT,
	@Organization INT,
	@Facility_ID VARCHAR(MAX),
	@TimeZone VARCHAR(50)




AS
BEGIN





    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SET NOCOUNT ON;



-- test parameters *****


--declare @ReportUser INT = 80,
--        @DateType INT = 0, -- 0 Approved, 1 DOS, 2 Sent, 3 PostAudit
--    	@StartDate DATETIME = '01/29/2024',
--	    @EndDate DATETIME =   '02/5/2024',
--		@AccountManager int = -1,   
--		@Organization  int = 50, 
--	    @FACILITY_ID VARCHAR(MAX) = '-1',	-- 2296	
--		@TimeZone VARCHAR(50) = 'Central Daylight Time'
--		;



-- SELECT * FROM TIME_ZONE   WHERE [DESCRIPTION] 

	DECLARE @m_ReportUser INT = @ReportUser;
	DECLARE @m_StartDate DATETIME = @StartDate;
	DECLARE @m_EndDate DATETIME = @EndDate;
	DECLARE @m_AccountManager INT = @AccountManager;
	DECLARE @m_Organization INT = @Organization;
	DECLARE @m_Facility_ID VARCHAR(MAX) = @Facility_ID;
	DECLARE @m_DateType INT = @DateType;
	
	
			




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
	;






if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
if object_id('TempDB..#CodedCharts1', 'U') is not null drop table #CodedCharts1;
if object_id('TempDB..#CodedCharts', 'U') is not null drop table #CodedCharts;
if object_id('TempDB..#Scorecard', 'U') is not null drop table #Scorecard;
if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
if object_id('TempDB..#Scorecard_2', 'U') is not null drop table #Scorecard_2;
if object_id('TempDB..#Scorecard_22', 'U') is not null drop table #Scorecard_22;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION;
if object_id('TempDB..#combined', 'U') is not null drop table #combined;
if object_id('TempDB..#combined_2', 'U') is not null drop table #combined_2;
if object_id('TempDB..#Audit2a', 'U') is not null drop table #Audit2a;
if object_id('TempDB..#Audit2', 'U') is not null drop table #Audit2;
if object_id('TempDB..#Final_Audit_2', 'U') is not null drop table #Final_Audit_2;
if object_id('TempDB..#PBA_1', 'U') is not null drop table #PBA_1;
if object_id('TempDB..#PBA_2', 'U') is not null drop table #PBA_2;

print 'Section: 00 ' + convert(varchar, getdate(), 121)



-- *****************************************************************************************************************************************
-- AuthorizedFacilities

SELECT *
INTO #AuthorizedFacilities
FROM (
  SELECT DISTINCT fua.FACILITY_ID
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa,
	SERVICE_AGREEMENT_MANAGEMENT_TEAM SAMT
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id
	and samt.service_agreement_id = sa.service_agreement_id 
	and up.IS_ACTIVE = 'Y'						
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser
	and (samt.user_profile_id = @AccountManager or (@AccountManager) in ( -1,-2,-3,-4,-5) )
	and ( sa.company_id = @m_Organization or -1 = @m_Organization )
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_Facility_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_Facility_ID, ',')) )
		) fa;

create nonclustered index idx_FACILITY_ID on #AuthorizedFacilities (FACILITY_ID);


print 'Section: 01 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************
 



-- Coded Charts   -- Move Coded Charts up, when no other data , these records were not being counted

SELECT	
c.chart_id
INTO	[#CodedCharts1]
FROM	chart as c  with (NOLOCK)
WHERE	
c.CHART_STATUS_ID in (4, 5) -- Approved, Sent

and	 
		(									
		@DateType = 0 and  c.APPROVED_DATE between dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, @m_StartDate ))												
			  and dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, dateadd(second, 86399, @m_EndDate) ))									
		or												
		@DateType = 1 and  c.TIME_OF_SERVICE between dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, @m_StartDate ))												
			  and dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, dateadd(second, 86399, @m_EndDate) ))									
        or												
		@DateType = 2 and  c.sent_date between dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, @m_StartDate ))												
			  and dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, dateadd(second, 86399, @m_EndDate) ))									
        or												
		@DateType = 3 and  c.POST_BILL_AUDIT_COMPLETED between dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, @m_StartDate ))												
			  and dateadd(hh, -@HrsOffSet, dateadd(mi, -@MinOffSet, dateadd(second, 86399, @m_EndDate) ))
		) 


AND	c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
; 


create nonclustered index idx_chart_id on #CodedCharts1 (chart_id);



print 'Section: 02.0 ' + convert(varchar, getdate(), 121)




alter table #CodedCharts1
	add
	[FACILITY_ID]					    INT,
    [SERVICE_AGREEMENT_ID]				INT,
	[FACILITY_CHART_ID]					VARCHAR(20),
	[APPROVED_DATE]						DATETIME,				
	[COMPLETED_BY_USER_PROFILE_ID]		INT,
	[APPROVED_BY_USER_PROFILE_ID]		INT,
	[PATIENT_DISPOSITION_ID]			INT,
	[CHART_STATUS_ID]					INT,
	[APPROVAL_REASON_CODE]				INT,
	[START_QA_DATE]						DATETIME
	; 



	update t
	set
	     t.facility_id = c.facility_id
		,t.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
		,t.FACILITY_CHART_ID = c.FACILITY_CHART_ID
		,t.APPROVED_DATE = c.APPROVED_DATE
		,t.COMPLETED_BY_USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
		,t.APPROVED_BY_USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
		,t.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		,t.CHART_STATUS_ID = c.CHART_STATUS_ID
		,t.APPROVAL_REASON_CODE = c.APPROVAL_REASON_CODE
		,t.START_QA_DATE = c.START_QA_DATE
	from
		#CodedCharts1 as t
		join CHART as c on t.chart_id = c.CHART_ID;


print 'Section: 02.1 ' + convert(varchar, getdate(), 121)


SELECT	
c.facility_id, 
count(*) as Number_of_Charts_Coded
INTO	[#CodedCharts]
FROM	#CodedCharts1 c
group by 
c.facility_id 
;

print 'Section: 02.2 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************
-- #ChartSubset 

SELECT	
		c.chart_id, 
		c.facility_id, 
		c.service_agreement_id, 
		c.approved_by_user_profile_id 

INTO	[#ChartSubset]
FROM	#CodedCharts1 as c 

WHERE	c.CHART_STATUS_ID in (4, 5)
AND     c.APPROVAL_REASON_CODE = 3
AND     c.APPROVED_BY_USER_PROFILE_ID <> 2			
AND 	c.START_QA_DATE is not null; 



print 'Section: 02.3 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************
-- 2nd Audit

SELECT 
          c.chart_id
      into #Audit2a
	  FROM CHART c 
	  WHERE c.CHART_STATUS_ID IN (4,5,8)
      --AND DATEADD(DAY, DATEDIFF(DAY, 0, c.second_level_qa_approved_datetime), 0) BETWEEN @m_StartDate AND @m_EndDate			  
	  AND DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.second_level_qa_approved_datetime ))), 0) BETWEEN @m_StartDate AND @m_EndDate	  	  
print 'Section: 03.0 ' + convert(varchar, getdate(), 121)





	select
c.chart_id,
c.[FACILITY_ID],						
c.[SERVICE_AGREEMENT_ID],					
c.[SECOND_LEVEL_QA_APPROVED_DATETIME],		
c.[SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID],	
c.[START_SECOND_LEVEL_QA_DATETIME],				
c.[START_SECOND_LEVEL_QA_USER_PROFILE_ID]	
into #Audit2	
from								
	chart c
where exists ( select a1.chart_id from #Audit2A  a1 where a1.chart_ID = c.chart_ID )



print 'Section: 03.1 ' + convert(varchar, getdate(), 121)




select 
         a2.FACILITY_ID,

         sum(case when a2.SECOND_LEVEL_QA_APPROVED_DATETIME is not null  THEN 1 ELSE 0 end) Second_Approved ,

     	 sum(case when a2.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2 		               
                        and a2.START_SECOND_LEVEL_QA_DATETIME is not null 
						and a2.SECOND_LEVEL_QA_APPROVED_DATETIME is not null 
						THEN 1 ELSE 0 end) Second_Audit ,

		 sum(case when a2.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID=2 
		                and a2.START_SECOND_LEVEL_QA_DATETIME is null THEN 1 ELSE 0 end) Second_System_Pushed ,

		 sum(case when a2.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID<>2 						
						and a2.START_SECOND_LEVEL_QA_DATETIME is null 
						and a2.SECOND_LEVEL_QA_APPROVED_DATETIME is not null 
		                THEN 1 ELSE 0 end) Second_Audit_Pushed
						 


into #Final_Audit_2
  from #Audit2 a2
   
  group by
  a2.FACILITY_ID 


print 'Section: 03.2 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************
-- Correction to Split Dx Types

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

	while exists (select top 1 * from #combined where Split = 0)
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

		


        delete from #combined where CHART_ID = @chart

	end



print 'Section: 04.0 ' + convert(varchar, getdate(), 121)

-- *****************************************************************************************************************************************

-- Correction to 2nd Level Split Dx Types


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
	into #combined_2
	from
		#ChartSubset c
		inner join dbo.CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
	where
		dx.SECOND_AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION like '%and%'




	declare @chart_2 int

	while exists (select top 1 * from #combined_2 where Split = 0) 
	begin
		
		set @chart_2 = (select top 1 CHART_ID from #combined_2 where Split = 0)



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
			#combined_2 c
		where
			c.CHART_ID = @chart_2

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
			#combined_2 c
		where
			c.CHART_ID = @chart_2

		
	

		delete from #combined_2 where CHART_ID = @chart_2


	end





-- *****************************************************************************************************************************************






select

			c.chart_id, 			
			c.facility_id, 
			c.service_agreement_id,



--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
--			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)  
--			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) 
--			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,


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
--            (select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
--				    AND dx.chart_id not in (select chart_id from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx2 WHERE dx2.CHART_ID = dx.CHART_ID AND dx2.ACTION in ('D','R','A') AND dx2.EXCLUDE_FROM_QA_REPORT <> 1 )	) as DxAbstract,

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
            (select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
									AND pr.chart_id not in (select chart_id from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr2 
											WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'CI' AND pr2.ACTION in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as InfusionInjectionAbstract,

			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted, 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions, 							 
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract,
			
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted, 
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions, 							 
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions, 							 
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions, 							 
--          (select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
--                    AND pr.chart_id not in (select chart_id from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr2 WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'OB' AND pr2.ACTION in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as ObsHoursAbstract, 	

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

--			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
--			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,	
--			(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,
			
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
--			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
--			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted, 
--			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges, 
--			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,  																															 
--			(select count(DISTINCT pr.CHART_ID) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,
--			(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges, 
			
			case when sa.EVALUATE_FACILITY_SVC = 1 then 'Y' else 'N' end as FacilityLOSService,
--			case when (sa.INFUSION_INJECTION_METHOD_ID = 1 or sa.INFUSION_INJECTION_METHOD_ID = 2) then 'Y' else 'N' end as InfusionInjectionService,
			case when sa.EVALUATE_FACILITY_PROCEDURES = 1 then 'Y' else 'N' end as FacilityProcService,
			case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 'Y' else 'N' end as PhysicianLOSService,
			case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 'Y' else 'N' end as ProfProcService,
			case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 'Y' else 'N' end as DxService,
-- 			case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 and c.PATIENT_DISPOSITION_ID = 5 then 'Y' else 'N' end as ObsHoursService,
			
			(select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSActions,
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcActions,
			(select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSActions,
			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcActions,
			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxActions
--			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursActions 							 
			

   into #Scorecard_1
			FROM				
			[#ChartSubset] c with (NOLOCK) 
						LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
 			WHERE		c.approved_by_user_profile_id <> 2
			;		    
			

print 'Section: 05.0 ' + convert(varchar, getdate(), 121)


-- *****************************************************************************************************************************************
-- 2nd Level

select

			c.chart_id, 			
			c.facility_id, 
			c.service_agreement_id,

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
			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_SECOND_LEVEL_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_FIRST_AUDITOR_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount

into #Scorecard_2
from
			#Audit2 c
			WHERE c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID<>2 

-- *****************************************************************************************************************************************
select 
s2.facility_id,
Sum(s2.TotalDeletedCodesCount)+sum(s2.TotalRevisedCodesCount)+sum(s2.TotalAddedCodesCount) as Second_AuditAccuracy_N,
Sum(s2.TotalCorrectCodesCount)+sum(s2.TotalRevisedCodesCount)+sum(s2.TotalAddedCodesCount) as Second_AuditAccuracy_D
into #Scorecard_22
from #Scorecard_2 s2
group by S2.facility_id

-- *****************************************************************************************************************************************
--calculations



select 
t1.FACILITY_ID,

sum(t1.TotalCharts) as TotalCharts,
sum(t1.TotalAudits) as TotalAudits,

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

sum(t1.CoderAccuracy_N) as CoderAccuracy_N,
sum(t1.CoderAccuracy_D) as CoderAccuracy_D

into #Scorecard


from (

select 
s.facility_id, 
0 as TotalCharts,

(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 
where 
 s2.facility_id = s.facility_id
) as TotalAudits,


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

Sum(s.TotalDeletedCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) as CoderAccuracy_N,
Sum(s.TotalCorrectCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) as CoderAccuracy_D

from #Scorecard_1 s

group by 
s.facility_id


union all 
-- Coded charts with No Approved


select 
facility_id,
Number_of_Charts_Coded as TotalCharts,
NULL as TotalAudits,
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
NULL as CoderAccuracy_N,
NULL as CoderAccuracy_D

from #CodedCharts



 ) t1

group by 
t1.FACILITY_ID



print 'Section: 06.0 ' + convert(varchar, getdate(), 121)
-- ******************************************************************
-- PBA

select 
c.facility_id,
c.chart_id
into #PBA_1
from 
chart c 
where 
DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.POST_BILL_AUDIT_COMPLETED ))), 0) BETWEEN @m_StartDate AND @m_EndDate	  	  	
AND	c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities);



select 
p1.FACILITY_ID,
sum(case when pba.ChartPostBillAuditReasonTypeCode = 3 then 1 else 0 end) as MonthlyQualtityMonitoring,
sum(case when pba.ChartPostBillAuditReasonTypeCode = 1 then 1 else 0 end) as ClientRequestedMonitoring,
sum(case when pba.ChartPostBillAuditReasonTypeCode = 1 and isnull(ErrorCount,0) < 1 then 1 else 0 end) as ClientRequestedMonitoringNoErrors,
sum(case when pba.ChartPostBillAuditReasonTypeCode = 2 then 1 else 0 end) as FocusedQualtityReview,
sum(case when pba.ChartPostBillAuditReasonTypeCode = 6 then 1 else 0 end) as SecondLevelAudit,
sum(case when isnull(ErrorCount,0) >= 1 then 1 else 0 end) as TotalPBAChartWithErrors
into #PBA_2
from #PBA_1 p1,
ChartPostBillAudit pba -- this table includes records from both new and old PBA engine 
where p1.chart_id = pba.chartid
group by 
p1.FACILITY_ID;



-- ******************************************************************

-- Output 

select 
s.Facility_ID, 
f.name as Facility,
s.TotalCharts,
s.TotalAudits,
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
A2.Second_Approved ,
A2.Second_Audit ,
A2.Second_System_Pushed ,
A2.Second_Audit_Pushed,
S2.Second_AuditAccuracy_N,
S2.Second_AuditAccuracy_D,
-- PBA
p2.MonthlyQualtityMonitoring,
p2.ClientRequestedMonitoring,
p2.ClientRequestedMonitoringNoErrors,
p2.FocusedQualtityReview,
p2.SecondLevelAudit,
(select count(chart_id) from #PBA_1 where facility_id = s.facility_id) as TotalPBAChartCount,
p2.TotalPBAChartWithErrors
from 
#Scorecard s
inner join facility f on s.facility_id = f.facility_id
left outer join #Final_Audit_2 A2 on  s.facility_id = A2.facility_id
left outer join #Scorecard_22 S2 on s.facility_id = S2.facility_id

left outer join #PBA_2 p2 on s.facility_id = p2.facility_id


  END               

   









GO
GRANT EXECUTE ON  [dbo].[rpt_CorroHealth_Facility_QA_Summary] TO [dbx_ExecuteReportProcs]
GO
