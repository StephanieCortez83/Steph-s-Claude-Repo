------------------------------------------------------------------------------------
-- 01) DACS-3524 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 047.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '047';
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
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' : Advance Care Plan : Percentage of patients aged 65 years and older who have an advance care plan or surrogate decision maker documented in the medical record or documentation in the medical record that an advance care plan was discussed but the patient did not wish or was not able to name a surrogate decision maker or provide an advance care plan. '
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
				,'MIPS# ' + @PqrsCd + ' : Advance Care Plan : Percentage of patients aged 65 years and older who have an advance care plan or surrogate decision maker documented in the medical record or documentation in the medical record that an advance care plan was discussed but the patient did not wish or was not able to name a surrogate decision maker or provide an advance care plan. '	
				,'B'
				,65
				,999
				,@Dos
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '047' -- = 1231
*/