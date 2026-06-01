----------------------------------------
-- 09) DACS-4742 - ALTER Table [IgniteIntegrationLog]
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[IgniteIntegrationLog]
ADD [Status] VARCHAR(50),
    [JobId] VARCHAR(100)