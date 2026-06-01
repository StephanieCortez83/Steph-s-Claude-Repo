SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 10/15/2013
-- Description:	SQL for report Patient Appears to Qualify for Critical Care-No Time Documented by Provider
-- =============================================
CREATE PROCEDURE [dbo].[rpt_PatientAppearsToQualifyCriticalCare] 
	-- Add the parameters for the stored procedure here
  @Facility INT,
  @ReportUser INT,
	@StartDate DATE,
  @ThruDate DATE = NULL,
  @DateType INT = 0, -- Default to DOS
  @ProviderBusinessUnit varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  -- Insert statements for procedure here
  DECLARE @m_Facility INT = @Facility;
  DECLARE @m_ReportUser INT = @ReportUser;
  DECLARE @m_StartDate DATE = @StartDate;
  DECLARE @m_ThruDate DATE = ISNULL(@ThruDate, @StartDate);
  DECLARE @m_DateType INT = @DateType;
  DECLARE @m_ProviderBusinessUnit varchar(50) = @ProviderBusinessUnit;

  SELECT facility_chart_id,
	  FACILITY.[NAME] FacilityName,
	  PATIENT_LAST_NAME + ', ' + PATIENT_FIRST_NAME PatientName,
	  TIME_OF_SERVICE DOS,
	  LAST_NAME + ', ' + FIRST_NAME ProviderName,
	  CHART.PHYSICIAN_SERVICE_PROC_ID,
	  CPT_CODE,
	  APPEARS_TO_QUALIFY_FOR_CRITICAL_CARE,
	  fp.provider_business_unit_id
  FROM CHART WITH (NOLOCK)
  INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON 
  --FACILITY_PROFESSIONAL.FACILITY_PROF_ID = CHART.PHYSICIAN_ID
  fp.FACILITY_PROF_ID = CASE 
            WHEN CHART.NURSE_PRACTITIONER_ID > 0
                AND (
                    CHART.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR CHART.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN CHART.NURSE_PRACTITIONER_ID
            ELSE CHART.PHYSICIAN_ID
            END

  INNER JOIN PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK) ON PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CHART.PHYSICIAN_SERVICE_PROC_ID
  

  INNER JOIN FACILITY WITH (NOLOCK) ON FACILITY.FACILITY_ID = CHART.FACILITY_ID
  WHERE PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = CHART.SERVICE_AGREEMENT_ID
	  AND CHART.FACILITY_ID = @m_Facility
    AND CHART.CHART_STATUS_ID IN (4,5)
    AND APPEARS_TO_QUALIFY_FOR_CRITICAL_CARE = 1
	  AND (
		  (
			  @m_DateType = 0
			  AND DATEADD(DAY, DATEDIFF(DAY, 0, TIME_OF_SERVICE), 0) BETWEEN @m_StartDate AND @m_ThruDate
			  )
		  OR (
			  @m_DateType = 1
			  AND DATEADD(DAY, DATEDIFF(DAY, 0, SENT_DATE), 0) BETWEEN @m_StartDate AND @m_ThruDate
			  )
		  )
	  AND EXISTS (
		  SELECT *
		  FROM FACILITY_USER_AUTHORIZATION
		  WHERE USER_PROFILE_ID = @m_ReportUser
			  AND FACILITY_ID = @m_Facility
			  AND DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
		  )

	  AND (fp.provider_business_unit_id in (SELECT * FROM SPLITSTRING(@m_ProviderBusinessUnit, ','))
	      OR '-999' in (SELECT * FROM SPLITSTRING(@m_ProviderBusinessUnit, ','))
	      ) 
  ORDER BY CHART.TIME_OF_SERVICE
END





GO
GRANT EXECUTE ON  [dbo].[rpt_PatientAppearsToQualifyCriticalCare] TO [dbx_ExecuteReportProcs]
GO
