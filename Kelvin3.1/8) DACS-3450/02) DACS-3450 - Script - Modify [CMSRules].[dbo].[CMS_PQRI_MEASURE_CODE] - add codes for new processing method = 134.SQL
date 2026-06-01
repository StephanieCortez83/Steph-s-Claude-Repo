------------------------------------------------------------------------------------
-- 02) DACS-3450 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 134.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
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