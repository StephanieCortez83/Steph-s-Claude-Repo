------------------------------------------------------------------------------------
-- 01) DACS-3457 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS = 416 (old).SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '416';
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
			,'Efficiency – High Priority'
			,'MIPS# ' + @PqrsCd + ' : Emergency Medicine: Emergency Department Utilization of CT for Minor Blunt Head Trauma for Patients Aged 2 Through 17 Years : Percentage of emergency department visits for patients aged 2 through 17 years who presented with a minor blunt head trauma who had a head CT for trauma ordered by an emergency care provider who are classified as low risk according to the Pediatric Emergency Care Applied Research Network (PECARN) prediction rules for traumatic brain injury. 			<p><strong>Definition:</strong></p> <p><strong>Low Risk for Traumatic Brain Injury according to PECARN prediction rules –</strong></p> <p>Patients can be classified as low risk if ALL of the following are met: <ul><li>No signs of altered mental status (e.g., agitation, somnolence, repetitive questioning, slow response to verbal communication) OR no GCS < 15</li><li>No signs of basilar skull fracture (signs include haemotympanum, “raccoon” eyes, cerebrospinal fluid leakage from the ear or nose, Battle’s sign)</li><li>No loss of consciousness</li><li>No vomiting</li><li>No severe mechanism of injury (i.e., motor vehicle crash with patient ejection, death of another passenger, or rollover; pedestrian or bicyclist without helmet struck by a motorized vehicle; falls of more than 5 feet; or head struck by a high-impact object)</li><li>No severe headache</li></ul></p> '	
			,'B'
			,2
			,18
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '416' -- = 228
*/