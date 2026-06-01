USE [RevCycleDB]
GO

/****** Object:  StoredProcedure [dbo].[SelectChartAuditDiagnosisVersionItemByChartAuditVersionId]    Script Date: 5/17/2023 10:48:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER   PROCEDURE [dbo].[SelectChartAuditDiagnosisVersionItemByChartAuditVersionId]
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
	[ChartAuditDiagnosisVersionItemId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChartAuditDiagnosisVersionItemId) ' +
		   'SELECT [ChartAuditDiagnosisVersionItem].[ChartAuditDiagnosisVersionItemId] ' +
		   'FROM [ChartAuditDiagnosisVersionItem] ' +
		   'WHERE [ChartAuditDiagnosisVersionItem].[ChartAuditVersionId] = ' + CAST(@ChartAuditVersionId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChartAuditDiagnosisVersionItem].[DateTimeCreated] '

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
	 [ChartAuditDiagnosisVersionItem].[ChartAuditDiagnosisVersionItemId]
	,[ChartAuditDiagnosisVersionItem].[ChartAuditVersionId]
	,[ChartAuditDiagnosisVersionItem].[DateTimeCreated]
	,[ChartAuditDiagnosisVersionItem].[CreatedByUserProfileId]
	,[ChartAuditDiagnosisVersionItem].[DateTimeLastUpdated]
	,[ChartAuditDiagnosisVersionItem].[LastUpdatedByUserProfileId]
	,[ChartAuditDiagnosisVersionItem].[ChartAuditActionTypeCode]
	,[ChartAuditDiagnosisVersionItem].[ActionDescription]
	,[ChartAuditDiagnosisVersionItem].[PrevChartAuditDiagnosisVersionItemId]
	,[ChartAuditDiagnosisVersionItem].[IsPreviousVersionCorrect]
	,[ChartAuditDiagnosisVersionItem].[ICDCode]
	,[ChartAuditDiagnosisVersionItem].[DiagnosisTypeId]
	,[ChartAuditDiagnosisVersionItem].[LevelNumber]
	,[ChartAuditDiagnosisVersionItem].[IsPrimary]
	,[ChartAuditDiagnosisVersionItem].[ICDPostingOrder]
	,[ChartAuditDiagnosisVersionItem].[ExcludeFromQA]
	,[ChartAuditDiagnosisVersionItem].[ExcludeFromQAReasonID]
FROM
	#tmp [tmp]
	INNER JOIN [ChartAuditDiagnosisVersionItem] 
			ON [ChartAuditDiagnosisVersionItem].[ChartAuditDiagnosisVersionItemId] = [tmp].[ChartAuditDiagnosisVersionItemId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO


