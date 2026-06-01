----------------------------------------
-- 01) DACS-4802 - create or alter SPROC - SelectChartAssignmentMethodIsChartFirstViewFromServiceAgreementByChartId.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartAssignmentMethodIsChartFirstViewFromServiceAgreementByChartId]
	@ChartId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	IF EXISTS
		(
			SELECT 
				TOP 1 1
			FROM
				[SERVICE_AGREEMENT]
				INNER JOIN [CHART] 
						ON [CHART].[SERVICE_AGREEMENT_ID] = [SERVICE_AGREEMENT].[SERVICE_AGREEMENT_ID] AND [CHART_ID] = @ChartId
			WHERE
				[CHART_ASSIGNMENT_METHOD_ID] = 2 -- ServiceAgreement.CHART_ASSIGNMENT_METHOD_CHART_FIRST_VIEW
		)
		RETURN 1;
END;
GO