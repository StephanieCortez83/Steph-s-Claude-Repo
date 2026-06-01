------------------------------------------------------------------------------------
-- 03) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 8-A.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '8-A';
	DECLARE @Dos DATETIME = '01-01-2024' --GETDATE();

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
		PRINT('No Measure loaded for 8-A.  Cannot continue.');
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
		 (@MeasureId,'DG1P1','I11.0',@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.0',@Dos,NULL)
		,(@MeasureId,'DG1P1','I13.2',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.1',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.20',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.21',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.22',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.23',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.30',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.31',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.32',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.33',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.40',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.41',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.42',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.43',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.814',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.82',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.83',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.84',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.89',@Dos,NULL)
		,(@MeasureId,'DG1P1','I50.9',@Dos,NULL)
		
		,(@MeasureId,'DG1P2','99202',@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',@Dos,NULL)
		,(@MeasureId,'DG1P2','99242',@Dos,NULL)
		,(@MeasureId,'DG1P2','99243',@Dos,NULL)
		,(@MeasureId,'DG1P2','99244',@Dos,NULL)
		,(@MeasureId,'DG1P2','99245',@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',@Dos,NULL)
		,(@MeasureId,'DG1P2','99315',@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',@Dos,NULL)
		,(@MeasureId,'DG1P2','99426',@Dos,NULL)
		
		,(@MeasureId,'DG2P1','99202',@Dos,NULL)
		,(@MeasureId,'DG2P1','99203',@Dos,NULL)
		,(@MeasureId,'DG2P1','99204',@Dos,NULL)
		,(@MeasureId,'DG2P1','99205',@Dos,NULL)
		,(@MeasureId,'DG2P1','99212',@Dos,NULL)
		,(@MeasureId,'DG2P1','99213',@Dos,NULL)
		,(@MeasureId,'DG2P1','99214',@Dos,NULL)
		,(@MeasureId,'DG2P1','99215',@Dos,NULL)
		,(@MeasureId,'DG2P1','99242',@Dos,NULL)
		,(@MeasureId,'DG2P1','99243',@Dos,NULL)
		,(@MeasureId,'DG2P1','99244',@Dos,NULL)
		,(@MeasureId,'DG2P1','99245',@Dos,NULL)
		,(@MeasureId,'DG2P1','99304',@Dos,NULL)
		,(@MeasureId,'DG2P1','99305',@Dos,NULL)
		,(@MeasureId,'DG2P1','99306',@Dos,NULL)
		,(@MeasureId,'DG2P1','99307',@Dos,NULL)
		,(@MeasureId,'DG2P1','99308',@Dos,NULL)
		,(@MeasureId,'DG2P1','99309',@Dos,NULL)
		,(@MeasureId,'DG2P1','99310',@Dos,NULL)
		,(@MeasureId,'DG2P1','99315',@Dos,NULL)
		,(@MeasureId,'DG2P1','99316',@Dos,NULL)
		,(@MeasureId,'DG2P1','99341',@Dos,NULL)
		,(@MeasureId,'DG2P1','99342',@Dos,NULL)
		,(@MeasureId,'DG2P1','99344',@Dos,NULL)
		,(@MeasureId,'DG2P1','99345',@Dos,NULL)
		,(@MeasureId,'DG2P1','99347',@Dos,NULL)
		,(@MeasureId,'DG2P1','99348',@Dos,NULL)
		,(@MeasureId,'DG2P1','99349',@Dos,NULL)
		,(@MeasureId,'DG2P1','99350',@Dos,NULL)
		,(@MeasureId,'DG2P1','99424',@Dos,NULL)
		,(@MeasureId,'DG2P1','99426',@Dos,NULL)
		
		,(@MeasureId,'DG2P2','G8923',@Dos,NULL)
		
		,(@MeasureId,'DG2P3','M1152',@Dos,NULL)  -- EXCLUDE codes
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8450',@Dos,'Performance Met: Beta-blocker therapy prescribed')
		,(@MeasureId,'HCPCS','G8451',@Dos,'Denominator Exception: Beta-Blocker Therapy for LVEF ≤ 40% not prescribed for reasons documented by the clinician (e.g., low blood pressure, fluid overload, asthma, patients recently treated with an intravenous positive inotropic agent, allergy, intolerance, other medical reasons, patient declined, other patient reasons)')
		,(@MeasureId,'HCPCS','G8452',@Dos,'Performance Not Met: Beta-blocker therapy not prescribed')
		; -- expect 89 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '8-A'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 196
*/