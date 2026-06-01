------------------------------------------------------------------------------------
-- 02) DACS-3230 - Script - Modify (20240714 doc changes) [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = THEPQR4.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
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