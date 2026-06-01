------------------------------------------------------------------------------------
-- 02) DACS-3458 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 415.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '415';
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
		PRINT('No Measure loaded for [' + @PqrsCd + '].  Cannot continue.');
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
		-- Diagnosis for minor blunt head trauma (ICD-10-CM)
		 (@MeasureId,'DG1P1','S00.03XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.33XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.431A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.432A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.439A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.531A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.532A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.83XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S00.93XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.A0XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.A1XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.0X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.1X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.2X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.30AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.300A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.301A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.302A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.303A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.304A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.309A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.31AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.32AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.33AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.34AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.340A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.341A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.342A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.343A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.344A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.349A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.35AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.350A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.351A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.352A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.353A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.354A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.359A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.36AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.360A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.361A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.362A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.363A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.364A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.369A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.37AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.38AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.4X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.5X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.6X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.81AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.810A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.811A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.812A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.813A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.814A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.819A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.82AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.820A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.821A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.822A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.823A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.824A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.829A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.89AA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.890A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.891A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.892A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.893A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.894A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.899A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9XAA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X0A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S06.9X9A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.11XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.19XA',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','S09.8XXA',NULL,@Dos,NULL)

		-- Patient encounter during performance period (CPT)
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
		,(@MeasureId,'HCPCS','G9531',NULL,@Dos,'(DENOMINATOR EXCLUSION): Patient was NOT documentated with ventricular shunt, brain tumor, multisystem trauma, or is currently taking an antiplatelet medication including: abciximab, anagrelide, cangrelor, cilostazol, clopidogrel, dipyridamole, eptifibatide, prasugrel, ticlopidine, ticagrelor, tirofiban, or vorapaxar? ')
		,(@MeasureId,'HCPCS','G9529',NULL,@Dos,'Performance Met: Patient with minor blunt head trauma had an appropriate indication(s) for a head CT. ')
		,(@MeasureId,'HCPCS','G9533',NULL,@Dos,'Performance Not Met: Patient with minor blunt head trauma did not have an appropriate indication(s) for a head CT. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G9530',NULL,@Dos,'Was Patient presented with a minor blunt head trauma and had a head CT ordered for trauma by an emergency care provider: (G9530)? ')
		--,(@MeasureId,'DQ411','G9531',NULL,@Dos,'Patient was NOT documentated with ventricular shunt, brain tumor, multisystem trauma, or is currently taking an antiplatelet medication including: abciximab, anagrelide, cangrelor, cilostazol, clopidogrel, dipyridamole, eptifibatide, prasugrel, ticlopidine, ticagrelor, tirofiban, or vorapaxar: (DENOMINATOR EXCLUSION - G9531)? ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 130 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '415' -- = 229
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 229
*/