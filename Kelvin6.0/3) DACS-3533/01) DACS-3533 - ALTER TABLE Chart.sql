------------------------------------------------------------------------------------
-- 01) DACS-3533 - ALTER Table to add a new column
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[CHART] 
ADD NO_PQRS BIT NULL