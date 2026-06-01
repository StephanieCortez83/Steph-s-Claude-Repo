SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteApplicationFeatureByApplicationFeatureId]
	@ApplicationFeatureId int
AS

DELETE 
	FROM [dbo].[ApplicationFeature]
WHERE
	[ApplicationFeatureId] = @ApplicationFeatureId

GO
