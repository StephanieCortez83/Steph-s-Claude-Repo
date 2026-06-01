SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveGetChartByFacilityDOS] (@FacilityID int
																			  , @DateFrom	date = NULL
																			  , @DateThru	date = NULL)
AS
	BEGIN
		SET NOCOUNT ON;

		SET @DateFrom = ISNULL(@DateFrom, '1/1/1900');
		SET @DateThru = ISNULL(@DateThru, '12/31/2199');

		SELECT		ChartId
				  , FacilityId
				  , ChartDOS
		FROM		dbo.FacilityChartArchiveItem
		WHERE		FacilityId = @FacilityID
					AND FacilityChartArchiveFileId IS NULL
					AND ChartDOS BETWEEN @DateFrom AND @DateThru
		ORDER BY	ChartDOS ASC;
	END;
GO
