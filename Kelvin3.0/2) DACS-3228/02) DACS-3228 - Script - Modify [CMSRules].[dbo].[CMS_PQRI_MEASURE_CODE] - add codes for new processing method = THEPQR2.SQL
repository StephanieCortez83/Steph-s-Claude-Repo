------------------------------------------------------------------------------------
-- 02) DACS-3228 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR2.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR2';
	DECLARE @Dos DATETIME = '01-01-2024';

	DECLARE @MeasureId INT = 
		(
			SELECT [CMS_PQRI_MEASURE_ID]
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('No Measure loaded for [' + @PqrsCd + '].  Cannot continue.');
		SELECT 'Error' = -1;
		RETURN;
	END;

	PRINT('@MeasureId = ' + CAST(@MeasureId AS VARCHAR(30)));

	DECLARE @countPQRSCodes INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodes' = @countPQRSCodes; -- testing


	IF @countPQRSCodes > 0
	BEGIN 
		PRINT('Found Measure Codes.  Expiring existing.');
	
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [END_DATE] = DATEADD(minute,-1,CAST(CAST(@Dos AS DATE) AS DATETIME))
		WHERE
			[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND [START_DATE] <= @Dos
			AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
			AND [CODE] IS NOT NULL
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	END;

	DECLARE @countPQRSCodesAfterExpiration INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- DENOMINATOR EXCLUSION: Patients who have an active diagnosis that meets criteria for long-term utilization of Proton Pump Inhibitors.  CANNOT have any of these
		 (@MeasureId,'DG1P1','B37.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','B37.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','B96.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C16.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','D47.Z1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.Z2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','D47.Z9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E16.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.3',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','E27.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E27.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E31.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I85.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I85.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I85.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I85.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.03',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.114',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.115',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.116',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.117',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.170',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.178',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.841',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.842',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.843',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.848',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K20.91',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K21.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K21.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K21.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.4',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','K22.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.70',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.710',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','K22.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K22.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K25.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K26.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K27.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.61',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.71',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K29.91',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.819',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A13',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A14',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A15',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K31.A29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.29',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','K52.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.831',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.832',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.838',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.839',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K52.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.03',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.04',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K59.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K90.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','K92.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','N18.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Q40.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z85.020',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z85.09',NULL,@Dos,NULL)

		-- denominator/numerator group 2
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		 
		-- measure code numerators
		-- SELECTIONS
		,(@MeasureId,'HCPCS','DG002',NULL,@Dos,'Performance Met: (Inpatient): Proton Pump Inhibitors discontinued by discharge OR (PAC/SNF): Proton Pump Inhibitors discontinued. ')
		,(@MeasureId,'HCPCS','DG003',NULL,@Dos,'Performance Not Met: Proton Pump Inhibitors not discontinued; reason not given. ')
		,(@MeasureId,'HCPCS','DG004',NULL,@Dos,'Denominator Exception: <ul><li>Documented medical reason for exclusion</li><li>Patient refusal</li><li>Eloped or left AMA</li><li>Expired</li><li>Discharged to hospice</li></ul> ')
		,(@MeasureId,'HCPCS','QR201',NULL,@Dos,'Denominator Exception: Documentation indicating patient has an active diagnosis or a history of diagnosis that meets criteria for long-term utilization of Proton Pump Inhibitors. (PQR201) <p><img src="/WebPages/Images/MIPS/MIPS_THEPQR2_PQR201_DenominatorExclustionTable.png" alt="(PQR201) Exception table image"></p> ')
				
		-- PQRS Question for response by coder within ACS		
		-- QUESTIONS		
		,(@MeasureId,'DQ411','DG847',NULL,@Dos,'Was a Proton Pump Inhibitor (PPI) Medication DG847 used? <ul><li>Omeprazole (Prilosec, Prilosec OTC, Zegerid)</li><li>Lansoprazole (Prevacid)</li><li>Pantoprazole (Protonix)</li><li>Rebeprazole (Aciphex)</li><li>Esomeprazole (Nexium)</li><li>Dexlansoprazole (Dexilant, Kapidex)</li></ul>')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 225 total inserts
		
		
	DECLARE @countPQRSCodesFinal INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesFinal' = @countPQRSCodesFinal;

	-- testing:
	SELECT 
		*
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR2' -- = 219
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 219
*/