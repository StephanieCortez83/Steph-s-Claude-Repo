------------------------------------------------------------------------------------
-- 02) DACS-3208 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 76.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '76';
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
		PRINT('No Measure loaded for 76.  Cannot continue.');
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
				AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
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
			AND [CODING_SYSTEM] IN ('C4','CPT_II')
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
				AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Needs table assistance.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'C4','36555',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36556',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36557',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36558',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36560',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36561',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36563',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36565',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36566',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36568',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36569',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36570',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36571',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36572',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36573',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36578',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36580',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36581',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36582',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36583',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36584',NULL,@Dos,NULL)
		,(@MeasureId,'C4','36585',NULL,@Dos,NULL)
		,(@MeasureId,'C4','93503',NULL,@Dos,NULL)			
				
		,(@MeasureId,'CPT_II','6030F','1P',@Dos,'Denominator Exception: 6030F with 1P: Documentation of medical reason(s) for not following all elements of maximal sterile barrier technique, hand hygiene, skin preparation and, if ultrasound is used, sterile ultrasound techniques during CVC insertion (including increased risk of harm to patient if adherence to aseptic technique would cause delay in CVC insertion)')			
		,(@MeasureId,'CPT_II','6030F','8P',@Dos,'Performance Not Met: 6030F with 8P: All elements of maximal sterile barrier technique, hand hygiene, skin preparation and, if ultrasound is used, sterile ultrasound techniques not followed, reason not otherwise specified')			
		,(@MeasureId,'CPT_II','6030F',NULL,@Dos,'Performance Met: CPT II 6030F: All elements of maximal sterile barrier technique, hand hygiene, skin preparation and, if ultrasound is used, sterile ultrasound techniques followed')			

		; -- expect 26 inserts
		
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
				AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
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
		AND cpmc.[CODING_SYSTEM] IN ('C4','CPT_II')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
SELECT TOP 1000 * FROM [dbo].[CMS_PQRI_MEASURE]
where [PQRS#] IN ('76');

SELECT TOP 1000 * 
FROM [dbo].[CMS_PQRI_MEASURE_CODE]
WHERE CMS_PQRI_MEASURE_ID IN (195)
*/