CREATE OR ALTER PROCEDURE [dbo].[SelectScheduledUserLogoutByUserProfileIdSimplified]
	 @UserProfileId int
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP 10					-- arbitrary
		 [ScheduledUserLogoutId]
		,[DateTimeCreated]
		,[CreatedByUserProfileId]
		,[DateTimeLastUpdated]
		,[LastUpdatedByUserProfileId]
		,[UserProfileId]
		,[ScheduledLogoutTime]
		,[PreventLoginUntilTime]
	FROM
		[ScheduledUserLogout]
	WHERE
		[UserProfileId] = @UserProfileId
	ORDER BY
		[ScheduledUserLogoutId];	-- because the primary key ordering should be faster than the original : [DateTimeCreated]

END
GO

IF OBJECT_ID('dbo.SelectScheduledUserLogoutByUserProfileIdSimplified', 'P') IS NOT NULL
	PRINT ('SPROC SelectScheduledUserLogoutByUserProfileIdSimplified created');
ELSE
	PRINT ('failed to create SPROC SelectScheduledUserLogoutByUserProfileIdSimplified');
GO