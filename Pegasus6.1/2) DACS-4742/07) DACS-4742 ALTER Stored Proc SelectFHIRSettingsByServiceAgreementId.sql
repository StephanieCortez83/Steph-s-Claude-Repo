----------------------------------------
-- 07) DACS-4742 - alter Stored Proc [SelectFHIRSettingsByServiceAgreementId]
----------------------------------------
USE [RevCycleDB]
GO
/****** Object:  StoredProcedure [dbo].[[SelectFHIRSettingsByServiceAgreementId]]    Script Date: 9/29/2025 12:01:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER    PROCEDURE [dbo].[SelectFHIRSettingsByServiceAgreementId]  
  @ServiceAgreementId int  
 ,@PageIndex int = NULL  
    ,@PageSize int = 25  
    ,@WhereClause varchar(1000) = NULL  
    ,@OrderByClause varchar(250) = NULL  
    ,@RecordCount int OUTPUT  
AS  
  
SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
--[ID LIST]------------------------------------------------------  
  
CREATE TABLE #tmp  
(  
 [IndexId] int IDENTITY (1, 1) NOT NULL,  
 [FHIRSettingsId] int NOT NULL  
)  
  
DECLARE @sql nvarchar(2000)  
  
SET @sql = 'INSERT INTO #tmp (FHIRSettingsId) ' +  
     'SELECT [FHIRSettings].[FHIRSettingsId] ' +  
     'FROM [FHIRSettings] ' +  
     'WHERE [FHIRSettings].[ServiceAgreementId] = ' + CAST(@ServiceAgreementId AS VARCHAR(10))   
  
IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0  
 SET @sql = @sql + ' AND (' + @WhereClause + ') '  
  
IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0  
 SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '  
ELSE  
 SET @sql = @sql + 'ORDER BY [FHIRSettings].[DateTimeCreated] '  
  
EXEC sp_executesql @sql  
  
--[RANGE]----------------------------------------------------------  
  
SELECT @RecordCount = @@ROWCOUNT  
  
DECLARE @FirstRecord int  
DECLARE @LastRecord  int  
  
IF @PageIndex IS NOT NULL  
BEGIN  
 SET @FirstRecord = (@PageIndex * @PageSize) + 1  
 SET @LastRecord  = (@PageIndex  + 1) * @PageSize  
END  
ELSE  
BEGIN  
 SET @FirstRecord = 1  
 SET @LastRecord  = @RecordCount  
END  
  
--[DATA]------------------------------------------------------------  
  
SELECT  
 [FHIRSettings].[FHIRSettingsId]  
 ,[FHIRSettings].[ServiceAgreementId]  
 ,[FHIRSettings].[EMRTypeId]  
 ,[FHIRSettings].[OrganizationId]  
 ,[FHIRSettings].[ResourceId]  
 ,[FHIRSettings].[RetrievalDelay]
 ,[FHIRSettings].[MaxRetries]
 ,[FHIRSettings].[RetryTimeout]
 ,[FHIRSettings].[TimeZonesId]
 ,[FHIRSettings].[DateTimeCreated]  
 ,[FHIRSettings].[CreatedByUserProfileId]  
 ,[FHIRSettings].[DateTimeLastUpdated]  
 ,[FHIRSettings].[LastUpdatedByUserProfileId]  
FROM  
 #tmp [tmp]  
 INNER JOIN [FHIRSettings]  
   ON [FHIRSettings].[FHIRSettingsId] = [tmp].[FHIRSettingsId]  
WHERE  
 [tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord  
ORDER BY  
 [tmp].[IndexId]  
    