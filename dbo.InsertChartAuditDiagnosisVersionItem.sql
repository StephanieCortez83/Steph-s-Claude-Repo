SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAuditDiagnosisVersionItem]
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditDiagnosisVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ICDCode varchar(10) = NULL
	,@DiagnosisTypeId int = NULL
	,@LevelNumber int = NULL
	,@IsPrimary bit = NULL
	,@ICDPostingOrder int = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartAuditDiagnosisVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditDiagnosisVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditDiagnosisVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ICDCode]
	,[DiagnosisTypeId]
	,[LevelNumber]
	,[IsPrimary]
	,[ICDPostingOrder]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditDiagnosisVersionItemId
	,@IsPreviousVersionCorrect
	,@ICDCode
	,@DiagnosisTypeId
	,@LevelNumber
	,@IsPrimary
	,@ICDPostingOrder
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID 
)

SET @ChartAuditDiagnosisVersionItemId = @@IDENTITY

GO
