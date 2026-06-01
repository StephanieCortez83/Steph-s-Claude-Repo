----------------------------------------
-- 05) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcEvalDiagIcd10ByChartIdAndProcIdAndLevelAndDos].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysSvcEvalDiagIcd10ByChartIdAndProcIdAndLevelAndDos]
    @ChartId INT,
    @ProcId INT,
	@LevelNumber INT,
	@DateOfService DATETIME
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		[Icd10Codes]
	FROM 
		[dbo].[PhysicianServiceEvalDiagnosis]
	WHERE
		[ChartId] = @ChartId
		AND [PhysicianServiceProcId] = @ProcId
		AND [PhysicianServiceLevelNumber] = @LevelNumber
		AND [DateOfService] = @DateOfService;

END
GO
