SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchivePopulateItems] (@FromDate	 date = NULL
															  , @ThruDate	 date = NULL
															  , @ChartStatus int  = 5)
AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @FromDatetime		   datetime = CAST(ISNULL(@FromDate, '1/1/1900') AS datetime2)
			  , @ThruDatetime		   datetime = DATEADD(MILLISECOND, -3, CAST(DATEADD(DAY, 1, @ThruDate) AS datetime))
			  , @ArchiveDate		   datetime = DATEADD(YEAR, -3, GETDATE())
			  , @TerminatedArchiveDate datetime = DATEADD(DAY, -90, GETDATE());

		SET @ThruDatetime = IIF(@ThruDatetime > @ArchiveDate, @ArchiveDate, @ThruDatetime);

		INSERT	dbo.FacilityChartArchiveItem (FacilityId
											, ChartId
											, ChartTOS
											, ChartDOS)
				SELECT	c.FACILITY_ID
					  , c.CHART_ID
					  , ISNULL(c.TIME_OF_SERVICE, '1/1/1900')
					  , CAST(ISNULL(c.TIME_OF_SERVICE, '1/1/1900') AS date)
				FROM	dbo.CHART							c WITH (NOLOCK)
						INNER JOIN dbo.FacilityChartArchive fca
							ON fca.FacilityId = c.FACILITY_ID
				WHERE	c.CHART_STATUS_ID = @ChartStatus
						AND c.TIME_OF_SERVICE BETWEEN @FromDatetime AND ISNULL(@ThruDate, IIF(fca.Terminated = 1, @TerminatedArchiveDate, @ArchiveDate))
						AND NOT EXISTS (SELECT	1
										FROM	FacilityChartArchiveItem f
										WHERE	f.ChartId = c.CHART_ID)

	END;
GO
