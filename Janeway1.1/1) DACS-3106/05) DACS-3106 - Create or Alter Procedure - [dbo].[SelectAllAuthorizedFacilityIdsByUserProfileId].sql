----------------------------------------
-- 05) DACS-3106 - Create or Alter Procedure - [dbo].[SelectAllAuthorizedFacilityIdsByUserProfileId].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  W. Pippin  
-- Create date: 03/25/2024  
-- Description: Returns all facility authentication information for the provided User Profile Id.  
-- =============================================  
CREATE OR ALTER PROCEDURE [dbo].[SelectAllAuthorizedFacilityIdsByUserProfileId] 
	@UserProfileId int
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- == WITH NOLOCK

	IF @UserProfileId IS NULL OR @UserProfileId < 0
		RETURN;
		
	SELECT DISTINCT 
		FACILITY_ID 
	FROM 
		FACILITY_USER_AUTHORIZATION 
	WHERE 
		USER_PROFILE_ID = @UserProfileId
		
END;
GO

/*
testing:
DECLARE @UserProfileId INT = 7157;
exec [dbo].[SelectAllAuthorizedFacilityIdsByUserProfileId] @UserProfileId = @UserProfileId

	-- original C#
SELECT DISTINCT FACILITY_ID FROM FACILITY_USER_AUTHORIZATION WHERE USER_PROFILE_ID= @UserProfileId

*/
