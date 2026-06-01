SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_ExpireFacilityAuthorizationUsers]
	 @FacilityIds dbo.udt_IntValue READONLY
	,@BackupSourceTableName VARCHAR(100)
	,@BackupDestinationTableName VARCHAR(100)
	,@ChangingUserId INT
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ChangedDate DATETIME = GETDATE()
	   ,@ChangedUserCount INT = 0
       ,@ChangingUserName VARCHAR(50)
	   ,@EffectiveDate DATETIME
       ,@ErrorMessage VARCHAR(200)
	   ,@ExpirationDate DATETIME
       ,@FuaCountAfterUpdate INT = 0
	   ,@FuaCountBeforeUpdate INT = 0
	   ,@FacilityId INT
	   ,@FacilityUserAuthorizationId INT
       ,@FacilityName VARCHAR(50)
	   ,@NewExpirationDate DATETIME
	   ,@PreviousUserProfileId INT = 0
	   ,@SignOnId VARCHAR(50)
       ,@UserCount INT = 0
       ,@UserProfileId INT;

---------------------------------------------------------
-- Grab the user taking action
---------------------------------------------------------
IF EXISTS(SELECT * FROM [USER_PROFILE] WHERE [USER_PROFILE_ID] = @ChangingUserId)
BEGIN
    SELECT @ChangingUserName = [SIGN_ON_ID] FROM [USER_PROFILE] WHERE [USER_PROFILE_ID] = @ChangingUserId
END
ELSE
BEGIN
 	SET @ErrorMessage = 'User Id ' + CAST(@ChangingUserId AS VARCHAR(10)) + ' does not exist. Stored procedure execution aborted.';
 	RAISERROR(@ErrorMessage, 16, 1);
    RETURN;
END
---------------------------------------------------------
-- Backup the target table
---------------------------------------------------------
IF OBJECT_ID(@BackupDestinationTableName) IS NOT NULL
BEGIN
	SET @ErrorMessage = 'The backup table ' + @BackupDestinationTableName + ' already exists. Stored procedure execution aborted.';
	RAISERROR(@ErrorMessage, 16, 1);
    RETURN;
END
ELSE
BEGIN
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = @BackupSourceTableName, @DestTable = @BackupDestinationTableName;
END

---------------------------------------------------------
-- Gather a list of FACILITY_USER_AUTHORIZATION records
---------------------------------------------------------
DROP TABLE IF EXISTS #FUA

CREATE TABLE #FUA
(
     [FACILITY_ID] INT NOT NULL
    ,[FACILITY_NAME] VARCHAR(50) NOT NULL
    ,[FACILITY_USER_AUTHORIZATION_ID] INT NOT NULL
    ,[USER_PROFILE_ID] INT NOT NULL
    ,[SIGN_ON_ID] VARCHAR(100) NOT NULL
	,[EFFECTIVE_DATE] DATETIME NOT NULL
	,[EXPIRATION_DATE] DATETIME NOT NULL
);

INSERT INTO #FUA
SELECT [FACILITY_USER_AUTHORIZATION].[FACILITY_ID]
      ,[FACILITY].[NAME]
      ,[FACILITY_USER_AUTHORIZATION].[FACILITY_AUTH_ID]
      ,[USER_PROFILE].[USER_PROFILE_ID]
      ,[USER_PROFILE].[SIGN_ON_ID]
	  ,[FACILITY_USER_AUTHORIZATION].[EFFECTIVE_DATE]
	  ,[FACILITY_USER_AUTHORIZATION].[EXPIRATION_DATE]
FROM [FACILITY_USER_AUTHORIZATION] WITH (NOLOCK)
INNER JOIN [FACILITY] WITH (NOLOCK)
        ON [FACILITY].[FACILITY_ID] = [FACILITY_USER_AUTHORIZATION].[FACILITY_ID]
INNER JOIN [USER_PROFILE] WITH (NOLOCK)
        ON [USER_PROFILE].[USER_PROFILE_ID] = [FACILITY_USER_AUTHORIZATION].[USER_PROFILE_ID]
WHERE
    [FACILITY_USER_AUTHORIZATION].[FACILITY_ID] IN (SELECT [Value] FROM @FacilityIds)
	AND
	[EXPIRATION_DATE] >= CAST(GETDATE() AS DATE)
    --AND
    --[USER_PROFILE].[USER_PROFILE_ID] = 10149
    --AND
    --[FACILITY].[FACILITY_ID] = 1061
ORDER BY
    [FACILITY_USER_AUTHORIZATION].[FACILITY_AUTH_ID];

---------------------------------------------------------
-- Expire the FUA records
---------------------------------------------------------
SELECT @FuaCountBeforeUpdate = COUNT(*) FROM #FUA;
SELECT @UserCount = COUNT(DISTINCT [SIGN_ON_ID]) FROM #FUA;

PRINT('performing update...');
PRINT ('...updating ' + CAST(@FuaCountBeforeUpdate AS VARCHAR(50)) + ' Facility User Authorization records for ' + CAST(@UserCount AS VARCHAR(50)) + ' users ');

DECLARE fua_cursor CURSOR FOR
SELECT [FACILITY_USER_AUTHORIZATION_ID]
      ,[USER_PROFILE_ID]
	  ,[SIGN_ON_ID]
	  ,[FACILITY_ID]
      ,[FACILITY_NAME]
	  ,[EFFECTIVE_DATE]
	  ,[EXPIRATION_DATE]
FROM
	#FUA
ORDER BY
	[SIGN_ON_ID]
   ,[FACILITY_NAME]
   ,[FACILITY_USER_AUTHORIZATION_ID];

OPEN fua_cursor;

FETCH NEXT FROM fua_cursor INTO @FacilityUserAuthorizationId, @UserProfileId, @SignOnId, @FacilityId, @FacilityName, @EffectiveDate, @ExpirationDate;

WHILE @@FETCH_STATUS = 0
BEGIN

	-- Setting the new expiration date to the original effective date
	-- *should* keep it from throwing an overlap FUA record error
	SET @NewExpirationDate = @EffectiveDate;

	PRINT ('......updating user ' + @SignOnId + ' / Facility ' + @FacilityName + ' Facility User Authorization record ' + CAST(@FacilityUserAuthorizationId AS VARCHAR(25)) + ': Effective Date: ' + CAST(FORMAT(@EffectiveDate, 'MM/dd/yyyy') AS VARCHAR(25)) + ' / Expiration Date: ' + CAST(FORMAT(@ExpirationDate, 'MM/dd/yyyy') AS VARCHAR(25)) + '; New Expiration Date: ' + CAST(FORMAT(@NewExpirationDate, 'MM/dd/yyyy') AS VARCHAR(25)));

	IF @ExpirationDate >= GETDATE()
	BEGIN
		UPDATE [FACILITY_USER_AUTHORIZATION]
		   SET [EXPIRATION_DATE] = @NewExpirationDate
			  ,[CHANGED_DATE_TIME] = @ChangedDate
			  ,[CHANGING_USER_PROFILE_ID] = @ChangingUserId
		WHERE [FACILITY_AUTH_ID] = @FacilityUserAuthorizationId;

		DECLARE @Comment VARCHAR(500), @StateString VARCHAR(500)

		SET @Comment = 'Client migration: Expiring authorized facility to prevent access ' + @FacilityName;
		SET @StateString = '{"EMR Access Expiration Date":"' + CAST(@NewExpirationDate AS VARCHAR(50)) + '"}';

		-- Write audit logs for the users for audits
		EXEC [dbo].[Maintenance_LogAdminAction]
				 @ObjectId = @UserProfileId
				,@AdministratorUsername = @ChangingUserName
				,@ObjectType = 'User Profile'
				,@EventName = 'Update'
				,@Comment = @Comment
				,@StateString = @StateString
				,@PrintDiagnostics = 0;

		EXEC [dbo].[Maintenance_LogAdminAction]
				 @ObjectId = @FacilityUserAuthorizationId
				,@AdministratorUsername = @ChangingUserName
				,@ObjectType = 'Facility Authorization'
				,@EventName = 'Update'
				,@Comment = @Comment
				,@StateString = @StateString
				,@PrintDiagnostics = 0;

		IF @UserProfileId <> @PreviousUserProfileId
		BEGIN
			SET @ChangedUserCount = @ChangedUserCount + 1;
			SET @PreviousUserProfileId = @UserProfileId;
        END

		SET @FuaCountAfterUpdate = @FuaCountAfterUpdate + 1;
	END

    FETCH NEXT FROM fua_cursor INTO @FacilityUserAuthorizationId, @UserProfileId, @SignOnId, @FacilityId, @FacilityName, @EffectiveDate, @ExpirationDate;
END

PRINT ('...updated ' + CAST(@FuaCountAfterUpdate AS VARCHAR(50)) + ' Facility User Authorization records for ' + CAST(@ChangedUserCount AS VARCHAR(50)) + ' user(s)');

CLOSE fua_cursor;
DEALLOCATE fua_cursor;
GO
