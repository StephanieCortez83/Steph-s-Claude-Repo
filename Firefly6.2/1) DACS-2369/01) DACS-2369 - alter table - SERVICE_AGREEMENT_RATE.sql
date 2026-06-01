--------------------------------------------------
-- 01) DACS-2369 - alter table - SERVICE_AGREEMENT_RATE.sql
--------------------------------------------------

USE [RevCycleDB] 
GO

SELECT TOP (1) 1 FROM [dbo].[SERVICE_AGREEMENT_RATE] WITH (TABLOCKX)

ALTER TABLE [dbo].[SERVICE_AGREEMENT_RATE]
	  ADD [PATIENT_CLASS_ID] INT NULL
	;

GO