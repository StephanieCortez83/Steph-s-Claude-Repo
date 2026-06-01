SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectApplicationFeatureByApplicationFeatureId]
	@ApplicationFeatureId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ApplicationFeature].[ApplicationFeatureId]
	,[ApplicationFeature].[DateTimeCreated]
	,[ApplicationFeature].[CreatedByUserProfileId]
	,[ApplicationFeature].[DateTimeLastUpdated]
	,[ApplicationFeature].[LastUpdatedByUserProfileId]
	,[ApplicationFeature].[ApplicationFeatureDomainObjectTypeCode]
	,[ApplicationFeature].[DomainObjectId]
	,[ApplicationFeature].[ApplicationFeatureTypeCode]
FROM
	[dbo].[ApplicationFeature]
WHERE
	[ApplicationFeature].[ApplicationFeatureId] = @ApplicationFeatureId

GO
