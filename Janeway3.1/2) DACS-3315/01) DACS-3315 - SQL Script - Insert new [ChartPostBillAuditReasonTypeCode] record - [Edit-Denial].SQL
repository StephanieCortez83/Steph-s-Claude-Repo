----------------------------------------------------
-- 01) DACS-3315 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Edit-Denial].SQL
----------------------------------------------------
USE [RevCycleDB]
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 8)
BEGIN
	PRINT('Adding [dbo].[ChartPostBillAuditReasonTypeCode] item [Edit/Denial');
	INSERT INTO 
		[dbo].[ChartPostBillAuditReasonTypeCode] 
	(
		[ChartPostBillAuditReasonTypeCode]
		, [Key]
		, [DisplayName]
		, [ExternalCode]
		, [Description]
	)
	VALUES 
	(
		8
		, 'EditDenial'
		, 'Edit/Denial'
		, 'EDD'
		, 'Edit/Denial'
	);
END;

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 8)
BEGIN
	PRINT('!!!! Failed to add [ChartPostBillAuditReasonTypeCode] item [Edit/Denial] !!!!');
END;

GO


