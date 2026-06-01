SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAuditDocumentationVersionItem]
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditDocumentationVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@DocumentationId int = NULL
	,@DocumentationDeficiencyId int = NULL
	,@DocumentationChecked bit = NULL
	,@ChartAuditDocumentationVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditDocumentationVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditDocumentationVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[DocumentationId]
	,[DocumentationDeficiencyId]
	,[DocumentationChecked]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditDocumentationVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@DocumentationId
	,@DocumentationDeficiencyId
	,@DocumentationChecked 
)

SET @ChartAuditDocumentationVersionItemId = @@IDENTITY

GO
