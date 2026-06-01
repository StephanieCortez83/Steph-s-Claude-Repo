SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId]
	@ChartAuditDocumentationVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditDocumentationVersionItem]
WHERE
	[ChartAuditDocumentationVersionItemId] = @ChartAuditDocumentationVersionItemId

GO
