------------------------------------------------------------------------------------
-- 02) DACS-3229 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR3.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
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