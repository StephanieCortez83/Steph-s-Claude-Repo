SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Laura Hotalling
-- Create date: 03/07/2013
-- Description:	Returns a list of User Classes.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_ListUserClass]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [USER_CLASS_ID]
		  ,[DESCRIPTION] USER_CLASS_NAME
	FROM [RevCycleDB].[dbo].[USER_CLASS]
	ORDER BY [DESCRIPTION]

END




GO
GRANT EXECUTE ON  [dbo].[rpt_ListUserClass] TO [dbx_ExecuteReportProcs]
GO
