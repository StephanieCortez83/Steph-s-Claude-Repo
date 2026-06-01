SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE PROCEDURE [dbo].[rpt_Post_Bill_Audit_Report_Summary_NEW] 
	@ReportUser INT,
	@DateType INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@CUID VARCHAR(MAX),
	@COMPANY_ID VARCHAR(MAX),  
	@FACILITY_ID VARCHAR(MAX)	


AS
BEGIN




SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;


-- test parameters
 -- declare
 --   @ReportUser INT = 80,
 --   @DateType INT = 3, -- 0 Approved, 1 DOS, 2 Sent, 3 PostAudit
	--@StartDate DATETIME = '09/01/2023',
	--@EndDate DATETIME   = '09/10/2023',
	--@FACILITY_ID VARCHAR(MAX) = -1,  -- -1 All 
	--@CUID VARCHAR(MAX)        = -1  -- -1 All 


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
	

-- Temp Tables
if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
if object_id('TempDB..#CompletedChartCount', 'U') is not null drop table #CompletedChartCount;
if object_id('TempDB..#ChartSubset1', 'U') is not null drop table #ChartSubset1;

-- AuthorizedFacilities



SELECT *
INTO #AuthorizedFacilities
FROM (
  SELECT DISTINCT fua.FACILITY_ID, sa.service_agreement_id, f.name 
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa,
	facility f
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id
	and fua.FACILITY_ID = f.FACILITY_ID 
	and up.IS_ACTIVE = 'Y'						
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.company_id <> 19 -- Exclude - Tenet Healthcare Corporation 
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser
	    and  ( sa.COMPANY_ID in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ',')) )
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		) fa;


-- **********************************************************************
-- from rpt_CorroHealth_Coder_QA_Trending_With_PostBillAudit] 
-- completed chart count from Coder Productivity by Facility Report. RACS-2577



select 
c.service_agreement_id,
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
group by c.service_agreement_id

-- *************************************************************************



SELECT	c.chart_id, c.service_agreement_id 


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

-- ******************************************************************************
-- Output 
-- Summary  

select 
c.Service_Agreement_ID, 
af.name as Facility,
(select Cnt from #CompletedChartCount where service_agreement_id = c.service_agreement_id) as TotalCompletedChartCount,
sum(case when ChartPostBillAuditReasonTypeCode = 3 then 1 else 0 end) as MonthlyQualtityMonitoring,
sum(case when ChartPostBillAuditReasonTypeCode = 1 then 1 else 0 end) as ClientRequestedMonitoring,
sum(case when ChartPostBillAuditReasonTypeCode = 1 and isnull(ErrorCount,0) < 1 then 1 else 0 end) as ClientRequestedMonitoringNoErrors,
sum(case when ChartPostBillAuditReasonTypeCode = 2 then 1 else 0 end) as FocusedQualtityReview,
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
group by c.service_agreement_id, af.name




END






GO
