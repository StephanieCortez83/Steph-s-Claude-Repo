SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[rpt_VisitReconciliation]
(
@Organization  int          
,@Facility     varchar(max)
,@ReportUser   int          
,@StartDate    date         
,@EndDate      date         
,@PatientClass varchar(max) 
)
as
begin



SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

-- Test Parameters ***
--DECLARE
 
--    	@Organization  int          = 213
--			,@Facility     varchar(max)          = '1238'
--			,@ReportUser   int          = 80
--			,@StartDate    date         = '4/1/2025'
--			,@EndDate      date         = '4/1/2025'
--			,@PatientClass varchar(max) = '-1';

IF OBJECT_ID('TempDB..#Chart1', 'U') IS NOT NULL DROP TABLE #Chart1;
 
IF OBJECT_ID('TempDB..#Visit1', 'U') IS NOT NULL DROP TABLE #Visit1;
 
IF OBJECT_ID('TempDB..#Recon1', 'U') IS NOT NULL DROP TABLE #Recon1;
 
IF OBJECT_ID('TempDB..#Facility1', 'U') IS NOT NULL DROP TABLE #Facility1;
 
IF OBJECT_ID('TempDB..#SA1', 'U') IS NOT NULL DROP TABLE #SA1;

SELECT * INTO #Facility1
 
FROM (
 
    SELECT sa.FACILITY_ID
 
    FROM SERVICE_AGREEMENT sa WITH (NOLOCK)
 
    WHERE (@Facility = '-1' OR sa.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@Facility, ',')))
 
    AND sa.COMPANY_ID = @Organization
 
    AND (@StartDate BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
 
         OR @EndDate BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE)
 
    AND sa.DEMO_TEST_SITE_IND = 0
 
    AND sa.SERVICE_AGREEMENT_ID IN (SELECT DISTINCT SERVICE_AGREEMENT_ID FROM VISIT_RECONCILIATION WITH (NOLOCK))
 
    AND EXISTS (
 
        SELECT * FROM FACILITY_USER_AUTHORIZATION WITH (NOLOCK)
 
        WHERE FACILITY_ID = sa.FACILITY_ID
 
        AND (@StartDate BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
 
             OR @EndDate BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE)
 
        AND USER_PROFILE_ID = @ReportUser
 
    )
 
) t5;

SELECT * INTO #SA1
 
FROM (
 
    SELECT SERVICE_AGREEMENT_ID
 
    FROM SERVICE_AGREEMENT sa WITH (NOLOCK)
 
    WHERE (@Facility = '-1' OR sa.FACILITY_ID IN (SELECT items FROM dbo.SplitString(@Facility, ',')))
 
    AND sa.COMPANY_ID = @Organization
 
    AND (@StartDate BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
 
         OR @EndDate BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE)
 
    AND sa.DEMO_TEST_SITE_IND = 0
 
    AND EXISTS (
 
        SELECT * FROM FACILITY_USER_AUTHORIZATION WITH (NOLOCK)
 
        WHERE FACILITY_ID = sa.FACILITY_ID
 
        AND GETDATE() BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
 
        AND USER_PROFILE_ID = @ReportUser
 
    )
 
) t6;

SELECT * INTO #Chart1
 
FROM (
 
    SELECT
 
        c.FACILITY_CHART_ID,
 
        c.FACILITY_ADMIN_CHART_ID,
 
        c.SERVICE_AGREEMENT_ID,
 
        CAST(c.TIME_OF_SERVICE AS DATE) AS TIME_OF_SERVICE,
 
        CAST(c.DATE_RECEIVED AS DATE) AS DATE_RECEIVED,
 
        CAST(c.SENT_DATE AS DATE) AS SENT_DATE,
 
        c.CHART_STATUS_ID,
 
        (SELECT DESCRIPTION FROM CHART_STATUS WHERE CHART_STATUS_ID = c.CHART_STATUS_ID) AS CHART_STATUS,
 
        c.PATIENT_LAST_NAME,
 
        c.PATIENT_FIRST_NAME,
 
        c.PATIENT_CLASS_ID,
 
        pc.DESCRIPTION AS PATIENT_CLASS
 
    FROM CHART c WITH (NOLOCK)
 
    LEFT JOIN PATIENT_CLASS pc ON c.SERVICE_AGREEMENT_ID = pc.SERVICE_AGREEMENT_ID
 
                              AND c.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID
 
    WHERE EXISTS (SELECT * FROM #Facility1 WHERE FACILITY_ID = c.FACILITY_ID)
 
    AND CAST(c.TIME_OF_SERVICE AS DATE) BETWEEN @StartDate AND @EndDate
 
) t1;

SELECT * INTO #Visit1
 
FROM (
 
    SELECT
 
        vc.FACILITY_CHART_ID,
 
        vc.SERVICE_AGREEMENT_ID,
 
        CAST(vc.TIME_OF_SERVICE AS DATE) AS TIME_OF_SERVICE
 
    FROM VISIT_RECONCILIATION vc WITH (NOLOCK)
 
    WHERE EXISTS (SELECT * FROM #SA1 WHERE SERVICE_AGREEMENT_ID = vc.SERVICE_AGREEMENT_ID)
 
    AND CAST(vc.TIME_OF_SERVICE AS DATE) BETWEEN @StartDate AND @EndDate
 
    AND vc.FACILITY_CHART_ID <> ''
 
) t2;

SELECT * INTO #Recon1
 
FROM (
 
    SELECT
 
        c.FACILITY_CHART_ID AS c_FACILITY_CHART_ID,
 
        c.FACILITY_ADMIN_CHART_ID AS c_FACILITY_ADMIN_CHART_ID,
 
        c.SERVICE_AGREEMENT_ID AS c_SERVICE_AGREEMENT_ID,
 
        c.TIME_OF_SERVICE AS c_TIME_OF_SERVICE,
 
        c.DATE_RECEIVED AS c_DATE_RECEIVED,
 
        c.SENT_DATE AS c_SENT_DATE,
 
        c.CHART_STATUS_ID AS c_CHART_STATUS_ID,
 
        c.CHART_STATUS AS c_CHART_STATUS,
 
        v.FACILITY_CHART_ID AS vc_FACILITY_CHART_ID,
 
        v.SERVICE_AGREEMENT_ID AS vc_SERVICE_AGREEMENT_ID,
 
        v.TIME_OF_SERVICE AS vc_TIME_OF_SERVICE,
 
        c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME AS PatientName,
 
        ISNULL(c.PATIENT_CLASS_ID, '-9999') AS PATIENT_CLASS_ID,
 
        c.PATIENT_CLASS
 
    FROM #Chart1 c
 
    FULL JOIN #Visit1 v ON (c.FACILITY_CHART_ID = v.FACILITY_CHART_ID
 
                        OR c.FACILITY_ADMIN_CHART_ID = v.FACILITY_CHART_ID)
 
    AND c.SERVICE_AGREEMENT_ID = v.SERVICE_AGREEMENT_ID
 
    AND c.TIME_OF_SERVICE = v.TIME_OF_SERVICE
 
) t3;

SELECT
 
    Visit,
 
    Admit,
 
    ReconStatus,
 
    CASE
 
        WHEN ReconStatus = 'No Visit in ACS' THEN 1

		when ReconStatus = 'Approved - Visit in ACS/Not in Recon File' then 2
 
				  when ReconStatus = 'Bypassed - Visit in ACS/Not in Recon File' then 3
 
				  when ReconStatus = 'Complete - Visit in ACS/Not in Recon File' then 4
 
				  when ReconStatus = 'Pending - Visit in ACS/Not in Recon File' then 5
 
				  when ReconStatus = 'Removed - Visit in ACS/Not in Recon File' then 6
 
				  when ReconStatus = 'Sent - Visit in ACS/Not in Recon File' then 7
 
				  when ReconStatus = 'Work in Progress - Visit in ACS/Not in Recon File' then 8
 
				  when ReconStatus = '2nd Audit - Visit in ACS/Not in Recon File' then 9
 
				  when ReconStatus = 'Approved' then 10
 
				  when ReconStatus = 'Bypassed' then 11
 
				  when ReconStatus = 'Complete' then 12
 
				  when ReconStatus = 'Pending' then 13
 
				  when ReconStatus = 'Removed' then 14

        When ReconStatus LIKE 'Sent %' THEN 15

		when ReconStatus = 'Work in Progress' then 16
 
		when ReconStatus = '2nd Audit' then 17

        ELSE 18
 
    END AS SortOrder,
 
    Received,
	DOS,
 
    ServiceAgreementID,
 
    COALESCE((SELECT DESCRIPTION FROM SERVICE_AGREEMENT sa WITH (NOLOCK)
 
              WHERE sa.SERVICE_AGREEMENT_ID = ServiceAgreementID), 'Unknown') AS ServiceAgreement,
 
    PatientName,
 
    PATIENT_CLASS_ID,
 
    PATIENT_CLASS,
 
    FACILITY_ADMIN_CHART_ID
 
FROM (
 
    SELECT
 
        CASE WHEN vc_FACILITY_CHART_ID IS NOT NULL THEN vc_FACILITY_CHART_ID
 
             WHEN c_FACILITY_CHART_ID IS NOT NULL THEN c_FACILITY_CHART_ID
 
        END AS Visit,
 
        CONVERT(VARCHAR, c_TIME_OF_SERVICE, 110) AS Admit,
 
        (case when c_facility_chart_id is null and c_facility_admin_chart_id is null then 'No Visit in ACS'
 
							 when vc_facility_chart_id is null then c.C_CHART_STATUS +' - Visit in ACS/Not in Recon File'
 
			when c.C_CHART_STATUS_ID = 1 and (c_facility_chart_id is not null or c_facility_admin_chart_id is not null) and vc_facility_chart_id is not null then 'Work in Progress'
 
			when c.C_CHART_STATUS_ID = 2 and (c_facility_chart_id is not null or c_facility_admin_chart_id is not null) and vc_facility_chart_id is not null then 'Pending'
 
			when c.C_CHART_STATUS_ID = 3 and (c_facility_chart_id is not null or c_facility_admin_chart_id is not null) and vc_facility_chart_id is not null then 'Complete'
 
			when c.C_CHART_STATUS_ID = 4 and (c_facility_chart_id is not null or c_facility_admin_chart_id is not null) and vc_facility_chart_id is not null then 'Approved'
 
			when c.C_CHART_STATUS_ID = 5 and (c_facility_chart_id is not null or c_facility_admin_chart_id is not null) and vc_facility_chart_id is not null then 'Sent ' + convert(varchar, c.C_SENT_DATE, 110)
 
			when c.C_CHART_STATUS_ID = 6 and (c_facility_chart_id is not null or c_facility_admin_chart_id is not null) and vc_facility_chart_id is not null then 'Removed'
 
			when c.C_CHART_STATUS_ID = 7 and (c_facility_chart_id is not null or c_facility_admin_chart_id is not null) and vc_facility_chart_id is not null then 'Bypassed'
 
			when c.C_CHART_STATUS_ID = 8 and (c_facility_chart_id is not null or c_facility_admin_chart_id is not null) and vc_facility_chart_id is not null then '2nd Audit'
 
			else 'Mismatch' end) ReconStatus,
 
        ISNULL(CONVERT(VARCHAR, c.c_DATE_RECEIVED, 101), '') AS Received,
		ISNULL(CONVERT(VARCHAR, c.c_TIME_OF_SERVICE, 101), '') AS DOS,
 
        CASE WHEN vc_SERVICE_AGREEMENT_ID IS NULL THEN c_SERVICE_AGREEMENT_ID ELSE vc_SERVICE_AGREEMENT_ID END AS ServiceAgreementID,
 
        c.PatientName,
 
        c.PATIENT_CLASS_ID,
 
        c.PATIENT_CLASS,
 
        c.c_FACILITY_ADMIN_CHART_ID as FACILITY_ADMIN_CHART_ID
 
    FROM #Recon1 c
 
    WHERE (@PatientClass = '-1' OR c.PATIENT_CLASS_ID IN (SELECT items FROM dbo.SplitString(@PatientClass, ',')))
 
) AS t4;


		----------------------------------------------------------------------------------------------------------------------------------


end
 
 
GO
