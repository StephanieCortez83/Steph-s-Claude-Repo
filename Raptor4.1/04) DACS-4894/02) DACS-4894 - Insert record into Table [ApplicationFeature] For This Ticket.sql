------------------------------------------------------------------------------------
-- 02) DACS-4894 - Insert record into Table [ApplicationFeature] For This Ticket.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Controls CAB Feature', 'Enable/Disables DACS-4894 SPROC variant within ChartAccessDAO.cs'))
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
			'ApplicationFeatureDomainObjectTypeCode'                  			--NAME
		   ,'CAB'                                              					--KEY
		   ,5                                                         			--VALUE
		   ,'CAB Feature'                                           			--DISPLAY_NAME
		   ,'CAB'                                                     			--SHORT_NAME
		   ,'Controls CAB Feature'												--DESCRIPTION
		)
		,(
			'ApplicationFeatureTypeCode'                                       	--NAME
		   ,'CAB_4894'                                                    		--KEY
		   ,5                                                                  	--VALUE
		   ,'CAB_4894'                                                    		--DISPLAY_NAME
		   ,'CAB_4894'                                                         	--SHORT_NAME
		   ,'Enable/Disables DACS-4894 SPROC variant within ChartAccessDAO.cs' 	--DESCRIPTION
		)
ELSE
	PRINT('One or more Type Codes already exists.  Action skipped.');
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 5)
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
			,5
		)
ELSE
	PRINT('Application Feature already exists.  Action skipped.');
GO

-- show some results for DBA/release verification logging
SELECT TOP 2 * FROM APPLICATIONFEATURE ORDER BY 1 DESC;
SELECT TOP 100 * FROM TYPE_CODE WHERE [NAME] = 'ApplicationFeatureTypeCode';
GO
