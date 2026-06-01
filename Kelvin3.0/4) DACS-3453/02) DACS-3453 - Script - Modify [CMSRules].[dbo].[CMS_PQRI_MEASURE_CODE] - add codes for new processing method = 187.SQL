------------------------------------------------------------------------------------
-- 02) DACS-3453 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 187.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '187';
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
		PRINT('No Measure loaded for 187.  Cannot continue.');
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
		-- Diagnosis for ischemic stroke (ICD-10-CM)
		 (@MeasureId,'DG1P1','I63.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.013',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.031',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.032',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.033',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.039',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.131',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.132',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.133',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.139',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.321',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.322',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.323',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.329',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.331',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.332',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.333',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.339',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.343',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.421',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.422',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.423',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.429',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.431',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.432',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.433',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.439',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.441',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.442',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.443',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.449',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I63.9',NULL,@Dos,NULL)

		-- Patient encounter during performance period (CPT)
		,(@MeasureId,'DG1P2','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)

		-- WITHOUT Telehealth Modifier (including but not limited to)
		,(@MeasureId,'DG2P1',NULL,'GQ',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'GT',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'95',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'POS 02',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'POS 10',@Dos,NULL)
		 
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8600',NULL,@Dos,'Performance Met: IV thrombolytic therapy initiated within 4.5 hours (≤ 270 minutes) of time last known well. ')
		,(@MeasureId,'HCPCS','G8602',NULL,@Dos,'Performance Not Met: IV thrombolytic therapy not initiated within 4.5 hours (≤ 270 minutes) of time last known well, reason not given. ')
		,(@MeasureId,'HCPCS','G8601',NULL,@Dos,'Denominator Exception: IV thrombolytic therapy not initiated within 4.5 hours (≤ 270 minutes) of time last known well for reasons documented by clinician (e.g. patient enrolled in clinical trial for stroke, patient admitted for elective carotid intervention). ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Was time last known well to hospital arrival less than or equal to 3.5 hours (≤ 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p> ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 113 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '187' -- = 214
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 214
*/