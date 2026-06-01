SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dbo].[InsertFHIRSettings]    
  @ServiceAgreementId int    
 ,@EMRTypeId int  = null  
 ,@OrganizationId varchar(1000) = null    
 ,@ResourceId varchar(5000) = null  
 ,@RetrievalDelay int = null
 ,@MaxRetries int =  null
 ,@RetryTimeout int = null
 ,@TimeZonesId int
 ,@CreatedByUserProfileId int = NULL    
 ,@LastUpdatedByUserProfileId int = NULL    
 ,@FHIRSettingsId int OUTPUT    
AS    
    
INSERT INTO [dbo].[FHIRSettings]    
(    
 [ServiceAgreementId]    
 ,[EMRTypeId]    
 ,[OrganizationId]    
 ,[ResourceId]
 ,[RetrievalDelay]
 ,[MaxRetries]
 ,[RetryTimeout]
 ,[TimeZonesId]
 ,[CreatedByUserProfileId]    
 ,[LastUpdatedByUserProfileId]    
)    
VALUES    
(    
 @ServiceAgreementId    
 ,@EMRTypeId    
 ,@OrganizationId    
 ,@ResourceId    
 ,@RetrievalDelay
 ,@MaxRetries
 ,@RetryTimeout
 ,@TimeZonesId
 ,@CreatedByUserProfileId    
 ,@LastUpdatedByUserProfileId     
)    
    
SET @FHIRSettingsId = @@IDENTITY    
GO
