-----------------------------------------------------------------------------
-- 01) DACS-4604 - ALTER TABLE SERVICE_AGREEMENT - add column SHOW_LONG_PATIENT_ID1.sql
-----------------------------------------------------------------------------
USE [RevCycleDB];
GO

BEGIN TRAN;
	SELECT TOP (1) 1 FROM	[dbo].[SERVICE_AGREEMENT] WITH (TABLOCKX)

	ALTER TABLE [dbo].[SERVICE_AGREEMENT]
		ADD [SHOW_LONG_PATIENT_ID1] [bit] NULL
COMMIT TRAN;
GO
