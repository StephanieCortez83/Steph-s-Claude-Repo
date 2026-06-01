SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertUserFailedLogonByUserProfileIdAndUserHostAndFromHostAndServerName] 
	 @UserProfileId INT
	,@UserHostAddress VARCHAR(100)
	,@LogonFromHost VARCHAR(256)
	,@ServerName VARCHAR(256)
WITH EXEC AS CALLER AS
BEGIN
	-- input param validation handled by ACS calling process.
	INSERT INTO USER_FAILED_LOGON 
		(
			 USER_PROFILE_ID
			,FAILED_LOGON_DATE_TIME
			,USER_HOST_ADDRESS
			,LOGON_FROM_HOST
			,SERVER_NAME
		)
	VALUES
		(
			 @UserProfileId
			,GETDATE()
			,@UserHostAddress
			,@LogonFromHost
			,@ServerName
		);	

/*
usage:
exec [dbo].[InsertUserFailedLogonByUserProfileIdAndUserHostAndFromHostAndServerName] @UserProfileId = 80,@UserHostAddress='UserHostAddress',@LogonFromHost='LogonFromHost',@ServerName='ServerName';
*/
END -- end procedure

GO
