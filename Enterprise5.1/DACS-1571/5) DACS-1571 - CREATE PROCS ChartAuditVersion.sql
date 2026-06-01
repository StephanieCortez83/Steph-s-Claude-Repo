 
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditVersion', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditVersion.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditVersion
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditVersionByChartAuditVersionId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditVersionByChartAuditVersionId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditVersionByChartAuditVersionId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditVersionByChartAuditVersionId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditVersionByChartAuditVersionId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditVersionByChartAuditVersionId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditVersionByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditVersionByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditVersionByChartAuditVersionId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditVersionByChartAuditId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditVersionByChartAuditId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditVersionByChartAuditId]
END
GO
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditVersion', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.InsertChartAuditVersion
	 @ChartAuditId int
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@VersionNumber int
	,@PreviousChartAuditVersionId int = NULL
	,@ChartAuditVersionId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditVersion]
(
	 [ChartAuditId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[VersionNumber]
	,[PreviousChartAuditVersionId]
)
VALUES
(
	 @ChartAuditId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@VersionNumber
	,@PreviousChartAuditVersionId 
)

SET @ChartAuditVersionId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditVersionByChartAuditVersionId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.UpdateByChartAuditVersionByChartAuditVersionId
	 @ChartAuditVersionId int
	,@ChartAuditId int
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@VersionNumber int
	,@PreviousChartAuditVersionId int = NULL
AS

UPDATE [dbo].[ChartAuditVersion] SET
	 [ChartAuditId] = @ChartAuditId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[VersionNumber] = @VersionNumber
	,[PreviousChartAuditVersionId] = @PreviousChartAuditVersionId
WHERE
	[ChartAuditVersionId] = @ChartAuditVersionId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditVersionByChartAuditVersionId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.DeleteChartAuditVersionByChartAuditVersionId
	@ChartAuditVersionId int
AS

DELETE 
	FROM [dbo].[ChartAuditVersion]
WHERE
	[ChartAuditVersionId] = @ChartAuditVersionId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditVersionByChartAuditVersionId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SelectChartAuditVersionByChartAuditVersionId]
	@ChartAuditVersionId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditVersion].[ChartAuditVersionId]
	,[ChartAuditVersion].[ChartAuditId]
	,[ChartAuditVersion].[DateTimeCreated]
	,[ChartAuditVersion].[CreatedByUserProfileId]
	,[ChartAuditVersion].[DateTimeLastUpdated]
	,[ChartAuditVersion].[LastUpdatedByUserProfileId]
	,[ChartAuditVersion].[VersionNumber]
	,[ChartAuditVersion].[PreviousChartAuditVersionId]
FROM
	[dbo].[ChartAuditVersion]
WHERE
	[ChartAuditVersion].[ChartAuditVersionId] = @ChartAuditVersionId

GO	
		
------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditVersionByChartAuditId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SelectChartAuditVersionByChartAuditId]
	 @ChartAuditId int
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
	[ChartAuditVersionId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditVersionId) ' +
		   'SELECT [ChartAuditVersion].[ChartAuditVersionId] ' +
		   'FROM [ChartAuditVersion] ' +
		   'WHERE [ChartAuditVersion].[ChartAuditId] = ' + CAST(@ChartAuditId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditVersion].[DateTimeCreated] '

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
	 [ChartAuditVersion].[ChartAuditVersionId]
	,[ChartAuditVersion].[ChartAuditId]
	,[ChartAuditVersion].[DateTimeCreated]
	,[ChartAuditVersion].[CreatedByUserProfileId]
	,[ChartAuditVersion].[DateTimeLastUpdated]
	,[ChartAuditVersion].[LastUpdatedByUserProfileId]
	,[ChartAuditVersion].[VersionNumber]
	,[ChartAuditVersion].[PreviousChartAuditVersionId]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditVersion] 
			ON [ChartAuditVersion].[ChartAuditVersionId] = [tmp].[ChartAuditVersionId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

