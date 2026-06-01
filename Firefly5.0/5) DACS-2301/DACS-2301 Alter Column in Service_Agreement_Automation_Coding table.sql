---------------------------------------------------------------------------------------------------
-- DACS-2301
-- Modify Import Directory column of the SERVICE_AGREEMENT_AUTOMATION_CODING table to allow nulls
---------------------------------------------------------------------------------------------------


USE [RevCycleDB] GO

SELECT TOP (1) 1 FROM [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING] WITH (TABLOCKX)

ALTER TABLE [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING]
ALTER COLUMN [IMPORT_DIRECTORY] VARCHAR(256) NULL;

GO
