USE [RevCycleDB]
GO

INSERT INTO [dbo].[ChargeMasterAutomationExcludeReason]
           ([Description]
           ,[DateTimeExpiration]
           ,[DateTimeEffective]
           ,[DateTimeCreated]
           ,[CreatedByUserProfileId]
           ,[DateTimeLastUpdated]
           ,[LastUpdatedByUserProfileId])
     VALUES
           ('Low Confidence'
           ,'12/31/2099'
           ,'06/01/2023'
           ,'06/01/2023'
           , 10037
           ,'06/01/2023'
           , 10037);

INSERT INTO [dbo].[ChargeMasterAutomationExcludeReason]
           ([Description]
           ,[DateTimeExpiration]
           ,[DateTimeEffective]
           ,[DateTimeCreated]
           ,[CreatedByUserProfileId]
           ,[DateTimeLastUpdated]
           ,[LastUpdatedByUserProfileId])
     VALUES
           ('Not Charged by Facility'
           ,'12/31/2099'
           ,'06/01/2023'
           ,'06/01/2023'
           , 10037
           ,'06/01/2023'
           , 10037);