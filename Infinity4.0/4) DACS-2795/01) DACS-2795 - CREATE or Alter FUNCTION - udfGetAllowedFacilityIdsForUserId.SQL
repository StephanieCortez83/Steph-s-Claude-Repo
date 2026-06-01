----------------------------------------
-- 01) DACS-2795 - CREATE or Alter FUNCTION - udfGetAllowedFacilityIdsForUserId.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- retrieves the facility_id access List for a specifed user on a specific DATE
-- The iTVF has not included BEGIN/END block in their syntax and the SELECT statement is the output of this type of functions

CREATE or Alter FUNCTION [dbo].[udfGetAllowedFacilityIdsForUserId]
	(
		@UserProfileId INT
		,@DateOfService datetime
	)
RETURNS TABLE
AS
RETURN
(
	SELECT 
		[FUA].[FACILITY_ID]
	FROM  
		[USER_PROFILE] AS [UP] WITH (NOLOCK)
		JOIN [FACILITY_USER_AUTHORIZATION] AS [FUA] WITH (NOLOCK) ON [UP].[USER_PROFILE_ID] = [FUA].[USER_PROFILE_ID]
	WHERE  
		[UP].[USER_PROFILE_ID] = @UserProfileId 
 		AND [FUA].[EFFECTIVE_DATE] <= @DateOfService
		AND ([FUA].[EXPIRATION_DATE] >= @DateOfService OR [FUA].EXPIRATION_DATE IS NULL)
)
 
