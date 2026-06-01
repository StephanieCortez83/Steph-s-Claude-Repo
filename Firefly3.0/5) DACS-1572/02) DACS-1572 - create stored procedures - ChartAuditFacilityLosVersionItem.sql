------------------------------------------------------
-- 02) DACS-1572 - create stored procedures - ChartAuditFacilityLosVersionItem.sql
------------------------------------------------------
USE [RevCycleDB]
GO
 
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
/*
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditFacilityLosVersionItem', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditFacilityLosVersionItem.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditFacilityLosVersionItem
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditFacilityLosVersionItem]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditFacilityLosVersionItem].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditFacilityLosVersionItem]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditVersionId]
END
GO
*/
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditFacilityLosVersionItem', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.InsertChartAuditFacilityLosVersionItem
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditFacilityLosVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@LevelNumber int = NULL
	,@CptCode varchar(10) = NULL
	,@Modifier varchar(100) = NULL
	,@FacilityChartId varchar(20) = NULL
	,@FacilityLevelId int = NULL
	,@OverrideFacilityLevelId int = NULL
	,@ChartAuditFacilityLosVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditFacilityLosVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditFacilityLosVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[LevelNumber]
	,[CptCode]
	,[Modifier]
	,[FacilityChartId]
	,[FacilityLevelId]
	,[OverrideFacilityLevelId]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditFacilityLosVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@LevelNumber
	,@CptCode
	,@Modifier
	,@FacilityChartId
	,@FacilityLevelId
	,@OverrideFacilityLevelId 
)

SET @ChartAuditFacilityLosVersionItemId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId
	 @ChartAuditFacilityLosVersionItemId int
	,@ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditFacilityLosVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@LevelNumber int = NULL
	,@CptCode varchar(10) = NULL
	,@Modifier varchar(100) = NULL
	,@FacilityChartId varchar(20) = NULL
	,@FacilityLevelId int = NULL
	,@OverrideFacilityLevelId int = NULL
AS

UPDATE [dbo].[ChartAuditFacilityLosVersionItem] SET
	 [ChartAuditVersionId] = @ChartAuditVersionId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartAuditActionTypeCode] = @ChartAuditActionTypeCode
	,[ActionDescription] = @ActionDescription
	,[PrevChartAuditFacilityLosVersionItemId] = @PrevChartAuditFacilityLosVersionItemId
	,[IsPreviousVersionCorrect] = @IsPreviousVersionCorrect
	,[ExcludeFromQA] = @ExcludeFromQA
	,[ExcludeFromQAReasonID] = @ExcludeFromQAReasonID
	,[ChartId] = @ChartId
	,[LevelNumber] = @LevelNumber
	,[CptCode] = @CptCode
	,[Modifier] = @Modifier
	,[FacilityChartId] = @FacilityChartId
	,[FacilityLevelId] = @FacilityLevelId
	,[OverrideFacilityLevelId] = @OverrideFacilityLevelId
WHERE
	[ChartAuditFacilityLosVersionItemId] = @ChartAuditFacilityLosVersionItemId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId
	@ChartAuditFacilityLosVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditFacilityLosVersionItem]
WHERE
	[ChartAuditFacilityLosVersionItemId] = @ChartAuditFacilityLosVersionItemId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditFacilityLosVersionItemId]
	@ChartAuditFacilityLosVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditFacilityLosVersionItem].[ChartAuditFacilityLosVersionItemId]
	,[ChartAuditFacilityLosVersionItem].[ChartAuditVersionId]
	,[ChartAuditFacilityLosVersionItem].[DateTimeCreated]
	,[ChartAuditFacilityLosVersionItem].[CreatedByUserProfileId]
	,[ChartAuditFacilityLosVersionItem].[DateTimeLastUpdated]
	,[ChartAuditFacilityLosVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditFacilityLosVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditFacilityLosVersionItem].[ActionDescription]
	,[ChartAuditFacilityLosVersionItem].[PrevChartAuditFacilityLosVersionItemId]
	,[ChartAuditFacilityLosVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditFacilityLosVersionItem].[ExcludeFromQA]
	,[ChartAuditFacilityLosVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditFacilityLosVersionItem].[ChartId]
	,[ChartAuditFacilityLosVersionItem].[LevelNumber]
	,[ChartAuditFacilityLosVersionItem].[CptCode]
	,[ChartAuditFacilityLosVersionItem].[Modifier]
	,[ChartAuditFacilityLosVersionItem].[FacilityChartId]
	,[ChartAuditFacilityLosVersionItem].[FacilityLevelId]
	,[ChartAuditFacilityLosVersionItem].[OverrideFacilityLevelId]
FROM
	[dbo].[ChartAuditFacilityLosVersionItem]
WHERE
	[ChartAuditFacilityLosVersionItem].[ChartAuditFacilityLosVersionItemId] = @ChartAuditFacilityLosVersionItemId

GO	
		
------------------------------------------------------------------
-- Unscoped Select Sproc
------------------------------------------------------------------
RAISERROR('Creating unscoped select stored procedure:', 0, 1) WITH NOWAIT;	

RAISERROR('...creating [dbo].[SelectChartAuditFacilityLosVersionItem]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditFacilityLosVersionItem]
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
	[ChartAuditFacilityLosVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditFacilityLosVersionItemId) ' +
		   'SELECT [ChartAuditFacilityLosVersionItemId] ' +
		   'FROM [ChartAuditFacilityLosVersionItem] ' 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' WHERE (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditFacilityLosVersionItem].[DateTimeCreated]'

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
	 [ChartAuditFacilityLosVersionItem].[ChartAuditFacilityLosVersionItemId]
	,[ChartAuditFacilityLosVersionItem].[ChartAuditVersionId]
	,[ChartAuditFacilityLosVersionItem].[DateTimeCreated]
	,[ChartAuditFacilityLosVersionItem].[CreatedByUserProfileId]
	,[ChartAuditFacilityLosVersionItem].[DateTimeLastUpdated]
	,[ChartAuditFacilityLosVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditFacilityLosVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditFacilityLosVersionItem].[ActionDescription]
	,[ChartAuditFacilityLosVersionItem].[PrevChartAuditFacilityLosVersionItemId]
	,[ChartAuditFacilityLosVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditFacilityLosVersionItem].[ExcludeFromQA]
	,[ChartAuditFacilityLosVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditFacilityLosVersionItem].[ChartId]
	,[ChartAuditFacilityLosVersionItem].[LevelNumber]
	,[ChartAuditFacilityLosVersionItem].[CptCode]
	,[ChartAuditFacilityLosVersionItem].[Modifier]
	,[ChartAuditFacilityLosVersionItem].[FacilityChartId]
	,[ChartAuditFacilityLosVersionItem].[FacilityLevelId]
	,[ChartAuditFacilityLosVersionItem].[OverrideFacilityLevelId]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditFacilityLosVersionItem] 
			ON [ChartAuditFacilityLosVersionItem].[ChartAuditFacilityLosVersionItemId] = [tmp].[ChartAuditFacilityLosVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditVersionId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditFacilityLosVersionItemByChartAuditVersionId]
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
	[ChartAuditFacilityLosVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditFacilityLosVersionItemId) ' +
		   'SELECT [ChartAuditFacilityLosVersionItem].[ChartAuditFacilityLosVersionItemId] ' +
		   'FROM [ChartAuditFacilityLosVersionItem] ' +
		   'WHERE [ChartAuditFacilityLosVersionItem].[ChartAuditVersionId] = ' + CAST(@ChartAuditVersionId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditFacilityLosVersionItem].[DateTimeCreated] '

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
	 [ChartAuditFacilityLosVersionItem].[ChartAuditFacilityLosVersionItemId]
	,[ChartAuditFacilityLosVersionItem].[ChartAuditVersionId]
	,[ChartAuditFacilityLosVersionItem].[DateTimeCreated]
	,[ChartAuditFacilityLosVersionItem].[CreatedByUserProfileId]
	,[ChartAuditFacilityLosVersionItem].[DateTimeLastUpdated]
	,[ChartAuditFacilityLosVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditFacilityLosVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditFacilityLosVersionItem].[ActionDescription]
	,[ChartAuditFacilityLosVersionItem].[PrevChartAuditFacilityLosVersionItemId]
	,[ChartAuditFacilityLosVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditFacilityLosVersionItem].[ExcludeFromQA]
	,[ChartAuditFacilityLosVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditFacilityLosVersionItem].[ChartId]
	,[ChartAuditFacilityLosVersionItem].[LevelNumber]
	,[ChartAuditFacilityLosVersionItem].[CptCode]
	,[ChartAuditFacilityLosVersionItem].[Modifier]
	,[ChartAuditFacilityLosVersionItem].[FacilityChartId]
	,[ChartAuditFacilityLosVersionItem].[FacilityLevelId]
	,[ChartAuditFacilityLosVersionItem].[OverrideFacilityLevelId]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditFacilityLosVersionItem] 
			ON [ChartAuditFacilityLosVersionItem].[ChartAuditFacilityLosVersionItemId] = [tmp].[ChartAuditFacilityLosVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

