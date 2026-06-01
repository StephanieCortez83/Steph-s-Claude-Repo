------------------------------------------------------------------------------------
-- 01) DACS-3205 - Insert record into Table [TYPE_CODE] for ApplicationFeature for Provider Cache
------------------------------------------------------------------------------------

USE [RevCycleDB]
GO

INSERT INTO 
    [TYPE_CODE]
(
    [TYPE_CODE].[NAME]
   ,[TYPE_CODE].[KEY]
   ,[TYPE_CODE].[VALUE]
   ,[TYPE_CODE].[DISPLAY_NAME]
   ,[TYPE_CODE].[SHORT_NAME]
   ,[TYPE_CODE].[DESCRIPTION]
)
VALUES
(
    'ApplicationFeatureTypeCode'                                                --NAME
   ,'ProviderCache'                                                             --KEY
   ,3                                                                           --VALUE
   ,'Provider Cache'                                                            --DISPLAY_NAME
   ,'PC'                                                                        --SHORT_NAME
   ,'Turns On/Off Provider Cache for SimpleFacilityProfessionalsListDAO'        --DESCRIPTION
)