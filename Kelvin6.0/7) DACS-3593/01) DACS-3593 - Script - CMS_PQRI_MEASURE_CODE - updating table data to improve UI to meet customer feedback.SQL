------------------------------------------------------------------------------------
-- 01) DACS-3593 - Script - CMS_PQRI_MEASURE_CODE - updating table data to improve UI to meet customer feedback.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO
-- begin tran; -- testing
	----------------
	/*
	reference document "MIPS 8.13.docx" within DACS-3361 Jira ticket for more details

	todo list: (* = handled in this Script)
	*005-A
	*005-B
	*007-A
	*007-B -- updated to show a question if cptcodes not found to satisfy miocarditus criteria (behaves as mipps 332 now)
	*332
	*ACEP60
	*ACEP61
	*ACEP64
	*ECPR39
	*ECPR51
	*HCPR27
	*PQRANES1
	*THEPQR1
	*THEPQR2
	*THEPQR4
	*HCPR24 - converting to single critera MIPS returning a question.
	*047 - updated to use the new fields that allow a definition to be placed below the MIPS.
	*134 - updated to replace question with denominator exclusion response entry
	*326 - converts questions to denominator exclusions
	415 - no changes made.  BUT, looks like it might need definitions added to follow the MIPS section
	*ECPR46 - updated to move the appendix image to bottom of MIPS
	*116 - changed questions to exclusions.  one exclusion has a lot of words (more than 500). uses an image that does not look quite right.  will have to wait for branch merge for image update.
	
	
	
	*/
	----------------
	
	--------------------------------------------
	-- Backup our data to be worked upon
	--------------------------------------------
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3593';
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3593';
	

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @measureId INT;
	DECLARE @measureName VARCHAR(32);
	
	DECLARE @foundRecordId INT;
	DECLARE @oldString VARCHAR(1000);
    DECLARE @newString VARCHAR(1000);

	----------------
	-- THEPQR1  : remove the "not"
	----------------
	SET @measureName = 'THEPQR1';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
		SET @oldString = 'Patient does <strong>NOT</strong> have any of';
		SET @newString = 'Patient does not have any of';

		SET @foundRecordId = (
			SELECT TOP 1
				[CMS_PQRI_MEASURE_CODE_ID] 
			FROM 
				[CMS_PQRI_MEASURE_CODE] 
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] LIKE (@oldString + '%')
			) ;

		SELECT '@foundRecordId =' = @foundRecordId;
		SELECT 'Old description =' = (SELECT [DESCRIPTION] FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_CODE_ID] = @foundrecordId) 

		IF @foundRecordId > 0
			UPDATE [CMS_PQRI_MEASURE_CODE]
				SET [DESCRIPTION] = REPLACE([DESCRIPTION], @oldString, @newString)
			WHERE
				[CMS_PQRI_MEASURE_CODE_ID] = @foundRecordId;
		ELSE
			SELECT 'Error: unable to find record to update for' + @measureName;
			
		SELECT 'New description =' = (SELECT [DESCRIPTION] FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_CODE_ID] = @foundrecordId) 

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';

	----------------
	-- THEPQR2  : reorder them
	----------------
	SET @measureName = 'THEPQR2';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
		DROP TABLE IF EXISTS #TempTHEPQR2Table;
		
		SELECT 
			*
		INTO 
			#TempTHEPQR2Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempTHEPQR2Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempTHEPQR2Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempTHEPQR2Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','QR201',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation indicating patient has an active diagnosis or a history of diagnosis that meets criteria for long-term utilization of Proton Pump Inhibitors. (PQR201) <p><img src="/WebPages/Images/MIPS/MIPS_THEPQR2_PQR201_DenominatorExclustionTable.png" alt="(PQR201) Exception table image"></p> ')
				,(@measureId,'HCPCS','DG002',NULL,'2024-01-01','Performance Met: (Inpatient): Proton Pump Inhibitors discontinued by discharge OR (PAC/SNF): Proton Pump Inhibitors discontinued. ')
				,(@measureId,'HCPCS','DG003',NULL,'2024-01-01','Performance Not Met: Proton Pump Inhibitors not discontinued; reason not given. ')
				,(@measureId,'HCPCS','DG004',NULL,'2024-01-01','Denominator Exception: <ul><li>Documented medical reason for exclusion</li><li>Patient refusal</li><li>Eloped or left AMA</li><li>Expired</li><li>Discharged to hospice</li></ul> ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG847',NULL,'2024-01-01','Was a Proton Pump Inhibitor (PPI) Medication DG847 used? <ul><li>Omeprazole (Prilosec, Prilosec OTC, Zegerid)</li><li>Lansoprazole (Prevacid)</li><li>Pantoprazole (Protonix)</li><li>Rebeprazole (Aciphex)</li><li>Esomeprazole (Nexium)</li><li>Dexlansoprazole (Dexilant, Kapidex)</li></ul> ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- PQRANES1  : reorder them
	----------------
	SET @measureName = 'PQRANES1';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempPQRANES1Table;
		
		SELECT 
			*
		INTO 
			#TempPQRANES1Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempPQRANES1Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempPQRANES1Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempPQRANES1Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','DG014',NULL,'2024-01-01','Performance Met: Patients for whom a peripheral nerve block is performed in the Emergency Department as evidenced by Presence of CPT Code, OR Documentation that peripheral nerve block was performed (CPT Codes: 64447, 64448, 64450) ')
				,(@measureId,'HCPCS','DG015',NULL,'2024-01-01','Performance Not Met: Peripheral nerve block not performed as evidenced by Absence of CPT Code in Numerator Met AND Absence of Documentation ')
				,(@measureId,'HCPCS','DG016',NULL,'2024-01-01','Denominator Exception: Documented medical reason for exclusion. Example of Medical Exclusions: open fracture, infection at the insertion site, or other medical reason, patient unable to consent. ')
				,(@measureId,'HCPCS','DG017',NULL,'2024-01-01','Denominator Exception: Documented patient refusal. Documentation Example: Patient refused block placement ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 332  : reorder them
	----------------
	SET @measureName = '332';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp332Table;
		
		SELECT 
			*
		INTO 
			#Temp332Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp332Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp332Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp332Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9315',NULL,'2024-01-01','Performance Met: Amoxicillin, with or without clavulanate, prescribed asa first line antibiotic at the time of diagnosis. ')
				,(@measureId,'HCPCS','G9314',NULL,'2024-01-01','Performance Not Met: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis, reason not given. ')
				,(@measureId,'HCPCS','G9313',NULL,'2024-01-01','Denominator Exception: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis for documented reason. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','G9364',NULL,'2024-01-01','Sinusitis caused by, or presumed to be caused by, bacterial infection: G9364? ')
				,(@measureId,'DQ411','G9498',NULL,'2024-01-01','Antibiotic regimen prescribed: G9498? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- HCPR27  : reorder them
	----------------
	SET @measureName = 'HCPR27';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempHCPR27Table;
		
		SELECT 
			*
		INTO 
			#TempHCPR27Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempHCPR27Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempHCPR27Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempHCPR27Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0704',NULL,'2024-01-01','Denominator EXCLUSION: Transferred, eloped, AMA, or expired patients are excluded. ')
				,(@measureId,'HCPCS','VH273',NULL,'2024-01-01','Performance Met:  Point-of-Care Ultrasound evaluation for Pneumothorax performed. ')
				,(@measureId,'HCPCS','VH275',NULL,'2024-01-01','Performance Not Met: Point-of-Care Ultrasound evaluation for pneumothorax not performed. ')
				,(@measureId,'HCPCS','VH274',NULL,'2024-01-01','Denominator Exception:  Documented medical reason for not performing Point-of-Care Ultrasound (e.g. no ultrasound machine available, patient refusal). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','00001',NULL,'2024-01-01','CVC Insertion was performed on internal jugular or subclavian veins (Pseudo Code): HCPR2701? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ECPR51  : reorder them
	----------------
	SET @measureName = 'ECPR51';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR51Table;
		
		SELECT 
			*
		INTO 
			#TempECPR51Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR51Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR51Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR51Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0700',NULL,'2024-01-01','Denominator EXCLUSION: Patient Transfered, elope or is an AMA patients? ')
				,(@measureId,'HCPCS','VE269',NULL,'2024-01-01','Performance Met: Naloxone was prescribed at discharge AND patient was educated about use. *NOTE: Distribution of Naloxone to patient at discharge is also acceptable in lieu of Naloxone prescription. ')
				,(@measureId,'HCPCS','VE271',NULL,'2024-01-01','Performance Not Met: Naloxone medication was not prescribed at discharge OR patient was not educated about use. ')
				,(@measureId,'HCPCS','VE270',NULL,'2024-01-01','Denominator Exception: Naloxone was not prescribed at discharge due to medical reasons such as allergy. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG519',NULL,'2024-01-01','Patient has Disposition of Discharged (Pseudo code - DG519)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP64  : reorder them
	----------------
	SET @measureName = 'ACEP64';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP64Table;
		
		SELECT 
			*
		INTO 
			#TempACEP64Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP64Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP64Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP64Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','P6401',NULL,'2024-01-01','Denominator EXCLUSIONS: <ul>  <li>Syncope</li>  <li>Pulmonary embolism</li>  <li>Proximal DVT</li>  <li>Already on anticoagulation at time of DVT diagnosis based on listed home medications</li></ul> ')
				,(@measureId,'HCPCS','P6402',NULL,'2024-01-01','Performance Met: Patient discharged from ED. ')
				,(@measureId,'HCPCS','P6403',NULL,'2024-01-01','Performance Not Met : Patient not discharged from ED. ')
				,(@measureId,'HCPCS','P6404',NULL,'2024-01-01','Denominator Exception: Death, LAMA, LWBS, LWT. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP60  : reorder them
	----------------
	SET @measureName = 'ACEP60';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP60Table;
		
		SELECT 
			*
		INTO 
			#TempACEP60Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP60Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP60Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP60Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','P6001',NULL,'2024-01-01','Denominator EXCLUSIONS: <ul><li>Heart Disease (coronary artery disease, Myocardial Infarction, CHF, cardiomyopathy, etc.)</li><li>Heart Rhythm Disorders (Arrhythmias, Sinus Node Dysfunction, Uncontrolled Atrial Fibrillation, etc.)</li><li>Aortic Dissection</li><li>Pulmonary Embolism</li><li>Subarachnoid Hemorrhage</li><li>Coagulation Disorder</li></ul> ')
				,(@measureId,'HCPCS','P6002',NULL,'2024-01-01','Performance Met: Patient discharged from ED. ')
				,(@measureId,'HCPCS','P6003',NULL,'2024-01-01','Performance Not Met: Patient not discharged from ED. ')
				,(@measureId,'HCPCS','P6004',NULL,'2024-01-01','Denominator Exception: Death, LAMA, LWBS, LWT. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ACEP61  : reorder them
	----------------
	SET @measureName = 'ACEP61';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempACEP61Table;
		
		SELECT 
			*
		INTO 
			#TempACEP61Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempACEP61Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempACEP61Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempACEP61Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','DG063',NULL,'2024-01-01','Denominator EXCLUSIONS: History of Cystic Fibrosis, Airway Malformations, Immunodeficiency Syndromes, Pneumonia. ')
				,(@measureId,'HCPCS','DG062',NULL,'2024-01-01','Performance Met: A chest x-ray was ordered/performed for the patient. ')
				,(@measureId,'HCPCS','DG061',NULL,'2024-01-01','Performance Not Met: A chest x-ray was not ordered/performed for the patient. ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';
 

	----------------
	-- ECPR39  : reorder them
	----------------
	SET @measureName = 'ECPR39';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR39Table;
		
		SELECT 
			*
		INTO 
			#TempECPR39Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR39Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR39Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR39Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0700',NULL,'2024-01-01','Denominator EXCLUSIONS: Transferred, eloped or AMA patients are excluded. ')
				,(@measureId,'HCPCS','VE250',NULL,'2024-01-01','Performance Met: Patients who did not have a head CT ordered. ')
				,(@measureId,'HCPCS','VE252',NULL,'2024-01-01','Performance Not Met: Patients who did have a Head CT ordered; reason not given. ')
				,(@measureId,'HCPCS','VE251',NULL,'2024-01-01','Denominator Exception:  Patients who did have a heat CT ordered for medical reason documented by the eligible professional <p>(i.e., <ul><li>Seizure;</li> <li>alcohol/drug intoxication;</li> <li>vomiting;</li> <li>altered mental status;</li> <li>abnormal neurologic exam;</li><li>concern for intracranial injury/hemorrhage, stroke, or mass lesion</li></ul>)</p> ')

				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 005-A  : update title
	----------------
	SET @measureName = '005-A';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '005-A Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- should read:
		-- MIPS# 005-A : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF HF ASSESSED DURING AN OUTPATIENT ENCOUNTER): Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 005-A : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) <= 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period: (SUBMISSION CRITERIA 1: All patients with a diagnosis of HF assessed during an outpatient encounter). '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '005-A Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 005-B  : update title
	----------------
	SET @measureName = '005-B';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '005-B Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- should read:
		-- MIPS# 005-B : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF HF AND DISCHARGED FROM HOSPITAL DENOMINATOR) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 005-B : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) <= 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period: (SUBMISSION CRITERIA 2: All patients with a diagnosis of HF and discharged from hospital). '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '005-B Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- THEPQR4  : reorder and put the CPT to be written in a more visible place for the question.
	----------------
	SET @measureName = 'THEPQR4';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempTHEPQR4Table;
		
		SELECT 
			*
		INTO 
			#TempTHEPQR4Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempTHEPQR4Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempTHEPQR4Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempTHEPQR4Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','QR307',NULL,'2024-01-01','Denominator EXCLUSION: <ul><li>Patient on hospice, or discharged to hospice.</li><li>Eloped or left AMA.</li><li>Expired</li><li>Comfort measures documented (Documented code status of DNR-A)</li><li>Transferred to another hospital</li><li>Patient admission to psychiatric or behavioral care</li></ul> (PQR307) ')
				,(@measureId,'HCPCS','QR309',NULL,'2024-01-01','Performance Met:  Patient received order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service (PQR309) ')
				,(@measureId,'HCPCS','QR310',NULL,'2024-01-01','Performance Not Met:  Patient did not receive an order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service (PQR310) ')
				,(@measureId,'HCPCS','QR308',NULL,'2024-01-01','Denominator Exception: <ul><li>Patient or medical decision maker refusal.</li><li>Documented medical reason for exclusion (example: palliative care not appropriate).</li><li>Palliative care not available, or system issue preventing palliative care consult.</li></ul> (PQR308) ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG111',NULL,'2024-01-01','Patient has any of the following? (DG111) <ul><li>2+ same diag ED or hospitalizations in 12 months (PQR301)</li><li>Chronic oxygen, or Vent (PQR302)</li><li>Hospital Admit from LTC Fac (PQR303)</li><li>Stage 4/Metastatic cancer (PQR304)</li><li>Difficult to control phys symptoms (PQR305)</li><li>Complex care requirements (PQR306): <ul><li>Home infusion</li><li>Tube feeding</li><li>mechanical Vent</li><li>24hr Bedbound care</li></ul></li><li>(SDOH) (ICD10): Z55, Z56, Z59, Z60, Z64, Z65</li></ul>')
				;
		
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 007-A  : reorder them
	----------------
	SET @measureName = '007-A';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp007ATable;
		
		SELECT 
			*
		INTO 
			#Temp007ATable
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp007ATable;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp007ATable);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp007ATable);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9189',NULL,'2024-01-01','Performance Met: Beta-blocker therapy prescribed or currently being taken. ')
				,(@measureId,'HCPCS','G9188',NULL,'2024-01-01','Performance Not Met: Beta-blocker therapy not prescribed, reason not given. ')
				,(@measureId,'HCPCS','G9190',NULL,'2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons). ')
				,(@measureId,'HCPCS','G9191',NULL,'2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','G8694',NULL,'2024-01-01','Is Left ventricular ejection fraction (LVEF) less than <= 40% or documentation of moderate or severe LVSD: G8694? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 007-B  : reorder them
	----------------
	SET @measureName = '007-B';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp007BTable;
		
		SELECT 
			*
		INTO 
			#Temp007BTable
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp007BTable;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp007BTable);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp007BTable);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','4008F',NULL,'2024-01-01','Performance Met: Beta-blocker therapy prescribed or currently being taken. ')
				,(@measureId,'HCPCS','4008F','8P','2024-01-01','Performance Not Met: Beta-blocker therapy not prescribed, reason not otherwise specified. ')
				,(@measureId,'HCPCS','4008F','1P','2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons). ')
				,(@measureId,'HCPCS','4008F','2P','2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','00001',NULL,'2024-01-01','Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				--AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				--AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- HCPR24  : reorder them
	----------------
	SET @measureName = 'HCPR24';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempHCPR24Table;
		
		SELECT 
			*
		INTO 
			#TempHCPR24Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempHCPR24Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempHCPR24Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempHCPR24Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0704',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Transferred, eloped, AMA or expired patients are excluded. ')
				,(@measureId,'HCPCS','VH271',NULL,'2024-01-01','Performance Met: <ul><li>Vancomycin not ordered</li><li>OR Vancomycin discontinued at admission.</li><li>OR Vancomycin ordered AND MRSA infection identified or risk for MRSA infection documented <p>(i.e., <ul><li>nasal colonization,</li><li>prior MRSA infection,</li><li>recent hospitalization,</li><li>recent antibiotics,</li><li>penetrating injury,</li><li>IVDU,</li><li>purulent cellulitis,</li><li>SIRS criteria,</li><li>sepsis,</li><li>impaired host defense</li></ul>)</p></li></ul> ')
				,(@measureId,'HCPCS','VH272',NULL,'2024-01-01','Performance Not Met: : Vancomycin ordered AND no MRSA infection identified OR no risk for MRSA infection documented. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','V0717',NULL,'2024-01-01','Patient Admitted or placed in Observation Status (V0717)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			
		-- before changes
		SELECT 'HCPR24 Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: HCPR24 Appropriate Utilization of Vancomycin for Cellulitis: Percentage of patients with Cellulitis who did not receive Vancomycin unless MRSA Infection or risk for MRSA Infection was identified.

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'HCPR24 : Appropriate Utilization of Vancomycin for Cellulitis: Percentage of patients with Cellulitis who did not receive Vancomycin unless MRSA Infection or risk for MRSA Infection was identified. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT 'HCPR24 Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 047  : update MEASURE_HOTSHEET_URI
	----------------
	SET @measureName = '047';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '047 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><strong>Definition:</strong></p><p><strong>Documentation that Patient did not Wish or was not able to Name a Surrogate Decision Maker or Provide an Advance Care Plan</strong> – May also include: <ul><li>That the patient’s cultural and/or spiritual beliefs preclude a discussion of advance care planning, and thus harmful to the physician-patient relationship.</li></ul></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '047 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

		-- remove the definition from the original not met response which was:
		-- Performance Not Met: Advance Care Planning not documented, reason not otherwise specified. <p><strong>Definition:</strong></p><p><strong>Documentation that Patient did not Wish or was not able to Name a Surrogate Decision Maker or Provide an Advance Care Plan</strong> – May also include: <ul><li>That the patient’s cultural and/or spiritual beliefs preclude a discussion of advance care planning, and thus harmful to the physician-patient relationship.</li></ul></p>

		SELECT '047 `Performance Not Met` description before update:' = (
			SELECT	
				[DESCRIPTION] 
			FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
				[CMS_PQRI_MEASURE_ID] = @measureId
				AND [CODING_SYSTEM] = 'HCPCS'
				AND [CODE] = '1123F'
				AND [MODIFIER] = '8P'
			);
		
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [DESCRIPTION] = 'Performance Not Met: Advance Care Planning not documented, reason not otherwise specified. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId
			AND [CODING_SYSTEM] = 'HCPCS'
			AND [CODE] = '1123F'
			AND [MODIFIER] = '8P';

		SELECT '047 `Performance Not Met` description after update:' = (
			SELECT	
				[DESCRIPTION] 
			FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
				[CMS_PQRI_MEASURE_ID] = @measureId
				AND [CODING_SYSTEM] = 'HCPCS'
				AND [CODE] = '1123F'
				AND [MODIFIER] = '8P'
			);
	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 134  : update title
	----------------
	SET @measureName = '134';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		-- before changes
		SELECT '134 Description before update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: MIPS# 134 : Preventive Care and Screening: Screening for Depression and Follow-Up Plan : Percentage of patients aged 12 years and older screened for depression on the date of the encounter or up to 14 days prior to the date of the encounter using an age-appropriate standardized depression screening tool AND if positive, a follow-up plan is documented on the date of or up to two days after the date of the qualifying encounter. 

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_TITLE] = 'MIPS# 134 : Preventive Care and Screening: Screening for Depression and Follow-Up Plan : Percentage of patients aged 12 years and older screened for depression on the date of the encounter or up to 14 days prior to the date of the encounter using an age-appropriate standardized depression screening tool AND if positive, a follow-up plan is documented on the date of or up to two days after the date of the qualifying encounter. '
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '134 Description after update:' = (SELECT [MEASURE_TITLE] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

		-- reorder the responses
		DROP TABLE IF EXISTS #Temp134Table;
		
		SELECT 
			*
		INTO 
			#Temp134Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp134Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp134Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp134Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9717',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation stating the patient has had a diagnosis of bipolar disorder. ')
				,(@measureId,'HCPCS','G8431',NULL,'2024-01-01','Performance Met: Screening for depression is documented as being positive AND a follow-up plan is documented. ')
				,(@measureId,'HCPCS','G8510',NULL,'2024-01-01','Performance Met: Screening for depression is documented as negative, a follow-up plan is not required. ')
				,(@measureId,'HCPCS','G8432',NULL,'2024-01-01','Performance Not Met: Depression screening not documented, reason not given. ')
				,(@measureId,'HCPCS','G8511',NULL,'2024-01-01','Performance Not Met: Screening for depression documented as positive, follow-up plan not documented, reason not given. ')
				,(@measureId,'HCPCS','G8433',NULL,'2024-01-01','Denominator Exception: Screening for depression not completed, documented patient or medical reason. ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','G9717',NULL,'2024-01-01','Does NOT have Documentation stating the patient has had a diagnosis of bipolar disorder: (G9717)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;


	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 326  : reorder responses
	----------------
	SET @measureName = '326';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 
	
		DROP TABLE IF EXISTS #Temp326Table;
		
		SELECT 
			*
		INTO 
			#Temp326Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp326Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp326Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp326Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G9929',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patient with transient or reversible cause of AF (e.g., pneumonia, hyperthyroidism, pregnancy, cardiac surgery). ')
				,(@measureId,'HCPCS','G9930',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients who are receiving comfort care only. ')
				,(@measureId,'HCPCS','G9931',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation of CHA2DS2-VASc risk score of 0 or 1 for men; or 0, 1, or 2 for women. ')
				,(@measureId,'HCPCS','G0044',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients with moderate or severe mitral stenosis. ')
				,(@measureId,'HCPCS','G0043',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients with mechanical prosthetic heart valve. ')
				,(@measureId,'HCPCS','G8967',NULL,'2024-01-01','Performance Met: FDA-approved oral anticoagulant is prescribed. ')
				,(@measureId,'HCPCS','G9928',NULL,'2024-01-01','Performance Not Met: FDA-approved anticoagulant not prescribed, reason not given. ')
				,(@measureId,'HCPCS','G8968',NULL,'2024-01-01','Denominator Exception: Documentation of medical reason(s) for not prescribing an FDA-approved anticoagulant (e.g., present or planned atrial appendage occlusion or ligation or patient being currently enrolled in a clinical trial related to AF/atrial flutter treatment). ')
				,(@measureId,'HCPCS','G8969',NULL,'2024-01-01','Denominator Exception: Documentation of patient reason(s) for not prescribing an oral anticoagulant that is FDA approved for the prevention of thromboembolism (e.g., patient preference for not receiving anticoagulation). ')

				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','00001',NULL,'2024-01-01','????: (00001)? ')
				;

			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;


	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- ECPR46  : reorder codes
	----------------
	SET @measureName = 'ECPR46';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #TempECPR46Table;
		
		SELECT 
			*
		INTO 
			#TempECPR46Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #TempECPR46Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #TempECPR46Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #TempECPR46Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','V0709',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patient does NOT have active cancer, palliative care, or end-of-life care? ')
				,(@measureId,'HCPCS','VE263',NULL,'2024-01-01','Performance Met: Opiate not prescribed at discharge. ')
				,(@measureId,'HCPCS','VE265',NULL,'2024-01-01','Performance Not Met: Opiate prescribed, reason not specified. ')
				,(@measureId,'HCPCS','VE264',NULL,'2024-01-01','Denominator Exception: Opiate prescribed for medical reason documented by the Eligible Professional (i.e., suspected or diagnosed herniated disk, fracture, sciatica, radiculopathy). ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				,(@measureId,'DQ411','DG469',NULL,'2024-01-01','Patient Disposition of Discharged – (Pseudo Code) (DG469)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

		-- before changes
		SELECT 'ECPR46 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><img src="/WebPages/Images/MIPS/Mips_ECPR46_AppendixAOpoidMedications.png" alt="(VE264) Appendix - Opoid Medications image"></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT 'ECPR46 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


	----------------
	-- 116  : reorder codes
	----------------
	SET @measureName = '116';
	SET @measureId = dbo.udfMipsSelectMeasureIdFromPqrsCode(@measureName,GETDATE());
	SELECT '@measureName =' = @measureName, '@measureId =' = @measureId;

	IF @measureId > 0
	BEGIN 

		DROP TABLE IF EXISTS #Temp116Table;
		
		SELECT 
			*
		INTO 
			#Temp116Table
		FROM 
			[CMS_PQRI_MEASURE_CODE]
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @measureId 
			AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
			AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
			AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
			AND [DESCRIPTION] IS NOT NULL

		SELECT * FROM #Temp116Table;
		
		SET @foundrecordId = (SELECT COUNT(*) FROM #Temp116Table);

		SELECT '@foundrecordId =' = @foundrecordId;

		IF @foundrecordId > 0
		BEGIN
			DELETE 
				FROM 
					[CMS_PQRI_MEASURE_CODE]
				WHERE 
					[CMS_PQRI_MEASURE_CODE_ID] IN (SELECT [CMS_PQRI_MEASURE_CODE_ID] FROM #Temp116Table);
			
			INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
			VALUES
				-- SELECTIONS
				 (@measureId,'HCPCS','G2176',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Outpatient, ED or Observation visits that result in an inpatient admission ')
				,(@measureId,'HCPCS','G2177',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Acute bronchitis/bronchiolitis episodes when the patient had a new or refill prescription of antibiotics (Table 1) in the 30 days prior to the episode date ')
				,(@measureId,'HCPCS','G9712',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Documentation of medical reason(s) for prescribing or dispensing antibiotic. (G9712) <p><img src="/WebPages/Images/MIPS/MIPS_116_Definition1.png" alt="(G9712) Definition image"></p> ')
				,(@measureId,'HCPCS','G9713',NULL,'2024-01-01','DENOMINATOR EXCLUSION: Patients who use hospice services any time during the measurement period ')
				,(@measureId,'HCPCS','4124F',NULL,'2024-01-01','Performance Met: Antibiotic neither prescribed nor dispensed. ')
				,(@measureId,'HCPCS','4120F',NULL,'2024-01-01','Performance Not Met: Antibiotic prescribed or dispensed. ')
						
				-- PQRS Question for response by coder within ACS		
				-- QUESTIONS		
				--,(@measureId,'DQ411','ddd',NULL,'2024-01-01','Patient Disposition of Discharged – (Pseudo Code) (DG469)? ')
				;
				
			-- review changes
			SELECT * FROM 
				[CMS_PQRI_MEASURE_CODE]
			WHERE 
				[CMS_PQRI_MEASURE_ID] = @measureId 
				AND [CODING_SYSTEM] IN ('HCPCS','DQ411')
				AND ([START_DATE] IS NULL OR [START_DATE] <= GETDATE())
				AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
				AND [DESCRIPTION] IS NOT NULL;
		END
		ELSE
			SELECT 'Error: unable to find records to update for' + @measureName;
			

		-- before changes
		SELECT '116 MEASURE_HOTSHEET_URI before update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);
		-- supposed to be something like: null

		UPDATE [CMS_PQRI_MEASURE]
			SET [MEASURE_HOTSHEET_URI] = '<p><img src="/WebPages/Images/MIPS/MIPS_116_Table1.png" alt="Table 1 image"></p> '
			, [MEASURE_TOOLTIP] = null
		WHERE
			[CMS_PQRI_MEASURE_ID] = @measureId;
			
		-- review changes
		SELECT '116 MEASURE_HOTSHEET_URI after update:' = (SELECT [MEASURE_HOTSHEET_URI] FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] = @measureId);

	END
	ELSE
		SELECT 'Error: unable to find a measure id for' + @measureName;

	SELECT '-----------------------------';


-- rollback tran; -- testing
-- commit tran; -- testing

GO

