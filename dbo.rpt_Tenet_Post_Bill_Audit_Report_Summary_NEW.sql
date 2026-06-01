SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE PROCEDURE [dbo].[rpt_Tenet_Post_Bill_Audit_Report_Summary_NEW] 
	@ReportUser INT,
	@DateType INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@CUID VARCHAR(MAX),
	@FACILITY_ID VARCHAR(MAX),
	@Clinic varchar(max)


AS
BEGIN




SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;


-- test parameters
 -- declare
 --   @ReportUser INT = 80,
 --   @DateType INT = 0, -- 0 Approved, 1 DOS, 2 Sent, 3 PostAudit
	--@StartDate DATETIME = '11/01/2024',
	--@EndDate DATETIME   = '11/06/2024',
	--@FACILITY_ID VARCHAR(MAX) = '1782',  -- -1 All 
	--@CUID VARCHAR(MAX)        = -1,  -- -1 All 
	--@Clinic varchar(max) = '-1'; --  'PBG';  -- '-1' ALL

	DECLARE @m_ReportUser INT
	DECLARE @m_StartDate DATETIME
	DECLARE @m_EndDate DATETIME
	DECLARE @m_FACILITY_ID VARCHAR(MAX)
	Set @m_ReportUser = @ReportUser
	Set @m_StartDate = @StartDate
	Set @m_EndDate = @EndDate
	Set @m_FACILITY_ID = @FACILITY_ID
 	DECLARE @m_CUID VARCHAR(MAX) = @CUID;
	DECLARE @m_DateType INT = @DateType;
	DECLARE @m_Clinic varchar(max) = @Clinic;
	

-- Temp Tables
if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#CompletedChartCount', 'U') is not null drop table #CompletedChartCount;
if object_id('TempDB..#ChartSubset1', 'U') is not null drop table #ChartSubset1;

-- *****************************************************************
-- AuthorizedFacilities

SELECT *
INTO #AuthorizedFacilities
FROM (
  SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id 
	and up.IS_ACTIVE = 'Y'						
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.company_id in ( 19, 298)  -- Tenet Healthcare Corporation, Conifer 
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP %'	 
		and (-2 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 1%'	 
		and (-3 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 2%'	 
		and (-4 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 3%'	 
		and (-5 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 4%'	 
		and (-6 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 5%'	 
		and (-7 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 6%'	 
		and (-8 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union -- Tenet ED
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation		
		and sa.DESCRIPTION like 'Tenet %'			
        and sa.DESCRIPTION not like 'Tenet OP %'	
		and sa.DESCRIPTION not like 'Tenet - Titan %' 
		and sa.DESCRIPTION not like 'Tenet - TPR%'
		and sa.DESCRIPTION not like 'Tenet USPI%'
		and (-9 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )  -- all ED facilities
		

union -- Titan Profee 
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID in ( 19, 298) -- Tenet Healthcare Corporation, Conifer		
		and (sa.DESCRIPTION like 'Tenet - Titan %') 		
		and (-10 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union	-- All Conifer
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 298 -- Conifer	
		and sa.DESCRIPTION not like 'Tenet - Titan %'
		and (-11 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
union -- Tenet USPI
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation		
		and sa.DESCRIPTION like 'Tenet USPI%'
		and (-12 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) ) 
union -- Conifer UC Urvine
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID in ( 19, 298)  -- Tenet, Conifer
		and (
		     sa.DESCRIPTION like 'Tenet 2 - U%'
		 OR  sa.DESCRIPTION like 'Tenet OP 5 - F%'
		 OR  sa.DESCRIPTION like 'Tenet OP 5 - L%'
		 OR  sa.DESCRIPTION like 'Tenet OP 5 - P%'
		)			
		and (-13 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) ) 
union -- Conifer Orlando
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 298 -- Conifer
		and (
		      sa.DESCRIPTION like 'Tenet 3 - O%'
		 or   sa.DESCRIPTION like 'Tenet 6 - O%'
		 or   sa.DESCRIPTION like 'Tenet OP 4%'
		 or   sa.DESCRIPTION like 'Tenet OP 6%'
		    )			
		and (-14 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) ) 
union -- Conifer Novant
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 298 -- Conifer
		and (
		      sa.DESCRIPTION like 'Tenet 3 - V%'		 
		 or   sa.DESCRIPTION like 'Tenet OP 2%'		 
		    )			
		and (-15 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) ) 
union -- Conifer Adventist
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID = 298 -- Conifer
		and (
		      sa.DESCRIPTION like 'Tenet 2 - B%'		 
		 or   sa.DESCRIPTION like 'Tenet OP 5 - C%'		 
		    )			
		and (-16 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) ) 
union -- TPR Profee 
	    SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, sa.description as name
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
		and SA.COMPANY_ID in ( 19, 298) -- Tenet Healthcare Corporation, Conifer		
		and sa.DESCRIPTION like 'Tenet - TPR%'		
		and (-17 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		) af;


-- select * from #AuthorizedFacilities

-- **********************************************************************
-- from rpt_CorroHealth_Coder_QA_Trending_With_PostBillAudit] 
-- completed chart count from Coder Productivity by Facility Report. RACS-2577



select 
c.service_agreement_id,
c.CLINIC_ID,
count(chart_id)	as Cnt
into #CompletedChartCount
from
    CHART c     
where
    c.CHART_STATUS_ID in (3, 4, 5, 8) 		
	and c.COMPLETION_DATE >= @StartDate
	and c.COMPLETION_DATE <= dateadd(second, 86399, @EndDate)
	and ( c.COMPLETED_BY_USER_PROFILE_ID in (SELECT * FROM SPLITSTRING(@m_CUID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_CUID, ',')) )
	and c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities )
group by c.service_agreement_id, c.CLINIC_ID

-- *************************************************************************



SELECT	c.chart_id, c.service_agreement_id, c.CLINIC_ID 


INTO	[#ChartSubset1]
FROM	chart as c 
WHERE	
        c.CHART_STATUS_ID in (4, 5) 
AND   
( c.COMPLETED_BY_USER_PROFILE_ID in (SELECT * FROM SPLITSTRING(@m_CUID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_CUID, ',')) )



and	 
		(									
		(@m_DateType = 0 and c.APPROVED_DATE between @m_StartDate and DateAdd(second, 86399, @m_EndDate) )						
		or					
		(@m_DateType = 1 and c.TIME_OF_SERVICE between @m_StartDate and DateAdd(second, 86399, @m_EndDate) )									
		or 									
		(@m_DateType = 2 and c.sent_date between @m_StartDate and  DateAdd(second, 86399, @m_EndDate) )
		or 
		(@m_DateType = 3 and c.POST_BILL_AUDIT_COMPLETED between @m_StartDate and  DateAdd(second, 86399, @m_EndDate) )
		) 
AND	    c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
;

-- select * from #ChartSubset1

-- ******************************************************************************
-- Output 
-- Summary  

select 
c.Service_Agreement_ID, 
af.name as Facility,
c.CLINIC_ID, 
(Select description from SERVICE_AGREEMENT_CLINIC where service_agreement_id = c.service_agreement_id and  CLINIC_ID = c.CLINIC_ID) as Clinic, 
(select Cnt from #CompletedChartCount where service_agreement_id = c.service_agreement_id and CLINIC_ID = c.CLINIC_ID  ) as TotalCompletedChartCount,
sum(case when ChartPostBillAuditReasonTypeCode = 3 then 1 else 0 end) as MonthlyQualtityMonitoring,
sum(case when (pba.ChartPostBillAuditReasonTypeCode = 3 and isnull(pba.ErrorCount,0) = 0) then 1 else 0 end) as MonthlyQualtityMonitoringWithNoErrors,
sum(case when ChartPostBillAuditReasonTypeCode = 1 then 1 else 0 end) as ClientRequestedMonitoring,
sum(case when ChartPostBillAuditReasonTypeCode = 1 and isnull(ErrorCount,0) < 1 then 1 else 0 end) as ClientRequestedMonitoringNoErrors,
sum(case when ChartPostBillAuditReasonTypeCode = 2 then 1 else 0 end) as FocusedQualtityReview,
sum(case when ChartPostBillAuditReasonTypeCode = 7 then 1 else 0 end) as IPDowngrade,
count(c.chart_id) as TotalPBACount,
sum(case when isnull(ErrorCount,0) >= 1 then 1 else 0 end) as TotalPBAChartWithErrors

from 
[#ChartSubset1] c,
ChartPostBillAudit pba, -- this table includes records from both new and old PBA engine 
ChartAuditVersion cav,  -- records in version table will be new PBA engine
#AuthorizedFacilities af
where c.chart_id = pba.chartID
and pba.ChartPostBillAuditId = cav.ChartAuditId
AND c.service_agreement_id = af.service_agreement_id
AND pba.ChartPostBillAuditStatusTypeCode = 3 -- Completed
AND cav.VersionNumber = 2 -- PBA Complete Version
AND ( c.CLINIC_ID in (SELECT * FROM SPLITSTRING(@m_Clinic, ','))
            OR	'-1' in (SELECT * FROM SPLITSTRING(@m_Clinic, ',')) )
group by c.service_agreement_id, af.name,c.CLINIC_ID




 END







GO
