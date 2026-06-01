SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchivePopulateStageCharts] (@UniqueID   varchar(36)
																	 , @FacilityID int
																	 , @DateFrom   date
																	 , @DateThru   date)
AS
	BEGIN
		SET NOCOUNT ON;

		INSERT	dbo.FacilityChartArchiveStageCharts (UniqueID
												   , FacilityId
												   , DateFrom
												   , DateThru)
		VALUES (@UniqueID, @FacilityID, @DateFrom, @DateThru);
	END;
GO
