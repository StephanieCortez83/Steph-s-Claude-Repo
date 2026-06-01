SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartAuditAnesthesiaVersionItem]
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditAnesthesiaVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit
	,@ExcludeFromQA bit
	,@ExcludeFromQAReasonID int = NULL
	,@AnesthesiaCode varchar(10) = NULL
	,@StartTime datetime = NULL
	,@StopTime datetime = NULL
	,@ExcludeMinutes int = NULL
	,@Units int = NULL
	,@Minutes int = NULL
	,@ProviderModifiers varchar(100) = NULL
	,@MacModifiers varchar(2) = NULL
	,@PhysicalStatusModifier varchar(2) = NULL
	,@BaseUnitExceptionFieldAvoidance bit = NULL
	,@BaseUnitExceptionNonSupine bit = NULL
	,@BaseUnitExceptionModifier varchar(2) = NULL
	,@QualifyingCircumstanceCode varchar(100) = NULL
	,@ChargeMasterId int = NULL
	,@BaseUnitExceptionLimitedAccessToAirway bit = NULL
	,@DocumentationSupportsIncreasedComplexity bit = NULL
	,@DocumentationSupportsIncreasedComplexityReasonId int = NULL
	,@CptModifiers varchar(100) = NULL
	,@ChartAuditAnesthesiaVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditAnesthesiaVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditAnesthesiaVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[AnesthesiaCode]
	,[StartTime]
	,[StopTime]
	,[ExcludeMinutes]
	,[Units]
	,[Minutes]
	,[ProviderModifiers]
	,[MacModifiers]
	,[PhysicalStatusModifier]
	,[BaseUnitExceptionFieldAvoidance]
	,[BaseUnitExceptionNonSupine]
	,[BaseUnitExceptionModifier]
	,[QualifyingCircumstanceCode]
	,[ChargeMasterId]
	,[BaseUnitExceptionLimitedAccessToAirway]
	,[DocumentationSupportsIncreasedComplexity]
	,[DocumentationSupportsIncreasedComplexityReasonId]
	,[CptModifiers]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditAnesthesiaVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@AnesthesiaCode
	,@StartTime
	,@StopTime
	,@ExcludeMinutes
	,@Units
	,@Minutes
	,@ProviderModifiers
	,@MacModifiers
	,@PhysicalStatusModifier
	,@BaseUnitExceptionFieldAvoidance
	,@BaseUnitExceptionNonSupine
	,@BaseUnitExceptionModifier
	,@QualifyingCircumstanceCode
	,@ChargeMasterId
	,@BaseUnitExceptionLimitedAccessToAirway
	,@DocumentationSupportsIncreasedComplexity
	,@DocumentationSupportsIncreasedComplexityReasonId
	,@CptModifiers 
)

SET @ChartAuditAnesthesiaVersionItemId = @@IDENTITY

GO
