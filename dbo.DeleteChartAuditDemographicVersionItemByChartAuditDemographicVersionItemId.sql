SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditDemographicVersionItemByChartAuditDemographicVersionItemId]
	@ChartAuditDemographicVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditDemographicVersionItem]
WHERE
	[ChartAuditDemographicVersionItemId] = @ChartAuditDemographicVersionItemId

GO
