----------------------------------------
-- 01) DACS-3876 - ROLLBACK All.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS SelectChargeMasterFacilityProcedureEvaluationEtalBaseLoadDataByChartIdEtAl; 
GO

DELETE FROM [TYPE_CODE]
	WHERE
		[DESCRIPTION] IN ('Enable/Disables DACS-3876 SPROC variant within FacilityProcedureEvaluationListDAO.cs')
		AND [NAME] = 'ApplicationFeatureTypeCode';
GO

DELETE FROM [ApplicationFeature]
	WHERE
		[ApplicationFeatureDomainObjectTypeCode] = 5
		AND [ApplicationFeatureTypeCode] = 22
		AND [DomainObjectId] = 2147483647;
GO
