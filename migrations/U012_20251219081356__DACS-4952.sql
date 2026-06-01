SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

DROP PROCEDURE IF EXISTS SelectIdAndDescriptionFromPatientDisposition; 
GO

DROP PROCEDURE IF EXISTS SelectFromPatientDispositionById; 
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-4952 SPROC variant within SimplePatientDispositionListDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 10
		AND [DomainObjectId] = 2147483647;
GO
