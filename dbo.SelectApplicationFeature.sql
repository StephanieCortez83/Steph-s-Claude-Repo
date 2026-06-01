SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SelectApplicationFeature]
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
	[ApplicationFeatureId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ApplicationFeatureId) ' +
		   'SELECT [ApplicationFeatureId] ' +
		   'FROM [ApplicationFeature] ' 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' WHERE (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ApplicationFeature].[DateTimeCreated]'

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
	 [ApplicationFeature].[ApplicationFeatureId]
	,[ApplicationFeature].[DateTimeCreated]
	,[ApplicationFeature].[CreatedByUserProfileId]
	,[ApplicationFeature].[DateTimeLastUpdated]
	,[ApplicationFeature].[LastUpdatedByUserProfileId]
	,[ApplicationFeature].[ApplicationFeatureDomainObjectTypeCode]
	,[ApplicationFeature].[DomainObjectId]
	,[ApplicationFeature].[ApplicationFeatureTypeCode]
FROM
	#tmp [tmp]
	INNER JOIN [ApplicationFeature] 
			ON [ApplicationFeature].[ApplicationFeatureId] = [tmp].[ApplicationFeatureId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO
