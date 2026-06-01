------------------------------------------------------------------------------------
-- 02) DACS-4895 - Insert record into Table [ApplicationFeature] For This Ticket - Rollback.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-4895 SPROC variant within ChartAccessDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 6
		AND [DomainObjectId] = 2147483647;
GO
