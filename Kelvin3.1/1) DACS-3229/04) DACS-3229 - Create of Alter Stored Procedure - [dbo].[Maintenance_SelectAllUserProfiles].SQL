------------------------------------------------------------------------------------
-- 04) DACS-3229 - Create of Alter Stored Procedure - [dbo].[Maintenance_SelectAllUserProfiles].SQL
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
	----------------------------------------------
	-- updated to make all fields strings to reduce field type exceptions when ACS reads data - DACS-3229 - 20240716 - pippin
	----------------------------------------------
	
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP (50000) 
		 CAST([USER_PROFILE_ID] AS VARCHAR(200)) AS USER_PROFILE_ID
		,CAST([SIGN_ON_ID] AS VARCHAR(200)) AS SIGN_ON_ID  
		,CAST([FIRST_NAME] AS VARCHAR(200)) AS FIRST_NAME
		,CAST([LAST_NAME] AS VARCHAR(200)) AS LAST_NAME
		,CAST([IS_ACTIVE] AS VARCHAR(200)) AS IS_ACTIVE
		,CAST([EMAIL_ADDRESS] AS VARCHAR(200)) AS EMAIL_ADDRESS
		,CAST([USER_CLASS_CD] AS VARCHAR(200)) AS USER_CLASS_CD
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