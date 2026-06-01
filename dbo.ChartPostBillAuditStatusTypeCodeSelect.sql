SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ChartPostBillAuditStatusTypeCodeSelect]
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartPostBillAuditStatusTypeCode].[ChartPostBillAuditStatusTypeCode]
	,[ChartPostBillAuditStatusTypeCode].[Key]
	,[ChartPostBillAuditStatusTypeCode].[DisplayName]
	,[ChartPostBillAuditStatusTypeCode].[ExternalCode]
	,[ChartPostBillAuditStatusTypeCode].[Description]
FROM
	[ChartPostBillAuditStatusTypeCode] 
ORDER BY
	[ChartPostBillAuditStatusTypeCode]

GO
