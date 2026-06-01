SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ICD_10_CM_SELECT_BY_ICD_10_CODE_AND_EFFECTIVE_DATE_AND_EXPIRATION_DATE]
	 @ICD_10_CODE varchar(10)
	,@EFFECTIVE_DATE datetime = NULL
	,@EXPIRATION_DATE datetime = NULL
	,@PAGE_INDEX int = NULL
    ,@PAGE_SIZE int	= 25
    ,@WHERE_CLAUSE varchar(1000) = NULL
    ,@ORDER_BY_CLAUSE varchar(250) = NULL
    ,@RECORD_COUNT int OUTPUT
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--[ID LIST]------------------------------------------------------

CREATE TABLE #tmp
(
	[INDEX_ID] int IDENTITY (1, 1) NOT NULL,
	[SEQ] int NOT NULL
)

DECLARE @sql nvarchar(2000)
DECLARE @KeyWhereClause nvarchar(1000)

SET @sql = 'INSERT INTO #tmp (SEQ) ' +
		   'SELECT [ICD_10_CM].[SEQ] ' +
		   'FROM [ICD_10_CM] ' +
		   'WHERE [ICD_10_CM].[ICD_10_CODE]		= ''' + @ICD_10_CODE +  '''' +
           '  AND ' +
		   ' ( ' +
		   '	[ICD_10_CM].[EFFECTIVE_DATE] IS NULL ' +
		   '	OR ' + 
		   '	[ICD_10_CM].[EFFECTIVE_DATE] <= CONVERT(date, ''' + CAST(@EFFECTIVE_DATE AS VARCHAR(36)) + ''')' +
		   ' ) ' +
		   '  AND ' +
		   ' ( ' +
		   '	[ICD_10_CM].[EXPIRATION_DATE] IS NULL ' +
		   '	OR ' + 
		   '	[ICD_10_CM].[EXPIRATION_DATE] >= CONVERT(date, ''' + CAST(@EXPIRATION_DATE AS VARCHAR(36)) + ''')' +
		   ' ) ' 

IF @WHERE_CLAUSE IS NOT NULL AND LEN(@WHERE_CLAUSE) > 0
	SET @sql = @sql + ' AND (' + @WHERE_CLAUSE + ') '

IF @ORDER_BY_CLAUSE IS NOT NULL AND LEN(@ORDER_BY_CLAUSE) > 0
	SET @sql = @sql + 'ORDER BY ' + @ORDER_BY_CLAUSE + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ICD_10_CM].[SEQ] '

EXEC sp_executesql @sql

--[RANGE]----------------------------------------------------------

SELECT @RECORD_COUNT = @@ROWCOUNT

DECLARE @FIRST_RECORD int
DECLARE @LAST_RECORD  int

IF @PAGE_INDEX IS NOT NULL
BEGIN
	SET @FIRST_RECORD = (@PAGE_INDEX * @PAGE_SIZE) + 1
	SET @LAST_RECORD  = (@PAGE_INDEX  + 1) * @PAGE_SIZE
END
ELSE
BEGIN
	SET @FIRST_RECORD = 1
	SET @LAST_RECORD  = @RECORD_COUNT
END

--[DATA]------------------------------------------------------------

SELECT
	 [ICD_10_CM].[SEQ]
	,[ICD_10_CM].[ICD_10_CODE]
	,[ICD_10_CM].[SELECTION_IND]
	,[ICD_10_CM].[SHORT_DESCRIPTION]
	,[ICD_10_CM].[LONG_DESCRIPTION]
	,[ICD_10_CM].[EFFECTIVE_DATE]
	,[ICD_10_CM].[EXPIRATION_DATE]
FROM
	#tmp [tmp]
	INNER JOIN [ICD_10_CM] 
			ON [ICD_10_CM].[SEQ] = [tmp].[SEQ]
WHERE
	[tmp].[INDEX_ID] BETWEEN @FIRST_RECORD AND @LAST_RECORD
ORDER BY
	[tmp].[INDEX_ID]

GO
