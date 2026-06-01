----------------------------------------
-- 03) DACS-4742 - ALTER Table FHIRSettings
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[FHIRSettings]
ADD [TimeZonesId] INT NULL;

ALTER TABLE [dbo].[FHIRSettings]
ADD CONSTRAINT FK_FHIRSettings_TimeZones
    FOREIGN KEY ([TimeZonesId]) REFERENCES [dbo].[TimeZones] ([TimeZonesId]);