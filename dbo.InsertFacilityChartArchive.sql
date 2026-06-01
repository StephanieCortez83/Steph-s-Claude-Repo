SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertFacilityChartArchive]
	 @CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@FacilityId int
	,@Throttle int
	,@Terminated bit = NULL
	,@LastDOSProcessed datetime = NULL
	,@FacilityChartArchiveId int OUTPUT
AS

INSERT INTO [dbo].[FacilityChartArchive]
(
	 [CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[FacilityId]
	,[Throttle]
	,[Terminated]
	,[LastDOSProcessed]
)
VALUES
(
	 @CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@FacilityId
	,@Throttle
	,@Terminated
	,@LastDOSProcessed 
)

SET @FacilityChartArchiveId = @@IDENTITY

GO
