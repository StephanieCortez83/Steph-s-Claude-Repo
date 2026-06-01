-----------------------------------------------------------------------------
-- 01) DACS-1671 - ALTER TABLE [dbo].[FACILITY_FINANCIAL_CLASS] - add column [USE_ALTERNATE_GOV_COMMERCIAL_MODE].sql
-----------------------------------------------------------------------------
USE [RevCycleDB];
GO

ALTER TABLE [dbo].[FACILITY_FINANCIAL_CLASS]
	ADD [USE_ALTERNATE_GOV_COMMERCIAL_MODE] INT NULL,
	CONSTRAINT [DF_USE_ALTERNATE_GOV_COMMERCIAL_MODE]  DEFAULT ((0)) FOR [USE_ALTERNATE_GOV_COMMERCIAL_MODE];

GO


