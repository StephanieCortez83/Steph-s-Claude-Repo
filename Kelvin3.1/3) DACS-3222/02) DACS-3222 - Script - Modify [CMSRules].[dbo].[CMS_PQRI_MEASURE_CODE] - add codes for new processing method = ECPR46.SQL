------------------------------------------------------------------------------------
-- 02) DACS-3222 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR46.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ECPR46';
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
		PRINT('No Measure loaded for [' + @PqrsCd + '].  Cannot continue.');
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
		-- Diagnosis of low back pain OR migraine (ICD10)
		 (@MeasureId,'DG1P1','M54.50',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','M54.51',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','M54.59',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.001',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.009',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.011',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.019',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.101',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.109',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.111',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.119',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.401',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','G43.409',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.411',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.419',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.501',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.509',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.511',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.519',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.601',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.609',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.611',NULL,@Dos,NULL) 
		,(@MeasureId,'DG1P1','G43.619',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.701',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.709',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.711',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.719',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.A0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.A1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.B0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.B1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.C0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.C1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.D0',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.D1',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.801',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.809',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.811',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.819',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.821',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.829',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.831',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.839',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.901',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.909',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.911',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.919',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.E01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.E09',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.E11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','G43.E19',NULL,@Dos,NULL)

		-- Eligible Professional in Emergency Department, Urgent Care Clinic, or Outpatient Clinic settings (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99291',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99292',NULL,@Dos,NULL)

		-- Disposition of Discharged – (Pseudo Code)
		-- might need to be a question
		--,(@MeasureId,'DG2P1','DG469',NULL,@Dos,NULL)
	 
		-- measure code numerators
		,(@MeasureId,'HCPCS','VE264',NULL,@Dos,'Denominator EXCLUSIONS: Opiate prescribed for medical reason documented by the Eligible Professional (i.e., suspected or diagnosed herniated disk, fracture, sciatica, radiculopathy). <p><img src="/WebPages/Images/MIPS/Mips_ECPR46_AppendixAOpoidMedications.png" alt="(VE264) Appendix - Opoid Medications image"></p> ')
		,(@MeasureId,'HCPCS','VE263',NULL,@Dos,'Performance Met: Opiate not prescribed at discharge. ')
		,(@MeasureId,'HCPCS','VE265',NULL,@Dos,'Performance Not Met: Opiate prescribed, reason not specified. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','DG469',NULL,@Dos,'Patient Disposition of Discharged – (Pseudo Code) (DG469)? ')
		,(@MeasureId,'DQ411','V0709',NULL,@Dos,'Patient does NOT have active cancer, palliative care, or end-of-life care (V0709)? ')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 72 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR46' -- = 224
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 224
*/