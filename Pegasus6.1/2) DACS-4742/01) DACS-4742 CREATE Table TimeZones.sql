----------------------------------------
-- 01) DACS-4742 - CREATE Table TimeZones
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE TimeZones (
    TimeZonesId INT PRIMARY KEY,
    TimeZonesName NVARCHAR(50),
    IANAIdentifier NVARCHAR(50),
    StandardOffset NVARCHAR(10),
    DstOffset NVARCHAR(10) NULL,
    ObservesDst BIT,
	CreatedByUserProfileId INT NOT NULL,
	DateTimeCreated DateTime NOT NULL,
	LastUpdatedByUserProfileId INT,
	DateTimeLastUpdated DateTime
);