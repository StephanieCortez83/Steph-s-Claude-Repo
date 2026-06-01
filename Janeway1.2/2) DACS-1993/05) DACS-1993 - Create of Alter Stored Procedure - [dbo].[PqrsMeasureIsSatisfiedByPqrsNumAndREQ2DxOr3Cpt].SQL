------------------------------------------------------------------------------------
-- 05) DACS-1993 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByPqrsNumAndREQ2DxOr3Cpt].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByPqrsNumAndREQ2DxOr3Cpt] 
	  @ChartId INT
	, @PqrsNum varchar(20)
	, @Dos DATETIME = NULL
	, @IsValidTestOnly BIT = 0
	, @ShowDebug BIT = 0
	, @UseTodayForDos BIT = 1 -- For backwards compatibility
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @PqrsNum IS NULL OR LEN(@PqrsNum) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @PqrsNum';
		RETURN;
	END;

	IF @Dos IS NULL OR @UseTodayForDos <> 0
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- validate Measure Id
	DECLARE @MeasureId INT = 
		(
			SELECT TOP 1 
				[CMS_PQRI_MEASURE_ID] 
			FROM 
				[CMS_PQRI_MEASURE] 
			WHERE 
				[PQRS#] = @PqrsNum 
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos)
			ORDER BY 
				[CMS_PQRI_MEASURE_ID] DESC
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'unable to find valid @MeasureId from @PqrsNum';
		RETURN;
	END;

	-- Validate Chart Id
	DECLARE @chartRangeDate DATETIME = DATEADD(day,-720, GETDATE()); -- limit to last 2 years to save database resources

	DECLARE @testChartId INT = 
		(
			SELECT TOP 1 
				[CHART_ID] 
			FROM 
				[CHART] 
			WHERE 
				[CHART_ID] = @ChartId
				AND [TIME_OF_SERVICE] >= @chartRangeDate
			ORDER BY 
				[CHART_ID] DESC
		);

	IF @testChartId IS NULL OR @testChartId <= 0 OR @ChartId <> @testChartId 
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'unable to find valid @ChartId';
		RETURN;
	END;
	
	-- Validate Service Agreement needs the given PQRS Measure check
	DECLARE @SaId INT = 
		(
			SELECT TOP 1 
				[SERVICE_AGREEMENT_ID] 
			FROM 
				[CHART] 
			WHERE 
				[CHART_ID] = @ChartId
				AND [TIME_OF_SERVICE] >= @chartRangeDate
			ORDER BY 
				[CHART_ID] DESC
		);
	
	IF @SaId IS NULL OR @SaId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'invalid chart @SaId';
		RETURN;
	END;

	DECLARE @testSaId INT = 
		(
			SELECT TOP 1 
				[SERVICE_AGREEMENT_ID] 
			FROM 
				[SERVICE_AGREEMENT_PQRS]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND [SERVICE_AGREEMENT_ID] = @SaId
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos)
			ORDER BY 
				[SERVICE_AGREEMENT_PQRS_ID] DESC
		);

	IF @testSaId IS NULL OR @testSaId <= 0 OR @testSaId <> @SaId
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'invalid PQRI @TestSaId';
		RETURN;
	END;

	-- Are we running in test only mode?
	IF @IsValidTestOnly <> 0 
	BEGIN
		SELECT 'Result' = 1, 'Message' = 'Test Only: Valid combination of ACSCId, PQRS# and Dos', 'MeasureId' = CAST(IIF(@MeasureId IS NULL, -1, @MeasureId) AS VARCHAR(20));
		RETURN;
	END;

	EXEC [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt] 
			  @ChartId = @ChartId
			, @MeasureId = @MeasureId
			, @Dos = @Dos
			, @ShowDebug = @ShowDebug;

END; -- end procedure


GO


/*
testing:
EXEC [dbo].[PqrsMeasureIsSatisfiedByPqrsNumAndREQ2DxOr3Cpt] 
			  @ChartId = 2100107862
			, @PqrsNum ='332'
			, @IsValidTestOnly = 1
*/