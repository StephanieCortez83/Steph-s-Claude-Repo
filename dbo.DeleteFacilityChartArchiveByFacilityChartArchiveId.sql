SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteFacilityChartArchiveByFacilityChartArchiveId]
	@FacilityChartArchiveId int
AS

DELETE 
	FROM [dbo].[FacilityChartArchive]
WHERE
	[FacilityChartArchiveId] = @FacilityChartArchiveId

GO
