----------------------------------------------------
-- 01) DACS-3241 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Inpatient Downgrade].SQL
----------------------------------------------------
USE [RevCycleDB]
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 7)
BEGIN
	PRINT('Adding [dbo].[ChartPostBillAuditReasonTypeCode] item [Inpatient Downgrade]');
	INSERT 
		INTO [dbo].[ChartPostBillAuditReasonTypeCode] 
			([ChartPostBillAuditReasonTypeCode], [Key], [DisplayName], [ExternalCode], [Description])
	VALUES 
		(7, 'InpatientDowngrade', 'Inpatient Downgrade', 'IDG', 'Inpatient Downgrade');
END;

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 7)
BEGIN
	PRINT('!!!! Failed to add [ChartPostBillAuditReasonTypeCode] item [Inpatient Downgrade] !!!!');
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

