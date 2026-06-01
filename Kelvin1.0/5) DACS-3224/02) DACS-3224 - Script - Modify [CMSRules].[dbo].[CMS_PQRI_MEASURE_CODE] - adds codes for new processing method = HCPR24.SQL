------------------------------------------------------------------------------------
-- 02) DACS-3224 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - adds codes for new processing method = HCPR24.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'HCPR24';
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
		PRINT('No Measure loaded for HCPR24.  Cannot continue.');
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
		 (@MeasureId,'DG1P1','99221',@Dos,NULL)
		,(@MeasureId,'DG1P1','99222',@Dos,NULL)
		,(@MeasureId,'DG1P1','99223',@Dos,NULL)
		,(@MeasureId,'DG1P1','99234',@Dos,NULL)
		,(@MeasureId,'DG1P1','99235',@Dos,NULL)
		,(@MeasureId,'DG1P1','99236',@Dos,NULL)
		,(@MeasureId,'DG1P1','99281',@Dos,NULL)
		,(@MeasureId,'DG1P1','99282',@Dos,NULL)
		,(@MeasureId,'DG1P1','99283',@Dos,NULL)
		,(@MeasureId,'DG1P1','99284',@Dos,NULL)
		,(@MeasureId,'DG1P1','99285',@Dos,NULL)
		,(@MeasureId,'DG1P1','99291',@Dos,NULL)
		,(@MeasureId,'DG1P1','99292',@Dos,NULL)
		
		,(@MeasureId,'DG1P2','A48.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','H05.011',@Dos,NULL)
		,(@MeasureId,'DG1P2','H05.012',@Dos,NULL)
		,(@MeasureId,'DG1P2','H05.013',@Dos,NULL)
		,(@MeasureId,'DG1P2','H05.019',@Dos,NULL)
		,(@MeasureId,'DG1P2','H60.10',@Dos,NULL)
		,(@MeasureId,'DG1P2','H60.11',@Dos,NULL)
		,(@MeasureId,'DG1P2','H60.12',@Dos,NULL)
		,(@MeasureId,'DG1P2','H60.13',@Dos,NULL)
		,(@MeasureId,'DG1P2','J34.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','J36',@Dos,NULL)
		,(@MeasureId,'DG1P2','J38.3',@Dos,NULL)
		,(@MeasureId,'DG1P2','J38.7',@Dos,NULL)
		,(@MeasureId,'DG1P2','J39.1',@Dos,NULL)
		,(@MeasureId,'DG1P2','K12.2',@Dos,NULL)
		,(@MeasureId,'DG1P2','K13.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','K61.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','K61.1',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.011',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.012',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.019',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.031',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.032',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.039',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.111',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.112',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.113',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.114',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.115',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.116',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.119',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.211',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.212',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.213',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.221',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.311',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.312',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.313',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.314',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.315',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.316',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.317',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.319',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.811',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.818',@Dos,NULL)
		,(@MeasureId,'DG1P2','L03.90',@Dos,NULL)
		,(@MeasureId,'DG1P2','L98.3',@Dos,NULL)
		,(@MeasureId,'DG1P2','N48.22',@Dos,NULL)
		,(@MeasureId,'DG1P2','N49.9',@Dos,NULL)
		,(@MeasureId,'DG1P2','N61.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','N73.0',@Dos,NULL)
		,(@MeasureId,'DG1P2','N73.1',@Dos,NULL)
		,(@MeasureId,'DG1P2','N73.2',@Dos,NULL)

		-- measure code numerators
		,(@MeasureId,'HCPCS','VH271',@Dos,'Performance Met: Vancomycin NOT ordered OR Vancomycin discontinued at admission.  OR Vancomycin ordered AND MRSA infection identified or risk for MRSA infection documented (i.e., nasal colonization, prior MRSA infection, recent hospitalization, recent antibiotics, penetrating injury, IVDU, purulent cellulitis, SIRS criteria, sepsis, impaired host defense).')
		,(@MeasureId,'HCPCS','VH272',@Dos,'Performance Not Met: : Vancomycin ordered AND no MRSA infection identified OR no risk for MRSA infection documented.')
		; -- expect 68 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'HCPR24'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 207
*/