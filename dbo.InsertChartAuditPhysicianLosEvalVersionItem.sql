SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAuditPhysicianLosEvalVersionItem]
	 @ChartAuditPhysicianLosVersionItemId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditPhysicianLosEvalVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int
	,@LevelNbr int
	,@PhysicianServiceId int = NULL
	,@PlanId int = NULL
	,@CategoryId int = NULL
	,@SubcategoryId int = NULL
	,@MinorCategoryId int = NULL
	,@ServiceDescription varchar(100) = NULL
	,@Quantity int = NULL
	,@Points int = NULL
	,@ChartAuditPhysicianLosEvalVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditPhysicianLosEvalVersionItem]
(
	 [ChartAuditPhysicianLosVersionItemId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditPhysicianLosEvalVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[LevelNbr]
	,[PhysicianServiceId]
	,[PlanId]
	,[CategoryId]
	,[SubcategoryId]
	,[MinorCategoryId]
	,[ServiceDescription]
	,[Quantity]
	,[Points]
)
VALUES
(
	 @ChartAuditPhysicianLosVersionItemId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditPhysicianLosEvalVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@LevelNbr
	,@PhysicianServiceId
	,@PlanId
	,@CategoryId
	,@SubcategoryId
	,@MinorCategoryId
	,@ServiceDescription
	,@Quantity
	,@Points 
)

SET @ChartAuditPhysicianLosEvalVersionItemId = @@IDENTITY

GO
