------------------------------------------------------------------------------------
-- 22) DACS-3351 - Create of Alter Stored Procedure - [dbo].[Maintenance_SelectAllUserProfiles].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_SelectAllUserProfiles] 
WITH EXEC AS CALLER AS
BEGIN
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP (20000) 
		 CAST([USER_PROFILE_ID] AS VARCHAR(200)) AS USER_PROFILE_ID
		,[SIGN_ON_ID]     
		,[FIRST_NAME]
		,[LAST_NAME]     
		,[IS_ACTIVE]  
		,[EMAIL_ADDRESS]
		,[USER_CLASS_CD]
		,CAST([INACTIVATED_DATE_TIME] AS VARCHAR(200)) AS INACTIVATED_DATE_TIME
		,CAST([USER_PROFILE_DEACTIVATION_REASON_ID] AS VARCHAR(200)) AS USER_PROFILE_DEACTIVATION_REASON_ID
		,CAST([USER_PROFILE_DEACTIVATION_OTHER_REASON] AS VARCHAR(200)) AS USER_PROFILE_DEACTIVATION_OTHER_REASON
		,CAST([SSO_COMPANY_ID] AS VARCHAR(200)) AS SSO_COMPANY_ID
		,CAST([SSO_EXTERNAL_IDENTIFIER] AS VARCHAR(200)) AS SSO_EXTERNAL_IDENTIFIER
	FROM USER_PROFILE;

END -- end procedure

GO

/*
testing:
begin tran; -- testing
EXEC [dbo].[Maintenance_SelectAllUserProfiles]
rollback tran; -- testing
commit tran; -- testing
*/