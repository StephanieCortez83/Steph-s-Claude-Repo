SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertFacilityChartArchiveFile]
	 @FacilityChartArchiveId int
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ArchivedToPath varchar(500)
	,@FileDateOfService datetime
	,@IsDestroyed bit
	,@DateTimeDestroyed datetime = NULL
	,@FacilityChartArchiveFileId int OUTPUT
AS

INSERT INTO [dbo].[FacilityChartArchiveFile]
(
	 [FacilityChartArchiveId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ArchivedToPath]
	,[FileDateOfService]
	,[IsDestroyed]
	,[DateTimeDestroyed]
)
VALUES
(
	 @FacilityChartArchiveId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ArchivedToPath
	,@FileDateOfService
	,@IsDestroyed
	,@DateTimeDestroyed 
)

SET @FacilityChartArchiveFileId = @@IDENTITY

GO
