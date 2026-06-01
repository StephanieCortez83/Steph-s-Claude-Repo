------------------------------------------------------------------------------------
-- 02) DACS-3476 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 066.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
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