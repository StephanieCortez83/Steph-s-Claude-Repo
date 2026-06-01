----------------------------------------
-- 08) DACS-4742 - alter Stored Proc UpdateByFHIRSettingsByFHIRSettingsId
----------------------------------------
USE [RevCycleDB]
GO
/****** Object:  StoredProcedure [dbo].[UpdateByFHIRSettingsByFHIRSettingsId]    Script Date: 9/29/2025 10:24:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
      
ALTER   PROCEDURE [dbo].[UpdateByFHIRSettingsByFHIRSettingsId]      
  @FHIRSettingsId int      
 ,@ServiceAgreementId int      
 ,@EMRTypeId int      
 ,@OrganizationId varchar(1000)
 ,@RetrievalDelay int
 ,@MaxRetries int
 ,@RetryTimeout int
 ,@ResourceId varchar(5000)  
 ,@TimeZonesId int
 ,@CreatedByUserProfileId int = NULL      
 ,@LastUpdatedByUserProfileId int = NULL     
AS      
      
UPDATE [dbo].[FHIRSettings]      
SET       
  [ServiceAgreementId] = @ServiceAgreementId      
 ,[EMRTypeId] = @EMRTypeId      
 ,[OrganizationId] = @OrganizationId      
 ,[ResourceId] = @ResourceId
 ,[RetrievalDelay] = @RetrievalDelay
 ,[MaxRetries] = @MaxRetries
 ,[RetryTimeout] = @RetryTimeout
 ,[TimeZonesId] = @TimeZonesId
 ,[CreatedByUserProfileId] = @CreatedByUserProfileId    
 ,[DateTimeLastUpdated] = GETDATE()    
 ,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId    
WHERE      
 [FHIRSettingsId] = @FHIRSettingsId 
  