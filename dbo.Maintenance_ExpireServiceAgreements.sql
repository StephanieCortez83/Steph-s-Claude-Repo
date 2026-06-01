SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_ExpireServiceAgreements]
     @ServiceAgreementIds dbo.udt_IntValue READONLY
	,@BackupSourceTableName VARCHAR(100)
	,@BackupDestinationTableName VARCHAR(100)
	,@ChangingUserId INT
AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ChangedDate DATETIME = GETDATE()
       ,@ChangingUserName VARCHAR(50)
       ,@Description VARCHAR(50)
       ,@EffectiveDate DATETIME
       ,@ErrorMessage VARCHAR(200)
       ,@ExpirationDate DATETIME
       ,@SACountAfterUpdate INT = 0
	   ,@SACountBeforeUpdate INT = 0
	   ,@ServiceAgreementId INT
       ,@NewExpirationDate DATETIME = GETDATE();

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
-- Gather a list of SERVICE_AGREEMENT records
---------------------------------------------------------
DROP TABLE IF EXISTS #SA;

CREATE TABLE #SA
(
     [SERVICE_AGREEMENT_ID] INT NOT NULL
    ,[DESCRIPTION] VARCHAR(50) NOT NULL
	,[EFFECTIVE_DATE] DATETIME NOT NULL
	,[EXPIRATION_DATE] DATETIME NOT NULL
);

INSERT INTO #SA
SELECT
     [SERVICE_AGREEMENT_ID]
    ,[DESCRIPTION]
    ,[EFFECTIVE_DATE]
    ,[EXPIRATION_DATE]
FROM [SERVICE_AGREEMENT] WITH (NOLOCK)
WHERE
    [SERVICE_AGREEMENT_ID] IN (SELECT [Value] FROM @ServiceAgreementIds)
    AND
	[EXPIRATION_DATE] >= CAST(GETDATE() AS DATE)
ORDER BY
    [DESCRIPTION];

---------------------------------------------------------
-- Expire the SERVICE_AGREEMENT records
---------------------------------------------------------
SELECT @SACountBeforeUpdate = COUNT(*) FROM #SA;

PRINT('performing expiration...');
PRINT ('...expiring ' + CAST(@SACountBeforeUpdate AS VARCHAR(50)) + ' Service Agreement records ');

DECLARE sa_cursor CURSOR FOR
SELECT
     [SERVICE_AGREEMENT_ID]
    ,[DESCRIPTION]
    ,[EFFECTIVE_DATE]
    ,[EXPIRATION_DATE]
FROM #SA
ORDER BY
    [SERVICE_AGREEMENT_ID];

OPEN sa_cursor;

FETCH NEXT FROM sa_cursor INTO @ServiceAgreementId, @Description, @EffectiveDate, @ExpirationDate;

SET @NewExpirationDate = GETDATE();

WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @Comment VARCHAR(500), @StateString VARCHAR(500)

	PRINT ('......updating Service Agreement ' + CAST(@ServiceAgreementId AS VARCHAR(10)) + ' / ' + @Description + ': Effective Date: ' + CAST(FORMAT(@EffectiveDate, 'MM/dd/yyyy') AS VARCHAR(25)) + ' / Expiration Date: ' + CAST(FORMAT(@ExpirationDate, 'MM/dd/yyyy') AS VARCHAR(25)) + '; New Expiration Date: ' + CAST(FORMAT(@NewExpirationDate, 'MM/dd/yyyy') AS VARCHAR(25)));

	UPDATE [SERVICE_AGREEMENT]
	    SET [EXPIRATION_DATE] = @NewExpirationDate
	       ,[CHANGED_DATE_TIME] = @ChangedDate
		   ,[CHANGING_USER_PROFILE_ID] = @ChangingUserId
	WHERE
	    [SERVICE_AGREEMENT_ID] = @ServiceAgreementId;

	SET @Comment = 'Client migration: Expiring service agreement to prevent access: ' + @Description;
	SET @StateString = '{"Expiration Date":"' + CAST(@NewExpirationDate AS VARCHAR(50)) + '"}';

	-- Write audit logs for the users for audits
	EXEC [dbo].[Maintenance_LogAdminAction]
			 @ObjectId = @ServiceAgreementId
			,@AdministratorUsername = @ChangingUserName
			,@ObjectType = 'Service Agreement'
			,@EventName = 'Update'
			,@Comment = @Comment
			,@StateString = @StateString
			,@PrintDiagnostics = 0;

	SET @SACountAfterUpdate = @SACountAfterUpdate + 1;

    FETCH NEXT FROM sa_cursor INTO @ServiceAgreementId, @Description, @EffectiveDate, @ExpirationDate;
END

PRINT ('...expired ' + CAST(@SACountAfterUpdate AS VARCHAR(50)) + ' Service Agreement records');

CLOSE sa_cursor;
DEALLOCATE sa_cursor;
GO
