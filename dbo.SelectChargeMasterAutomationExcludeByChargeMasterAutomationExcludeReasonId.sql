SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]
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
