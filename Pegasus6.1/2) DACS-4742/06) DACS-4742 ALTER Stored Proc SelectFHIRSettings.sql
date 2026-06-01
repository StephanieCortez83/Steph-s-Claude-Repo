----------------------------------------
-- 06) DACS-4742 - alter Stored Proc [InsertFHIRSettings]
----------------------------------------
USE [RevCycleDB]
GO
/****** Object:  StoredProcedure [dbo].[SelectFHIRSettings]    Script Date: 9/29/2025 11:14:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER    PROCEDURE [dbo].[SelectFHIRSettings]  
AS  
  
SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
SELECT  
  [FHIRSettingsId]  
 ,[ServiceAgreementId]  
 ,[EMRTypeId]  
 ,[OrganizationId]  
 ,[ResourceId]  
 ,[RetrievalDelay]
 ,[MaxRetries]
 ,[RetryTimeout]
 ,[TimeZonesId]
 ,[DateTimeCreated]  
 ,[CreatedByUserProfileId]  
 ,[DateTimeLastUpdated]  
 ,[LastUpdatedByUserProfileId]  
FROM  
 [FHIRSettings]  
  