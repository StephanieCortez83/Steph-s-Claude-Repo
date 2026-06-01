---------------------------------------------------------------------------------
-- 01) DACS-3289 - SQL Script Update 92960 CHARGE_MASTER entries that include 'conscious sedation'.SQL
---------------------------------------------------------------------------------
USE [RevCycleDB]
GO 
-- begin tran; -- testing

-- setup resources
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #TempToProcessTable;

SELECT DISTINCT TOP 5000 
	  [CHARGE_MASTER_ID]
	, [SERVICE_AGREEMENT_ID]
	, [CPT_CODE]
	, [DESCRIPTION]
INTO #TempToProcessTable	
FROM 
	[CHARGE_MASTER]
WHERE
	[CPT_CODE] = '92960'
	AND [DESCRIPTION] LIKE '%conscious sedation%' -- expect 370 on QA, 668 in production
	AND GETDATE() >= [EFFECTIVE_DATE]
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
ORDER BY 
	[SERVICE_AGREEMENT_ID], [CPT_CODE]

DECLARE @countToProcess INT = (SELECT COUNT(*) FROM #TempToProcessTable);
SELECT '@countToProcess' = @countToProcess;
--SELECT DISTINCT * FROM #TempToProcessTable; -- testing

IF @countToProcess IS NULL OR @countToProcess <= 0
BEGIN 
	SELECT 'Result' = 'Nothing to do.  Exiting';
	RETURN
END;

-------------------------------------------------------
-- backup the table first
-------------------------------------------------------
exec [dbo].[Maintenance_BackupTable] @SrcTable = 'CHARGE_MASTER', @DestTable = 'CHARGE_MASTER_DACS-3289';
-------------------------------------------------------

UPDATE 
	[CHARGE_MASTER]
SET 
	[DESCRIPTION] = 'Cardioversion'
WHERE 
	[CHARGE_MASTER_ID] IN (SELECT [CHARGE_MASTER_ID] FROM #TempToProcessTable) 

-- Results of change:
DECLARE @countResult INT = (SELECT Count(*)
	FROM 
		[CHARGE_MASTER]
	WHERE
		[CPT_CODE] = '92960'
		AND [DESCRIPTION] LIKE '%conscious sedation%' -- expect 0
		AND GETDATE() >= [EFFECTIVE_DATE]
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	);
	
SELECT '@countResult (0 is expected)' = @countResult;

-- rollback tran; -- testing
-- commit tran; -- testing

GO


/*
-- expected messaging output:
(370 rows affected)

(1 row affected)
 @countSource: 1314388
 backing up [CHARGE_MASTER] to [CHARGE_MASTER_DACS-3289]
backup table SQL :: SELECT * INTO [CHARGE_MASTER_DACS-3289] FROM [CHARGE_MASTER]

(1314388 rows affected)

(1 row affected)

(370 rows affected)

(1 row affected)

Completion time: 2024-05-23T12:26:56.0604335-04:00
*/

/*
-- rollback:
DROP TABLE IF EXISTS #TempRollbackTable;

SELECT DISTINCT TOP 5000 
	  [CHARGE_MASTER_ID]
	, [SERVICE_AGREEMENT_ID]
	, [CPT_CODE]
	, [DESCRIPTION]
INTO #TempRollbackTable	
FROM 
	[CHARGE_MASTER_DACS-3289]
WHERE
	[CPT_CODE] = '92960'
	AND [DESCRIPTION] LIKE '%conscious sedation%' -- expect 370 on QA, 668 in production
	AND GETDATE() >= [EFFECTIVE_DATE]
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
ORDER BY 
	[SERVICE_AGREEMENT_ID], [CPT_CODE]

DECLARE @countToRollback INT = (SELECT COUNT(*) FROM #TempRollbackTable);
SELECT '@countToRollback' = @countToRollback;
--SELECT DISTINCT * FROM #TempRollbackTable; -- testing

IF @countToRollback IS NULL OR @countToRollback <= 0
BEGIN 
	SELECT 'Result' = 'Nothing to rollback.  Exiting';
	RETURN
END;

UPDATE cm
	SET cm.[DESCRIPTION] = tmp.[DESCRIPTION]
FROM 
	[CHARGE_MASTER] cm
	INNER JOIN #TempRollbackTable tmp ON cm.[CHARGE_MASTER_ID] = tmp.[CHARGE_MASTER_ID]


-- Results of change:
SELECT *
FROM 
	[CHARGE_MASTER]
WHERE
	[CHARGE_MASTER_ID] IN (SELECT [CHARGE_MASTER_ID] FROM #TempRollbackTable)


*/

/*-- testing
SELECT DISTINCT TOP 5000 
	'Updated' AS SRC ,
	  [CHARGE_MASTER_ID]
	, [SERVICE_AGREEMENT_ID]
	, [CPT_CODE]
	, [DESCRIPTION]
FROM 
	[CHARGE_MASTER]
WHERE 
	[CHARGE_MASTER_ID] IN (SELECT [CHARGE_MASTER_ID] FROM #TempToProcessTable)
ORDER BY 
	[SERVICE_AGREEMENT_ID], [CPT_CODE]

-- testing
SELECT DISTINCT TOP 5000 
	'All' AS SRC ,
	  [CHARGE_MASTER_ID]
	, [SERVICE_AGREEMENT_ID]
	, [CPT_CODE]
	, [DESCRIPTION]
FROM 
	[CHARGE_MASTER]
WHERE 
	[CPT_CODE] = '92960'
	AND [DESCRIPTION] LIKE 'Cardioversion%' -- expect 0
	AND GETDATE() >= [EFFECTIVE_DATE]
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
ORDER BY 
	[SERVICE_AGREEMENT_ID], [CPT_CODE]
*/

