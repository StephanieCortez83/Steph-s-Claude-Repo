SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [dbo].[SelectPhysicianLOSPointByChartId] (@ChartId int)
AS
	BEGIN
		DECLARE @ChartStatus						  int
			  , @ChartCompletionDate				  date
			  , @ChartTOS							  datetime
				--PHYSICIAN_CRITICAL_CARE
			  , @ChartPCC							  bit
			  , @ChartLosHistoryPCC					  bit
			  , @ChartPhyAddlLosHistoryPCC			  bit
			  , @ChartPhyAddlLosHistoryLevel		  int
			  , @ChartPhyLosPCC						  bit
			  , @ChartPhyLosLevelPCC				  bit
				--PHYSICIAN_SERVICE_PROC_ID
			  , @ChartProcId						  int
			  , @ChartLosHistoryProcId				  int
			  , @ChartPhyAddlLosHistoryProcId		  int
			  , @ChartPhyLosProcId					  int
			  , @ChartPhyLosLevelProcId				  int
				--PHYSICIAN_SERVICE_MOD
			  , @ChartSMod							  varchar(100)
			  , @ChartLosHistorySMod				  varchar(100)
			  , @ChartPhyAddlLosHistorySMod			  varchar(100)
			  , @ChartPhyLosSMod					  varchar(100)
			  , @ChartPhyLosLevelSMod				  varchar(100)
				--OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
			  , @ChartProcIdOverride				  int
			  , @ChartLosHistoryProcIdOverride		  int
			  , @ChartPhyAddlLosHistoryProcIdOverride int
			  , @ChartPhyLosProcIdOverride			  int
			  , @ChartPhyLosLevelProcIdOverride		  int
			  , @SA									  int;
		DECLARE @Exclusion bit = CASE
									 WHEN EXISTS (SELECT	TOP 1
															1
												  FROM		CODER_QA_REPORT_EXCLUSION qa WITH (NOLOCK)
												  WHERE		qa.KEY_VALUE_1 = @ChartId
															AND qa.KEY_VALUE_2 = 'PLOS'
															AND qa.SOURCE_RECORD_TABLE_NAME = 'CHART_LOS_HISTORY')
										 THEN 1
									 ELSE 0
								 END;

		--query CHART and CHART_LOS_HISTORY and exit early if possible
		SELECT	@ChartStatus		 = CHART_STATUS_ID
			  , @SA					 = SERVICE_AGREEMENT_ID
			  , @ChartCompletionDate = COMPLETION_DATE
			  , @ChartTOS			 = TIME_OF_SERVICE
			  , @ChartPCC			 = PHYSICIAN_CRITICAL_CARE
			  , @ChartProcId		 = PHYSICIAN_SERVICE_PROC_ID
			  , @ChartSMod			 = PHYSICIAN_SERVICE_MOD
			  , @ChartProcIdOverride = OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		FROM	CHART
		WHERE	CHART_ID = @ChartId;

		SELECT	@ChartLosHistoryPCC			   = PHYSICIAN_CRITICAL_CARE
			  , @ChartLosHistoryProcId		   = PHYSICIAN_SERVICE_PROC_ID
			  , @ChartLosHistorySMod		   = PHYSICIAN_SERVICE_MOD
			  , @ChartLosHistoryProcIdOverride = OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		FROM	CHART_LOS_HISTORY
		WHERE	CHART_ID = @ChartId;

		IF EXISTS (SELECT	1 v1qry
				   WHERE	@ChartStatus IN (3, 4, 5, 8)
							AND @Exclusion = 0
							AND ((@ChartLosHistoryProcId = -1
								  AND  @ChartProcId > 0)
								 OR (@ChartProcId = -1
									 AND   @ChartLosHistoryProcId > 0))
				   UNION
				   SELECT	8
				   WHERE	@ChartStatus IN (3, 4, 5, 8)
							AND @ChartLosHistoryPCC = 1
							AND @ChartPCC <> 1
				   UNION
				   SELECT	9
				   WHERE	@ChartStatus IN (3, 4, 5)
							AND @ChartPCC = 1
							AND @ChartLosHistoryPCC <> 1
				   UNION
				   SELECT	10
				   WHERE	@ChartStatus IN (3, 4, 5, 8)
							AND @ChartPhyAddlLosHistoryPCC = 1
							AND @ChartPhyLosLevelPCC <> 1
				   UNION
				   SELECT	11
				   WHERE	@ChartStatus IN (3, 4, 5)
							AND @ChartPCC = 1
							AND @ChartLosHistoryPCC <> 1)
			BEGIN
				SELECT 0  result;

				RETURN;
			END;

		--query CHART_PHYSICIAN_ADDITIONAL_LOS_HISTORY and CHART_PHYSICIAN_LEVEL_OF_SERVICE and exit early if possible		
		SELECT	@ChartPhyAddlLosHistoryPCC			  = PHYSICIAN_CRITICAL_CARE
			  , @ChartPhyAddlLosHistoryLevel		  = LEVEL_NUMBER
			  , @ChartPhyAddlLosHistoryProcId		  = PHYSICIAN_SERVICE_PROC_ID
			  , @ChartPhyAddlLosHistorySMod			  = PHYSICIAN_SERVICE_MOD
			  , @ChartPhyAddlLosHistoryProcIdOverride = OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		FROM	CHART_PHYSICIAN_ADDITIONAL_LOS_HISTORY
		WHERE	CHART_ID = @ChartId
				AND LEVEL_NUMBER = @ChartPhyAddlLosHistoryLevel;

		SELECT	@ChartPhyLosPCC			   = PHYSICIAN_CRITICAL_CARE
			  , @ChartPhyLosProcId		   = PHYSICIAN_SERVICE_PROC_ID
			  , @ChartPhyLosSMod		   = PHYSICIAN_SERVICE_MOD
			  , @ChartPhyLosProcIdOverride = OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		FROM	CHART_PHYSICIAN_LEVEL_OF_SERVICE
		WHERE	CHART_ID = @ChartId;

		SELECT	@ChartPhyLosLevelPCC			= PHYSICIAN_CRITICAL_CARE
			  , @ChartPhyLosLevelProcId			= PHYSICIAN_SERVICE_PROC_ID
			  , @ChartPhyLosLevelSMod			= PHYSICIAN_SERVICE_MOD
			  , @ChartPhyLosLevelProcIdOverride = OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		FROM	CHART_PHYSICIAN_LEVEL_OF_SERVICE
		WHERE	CHART_ID = @ChartId
				AND LEVEL_NUMBER = @ChartPhyAddlLosHistoryLevel;

		IF EXISTS (SELECT	2
				   WHERE	@ChartStatus IN (3, 4, 5, 8)
							AND @Exclusion = 0
							AND ((@ChartPhyAddlLosHistoryProcId = -1
								  AND  @ChartPhyLosLevelProcId > 0)
								 OR (@ChartPhyLosLevelProcId = -1
									 AND   @ChartPhyAddlLosHistoryProcId > 0))
				   UNION
				   SELECT	12
				   WHERE	@ChartStatus IN (3, 4, 5)
							AND @ChartPhyLosLevelPCC = 1
							AND @ChartPhyAddlLosHistoryPCC <> 1
				   UNION
				   SELECT	13
				   WHERE	@ChartCompletionDate >= '1/23/17'
							AND @Exclusion = 0
							AND ISNULL(@ChartSMod, '') <> ISNULL(@ChartLosHistorySMod, '')
				   UNION
				   SELECT	14
				   WHERE	@ChartCompletionDate >= '1/23/17'
							AND @Exclusion = 0
							AND ISNULL(@ChartPhyLosLevelSMod, '') <> ISNULL(@ChartPhyAddlLosHistorySMod, ''))
			BEGIN
				SELECT 0  result;

				RETURN;
			END;

		--do the more expensive queries if not exited earlier
		DECLARE @PspPCCChartProcIdOverride					int = IIF(@ChartProcIdOverride <> -1, @ChartProcIdOverride, @ChartProcId)
			  , @PspPCCChartPhyAddlLosHistoryProcIdOverride int = IIF(@ChartPhyAddlLosHistoryProcIdOverride <> -1, @ChartPhyAddlLosHistoryProcIdOverride, @ChartPhyAddlLosHistoryProcId)
			  , @PspPCCChartPhyLosProcIdOverride			int = IIF(@ChartPhyLosProcIdOverride <> -1, @ChartPhyLosProcIdOverride, @ChartPhyLosProcId)
			  , @PspPCCChartPhyLosLevelProcIdOverride		int = IIF(@ChartPhyLosLevelProcIdOverride <> -1, @ChartPhyLosLevelProcIdOverride, @ChartPhyLosLevelProcId)
			  , @PspPCCChartLosHistoryProcIdOverride		int = IIF(@ChartLosHistoryProcIdOverride <> -1, @ChartLosHistoryProcIdOverride, @ChartLosHistoryProcId);

		IF @Exclusion = 0
		   AND	@ChartStatus IN (3, 4, 5, 8)
		   AND	EXISTS (SELECT	4
						FROM	PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK)
						WHERE	psp.SERVICE_AGREEMENT_ID = @SA
								AND psp.PHYSICIAN_SERVICE_PROC_ID = @PspPCCChartLosHistoryProcIdOverride
								AND ISNULL(psp.CPT_CODE, '') <> ISNULL((SELECT	psp2.CPT_CODE
																		FROM	PHYSICIAN_SERVICE_PROCEDURE psp2 WITH (NOLOCK)
																		WHERE	psp2.SERVICE_AGREEMENT_ID = @SA
																				AND @ChartTOS BETWEEN psp2.EFFECTIVE_DATE AND psp2.EXPIRATION_DATE
																				AND @PspPCCChartProcIdOverride = psp2.PHYSICIAN_SERVICE_PROC_ID), '')
								AND @ChartLosHistoryPCC <> 1
						UNION
						SELECT	3
						FROM	PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK)
						WHERE	psp.SERVICE_AGREEMENT_ID = @SA
								AND psp.PHYSICIAN_SERVICE_PROC_ID = @PspPCCChartPhyAddlLosHistoryProcIdOverride
								AND ISNULL(psp.CPT_CODE, '') <> ISNULL((SELECT	psp2.CPT_CODE
																		FROM	PHYSICIAN_SERVICE_PROCEDURE psp2 WITH (NOLOCK)
																		WHERE	psp2.SERVICE_AGREEMENT_ID = @SA
																				AND @ChartTOS BETWEEN psp2.EFFECTIVE_DATE AND psp2.EXPIRATION_DATE
																				AND @PspPCCChartPhyLosLevelProcIdOverride = psp2.PHYSICIAN_SERVICE_PROC_ID), '')
								AND @ChartPhyAddlLosHistoryPCC <> 1
						UNION
						SELECT	5
						FROM	PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK)
						WHERE	psp.SERVICE_AGREEMENT_ID = @SA
								AND psp.PHYSICIAN_SERVICE_PROC_ID = @PspPCCChartPhyAddlLosHistoryProcIdOverride
								AND ISNULL(psp.CPT_CODE, '') <> ISNULL((SELECT	psp2.CPT_CODE
																		FROM	PHYSICIAN_SERVICE_PROCEDURE psp2 WITH (NOLOCK)
																		WHERE	psp2.SERVICE_AGREEMENT_ID = @SA
																				AND @ChartTOS BETWEEN psp2.EFFECTIVE_DATE AND psp2.EXPIRATION_DATE
																				AND @PspPCCChartPhyLosLevelProcIdOverride = psp2.PHYSICIAN_SERVICE_PROC_ID), '')
								AND @ChartPhyAddlLosHistoryPCC <> 1
						UNION
						SELECT	6
						FROM	PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK)
						WHERE	psp.SERVICE_AGREEMENT_ID = @SA
								AND psp.PHYSICIAN_SERVICE_PROC_ID = @PspPCCChartLosHistoryProcIdOverride
								AND ISNULL(psp.CPT_CODE, '') <> ISNULL((SELECT	psp2.CPT_CODE
																		FROM	PHYSICIAN_SERVICE_PROCEDURE psp2 WITH (NOLOCK)
																		WHERE	psp2.SERVICE_AGREEMENT_ID = @SA
																				AND @ChartTOS BETWEEN psp2.EFFECTIVE_DATE AND psp2.EXPIRATION_DATE
																				AND @PspPCCChartLosHistoryProcIdOverride = psp2.PHYSICIAN_SERVICE_PROC_ID), '')
								AND @ChartPCC <> 1
						UNION
						SELECT	7
						FROM	PHYSICIAN_SERVICE_PROCEDURE psp WITH (NOLOCK)
						WHERE	psp.SERVICE_AGREEMENT_ID = @SA
								AND psp.PHYSICIAN_SERVICE_PROC_ID = @PspPCCChartPhyLosLevelProcIdOverride
								AND ISNULL(psp.CPT_CODE, '') <> (SELECT ISNULL(psp2.CPT_CODE, '')
																 FROM	PHYSICIAN_SERVICE_PROCEDURE psp2 WITH (NOLOCK)
																 WHERE	psp2.SERVICE_AGREEMENT_ID = @SA
																		AND @ChartTOS BETWEEN psp2.EFFECTIVE_DATE AND psp2.EXPIRATION_DATE
																		AND @PspPCCChartPhyAddlLosHistoryProcIdOverride = psp2.PHYSICIAN_SERVICE_PROC_ID)
								AND @ChartPCC <> 1)
			BEGIN
				SELECT 0  result;

				RETURN;
			END;

		SELECT 1  result;
	END;
GO

DECLARE @exp VARCHAR(50) = (SELECT CAST(modify_date AS VARCHAR(50)) FROM sys.objects WHERE type = 'P' AND name = 'SelectPhysicianLOSPointByChartId');

IF OBJECT_ID('dbo.SelectPhysicianLOSPointByChartId', 'P') IS NOT NULL
	PRINT ('SPROC SelectPhysicianLOSPointByChartId last changed ' + @exp);
ELSE
	PRINT ('failed to create SPROC SelectPhysicianLOSPointByChartId');
GO

