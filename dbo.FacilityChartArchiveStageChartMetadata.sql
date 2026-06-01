SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStageChartMetadata] (@UniqueID	 uniqueidentifier
																, @QueryRate int = 100000)
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

		--loop through the charts
		WHILE @min IS NOT NULL
			BEGIN
				SET @offset = @offset + @QueryRate;
				SET @min = (SELECT MIN(x)FROM #ChartList   WHERE x > @max);
				SET @max = CASE
							   WHEN @offset >= @chartCount
								   THEN @lastChartId
							   ELSE (SELECT		x
									 FROM		#ChartList
									 ORDER BY	x OFFSET @offset ROW FETCH NEXT 1 ROW ONLY)
						   END;

				INSERT	dbo.FacilityChartArchiveChartMetadata (CHART_ID
															 , FACILITY_CHART_ID
															 , MEDICAL_RECORD_NUM
															 , PATIENT_TITLE
															 , PATIENT_FIRST_NAME
															 , PATIENT_MIDDLE_NAME
															 , PATIENT_LAST_NAME
															 , PATIENT_NAME_SUFFIX
															 , PATIENT_ADDR_LINE_1
															 , PATIENT_ADDR_LINE_2
															 , PATIENT_CITY
															 , PATIENT_STATE
															 , PATIENT_ZIPCODE
															 , PATIENT_DOB
															 , TIME_OF_SERVICE
															 , TIME_TO_ROOM
															 , TIME_OF_PHYS_EVAL
															 , TIME_OF_PHYS_DIS
															 , TIME_OF_TRIAGE
															 , TIME_OF_DIS
															 , DATE_RECEIVED
															 , FACILITY_CRITICAL_CARE
															 , FACILITY_CRITICAL_CARE_MINUTES
															 , PHYSICIAN_CRITICAL_CARE
															 , PHYSICIAN_CRITICAL_CARE_MINUTES
															 , PHYSICIAN_SERVICE_OVERRIDE_MOD
															 , NON_ER_PROCEDURES_OVERRIDE
															 , COMPLETED_BY_USER_PROFILE_ID
															 , APPROVED_BY_USER_PROFILE_ID
															 , FACILITY_ADMIN_CHART_ID
															 , PHYSICIAN_ID
															 , TRIAGE_NURSE_ID
															 , DIS_NURSE_ID
															 , SERVICE_AGREEMENT_ID
															 , PATIENT_DISPOSITION_ID
															 , FACILITY_LEVEL_ID
															 , PHYSICIAN_SERVICE_MOD
															 , OVERRIDE_FACILITY_LEVEL_ID
															 , FACILITY_LOS_27_MODIFIER
															 , FACILITY_LOS_32_MODIFIER
															 , FACILITY_LOS_95_MODIFIER
															 , FACILITY_LOS_AF_MODIFIER
															 , FACILITY_LOS_AG_MODIFIER
															 , FACILITY_LOS_CS_MODIFIER)
						SELECT	c.CHART_ID
							  , c.FACILITY_CHART_ID
							  , c.MEDICAL_RECORD_NUM
							  , c.PATIENT_TITLE
							  , c.PATIENT_FIRST_NAME
							  , c.PATIENT_MIDDLE_NAME
							  , c.PATIENT_LAST_NAME
							  , c.PATIENT_NAME_SUFFIX
							  , c.PATIENT_ADDR_LINE_1
							  , c.PATIENT_ADDR_LINE_2
							  , c.PATIENT_CITY
							  , c.PATIENT_STATE
							  , c.PATIENT_ZIPCODE
							  , c.PATIENT_DOB
							  , c.TIME_OF_SERVICE
							  , c.TIME_TO_ROOM
							  , c.TIME_OF_PHYS_EVAL
							  , c.TIME_OF_PHYS_DIS
							  , c.TIME_OF_TRIAGE
							  , c.TIME_OF_DIS
							  , c.DATE_RECEIVED
							  , c.FACILITY_CRITICAL_CARE
							  , c.FACILITY_CRITICAL_CARE_MINUTES
							  , c.PHYSICIAN_CRITICAL_CARE
							  , c.PHYSICIAN_CRITICAL_CARE_MINUTES
							  , c.PHYSICIAN_SERVICE_MOD AS PHYSICIAN_SERVICE_OVERRIDE_MOD
							  , c.NON_ER_PROCEDURES_OVERRIDE
							  , c.COMPLETED_BY_USER_PROFILE_ID
							  , c.APPROVED_BY_USER_PROFILE_ID
							  , c.FACILITY_ADMIN_CHART_ID
							  , c.PHYSICIAN_ID
							  , c.TRIAGE_NURSE_ID
							  , c.DIS_NURSE_ID
							  , c.SERVICE_AGREEMENT_ID
							  , c.PATIENT_DISPOSITION_ID
							  , c.FACILITY_LEVEL_ID
							  , c.PHYSICIAN_SERVICE_MOD
							  , ISNULL(c.OVERRIDE_FACILITY_LEVEL_ID, -1)
							  , FACILITY_LOS_27_MODIFIER
							  , FACILITY_LOS_32_MODIFIER
							  , FACILITY_LOS_95_MODIFIER
							  , FACILITY_LOS_AF_MODIFIER
							  , FACILITY_LOS_AG_MODIFIER
							  , FACILITY_LOS_CS_MODIFIER
						FROM	dbo.CHART c WITH (NOLOCK)
						WHERE	EXISTS (SELECT	1
										FROM	#ChartList cx
										WHERE	c.CHART_ID = cx.x
												AND cx.x BETWEEN @min AND @max);
			END;

		UPDATE	cm
		SET		cm.FACILITY_LEVEL_DESCRIPTION = fl.DESCRIPTION
			  , cm.FACILITY_LEVEL_CPT = fl.CPT_CODE
			  , cm.FACILITY_LEVEL_BILLING_CODE = fl.BILLING_CODE
			  , cm.PATIENT_DISPOSITION = pd.PATIENT_DISPOSITION_ID
		FROM	FacilityChartArchiveChartMetadata cm
				LEFT JOIN FACILITY_LEVEL		  fl WITH (NOLOCK)
					ON fl.FACILITY_LEVEL_ID = cm.FACILITY_LEVEL_ID
				LEFT JOIN dbo.PATIENT_DISPOSITION pd WITH (NOLOCK)
					ON pd.PATIENT_DISPOSITION_ID = cm.PATIENT_DISPOSITION_ID
		WHERE	EXISTS (SELECT 1  FROM #ChartList  cx WHERE cm.CHART_ID = cx.x);
	END;
 
GO
