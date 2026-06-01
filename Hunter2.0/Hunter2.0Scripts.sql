USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2763 - ALTER TABLE LOG_NOTE - widen details field to 4000.sql

-----------------------------------------------------------------------------
-- 01) DACS-2763 - ALTER TABLE LOG_NOTE - widen details field to 4000.sql
-----------------------------------------------------------------------------
GO

/*
  DBA, if needed please uncomment the table lock after this comment.
  Probably not needed but the target table has high record count and high use.
  Metadata change only, so might just be a case of being a bit paranoid on my part.
  Pippin
*/
-- SELECT	TOP (1) 1 FROM	[dbo].[LOG_NOTE] WITH (TABLOCKX)

ALTER TABLE [dbo].[LOG_NOTE] ALTER COLUMN [DETAIL] VARCHAR (4000) NULL;

GO
-- End of 01) DACS-2763 - ALTER TABLE LOG_NOTE - widen details field to 4000.sql
GO

-- Start of 02) DACS-2763 - Alter Stored Procedure - [dbo].[SelectUserProfileSignOnIdByEmailAddress].sql

----------------------------------------
-- 02) DACS-2763 - Alter Stored Procedure - [dbo].[SelectUserProfileSignOnIdByEmailAddress].sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectUserProfileSignOnIdByEmailAddress]
	@EmailAddress VARCHAR(50)
	
AS
BEGIN

	IF @EmailAddress IS NULL OR LEN(@EmailAddress) > 50 OR LEN(RTRIM(@EmailAddress)) < 3
	BEGIN
		SELECT 'SIGN_ON_ID' = 'Invalid Email Address'
		RETURN
	END;

	DECLARE @SearchEmail VARCHAR(54) = '%' + RTRIM(@EmailAddress) + '%';

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	SELECT 
		TOP 100 [SIGN_ON_ID]
	FROM 
		[RevCycleDB].[dbo].[USER_PROFILE] 
	WHERE 
		[EMAIL_ADDRESS] LIKE @SearchEmail
	ORDER BY [SIGN_ON_ID];

END
GO

/*
exec [dbo].[SelectUserProfileSignOnIdByEmailAddress] @EmailAddress= 'bill.pippin@corrohealth.com';
exec [dbo].[SelectUserProfileSignOnIdByEmailAddress] @EmailAddress= 'bill.pi';
exec [dbo].[SelectUserProfileSignOnIdByEmailAddress] @EmailAddress= 'bill';
exec [dbo].[SelectUserProfileSignOnIdByEmailAddress] @EmailAddress= NULL;
*/
-- End of 02) DACS-2763 - Alter Stored Procedure - [dbo].[SelectUserProfileSignOnIdByEmailAddress].sql
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
