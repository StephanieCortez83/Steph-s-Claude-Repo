SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[AreAnySavesPhysicianProcedureEvalCodesUsedForMipsByChartIdAndPqrsCode]   
	 @ChartId INT
	,@PqrsCode VARCHAR(20)
	,@ShowDebug BIT = 0
AS
BEGIN  
	IF @ChartId IS NULL OR @ChartId <= 0 OR @PqrsCode IS NULL OR LEN(RTRIM(@PqrsCode)) <= 0
		RETURN;
	
	DECLARE @MeasureId INT = dbo.udfMipsSelectMeasureIdFromPqrsCode(@PqrsCode,GETDATE());
	IF @MeasureId IS NULL OR @MeasureId <= 0
		RETURN;
	
	DECLARE @tmpMipsCptList TABLE ([code] VARCHAR(20) NULL);
	
	INSERT INTO 
		@tmpMipsCptList ([CODE])
	SELECT DISTINCT
		[CODE] 
	FROM 
		[CMS_PQRI_MEASURE_CODE] 
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId 
		AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE()) 
		AND ([END_DATE] IS NULL OR [END_DATE] >= GETDATE())
		AND [CODE] IS NOT NULL
		AND [CODING_SYSTEM] IN ('DQ411','HCPCS');
	
	IF @ShowDebug <> 0 SELECT * FROM @tmpMipsCptList; -- testing

	INSERT INTO 
		@tmpMipsCptList ([CODE])
	SELECT DISTINCT
		[CODE_2] AS [CODE]
	FROM 
		[CMS_PQRI_MEASURE_CODE] 
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId 
		AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE()) 
		AND ([END_DATE] IS NULL OR [END_DATE] >= GETDATE())
		AND [CODE_2] IS NOT NULL
		AND [CODING_SYSTEM] IN ('DQ411','HCPCS');

	IF @ShowDebug <> 0 SELECT * FROM @tmpMipsCptList; -- testing

	DECLARE @result INT = 
		(
		SELECT TOP 1 1
			--physician_procedure_id,charge_master_id,CPT_CODE,billing_code,cm.[description] 
		FROM 
			[PHYSICIAN_PROCEDURE_EVALUATION] ppe 
			JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
		WHERE 
			[CHART_ID] = @ChartId 
			--AND [SERVICE_AGREEMENT_ID] =  ??
			AND (cm.[CHARGE_MASTER_USAGE_CODE] = 9)
			AND cm.[CPT_CODE] IN (SELECT DISTINCT [CODE] FROM @tmpMipsCptList)
		);
	
	IF @ShowDebug <> 0 SELECT 'result' = @result; -- testing
	
	RETURN @result;


/*
usage:
EXEC  [dbo].[AreAnySavesPhysicianProcedureEvalCodesUsedForMipsByChartIdAndPqrsCode]	@ChartId=2100118399,@PqrsCode='THEPQR4',@ShowDebug=1
DECLARE @res INT = 0;
EXEC @res = [dbo].[AreAnySavesPhysicianProcedureEvalCodesUsedForMipsByChartIdAndPqrsCode]	@ChartId=2100118399,@PqrsCode='THEPQR4'
SELECT 'res' = @res; -- testing

*/
END -- end SPROC

GO
