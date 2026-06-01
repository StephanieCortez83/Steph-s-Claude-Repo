SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 1/10/2014
-- Description:	Report SQL for Coder QA Summary by Facility
-- =============================================
CREATE PROCEDURE [dbo].[rpt_CoderQASummaryByFacility] @StartDate DATE,
	@EndDate DATE,
	@ReportUser INT,
	@Facility VARCHAR,
	@UserGroup VARCHAR
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @m_StartDate DATE = @StartDate;
	DECLARE @m_EndDate DATE = @EndDate;
	DECLARE @m_ReportUser INT = @ReportUser;
	DECLARE @m_Facility VARCHAR(MAX) = @Facility;
	DECLARE @m_UserGroup VARCHAR(MAX) = @UserGroup;

	WITH CoderQASummary
	AS (
		SELECT car.FACILITY_ID,
			car.FNAME,
			car.Coder,
			car.CUID CUID,
			COUNT(*) Charts,
			CAST(SUM(car.Audits) AS DECIMAL) Audits,
			SUM(car.ObsAudits) ObsAudits,
			CAST(SUM(car.fa) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.OIA) + SUM(car.OPA) + SUM(car.OHA) AS DECIMAL) Available,
			SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) + SUM(car.OHE) + SUM(car.OPE) + SUM(car.OIE) Earned,
			CAST(SUM(car.FA) + SUM(car.FPA) + SUM(car.FIA) AS DECIMAL) FAvail,
			CAST(SUM(car.PA) + SUM(car.PPA) AS DECIMAL) PAvail,
			CAST(SUM(car.PA) AS DECIMAL) PA,
			CAST(SUM(car.PPA) AS DECIMAL) PPA,
			CAST(SUM(car.DA) AS DECIMAL) DAvail,
			SUM(car.FLOSE) FLOS,
			SUM(car.FPROCE) FProc,
			SUM(car.FINJE) FInj,
			SUM(car.PLOSE) PLOS,
			SUM(car.PPROCE) PProc,
			SUM(car.DE) Diag,
			CAST(SUM(car.OIA) AS DECIMAL) ObsInjAvail,
			CAST(SUM(car.OHA) AS DECIMAL) ObsHoursAvail,
			CAST(SUM(car.OPA) AS DECIMAL) ObsProcAvail,
			SUM(car.OIE) ObsInj,
			SUM(car.OHE) ObsHours,
			SUM(car.OPE) ObsProc
		FROM (
			SELECT car2.FACILITY_ID,
				car2.FNAME,
				car2.CNAME Coder,
				car2.CUID CUID,
				1 Charts,
				car2.AUDITED Audits,
				(
					SELECT 1
					FROM CHART c
					WHERE c.CHART_ID = car2.CHART_ID
						AND c.PATIENT_DISPOSITION_ID = 5
						AND sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1
						AND c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = - 1
					) ObsAudits,
				car2.PA PA,
				car2.PPA PPA,
				car2.DA,
				car2.FA,
				car2.FIA,
				car2.FPA,
				car2.FLOSE,
				car2.FPROCE,
				car2.FINJE,
				car2.PLOSE,
				car2.PPROCE,
				car2.DE,
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
			WHERE DATEADD(DAY, DATEDIFF(DAY, 0, car2.APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.CHART_ID = c2.CHART_ID
				AND sa.SERVICE_AGREEMENT_ID = c2.SERVICE_AGREEMENT_ID
				AND car2.FACILITY_ID IN (
					SELECT LTRIM(RTRIM(Value))
					FROM dbo.SplitMultivaluedString(@m_Facility, ',')
					)
				AND up.USER_PROFILE_ID = car2.CUID
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
				AND up.USER_GROUP_ID IN (
					SELECT LTRIM(RTRIM(Value))
					FROM dbo.SplitMultivaluedString(@m_UserGroup, ',')
					)
			
			UNION ALL
			
			SELECT car2.FACILITY_ID,
				car2.FNAME,
				car2.CNAME Coder,
				car2.CUID CUID,
				1 Charts,
				car2.AUDITED Audits,
				0 ObsAudits,
				car2.PA PA,
				car2.PPA PPA,
				car2.DA,
				car2.FA,
				car2.FIA,
				car2.FPA,
				car2.FLOSE,
				car2.FPROCE,
				car2.FINJE,
				car2.PLOSE,
				car2.PPROCE,
				car2.DE,
				0 OIA,
				0 OHA,
				0 OPA,
				0 OIE,
				0 OHE,
				0 OPE
			FROM CHART_AUDIT_RESULT car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK)
			WHERE DATEADD(DAY, DATEDIFF(DAY, 0, car2.APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.FACILITY_ID IN (
					SELECT LTRIM(RTRIM(Value))
					FROM dbo.SplitMultivaluedString(@m_Facility, ',')
					)
				AND up.USER_PROFILE_ID = car2.CUID
				AND (car2.obsUID > 0)
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)
				AND up.USER_GROUP_ID IN (
					SELECT LTRIM(RTRIM(Value))
					FROM dbo.SplitMultivaluedString(@m_UserGroup, ',')
					)
			
			UNION ALL
			
			SELECT car2.FACILITY_ID,
				car2.FNAME,
				car2.ObsName Coder,
				car2.ObsUID CUID,
				1 Charts,
				car2.AUDITED Audits,
				1 ObsAudits,
				0 PA,
				0 PPA,
				0 DA,
				0 FA,
				0 FIA,
				0 FPA,
				0 FLOSE,
				0 FPROCE,
				0 FINJE,
				0 PLOSE,
				0 PPROCE,
				0 DE,
				car2.OIA,
				car2.OHA,
				car2.OPA,
				car2.OIE,
				car2.OHE,
				car2.OPE
			FROM CHART_AUDIT_RESULT car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK)
			WHERE DATEADD(DAY, DATEDIFF(DAY, 0, car2.APPROVED_DATE), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.FACILITY_ID IN (
					SELECT LTRIM(RTRIM(Value))
					FROM dbo.SplitMultivaluedString(@m_Facility, ',')
					)
				AND up.USER_PROFILE_ID = car2.ObsUID
				AND car2.obsUID > 0
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)
				AND up.USER_GROUP_ID IN (
					SELECT LTRIM(RTRIM(Value))
					FROM dbo.SplitMultivaluedString(@m_UserGroup, ',')
					)
			) car
		GROUP BY car.FACILITY_ID,
			car.FNAME,
			car.Coder,
			car.CUID
		)
	SELECT *,
		NULLIF(FLOS / ISNULL(NULLIF(Audits, 0), 1), 0) FacLosRate,
		NULLIF(Finj / ISNULL(NULLIF(Audits, 0), 1), 0) FacInjRate,
		NULLIF(FPROC / ISNULL(NULLIF(Audits, 0), 1), 0) FacProcRate,
		NULLIF((FLOS + Finj + FPROC) / ISNULL(NULLIF(FAvail, 0), 1), 0) FacRate,
		NULLIF(ObsProc / ISNULL(NULLIF(ObsProcAvail, 0), 1), 0) ObsProcRate,
		NULLIF(ObsInj / ISNULL(NULLIF(ObsInjAvail, 0), 1), 0) ObsInjRate,
		NULLIF(ObsHours / ISNULL(NULLIF(ObsHoursAvail, 0), 1), 0) ObsRate,
		NULLIF(PLOS / ISNULL(NULLIF(PA, 0), 1), 0) PhysLosRate,
		NULLIF(PProc / ISNULL(NULLIF(PPA, 0), 1), 0) PhysProcRate,
		NULLIF((PLOS + PProc) / ISNULL(NULLIF(PAvail, 0), 1), 0) PhysRate,
		NULLIF(Diag / ISNULL(NULLIF(DAvail, 0), 1), 0) DiagRate,
		NULLIF(Earned / ISNULL(NULLIF(Available, 0), 1), 0) Rate
	FROM CoderQASummary
	WHERE EXISTS (
			SELECT *
			FROM FACILITY_USER_AUTHORIZATION
			WHERE FACILITY_ID = CoderQASummary.FACILITY_ID
				AND USER_PROFILE_ID = @m_ReportUser
			)
	ORDER BY FNAME,
		Coder,
		CUID
END
GO
