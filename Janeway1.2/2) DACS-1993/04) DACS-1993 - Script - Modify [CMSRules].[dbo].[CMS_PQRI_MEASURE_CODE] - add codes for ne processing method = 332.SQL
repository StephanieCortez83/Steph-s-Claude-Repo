------------------------------------------------------------------------------------
-- 04) DACS-1993 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 332.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '332';
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
		PRINT('No Measure loaded for 332.  Cannot continue.');
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
		 (@MeasureId,'DG1P1','J01.00',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.01',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.10',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.11',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.20',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.21',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.30',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.31',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.40',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.41',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.80',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.81',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.90',@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.91',@Dos,NULL)

		,(@MeasureId,'DG1P2','B95.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.1',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.2',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.3',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.4',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.5',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.61',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.62',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.7',@Dos,NULL)
		,(@MeasureId,'DG1P2','B95.8',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.1',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.20',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.21',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.22',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.23',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.29',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.3',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.4',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.5',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.6',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.7',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.81',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.82',@Dos,NULL)
		,(@MeasureId,'DG1P2','B96.89',@Dos,NULL)
		
		,(@MeasureId,'DG2P1','G9364',@Dos,NULL)
		
		,(@MeasureId,'DG2P2','99202',@Dos,NULL)
		,(@MeasureId,'DG2P2','99203',@Dos,NULL)
		,(@MeasureId,'DG2P2','99204',@Dos,NULL)
		,(@MeasureId,'DG2P2','99205',@Dos,NULL)
		,(@MeasureId,'DG2P2','99212',@Dos,NULL)
		,(@MeasureId,'DG2P2','99213',@Dos,NULL)
		,(@MeasureId,'DG2P2','99214',@Dos,NULL)
		,(@MeasureId,'DG2P2','99215',@Dos,NULL)
		,(@MeasureId,'DG2P2','99281',@Dos,NULL)
		,(@MeasureId,'DG2P2','99282',@Dos,NULL)
		,(@MeasureId,'DG2P2','99283',@Dos,NULL)
		,(@MeasureId,'DG2P2','99284',@Dos,NULL)
		,(@MeasureId,'DG2P2','99285',@Dos,NULL)
		,(@MeasureId,'DG2P2','99304',@Dos,NULL)
		,(@MeasureId,'DG2P2','99305',@Dos,NULL)
		,(@MeasureId,'DG2P2','99306',@Dos,NULL)
		,(@MeasureId,'DG2P2','99307',@Dos,NULL)
		,(@MeasureId,'DG2P2','99308',@Dos,NULL)
		,(@MeasureId,'DG2P2','99309',@Dos,NULL)
		,(@MeasureId,'DG2P2','99310',@Dos,NULL)
		,(@MeasureId,'DG2P2','99341',@Dos,NULL)
		,(@MeasureId,'DG2P2','99342',@Dos,NULL)
		,(@MeasureId,'DG2P2','99344',@Dos,NULL)
		,(@MeasureId,'DG2P2','99345',@Dos,NULL)
		,(@MeasureId,'DG2P2','99347',@Dos,NULL)
		,(@MeasureId,'DG2P2','99348',@Dos,NULL)
		,(@MeasureId,'DG2P2','99349',@Dos,NULL)
		,(@MeasureId,'DG2P2','99350',@Dos,NULL)
		,(@MeasureId,'DG2P2','99424',@Dos,NULL)
		,(@MeasureId,'DG2P2','99491',@Dos,NULL)
		
		,(@MeasureId,'DG2P3','G9498',@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G9315',@Dos,'Performance Met: Amoxicillin, with or without clavulanate, prescribed asa first line antibiotic at the time of diagnosis')
		,(@MeasureId,'HCPCS','G9313',@Dos,'Other Performance Exclusion: Amoxicillin, with or without clavulanate, notprescribed as first line antibiotic at the time of diagnosis for documented reason')
		,(@MeasureId,'HCPCS','G9314',@Dos,'Performance Not Met: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis, reason not given')
		; -- expect 74 total inserts
		
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332'
*/