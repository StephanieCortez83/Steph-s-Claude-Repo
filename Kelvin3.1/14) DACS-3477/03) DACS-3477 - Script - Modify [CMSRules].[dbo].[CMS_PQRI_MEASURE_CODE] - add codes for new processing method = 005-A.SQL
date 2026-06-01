------------------------------------------------------------------------------------
-- 03) DACS-3477 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 005-A.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
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