---------------------------------------------------------------------------------------------------
-- 01) DACS-2252 - alter table CHARGE_MASTER - add age min max fields.SQL
-- *Note:  This script alters the highly used Charge_master table
---------------------------------------------------------------------------------------------------
USE [RevCycleDB] 
GO

SELECT TOP (1) 1 FROM [dbo].[CHARGE_MASTER] WITH (TABLOCKX)

ALTER TABLE [dbo].[CHARGE_MASTER]
	  ADD [AGE_MINIMUM] INT NULL
	, [AGE_MAXIMUM] INT NULL
	;

GO

