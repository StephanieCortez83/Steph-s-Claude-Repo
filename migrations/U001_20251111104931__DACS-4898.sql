SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

DROP PROCEDURE IF EXISTS SelectFacilityLevelCodeFieldsByChartId
GO

DROP PROCEDURE IF EXISTS SelectLogNoteForPast2WeeksByDetail
GO

DROP PROCEDURE IF EXISTS Select99292UnitsFromFacilityProcedureEvaluationByChartId
GO

DROP PROCEDURE IF EXISTS Select99292UnitsFromPhysicianProcedureEvaluationByChartId
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-4898 SPROC variant within FacilityProcedureEvaluationListDAO,FacilityLevelDAO,ServiceAgreementDAO,PhysicianProcedureEvaluationListDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 9
		AND [DomainObjectId] = 2147483647;
GO
