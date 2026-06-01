SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ChartPostBillAuditReasonTypeCodeSelect]
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartPostBillAuditReasonTypeCode].[ChartPostBillAuditReasonTypeCode]
	,[ChartPostBillAuditReasonTypeCode].[Key]
	,[ChartPostBillAuditReasonTypeCode].[DisplayName]
	,[ChartPostBillAuditReasonTypeCode].[ExternalCode]
	,[ChartPostBillAuditReasonTypeCode].[Description]
FROM
	[ChartPostBillAuditReasonTypeCode] 
ORDER BY
	[ChartPostBillAuditReasonTypeCode]

GO
