----------------------------------------------------------------------
-- 01) DACS-3550 - Script to expire specified records from table [CMS_PQRI_MEASURE_CODE].sql
----------------------------------------------------------------------
/*
	expire all records from [CMS_PQRI_MEASURE_CODE] that are like the following:  
	"Is there at least one additional patient encounter during performance period (CPT)?" 
	and are "new 2024 MIPS" records.  (measure id >= 175)
*/

-- USE [CMSRules]; -- can use either in this instance.  Using the RevCycleDB to make things just a little less confusing during deployment
USE [RevCycleDB];
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Dos DATETIME = '01-01-2024';
DECLARE @ExpirationDate DATETIME = '01-01-2024';

	--------------------------------------------
	-- Backup our data to be worked upon
	--------------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3550';


	--------------------------------------------
	-- see what we are working on
	--------------------------------------------
DECLARE @CountToProcess INT = (
	SELECT 
		COUNT(*)
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		[CMS_PQRI_MEASURE_ID] >= 175
		AND [START_DATE] <= @Dos
		AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
		AND [DESCRIPTION] like '%one additional patient encounter during performance period%'
	);

SELECT 'Count before Measure Code Processing (expect ~6) =' = @CountToProcess;


	--------------------------------------------
	-- update table 
	--------------------------------------------
UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [END_DATE] = @ExpirationDate
WHERE 
	[CMS_PQRI_MEASURE_ID] >= 175
	AND [START_DATE] <= @Dos
	AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
	AND [DESCRIPTION] like '%one additional patient encounter during performance period%';


	--------------------------------------------
	-- double check
	--------------------------------------------
SET @CountToProcess = (
	SELECT 
		COUNT(*)
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		[CMS_PQRI_MEASURE_ID] >= 175
		AND [START_DATE] <= @Dos
		AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
		AND [DESCRIPTION] like '%one additional patient encounter during performance period%'
	);

SELECT 'Count after Measure Code Processing (expect ~0) =' = @CountToProcess;


GO

/*
rollback if needed:
begin tran;

DECLARE @Dos DATETIME = '01-01-2024';
DECLARE @ExpirationDate DATETIME = '01-01-2024';

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [END_DATE] = NULL
WHERE 
	[CMS_PQRI_MEASURE_ID] >= 175
	AND [START_DATE] <= @Dos
	AND ([END_DATE] = @ExpirationDate)
	AND [DESCRIPTION] like '%one additional patient encounter during performance period%';

-- rollback tran;
-- commit tran;

Tools:
select top 300 * from cms_pqri_measure order by cms_pqri_measure_id;
select top 300 * from cms_pqri_measure where cms_pqri_measure_id in (215,202,199,200,210,211);
select top 100 * from cms_pqri_measure_code where [description] like '%encounter%';

SELECT * 
FROM 
	[CMS_PQRI_MEASURE_CODE]
WHERE
	[CMS_PQRI_MEASURE_ID] >= 175
	AND [START_DATE] <= @Dos
	AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
	AND [DESCRIPTION] like '%one additional patient encounter during performance period%'
	
*/

