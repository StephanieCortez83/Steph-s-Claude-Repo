SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStageInfusionResults] (@QueryRate int = 100000
																  , @UniqueID  uniqueidentifier)
AS
	BEGIN
		SET NOCOUNT ON;

		--get the chart  list
		SELECT	i.ChartId x
		INTO	#ChartList
		FROM	dbo.FacilityChartArchiveItem i
		WHERE	EXISTS (SELECT	1
						FROM	dbo.FacilityChartArchiveStageCharts s
						WHERE	s.FacilityId = i.FacilityId
								AND i.ChartDOS BETWEEN s.DateFrom AND s.DateThru
								AND s.UniqueID = @UniqueID);

		CREATE NONCLUSTERED INDEX IX_tmp_ChartList
			ON #ChartList ([x]);

		DECLARE @min		 int = 0
			  , @max		 int = 0
			  , @offset		 int = 0
			  , @lastChartId int = (SELECT MAX(x)FROM #ChartList  )
			  , @chartCount	 int = (SELECT		COUNT(x)FROM #ChartList);

		DROP TABLE IF EXISTS #CHART_INFUSION_RESULT;

		CREATE TABLE #CHART_INFUSION_RESULT (x int);

		--loop through the charts to get CHART_INFUSION_RESULT_ID's (1m at a time)
		WHILE @min IS NOT NULL
			BEGIN
				SET @offset = @offset + 1000000;
				SET @min = (SELECT MIN(x)FROM #ChartList   WHERE x > @max);
				SET @max = CASE
							   WHEN @offset >= @chartCount
								   THEN @lastChartId
							   ELSE (SELECT		x
									 FROM		#ChartList
									 ORDER BY	x OFFSET @offset ROW FETCH NEXT 1 ROW ONLY)
						   END;

				INSERT	#CHART_INFUSION_RESULT (x)
						SELECT	CHART_INFUSION_RESULT_ID
						FROM	CHART_INFUSION_RESULT cir WITH (NOLOCK)
						WHERE	EXISTS (SELECT	1
										FROM	#ChartList cx
										WHERE	cir.CHART_ID = cx.x
												AND cx.x BETWEEN @min AND @max);
			END;

		CREATE NONCLUSTERED INDEX IX_tmp_CHART_INFUSION_RESULT
			ON #CHART_INFUSION_RESULT ([x]);


			--loop through the #CHART_INFUSION_RESULT and insert the metadata. loop theugh x number of records at a time based on @QueryRate
		SELECT	@min		 = 0
			  , @max		 = 0
			  , @offset		 = 0
			  , @lastChartId = (SELECT MAX(x)FROM #CHART_INFUSION_RESULT  )
			  , @chartCount	 = (SELECT		COUNT(x)FROM #CHART_INFUSION_RESULT);

		WHILE @min IS NOT NULL
			BEGIN
				SET @offset = @offset + @QueryRate;
				SET @min = (SELECT MIN(x)FROM #ChartList   WHERE x > @max);
				SET @max = CASE
							   WHEN @offset >= @chartCount
								   THEN @lastChartId
							   ELSE (SELECT		x
									 FROM		#CHART_INFUSION_RESULT
									 ORDER BY	x OFFSET @offset ROW FETCH NEXT 1 ROW ONLY)
						   END;

				INSERT	dbo.FacilityChartArchiveChartInfusionResults (CHART_INFUSION_RESULT_ID
																	, CHART_ID
																	, UNITS
																	, CHARGE_MASTER_ID
																	, MODIFIERS
																	, DATE_OF_SERVICE)
						SELECT	cir.CHART_INFUSION_RESULT_ID
							  , cir.CHART_ID
							  , cir.UNITS
							  , cir.CHARGE_MASTER_ID
							  , cir.MODIFIERS
							  , cir.DATE_OF_SERVICE
						FROM	CHART_INFUSION_RESULT cir WITH (NOLOCK)
						WHERE	EXISTS (SELECT	1
										FROM	#CHART_INFUSION_RESULT cx
										WHERE	cir.CHART_INFUSION_RESULT_ID = cx.x
												AND cx.x BETWEEN @min AND @max);
			END;
	END;
GO
