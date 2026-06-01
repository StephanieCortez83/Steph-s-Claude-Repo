------------------------------------------------------
-- 02) DACS-1570 - create stored procedures - ChartAuditPhysicianLosVersionItem.sql
------------------------------------------------------
USE [RevCycleDB]
GO
 
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
/*
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditPhysicianLosVersionItem', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditPhysicianLosVersionItem.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditPhysicianLosVersionItem
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditPhysicianLosVersionItem]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditPhysicianLosVersionItem].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditPhysicianLosVersionItem]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditVersionId]
END
GO
*/
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditPhysicianLosVersionItem', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.InsertChartAuditPhysicianLosVersionItem
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditPhysicianLosVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@LevelNumber int = NULL
	,@DateOfService datetime = NULL
	,@PhysicianHistoryId int = NULL
	,@PhysicianHistoryDescription varchar(250) = NULL
	,@PhysicianExamId int = NULL
	,@PhysicianExamDescription varchar(250) = NULL
	,@PhysicianMdmId int = NULL
	,@PhysicianMdmDescription varchar(250) = NULL
	,@PhysicianServiceProcId int = NULL
	,@OverridePhysicianServiceProcId int = NULL
	,@CptCode varchar(10) = NULL
	,@Modifier varchar(100) = NULL
	,@ProviderId int = NULL
	,@ChartAuditPhysicianLosVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditPhysicianLosVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditPhysicianLosVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[LevelNumber]
	,[DateOfService]
	,[PhysicianHistoryId]
	,[PhysicianHistoryDescription]
	,[PhysicianExamId]
	,[PhysicianExamDescription]
	,[PhysicianMdmId]
	,[PhysicianMdmDescription]
	,[PhysicianServiceProcId]
	,[OverridePhysicianServiceProcId]
	,[CptCode]
	,[Modifier]
	,[ProviderId]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditPhysicianLosVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@LevelNumber
	,@DateOfService
	,@PhysicianHistoryId
	,@PhysicianHistoryDescription
	,@PhysicianExamId
	,@PhysicianExamDescription
	,@PhysicianMdmId
	,@PhysicianMdmDescription
	,@PhysicianServiceProcId
	,@OverridePhysicianServiceProcId
	,@CptCode
	,@Modifier
	,@ProviderId 
)

SET @ChartAuditPhysicianLosVersionItemId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId
	 @ChartAuditPhysicianLosVersionItemId int
	,@ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditPhysicianLosVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@LevelNumber int = NULL
	,@DateOfService datetime = NULL
	,@PhysicianHistoryId int = NULL
	,@PhysicianHistoryDescription varchar(250) = NULL
	,@PhysicianExamId int = NULL
	,@PhysicianExamDescription varchar(250) = NULL
	,@PhysicianMdmId int = NULL
	,@PhysicianMdmDescription varchar(250) = NULL
	,@PhysicianServiceProcId int = NULL
	,@OverridePhysicianServiceProcId int = NULL
	,@CptCode varchar(10) = NULL
	,@Modifier varchar(100) = NULL
	,@ProviderId int = NULL
AS

UPDATE [dbo].[ChartAuditPhysicianLosVersionItem] SET
	 [ChartAuditVersionId] = @ChartAuditVersionId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartAuditActionTypeCode] = @ChartAuditActionTypeCode
	,[ActionDescription] = @ActionDescription
	,[PrevChartAuditPhysicianLosVersionItemId] = @PrevChartAuditPhysicianLosVersionItemId
	,[IsPreviousVersionCorrect] = @IsPreviousVersionCorrect
	,[ExcludeFromQA] = @ExcludeFromQA
	,[ExcludeFromQAReasonID] = @ExcludeFromQAReasonID
	,[ChartId] = @ChartId
	,[LevelNumber] = @LevelNumber
	,[DateOfService] = @DateOfService
	,[PhysicianHistoryId] = @PhysicianHistoryId
	,[PhysicianHistoryDescription] = @PhysicianHistoryDescription
	,[PhysicianExamId] = @PhysicianExamId
	,[PhysicianExamDescription] = @PhysicianExamDescription
	,[PhysicianMdmId] = @PhysicianMdmId
	,[PhysicianMdmDescription] = @PhysicianMdmDescription
	,[PhysicianServiceProcId] = @PhysicianServiceProcId
	,[OverridePhysicianServiceProcId] = @OverridePhysicianServiceProcId
	,[CptCode] = @CptCode
	,[Modifier] = @Modifier
	,[ProviderId] = @ProviderId
WHERE
	[ChartAuditPhysicianLosVersionItemId] = @ChartAuditPhysicianLosVersionItemId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId
	@ChartAuditPhysicianLosVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditPhysicianLosVersionItem]
WHERE
	[ChartAuditPhysicianLosVersionItemId] = @ChartAuditPhysicianLosVersionItemId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditPhysicianLosVersionItemId]
	@ChartAuditPhysicianLosVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditPhysicianLosVersionItem].[ChartAuditPhysicianLosVersionItemId]
	,[ChartAuditPhysicianLosVersionItem].[ChartAuditVersionId]
	,[ChartAuditPhysicianLosVersionItem].[DateTimeCreated]
	,[ChartAuditPhysicianLosVersionItem].[CreatedByUserProfileId]
	,[ChartAuditPhysicianLosVersionItem].[DateTimeLastUpdated]
	,[ChartAuditPhysicianLosVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditPhysicianLosVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditPhysicianLosVersionItem].[ActionDescription]
	,[ChartAuditPhysicianLosVersionItem].[PrevChartAuditPhysicianLosVersionItemId]
	,[ChartAuditPhysicianLosVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditPhysicianLosVersionItem].[ExcludeFromQA]
	,[ChartAuditPhysicianLosVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditPhysicianLosVersionItem].[ChartId]
	,[ChartAuditPhysicianLosVersionItem].[LevelNumber]
	,[ChartAuditPhysicianLosVersionItem].[DateOfService]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianHistoryId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianHistoryDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianExamId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianExamDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianMdmId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianMdmDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianServiceProcId]
	,[ChartAuditPhysicianLosVersionItem].[OverridePhysicianServiceProcId]
	,[ChartAuditPhysicianLosVersionItem].[CptCode]
	,[ChartAuditPhysicianLosVersionItem].[Modifier]
	,[ChartAuditPhysicianLosVersionItem].[ProviderId]
FROM
	[dbo].[ChartAuditPhysicianLosVersionItem]
WHERE
	[ChartAuditPhysicianLosVersionItem].[ChartAuditPhysicianLosVersionItemId] = @ChartAuditPhysicianLosVersionItemId

GO	
		
------------------------------------------------------------------
-- Unscoped Select Sproc
------------------------------------------------------------------
RAISERROR('Creating unscoped select stored procedure:', 0, 1) WITH NOWAIT;	

RAISERROR('...creating [dbo].[SelectChartAuditPhysicianLosVersionItem]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditPhysicianLosVersionItem]
	 @PageIndex int = NULL
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
	[ChartAuditPhysicianLosVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditPhysicianLosVersionItemId) ' +
		   'SELECT [ChartAuditPhysicianLosVersionItemId] ' +
		   'FROM [ChartAuditPhysicianLosVersionItem] ' 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' WHERE (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditPhysicianLosVersionItem].[DateTimeCreated]'

EXEC sp_executesql @sql

--[RANGE]----------------------------------------------------------

SELECT @RecordCount = @@ROWCOUNT

DECLARE @FirstRecord int
DECLARE @LastRecord  int

IF @PageIndex IS NOT NULL
BEGIN
	SET @FirstRecord = (@PageIndex * @PageSize) + 1
	SET @LastRecord  = (@PageIndex + 1) * @PageSize
END
ELSE
BEGIN
	SET @FirstRecord = 1
	SET @LastRecord  = @RecordCount
END

--[DATA]------------------------------------------------------------

SELECT
	 [ChartAuditPhysicianLosVersionItem].[ChartAuditPhysicianLosVersionItemId]
	,[ChartAuditPhysicianLosVersionItem].[ChartAuditVersionId]
	,[ChartAuditPhysicianLosVersionItem].[DateTimeCreated]
	,[ChartAuditPhysicianLosVersionItem].[CreatedByUserProfileId]
	,[ChartAuditPhysicianLosVersionItem].[DateTimeLastUpdated]
	,[ChartAuditPhysicianLosVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditPhysicianLosVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditPhysicianLosVersionItem].[ActionDescription]
	,[ChartAuditPhysicianLosVersionItem].[PrevChartAuditPhysicianLosVersionItemId]
	,[ChartAuditPhysicianLosVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditPhysicianLosVersionItem].[ExcludeFromQA]
	,[ChartAuditPhysicianLosVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditPhysicianLosVersionItem].[ChartId]
	,[ChartAuditPhysicianLosVersionItem].[LevelNumber]
	,[ChartAuditPhysicianLosVersionItem].[DateOfService]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianHistoryId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianHistoryDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianExamId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianExamDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianMdmId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianMdmDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianServiceProcId]
	,[ChartAuditPhysicianLosVersionItem].[OverridePhysicianServiceProcId]
	,[ChartAuditPhysicianLosVersionItem].[CptCode]
	,[ChartAuditPhysicianLosVersionItem].[Modifier]
	,[ChartAuditPhysicianLosVersionItem].[ProviderId]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditPhysicianLosVersionItem] 
			ON [ChartAuditPhysicianLosVersionItem].[ChartAuditPhysicianLosVersionItemId] = [tmp].[ChartAuditPhysicianLosVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditVersionId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditPhysicianLosVersionItemByChartAuditVersionId]
	 @ChartAuditVersionId int
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
	[ChartAuditPhysicianLosVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditPhysicianLosVersionItemId) ' +
		   'SELECT [ChartAuditPhysicianLosVersionItem].[ChartAuditPhysicianLosVersionItemId] ' +
		   'FROM [ChartAuditPhysicianLosVersionItem] ' +
		   'WHERE [ChartAuditPhysicianLosVersionItem].[ChartAuditVersionId] = ' + CAST(@ChartAuditVersionId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditPhysicianLosVersionItem].[DateTimeCreated] '

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
	 [ChartAuditPhysicianLosVersionItem].[ChartAuditPhysicianLosVersionItemId]
	,[ChartAuditPhysicianLosVersionItem].[ChartAuditVersionId]
	,[ChartAuditPhysicianLosVersionItem].[DateTimeCreated]
	,[ChartAuditPhysicianLosVersionItem].[CreatedByUserProfileId]
	,[ChartAuditPhysicianLosVersionItem].[DateTimeLastUpdated]
	,[ChartAuditPhysicianLosVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditPhysicianLosVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditPhysicianLosVersionItem].[ActionDescription]
	,[ChartAuditPhysicianLosVersionItem].[PrevChartAuditPhysicianLosVersionItemId]
	,[ChartAuditPhysicianLosVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditPhysicianLosVersionItem].[ExcludeFromQA]
	,[ChartAuditPhysicianLosVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditPhysicianLosVersionItem].[ChartId]
	,[ChartAuditPhysicianLosVersionItem].[LevelNumber]
	,[ChartAuditPhysicianLosVersionItem].[DateOfService]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianHistoryId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianHistoryDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianExamId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianExamDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianMdmId]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianMdmDescription]
	,[ChartAuditPhysicianLosVersionItem].[PhysicianServiceProcId]
	,[ChartAuditPhysicianLosVersionItem].[OverridePhysicianServiceProcId]
	,[ChartAuditPhysicianLosVersionItem].[CptCode]
	,[ChartAuditPhysicianLosVersionItem].[Modifier]
	,[ChartAuditPhysicianLosVersionItem].[ProviderId]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditPhysicianLosVersionItem] 
			ON [ChartAuditPhysicianLosVersionItem].[ChartAuditPhysicianLosVersionItemId] = [tmp].[ChartAuditPhysicianLosVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

