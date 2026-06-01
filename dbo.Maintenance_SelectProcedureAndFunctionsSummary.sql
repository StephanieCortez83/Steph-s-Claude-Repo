SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_SelectProcedureAndFunctionsSummary]
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		 LEN(m.definition) AS LenProc
		,o.[type] 
		,o.[modify_date] 
		,o.[name]
	FROM 
		[sys].[objects] o
		JOIN sys.sql_modules m ON o.OBJECT_ID = m.OBJECT_ID
	WHERE 
		[type] IN ('P','FN','FS')
	ORDER BY 
		[type],[name],[modify_date] DESC;

/*
EXEC [dbo].[Maintenance_SelectProcedureAndFunctionsSummary];
*/	
END -- end procedure
GO
