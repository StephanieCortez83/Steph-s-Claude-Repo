SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_TypeACEP64] 
	  @ChartId INT
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of ACEP64, there is 1 valid decision path.  This script is designed around this example.
	-- checks chart age within range of 18 years or older
	-- checks that the chart patient class is Emergency department (ED) = "Place of Service: 23"
	-- requires one CPT code within the DG1P1 GROUP 
	-- requires one ICD10 code within the DG1P2 GROUP 
	
	-- Only return 1 result value (1 "one") to speed up the process
	
	-- returns 1 on Satisfaction of Rule - Now needs ACS human selection of Performance status
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors, or not an ED patient class
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
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	 
	----------------
	-- check for age CONSTRAINTS ex Patients aged 0 to < 18 years on date of encounter.  these will be used for defaults but overridable by database settings due to customer wants.
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
	----------------
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
	
	IF dbo.udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService(@chartPatientClassId,@chartSAId,'1','23') <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId does NOT have a Physician service class of (1) or Location of Service value of (23)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
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
	-- do we have Patient had a diagnosis of DVT (ICD10)?
	IF NOT EXISTS (SELECT 1 FROM @tempDiagnosisList WHERE [Value] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P2'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient had a diagnosis of DVT (ICD10))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)?
	IF NOT EXISTS (SELECT 1 FROM @tempProcedureList WHERE [Value1] IN (SELECT [Code] FROM @tempDenominatorList WHERE [CodingSystem] = 'DG1P1'))
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met. :', 'Code' = '????';

END -- end procedure

GO
