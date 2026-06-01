SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectFacilityLevelCodeFieldsByChartId]
	@ChartId INT
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		 [FACILITY_LEVEL].[CPT_CODE]
		,[FACILITY_LEVEL].[MODIFIER]
		,[FACILITY_LEVEL].[BILLING_CODE]
		,[FACILITY_LEVEL].[DESCRIPTION]
	FROM
		[FACILITY_LEVEL]
		JOIN [CHART]
		  ON [FACILITY_LEVEL].[FACILITY_LEVEL_ID] = 
			(
				CASE WHEN [CHART].[OVERRIDE_FACILITY_LEVEL_ID] <> -1 
					THEN [CHART].[OVERRIDE_FACILITY_LEVEL_ID]
					ELSE [CHART].[FACILITY_LEVEL_ID]
				END
			)  
	WHERE
		[CHART].[CHART_ID] = @ChartId
		AND [FACILITY_LEVEL].[SERVICE_AGREEMENT_ID] = [CHART].[SERVICE_AGREEMENT_ID]		
	;
/*

Replaces in method public int LoadLevelForChart(int chartId) ("\CCSBusinessObjects\DAO\Facility\FacilityLevelDAO.cs")
			sql = "SELECT FACILITY_LEVEL.CPT_CODE, FACILITY_LEVEL.MODIFIER, FACILITY_LEVEL.BILLING_CODE, FACILITY_LEVEL.DESCRIPTION"
				+ " FROM  FACILITY_LEVEL WITH (NOLOCK), CHART WITH (NOLOCK) "
				+ " WHERE FACILITY_LEVEL.FACILITY_LEVEL_ID = (CASE WHEN CHART.OVERRIDE_FACILITY_LEVEL_ID <> -1 "
																+ "THEN CHART.OVERRIDE_FACILITY_LEVEL_ID "
																+ "ELSE CHART.FACILITY_LEVEL_ID END) "
						+ "AND CHART.CHART_ID = " + aChart.ChartID;
*/
END
GO

CREATE   PROCEDURE [dbo].[SelectLogNoteForPast2WeeksByDetail]
	@Detail VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @endDay DATETIME = CAST(CAST(GETDATE() AS DATE) AS DATETIME);
	DECLARE @startDay DATETIME = DATEADD(DAY, (5 - DATEPART(WEEKDAY, @endDay) + @@DATEFIRST + 7) % 7 - 21, CAST(@endDay AS DATE));
		
	DECLARE @limitDate DATETIME;
	SET @limitDate = DATEADD(DAY, -5, @startDay);

	DECLARE @limitLogId INT = (select top 1 LOG_NOTE_ID from LOG_NOTE where CREATION_DATE_TIME < @limitDate order by log_note_id desc);
	DECLARE @limitChartId INT = (select top 1 chart_id from chart where CREATION_DATE_TIME < @limitDate order by chart_id desc);
	DECLARE @SearchStr VARCHAR(110) = ('%' + @Detail + '%');

	-- testing
	 select '@startDay' = @startDay, '@endDay' = @endDay, '@limitDate' = @limitDate,
		   '@limitLogId' = @limitLogId, '@limitChartId' = @limitChartId, '@SearchStr' = @SearchStr;


	SELECT TOP 2000
		 c.[FACILITY_CHART_ID]
		,ln.[DETAIL]
		,c.chart_id
	FROM
		[CHART] c
		INNER JOIN [LOG_NOTE] ln 
				ON c.[CHART_ID] = ln.[CHART_ID]
	WHERE 
		LN.[DETAIL] LIKE @SearchStr
		AND c.[TIME_OF_SERVICE] BETWEEN @startDay AND @endDay
		AND ln.[LOG_NOTE_ID] >= @limitLogId
		and c.[CHART_ID] >= @limitChartId;
END
GO

CREATE   PROCEDURE [dbo].[Select99292UnitsFromFacilityProcedureEvaluationByChartId]
	@ChartId INT
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP 1
		[QUANTITY]
	FROM
		[FACILITY_PROCEDURE_EVALUATION]
		INNER JOIN [CHARGE_MASTER]
				ON [CHARGE_MASTER].[CHARGE_MASTER_ID] = [FACILITY_PROCEDURE_EVALUATION].[FACILITY_PROCEDURE_ID]
					AND [CHARGE_MASTER].[CPT_CODE] = '99292'
	WHERE
		[FACILITY_PROCEDURE_EVALUATION].[CHART_ID] = @ChartId
		;


/*
Replaces in method public int Get99292UnitsForChart(int chartId)
			var sql = "SELECT QUANTITY FROM FACILITY_PROCEDURE_EVALUATION WITH (NOLOCK) WHERE FACILITY_PROCEDURE_EVALUATION.CHART_ID = " + chartId + " "
				+ "AND FACILITY_PROCEDURE_EVALUATION.FACILITY_PROCEDURE_ID = (SELECT FACILITY_PROCEDURE_EVALUATION.FACILITY_PROCEDURE_ID "
				+ "FROM FACILITY_PROCEDURE_EVALUATION WITH (NOLOCK), CHARGE_MASTER WITH (NOLOCK) WHERE "
				+ "FACILITY_PROCEDURE_EVALUATION.CHART_ID = " + chartId + " AND CHARGE_MASTER.CHARGE_MASTER_ID = FACILITY_PROCEDURE_EVALUATION.FACILITY_PROCEDURE_ID "
				+ "AND CHARGE_MASTER.CPT_CODE = '99292')";
*/
END
GO

CREATE   PROCEDURE [dbo].[Select99292UnitsFromPhysicianProcedureEvaluationByChartId]
	@ChartId INT
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		SUM(x.QTY)
	FROM
		(
			SELECT
				[QUANTITY] as QTY 
			FROM
				[PHYSICIAN_PROCEDURE_EVALUATION] ppe
				INNER JOIN [CHARGE_MASTER] cm
						ON ppe.[PHYSICIAN_PROCEDURE_ID] = cm.[CHARGE_MASTER_ID] AND cm.[CPT_CODE] = '99292'
			WHERE
				ppe.[CHART_ID] = @ChartId

			UNION ALL

			SELECT
				SUM([QUANTITY]) as QTY
			FROM
				[CHART_ADDITIONAL_PROCEDURE] cap 
			WHERE
				cap.[CHART_ID] = @ChartId
				AND cap.[CHARGE_MASTER_ID] =
					(
						SELECT TOP 1 [CHARGE_MASTER_ID]
						FROM
							[CHARGE_MASTER]
						WHERE
							[CHARGE_MASTER].[CHARGE_MASTER_ID] = cap.[CHARGE_MASTER_ID]
							AND [CHARGE_MASTER].[CPT_CODE] = '99292'
					)
		) x

/*
*Note: There is a built in flaw in the lower select statement above.  because the Class column is not used in the chart_additional_procedure table
	and because it is assumed that the charge master table will only have 1x 99292 cpt code for a given service agreement we cannot use joins correctly here.
	why?  because updating at this point will "break" what has been expected behavior of ACS for so long.  it is fine for single level facilities, which are most of them.
	but, might not be quite perfect for multi level facilities.  at some point thinking through this might be needed.  so, for now leaving the logic as presently implemented.
	fwiw i believe CM usage category column might need to be considered or, change the lower select statement to use an "in" clause instead of an "=".  or a combination thereof 

Replaces in method public int Get99292UnitsForChart(int chartId) ("\CCSBusinessObjects\DAO\Physician\PhysicianProcedureEvaluationListDAO.cs")
"SET NOCOUNT ON; SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;"
				+ " SELECT SUM(x.QTY) FROM "
				+ "(SELECT QUANTITY as QTY FROM PHYSICIAN_PROCEDURE_EVALUATION WHERE PHYSICIAN_PROCEDURE_EVALUATION.CHART_ID = " + chartId + " "
				+ "AND PHYSICIAN_PROCEDURE_EVALUATION.PHYSICIAN_PROCEDURE_ID = (SELECT PHYSICIAN_PROCEDURE_EVALUATION.PHYSICIAN_PROCEDURE_ID "
				+ "FROM PHYSICIAN_PROCEDURE_EVALUATION, CHARGE_MASTER WHERE "
				+ "PHYSICIAN_PROCEDURE_EVALUATION.CHART_ID = " + chartId + " AND CHARGE_MASTER.CHARGE_MASTER_ID = PHYSICIAN_PROCEDURE_EVALUATION.PHYSICIAN_PROCEDURE_ID "
				+ "AND CHARGE_MASTER.CPT_CODE = '99292')"
				+" UNION ALL "
				+ "SELECT SUM(QUANTITY) as QTY FROM CHART_ADDITIONAL_PROCEDURE cap WHERE cap.CHART_ID = " + chartId + " "
				+ "AND cap.CHARGE_MASTER_ID = (SELECT TOP 1 CHARGE_MASTER_ID "
				+ "FROM CHARGE_MASTER  "
				+ "WHERE CHARGE_MASTER.CHARGE_MASTER_ID = cap.CHARGE_MASTER_ID "
				+ "AND CHARGE_MASTER.CPT_CODE = '99292')) x";*/
END
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4898 SPROC variant within FacilityProcedureEvaluationListDAO,FacilityLevelDAO,ServiceAgreementDAO,PhysicianProcedureEvaluationListDAO.cs'))
	INSERT INTO 
		[TYPE_CODE]
		(
			[NAME]
		   ,[KEY]
		   ,[VALUE]
		   ,[DISPLAY_NAME]
		   ,[SHORT_NAME]
		   ,[DESCRIPTION]
		)
		VALUES
		(
			'ApplicationFeatureTypeCode'                                      																									--NAME
		   ,'CAB_4898'                                                    																										--KEY
		   ,9                                                                 																									--VALUE
		   ,'CAB_4898'                                                    																										--DISPLAY_NAME
		   ,'CAB_4898'                                                        																									--SHORT_NAME
		   ,'Enable/Disables DACS-4898 SPROC variant within FacilityProcedureEvaluationListDAO,FacilityLevelDAO,ServiceAgreementDAO,PhysicianProcedureEvaluationListDAO.cs' 	--DESCRIPTION
		)
ELSE
	PRINT('Type Code already exists.  Action skipped.');
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 9)
	INSERT INTO 
		[dbo].[ApplicationFeature]
		(
			 [DateTimeCreated]
			,[CreatedByUserProfileId]
			,[DateTimeLastUpdated]
			,[LastUpdatedByUserProfileId]
			,[ApplicationFeatureDomainObjectTypeCode]
			,[DomainObjectId]
			,[ApplicationFeatureTypeCode]
		)
	VALUES
		(
			 @dtCreated
			,@Uid
			,@dtCreated
			,@Uid
			,5
			,2147483647															--ALL
			,9
		)
ELSE
	PRINT('Application Feature already exists.  Action skipped.');
GO

