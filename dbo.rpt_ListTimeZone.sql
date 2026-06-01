SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/06/2013
-- Description:	Returns a list of Report Users.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListTimeZone]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [TIME_ZONE_ID]			TimeZone_ID
		  ,[DESCRIPTION]			TimeZone_NAME
		  ,[REPORTING_DESCRIPTION]	TimeZone_DESC
		  ,[CT_OFFSET]				Offset
	FROM dbo.TIME_ZONE
	ORDER BY [DESCRIPTION], [TIME_ZONE_ID]

END


GO
GRANT EXECUTE ON  [dbo].[rpt_ListTimeZone] TO [dbx_ExecuteReportProcs]
GO
