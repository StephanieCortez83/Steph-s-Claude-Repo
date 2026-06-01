SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAuditPhysicianLosVersionItem]
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditPhysicianLosVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@LevelNumber int = NULL
	,@DateOfService datetime = NULL
	,@PhysicianHistoryId int = NULL
	,@PhysicianHistoryDescription varchar(250) = NULL
	,@PhysicianExamId int = NULL
	,@PhysicianExamDescription varchar(250) = NULL
	,@PhysicianMdmId int = NULL
	,@PhysicianMdmDescription varchar(250) = NULL
	,@PhysicianServiceProcId int = NULL
	,@OverridePhysicianServiceProcId int = NULL
	,@CptCode varchar(10) = NULL
	,@Modifier varchar(100) = NULL
	,@ProviderId int = NULL
	,@ChartAuditPhysicianLosVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditPhysicianLosVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditPhysicianLosVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[LevelNumber]
	,[DateOfService]
	,[PhysicianHistoryId]
	,[PhysicianHistoryDescription]
	,[PhysicianExamId]
	,[PhysicianExamDescription]
	,[PhysicianMdmId]
	,[PhysicianMdmDescription]
	,[PhysicianServiceProcId]
	,[OverridePhysicianServiceProcId]
	,[CptCode]
	,[Modifier]
	,[ProviderId]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditPhysicianLosVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@LevelNumber
	,@DateOfService
	,@PhysicianHistoryId
	,@PhysicianHistoryDescription
	,@PhysicianExamId
	,@PhysicianExamDescription
	,@PhysicianMdmId
	,@PhysicianMdmDescription
	,@PhysicianServiceProcId
	,@OverridePhysicianServiceProcId
	,@CptCode
	,@Modifier
	,@ProviderId 
)

SET @ChartAuditPhysicianLosVersionItemId = @@IDENTITY

GO
