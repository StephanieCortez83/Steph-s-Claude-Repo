SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 8/7/2013
-- Description:	SQL for the NetMD Unbilled Chart Reconciliation Report
-- =============================================
CREATE PROCEDURE [dbo].[rptNetMDUnbilledChartRecon]
	-- Add the parameters for the stored procedure here
	@Organization INT = -1,
  @FacilityID INT = -1,
  @ReportUser INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  DECLARE @m_Organization INT = @Organization;
  DECLARE @m_FacilityID INT = @FacilityID;
  DECLARE @m_ReportUser INT = @ReportUser;

  SELECT ur.[SERVICE_AGREEMENT_ID],
	  f.[ABBREVIATED_NAME] FACILITY,
	  ur.[FACILITY_CHART_ID],
	  UPPER(c.[PATIENT_LAST_NAME] + ', ' + c.[PATIENT_FIRST_NAME]) PATIENT_NAME,
	  c.[TIME_OF_SERVICE] DOS,
	  CASE 
		  WHEN c.[CHART_ID] IS NOT NULL
			  THEN CASE c.[CHART_STATUS_ID]
					  WHEN 1
						  THEN 'In Process'
					  WHEN 2
						  THEN 'Pending - ' + pr.[DESCRIPTION]
					  WHEN 3
						  THEN 'In Process'
					  WHEN 4
						  THEN 'In Process'
					  WHEN 5
						  THEN 'Posted ' + CONVERT(VARCHAR, c.[SENT_DATE], 110)
					  WHEN 6
						  THEN 'Removed'
					  WHEN 7
						  THEN 'Bypassed'
					  ELSE 'Mismatch'
					  END
		  ELSE 'Not Found in ACS'
		  END RECON_STATUS,
	  ur.[STATUS_CODE],
	  ur.[RECEIVED],
	  ur.[FACILITY_TYPE],
	  ISNULL((
			  SELECT MAX([CREATION_DATE_TIME])
			  FROM vwImportImage WITH (NOLOCK)
			  WHERE [CHART_ID] = c.[CHART_ID]
			  ), (
			  SELECT MAX([CREATION_DATE_TIME])
			  FROM vwImportImage WITH (NOLOCK)
			  WHERE SERVICE_AGREEMENT_ID = ur.[SERVICE_AGREEMENT_ID] 
          AND [FACILITY_CHART_ID] = ur.[FACILITY_CHART_ID]
			  )) LAST_IMAGE
  FROM CHART c WITH (NOLOCK)
    INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.[PATIENT_DISPOSITION_ID] = c.[PATIENT_DISPOSITION_ID]
    RIGHT JOIN NETMD_UNBILLED_CHART_RECONCILIATION ur WITH (NOLOCK) ON ur.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID] AND ur.[FACILITY_CHART_ID] = c.[FACILITY_CHART_ID]
    LEFT JOIN PENDING_REASON pr WITH (NOLOCK) ON pr.[PENDING_REASON_ID] = c.[PENDING_REASON_ID]
    LEFT JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON ur.[SERVICE_AGREEMENT_ID] = sa.[SERVICE_AGREEMENT_ID]
    LEFT JOIN FACILITY f WITH (NOLOCK) ON f.[FACILITY_ID] = sa.[FACILITY_ID] AND GETDATE() BETWEEN sa.[EFFECTIVE_DATE] AND sa.[EXPIRATION_DATE]
  WHERE sa.[COMPANY_ID] IN (54,55)
	  AND (
		  @m_Organization = - 1
		  OR @m_Organization = sa.[COMPANY_ID]
		  )
	  AND (
      @m_FacilityID = - 1
		  OR @m_FacilityID = sa.[FACILITY_ID]
		  )
	  AND EXISTS (
		  SELECT [FACILITY_ID]
		  FROM FACILITY_USER_AUTHORIZATION WITH (NOLOCK)
		  WHERE [USER_PROFILE_ID] = @m_ReportUser
			  AND [FACILITY_ID] = sa.[FACILITY_ID]
			  AND GETDATE() BETWEEN [EFFECTIVE_DATE]
				  AND [EXPIRATION_DATE]
		  )

  UNION

  SELECT sa.[SERVICE_AGREEMENT_ID],
	  f.[ABBREVIATED_NAME] FACILITY,
	  ii.[FACILITY_CHART_ID],
	  NULLIF(ii.[PATIENT_NAME], '') PATIENT_NAME,
	  NULLIF(ii.[DATE_OF_SERVICE], '') DOS,
	  'Not Found in ACS' [RECON_STATUS],
	  NULL [STATUS_CODE],
	  NULL [RECEIVED],
	  CASE 
		  WHEN sa.[COMPANY_ID] = 54
			  THEN 'Profee'
		  ELSE 'Facility'
		  END [FACILITY_TYPE],
	  ii.[CREATION_DATE_TIME] LAST_IMAGE
  FROM vwImportImage ii WITH (NOLOCK)
    INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK)	ON ii.[SERVICE_AGREEMENT_ID] = sa.[SERVICE_AGREEMENT_ID]
    INNER JOIN FACILITY f WITH (NOLOCK)	ON f.FACILITY_ID = sa.FACILITY_ID
  WHERE ii.CHART_ID = - 1
	  AND sa.[COMPANY_ID] IN (54, 55)
	  AND (
		  @m_Organization = - 1
		  OR @m_Organization = sa.[COMPANY_ID]
		  )
	  AND (
      @m_FacilityID = - 1
		  OR @m_FacilityID = sa.[FACILITY_ID]
		  )
	  AND ii.[CREATION_DATE_TIME] >= sa.[EFFECTIVE_DATE]
	  AND ii.[CREATION_DATE_TIME] >= '7/25/2013'
	  AND NOT EXISTS (
		  SELECT *
		  FROM NETMD_UNBILLED_CHART_RECONCILIATION WITH (NOLOCK)
		  WHERE [SERVICE_AGREEMENT_ID] = sa.[SERVICE_AGREEMENT_ID]
			  AND [FACILITY_CHART_ID] = ii.[FACILITY_CHART_ID]
		  )
	  AND EXISTS (
		  SELECT [FACILITY_ID]
		  FROM FACILITY_USER_AUTHORIZATION WITH (NOLOCK)
		  WHERE [USER_PROFILE_ID] = @m_ReportUser
			  AND [FACILITY_ID] = sa.[FACILITY_ID]
			  AND GETDATE() BETWEEN [EFFECTIVE_DATE]
				  AND [EXPIRATION_DATE]
		  )
  ORDER BY FACILITY_TYPE,
    FACILITY,
	  RECON_STATUS,
	  DOS,
	  FACILITY_CHART_ID
END




GO
GRANT EXECUTE ON  [dbo].[rptNetMDUnbilledChartRecon] TO [dbx_ExecuteReportProcs]
GO
