SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 7/8/2013
-- Description:	SQL for CPT Frequency by Physician report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_CptFrequencyByPhysician]
@StartDate date, @ThruDate date, @Organization int, @Facility varchar(MAX)
WITH EXEC AS CALLER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  DECLARE @m_StartDate DATE = @StartDate;
  DECLARE @m_ThruDate DATE = @ThruDate;
  DECLARE @m_Organization INT = @Organization;
  DECLARE @m_Facility VARCHAR(MAX) = @Facility;

  SELECT f.NAME Facility,
   case when fp.EMPLOYEE_IDENTIFIER is NULL Then 'Unknown'
	   else fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.MIDDLE_NAME end as  Physician,	  

	  fp.EMPLOYEE_IDENTIFIER 'Physician ID',
	  x.DOS_Year 'Year',
	  x.DOS_Month 'Month',
	  x.CPT,
	  x.Class 'Type',
	  x.SIM,
	  x.Units,
	  x.Procedures
  FROM FACILITY f WITH (NOLOCK),	  
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
		  WHERE @m_Organization IN (-1, sa.COMPANY_ID)
        AND c.FACILITY_ID IN (SELECT * FROM SPLITSTRING(@m_Facility, ','))
			  AND DATEADD(DAY, DATEDIFF(DAY, 0, sp.TIME_OF_SERVICE), 0) BETWEEN @m_StartDate AND @m_ThruDate
			  and sp.CLASS <> 'PL'
		  GROUP BY c.FACILITY_ID,
			  YEAR(sp.TIME_OF_SERVICE),
			  MONTH(sp.TIME_OF_SERVICE),
			  sp.PHYSICIAN_ID,
			  sp.CPT_CODE,
			  sp.CLASS,
			  sp.BILLING_CODE

UNION

			
			SELECT c.FACILITY_ID,
			  YEAR(sp.TIME_OF_SERVICE) DOS_Year,
			  MONTH(sp.TIME_OF_SERVICE) DOS_Month,

			  CASE 
            WHEN c.NURSE_PRACTITIONER_ID > 0
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
            ELSE c.PHYSICIAN_ID
            END as PHYSICIAN_ID,

--			  sp.PHYSICIAN_ID,
			  sp.CPT_CODE CPT,
			  sp.CLASS,
			  sp.BILLING_CODE SIM,
			  SUM(sp.QUANTITY) Units,
			  COUNT(*) Procedures
		  FROM SENT_PROCEDURE sp WITH (NOLOCK)
		    INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK)	ON sa.SERVICE_AGREEMENT_ID = sp.SERVICE_AGREEMENT_ID
			  INNER JOIN CHART c WITH(NOLOCK) ON c.CHART_ID=sp.CHART_ID AND c.CHART_STATUS_ID=5
		  WHERE @m_Organization IN (-1, sa.COMPANY_ID)
        AND c.FACILITY_ID IN (SELECT * FROM SPLITSTRING(@m_Facility, ','))
			  AND DATEADD(DAY, DATEDIFF(DAY, 0, sp.TIME_OF_SERVICE), 0) BETWEEN @m_StartDate AND @m_ThruDate
			  and sp.CLASS = 'PL'
		  GROUP BY c.FACILITY_ID,
			  YEAR(sp.TIME_OF_SERVICE),
			  MONTH(sp.TIME_OF_SERVICE),
			  CASE 
              WHEN c.NURSE_PRACTITIONER_ID > 0
                AND (
                    c.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
                    OR c.PROVIDER_EVAL_PERFORMED_BY_IND = 1
                    )
                THEN c.NURSE_PRACTITIONER_ID
               ELSE c.PHYSICIAN_ID
               END,
			  sp.CPT_CODE,
			  sp.CLASS,
			  sp.BILLING_CODE

		  ) x
  -- DAH 12/22/2016 ACS-8791 Changed to outer join to list CPT Code when no physician available.
 left outer join FACILITY_PROFESSIONAL fp WITH (NOLOCK) on fp.FACILITY_PROF_ID = x.PHYSICIAN_ID 
  WHERE x.FACILITY_ID = f.FACILITY_ID	
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
GRANT EXECUTE ON  [dbo].[rpt_CptFrequencyByPhysician] TO [dbx_ExecuteReportProcs]
GO
