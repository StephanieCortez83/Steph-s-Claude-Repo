----------------------------------------
-- 03) DACS-3365 - SQL Script will Delete Denial entry from Catalog table
----------------------------------------

USE ReportServer
GO

BEGIN TRANSACTION
BEGIN TRY    
    DECLARE @ITEM_ID uniqueidentifier

    SELECT @ITEM_ID = ItemId FROM [dbo].[Catalog] where name = 'Denial Billing Summary'

    DELETE FROM dbo.DataSource WHERE ITEMID = @ITEM_ID

    DELETE FROM [dbo].[Catalog] where ITEMID = @ITEM_ID

    COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
