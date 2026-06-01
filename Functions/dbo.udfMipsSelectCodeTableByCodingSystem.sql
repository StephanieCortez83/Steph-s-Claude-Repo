SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------


CREATE   FUNCTION [dbo].[udfMipsSelectCodeTableByCodingSystem]
(
	 @MeasureId INT
	,@CodingSystem VARCHAR(32) 
)
RETURNS @Codes TABLE
(
     Id INT
	,Value VARCHAR(32)
)
WITH EXECUTE AS CALLER
AS
BEGIN
	INSERT INTO 
		@Codes
	SELECT 
		 [CMS_PQRI_MEASURE_CODE_ID] AS Id
		,[CODE] AS Value
	FROM 
		[dbo].[CMS_PQRI_MEASURE_CODE]
	WHERE
		[CMS_PQRI_MEASURE_ID] = @measureId
		AND [CODING_SYSTEM] = @CodingSystem
		AND ([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] >= GETDATE())
	;		

	RETURN;
END;

GO
