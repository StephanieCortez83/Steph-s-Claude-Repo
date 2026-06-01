------------------------------------------------------------------------------------
-- 02) DACS-3474 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 116.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
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