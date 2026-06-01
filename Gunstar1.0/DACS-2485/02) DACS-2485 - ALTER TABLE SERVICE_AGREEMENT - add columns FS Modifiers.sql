-----------------------------------------------------------------------------
-- 02) DACS-2485 - ALTER TABLE SERVICE_AGREEMENT - add columns FS Modifiers.sql
-----------------------------------------------------------------------------
USE [RevCycleDB];
GO

SELECT	TOP (1) 1 FROM	[dbo].[SERVICE_AGREEMENT] WITH (TABLOCKX)

ALTER TABLE [dbo].[SERVICE_AGREEMENT]
	ADD [DISPLAY_MODIFIER_FS_CHECKBOX] [bit] NULL,
	CONSTRAINT [DF_DISPLAY_MODIFIER_FS_CHECKBOX]  DEFAULT ((0)) FOR [DISPLAY_MODIFIER_FS_CHECKBOX];

GO
