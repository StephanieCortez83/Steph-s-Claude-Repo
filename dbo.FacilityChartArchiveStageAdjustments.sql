SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStageAdjustments] (@UniqueID uniqueidentifier)
AS
	BEGIN
		SET NOCOUNT ON;

		INSERT	dbo.FacilityChartArchiveChartAdjustments (CHART_ADJUSTMENT_ID
														, CHART_ID
														, STATUS_ID
														, QUANTITY
														, MODIFIERS
														, REFERENCE_CODE
														, REASON_ID
														, COMMENT
														, ADJUSTMENT_DESCRIPTION
														, REVISED_DATE_OF_SERVICE
														, CHARGE_MASTER_ID)
				SELECT	ca.CHART_ADJUSTMENT_ID
					  , ca.CHART_ID
					  , ca.STATUS_ID
					  , ca.QUANTITY
					  , ca.MODIFIERS
					  , ca.REFERENCE_CODE
					  , ca.REASON_ID
					  , ca.COMMENT
					  , car.DESCRIPTION AS ADJUSTMENT_DESCRIPTION
					  , ca.REVISED_DATE_OF_SERVICE
					  , ca.CHARGE_MASTER_ID
				FROM	CHART_ADJUSTMENT				   ca WITH (NOLOCK)
						INNER JOIN CHART_ADJUSTMENT_REASON car WITH (NOLOCK)
							ON ca.REASON_ID = car.CHART_ADJUSTMENT_REASON_ID
				WHERE	EXISTS (SELECT	1
								FROM	dbo.FacilityChartArchiveStageCharts		s
										INNER JOIN dbo.FacilityChartArchiveItem i
											ON i.FacilityId = s.FacilityId
											   AND i.ChartDOS BETWEEN s.DateFrom AND s.DateThru
								WHERE	s.UniqueID = @UniqueID
										AND ca.CHART_ID = i.ChartId);
	END;
GO
