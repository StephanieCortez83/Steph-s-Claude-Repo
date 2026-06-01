----------------------------------------
-- 03) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureIdFromPqrsCode].SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMeasureIdFromPqrsCode]
(
	 @PqrsCode VARCHAR(32) 
	,@Dos DATETIME
)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN

	IF @PqrsCode IS NOT NULL AND LEN(LTRIM(RTRIM(@PqrsCode))) > 0
	BEGIN
		DECLARE @testPqrs INT = (
			SELECT TOP 1 
				[CMS_PQRI_MEASURE_ID] 
			FROM 
				[dbo].[CMS_PQRI_MEASURE] 
			WHERE 
				[PQRS#] = @PqrsCode 
				AND [EFFECTIVE_DATE] <= @Dos 
				AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) 
		);

		IF @testPqrs IS NOT NULL AND @testPqrs > 0
			RETURN @testPqrs;
	END;
	
	RETURN -1;
END;

GO

/*
-- testing
DECLARE @MipsId INT = dbo.udfMipsSelectMeasureIdFromPqrsCode('005-A','08-01-2024');
SELECT '@MipsId' = @MipsId
*/
