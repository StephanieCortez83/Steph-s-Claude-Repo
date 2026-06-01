SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ChargeMasterModifiersQualifyUpdateByServiceAgreementIds]
	 @SourceSAId INT
	,@TargetSAId INT
	,@UPId INT
	,@InsDate DATETIME = NULL
	,@MaxToProcess INT = 100000
	,@DateMin DATETIME = NULL
	,@UseDateMinLimit BIT = 0
AS
BEGIN
	SET NOCOUNT ON  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

	DECLARE @Dos DATETIME = GETDATE();
	DECLARE @MaxToSources INT = 200000;		-- for testing

	IF @SourceSAId IS NULL OR @SourceSAId <= 0
	BEGIN
		SELECT Result = -1, Error = 'Error: Source SA Id is invalid.';
		RETURN;
	END;

	IF @TargetSAId IS NULL OR @TargetSAId <= 0
	BEGIN
		SELECT Result = -2, Error = 'Error: Target SA Id is invalid.';
		RETURN;
	END;

	IF @UPId IS NULL OR @UPId <= 0
	BEGIN
		SELECT Result = -3, Error = 'Error: UP Id is invalid.';
		RETURN;
	END;

	IF @InsDate IS NULL
		SET @InsDate = CONVERT(date, GETDATE());

	IF @MaxToProcess IS NULL OR @MaxToProcess <= 0
		SET @MaxToProcess = 10000;

	IF @UseDateMinLimit = 1 AND @DateMin IS NULL
		SET @DateMin = DATEADD(DAY, -1, @Dos);


	------------------------------------------------------------------------------------------------------------------
	-- Make sure we have charge master data already inserted for the target CM
	-- we would prefer these counts to be the same, but the later join statements can deal with missmatches with Target being the assumed correct number
	------------------------------------------------------------------------------------------------------------------
	DECLARE @CountSourceCM INT = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE [SERVICE_AGREEMENT_ID] = @SourceSAId);
	-- SELECT * FROM CHARGE_MASTER WHERE [SERVICE_AGREEMENT_ID] = @SourceSAId -- testing
	DECLARE @CountTargetCM INT = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId);
	-- SELECT * FROM CHARGE_MASTER WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId -- testing

	IF @CountTargetCM <= 0
	BEGIN 
		SELECT Result = -4, Error = 'Error: NO Target [' + CAST(@TargetSAId AS VARCHAR(30)) + '] Charge Master CPT codes to process.';
		RETURN;
	END;

	IF @CountSourceCM <= 0
	BEGIN 
		SELECT Result = -4, Error = 'Error: NO Source [' + CAST(@CountSourceCM AS VARCHAR(30)) + '] Charge Master CPT codes to process.';
		RETURN;
	END;

	------------------------------------------------------------------------------------------------------------------
	-- Populate Temporary Table of data to process
	-- get a list of the recently added cpt codes to our target SA that came from our source SA
	-- normally this SPROC will be run just before this one. but we will allow for a date_created filter of 1day
	------------------------------------------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #TempRows;

	SELECT DISTINCT
		 cm.[cpt_code]																dest_cm_cpt
		,cm.[CHARGE_MASTER_ID]														dest_cmid
		,(SELECT STRING_AGG([MODIFIER], '|') 
			FROM [CHARGE_MASTER_MODIFIER] 
			WHERE [SERVICE_AGREEMENT_ID] = @SourceSAId AND [CHARGE_MASTER_ID] = (
				SELECT TOP 1 [CHARGE_MASTER_ID] FROM CHARGE_MASTER 
				WHERE [SERVICE_AGREEMENT_ID] = @SourceSAId 
					AND [CPT_CODE] = cm.[CPT_CODE]
					AND [BILLING_CODE] = cm.[BILLING_CODE]
					AND [DESCRIPTION] = cm.[DESCRIPTION])) AS						src_mods
		,(SELECT STRING_AGG([DESCRIPTION], '|') 
			FROM [CHARGE_MASTER_MODIFIER] 
			WHERE [SERVICE_AGREEMENT_ID] = @SourceSAId AND [CHARGE_MASTER_ID] = (
				SELECT TOP 1 [CHARGE_MASTER_ID] FROM CHARGE_MASTER 
				WHERE [SERVICE_AGREEMENT_ID] = @SourceSAId 
					AND [CPT_CODE] = cm.[CPT_CODE]
					AND [BILLING_CODE] = cm.[BILLING_CODE]
					AND [DESCRIPTION] = cm.[DESCRIPTION])) AS						src_mods_desc
	INTO #TempRows
	FROM 
		[CHARGE_MASTER] cm
	WHERE
		[SERVICE_AGREEMENT_ID] = @TargetSAId
		AND ((@UseDateMinLimit = 1 AND [CREATION_DATE_TIME] >= @DateMin) OR @UseDateMinLimit <> 1)
		AND @Dos BETWEEN [EFFECTIVE_DATE] AND COALESCE([EXPIRATION_DATE], '12-31-2099')
	ORDER BY 
		dest_cm_cpt;

	DELETE FROM #TempRows WHERE src_mods IS NULL;
	--SELECT * FROM #TempRows -- testing

	DECLARE @tempTableRowCount INT = (SELECT COUNT(*) FROM #TempRows);
	DECLARE @tmpCountOne INT = @tempTableRowCount;

	IF @tempTableRowCount <= 0
	BEGIN
		SELECT Result = 0, Error = 'No new data rows to insert';
		RETURN;
	END;

	------------------------------------------------------------------------------------------------------------------
	-- fetch loop to process all cpt codes / charge_master ids to add
	------------------------------------------------------------------------------------------------------------------
	DECLARE @ErrorCount INT = 0;
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = @tempTableRowCount;
	DECLARE @FetchCmid INT;
	DECLARE @FetchCptCode VARCHAR(20);
	DECLARE @FetchModifiers VARCHAR(MAX);
	DECLARE @FetchModDescriptions VARCHAR(MAX);
	DECLARE @msg VARCHAR(MAX);
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT dest_cm_cpt, dest_cmid, src_mods, src_mods_desc FROM #TempRows;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchCptCode, @FetchCmid, @FetchModifiers, @FetchModDescriptions;
				
	PRINT('------------------- processing #TempRows loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		--IF @ProcessCount > 20 -- testing
		--BEGIN
		--	PRINT('Exiting main fetch loop.  Testing limit = 10.') 
		--	BREAK;
		--END;

		PRINT('');
		PRINT('     =============================');
		PRINT('');
		SET @msg = '==> Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' : cmid: ' + CAST(@FetchCmid AS VARCHAR(50)) 
			+ ' : cpt: ' + CAST(@FetchCptCode AS VARCHAR(50)) 
			+ ' : mods: ' + CAST(@FetchModifiers AS VARCHAR(50)) 
			+ ' : mdesc: ' + CAST(@FetchModDescriptions AS VARCHAR(50)) ;
		PRINT(@msg);
		
		-- now break up the modifiers and their descriptions and perform and insert into the table.
		DROP TABLE IF EXISTS #loopMods;
		CREATE TABLE #loopMods
		(
			ID INT IDENTITY(1, 1)
		   ,Modifier VARCHAR(10)
		);
		
		INSERT #loopMods(Modifier)
		SELECT 
			RTRIM(LTRIM(value)) AS Modifier
			FROM STRING_SPLIT (@FetchModifiers, '|')

		DROP TABLE IF EXISTS #loopModDescp;
		CREATE TABLE #loopModDescp
		(
			ID INT IDENTITY(1, 1)
		   ,Descp VARCHAR(512)
		);
		
		IF @FetchModDescriptions IS NOT NULL
			INSERT #loopModDescp(Descp)
			SELECT 
				RTRIM(LTRIM(value)) AS Descp
				FROM STRING_SPLIT (@FetchModDescriptions, '|')
			UPDATE #loopModDescp
				SET Descp = ''
				WHERE Descp IS NULL;

		------------------------------------------------------------------------------------------------------------------
		-- loop to process all modifiers and descriptions
		------------------------------------------------------------------------------------------------------------------
		DECLARE @PreviousModifier VARCHAR(2) = '';
		DECLARE @InnerCounter INT = 1;
		DECLARE @InnerMax INT = (SELECT MAX(ID) FROM #loopMods); 

		WHILE @InnerCounter <= @InnerMax
		BEGIN
			PRINT CONCAT('====>> Inner Loop Iteration: ', @InnerCounter);
			
			DECLARE @InnerModifier VARCHAR(2) = (SELECT Modifier FROM #loopMods WHERE ID = @InnerCounter);
			DECLARE @InnerDescription VARCHAR(512) = (IIF((SELECT TOP 1 1 FROM #loopModDescp) IS NULL, '', (SELECT Descp FROM #loopModDescp WHERE ID = @InnerCounter)));
			PRINT('    Inner Loop Modifier = ' + ISNULL(@InnerModifier, 'NULL') + ', descp = ' + ISNULL(@InnerDescription, 'NULL'));
			
			IF LEN(@InnerModifier) = 2 AND @InnerModifier <> @PreviousModifier
			BEGIN 
				BEGIN TRY
					SET @PreviousModifier = @InnerModifier;					
					
					IF NOT EXISTS (SELECT TOP 1 1 FROM [CHARGE_MASTER_MODIFIER] WHERE [CHARGE_MASTER_ID] = @FetchCmid AND [MODIFIER] = @InnerModifier )
					BEGIN
						INSERT INTO [RevCycleDB].[dbo].[CHARGE_MASTER_MODIFIER]
						(
							 [SERVICE_AGREEMENT_ID]
							,[CHARGE_MASTER_ID]
							,[MODIFIER]
							,[DESCRIPTION]
							,[CREATION_DATE_TIME]
							,[CREATING_USER_PROFILE_ID]
							,[CHANGED_DATE_TIME]
							,[CHANGING_USER_PROFILE_ID]
						)
						VALUES
						(
							 @TargetSAId
							,@FetchCmid
							,@InnerModifier
							,@InnerDescription
							,@Dos
							,@UPId
							,@Dos
							,@UPId
						);
					END;

				END TRY
				BEGIN CATCH
					PRINT('    !!Exception occurred [' + @FetchCptCode + ', ' + CAST(@FetchCmid AS VARCHAR(50)) + ', ' + @InnerModifier + ', ' + @InnerDescription + '].  Error = ' 
							+ CAST(ERROR_NUMBER() AS VARCHAR(30)) + ' :: ' + CAST(ERROR_MESSAGE() AS VARCHAR(4000)));
					SET @ErrorCount = @ErrorCount + 1;
				END CATCH;
			END
			ELSE
			BEGIN
				IF @InnerModifier = @PreviousModifier
					PRINT('    Repeated Modifier [' + ISNULL(@InnerModifier, 'NULL') + ']');
				ELSE IF LEN(@InnerModifier) <> 2
					PRINT('    LEN Modifier not equal to 2 [' + ISNULL(@InnerModifier, 'NULL') + ']');
				-- SET @ErrorCount = @ErrorCount + 1;
			END;
			
			SET @InnerCounter = @InnerCounter + 1;
		END;

		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchCptCode, @FetchCmid, @FetchModifiers, @FetchModDescriptions;		   
	END; -- end WHILE

	--------------------
	-- cleanup our cursor
	--------------------
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 

	DECLARE @resultCount INT = (SELECT COUNT([CHARGE_MASTER_MODIFIER_ID]) FROM [RevCycleDB].[dbo].[CHARGE_MASTER_MODIFIER] WITH (NOLOCK) WHERE [SERVICE_AGREEMENT_ID] = @TargetSAId)
	SELECT Result = @tempTableRowCount, Error = 'Total Rows = ' + CAST(@resultCount AS VARCHAR(20)) 
						+ ' :: Error count = ' + CAST(@ErrorCount AS VARCHAR(20))
						+ ' :: All Target CPT#,To Insert Target CPT# = ' + CAST(@tmpCountOne AS VARCHAR(20));

END -- end of stored procedure

GO
