SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 9/17/2014
-- Description:	Billing report distribution details
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListBillingReportDistribution]
	-- Add the parameters for the stored procedure here
	@ReportName VARCHAR(50),
	@Group INT = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	DECLARE @m_ReportName VARCHAR(50) = @ReportName,
		@m_Group INT = @Group;

	SELECT FACILITY.FACILITY_ID,
		(
			SELECT MAX(BILLING_CONTROL_ID)
			FROM [BILLING_CONTROL]
			WHERE STATUS_CD = 'I'
				AND BILLING_CONTROL_ID < (
					SELECT BILLING_CONTROL_ID
					FROM [BILLING_CONTROL]
					WHERE STATUS_CD = 'A'
					)
			) BILLING_CONTROL_ID,
		RECIPIENTS_TO,
		RECIPIENTS_CC,
		RECIPIENTS_BCC,
		'Susan.Bunn@CorroHealth.com' REPLY_TO,
		REPORT + CASE 
			WHEN FACILITY.[ACCOUNTING_FACILITY_CODE] IS NULL
				THEN ''
			ELSE ' (' + FACILITY.[ACCOUNTING_FACILITY_CODE] + ')'
			END + ' was executed at ' + CONVERT(VARCHAR, GETDATE(), 22) + ' [Sensitivity: Company-Confidential]' [SUBJECT],
		--'Message will be sent to the following recipient(s) when live.' + CHAR(10) + CHAR(13) + COMMENT [COMMENT]
    [COMMENT]
	FROM SSRS_SUBSCRIPTION_DISTRIBUTION
	inner join service_agreement sa on SA.FACILITY_ID = SSRS_SUBSCRIPTION_DISTRIBUTION.FACILITY_ID
	LEFT JOIN FACILITY ON FACILITY.FACILITY_ID = SSRS_SUBSCRIPTION_DISTRIBUTION.FACILITY_ID
	WHERE 
	-- DAH 05/12/16 added service_agreement table, noticed expired facilities in error in subscription.
	getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE	
    AND sa.DEMO_TEST_SITE_IND = 0					
	AND	REPORT = @m_ReportName
	AND [GROUP] = @m_Group
END






GO
GRANT EXECUTE ON  [dbo].[rpt_ListBillingReportDistribution] TO [dbx_ExecuteReportProcs]
GO
