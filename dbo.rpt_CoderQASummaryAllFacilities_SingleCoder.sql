SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[rpt_CoderQASummaryAllFacilities_SingleCoder] @StartDate DATETIME,
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
			car.Coder,
			car.CUID CUID,
			COUNT(*) Charts,
			CAST(SUM(car.Audits) AS DECIMAL) Audits,
			CAST(SUM(car.fa) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.OIA) + SUM(car.OPA) + SUM(car.OHA) AS DECIMAL) Available,
			SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) + SUM(car.OHE) + SUM(car.OPE) + SUM(car.OIE) Earned,
			--CAST(SUM(car.FA) + SUM(car.FPA) + SUM(car.FIA) AS DECIMAL) FAvail,
			--CAST(SUM(car.PA) + SUM(car.PPA) AS DECIMAL) PAvail,
			CAST(SUM(car.FA) AS DECIMAL) FacLOSAvail,
			CAST(SUM(car.FLOSE) AS DECIMAL) FacLOSEarned,
			CAST(SUM(car.FIA) AS DECIMAL) FacInjAvail,
			CAST(SUM(car.FINJE) AS DECIMAL) FacInjEarned,
			CAST(SUM(car.FPA) AS DECIMAL) FacProcAvail,
			CAST(SUM(car.FPROCE) AS DECIMAL) FacProcEarned,
			CAST(SUM(car.PA) AS DECIMAL) PhysLOSAvail,
			CAST(SUM(car.PLOSE) AS DECIMAL) PhysLOSEarnedl,
			CAST(SUM(car.PPA) AS DECIMAL) PhysProcAvail,
			CAST(SUM(car.PPROCE) AS DECIMAL) PhysProcEarned,
			CAST(SUM(car.DA) AS DECIMAL) DiagAvail,
			CAST(SUM(car.DE) AS DECIMAL) DiagEarned,
			CAST(SUM(car.DEMA) AS DECIMAL) DemoAvail,
			CAST(SUM(car.DEME) AS DECIMAL) DemoEarned,
			SUM(car.ObsAudits) ObsAudits,
			CAST(SUM(car.OIA) AS DECIMAL) ObsInjAvail,
			CAST(SUM(car.OHA) AS DECIMAL) ObsHoursAvail,
			CAST(SUM(car.OPA) AS DECIMAL) ObsProcAvail,
			SUM(car.OIE) ObsInj,
			SUM(car.OHE) ObsHours,
			SUM(car.OPE) ObsProc
		FROM (
			SELECT 
				car2.CNAME Coder,
				car2.CUID CUID,
				1 Charts,
				car2.FA,
				car2.FLOSE,
				car2.FIA,
				car2.FINJE,
				car2.FPA,
				car2.FPROCE,
				car2.PA,
				car2.PLOSE,
				car2.PPA,
				car2.PPROCE,
				car2.DE,
				car2.DA,
				car2.DEMA,
				car2.DEME,
				(select 1 FROM CHART c where c.chart_id = car2.chart_id
				 and car2.AUDITED = 1 AND car2.AUID <> 2
				)
				 Audits,
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
				car2.OIE,
				car2.OHE,
				car2.OPE
			FROM CHART_AUDIT_RESULT car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK),
				CHART c2 WITH (NOLOCK),
				SERVICE_AGREEMENT sa WITH (NOLOCK)
			WHERE 
				   convert(varchar, car2.APPROVED_DATE, 112) >= convert(varchar, @m_StartDate, 112)
			 and   convert(varchar, car2.APPROVED_DATE, 112) <= convert(varchar, @m_EndDate, 112)
			--DATEADD(DAY, DATEDIFF(DAY, 0, car2.APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.CHART_ID = c2.CHART_ID
				AND sa.SERVICE_AGREEMENT_ID = c2.SERVICE_AGREEMENT_ID
				AND up.USER_PROFILE_ID = car2.CUID
				AND up.USER_PROFILE_ID = @m_UserProfileID
				AND (
					car2.CUID = car2.obsUID
					OR car2.obsUID IS NULL
					OR car2.obsUID = 0
					)
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)

				--AND up.USER_GROUP_ID IN (
				--	SELECT LTRIM(RTRIM(Value))
				--	FROM dbo.SplitMultivaluedString(@m_UserGroup, ',')
				--	)
			
			UNION ALL
			
			SELECT 
				car2.CNAME Coder,
				car2.CUID CUID,
				1 Charts,
				car2.FA,
				car2.FLOSE,
				car2.FIA,
				car2.FINJE,
				car2.FPA,
				car2.FPROCE,
				car2.PA,
				car2.PLOSE,
				car2.PPA,
				car2.PPROCE,
				car2.DE,
				car2.DA,
				car2.DEMA,
				car2.DEME,
				car2.AUDITED Audits,

				0 ObsAudits,
				0 OIA,
				0 OHA,
				0 OPA,
				0 OIE,
				0 OHE,
				0 OPE
			FROM CHART_AUDIT_RESULT car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK)
			WHERE 				   
					convert(varchar, car2.APPROVED_DATE, 112) >= convert(varchar, @m_StartDate, 112)
				and convert(varchar, car2.APPROVED_DATE, 112) <= convert(varchar, @m_EndDate, 112)
			--DATEADD(DAY, DATEDIFF(DAY, 0, car2.APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.CUID = @m_UserProfileID
				AND up.USER_PROFILE_ID = car2.CUID
				AND (car2.obsUID > 0)
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)
				AND up.USER_PROFILE_ID = @m_UserProfileID
				--AND up.USER_GROUP_ID IN (
				--	SELECT LTRIM(RTRIM(Value))
				--	FROM dbo.SplitMultivaluedString(@m_UserGroup, ',')
				--	)
			
			UNION ALL
			
			SELECT 
				car2.ObsName Coder,
				car2.ObsUID CUID,
				1 Charts,
				car2.AUDITED Audits,
				0 FA,
				0 FLOSE,
				0 FIA,
				0 FINJE,
				0 FPA,
				0 FPROCE,
				0 PA,
				0 PLOSE,
				0 PPA,
				0 PPROCE,
				0 DE,
				0 DA,
				0 DEMA,
				0 DEME,
				1 ObsAudits,
				car2.OIA,
				car2.OHA,
				car2.OPA,
				car2.OIE,
				car2.OHE,
				car2.OPE
			FROM CHART_AUDIT_RESULT car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK)
			WHERE 
					convert(varchar, car2.APPROVED_DATE, 112) >= convert(varchar, @m_StartDate, 112)
			  and   convert(varchar, car2.APPROVED_DATE, 112) <= convert(varchar, @m_EndDate, 112)
			--DATEADD(DAY, DATEDIFF(DAY, 0, car2.APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.CUID = @m_UserProfileID
				AND up.USER_PROFILE_ID = car2.ObsUID
				AND car2.obsUID > 0
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)
				AND up.USER_PROFILE_ID = @m_UserProfileID
				--AND up.USER_GROUP_ID IN (
				--	SELECT LTRIM(RTRIM(Value))
				--	FROM dbo.SplitMultivaluedString(@m_UserGroup, ',')
				--	)
			) car
		GROUP BY
			car.Coder,
			car.CUID
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
		Coder,
		CUID
END



GO
