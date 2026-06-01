SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStagePhysicianLOS] (@UniqueID uniqueidentifier)
AS
	BEGIN
		SET NOCOUNT ON;

		SELECT	c.CHART_ID
			  , PHYSICIAN_SERVICE_MOD
			  , IIF(c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1, 0, 1) isChartLevel
			  , PHYSICIAN_SERVICE_PROC_ID
		INTO	#ChartList
		FROM	dbo.FacilityChartArchiveChartMetadata c
		WHERE	EXISTS (SELECT	1
						FROM	dbo.FacilityChartArchiveStageCharts		s
								INNER JOIN dbo.FacilityChartArchiveItem i
									ON s.FacilityId = i.FacilityId
									   AND i.ChartDOS BETWEEN s.DateFrom AND s.DateThru
						WHERE	s.UniqueID = @UniqueID
								AND i.ChartId = c.CHART_ID);

		INSERT	dbo.FacilityChartArchiveChartPhysicianLOS (PHYSICIAN_SERVICE_MOD
														 , CHART_ID
														 , QUANTITY
														 , SHORT_DESC
														 , CPT_CODE
														 , BILLING_CODE
														 , ALIAS_BILLING_CODE
														 , DEPARTMENT
														 , LEVEL_NUMBER)
				SELECT	ca.PHYSICIAN_SERVICE_MOD
					  , ca.CHART_ID
					  , 1				AS QUANTITY
					  , psp.DESCRIPTION AS SHORT_DESC
					  , psp.CPT_CODE
					  , psp.BILLING_CODE
					  , psp.ALIAS_BILLING_CODE
					  , psp.DEPARTMENT
					  , 1				AS LEVEL_NUMBER
				FROM	#ChartList							   ca
						INNER JOIN PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK)
							ON ca.PHYSICIAN_SERVICE_PROC_ID = psp.PHYSICIAN_SERVICE_PROC_ID
				WHERE	isChartLevel = 0
				UNION
				SELECT	los.PHYSICIAN_SERVICE_MOD
					  , los.CHART_ID
					  , 1				AS QUANTITY
					  , psp.DESCRIPTION AS SHORT_DESC
					  , psp.CPT_CODE
					  , psp.BILLING_CODE
					  , psp.ALIAS_BILLING_CODE
					  , psp.DEPARTMENT
					  , los.LEVEL_NUMBER
				FROM	CHART_PHYSICIAN_LEVEL_OF_SERVICE	   los WITH (NOLOCK)
						INNER JOIN PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK)
							ON los.PHYSICIAN_SERVICE_PROC_ID = psp.PHYSICIAN_SERVICE_PROC_ID
				WHERE	EXISTS (SELECT	1
								FROM	#ChartList c
								WHERE	c.CHART_ID = los.CHART_ID)
						AND (los.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID IS NULL
							 OR los.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID = -1);
	END;
GO
