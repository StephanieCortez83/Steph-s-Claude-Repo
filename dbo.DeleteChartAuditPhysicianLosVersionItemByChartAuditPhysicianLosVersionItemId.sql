SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId]
	@ChartAuditPhysicianLosVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditPhysicianLosVersionItem]
WHERE
	[ChartAuditPhysicianLosVersionItemId] = @ChartAuditPhysicianLosVersionItemId

GO
