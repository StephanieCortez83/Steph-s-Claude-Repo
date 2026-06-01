SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 7/8/2013
-- Description:	SQL for CPT Frequency by Physician report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_CCHMC-CptFrequencyByPhysician]
@StartDate date, @ThruDate date, @Organization int
WITH EXEC AS CALLER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  DECLARE @m_StartDate DATE = @StartDate;
  DECLARE @m_ThruDate DATE = @ThruDate;
  DECLARE @m_Organization INT = @Organization;

  SELECT f.NAME Facility,
	  fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME Physician,
	  fp.EMPLOYEE_IDENTIFIER 'Physician ID',
	  x.DOS_Year 'Year',
	  x.DOS_Month 'Month',
	  x.CPT,
	  x.Class 'Type',
	  x.SIM,
	  x.Units,
	  x.Procedures
  FROM FACILITY f WITH (NOLOCK),
	  FACILITY_PROFESSIONAL fp WITH (NOLOCK),
	  (
		  SELECT c.FACILITY_ID,
			  YEAR(sp.TIME_OF_SERVICE) DOS_Year,
			  MONTH(sp.TIME_OF_SERVICE) DOS_Month,
			  sp.PHYSICIAN_ID,
			  sp.CPT_CODE CPT,
			  sp.CLASS,
			  sp.BILLING_CODE SIM,
			  SUM(sp.QUANTITY) Units,
			  COUNT(*) Procedures
		  FROM SENT_PROCEDURE sp WITH (NOLOCK)
		    INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK)	ON sa.SERVICE_AGREEMENT_ID = sp.SERVICE_AGREEMENT_ID
			  INNER JOIN CHART c WITH(NOLOCK) ON c.CHART_ID=sp.CHART_ID AND c.CHART_STATUS_ID=5
		  WHERE sa.COMPANY_ID = @m_Organization
			  AND DATEADD(DAY, DATEDIFF(DAY, 0, sp.TIME_OF_SERVICE), 0) BETWEEN @m_StartDate AND @m_ThruDate
		  GROUP BY c.FACILITY_ID,
			  YEAR(sp.TIME_OF_SERVICE),
			  MONTH(sp.TIME_OF_SERVICE),
			  sp.PHYSICIAN_ID,
			  sp.CPT_CODE,
			  sp.CLASS,
			  sp.BILLING_CODE
		  ) x
  WHERE x.FACILITY_ID = f.FACILITY_ID
	  AND fp.FACILITY_PROF_ID = x.PHYSICIAN_ID
  ORDER BY f.NAME,
	  x.DOS_Year,
	  x.DOS_Month,
	  fp.LAST_NAME,
	  fp.FIRST_NAME,
	  fp.MIDDLE_NAME,
	  x.CPT,
	  x.SIM
END
GO
GRANT EXECUTE ON  [dbo].[rpt_CCHMC-CptFrequencyByPhysician] TO [dbx_ExecuteReportProcs]
GO
