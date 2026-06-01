SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_LogAdminAction]
	 @AdministratorUsername			AS VARCHAR(25)  	-- 'WPIPPIN'
	,@ObjectId						AS INT  			-- 12345
	,@ObjectType					AS VARCHAR(64)  	-- 'Service Agreement', or whatever is being worked on
	,@EventName						AS VARCHAR(32)  	-- 'Create', 'Update', etc.
	,@Comment    					AS VARCHAR(255) 	-- 'I did something that needs logging'
	,@StateString     				AS VARCHAR(MAX)   	--  will accept a JSON formatted string or string (which gets turned into a JSON formatted string)
    ,@PrintDiagnostics              AS BIT = 1          -- Set to 0 to not print diagnostics at the end to flood the GUI
AS  
BEGIN    
	SET NOCOUNT ON  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @PrintDiagnostics = 1
	BEGIN
	    print('AdministratorUsername = ' + IIF(@AdministratorUsername IS NULL, 'NULL', CAST(@AdministratorUsername AS VARCHAR(50))));
	    print('ObjectId = ' + IIF(@ObjectId IS NULL, 'NULL', CAST(@ObjectId AS VARCHAR(50))));
	    print('ObjectType = ' + IIF(@ObjectType IS NULL, 'NULL', CAST(@ObjectType AS VARCHAR(64))));
	    print('EventName = ' + IIF(@EventName IS NULL, 'NULL', CAST(@EventName AS VARCHAR(50))));
	    print('Comment = ' + IIF(@Comment IS NULL, 'NULL', CAST(@Comment AS VARCHAR(255))));
    END

	IF @StateString NOT LIKE '{%' AND @StateString NOT LIKE '%"%' AND @StateString NOT LIKE '%:%' AND @StateString NOT LIKE '%}'
	BEGIN
		SET @StateString = '{"Information":"' + @StateString + '"}';
	END;

	IF @PrintDiagnostics = 1
	BEGIN
	    print('StateString = ' + IIF(@StateString IS NULL, 'NULL', CAST(@StateString AS VARCHAR(MAX))));
	END

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

	IF @PrintDiagnostics = 1
	BEGIN
	    print('AdministratorUserProfileId = ' + IIF(@AdministratorUserProfileId IS NULL, 'NULL', CAST(@AdministratorUserProfileId AS VARCHAR(250))));
	    print('AdministratorEmailAddress = ' + IIF(@AdministratorEmailAddress IS NULL, 'NULL', CAST(@AdministratorEmailAddress AS VARCHAR(250))));
	    print('AdministratorFirstName = ' + IIF(@AdministratorFirstName IS NULL, 'NULL', CAST(@AdministratorFirstName AS VARCHAR(250))));
	    print('AdministratorLastName = ' + IIF(@AdministratorLastName IS NULL, 'NULL', CAST(@AdministratorLastName AS VARCHAR(250))));
    END
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

    IF @PrintDiagnostics = 1
    BEGIN
	    SELECT 'SUCCESS' =
	    	'@OutputAuditLogId = [' + IIF(@OutputAuditLogId IS NULL, 'NULL', CAST(@OutputAuditLogId AS VARCHAR(50)))
	    	+ '].  @OutputAuditLogObjectStateId = [' + IIF(@OutputAuditLogObjectStateId IS NULL, 'NULL', CAST(@OutputAuditLogObjectStateId AS VARCHAR(50))) + ']';
    END
END
GO
