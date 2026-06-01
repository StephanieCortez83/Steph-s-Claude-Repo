SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId]
	@ChartAuditProcedureVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditProcedureVersionItem]
WHERE
	[ChartAuditProcedureVersionItemId] = @ChartAuditProcedureVersionItemId

GO
