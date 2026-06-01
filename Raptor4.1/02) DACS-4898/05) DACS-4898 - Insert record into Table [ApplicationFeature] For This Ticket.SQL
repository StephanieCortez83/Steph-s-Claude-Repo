------------------------------------------------------------------------------------
-- 05) DACS-4898 - Insert record into Table [ApplicationFeature] For This Ticket.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4898 SPROC variant within FacilityProcedureEvaluationListDAO,FacilityLevelDAO,ServiceAgreementDAO,PhysicianProcedureEvaluationListDAO.cs'))
	INSERT INTO 
		[TYPE_CODE]
		(
			[NAME]
		   ,[KEY]
		   ,[VALUE]
		   ,[DISPLAY_NAME]
		   ,[SHORT_NAME]
		   ,[DESCRIPTION]
		)
		VALUES
		(
			'ApplicationFeatureTypeCode'                                      																									--NAME
		   ,'CAB_4898'                                                    																										--KEY
		   ,9                                                                 																									--VALUE
		   ,'CAB_4898'                                                    																										--DISPLAY_NAME
		   ,'CAB_4898'                                                        																									--SHORT_NAME
		   ,'Enable/Disables DACS-4898 SPROC variant within FacilityProcedureEvaluationListDAO,FacilityLevelDAO,ServiceAgreementDAO,PhysicianProcedureEvaluationListDAO.cs' 	--DESCRIPTION
		)
ELSE
	PRINT('Type Code already exists.  Action skipped.');
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 9)
	INSERT INTO 
		[dbo].[ApplicationFeature]
		(
			 [DateTimeCreated]
			,[CreatedByUserProfileId]
			,[DateTimeLastUpdated]
			,[LastUpdatedByUserProfileId]
			,[ApplicationFeatureDomainObjectTypeCode]
			,[DomainObjectId]
			,[ApplicationFeatureTypeCode]
		)
	VALUES
		(
			 @dtCreated
			,@Uid
			,@dtCreated
			,@Uid
			,5
			,2147483647															--ALL
			,9
		)
ELSE
	PRINT('Application Feature already exists.  Action skipped.');
GO

-- show some results for DBA/release verification logging
SELECT TOP 2 * FROM APPLICATIONFEATURE ORDER BY 1 DESC;
SELECT TOP 100 * FROM TYPE_CODE WHERE [NAME] = 'ApplicationFeatureTypeCode';
GO
