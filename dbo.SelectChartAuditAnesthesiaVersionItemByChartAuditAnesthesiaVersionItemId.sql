SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]
	@ChartAuditAnesthesiaVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditVersionId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeCreated]
	,[ChartAuditAnesthesiaVersionItem].[CreatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeLastUpdated]
	,[ChartAuditAnesthesiaVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditAnesthesiaVersionItem].[ActionDescription]
	,[ChartAuditAnesthesiaVersionItem].[PrevChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQA]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditAnesthesiaVersionItem].[AnesthesiaCode]
	,[ChartAuditAnesthesiaVersionItem].[StartTime]
	,[ChartAuditAnesthesiaVersionItem].[StopTime]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeMinutes]
	,[ChartAuditAnesthesiaVersionItem].[Units]
	,[ChartAuditAnesthesiaVersionItem].[Minutes]
	,[ChartAuditAnesthesiaVersionItem].[ProviderModifiers]
	,[ChartAuditAnesthesiaVersionItem].[MacModifiers]
	,[ChartAuditAnesthesiaVersionItem].[PhysicalStatusModifier]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionFieldAvoidance]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionNonSupine]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionModifier]
	,[ChartAuditAnesthesiaVersionItem].[QualifyingCircumstanceCode]
	,[ChartAuditAnesthesiaVersionItem].[ChargeMasterId]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionLimitedAccessToAirway]
	,[ChartAuditAnesthesiaVersionItem].[DocumentationSupportsIncreasedComplexity]
	,[ChartAuditAnesthesiaVersionItem].[DocumentationSupportsIncreasedComplexityReasonId]
	,[ChartAuditAnesthesiaVersionItem].[CptModifiers]
FROM
	[dbo].[ChartAuditAnesthesiaVersionItem]
WHERE
	[ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId] = @ChartAuditAnesthesiaVersionItemId

GO
