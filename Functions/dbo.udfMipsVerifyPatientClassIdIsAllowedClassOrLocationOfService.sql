SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   FUNCTION [dbo].[udfMipsVerifyPatientClassIdIsAllowedClassOrLocationOfService]
(
	 @PatientClassId INT
	,@ServiceAgreementId INT
	,@TestForPatientClassCodesCsv VARCHAR(150)		-- DACS-3763 - 20241002 - pippin - updated variable width to 150
	,@TestForLocationOfServiceCsv VARCHAR(150)		-- DACS-3763 - 20241002 - pippin - updated variable width to 150
)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN
	----------------
	-- validate parameters
	----------------
	IF @PatientClassId IS NULL 
		OR @PatientClassId <= 0
		OR @ServiceAgreementId IS NULL 
		OR @ServiceAgreementId <= 0
		RETURN -1;
	
	IF @TestForPatientClassCodesCsv IS NOT NULL AND LEN(LTRIM(RTRIM(@TestForPatientClassCodesCsv))) <= 0
		SET @TestForPatientClassCodesCsv = NULL;
	
	IF @TestForLocationOfServiceCsv IS NOT NULL AND LEN(LTRIM(RTRIM(@TestForLocationOfServiceCsv))) <= 0
		SET @TestForLocationOfServiceCsv = NULL;

	IF @TestForPatientClassCodesCsv IS NULL AND @TestForLocationOfServiceCsv IS NULL
		RETURN -2;
	
	----------------
	-- retrieve code and los from chart where PATIENT_CLASS_ID is specified
	----------------
	DECLARE @PhysicianServiceClassCode VARCHAR(150);		-- DACS-3763 - 20241002 - pippin - updated variable width to 150
	DECLARE @LocationOfService VARCHAR(150);				-- DACS-3763 - 20241002 - pippin - updated variable width to 150

	SELECT TOP 1 
		 @PhysicianServiceClassCode = [PHYSICIAN_SERVICE_CLASS_CD]
		,@LocationOfService = [LOCATION_OF_SERVICE]
	FROM 
		[dbo].[PATIENT_CLASS] WITH (NOLOCK)
	WHERE 
		[PATIENT_CLASS_ID] = @PatientClassId 
		AND [SERVICE_AGREEMENT_ID] = @ServiceAgreementId;
	
	----------------
	-- test patient class code
	----------------
	IF @TestForPatientClassCodesCsv IS NOT NULL AND @PhysicianServiceClassCode IS NOT NULL AND LEN(LTRIM(RTRIM(@PhysicianServiceClassCode))) > 0
	BEGIN
		DECLARE @splitsTestPatientCodes tIntString32;

		INSERT @splitsTestPatientCodes(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@TestForPatientClassCodesCsv, ',');
		
		IF EXISTS (SELECT 1 FROM @splitsTestPatientCodes) AND EXISTS (SELECT 1 FROM @splitsTestPatientCodes WHERE value = @PhysicianServiceClassCode)
			RETURN 1;
	END;

	----------------
	-- test location of service
	----------------
	IF @TestForLocationOfServiceCsv IS NOT NULL AND @LocationOfService IS NOT NULL AND LEN(LTRIM(RTRIM(@LocationOfService))) > 0
	BEGIN
		DECLARE @splitsTestLocationsOfService tIntString32;
		DECLARE @splitsChartLocationsOfService tIntString32;

		INSERT @splitsTestLocationsOfService(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@TestForLocationOfServiceCsv, ',');

		INSERT @splitsChartLocationsOfService(Id,value)
		SELECT 
			 0 AS [Id]
			,RTRIM(LTRIM(value)) AS value
		FROM STRING_SPLIT (@LocationOfService, ',');

		IF EXISTS (SELECT 1 FROM @splitsTestLocationsOfService) 
			AND EXISTS (SELECT 1 FROM @splitsChartLocationsOfService) -- prolly can remove.  just being paranoid about bad chart data
			AND EXISTS (SELECT 1 FROM @splitsChartLocationsOfService WHERE value IN (SELECT DISTINCT value FROM @splitsTestLocationsOfService))
				RETURN 1;
	END;

	RETURN 0;
END;

GO
