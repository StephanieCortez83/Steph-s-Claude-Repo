SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS SelectFacilityProceduresWithQuantityByChartIdAndServiceAgreementIdAndUsageCodeAndTimeOfService; 
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-3779 SPROC variant within FacilityProcedureEvaluationListDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 14
		AND [DomainObjectId] = 2147483647;
GO
