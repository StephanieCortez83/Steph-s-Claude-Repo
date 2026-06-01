SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


	--------------------------------
	-- alter stored procedure
	--------------------------------
CREATE   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR7] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = 'THEPQR7'
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of THEPQR4, there are 1 valid decision paths.  the data is stored by PQRS# 'THEPQR4' for example
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
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
		
	
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED



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


	IF @Dos IS NULL
	BEGIN
		SET @Dos = (SELECT TOP 1 [TimeOfService] FROM @tempChartInfo);
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;


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
	-- check PATIENT_CLASS_ID 
	-- not checking location of service for now.  ACS uses patient class instead of LOS which do not always translate perfectly
	-- this could change at anytime though
	----------------
/*
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test', 'Code' = 'ERR-2';
		RETURN;
	END;

	DECLARE @chartPatientClassId INT = (SELECT TOP 1 [PatientClassId] FROM @tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		SELECT 'Result' = -2, 'Message' = '@ChartId does not have a valid patient class id to test', 'Code' = 'ERR-2';
		RETURN;
	END;
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'7,8,9','21') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid [PHYSICIAN_SERVICE_CLASS_CD] IN (7,8,9) OR [LOCATION_OF_SERVICE] IN (21) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
*/	
	
	----------------
	-- Present Procedure List 
	----------------
	DECLARE @chartSAId INT = (SELECT TOP 1 [ServiceAgreementId] FROM @tempChartInfo);
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
	
	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'REQP1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'REQD1')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG1P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'REQD2')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG2P1 records', 'Code' = 'ERR-3';
		RETURN;
	END;

	IF NOT EXISTS (SELECT 1 FROM @tempDenominatorList WHERE [CodingSystem] = 'REQD3')
	BEGIN
		SELECT 'Result' = -3, 'Message' = 'Missing Denominator DG2P2 records', 'Code' = 'ERR-3';
		RETURN;
	END;


	----------------
	-- Collect our test decision points ---->
	----------------
	
	-- do we have  Patient encounter during the performance period (CPT or HCPCS)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'REQP1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met ( Patient encounter during the performance period (CPT or HCPCS))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis of Minor ischemic stroke (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'REQD1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of Minor ischemic stroke (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis of High-risk TIA (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'REQD2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of High-risk TIA (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Intracranial large artery atherosclerosis (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'REQD3'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Intracranial large artery atherosclerosis (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT * FROM [dbo].[udfReturnMips411Questions](@tempDenominatorList, @MeasureId);

/*
-- usage example:
exec [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR7] 
	  @ChartId = 2100123023
	, @ShowDebug = 1
*/

END -- end procedure

GO
