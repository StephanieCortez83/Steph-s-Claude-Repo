SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

DROP PROCEDURE IF EXISTS SelectFacilityFinancialClassByFinancialClassId; 
GO

DROP PROCEDURE IF EXISTS SelectFacilityFinancialClassByFinancialClassCodeAndServiceAgreementId; 
GO

DROP PROCEDURE IF EXISTS SelectFacilityFinancialClassByFinancialClassCodeAndServiceAgreementId; 
GO

DROP PROCEDURE IF EXISTS SelectFacilityFinancialClassByServiceAgreementId; 
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-3773 SPROC variant within FacilityFinancialClassDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 11
		AND [DomainObjectId] = 2147483647;
GO