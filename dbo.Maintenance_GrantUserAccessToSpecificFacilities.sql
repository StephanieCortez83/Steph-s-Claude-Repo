SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------  
-- Purpose - Grant access to given user on all facilities  
-- Created By - Kalpana Panwar  
-- Created On - 08/07/2023
-- Modified By - Pippin (DACS-2848 adjust fields updated and messaging)
-- Modified on - 10/26/2023
---------------------------------------------------------------------------------  
--USAGE
--EXEC [dbo].[Maintenance_GrantUserAccessToSpecificFacilities] 
--@Facility_id_list = '1353,965,940,983,939,937,938,985,934,1155,1542,1543,1544,1545,1546,1548,1549,1550,1551',
--@UserProfileId = 10245, @AdministratorUsername = 'MFERRELL', @EffectiveDate = '8/7/2023 12:00:00 AM', @ExpirationDate = '12/31/2099 12:00:00 AM'  
CREATE   PROCEDURE [dbo].[Maintenance_GrantUserAccessToSpecificFacilities]  
  @Facility_id_list 				AS VARCHAR(MAX)
 ,@UserProfileId        			AS INT = NULL  
 ,@Username         				AS VARCHAR(15) = NULL  
 ,@AdministratorUsername			AS VARCHAR(15)  
 ,@EffectiveDate        			AS DATETIME  
 ,@ExpirationDate       			AS DATETIME  
 ,@AllowAutomationFacilitiesOnly 	AS BIT = 0  
 ,@CanApproveCharts       			AS BIT = 0  
 ,@AuditApprovalRate       			AS BIT = 0  
 ,@SecondLevelAuditApprovalRate  	AS BIT = 0  
 ,@IncludeDemoSites					AS BIT = 0   
AS  
BEGIN    
  SET NOCOUNT ON  
  print('UserProfileId = ' + IIF(@UserProfileId IS NULL, 'NULL', CAST(@UserProfileId AS VARCHAR(50))));
  print('Username = ' + IIF(@Username IS NULL, 'NULL', CAST(@Username AS VARCHAR(50))));
  print('AdministratorUsername = ' + IIF(@AdministratorUsername IS NULL, 'NULL', CAST(@AdministratorUsername AS VARCHAR(50))));
  print('EffectiveDate = ' + IIF(@EffectiveDate IS NULL, 'NULL', CAST(@EffectiveDate AS VARCHAR(50))));
  print('ExpirationDate = ' + IIF(@ExpirationDate IS NULL, 'NULL', CAST(@ExpirationDate AS VARCHAR(50))));
  print('AllowAutomationFacilitiesOnly = ' + IIF(@AllowAutomationFacilitiesOnly IS NULL, 'NULL', CAST(@AllowAutomationFacilitiesOnly AS VARCHAR(50))));
  print('CanApproveCharts = ' + IIF(@CanApproveCharts IS NULL, 'NULL', CAST(@CanApproveCharts AS VARCHAR(50))));
  print('AuditApprovalRate = ' + IIF(@AuditApprovalRate IS NULL, 'NULL', CAST(@AuditApprovalRate AS VARCHAR(50))));
  print('SecondLevelAuditApprovalRate = ' + IIF(@SecondLevelAuditApprovalRate IS NULL, 'NULL', CAST(@SecondLevelAuditApprovalRate AS VARCHAR(50))));
  print('Facility_id_list = ' + IIF(@Facility_id_list IS NULL, 'NULL', @Facility_id_list));
  print('IncludeDemoSites = ' + IIF(@IncludeDemoSites IS NULL, 'NULL', CAST(@IncludeDemoSites AS VARCHAR(50))));
  IF @EffectiveDate IS NULL  
  BEGIN  
   SELECT 'ERROR' = 'Effective Date is required';
  END  
  IF @ExpirationDate IS NULL  
  BEGIN  
   SELECT 'ERROR' = 'Expiration Date is required';
  END  
  ---------------------------------------------------------  
  -- GET ADMINISTRATOR INFO  
  -------------------------------------------------------  
  DECLARE @RowCount      				INT; 
  DECLARE @AdministratorUserProfileId  	INT;
  DECLARE @AdministratorEmailAddress  	VARCHAR(50);  
  DECLARE @AdministratorFirstName   	VARCHAR(25);  
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
  ---------------------------------------------------------  
  -- GET USER PROFILE INFO  
  -------------------------------------------------------  
  IF @UserProfileId IS NULL AND @Username IS NULL  
  BEGIN    
   SELECT 'ERROR' = 'Please provide a User Profile ID OR Sign On ID to grant access';
   RETURN   
  END 
  IF @UserProfileId IS NOT NULL AND @Username IS NOT NULL  
  BEGIN  
   IF NOT EXISTS(SELECT 1 FROM [USER_PROFILE] WITH (NOLOCK) WHERE [USER_PROFILE].[SIGN_ON_ID] = @Username AND [USER_PROFILE].[USER_PROFILE_ID] = @UserProfileId)  
   BEGIN  
     SELECT 'ERROR' = 'User Profile ID ' + CAST(@UserProfileId AS VARCHAR(50)) + ' AND Sign On ID ' + @Username + ' combination not found in the system.';
     RETURN  
   END  
  END  
  ELSE IF @Username IS NOT NULL  
  BEGIN  
   SELECT @UserProfileId = [USER_PROFILE].[USER_PROFILE_ID] FROM [USER_PROFILE] WITH (NOLOCK) WHERE [USER_PROFILE].[SIGN_ON_ID] = @Username  
   IF @UserProfileId IS NULL  
   BEGIN  
     SELECT 'ERROR' = 'Sign On ID ' + @Username + ' not found in the system.';
     RETURN  
   END  
  END  
  ELSE IF @UserProfileId IS NOT NULL  
  BEGIN  
   IF NOT EXISTS(SELECT 1 FROM [USER_PROFILE] WITH (NOLOCK) WHERE [USER_PROFILE].[USER_PROFILE_ID] = @UserProfileId)  
   BEGIN  
     SELECT 'ERROR' = 'User Profile ID ' + CAST(@UserProfileId AS VARCHAR(50)) + ' not found in the system.';
     RETURN  
   END  
  END  
----  
print('--------------------------  Processing  ---------------------');
BEGIN TRANSACTION
BEGIN TRY  
  DECLARE @RowCountFound     			INT  
  DECLARE @FacilityComment    			VARCHAR(255)  
  DECLARE @FacilityId      				INT  
  DECLARE @FacilityAuthId     			INT  
  DECLARE @StateString     				VARCHAR(MAX)  
  DECLARE @OutputAuditLogObjectStateId 	INT  
  DECLARE @OutputAuditLogId    			INT  
  SELECT DISTINCT [SERVICE_AGREEMENT].[FACILITY_ID]  
  INTO #FacilityUserAuthorization  
  FROM [SERVICE_AGREEMENT]
  WHERE   
  -- make sure it's not a demo service agreement  
  ( (@IncludeDemoSites = 1) OR
	(  
	[SERVICE_AGREEMENT].[DEMO_TEST_SITE_IND] IS NULL   
	OR   
	 [SERVICE_AGREEMENT].[DEMO_TEST_SITE_IND] = 0  
	)  
	AND [SERVICE_AGREEMENT].[DESCRIPTION] NOT LIKE 'Practice%'  
	AND [SERVICE_AGREEMENT].[DESCRIPTION] NOT LIKE 'Demo%'
  )
  -- make sure it's only for non-expired service agreements  
  AND [SERVICE_AGREEMENT].[EXPIRATION_DATE] > GETDATE()  
  -- make sure the user doesn't already have a facility user authorizaton for the current facility id  
  AND [SERVICE_AGREEMENT].[FACILITY_ID] NOT IN   
  (  
   -- get a list of the user's current authorized facilties  
   SELECT [FACILITY_USER_AUTHORIZATION].[FACILITY_ID]   
   FROM [FACILITY_USER_AUTHORIZATION]  
   WHERE [FACILITY_USER_AUTHORIZATION].[USER_PROFILE_ID] = @UserProfileId   
    AND @EffectiveDate BETWEEN [FACILITY_USER_AUTHORIZATION].[EFFECTIVE_DATE] AND [FACILITY_USER_AUTHORIZATION].[EXPIRATION_DATE]  
  )   
  -- make sure the user doesn't already have a FUTURE facility user authorizaton for the current facility id  
  AND [SERVICE_AGREEMENT].[FACILITY_ID] NOT IN   
  (  
   SELECT [FACILITY_USER_AUTHORIZATION].[FACILITY_ID]   
   FROM [FACILITY_USER_AUTHORIZATION]  
   WHERE [FACILITY_USER_AUTHORIZATION].[USER_PROFILE_ID] = @UserProfileId   
    AND [FACILITY_USER_AUTHORIZATION].[EFFECTIVE_DATE] > @EffectiveDate  
  )   
  ---- only authorize to automation facilities if required  
  AND   
  (   
   @AllowAutomationFacilitiesOnly = 0  
   OR  
   @AllowAutomationFacilitiesOnly = 1 AND [SERVICE_AGREEMENT].[AUTOMATION_CODING_ENABLED] = 1  
  )  
  AND
  EXISTS (SELECT * FROM  dbo.SplitString(@Facility_id_list, ',') WHERE items = [SERVICE_AGREEMENT].[FACILITY_ID])
  SET @RowCount = @@ROWCOUNT  
  SET @RowCountFound  = @RowCount      
DECLARE @countFacilityUserAuthorization INT = (SELECT COUNT(*) FROM #FacilityUserAuthorization);
print('countFacilityUserAuthorization = ' + IIF(@countFacilityUserAuthorization IS NULL, 'NULL', CAST(@countFacilityUserAuthorization AS VARCHAR(50))));
--select * from #FacilityUserAuthorization;
print('--------------------------  Begin While loop  ---------------------');
  WHILE(@RowCount > 0)  
  BEGIN     
   print(IIF(@RowCount IS NULL,'NULL',CAST((@RowCount + 1) AS VARCHAR(50))) + ') loop start.')
   SET @RowCount = @RowCount - 1  
   SELECT @FacilityId = [FACILITY_ID]  
   FROM #FacilityUserAuthorization
   ORDER BY [FACILITY_ID]  
   OFFSET @RowCount ROWS   
   FETCH NEXT 1 ROWS ONLY;  
   print(IIF(@RowCount IS NULL,'NULL',CAST((@RowCount + 1) AS VARCHAR(50))) 
	+ ') @FacilityId[' + IIF(@FacilityId IS NULL,'NULL',CAST(@FacilityId AS VARCHAR(50))) 
	+ '] @UserProfileId[' + IIF(@UserProfileId IS NULL,'NULL',CAST(@UserProfileId AS VARCHAR(50))) + '].')
   INSERT INTO [dbo].[FACILITY_USER_AUTHORIZATION]  
   (  
     [FACILITY_ID]  
    ,[USER_PROFILE_ID]  
    ,[CREATION_DATE_TIME]  
    ,[CREATING_USER_PROFILE_ID]  
    ,[CHANGED_DATE_TIME]  
    ,[CHANGING_USER_PROFILE_ID]  
    ,[EFFECTIVE_DATE]  
    ,[EXPIRATION_DATE]  
    ,[CAN_APPROVE_CHARTS]  
    ,[AUDIT_APPROVAL_RATE]  
    ,[NUMBER_COMPLETED]  
    ,[AUDIT_PROCEDURE_RATE]  
    ,[PROCEDURE_NUMBER_COMPLETED]  
    ,[ACCOUNT_MANAGER_IND]  
    ,[AUDIT_INFUSION_RATE]  
    ,[INFUSION_NUMBER_COMPLETED]  
    ,[AUDIT_OBSERVATION_RATE]  
    ,[OBSERVATION_NUMBER_COMPLETED]  
    ,[CODER_AUTHORIZED_SERVICE_CODE]  
    ,[FACILITY_PROF_ID]  
    ,[SECOND_LEVEL_AUDIT_APPROVAL_RATE]  
    ,[FORCE_AUDIT]  
   )  
   VALUES  
   (  
    @FacilityId,  
    @UserProfileId,  
    GETDATE(),  
    @AdministratorUserProfileId,   
    NULL,   
    NULL,  
    @EffectiveDate,   
    @ExpirationDate,  
    @CanApproveCharts,   
    @AuditApprovalRate,  
    0,   
    0,   
    0,   
    0,  
    0,  
    0,  
    0,  
    0,  
    0,  
    NULL,  
    @SecondLevelAuditApprovalRate,  
    0      
   )  
   SELECT @FacilityAuthId = SCOPE_IDENTITY();    
   print(CAST(@RowCount AS VARCHAR(50)) + ') @FacilityId ['+ CAST(@FacilityId AS VARCHAR(50)) +'] FacilityAuthId[' + CAST(@FacilityAuthId AS VARCHAR(50)) + ']')
   ---------------------------------------------------------------------  
   -- HANDLE LOGGING  
   ---------------------------------------------------------------------  
   -- INSERT "FACILITY AUTHORIZATION" AUDIT LOG & AUDIT LOG OBJECT STATE  
   SET @FacilityComment = 'Inserted authorized facility ID ' + CAST(@FacilityId AS VARCHAR)  
   SET @StateString =   '{'  
        + '"Facility Authorization ID":"'   
        + CAST(@FacilityAuthId AS VARCHAR)  
        + '","Facility ID":"'  
        + CAST(@FacilityId AS VARCHAR)  
        + '","User Profile ID":"'  
        + CAST(@UserProfileId AS VARCHAR)  
        + '","Effective Date":"'  
        + FORMAT(CONVERT(DATE, @EffectiveDate), 'MM/dd/yyyy hh:mm:ss tt')   
        + '","Expiration Date":"'  
        + + FORMAT(CONVERT(DATE, @ExpirationDate), 'MM/dd/yyyy hh:mm:ss tt')   
        + '","Can Approve Charts":"'  
        + CASE @CanApproveCharts WHEN 1 THEN 'True' ELSE 'False' END  
        + '","First Level Audit Rate":"'  
        + CASE @AuditApprovalRate WHEN 1 THEN 'True' ELSE 'False' END               
        + '","Number Completed":"0'  
        + '","Audit Procedure Rate":"0'  
        + '","Procedure Number Completed":"0'  
        + '","Account Manager Indicator":"0'  
        + '","Audit Infusion Rate":"0'  
        + '","Infusion Number Completed":"0'  
        + '","Audit Observation Rate":"0'  
        + '","Observation Number Completed":"0'  
        + '","Coder Authorized Service Code":"0'  
        + '","Second Level Audit Rate":"0'  
        + CAST(@SecondLevelAuditApprovalRate AS VARCHAR)  
        + '","Force Audit": "False"'  
        + '}'  
   EXEC [dbo].[AUDIT_LOG_INSERT]  
    @OBJECT_TYPE =     'Facility Authorization'  
    ,@OBJECT_ID =      @FacilityAuthId  
    ,@EVENT_NAME =     'Create'  
    ,@COMMENT =      ''  
    ,@CHANGING_USER_PROFILE_ID =  @AdministratorUserProfileId  
    ,@CHANGING_SIGN_ON_ID =   @AdministratorUsername  
    ,@CHANGING_EMAIL_ADDRESS =  @AdministratorEmailAddress  
    ,@CHANGING_FIRST_NAME =   @AdministratorFirstName  
    ,@CHANGING_LAST_NAME =   @AdministratorLastName  
    ,@AUDIT_LOG_ID =     @OutputAuditLogId OUTPUT  
   EXEC [dbo].[AUDIT_LOG_OBJECT_STATE_INSERT]  
    @AUDIT_LOG_ID =     @OutputAuditLogId  
    ,@STATE =      @StateString  
    ,@AUDIT_LOG_OBJECT_STATE_ID = @OutputAuditLogObjectStateId  
   -- INSERT "USER PROFILE" AUDIT LOG & AUDIT LOG OBJECT STATE  
   EXEC [dbo].[AUDIT_LOG_INSERT]  
    @OBJECT_TYPE =     'User Profile'  
    ,@OBJECT_ID =      @UserProfileId  
    ,@EVENT_NAME =     'Updated'  
    ,@COMMENT =      @FacilityComment  
    ,@CHANGING_USER_PROFILE_ID =  @AdministratorUserProfileId  
    ,@CHANGING_SIGN_ON_ID =   @AdministratorUsername  
    ,@CHANGING_EMAIL_ADDRESS =  @AdministratorEmailAddress  
    ,@CHANGING_FIRST_NAME =   @AdministratorFirstName  
    ,@CHANGING_LAST_NAME =   @AdministratorLastName  
    ,@AUDIT_LOG_ID =     @OutputAuditLogId OUTPUT  
   EXEC [dbo].[AUDIT_LOG_OBJECT_STATE_INSERT]  
    @AUDIT_LOG_ID =     @OutputAuditLogId  
    ,@STATE =      @StateString  
    ,@AUDIT_LOG_OBJECT_STATE_ID = @OutputAuditLogObjectStateId   
  print(IIF(@RowCount IS NULL, 'NULL', CAST((@RowCount + 1) AS VARCHAR(50))) 
	+ ') @RowCountFound [' + IIF(@RowCountFound IS NULL, 'NULL', CAST(@RowCountFound AS VARCHAR(50)))
	+ '] FacilityAuthId[' + IIF(@FacilityAuthId IS NULL, 'NULL', CAST(@FacilityAuthId AS VARCHAR(50))) + ']');
  print('--------------------------  End While loop  ---------------------');
  END;  
COMMIT TRANSACTION;
  IF @RowCountFound > 0   
    PRINT CAST(@RowCountFound AS VARCHAR) + ' Records Inserted Sucessfully.'  
  ELSE  
    PRINT 'No Records found.'  
END TRY  
BEGIN CATCH    
  PRINT 'ERROR :: Rolling back transaction'  
  IF (@@TRANCOUNT > 0)  
    ROLLBACK TRAN  
    SELECT 'ERROR' = 'Exception updating access for: ' + CAST(@UserProfileId AS VARCHAR(50)) + ' :: ' + ERROR_MESSAGE();
	RETURN
END CATCH  
SELECT 'DONE' = 'Updated access for: ' + CAST(@UserProfileId AS VARCHAR(50)) + ',  Source count = ' +IIF(@countFacilityUserAuthorization IS NULL, 'NULL', CAST(@countFacilityUserAuthorization AS VARCHAR(50))) ;
END ;
GO
