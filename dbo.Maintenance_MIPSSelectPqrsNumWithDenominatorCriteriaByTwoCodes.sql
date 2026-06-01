SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_MIPSSelectPqrsNumWithDenominatorCriteriaByTwoCodes] 
	 @Code VARCHAR(20)
	,@Code2 VARCHAR(20)
WITH EXEC AS CALLER AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @Code IS NULL OR LEN(RTRIM(@Code)) <= 0
		RETURN;
		
	IF @Code2 IS NULL OR LEN(RTRIM(@Code2)) <= 0
		RETURN;

	SET @Code = RTRIM(@Code);	
	
	DECLARE @T TABLE (MipsId INT, Mips VARCHAR(20), MipsType VARCHAR(20))
	INSERT INTO @T EXEC [dbo].[Maintenance_MIPSSelectPqrsNumWithDenominatorCriteriaByCode] @Code = @Code;
	--SELECT * FROM @T -- testing

	IF NOT EXISTS(SELECT TOP 1 1 FROM @T)
		RETURN;

	SET @Code2 = RTRIM(@Code2);	

	SELECT DISTINCT  
		 cpm.[CMS_PQRI_MEASURE_ID] AS [MipsId]
		,[PQRS#] AS [Mips]
		,IIF([CODING_SYSTEM] IN ('C4','I10'), 'Old', '2024') AS [MipsType]
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc 
		JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE 
		cpmc.[CODE] = @Code2
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','C4','I10')
		AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] <= GETDATE())
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
		AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] >= GETDATE())
		AND cpm.[CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @T)
	ORDER BY 
		[PQRS#];
		
/*
EXEC [dbo].[Maintenance_MIPSSelectPqrsNumWithDenominatorCriteriaByTwoCodes] @Code = 'I50.89', @Code2 = '99238';
EXEC [dbo].[Maintenance_MIPSSelectPqrsNumWithDenominatorCriteriaByTwoCodes] @Code = '99238', @Code2 = 'I10';
*/		

END; -- end of SPROC

GO
