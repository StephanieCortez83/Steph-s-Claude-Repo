------------------------------------------------------------------------------------
-- 01) DACS-3453 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 187 (old).SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '187';
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
			,'MIPS# ' + @PqrsCd + ' : Stroke and Stroke Rehabilitation: Thrombolytic Therapy : Percentage of patients aged 18 years and older with a diagnosis of acute ischemic stroke who arrive at the hospital within 3.5 hours of time last known well and for whom IV thrombolytic therapy was initiated within 4.5 hours of time last known well. '	
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '187' -- = 214
*/