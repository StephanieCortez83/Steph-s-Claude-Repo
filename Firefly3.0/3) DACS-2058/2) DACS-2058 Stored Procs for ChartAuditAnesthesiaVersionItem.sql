 Use [RevCycleDB]
 GO
 
/* Run Drop statements if procs already exist.

---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditAnesthesiaVersionItem', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditAnesthesiaVersionItem.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditAnesthesiaVersionItem
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]
END
GO
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditAnesthesiaVersionItem', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

*/

CREATE OR ALTER PROCEDURE dbo.InsertChartAuditAnesthesiaVersionItem
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditAnesthesiaVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit
	,@ExcludeFromQA bit
	,@ExcludeFromQAReasonID int = NULL
	,@AnesthesiaCode varchar(10) = NULL
	,@ChartAuditAnesthesiaVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditAnesthesiaVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditAnesthesiaVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[AnesthesiaCode]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditAnesthesiaVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@AnesthesiaCode 
)

SET @ChartAuditAnesthesiaVersionItemId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId
	 @ChartAuditAnesthesiaVersionItemId int
	,@ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditAnesthesiaVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit
	,@ExcludeFromQA bit
	,@ExcludeFromQAReasonID int = NULL
	,@AnesthesiaCode varchar(10) = NULL
AS

UPDATE [dbo].[ChartAuditAnesthesiaVersionItem] SET
	 [ChartAuditVersionId] = @ChartAuditVersionId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartAuditActionTypeCode] = @ChartAuditActionTypeCode
	,[ActionDescription] = @ActionDescription
	,[PrevChartAuditAnesthesiaVersionItemId] = @PrevChartAuditAnesthesiaVersionItemId
	,[IsPreviousVersionCorrect] = @IsPreviousVersionCorrect
	,[ExcludeFromQA] = @ExcludeFromQA
	,[ExcludeFromQAReasonID] = @ExcludeFromQAReasonID
	,[AnesthesiaCode] = @AnesthesiaCode
WHERE
	[ChartAuditAnesthesiaVersionItemId] = @ChartAuditAnesthesiaVersionItemId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId
	@ChartAuditAnesthesiaVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditAnesthesiaVersionItem]
WHERE
	[ChartAuditAnesthesiaVersionItemId] = @ChartAuditAnesthesiaVersionItemId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditAnesthesiaVersionItemId]
	@ChartAuditAnesthesiaVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditVersionId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeCreated]
	,[ChartAuditAnesthesiaVersionItem].[CreatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeLastUpdated]
	,[ChartAuditAnesthesiaVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditAnesthesiaVersionItem].[ActionDescription]
	,[ChartAuditAnesthesiaVersionItem].[PrevChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQA]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditAnesthesiaVersionItem].[AnesthesiaCode]
FROM
	[dbo].[ChartAuditAnesthesiaVersionItem]
WHERE
	[ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId] = @ChartAuditAnesthesiaVersionItemId

GO	
		
------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]
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
	[ChartAuditAnesthesiaVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditAnesthesiaVersionItemId) ' +
		   'SELECT [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId] ' +
		   'FROM [ChartAuditAnesthesiaVersionItem] ' +
		   'WHERE [ChartAuditAnesthesiaVersionItem].[ChartAuditVersionId] = ' + CAST(@ChartAuditVersionId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditAnesthesiaVersionItem].[DateTimeCreated] '

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
	 [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditVersionId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeCreated]
	,[ChartAuditAnesthesiaVersionItem].[CreatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[DateTimeLastUpdated]
	,[ChartAuditAnesthesiaVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditAnesthesiaVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditAnesthesiaVersionItem].[ActionDescription]
	,[ChartAuditAnesthesiaVersionItem].[PrevChartAuditAnesthesiaVersionItemId]
	,[ChartAuditAnesthesiaVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQA]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditAnesthesiaVersionItem].[AnesthesiaCode]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditAnesthesiaVersionItem] 
			ON [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId] = [tmp].[ChartAuditAnesthesiaVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

