---------------------------------------------------------------------------------
-- 01) DACS-3318 - SQL Script to insert into SERVICE_AGREEMENT_RATE_TYPE.SQL
---------------------------------------------------------------------------------
USE [RevCycleDB]
GO 

/*
Please add new “Rate Types” Claim Based, FTE Billing, Hourly, Transaction to the Service Agreement rate type selection options.  
*/

-- begin tran; -- testing

-- setup resources
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @countBefore INT = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT_RATE_TYPE] WHERE [RATE_TYPE_CD] IN ('CB','FB','HO','TR')); 

IF @countBefore != 0
BEGIN
	SELECT 'ERROR' = 'At least one field already exists.  Exiting.  @countBefore = ' + CAST(@countBefore AS VARCHAR(50));
	RETURN;
END;

-------------------------------------------------------
-- backup the table first
-------------------------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'SERVICE_AGREEMENT_RATE_TYPE', @DestTable = 'SERVICE_AGREEMENT_RATE_TYPE_DACS-3318';

INSERT INTO [SERVICE_AGREEMENT_RATE_TYPE] 
	([RATE_TYPE_CD], [DESCRIPTION])
VALUES
	 ('CB','Claim Based')
	,('FB','FTE Billing')
	,('HO','Hourly')
	,('TR','Transaction');

DECLARE @countAfter INT = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT_RATE_TYPE] WHERE [RATE_TYPE_CD] IN ('CB','FB','HO','TR')); 

IF @countAfter != 4
BEGIN
	SELECT 'ERROR' = 'Unexpected return count.  Exiting.  @countAfter = ' + CAST(@countAfter AS VARCHAR(50));
	RETURN;
END;

SELECT 'RESULT' = 'DONE';

-- SELECT * FROM SERVICE_AGREEMENT_RATE_TYPE; -- testing

-- rollback tran; -- testing
-- commit tran; -- testing

GO


