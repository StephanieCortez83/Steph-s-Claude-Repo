-----------------------------------------------------------------------------
-- 03) DACS-2485 - ALTER TABLE CHART- add columns FS Modifiers.sql
-----------------------------------------------------------------------------
USE [RevCycleDB];
GO

SELECT	TOP (1) 1 FROM	[dbo].[CHART] WITH (TABLOCKX)

ALTER TABLE [dbo].[CHART]
	ADD [ADD_MODIFIER_FS_TO_PHYSICIAN_LOS] [bit] NULL,
	CONSTRAINT [DF_ADD_MODIFIER_FS_TO_PHYSICIAN_LOS]  DEFAULT ((0)) FOR [ADD_MODIFIER_FS_TO_PHYSICIAN_LOS]

GO
