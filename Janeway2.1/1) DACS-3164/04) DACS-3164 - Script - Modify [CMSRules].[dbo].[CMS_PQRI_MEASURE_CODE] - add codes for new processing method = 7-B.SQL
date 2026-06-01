------------------------------------------------------------------------------------
-- 04) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 7-B.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '7-B';
	DECLARE @Dos DATETIME = GETDATE();

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
		PRINT('No Measure loaded for 7-B.  Cannot continue.');
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
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
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'DG1P1','I20.0',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.2',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.8',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.8',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.10',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.112',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.702',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.712',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.722',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.732',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.752',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.762',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.792',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.84',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.1',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',@Dos,NULL)

		,(@MeasureId,'DG1P2','33140',@Dos,NULL)
		,(@MeasureId,'DG1P2','33509',@Dos,NULL)
		,(@MeasureId,'DG1P2','33510',@Dos,NULL)
		,(@MeasureId,'DG1P2','33511',@Dos,NULL)
		,(@MeasureId,'DG1P2','33512',@Dos,NULL)
		,(@MeasureId,'DG1P2','33513',@Dos,NULL)
		,(@MeasureId,'DG1P2','33514',@Dos,NULL)
		,(@MeasureId,'DG1P2','33516',@Dos,NULL)
		,(@MeasureId,'DG1P2','33533',@Dos,NULL)
		,(@MeasureId,'DG1P2','33534',@Dos,NULL)
		,(@MeasureId,'DG1P2','33535',@Dos,NULL)
		,(@MeasureId,'DG1P2','33536',@Dos,NULL)
		,(@MeasureId,'DG1P2','92920',@Dos,NULL)
		,(@MeasureId,'DG1P2','92924',@Dos,NULL)
		,(@MeasureId,'DG1P2','92928',@Dos,NULL)
		,(@MeasureId,'DG1P2','92933',@Dos,NULL)
		,(@MeasureId,'DG1P2','92937',@Dos,NULL)
		,(@MeasureId,'DG1P2','92941',@Dos,NULL)
		,(@MeasureId,'DG1P2','92943',@Dos,NULL)
		
		,(@MeasureId,'DG2P1','I21.01',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.02',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.09',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.11',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.19',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.21',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.29',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.3',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.4',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.9',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.A1',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.A9',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.0',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.1',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.2',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.8',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.9',@Dos,NULL)
		
		,(@MeasureId,'DG2P2','99202',@Dos,NULL)
		,(@MeasureId,'DG2P2','99203',@Dos,NULL)
		,(@MeasureId,'DG2P2','99204',@Dos,NULL)
		,(@MeasureId,'DG2P2','99205',@Dos,NULL)
		,(@MeasureId,'DG2P2','99212',@Dos,NULL)
		,(@MeasureId,'DG2P2','99213',@Dos,NULL)
		,(@MeasureId,'DG2P2','99214',@Dos,NULL)
		,(@MeasureId,'DG2P2','99215',@Dos,NULL)
		,(@MeasureId,'DG2P2','99242',@Dos,NULL)
		,(@MeasureId,'DG2P2','99243',@Dos,NULL)
		,(@MeasureId,'DG2P2','99244',@Dos,NULL)
		,(@MeasureId,'DG2P2','99245',@Dos,NULL)
		,(@MeasureId,'DG2P2','99304',@Dos,NULL)
		,(@MeasureId,'DG2P2','99305',@Dos,NULL)
		,(@MeasureId,'DG2P2','99306',@Dos,NULL)
		,(@MeasureId,'DG2P2','99307',@Dos,NULL)
		,(@MeasureId,'DG2P2','99308',@Dos,NULL)
		,(@MeasureId,'DG2P2','99309',@Dos,NULL)
		,(@MeasureId,'DG2P2','99310',@Dos,NULL)
		,(@MeasureId,'DG2P2','99315',@Dos,NULL)
		,(@MeasureId,'DG2P2','99316',@Dos,NULL)
		,(@MeasureId,'DG2P2','99341',@Dos,NULL)
		,(@MeasureId,'DG2P2','99342',@Dos,NULL)
		,(@MeasureId,'DG2P2','99344',@Dos,NULL)
		,(@MeasureId,'DG2P2','99345',@Dos,NULL)
		,(@MeasureId,'DG2P2','99347',@Dos,NULL)
		,(@MeasureId,'DG2P2','99348',@Dos,NULL)
		,(@MeasureId,'DG2P2','99349',@Dos,NULL)
		,(@MeasureId,'DG2P2','99350',@Dos,NULL)
		,(@MeasureId,'DG2P2','99424',@Dos,NULL)
		,(@MeasureId,'DG2P2','99426',@Dos,NULL)
		
		,(@MeasureId,'DG2P3','99202',@Dos,NULL)
		,(@MeasureId,'DG2P3','99203',@Dos,NULL)
		,(@MeasureId,'DG2P3','99204',@Dos,NULL)
		,(@MeasureId,'DG2P3','99205',@Dos,NULL)
		,(@MeasureId,'DG2P3','99212',@Dos,NULL)
		,(@MeasureId,'DG2P3','99213',@Dos,NULL)
		,(@MeasureId,'DG2P3','99214',@Dos,NULL)
		,(@MeasureId,'DG2P3','99215',@Dos,NULL)
		,(@MeasureId,'DG2P3','99242',@Dos,NULL)
		,(@MeasureId,'DG2P3','99243',@Dos,NULL)
		,(@MeasureId,'DG2P3','99244',@Dos,NULL)
		,(@MeasureId,'DG2P3','99245',@Dos,NULL)
		,(@MeasureId,'DG2P3','99304',@Dos,NULL)
		,(@MeasureId,'DG2P3','99305',@Dos,NULL)
		,(@MeasureId,'DG2P3','99306',@Dos,NULL)
		,(@MeasureId,'DG2P3','99307',@Dos,NULL)
		,(@MeasureId,'DG2P3','99308',@Dos,NULL)
		,(@MeasureId,'DG2P3','99309',@Dos,NULL)
		,(@MeasureId,'DG2P3','99310',@Dos,NULL)
		,(@MeasureId,'DG2P3','99315',@Dos,NULL)
		,(@MeasureId,'DG2P3','99316',@Dos,NULL)
		,(@MeasureId,'DG2P3','99341',@Dos,NULL)
		,(@MeasureId,'DG2P3','99342',@Dos,NULL)
		,(@MeasureId,'DG2P3','99344',@Dos,NULL)
		,(@MeasureId,'DG2P3','99345',@Dos,NULL)
		,(@MeasureId,'DG2P3','99347',@Dos,NULL)
		,(@MeasureId,'DG2P3','99348',@Dos,NULL)
		,(@MeasureId,'DG2P3','99349',@Dos,NULL)
		,(@MeasureId,'DG2P3','99350',@Dos,NULL)
		,(@MeasureId,'DG2P3','99424',@Dos,NULL)
		,(@MeasureId,'DG2P3','99426',@Dos,NULL)
		; -- expect 160 total inserts
		
		-- measure code numerators -- handle seperately due to MODIFIER column update
	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		 (@MeasureId,'HCPCS','4008F',NULL,@Dos,'Performance Met: Beta-blocker therapy prescribed or currently being taken')
		,(@MeasureId,'HCPCS','4008F','1P',@Dos,'Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons)')
		,(@MeasureId,'HCPCS','4008F','2P',@Dos,'Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons)')
		,(@MeasureId,'HCPCS','4008F','3P',@Dos,'Denominator Exception: Documentation of system reason(s) for not prescribing beta-blocker therapy (e.g., other reasons attributable to the health care system)')
		,(@MeasureId,'HCPCS','4008F','8P',@Dos,'Performance Not Met: Beta-blocker therapy not prescribed, reason not otherwise specified')
		; -- expect 5 total inserts
				
		
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
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
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
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '7-B'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 194
*/