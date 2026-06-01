SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAuditFacilityLosEvalVersionItem]
	 @ChartAuditFacilityLosVersionItemId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditFacilityLosEvalVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@FacilityServiceId int = NULL
	,@FacilityServiceDescription varchar(75) = NULL
	,@Points int = NULL
	,@ChartAuditFacilityLosEvalVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditFacilityLosEvalVersionItem]
(
	 [ChartAuditFacilityLosVersionItemId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditFacilityLosEvalVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[FacilityServiceId]
	,[FacilityServiceDescription]
	,[Points]
)
VALUES
(
	 @ChartAuditFacilityLosVersionItemId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditFacilityLosEvalVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@FacilityServiceId
	,@FacilityServiceDescription
	,@Points 
)

SET @ChartAuditFacilityLosEvalVersionItemId = @@IDENTITY

GO
