SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosEvalVersionItemId]
	@ChartAuditFacilityLosEvalVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditFacilityLosEvalVersionItem]
WHERE
	[ChartAuditFacilityLosEvalVersionItemId] = @ChartAuditFacilityLosEvalVersionItemId

GO
