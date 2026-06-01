USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 118-A.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 118-A.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '118-A';
	DECLARE @Dos DATETIME = '01-01-2024' -- GETDATE();

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
				 '118-A'
				,'Clinical Quality Measures'
				,'MIPS# 118-A [Requires 118-B for full functionality] Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF < 40%)'	
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-A' -- = 199
*/
-- End of 01) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 118-A.SQL
GO

-- Start of 02) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 118-B.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 118-B.SQL
------------------------------------------------------------------------------------
GO

--begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


	DECLARE @PqrsCd VARCHAR(20) = '118-B';
	DECLARE @Dos DATETIME = '01-01-2024' -- GETDATE();

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
				 '118-B'
				,'Clinical Quality Measures'
				,'MIPS# 118-B [Requires 118-A for full functionality] Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF < 40%)'	
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-B' -- = 200
*/
-- End of 02) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 118-B.SQL
GO

-- Start of 03) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-A.SQL

------------------------------------------------------------------------------------
-- 03) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-A.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '118-A';
	DECLARE @Dos DATETIME = '01-01-2024'; -- GETDATE();

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
		PRINT('No Measure loaded for 118-A.  Cannot continue.');
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


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.A1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.A9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',NULL,@Dos,NULL)

		,(@MeasureId,'DG1P2','99201',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99241',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99324',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99325',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99326',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99327',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99328',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99334',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99335',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99336',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99337',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99343',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)

--cannot have these modifiers EXCEPTION
		,(@MeasureId,'DG2P1',NULL,'GQ',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'GT',@Dos,NULL)
		,(@MeasureId,'DG2P1',NULL,'95',@Dos,NULL)
 
-- !!! AND have to check that the telehealth use code is NOT POS 02.  for now till just check the ACS chart telehealth flag field for set ot not.!!!
		
-- !!!check for "Two Denominator Eligible Visits"  will likely need a UI question but will check for the CPT codes again for now.!!!
		,(@MeasureId,'DG2P2','99201',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99241',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99324',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99325',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99326',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99327',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99328',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99334',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99335',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99336',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99337',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99343',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P2','99350',NULL,@Dos,NULL)
		
		,(@MeasureId,'DG2P3','G8934',NULL,@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8935',NULL,@Dos,'Performance Met: Clinician prescribed angiotensin converting enzyme(ACE) inhibitor or angiotensin receptor blocker (ARB) therapy')
		,(@MeasureId,'HCPCS','G8936',NULL,@Dos,'Denominator Exception: Clinician documented that patient was not an eligible candidate for angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy (eg, allergy, intolerance, pregnancy, renal failure due to ACE inhibitor, diseases of the aortic or mitral valve, other medical reasons) or (eg, patient declined, other patient reasons) or (eg, lack of drug availability, other reasons attributable to the health care system) ')
		,(@MeasureId,'HCPCS','G8937',NULL,@Dos,'Performance Not Met: Clinician did not prescribe angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy, reason not given')
		; -- expect 156 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-A' -- = 199
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 199
*/
-- End of 03) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-A.SQL
GO

-- Start of 04) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-B.SQL

------------------------------------------------------------------------------------
-- 04) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-B.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '118-B';
	DECLARE @Dos DATETIME = '01-01-2024'; -- GETDATE();

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
		PRINT('No Measure loaded for 118-B.  Cannot continue.');
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


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- measure code denominators
		 (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I21.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I22.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',NULL,@Dos,NULL)

		,(@MeasureId,'DG1P2','E10.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E10.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E11.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3211',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3219',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3292',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3293',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3299',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3391',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3392',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3393',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3399',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3412',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3413',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3491',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3492',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3493',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3499',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3521',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3522',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3523',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3529',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3531',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3532',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3539',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3541',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3542',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3543',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3549',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3551',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3552',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3553',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3559',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3591',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3592',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3593',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.3599',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.36',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.37X1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.37X2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.37X3',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.37X9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.39',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.42',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.43',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.44',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.49',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.52',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.610',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.618',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.620',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.621',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.622',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.628',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.630',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.638',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.641',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.649',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.65',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.69',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','E13.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.012',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.013',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.03',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.0111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.0112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.0113',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.0119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.12',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.13',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.311',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.312',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.313',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.319',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.32',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.33',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.813',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.819',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','O24.83',NULL,@Dos,NULL)

		,(@MeasureId,'DG2P1','99201',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99241',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99324',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99325',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99326',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99327',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99328',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99334',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99335',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99336',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99337',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99343',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','99350',NULL,@Dos,NULL)

--cannot have these modifiers EXCEPTION
		,(@MeasureId,'DG2P2',NULL,'GQ',@Dos,NULL)
		,(@MeasureId,'DG2P2',NULL,'GT',@Dos,NULL)
		,(@MeasureId,'DG2P2',NULL,'95',@Dos,NULL)

-- !!! AND have to check that the telehealth use code is NOT POS 02.  for now till just check the ACS chart telehealth flag field for set or not.!!!
 		
-- !!!check for "Two Denominator Eligible Visits"  will likely need a UI question but will check for the CPT codes again for now.!!!
		,(@MeasureId,'DG2P3','99201',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99241',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99242',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99243',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99244',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99245',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99324',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99325',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99326',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99327',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99328',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99334',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99335',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99336',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99337',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99343',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P3','99350',NULL,@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G8473',NULL,@Dos,'Performance Met: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy prescribed')
		,(@MeasureId,'HCPCS','G8474',NULL,@Dos,'Denominator Exception: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy not prescribed for reasons documented by the clinician (eg, allergy, intolerance, pregnancy, renal failure due to ACE inhibitor, diseases of the aortic or mitral valve, other medical reasons) or (eg, patient declined, other patient reasons) or (eg, lack of drug availability, other reasons attributable to the health care system)')
		,(@MeasureId,'HCPCS','G8475',NULL,@Dos,'Performance Not Met: Angiotensin converting enzyme (ACE) inhibitor or angiotensin receptor blocker (ARB) therapy not prescribed, reason not given')
		; -- expect 428 total inserts
				
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-B' -- = 200
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 200
*/
-- End of 04) DACS-3210 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 118-B.SQL
GO

-- Start of 05) DACS-3210 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118A].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3210 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118A] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
	-- will handle them seperately based on the MeasureId passed into this script
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G8935
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G8936
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G8937
	
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
		, USE_TELEHEALTH
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data or failed USE_TELEHEALTH field check.', 'Code' = 'ERR-0-NCD';
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
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
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

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
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
		, [MODIFIER]
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
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
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


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a telehealth modifier or is the telehealth chart flag set?  must NOT have these as these are EXCLUSIONS for this MIPS rule.
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT([MODIFIER]) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1' AND [MODIFIER] IN (SELECT DISTINCT [MODIFIERS] FROM #tempProcedureList));
	IF @foundDenominatorGroup2Pick1MatchCount > 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Telehealth Modifier found)', 'Code' = 'ERR-1-NWM';
		RETURN;
	END;

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	-- do we have Two Denominator Eligible Visits?
	IF @foundDenominatorGroup1Pick2MatchCount <= 1
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Two Denominator Eligible Visits)', 'Code' = 'ERR-4-NEV';
		RETURN;
	END;

	-- do we have Left Ventricular Ejection Fraction (LVEF) < 40% or documentation of moderately or severely depressed left ventricular systolic function?
	SET @foundDenominatorGroup2Pick3MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P3'));
	IF @foundDenominatorGroup2Pick3MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Left Ventricular Ejection Fraction (LVEF) < 40% or documentation of moderately or severely depressed left ventricular systolic function)', 'Code' = 'ERR-5-NVE';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G8935
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G8936
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G8937

	DECLARE @foundG8935Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8935');  /*@ResultPerformanceCodeMet*/
	IF @foundG8935Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'G8935';
		RETURN;
	END;

	DECLARE @foundG8937Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8937');  /*@ResultPerformanceCodeNotMet*/
	IF @foundG8937Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'G8937';
		RETURN;
	END;

	DECLARE @foundG8936Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8936');  /*@ResultPerformanceCodeExMet*/
	IF @foundG8936Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G8936';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (G8935,G8936,G8937)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-A'
begin tran; -- testing
*/
-- End of 05) DACS-3210 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118A].SQL
GO

-- Start of 06) DACS-3210 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118B].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3210 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118B] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 118, there are 2 valid decision paths.  the data is stored by PQRS# '118-A' and '118-B' for example.  This script is designed around this example.
	-- will handle them seperately based on the MeasureId passed into this script
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G8473
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G8474
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G8475
	
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
		, USE_TELEHEALTH
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId
		AND (USE_TELEHEALTH IS NULL OR USE_TELEHEALTH  = 0); -- USE_TELEHEALTH Chart flag check.  If this flag is set, this chart must be excluded from this MIPS.

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		PRINT('@ChartId returned no data : ' + CAST(@ChartId AS VARCHAR(30)));
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data or failed USE_TELEHEALTH field check.', 'Code' = 'ERR-0-NCD';
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
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
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

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
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
		, [MODIFIER]
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
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
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


	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a telehealth modifier or is the telehealth chart flag set?  must NOT have these as these are EXCLUSIONS for this MIPS rule.
	SET @foundDenominatorGroup2Pick2MatchCount = (SELECT COUNT([MODIFIER]) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P2' AND [MODIFIER] IN (SELECT DISTINCT [MODIFIERS] FROM #tempProcedureList));
	IF @foundDenominatorGroup2Pick2MatchCount > 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Telehealth Modifier found)', 'Code' = 'ERR-1-NWM';
		RETURN;
	END;

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for diabetes (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for coronary artery disease)', 'Code' = 'ERR-3-NDD';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-4-NPE';
		RETURN;
	END;

	-- do we have Two Denominator Eligible Visits?
	IF @foundDenominatorGroup2Pick1MatchCount <= 1
	BEGIN 
		PRINT('Data completeness Not Met : [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Two Denominator Eligible Visits)', 'Code' = 'ERR-5-NEV';
		RETURN;
	END;


	----------------
	-- all Data Completion steps satisified.
	----------------

	PRINT('Data Completeness met.  checking Performance...: [' + CAST(@ChartId AS VARCHAR(30)) + ', '  + CAST(@MeasureId AS VARCHAR(30)) + ']');
	
	-- returns 1 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance Met) - G8473
	-- returns 2 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + denominator exception) - G8474
	-- returns 3 on Satisfaction of Rule - Column name will be 'Result' (Date completeness met + Performance NOT Met) - G8475

	DECLARE @foundG8473Count INT  = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8473');  /*@ResultPerformanceCodeMet*/
	IF @foundG8473Count >= 0
	BEGIN 
		SELECT 'Result' = 1, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Met:', 'Code' = 'G8473';
		RETURN;
	END;

	DECLARE @foundG8475Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8475');  /*@ResultPerformanceCodeNotMet*/
	IF @foundG8475Count >= 0
	BEGIN 
		SELECT 'Result' = 3, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Performance Not Met:', 'Code' = 'G8475';
		RETURN;
	END;

	DECLARE @foundG8474Count INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] = 'G8474');  /*@ResultPerformanceCodeExMet*/
	IF @foundG8474Count >= 0
	BEGIN 
		SELECT 'Result' = 2, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness met + Denominator Exception:', 'Code' = 'G8474';
		RETURN;
	END;
		
	SELECT 'Result' = 911, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data is complete but no Denominator code available to set from list (G8473,G8474,G8475)', 'Code' = '????';

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '118-B'
begin tran; -- testing
*/
-- End of 06) DACS-3210 - Create of Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118B].SQL
GO

-- Start of 10) DACS-3210 - Create or Alter Procedure - Modify [RevCycleDB].[dbo].[Maintenance_BackupProcedure].SQL

------------------------------------------------------------------------------------
-- 10) DACS-3210 - Create or Alter Procedure - Modify [RevCycleDB].[dbo].[Maintenance_BackupProcedure].SQL
------------------------------------------------------------------------------------
GO

GO

GO


CREATE OR ALTER PROCEDURE [dbo].[Maintenance_BackupProcedure]
      @SrcProc VARCHAR(512)
	, @DestProc VARCHAR(512) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY


		IF @SrcProc IS NULL OR LEN(@SrcProc) <= 0
		BEGIN
			SELECT 'ERROR' = '@SrcProc is invalid';
			RETURN;
		END;

		IF @DestProc IS NULL
		BEGIN
			DECLARE @dos DATETIME = GETDATE();
			DECLARE @Suf VARCHAR(40) = 
			(
				SELECT SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 1,4) 
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 6, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 9, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 12, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 15, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 18, 2)
			);  

			SET @DestProc = @SrcProc + '_' + @Suf;
			PRINT('setting @DestProc to: ' + @DestProc);
		END;

		IF @DestProc IS NULL OR LEN(@DestProc) <= 0
		BEGIN
			SELECT 'ERROR' = '@DestProc is invalid';
			RETURN;
		END;
				
		IF LOWER(RTRIM(@DestProc)) = LOWER(RTRIM(@SrcProc))
		BEGIN
			SELECT 'ERROR' = '@SrcProc and @DestProc can NOT be the same';
			RETURN;
		END;

		-- see if we can find the stored procedure
		DECLARE @defProc NVARCHAR(MAX) = 
		(
			SELECT 
				m.definition
			FROM 
				sys.procedures p
				JOIN sys.sql_modules m ON p.OBJECT_ID = m.OBJECT_ID
			WHERE 
				[name] LIKE @SrcProc
		);

		IF @defProc IS NULL OR LEN(@defProc) <= 0
		BEGIN
			SELECT 'ERROR' = 'Procedure [' + @SrcProc + '] does NOT exist';
			RETURN;
		END;
		
		PRINT('@defProc = ' + @defProc);

		-- copy it
		-- fix SPROC target name
		SET @defProc = REPLACE(@defProc, @SrcProc, @DestProc);
		-- fix the single quotes that may occur within the SPROC
		SET @defProc = REPLACE(@defProc, '''','''''');
		--PRINT('@defProc fixed = ' + @defProc);

		DECLARE @nSql NVARCHAR(MAX) = 'EXEC(''' + @defProc + ''')';
		PRINT('Executing: ' + @nSql);
		EXEC(@nSql);

		-- make sure new proc exists
		SET @defProc = 
		(
			SELECT 
				p.[name]
			FROM 
				sys.procedures p
				JOIN sys.sql_modules m ON p.OBJECT_ID = m.OBJECT_ID
			WHERE 
				[name] LIKE @DestProc
		);

		IF @defProc IS NULL
		BEGIN
			SELECT 'ERROR' = 'Copied Procedure [' + @DestProc + '] does NOT exist';
			RETURN;
		END;
		
		IF @defProc <> @DestProc
		BEGIN
			SELECT 'ERROR' = ' [' + @defProc + '] does NOT match [' + @DestProc + ']';
			RETURN;
		END;
		
		SELECT 'SUCCESS' = ' [' + @SrcProc + '] Copied to [' + @DestProc + ']';

	END TRY
	BEGIN CATCH
		SELECT 'ERROR' = 'Exception copying procedure.';
		RETURN;
	END CATCH;

END
GO

/*
-- testing:
begin tran;

EXEC [dbo].[Maintenance_BackupProcedure]
      @SrcProc = 'Maintenance_FindObjectsByName'
	--, @DestProc VARCHAR(512) = NULL

-- rollback tran;
-- commit tran;

--[dbo].[Maintenance_FindObjectsByName]

SELECT 
	m.definition,*
FROM 
	sys.procedures p
	JOIN sys.sql_modules m ON p.OBJECT_ID = m.OBJECT_ID
WHERE 
	[name] LIKE 'Maintenance_FindObjectsByName%'

*/
-- End of 10) DACS-3210 - Create or Alter Procedure - Modify [RevCycleDB].[dbo].[Maintenance_BackupProcedure].SQL
GO

-- Start of 11) DACS-3210 - Create or Alter Procedure - Modify [RevCycleDB].[dbo].[Maintenance_BackupProcedureAndDrop].SQL

------------------------------------------------------------------------------------
-- 11) DACS-3210 - Create or Alter Procedure - Modify [RevCycleDB].[dbo].[Maintenance_BackupProcedureAndDrop].SQL
------------------------------------------------------------------------------------
GO

GO

GO


CREATE OR ALTER PROCEDURE [dbo].[Maintenance_BackupProcedureAndDrop]
      @SrcProc VARCHAR(512)
	, @DestProc VARCHAR(512) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		IF @SrcProc IS NULL OR LEN(@SrcProc) <= 0
		BEGIN
			SELECT 'ERROR' = '@SrcProc is invalid';
			RETURN;
		END;

		IF @DestProc IS NULL
		BEGIN
			DECLARE @dos DATETIME = GETDATE();
			DECLARE @Suf VARCHAR(40) = 
			(
				SELECT SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 1,4) 
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 6, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 9, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 12, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 15, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 18, 2)
			);  

			SET @DestProc = @SrcProc + '_' + @Suf;
			PRINT('setting @DestProc to: ' + @DestProc);
		END;

		IF @DestProc IS NULL OR LEN(@DestProc) <= 0
		BEGIN
			SELECT 'ERROR' = '@DestProc is invalid';
			RETURN;
		END;
				
		IF LOWER(RTRIM(@DestProc)) = LOWER(RTRIM(@SrcProc))
		BEGIN
			SELECT 'ERROR' = '@SrcProc and @DestProc can NOT be the same';
			RETURN;
		END;

		-- see if we can find the stored procedure
		DECLARE @defProc NVARCHAR(MAX) = 
		(
			SELECT 
				m.definition
			FROM 
				sys.procedures p
				JOIN sys.sql_modules m ON p.OBJECT_ID = m.OBJECT_ID
			WHERE 
				[name] LIKE @SrcProc
		);

		IF @defProc IS NULL OR LEN(@defProc) <= 0
		BEGIN
			SELECT 'ERROR' = 'Procedure [' + @SrcProc + '] does NOT exist';
			RETURN;
		END;
		
		-- PRINT('@defProc = ' + @defProc);

		-- copy it
		-- fix SPROC target name
		SET @defProc = REPLACE(@defProc, @SrcProc, @DestProc);
		-- fix the single quotes that may occur within the SPROC
		SET @defProc = REPLACE(@defProc, '''','''''');
		--PRINT('@defProc fixed = ' + @defProc);

		DECLARE @nSql NVARCHAR(MAX) = 'EXEC(''' + @defProc + ''')';
		PRINT('Executing: ' + @nSql);
		EXEC(@nSql);

		-- make sure new proc exists
		SET @defProc = 
		(
			SELECT 
				p.[name]
			FROM 
				sys.procedures p
				JOIN sys.sql_modules m ON p.OBJECT_ID = m.OBJECT_ID
			WHERE 
				[name] LIKE @DestProc
		);

		IF @defProc IS NULL
		BEGIN
			SELECT 'ERROR' = 'Copied Procedure [' + @DestProc + '] does NOT exist';
			RETURN;
		END;
		
		IF @defProc <> @DestProc
		BEGIN
			SELECT 'ERROR' = ' [' + @defProc + '] does NOT match [' + @DestProc + ']';
			RETURN;
		END;

	END TRY
	BEGIN CATCH
		SELECT 'ERROR' = 'Exception copying procedure: ' + CAST(ERROR_MESSAGE() AS VARCHAR(512));
		RETURN;
	END CATCH;


	BEGIN TRY

		SET @nSql = 'DROP PROCEDURE ' + @SrcProc + ';';
		PRINT('Executing: ' + @nSql);
		EXEC(@nSql);

		SELECT 'SUCCESS' = ' [' + @SrcProc + '] Copied to [' + @DestProc + '] and dropped.';

	END TRY
	BEGIN CATCH
		SELECT 'ERROR' = 'Exception dropping procedure: ' + CAST(ERROR_MESSAGE() AS VARCHAR(512));
		RETURN;
	END CATCH;

END
GO

/*
-- testing:
begin tran;

EXEC [dbo].[Maintenance_BackupProcedureAndDrop]
      @SrcProc = 'Maintenance_FindObjectsByName'
	--, @DestProc VARCHAR(512) = NULL

-- rollback tran;
-- commit tran;

--[dbo].[Maintenance_FindObjectsByName]

SELECT 
	m.definition,*
FROM 
	sys.procedures p
	JOIN sys.sql_modules m ON p.OBJECT_ID = m.OBJECT_ID
WHERE 
	[name] LIKE 'Maintenance_FindObjectsByName%'

*/
-- End of 11) DACS-3210 - Create or Alter Procedure - Modify [RevCycleDB].[dbo].[Maintenance_BackupProcedureAndDrop].SQL
GO

-- Start of 01) DACS-3315 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Edit-Denial].SQL

----------------------------------------------------
-- 01) DACS-3315 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Edit-Denial].SQL
----------------------------------------------------
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 8)
BEGIN
	PRINT('Adding [dbo].[ChartPostBillAuditReasonTypeCode] item [Edit/Denial');
	INSERT INTO 
		[dbo].[ChartPostBillAuditReasonTypeCode] 
	(
		[ChartPostBillAuditReasonTypeCode]
		, [Key]
		, [DisplayName]
		, [ExternalCode]
		, [Description]
	)
	VALUES 
	(
		8
		, 'EditDenial'
		, 'Edit/Denial'
		, 'EDD'
		, 'Edit/Denial'
	);
END;

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 8)
BEGIN
	PRINT('!!!! Failed to add [ChartPostBillAuditReasonTypeCode] item [Edit/Denial] !!!!');
END;

GO


-- End of 01) DACS-3315 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Edit-Denial].SQL
GO

-- Start of 01) DACS-3318 - SQL Script to insert into SERVICE_AGREEMENT_RATE_TYPE.SQL

---------------------------------------------------------------------------------
-- 01) DACS-3318 - SQL Script to insert into SERVICE_AGREEMENT_RATE_TYPE.SQL
---------------------------------------------------------------------------------
GO 

/*
Please add new “Rate Types” Claim Based, FTE Billing, Hourly, Transaction to the Service Agreement rate type selection options.  
*/

-- begin tran; -- testing

-- setup resources
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @countBefore INT = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT_RATE_TYPE] WHERE [RATE_TYPE_CD] IN ('CB','FB','HO','TR')); 

IF @countBefore != 0
BEGIN
	SELECT 'ERROR' = 'At least one field already exists.  Exiting.  @countBefore = ' + CAST(@countBefore AS VARCHAR(50));
	RETURN;
END;

-------------------------------------------------------
-- backup the table first
-------------------------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'SERVICE_AGREEMENT_RATE_TYPE', @DestTable = 'SERVICE_AGREEMENT_RATE_TYPE_DACS-3318';

INSERT INTO [SERVICE_AGREEMENT_RATE_TYPE] 
	([RATE_TYPE_CD], [DESCRIPTION])
VALUES
	 ('CB','Claim Based')
	,('FB','FTE Billing')
	,('HO','Hourly')
	,('TR','Transaction');

DECLARE @countAfter INT = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT_RATE_TYPE] WHERE [RATE_TYPE_CD] IN ('CB','FB','HO','TR')); 

IF @countAfter != 4
BEGIN
	SELECT 'ERROR' = 'Unexpected return count.  Exiting.  @countAfter = ' + CAST(@countAfter AS VARCHAR(50));
	RETURN;
END;

SELECT 'RESULT' = 'DONE';

-- SELECT * FROM SERVICE_AGREEMENT_RATE_TYPE; -- testing

-- rollback tran; -- testing
-- commit tran; -- testing

GO


-- End of 01) DACS-3318 - SQL Script to insert into SERVICE_AGREEMENT_RATE_TYPE.SQL
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
