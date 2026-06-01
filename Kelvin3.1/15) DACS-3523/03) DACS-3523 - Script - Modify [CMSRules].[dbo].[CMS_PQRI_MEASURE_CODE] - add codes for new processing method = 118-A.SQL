------------------------------------------------------------------------------------
-- 03) DACS-3523 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-A.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
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