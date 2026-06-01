----------------------------------------------------------------
-- 01) DACS-2581 - Alter Table - dbo.SERVICE_AGREEMENT_CLINIC.SQL
----------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[SERVICE_AGREEMENT_CLINIC]
	ADD [DEFAULT_SELECTION] bit NULL;
