SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 12/16/2014
-- Description:	SQL for the Midlevel Providers Assigned by Facility report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_MidlevelProvidersAssignedByFacility] 
	-- Add the parameters for the stored procedure here
  @Facilities VARCHAR(MAX),
	@StartDate DATETIME, 
	@EndDate DATETIME,
  @ReportUser INT,
  @DateType INT = 0,
  @FacilityChartID VARCHAR(25) = NULL,
  @Attending VARCHAR(MAX),
  @Midlevel VARCHAR(MAX),
  @ProFeeLevel VARCHAR(MAX),
  @FinancialClass VARCHAR(MAX) = '-1'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  DECLARE @m_Facilities VARCHAR(MAX) = @Facilities,
	  @m_StartDate DATETIME = @StartDate,
	  @m_EndDate DATETIME = DATEADD(DAY, 1, @EndDate),
    @m_ReportUser INT = @ReportUser,
    @m_DateType INT = @DateType,
    @m_FacilityChartID VARCHAR(25) = @FacilityChartID,
    @m_Attending VARCHAR(MAX) = @Attending,
    @m_Midlevel VARCHAR(MAX) = @Midlevel,
    @m_ProFeeLevel VARCHAR(MAX) = @ProFeeLevel,
    @m_FinancialClass VARCHAR(MAX) = @FinancialClass;

  SELECT FACILITY_CHART_ID 'Account Number',
	  TIME_OF_SERVICE 'Date of Service',
	  f.NAME 'Facility',
	  att.LAST_NAME + ', ' + att.FIRST_NAME 'Attending',
	  mlp.LAST_NAME + ', ' + mlp.FIRST_NAME 'Midlevel'
  FROM [dbo].CHART WITH (NOLOCK)
  INNER JOIN [dbo].FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = chart.FACILITY_ID
  INNER JOIN [dbo].FACILITY_PROFESSIONAL att WITH (NOLOCK) ON att.FACILITY_PROF_ID = chart.PHYSICIAN_ID
  INNER JOIN [dbo].FACILITY_PROFESSIONAL mlp WITH (NOLOCK) ON mlp.FACILITY_PROF_ID = chart.NURSE_PRACTITIONER_ID
  LEFT JOIN [dbo].PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK) ON psp.[PHYSICIAN_SERVICE_PROC_ID] = ISNULL(NULLIF(CHART.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID, -1), CHART.PHYSICIAN_SERVICE_PROC_ID)
  WHERE NURSE_PRACTITIONER_ID > 0
	  AND PHYSICIAN_ID > 0
	  AND PROVIDER_EVAL_PERFORMED_BY_IND IS NOT NULL
	  AND PROVIDER_EVAL_PERFORMED_BY_IND = 1
	  AND EXISTS (
		  SELECT *
		  FROM [dbo].SplitString(@m_Facilities, ',')
		  WHERE CHART.FACILITY_ID = ITEMS
		  )
	  AND CASE WHEN @m_DateType = 0 THEN TIME_OF_SERVICE ELSE SENT_DATE END >= @m_StartDate
	  AND CASE WHEN @m_DateType = 0 THEN TIME_OF_SERVICE ELSE SENT_DATE END < @m_EndDate
    AND ISNULL(NULLIF(@m_FacilityChartID, ''), CHART.FACILITY_CHART_ID) = CHART.FACILITY_CHART_ID
    AND EXISTS (
      SELECT *
      FROM [dbo].SplitString(@m_Attending, ';')
      WHERE ITEMS = (att.LAST_NAME + ', ' + att.FIRST_NAME)
    )
    AND EXISTS (
      SELECT *
      FROM [dbo].SplitString(@m_Midlevel, ';')
      WHERE ITEMS = (mlp.LAST_NAME + ', ' + mlp.FIRST_NAME)
    )
    AND EXISTS (
      SELECT *
      FROM [dbo].SplitString(@m_ProFeeLevel, ',')
      WHERE ITEMS = psp.SERVICE_LEVEL_CD
    )
    AND EXISTS (
      SELECT *
      FROM [dbo].SplitString(@m_FinancialClass, ',')
      WHERE ITEMS IN (CHART.FINANCIAL_CLASS_CD, '-1')
    )
	  AND CHART_STATUS_ID IN (
		  3,
		  4,
		  5
		  )
  ORDER BY FACILITY,
	  TIME_OF_SERVICE
END

GO
GRANT EXECUTE ON  [dbo].[rpt_MidlevelProvidersAssignedByFacility] TO [dbx_ExecuteReportProcs]
GO
