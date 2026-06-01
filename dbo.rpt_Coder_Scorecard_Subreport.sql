SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Don Hutton
-- Create date: 4/12/2016
-- Description:	Based on rpt_CoderQATrending 
-- =============================================
CREATE PROCEDURE [dbo].[rpt_Coder_Scorecard_Subreport] @StartDate DATETIME,
	@EndDate DATETIME,
	@TimeZone VARCHAR(MAX),
	@MonthView BIT = 0,
	@Facility VARCHAR(8000),
	@UserGroup VARCHAR(8000),
	@ReportUser INT,
	@CODER int,
	@TimeInterval INT = NULL,
	@PostBill VARCHAR(MAX),
	@Disposition VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	set transaction isolation level read uncommitted	
	SET NOCOUNT ON;

	DECLARE @m_ReportUser INT = @ReportUser;
	DECLARE @m_Facility VARCHAR(8000) = @Facility;
	DECLARE @m_UserGroup VARCHAR(8000) = @UserGroup;
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
    DECLARE @m_CODER int = @CODER;
	DECLARE @m_TimeInterval INT = @TimeInterval;
	DECLARE @m_PostBill VARCHAR(MAX) = @PostBill;
	DECLARE @m_Disposition VARCHAR(MAX) = @Disposition;



	if object_id('TempDB..#coder', 'U') is not null drop table #coder


select distinct t1.USER_PROFILE_ID, t1.last_name, t1.first_name				
into #coder				
from  				
		(
		SELECT USER_PROFILE_ID, last_name, first_name				
		FROM USER_PROFILE				
		WHERE is_active = 'Y'			
		and USER_PROFILE_ID	in ( SELECT items FROM dbo.SplitString(@m_CODER, ',') )
		and ( USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) 
		or -1 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) )
		
		
				
		UNION				
				
		SELECT up.USER_PROFILE_ID, up.last_name, up.first_name								
		FROM USER_GROUP_TO_USER_PROFILE ugup,				
		user_profile up				
		where up.user_profile_id = ugup.user_profile_id				
		and up.is_active = 'Y'				
		and ugup.USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_CODER, ',') )
		and ( ugup.USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) 
		or -1 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) )		
		) t1


create nonclustered index idx_USER_PROFILE_ID on #coder (USER_PROFILE_ID);


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
				chart c2 WITH (NOLOCK),
				service_agreement sa WITH (NOLOCK)
			WHERE DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0) BETWEEN @m_StartDate AND @m_EndDate
				and 0 IN ( SELECT * FROM dbo.SplitString (@m_PostBill, ',') )  
				AND car2.chart_id = c2.chart_id
				AND sa.service_agreement_id = c2.service_agreement_id
				AND ( car2.facility_id IN ( SELECT * FROM dbo.SplitString(@m_Facility, ','))
				    or '-1' IN ( SELECT * FROM dbo.SplitString(@m_Facility, ','))     )
	
				AND car2.CUID IN (select user_profile_id from #coder)
				AND ( 
			      c2.PATIENT_DISPOSITION_ID IN ( SELECT * FROM dbo.SplitString (@m_Disposition, ',') )  				
				  or 
				  -99 IN ( SELECT * FROM dbo.SplitString (@m_Disposition, ',') )  
				   )			  
			
			


      UNION ALL 

      -- post-bill audit  ****
      SELECT c2.FACILITY_ID,
              f.NAME FNAME,
              #coder.LAST_NAME + ', ' + #coder.FIRST_NAME Coder,
              #coder.USER_PROFILE_ID CUID,
              CASE @m_TimeInterval
                    WHEN 0
                          THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED))), 0)), 0)
                    WHEN 1
                          THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED))), 0)), - 1)
                    WHEN 2
                          THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED))), 0)), 0)
                    WHEN 3
                          THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED))), 0)), 0)
                    ELSE NULL
                    END [DATE],
              1 Charts,
			  CASE when c2.POST_BILL_AUDIT_COMPLETED is null THEN 0 ELSE 1 END Audits,              
              0 ObsAudits,
              CASE WHEN PHYSICIAN_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS PA,
			  CASE WHEN PHYSICIAN_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS PPA,
			  CASE WHEN DIAGNOSIS_ICD10_ERROR IS NULL THEN 0 ELSE 1 END AS DA,
			  CASE WHEN FACILITY_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS FA ,
			  CASE WHEN INFUSION_ERROR IS NULL THEN 0 ELSE 1 END AS FIA ,
			  CASE WHEN FACILITY_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS FPA,
			  CASE when FACILITY_SVC_ERROR = 1 then 0 
	               when FACILITY_SVC_ERROR is null then 0
	               else 1 end as FLOSE ,
			  CASE when FACILITY_PROCEDURE_ERROR = 1 then 0 
	               when FACILITY_PROCEDURE_ERROR is null then 0
	               else 1 end as FPROCE , 
			  CASE when INFUSION_ERROR = 1 then 0 
	               when INFUSION_ERROR is null then 0
	               else 1 end as FINJE ,
			  CASE when PHYSICIAN_SVC_ERROR = 1 then 0 
	               when PHYSICIAN_SVC_ERROR is null then 0
	               else 1 end as PLOSE ,
			  CASE when PHYSICIAN_PROCEDURE_ERROR = 1 then 0 
	               when PHYSICIAN_PROCEDURE_ERROR is null then 0
	               else 1 end as PPROCE , 
			  CASE when DIAGNOSIS_ICD10_ERROR = 1 then 0 
	               when DIAGNOSIS_ICD10_ERROR is null then 0
	               else 1 end as DE ,
			  CASE WHEN OBSERVATION_INFUSIONS_ERROR IS NULL THEN 0 ELSE 1 END AS OIA ,
			  CASE WHEN OBSERVATION_HOURS_ERROR IS NULL THEN 0 ELSE 1 END AS OHA ,
			  CASE WHEN OBSERVATION_PROCEDURES_ERROR IS NULL THEN 0 ELSE 1 END AS OPA,
			  CASE when OBSERVATION_INFUSIONS_ERROR = 1 then 0 
	               when OBSERVATION_INFUSIONS_ERROR is null then 0
	               else 1 end  as OIE ,
			  CASE when OBSERVATION_HOURS_ERROR = 1 then 0 
	               when OBSERVATION_HOURS_ERROR is null then 0
	               else 1 end as OHE ,
			  CASE when OBSERVATION_PROCEDURES_ERROR = 1 then 0 
	               when OBSERVATION_PROCEDURES_ERROR is null then 0
	               else 1 end as OPE ,
			  CASE WHEN DEMOGRAPHIC_ERROR IS NULL THEN 0 ELSE 1 END AS DEMA ,
			  CASE when DEMOGRAPHIC_ERROR = 1 then 0 
	               when DEMOGRAPHIC_ERROR is null then 0
	               else 1 end as DEME 
      FROM [dbo].[CHART_POST_BILL_AUDIT_REVIEW] cpbar WITH (NOLOCK),
              #coder,
              chart c2 WITH (NOLOCK),
              service_agreement sa WITH (NOLOCK),
              FACILITY f WITH (NOLOCK)
      WHERE DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED))), 0) BETWEEN @m_StartDate AND @m_EndDate
              AND cpbar.chart_id = c2.chart_id
              AND sa.service_agreement_id = c2.service_agreement_id
              AND f.FACILITY_ID = c2.FACILITY_ID
			  AND c2.POST_BILL_AUDIT_COMPLETED is not null
			  AND c2.COMPLETED_BY_USER_PROFILE_ID = #coder.user_profile_id
			  AND 1 IN ( SELECT * FROM dbo.SplitString (@m_PostBill, ',') )  -- include Post Bill Audit Data.
              AND ( c2.facility_id IN ( SELECT * FROM dbo.SplitString(@m_Facility, ','))
				    or '-1' IN ( SELECT * FROM dbo.SplitString(@m_Facility, ','))     )		

              AND ( 
			      c2.PATIENT_DISPOSITION_ID IN ( SELECT * FROM dbo.SplitString (@m_Disposition, ',') )  				
				  or 
				  -99 IN ( SELECT * FROM dbo.SplitString (@m_Disposition, ',') )  
				   )			  

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
		CAST( ROUND(FLOS * 1.00 / ISNULL(NULLIF(FA, 0), 1) , 3) AS FLOAT) as FacLosRate,
        CAST( ROUND(Finj * 1.00 / ISNULL(NULLIF(FIA, 0), 1) , 3) AS FLOAT) as FacInjRate,
        CAST( ROUND(FPROC * 1.00 / ISNULL(NULLIF(FPA, 0), 1) , 3) AS FLOAT) as FacProcRate,
		(FLOS + Finj + FPROC) / ISNULL(NULLIF(FAvail, 0), 1) FacRate,
		ObsProc / ISNULL(NULLIF(ObsProcAvail, 0), 1) ObsProcRate,
		ObsInj / ISNULL(NULLIF(ObsInjAvail, 0), 1) ObsInjRate,
		ObsHOURs / ISNULL(NULLIF(ObsHOURsAvail, 0), 1) ObsRate,
		PLOS / ISNULL(NULLIF(PA, 0), 1) PhysLosRate,
		PProc / ISNULL(NULLIF(PPA, 0), 1) PhysProcRate,
		(PLOS + PProc) / ISNULL(NULLIF(PAvail, 0), 1) PhysRate,
		Diag / ISNULL(NULLIF(DAvail, 0), 1) DiagRate,
		Demo / ISNULL(NULLIF(DemoAvail, 0), 1) DemoRate,
		Earned / ISNULL(NULLIF(Available, 0), 1) Rate,
		Earned_NODEM / ISNULL(NULLIF(Available_NODEM, 0), 1) Rate_NODEM,
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
GRANT EXECUTE ON  [dbo].[rpt_Coder_Scorecard_Subreport] TO [dbx_ExecuteReportProcs]
GO
