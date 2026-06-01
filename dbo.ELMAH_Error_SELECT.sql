SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ELMAH_Error_SELECT]
	 @PAGE_INDEX int = NULL
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
	[ErrorId] uniqueidentifier NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ErrorId) ' +
		   'SELECT [ELMAH_Error].[ErrorId] ' +
		   'FROM [ELMAH_Error] ' 

IF @WHERE_CLAUSE IS NOT NULL AND LEN(@WHERE_CLAUSE) > 0
	SET @sql = @sql + ' WHERE (' + @WHERE_CLAUSE + ') '

IF @ORDER_BY_CLAUSE IS NOT NULL AND LEN(@ORDER_BY_CLAUSE) > 0
	SET @sql = @sql + 'ORDER BY ' + @ORDER_BY_CLAUSE + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ELMAH_Error].[TimeUtc]'

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
	 [ELMAH_Error].[ErrorId]
	,[ELMAH_Error].[Application]
	,[ELMAH_Error].[Host]
	,[ELMAH_Error].[Type]
	,[ELMAH_Error].[Source]
	,[ELMAH_Error].[Message]
	,[ELMAH_Error].[User]
	,[ELMAH_Error].[StatusCode]
	,[ELMAH_Error].[TimeUtc]
	,[ELMAH_Error].[Sequence]
	,[ELMAH_Error].[AllXml]
FROM
	#tmp [tmp]
	INNER JOIN [ELMAH_Error] 
			ON [ELMAH_Error].[ErrorId] = [tmp].[ErrorId]
WHERE
	[tmp].[INDEX_ID] BETWEEN @FIRST_RECORD AND @LAST_RECORD
ORDER BY
	[tmp].[INDEX_ID]

GO
