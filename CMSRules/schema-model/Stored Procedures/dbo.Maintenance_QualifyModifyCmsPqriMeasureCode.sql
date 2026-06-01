SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_QualifyModifyCmsPqriMeasureCode]
     @CMS_PQRI_MEASURE_CODE_ID [int] = NULL
	,@CMS_PQRI_MEASURE_ID [int] = NULL
	,@CODING_SYSTEM [varchar](20) = NULL
	,@OPTION_GROUP [numeric](18, 0) = NULL
	,@CODE [varchar](20) = NULL
	,@MODIFIER [varchar](20) = NULL
	,@DESCRIPTION [varchar](500) = NULL
	,@PLACE_OF_SERVICE [varchar](20) = NULL
	,@END_DATE [date] = NULL
	,@CODE_2 [varchar](6) = NULL
	,@MODIFIER_2 [varchar](20) = NULL
	,@START_DATE [date] = NULL
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	-- if [CMS_PQRI_MEASURE_CODE_ID] is not null, we are just doing an update and leaving
	IF @CMS_PQRI_MEASURE_CODE_ID IS NOT NULL
	BEGIN
		PRINT('updating record with CMS_PQRI_MEASURE_CODE_ID: ' + CAST(@CMS_PQRI_MEASURE_CODE_ID AS VARCHAR(30)));
		DECLARE @countUpdate INT = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_CODE_ID] = @CMS_PQRI_MEASURE_CODE_ID);
		IF @countUpdate <= 0
		BEGIN
			SELECT 'ERROR' = '@CMS_PQRI_MEASURE_CODE_ID cannot be located for update.';
			RETURN;
		END;
		SET @countUpdate = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_CODE_ID] = @CMS_PQRI_MEASURE_CODE_ID);
		SELECT 'Result' = 'Updated record count for ID [' +  CAST(@CMS_PQRI_MEASURE_CODE_ID AS VARCHAR(30)) + '] = ' + CAST(@countUpdate AS VARCHAR(30))
		RETURN;
	END;
	-- find a record id to update where we find a complete match of all fields.  there should never be a 100% match of all fields for more than one record
	DECLARE @countFound INT = 
		(
			SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
			      [CMS_PQRI_MEASURE_ID] = @CMS_PQRI_MEASURE_ID
			  AND [CODING_SYSTEM] = @CODING_SYSTEM
			  AND [OPTION_GROUP] = @OPTION_GROUP
			  AND [CODE] = @CODE
			  AND [MODIFIER] = @MODIFIER
			  AND [DESCRIPTION] = @DESCRIPTION
			  AND [PLACE_OF_SERVICE] = @PLACE_OF_SERVICE
			  AND [END_DATE] = @END_DATE
			  AND [CODE_2] = @CODE_2
			  AND [MODIFIER_2] = @MODIFIER_2
			  AND [START_DATE] = @START_DATE
		);
	IF @countFound >= 1
	BEGIN
		SELECT 'ERROR' = 'Records found with a full field match test.  Assume no action required or manually adjust and reprocess.  Exiting.';
		RETURN;
	END;
	-- test for a logical compound index match (may not be defined for the table so do the hard way)
	SET @countFound = 
		(
			SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
			      [CMS_PQRI_MEASURE_ID] = @CMS_PQRI_MEASURE_ID
			  AND [CODING_SYSTEM] = @CODING_SYSTEM
			  --AND [OPTION_GROUP] = @OPTION_GROUP
			  AND [CODE] = @CODE
			  AND [MODIFIER] = @MODIFIER
			  --AND [DESCRIPTION] = @DESCRIPTION
			  --AND [PLACE_OF_SERVICE] = @PLACE_OF_SERVICE
			  AND (([END_DATE] IS NULL OR [END_DATE] >= CAST(GETDATE() AS DATE)) /* AND [END_DATE] = @END_DATE*/) -- just make sure we are looking at active records
			  AND [CODE_2] = @CODE_2
			  --AND [MODIFIER_2] = @MODIFIER_2 -- field not used
			  AND (([START_DATE] IS NULL OR CAST(GETDATE() AS DATE) >= [START_DATE]) /* AND [START_DATE] = @START_DATE*/) -- just make sure we are looking at active records
		);
	DECLARE @actionPerformed VARCHAR(100) = 'Update';
	IF @countFound > 1
	BEGIN 
		SELECT 'ERROR' = 'More than one record found for compound match check.  Manually adjust and reprocess.  Exiting.';
		RETURN;
	END
	ELSE IF @countFound <= 0
	BEGIN
		SET @actionPerformed = 'Insert';
		INSERT INTO [CMS_PQRI_MEASURE_CODE]
			([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[OPTION_GROUP],[CODE],[MODIFIER],[DESCRIPTION],[PLACE_OF_SERVICE],[END_DATE],[CODE_2],[MODIFIER_2],[START_DATE])
		VALUES
			(@CMS_PQRI_MEASURE_ID,@CODING_SYSTEM,@OPTION_GROUP,@CODE,@MODIFIER,@DESCRIPTION,@PLACE_OF_SERVICE,@END_DATE,@CODE_2,@MODIFIER_2,@START_DATE);
	END
	ELSE
	BEGIN 
		-- do an update
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET
			    [CMS_PQRI_MEASURE_ID] = @CMS_PQRI_MEASURE_ID
			  , [CODING_SYSTEM] = @CODING_SYSTEM
			  , [OPTION_GROUP] = @OPTION_GROUP
			  , [CODE] = @CODE
			  , [MODIFIER] = @MODIFIER
			  , [DESCRIPTION] = @DESCRIPTION
			  , [PLACE_OF_SERVICE] = @PLACE_OF_SERVICE
			  , [END_DATE] = @END_DATE
			  , [CODE_2] = @CODE_2
			  , [MODIFIER_2] = @MODIFIER_2
			  , [START_DATE] = @START_DATE
		WHERE
			  [CMS_PQRI_MEASURE_ID] = @CMS_PQRI_MEASURE_ID
		  AND [CODING_SYSTEM] = @CODING_SYSTEM
		  --AND [OPTION_GROUP] = @OPTION_GROUP
		  AND [CODE] = @CODE
		  AND [MODIFIER] = @MODIFIER
		  --AND [DESCRIPTION] = @DESCRIPTION
		  --AND [PLACE_OF_SERVICE] = @PLACE_OF_SERVICE
		  AND (([END_DATE] IS NULL OR [END_DATE] >= CAST(GETDATE() AS DATE)) /* AND [END_DATE] = @END_DATE*/) -- just make sure we are looking at active records
		  AND [CODE_2] = @CODE_2
		  --AND [MODIFIER_2] = @MODIFIER_2 -- field not used
		  AND (([START_DATE] IS NULL OR CAST(GETDATE() AS DATE) >= [START_DATE]) /* AND [START_DATE] = @START_DATE*/) -- just make sure we are looking at active records
		;
	END;
	DECLARE @foundId INT = 
		(
			SELECT [CMS_PQRI_MEASURE_CODE_ID] 
			FROM [CMS_PQRI_MEASURE_CODE]
			WHERE 
				  [CMS_PQRI_MEASURE_ID] = @CMS_PQRI_MEASURE_ID
			  AND [CODING_SYSTEM] = @CODING_SYSTEM
			  AND [OPTION_GROUP] = @OPTION_GROUP
			  AND [CODE] = @CODE
			  AND [MODIFIER] = @MODIFIER
			  AND [DESCRIPTION] = @DESCRIPTION
			  AND [PLACE_OF_SERVICE] = @PLACE_OF_SERVICE
			  AND [END_DATE] = @END_DATE
			  AND [CODE_2] = @CODE_2
			  AND [MODIFIER_2] = @MODIFIER_2
			  AND [START_DATE] = @START_DATE
		);
	SET @countFound = 
		(
			SELECT COUNT(*) FROM [CMS_PQRI_MEASURE_CODE]
			WHERE
			      [CMS_PQRI_MEASURE_ID] = @CMS_PQRI_MEASURE_ID
			  AND [CODING_SYSTEM] = @CODING_SYSTEM
			  AND [OPTION_GROUP] = @OPTION_GROUP
			  AND [CODE] = @CODE
			  AND [MODIFIER] = @MODIFIER
			  AND [DESCRIPTION] = @DESCRIPTION
			  AND [PLACE_OF_SERVICE] = @PLACE_OF_SERVICE
			  AND [END_DATE] = @END_DATE
			  AND [CODE_2] = @CODE_2
			  AND [MODIFIER_2] = @MODIFIER_2
			  AND [START_DATE] = @START_DATE
		);
	SELECT 'Result' = @actionPerformed + ' record count for ID [' +  CAST(@foundId AS VARCHAR(30)) + '] = ' + CAST(@countFound AS VARCHAR(30))
END
GO
