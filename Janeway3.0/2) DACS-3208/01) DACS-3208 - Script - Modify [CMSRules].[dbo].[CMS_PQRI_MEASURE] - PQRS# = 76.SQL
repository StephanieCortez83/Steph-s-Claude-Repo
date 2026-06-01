------------------------------------------------------------------------------------
-- 01) DACS-3208 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - PQRS# = 76.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '76';
	DECLARE @Dos DATETIME = '01-01-2024';
	DECLARE @dateOfExpiration DATETIME = '12-31-2023';

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	PRINT('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('Expiring...');
		
		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET [EXPIRATION_DATE] = @dateOfExpiration
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	

		SET @countPQRS = 
			(
				SELECT COUNT(*) 
				FROM [dbo].[CMS_PQRI_MEASURE] 
				WHERE [PQRS#] = @PqrsCd
					AND [EFFECTIVE_DATE] <= @Dos
					AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
			);

		PRINT('after expiration @countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));
		
		IF @countPQRS > 0
		BEGIN 
			PRINT('Expiration failed.  Needs table assistance.  Exiting.');
			RETURN;
		END;

	END;

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
			 '76'
			,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
			,'PQRS# 76 Prevention of Central Venous Catheter (CVC): Related Bloodstream Infections'	
			,'B'
			,0
			,999
			,@Dos
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,0
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
		);

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
SELECT TOP 1000 * FROM [dbo].[CMS_PQRI_MEASURE]
where [PQRS#] IN ('76');
*/