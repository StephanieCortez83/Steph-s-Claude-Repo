----------------------------------------------
-- 01 DACS-1375 - add Cancel status to - ChartPostBillAuditStatusTypeCode.sql
----------------------------------------------
USE [RevCycleDB]
GO

/*
-- if needed for verification
SELECT * FROM [dbo].[ChartPostBillAuditStatusTypeCode]
*/

IF (SELECT count(*) FROM [dbo].[ChartPostBillAuditStatusTypeCode] WHERE [ExternalCode] = 'X' OR [ChartPostBillAuditStatusTypeCode] = 6) <= 0
	INSERT INTO [dbo].[ChartPostBillAuditStatusTypeCode]
		([ChartPostBillAuditStatusTypeCode],[Key],[DisplayName],[ExternalCode],[Description])
	VALUES (6,'PBACancelled','Post-Bill Audit Cancelled','X','Post-Bill Audit Cancelled');
ELSE
	PRINT('No action performed.');

GO

