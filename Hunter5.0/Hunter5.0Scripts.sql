USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2864 - Add stored procedure - [dbo].[Maintenance_LogAdminAction].sql

----------------------------------------
-- 01) DACS-2864 - Add stored procedure - [dbo].[Maintenance_LogAdminAction].sql
----------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_LogAdminAction]  
	 @AdministratorUsername			AS VARCHAR(25)  	-- 'WPIPPIN'
	,@ObjectId						AS INT  			-- 12345
	,@ObjectType					AS VARCHAR(64)  	-- 'Service Agreement', or whatever is being worked on
	,@EventName						AS VARCHAR(32)  	-- 'Create', 'Update', etc.
	,@Comment    					AS VARCHAR(255) 	-- 'I did something that needs logging'
	,@StateString     				AS VARCHAR(MAX)   	--  will accept a JSON formatted string or string (which gets turned into a JSON formatted string)
AS  
BEGIN    
	SET NOCOUNT ON  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	print('AdministratorUsername = ' + IIF(@AdministratorUsername IS NULL, 'NULL', CAST(@AdministratorUsername AS VARCHAR(50))));
	print('ObjectId = ' + IIF(@ObjectId IS NULL, 'NULL', CAST(@ObjectId AS VARCHAR(50))));
	print('ObjectType = ' + IIF(@ObjectType IS NULL, 'NULL', CAST(@ObjectType AS VARCHAR(64))));
	print('EventName = ' + IIF(@EventName IS NULL, 'NULL', CAST(@EventName AS VARCHAR(50))));
	print('Comment = ' + IIF(@Comment IS NULL, 'NULL', CAST(@Comment AS VARCHAR(255))));

	IF @StateString NOT LIKE '{%' AND @StateString NOT LIKE '%"%' AND @StateString NOT LIKE '%:%' AND @StateString NOT LIKE '%}'
	BEGIN
		SET @StateString = '{"Information":"' + @StateString + '"}';
	END;

	print('StateString = ' + IIF(@StateString IS NULL, 'NULL', CAST(@StateString AS VARCHAR(MAX))));

	IF @AdministratorUsername IS NULL OR LEN(@AdministratorUsername) <= 0   
	BEGIN  
		SELECT 'ERROR' = '@AdministratorUsername is invalid.';
		RETURN  
	END  

	---------------------------------------------------------  
	-- GET ADMINISTRATOR INFO  
	-------------------------------------------------------  
	DECLARE @RowCount      					INT; 
	DECLARE @AdministratorUserProfileId  	INT;
	DECLARE @AdministratorEmailAddress  	VARCHAR(128);  
	DECLARE @AdministratorFirstName   		VARCHAR(25);  
	DECLARE @AdministratorLastName   		VARCHAR(25);  

	SELECT  
		 @AdministratorUserProfileId = [USER_PROFILE].[USER_PROFILE_ID]  
		,@AdministratorEmailAddress = [USER_PROFILE].[EMAIL_ADDRESS]  
		,@AdministratorFirstName = [USER_PROFILE].[FIRST_NAME]  
		,@AdministratorLastName = [USER_PROFILE].[LAST_NAME]  
	FROM  
		[dbo].[USER_PROFILE] WITH (NOLOCK)   
	WHERE  
		[USER_PROFILE].[SIGN_ON_ID] = @AdministratorUsername   

	IF @ROWCOUNT > 1  
	BEGIN  
		SELECT 'ERROR' = 'Found multiple entries for admin ' + @AdministratorUsername;
		RETURN  
	END  

	IF @AdministratorUserProfileId IS NULL   
	BEGIN  
		SELECT 'ERROR' = '@AdministratorUserProfileId is null.';
		RETURN  
	END  

	print('AdministratorUserProfileId = ' + IIF(@AdministratorUserProfileId IS NULL, 'NULL', CAST(@AdministratorUserProfileId AS VARCHAR(250))));
	print('AdministratorEmailAddress = ' + IIF(@AdministratorEmailAddress IS NULL, 'NULL', CAST(@AdministratorEmailAddress AS VARCHAR(250))));
	print('AdministratorFirstName = ' + IIF(@AdministratorFirstName IS NULL, 'NULL', CAST(@AdministratorFirstName AS VARCHAR(250))));
	print('AdministratorLastName = ' + IIF(@AdministratorLastName IS NULL, 'NULL', CAST(@AdministratorLastName AS VARCHAR(250))));


   ---------------------------------------------------------------------  
   -- HANDLE LOGGING  
   ---------------------------------------------------------------------  
	DECLARE @OutputAuditLogObjectStateId 	INT  
	DECLARE @OutputAuditLogId    			INT  
  
	EXEC [dbo].[AUDIT_LOG_INSERT]  
		 @OBJECT_TYPE =     			@ObjectType  
		,@OBJECT_ID =     				@ObjectId 
		,@EVENT_NAME =     				@EventName  
		,@COMMENT =      				@Comment 
		,@CHANGING_USER_PROFILE_ID =  	@AdministratorUserProfileId  
		,@CHANGING_SIGN_ON_ID =   		@AdministratorUsername  
		,@CHANGING_EMAIL_ADDRESS =  	@AdministratorEmailAddress  
		,@CHANGING_FIRST_NAME =   		@AdministratorFirstName  
		,@CHANGING_LAST_NAME =   		@AdministratorLastName  
		,@AUDIT_LOG_ID =     			@OutputAuditLogId OUTPUT  

	EXEC [dbo].[AUDIT_LOG_OBJECT_STATE_INSERT]  
		 @AUDIT_LOG_ID =     			@OutputAuditLogId  
		,@STATE =      					@StateString  
		,@AUDIT_LOG_OBJECT_STATE_ID = 	@OutputAuditLogObjectStateId OUTPUT  


	SELECT 'SUCCESS' = 
		'@OutputAuditLogId = [' + IIF(@OutputAuditLogId IS NULL, 'NULL', CAST(@OutputAuditLogId AS VARCHAR(50))) 
		+ '].  @OutputAuditLogObjectStateId = [' + IIF(@OutputAuditLogObjectStateId IS NULL, 'NULL', CAST(@OutputAuditLogObjectStateId AS VARCHAR(50))) + ']';

END

GO


/*
testing
begin tran;
exec [dbo].[Maintenance_LogAdminAction]  
	 @AdministratorUsername			= 'WPIPPIN'
	,@ObjectId						= 1
	,@ObjectType					= 'Test'
	,@EventName						= 'Create'
	,@Comment    					= 'I did something that needs logging'
	,@StateString     				= 'State string giving information about the action' 

select * FROM AUDIT_LOG WHERE AUDIT_LOG_ID = 2100121311;
select * FROM AUDIT_LOG_OBJECT_STATE WHERE AUDIT_LOG_OBJECT_STATE_ID = ;

select TOP 10 * FROM AUDIT_LOG ORDER BY AUDIT_LOG_ID DESC ;
select TOP 10 * FROM AUDIT_LOG_OBJECT_STATE ORDER BY AUDIT_LOG_OBJECT_STATE_ID DESC ;

@OutputAuditLogId = [2100121311].  @OutputAuditLogObjectStateId = [2100121334]
*/
-- End of 01) DACS-2864 - Add stored procedure - [dbo].[Maintenance_LogAdminAction].sql
GO

-- Start of 01) DACS-2807 - Create OR Alter Procedure - [dbo].[SelectDefinedRightsByUserGroupId].sql

-----------------------------------------------------
-- 01) DACS-2807 - Create OR Alter Procedure - [dbo].[SelectDefinedRightsByUserGroupId].sql
-----------------------------------------------------
GO

GO

GO


CREATE OR ALTER PROCEDURE [dbo].[SelectDefinedRightsByUserGroupId]
	@UserGroupId INT
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @UserGroupId < 0
	BEGIN
		print('Invalid User Group Id');
		RETURN;
	END;

	SELECT 
		DR.DEFINED_RIGHT_ID
		, DR.NAME
		, GR.GROUP_RIGHT_ID
		, DR.IS_ADMIN
    FROM 
		DEFINED_RIGHT DR 
		LEFT OUTER JOIN GROUP_RIGHTS GR ON DR.DEFINED_RIGHT_ID = GR.DEFINED_RIGHT_ID
        AND (GR.USER_GROUP_ID = @UserGroupId OR USER_GROUP_ID IS NULL)

GO

/*
begin tran;
exec [dbo].[SelectDefinedRightsByUserGroupId] @UserGroupId= 12;
*/
-- End of 01) DACS-2807 - Create OR Alter Procedure - [dbo].[SelectDefinedRightsByUserGroupId].sql
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
