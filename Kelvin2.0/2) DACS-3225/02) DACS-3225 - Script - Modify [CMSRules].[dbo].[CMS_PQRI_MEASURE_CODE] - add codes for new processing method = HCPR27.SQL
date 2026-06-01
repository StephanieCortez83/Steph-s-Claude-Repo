------------------------------------------------------------------------------------
-- 02) DACS-3225 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = HCPR27.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'HCPR27';
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
		PRINT('No Measure loaded for HCPR27.  Cannot continue.');
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
		-- Seen by Eligible Professionals in Emergency Department or Intensive Care Unit Settings (CPT Codes)
 		 (@MeasureId,'DG1P1','99221',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99222',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99223',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','99292',NULL,@Dos,NULL)

		-- Undergone CVC insertion (limited to internal jugular or subclavian lines) (CPT Codes)
		,(@MeasureId,'DG1P2','36555',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36556',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36557',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36558',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36560',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36561',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36563',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36565',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36566',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36568',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36569',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36570',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36571',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36572',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36573',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36578',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36580',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36581',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36582',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36583',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36584',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','36585',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93503',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93594',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93595',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93596',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','93597',NULL,@Dos,NULL)
 		
		-- measure code numerators
		,(@MeasureId,'HCPCS','VH273',NULL,@Dos,'Performance Met:  Point-of-Care Ultrasound evaluation for Pneumothorax performed. ')
		,(@MeasureId,'HCPCS','VH275',NULL,@Dos,'Performance Not Met: Point-of-Care Ultrasound evaluation for pneumothorax not performed. ')
		,(@MeasureId,'HCPCS','VH274',NULL,@Dos,'Denominator Exception:  Documented medical reason for not performing Point-of-Care Ultrasound (e.g. no ultrasound machine available, patient refusal) ')
		,(@MeasureId,'HCPCS','V0704',NULL,@Dos,'Denominator EXCLUSION: Transferred, eloped, AMA, or expired patients are excluded ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Was a CVC Insertion was performed on internal jugular or subclavian veins (Pseudo Code): HCPR2701? ')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 47 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'HCPR27' -- = 213
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 213
*/