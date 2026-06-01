SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 7/24/2013
-- Description:	Returns a list of charts that are Approved and ready to send but are awaiting
--              inbound demographic data from the workflow database.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_EROneNetMD_ApprovedChartsAwaitingInboundDemographic]
  @ReportUser int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  DECLARE @m_ReportUser INT = @ReportUser;

  SELECT f.[NAME] FACILITY,
	  c.FACILITY_CHART_ID,
	  c.TIME_OF_SERVICE,
	  c.APPROVED_DATE
  FROM CHART c
    JOIN SERVICE_AGREEMENT sa	ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    JOIN FACILITY f	ON f.FACILITY_ID = sa.FACILITY_ID
  WHERE sa.COMPANY_ID IN (54,55)
	  AND CHART_STATUS_ID = 4
    AND EXISTS (
      SELECT *
      FROM FACILITY_USER_AUTHORIZATION fua
      WHERE fua.FACILITY_ID=c.FACILITY_ID
        AND fua.USER_PROFILE_ID=@m_ReportUser
        AND GETDATE() BETWEEN fua.EFFECTIVE_DATE AND fua.EXPIRATION_DATE
    )
	  AND NOT EXISTS (
		  SELECT *
		  FROM RCM_FLATFILE_INBOUND_DEMOGRAPHICS_NETMD
		  WHERE RCM_HospitalCode = f.FACILITY_NUMBER
			  AND FILE_AccountId = c.FACILITY_CHART_ID
		  )
  ORDER BY f.[NAME], c.APPROVED_DATE
END


GO
GRANT EXECUTE ON  [dbo].[rpt_EROneNetMD_ApprovedChartsAwaitingInboundDemographic] TO [dbx_ExecuteReportProcs]
GO
