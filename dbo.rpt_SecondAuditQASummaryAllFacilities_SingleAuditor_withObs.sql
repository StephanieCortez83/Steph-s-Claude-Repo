SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[rpt_SecondAuditQASummaryAllFacilities_SingleAuditor_withObs] @StartDate DATETIME,
	@EndDate DATETIME,
	@UserProfileID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @m_StartDate DATETIME
	DECLARE @m_EndDate DATETIME
	Set @m_StartDate = @StartDate
	Set @m_EndDate = @EndDate
	DECLARE @m_UserProfileID INT = @UserProfileID;

	WITH CoderQASummary
	AS (
		SELECT 
			car.Auditor,
			car.AUID AUID,
			COUNT(*) SecondAudits,
			CAST(SUM(car.SecondAuditCorrected) AS DECIMAL)  S_SecondAuditsCorrected,
			CAST(SUM(car.fa) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.OIA) + SUM(car.OPA) + SUM(car.OHA) AS DECIMAL) Available,
			SUM(car.AUDITOR_FLOSE) + SUM(car.AUDITOR_FPROCE) + SUM(car.AUDITOR_FINJE) + SUM(car.AUDITOR_PLOSE) + SUM(car.AUDITOR_PPROCE) + SUM(car.AUDITOR_DE) + SUM(car.AUDITOR_OHE) + SUM(car.AUDITOR_OPE) + SUM(car.AUDITOR_OIE) Earned,
			CAST(SUM(car.FA) AS DECIMAL) FacLOSAvail,
			CAST(SUM(car.AUDITOR_FLOSE) AS DECIMAL) FacLOSEarned,
			CAST(SUM(car.FIA) AS DECIMAL) FacInjAvail,
			CAST(SUM(car.AUDITOR_FINJE) AS DECIMAL) FacInjEarned,
			CAST(SUM(car.FPA) AS DECIMAL) FacProcAvail,
			CAST(SUM(car.AUDITOR_FPROCE) AS DECIMAL) FacProcEarned,
			CAST(SUM(car.PA) AS DECIMAL) PhysLOSAvail,
			CAST(SUM(car.AUDITOR_PLOSE) AS DECIMAL) PhysLOSEarnedl,
			CAST(SUM(car.PPA) AS DECIMAL) PhysProcAvail,
			CAST(SUM(car.AUDITOR_PPROCE) AS DECIMAL) PhysProcEarned,
			CAST(SUM(car.DA) AS DECIMAL) DiagAvail,
			CAST(SUM(car.AUDITOR_DE) AS DECIMAL) DiagEarned,
			CAST(SUM(car.DEMA) AS DECIMAL) DemoAvail,
			CAST(SUM(car.AUDITOR_DEME) AS DECIMAL) DemoEarned,
			CAST(SUM(car.OHA) AS DECIMAL) ObsHoursAvail,
			CAST(SUM(car.AUDITOR_OHE) as DECIMAL) ObsHours,
			CAST(SUM(car.OIA) AS DECIMAL) ObsInjAvail,
			CAST(SUM(car.AUDITOR_OIE) as DECIMAL) ObsInj,
			CAST(SUM(car.OPA) AS DECIMAL) ObsProcAvail,
			CAST(SUM(car.AUDITOR_OPE) as DECIMAL) ObsProc,
			SUM(car.ObsAudits) ObsAudits
		FROM (
			SELECT 
				car2.ANAME Auditor,
				car2.AUID AUID,
				1 Charts,
				car2.FA,
				car2.AUDITOR_FLOSE,
				car2.FIA,
				car2.AUDITOR_FINJE,
				car2.FPA,
				car2.AUDITOR_FPROCE,
				car2.PA,
				car2.AUDITOR_PLOSE,
				car2.PPA,
				car2.AUDITOR_PPROCE,
				car2.AUDITOR_DE,
				car2.DA,
				car2.DEMA,
				car2.AUDITOR_DEME,
				car2.AUDITED Audits,
				(
					SELECT 1
					FROM CHART c
					WHERE c.CHART_ID = car2.CHART_ID
						AND c.PATIENT_DISPOSITION_ID = 5
						AND sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1
						AND c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = - 1
					) ObsAudits,
				car2.OIA,
				car2.OHA,
				car2.OPA,
				car2.AUDITOR_OIE,
				car2.AUDITOR_OHE,
				car2.AUDITOR_OPE,
				CASE 	WHEN (car2.PA +car2.PPA + car2.DA + car2.FA + car2.FIA + car2.FPA + car2.OIA + car2.OHA + car2.OPA + car2.DEMA) >
				 (car2.AUDITOR_FLOSE + car2.AUDITOR_FPROCE + car2.AUDITOR_FINJE + car2.AUDITOR_PLOSE + car2.AUDITOR_PPROCE + car2.AUDITOR_DE + 
				  car2.AUDITOR_OIE + car2.AUDITOR_OHE + car2.AUDITOR_OPE + car2.AUDITOR_DEME) 
			THEN 1 ELSE 0 END  SecondAuditCorrected
			FROM CHART_SECOND_LEVEL_AUDIT_RESULT car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK),
				CHART c2 WITH (NOLOCK),
				SERVICE_AGREEMENT sa WITH (NOLOCK)
			WHERE 
					  convert(varchar, car2.SECOND_APPROVED_DATE, 112) >= convert(varchar, @m_StartDate, 112)
				and   convert(varchar, car2.SECOND_APPROVED_DATE, 112) <= convert(varchar, @m_EndDate, 112)
			--DATEADD(DAY, DATEDIFF(DAY, 0, car2.SECOND_APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.CHART_ID = c2.CHART_ID
				AND sa.SERVICE_AGREEMENT_ID = c2.SERVICE_AGREEMENT_ID
				AND up.USER_PROFILE_ID = car2.AUID
				AND up.USER_PROFILE_ID = @m_UserProfileID
				--AND (
				--	car2.CUID = car2.obsUID
				--	OR car2.obsUID IS NULL
				--	OR car2.obsUID = 0
				--	)

			UNION ALL
			
			SELECT 
				car2.ANAME Auditor,
				car2.AUID AUID,
				1 Charts,
				car2.FA,
				car2.AUDITOR_FLOSE,
				car2.FIA,
				car2.AUDITOR_FINJE,
				car2.FPA,
				car2.AUDITOR_FPROCE,
				car2.PA,
				car2.AUDITOR_PLOSE,
				car2.PPA,
				car2.AUDITOR_PPROCE,
				car2.AUDITOR_DE,
				car2.DA,
				car2.DEMA,
				car2.AUDITOR_DEME,
				car2.AUDITED Audits,

				0 ObsAudits,
				0 OIA,
				0 OHA,
				0 OPA,
				0 AUDITOR_OIE,
				0 AUDITOR_OHE,
				0 AUDITOR_OPE,
				CASE 	WHEN (car2.PA +car2.PPA + car2.DA + car2.FA + car2.FIA + car2.FPA + car2.OIA + car2.OHA + car2.OPA + car2.DEMA) >
				 (car2.AUDITOR_FLOSE + car2.AUDITOR_FPROCE + car2.AUDITOR_FINJE + car2.AUDITOR_PLOSE + car2.AUDITOR_PPROCE + car2.AUDITOR_DE + 
				  car2.AUDITOR_OIE + car2.AUDITOR_OHE + car2.AUDITOR_OPE + car2.AUDITOR_DEME)
				THEN 1 ELSE 0 END  SecondAuditCorrected				   
			FROM CHART_SECOND_LEVEL_AUDIT_RESULT car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK)
			WHERE 
					  convert(varchar, car2.SECOND_APPROVED_DATE, 112) >= convert(varchar, @m_StartDate, 112)
				and   convert(varchar, car2.SECOND_APPROVED_DATE, 112) <= convert(varchar, @m_EndDate, 112)
			--DATEADD(DAY, DATEDIFF(DAY, 0, car2.SECOND_APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.AUID = @m_UserProfileID
				AND up.USER_PROFILE_ID = car2.CUID
				AND (car2.obsUID > 0)
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)
				AND up.USER_PROFILE_ID = @m_UserProfileID
			
			--UNION ALL
			
			--SELECT 
			--	car2.ObsName Coder,
			--	car2.ObsUID CUID,
			--	1 Charts,
			--	car2.AUDITED Audits,
			--	0 FA,
			--	0 AUDITOR_FLOSE,
			--	0 FIA,
			--	0 AUDITOR_FINJE,
			--	0 FPA,
			--	0 AUDITOR_FPROCE,
			--	0 PA,
			--	0 AUDITOR_PLOSE,
			--	0 PPA,
			--	0 AUDITOR_PPROCE,
			--	0 AUDITOR_DE,
			--	0 DA,
			--	0 DEMA,
			--	0 AUDITOR_DEME,
			--	1 ObsAudits,
			--	car2.OIA,
			--	car2.OHA,
			--	car2.OPA,
			--	car2.AUDITOR_OIE,
			--	car2.AUDITOR_OHE,
			--	car2.AUDITOR_OPE
			--FROM CHART_AUDIT_RESULT car2 WITH (NOLOCK),
			--	USER_PROFILE up WITH (NOLOCK)
			--WHERE DATEADD(DAY, DATEDIFF(DAY, 0, car2.SECOND_APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
			--	AND car2.AUID = @m_UserProfileID
			--	AND up.USER_PROFILE_ID = car2.ObsUID
			--	AND car2.obsUID > 0
			--	AND up.USER_CLASS_CD IN (
			--		1,
			--		2,
			--		4,
			--		5
			--		)
			--	AND up.USER_PROFILE_ID = @m_UserProfileID
			--	--AND up.USER_GROUP_ID IN (
			--	--	SELECT LTRIM(RTRIM(Value))
			--	--	FROM dbo.SplitMultivaluedString(@m_UserGroup, ',')
			--	--	)
			) car
		GROUP BY
			car.Auditor,
			car.AUID
		)
	SELECT *,
		NULLIF(FacLOSEarned / ISNULL(NULLIF(FacLOSAvail, 0), 1), 0) FacLosRate,
		NULLIF(FacInjEarned / ISNULL(NULLIF(FacInjAvail, 0), 1), 0) FacInjRate,
		NULLIF(FacProcEarned / ISNULL(NULLIF(FacProcAvail, 0), 1), 0) FacProcRate,
		NULLIF(PhysLOSEarnedl / ISNULL(NULLIF(PhysLOSAvail, 0), 1), 0) PhysLosRate,
		NULLIF(PhysProcEarned / ISNULL(NULLIF(PhysProcAvail, 0), 1), 0) PhysProcRate,
		NULLIF(DiagEarned / ISNULL(NULLIF(DiagAvail, 0), 1), 0) DiagRate,
		NULLIF(DemoEarned / ISNULL(NULLIF(DemoAvail, 0), 1), 0) DemoRate,
		NULLIF(Earned / ISNULL(NULLIF(Available, 0), 1), 0) Rate,
		NULLIF(ObsProc / ISNULL(NULLIF(ObsProcAvail, 0), 1), 0) ObsProcRate,
		NULLIF(ObsInj / ISNULL(NULLIF(ObsInjAvail, 0), 1), 0) ObsInjRate,
		NULLIF(ObsHours / ISNULL(NULLIF(ObsHoursAvail, 0), 1), 0) ObsRate

		
	FROM CoderQASummary
	--WHERE EXISTS (
	--		SELECT *
	--		FROM FACILITY_USER_AUTHORIZATION
	--		WHERE FACILITY_ID = CoderQASummary.FACILITY_ID
	--			AND USER_PROFILE_ID = @m_UserProfileID
	--		)
	ORDER BY 
		Auditor,
		AUID
END




GO
GRANT EXECUTE ON  [dbo].[rpt_SecondAuditQASummaryAllFacilities_SingleAuditor_withObs] TO [dbx_ExecuteReportProcs]
GO
