---------------------------------------------------
-- 01) DACS-1802 - insert rows into ANALYTICAL_REPORT_REPORTS table.sql
---------------------------------------------------
USE RevCycleDB;  
GO

-- select * from ANALYTICAL_REPORT_REPORTS; -- if needed to check


BEGIN TRANSACTION;

DECLARE @NewReportName varchar(50) = 'ACS Sent Volumes KPI Report v2';
-- https://app.powerbi.com/groups/810c5f04-ae06-45d5-8e0d-1ea3b317ba9d/reports/0fdba6e6-d5e6-4ce1-a1bd-782e7682596c/ReportSectiona84d41980ba3b8ccd3dd
-- SELECT count([ANALYTICAL_REPORT_REPORTS_ID]) FROM [dbo].[ANALYTICAL_REPORT_REPORTS] WHERE [NAME] = @NewReportName

if (SELECT count([ANALYTICAL_REPORT_REPORTS_ID]) FROM [dbo].[ANALYTICAL_REPORT_REPORTS] WHERE [NAME] = @NewReportName) = 0
	INSERT INTO [dbo].[ANALYTICAL_REPORT_REPORTS] ([ANALYTICAL_REPORT_ITEM_ID],[NAME],[ANALYTICAL_GROUP_ITEM_ID])
		VALUES ('0fdba6e6-d5e6-4ce1-a1bd-782e7682596c',@NewReportName,'810c5f04-ae06-45d5-8e0d-1ea3b317ba9d')
ELSE
	PRINT('[' + @NewReportName + '] Exists already');

SET @NewReportName = 'Frequency by EM Codes';
-- https://app.powerbi.com/groups/810c5f04-ae06-45d5-8e0d-1ea3b317ba9d/reports/1da70c62-b180-4389-a9be-d3ec11e97412/ReportSectiondf0df0f0a492c08a0c09

if (SELECT count([ANALYTICAL_REPORT_REPORTS_ID]) FROM [dbo].[ANALYTICAL_REPORT_REPORTS] WHERE [NAME] = @NewReportName) = 0
	INSERT INTO [dbo].[ANALYTICAL_REPORT_REPORTS] ([ANALYTICAL_REPORT_ITEM_ID],[NAME],[ANALYTICAL_GROUP_ITEM_ID])
		VALUES ('1da70c62-b180-4389-a9be-d3ec11e97412',@NewReportName,'810c5f04-ae06-45d5-8e0d-1ea3b317ba9d')
ELSE
	PRINT('[' + @NewReportName + '] Exists already');

COMMIT TRANSACTION;
-- ROLLBACK TRANSACTION;

GO

