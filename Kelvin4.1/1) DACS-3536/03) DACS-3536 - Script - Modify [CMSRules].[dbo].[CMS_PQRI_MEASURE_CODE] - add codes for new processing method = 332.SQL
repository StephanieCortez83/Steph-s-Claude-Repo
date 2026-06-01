------------------------------------------------------------------------------------
-- 03) DACS-3536 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 332.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '332';
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
		-- Diagnosis for acute sinusitis (ICD-10-CM):
		 (@MeasureId,'DG1P1','J01.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.91',NULL,@Dos,NULL)
	
		-- Patient encounter during the performance period (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99491',NULL,@Dos,NULL)

		-- Diagnosis for bacterial and infectious agents (ICD-10-CM)
		,(@MeasureId,'DG2P1','B95.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.61',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.62',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.89',NULL,@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G9315',NULL,@Dos,'Performance Met: Amoxicillin, with or without clavulanate, prescribed asa first line antibiotic at the time of diagnosis. ')
		,(@MeasureId,'HCPCS','G9314',NULL,@Dos,'Performance Not Met: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis, reason not given. ')
		,(@MeasureId,'HCPCS','G9313',NULL,@Dos,'Denominator Exception: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis for documented reason. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G9364',NULL,@Dos,'Sinusitis caused by, or presumed to be caused by, bacterial infection: G9364? ')
		,(@MeasureId,'DQ411','G9498',NULL,@Dos,'Antibiotic regimen prescribed: G9498?')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		
		; -- expect 35 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332' -- = 170
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 170
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 170
--commit tran;
*/