----------------------------------------
-- 02) DACS-3365 - SQL Script will Delete Denial group Rights for reports for user groups
----------------------------------------

USE RevCycleDB
GO

BEGIN TRANSACTION
BEGIN TRY
    DECLARE @PORTAL_REPORT_ID INT

	SELECT TOP 1 @PORTAL_REPORT_ID = portal_report_id FROM PORTAL_REPORT where name = 'Denials Monthly Reporting'

	DELETE FROM USER_GROUP_TO_PORTAL_REPORT WHERE portal_report_id = @PORTAL_REPORT_ID

    DELETE FROM PORTAL_REPORT where name = 'Denials Monthly Reporting'

    COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
