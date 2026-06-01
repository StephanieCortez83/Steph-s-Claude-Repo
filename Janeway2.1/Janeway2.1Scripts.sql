USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 7-A.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 7-A.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '7-A';
	DECLARE @Dos DATETIME = GETDATE();

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [REQ_2_DX_OR_3CPT] = 1
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 '7-A'
				,'Efficiency and Cost Reduction'
				,'PQRS# 7-A [Requires 7-B also be added to Service Agreement for full MIPS functionality] Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF ≤ 40%)'	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);



	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '7-A'
*/
-- End of 01) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 7-A.SQL
GO

-- Start of 02) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 7-B.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 7-B.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '7-B';
	DECLARE @Dos DATETIME = GETDATE();

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @countPQRS > 0
	BEGIN 
		PRINT('Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [REQ_2_DX_OR_3CPT] = 1
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 '7-B'
				,'Efficiency and Cost Reduction'
				,'PQRS# 7-B [Requires 7-A also be added to Service Agreement for full MIPS functionality] Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF ≤ 40%)'	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);



	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '7-B'
*/
-- End of 02) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 7-B.SQL
GO

-- Start of 03) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 7-A.SQL

------------------------------------------------------------------------------------
-- 03) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 7-A.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '7-A';
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
		PRINT('No Measure loaded for 7-A.  Cannot continue.');
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
		 (@MeasureId,'DG1P1','I20.0',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.2',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.8',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.8',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.10',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.112',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.702',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.712',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.722',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.732',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.752',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.762',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.792',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.84',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.1',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',@Dos,NULL)
		
		,(@MeasureId,'DG1P2','33140',@Dos,NULL)
		,(@MeasureId,'DG1P2','33509',@Dos,NULL)
		,(@MeasureId,'DG1P2','33510',@Dos,NULL)
		,(@MeasureId,'DG1P2','33511',@Dos,NULL)
		,(@MeasureId,'DG1P2','33512',@Dos,NULL)
		,(@MeasureId,'DG1P2','33513',@Dos,NULL)
		,(@MeasureId,'DG1P2','33514',@Dos,NULL)
		,(@MeasureId,'DG1P2','33516',@Dos,NULL)
		,(@MeasureId,'DG1P2','33533',@Dos,NULL)
		,(@MeasureId,'DG1P2','33534',@Dos,NULL)
		,(@MeasureId,'DG1P2','33535',@Dos,NULL)
		,(@MeasureId,'DG1P2','33536',@Dos,NULL)
		,(@MeasureId,'DG1P2','92920',@Dos,NULL)
		,(@MeasureId,'DG1P2','92924',@Dos,NULL)
		,(@MeasureId,'DG1P2','92928',@Dos,NULL)
		,(@MeasureId,'DG1P2','92933',@Dos,NULL)
		,(@MeasureId,'DG1P2','92937',@Dos,NULL)
		,(@MeasureId,'DG1P2','92941',@Dos,NULL)
		,(@MeasureId,'DG1P2','92943',@Dos,NULL)
		
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
		
		,(@MeasureId,'DG2P2','99202',@Dos,NULL)
		,(@MeasureId,'DG2P2','99202',@Dos,NULL)
		,(@MeasureId,'DG2P2','99203',@Dos,NULL)
		,(@MeasureId,'DG2P2','99204',@Dos,NULL)
		,(@MeasureId,'DG2P2','99205',@Dos,NULL)
		,(@MeasureId,'DG2P2','99212',@Dos,NULL)
		,(@MeasureId,'DG2P2','99213',@Dos,NULL)
		,(@MeasureId,'DG2P2','99214',@Dos,NULL)
		,(@MeasureId,'DG2P2','99215',@Dos,NULL)
		,(@MeasureId,'DG2P2','99242',@Dos,NULL)
		,(@MeasureId,'DG2P2','99243',@Dos,NULL)
		,(@MeasureId,'DG2P2','99244',@Dos,NULL)
		,(@MeasureId,'DG2P2','99245',@Dos,NULL)
		,(@MeasureId,'DG2P2','99304',@Dos,NULL)
		,(@MeasureId,'DG2P2','99305',@Dos,NULL)
		,(@MeasureId,'DG2P2','99306',@Dos,NULL)
		,(@MeasureId,'DG2P2','99307',@Dos,NULL)
		,(@MeasureId,'DG2P2','99308',@Dos,NULL)
		,(@MeasureId,'DG2P2','99309',@Dos,NULL)
		,(@MeasureId,'DG2P2','99310',@Dos,NULL)
		,(@MeasureId,'DG2P2','99315',@Dos,NULL)
		,(@MeasureId,'DG2P2','99316',@Dos,NULL)
		,(@MeasureId,'DG2P2','99341',@Dos,NULL)
		,(@MeasureId,'DG2P2','99342',@Dos,NULL)
		,(@MeasureId,'DG2P2','99344',@Dos,NULL)
		,(@MeasureId,'DG2P2','99345',@Dos,NULL)
		,(@MeasureId,'DG2P2','99347',@Dos,NULL)
		,(@MeasureId,'DG2P2','99348',@Dos,NULL)
		,(@MeasureId,'DG2P2','99349',@Dos,NULL)
		,(@MeasureId,'DG2P2','99350',@Dos,NULL)
		,(@MeasureId,'DG2P2','99424',@Dos,NULL)
		,(@MeasureId,'DG2P2','99426',@Dos,NULL)
		
		,(@MeasureId,'DG2P3','G8694',@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G9189',@Dos,'Performance Met: Beta-blocker therapy prescribed or currently being taken')
		,(@MeasureId,'HCPCS','G9190',@Dos,'Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons)')
		,(@MeasureId,'HCPCS','G9191',@Dos,'Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons)')
		,(@MeasureId,'HCPCS','G9192',@Dos,'Denominator Exception: Documentation of system reason(s) for not prescribing beta-blocker therapy (e.g., other reasons attributable to the health care system)')
		,(@MeasureId,'HCPCS','G9188',@Dos,'Performance Not Met: Beta-blocker therapy not prescribed, reason not given')
		; -- expect 150 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '7-A'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 193
*/
-- End of 03) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 7-A.SQL
GO

-- Start of 04) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 7-B.SQL

------------------------------------------------------------------------------------
-- 04) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 7-B.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '7-B';
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
		PRINT('No Measure loaded for 7-B.  Cannot continue.');
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
		 (@MeasureId,'DG1P1','I20.0',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.2',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.8',@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.8',@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.10',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.112',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.702',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.712',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.722',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.732',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.752',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.762',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.792',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.84',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.1',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',@Dos,NULL)

		,(@MeasureId,'DG1P2','33140',@Dos,NULL)
		,(@MeasureId,'DG1P2','33509',@Dos,NULL)
		,(@MeasureId,'DG1P2','33510',@Dos,NULL)
		,(@MeasureId,'DG1P2','33511',@Dos,NULL)
		,(@MeasureId,'DG1P2','33512',@Dos,NULL)
		,(@MeasureId,'DG1P2','33513',@Dos,NULL)
		,(@MeasureId,'DG1P2','33514',@Dos,NULL)
		,(@MeasureId,'DG1P2','33516',@Dos,NULL)
		,(@MeasureId,'DG1P2','33533',@Dos,NULL)
		,(@MeasureId,'DG1P2','33534',@Dos,NULL)
		,(@MeasureId,'DG1P2','33535',@Dos,NULL)
		,(@MeasureId,'DG1P2','33536',@Dos,NULL)
		,(@MeasureId,'DG1P2','92920',@Dos,NULL)
		,(@MeasureId,'DG1P2','92924',@Dos,NULL)
		,(@MeasureId,'DG1P2','92928',@Dos,NULL)
		,(@MeasureId,'DG1P2','92933',@Dos,NULL)
		,(@MeasureId,'DG1P2','92937',@Dos,NULL)
		,(@MeasureId,'DG1P2','92941',@Dos,NULL)
		,(@MeasureId,'DG1P2','92943',@Dos,NULL)
		
		,(@MeasureId,'DG2P1','I21.01',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.02',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.09',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.11',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.19',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.21',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.29',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.3',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.4',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.9',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.A1',@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.A9',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.0',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.1',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.2',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.8',@Dos,NULL)
		,(@MeasureId,'DG2P1','I22.9',@Dos,NULL)
		
		,(@MeasureId,'DG2P2','99202',@Dos,NULL)
		,(@MeasureId,'DG2P2','99203',@Dos,NULL)
		,(@MeasureId,'DG2P2','99204',@Dos,NULL)
		,(@MeasureId,'DG2P2','99205',@Dos,NULL)
		,(@MeasureId,'DG2P2','99212',@Dos,NULL)
		,(@MeasureId,'DG2P2','99213',@Dos,NULL)
		,(@MeasureId,'DG2P2','99214',@Dos,NULL)
		,(@MeasureId,'DG2P2','99215',@Dos,NULL)
		,(@MeasureId,'DG2P2','99242',@Dos,NULL)
		,(@MeasureId,'DG2P2','99243',@Dos,NULL)
		,(@MeasureId,'DG2P2','99244',@Dos,NULL)
		,(@MeasureId,'DG2P2','99245',@Dos,NULL)
		,(@MeasureId,'DG2P2','99304',@Dos,NULL)
		,(@MeasureId,'DG2P2','99305',@Dos,NULL)
		,(@MeasureId,'DG2P2','99306',@Dos,NULL)
		,(@MeasureId,'DG2P2','99307',@Dos,NULL)
		,(@MeasureId,'DG2P2','99308',@Dos,NULL)
		,(@MeasureId,'DG2P2','99309',@Dos,NULL)
		,(@MeasureId,'DG2P2','99310',@Dos,NULL)
		,(@MeasureId,'DG2P2','99315',@Dos,NULL)
		,(@MeasureId,'DG2P2','99316',@Dos,NULL)
		,(@MeasureId,'DG2P2','99341',@Dos,NULL)
		,(@MeasureId,'DG2P2','99342',@Dos,NULL)
		,(@MeasureId,'DG2P2','99344',@Dos,NULL)
		,(@MeasureId,'DG2P2','99345',@Dos,NULL)
		,(@MeasureId,'DG2P2','99347',@Dos,NULL)
		,(@MeasureId,'DG2P2','99348',@Dos,NULL)
		,(@MeasureId,'DG2P2','99349',@Dos,NULL)
		,(@MeasureId,'DG2P2','99350',@Dos,NULL)
		,(@MeasureId,'DG2P2','99424',@Dos,NULL)
		,(@MeasureId,'DG2P2','99426',@Dos,NULL)
		
		,(@MeasureId,'DG2P3','99202',@Dos,NULL)
		,(@MeasureId,'DG2P3','99203',@Dos,NULL)
		,(@MeasureId,'DG2P3','99204',@Dos,NULL)
		,(@MeasureId,'DG2P3','99205',@Dos,NULL)
		,(@MeasureId,'DG2P3','99212',@Dos,NULL)
		,(@MeasureId,'DG2P3','99213',@Dos,NULL)
		,(@MeasureId,'DG2P3','99214',@Dos,NULL)
		,(@MeasureId,'DG2P3','99215',@Dos,NULL)
		,(@MeasureId,'DG2P3','99242',@Dos,NULL)
		,(@MeasureId,'DG2P3','99243',@Dos,NULL)
		,(@MeasureId,'DG2P3','99244',@Dos,NULL)
		,(@MeasureId,'DG2P3','99245',@Dos,NULL)
		,(@MeasureId,'DG2P3','99304',@Dos,NULL)
		,(@MeasureId,'DG2P3','99305',@Dos,NULL)
		,(@MeasureId,'DG2P3','99306',@Dos,NULL)
		,(@MeasureId,'DG2P3','99307',@Dos,NULL)
		,(@MeasureId,'DG2P3','99308',@Dos,NULL)
		,(@MeasureId,'DG2P3','99309',@Dos,NULL)
		,(@MeasureId,'DG2P3','99310',@Dos,NULL)
		,(@MeasureId,'DG2P3','99315',@Dos,NULL)
		,(@MeasureId,'DG2P3','99316',@Dos,NULL)
		,(@MeasureId,'DG2P3','99341',@Dos,NULL)
		,(@MeasureId,'DG2P3','99342',@Dos,NULL)
		,(@MeasureId,'DG2P3','99344',@Dos,NULL)
		,(@MeasureId,'DG2P3','99345',@Dos,NULL)
		,(@MeasureId,'DG2P3','99347',@Dos,NULL)
		,(@MeasureId,'DG2P3','99348',@Dos,NULL)
		,(@MeasureId,'DG2P3','99349',@Dos,NULL)
		,(@MeasureId,'DG2P3','99350',@Dos,NULL)
		,(@MeasureId,'DG2P3','99424',@Dos,NULL)
		,(@MeasureId,'DG2P3','99426',@Dos,NULL)
		; -- expect 160 total inserts
		
		-- measure code numerators -- handle seperately due to MODIFIER column update
	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		 (@MeasureId,'HCPCS','4008F',NULL,@Dos,'Performance Met: Beta-blocker therapy prescribed or currently being taken')
		,(@MeasureId,'HCPCS','4008F','1P',@Dos,'Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons)')
		,(@MeasureId,'HCPCS','4008F','2P',@Dos,'Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons)')
		,(@MeasureId,'HCPCS','4008F','3P',@Dos,'Denominator Exception: Documentation of system reason(s) for not prescribing beta-blocker therapy (e.g., other reasons attributable to the health care system)')
		,(@MeasureId,'HCPCS','4008F','8P',@Dos,'Performance Not Met: Beta-blocker therapy not prescribed, reason not otherwise specified')
		; -- expect 5 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '7-B'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 194
*/
-- End of 04) DACS-3164 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 7-B.SQL
GO

-- Start of 05) DACS-3164 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3CptTypeA].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3164 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type7A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type7A] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 7, there are 2 valid decision paths.  the data is stored by PQRS# '7-A' and '7-B' for example.  This script is designed around this example.
	-- will handle them seperately based on the MeasureId passed into this script
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9189 or 4008F
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9190 or 4008F with 1P
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9191 or 4008F with 2P
	-- returns 4 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9192 or (4008F with 3P
	-- returns 5 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9188 or (4008F with 8P
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors


	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList

	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList


	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	DECLARE @gender VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempChartInfo);

	IF (@gender IS NULL OR @gender IN ('U', 'X')) SET @gender = 'B';
	
	IF @gender <> 'B'
	BEGIN 
		DECLARE @genderCheck VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempMeasureInfo);
		
		IF @genderCheck IS NULL SET @genderCheck = 'B';

		IF @gender <> @genderCheck AND @genderCheck <> 'B'
		BEGIN 
			PRINT('@ChartId does not match gender test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not match gender test', 'Code' = 'ERR-0-GEN';
			RETURN;
		END;
	END;

	PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	
	SELECT TOP 1 
		@PSP_CPT = [CPT_CODE]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorGroup2Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2');
	DECLARE @foundDenominatorGroup2Pick3MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P3 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P3 records';
		RETURN;
	END;

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	-- do we have a History of cardiac surgery (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (coronary artery disease) OR (cardiac surgery)', 'Code' = 'ERR-1-NCA';
		RETURN;
	END;

	-- Patient encounter during performance period – to be used for numerator evaluation (CPT)
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period)', 'Code' = 'ERR-2-NPE';
		RETURN;
	END;

	-- At least one additional patient encounter during performance period (CPT)
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2'));

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (At least one additional patient encounter during performance period)', 'Code' = 'ERR-3-NPP';
		RETURN;
	END;

	-- Left ventricular ejection fraction (LVEF) (CPT/HCPCS)
	SET @foundDenominatorGroup2Pick3MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'));

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Left ventricular ejection fraction)', 'Code' = 'ERR-4-NLV';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Performance Met: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9189 or 4008F
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9190 or 4008F with 1P
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9191 or 4008F with 2P
	-- returns 4 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9192 or (4008F with 3P
	-- returns 5 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9188 or (4008F with 8P

	DECLARE @foundG9189Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9189');  /*@ResultPerformanceCodeMet*/

	IF @foundG9189Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'G9189';
		RETURN;
	END;

	DECLARE @foundG9188Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9188');  /*@ResultPerformanceCodeNotMet*/

	IF @foundG9188Count >= 0
	BEGIN 
		SELECT 'Result' = 5, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'G9188';
		RETURN;
	END;

	DECLARE @foundG9190Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9190');  /*@ResultPerformanceCodeExMet*/

	IF @foundG9190Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G9190';
		RETURN;
	END;

	DECLARE @foundG9191Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9191');  /*@ResultPerformanceCodeExMet*/

	IF @foundG9191Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G9191';
		RETURN;
	END;

	DECLARE @foundG9192Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G9192');  /*@ResultPerformanceCodeExMet*/

	IF @foundG9192Count >= 0
	BEGIN 
		SELECT 'Result' = 4, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G9192';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (G9189,G9190,G9191,G9192,G9188)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '7-A'
begin tran; -- testing
*/
-- End of 05) DACS-3164 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3CptTypeA].SQL
GO

-- Start of 06) DACS-3164 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type7B].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3164 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type7B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type7B] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 7, there are 2 valid decision paths.  the data is stored by PQRS# '7-A' and '7-B' for example.  This script is designed around this example.
	-- will handle them seperately based on the MeasureId passed into this script
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9189 or 4008F
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9190 or 4008F with 1P
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9191 or 4008F with 2P
	-- returns 4 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9192 or (4008F with 3P
	-- returns 5 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9188 or (4008F with 8P
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors


	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList

	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList


	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	DECLARE @gender VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempChartInfo);

	IF (@gender IS NULL OR @gender IN ('U', 'X')) SET @gender = 'B';
	
	IF @gender <> 'B'
	BEGIN 
		DECLARE @genderCheck VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempMeasureInfo);
		
		IF @genderCheck IS NULL SET @genderCheck = 'B';

		IF @gender <> @genderCheck AND @genderCheck <> 'B'
		BEGIN 
			PRINT('@ChartId does not match gender test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not match gender test', 'Code' = 'ERR-0-GEN';
			RETURN;
		END;
	END;

	PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE]
		, ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	
	SELECT TOP 1 
		@PSP_CPT = [CPT_CODE]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorGroup2Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2');
	DECLARE @foundDenominatorGroup2Pick3MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P3 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P3 records';
		RETURN;
	END;

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	-- do we have a History of cardiac surgery (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (coronary artery disease) OR (cardiac surgery)', 'Code' = 'ERR-1-NCA';
		RETURN;
	END;

	-- Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM):
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (prior (within the past 3 years) myocardial infarction)', 'Code' = 'ERR-2-NMI';
		RETURN;
	END;

	-- Patient encounter during performance period – to be used for numerator evaluation (CPT)
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2'));

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (At least one additional patient encounter during performance period)', 'Code' = 'ERR-3-NPP';
		RETURN;
	END;

	-- At least one additional patient encounter during performance period (CPT)
	SET @foundDenominatorGroup2Pick3MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'));

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Left ventricular ejection fraction)', 'Code' = 'ERR-4-NAP';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Performance Met: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G9189 or 4008F
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9190 or 4008F with 1P
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9191 or 4008F with 2P
	-- returns 4 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G9192 or 4008F with 3P
	-- returns 5 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G9188 or 4008F with 8P

	DECLARE @found4008FCount INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F');  /*@ResultPerformanceCodeMet*/

	IF @found4008FCount >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = '4008F';
		RETURN;
	END;

	DECLARE @found4008F8PCount INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F' AND [MODIFIERS] LIKE '%8P%');  /*@ResultPerformanceCodeNotMet*/

	IF @found4008F8PCount >= 0
	BEGIN 
		SELECT 'Result' = 5, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = '4008F+8P';
		RETURN;
	END;

	DECLARE @found4008F1PCount INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F' AND [MODIFIERS] LIKE '%1P%');  /*@ResultPerformanceCodeExMet*/

	IF @found4008F1PCount >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = '4008F+1P';
		RETURN;
	END;

	DECLARE @found4008F2PCount INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F' AND [MODIFIERS] LIKE '%2P%');  /*@ResultPerformanceCodeExMet*/

	IF @found4008F1PCount >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = '4008F+2P';
		RETURN;
	END;

	DECLARE @found4008F3PCount INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = '4008F' AND [MODIFIERS] LIKE '%3P%');  /*@ResultPerformanceCodeExMet*/

	IF @found4008F3PCount >= 0
	BEGIN 
		SELECT 'Result' = 4, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = '4008F+3P';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (4008F,4008F+1P,4008F+2P,4008F+3P,4008F+8P)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '7-A'
begin tran; -- testing
*/
-- End of 06) DACS-3164 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type7B].SQL
GO

-- Start of 07) DACS-3164 - Create of Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL

------------------------------------------------------------------------------------
-- 07) DACS-3164 - Create of Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL
------------------------------------------------------------------------------------
GO

/****** Object:  StoredProcedure [dbo].[spSelectChartPqrs]    Script Date: 4/22/2024 5:48:40 PM ******/
GO

GO

CREATE OR ALTER PROCEDURE [dbo].[spSelectChartPqrs] 
	@ChartId INT,
	@MeasureId INT = NULL,
	@MeasureCodeId INT = NULL
	WITH
EXEC AS CALLER AS

------------------------------------------------------------------------------------
-- Adds additional CODING_SYSTEM strings used within the various temporary tables to allow for extended behavior supporting new MIPS decision logic - DACS-3164 - 20240422 - pippin
------------------------------------------------------------------------------------

-- testing
-- DECLARE @ChartId INT = 2100107114;
-- DECLARE @MeasureId INT = NULL;
-- DECLARE @MeasureCodeId INT = NULL;
-- body of original SPROC -- >

DECLARE @chart_id INT = @ChartId;
DECLARE @measure_id INT = @MeasureId;
DECLARE @measure_code_id INT = @MeasureCodeId;
DECLARE @Now DATETIME = GETDATE();
DECLARE @flag VARCHAR(10) = '';
DECLARE @HasDXCode INT;
DECLARE @HasCPTCode INT;

Declare @PSP_CPT varchar(50)	-- added 2/21/2023 (dsexton)

-- Drop statements for new temp tables added 2/21/2023 (dsexton)
if object_id('TempDB..#MeasureList', 'U') is not null DROP TABLE #MeasureList;
if object_id('TempDB..#RequireCptMeasures', 'U') is not null DROP TABLE #RequireCptMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures2', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures2;
if object_id('TempDB..#RequiredMeasures2', 'U') is not null DROP TABLE #RequiredMeasures2;
if object_id('TempDB..#RequiredMeasuresOldLogic', 'U') is not null DROP TABLE #RequiredMeasuresOldLogic;
if object_id('TempDB..#Chart', 'U') is not null DROP TABLE #Chart;
if object_id('TempDB..#ChartDiagCode9', 'U') is not null DROP TABLE #ChartDiagCode9;
if object_id('TempDB..#ChartDiagCodeICD10', 'U') is not null DROP TABLE #ChartDiagCodeICD10;
if object_id('TempDB..#PPE_CPT', 'U') is not null DROP TABLE #PPE_CPT;

-- new temp table for tuning, 2/21/2023 (dsexton)
select chart_ID, service_agreement_ID, primary_complaint, chief_complaint, PHYSICIAN_SERVICE_PROC_ID, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
	, Time_of_Service, gender, patient_DOB, patient_age
  into #Chart	
from CHART
where chart_ID = @chart_id

-- select * from #Chart -- testing

/*
This sproc executes very frequently at certain times of the day. For example, on 2/21/2023 it executed nearly 8K times between 4:30-7:30 AM. By 3 pm it executed only an additional 3,500 times.
It is called by sproc spSelectMissingChartPqrs which has executed 37K times over the past seven days. 
Avg LReads have been 150K which adds up to several billion reads each day. 

Modified all CLR queries to instead write to temp tables, 2/21/2023 (dsexton).  This reduced logical reads 95% (13K vs 240K) when testing with chart_ID 101104526.
	-- Duration was reduced 80% (31ms vs 184ms).
*/


--WITH MeasureList						-- replaced all CLR queries with temp tables, 2/21/2023 (dsexton)
--AS (
	SELECT cpm.CMS_PQRI_MEASURE_ID,
		cpm.MEASURE_TITLE,
		cpm.REQUIRES_BOTH_CPT_AND_DX,
		cpmc.CMS_PQRI_MEASURE_CODE_ID,
		cpmc.CODING_SYSTEM,
		cpmc.OPTION_GROUP,
		cpmc.CODE,
		cpmc.MODIFIER,
		cpmc.[DESCRIPTION],
		CASE 
			WHEN cpmc.END_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.END_DATE 
			END END_DATE,
		cpmc.CODE_2,
		cpmc.MODIFIER_2,
		cpm.REQUIRES_MULTIPLE_CPTS,
		cpm.MULTIPLE_CPT_COUNT,
		cpm.REQUIRES_MULTIPLE_DX,
		cpm.REQUIRES_CPT_CODE,
		cpm.REQUIRED_CPT_CODE,
		CASE 
			WHEN COALESCE(cpm.REQUIRES_EM_ONLY, 0) = 1
				AND (c.PHYSICIAN_SERVICE_PROC_ID > 0 OR c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0)
				THEN 1
			ELSE 0
			END REQUIRES_EM_ONLY,
		CASE 
			WHEN COALESCE(cpm.MATCH_EM_LEVEL, 0) = 1
				THEN 1
			ELSE 0
			END MATCH_EM_LEVEL,
		CASE 
			WHEN cpmc.START_DATE IS NULL
				THEN '1/1/1900 00:00:00'
			ELSE cpmc.START_DATE
			END START_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE IS NULL
				THEN '02/20/2020 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
	    CONVERT(Date, c.TIME_OF_SERVICE) as DATE_OF_SERVICE
into #MeasureList							-- tuning, 2/21/2023 (dsexton)
	FROM CMS_PQRI_MEASURE cpm WITH (NOLOCK)
	LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc WITH (NOLOCK) ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID
	--INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
	cross join #Chart c		--ON c.CHART_ID = @chart_id
	WHERE DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, c.TIME_OF_SERVICE)
		AND (
			ISNULL(cpm.GENDER, 'B') = 'B'
			OR cpm.GENDER = c.GENDER
			)
		AND (
			(
				(COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) = 0
				AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0)) = 999
				)
			OR (
				(c.PATIENT_AGE IS NOT NULL AND c.PATIENT_DOB IS NULL
				AND c.PATIENT_AGE BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				))
			
			OR (
				(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NOT NULL OR cpm.TO_AGE_FRACTIONAL IS NOT NULL)
				AND ((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				)
			
			OR (
			(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NULL AND cpm.TO_AGE_FRACTIONAL IS NULL)
				AND CAST(((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) AS INT) BETWEEN COALESCE(cpm.FROM_AGE, 0)  AND COALESCE(cpm.TO_AGE, 999)
				)
			)

		AND cpm.CMS_PQRI_MEASURE_ID IN (
			SELECT sapqrs.CMS_PQRI_MEASURE_ID
			FROM SERVICE_AGREEMENT_PQRS sapqrs WITH (NOLOCK)
			WHERE sapqrs.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND CONVERT(Date, c.TIME_OF_SERVICE) BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, @Now)
			)
	--),

-- select '#MeasureList' = null
-- select * from #MeasureList where measure_title like '%332%' OR measure_title like '% 7-%' -- testing


-- New objects for tuning, 2/21/2023 (dsexton)  -------------------------------------------------------------------------------

SELECT cdc.ICD9_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, c.CHIEF_COMPLAINT, c.PRIMARY_COMPLAINT, c.Time_of_Service
  into #ChartDiagCode9
FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID

SELECT cdc.ICD10_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, cdc.DIAGNOSIS_TYPE_ID, cdc.IS_PRIMARY, c.Time_of_Service
  into #ChartDiagCodeICD10
FROM CHART_DIAGNOSIS_CODE_ICD10 cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID

SELECT cm.CPT_Code
  into #PPE_CPT
FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
	and ppe.CHART_ID = @chart_id	

select TOP 1 @PSP_CPT = CPT_CODE
FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
INNER JOIN #Chart c 
on PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
WHERE PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
        WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
            THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
        ELSE c.PHYSICIAN_SERVICE_PROC_ID
        END
-------------------------------------------------------------------------------------------------------------------

--RequiredMeasuresOldLogic
--AS (
SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		ROW_NUMBER() OVER (
			PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE
into #RequiredMeasuresOldLogic	-- tuning, 2/21/2023 (dsexton)
	--FROM MeasureList ml
	from #MeasureList ml		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE (
			ml.CODING_SYSTEM = 'I9'
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR (cdc.DIAGNOSIS_TYPE_ID IN (1,3,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			OR (
				ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select 1 from #PPE_CPT as t where t.CPT_Code = ml.Code		-- tuning to replace old subquery, 2/21/2023 (dsexton)
					)
				)
			)
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
      ml.REQUIRES_EM_ONLY = 1
      AND 
			@PSP_CPT	 -- tuning to replace subquery, 2/21/2023 (dsexton)
			  IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395')
    )
--	)
-- select '#RequiredMeasuresOldLogic' = null
-- select * from #RequiredMeasuresOldLogic where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--,
--RequiredDiagnosisMeasures
--AS (

	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE
into #RequiredDiagnosisMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 		   
		  ml.CODING_SYSTEM = 'I9'
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 1)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			

--    )
	  
-- select '#RequiredDiagnosisMeasures' = null
-- select * from #RequiredDiagnosisMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
	
--	,
--	RequiredDiagnosisMeasures2
--AS (
	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE
into #RequiredDiagnosisMeasures2
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 
		   
		  ml.CODING_SYSTEM = 'I9'
			AND EXISTS (
			/*	-- example of old subquery, 2/21/2023 (dsexton)
				SELECT *
				FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
				INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = cdc.CHART_ID
				INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				WHERE cdc.CHART_ID = @chart_id
			*/
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 0)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						)
			
			)
 --   )
	  
-- select '#RequiredDiagnosisMeasures2' = null
-- select * from #RequiredDiagnosisMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--	,
--	RequireCptMeasures
--AS (
     SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE
into #RequireCptMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					SELECT *
					FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
					INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
					WHERE ppe.CHART_ID = @chart_id
						AND cm.CPT_CODE = ml.CODE
						AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					)
				
			
			
			
			
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
		ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
      AND  (
              SELECT  CPT_CODE
              FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
              INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
              WHERE PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                  AND PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
                      WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
                          THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                      ELSE c.PHYSICIAN_SERVICE_PROC_ID
                      END 
              ) = ml.Code
			  AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
			  )
--),

-- select '#RequireCptMeasures' = null
-- select * from #RequireCptMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--	RequiredMeasures2
--AS (
   
    SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
		rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
into #RequiredMeasures2
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		
		UNION
		SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
        rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS = 1
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		GROUP BY rdm.CMS_PQRI_MEASURE_ID, rdm.MEASURE_TITLE, rdm.REQUIRES_BOTH_CPT_AND_DX, rdm.CMS_PQRI_MEASURE_CODE_ID, rdm.CODING_SYSTEM, rdm.OPTION_GROUP, rdm.CODE, rdm.MODIFIER, rdm.[DESCRIPTION], rdm.END_DATE, rdm.CODE_2, rdm.MODIFIER_2, rdm.REQUIRES_EM_ONLY, rcm.MULTIPLE_CPT_COUNT
		HAVING COUNT(rcm.CODE) = rcm.MULTIPLE_CPT_COUNT

		UNION
		SELECT rdm2.CMS_PQRI_MEASURE_ID,
		rdm2.MEASURE_TITLE,
		rdm2.REQUIRES_BOTH_CPT_AND_DX,
		rdm2.CMS_PQRI_MEASURE_CODE_ID,
		rdm2.CODING_SYSTEM,
		rdm2.OPTION_GROUP,
		rdm2.CODE,
		rdm2.MODIFIER,
        rdm2.[DESCRIPTION],
		rdm2.END_DATE,
		rdm2.CODE_2,
		rdm2.MODIFIER_2,
		rdm2.REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rdm2.CMS_PQRI_MEASURE_ID ORDER BY rdm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures2 rdm2
		from #RequiredDiagnosisMeasures2 rdm2															-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID				-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		AND rdm2.CODE IS NOT NULL
		UNION
		
		SELECT rmol.CMS_PQRI_MEASURE_ID,
		rmol.MEASURE_TITLE,
		rmol.REQUIRES_BOTH_CPT_AND_DX,
		rmol.CMS_PQRI_MEASURE_CODE_ID,
		rmol.CODING_SYSTEM,
		rmol.OPTION_GROUP,
		rmol.CODE,
		rmol.MODIFIER,
		rmol.[DESCRIPTION],
		rmol.END_DATE,
		rmol.CODE_2,
		rmol.MODIFIER_2,
		rmol.REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rmol.CMS_PQRI_MEASURE_ID ORDER BY rmol.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredMeasuresOldLogic rmol
		from #RequiredMeasuresOldLogic rmol			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		WHERE rmol.REQUIRES_BOTH_CPT_AND_DX = 1
		AND CONVERT(Date, rmol.DATE_OF_SERVICE) < rmol.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
		AND rmol.CODE IS NOT NULL
		
		
		UNION
		 
		SELECT rcm.CMS_PQRI_MEASURE_ID,
		rcm.MEASURE_TITLE,
		rcm.REQUIRES_BOTH_CPT_AND_DX,
		rcm.CMS_PQRI_MEASURE_CODE_ID,
		rcm.CODING_SYSTEM,
		rcm.OPTION_GROUP,
		rcm.CODE,
		rcm.MODIFIER,
		rcm.[DESCRIPTION],
		rcm.END_DATE,
		rcm.CODE_2,
		rcm.MODIFIER_2,
		REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rcm.CMS_PQRI_MEASURE_ID ORDER BY rcm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm
		from #RequireCptMeasures rcm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND COALESCE(rcm.REQUIRES_CPT_CODE, 0) = 0
		AND rcm.CODE IS NOT NULL

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		 

		 UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--)

-- select '#RequiredMeasures2' = null
-- select * from #RequiredMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

	
SELECT DISTINCT CMS_PQRI_MEASURE_ID,
	MEASURE_TITLE,
	CMS_PQRI_MEASURE_CODE_ID,
	CODING_SYSTEM,
	NULL OPTION_GROUP,
	CASE COALESCE(REQUIRES_EM_ONLY, 0)
		WHEN 1
			THEN 'E&M'
		ELSE CODE
		END CODE,
	NULL MODIFIER,
	NULL [DESCRIPTION],
	NULL END_DATE,
	NULL CODE_2,
	NULL MODIFIER_2,
	CAST([ROW_NUMBER] AS BIGINT) [ROW_NUMBER]
--FROM RequiredMeasures2
from #RequiredMeasures2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
WHERE @measure_id IS NULL
	AND @measure_code_id IS NULL
	AND [ROW_NUMBER] = 1

UNION

SELECT ml.CMS_PQRI_MEASURE_ID,
	ml.MEASURE_TITLE,
	ml.CMS_PQRI_MEASURE_CODE_ID,
	ml.CODING_SYSTEM,
	ml.OPTION_GROUP,
	ml.CODE,
	ml.MODIFIER,
	ml.[DESCRIPTION],
	ml.END_DATE,
	ml.CODE_2,
	ml.MODIFIER_2,
	NULL [ROW_NUMBER]
--FROM MeasureList ml
from #MeasureList ml						-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--INNER JOIN RequiredMeasures2 rm ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
INNER JOIN #RequiredMeasures2 rm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
WHERE (
		ml.CMS_PQRI_MEASURE_ID = @measure_id
		OR ml.CMS_PQRI_MEASURE_CODE_ID = @measure_code_id
		)
	AND ml.CODING_SYSTEM IN (
		'CPT_II',
		'HCPCS'
		)
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
	
ORDER BY CMS_PQRI_MEASURE_ID ASC,
	MEASURE_TITLE DESC

GO

-- EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
-- GO


-- End of 07) DACS-3164 - Create of Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL
GO

-- Start of 01) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 8-A.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 8-A.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '8-A';
	DECLARE @Dos DATETIME = '01-01-2024' --GETDATE();

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [REQ_2_DX_OR_3CPT] = 1
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 '8-A'
				,'Efficiency and Cost Reduction'
				,'PQRS# 8-A [Requires 8-B also be added to Service Agreement for full MIPS functionality] Heart Failure (HF): Beta-Blocker Therapy for Left Ventricular Systolic Dysfunction (LVSD)'	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);



	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '8-A'
*/
-- End of 01) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 8-A.SQL
GO

-- Start of 02) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 8-B.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 8-B.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '8-B';
	DECLARE @Dos DATETIME = '01-01-2024' --GETDATE();

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('Updating...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [REQ_2_DX_OR_3CPT] = 1
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 '8-B'
				,'Efficiency and Cost Reduction'
				,'PQRS# 8-B [Requires 8-A also be added to Service Agreement for full MIPS functionality] Heart Failure (HF): Beta-Blocker Therapy for Left Ventricular Systolic Dysfunction (LVSD)'	
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);



	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '8-B'
*/
-- End of 02) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 8-B.SQL
GO

-- Start of 03) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 8-A.SQL

------------------------------------------------------------------------------------
-- 03) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 8-A.SQL
------------------------------------------------------------------------------------
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
-- End of 03) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 8-A.SQL
GO

-- Start of 04) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 8-B.SQL

------------------------------------------------------------------------------------
-- 04) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 8-B.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '8-B';
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
		PRINT('No Measure loaded for 8-B.  Cannot continue.');
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
		
		,(@MeasureId,'DG1P2','99238',@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',@Dos,NULL)
		
		,(@MeasureId,'DG2P1','G8923',@Dos,NULL)
		
		,(@MeasureId,'DG2P2','M1152',@Dos,NULL)  -- EXCLUDE codes
		
		--,(@MeasureId,'DG2P3','?????',@Dos,NULL)  -- Group not needed for this PQRI Rule
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8450',@Dos,'Performance Met: Beta-blocker therapy prescribed')
		,(@MeasureId,'HCPCS','G8451',@Dos,'Denominator Exception: Beta-Blocker Therapy for LVEF ≤ 40% not prescribed for reasons documented by the clinician (e.g., low blood pressure, fluid overload, asthma, patients recently treated with an intravenous positive inotropic agent, allergy, intolerance, other medical reasons, patient declined, other patient reasons)')
		,(@MeasureId,'HCPCS','G8452',@Dos,'Performance Not Met: Beta-blocker therapy not prescribed')
		; -- expect 29 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '8-B'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 197
*/
-- End of 04) DACS-3165 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 8-B.SQL
GO

-- Start of 05) DACS-3165 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type8A].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3165 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type8A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type8A] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 8, there are 2 valid decision paths.  the data is stored by PQRS# '8-A' and '8-B' for example.  This script is designed around this example.
	-- will handle them seperately based on the MeasureId passed into this script
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G8450
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G8451
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G8452
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors


	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList

	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList


	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	DECLARE @gender VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempChartInfo);

	IF (@gender IS NULL OR @gender IN ('U', 'X')) SET @gender = 'B';
	
	IF @gender <> 'B'
	BEGIN 
		DECLARE @genderCheck VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempMeasureInfo);
		
		IF @genderCheck IS NULL SET @genderCheck = 'B';

		IF @gender <> @genderCheck AND @genderCheck <> 'B'
		BEGIN 
			PRINT('@ChartId does not match gender test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not match gender test', 'Code' = 'ERR-0-GEN';
			RETURN;
		END;
	END;

	PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	
	SELECT TOP 1 
		@PSP_CPT = [CPT_CODE]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorGroup2Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2');
	DECLARE @foundDenominatorGroup2Pick3MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P3 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P3 records';
		RETURN;
	END;

	-- do we have a Diagnosis for heart failure (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for heart failure)', 'Code' = 'ERR-1-NHF';
		RETURN;
	END;

	-- do we have Patient encounter during performance period – to be used for numerator evaluation (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period)', 'Code' = 'ERR-2-NPP';
		RETURN;
	END;

	-- do we have At least one additional patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (At least one additional patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NAP';
		RETURN;
	END;

	-- do we have Left ventricular ejection fraction (LVEF) ≤ 40% or documentation of moderately or severely depressed left ventricular systolic function?
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2'));

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Left ventricular ejection fraction (LVEF) ≤ 40% or documentation of moderately or severely depressed left ventricular systolic function)', 'Code' = 'ERR-4-NAP';
		RETURN;
	END;

	-- EXCLUSION CHECK: do we have Patients with a history of heart transplant or with a Left Ventricular Assist Device (LVAD)?
	SET @foundDenominatorGroup2Pick3MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'));

	IF @foundDenominatorGroup2Pick3MatchCount > 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Found Patients with a history of heart transplant or with a Left Ventricular Assist Device (LVAD):)', 'Code' = 'ERR-5-NEH';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G8450
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G8451
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G8452

	DECLARE @foundG8450Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8450');  /*@ResultPerformanceCodeMet*/

	IF @foundG8450Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'G8450';
		RETURN;
	END;

	DECLARE @foundG8452Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8452');  /*@ResultPerformanceCodeNotMet*/

	IF @foundG8452Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'G8452';
		RETURN;
	END;

	DECLARE @foundG8451Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8451');  /*@ResultPerformanceCodeExMet*/

	IF @foundG8451Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G8451';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (G8450,G8451,G8452)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '8-A'
begin tran; -- testing
*/
-- End of 05) DACS-3165 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type8A].SQL
GO

-- Start of 06) DACS-3165 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type8B].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3165 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type8B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type8B] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 8, there are 2 valid decision paths.  the data is stored by PQRS# '8-A' and '8-B' for example.  This script is designed around this example.
	-- will handle them seperately based on the MeasureId passed into this script
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G8450
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G8451
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G8452
	
	-- returns 911 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + But no codes in chart already found for denominator value) - ????
	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors


	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList

	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList


	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		PRINT('@MeasureId returned no data : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		PRINT('@MeasureId does not support this test : ' + CAST(@MeasureId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	DECLARE @gender VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempChartInfo);

	IF (@gender IS NULL OR @gender IN ('U', 'X')) SET @gender = 'B';
	
	IF @gender <> 'B'
	BEGIN 
		DECLARE @genderCheck VARCHAR(1) = (SELECT TOP 1 UPPER([GENDER]) from #tempMeasureInfo);
		
		IF @genderCheck IS NULL SET @genderCheck = 'B';

		IF @gender <> @genderCheck AND @genderCheck <> 'B'
		BEGIN 
			PRINT('@ChartId does not match gender test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not match gender test', 'Code' = 'ERR-0-GEN';
			RETURN;
		END;
	END;

	PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			PRINT('@ChartId does not have a valid Date of Service to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			PRINT('@ChartId does not have a valid age or DOB to test : ' + CAST(@ChartId AS VARCHAR(30)));
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			PRINT('@ChartId does not fall within age test : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
		
		PRINT ('Age criteria satisfied to continue comparisons.');
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	
	SELECT TOP 1 
		@PSP_CPT = [CPT_CODE]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 
	IF (NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		PRINT('@ChartId returned no Procedure Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList))
	BEGIN
		PRINT('@ChartId returned no Diagnosis Codes : ' + CAST(@ChartId AS VARCHAR(3)));
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		PRINT('No Denominator Pick List records found : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorGroup2Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2');
	-- DECLARE @foundDenominatorGroup2Pick3MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'); -- This PQRI Rule only has 4 decision groups.
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG1P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P1 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick2MatchCount <= 0
	BEGIN
		PRINT('Missing Denominator DG2P2 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P2 records';
		RETURN;
	END;

	-- This PQRI Rule only has 4 decision groups.
	-- IF @foundDenominatorGroup2Pick3MatchCount <= 0
	-- BEGIN
		-- PRINT('Missing Denominator DG2P3 records : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		-- SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P3 records';
		-- RETURN;
	-- END;

	-- do we have a Diagnosis for heart failure (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for heart failure)', 'Code' = 'ERR-1-NHF';
		RETURN;
	END;

	-- do we have Patient encounter during performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during performance period)', 'Code' = 'ERR-2-NPP';
		RETURN;
	END;

	-- do we have Left ventricular ejection fraction (LVEF) ≤ 40% or documentation of moderately or severely depressed left ventricular systolic function?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (At least one additional patient encounter during performance period (CPT))', 'Code' = 'ERR-3-NLV';
		RETURN;
	END;

	-- EXCLUSION CHECK: do we have Patients with a history of heart transplant or with a Left Ventricular Assist Device (LVAD)?
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2'));

	IF @foundDenominatorGroup2Pick2MatchCount > 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Found Patients with a history of heart transplant or with a Left Ventricular Assist Device (LVAD):)', 'Code' = 'ERR-4-NEH';
		RETURN;
	END;

	-- all Data Completion steps satisified.
	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G8450
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G8451
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G8452

	DECLARE @foundG8450Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8450');  /*@ResultPerformanceCodeMet*/

	IF @foundG8450Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'G8450';
		RETURN;
	END;

	DECLARE @foundG8452Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8452');  /*@ResultPerformanceCodeNotMet*/

	IF @foundG8452Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'G8452';
		RETURN;
	END;

	DECLARE @foundG8451Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8451');  /*@ResultPerformanceCodeExMet*/

	IF @foundG8451Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G8451';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (G8450,G8451,G8452)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '8-B'
begin tran; -- testing
*/
-- End of 06) DACS-3165 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type8B].SQL
GO

-- Start of 01) DACS-3241 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Inpatient Downgrade].SQL

----------------------------------------------------
-- 01) DACS-3241 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Inpatient Downgrade].SQL
----------------------------------------------------
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 7)
BEGIN
	PRINT('Adding [dbo].[ChartPostBillAuditReasonTypeCode] item [Inpatient Downgrade]');
	INSERT 
		INTO [dbo].[ChartPostBillAuditReasonTypeCode] 
			([ChartPostBillAuditReasonTypeCode], [Key], [DisplayName], [ExternalCode], [Description])
	VALUES 
		(7, 'InpatientDowngrade', 'Inpatient Downgrade', 'IDG', 'Inpatient Downgrade');
END;

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 7)
BEGIN
	PRINT('!!!! Failed to add [ChartPostBillAuditReasonTypeCode] item [Inpatient Downgrade] !!!!');
END;

GO

/*
testing: 
SELECT TOP (1000) [ChartPostBillAuditReasonTypeCode]
      ,[Key]
      ,[DisplayName]
      ,[ExternalCode]
      ,[Description]
  FROM [RevCycleDB].[dbo].[ChartPostBillAuditReasonTypeCode]
---
begin tran;
*/

-- End of 01) DACS-3241 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Inpatient Downgrade].SQL
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
