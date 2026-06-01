SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	----------------
	-- alter stored procedure
	----------------
CREATE   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @ChartId', 'Code' = 'ERR-1';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
	
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	----------------
	-- Measure info
	----------------
	DECLARE @tempMeasureInfo tMipsMeasureInfo;
	INSERT INTO @tempMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@PqrsNum,@Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempMeasureInfo; -- testing

	DECLARE @MeasureId INT = (SELECT TOP 1 [MeasureId] FROM @tempMeasureInfo);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'bad @MeasureId', 'Code' = 'ERR-1';
		RETURN;
	END;
	
	IF NOT EXISTS (SELECT 1 FROM @tempMeasureInfo WHERE [Req2DxOr3Cpt] = 1)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;


	----------------
	-- Chart info
	----------------
	DECLARE @tempChartInfo tMipsChartMinimumInfo;
	INSERT INTO @tempChartInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempChartInfo; -- testing

	IF NOT EXISTS (SELECT 1 FROM @tempChartInfo)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FromAge] from @tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [ToAge] from @tempMeasureInfo);

	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PatientAge] from @tempChartInfo);
		DECLARE @timeOfService DATETIME = (SELECT TOP 1 [TimeOfService] from @tempChartInfo);

		IF @timeOfService IS NULL
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid time of service to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		IF @patientAge IS NULL OR @patientAge < 0
			SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge, @timeOfService, (SELECT TOP 1 [PatientDob] from @tempChartInfo));

		IF @patientAge IS NULL OR @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient Age to test', 'Code' = 'ERR-2';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @tempProcedureList t2xString32;
	INSERT INTO @tempProcedureList SELECT * FROM dbo.udfMIPSSelectPresentProcedureCodesByChartId(@ChartId,@chartSAId);
	IF @ShowDebug <> 0 SELECT * FROM @tempProcedureList; -- testing	


	----------------
	-- Present Diagnosis List 
	----------------
	DECLARE @tempDiagnosisList tIntString32;
	INSERT INTO @tempDiagnosisList SELECT * FROM dbo.udfMIPSSelectPresentDiagnosticCodesByChartId(@ChartId);
	IF @ShowDebug <> 0 SELECT * FROM @tempDiagnosisList; -- testing


	----------------
	-- Verify that we have data
	----------------
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList) OR NOT EXISTS (SELECT 1 FROM @tempDiagnosisList)
	BEGIN
		SELECT 'Result' = 0, 'Message' = '@ChartId is missing Procedure Codes or Diagnosis Codes ', 'Code' = 'ERR-0-MPD';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	DECLARE @tempDenominatorList tDenominatorInfo;
	INSERT INTO @tempDenominatorList SELECT * FROM dbo.udfMipsSelectQuestionDenominatorData(@MeasureId, @Dos);

	IF @ShowDebug <> 0 SELECT * FROM @tempDenominatorList; -- testing
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis (ICD-10-CM) listing?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

END -- end procedure

GO
