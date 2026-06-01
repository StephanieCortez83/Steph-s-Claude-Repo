------------------------------------------------------------------------------------
-- 02) DACS-3226 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - adds codes for new processing method = PQRANES1.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'PQRANES1';
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
		PRINT('No Measure loaded for PQRANES1.  Cannot continue.');
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
	EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3226';

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
		 
		,(@MeasureId,'DG1P2','S72.001A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.002A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.009A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.011A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.012A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.019A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.021A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.022A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.023A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.024A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.025A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.026A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.031A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.032A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.033A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.034A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.035A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.036A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.041A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.042A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.043A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.044A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.045A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.046A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.051A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.052A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.059A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.061A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.062A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.063A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.064A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.065A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.066A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.091A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.092A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.099A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.101A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.102A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.109A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.111A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.112A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.113A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.114A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.115A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.116A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.121A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.122A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.123A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.124A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.125A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.126A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.131A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.132A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.133A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.134A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.136A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.141A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.142A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.143A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.144A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.145A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.146A',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.21XA',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.22XA',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.23XA',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.24XA',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.25XA',@Dos,NULL)
		,(@MeasureId,'DG1P2','S72.26XA',@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','DG014',@Dos,'Performance Met: Patients for whom a peripheral nerve block is performed in the Emergency Department as evidenced by Presence of CPT Code, OR Documentation that peripheral nerve block was performed.')
		,(@MeasureId,'HCPCS','64447',@Dos,'Performance Met: Patients for whom a peripheral nerve block is performed in the Emergency Department as evidenced by Presence of CPT Code, OR Documentation that peripheral nerve block was performed.')
		,(@MeasureId,'HCPCS','64448',@Dos,'Performance Met: Patients for whom a peripheral nerve block is performed in the Emergency Department as evidenced by Presence of CPT Code, OR Documentation that peripheral nerve block was performed.')
		,(@MeasureId,'HCPCS','64450',@Dos,'Performance Met: Patients for whom a peripheral nerve block is performed in the Emergency Department as evidenced by Presence of CPT Code, OR Documentation that peripheral nerve block was performed.')
		,(@MeasureId,'HCPCS','DG015',@Dos,'Performance Not Met: : Peripheral nerve block not performed as evidenced by Absence of CPT Code in Numerator Met AND Absence of Documentation.')
		,(@MeasureId,'HCPCS','DG016',@Dos,'Denominator EXCLUSIONS: Documented medical reason for exclusion. Example of Medical Exclusions: open fracture, infection at the insertion site, or other medical reason, patient unable to consent.')
		,(@MeasureId,'HCPCS','DG017',@Dos,'Denominator EXCLUSIONS: Documented patient refusal. Example: Patient refused block placement.')
		; -- expect 80 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'PQRANES1'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 209
*/