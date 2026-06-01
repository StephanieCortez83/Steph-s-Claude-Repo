SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-4956 SPROC variant within AnesthesiaListDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 8
		AND [DomainObjectId] = 2147483647;
GO

DROP PROCEDURE IF EXISTS SelectAnesthesiaTypeByServiceAgreementId
GO
