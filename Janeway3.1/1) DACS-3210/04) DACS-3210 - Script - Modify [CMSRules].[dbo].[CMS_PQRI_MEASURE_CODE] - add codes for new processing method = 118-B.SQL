------------------------------------------------------------------------------------
-- 04) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-B.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '118-B';
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


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.8',NULL,@Dos,NULL)
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
		,(@MeasureId,'DG1P1','I22.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',NULL,@Dos,NULL)

		,(@MeasureId,'DG1P2','E10.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.013',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.03',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.0111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.0112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.0113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.0119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.13',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.813',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.819',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.83',NULL,@Dos,NULL)

		,(@MeasureId,'DG2P1','99201',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99241',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99324',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99325',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99326',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99327',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99328',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99334',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99335',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99336',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99337',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99343',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99350',NULL,@Dos,NULL)

--cannot have these modifiers EXCEPTION
		,(@MeasureId,'DG2P2',NULL,'GQ',@Dos,NULL)
		,(@MeasureId,'DG2P2',NULL,'GT',@Dos,NULL)
		,(@MeasureId,'DG2P2',NULL,'95',@Dos,NULL)

-- !!! AND have to check that the telehealth use code is NOT POS 02.  for now till just check the ACS chart telehealth flag field for set or not.!!!
 		
-- !!!check for "Two Denominator Eligible Visits"  will likely need a UI question but will check for the CPT codes again for now.!!!
		,(@MeasureId,'DG2P3','99201',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99241',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99324',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99325',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99326',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99327',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99328',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99334',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99335',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99336',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99337',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99343',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99350',NULL,@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8473',NULL,@Dos,'Performance Met: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy prescribed')
		,(@MeasureId,'HCPCS','G8474',NULL,@Dos,'Denominator Exception: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy not prescribed for reasons documented by the clinician (eg, allergy, intolerance, pregnancy, renal failure due to ACE inhibitor, diseases of the aortic or mitral valve, other medical reasons) or (eg, patient declined, other patient reasons) or (eg, lack of drug availability, other reasons attributable to the health care system)')
		,(@MeasureId,'HCPCS','G8475',NULL,@Dos,'Performance Not Met: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy not prescribed, reason not given')
		; -- expect 428 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-B' -- = 200
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 200
*/