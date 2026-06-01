SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartPostBillAuditByChartPostBillAuditId]
	@ChartPostBillAuditId int
AS

DELETE 
	FROM [dbo].[ChartPostBillAudit]
WHERE
	[ChartPostBillAuditId] = @ChartPostBillAuditId

GO
