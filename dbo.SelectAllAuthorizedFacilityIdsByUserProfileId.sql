SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:  W. Pippin  
-- Create date: 03/25/2024  
-- Description: Returns all facility authentication information for the provided User Profile Id.  
-- =============================================  
CREATE   PROCEDURE [dbo].[SelectAllAuthorizedFacilityIdsByUserProfileId] 
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
