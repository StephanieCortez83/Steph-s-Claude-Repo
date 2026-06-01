USE [RevCycleDB]
GO

CREATE OR ALTER PROCEDURE dbo.InsertChartAuditFacilityLosEvalVersionItem
	 @ChartAuditFacilityLosVersionItemId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditFacilityLosEvalVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@FacilityServiceId int = NULL
	,@FacilityServiceDescription varchar(75) = NULL
	,@Points int = NULL
	,@ChartAuditFacilityLosEvalVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditFacilityLosEvalVersionItem]
(
	 [ChartAuditFacilityLosVersionItemId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditFacilityLosEvalVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ChartId]
	,[FacilityServiceId]
	,[FacilityServiceDescription]
	,[Points]
)
VALUES
(
	 @ChartAuditFacilityLosVersionItemId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditFacilityLosEvalVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ChartId
	,@FacilityServiceId
	,@FacilityServiceDescription
	,@Points 
)

SET @ChartAuditFacilityLosEvalVersionItemId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosEvalVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosEvalVersionItemId
	 @ChartAuditFacilityLosEvalVersionItemId int
	,@ChartAuditFacilityLosVersionItemId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditFacilityLosEvalVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@ChartId int = NULL
	,@FacilityServiceId int = NULL
	,@FacilityServiceDescription varchar(75) = NULL
	,@Points int = NULL
AS

UPDATE [dbo].[ChartAuditFacilityLosEvalVersionItem] SET
	 [ChartAuditFacilityLosVersionItemId] = @ChartAuditFacilityLosVersionItemId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartAuditActionTypeCode] = @ChartAuditActionTypeCode
	,[ActionDescription] = @ActionDescription
	,[PrevChartAuditFacilityLosEvalVersionItemId] = @PrevChartAuditFacilityLosEvalVersionItemId
	,[IsPreviousVersionCorrect] = @IsPreviousVersionCorrect
	,[ExcludeFromQA] = @ExcludeFromQA
	,[ExcludeFromQAReasonID] = @ExcludeFromQAReasonID
	,[ChartId] = @ChartId
	,[FacilityServiceId] = @FacilityServiceId
	,[FacilityServiceDescription] = @FacilityServiceDescription
	,[Points] = @Points
WHERE
	[ChartAuditFacilityLosEvalVersionItemId] = @ChartAuditFacilityLosEvalVersionItemId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosEvalVersionItemId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosEvalVersionItemId
	@ChartAuditFacilityLosEvalVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditFacilityLosEvalVersionItem]
WHERE
	[ChartAuditFacilityLosEvalVersionItemId] = @ChartAuditFacilityLosEvalVersionItemId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosEvalVersionItemId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosEvalVersionItemId]
	@ChartAuditFacilityLosEvalVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditFacilityLosEvalVersionItem].[ChartAuditFacilityLosEvalVersionItemId]
	,[ChartAuditFacilityLosEvalVersionItem].[ChartAuditFacilityLosVersionItemId]
	,[ChartAuditFacilityLosEvalVersionItem].[DateTimeCreated]
	,[ChartAuditFacilityLosEvalVersionItem].[CreatedByUserProfileId]
	,[ChartAuditFacilityLosEvalVersionItem].[DateTimeLastUpdated]
	,[ChartAuditFacilityLosEvalVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditFacilityLosEvalVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditFacilityLosEvalVersionItem].[ActionDescription]
	,[ChartAuditFacilityLosEvalVersionItem].[PrevChartAuditFacilityLosEvalVersionItemId]
	,[ChartAuditFacilityLosEvalVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditFacilityLosEvalVersionItem].[ExcludeFromQA]
	,[ChartAuditFacilityLosEvalVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditFacilityLosEvalVersionItem].[ChartId]
	,[ChartAuditFacilityLosEvalVersionItem].[FacilityServiceId]
	,[ChartAuditFacilityLosEvalVersionItem].[FacilityServiceDescription]
	,[ChartAuditFacilityLosEvalVersionItem].[Points]
FROM
	[dbo].[ChartAuditFacilityLosEvalVersionItem]
WHERE
	[ChartAuditFacilityLosEvalVersionItem].[ChartAuditFacilityLosEvalVersionItemId] = @ChartAuditFacilityLosEvalVersionItemId

GO	
		
------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosVersionItemId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditFacilityLosEvalVersionItemByChartAuditFacilityLosVersionItemId]
	 @ChartAuditFacilityLosVersionItemId int
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
	[ChartAuditFacilityLosEvalVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditFacilityLosEvalVersionItemId) ' +
		   'SELECT [ChartAuditFacilityLosEvalVersionItem].[ChartAuditFacilityLosEvalVersionItemId] ' +
		   'FROM [ChartAuditFacilityLosEvalVersionItem] ' +
		   'WHERE [ChartAuditFacilityLosEvalVersionItem].[ChartAuditFacilityLosVersionItemId] = ' + CAST(@ChartAuditFacilityLosVersionItemId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditFacilityLosEvalVersionItem].[DateTimeCreated] '

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
	 [ChartAuditFacilityLosEvalVersionItem].[ChartAuditFacilityLosEvalVersionItemId]
	,[ChartAuditFacilityLosEvalVersionItem].[ChartAuditFacilityLosVersionItemId]
	,[ChartAuditFacilityLosEvalVersionItem].[DateTimeCreated]
	,[ChartAuditFacilityLosEvalVersionItem].[CreatedByUserProfileId]
	,[ChartAuditFacilityLosEvalVersionItem].[DateTimeLastUpdated]
	,[ChartAuditFacilityLosEvalVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditFacilityLosEvalVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditFacilityLosEvalVersionItem].[ActionDescription]
	,[ChartAuditFacilityLosEvalVersionItem].[PrevChartAuditFacilityLosEvalVersionItemId]
	,[ChartAuditFacilityLosEvalVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditFacilityLosEvalVersionItem].[ExcludeFromQA]
	,[ChartAuditFacilityLosEvalVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditFacilityLosEvalVersionItem].[ChartId]
	,[ChartAuditFacilityLosEvalVersionItem].[FacilityServiceId]
	,[ChartAuditFacilityLosEvalVersionItem].[FacilityServiceDescription]
	,[ChartAuditFacilityLosEvalVersionItem].[Points]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditFacilityLosEvalVersionItem] 
			ON [ChartAuditFacilityLosEvalVersionItem].[ChartAuditFacilityLosEvalVersionItemId] = [tmp].[ChartAuditFacilityLosEvalVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO









