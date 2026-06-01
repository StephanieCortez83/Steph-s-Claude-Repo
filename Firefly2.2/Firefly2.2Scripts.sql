USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-1674 - create table - ChartAuditDocumentationVersionItem.sql

------------------------------------------------------
-- 01) DACS-1674 - create table - ChartAuditDocumentationVersionItem.sql
------------------------------------------------------
GO

GO

GO

CREATE TABLE [dbo].[ChartAuditDocumentationVersionItem](
	-- Base table structure
	[ChartAuditDocumentationVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditVersionId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditDocumentationVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	-- Exclusion information
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	-- Particular to Documentation Audit fields
	[DocumentationId] [int] NULL,
	[DocumentationDeficiencyId] [int] NULL,
	[DocumentationChecked] [bit] NULL
CONSTRAINT [PK_ChartAuditDocumentationVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditDocumentationVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditDocumentationVersionItem] ADD  CONSTRAINT [DF_ChartAuditDocumentationVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditDocumentationVersionItem] ADD  CONSTRAINT [DF_ChartAuditDocumentationVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditDocumentationVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditDocumentationVersionItem_ChartAuditVersion] FOREIGN KEY([ChartAuditVersionId])
REFERENCES [dbo].[ChartAuditVersion] ([ChartAuditVersionId])
GO

ALTER TABLE [dbo].[ChartAuditDocumentationVersionItem] CHECK CONSTRAINT [FK_ChartAuditDocumentationVersionItem_ChartAuditVersion]
GO


-- if table needs to be removed: DROP TABLE [dbo].[ChartAuditDocumentationVersionItem];
-- End of 01) DACS-1674 - create table - ChartAuditDocumentationVersionItem.sql
GO

-- Start of 02) DACS-1674 - create stored procedures - ChartAuditDocumentationVersionItem.sql

------------------------------------------------------
-- 02) DACS-1674 - create stored procedures - ChartAuditDocumentationVersionItem.sql
------------------------------------------------------
GO
 
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
/*  -- just in case NEEDED
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditDocumentationVersionItem', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditDocumentationVersionItem.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditDocumentationVersionItem
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditDocumentationVersionItem]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditDocumentationVersionItem].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditDocumentationVersionItem]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditDocumentationVersionItemByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditDocumentationVersionItemByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditDocumentationVersionItemByChartAuditVersionId]
END
GO
*/
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditDocumentationVersionItem', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.InsertChartAuditDocumentationVersionItem
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditDocumentationVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@DocumentationId int = NULL
	,@DocumentationDeficiencyId int = NULL
	,@DocumentationChecked bit = NULL
	,@ChartAuditDocumentationVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditDocumentationVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditDocumentationVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[DocumentationId]
	,[DocumentationDeficiencyId]
	,[DocumentationChecked]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditDocumentationVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@DocumentationId
	,@DocumentationDeficiencyId
	,@DocumentationChecked 
)

SET @ChartAuditDocumentationVersionItemId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId
	 @ChartAuditDocumentationVersionItemId int
	,@ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditDocumentationVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit = NULL
	,@ExcludeFromQA bit = NULL
	,@ExcludeFromQAReasonID int = NULL
	,@DocumentationId int = NULL
	,@DocumentationDeficiencyId int = NULL
	,@DocumentationChecked bit = NULL
AS

UPDATE [dbo].[ChartAuditDocumentationVersionItem] SET
	 [ChartAuditVersionId] = @ChartAuditVersionId
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartAuditActionTypeCode] = @ChartAuditActionTypeCode
	,[ActionDescription] = @ActionDescription
	,[PrevChartAuditDocumentationVersionItemId] = @PrevChartAuditDocumentationVersionItemId
	,[IsPreviousVersionCorrect] = @IsPreviousVersionCorrect
	,[ExcludeFromQA] = @ExcludeFromQA
	,[ExcludeFromQAReasonID] = @ExcludeFromQAReasonID
	,[DocumentationId] = @DocumentationId
	,[DocumentationDeficiencyId] = @DocumentationDeficiencyId
	,[DocumentationChecked] = @DocumentationChecked
WHERE
	[ChartAuditDocumentationVersionItemId] = @ChartAuditDocumentationVersionItemId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId
	@ChartAuditDocumentationVersionItemId int
AS

DELETE 
	FROM [dbo].[ChartAuditDocumentationVersionItem]
WHERE
	[ChartAuditDocumentationVersionItemId] = @ChartAuditDocumentationVersionItemId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditDocumentationVersionItemByChartAuditDocumentationVersionItemId]
	@ChartAuditDocumentationVersionItemId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartAuditDocumentationVersionItem].[ChartAuditDocumentationVersionItemId]
	,[ChartAuditDocumentationVersionItem].[ChartAuditVersionId]
	,[ChartAuditDocumentationVersionItem].[DateTimeCreated]
	,[ChartAuditDocumentationVersionItem].[CreatedByUserProfileId]
	,[ChartAuditDocumentationVersionItem].[DateTimeLastUpdated]
	,[ChartAuditDocumentationVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditDocumentationVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditDocumentationVersionItem].[ActionDescription]
	,[ChartAuditDocumentationVersionItem].[PrevChartAuditDocumentationVersionItemId]
	,[ChartAuditDocumentationVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditDocumentationVersionItem].[ExcludeFromQA]
	,[ChartAuditDocumentationVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditDocumentationVersionItem].[DocumentationId]
	,[ChartAuditDocumentationVersionItem].[DocumentationDeficiencyId]
	,[ChartAuditDocumentationVersionItem].[DocumentationChecked]
FROM
	[dbo].[ChartAuditDocumentationVersionItem]
WHERE
	[ChartAuditDocumentationVersionItem].[ChartAuditDocumentationVersionItemId] = @ChartAuditDocumentationVersionItemId

GO	
		
------------------------------------------------------------------
-- Unscoped Select Sproc
------------------------------------------------------------------
RAISERROR('Creating unscoped select stored procedure:', 0, 1) WITH NOWAIT;	

RAISERROR('...creating [dbo].[SelectChartAuditDocumentationVersionItem]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditDocumentationVersionItem]
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
	[ChartAuditDocumentationVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditDocumentationVersionItemId) ' +
		   'SELECT [ChartAuditDocumentationVersionItemId] ' +
		   'FROM [ChartAuditDocumentationVersionItem] ' 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' WHERE (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditDocumentationVersionItem].[DateTimeCreated]'

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
	 [ChartAuditDocumentationVersionItem].[ChartAuditDocumentationVersionItemId]
	,[ChartAuditDocumentationVersionItem].[ChartAuditVersionId]
	,[ChartAuditDocumentationVersionItem].[DateTimeCreated]
	,[ChartAuditDocumentationVersionItem].[CreatedByUserProfileId]
	,[ChartAuditDocumentationVersionItem].[DateTimeLastUpdated]
	,[ChartAuditDocumentationVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditDocumentationVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditDocumentationVersionItem].[ActionDescription]
	,[ChartAuditDocumentationVersionItem].[PrevChartAuditDocumentationVersionItemId]
	,[ChartAuditDocumentationVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditDocumentationVersionItem].[ExcludeFromQA]
	,[ChartAuditDocumentationVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditDocumentationVersionItem].[DocumentationId]
	,[ChartAuditDocumentationVersionItem].[DocumentationDeficiencyId]
	,[ChartAuditDocumentationVersionItem].[DocumentationChecked]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditDocumentationVersionItem] 
			ON [ChartAuditDocumentationVersionItem].[ChartAuditDocumentationVersionItemId] = [tmp].[ChartAuditDocumentationVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChartAuditDocumentationVersionItemByChartAuditVersionId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAuditDocumentationVersionItemByChartAuditVersionId]
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
	[ChartAuditDocumentationVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditDocumentationVersionItemId) ' +
		   'SELECT [ChartAuditDocumentationVersionItem].[ChartAuditDocumentationVersionItemId] ' +
		   'FROM [ChartAuditDocumentationVersionItem] ' +
		   'WHERE [ChartAuditDocumentationVersionItem].[ChartAuditVersionId] = ' + CAST(@ChartAuditVersionId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditDocumentationVersionItem].[DateTimeCreated] '

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
	 [ChartAuditDocumentationVersionItem].[ChartAuditDocumentationVersionItemId]
	,[ChartAuditDocumentationVersionItem].[ChartAuditVersionId]
	,[ChartAuditDocumentationVersionItem].[DateTimeCreated]
	,[ChartAuditDocumentationVersionItem].[CreatedByUserProfileId]
	,[ChartAuditDocumentationVersionItem].[DateTimeLastUpdated]
	,[ChartAuditDocumentationVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditDocumentationVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditDocumentationVersionItem].[ActionDescription]
	,[ChartAuditDocumentationVersionItem].[PrevChartAuditDocumentationVersionItemId]
	,[ChartAuditDocumentationVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditDocumentationVersionItem].[ExcludeFromQA]
	,[ChartAuditDocumentationVersionItem].[ExcludeFromQAReasonID]
	,[ChartAuditDocumentationVersionItem].[DocumentationId]
	,[ChartAuditDocumentationVersionItem].[DocumentationDeficiencyId]
	,[ChartAuditDocumentationVersionItem].[DocumentationChecked]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditDocumentationVersionItem] 
			ON [ChartAuditDocumentationVersionItem].[ChartAuditDocumentationVersionItemId] = [tmp].[ChartAuditDocumentationVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

-- End of 02) DACS-1674 - create stored procedures - ChartAuditDocumentationVersionItem.sql
GO

-- Start of 03) DACS-1674 - update PhysicianService into ChartAuditSectionTypeCode.sql

------------------------------------------------------
-- 03) DACS-1674 - update PhysicianService into ChartAuditSectionTypeCode.sql
------------------------------------------------------
GO

-- if needed:
-- select top 20 * FROM ChartAuditSectionTypeCode;

-- adjust older key
UPDATE [dbo].[ChartAuditSectionTypeCode]
    SET [Key] = 'PhysicianService',
        [DisplayName] = 'Physician Service',
        [Description] = 'Physician Service Audit Section'
	WHERE [Key] = 'ProcedureService'

-- delete this key:
DELETE FROM [dbo].[chartauditsectiontypecode]
	WHERE [Key] = 'PhysicianEvaluation';	

GO
-- End of 03) DACS-1674 - update PhysicianService into ChartAuditSectionTypeCode.sql
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
