SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAuditFacilityLosVersionItem]
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditFacilityLosVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@LevelNumber int = NULL
	,@CptCode varchar(10) = NULL
	,@Modifier varchar(100) = NULL
	,@FacilityChartId varchar(20) = NULL
	,@FacilityLevelId int = NULL
	,@OverrideFacilityLevelId int = NULL
	,@ChartAuditFacilityLosVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditFacilityLosVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditFacilityLosVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[LevelNumber]
	,[CptCode]
	,[Modifier]
	,[FacilityChartId]
	,[FacilityLevelId]
	,[OverrideFacilityLevelId]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditFacilityLosVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@LevelNumber
	,@CptCode
	,@Modifier
	,@FacilityChartId
	,@FacilityLevelId
	,@OverrideFacilityLevelId 
)

SET @ChartAuditFacilityLosVersionItemId = @@IDENTITY

GO
