SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
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
