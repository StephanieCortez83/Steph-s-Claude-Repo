------------------------------------------------------------------------------------
-- 02) DACS-3524 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 047.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '047';
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
		-- Diagnosis (ICD-10-CM): -- none at present
		-- (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)

		-- Patient encounter during the performance period (CPT or HCPCS)
		 (@MeasureId,'DG1P2','90791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90832',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90834',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90837',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90845',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90846',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','90847',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99231',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99232',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99233',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)
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
		,(@MeasureId,'DG1P2','G0402',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0438',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','G0439',NULL,@Dos,NULL)

		-- measure code numerators
		,(@MeasureId,'HCPCS','G9692',NULL,@Dos,'Denominator EXCLUSION: Hospice services received by patient any time during the measurement period. ')
		,(@MeasureId,'HCPCS','1123F',NULL,@Dos,'Performance Met: Advance Care Planning discussed and documented; advance care plan or surrogate decision maker documented in the medical record. ')
		,(@MeasureId,'HCPCS','1124F',NULL,@Dos,'Performance Met: Advance Care Planning discussed and documented in the medical record; patient did not wish or was notable to name a surrogate decision maker or provide an advance care plan. ')
		,(@MeasureId,'HCPCS','1123F','8P',@Dos,'Performance Not Met: Advance Care Planning not documented, reason not otherwise specified. <p><strong>Definition:</strong></p><p><strong>Documentation that Patient did not Wish or was not able to Name a Surrogate Decision Maker or Provide an Advance Care Plan</strong> – May also include: <ul><li>That the patient’s cultural and/or spiritual beliefs preclude a discussion of advance care planning, and thus harmful to the physician-patient relationship.</li></ul></p>')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		
		; -- expect 49 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '047' -- = 1231
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 1231
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 1231
--commit tran;
*/