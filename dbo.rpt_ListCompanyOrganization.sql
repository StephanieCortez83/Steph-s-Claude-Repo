SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/07/2013
-- Description:	Returns a list of 
--				Company (internal) Organizations.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListCompanyOrganization]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [ORGANIZATION_ID]
		  ,[DESCRIPTION] ORGANIZATION_NAME
	FROM [RevCycleDB].[dbo].[ORGANIZATION]
	ORDER BY [DESCRIPTION]

END



GO
GRANT EXECUTE ON  [dbo].[rpt_ListCompanyOrganization] TO [dbx_ExecuteReportProcs]
GO
