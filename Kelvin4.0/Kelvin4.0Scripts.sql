USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 007-A.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 007-A.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '007-A';
	DECLARE @Dos DATETIME = '01-01-2024'

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
		PRINT('!!!!! Updating...');

		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 1): All patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a current or prior LVEF less than or equal to 40% : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a prior MI or a current or prior LVEF less than or equal to 40% who were prescribed beta-blocker therapy. '
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
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
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' : Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 1): All patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a current or prior LVEF less than or equal to 40% : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a prior MI or a current or prior LVEF less than or equal to 40% who were prescribed beta-blocker therapy. '
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '007-A' -- = 210
*/
-- End of 01) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 007-A.SQL
GO

-- Start of 02) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 007-B.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 007-B.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '007-B';
	DECLARE @Dos DATETIME = '01-01-2024'

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
		PRINT('!!!!! Updating...');

		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 2): All patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have prior (within the past 3 years) MI : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a prior MI or a current or prior LVEF less than or equal to 40% who were prescribed beta-blocker therapy. '	
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
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
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' : Coronary Artery Disease (CAD): Beta-Blocker Therapy – Prior Myocardial Infarction (MI) or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 2): All patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have prior (within the past 3 years) MI : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have a prior MI or a current or prior LVEF less than or equal to 40% who were prescribed beta-blocker therapy. '	
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '007-B' -- = 211
*/
-- End of 02) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 007-B.SQL
GO

-- Start of 03) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 007-A.SQL

------------------------------------------------------------------------------------
-- 03) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 007-A.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '007-A';
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
		-- Diagnosis for coronary artery disease (ICD-10-CM):
		 (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','I25.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.702',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.712',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.722',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.732',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.752',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.762',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.792',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',NULL,@Dos,NULL)

		-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
		,(@MeasureId,'DG1P1','33140',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33510',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33514',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33516',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33534',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33535',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33536',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92920',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92924',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92928',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92933',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92937',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92941',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92943',NULL,@Dos,NULL)
		
		-- Patient encounter during the performance period (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
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
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99426',NULL,@Dos,NULL) 
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G9189',NULL,@Dos,'Performance Met: Beta-blocker therapy prescribed or currently being taken. ')
		,(@MeasureId,'HCPCS','G9188',NULL,@Dos,'Performance Not Met: Beta-blocker therapy not prescribed, reason not given. ')
		,(@MeasureId,'HCPCS','G9190',NULL,@Dos,'Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons). ')
		,(@MeasureId,'HCPCS','G9191',NULL,@Dos,'Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons). ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Is there at least one additional patient encounter during performance period (CPT)?')
		,(@MeasureId,'DQ411','G8694',NULL,@Dos,'Is Left ventricular ejection fraction (LVEF) ≤ 40% or documentation of moderate or severe LVSD: G8694?')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		
		; -- expect 118 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '007-A' -- = 210
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 210
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 210
--commit tran;
*/
-- End of 03) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 007-A.SQL
GO

-- Start of 04) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 007-B.SQL

------------------------------------------------------------------------------------
-- 04) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 007-B.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '007-B';
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
		-- Diagnosis for coronary artery disease (ICD-10-CM)
		 (@MeasureId,'DG1P1','I20.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I20.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I24.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','I25.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.110',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.112',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.118',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.700',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.702',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.708',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.710',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.712',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.718',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.720',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.721',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.722',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.728',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.729',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.730',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.731',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.732',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.738',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.739',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.750',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.751',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.752',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.758',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.759',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.760',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.761',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.762',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.768',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.769',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.790',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.791',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.792',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.798',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.799',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.810',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.812',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.84',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.89',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','I25.9',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','Z98.61',NULL,@Dos,NULL)

		-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
		,(@MeasureId,'DG1P1','33140',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33510',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33512',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33513',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33514',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33516',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33533',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33534',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33535',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','33536',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92920',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92924',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92928',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92933',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92937',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92941',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','92943',NULL,@Dos,NULL)

		-- Patient encounter during the performance period (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
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
		,(@MeasureId,'DG1P2','99315',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99316',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99426',NULL,@Dos,NULL)

		--Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM)
		,(@MeasureId,'DG2P1','I21.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.02',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.09',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.19',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','I21.9',NULL,@Dos,NULL) 
		,(@MeasureId,'DG2P1','I21.A9',NULL,@Dos,NULL)

		-- measure code numerators
		,(@MeasureId,'HCPCS','4008F',NULL,@Dos,'Performance Met: Beta-blocker therapy prescribed or currently being taken. ')
		,(@MeasureId,'HCPCS','4008F','8P',@Dos,'Performance Not Met: Beta-blocker therapy not prescribed, reason not otherwise specified. ')
		,(@MeasureId,'HCPCS','4008F','1P',@Dos,'Denominator Exception: Documentation of medical reason(s) for not prescribing beta-blocker therapy (e.g., allergy, intolerance, other medical reasons). ')
		,(@MeasureId,'HCPCS','4008F','2P',@Dos,'Denominator Exception: Documentation of patient reason(s) for not prescribing beta-blocker therapy (e.g., patient declined, other patient reasons). ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','00001',NULL,@Dos,'Is there at least one additional patient encounter during performance period (CPT)?')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 128 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '007-B' -- = 211
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 211
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 211
--commit tran;
*/
-- End of 04) DACS-3535 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 007-B.SQL
GO

-- Start of 05) DACS-3535 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL

------------------------------------------------------------------------------------
-- 05) DACS-3535 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

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
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
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
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
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
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
			RETURN;
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
				RETURN;
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
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


	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
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
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;
	
	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick1MatchCountB <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '007-A' -- = 210
begin tran; -- testing
*/
-- End of 05) DACS-3535 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007A].SQL
GO

-- Start of 06) DACS-3535 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL

------------------------------------------------------------------------------------
-- 06) DACS-3535 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

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
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
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
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
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
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
			RETURN;
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
				RETURN;
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
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


	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
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
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick1MatchCountB <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM) listing?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	SELECT TOP 5
		'411' AS 'RESULT'
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '007-B' -- = 211
exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B
	@ChartId = 2100113517
	,@PqrsNum = '007-B'
begin tran; -- testing
*/
-- End of 06) DACS-3535 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
GO

-- Start of 07) DACS-3535 - CREATE or Alter FUNCTION - [dbo].[fGetPatientAgeInYears].SQL

----------------------------------------
-- 07) DACS-3535 - CREATE or Alter FUNCTION - [dbo].[fGetPatientAgeInYears].SQL
----------------------------------------
GO

GO

GO

CREATE OR ALTER FUNCTION [dbo].[fGetPatientAgeInYears] (
	 @patientAge INT
	,@chartDos DATETIME
	,@patienDOB DATETIME
)
RETURNS INT
AS
BEGIN
	IF @chartDos IS NULL OR @chartDos <= Convert(datetime, '1900-01-01' )
		RETURN -1;
	
	IF @patientAge IS NULL
	BEGIN
		IF @patienDOB IS NULL
			RETURN -2;
			
		SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
	END;
		
	IF @patientAge < 0 OR @patientAge > 999 OR @patientAge IS NULL
		RETURN -3;

	RETURN @patientAge
END;

/*
-- testing:
SELECT dbo.fGetPatientAgeInYears(NULL,'01-12-2024','12-2-1971') AS SumResult; -- returns 54
SELECT dbo.fGetPatientAgeInYears(21,'01-12-2024','12-2-1971') AS SumResult; -- returns 21

*/
-- End of 07) DACS-3535 - CREATE or Alter FUNCTION - [dbo].[fGetPatientAgeInYears].SQL
GO

-- Start of 01) DACS-3534 - SQL Script to Expire MIPS- 436, 254, THEPQR3 on 12-31-24.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3534 - SQL Script to Expire MIPS- 436, 254, THEPQR3 on 12-31-24.SQL
------------------------------------------------------------------------------------
GO

GO

GO

-- begin tran; --testing
-- commit tran; --testing
-- rollback tran; --testing

-------------------------------------------------------
-- backup the tables first
-------------------------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3534';
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3534';
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'SERVICE_AGREEMENT_PQRS', @DestTable = 'SERVICE_AGREEMENT_PQRS_DACS-3534';


DECLARE @ExpirationDate DATETIME = '12-31-24';

--get the IDs for the MIPS to expire
DECLARE @mipsToExpire TABLE
	(
		Id INT IDENTITY(1, 1)
	   ,MipsName VARCHAR(100)
	   ,MipsId INT
	);

INSERT @mipsToExpire(MipsName, MipsId)
	SELECT 
		 [PQRS#] AS mipsName
		,[CMS_PQRI_MEASURE_ID] AS MipsId
	FROM 
		[CMS_PQRI_MEASURE]
	WHERE
		[PQRS#] IN ('436','254','THEPQR3');
		
SELECT * FROM @mipsToExpire; -- testing
	
DECLARE @CountMips INT = (SELECT COUNT(*) FROM @mipsToExpire)
	
IF @CountMips <> 3
BEGIN 
	SELECT 'Error' = 'Bad MIPS Count:  Check Table settings, adjust and try again.';
	RETURN;
END;

-------------------------------------------------------
-- update the CMS_PQRI_MEASURE TABLE
-------------------------------------------------------
SELECT TOP 200 * FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate); -- testing

SET @CountMips = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate))

SELECT '@CountMips before updating [CMS_PQRI_MEASURE]' = @CountMips;

UPDATE [CMS_PQRI_MEASURE]
	SET [EXPIRATION_DATE] = @ExpirationDate
	WHERE 
		[CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) 
		AND ([EFFECTIVE_DATE] < @ExpirationDate)
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate))

SELECT '@CountMips after updating [CMS_PQRI_MEASURE]' = @CountMips;

-- SELECT TOP 200 * FROM [CMS_PQRI_MEASURE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire); -- testing


-------------------------------------------------------
-- update the CMS_PQRI_MEASURE_CODE TABLE
-------------------------------------------------------
SELECT TOP 10000 * FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([START_DATE] IS NULL OR [START_DATE] < @ExpirationDate) AND ([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([START_DATE] IS NULL OR [START_DATE] < @ExpirationDate) AND ([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate))

SELECT '@CountMips before updating [CMS_PQRI_MEASURE_CODE]' = @CountMips;

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [END_DATE] = @ExpirationDate
	WHERE 
		[CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) 
		AND ([START_DATE] IS NULL OR [START_DATE] < @ExpirationDate)
		AND ([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([START_DATE] IS NULL OR [START_DATE] < @ExpirationDate) AND ([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate))

SELECT '@CountMips after updating [CMS_PQRI_MEASURE_CODE]' = @CountMips;

-- SELECT TOP 10000 * FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire); -- testing

-------------------------------------------------------
-- update the [dbo].[SERVICE_AGREEMENT_PQRS]  table.
-------------------------------------------------------
SELECT TOP 10000 * FROM [SERVICE_AGREEMENT_PQRS] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT_PQRS] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate))

SELECT '@CountMips before updating [SERVICE_AGREEMENT_PQRS]' = @CountMips;

UPDATE [SERVICE_AGREEMENT_PQRS]
	SET [EXPIRATION_DATE] = @ExpirationDate
	WHERE 
		[CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) 
		AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < @ExpirationDate)
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate);

SET @CountMips = (SELECT COUNT(*) FROM [SERVICE_AGREEMENT_PQRS] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire) AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] < @ExpirationDate) AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate))

SELECT '@CountMips after updating [SERVICE_AGREEMENT_PQRS]' = @CountMips;

-- SELECT TOP 10000 * FROM [SERVICE_AGREEMENT_PQRS] WHERE [CMS_PQRI_MEASURE_ID] IN (SELECT DISTINCT [MipsId] FROM @mipsToExpire); -- testing

-- commit tran;
-- rollback tran;
-- End of 01) DACS-3534 - SQL Script to Expire MIPS- 436, 254, THEPQR3 on 12-31-24.SQL
GO

-- Start of 01) DACS-3488 - Create or Alter Stored Procedure - [dbo].[SelectPhysicianServiceProcedureCptCodeByServiceAgreementIdAndPhysicianServiceProcId].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3488 - Create or Alter Stored Procedure - [dbo].[SelectPhysicianServiceProcedureCptCodeByServiceAgreementIdAndPhysicianServiceProcId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysicianServiceProcedureCptCodeByServiceAgreementIdAndPhysicianServiceProcId] 
	  @ServiceAgreementId INT
	 ,@PhysicianServiceProcId INT
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- This SPROC is used a great deal.
	-- validation of parameters being handled within ACS for better efficiency.
	-- replaces the following C# segment:
	/*
		sql = "SELECT CPT_CODE "
					+ "FROM PHYSICIAN_SERVICE_PROCEDURE "
					+ "WHERE "
					+ "     SERVICE_AGREEMENT_ID = " + saID.ToString()
					+ " AND PHYSICIAN_SERVICE_PROC_ID = " + procID.ToString()
					+ andStr;
		in method "public String GetCPTCode(int saId, int procId)" of file "\ACS\CCSBusinessObjects\DAO\Physician\PhysicianServiceEvaluationListDAO.cs" at ~line# 1808
	*/
	----------------
	
	--IF @ServiceAgreementId IS NULL OR @ServiceAgreementId <= 0 OR @PhysicianServiceProcId IS NULL OR @PhysicianServiceProcId <= 0
	--	RETURN;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- result
	----------------
	SELECT TOP 1 
		[CPT_CODE] 
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
    WHERE 
        [SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND [PHYSICIAN_SERVICE_PROC_ID] = @PhysicianServiceProcId;	

END -- end procedure

GO
-- End of 01) DACS-3488 - Create or Alter Stored Procedure - [dbo].[SelectPhysicianServiceProcedureCptCodeByServiceAgreementIdAndPhysicianServiceProcId].SQL
GO

-- Start of 01) DACS-3483 Alter Table SERVICE_AGREEMENT_AUTOMATION_CODING.sql

------------------------------------------------------------------------------------
-- 01) DACS-3483 - Alter table SERVICE_AGREEMENT_AUTOMATION_CODING to add new columns
------------------------------------------------------------------------------------
GO

ALTER TABLE 
	SERVICE_AGREEMENT_AUTOMATION_CODING
ADD 
	COLLECT_ADDITIONAL_PROCEDURES bit null,
	COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE datetime null,
	COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE datetime null
-- End of 01) DACS-3483 Alter Table SERVICE_AGREEMENT_AUTOMATION_CODING.sql
GO

-- Start of 02) DACS-3483 Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_UPDATE_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID.sql

------------------------------------------------------------------------------------
-- 02) DACS-3483 - Alter Stored Proc [SERVICE_AGREEMENT_AUTOMATION_CODING_UPDATE_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID] to add 3 new columns
------------------------------------------------------------------------------------

GO
/****** Object:  StoredProcedure [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING_UPDATE_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID]    Script Date: 8/2/2024 12:38:46 PM ******/
GO
GO

ALTER   PROCEDURE [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING_UPDATE_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID]  
  @SERVICE_AGREEMENT_AUTOMATION_CODING_ID int  
 ,@CREATING_USER_PROFILE_ID int = NULL  
 ,@CHANGING_USER_PROFILE_ID int = NULL  
 ,@SERVICE_AGREEMENT_ID int  
 ,@IMPORT_DIRECTORY varchar(256)  
 ,@FACILITY_AUTOMATION_CODING_REQUIRED bit = NULL  
 ,@FACILITY_AUTOMATION_CODING_DOS_EFFECTIVE_DATE datetime = NULL  
 ,@FACILITY_AUTOMATION_CODING_DOS_EXPIRATION_DATE datetime = NULL  
 ,@PHYSICIAN_AUTOMATION_CODING_REQUIRED bit = NULL  
 ,@PHYSICIAN_AUTOMATION_CODING_DOS_EFFECTIVE_DATE datetime = NULL  
 ,@PHYSICIAN_AUTOMATION_CODING_DOS_EXPIRATION_DATE datetime = NULL  
 ,@COLLECT_FACILITY_SERVICE bit = NULL  
 ,@COLLECT_FACILITY_SERVICE_EFFECTIVE_DATE datetime = NULL  
 ,@COLLECT_FACILITY_SERVICE_EXPIRATION_DATE datetime = NULL  
 ,@COLLECT_FACILITY_PROCEDURES bit = NULL  
 ,@COLLECT_FACILITY_PROCEDURES_EFFECTIVE_DATE datetime = NULL  
 ,@COLLECT_FACILITY_PROCEDURES_EXPIRATION_DATE datetime = NULL  
 ,@COLLECT_PHYSICIAN_SERVICE bit = NULL  
 ,@COLLECT_PHYSICIAN_SERVICE_EFFECTIVE_DATE datetime = NULL  
 ,@COLLECT_PHYSICIAN_SERVICE_EXPIRATION_DATE datetime = NULL  
 ,@COLLECT_PHYSICIAN_PROCEDURES bit = NULL  
 ,@COLLECT_PHYSICIAN_PROCEDURES_EFFECTIVE_DATE datetime = NULL  
 ,@COLLECT_PHYSICIAN_PROCEDURES_EXPIRATION_DATE datetime = NULL  
 ,@COLLECT_INFUSIONS_INJECTIONS bit = NULL  
 ,@COLLECT_INFUSIONS_INJECTIONS_EFFECTIVE_DATE datetime = NULL  
 ,@COLLECT_INFUSIONS_INJECTIONS_EXPIRATION_DATE datetime = NULL  
 ,@COLLECT_DIAGNOSIS_CODING bit = NULL  
 ,@COLLECT_DIAGNOSIS_CODING_EFFECTIVE_DATE datetime = NULL  
 ,@COLLECT_DIAGNOSIS_CODING_EXPIRATION_DATE datetime = NULL  
 ,@PEND_CHARTS_FOR_AUDIT bit = NULL  
 ,@PEND_CHARTS_FOR_AUDIT_EFFECTIVE_DATE datetime = NULL  
 ,@PEND_CHARTS_FOR_AUDIT_EXPIRATION_DATE datetime = NULL  
 ,@SHOW_INDICATORS_ON_CHARTS_PAGE bit = NULL
 ,@COLLECT_ADDITIONAL_PROCEDURES bit = NULL  
 ,@COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE datetime = NULL  
 ,@COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE datetime = NULL   
AS  
  
UPDATE [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING] SET  
  [CREATING_USER_PROFILE_ID] = @CREATING_USER_PROFILE_ID  
 ,[CHANGED_DATE_TIME] = GETDATE()  
 ,[CHANGING_USER_PROFILE_ID] = @CHANGING_USER_PROFILE_ID  
 ,[SERVICE_AGREEMENT_ID] = @SERVICE_AGREEMENT_ID  
 ,[IMPORT_DIRECTORY] = @IMPORT_DIRECTORY  
 ,[FACILITY_AUTOMATION_CODING_REQUIRED] = @FACILITY_AUTOMATION_CODING_REQUIRED  
 ,[FACILITY_AUTOMATION_CODING_DOS_EFFECTIVE_DATE] = @FACILITY_AUTOMATION_CODING_DOS_EFFECTIVE_DATE  
 ,[FACILITY_AUTOMATION_CODING_DOS_EXPIRATION_DATE] = @FACILITY_AUTOMATION_CODING_DOS_EXPIRATION_DATE  
 ,[PHYSICIAN_AUTOMATION_CODING_REQUIRED] = @PHYSICIAN_AUTOMATION_CODING_REQUIRED  
 ,[PHYSICIAN_AUTOMATION_CODING_DOS_EFFECTIVE_DATE] = @PHYSICIAN_AUTOMATION_CODING_DOS_EFFECTIVE_DATE  
 ,[PHYSICIAN_AUTOMATION_CODING_DOS_EXPIRATION_DATE] = @PHYSICIAN_AUTOMATION_CODING_DOS_EXPIRATION_DATE  
 ,[COLLECT_FACILITY_SERVICE] = @COLLECT_FACILITY_SERVICE  
 ,[COLLECT_FACILITY_SERVICE_EFFECTIVE_DATE] = @COLLECT_FACILITY_SERVICE_EFFECTIVE_DATE  
 ,[COLLECT_FACILITY_SERVICE_EXPIRATION_DATE] = @COLLECT_FACILITY_SERVICE_EXPIRATION_DATE  
 ,[COLLECT_FACILITY_PROCEDURES] = @COLLECT_FACILITY_PROCEDURES  
 ,[COLLECT_FACILITY_PROCEDURES_EFFECTIVE_DATE] = @COLLECT_FACILITY_PROCEDURES_EFFECTIVE_DATE  
 ,[COLLECT_FACILITY_PROCEDURES_EXPIRATION_DATE] = @COLLECT_FACILITY_PROCEDURES_EXPIRATION_DATE  
 ,[COLLECT_PHYSICIAN_SERVICE] = @COLLECT_PHYSICIAN_SERVICE  
 ,[COLLECT_PHYSICIAN_SERVICE_EFFECTIVE_DATE] = @COLLECT_PHYSICIAN_SERVICE_EFFECTIVE_DATE  
 ,[COLLECT_PHYSICIAN_SERVICE_EXPIRATION_DATE] = @COLLECT_PHYSICIAN_SERVICE_EXPIRATION_DATE  
 ,[COLLECT_PHYSICIAN_PROCEDURES] = @COLLECT_PHYSICIAN_PROCEDURES  
 ,[COLLECT_PHYSICIAN_PROCEDURES_EFFECTIVE_DATE] = @COLLECT_PHYSICIAN_PROCEDURES_EFFECTIVE_DATE  
 ,[COLLECT_PHYSICIAN_PROCEDURES_EXPIRATION_DATE] = @COLLECT_PHYSICIAN_PROCEDURES_EXPIRATION_DATE  
 ,[COLLECT_INFUSIONS_INJECTIONS] = @COLLECT_INFUSIONS_INJECTIONS  
 ,[COLLECT_INFUSIONS_INJECTIONS_EFFECTIVE_DATE] = @COLLECT_INFUSIONS_INJECTIONS_EFFECTIVE_DATE  
 ,[COLLECT_INFUSIONS_INJECTIONS_EXPIRATION_DATE] = @COLLECT_INFUSIONS_INJECTIONS_EXPIRATION_DATE   
 ,[COLLECT_DIAGNOSIS_CODING] = @COLLECT_DIAGNOSIS_CODING  
 ,[COLLECT_DIAGNOSIS_CODING_EFFECTIVE_DATE] = @COLLECT_DIAGNOSIS_CODING_EFFECTIVE_DATE  
 ,[COLLECT_DIAGNOSIS_CODING_EXPIRATION_DATE] = @COLLECT_DIAGNOSIS_CODING_EXPIRATION_DATE  
 ,[PEND_CHARTS_FOR_AUDIT] = @PEND_CHARTS_FOR_AUDIT  
 ,[PEND_CHARTS_FOR_AUDIT_EFFECTIVE_DATE] = @PEND_CHARTS_FOR_AUDIT_EFFECTIVE_DATE  
 ,[PEND_CHARTS_FOR_AUDIT_EXPIRATION_DATE] = @PEND_CHARTS_FOR_AUDIT_EXPIRATION_DATE  
 ,[SHOW_INDICATORS_ON_CHARTS_PAGE] = @SHOW_INDICATORS_ON_CHARTS_PAGE
 ,[COLLECT_ADDITIONAL_PROCEDURES] = @COLLECT_ADDITIONAL_PROCEDURES
 ,[COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE] = @COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE  
 ,[COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE] = @COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE 

WHERE  
 [SERVICE_AGREEMENT_AUTOMATION_CODING_ID] = @SERVICE_AGREEMENT_AUTOMATION_CODING_ID  
-- End of 02) DACS-3483 Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_UPDATE_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID.sql
GO

-- Start of 03) DACS-3483 Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_ID.sql

------------------------------------------------------------------------------------
-- 03) DACS-3483 - Alter Stored Proc [SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_ID] to add 3 new columns
------------------------------------------------------------------------------------

GO
/****** Object:  StoredProcedure [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_ID]    Script Date: 8/2/2024 12:39:26 PM ******/
GO
GO

ALTER PROCEDURE [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_ID]
	@SERVICE_AGREEMENT_ID int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [SERVICE_AGREEMENT_AUTOMATION_CODING].[SERVICE_AGREEMENT_AUTOMATION_CODING_ID]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[CREATION_DATE_TIME]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[CREATING_USER_PROFILE_ID]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[CHANGED_DATE_TIME]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[CHANGING_USER_PROFILE_ID]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[SERVICE_AGREEMENT_ID]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[IMPORT_DIRECTORY]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[FACILITY_AUTOMATION_CODING_REQUIRED]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[FACILITY_AUTOMATION_CODING_DOS_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[FACILITY_AUTOMATION_CODING_DOS_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PHYSICIAN_AUTOMATION_CODING_REQUIRED]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PHYSICIAN_AUTOMATION_CODING_DOS_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PHYSICIAN_AUTOMATION_CODING_DOS_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_SERVICE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_SERVICE_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_SERVICE_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_PROCEDURES]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_PROCEDURES_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_PROCEDURES_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_SERVICE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_SERVICE_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_SERVICE_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_PROCEDURES]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_PROCEDURES_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_PROCEDURES_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_INFUSIONS_INJECTIONS]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_INFUSIONS_INJECTIONS_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_INFUSIONS_INJECTIONS_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_DIAGNOSIS_CODING]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_DIAGNOSIS_CODING_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_DIAGNOSIS_CODING_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PEND_CHARTS_FOR_AUDIT]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PEND_CHARTS_FOR_AUDIT_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PEND_CHARTS_FOR_AUDIT_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[SHOW_INDICATORS_ON_CHARTS_PAGE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_ADDITIONAL_PROCEDURES]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE]
FROM
	[dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING]
WHERE
	[SERVICE_AGREEMENT_AUTOMATION_CODING].[SERVICE_AGREEMENT_ID] = @SERVICE_AGREEMENT_ID

-- End of 03) DACS-3483 Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_ID.sql
GO

-- Start of 04) DACS-3483 Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID.sql

------------------------------------------------------------------------------------
-- 04) DACS-3483 - Alter Stored Proc [SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID] to add 3 new columns
------------------------------------------------------------------------------------

GO
/****** Object:  StoredProcedure [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID]    Script Date: 8/2/2024 12:39:38 PM ******/
GO
GO

ALTER PROCEDURE [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID]
	@SERVICE_AGREEMENT_AUTOMATION_CODING_ID int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [SERVICE_AGREEMENT_AUTOMATION_CODING].[SERVICE_AGREEMENT_AUTOMATION_CODING_ID]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[CREATION_DATE_TIME]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[CREATING_USER_PROFILE_ID]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[CHANGED_DATE_TIME]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[CHANGING_USER_PROFILE_ID]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[SERVICE_AGREEMENT_ID]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[IMPORT_DIRECTORY]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[FACILITY_AUTOMATION_CODING_REQUIRED]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[FACILITY_AUTOMATION_CODING_DOS_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[FACILITY_AUTOMATION_CODING_DOS_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PHYSICIAN_AUTOMATION_CODING_REQUIRED]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PHYSICIAN_AUTOMATION_CODING_DOS_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PHYSICIAN_AUTOMATION_CODING_DOS_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_SERVICE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_SERVICE_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_SERVICE_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_PROCEDURES]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_PROCEDURES_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_FACILITY_PROCEDURES_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_SERVICE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_SERVICE_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_SERVICE_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_PROCEDURES]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_PROCEDURES_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_PHYSICIAN_PROCEDURES_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_INFUSIONS_INJECTIONS]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_INFUSIONS_INJECTIONS_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_INFUSIONS_INJECTIONS_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_DIAGNOSIS_CODING]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_DIAGNOSIS_CODING_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_DIAGNOSIS_CODING_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PEND_CHARTS_FOR_AUDIT]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PEND_CHARTS_FOR_AUDIT_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[PEND_CHARTS_FOR_AUDIT_EXPIRATION_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[SHOW_INDICATORS_ON_CHARTS_PAGE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_ADDITIONAL_PROCEDURES]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE]
	,[SERVICE_AGREEMENT_AUTOMATION_CODING].[COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE]
FROM
	[dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING]
WHERE
	[SERVICE_AGREEMENT_AUTOMATION_CODING].[SERVICE_AGREEMENT_AUTOMATION_CODING_ID] = @SERVICE_AGREEMENT_AUTOMATION_CODING_ID

-- End of 04) DACS-3483 Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_SELECT_BY_SERVICE_AGREEMENT_AUTOMATION_CODING_ID.sql
GO

-- Start of 05) DACS-3483 Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_INSERT.sql

------------------------------------------------------------------------------------
-- 05) DACS-3483 - Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_INSERT to add 3 new columns
------------------------------------------------------------------------------------

GO
/****** Object:  StoredProcedure [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING_INSERT]    Script Date: 8/2/2024 12:39:01 PM ******/
GO
GO

ALTER PROCEDURE [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING_INSERT]
	 @CREATING_USER_PROFILE_ID int = NULL
	,@CHANGING_USER_PROFILE_ID int = NULL
	,@SERVICE_AGREEMENT_ID int
	,@IMPORT_DIRECTORY varchar(256)
	,@FACILITY_AUTOMATION_CODING_REQUIRED bit = NULL
	,@FACILITY_AUTOMATION_CODING_DOS_EFFECTIVE_DATE datetime = NULL
	,@FACILITY_AUTOMATION_CODING_DOS_EXPIRATION_DATE datetime = NULL
	,@PHYSICIAN_AUTOMATION_CODING_REQUIRED bit = NULL
	,@PHYSICIAN_AUTOMATION_CODING_DOS_EFFECTIVE_DATE datetime = NULL
	,@PHYSICIAN_AUTOMATION_CODING_DOS_EXPIRATION_DATE datetime = NULL
	,@COLLECT_FACILITY_SERVICE bit = NULL
	,@COLLECT_FACILITY_SERVICE_EFFECTIVE_DATE datetime = NULL
	,@COLLECT_FACILITY_SERVICE_EXPIRATION_DATE datetime = NULL
	,@COLLECT_FACILITY_PROCEDURES bit = NULL
	,@COLLECT_FACILITY_PROCEDURES_EFFECTIVE_DATE datetime = NULL
	,@COLLECT_FACILITY_PROCEDURES_EXPIRATION_DATE datetime = NULL
	,@COLLECT_PHYSICIAN_SERVICE bit = NULL
	,@COLLECT_PHYSICIAN_SERVICE_EFFECTIVE_DATE datetime = NULL
	,@COLLECT_PHYSICIAN_SERVICE_EXPIRATION_DATE datetime = NULL
	,@COLLECT_PHYSICIAN_PROCEDURES bit = NULL
	,@COLLECT_PHYSICIAN_PROCEDURES_EFFECTIVE_DATE datetime = NULL
	,@COLLECT_PHYSICIAN_PROCEDURES_EXPIRATION_DATE datetime = NULL
	,@COLLECT_INFUSIONS_INJECTIONS bit = NULL
	,@COLLECT_INFUSIONS_INJECTIONS_EFFECTIVE_DATE datetime = NULL
	,@COLLECT_INFUSIONS_INJECTIONS_EXPIRATION_DATE datetime = NULL
	,@COLLECT_DIAGNOSIS_CODING bit = NULL
	,@COLLECT_DIAGNOSIS_CODING_EFFECTIVE_DATE datetime = NULL
	,@COLLECT_DIAGNOSIS_CODING_EXPIRATION_DATE datetime = NULL
	,@PEND_CHARTS_FOR_AUDIT bit = NULL
	,@PEND_CHARTS_FOR_AUDIT_EFFECTIVE_DATE datetime = NULL
	,@PEND_CHARTS_FOR_AUDIT_EXPIRATION_DATE datetime = NULL
	,@SHOW_INDICATORS_ON_CHARTS_PAGE bit = NULL
	,@COLLECT_ADDITIONAL_PROCEDURES bit = NULL  
	,@COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE datetime = NULL  
	,@COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE datetime = NULL
	,@SERVICE_AGREEMENT_AUTOMATION_CODING_ID int OUTPUT
AS

INSERT INTO [dbo].[SERVICE_AGREEMENT_AUTOMATION_CODING]
(
	 [CREATING_USER_PROFILE_ID]
	,[CHANGING_USER_PROFILE_ID]
	,[SERVICE_AGREEMENT_ID]
	,[IMPORT_DIRECTORY]
	,[FACILITY_AUTOMATION_CODING_REQUIRED]
	,[FACILITY_AUTOMATION_CODING_DOS_EFFECTIVE_DATE]
	,[FACILITY_AUTOMATION_CODING_DOS_EXPIRATION_DATE]
	,[PHYSICIAN_AUTOMATION_CODING_REQUIRED]
	,[PHYSICIAN_AUTOMATION_CODING_DOS_EFFECTIVE_DATE]
	,[PHYSICIAN_AUTOMATION_CODING_DOS_EXPIRATION_DATE]
	,[COLLECT_FACILITY_SERVICE]
	,[COLLECT_FACILITY_SERVICE_EFFECTIVE_DATE]
	,[COLLECT_FACILITY_SERVICE_EXPIRATION_DATE]
	,[COLLECT_FACILITY_PROCEDURES]
	,[COLLECT_FACILITY_PROCEDURES_EFFECTIVE_DATE]
	,[COLLECT_FACILITY_PROCEDURES_EXPIRATION_DATE]
	,[COLLECT_PHYSICIAN_SERVICE]
	,[COLLECT_PHYSICIAN_SERVICE_EFFECTIVE_DATE]
	,[COLLECT_PHYSICIAN_SERVICE_EXPIRATION_DATE]
	,[COLLECT_PHYSICIAN_PROCEDURES]
	,[COLLECT_PHYSICIAN_PROCEDURES_EFFECTIVE_DATE]
	,[COLLECT_PHYSICIAN_PROCEDURES_EXPIRATION_DATE]
	,[COLLECT_INFUSIONS_INJECTIONS]
	,[COLLECT_INFUSIONS_INJECTIONS_EFFECTIVE_DATE]
	,[COLLECT_INFUSIONS_INJECTIONS_EXPIRATION_DATE]
	,[COLLECT_DIAGNOSIS_CODING]
	,[COLLECT_DIAGNOSIS_CODING_EFFECTIVE_DATE]
	,[COLLECT_DIAGNOSIS_CODING_EXPIRATION_DATE]
	,[PEND_CHARTS_FOR_AUDIT]
	,[PEND_CHARTS_FOR_AUDIT_EFFECTIVE_DATE]
	,[PEND_CHARTS_FOR_AUDIT_EXPIRATION_DATE]
	,[SHOW_INDICATORS_ON_CHARTS_PAGE]
	,[COLLECT_ADDITIONAL_PROCEDURES]
	,[COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE]
	,[COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE]
)
VALUES
(
	 @CREATING_USER_PROFILE_ID
	,@CHANGING_USER_PROFILE_ID
	,@SERVICE_AGREEMENT_ID
	,@IMPORT_DIRECTORY
	,@FACILITY_AUTOMATION_CODING_REQUIRED
	,@FACILITY_AUTOMATION_CODING_DOS_EFFECTIVE_DATE
	,@FACILITY_AUTOMATION_CODING_DOS_EXPIRATION_DATE
	,@PHYSICIAN_AUTOMATION_CODING_REQUIRED
	,@PHYSICIAN_AUTOMATION_CODING_DOS_EFFECTIVE_DATE
	,@PHYSICIAN_AUTOMATION_CODING_DOS_EXPIRATION_DATE
	,@COLLECT_FACILITY_SERVICE
	,@COLLECT_FACILITY_SERVICE_EFFECTIVE_DATE
	,@COLLECT_FACILITY_SERVICE_EXPIRATION_DATE
	,@COLLECT_FACILITY_PROCEDURES
	,@COLLECT_FACILITY_PROCEDURES_EFFECTIVE_DATE
	,@COLLECT_FACILITY_PROCEDURES_EXPIRATION_DATE
	,@COLLECT_PHYSICIAN_SERVICE
	,@COLLECT_PHYSICIAN_SERVICE_EFFECTIVE_DATE
	,@COLLECT_PHYSICIAN_SERVICE_EXPIRATION_DATE
	,@COLLECT_PHYSICIAN_PROCEDURES
	,@COLLECT_PHYSICIAN_PROCEDURES_EFFECTIVE_DATE
	,@COLLECT_PHYSICIAN_PROCEDURES_EXPIRATION_DATE
	,@COLLECT_INFUSIONS_INJECTIONS
	,@COLLECT_INFUSIONS_INJECTIONS_EFFECTIVE_DATE
	,@COLLECT_INFUSIONS_INJECTIONS_EXPIRATION_DATE
	,@COLLECT_DIAGNOSIS_CODING
	,@COLLECT_DIAGNOSIS_CODING_EFFECTIVE_DATE
	,@COLLECT_DIAGNOSIS_CODING_EXPIRATION_DATE
	,@PEND_CHARTS_FOR_AUDIT
	,@PEND_CHARTS_FOR_AUDIT_EFFECTIVE_DATE
	,@PEND_CHARTS_FOR_AUDIT_EXPIRATION_DATE
	,@SHOW_INDICATORS_ON_CHARTS_PAGE
	,@COLLECT_PHYSICIAN_PROCEDURES
	,@COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE  
	,@COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE 
)

SET @SERVICE_AGREEMENT_AUTOMATION_CODING_ID = @@IDENTITY

-- End of 05) DACS-3483 Alter Stored Proc SERVICE_AGREEMENT_AUTOMATION_CODING_INSERT.sql
GO

-- Start of 01) DACS-3484 Alter Table Chart.sql

------------------------------------------------------------------------------------
-- 01) DACS-3484 - Script - Alter table Chart to add new columns
------------------------------------------------------------------------------------
GO

ALTER TABLE 
	dbo.[Chart]
ADD 
	ADDITIONAL_PROCEDURE_CODING_RECEIVED bit null,
	ADDITIONAL_PROCEDURE_CODING_RECEIVED_DATE_TIME datetime null
GO
-- End of 01) DACS-3484 Alter Table Chart.sql
GO

-- Start of 02) DACS-3484 Alter Stored Proc CHART_SELECT_BY_CHART_ID.sql

------------------------------------------------------------------------------------
-- 02) DACS-3484 - Script - Alter stored proc CHART_SELECT_BY_CHART_ID to add 2 new columns at the end
------------------------------------------------------------------------------------
GO
  
CREATE OR ALTER PROCEDURE [dbo].[CHART_SELECT_BY_CHART_ID]  
 @CHART_ID INT  
AS  
BEGIN  
 ----------------  
 -- Simple select statement used by ChartDAO.cs within ACS  
 ----------------  
  
 ----------------  
 -- validate parameters  
 ----------------  
 IF @CHART_ID IS NULL OR @CHART_ID <= 0  
 BEGIN  
  PRINT('@CHART_ID is invalid.');  
  RETURN;  
 END;  
  
 SET NOCOUNT ON  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    
 SELECT TOP 1 -- this is a just in case safety item, do not remove. -- added DACS-3159 -- 20240412 -- pippin  
   [CHART_ID]  
  ,[SERVICE_AGREEMENT_ID]  
  ,[FACILITY_ID]  
  ,[FACILITY_CHART_ID]  
  ,[FACILITY_ADMIN_CHART_ID]  
  ,[MEDICAL_RECORD_NUM]  
  ,[PATIENT_TITLE]  
  ,[PATIENT_FIRST_NAME]  
  ,[PATIENT_MIDDLE_NAME]  
  ,[PATIENT_LAST_NAME]  
  ,[PATIENT_NAME_SUFFIX]  
  ,[PATIENT_ADDR_LINE_1]  
  ,[PATIENT_ADDR_LINE_2]  
  ,[PATIENT_CITY]  
  ,[PATIENT_STATE]  
  ,[PATIENT_ZIPCODE]  
  ,[PATIENT_DOB]  
  ,[TIME_OF_SERVICE]  
  ,[TIME_TO_ROOM]  
  ,[TIME_OF_PHYS_EVAL]  
  ,[TIME_OF_PHYS_DIS]  
  ,[TIME_OF_TRIAGE]  
  ,[TIME_OF_DIS]  
  ,[PHYSICIAN_ID]  
  ,[TRIAGE_NURSE_ID]  
  ,[DIS_NURSE_ID]  
  ,[DATE_RECEIVED]  
  ,[ASSIGNED_TO_ID]  
  ,[CHART_STATUS_ID]  
  ,[PENDING_REASON_ID]  
  ,[CODER_COMMENT]  
  ,[FAC_SVCS_COMPLETED]  
  ,[FAC_PROC_COMPLETED]  
  ,[PHYS_COMPLETED]  
  ,[PHYS_PROC_COMPLETED]  
  ,[PREBILL_AUDIT_COMPLETED]  
  ,[DEMOGRAPHICS_COMPLETED]  
  ,[RESULTS_COMPLETED]  
  ,[INFUSIONS_COMPLETED]  
  ,[FACILITY_CRITICAL_CARE]  
  ,[FACILITY_CRITICAL_CARE_MINUTES]  
  ,[PHYSICIAN_CRITICAL_CARE]  
  ,[PHYSICIAN_CRITICAL_CARE_MINUTES]  
  ,[FACILITY_LEVEL_ID]  
  ,[OVERRIDE_FACILITY_LEVEL_ID]  
  ,[PATIENT_DISPOSITION_ID]  
  ,[PHYSICIAN_HISTORY_ID]  
  ,[PHYSICIAN_EXAM_ID]  
  ,[PHYSICIAN_MDM_ID]  
  ,[PHYSICIAN_SERVICE_PROC_ID]  
  ,[PHYSICIAN_HISTORY_REASON_IF_DIFFERENT_ID]  
  ,[OVERRIDE_PHYS_HIST_ID]  
  ,[OVERRIDE_PHYS_EXAM_ID]  
  ,[OVERRIDE_PHYS_MDM_ID]  
  ,[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]  
  ,[PHYSICIAN_SERVICE_MOD]  
  ,[COMPLETED_BY_USER_PROFILE_ID]  
  ,[APPROVED_BY_USER_PROFILE_ID]  
  ,[SENT_BY_USER_PROFILE_ID]  
  ,[COMPLETION_DATE]  
  ,[APPROVED_DATE]  
  ,[SENT_DATE]  
  ,[NON_ER_PROCEDURES_OVERRIDE]  
  ,[NO_FACILITY_SERVICES]  
  ,[NO_FACILITY_PROCEDURES]  
  ,[NO_PHYSICIAN_SERVICES]  
  ,[NO_PHYSICIAN_PROCEDURES]  
  ,[NO_PREBILL_AUDIT]  
  ,[NO_INJECTIONS_OR_INFUSIONS]  
  ,[EDITED_BY_EXPERT]  
  ,[NUMBER_OF_IV_PUSHES]  
  ,[IMAGES_AVAILABLE]  
  ,[DIAGNOSIS_CODING_COMPLETE]  
  ,[NO_DIAGNOSIS_CODING]  
  ,[CHIEF_COMPLAINT]  
  ,[PATIENT_CLASS_ID]  
  ,[PATIENT_CLASS_CD]  
  ,[INSUFFICIENT_PHYSICIAN_PROCEDURE_DOC]  
  ,[INSUFFICIENT_PHYSICIAN_PROCEDURE_REASON_ID]  
  ,[CLIENT_COMMENT]  
  ,[CHART_IMAGES_TRANSMITTED]  
  ,[FINANCIAL_CLASS_CD]  
  ,[DOCUMENTATION_COMPLETED]  
  ,[DOCUMENTATION_EVALUATION_OK]  
  ,[RESIDENT_ID]  
  ,[DEPARTMENT]  
  ,[LONG_PATIENT_ID1]  
  ,[LONG_PATIENT_ID2]  
  ,[NUMBER_OF_IV_PUSHES_SAME_SUB]  
  ,[APPROVAL_REASON_CODE]  
  ,[PRIMARY_COMPLAINT]  
  ,[PATIENT_DISPOSITION_MAP_ID]  
  ,[HORMONAL]  
  ,[NON_HORMONAL]  
  ,[INTERLESIONAL_7_OR_LESS]  
  ,[INTERLESIONAL_MORE_THAN_7]  
  ,[NUMBER_CHEMOTHERAPY_IV_PUSH]  
  ,[PROLONGED_IV_CHEMOTHERAPY]  
  ,[PROLONGED_IA_CHEMOTHERAPY]  
  ,[ADDITIONAL_CRITICAL_CARE_UNITS]  
  ,[SUPPLIES_COMPLETED]  
  ,[NO_SUPPLIES]  
  ,[ADDITIONAL_COMPLAINT]  
  ,[ADDITIONAL_COMPLAINT2]  
  ,[GENDER]  
  ,[HOSPITAL_POINTS]  
  ,[HOSPITAL_CHIEF_COMPLAINT]  
  ,[APPEARS_TO_QUALIFY_FOR_CRITICAL_CARE]  
  ,[SERVICES_PERFORMED_BY_RESIDENT]  
  ,[RESIDENT_PHYS_PRESENT]  
  ,[RESIDENT_PHYS_PRESENT_REF_RES_NOTES]  
  ,[RESIDENT_PHYS_PRESENT_DISCUSSED_PLAN]  
  ,[RESIDENT_PHYS_INDEPENDENT_REF_RES_NOTES]  
  ,[RESIDENT_PHYS_INDEPENDENT_PERSONALLY_SAW]  
  ,[RESIDENT_PHYS_INDEPENDENT_DISCUSSED]  
  ,[RESIDENT_CPT_ENTIRELY_PRESENT]  
  ,[RESIDENT_CPT_PRESENT_DURING_KEY_PORTION]  
  ,[FACILITY_LEVEL_CODER_COMMENT]  
  ,[CREATION_DATE_TIME]  
  ,[CREATING_USER_PROFILE_ID]  
  ,[CHANGED_DATE_TIME]  
  ,[CHANGING_USER_PROFILE_ID]  
  ,[OVERRIDE_LCD_ERRORS]  
  ,[EVER_COMPLETED]  
  ,[LAST_ENCOUNTER_DATE]  
  ,[SAFETY_DEVICE_CD]  
  ,[SPORT_TYPE_CD]  
  ,[RESIDENT_PARTICIPATED_IN_CARE]  
  ,[ATTESTATION_SIGNED_BY_ATTENDING]  
  ,[REPORT_CHIEF_COMPLAINT_AS_SECONDARY]  
  ,[REPORT_ADDITIONAL_COMPLAINT_AS_SECONDARY]  
  ,[REPORT_ADDITIONAL_COMPLAINT2_AS_SECONDARY]  
  ,[PATIENT_AGE]  
  ,[START_QA_USER_PROFILE_ID]  
  ,[START_QA_DATE]  
  ,[PHYSICIAN_SIGNATURE_PRESENT]  
  ,[OBS_DEPT_EVAL_COMPLETED]  
  ,[INITIAL_CHARGE_MASTER_DEPT_ID]  
  ,[PHYSICIAN_LEVEL_CODER_COMMENT]  
  ,[EXCLUDE_OBSERVATION_DIRECT_CHARGE]  
  ,[NURSE_PRACTITIONER_ID]  
  ,[ADD_MODIFIER_32_TO_PHYSICIAN_LOS]  
  ,[NO_PHYSICIAN_LOS_REASON_ID]  
  ,[CLINIC_ID]  
  ,[SERIAL_CODE]  
  ,[REGISTRATION_AREA]  
  ,[REGISTRATION_CODE]  
  ,[SERVICE_LINE_ID]  
  ,[TERMINAL_DIGITS]  
  ,[IMAGE_SOURCE_ID]  
  ,[PAYOR_CD]  
  ,[POTENTIAL_PHYSICIAN_SERVICE_CPT_CODE]  
  ,[IS_PRIORITY]  
  ,[NO_ACTIVITY_CODES]  
  ,[NO_LCD_SERVICES]  
  ,[MODIFIER_25_REQUIRED_REASON_ID]  
  ,[CONDITION_OF_ACCIDENT_ID]  
  ,[ACCIDENT_DATE]  
  ,[ADMISSION_DATE_TIME]  
  ,[OBSERVATION_ATTENDING_PROVIDER_ID]  
  ,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]  
  ,[PATIENT_DISPOSITION_DESTINATION_ID]  
  ,[NO_OBSERVATION_HOURS]  
  ,[OBSERVATION_COMPLETED_BY_USER_PROFILE_ID]  
  ,[OBSERVATION_COMPLETION_DTTM]  
  ,[OBSERVATION_PROCEDURES_AUDIT_COMMENT]  
  ,[OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT]  
  ,[OBSERVATION_AUDITOR_REVIEW_FEEDBACK]  
  ,[FACILITY_LOS_27_MODIFIER]  
  ,[OBSERVATION_BILLING_METHOD_CD]  
  ,[ARRIVAL_DATE_TIME]  
  ,[SERVICE_AGREEMENT_TRIAGE_ACUITY_ID]  
  ,[SERVICE_AGREEMENT_ARRIVAL_MODE_ID]  
  ,[FACILITY_CRITICAL_CARE_CALC_METHOD_CD]  
  ,[FACILITY_CRITICAL_CARE_START_DATE]  
  ,[FACILITY_CRITICAL_CARE_STOP_DATE]  
  ,[PHYSICIAN_CRITICAL_CARE_CALC_METHOD_CD]  
  ,[PHYSICIAN_CRITICAL_CARE_START_DATE]  
  ,[PHYSICIAN_CRITICAL_CARE_STOP_DATE]  
  ,[AUDIT_REQUIRED]  
  ,[ARRIVAL_DATE_TIME_NOT_AVAILABLE]  
  ,[TIME_OF_TRIAGE_NOT_AVAILABLE]  
  ,[TIME_TO_ROOM_NOT_AVAILABLE]  
  ,[TIME_OF_PHYSICIAN_EVAL_NOT_AVAILABLE]  
  ,[ARRIVAL_MODE_NOT_AVAILABLE]  
  ,[TRIAGE_ACUITY_NOT_AVAILABLE]  
  ,[OBSERVATION_TELEMETRY]  
  ,[DEMOGRAPHIC_AUDIT_COMMENT]  
  ,[LAST_MENSTRUAL_PERIOD]  
  ,[PAYOR_NAME]  
  ,[SERVICE_AGREEMENT_MODE_OF_DEPARTURE_ID]  
  ,[ORGAN_DONATION]  
  ,[REASON_FOR_VISIT_CATEGORY_DETAIL_ID]  
  ,[ADD_MODIFIER_57_TO_PHYSICIAN_LOS]  
  ,[DO_NOT_APPLY_PHYSICIAN_MODIFER_25]  
  ,[ADD_MODIFIER_GW_TO_PHYSICIAN_LOS]  
  ,[PRIMARY_CARE_PHYSICIAN_ID]  
  ,[SCRIBE_ID]  
  ,[NO_ATTENDING_PROVIDER_SELECTED_IND]  
  ,[PROVIDER_EVAL_PERFORMED_BY_IND]  
  ,[BILLING_INSTRUCTIONS]  
  ,[PHYSICIAN_SERVICE_OBSERVATION_ADMIT_DATETIME]  
  ,[PHYSICIAN_SERVICE_OBSERVATION_DISCHARGE_DATETIME]  
  ,[PHYSICIAN_SERVICE_OBSERVATION_FINAL_EXAM]  
  ,[SUBSEQUENT_VISIT_CODE]  
  ,[SERVICE_AGREEMENT_ADMIT_TYPE_ID]  
  ,[LOCATION_CODE]  
  ,[BILLING_AREA]  
  ,[ADD_GC_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]  
  ,[ADD_GE_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]  
  ,[MEDICAL_EXAMINER_NOTIFIED]  
  ,[SEEN_IN_ED_WITHIN_48_HOURS_OF_OR]  
  ,[ADD_24_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]  
  ,[ADD_PHYSICIAN_SVC_25_MODIFIER]  
  ,[LMP_DATE_NOT_AVAILABLE]  
  ,[OBSERVATION_DISCHARGE_PROVIDER_ID]  
  ,[FORCED_AUDIT]  
  ,[FLAGGED_FOR_AUDIT]  
  ,[START_SECOND_LEVEL_QA_DATETIME]  
  ,[START_SECOND_LEVEL_QA_USER_PROFILE_ID]  
  ,[SECOND_LEVEL_QA_APPROVED_DATETIME]  
  ,[SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID]  
  ,[QUALIFIED_FOR_SECOND_AUDIT_AT_COMPLETION]  
  ,[FRACTURE_CARE_CPT_CHARGED]  
  ,[SERVICE_AGREEMENT_TRANSFER_FACILITY_ID]  
  ,[OVERRIDE_PHYSICIAN_SERVICE_GUIDELINE_ID]  
  ,[PHYSICIAN_SERVICE_SPECIALTY_TEMPLATE_ID]  
  ,[USE_TIME_BASED_CHARGE_CAPTURE]  
  ,[TIME_BASED_CHARGE_CAPTURE_COMMENT]  
  ,[TIME_BASED_PHYSICIAN_LOS]  
  ,[POST_BILL_AUDIT_STARTED]  
  ,[POST_BILL_AUDIT_STARTED_BY_USER_ID]  
  ,[POST_BILL_AUDIT_COMPLETED]  
  ,[POST_BILL_AUDIT_COMPLETED_BY_USER_ID]  
  ,[FLAGGED_FOR_POST_BILL_AUDIT_DT]  
  ,[ADD_59_XU_MODIFIER]  
  ,[ANESTHESIA_CODING_COMPLETE]  
  ,[NO_ANESTHESIA_CODING]  
  ,[USE_PREVENTATIVE_MEDICINE_CHARGE_CAPTURE]  
  ,[PREVENTATIVE_MEDICINE_PHYSICIAN_PROC_ID]  
  ,[USE_INPATIENT_DOWNCODE_OPTION]  
  ,[BYPASS_AUTO_APPROVAL]  
  ,[FACILITY_LOS_AF_MODIFIER]  
  ,[FACILITY_LOS_AG_MODIFIER]  
  ,[ADD_AI_MODIFIER_TO_PHYSICIAN_SERVICE_LEVEL]  
  ,[DO_NOT_APPLY_FACILITY_MODIFIER_25]  
  ,[ADD_MODIFIER_CG_TO_PHYSICIAN_LOS]  
  ,[USE_EXPERT_HISTORY_WORKSHEET_SECTION]  
  ,[USE_EXPERT_EXAM_WORKSHEET_SECTION]  
  ,[USE_EXPERT_MDM_WORKSHEET_SECTION]  
  ,[ADD_MODIFIER_GQ_TO_PHYSICIAN_LOS]  
  ,[ADD_MODIFIER_GT_TO_PHYSICIAN_LOS]  
  ,[ADD_MODIFIER_G0_TO_PHYSICIAN_LOS]  
  ,[ADD_MODIFIER_95_TO_PHYSICIAN_LOS]  
  ,[FACILITY_LOS_CS_MODIFIER]  
  ,[ADD_MODIFIER_CS_TO_PHYSICIAN_LOS]  
  ,[FACILITY_LOS_95_MODIFIER]  
  ,[ADD_MODIFIER_CR_TO_PHYSICIAN_LOS]  
  ,[CHART_HAS_QA_SCORECARD_DATA]  
  ,[CLINIC_2021_TIME_BASED_ENCOUNTER_MINUTES]  
  ,[CLINIC_2021_TIME_BASED_SERVICE_LEVEL_CODE]  
  ,[CLINIC_2021_CALCULATED_SERVICE_LEVEL_CODE]  
  ,[CLINIC_2021_TIME_BASED_ADDITIONAL_QUANTITY]  
  ,[CLINIC_2021_TIME_BASED_ADDITIONAL_CPT_CODE]  
  ,[ADD_MODIFIER_GV_TO_PHYSICIAN_LOS]  
  ,[PROVIDER_TYPE_CREDENTIALS_MODIFIER]  
  ,[SERVICE_AGREEMENT_PROVIDER_TYPE_CREDENTIAL_ID]  
  ,[ADD_MODIFIER_EP_TO_PHYSICIAN_LOS]  
  ,[PROVIDER_SPECIFIED_LOS_PHYSICIAN_SERVICE_PROC_ID]  
  ,[PROVIDER_SPECIFIED_LOS_MODIFIER]  
  ,[ADMIT_SOURCE_ID]  
  ,[DATE_TIME_OF_DEATH]  
  ,[FACILITY_AUTOMATION_CODING_COMPLETE]  
  ,[FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME]  
  ,[PHYSICIAN_AUTOMATION_CODING_COMPLETE]  
  ,[PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME]  
  ,[FLAG_CHART_FOR_AUTOMATION_CODING_AUDIT]  
  ,[ADD_MODIFIER_AF_TO_PHYSICIAN_LOS]  
  ,[ADD_MODIFIER_AG_TO_PHYSICIAN_LOS]  
  ,[CODER_ERROR_RESPONSE]  
  ,[CODER_ERROR_RESPONSE_COMMENTS]  
  ,[AUDITOR_ERROR_RESPONSE]  
  ,[AUDITOR_ERROR_RESPONSE_COMMENTS]  
  ,[CODER_RESPONSE_DATE]  
  ,[AUDITOR_RESPONSE_DATE]  
  ,[USE_TELEHEALTH]  
  ,[ATTESTATION_SYNCHRONIZED_AV_PRESENT]  
  ,[PLOS_ICD_10_CODE]  
  ,[ADD_MODIFIER_AM_TO_PHYSICIAN_LOS]  
  ,[ADD_MODIFIER_U7_TO_PHYSICIAN_LOS]  
  ,[FACILITY_LOS_32_MODIFIER]  
  ,[NO_PROVIDER_SPECIFIED_PROCEDURES]  
  ,[ADD_MODIFIER_SA_TO_PHYSICIAN_LOS]  
  ,[ADD_MODIFIER_93_TO_PHYSICIAN_LOS] -- added DACS-2475 - 20230619 - pippin  
  ,[FACILITY_LOS_93_MODIFIER]   -- added DACS-2475 - 20230619 - pippin  
  ,[ADD_MODIFIER_FS_TO_PHYSICIAN_LOS] -- added DACS-2485 - 20230626 - pippin  
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED -- added column DACS-3484 
  ,ADDITIONAL_PROCEDURE_CODING_RECEIVED_DATE_TIME -- added column DACS-3484 
 FROM   
  [dbo].[CHART]   
 WHERE   
  [CHART_ID] = @CHART_ID;  
END  
  
-- End of 02) DACS-3484 Alter Stored Proc CHART_SELECT_BY_CHART_ID.sql
GO

-- Start of 01) DACS-3485 Create Table TenetChargeValidation.sql

------------------------------------------------------------------------------------
-- 01) DACS-3485 - Script - Create table TenetChargeValidation
------------------------------------------------------------------------------------
GO

GO

GO

CREATE TABLE [dbo].[TenetChargeValidation]
(
	[TenetChargeValidationId] [int] IDENTITY(1,1) NOT NULL CONSTRAINT [PK_TenetChargeValidation_TenetChargeValidationId] PRIMARY KEY CLUSTERED,
	[PatientId] [varchar](20) NOT NULL,
	[BillingCode] [varchar](20) NOT NULL,
	[CPTCode] [varchar](5) NOT NULL,
	[TenetChargeId] [int] NOT NULL,
	[CreationDateTime] [datetime] NOT NULL	
)
-- End of 01) DACS-3485 Create Table TenetChargeValidation.sql
GO

-- Start of 02) DACS-3485 Stored Proc SelectTenetChargeValidation.sql

---------------------------------------------------------------------------------------------------------------------
-- 02) DACS-3485 - Stored Procedure [dbo].[SelectTenetChargeValidation] to select all TenetChargeValidation
---------------------------------------------------------------------------------------------------------------------

GO

CREATE PROCEDURE [dbo].[SelectTenetChargeValidation]
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	[TenetChargeValidationId],
	[PatientId],
	[BillingCode],
	[CPTCode],
	[TenetChargeId],
	[CreationDateTime]
FROM
	[TenetChargeValidation]

GO
-- End of 02) DACS-3485 Stored Proc SelectTenetChargeValidation.sql
GO

-- Start of 03) DACS-3485 Stored Proc InsertTenetChargeValidation.sql

------------------------------------------------------------------
-- 03) DACS-3485 - Insert
------------------------------------------------------------------

GO

RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertTenetChargeValidation', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.InsertTenetChargeValidation
	 @PatientId varchar(20)
	,@BillingCode varchar(20)
	,@CPTCode varchar(5)
	,@TenetChargeId int
	,@CreationDateTime datetime
	,@TenetChargeValidationId int OUTPUT
AS

INSERT INTO [dbo].[TenetChargeValidation]
(
	 [PatientId]
	,[BillingCode]
	,[CPTCode]
	,[TenetChargeId]
	,[CreationDateTime]
)
VALUES
(
	 @PatientId
	,@BillingCode
	,@CPTCode
	,@TenetChargeId
	,@CreationDateTime 
)

SET @TenetChargeValidationId = @@IDENTITY

GO
-- End of 03) DACS-3485 Stored Proc InsertTenetChargeValidation.sql
GO

-- Start of 04) DACS-3485 Stored Proc TenetChargeValidationDeleteByTenetChargeValidationId.sql

------------------------------------------------------------------
-- 04) DACS-3485 - Delete by primary key or unique index(es)
------------------------------------------------------------------
GO

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteTenetChargeValidationByTenetChargeValidationId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.DeleteTenetChargeValidationByTenetChargeValidationId
	@TenetChargeValidationId int
AS

DELETE 
	FROM [dbo].[TenetChargeValidation]
WHERE
	[TenetChargeValidationId] = @TenetChargeValidationId

GO
-- End of 04) DACS-3485 Stored Proc TenetChargeValidationDeleteByTenetChargeValidationId.sql
GO

-- Start of 05) DACS-3485 Stored Proc SelectTenetChargeValidationByTenetChargeValidationId.sql

------------------------------------------------------------------
-- 05) DACS-3485 - Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
GO

RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectTenetChargeValidationByTenetChargeValidationId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectTenetChargeValidationByTenetChargeValidationId]
	@TenetChargeValidationId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [TenetChargeValidation].[TenetChargeValidationId]
	,[TenetChargeValidation].[PatientId]
	,[TenetChargeValidation].[BillingCode]
	,[TenetChargeValidation].[CPTCode]
	,[TenetChargeValidation].[TenetChargeId]
	,[TenetChargeValidation].[CreationDateTime]
FROM
	[dbo].[TenetChargeValidation]
WHERE
	[TenetChargeValidation].[TenetChargeValidationId] = @TenetChargeValidationId

GO	
-- End of 05) DACS-3485 Stored Proc SelectTenetChargeValidationByTenetChargeValidationId.sql
GO

-- Start of 06) DACS-3485 Stored Proc UpdateByTenetChargeValidationByTenetChargeValidationId.sql

------------------------------------------------------------------
-- 06) DACS-3485 - Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByTenetChargeValidationByTenetChargeValidationId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByTenetChargeValidationByTenetChargeValidationId
	 @TenetChargeValidationId int
	,@PatientId varchar(20)
	,@BillingCode varchar(20)
	,@CPTCode varchar(5)
	,@TenetChargeId int
	,@CreationDateTime datetime
AS

UPDATE [dbo].[TenetChargeValidation] SET
	 [PatientId] = @PatientId
	,[BillingCode] = @BillingCode
	,[CPTCode] = @CPTCode
	,[TenetChargeId] = @TenetChargeId
	,[CreationDateTime] = @CreationDateTime
WHERE
	[TenetChargeValidationId] = @TenetChargeValidationId
GO
-- End of 06) DACS-3485 Stored Proc UpdateByTenetChargeValidationByTenetChargeValidationId.sql
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
