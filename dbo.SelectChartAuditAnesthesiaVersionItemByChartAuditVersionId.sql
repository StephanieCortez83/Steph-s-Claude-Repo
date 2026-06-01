SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChartAuditAnesthesiaVersionItemByChartAuditVersionId]
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
	,[ChartAuditAnesthesiaVersionItem].[StartTime]
	,[ChartAuditAnesthesiaVersionItem].[StopTime]
	,[ChartAuditAnesthesiaVersionItem].[ExcludeMinutes]
	,[ChartAuditAnesthesiaVersionItem].[Units]
	,[ChartAuditAnesthesiaVersionItem].[Minutes]
	,[ChartAuditAnesthesiaVersionItem].[ProviderModifiers]
	,[ChartAuditAnesthesiaVersionItem].[MacModifiers]
	,[ChartAuditAnesthesiaVersionItem].[PhysicalStatusModifier]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionFieldAvoidance]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionNonSupine]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionModifier]
	,[ChartAuditAnesthesiaVersionItem].[QualifyingCircumstanceCode]
	,[ChartAuditAnesthesiaVersionItem].[ChargeMasterId]
	,[ChartAuditAnesthesiaVersionItem].[BaseUnitExceptionLimitedAccessToAirway]
	,[ChartAuditAnesthesiaVersionItem].[DocumentationSupportsIncreasedComplexity]
	,[ChartAuditAnesthesiaVersionItem].[DocumentationSupportsIncreasedComplexityReasonId]
	,[ChartAuditAnesthesiaVersionItem].[CptModifiers]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditAnesthesiaVersionItem] 
			ON [ChartAuditAnesthesiaVersionItem].[ChartAuditAnesthesiaVersionItemId] = [tmp].[ChartAuditAnesthesiaVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO
