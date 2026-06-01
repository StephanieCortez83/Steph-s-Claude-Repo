-----------------------------------------------------------------------------
-- DACS-1347:  Add column to service agreement and set default value.
-----------------------------------------------------------------------------

USE [RevCycleDB];
GO


SELECT	TOP (1) 1 FROM	[dbo].[SERVICE_AGREEMENT] WITH (TABLOCKX)


ALTER TABLE [dbo].[SERVICE_AGREEMENT]
ADD [HIGHLIGHT_LAST_CHANGED_DATE_OVER_24_HOURS] BIT NULL
GO


UPDATE	[dbo].[SERVICE_AGREEMENT] 
SET [HIGHLIGHT_LAST_CHANGED_DATE_OVER_24_HOURS] = 1
