------------------------------------------------------------------------------------
-- 06) DACS-3593 - Create or Alter stored procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER   PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListById] 
	 @MeasureId INT
	,@Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		--PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));	-- DACS-3417, 08/19/2024 (pippin)
	END;

	DECLARE @dateOfService DATE = CAST(@Dos AS DATE);			-- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 cpm.[CMS_PQRI_MEASURE_ID]
		,cpm.[MEASURE_TITLE]
		,cpmc.[CMS_PQRI_MEASURE_CODE_ID]
		,cpmc.[CODING_SYSTEM]
		,cpmc.[OPTION_GROUP]
		,cpmc.[CODE]
		,cpmc.[MODIFIER]
		,cpmc.[DESCRIPTION]
		,
		CASE 
			WHEN cpmc.[END_DATE] IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.[END_DATE] 
			END [END_DATE]
		,cpmc.[CODE_2]
		,cpmc.[MODIFIER_2]
		,cpm.[MEASURE_TOOLTIP]				-- DACS-3417, 08/19/2024 (pippin)
		,cpm.[MEASURE_HOTSHEET_URI]			-- DACS-3417, 08/19/2024 (pippin)
		,NULL [ROW_NUMBER]
	FROM 
		[CMS_PQRI_MEASURE] cpm
		LEFT JOIN [CMS_PQRI_MEASURE_CODE] cpmc ON cpmc.[CMS_PQRI_MEASURE_ID] = cpm.[CMS_PQRI_MEASURE_ID]
	WHERE 
		--DATEADD(DAY, DATEDIFF(DAY, 0, @dateOfService), 0) BETWEEN cpm.[EFFECTIVE_DATE] AND ISNULL(cpm.[EXPIRATION_DATE], @dateOfService) -- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types
		(cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] <= @dateOfService)
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @dateOfService) 
		AND cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[CODING_SYSTEM] IN ('CPT_II','HCPCS')
	ORDER BY 
		cpmc.[CODE], cpmc.[MODIFIER]
	;

END -- end procedure

GO


