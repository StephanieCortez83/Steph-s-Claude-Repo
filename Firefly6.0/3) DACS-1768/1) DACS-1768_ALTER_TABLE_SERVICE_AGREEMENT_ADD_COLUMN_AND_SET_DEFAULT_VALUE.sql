-----------------------------------------------------------------------------
-- DACS-1768:  Add column to service agreement and set default value.
-----------------------------------------------------------------------------

USE [RevCycleDB];
GO


SELECT	TOP (1) 1 FROM	[dbo].[SERVICE_AGREEMENT] WITH (TABLOCKX)

ALTER TABLE [dbo].[SERVICE_AGREEMENT]
ADD [SHOW_AGED_ACCOUNTS_IN_ORANGE] BIT NULL
GO


UPDATE	[dbo].[SERVICE_AGREEMENT] 
SET [SHOW_AGED_ACCOUNTS_IN_ORANGE] = 1

GO

