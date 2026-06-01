----------------------------------------
-- 01) DACS-3365 - SQL Script will Delete Denial group Rights and Denial User Group
----------------------------------------

USE RevCycleDB
GO

BEGIN TRANSACTION
BEGIN TRY
    DECLARE @USER_GROUP_ID INT
    DECLARE @CODER_USER_GROUP_ID INT

    SELECT @USER_GROUP_ID = user_group_id FROM dbo.user_group WHERE name = 'Denial Management Administration'

    --DELETE ALL GROUP RIGHTS FOR DENIAL MGMT ADMIN
    DELETE FROM [DBO].[group_rights]
    WHERE user_group_id = @USER_GROUP_ID

    --Remove additional group assignment for this user group
    DELETE FROM [dbo].[USER_GROUP_TO_USER_PROFILE]
    WHERE user_group_id = @USER_GROUP_ID 
       
    SELECT @CODER_USER_GROUP_ID = user_group_id  FROM dbo.user_group WHERE name = 'Coders'

	SELECT * FROM [dbo].[user_profile] WHERE user_group_id = @USER_GROUP_ID

    UPDATE [dbo].[user_profile]
    SET user_group_id = @CODER_USER_GROUP_ID
    WHERE 
    user_group_id = @USER_GROUP_ID

    PRINT 'Verify all denial users are updated to Coders user group'

    SELECT COUNT(*) FROM [dbo].[user_profile] WHERE user_group_id = @USER_GROUP_ID

	--DELETE DENIAL MGMT ADMIN USER GROUP
    DELETE FROM [dbo].[user_group]
    WHERE user_group_id = @USER_GROUP_ID

    SELECT @USER_GROUP_ID = user_group_id FROM dbo.user_group WHERE name = 'Denial Management Administration 2'

	--Remove additional group assignment for this user group
    DELETE FROM [dbo].[USER_GROUP_TO_USER_PROFILE]
    WHERE user_group_id = @USER_GROUP_ID 

    --DELETE DENIAL MGMT ADMIN USER GROUP
    DELETE FROM [dbo].[user_group]
    WHERE user_group_id = @USER_GROUP_ID

    COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
