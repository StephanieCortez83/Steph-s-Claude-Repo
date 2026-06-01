USE [RevCycleDB]
GO

INSERT INTO [dbo].[DEFINED_RIGHT]
           ([DEFINED_RIGHT_ID]
           ,[NAME]
           ,[CREATION_DATE_TIME]
           ,[CREATING_USER_PROFILE_ID]
           ,[CHANGED_DATE_TIME]
           ,[CHANGING_USER_PROFILE_ID]
           ,[ALLOW_INHERITANCE])
SELECT 112
	  ,'View IP Address Whitelist'
	  ,GETDATE()
	  ,10149
	  ,GETDATE()
	  ,1149
	  ,0

INSERT INTO [dbo].[DEFINED_RIGHT]
           ([DEFINED_RIGHT_ID]
           ,[NAME]
           ,[CREATION_DATE_TIME]
           ,[CREATING_USER_PROFILE_ID]
           ,[CHANGED_DATE_TIME]
           ,[CHANGING_USER_PROFILE_ID]
           ,[ALLOW_INHERITANCE])
SELECT 113
	  ,'Add IP Address Whitelist'
	  ,GETDATE()
	  ,10149
	  ,GETDATE()
	  ,1149
	  ,0

INSERT INTO [dbo].[DEFINED_RIGHT]
           ([DEFINED_RIGHT_ID]
           ,[NAME]
           ,[CREATION_DATE_TIME]
           ,[CREATING_USER_PROFILE_ID]
           ,[CHANGED_DATE_TIME]
           ,[CHANGING_USER_PROFILE_ID]
           ,[ALLOW_INHERITANCE])
SELECT 114
	  ,'Edit IP Address Whitelist'
	  ,GETDATE()
	  ,10149
	  ,GETDATE()
	  ,1149
	  ,0

INSERT INTO [dbo].[DEFINED_RIGHT]
           ([DEFINED_RIGHT_ID]
           ,[NAME]
           ,[CREATION_DATE_TIME]
           ,[CREATING_USER_PROFILE_ID]
           ,[CHANGED_DATE_TIME]
           ,[CHANGING_USER_PROFILE_ID]
           ,[ALLOW_INHERITANCE])
SELECT 115
	  ,'Delete IP Address Whitelist'
	  ,GETDATE()
	  ,10149
	  ,GETDATE()
	  ,1149
	  ,0



