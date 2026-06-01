USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 1) DACS-2554 Create table ChartAuditFacilityLosEvalVersionItem.sql

GO

CREATE TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem](
	[ChartAuditFacilityLosEvalVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditFacilityLosVersionItemId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditFacilityLosEvalVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	[ChartId] [int] NULL,
	[FacilityServiceId] [int] NULL,
	[FacilityServiceDescription] [varchar](75) NULL,
	[Points] [int] NULL
 CONSTRAINT [PK_ChartAuditFacilityLosEvalVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditFacilityLosEvalVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem] ADD  CONSTRAINT [DF_ChartAuditFacilityLosEvalVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem] ADD  CONSTRAINT [DF_ChartAuditFacilityLosEvalVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditFacilityLosEvalVersionItem_ChartAuditFacilityLosVersionItem] FOREIGN KEY([ChartAuditFacilityLosVersionItemId])
REFERENCES [dbo].[ChartAuditFacilityLosVersionItem] ([ChartAuditFacilityLosVersionItemId])
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem] CHECK CONSTRAINT [FK_ChartAuditFacilityLosEvalVersionItem_ChartAuditFacilityLosVersionItem]
GO
-- End of 1) DACS-2554 Create table ChartAuditFacilityLosEvalVersionItem.sql
GO

-- Start of 2) DACS-2554 Create procs for ChartAuditFacilityLosEvalVersionItem.sql

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

GO
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

GO
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

GO
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

GO
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









-- End of 2) DACS-2554 Create procs for ChartAuditFacilityLosEvalVersionItem.sql
GO

-- Start of 1) DACS-3057 Create table ChartAuditPhysicianLosEvalVersionItem.sql

GO

CREATE TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem](
	[ChartAuditPhysicianLosEvalVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditPhysicianLosVersionItemId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditPhysicianLosEvalVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	[ChartId] [int] NOT NULL,
	[LevelNbr] [int] NOT NULL,
	[PhysicianServiceId] [int] NULL,
	[PlanId] [int] NULL,
	[CategoryId] [int] NULL,
	[SubcategoryId] [int] NULL,
	[MinorCategoryId] [int] NULL,
	[ServiceDescription] [varchar](100) NULL,
	[Quantity] [int] NULL,
	[Points]  [int] NULL
 CONSTRAINT [PK_ChartAuditPhysicianLosEvalVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditPhysicianLosEvalVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem] ADD  CONSTRAINT [DF_ChartAuditPhysicianLosEvalVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem] ADD  CONSTRAINT [DF_ChartAuditPhysicianLosEvalVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditPhysicianLosEvalVersionItem_ChartAuditPhysicianLosVersionItem] FOREIGN KEY([ChartAuditPhysicianLosVersionItemId])
REFERENCES [dbo].[ChartAuditPhysicianLosVersionItem] ([ChartAuditPhysicianLosVersionItemId])
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem] CHECK CONSTRAINT [FK_ChartAuditPhysicianLosEvalVersionItem_ChartAuditPhysicianLosVersionItem]
GO
-- End of 1) DACS-3057 Create table ChartAuditPhysicianLosEvalVersionItem.sql
GO

-- Start of 2) DACS-3057 Create procs for ChartAuditPhysicianLosEvalVersionItem.sql

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

GO
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

GO
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

GO
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

GO
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

-- End of 2) DACS-3057 Create procs for ChartAuditPhysicianLosEvalVersionItem.sql
GO

-- Start of 01) DACS-2224 - Alter Procedure - [dbo].[sp_Validate_UserSessionUuid].sql

----------------------------------------
-- 01) DACS-2224 - Alter Procedure - [dbo].[sp_Validate_UserSessionUuid].sql
----------------------------------------
GO

GO

GO

-- =============================================
-- Author:  Daniel Bonebrake  
-- Create date: 7/31/2015  
-- Description: Returns a list of active session for the UserProfileID that started after the given SessionID with a different UUID.  
-- Author:  J. Burge - CDBT-458 - DACS-2224
-- Modification date: 3/21/2024
-- Description: Returns '1' if active session for the UserProfileID that started after the given SessionID with a different UUID.  
-- =============================================  
CREATE OR ALTER PROCEDURE [dbo].[sp_Validate_UserSessionUuid] @UserProfileID int
														    , @SessionID	 char(36)
														    , @Uuid			 nvarchar(36)
AS
	BEGIN
		SET NOCOUNT ON;

		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		IF EXISTS (SELECT	1
				   FROM		[dbo].[USER_SESSION]
				   WHERE	USER_PROFILE_ID = @UserProfileID
							AND SIGNED_OUT = 0
							AND UUID IS NOT NULL
							AND UUID <> @Uuid
							AND USER_SESSION_ID >= (SELECT	USER_SESSION_ID
													FROM	USER_SESSION
													WHERE	USER_PROFILE_ID = @UserProfileID
															AND SESSION_ID = @SessionID))
			SELECT 1;
	END;
GO

/*
testing:
DECLARE @SearchMinUserSessionId INT = (SELECT MAX(USER_SESSION_ID) FROM [dbo].[USER_SESSION])
select '1 @SearchMinUserSessionId =' = @SearchMinUserSessionId

SET @SearchMinUserSessionId = @SearchMinUserSessionId - 10000
select '2 @SearchMinUserSessionId =' = @SearchMinUserSessionId


select top 100 * from [dbo].[USER_SESSION] WITH (NOLOCK) 
where USER_SESSION_ID <= @SearchMinUserSessionId
order by USER_SESSION_ID desc;


*/
-- End of 01) DACS-2224 - Alter Procedure - [dbo].[sp_Validate_UserSessionUuid].sql
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
