SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditDiagnosisVersionItemByChartAuditDiagnosisVersionItemId]
	@ChartAuditDiagnosisVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditDiagnosisVersionItem]
WHERE
	[ChartAuditDiagnosisVersionItemId] = @ChartAuditDiagnosisVersionItemId

GO
