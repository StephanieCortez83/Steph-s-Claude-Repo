----------------------------------------
-- 06) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService].SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- drop type 
DROP TYPE IF EXISTS tMipsMeasureInfo;

CREATE TYPE tMipsMeasureInfo AS TABLE
(
	 MeasureId INT
	,MeasureName VARCHAR(32) NULL
	,Gender VARCHAR(32) NULL
	,FromAge INT NULL
	,ToAge INT NULL
	,RequiresEmOnly BIT NULL
	,Req2DxOr3Cpt BIT NULL
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMeasureInformationByMipsNameAndDateOfService]
(
	 @MeasureName VARCHAR(32)
	,@DateOfService DATETIME
)
RETURNS @MeasureInfo TABLE
(
	 MeasureId INT
	,MeasureName VARCHAR(32) NULL
	,Gender VARCHAR(32) NULL
	,FromAge INT NULL
	,ToAge INT NULL
	,RequiresEmOnly BIT NULL
	,Req2DxOr3Cpt BIT NULL
)
WITH EXECUTE AS CALLER
AS
BEGIN

	IF @MeasureName IS NULL OR LEN(@MeasureName) <= 0
		RETURN;

	IF @DateOfService IS NULL
		SET @DateOfService = GETDATE();

	DECLARE @MeasureId INT = [dbo].[udfMipsSelectMeasureIdFromPqrsCode](@MeasureName, @DateOfService);

	IF @MeasureId IS NULL OR @MeasureId <= 0
		RETURN;

	INSERT INTO 
		@MeasureInfo	
	SELECT TOP 1
		 [CMS_PQRI_MEASURE_ID] AS MeasureId
		,[PQRS#] AS MeasureName
		,[GENDER] AS Gender
		,[FROM_AGE] AS FromAge
		,[TO_AGE] AS ToAge
		,[REQUIRES_EM_ONLY] AS RequiresEmOnly
		,[REQ_2_DX_OR_3CPT] AS Req2DxOr3Cpt
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] <= @DateOfService)
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @DateOfService )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;

	RETURN;
END;

GO

/*
-- testing
DECLARE @MipsMeasureInfo tMipsMeasureInfo;
INSERT INTO @MipsMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(148,'08-16-2024');
SELECT * FROM @MipsMeasureInfo
*/


