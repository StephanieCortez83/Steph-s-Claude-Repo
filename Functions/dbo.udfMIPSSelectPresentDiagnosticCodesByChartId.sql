SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   FUNCTION [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId]
(
	  @ChartId INT
)
RETURNS @returnResults TABLE
(
	 Id INT
	,Value VARCHAR(32)
)
AS
BEGIN
	----------------
	-- Present Diagnosis List 
	----------------
	INSERT INTO
		@returnResults
	SELECT 
		 [CHART_DIAGNOSIS_CODE_ICD10_ID] AS Id
		,[ICD10_CODE] AS Value
	FROM 
		[dbo].[CHART_DIAGNOSIS_CODE_ICD10]
	WHERE 
		[CHART_ID] = @ChartId

	RETURN;
 END; -- end function

GO
