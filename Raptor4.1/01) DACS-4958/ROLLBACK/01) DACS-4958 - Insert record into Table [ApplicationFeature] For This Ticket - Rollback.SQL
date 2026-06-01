------------------------------------------------------------------------------------
-- 01) DACS-4958 - Insert record into Table [ApplicationFeature] For This Ticket - Rollback.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-4958 SPROC variant within FacilityProfessionalDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 7
		AND [DomainObjectId] = 2147483647;
GO
