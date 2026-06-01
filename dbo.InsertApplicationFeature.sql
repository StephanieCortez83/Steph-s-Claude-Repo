SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertApplicationFeature]
	 @CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ApplicationFeatureDomainObjectTypeCode tinyint
	,@DomainObjectId int
	,@ApplicationFeatureTypeCode int
	,@ApplicationFeatureId int OUTPUT
AS

INSERT INTO [dbo].[ApplicationFeature]
(
	 [CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ApplicationFeatureDomainObjectTypeCode]
	,[DomainObjectId]
	,[ApplicationFeatureTypeCode]
)
VALUES
(
	 @CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ApplicationFeatureDomainObjectTypeCode
	,@DomainObjectId
	,@ApplicationFeatureTypeCode 
)

SET @ApplicationFeatureId = @@IDENTITY

GO
