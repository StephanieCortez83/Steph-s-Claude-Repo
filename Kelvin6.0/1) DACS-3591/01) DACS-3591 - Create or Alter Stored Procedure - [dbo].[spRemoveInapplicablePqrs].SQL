------------------------------------------------------------------------------------
-- 01) DACS-3591 - Create or Alter Stored Procedure - [dbo].[spRemoveInapplicablePqrs].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spRemoveInapplicablePqrs', @DestProc = 'spRemoveInapplicablePqrs_DACS-3591';
GO


CREATE OR ALTER PROCEDURE [dbo].[spRemoveInapplicablePqrs]
	@ChartId INT
WITH EXEC AS CALLER
AS
BEGIN
	DECLARE @chart_id INT=@ChartId;

	DECLARE @RequiredMeasures TABLE
	(
	   [CMS_PQRI_MEASURE_ID] INT
	  ,[MEASURE_TITLE] VARCHAR(2000)		-- DACS-3591, pippin -- increased column width to 2000 (original = 500)
	  ,[CMS_PQRI_MEASURE_CODE_ID] INT
	  ,[CODING_SYSTEM] VARCHAR(20)
	  ,[OPTION_GROUP] NUMERIC(18,0)
	  ,[CODE] VARCHAR(20)
	  ,[MODIFIER] VARCHAR(20)
	  ,[DESCRIPTION] VARCHAR(500)
	  ,[END_DATE] DATE
	  ,[CODE_2] VARCHAR(6)
	  ,[MODIFIER_2] VARCHAR(20)
	  ,[ROW_NUMBER] BIGINT
	)
	------------------------------------------------------------------------------------
	-- DACS-3591, pippin -- formatting adjusted for improved readibility
	------------------------------------------------------------------------------------

	-- Populate the table variable with values returned from spSelectChartPQRS
	INSERT INTO @RequiredMeasures(
		 [CMS_PQRI_MEASURE_ID]
		,[MEASURE_TITLE]
		,[CMS_PQRI_MEASURE_CODE_ID]
		,[CODING_SYSTEM]
		,[OPTION_GROUP]
		,[CODE]
		,[MODIFIER]
		,[DESCRIPTION]
		,[END_DATE]
		,[CODE_2]
		,[MODIFIER_2]
		,[ROW_NUMBER]
		)
	  EXEC [spSelectChartPQRS] @ChartId=@chart_id

	-- Delete the PQRS items from PHYSICIAN_PROCEDURE_EVALUATION that are inapplicable to this chart
	DELETE 
		[PHYSICIAN_PROCEDURE_EVALUATION]
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID]=ppe.[PHYSICIAN_PROCEDURE_ID]
	WHERE 
		[CHART_ID]=@chart_id
		AND cm.[CHARGE_MASTER_USAGE_CODE]=9
		AND cm.[CPT_CODE] NOT IN (
			SELECT 
				cpmc.[CODE] 
			FROM 
				@RequiredMeasures rm
				JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID]=rm.[CMS_PQRI_MEASURE_ID]
			WHERE 
				cpmc.[CODING_SYSTEM] IN ('CPT_II', 'HCPCS')
				AND cpmc.[CODE]=cm.[CPT_CODE]
				AND ppe.[MODIFIERS] LIKE ISNULL('%' + cpmc.[MODIFIER] + '%', '')
			)
		AND cm.[CPT_CODE] NOT IN (
			SELECT 
				cpmc.[CODE_2] 
			FROM 
				@RequiredMeasures rm
				JOIN [CMS_PQRI_MEASURE_CODE] cpmc on cpmc.[CMS_PQRI_MEASURE_ID]=rm.[CMS_PQRI_MEASURE_ID]
			WHERE 
				cpmc.[CODING_SYSTEM] IN ('CPT_II', 'HCPCS')
				AND cpmc.[CODE_2]=cm.[CPT_CODE]
				AND ppe.[MODIFIERS] LIKE ISNULL('%' + cpmc.[MODIFIER] + '%', '')
			)
END; -- end SPROC
GO


