USE [RevCycleDB]
GO

---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChargeMasterAutomationExclude', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChargeMasterAutomationExclude.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChargeMasterAutomationExclude
END
GO

IF OBJECT_ID('dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId
END
GO
IF OBJECT_ID('dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId
END
GO

IF OBJECT_ID('[dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]
END
GO

IF OBJECT_ID('[dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]
END
GO
IF OBJECT_ID('[dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId]
END
GO
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChargeMasterAutomationExclude', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.InsertChargeMasterAutomationExclude
	 @ChargeMasterId int
	,@ChargeMasterAutomationExcludeReasonId int
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChargeMasterAutomationExcludeId int OUTPUT
AS

INSERT INTO [dbo].[ChargeMasterAutomationExclude]
(
	 [ChargeMasterId]
	,[ChargeMasterAutomationExcludeReasonId]
	,[DateTimeExpiration]
	,[DateTimeEffective]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
)
VALUES
(
	 @ChargeMasterId
	,@ChargeMasterAutomationExcludeReasonId
	,@DateTimeExpiration
	,@DateTimeEffective
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId 
)

SET @ChargeMasterAutomationExcludeId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId
	 @ChargeMasterAutomationExcludeId int
	,@ChargeMasterId int
	,@ChargeMasterAutomationExcludeReasonId int
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
AS

UPDATE [dbo].[ChargeMasterAutomationExclude] SET
	 [ChargeMasterId] = @ChargeMasterId
	,[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId
	,[DateTimeExpiration] = @DateTimeExpiration
	,[DateTimeEffective] = @DateTimeEffective
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
WHERE
	[ChargeMasterAutomationExcludeId] = @ChargeMasterAutomationExcludeId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId
	@ChargeMasterAutomationExcludeId int
AS

DELETE 
	FROM [dbo].[ChargeMasterAutomationExclude]
WHERE
	[ChargeMasterAutomationExcludeId] = @ChargeMasterAutomationExcludeId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]
	@ChargeMasterAutomationExcludeId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId]
	,[ChargeMasterAutomationExclude].[ChargeMasterId]
	,[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExclude].[DateTimeExpiration]
	,[ChargeMasterAutomationExclude].[DateTimeEffective]
	,[ChargeMasterAutomationExclude].[DateTimeCreated]
	,[ChargeMasterAutomationExclude].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExclude].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExclude].[LastUpdatedByUserProfileId]
FROM
	[dbo].[ChargeMasterAutomationExclude]
WHERE
	[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] = @ChargeMasterAutomationExcludeId

GO	
		
------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]
	 @ChargeMasterAutomationExcludeReasonId int
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
	[ChargeMasterAutomationExcludeId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChargeMasterAutomationExcludeId) ' +
		   'SELECT [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] ' +
		   'FROM [ChargeMasterAutomationExclude] ' +
		   'WHERE [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId] = ' + CAST(@ChargeMasterAutomationExcludeReasonId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChargeMasterAutomationExclude].[DateTimeCreated] '

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
	 [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId]
	,[ChargeMasterAutomationExclude].[ChargeMasterId]
	,[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExclude].[DateTimeExpiration]
	,[ChargeMasterAutomationExclude].[DateTimeEffective]
	,[ChargeMasterAutomationExclude].[DateTimeCreated]
	,[ChargeMasterAutomationExclude].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExclude].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExclude].[LastUpdatedByUserProfileId]
FROM
	#tmp [tmp]
	INNER JOIN [ChargeMasterAutomationExclude] 
			ON [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] = [tmp].[ChargeMasterAutomationExcludeId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

RAISERROR('...creating [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId]
	 @ChargeMasterId int
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
	[ChargeMasterAutomationExcludeId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChargeMasterAutomationExcludeId) ' +
		   'SELECT [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] ' +
		   'FROM [ChargeMasterAutomationExclude] ' +
		   'WHERE [ChargeMasterAutomationExclude].[ChargeMasterId] = ' + CAST(@ChargeMasterId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChargeMasterAutomationExclude].[DateTimeCreated] '

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
	 [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId]
	,[ChargeMasterAutomationExclude].[ChargeMasterId]
	,[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExclude].[DateTimeExpiration]
	,[ChargeMasterAutomationExclude].[DateTimeEffective]
	,[ChargeMasterAutomationExclude].[DateTimeCreated]
	,[ChargeMasterAutomationExclude].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExclude].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExclude].[LastUpdatedByUserProfileId]
FROM
	#tmp [tmp]
	INNER JOIN [ChargeMasterAutomationExclude] 
			ON [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] = [tmp].[ChargeMasterAutomationExcludeId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

