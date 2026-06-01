USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3229 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR3.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3229 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR3.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR3';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Process'
			,@PqrsCd + ' : SGLT-2 inhibitors for patients with HFrEF with or without Type 2 Diabetes : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) ≤ 40% who were prescribed SGLT-2 Inhibitors with or without Type 2 diabetes during their SNF stay or discharge from either the hospital (inpatient or observation) or SNF. '
			,'B'
			,18
			,999
			,@Dos
			,'12-31-24'
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR3' -- = 221
*/
-- End of 01) DACS-3229 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR3.SQL
GO

-- Start of 02) DACS-3229 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR3.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3229 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR3.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR3';
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
		-- Diagnosis for heart failure (ICD-10-CM)
		 (@MeasureId,'DG1P1','I11.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.813',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.814',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.9',NULL,@Dos,NULL)

		-- Outpatient Encounters during performance period (CPT) and Inpatient Discharges during performance period (CPT)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		
		-- Inpatient Discharge during performance period (CPT)  -- may need to become DG2P1.  await customer feedback
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		
		-- more exclusion codes list A and B
		,(@MeasureId,'DG2P1','E08.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E08.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E08.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E09.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E09.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E09.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.321',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.329',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.331',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.339',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.34',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.341',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.349',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.35',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.351',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.352',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.353',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.354',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.355',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.359',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.61',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.62',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.63',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.64',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.013',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.03',NULL,@Dos,NULL)
		 
		-- measure code numerators
		,(@MeasureId,'HCPCS','QR401',NULL,@Dos,'Denominator EXCLUSIONS: <ul><li>Enrolled in clinical trial</li><li>Transferred, Eloped or left AMA</li><li>Expired</li><li>Comfort measures documented</li><li>Discharged to hospice</li><li>Patients with heart transplant or assist device</li><li>Diabetic Ketoacidosis (DKA)</li><li>Type 1 diabetes</li><li>Patients with a history of heart transplant or with a Left Ventricular Assist Device (LVAD)</li></ul> (Pseudo code: PQR401). ')
		,(@MeasureId,'HCPCS','QR404',NULL,@Dos,'Performance Met: Patients who were prescribed or currently taking SGLT-2 Inhibitors (Pseudo code: PQR404). ')
		,(@MeasureId,'HCPCS','QR403',NULL,@Dos,'Performance Not Met: Patients for whom any of the SGLT-2 inhibitors were neither a prescribed or currently active within the medication. Reason not given. (Pseudo code: PQR403). ')
		,(@MeasureId,'HCPCS','QR402',NULL,@Dos,'Denominator Exception: <ul><li>Hypoglycemia</li><li>Allergy intolerance</li><li>GFR less than 30 ml/min</li><li>History of complicated or recurrent UTIs</li><li>Patient refusal</li></ul> (Pseudo code: PQR402). ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','M1150',NULL,@Dos,'Does patient have Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: M1150? ')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 180 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR3' -- = 221
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 221
*/
-- End of 02) DACS-3229 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR3.SQL
GO

-- Start of 03) DACS-3229 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3229 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;
		--AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- not used but might change after review by client-- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	-- at present, not needed for this particular MIPS.

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	-- IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	-- BEGIN
		-- PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	-- IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	-- BEGIN
		-- PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for heart failure (ICD-10-CM)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for heart failure (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Outpatient Encounters during performance period (CPT) and Inpatient Discharges during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have any diagnosis exclusions?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount > 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Excluded code found (ICD-10-CM))', 'Code' = 'ERR-3-NID';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR3' -- = 221

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3
	@ChartId = 2100112304
	,@PqrsNum = 'THEPQR3'
	,@Dos = '7/11/2024 2:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3229 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR3].SQL
GO

-- Start of 04) DACS-3229 - Create of Alter Stored Procedure - [dbo].[Maintenance_SelectAllUserProfiles].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3229 - Create of Alter Stored Procedure - [dbo].[Maintenance_SelectAllUserProfiles].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_SelectAllUserProfiles] 
WITH EXEC AS CALLER AS
BEGIN
	----------------------------------------------
	-- updated to make all fields strings to reduce field type exceptions when ACS reads data - DACS-3229 - 20240716 - pippin
	----------------------------------------------
	
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP (50000) 
		 CAST([USER_PROFILE_ID] AS VARCHAR(200)) AS USER_PROFILE_ID
		,CAST([SIGN_ON_ID] AS VARCHAR(200)) AS SIGN_ON_ID  
		,CAST([FIRST_NAME] AS VARCHAR(200)) AS FIRST_NAME
		,CAST([LAST_NAME] AS VARCHAR(200)) AS LAST_NAME
		,CAST([IS_ACTIVE] AS VARCHAR(200)) AS IS_ACTIVE
		,CAST([EMAIL_ADDRESS] AS VARCHAR(200)) AS EMAIL_ADDRESS
		,CAST([USER_CLASS_CD] AS VARCHAR(200)) AS USER_CLASS_CD
		,CAST([INACTIVATED_DATE_TIME] AS VARCHAR(200)) AS INACTIVATED_DATE_TIME
		,CAST([USER_PROFILE_DEACTIVATION_REASON_ID] AS VARCHAR(200)) AS USER_PROFILE_DEACTIVATION_REASON_ID
		,CAST([USER_PROFILE_DEACTIVATION_OTHER_REASON] AS VARCHAR(200)) AS USER_PROFILE_DEACTIVATION_OTHER_REASON
		,CAST([SSO_COMPANY_ID] AS VARCHAR(200)) AS SSO_COMPANY_ID
		,CAST([SSO_EXTERNAL_IDENTIFIER] AS VARCHAR(200)) AS SSO_EXTERNAL_IDENTIFIER
	FROM USER_PROFILE;

END -- end procedure

GO

/*
testing:
begin tran; -- testing
EXEC [dbo].[Maintenance_SelectAllUserProfiles]
*/
-- End of 04) DACS-3229 - Create of Alter Stored Procedure - [dbo].[Maintenance_SelectAllUserProfiles].SQL
GO

-- Start of 01) DACS-3457 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 416 (old).SQL

------------------------------------------------------------------------------------
-- 01) DACS-3457 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 416 (old).SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '416';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Efficiency – High Priority'
			,'MIPS# ' + @PqrsCd + ' : Emergency Medicine: Emergency Department Utilization of CT for Minor Blunt Head Trauma for Patients Aged 2 Through 17 Years : Percentage of emergency department visits for patients aged 2 through 17 years who presented with a minor blunt head trauma who had a head CT for trauma ordered by an emergency care provider who are classified as low risk according to the Pediatric Emergency Care Applied Research Network (PECARN) prediction rules for traumatic brain injury. 			<p><strong>Definition:</strong></p> <p><strong>Low Risk for Traumatic Brain Injury according to PECARN prediction rules –</strong></p> <p>Patients can be classified as low risk if ALL of the following are met: <ul><li>No signs of altered mental status (e.g., agitation, somnolence, repetitive questioning, slow response to verbal communication) OR no GCS < 15</li><li>No signs of basilar skull fracture (signs include haemotympanum, “raccoon” eyes, cerebrospinal fluid leakage from the ear or nose, Battle’s sign)</li><li>No loss of consciousness</li><li>No vomiting</li><li>No severe mechanism of injury (i.e., motor vehicle crash with patient ejection, death of another passenger, or rollover; pedestrian or bicyclist without helmet struck by a motorized vehicle; falls of more than 5 feet; or head struck by a high-impact object)</li><li>No severe headache</li></ul></p> '	
			,'B'
			,2
			,18
			,'2024-01-01'
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '416' -- = 228
*/
-- End of 01) DACS-3457 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 416 (old).SQL
GO

-- Start of 02) DACS-3457 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 416.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3457 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 416.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '416';
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
		-- Diagnosis for minor blunt head trauma (ICD-10-CM)
		 (@MeasureId,'DG1P1','S00.03XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.33XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.431A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.432A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.439A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.531A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.532A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.83XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.93XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.A0XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.A1XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.30AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.300A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.301A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.302A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.303A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.304A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.309A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.31AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.32AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.33AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.34AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.340A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.341A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.342A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.343A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.344A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.349A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.35AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.350A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.351A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.352A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.353A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.354A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.359A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.36AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.360A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.361A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.362A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.363A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.364A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.369A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.37AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.38AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.81AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.810A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.811A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.812A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.813A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.814A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.819A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.82AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.820A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.821A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.822A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.823A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.824A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.829A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.89AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.890A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.891A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.892A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.893A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.894A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.899A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.11XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.19XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.8XXA',NULL,@Dos,NULL)

		-- Patient encounter during performance period (CPT)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)

		-- WITHOUT Telehealth Modifier (including but not limited to)
		,(@MeasureId,'DG2P1',NULL,'GQ',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'GT',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'95',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'POS 02',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'POS 10',@Dos,NULL)
		 
		-- measure code numerators
		-- SELECTIONS
		--,(@MeasureId,'HCPCS','G9594',NULL,@Dos,'Patient presented with a minor blunt head trauma and had a head CT ordered for trauma by an emergency care provider? ')
		,(@MeasureId,'HCPCS','G9595',NULL,@Dos,'(DENOMINATOR EXCLUSION): Patient was NOT documentated with ventricular shunt, brain tumor, or coagulopathy? ')
		,(@MeasureId,'HCPCS','G9593',NULL,@Dos,'Performance Met: Pediatric patient with minor blunt head trauma classified as low risk according to the PECARN prediction rules. ')
		,(@MeasureId,'HCPCS','G0047',NULL,@Dos,'Performance Met: Pediatric patient with minor blunt head trauma and PECARN prediction criteria are not assessed. ')
		,(@MeasureId,'HCPCS','G9597',NULL,@Dos,'Performance Not Met: Pediatric patient with minor blunt head trauma not classified as low risk according to the PECARN prediction rules. <p><img src="/WebPages/Images/MIPS/MIPS416_PECARN_definition.png" alt="(G9597) PECARN prediction rules image"></p>')
				
		-- PQRS Question for response by coder within ACS		
		-- QUESTION
		,(@MeasureId,'DQ411','G9594',NULL,@Dos,'Was Patient presented with a minor blunt head trauma and had a head CT ordered for trauma by an emergency care provider: (G9594)? ')
		-- ,(@MeasureId,'DQ411','00002',NULL,@Dos,'Patient was NOT documentated with ventricular shunt, brain tumor, or coagulopathy: (DENOMINATOR EXCLUSION - G9595)? ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 131 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '416' -- = 228
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 228
*/
-- End of 02) DACS-3457 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 416.SQL
GO

-- Start of 03) DACS-3457 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3457 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data or failed USE_TELEHEALTH field check.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND [LOCATION_OF_SERVICE] IN ('02','10')
		)
	BEGIN 
		PRINT('@ChartId has an excluded telehealth Location of Service value of (02 or 10) : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [MODIFIERS] IN (SELECT [MODIFIER] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount > 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '416' -- = 228

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416
	@ChartId = 2100112732
	,@PqrsNum = '416'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3457 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type416].SQL
GO

-- Start of 04) DACS-3457 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3457 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL
------------------------------------------------------------------------------------
GO

GO

GO

-- begin tran -- testing rollback tran;
-- backup procedure before we work on it
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectMissingChartPqrs', @DestProc = 'spSelectMissingChartPqrs_DACS-3457';
GO

CREATE OR ALTER PROCEDURE [dbo].[spSelectMissingChartPqrs]
	@ChartId int
WITH EXEC AS CALLER
AS

SET NOCOUNT ON					-- DACS-3457 - 20240723 - pippin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @chart_id INT =@ChartId;
DECLARE @RequiredMeasures table
(
  CMS_PQRI_MEASURE_ID int,
  MEASURE_TITLE varchar(4000), 	-- DACS-3457 - 20240723 - pippin - increases field width
  CMS_PQRI_MEASURE_CODE_ID int,
  CODING_SYSTEM varchar(20),
  OPTION_GROUP numeric(18,0),
  CODE varchar(20),
  MODIFIER varchar(20),
  [DESCRIPTION] varchar(4000), 	-- DACS-3457 - 20240723 - pippin - increases field width
  END_DATE date,
  CODE_2 varchar(6),
  MODIFIER_2 varchar(20),
  [ROW_NUMBER] bigint
)

INSERT INTO @RequiredMeasures(CMS_PQRI_MEASURE_ID, MEASURE_TITLE, CMS_PQRI_MEASURE_CODE_ID, CODING_SYSTEM, OPTION_GROUP, CODE, MODIFIER, [DESCRIPTION], END_DATE, CODE_2, MODIFIER_2, [ROW_NUMBER])
  EXEC [spSelectChartPQRS] @ChartId=@chart_id

SELECT *
FROM @RequiredMeasures rm
WHERE (SELECT COUNT(*)
       FROM PHYSICIAN_PROCEDURE_EVALUATION ppe
         JOIN CHARGE_MASTER cm on cm.CHARGE_MASTER_ID=ppe.PHYSICIAN_PROCEDURE_ID
         JOIN CMS_PQRI_MEASURE_CODE cpmc on cpmc.CMS_PQRI_MEASURE_ID=rm.CMS_PQRI_MEASURE_ID
       WHERE CHART_ID=@chart_id
         AND cm.CHARGE_MASTER_USAGE_CODE=9
         AND cpmc.CODING_SYSTEM in ('CPT_II', 'HCPCS')
         AND cm.CPT_CODE=cpmc.CODE
         AND ppe.MODIFIERS=isnull(cpmc.MODIFIER, ''))=0
GO


-- End of 04) DACS-3457 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL
GO

-- Start of 01) DACS-3458 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 415 (old).SQL

------------------------------------------------------------------------------------
-- 01) DACS-3458 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 415 (old).SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '415';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Efficiency – High Priority'
			,'MIPS# ' + @PqrsCd + ' : Emergency Medicine: Emergency Department Utilization of CT for Minor Blunt Head Trauma for Patients Aged 18 Years and Older : Percentage of emergency department visits for patients aged 18 years and older who presented with a minor blunt head trauma who had a head CT for trauma ordered by an emergency care provider who have an indication for a head CT. '	
			,'B'
			,18
			,999
			,'2024-01-01'
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '415' -- = 229
*/
-- End of 01) DACS-3458 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 415 (old).SQL
GO

-- Start of 02) DACS-3458 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 415.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3458 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 415.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '415';
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
		-- Diagnosis for minor blunt head trauma (ICD-10-CM)
		 (@MeasureId,'DG1P1','S00.03XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.33XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.431A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.432A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.439A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.531A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.532A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.83XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.93XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.A0XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.A1XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.30AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.300A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.301A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.302A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.303A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.304A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.309A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.31AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.32AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.33AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.34AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.340A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.341A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.342A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.343A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.344A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.349A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.35AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.350A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.351A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.352A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.353A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.354A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.359A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.36AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.360A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.361A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.362A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.363A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.364A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.369A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.37AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.38AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.81AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.810A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.811A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.812A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.813A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.814A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.819A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.82AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.820A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.821A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.822A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.823A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.824A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.829A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.89AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.890A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.891A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.892A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.893A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.894A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.899A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.11XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.19XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.8XXA',NULL,@Dos,NULL)

		-- Patient encounter during performance period (CPT)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)

		-- WITHOUT Telehealth Modifier (including but not limited to)
		,(@MeasureId,'DG2P1',NULL,'GQ',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'GT',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'95',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'POS 02',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'POS 10',@Dos,NULL)
		 
		-- measure code numerators
		,(@MeasureId,'HCPCS','G9531',NULL,@Dos,'(DENOMINATOR EXCLUSION): Patient was NOT documentated with ventricular shunt, brain tumor, multisystem trauma, or is currently taking an antiplatelet medication including: abciximab, anagrelide, cangrelor, cilostazol, clopidogrel, dipyridamole, eptifibatide, prasugrel, ticlopidine, ticagrelor, tirofiban, or vorapaxar? ')
		,(@MeasureId,'HCPCS','G9529',NULL,@Dos,'Performance Met: Patient with minor blunt head trauma had an appropriate indication(s) for a head CT. ')
		,(@MeasureId,'HCPCS','G9533',NULL,@Dos,'Performance Not Met: Patient with minor blunt head trauma did not have an appropriate indication(s) for a head CT. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G9530',NULL,@Dos,'Was Patient presented with a minor blunt head trauma and had a head CT ordered for trauma by an emergency care provider: (G9530)? ')
		--,(@MeasureId,'DQ411','G9531',NULL,@Dos,'Patient was NOT documentated with ventricular shunt, brain tumor, multisystem trauma, or is currently taking an antiplatelet medication including: abciximab, anagrelide, cangrelor, cilostazol, clopidogrel, dipyridamole, eptifibatide, prasugrel, ticlopidine, ticagrelor, tirofiban, or vorapaxar: (DENOMINATOR EXCLUSION - G9531)? ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 130 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '415' -- = 229
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 229
*/
-- End of 02) DACS-3458 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 415.SQL
GO

-- Start of 03) DACS-3458 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3458 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data or failed USE_TELEHEALTH field check.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND [LOCATION_OF_SERVICE] IN ('02','10')
		)
	BEGIN 
		PRINT('@ChartId has an excluded telehealth Location of Service value of (02 or 10) : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded telehealth Location of Service value of (02 or 10)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Telehealth Modifier (including but not limited to)?  if we do, reject this MIPS.
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [MODIFIERS] IN (SELECT [MODIFIER] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount > 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have a Telehealth Modifier)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Diagnosis for ischemic stroke (ICD-10-CM)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for ischemic stroke (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '415' -- = 229

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415
	@ChartId = 2100112732
	,@PqrsNum = '415'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3458 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type415].SQL
GO

-- Start of 01) DACS-3459 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 326 (old).SQL

------------------------------------------------------------------------------------
-- 01) DACS-3459 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 326 (old).SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '326';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
			,'MIPS# ' + @PqrsCd + ' : Atrial Fibrillation and Atrial Flutter: Chronic Anticoagulation Therapy : Percentage of patients aged 18 years and older with atrial fibrillation (AF) or atrial flutter who were prescribed an FDA-approved oral anticoagulant drug for the prevention of thromboembolism during the measurement period. '	
			,'B'
			,18
			,999
			,'2024-01-01'
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '326' -- = 230
*/
-- End of 01) DACS-3459 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 326 (old).SQL
GO

-- Start of 02) DACS-3459 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 326.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3459 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 326.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '326';
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
		-- Diagnosis for atrial fibrillation or atrial flutter (ICD-10-CM)
		 (@MeasureId,'DG1P1','I48.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I48.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I48.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I48.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I48.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I48.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I48.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I48.91',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I48.92',NULL,@Dos,NULL)

		-- Patient encounter during performance period (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99426',NULL,@Dos,NULL)

		-- measure code numerators
		,(@MeasureId,'HCPCS','G9929',NULL,@Dos,'DENOMINATOR EXCLUSION: Patient was NOT documentated with transient or reversible cause of AF (e.g., pneumonia, hyperthyroidism, pregnancy, cardiac surgery). ')
		,(@MeasureId,'HCPCS','G8967',NULL,@Dos,'Performance Met: FDA-approved oral anticoagulant is prescribed. ')
		,(@MeasureId,'HCPCS','G9928',NULL,@Dos,'Performance Not Met: FDA-approved anticoagulant not prescribed, reason not given. ')
		,(@MeasureId,'HCPCS','G8968',NULL,@Dos,'Denominator Exception: Documentation of medical reason(s) for not prescribing an FDA-approved anticoagulant (e.g., present or planned atrial appendage occlusion or ligation or patient being currently enrolled in a clinical trial related to AF/atrial flutter treatment). ')
		,(@MeasureId,'HCPCS','G8969',NULL,@Dos,'Denominator Exception: Documentation of patient reason(s) for not prescribing an oral anticoagulant that is FDA approved for the prevention of thromboembolism (e.g., patient preference for not receiving anticoagulation). ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G9930',NULL,@Dos,'Patient who was <strong>NOT</strong> receiving comfort care only (G9930)? ')
		,(@MeasureId,'DQ411','G9931',NULL,@Dos,'Patient who does <strong>NOT</strong> have documentation of CHA2DS2-VASc risk score of 0 or 1 for men; or 0, 1, or 2 for women (G9931)? ')
		,(@MeasureId,'DQ411','G0044',NULL,@Dos,'Patient who does <strong>NOT</strong> have moderate or severe mitral stenosis (G0044)? ')
		,(@MeasureId,'DQ411','G0043',NULL,@Dos,'Patient who does <strong>NOT</strong> have mechanical prosthetic heart valve (G0043)? ')
		--,(@MeasureId,'DQ411','00005',NULL,@Dos,'Patient was NOT documentated with transient or reversible cause of AF (e.g., pneumonia, hyperthyroidism, pregnancy, cardiac surgery): (DENOMINATOR EXCLUSION - G9929)? ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 50 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '326' -- = 230
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 230
*/
-- End of 02) DACS-3459 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 326.SQL
GO

-- Start of 03) DACS-3459 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3459 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		--PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	-- No PATIENT_CLASS_ID restrictions at this time.

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	-- IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	-- BEGIN
		-- PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	-- IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	-- BEGIN
		-- PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;


	----------------
	-- if we have no procedure codes nor diagnosis codes, cannot continue
	----------------
	 IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	 BEGIN
	 	SELECT 'Result' = 0, 'Message' = '@ChartId does not have any diagnosis or procedure codes to check.', 'Code' = 'ERR-0-NDP';
		RETURN;
	 END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for atrial fibrillation or atrial flutter (ICD-10-CM)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for atrial fibrillation or atrial flutter (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '326' -- = 230

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326
	@ChartId = 2100112732
	,@PqrsNum = '326'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3459 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type326].SQL
GO

-- Start of 01) DACS-3474 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 116.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3474 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 116.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '116';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
			,'MIPS# ' + @PqrsCd + ' : Avoidance of Antibiotic Treatment for Acute Bronchitis/Bronchiolitis : The percentage of episodes for patients ages 3 months and older with a diagnosis of acute bronchitis/bronchiolitis that did not result in an antibiotic dispensing event. '	
			,'B'
			,0 -- 3 months of age or older check handled by associated SPROC
			,999
			,'2024-01-01'
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '116' -- = 1229
*/
-- End of 01) DACS-3474 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 116.SQL
GO

-- Start of 02) DACS-3474 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 116.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3474 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 116.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '116';
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
		-- Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM)
		 (@MeasureId,'DG1P1','J20.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J20.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J20.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J20.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J20.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J20.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J20.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J21.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J21.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J21.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J21.9',NULL,@Dos,NULL)

		-- Patient encounter during performance period (CPT)
		,(@MeasureId,'DG1P2','98966',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98967',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98968',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98970',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98971',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98972',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99381',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99382',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99383',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99384',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99385',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99386',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99387',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99394',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99395',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99396',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99397',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99401',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99402',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99403',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99404',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99421',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99422',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99423',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99429',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99441',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99442',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99443',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99455',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99456',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99457',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99483',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0071',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0402',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0438',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0439',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0463',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G2010',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G2012',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G2250',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G2251',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G2252',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','T1015',NULL,@Dos,NULL)
		 
		-- measure code numerators
		,(@MeasureId,'HCPCS','G2176',NULL,@Dos,'DENOMINATOR EXCLUSIONS: Outpatient, ED or Observation visits that result in an inpatient admission. ')
		,(@MeasureId,'HCPCS','4124F',NULL,@Dos,'Performance Met: Antibiotic neither prescribed nor dispensed. ')
		,(@MeasureId,'HCPCS','4120F',NULL,@Dos,'Performance Not Met: Antibiotic prescribed or dispensed. <p><img src="/WebPages/Images/MIPS/MIPS_116_Table1.png" alt="Table 1 image"></p> ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G2177',NULL,@Dos,'Patient has <strong>NO</strong> Acute bronchitis/bronchiolitis episodes when the patient had a new or refill prescription of antibiotics (Table 1) in the 30 days prior to the episode date: (G2177)? ')
		,(@MeasureId,'DQ411','G9713',NULL,@Dos,'Patient did <strong>NOT</strong> use hospice services any time during the measurement period? (G9713) ')
		,(@MeasureId,'DQ411','G9712',NULL,@Dos,'Patient did <strong>NOT</strong> have Documentation of medical reason(s) for prescribing or dispensing antibiotic? (G9712) <p><img src="/WebPages/Images/MIPS/MIPS_116_Definition1.png" alt="(G9712) Definition image"></p> ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 97 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '116' -- = 1229
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 1229
*/
-- End of 02) DACS-3474 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 116.SQL
GO

-- Start of 03) DACS-3474 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3474 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 3months on date of encounter
	----------------
	DECLARE @ageFrom DECIMAL(5, 2) = 0.25; -- (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = 999; -- (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge DECIMAL(5, 2) = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		--IF @patientAge IS NULL -- removed because ACS fills this field with an integer and invalidates the use of this field for a fractional age test
		--BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		--END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		--IF @ageFrom IS NULL SET @ageFrom = 0.25;
		--IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		--PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		--PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		--PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('7','8','9') OR [LOCATION_OF_SERVICE] IN ('21'))
		)
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded Physician service class of (7, 8 or 9) Location of Service value of (21)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	-- IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	-- BEGIN
		-- PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	-- IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	-- BEGIN
		-- PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '116' -- = 1229

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116
	@ChartId = 2100112732
	,@PqrsNum = '116'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3474 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type116].SQL
GO

-- Start of 01) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 005-A.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 005-A.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '005-A';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('!!!!! Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF HF ASSESSED DURING AN OUTPATIENT ENCOUNTER): Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) ≤ 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge. '
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF HF ASSESSED DURING AN OUTPATIENT ENCOUNTER): Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) ≤ 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge. '	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);
	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '005-A' -- = 202
*/
-- End of 01) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 005-A.SQL
GO

-- Start of 02) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 005-B.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 005-B.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '005-B';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('!!!!! Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF HF AND DISCHARGED FROM HOSPITAL DENOMINATOR) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) ≤ 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge. '	
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF HF AND DISCHARGED FROM HOSPITAL DENOMINATOR) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) ≤ 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge. '	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);
	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '005-B' -- = 203
*/
-- End of 02) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 005-B.SQL
GO

-- Start of 03) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 005-A.SQL

------------------------------------------------------------------------------------
-- 03) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 005-A.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '005-A';
	DECLARE @Dos DATETIME = '01-01-2024'; -- GETDATE();

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
		PRINT('No Measure loaded for 005-A.  Cannot continue.');
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
		-- measure code denominators
		 (@MeasureId,'DG1P1','I11.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.814',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.9',NULL,@Dos,NULL)

		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99426',NULL,@Dos,NULL)
 
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','M1151',NULL,@Dos,'Denominator EXCLUSION: Patients with a history of heart transplant or with a Left Ventricular Assist Device (LVAD). ')
		,(@MeasureId,'HCPCS','G2092',NULL,@Dos,'Performance Met: Angiotensin Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) therapy prescribed or currently being taken. ')
		,(@MeasureId,'HCPCS','G2096',NULL,@Dos,'Performance Not Met: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) therapy was not prescribed, reason not given. ')
		,(@MeasureId,'HCPCS','G2093',NULL,@Dos,'Denominator Exception: Documentation of medical reason(s) for not prescribing ACE inhibitor or ARB or ARNI therapy (e.g., hypotensive patients who are at immediate risk of cardiogenic shock, hospitalized patients who have experienced marked azotemia, allergy, intolerance, other medical reasons) ')
		,(@MeasureId,'HCPCS','G2094',NULL,@Dos,'Denominator Exception: Documentation of patient reason(s) for not prescribing ACE inhibitor or ARB or ARNI therapy (e.g., patient declined, other patient reasons) ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Is there at least one additional patient encounter during performance period (CPT)?')
		,(@MeasureId,'DQ411','M1150',NULL,@Dos,'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: M1150?')
		--,(@MeasureId,'DQ411','00003',NULL,@Dos,'Is there NO Patient history of heart transplant or with a Left Ventricular Assist Device (LVAD): M1151?')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		
		; -- expect 61 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '005-A' -- = 202
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 202
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 202
--commit tran;
*/
-- End of 03) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 005-A.SQL
GO

-- Start of 04) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 005-B.SQL

------------------------------------------------------------------------------------
-- 04) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 005-B.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '005-B';
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
		PRINT('No Measure loaded for 005-B.  Cannot continue.');
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
		-- measure code denominators
		 (@MeasureId,'DG1P1','I11.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.814',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.9',NULL,@Dos,NULL)

		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','M1151',NULL,@Dos,'Denominator EXCLUSION: Patients with a history of heart transplant or with a Left Ventricular Assist Device (LVAD) ')
		,(@MeasureId,'HCPCS','G2092',NULL,@Dos,'Performance Met: Angiotensin Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) therapy prescribed or currently being taken. ')
		,(@MeasureId,'HCPCS','G2096',NULL,@Dos,'Performance Not Met: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) therapy was not prescribed, reason not given. ')
		,(@MeasureId,'HCPCS','G2093',NULL,@Dos,'Denominator Exception: Documentation of medical reason(s) for not prescribing ACE inhibitor or ARB or ARNI therapy (e.g., hypotensivepatients who are at immediate risk of cardiogenic shock, hospitalized patients who have experienced marked azotemia, allergy, intolerance, other medical reasons) ')
		,(@MeasureId,'HCPCS','G2094',NULL,@Dos,'Denominator Exception: Documentation of patient reason(s) for not prescribing ACE inhibitor or ARB or ARNI therapy (e.g., patient declined, other patient reasons) ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','M1150',NULL,@Dos,'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function? ')
		--,(@MeasureId,'DQ411','M1151',NULL,@Dos,'NO Patient history of heart transplant or with a Left Ventricular Assist Device (LVAD): M1151? ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 31 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '005-B' -- = 203
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 203
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 203
--commit tran;
*/
-- End of 04) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 005-B.SQL
GO

-- Start of 05) DACS-3477 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3477 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 005, there are 2 valid decision paths.  the data is stored by PQRS# '005-A' and '005-B' for example.  This script is designed around this example.
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	--IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	--BEGIN
	--	PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	--IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	--BEGIN
	--	PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis in our inclusive diagnosis listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '005-A' -- = 202
begin tran; -- testing
*/
-- End of 05) DACS-3477 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005A].SQL
GO

-- Start of 06) DACS-3477 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3477 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 005, there are 2 valid decision paths.  the data is stored by PQRS# '005-A' and '005-B' for example.  This script is designed around this example.
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	--IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	--BEGIN
	--	PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	--IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	--BEGIN
	--	PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis in our inclusive diagnosis listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT'
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '005-B' -- = 203
begin tran; -- testing
*/
-- End of 06) DACS-3477 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type005B].SQL
GO

-- Start of 01) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 118-A.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 118-A.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '118-A';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('!!!!! Updating...');

		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF ≤ 40%) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF CAD WITH LVEF ≤ 40% (WITHOUT A DIAGNOSIS OF DIABETES)) : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have diabetes OR a current or prior Left Ventricular Ejection Fraction (LVEF) ≤ 40% who were prescribed ACE inhibitor or ARB therapy. '
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' : Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF ≤ 40%) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF CAD WITH LVEF ≤ 40% (WITHOUT A DIAGNOSIS OF DIABETES)) : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have diabetes OR a current or prior Left Ventricular Ejection Fraction (LVEF) ≤ 40% who were prescribed ACE inhibitor or ARB therapy. '	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);
	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-A' -- = 199
*/
-- End of 01) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 118-A.SQL
GO

-- Start of 02) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 118-B.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 118-B.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '118-B';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('!!!!! Updating...');

		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF ≤ 40%) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF CAD WHO HAVE DIABETES) : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have diabetes OR a current or prior Left Ventricular Ejection Fraction (LVEF) ≤ 40% who were prescribed ACE inhibitor or ARB therapy. '	
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' : Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF ≤ 40%) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF CAD WHO HAVE DIABETES) : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have diabetes OR a current or prior Left Ventricular Ejection Fraction (LVEF) ≤ 40% who were prescribed ACE inhibitor or ARB therapy. '	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);
	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-B' -- = 200
*/
-- End of 02) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 118-B.SQL
GO

-- Start of 03) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-A.SQL

------------------------------------------------------------------------------------
-- 03) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-A.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '118-A';
	DECLARE @Dos DATETIME = '01-01-2024'; -- GETDATE();

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
		PRINT('No Measure loaded for 118-A.  Cannot continue.');
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
		-- Diagnosis for coronary artery disease (ICD-10-CM):
		 (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.A9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.702',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','I25.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.712',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.722',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.732',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','I25.738',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.752',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.762',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','I25.790',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.792',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','Z95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',NULL,@Dos,NULL)

		-- Patient encounter during the performance period (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99426',NULL,@Dos,NULL) 
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8935',NULL,@Dos,'Performance Met: Clinician prescribed angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy. ')
		,(@MeasureId,'HCPCS','G8937',NULL,@Dos,'Performance Not Met: Clinician did not prescribe angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy, reason not given. ')
		,(@MeasureId,'HCPCS','G8936',NULL,@Dos,'Denominator Exception: Clinician documented that patient was not an eligible candidate for angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy (e.g., allergy, intolerance, pregnancy, renal failure due to ACE inhibitor, diseases of the aortic or mitral valve, other medical reasons) or (e.g., patient declined, other patient reasons). ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Is there at least one additional patient encounter during performance period (CPT)?')
		,(@MeasureId,'DQ411','G8934',NULL,@Dos,'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: G8934?')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		
		; -- expect 111 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-A' -- = 199
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 199
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 199
--commit tran;
*/
-- End of 03) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-A.SQL
GO

-- Start of 04) DACS-3423 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-B.SQL

------------------------------------------------------------------------------------
-- 04) DACS-3423 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-B.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '118-B';
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
		PRINT('No Measure loaded for 118-B.  Cannot continue.');
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
		-- Diagnosis for coronary artery disease (ICD-10-CM)
		 (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.A9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.702',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.712',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.722',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.732',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.752',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.762',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.792',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','Z95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',NULL,@Dos,NULL)

		-- Patient encounter during the performance period (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99426',NULL,@Dos,NULL)

		-- Diagnosis for diabetes (ICD-10-CM)
		,(@MeasureId,'DG2P1','E10.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.649',NULL,@Dos,NULL) 
		,(@MeasureId,'DG2P1','E10.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E10.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.52',NULL,@Dos,NULL) 
		,(@MeasureId,'DG2P1','E11.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.649',NULL,@Dos,NULL) 
		,(@MeasureId,'DG2P1','E11.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E11.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','E13.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.013',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.02',NULL,@Dos,NULL)             
		,(@MeasureId,'DG2P1','O24.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.113',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.13',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.312',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.313',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.811',NULL,@Dos,NULL) 
		,(@MeasureId,'DG2P1','O24.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.813',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.819',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','O24.83',NULL,@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8473',NULL,@Dos,'Performance Met: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy prescribed. ')
		,(@MeasureId,'HCPCS','G8475',NULL,@Dos,'Performance Not Met: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy not prescribed, reason not given. ')
		,(@MeasureId,'HCPCS','G8474',NULL,@Dos,'Denominator Exception: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy not prescribed for reasons documented by the clinician (e.g., allergy, intolerance, pregnancy, renal failure due to ACE inhibitor, diseases of the aortic or mitral valve, other medical reasons) or (e.g., patient declined, other patient reasons). ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Is there at least one additional patient encounter during performance period (CPT)?')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 389 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-B' -- = 200
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 200
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 200
--commit tran;
*/
-- End of 04) DACS-3423 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-B.SQL
GO

-- Start of 05) DACS-3523 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type118A].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3523 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118A] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		--PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	--IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	--BEGIN
	--	PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	--IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	--BEGIN
	--	PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-A' -- = 199
begin tran; -- testing
*/
-- End of 05) DACS-3523 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type118A].SQL
GO

-- Start of 06) DACS-3523 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type118B].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3523 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type118B] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		--PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	--IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	--BEGIN
	--	PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	--IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	--BEGIN
	--	PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	--END;

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for diabetes (ICD-10-CM) listing?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT'
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-B' -- = 200
begin tran; -- testing
*/
-- End of 06) DACS-3523 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByTwoCriteriaAndCoderResponse_Type118B].SQL
GO

-- Start of 01) DACS-3524 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 047.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3524 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 047.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '047';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('!!!!! Updating...');

		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Advance Care Plan : Percentage of patients aged 65 years and older who have an advance care plan or surrogate decision maker documented in the medical record or documentation in the medical record that an advance care plan was discussed but the patient did not wish or was not able to name a surrogate decision maker or provide an advance care plan. '
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' : Advance Care Plan : Percentage of patients aged 65 years and older who have an advance care plan or surrogate decision maker documented in the medical record or documentation in the medical record that an advance care plan was discussed but the patient did not wish or was not able to name a surrogate decision maker or provide an advance care plan. '	
				,'B'
				,65
				,999
				,@Dos
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);
	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '047' -- = 1231
*/
-- End of 01) DACS-3524 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 047.SQL
GO

-- Start of 02) DACS-3524 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 047.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3524 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 047.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '047';
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
		PRINT('No Measure loaded for ' + @PqrsCd + '.  Cannot continue.');
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
		-- Diagnosis (ICD-10-CM): -- none at present
		-- (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)

		-- Patient encounter during the performance period (CPT or HCPCS)
		 (@MeasureId,'DG1P2','90791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90832',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90834',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90837',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90845',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90846',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90847',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0402',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0438',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0439',NULL,@Dos,NULL)

		-- measure code numerators
		,(@MeasureId,'HCPCS','G9692',NULL,@Dos,'Denominator EXCLUSION: Hospice services received by patient any time during the measurement period. ')
		,(@MeasureId,'HCPCS','1123F',NULL,@Dos,'Performance Met: Advance Care Planning discussed and documented; advance care plan or surrogate decision maker documented in the medical record. ')
		,(@MeasureId,'HCPCS','1124F',NULL,@Dos,'Performance Met: Advance Care Planning discussed and documented in the medical record; patient did not wish or was notable to name a surrogate decision maker or provide an advance care plan. ')
		,(@MeasureId,'HCPCS','1123F','8P',@Dos,'Performance Not Met: Advance Care Planning not documented, reason not otherwise specified. <p><strong>Definition:</strong></p><p><strong>Documentation that Patient did not Wish or was not able to Name a Surrogate Decision Maker or Provide an Advance Care Plan</strong> – May also include: <ul><li>That the patient’s cultural and/or spiritual beliefs preclude a discussion of advance care planning, and thus harmful to the physician-patient relationship.</li></ul></p>')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		
		; -- expect 49 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '047' -- = 1231
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 1231
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 1231
--commit tran;
*/
-- End of 02) DACS-3524 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 047.SQL
GO

-- Start of 03) DACS-3524 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3524 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
 
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
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
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('1') OR [LOCATION_OF_SERVICE] IN ('23'))
		)
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId CANNOT have a valid patient class type of (1) OR Location of Service of (23).', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	-- at present no diagnosis codes to check
	-- SELECT 
		  -- cdc.ICD10_CODE
		-- , sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		-- , cdc.DIAGNOSIS_TYPE_ID
		-- , cdc.IS_PRIMARY
		-- , c.Time_of_Service
	-- INTO 
		-- #tempDiagnosisList
	-- FROM 
		-- CHART_DIAGNOSIS_CODE_ICD10 cdc
		-- INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		-- INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	-- IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	-- --IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	-- --BEGIN
	-- --	PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- --END;

	-- IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	-- BEGIN
		-- SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		-- RETURN;
	-- END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	--DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	-- IF @foundDenominatorGroup1Pick1MatchCount <= 0
	-- BEGIN
		-- --PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		-- RETURN;
	-- END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis (ICD-10-CM) listing?
	-- SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	-- IF @foundDenominatorGroup1Pick1MatchCount <= 0
	-- BEGIN 
		-- --PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		-- RETURN;
	-- END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		--AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '047' -- = 1231
begin tran; -- testing

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047
	@ChartId = 2100113491
	,@PqrsNum = '047'
*/
-- End of 03) DACS-3524 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type047].SQL
GO

-- Start of 01) DACS-3454 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 001.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3454 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 001.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '001';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('!!!!! Updating...');

		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Diabetes: Hemoglobin A1c (HbA1c) Poor Control (>9%) : Percentage of patients 18-75 years of age with diabetes who had hemoglobin A1c > 9.0% during the measurement period. '
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' :  Diabetes: Hemoglobin A1c (HbA1c) Poor Control (>9%) : Percentage of patients 18-75 years of age with diabetes who had hemoglobin A1c > 9.0% during the measurement period.'	
				,'B'
				,18
				,75
				,@Dos
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);
	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '001' -- = 1232
*/
-- End of 01) DACS-3454 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 001.SQL
GO

-- Start of 02) DACS-3454 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 001.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3454 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 001.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '001';
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
		PRINT('No Measure loaded for ' + @PqrsCd + '.  Cannot continue.');
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
		-- Diagnosis for diabetes (ICD-10-CM)
		 (@MeasureId,'DG1P1','E10.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E10.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E11.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.37X',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.37X3',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','E13.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','E13.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.013',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.03',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.13',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.813',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.819',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','O24.83',NULL,@Dos,NULL)

		-- Patient encounter during the performance period (CPT or HCPCS)
		,(@MeasureId,'DG1P2','97802',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97803',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97804',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99385',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99386',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99387',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99395',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99396',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99397',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0270',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0271',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0438',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0439',NULL,@Dos,NULL)

		-- measure code numerators
		,(@MeasureId,'HCPCS','G9687',NULL,@Dos,'Denominator EXCLUSION: Hospice services provided to patient any time during the measurement period. ')
		,(@MeasureId,'HCPCS','G2081',NULL,@Dos,'Denominator EXCLUSION: Patients age 66 and older in Institutional Special Needs Plans (SNP) or residing in long-term care with a POS code 32, 33, 34, 54 or 56 for more than 90 consecutive days during the measurement period. ')
		,(@MeasureId,'HCPCS','G2090',NULL,@Dos,'Denominator EXCLUSION: Patients 66 years of age and older with at least one claim/encounter for frailty during the measurement period AND a dispensed medication for dementia during the measurement period or the year prior to the measurement period. <p><img src="/WebPages/Images/MIPS/MIPS_001_Table1.png" alt="(G2090) dementia medication table image"></p> ')
		,(@MeasureId,'HCPCS','G2091',NULL,@Dos,'Denominator EXCLUSION: Patients 66 years of age and older with at least one claim/encounter for frailty during the measurement period AND either one acute inpatient encounter with a diagnosis of advanced illness or two outpatient, observation, ED or nonacute inpatient encounters on different dates of service with an advanced illness diagnosis during the measurement period or the year prior to the measurement period. ')
		,(@MeasureId,'HCPCS','M1211',NULL,@Dos,'Performance Met: Most recent hemoglobin A1c level > 9.0%. ')
		,(@MeasureId,'HCPCS','M1212',NULL,@Dos,'Performance Met: Hemoglobin A1c level is missing, or was not performed during the measurement period (12 months). ')
		,(@MeasureId,'HCPCS','3044F',NULL,@Dos,'Performance Not Met: Most recent hemoglobin A1c (HbA1c) level < 7.0%. ')
		,(@MeasureId,'HCPCS','3051F',NULL,@Dos,'Performance Not Met: Most recent hemoglobin A1c (HbA1c) level greater than or equal to 7.0% and less than 8.0%. ')
		,(@MeasureId,'HCPCS','3052F',NULL,@Dos,'Performance Not Met: Most recent hemoglobin A1c (HbA1c) level greater than or equal to 8.0% and less than or equal to 9.0%. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G9988',NULL,@Dos,'Was Palliative care services provided to patient any time during the measurement period? (G9988) ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		
		; -- expect 318 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '001' -- = 1232
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 1232
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 1232
--commit tran;
*/
-- End of 02) DACS-3454 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 001.SQL
GO

-- Start of 03) DACS-3454 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3454 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
 
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
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
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	 
	----------------
	-- Present Diagnosis List 
	----------------
	-- at present no diagnosis codes to check
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis (ICD-10-CM) listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for diabetes (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		--AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '001' -- = 1232
begin tran; -- testing

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001
	@ChartId = 2100113491
	,@PqrsNum = '001'
*/
-- End of 03) DACS-3454 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type001].SQL
GO

-- Start of 01) DACS-3476 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 066.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3476 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 066.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '066';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
			,'MIPS# ' + @PqrsCd + ' : Appropriate Testing for Pharyngitis : The percentage of episodes for patients 3 years and older with a diagnosis of pharyngitis that resulted in an antibiotic order on or within 3 days after the episode date and a group A Streptococcus (Strep) test in the seven-day period from three days prior to the episode date through three days after the episode date. '	
			,'B'
			,3
			,999
			,'2024-01-01'
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '066' -- = 1230
*/
-- End of 01) DACS-3476 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 066.SQL
GO

-- Start of 02) DACS-3476 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 066.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3476 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 066.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '066';
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
		-- Diagnosis for pharyngitis or tonsillitis (ICD-10-CM)
		 (@MeasureId,'DG1P1','J02.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J02.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J02.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J03.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J03.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J03.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J03.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J03.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J03.91',NULL,@Dos,NULL)
		
		-- Patient encounter during performance period (CPT)
		,(@MeasureId,'DG1P2','98966',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98967',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98968',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P2','99382',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99383',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99384',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99385',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99386',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99387',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99394',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99395',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99396',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99397',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99421',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P2','99422',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99423',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99457',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98980',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G2250',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G2251',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G2252',NULL,@Dos,NULL)

		-- measure code numerators
		,(@MeasureId,'HCPCS','G9703',NULL,@Dos,'DENOMINATOR EXCLUSIONS: Episodes where the patient is taking antibiotics (Table 1) in the 30 days prior to the episode date. ')
		,(@MeasureId,'HCPCS','G2175',NULL,@Dos,'DENOMINATOR EXCLUSIONS: Episodes where the patient had a comorbid condition during the 12 months prior to or on the episode date (e.g., tuberculosis, neutropenia, cystic fibrosis, chronic bronchitis, pulmonary edema, respiratory failure, rheumatoid lung disease). ')
		,(@MeasureId,'HCPCS','G2097',NULL,@Dos,'DENOMINATOR EXCLUSIONS: Episodes where the patient had a competing diagnosis on or within three days after the episode date (e.g., intestinal infection, pertussis, bacterial infection, Lyme disease, otitis media, acute sinusitis, chronic sinusitis, infection of the adenoids, prostatitis, cellulitis, mastoiditis, or bone infections, acute lymphadenitis, impetigo, skin staph infections, pneumonia/gonococcal infections, venereal disease, infections of the kidney, cystitis or UTI). ')
		,(@MeasureId,'HCPCS','G9702',NULL,@Dos,'DENOMINATOR EXCLUSIONS: Patients who use hospice services any time during the measurement period. ')
		,(@MeasureId,'HCPCS','3210F',NULL,@Dos,'Performance Met: Group A Strep Test Performed. ')
		,(@MeasureId,'HCPCS','3210F','8P',@Dos,'Performance Not Met: Group A Strep Test not Performed, reason not otherwise specified. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G8711',NULL,@Dos,'Prescribed antibiotic on or within 3 days after the episode date (G8711)? <p><img src="/WebPages/Images/MIPS/MIPS_066_Table1_AntibioticMeds.png" alt="(G8711) Antibiotic Medication image"></p>')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 70 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '066' -- = 1230
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 1230
*/
-- End of 02) DACS-3476 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 066.SQL
GO

-- Start of 03) DACS-3476 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3476 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NULL SET @PqrsNum = '066';
		
		IF LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		--PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		--PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		--PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 3 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		--PRINT ('Age criteria satisfied to continue comparisons.');
	END;


	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		--PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		--PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('7','8','9') OR [LOCATION_OF_SERVICE] IN ('21'))
		)
	BEGIN 
		SELECT 'Result' = 0, 'Message' = '@ChartId has an excluded Physician service class of (7, 8 or 9) Location of Service value of (21)', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	-- IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	-- BEGIN
		-- PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	-- IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	-- BEGIN
		-- PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for pharyngitis or tonsillitis (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for acute bronchitis/bronchiolitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '066' -- = 1230

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066
	@ChartId = 2100112732
	,@PqrsNum = '066'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3476 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type066].SQL
GO

-- Start of 01) DACS-3222 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR46.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3222 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR46.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ECPR46';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Process'
			,@PqrsCd + ' : Avoidance of Opiate Prescriptions for Low Back Pain or Migraines : Percentage of Patients with Low Back Pain and/or Migraines Who Were Not Prescribed an Opiate. '
			,'B'
			,18
			,999
			,@Dos
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR46' -- = 224
*/
-- End of 01) DACS-3222 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR46.SQL
GO

-- Start of 02) DACS-3222 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR46.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3222 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR46.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ECPR46';
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
		-- Diagnosis of low back pain OR migraine (ICD10)
		 (@MeasureId,'DG1P1','M54.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','M54.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','M54.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.001',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.009',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.101',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.109',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.401',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','G43.409',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.501',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.509',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.601',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.609',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.611',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','G43.619',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.A0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.A1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.B0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.B1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.C0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.C1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.D0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.D1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.801',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.809',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.819',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.821',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.829',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.831',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.839',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.901',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.909',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.911',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.919',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.E01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.E09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.E11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.E19',NULL,@Dos,NULL)

		-- Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99292',NULL,@Dos,NULL)

		-- Disposition of Discharged – (Pseudo Code)
		-- might need to be a question
		--,(@MeasureId,'DG2P1','DG469',NULL,@Dos,NULL)
	 
		-- measure code numerators
		,(@MeasureId,'HCPCS','VE264',NULL,@Dos,'Denominator EXCLUSIONS: Opiate prescribed for medical reason documented by the Eligible Professional (i.e., suspected or diagnosed herniated disk, fracture, sciatica, radiculopathy). <p><img src="/WebPages/Images/MIPS/Mips_ECPR46_AppendixAOpoidMedications.png" alt="(VE264) Appendix - Opoid Medications image"></p> ')
		,(@MeasureId,'HCPCS','VE263',NULL,@Dos,'Performance Met: Opiate not prescribed at discharge. ')
		,(@MeasureId,'HCPCS','VE265',NULL,@Dos,'Performance Not Met: Opiate prescribed, reason not specified. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','DG469',NULL,@Dos,'Patient Disposition of Discharged – (Pseudo Code) (DG469)? ')
		,(@MeasureId,'DQ411','V0709',NULL,@Dos,'Patient does NOT have active cancer, palliative care, or end-of-life care (V0709)? ')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 72 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR46' -- = 224
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 224
*/
-- End of 02) DACS-3222 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR46.SQL
GO

-- Start of 03) DACS-3222 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3222 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;
		
	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF NOT EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('1','2','3','6','7','8','9','11') OR [LOCATION_OF_SERVICE] IN ('02','10','11','19','20','22','23'))
		)
	BEGIN 
		PRINT('@ChartId does not have a valid patient class type of (1, 2, 3, 6, 7, 8, 9 or 11) OR Location of Service of (02, 10, 11, 19, 20, 22, 23) to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid patient class type of (1, 2, 3, 6, 7, 8, 9 or 11) OR Location of Service of (02, 10, 11, 19, 20, 22, 23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	--DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	-- IF @foundDenominatorGroup2Pick1MatchCount <= 0
	-- BEGIN
		-- PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		-- RETURN;
	-- END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis of low back pain (ICD10)?
	-- might end up being and OR canse and not an AND with the next criteria
	-- SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	-- IF @foundDenominatorGroup2Pick1MatchCount <= 0
	-- BEGIN 
		-- PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10))', 'Code' = 'ERR-3-NPE';
		-- RETURN;
	-- END;

	-- do we have any Diagnosis of migraine PLUS (ICD10)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have any Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have a Disposition of Discharged – (Pseudo Code)?
	-- SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	-- IF @foundDenominatorGroup2Pick1MatchCount <= 0
	-- BEGIN 
		-- PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Disposition of Discharged – (Pseudo Code))', 'Code' = 'ERR-3-NPE';
		-- RETURN;
	-- END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	--PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR46' -- = 224

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46
	@ChartId = 2100112304
	,@PqrsNum = 'ECPR46'
	,@Dos = '7/11/2024 2:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3222 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR46].SQL
GO

-- Start of 01) DACS-3223 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR51.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3223 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR51.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ECPR51';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Process'
			,@PqrsCd + ' : Discharge Prescription of Naloxone after Opioid Poisoning or Overdose : Percentage of Opioid Poisoning or Overdose Patients Presenting to An Acute Care Facility Who Were Prescribed Naloxone at Discharge. '
			,'B'
			,0
			,999
			,@Dos
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR51' -- = 225
*/
-- End of 01) DACS-3223 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = ECPR51.SQL
GO

-- Start of 02) DACS-3223 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR51.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3223 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR51.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ECPR51';
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
		-- Diagnosis of opioid poisoning from heroin, methadone, morphine, opium, codeine, hydrocodone, or another opioid substance (ICD10)
		 (@MeasureId,'DG1P1','T40.0X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X1D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X1S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X2D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X2S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X3D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X3S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X4D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X4S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X1D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X1S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X2D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X2S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X3D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X3S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X4D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X4S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X1D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X1S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X2D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X2S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X3D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X3S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X4D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X4S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X1D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X1S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X2D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X2S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X3D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X3S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X4D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X4S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.411A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.411D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.411S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.412A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.412D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.412S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.413A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.413D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.413S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.414A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.414D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.414S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.421A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.421D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.421S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.422A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.422D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.422S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.423A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.423D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.423S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.424A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.424D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.424S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.491A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.491D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.491S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.492A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.492D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.492S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.493A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.493D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.493S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.494A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.494D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.494S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.601A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.601D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.601S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.602A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.602D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.602S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.603A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.603D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.603S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.604A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.604D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.604S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.691A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.691D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.691S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.692A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.692D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.692S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.693A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.693D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.693S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.694A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.694D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.694S',NULL,@Dos,NULL)

		-- Eligible Professional in  Eligible Professional in acute care settings (CPT)
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
	 
		-- measure code numerators
		,(@MeasureId,'HCPCS','VE269',NULL,@Dos,'Performance Met: Naloxone was prescribed at discharge AND patient was educated about use. *NOTE: Distribution of Naloxone to patient at discharge is also acceptable in lieu of Naloxone prescription')
		,(@MeasureId,'HCPCS','VE271',NULL,@Dos,'Performance Not Met: Naloxone medication was not prescribed at discharge OR patient was not educated about use. ')
		,(@MeasureId,'HCPCS','VE270',NULL,@Dos,'Denominator Exception: Naloxone was not prescribed at discharge due to medical reasons such as allergy. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','DG519',NULL,@Dos,'Patient has Disposition of Discharged (Pseudo code - DG519)? ')
		,(@MeasureId,'DQ411','V0700',NULL,@Dos,'Patient did NOT Transfer, elope or is an AMA patients (V0700)? ')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 124 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR51' -- = 225
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 225
*/
-- End of 02) DACS-3223 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR51.SQL
GO

-- Start of 03) DACS-3223 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3223 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;
		
	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	-- No age restrictions at this time.
	-- PRINT ('Age criteria satisfied to continue comparisons.');

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF NOT EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('1','2','3','6','7','8','9','11') OR [LOCATION_OF_SERVICE] IN ('02','21','22','23'))
		)
	BEGIN 
		PRINT('@ChartId does not have a valid patient class type of (1, 2, 3, 6, 7, 8, 9 or 11) OR Location of Service of (02, 21, 22, 23) to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid patient class type of (1, 2, 3, 6, 7, 8, 9 or 11) OR Location of Service of (02, 21, 22, 23) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have any Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis of low back pain OR Diagnosis of migraine PLUS (ICD10))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have any Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR51' -- = 225

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51
	@ChartId = 2100112304
	,@PqrsNum = 'ECPR51'
	,@Dos = '7/11/2024 2:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3223 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeECPR51].SQL
GO

-- Start of 01) DACS-3365 Remove Denial User Group and Group Rights.sql

----------------------------------------
-- 01) DACS-3365 - SQL Script will Delete Denial group Rights and Denial User Group
----------------------------------------

GO

BEGIN TRY
    DECLARE @USER_GROUP_ID INT
    DECLARE @CODER_USER_GROUP_ID INT

    SELECT @USER_GROUP_ID = user_group_id FROM dbo.user_group WHERE name = 'Denial Management Administration'

    --DELETE ALL GROUP RIGHTS FOR DENIAL MGMT ADMIN
    DELETE FROM [DBO].[group_rights]
    WHERE user_group_id = @USER_GROUP_ID

    --Remove additional group assignment for this user group
    DELETE FROM [dbo].[USER_GROUP_TO_USER_PROFILE]
    WHERE user_group_id = @USER_GROUP_ID 
       
    SELECT @CODER_USER_GROUP_ID = user_group_id  FROM dbo.user_group WHERE name = 'Coders'

	SELECT * FROM [dbo].[user_profile] WHERE user_group_id = @USER_GROUP_ID

    UPDATE [dbo].[user_profile]
    SET user_group_id = @CODER_USER_GROUP_ID
    WHERE 
    user_group_id = @USER_GROUP_ID

    PRINT 'Verify all denial users are updated to Coders user group'

    SELECT COUNT(*) FROM [dbo].[user_profile] WHERE user_group_id = @USER_GROUP_ID

	--DELETE DENIAL MGMT ADMIN USER GROUP
    DELETE FROM [dbo].[user_group]
    WHERE user_group_id = @USER_GROUP_ID

    SELECT @USER_GROUP_ID = user_group_id FROM dbo.user_group WHERE name = 'Denial Management Administration 2'

	--Remove additional group assignment for this user group
    DELETE FROM [dbo].[USER_GROUP_TO_USER_PROFILE]
    WHERE user_group_id = @USER_GROUP_ID 

    --DELETE DENIAL MGMT ADMIN USER GROUP
    DELETE FROM [dbo].[user_group]
    WHERE user_group_id = @USER_GROUP_ID

    COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
-- End of 01) DACS-3365 Remove Denial User Group and Group Rights.sql
GO

-- Start of 02) DACS-3365 Remove Denial from Reports Avilable to Group.sql

----------------------------------------
-- 02) DACS-3365 - SQL Script will Delete Denial group Rights for reports for user groups
----------------------------------------

GO

BEGIN TRY
    DECLARE @PORTAL_REPORT_ID INT

	SELECT TOP 1 @PORTAL_REPORT_ID = portal_report_id FROM PORTAL_REPORT where name = 'Denials Monthly Reporting'

	DELETE FROM USER_GROUP_TO_PORTAL_REPORT WHERE portal_report_id = @PORTAL_REPORT_ID

    DELETE FROM PORTAL_REPORT where name = 'Denials Monthly Reporting'

    COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
-- End of 02) DACS-3365 Remove Denial from Reports Avilable to Group.sql
GO

-- Start of 03) DACS-3365 Remove Denial from ReportServer.sql

----------------------------------------
-- 03) DACS-3365 - SQL Script will Delete Denial entry from Catalog table
----------------------------------------

GO

BEGIN TRY    
    DECLARE @ITEM_ID uniqueidentifier

    SELECT @ITEM_ID = ItemId FROM [dbo].[Catalog] where name = 'Denial Billing Summary'

    DELETE FROM dbo.DataSource WHERE ITEMID = @ITEM_ID

    DELETE FROM [dbo].[Catalog] where ITEMID = @ITEM_ID

    COMMIT TRANSACTION;   
END TRY  
   BEGIN CATCH  
    ROLLBACK TRANSACTION;    
    DECLARE @ERROR_MESSAGE VARCHAR(4000) = (SELECT Error_Message());  
  
    THROW 50001 , @ERROR_MESSAGE, 1  
END CATCH  
-- End of 03) DACS-3365 Remove Denial from ReportServer.sql
GO

-- Start of 01) DACS-3227 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR1.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3227 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR1.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR1';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Process'
			,@PqrsCd + ' : High Intensity Statin Prescribed for Acute and Subacute Ischemic Stroke and Transient Ischemic Attack (TIA) : Acute and subacute ischemic stroke and confirmed Transient Ischemic Attack (TIA) patients prescribed or continuing to take a high intensity statin at time of hospital discharge. '
			,'B'
			,18
			,999
			,@Dos
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR1' -- = 222
*/
-- End of 01) DACS-3227 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR1.SQL
GO

-- Start of 02) DACS-3227 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR1.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3227 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR1.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR1';
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
		-- (ICD‐10)
		 (@MeasureId,'DG1P1','G45.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G45.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.013',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.031',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.032',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.033',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.039',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.131',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.132',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.133',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.139',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.321',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.322',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.323',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.329',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.331',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.332',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.333',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.339',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.343',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.421',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','I63.422',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.423',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.429',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.431',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.432',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.433',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.439',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.441',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.442',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.443',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.449',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I67.82',NULL,@Dos,NULL)

		-- (CPT)
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		 
		-- measure code numerators
		,(@MeasureId,'HCPCS','DG036',NULL,@Dos,'Performance Met: High-Intensity Statin prescribed or currently being taken. ')
		,(@MeasureId,'HCPCS','DG037',NULL,@Dos,'Performance Not Met: High-Intensity Statin neither prescribed or active - Reason not given. ')
		,(@MeasureId,'HCPCS','DG038',NULL,@Dos,'Denominator Exception: Documented medical reason for exclusion - Patient Refusal. <p><strong>HIGH-Intensity STATIN Medication List and Dosage:</strong><ul><li>Atorvastatin or Lipitor ≥40mg per day, OR</li><li>Rosuvastatin or Crestor or Ezallor ≥20 mg per day</li></ul></p> ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','DG848',NULL,@Dos,'Patient does <strong>NOT</strong> have any of the following Exclusion items (DG848)? <ul><li>Chronic stroke</li><li>Enrolled in clinical trial</li><li>Transferred</li><li>Eloped or left AMA</li><li>Expired</li><li>Comfort measures documented</li><li>Discharged to hospice</li></ul> ')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 104 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR1' -- = 222
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 222
*/
-- End of 02) DACS-3227 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR1.SQL
GO

-- Start of 03) DACS-3227 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3227 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		--AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data check.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF NOT EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('7','8','9') OR [LOCATION_OF_SERVICE] IN ('21'))
		)
	BEGIN 
		PRINT('@ChartId does not have a valid patient class type of (7,8,9) OR Location of Service of (21) to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid patient class type of (7,8,9) OR Location of Service of (21) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;
	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have an (ICD-10)?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (ICD-10)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CPT)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR1' -- = 222
select top 200 * from CMS_PQRI_MEASURE_code where CMS_PQRI_MEASURE_ID = 222

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1
	@ChartId = 2100112636
	,@PqrsNum = 'THEPQR1'
	,@Dos = '7/11/2024 2:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3227 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR1].SQL
GO

-- Start of 01) DACS-3230 - Script - Modify (20240714 doc changes) [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = THEPQR4.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3230 - Script - Modify (20240714 doc changes) [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = THEPQR4.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR4';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [REQ_2_DX_OR_3CPT] = 1
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 'THEPQR4'
				,'Process'
				,'THEPQR4 : Consultation to Palliative Care for Patients with End Stage Conditions : The measure will identify patients with end stage diagnoses who meet any of the listed criteria for a palliative care consult. '	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);
	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR4' -- = 212
*/
-- End of 01) DACS-3230 - Script - Modify (20240714 doc changes) [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = THEPQR4.SQL
GO

-- Start of 02) DACS-3230 - Script - Modify (20240714 doc changes) [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR4.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3230 - Script - Modify (20240714 doc changes) [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR4.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'THEPQR4';
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
		PRINT('No Measure loaded for THEPQR4.  Cannot continue.');
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
	
		-- Has encounter who have one of the of the following conditions (Primary Criteria): Refer codeset document for ICD10 codes (ICD10)
		 (@MeasureId,'DG1P1','C79.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C95.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C80.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.28',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z85.72',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C77.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C95.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C77.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C77.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C77.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C95.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.99',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C82.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C77.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z85.71',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C95.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.60',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C93.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.93',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.91',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C96.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C93.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.70',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C77.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.38',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C77.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.61',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.70',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','M72.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.A0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C94.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.98',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.Z0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C77.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.91',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C82.93',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C90.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C95.92',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.99',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C86.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C86.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.62',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.72',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.94',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.18',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.37',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.60',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.A3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.92',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C94.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.07',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.48',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.97',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C94.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C22.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.60',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.70',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.92',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.93',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C82.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C82.95',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.03',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.16',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.54',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C84.A9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.95',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.96',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C86.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C86.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.60',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.A0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.62',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C93.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C94.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C95.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.76',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C93.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C90.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.Z0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.13',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C85.94',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C78.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.71',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.79',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C82.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C96.A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C92.60',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C43.71',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.04',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C83.14',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C79.72',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C81.97',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C82.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C82.99',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','C91.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z99.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I12.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I12.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','N18.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I11.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I42.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I42.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I42.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.813',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I42.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I09.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.814',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I42.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J44.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J44.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J96.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J43.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J44.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J96.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J98.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J96.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J96.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J66.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J96.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J96.92',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J43.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J84.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J43.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J43.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J61',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J43.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J66.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J62.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J62.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J67.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J60',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J67.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J63.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J64',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J67.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J63.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J66.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J68.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J98.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J63.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F03.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G30.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G80.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F02.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G70.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G70.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G31.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G12.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F01.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G30.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G30.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G37.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G30.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G31.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G21.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G37.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G23.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G80.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G80.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G31.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G23.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G12.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G80.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G11.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G23.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F10.27',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G31.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G40.834',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G11.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G21.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G37.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F10.97',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G12.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G80.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G12.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G37.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','A81.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G12.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G80.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','A81.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','A81.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G11.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G11.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G12.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G12.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G23.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G23.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G37.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G40.833',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G70.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G80.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G13.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F03.91',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G45.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G45.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I67.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.331',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.439',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.441',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.431',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.039',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.032',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.432',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.031',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.322',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.332',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.033',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.421',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.429',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.442',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.333',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.443',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.423',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.133',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.449',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.339',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.139',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.132',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.422',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.131',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.343',NULL,@Dos,NULL)
	
		-- Has encounter during the performance period (CPT)
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)
 		
		-- measure code numerators
		,(@MeasureId,'HCPCS','QR307',NULL,@Dos,'Denominator EXCLUSION: <ul><li>Patient on hospice, or discharged to hospice.</li><li>Eloped or left AMA.</li><li>Expired</li><li>Comfort measures documented (Documented code status of DNR-A)</li><li>Transferred to another hospital</li><li>Patient admission to psychiatric or behavioral care</li></ul> (PQR307) ')
		,(@MeasureId,'HCPCS','QR309',NULL,@Dos,'Performance Met:  Patient received order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service (PQR309) ')
		,(@MeasureId,'HCPCS','QR310',NULL,@Dos,'Performance Not Met:  Patient did not receive an order for palliative care by discharge or had a palliative care consult documented within the past 12 months from date of service (PQR310) ')
		,(@MeasureId,'HCPCS','QR308',NULL,@Dos,'Denominator Exception: <ul><li>Patient or medical decision maker refusal.</li><li>Documented medical reason for exclusion (example: palliative care not appropriate).</li><li>Palliative care not available, or system issue preventing palliative care consult.</li></ul> (PQR308) ')
				
		-- PQRS Question for response by coder within ACS		
		-- handled above by icd 10 codes.  may become question... leaving just in case
		--,(@MeasureId,'DQ411','00001',NULL,@Dos,'Patient has any of the following? <ul><li>Cancer</li><li>Stroke or TIA</li><li>Chronic obstructive pulmonary disease (COPD)</li><li>Neurodegenerative Disease</li><li>Congestive Heart Failure (CHF)</li><li>Kidney Failure (ESRD)</li></ul> ')
		,(@MeasureId,'DQ411','00002',NULL,@Dos,'Patient has any of the following? <ul><li>2+ same diag ED or hospitalizations in 12 months (PQR301)</li><li>Chronic oxygen, or Vent (PQR302)</li><li>Hospital Admit from LTC Fac (PQR303)</li><li>Stage 4/Metastatic cancer (PQR304)</li><li>Difficult to control phys symptoms (PQR305)</li><li>Complex care requirements (PQR306): <ul><li>Home infusion</li><li>Tube feeding</li><li>mechanical Vent</li><li>24hr Bedbound care</li></ul></li><li>(SDOH) (ICD10): Z55, Z56, Z59, Z60, Z64, Z65</li></ul> ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 418 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR4' -- = 212
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 212
*/
-- End of 02) DACS-3230 - Script - Modify (20240714 doc changes) [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR4.SQL
GO

-- Start of 03) DACS-3230 - Create or Alter Stored Procedure (20240714 doc changes) - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3230 - Create or Alter Stored Procedure (20240714 doc changes) - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			--PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			--PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			--PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	DECLARE @chartPatientClassId INT = (SELECT TOP 1 PATIENT_CLASS_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartPatientClassId =' = @chartPatientClassId; -- testing
	IF @chartPatientClassId IS NULL OR @chartPatientClassId <= 0
	BEGIN 
		--PRINT('@ChartId does not have a valid patient class id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid patient class id to test';
	END;
		
	DECLARE @chartSAId INT = (SELECT TOP 1 SERVICE_AGREEMENT_ID FROM #tempChartInfo);
	IF @ShowDebug <> 0 SELECT '@chartSAId =' = @chartSAId; -- testing
	IF @chartSAId IS NULL OR @chartSAId <= 0
	BEGIN 
		--PRINT('@ChartId does not have a valid service agreement id to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid service agreement id to test';
	END;
	
	IF NOT EXISTS 
		(
			SELECT TOP 1 
				PATIENT_CLASS_ID 
			FROM 
				[dbo].[PATIENT_CLASS] 
			WHERE 
				PATIENT_CLASS_ID = @chartPatientClassId 
				AND SERVICE_AGREEMENT_ID = @chartSAId
				AND (PHYSICIAN_SERVICE_CLASS_CD IN ('1','2','3','6','7','8','9','11','12','13') OR [LOCATION_OF_SERVICE] IN ('21','22','23','31','32','33'))
		)
	BEGIN 
		-- PRINT('@ChartId does not have a valid patient class type of ED to test : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Result' = 0, 'Message' = '@ChartId does not have a valid PHYSICIAN_SERVICE_CLASS_CD IN (1,2,3,6,7,8,9,11,12,13) OR [LOCATION_OF_SERVICE] IN (21,22,23,31,32,33) to test', 'Code' = 'ERR-0-AED';
		RETURN;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	-- IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	-- BEGIN
		-- PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	-- IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	-- BEGIN
		-- PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	-- END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis in our inclusive diagnosis listing?
	 SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	 IF @foundDenominatorGroup1Pick1MatchCount <= 0
	 BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	-- PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'THEPQR4' -- = 212

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4
	@ChartId = 2100111832
	,@PqrsNum = 'THEPQR4'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/
-- End of 03) DACS-3230 - Create or Alter Stored Procedure (20240714 doc changes) - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_TypeTHEPQR4].SQL
GO

-- Start of 01) DACS-3450 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 134 (old).SQL

------------------------------------------------------------------------------------
-- 01) DACS-3450 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 134 (old).SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '134';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
	INSERT INTO [dbo].[CMS_PQRI_MEASURE]
		(
			 [PQRS#]
			,[MEASURE_TOPIC]
			,[MEASURE_TITLE]
			,[GENDER]
			,[FROM_AGE]
			,[TO_AGE]
			,[EFFECTIVE_DATE]
			,[EXPIRATION_DATE]
			,[REQUIRES_EM_ONLY]
			,[FROM_AGE_FRACTIONAL]
			,[TO_AGE_FRACTIONAL]
			,[MATCH_EM_LEVEL]
			,[REQUIRES_BOTH_CPT_AND_DX]
			,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
			,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
			,[REQUIRES_MULTIPLE_CPTS]
			,[MULTIPLE_CPT_COUNT]
			,[REQUIRES_MULTIPLE_DX]
			,[REQUIRES_CPT_CODE]
			,[REQUIRED_CPT_CODE]
			,[REQ_2_DX_OR_3CPT]
		)
	VALUES
		(
			 @PqrsCd
			,'Process'
			,'MIPS# ' + @PqrsCd + ' : Preventive Care and Screening: Screening for Depression and Follow-Up Plan : Percentage of patients aged 12 years and older screened for depression on the date of the encounter or up to 14 days prior to the date of the encounter using an age-appropriate standardized depression screening tool AND if positive, a follow-up plan is documented on the date of or up to two days after the date of the qualifying encounter. '
			,'B'
			,12
			,999
			,'2024-01-01'
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,1
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '134' -- = 217
*/
-- End of 01) DACS-3450 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 134 (old).SQL
GO

-- Start of 02) DACS-3450 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 134.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3450 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 134.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '134';
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
		PRINT('No Measure loaded for ' + @PqrsCd + '.  Cannot continue.');
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

		/*
			Not Eligible for Depression Screening or Follow-Up Plan (Denominator Exclusions) – Patients who 
			have been diagnosed with bipolar disorder
			• The following codes would be sufficient to define the Denominator Exclusion of bipolar disorder: 
			F30.2, F30.3, F30.4, F30.8, F30.9, F30.10, F30.11, F30.12, F30.13, F31.0, F31.10, F31.11, F31.12, 
			F31.13, F31.2, F31.30, F31.31, F31.32, F31.4, F31.5, F31.60, F31.61, F31.62, F31.63, F31.64, 
			F31.70, F31.71, F31.72, F31.73, F31.74, F31.75, F31.76, F31.77, F31.78, F31.81, F31.89, F31.9
			• For historical reference purposes these ICD-9 codes if documented would be sufficient to define the 
			Denominator Exclusion of bipolar disorder: 296.00, 296.01, 296.02, 296.03, 296.04, 296.05, 296.06, 
			296.10, 296.11, 296.12, 296.13, 296.14, 296.15, 296.16, 296.40, 296.41, 296.42, 296.43, 296.44, 
			296.45, 296.46, 296.50, 296.51, 296.52, 296.53, 296.54, 296.55, 296.56, 296.60, 296.61, 296.62, 
			296.63, 296.64, 296.65, 296.66, 296.7, 296.80, 296.81, 296.82, 296.89
		*/
		
		 (@MeasureId,'DG1P1','F30.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F30.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F30.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F30.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F30.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F30.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F30.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F30.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F30.13',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.13',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.60',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.61',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.62',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.63',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.64',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.70',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.71',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.72',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.73',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.74',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.75',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.76',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.77',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.78',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','F31.9',NULL,@Dos,NULL)
		-- ignore icd 9s until told otherwise
		-- ,(@MeasureId,'DG1P1','296.00',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.01',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.02',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.03',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.04',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.05',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.06',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.10',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.11',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.12',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.13',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.14',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.15',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.16',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.40',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.41',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.42',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.43',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.44',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.45',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.46',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.50',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.51',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.52',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.53',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.54',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.55',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.56',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.60',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.61',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.62',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.63',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.64',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.65',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.66',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.7',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.80',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.81',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.82',NULL,@Dos,NULL)
		-- ,(@MeasureId,'DG1P1','296.89',NULL,@Dos,NULL)		
			
		-- Patient encounter during the performance period (CPT or HCPCS)
		,(@MeasureId,'DG1P2','59400',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','59510',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','59610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','59618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90792',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90832',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90834',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90837',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','92622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','92625',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96105',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96110',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96116',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96125',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96136',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96138',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96156',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','96158',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97161',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97162',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97163',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97164',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97165',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97166',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97167',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97802',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','97803',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98966',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98967',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','98968',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99078',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99401',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99402',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99403',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99441',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99442',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99443',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99483',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99484',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99384',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99385',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99386',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99387',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99394',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P2','99395',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99396',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99397',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0101',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0270',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0271',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0402',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0438',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0439',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0444',NULL,@Dos,NULL)
		 
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8431',NULL,@Dos,'Performance Met: Screening for depression is documented as being positive AND a follow-up plan is documented. ')
		,(@MeasureId,'HCPCS','G8510',NULL,@Dos,'Performance Met: Screening for depression is documented as negative, a follow-up plan is not required. ')
		,(@MeasureId,'HCPCS','G8432',NULL,@Dos,'Performance Not Met: Depression screening not documented, reason not given. ')
		,(@MeasureId,'HCPCS','G8511',NULL,@Dos,'Performance Not Met: Screening for depression documented as positive, follow-up plan not documented, reason not given. ')
		,(@MeasureId,'HCPCS','G8433',NULL,@Dos,'Denominator Exception: Screening for depression not completed, documented patient or medical reason. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G9717',NULL,@Dos,'Does NOT have Documentation stating the patient has had a diagnosis of bipolar disorder: G9717? ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 129 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '134' -- = 217
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 217
*/
-- End of 02) DACS-3450 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 134.SQL
GO

-- Start of 03) DACS-3450 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3450 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134] 
	  @ChartId INT
	, @MeasureId INT = NULL
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
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
		, PATIENT_CLASS_ID
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		-- AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- USE_TELEHEALTH Chart flag check.  allowable at this revision time

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;

	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	----------------
	-- check PATIENT_CLASS_ID 
	----------------
	-- at present, not needed for this particular MIPS.

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;

	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		--PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		--PRINT('Missing Denominator DQ411 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have Not Eligible for Depression Screening or Follow-Up Plan (Denominator Exclusions) – Patients who have been diagnosed with bipolar disorder?  if we do, reject this MIPS.
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick2MatchCount > 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (CANNOT have Depression Screening or Follow-Up Plan (Denominator Exclusions) – Patients who have been diagnosed with bipolar disorder)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT or HCPCS)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		--PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '134' -- = 217

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134
	@ChartId = 2100112304
	,@PqrsNum = '134'
	,@Dos = '7/2/2024 6:38:01 PM'

begin tran; -- testing
*/

-- End of 03) DACS-3450 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type134].SQL
GO

-- Start of 01) DACS-3415 Alter Table CHARGE_MASTER_CATEGORY.sql

------------------------------------------------------------------------------------
-- 01) DACS-3415 - Script - Modify CHARGE_MASTER_CATEGORY table and add a column VALIDATION_CATEGORY
------------------------------------------------------------------------------------
GO

ALTER TABLE 
	CHARGE_MASTER_CATEGORY
ADD 
	VALIDATION_CATEGORY BIT DEFAULT 0
-- End of 01) DACS-3415 Alter Table CHARGE_MASTER_CATEGORY.sql
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
