USE [RevCycleDB]
GO

CREATE OR ALTER PROCEDURE dbo.InsertChartAuditPhysicianLosEvalVersionItem
	 @ChartAuditPhysicianLosVersionItemId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditPhysicianLosEvalVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int
	,@LevelNbr int
	,@PhysicianServiceId int = NULL
	,@PlanId int = NULL
	,@CategoryId int = NULL
	,@SubcategoryId int = NULL
	,@MinorCategoryId int = NULL
	,@ServiceDescription varchar(100) = NULL
	,@Quantity int = NULL
	,@Points int = NULL
	,@ChartAuditPhysicianLosEvalVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditPhysicianLosEvalVersionItem]
(
	 [ChartAuditPhysicianLosVersionItemId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditPhysicianLosEvalVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[LevelNbr]
	,[PhysicianServiceId]
	,[PlanId]
	,[CategoryId]
	,[SubcategoryId]
	,[MinorCategoryId]
	,[ServiceDescription]
	,[Quantity]
	,[Points]
)
VALUES
(
	 @ChartAuditPhysicianLosVersionItemId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditPhysicianLosEvalVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@LevelNbr
	,@PhysicianServiceId
	,@PlanId
	,@CategoryId
	,@SubcategoryId
	,@MinorCategoryId
	,@ServiceDescription
	,@Quantity
	,@Points 
)

SET @ChartAuditPhysicianLosEvalVersionItemId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosEvalVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosEvalVersionItemId
	 @ChartAuditPhysicianLosEvalVersionItemId int
	,@ChartAuditPhysicianLosVersionItemId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditPhysicianLosEvalVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int
	,@LevelNbr int
	,@PhysicianServiceId int = NULL
	,@PlanId int = NULL
	,@CategoryId int = NULL
	,@SubcategoryId int = NULL
	,@MinorCategoryId int = NULL
	,@ServiceDescription varchar(100) = NULL
	,@Quantity int = NULL
	,@Points int = NULL
AS

UPDATE [dbo].[ChartAuditPhysicianLosEvalVersionItem] SET
	 [ChartAuditPhysicianLosVersionItemId] = @ChartAuditPhysicianLosVersionItemId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartAuditActionTypeCode] = @ChartAuditActionTypeCode
	,[ActionDescription] = @ActionDescription
	,[PrevChartAuditPhysicianLosEvalVersionItemId] = @PrevChartAuditPhysicianLosEvalVersionItemId
	,[IsPreviousVersionCorrect] = @IsPreviousVersionCorrect
	,[ExcludeFromQA] = @ExcludeFromQA
	,[ExcludeFromQAReasonID] = @ExcludeFromQAReasonID
	,[ChartId] = @ChartId
	,[LevelNbr] = @LevelNbr
	,[PhysicianServiceId] = @PhysicianServiceId
	,[PlanId] = @PlanId
	,[CategoryId] = @CategoryId
	,[SubcategoryId] = @SubcategoryId
	,[MinorCategoryId] = @MinorCategoryId
	,[ServiceDescription] = @ServiceDescription
	,[Quantity] = @Quantity
	,[Points] = @Points
WHERE
	[ChartAuditPhysicianLosEvalVersionItemId] = @ChartAuditPhysicianLosEvalVersionItemId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosEvalVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosEvalVersionItemId
	@ChartAuditPhysicianLosEvalVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditPhysicianLosEvalVersionItem]
WHERE
	[ChartAuditPhysicianLosEvalVersionItemId] = @ChartAuditPhysicianLosEvalVersionItemId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosEvalVersionItemId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosEvalVersionItemId]
	@ChartAuditPhysicianLosEvalVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditPhysicianLosEvalVersionItem].[ChartAuditPhysicianLosEvalVersionItemId]
	,[ChartAuditPhysicianLosEvalVersionItem].[ChartAuditPhysicianLosVersionItemId]
	,[ChartAuditPhysicianLosEvalVersionItem].[DateTimeCreated]
	,[ChartAuditPhysicianLosEvalVersionItem].[CreatedByUserProfileId]
	,[ChartAuditPhysicianLosEvalVersionItem].[DateTimeLastUpdated]
	,[ChartAuditPhysicianLosEvalVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditPhysicianLosEvalVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditPhysicianLosEvalVersionItem].[ActionDescription]
	,[ChartAuditPhysicianLosEvalVersionItem].[PrevChartAuditPhysicianLosEvalVersionItemId]
	,[ChartAuditPhysicianLosEvalVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditPhysicianLosEvalVersionItem].[ExcludeFromQA]
	,[ChartAuditPhysicianLosEvalVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditPhysicianLosEvalVersionItem].[ChartId]
	,[ChartAuditPhysicianLosEvalVersionItem].[LevelNbr]
	,[ChartAuditPhysicianLosEvalVersionItem].[PhysicianServiceId]
	,[ChartAuditPhysicianLosEvalVersionItem].[PlanId]
	,[ChartAuditPhysicianLosEvalVersionItem].[CategoryId]
	,[ChartAuditPhysicianLosEvalVersionItem].[SubcategoryId]
	,[ChartAuditPhysicianLosEvalVersionItem].[MinorCategoryId]
	,[ChartAuditPhysicianLosEvalVersionItem].[ServiceDescription]
	,[ChartAuditPhysicianLosEvalVersionItem].[Quantity]
	,[ChartAuditPhysicianLosEvalVersionItem].[Points]
FROM
	[dbo].[ChartAuditPhysicianLosEvalVersionItem]
WHERE
	[ChartAuditPhysicianLosEvalVersionItem].[ChartAuditPhysicianLosEvalVersionItemId] = @ChartAuditPhysicianLosEvalVersionItemId

GO	
		
------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosVersionItemId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditPhysicianLosEvalVersionItemByChartAuditPhysicianLosVersionItemId]
	 @ChartAuditPhysicianLosVersionItemId int
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
	[ChartAuditPhysicianLosEvalVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditPhysicianLosEvalVersionItemId) ' +
		   'SELECT [ChartAuditPhysicianLosEvalVersionItem].[ChartAuditPhysicianLosEvalVersionItemId] ' +
		   'FROM [ChartAuditPhysicianLosEvalVersionItem] ' +
		   'WHERE [ChartAuditPhysicianLosEvalVersionItem].[ChartAuditPhysicianLosVersionItemId] = ' + CAST(@ChartAuditPhysicianLosVersionItemId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditPhysicianLosEvalVersionItem].[DateTimeCreated] '

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
	 [ChartAuditPhysicianLosEvalVersionItem].[ChartAuditPhysicianLosEvalVersionItemId]
	,[ChartAuditPhysicianLosEvalVersionItem].[ChartAuditPhysicianLosVersionItemId]
	,[ChartAuditPhysicianLosEvalVersionItem].[DateTimeCreated]
	,[ChartAuditPhysicianLosEvalVersionItem].[CreatedByUserProfileId]
	,[ChartAuditPhysicianLosEvalVersionItem].[DateTimeLastUpdated]
	,[ChartAuditPhysicianLosEvalVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditPhysicianLosEvalVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditPhysicianLosEvalVersionItem].[ActionDescription]
	,[ChartAuditPhysicianLosEvalVersionItem].[PrevChartAuditPhysicianLosEvalVersionItemId]
	,[ChartAuditPhysicianLosEvalVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditPhysicianLosEvalVersionItem].[ExcludeFromQA]
	,[ChartAuditPhysicianLosEvalVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditPhysicianLosEvalVersionItem].[ChartId]
	,[ChartAuditPhysicianLosEvalVersionItem].[LevelNbr]
	,[ChartAuditPhysicianLosEvalVersionItem].[PhysicianServiceId]
	,[ChartAuditPhysicianLosEvalVersionItem].[PlanId]
	,[ChartAuditPhysicianLosEvalVersionItem].[CategoryId]
	,[ChartAuditPhysicianLosEvalVersionItem].[SubcategoryId]
	,[ChartAuditPhysicianLosEvalVersionItem].[MinorCategoryId]
	,[ChartAuditPhysicianLosEvalVersionItem].[ServiceDescription]
	,[ChartAuditPhysicianLosEvalVersionItem].[Quantity]
	,[ChartAuditPhysicianLosEvalVersionItem].[Points]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditPhysicianLosEvalVersionItem] 
			ON [ChartAuditPhysicianLosEvalVersionItem].[ChartAuditPhysicianLosEvalVersionItemId] = [tmp].[ChartAuditPhysicianLosEvalVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

