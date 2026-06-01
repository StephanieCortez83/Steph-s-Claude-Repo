----------------------------------------
-- 01) DACS-2224 - Alter Procedure - [dbo].[sp_Validate_UserSessionUuid].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:  Daniel Bonebrake  
-- Create date: 7/31/2015  
-- Description: Returns a list of active session for the UserProfileID that started after the given SessionID with a different UUID.  
-- Author:  J. Burge - CDBT-458 - DACS-2224
-- Modification date: 3/21/2024
-- Description: Returns '1' if active session for the UserProfileID that started after the given SessionID with a different UUID.  
-- =============================================  
CREATE OR ALTER PROCEDURE [dbo].[sp_Validate_UserSessionUuid] @UserProfileID int
														    , @SessionID	 char(36)
														    , @Uuid			 nvarchar(36)
AS
	BEGIN
		SET NOCOUNT ON;

		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		IF EXISTS (SELECT	1
				   FROM		[dbo].[USER_SESSION]
				   WHERE	USER_PROFILE_ID = @UserProfileID
							AND SIGNED_OUT = 0
							AND UUID IS NOT NULL
							AND UUID <> @Uuid
							AND USER_SESSION_ID >= (SELECT	USER_SESSION_ID
													FROM	USER_SESSION
													WHERE	USER_PROFILE_ID = @UserProfileID
															AND SESSION_ID = @SessionID))
			SELECT 1;
	END;
GO

/*
testing:
DECLARE @SearchMinUserSessionId INT = (SELECT MAX(USER_SESSION_ID) FROM [dbo].[USER_SESSION])
select '1 @SearchMinUserSessionId =' = @SearchMinUserSessionId

SET @SearchMinUserSessionId = @SearchMinUserSessionId - 10000
select '2 @SearchMinUserSessionId =' = @SearchMinUserSessionId


select top 100 * from [dbo].[USER_SESSION] WITH (NOLOCK) 
where USER_SESSION_ID <= @SearchMinUserSessionId
order by USER_SESSION_ID desc;


*/
