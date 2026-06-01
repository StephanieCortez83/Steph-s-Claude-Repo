SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId]
	@ChartAuditFacilityLosVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditFacilityLosVersionItem]
WHERE
	[ChartAuditFacilityLosVersionItemId] = @ChartAuditFacilityLosVersionItemId

GO
