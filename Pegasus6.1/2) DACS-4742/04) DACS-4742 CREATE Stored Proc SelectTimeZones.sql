----------------------------------------
-- 04) DACS-4742 - cREATE Stored Proc SelectTimeZones
----------------------------------------
USE [RevCycleDB]
GO
/****** Object:  StoredProcedure [dbo].[SelectTimeZones]    Script Date: 9/23/2025 9:39:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectTimeZones]
	 @PageIndex int = NULL  
	,@PageSize int = 25  
	,@WhereClause varchar(1000) = NULL  
	,@OrderByClause varchar(250) = NULL  
	,@RecordCount int OUTPUT  
AS  

  
SET NOCOUNT ON  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
SELECT  
   TimeZonesId
   ,TimeZonesName
   ,IANAIdentifier
   ,StandardOffset
   ,DstOffset
   ,ObservesDst
   ,CreatedByUserProfileId
   ,DateTimeCreated
   ,LastUpdatedByUserProfileId
   ,DateTimeLastUpdated
FROM  
 [TimeZones]

 SELECT @RecordCount = @@ROWCOUNT  
  