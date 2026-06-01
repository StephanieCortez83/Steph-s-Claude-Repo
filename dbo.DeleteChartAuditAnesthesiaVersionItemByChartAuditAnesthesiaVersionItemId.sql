SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]
	@ChartAuditAnesthesiaVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditAnesthesiaVersionItem]
WHERE
	[ChartAuditAnesthesiaVersionItemId] = @ChartAuditAnesthesiaVersionItemId

GO
