----------------------------------------
-- 04) DACS-2951 - MDM Verbiage updates 2024.3 - SQL Script to delete all non Active CDMs from list of SAs.sql
/*
DELETE all CDMs ONLY if there are no charts:
Neighbors - Baytown GR (Service Agreement ID = 1914 Facility ID = 2026)
Neighbors - Crosby GR (Service Agreement ID = 1965 Facility ID = 2067)
Neighbors - Kingwood GR (Service Agreement ID = 1995 Facility ID = 2074)
Neighbors - Pasadena GR (Service Agreement ID = 1996 Facility ID = 2075)
Neighbors - Pearland GR (Service Agreement ID = 1997 Facility ID = 2076)
Neighbors - Porter GR (Service Agreement ID = 1998 Facility ID = 2077)

for QA Testing:
(Service Agreement ID = 555103 Facility ID = 1832)  first has 4 test charts that are removed
(Service Agreement ID = 555200 Facility ID = 555172) second has no charts at all
*/
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @countFound INT;
DECLARE @saFound INT;
DECLARE @SAId INT;

/*
-- QA Test:
------
SET @SAId = 555103; -- QA  first has 4 test charts that are removed
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId, @BackupDestTableSuffix = 'DACS-2951-QA1';
END;
------

------
SET @SAId = 555200; -- QA  second has no charts at all
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId, @BackupDestTableSuffix = 'DACS-2951-QA2';
END;
------
*/

-- Production:
------
SET @SAId = 1914; -- Neighbors - Baytown GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId, @BackupDestTableSuffix = 'DACS-2951-1';
END;
------

------
SET @SAId = 1965; -- Neighbors - Crosby GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-2'; -- (DBA replace if you think these table backups are necessary)
END;
------

------
SET @SAId = 1995; -- Neighbors - Kingwood GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-3'; -- (DBA replace if you think these table backups are necessary)
END;
------

------
SET @SAId = 1996; -- Neighbors - Pasadena GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-4'; -- (DBA replace if you think these table backups are necessary)
END;
------

------
SET @SAId = 1997; -- Neighbors - Pearland GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-5'; -- (DBA replace if you think these table backups are necessary)
END;
------

------
SET @SAId = 1998; -- Neighbors - Porter GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-6'; -- (DBA replace if you think these table backups are necessary)
END;
------



GO

/*
testing:
SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = 555103 
SELECT COUNT(*) FROM charge_master where SERVICE_AGREEMENT_ID = 555103 

SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = 555200 
SELECT COUNT(*) FROM charge_master where SERVICE_AGREEMENT_ID = 555200 

DECLARE @SAID INT = 555203
SELECT 'SA Name' = @SAID
SELECT [description] FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAID 
SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAID 
SELECT COUNT(*) FROM charge_master where SERVICE_AGREEMENT_ID = @SAID 

begin tran;

rollback tran;

select top 10 * from chart
*/