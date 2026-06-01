------------------------------------------------------------------------------------
-- 01) DACS-3476 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 066.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '066';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] < @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	-- expire the old rule - Pre MIPS 2024
	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @Dos
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END;

	
	PRINT('Inserting MIPS 2024 Rule for [' + @PqrsCd + '] ...');
	
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
			,'MIPS# ' + @PqrsCd + ' : Appropriate Testing for Pharyngitis : The percentage of episodes for patients 3 years and older with a diagnosis of pharyngitis that resulted in an antibiotic order on or within 3 days after the episode date and a group A Streptococcus (Strep) test in the seven-day period from three days prior to the episode date through three days after the episode date. '	
			,'B'
			,3
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '066' -- = 1230
*/