------------------------------------------------------------------------------------
-- 02) DACS-3219 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - adds codes for new processing method = ACEP61.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ACEP61';
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
		PRINT('No Measure loaded for ACEP61.  Cannot continue.');
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
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3219';

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
		,(@MeasureId,'DG1P1','99291',@Dos,NULL)
		,(@MeasureId,'DG1P1','99292',@Dos,NULL)
		
		,(@MeasureId,'DG1P2','J45.5',@Dos,NULL)
		,(@MeasureId,'DG1P2','J05',@Dos,NULL)
		,(@MeasureId,'DG1P2','J05.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','J21',@Dos,NULL)
		,(@MeasureId,'DG1P2','J21.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','J21.1',@Dos,NULL)
		,(@MeasureId,'DG1P2','J21.8',@Dos,NULL)
		,(@MeasureId,'DG1P2','J21.9',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.2',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.20',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.21',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.22',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.3',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.30',@Dos,NULL) 
		,(@MeasureId,'DG1P2','J45.31',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.32',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.4',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.40',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.41',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.42',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.50',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.51',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.52',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.9',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.90',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.901',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.902',@Dos,NULL) 
		,(@MeasureId,'DG1P2','J45.909',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.99',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.991',@Dos,NULL)
		,(@MeasureId,'DG1P2','J45.998',@Dos,NULL)
		,(@MeasureId,'DG1P2','J84.115',@Dos,NULL)
	
		-- measure code numerators
		,(@MeasureId,'HCPCS','DG062',@Dos,'Performance Met: A chest x-ray was ordered/performed for the patient.')
		,(@MeasureId,'HCPCS','DG061',@Dos,'Performance Not Met: A chest x-ray was NOT ordered/performed for the patient.')
		,(@MeasureId,'HCPCS','DG063',@Dos,'Denominator EXCLUSIONS: History of Cystic Fibrosis, Airway Malformations, Immunodeficiency Syndromes, Pneumonia')
		; -- expect 43 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ACEP61'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 204
*/