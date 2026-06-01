SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartPostBillAudit]
	 @CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartId int
	,@ChartPostBillAuditStatusTypeCode int = NULL
	,@ChartPostBillAuditReasonTypeCode int = NULL
	,@ChartPostBillAuditId int OUTPUT
AS

INSERT INTO [dbo].[ChartPostBillAudit]
(
	 [CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartId]
	,[ChartPostBillAuditStatusTypeCode]
	,[ChartPostBillAuditReasonTypeCode]
)
VALUES
(
	 @CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartId
	,@ChartPostBillAuditStatusTypeCode
	,@ChartPostBillAuditReasonTypeCode 
)

SET @ChartPostBillAuditId = @@IDENTITY

GO
