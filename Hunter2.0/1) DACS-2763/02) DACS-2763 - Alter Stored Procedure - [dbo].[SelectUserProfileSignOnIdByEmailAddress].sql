----------------------------------------
-- 02) DACS-2763 - Alter Stored Procedure - [dbo].[SelectUserProfileSignOnIdByEmailAddress].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
