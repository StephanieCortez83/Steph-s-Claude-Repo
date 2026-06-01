SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		Don Hutton
-- Create date: 4/12/2016
-- Description:	Based on rpt_CoderQATrending , added CODER parameter
-- =============================================
CREATE PROCEDURE [dbo].[rpt_Coder_Scorecard_NEW] @StartDate DATETIME,
	@EndDate DATETIME,
	@TimeZone VARCHAR(MAX),
	@MonthView BIT = 0,
	@Facility VARCHAR(MAX),
	@UserGroup VARCHAR(MAX),
	@ReportUser INT,
	@CODER VARCHAR(MAX),
	@TimeInterval INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @m_ReportUser INT = @ReportUser;
	DECLARE @m_CODER VARCHAR(MAX) = @CODER;
	DECLARE @m_Facility VARCHAR(MAX) = @Facility;
	DECLARE @m_UserGroup VARCHAR(MAX) = @UserGroup;
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
	DECLARE @m_TimeInterval INT = @TimeInterval;

	WITH CoderQASUMmary
	AS (
		SELECT car.FACILITY_ID,
			car.FNAME,
			car.Coder,
			car.CUID CUID,
			car.[DATE],
			COUNT(*) Charts,
			CAST(SUM(car.Audits) AS DECIMAL) Audits,
			SUM(car.ObsAudits) ObsAudits,
			CAST(SUM(car.fa) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.OIA) + SUM(car.OPA) + SUM(car.OHA) + SUM(car.DEMA) AS DECIMAL) Available,
			SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) + SUM(car.OHE) + SUM(car.OPE) + SUM(car.OIE) + SUM(car.DEME) Earned,
			CAST(SUM(car.fa) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.OIA) + SUM(car.OPA) + SUM(car.OHA) AS DECIMAL) Available_NODEM,
			SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) + SUM(car.OHE) + SUM(car.OPE) + SUM(car.OIE) Earned_NODEM,
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
			CAST(SUM(car.OHA) AS DECIMAL) ObsHOURsAvail,
			CAST(SUM(car.OPA) AS DECIMAL) ObsProcAvail,
			SUM(car.OIE) ObsInj,
			SUM(car.OHE) ObsHOURs,
			SUM(car.OPE) ObsProc,
			CAST(SUM(car.DEMA) AS DECIMAL) DemoAvail,
			SUM(car.DEME) Demo,
      SUM(car.FA) FA,
      SUM(car.FPA) FPA,
      SUM(car.FIA) FIA
		FROM (
			SELECT car2.FACILITY_ID,
				car2.FNAME,
				car2.CNAME Coder,
				car2.CUID CUID,
				CASE @m_TimeInterval
					WHEN 0
						THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					WHEN 1
						THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), - 1)
					WHEN 2
						THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					WHEN 3
						THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					ELSE NULL
					END [DATE],
				1 Charts,
				car2.AUDITED Audits,
				(
					SELECT 1
					FROM chart c
					WHERE c.chart_id = car2.chart_id
						AND c.patient_disposition_id = 5
						AND sa.evaluate_observation_departments = 1
						AND c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = - 1
					) ObsAudits,
				car2.PA,
				car2.PPA,
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
				car2.OPE,
				car2.DEMA,
				car2.DEME
			FROM chart_audit_result car2 WITH (NOLOCK),
				user_profile up WITH (NOLOCK),
				chart c2 WITH (NOLOCK),
				service_agreement sa WITH (NOLOCK)
			WHERE DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.chart_id = c2.chart_id
				AND sa.service_agreement_id = c2.service_agreement_id
				AND car2.facility_id IN (
					SELECT *
					FROM dbo.SplitString(@m_Facility, ',')
					)
                AND car2.CUID IN (
					SELECT *
					FROM dbo.SplitString(@m_CODER, ',')
					)
				AND up.USER_PROFILE_ID = car2.CUID
				AND up.is_active = 'Y'
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
					SELECT *
					FROM dbo.SplitString(@m_UserGroup, ',')
					)
			
			UNION ALL
			
			SELECT car2.FACILITY_ID,
				car2.FNAME,
				car2.CNAME Coder,
				car2.CUID CUID,
				CASE @m_TimeInterval
					WHEN 0
						THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					WHEN 1
						THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), - 1)
					WHEN 2
						THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					WHEN 3
						THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					ELSE NULL
					END [DATE],
				1 Charts,
				car2.AUDITED Audits,
				0 ObsAudits,
				car2.PA,
				car2.PPA,
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
				0 OPE,
				car2.DEMA,
				car2.DEME
			FROM chart_audit_result car2 WITH (NOLOCK),
				user_profile up WITH (NOLOCK)
			WHERE DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.facility_id IN (
					SELECT *
					FROM dbo.SplitString(@m_Facility, ',')
					)
				AND car2.CUID IN (
					SELECT *
					FROM dbo.SplitString(@m_CODER, ',')
					)
				AND up.USER_PROFILE_ID = car2.CUID
				AND up.is_active = 'Y'
				AND (car2.obsUID > 0)
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)
				AND up.USER_GROUP_ID IN (
					SELECT *
					FROM dbo.SplitString(@m_UserGroup, ',')
					)
			
			UNION ALL
			
			SELECT car2.FACILITY_ID,
				car2.FNAME,
				car2.ObsName Coder,
				car2.ObsUID CUID,
				CASE @m_TimeInterval
					WHEN 0
						THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					WHEN 1
						THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), - 1)
					WHEN 2
						THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					WHEN 3
						THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					ELSE NULL
					END [DATE],
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
				car2.OPE,
				car2.DEMA,
				car2.DEME
			FROM chart_audit_result car2 WITH (NOLOCK),
				user_profile up WITH (NOLOCK)
			WHERE DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.facility_id IN (
					SELECT *
					FROM dbo.SplitString(@m_Facility, ',')
					)
                AND car2.CUID IN (
					SELECT *
					FROM dbo.SplitString(@m_CODER, ',')
					)
				AND up.USER_PROFILE_ID = car2.ObsUID
				AND up.is_active = 'Y'
				AND car2.obsUID > 0
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)
				AND up.USER_GROUP_ID IN (
					SELECT *
					FROM dbo.SplitString(@m_UserGroup, ',')
					)

      UNION ALL

      -- second audit  ****
      SELECT car2.FACILITY_ID,
              car2.FNAME,
              car2.CNAME Coder,
              car2.CUID CUID,
              CASE @m_TimeInterval
                    WHEN 0
                          THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
                    WHEN 1
                          THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), - 1)
                    WHEN 2
                          THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
                    WHEN 3
                          THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
                    ELSE NULL
                    END [DATE],
              1 Charts,
              car2.AUDITED Audits,
              (
                    SELECT 1
                    FROM chart c
                    WHERE c.chart_id = car2.chart_id
                          AND c.patient_disposition_id = 5
                          AND sa.evaluate_observation_departments = 1
                          AND c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = - 1
                    ) ObsAudits,
              car2.PA,
              car2.PPA,
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
              car2.OPE,
              car2.DEMA,
              car2.DEME
      FROM CHART_SECOND_LEVEL_AUDIT_RESULT car2 WITH (NOLOCK),
              user_profile up WITH (NOLOCK),
              chart c2 WITH (NOLOCK),
              service_agreement sa WITH (NOLOCK)
      WHERE DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0) BETWEEN @m_StartDate AND @m_EndDate
              AND car2.chart_id = c2.chart_id
              AND sa.service_agreement_id = c2.service_agreement_id
              AND car2.facility_id IN (
                    SELECT *
                    FROM dbo.SplitString(@m_Facility, ',')
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
              AND up.USER_GROUP_ID IN ( SELECT * FROM dbo.SplitString(@m_UserGroup, ',') )    --- commented for testing *****         


      UNION ALL 

      -- post-bill audit  ****
      SELECT c2.FACILITY_ID,
              f.NAME FNAME,
              up.LAST_NAME + ', ' + up.FIRST_NAME Coder,
              up.USER_PROFILE_ID CUID,
              CASE @m_TimeInterval
                    WHEN 0
                          THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.[POST_BILL_AUDIT_COMPLETED]))), 0)), 0)
                    WHEN 1
                          THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.[POST_BILL_AUDIT_COMPLETED]))), 0)), - 1)
                    WHEN 2
                          THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.[POST_BILL_AUDIT_COMPLETED]))), 0)), 0)
                    WHEN 3
                          THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.[POST_BILL_AUDIT_COMPLETED]))), 0)), 0)
                    ELSE NULL
                    END [DATE],
              1 Charts,
              1 Audits,
              0 ObsAudits,
              CASE WHEN [PHYSICIAN_SVC_ERROR] IS NULL THEN 0 ELSE 1 END AS PA,
              CASE WHEN [PHYSICIAN_PROCEDURE_ERROR] IS NULL THEN 0 ELSE 1 END AS PPA,
              CASE WHEN [DIAGNOSIS_ICD10_ERROR] IS NULL THEN 0 ELSE 1 END AS DA,
              CASE WHEN [FACILITY_SVC_ERROR] IS NULL THEN 0 ELSE 1 END AS FA,
              CASE WHEN [INFUSION_ERROR] IS NULL THEN 0 ELSE 1 END AS FIA,
              CASE WHEN [FACILITY_PROCEDURE_ERROR] IS NULL THEN 0 ELSE 1 END AS FPA,
              cast(coalesce([FACILITY_SVC_ERROR], 0) as int) as FLOSE,
              cast(coalesce([FACILITY_PROCEDURE_ERROR], 0) as int) as FPROCE,
              cast(coalesce([INFUSION_ERROR], 0) as int) as FINJE,
              cast(coalesce([PHYSICIAN_SVC_ERROR], 0) as int) as PLOSE,
              cast(coalesce([PHYSICIAN_PROCEDURE_ERROR], 0) as int) as PPROCE,
              cast(coalesce([DIAGNOSIS_ICD10_ERROR], 0) as int) as DE,
              CASE WHEN [OBSERVATION_INFUSIONS_ERROR] IS NULL THEN 0 ELSE 1 END AS OIA,
              CASE WHEN [OBSERVATION_HOURS_ERROR] IS NULL THEN 0 ELSE 1 END AS OHA,
              CASE WHEN [OBSERVATION_PROCEDURES_ERROR] IS NULL THEN 0 ELSE 1 END AS OPA,
              cast(coalesce([OBSERVATION_INFUSIONS_ERROR], 0) as int) as OIE,
              cast(coalesce([OBSERVATION_HOURS_ERROR], 0) as int) as OHE,
              cast(coalesce([OBSERVATION_PROCEDURES_ERROR], 0) as int) as OPE,
              CASE WHEN [DEMOGRAPHIC_ERROR] IS NULL THEN 0 ELSE 1 END AS DEMA,
              cast(coalesce([DEMOGRAPHIC_ERROR], 0) as int) as DEME
      FROM [dbo].[CHART_POST_BILL_AUDIT_REVIEW] cpbar WITH (NOLOCK),
              user_profile up WITH (NOLOCK),
              chart c2 WITH (NOLOCK),
              service_agreement sa WITH (NOLOCK),
              FACILITY f WITH (NOLOCK)
      WHERE DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.APPROVED_DATE))), 0) BETWEEN @m_StartDate AND @m_EndDate
              AND cpbar.chart_id = c2.chart_id
              AND sa.service_agreement_id = c2.service_agreement_id
              and f.FACILITY_ID = c2.FACILITY_ID
              AND c2.facility_id IN (
                    SELECT *
                    FROM dbo.SplitString(@m_Facility, ',')
                    )
              AND up.USER_PROFILE_ID = c2.[COMPLETED_BY_USER_PROFILE_ID]
              AND up.USER_CLASS_CD IN (
                    1,
                    2,
                    4,
                    5
                    )
              AND up.USER_GROUP_ID IN ( SELECT * FROM dbo.SplitString(@m_UserGroup, ',') )
			) car
		GROUP BY car.FACILITY_ID,
			car.FNAME,
			car.Coder,
			car.CUID,
			car.[DATE]
		)
	SELECT FACILITY_ID,
		FNAME,
		Coder,
		CUID CUID,
		[DATE],
		Charts,
		Audits,
		Audits / Charts AuditRate,
		ObsAudits,
		Available,
		Earned,
		Available_NODEM,
		Earned_NODEM,
		FAvail,
		PAvail,
		PA,
		PPA,
		DAvail,
		FLOS,
		FProc,
		FInj,
		PLOS,
		PProc,
		Diag,
		ObsInjAvail,
		ObsHoursAvail,
		ObsProcAvail,
		ObsInj,
		ObsHours,
		ObsProc,
		DemoAvail,
		Demo,
		NULLIF(FLOS / ISNULL(NULLIF(Audits, 0), 1), 0) FacLosRate,
		NULLIF(Finj / ISNULL(NULLIF(Audits, 0), 1), 0) FacInjRate,
		NULLIF(FPROC / ISNULL(NULLIF(Audits, 0), 1), 0) FacProcRate,
		NULLIF((FLOS + Finj + FPROC) / ISNULL(NULLIF(FAvail, 0), 1), 0) FacRate,
		NULLIF(ObsProc / ISNULL(NULLIF(ObsProcAvail, 0), 1), 0) ObsProcRate,
		NULLIF(ObsInj / ISNULL(NULLIF(ObsInjAvail, 0), 1), 0) ObsInjRate,
		NULLIF(ObsHOURs / ISNULL(NULLIF(ObsHOURsAvail, 0), 1), 0) ObsRate,
		NULLIF(PLOS / ISNULL(NULLIF(PA, 0), 1), 0) PhysLosRate,
		NULLIF(PProc / ISNULL(NULLIF(PPA, 0), 1), 0) PhysProcRate,
		NULLIF((PLOS + PProc) / ISNULL(NULLIF(PAvail, 0), 1), 0) PhysRate,
		NULLIF(Diag / ISNULL(NULLIF(DAvail, 0), 1), 0) DiagRate,
		NULLIF(Demo / ISNULL(NULLIF(DemoAvail, 0), 1), 0) DemoRate,
		NULLIF(Earned / ISNULL(NULLIF(Available, 0), 1), 0) Rate,
		NULLIF(Earned_NODEM / ISNULL(NULLIF(Available_NODEM, 0), 1), 0) Rate_NODEM,
    FA,
    FPA,
    FIA
	FROM CoderQASummary
	WHERE EXISTS (
			SELECT *
			FROM FACILITY_USER_AUTHORIZATION
			WHERE FACILITY_ID = CoderQASUMmary.FACILITY_ID
				AND USER_PROFILE_ID = @ReportUser
			)
	ORDER BY Coder,
		CUID,
		FNAME,
		[DATE]
  OPTION (RECOMPILE);
END






GO
