SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[rpt_CoderQASummaryAllFacilities_SingleCoder_withObs] @StartDate DATETIME,
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
			CAST(SUM(car.OHA) AS DECIMAL) ObsHoursAvail,
			CAST(SUM(car.OHE) AS DECIMAL) ObsHours,
			CAST(SUM(car.OPA) AS DECIMAL) ObsProcAvail,
			CAST(SUM(car.OPE) AS DECIMAL) ObsProc,
			CAST(SUM(car.OIA) AS DECIMAL) ObsInjAvail,
			CAST(SUM(car.OIE) AS DECIMAL) ObsInj,
			SUM(car.ObsAudits) ObsAudits
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
				car2.OHA,
				car2.OHE,
				car2.OIA,
				car2.OIE,
				car2.OPA,
				car2.OPE,
				(
					SELECT 1
					FROM CHART c
					WHERE c.CHART_ID = car2.CHART_ID
						AND c.PATIENT_DISPOSITION_ID = 5
						AND sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1
						AND c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = - 1
					) ObsAudits
			FROM CHART_AUDIT_RESULT car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK),
				CHART c2 WITH (NOLOCK),
				SERVICE_AGREEMENT sa WITH (NOLOCK)
			WHERE 
				 convert(varchar, car2.APPROVED_DATE, 112) BETWEEN convert(varchar, @StartDate, 112) AND convert(varchar, @EndDate, 112)
				AND car2.CHART_ID = c2.CHART_ID
				AND sa.SERVICE_AGREEMENT_ID = c2.SERVICE_AGREEMENT_ID
				AND up.USER_PROFILE_ID = car2.CUID
				AND up.USER_PROFILE_ID = @m_UserProfileID
				--AND (
				--	car2.CUID = car2.obsUID
				--	OR car2.obsUID IS NULL
				--	OR car2.obsUID = 0
				--	)
				AND up.USER_CLASS_CD IN (
					1,
					2,
					4,
					5
					)

				UNION ALL
			SELECT 
				up.last_name + ', ' + up.first_name Coder,
				c2.completed_by_user_profile_id CUID,
				1 Charts,
				 CASE WHEN car2.FACILITY_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS FA,
				 CASE when car2.FACILITY_SVC_ERROR = 1 then 0 
					  when car2.FACILITY_SVC_ERROR is null then 0
					  else 1 end as FLOSE ,
				 CASE WHEN car2.INFUSION_ERROR IS NULL THEN 0 ELSE 1 END AS FIA,
				 CASE when car2.INFUSION_ERROR = 1 then 0 
					  when car2.INFUSION_ERROR is null then 0
					  else 1 end as FINJE ,
				 CASE WHEN car2.FACILITY_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS FPA,
				 CASE when car2.FACILITY_PROCEDURE_ERROR = 1 then 0 
					  when car2.FACILITY_PROCEDURE_ERROR is null then 0
					  else 1 end as FPROCE ,
				 CASE WHEN car2.PHYSICIAN_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS PA,
				 CASE when car2.PHYSICIAN_SVC_ERROR = 1 then 0 
					  when car2.PHYSICIAN_SVC_ERROR is null then 0
					  else 1 end as PLOSE ,
				 CASE WHEN car2.PHYSICIAN_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS PPA,
				 CASE when car2.PHYSICIAN_PROCEDURE_ERROR = 1 then 0 
					  when car2.PHYSICIAN_PROCEDURE_ERROR is null then 0
					  else 1 end as PPROCE , 
				 CASE WHEN car2.DIAGNOSIS_ICD10_ERROR IS NULL THEN 0 ELSE 1 END AS DA,	
				 CASE when car2.DIAGNOSIS_ICD10_ERROR = 1 then 0 
					  when car2.DIAGNOSIS_ICD10_ERROR is null then 0
					  else 1 end as DE ,
				 CASE WHEN car2.DEMOGRAPHIC_ERROR IS NULL THEN 0 ELSE 1 END AS DEMA ,
				 CASE when car2.DEMOGRAPHIC_ERROR = 1 then 0 
					  when car2.DEMOGRAPHIC_ERROR is null then 0
					  else 1 end as DEME ,
					1 Audits,
				 CASE WHEN car2.OBSERVATION_HOURS_ERROR IS NULL THEN 0 ELSE 1 END AS OHA ,
  				 CASE when car2.OBSERVATION_HOURS_ERROR = 1 then 0 
					  when car2.OBSERVATION_HOURS_ERROR is null then 0
					  else 1 end as OHE ,
				 CASE WHEN car2.OBSERVATION_INFUSIONS_ERROR IS NULL THEN 0 ELSE 1 END AS OIA ,
				 CASE when car2.OBSERVATION_INFUSIONS_ERROR = 1 then 0 
					  when car2.OBSERVATION_INFUSIONS_ERROR is null then 0
					  else 1 end  as OIE ,
				 CASE WHEN car2.OBSERVATION_PROCEDURES_ERROR IS NULL THEN 0 ELSE 1 END AS OPA,
				 CASE when car2.OBSERVATION_PROCEDURES_ERROR = 1 then 0 
					  when car2.OBSERVATION_PROCEDURES_ERROR is null then 0
					  else 1 end as OPE ,
				(
					SELECT 1
					FROM CHART c
					WHERE c.CHART_ID = car2.CHART_ID
						AND c.PATIENT_DISPOSITION_ID = 5
						AND sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1
						AND c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = - 1
					) ObsAudits
			FROM CHART_POST_BILL_AUDIT_REVIEW car2 WITH (NOLOCK),
				USER_PROFILE up WITH (NOLOCK),
				CHART c2 WITH (NOLOCK),
				SERVICE_AGREEMENT sa WITH (NOLOCK),
				FACILITY_USER_AUTHORIZATION fua with (NOLOCK)
			WHERE 
				car2.CHART_ID = c2.CHART_ID
				AND sa.SERVICE_AGREEMENT_ID = c2.SERVICE_AGREEMENT_ID
				AND up.USER_PROFILE_ID = @m_UserProfileID
				and  c2.completed_by_user_profile_id = up.user_profile_id
				and  c2.POST_BILL_AUDIT_COMPLETED is not null
				and  cast(c2.POST_BILL_AUDIT_COMPLETED as date)BETWEEN @StartDate AND @EndDate
				and  fua.user_profile_id = @m_UserProfileID
				and  fua.facility_id = c2.FACILITY_ID
				and  cast(c2.POST_BILL_AUDIT_COMPLETED as date) BETWEEN fua.EFFECTIVE_DATE AND fua.EXPIRATION_DATE
				and (FACILITY_SVC_ERROR = 1 or INFUSION_ERROR = 1 or FACILITY_PROCEDURE_ERROR = 1 or PHYSICIAN_SVC_ERROR =1 or PHYSICIAN_PROCEDURE_ERROR = 1 or DIAGNOSIS_ICD10_ERROR =1 
					or DEMOGRAPHIC_ERROR =1 or OBSERVATION_HOURS_ERROR = 1 or OBSERVATION_INFUSIONS_ERROR = 1 or OBSERVATION_PROCEDURES_ERROR = 1)


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
		NULLIF(ObsHours / ISNULL(NULLIF(ObsHoursAvail, 0), 1), 0) ObsRate,
		NULLIF(ObsInj / ISNULL(NULLIF(ObsInjAvail, 0), 1), 0) ObsInjRate,
		NULLIF(ObsProc / ISNULL(NULLIF(ObsProcAvail, 0), 1), 0) ObsProcRate
		
	FROM CoderQASummary

	ORDER BY 
		Coder,
		CUID
END



GO
GRANT EXECUTE ON  [dbo].[rpt_CoderQASummaryAllFacilities_SingleCoder_withObs] TO [dbx_ExecuteReportProcs]
GO
