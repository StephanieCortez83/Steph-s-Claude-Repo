SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteFacilityChartArchiveFileByFacilityChartArchiveFileId]
	@FacilityChartArchiveFileId int
AS

DELETE 
	FROM [dbo].[FacilityChartArchiveFile]
WHERE
	[FacilityChartArchiveFileId] = @FacilityChartArchiveFileId

GO
