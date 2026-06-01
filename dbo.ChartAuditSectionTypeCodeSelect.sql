SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ChartAuditSectionTypeCodeSelect]
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditSectionTypeCode].[ChartAuditSectionTypeCode]
	,[ChartAuditSectionTypeCode].[Key]
	,[ChartAuditSectionTypeCode].[DisplayName]
	,[ChartAuditSectionTypeCode].[ExternalCode]
	,[ChartAuditSectionTypeCode].[Description]
FROM
	[ChartAuditSectionTypeCode] 
ORDER BY
	[ChartAuditSectionTypeCode]

GO
