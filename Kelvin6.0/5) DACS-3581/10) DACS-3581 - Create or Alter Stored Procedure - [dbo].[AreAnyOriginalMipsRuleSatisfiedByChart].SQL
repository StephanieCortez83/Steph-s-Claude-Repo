------------------------------------------------------------------------------------
-- 10) DACS-3581 - Create or Alter Stored Procedure - [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] 
	 @ChartId INT
	,@ShowDebug BIT = 0
	,@TestAll BIT = 0
WITH EXEC AS CALLER AS
BEGIN

	IF @ChartId IS NULL OR @ChartId <= 0 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad ChartId ' = @ChartId;
		RETURN;
	END;
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Chart info
	----------------
	DECLARE @MipsChartMinimumInfo tMipsChartMinimumInfo;
	/*
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId
	,UseTelehealth BIT NULL
	*/
	INSERT INTO @MipsChartMinimumInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(@ChartId);
	IF @ShowDebug = 1 SELECT * FROM @MipsChartMinimumInfo
	
	IF NOT EXISTS (SELECT 1 FROM @MipsChartMinimumInfo)
	BEGIN 
		IF @ShowDebug = 1 SELECT 'Returned chart count is empty for ' = @ChartId;
		RETURN;
	END;

	DECLARE @chartServiceAgreementId INT;
	DECLARE @chartDateOfService DATETIME;
	DECLARE @chartGender VARCHAR(32) ;
	DECLARE @chartPatientDob DATETIME;
	DECLARE @chartPatientAge INT;
	DECLARE @chartPatientClassId INT;
	DECLARE @chartUseTelehealth BIT;
	
	SELECT TOP 1
		 @chartServiceAgreementId = [ServiceAgreementId]
		,@chartDateOfService = [TimeOfService] 
		,@chartGender = [Gender] 
		,@chartPatientDob = [PatientDob] 
		,@chartPatientAge = [PatientAge] 
		,@chartPatientClassId = [PatientClassId] 
		,@chartUseTelehealth = [UseTelehealth] 
	FROM 
		@MipsChartMinimumInfo;

	PRINT('chartserviceAgreementId = ' + CAST(@chartServiceAgreementId AS VARCHAR(64)));
	PRINT('chartdateOfService = ' + CAST(@chartDateOfService AS VARCHAR(64)));
	PRINT('chartgender = ' + CAST(@chartGender AS VARCHAR(64)));
	PRINT('chartpatientDob = ' + CAST(@chartPatientDob AS VARCHAR(64)));
	PRINT('chartpatientAge = ' + CAST(@chartPatientAge AS VARCHAR(64)));
	PRINT('chartPatientClassId = ' + CAST(@chartPatientClassId AS VARCHAR(64)));
	PRINT('chartUseTelehealth = ' + CAST(@chartUseTelehealth AS VARCHAR(64)));

	IF @chartServiceAgreementId IS NULL OR @chartServiceAgreementId <= 0 OR @chartDateOfService IS NULL 
	BEGIN
		IF @ShowDebug = 1 SELECT 'Bad data returned for chart ' = @ChartId;
		RETURN;
	END;


	---------------------------------
	-- get procedure codes for this chart
	---------------------------------
	DECLARE @TempFoundProcedureCodes t2xString32;
	INSERT INTO 
		@TempFoundProcedureCodes ( 
			 [Value1]
			,[Value2] 
		)
		SELECT * FROM [dbo].[udfMIPSSelectPresentProcedureCodesByChartId](@ChartId, @chartServiceAgreementId);
	
	IF NOT EXISTS (SELECT 1 FROM @TempFoundProcedureCodes)
	BEGIN
		-- if no procedure codes, then no MIPS will be satisfied
		IF @ShowDebug = 1 SELECT 'No procedure codes found for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT * FROM @TempFoundProcedureCodes;

	---------------------------------
	-- get diagnostic codes for this chart
	---------------------------------
	DECLARE @TempFoundDiagnosticCodes tIntString32;
	INSERT INTO 
		@TempFoundDiagnosticCodes ( 
			 [Id]
			,[Value] 
		)
		SELECT * FROM [dbo].[udfMIPSSelectPresentDiagnosticCodesByChartId](@ChartId);
	
	IF @ShowDebug = 1 SELECT * FROM @TempFoundDiagnosticCodes;

	-----------------------------------
	-- get a list of MIPS to process
	-----------------------------------
	DECLARE @activeSAMipsRulesTable TABLE ( [NAME] VARCHAR(32) );
	
	INSERT INTO 
		@activeSAMipsRulesTable
	EXEC [dbo].[SelectActiveServiceAgreementMipsBySaidAndDos] @SaId=@chartServiceAgreementId, @Dos=@chartDateOfService

	DECLARE @countSaMips INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF NOT EXISTS (SELECT 1 FROM @activeSAMipsRulesTable)
	BEGIN
		IF @ShowDebug = 1 SELECT 'No SA Mips for chart ' = @ChartId;
		RETURN;
	END;
	
	-----------------------------------
	-- remove the MIPS 2024 entries from the list since they are checked by anothe SPROC of a similar name separately
	-----------------------------------
	DECLARE @active2024MipsRulesTable TABLE ( [name] VARCHAR(32) );
	
	INSERT INTO 
		@active2024MipsRulesTable ([NAME]) 
	VALUES 
		 ('THEPQR4')
		,('THEPQR3')
		,('THEPQR2')
		,('THEPQR1')
		,('HCPR27')
		,('ECPR39')
		,('ECPR46')
		,('ECPR51')
		,('187')
		,('116')
		,('134')
		,('066')
		,('416')
		,('415')
		,('332')
		,('326')
		,('001')
		,('047')
		,('007-A')
		,('007-B')
		,('118-A')
		,('118-B')
		,('005-A')
		,('005-B')
		,('008-A')
		,('008-B')
		,('PQRANES1')
		,('ACEP60')
		,('HCPR24')
		,('ACEP61')
		,('ACEP64')
	;
	
	DELETE FROM @activeSAMipsRulesTable WHERE [NAME] IN (SELECT [NAME] FROM @active2024MipsRulesTable);

	DECLARE @TotalToProcessCount INT = (SELECT COUNT(*) FROM @activeSAMipsRulesTable);
	IF @TotalToProcessCount <= 0
	BEGIN
		IF @ShowDebug = 1 SELECT 'No Original Mips for chart ' = @ChartId;
		RETURN;
	END;

	IF @ShowDebug = 1 SELECT '@TotalToProcessCount = ' = @TotalToProcessCount;
	IF @ShowDebug = 1 SELECT * FROM @activeSAMipsRulesTable;

	----------------
	-- setup fetch loop to process each batch id in the list
	----------------
	DECLARE @ProcessCount INT = 1;

	DECLARE @FetchMeasureId INT;
	DECLARE @FetchMipsName VARCHAR(32);
	DECLARE @FetchGender VARCHAR(32);
	DECLARE @FetchFromAgeYears INT;
	DECLARE @FetchToAgeYears INT;
	DECLARE @FetchRequiresEmOnly BIT;
	
	DECLARE @FetchMipsMeasureInfo tMipsMeasureInfo;
	DECLARE @FetchMipsDiagCodes tIntString32;
	DECLARE @FetchMipsProcCodes tIntString32;
	
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT DISTINCT [NAME] FROM @activeSAMipsRulesTable;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): MIPS Name ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName)
			);
	
		IF @FetchMipsName IS NULL OR LEN(LTRIM(RTRIM(@FetchMipsName))) <= 0
		BEGIN
			PRINT('  --> FetchMipsName is invalid ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName));
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;
		
		SET @FetchMeasureId = -1;
		DELETE FROM @FetchMipsMeasureInfo;
		DELETE FROM @FetchMipsDiagCodes;
		DELETE FROM @FetchMipsProcCodes;

		----------------
		-- Measure info
		----------------
		INSERT INTO @FetchMipsMeasureInfo SELECT * FROM dbo.udfMipsSelectMeasureInformationByMipsNameAndDateOfService(@FetchMipsName, @ChartDateOfService);
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsMeasureInfo

		----------------
		-- none of the original (pre 2024) MIPS will have [Req2DxOr3Cpt] set to a 1.
		----------------
		SET @FetchMeasureId = (SELECT TOP 1 [MeasureId] FROM @FetchMipsMeasureInfo WHERE ([Req2DxOr3Cpt] IS NULL OR [Req2DxOr3Cpt] = 0));
			
		IF @FetchMeasureId IS NULL OR @FetchMeasureId <= 0
		BEGIN 
			PRINT('  --> FetchMeasureId failed [Req2DxOr3Cpt] check for ' + IIF(@FetchMipsName IS NULL, 'NULL', @FetchMipsName));
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;

		SELECT TOP 1
			 @FetchMipsName = [MeasureName]
			,@FetchGender = [Gender] 
			,@FetchFromAgeYears = [FromAge] 
			,@FetchToAgeYears = [ToAge] 
			,@FetchRequiresEmOnly = [RequiresEmOnly] 
		FROM 
			@FetchMipsMeasureInfo;
			
		PRINT(' --> FetchMeasureId = ' + CAST(@FetchMeasureId AS VARCHAR(64)));
		PRINT(' --> FetchMipsName = ' + CAST(@FetchMipsName AS VARCHAR(64)));
		PRINT(' --> FetchGender = ' + CAST(@FetchGender AS VARCHAR(64)));
		PRINT(' --> FetchFromAgeYears = ' + CAST(@FetchFromAgeYears AS VARCHAR(64)));
		PRINT(' --> FetchToAgeYears = ' + CAST(@FetchToAgeYears AS VARCHAR(64)));
		PRINT(' --> FetchRequiresEmOnly = ' + CAST(@FetchRequiresEmOnly AS VARCHAR(64)));

		/*  -- does not work quite right.  might need to use the pat class id and or the location of service fields instead
		IF @FetchRequiresEmOnly = 1 
			AND EXISTS (SELECT 1 FROM @TempFoundProcedureCodes WHERE [Value1] IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395'))
		BEGIN 
			-- to maintain compatibility, the original MIPS only check the following if the field is SET
			-- may update later to check the PATIENT_CLASS_ID or LOCATION_OF_SERVICE instead, but for compatibility leave as is.
			IF @TestAll <> 1
			BEGIN
				SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
				-- cleanup our cursor
				CLOSE cursorTempRows;  
				DEALLOCATE cursorTempRows;
				RETURN 1;
			END
			ELSE
				PRINT('!!!! Satisfied MIPS (EM Only test) = ' + CAST(@FetchMipsName AS VARCHAR(64)));
		END;
		*/
		
		----------------
		-- check Gender = gender: U,X,F,M
		----------------
		IF @FetchGender IS NOT NULL 
			AND @FetchGender <> 'B' 
			AND (
					@ChartGender IS NULL
					OR (@ChartGender IS NOT NULL AND @ChartGender IN ('M','F') AND (@ChartGender <> @FetchGender))	
				)
		BEGIN
			PRINT(' --> Gender check failed for ' + @FetchMipsName + '[' + IIF(@FetchGender IS NULL, 'NULL', @FetchGender) + ':' + IIF(@ChartGender IS NULL, 'NULL', @ChartGender) + ']');
			SET @ProcessCount = @ProcessCount + 1;
			FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
			CONTINUE;
		END;
		
		----------------
		-- check age
		----------------
		IF @FetchFromAgeYears IS NOT NULL OR @FetchToAgeYears IS NOT NULL
		BEGIN
			IF @chartDateOfService IS NULL
			BEGIN 
				PRINT(' --> chartDateOfService is invalid for age test.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;

			IF @chartPatientAge IS NULL OR @chartPatientAge < 0
				SET @chartpatientAge = dbo.fGetPatientAgeInYears(@chartpatientAge, @chartDateOfService, @chartPatientDob);

			IF @chartPatientAge IS NULL OR @chartPatientAge < 0 OR @chartPatientAge > 999
			BEGIN 
				PRINT(' --> chartPatientAge is invalid for age test.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;

			-- check the age constraints
			IF @FetchFromAgeYears IS NULL SET @FetchFromAgeYears = 0;
			IF @FetchToAgeYears IS NULL SET @FetchToAgeYears = 999;
			
			IF @chartPatientAge < @FetchFromAgeYears OR @chartPatientAge > @FetchToAgeYears
			BEGIN 
				PRINT(' --> chartPatientAge does not fall within the valid MIPS range.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;	

	
		----------------
		-- get the C4 data
		----------------
		INSERT INTO @FetchMipsProcCodes SELECT * FROM [dbo].[udfMipsSelectCodeTableByCodingSystem](@FetchMeasureId,'C4');
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsProcCodes;

		IF EXISTS (SELECT 1 FROM @FetchMipsProcCodes)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM @TempFoundProcedureCodes WHERE [Value1] IN (SELECT [Value] FROM @FetchMipsProcCodes))
			BEGIN
				PRINT(' --> No Procedure Codes are within C4 test list.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;


		----------------
		-- get the I10 data
		----------------
		INSERT INTO @FetchMipsDiagCodes SELECT * FROM [dbo].[udfMipsSelectCodeTableByCodingSystem](@FetchMeasureId,'I10');
		IF @ShowDebug = 1 SELECT * FROM @FetchMipsDiagCodes;

		IF EXISTS (SELECT 1 FROM @FetchMipsDiagCodes)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM @TempFoundDiagnosticCodes WHERE [Value] IN (SELECT [Value] FROM @FetchMipsDiagCodes))
			BEGIN
				PRINT(' --> No Diagnostic Codes are within I10 test list.');
				SET @ProcessCount = @ProcessCount + 1;
				FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
				CONTINUE;
			END;
		END;


		----------------
		-- MIPS passes if we make it all the way here
		----------------
		PRINT('!!!! MIPS [' + @FetchMipsName + '] Satisfied for Cid: ' + CAST(@ChartId AS VARCHAR(32)));

		IF @TestAll <> 1
		BEGIN
			SELECT 'RESULT' = CAST(1 AS BIT), 'MIPS#' = @FetchMipsName, 'Cid' = @ChartId;
			-- cleanup our cursor
			CLOSE cursorTempRows;  
			DEALLOCATE cursorTempRows;
			RETURN 1;
		END;

		PRINT('-------------------');		
		
		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchMipsName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 
	
	IF @ShowDebug = 1 AND @TestAll <> 1 SELECT 'NO Original Mips satisfied for chart ' = @ChartId;

END; -- end of SPROC

GO

/*
testing:
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=121366953,@ShowDebug=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=121366953;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=122615466,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=122615466,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100113749,@ShowDebug=1,@TestAll=1;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100113749,@TestAll=1;

select top 20 * from chart order by chart_id desc;
EXEC [dbo].[AreAnyOriginalMipsRuleSatisfiedByChart] @ChartId=2100114071;

*/