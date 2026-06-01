SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertUserLogonByUserProfileIdAndUserHostAndUserTypeAndFromHostAndServerName] 
	 @UserProfileId INT
	,@UserHostAddress VARCHAR(100)
	,@UserLogonTypeCode INT = 1
	,@LogonFromHost VARCHAR(256)
	,@ServerName VARCHAR(256)
WITH EXEC AS CALLER AS
BEGIN
	-- input param validation handled by ACS calling process.
	INSERT INTO USER_LOGON 
		(
			 USER_PROFILE_ID
			,LOGON_DATE_TIME
			,USER_HOST_ADDRESS
			,USER_LOGON_TYPE_CODE
			,LOGON_FROM_HOST
			,SERVER_NAME
		)
	VALUES
		(
			 @UserProfileId
			,GETDATE()
			,@UserHostAddress
			,@UserLogonTypeCode
			,@LogonFromHost
			,@ServerName
		);	

/*
usage:
exec [dbo].[InsertUserLogonByUserProfileIdAndUserHostAndUserTypeAndFromHostAndServerName] @UserProfileId = 80,@UserHostAddress='UserHostAddress',@LogonFromHost='LogonFromHost',@ServerName='ServerName';
*/
END -- end procedure

GO
