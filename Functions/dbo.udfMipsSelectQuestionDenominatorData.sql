SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
-- testing
EXEC spMipsSelectQuestionDenominatorData @MeasureId=200;
*/

/*
CREATE TYPE tDenominatorInfo AS TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
) --WITH ( MEMORY_OPTIMIZED = ON )
*/

---------------------------------------------------------------------------------------
--  Now Create a function version of the above SPROC
---------------------------------------------------------------------------------------
CREATE   FUNCTION [dbo].[udfMipsSelectQuestionDenominatorData]
(
	 @MeasureId INT
	,@DateOfService DATETIME
)
RETURNS @returnResults TABLE
(
	 [Code] VARCHAR(32) NULL
	,[CodingSystem] VARCHAR(32) NULL
	,[Description] VARCHAR(500) NULL
	,[Modifier] VARCHAR(64) NULL
)
AS
BEGIN
	----------------
	-- parameter validation		-- if speed is an issue, these can be removed.
	----------------
	IF @DateOfService IS NULL
		SET @DateOfService = GETDATE();

	IF @MeasureId IS NOT NULL AND @MeasureId > 0
	BEGIN 
		----------------
		-- return some data
		----------------
		INSERT INTO 
			@returnResults
		SELECT 
			 [CODE]
			,[CODING_SYSTEM]
			,[DESCRIPTION]
			,[MODIFIER]
		FROM 
			[CMS_PQRI_MEASURE_CODE] cpmc
			INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
		WHERE
			cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND cpmc.[START_DATE] <= @DateOfService
			AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @DateOfService)
			AND (cpm.[EFFECTIVE_DATE] IS NULL OR cpm.[EFFECTIVE_DATE] <= @DateOfService)
			AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @DateOfService)
			AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
			AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','DQ411','EXCLUDE'
				,'REQP1','REQP2','REQP3','REQD1','REQD2','REQD3') -- adds new entries for MIPS 2025 processing - DACS-4140 - pippin - 20250103
		ORDER BY 	-- if speed is an issue we can likely remove the order by clause
			cpmc.CMS_PQRI_MEASURE_CODE_ID; 
	END;	

	RETURN;
 END; -- end function

GO
