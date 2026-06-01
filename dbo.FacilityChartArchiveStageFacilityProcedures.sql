SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStageFacilityProcedures] (@UniqueID  uniqueidentifier
																	 , @QueryRate int = 500000)
AS
	BEGIN
		SET NOCOUNT ON;

		DECLARE @uid uniqueidentifier = NEWID();

		--get the chart  list
		CREATE TABLE #ProcedureList (ID					   int IDENTITY(1, 1)
								   , FACILITY_PROCEDURE_ID int);

		INSERT	#ProcedureList (FACILITY_PROCEDURE_ID)
				SELECT	fpe.FACILITY_PROCEDURE_ID
				FROM	FACILITY_PROCEDURE_EVALUATION fpe WITH (NOLOCK)
				WHERE	EXISTS (SELECT	1
								FROM	dbo.FacilityChartArchiveStageCharts		s
										INNER JOIN dbo.FacilityChartArchiveItem i
											ON i.FacilityId = s.FacilityId
											   AND i.ChartDOS BETWEEN s.DateFrom AND s.DateThru
								WHERE	s.UniqueID = @UniqueID
										AND i.ChartId = fpe.CHART_ID);

		CREATE INDEX TMP_IDX_ProcedureList_ID
			ON #ProcedureList (ID);

		DECLARE @min		 int = 0
			  , @max		 int = 0
			  , @offset		 int = 0
			  , @lastChartId int = (SELECT MAX(FACILITY_PROCEDURE_ID)FROM #ProcedureList  )
			  , @chartCount	 int = (SELECT		COUNT(FACILITY_PROCEDURE_ID)
									FROM		#ProcedureList);

		--loop through the charts
		WHILE @min IS NOT NULL
			BEGIN
				SET @offset = @offset + @QueryRate;
				SET @min = (SELECT MIN(ID)FROM #ProcedureList  WHERE ID > @max);
				SET @max = CASE
							   WHEN @offset >= @chartCount
								   THEN @lastChartId
							   ELSE (SELECT		ID
									 FROM		#ProcedureList
									 ORDER BY	ID OFFSET @offset ROW FETCH NEXT 1 ROW ONLY)
						   END;

				INSERT	dbo.FacilityChartArchiveChartFacilityProcedures (FACILITY_PROCEDURE_ID
																	   , CHART_ADDITIONAL_PROCEDURE_ID
																	   , QUANTITY
																	   , MODIFIERS
																	   , CHART_ID
																	   , PROCEDURE_DATE
																	   , PHYSICIAN_ID
																	   , INSUFFICIENT_DOCUMENTATION_TO_BILL
																	   , DIAGNOSIS_CODE
																	   , DIAGNOSIS_CODE_ICD10
																	   , ICD_10_PCS_CODE)
						SELECT	fpe.FACILITY_PROCEDURE_ID
							  , NULL			CHART_ADDITIONAL_PROCEDURE_ID
							  , fpe.QUANTITY
							  , fpe.MODIFIERS
							  , fpe.CHART_ID
							  , fpe.PROCEDURE_DATE
							  , fpe.PHYSICIAN_ID
							  , fpe.INSUFFICIENT_DOCUMENTATION_TO_BILL
							  , fpe.ICD9_CODE	AS DIAGNOSIS_CODE
							  , fpe.ICD_10_CODE AS DIAGNOSIS_CODE_ICD10
							  , fpe.ICD_10_PCS_CODE
						FROM	FACILITY_PROCEDURE_EVALUATION fpe WITH (NOLOCK)
						WHERE	EXISTS (SELECT	1
										FROM	#ProcedureList px
										WHERE	fpe.FACILITY_PROCEDURE_ID = px.FACILITY_PROCEDURE_ID
												AND px.ID BETWEEN @min AND @max);
			END;

		INSERT	dbo.FacilityChartArchiveChartFacilityProcedures (FACILITY_PROCEDURE_ID
															   , CHART_ADDITIONAL_PROCEDURE_ID
															   , QUANTITY
															   , MODIFIERS
															   , CHART_ID
															   , PROCEDURE_DATE
															   , PHYSICIAN_ID
															   , INSUFFICIENT_DOCUMENTATION_TO_BILL
															   , DIAGNOSIS_CODE
															   , DIAGNOSIS_CODE_ICD10
															   , ICD_10_PCS_CODE)
				SELECT	cap.CHARGE_MASTER_ID
					  , cap.CHART_ADDITIONAL_PROCEDURE_ID
					  , cap.QUANTITY
					  , cap.MODIFIERS
					  , cap.CHART_ID
					  , cap.PROCEDURE_DATE
					  , cap.PHYSICIAN_ID
					  , cap.INSUFFICIENT_DOCUMENTATION_TO_BILL
					  , fpe.DIAGNOSIS_CODE
					  , fpe.DIAGNOSIS_CODE_ICD10
					  , cap.ICD_10_PCS_CODE
				FROM	CHART_ADDITIONAL_PROCEDURE								   cap WITH (NOLOCK)
						INNER JOIN dbo.FacilityChartArchiveChartFacilityProcedures fpe
							ON fpe.FACILITY_PROCEDURE_ID = cap.CHARGE_MASTER_ID
							   AND cap.CHART_ID = fpe.CHART_ID
				WHERE	cap.CLASS = 'FP'
						AND EXISTS (SELECT	1
									FROM	#ProcedureList l
									WHERE	l.FACILITY_PROCEDURE_ID = cap.CHARGE_MASTER_ID);
	END; 
GO
