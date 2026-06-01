SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartAuditVersionCommentByChartAuditVersionCommentId]
	@ChartAuditVersionCommentId int
AS

DELETE 
	FROM [dbo].[ChartAuditVersionComment]
WHERE
	[ChartAuditVersionCommentId] = @ChartAuditVersionCommentId

GO
