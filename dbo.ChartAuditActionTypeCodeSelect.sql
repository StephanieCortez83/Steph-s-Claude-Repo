SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ChartAuditActionTypeCodeSelect]
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditActionTypeCode]
	,[Key]
	,[DisplayName]
	,[ExternalCode]
	,[Description]
FROM
	[ChartAuditActionTypeCode] 
ORDER BY
	[ChartAuditActionTypeCode]


GO
