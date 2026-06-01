------------------------------------------------------------------------------------
-- 02) DACS-3220 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - adds codes for new processing method = ACEP64.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ACEP64';
	DECLARE @Dos DATETIME = '01-01-2024' 

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
		PRINT('No Measure loaded for ACEP64.  Cannot continue.');
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

	-------------------------------------------------------
	-- backup the table first
	-------------------------------------------------------
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3220';

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

--RETURN; -- testing
-- rollback tran; -- testing
-- commit tran; -- testing

	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'DG1P1','99281',@Dos,NULL)
		,(@MeasureId,'DG1P1','99282',@Dos,NULL)
		,(@MeasureId,'DG1P1','99283',@Dos,NULL)
		,(@MeasureId,'DG1P1','99284',@Dos,NULL)
		,(@MeasureId,'DG1P1','99285',@Dos,NULL)
		,(@MeasureId,'DG1P1','99286',@Dos,NULL)
		,(@MeasureId,'DG1P1','99287',@Dos,NULL)
		,(@MeasureId,'DG1P1','99288',@Dos,NULL)
		,(@MeasureId,'DG1P1','99291',@Dos,NULL)
		,(@MeasureId,'DG1P1','99292',@Dos,NULL)
		
		,(@MeasureId,'DG1P2','I82.4',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.40',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.401',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.402',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.403',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.409',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.49',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.491',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.492',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.493',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.499',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Y',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Y1',@Dos,NULL) 
		,(@MeasureId,'DG1P2','I82.4Y2',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Y3',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Y9',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Z',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Z1',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Z2',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Z3',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.4Z9',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.50',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.501',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.502',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.503',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.509',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.59',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.591',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.592',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.593',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.599',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Y',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Y1',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Y2',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Y3',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Y9',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Z',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Z1',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Z2',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Z3',@Dos,NULL)
		,(@MeasureId,'DG1P2','I82.5Z9',@Dos,NULL)
	
		-- measure code numerators
		,(@MeasureId,'HCPCS','P6402',@Dos,'Performance Met: Patient discharged from ED')
		,(@MeasureId,'HCPCS','P6403',@Dos,'Performance Not Met: : Patient NOT discharged from ED')
		,(@MeasureId,'HCPCS','P6404',@Dos,'Denominator Exception: Death, LAMA, LWBS, LWT')
		,(@MeasureId,'HCPCS','P6401',@Dos,'Denominator EXCLUSIONS: <ul>  <li>Syncope</li>  <li>Pulmonary embolism</li>  <li>Proximal DVT</li>  <li>Already on anticoagulation at time of DVT diagnosis based on listed home medications</li></ul>')
		; -- expect 56 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ACEP64'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 206
*/