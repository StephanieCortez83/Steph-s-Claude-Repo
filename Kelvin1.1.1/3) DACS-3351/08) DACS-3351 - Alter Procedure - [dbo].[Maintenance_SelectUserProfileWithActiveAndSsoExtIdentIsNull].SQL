----------------------------------------------------------------------------------------
-- 08) DACS-3351 - Alter Procedure - [dbo].[Maintenance_SelectUserProfileWithActiveAndSsoExtIdentIsNull].SQL
----------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [dbo].[Maintenance_SelectUserProfileWithActiveAndSsoExtIdentIsNull]  
AS  
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT top 1000 
		--*
		  [USER_PROFILE_ID]
		, [SIGN_ON_ID]
		, [FIRST_NAME]
		, [LAST_NAME]
		, [EMAIL_ADDRESS]
	FROM 
		[USER_PROFILE]
	WHERE 
		[IS_ACTIVE] = 'Y'
		AND [SSO_EXTERNAL_IDENTIFIER] IS NULL;

GO

/*
Testing:
-- exec [dbo].[Maintenance_SelectUserProfileWithActiveAndSsoExtIdentIsNull]
*/



