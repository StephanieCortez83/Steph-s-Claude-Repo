------------------------------------------------------------------------------------
-- 02) DACS-3205 - Insert record into Table [ApplicationFeature] For limited facilities that starts with "PeaceHealth"
------------------------------------------------------------------------------------

USE [RevCycleDB]
GO

INSERT INTO [dbo].[ApplicationFeature]
           ([DateTimeCreated]
           ,[CreatedByUserProfileId]
           ,[DateTimeLastUpdated]
           ,[LastUpdatedByUserProfileId]
           ,[ApplicationFeatureDomainObjectTypeCode]
           ,[DomainObjectId]
           ,[ApplicationFeatureTypeCode])
     SELECT
	       GETDATE(), 10149, GETDATE(), 10149, 2, Facility_Id, 3
	 FROM [Facility]
	 WHERE
		facility_number <> ''
		AND name LIKE 'PeaceHealth -%'
GO


