------------------------------------------------------------------------------------
-- 01) DACS-3534 - SQL Script to Expire MIPS- 436, 254, THEPQR3 on 12-31-24.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- begin tran; --testing
-- commit tran; --testing
-- rollback tran; --testing

-------------------------------------------------------
-- backup the tables first
-------------------------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3534';
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3534';
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'SERVICE_AGREEMENT_PQRS', @DestTable = 'SERVICE_AGREEMENT_PQRS_DACS-3534';


DECLARE @ExpirationDate DATETIME = '12-31-24';

--get the IDs for the MIPS to expire
DECLARE @mipsToExpire TABLE
	(
		Id INT IDENTITY(1, 1)
	   ,MipsName VARCHAR(100)
	   ,MipsId INT
	);

INSERT @mipsToExpire(MipsName, MipsId)
	SELECT 
		 [PQRS#] AS mipsName
		,[CMS_PQRI_MEASURE_ID] AS MipsId
	FROM 
		[CMS_PQRI_MEASURE]
	WHERE
		[PQRS#] IN ('436','254','THEPQR3');
		
SELECT * FROM @mipsToExpire; -- testing
	
DECLARE @CountMips INT = (SELECT COUNT(*) FROM @mipsToExpire)
	
IF @CountMips <> 3
BEGIN 
	SELECT 'Error' = 'Bad MIPS Count:  Check Table settings, adjust and try again.';
	RETURN;
END;

-------------------------------------------------------
-- update the CMS_PQRI_MEASURE TABLE
-------------------------------------------------------
SELECT TOP 200 * FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate); -- testing

SET @CountMips = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate))

SELECT '@CountMips before updating [CMS_PQRI_MEASURE]' = @CountMips;

UPDATE [CMS_PQRI_MEASURE]
	SET [EXPIRATION_DATE] = @ExpirationDate
	WHERE 
		[CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) 
		AND ([EFFECTIVE_DATE] < @ExpirationDate)
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate))

SELECT '@CountMips after updating [CMS_PQRI_MEASURE]' = @CountMips;

-- SELECT TOP 200 * FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire); -- testing


-------------------------------------------------------
-- update the CMS_PQRI_MEASURE_CODE TABLE
-------------------------------------------------------
SELECT TOP 10000 * FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([START_DATE] IS NULL OR [START_DATE] < @ExpirationDate) AND ([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([START_DATE] IS NULL OR [START_DATE] < @ExpirationDate) AND ([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate))

SELECT '@CountMips before updating [CMS_PQRI_MEASURE_CODE]' = @CountMips;

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [END_DATE] = @ExpirationDate
	WHERE 
		[CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) 
		AND ([START_DATE] IS NULL OR [START_DATE] < @ExpirationDate)
		AND ([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([START_DATE] IS NULL OR [START_DATE] < @ExpirationDate) AND ([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate))

SELECT '@CountMips after updating [CMS_PQRI_MEASURE_CODE]' = @CountMips;

-- SELECT TOP 10000 * FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire); -- testing

-------------------------------------------------------
-- update the [dbo].[SERVICE_AGREEMENT_PQRS]  table.
-------------------------------------------------------
SELECT TOP 10000 * FROM [SERVICE_AGREEMENT_PQRS] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT_PQRS] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate))

SELECT '@CountMips before updating [SERVICE_AGREEMENT_PQRS]' = @CountMips;

UPDATE [SERVICE_AGREEMENT_PQRS]
	SET [EXPIRATION_DATE] = @ExpirationDate
	WHERE 
		[CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) 
		AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < @ExpirationDate)
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT_PQRS] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate))

SELECT '@CountMips after updating [SERVICE_AGREEMENT_PQRS]' = @CountMips;

-- SELECT TOP 10000 * FROM [SERVICE_AGREEMENT_PQRS] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire); -- testing

-- commit tran;
-- rollback tran;
