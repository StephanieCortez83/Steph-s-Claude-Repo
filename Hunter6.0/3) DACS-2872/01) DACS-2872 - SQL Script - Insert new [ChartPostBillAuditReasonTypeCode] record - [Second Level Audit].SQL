----------------------------------------------------
-- 01) DACS-2872 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Second Level Audit].SQL
----------------------------------------------------
USE [RevCycleDB]
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 6)
BEGIN
	PRINT('Adding [dbo].[ChartPostBillAuditReasonTypeCode] item [Second Level Audit]');
	INSERT 
		INTO [dbo].[ChartPostBillAuditReasonTypeCode] 
			([ChartPostBillAuditReasonTypeCode], [Key], [DisplayName], [ExternalCode], [Description])
	VALUES 
		(6, 'SecondLevelAudit', 'Second Level Audit', 'SLA', 'Second Level Audit (2nd Level Audit)');
END;

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 6)
BEGIN
	PRINT('!!!! Failed to add [ChartPostBillAuditReasonTypeCode] item [Second Level Audit] !!!!');
END;

GO

/*
testing: 
SELECT TOP (1000) [ChartPostBillAuditReasonTypeCode]
      ,[Key]
      ,[DisplayName]
      ,[ExternalCode]
      ,[Description]
  FROM [RevCycleDB].[dbo].[ChartPostBillAuditReasonTypeCode]
---
begin tran;
rollback tran;
commit tran;
*/

