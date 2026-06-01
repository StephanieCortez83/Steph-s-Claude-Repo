------------------------------------------------------------------------------------
-- 02) DACS-3454 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 001.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
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