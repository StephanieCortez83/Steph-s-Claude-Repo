------------------------------------------------------------------------------------
-- 01) DACS-3405 - Script - CMS_PQRI_MEASURE and CMS_PQRI_MEASURE_CODE - expire MIPS 76.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO
-- begin tran; -- testing

--------------------------------------
-- backup table before we work on it
--------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3405';
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3405';

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ExpirationDate DATETIME = '12-31-2022';

--------------------------------------
--  expire MIPS from CMS_PQRI_MEASURE table
--------------------------------------
DECLARE @measureId INT = (
	SELECT TOP 1 
		[CMS_PQRI_MEASURE_ID]
	FROM 
		[CMS_PQRI_MEASURE] 
	WHERE 
		[PQRS#] = '76' 
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate)
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC
	);

IF @measureId IS NULL OR @measureId < 170
BEGIN 
	SELECT '@measureId is invalid for expiration date given.  exiting.' = @measureId;
	RETURN;
END;

SELECT '@measureId' = @measureId;

DECLARE @startDateOfMips DATETIME = (
	SELECT TOP 1 
		[EFFECTIVE_DATE]
	FROM 
		[CMS_PQRI_MEASURE] 
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @measureId
	);

SELECT '@startDateOfMips' = @startDateOfMips;

IF @startDateOfMips > @ExpirationDate
BEGIN 
	SET @ExpirationDate = @startDateOfMips;
	SELECT 'Adjusted @ExpirationDate' = @ExpirationDate;
END;

UPDATE [CMS_PQRI_MEASURE]
	SET [EXPIRATION_DATE] = @ExpirationDate
WHERE
	[PQRS#] = '76' 
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @ExpirationDate);
	
DECLARE @CountItemsToProcess INT = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE] WHERE [PQRS#] = '76' AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate));

SELECT '#after process (expect 0)' = @CountItemsToProcess

--------------------------------------
--  expire MIPS from CMS_PQRI_MEASURE_CODE table
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([END_DATE] IS NULL OR [END_DATE] >= @ExpirationDate)
		AND [CMS_PQRI_MEASURE_ID] = @measureId
	) ;

SELECT '# CMS_PQRI_MEASURE_CODEs to process (expect ~??)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [END_DATE] = @ExpirationDate
WHERE
	([END_DATE] IS NULL OR [END_DATE] >= @ExpirationDate)
	AND [CMS_PQRI_MEASURE_ID] = @measureId
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate)
		AND [CMS_PQRI_MEASURE_ID] = @measureId
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess

GO

/*
testing:
-- rollback tran; -- testing
-- commit tran; -- testing

select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '76'
select top 200 * from CMS_PQRI_MEASURE_CODE where [CMS_PQRI_MEASURE_ID] = 201
*/