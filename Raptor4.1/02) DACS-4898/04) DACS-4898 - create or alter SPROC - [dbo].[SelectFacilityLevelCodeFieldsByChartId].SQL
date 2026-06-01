----------------------------------------
-- 04) DACS-4898 - create or alter SPROC - [dbo].[SelectFacilityLevelCodeFieldsByChartId].SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFacilityLevelCodeFieldsByChartId]
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

DECLARE @exp VARCHAR(50) = (SELECT CAST(modify_date AS VARCHAR(50)) FROM sys.objects WHERE type = 'P' AND name = 'SelectFacilityLevelCodeFieldsByChartId');

IF OBJECT_ID('dbo.SelectFacilityLevelCodeFieldsByChartId', 'P') IS NOT NULL
	PRINT ('SPROC SelectFacilityLevelCodeFieldsByChartId last changed ' + @exp);
ELSE
	PRINT ('failed to create SPROC SelectFacilityLevelCodeFieldsByChartId');
GO

