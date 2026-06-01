SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[DeleteChartAuditVersionByChartAuditVersionId]
	@ChartAuditVersionId int
AS

DELETE 
	FROM [dbo].[ChartAuditVersion]
WHERE
	[ChartAuditVersionId] = @ChartAuditVersionId


GO
