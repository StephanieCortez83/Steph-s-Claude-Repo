------------------------------------------------------------------------------------
-- 02) DACS-3223 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = ECPR51.SQL
------------------------------------------------------------------------------------
USE [CMSRules]
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = 'ECPR51';
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
		-- Diagnosis of opioid poisoning from heroin, methadone, morphine, opium, codeine, hydrocodone, or another opioid substance (ICD10)
		 (@MeasureId,'DG1P1','T40.0X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X1D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X1S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X2D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X2S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X3D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X3S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X4D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.0X4S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X1D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X1S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X2D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X2S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X3D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X3S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X4D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.1X4S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X1D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X1S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X2D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X2S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X3D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X3S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X4D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.2X4S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X1A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X1D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X1S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X2A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X2D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X2S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X3A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X3D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X3S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X4A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X4D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.3X4S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.411A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.411D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.411S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.412A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.412D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.412S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.413A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.413D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.413S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.414A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.414D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.414S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.421A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.421D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.421S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.422A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.422D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.422S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.423A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.423D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.423S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.424A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.424D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.424S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.491A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.491D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.491S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.492A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.492D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.492S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.493A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.493D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.493S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.494A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.494D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.494S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.601A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.601D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.601S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.602A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.602D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.602S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.603A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.603D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.603S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.604A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.604D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.604S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.691A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.691D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.691S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.692A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.692D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.692S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.693A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.693D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.693S',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.694A',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.694D',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','T40.694S',NULL,@Dos,NULL)

		-- Eligible Professional in  Eligible Professional in acute care settings (CPT)
		,(@MeasureId,'DG1P2','99234',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99235',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99236',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99238',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99239',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
	 
		-- measure code numerators
		,(@MeasureId,'HCPCS','VE269',NULL,@Dos,'Performance Met: Naloxone was prescribed at discharge AND patient was educated about use. *NOTE: Distribution of Naloxone to patient at discharge is also acceptable in lieu of Naloxone prescription')
		,(@MeasureId,'HCPCS','VE271',NULL,@Dos,'Performance Not Met: Naloxone medication was not prescribed at discharge OR patient was not educated about use. ')
		,(@MeasureId,'HCPCS','VE270',NULL,@Dos,'Denominator Exception: Naloxone was not prescribed at discharge due to medical reasons such as allergy. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','DG519',NULL,@Dos,'Patient has Disposition of Discharged (Pseudo code - DG519)? ')
		,(@MeasureId,'DQ411','V0700',NULL,@Dos,'Patient did NOT Transfer, elope or is an AMA patients (V0700)? ')
		
		-- add the default procedure code handler for unanswered questions
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		; -- expect 124 total inserts
		
		
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
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = 'ECPR51' -- = 225
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 225
*/