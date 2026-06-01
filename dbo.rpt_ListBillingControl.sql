SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/13/2013
-- Description:	Returns a list of active 
--				(not future) Billing Periods.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListBillingControl]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [BILLING_CONTROL_ID]
		  ,RIGHT('0' + CAST([BILLING_PERIOD_MONTH] AS VARCHAR(12)),2) + '-' + CAST([BILLING_PERIOD_YEAR] AS VARCHAR) 'BILLING_CONTROL_NAME'
		  ,[BILLING_PERIOD_YEAR]
		  ,[BILLING_PERIOD_MONTH]
		  ,[START_DATE]
		  ,[END_DATE]
		  ,[BILLING_DATE]
		  ,[STATUS_CD]
	FROM [RevCycleDB].[dbo].[BILLING_CONTROL]
	WHERE [START_DATE] <= GETDATE()
	ORDER BY [BILLING_CONTROL_ID] DESC
END

GO
GRANT EXECUTE ON  [dbo].[rpt_ListBillingControl] TO [dbx_ExecuteReportProcs]
GO
