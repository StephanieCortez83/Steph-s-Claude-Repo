----------------------------------------
-- 02) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectCodeTableByCodingSystem].SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- drop type 
DROP TYPE IF EXISTS tIntString32;

CREATE TYPE tIntString32 AS TABLE
(
	 Id INT
	,Value VARCHAR(32)
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectCodeTableByCodingSystem]
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

/*
-- testing
DECLARE @MipsCodes tIntString32;
INSERT INTO @MipsCodes SELECT * FROM dbo.udfMipsSelectCodeTableByCodingSystem(148,'C4');
SELECT * FROM @MipsCodes
*/
