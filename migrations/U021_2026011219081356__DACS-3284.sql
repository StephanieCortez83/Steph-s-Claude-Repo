SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS SelectHasAPhysicianProcedureWith25ModifierFlagByChartIdAndEtAl; 
GO

DROP PROCEDURE IF EXISTS SelectHasAPhysicianProcedureWith25ModifierFlagByChartIdAndEtAlVer2; 
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-3284 SPROC variant within ChartPhysicianLevelOfService.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 19
		AND [DomainObjectId] = 2147483647;
GO
