SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 6/27/2013
-- Description:	Reports the facility service points for accounts with Child Life points selected.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ChildLifePoints]
  @ReportUser INT,
  @DOSFrom DATE,
  @DOSThru DATE,
  @Organization INT,
  @Facility INT = -1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  DECLARE @m_ReportUser INT = @ReportUser;
  DECLARE @m_DOSFrom DATE = @DOSFrom;
  DECLARE @m_DOSThru DATE = @DOSThru;
  DECLARE @m_Organization INT = @Organization;
  DECLARE @m_Facility INT = @Facility;

  WITH ChildLifeCharts
  AS (
	  SELECT DISTINCT sp.[CHART_ID]
	  FROM SENT_PROCEDURE sp WITH(NOLOCK)
	    INNER JOIN SERVICE_AGREEMENT sa WITH(NOLOCK) ON sa.[SERVICE_AGREEMENT_ID] = sp.[SERVICE_AGREEMENT_ID]
	    INNER JOIN FACILITY_SERVICE_EVALUATION fse WITH(NOLOCK) ON fse.[CHART_ID] = sp.[CHART_ID]
	    INNER JOIN FACILITY_SERVICE fs WITH(NOLOCK) ON fs.[FACILITY_SERVICE_ID] = fse.[FACILITY_SERVICE_ID]
	  WHERE sa.[DEMO_TEST_SITE_IND] = 0
		  AND sa.[EVALUATE_FACILITY_SVC] = 1
		  AND sa.[COMPANY_ID] = @m_Organization
      AND (@m_Facility = -1 OR sa.[FACILITY_ID] = @m_Facility)
		  AND sp.[CLASS] = 'FL'
		  AND fs.[DESCRIPTION] LIKE ('%Child Life%')
		  AND dateadd(day, datediff(day, 0, sp.[TIME_OF_SERVICE]), 0) BETWEEN @m_DOSFrom	AND @m_DOSThru
	  )
  SELECT f.[NAME] [Facility],
	       sp.[FACILITY_CHART_ID] [Account],
	       c.[PATIENT_LAST_NAME] + ', ' + c.[PATIENT_FIRST_NAME] [PatientName],
         sp.[TIME_OF_SERVICE] [DOS],
	       sp.[CPT_CODE] [Level],
	       fs.[DESCRIPTION] [Description],
	       fs.[MAX_POINTS] [Points]
  FROM SENT_PROCEDURE sp WITH(NOLOCK)
    INNER JOIN CHART c WITH(NOLOCK) ON c.[CHART_ID] = sp.[CHART_ID]
    INNER JOIN ChildLifeCharts clc WITH(NOLOCK) ON clc.[CHART_ID] = sp.[CHART_ID]
    INNER JOIN FACILITY f WITH(NOLOCK) ON f.[FACILITY_ID] = sp.[FACILITY_ID]
    INNER JOIN FACILITY_SERVICE_EVALUATION fse WITH(NOLOCK)	ON fse.[CHART_ID] = sp.[CHART_ID]
    INNER JOIN FACILITY_SERVICE fs WITH(NOLOCK) ON fs.[FACILITY_SERVICE_ID] = fse.[FACILITY_SERVICE_ID]
  WHERE sp.[CLASS] = 'FL'
	  AND dateadd(day, datediff(day, 0, sp.[TIME_OF_SERVICE]), 0) BETWEEN @m_DOSFrom	AND @m_DOSThru
    AND f.FACILITY_ID IN (SELECT DISTINCT FACILITY_ID
                          FROM FACILITY_USER_AUTHORIZATION
                          WHERE USER_PROFILE_ID=@m_ReportUser)
  ORDER BY F.[NAME],
	  sp.[FACILITY_CHART_ID],
	  sp.[CPT_CODE],
	  fs.[MAX_POINTS]
END

GO
GRANT EXECUTE ON  [dbo].[rpt_ChildLifePoints] TO [dbx_ExecuteReportProcs]
GO
