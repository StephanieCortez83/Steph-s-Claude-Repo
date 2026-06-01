SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosEvalVersionItemId]
	@ChartAuditPhysicianLosEvalVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditPhysicianLosEvalVersionItem]
WHERE
	[ChartAuditPhysicianLosEvalVersionItemId] = @ChartAuditPhysicianLosEvalVersionItemId

GO
