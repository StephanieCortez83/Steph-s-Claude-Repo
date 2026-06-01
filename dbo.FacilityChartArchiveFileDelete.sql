SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveFileDelete] (@FacilityChartArchiveFileId int)
AS
	BEGIN
		SET NOCOUNT ON;

		--remove items tied to the file
		UPDATE dbo.FacilityChartArchiveItem
		SET FacilityChartArchiveFileId = NULL
		WHERE FacilityChartArchiveFileId=@FacilityChartArchiveFileId

		-- delete the file
		DELETE	dbo.FacilityChartArchiveItem
		WHERE FacilityChartArchiveFileId=@FacilityChartArchiveFileId

		
	END;
GO
