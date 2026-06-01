----------------------------------------
-- 02) DACS-4742 - INSERT Table TimeZones
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

INSERT INTO TimeZones
(
    TimeZonesId, 
    TimeZonesName, 
    IANAIdentifier, 
    StandardOffset, 
    DstOffset, 
    ObservesDst,
    CreatedByUserProfileId,
    DateTimeCreated,
    LastUpdatedByUserProfileId,
    DateTimeLastUpdated
)
VALUES
(1, 'Eastern Time', 'America/New_York', 'UTC−05:00', 'UTC−04:00', 1, 2, GETDATE(), NULL, NULL),
(2, 'Central Time', 'America/Dallas', 'UTC−06:00', 'UTC−05:00', 1, 2, GETDATE(), NULL, NULL),
(3, 'Mountain Time', 'America/Denver', 'UTC−07:00', 'UTC−06:00', 1, 2, GETDATE(), NULL, NULL),
(4, 'Pacific Time', 'America/Los_Angeles', 'UTC−08:00', 'UTC−07:00', 1, 2, GETDATE(), NULL, NULL),
(5, 'Alaska Time', 'America/Anchorage', 'UTC−09:00', 'UTC−08:00', 1, 2, GETDATE(), NULL, NULL),
(6, 'Hawaii-Aleutian Time', 'Pacific/Honolulu', 'UTC−10:00', NULL, 0, 2, GETDATE(), NULL, NULL),
(7, 'Arizona (no DST)', 'America/Phoenix', 'UTC−07:00', NULL, 0, 2, GETDATE(), NULL, NULL);