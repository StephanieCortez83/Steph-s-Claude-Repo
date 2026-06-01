USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of Infinity4.2Scripts.sql

SET XACT_ABORT ON;

-- Start of Infinity4.2Scripts.sql

-- End of Infinity4.2Scripts.sql
GO

-- Start of 01) DACS-3020 - Alter Procedure - [dbo].[Maintenance_SelectIndexesForTablesbyTableName].SQL

----------------------------------------------------------------------------------------
-- 01) DACS-3020 - Alter Procedure - [dbo].[Maintenance_SelectIndexesForTablesbyTableName].SQL
----------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROC [dbo].[Maintenance_SelectIndexesForTablesbyTableName]  
	 @TableName VARCHAR(1024)
AS  
	-- Original implementation bt Mr. D. Sexton
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @TableName IS NULL OR LEN(@TableName) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'Error: TableName is invalid.';
		RETURN;
	END;

	PRINT('TableName = ' + @TableName);

	SELECT 
		  TABLENAME = T.NAME
		, INDEXNAME = I.NAME
		, COLUMNNAME = C.NAME
		, IC.KEY_ORDINAL
		, IC.IS_INCLUDED_COLUMN
		, IC.INDEX_COLUMN_ID
	FROM
		SYS.INDEXES AS I
		INNER JOIN SYS.INDEX_COLUMNS AS IC
			ON I.OBJECT_ID = IC.OBJECT_ID
			AND I.INDEX_ID = IC.INDEX_ID
		INNER JOIN SYS.COLUMNS AS C
			ON IC.OBJECT_ID = C.OBJECT_ID
			AND IC.COLUMN_ID = C.COLUMN_ID
		INNER JOIN SYS.TABLES AS T
			ON T.OBJECT_ID = C.OBJECT_ID
	WHERE 
		T.NAME = @TableName
	ORDER BY 
		INDEXNAME
		, CASE WHEN KEY_ORDINAL > 0 THEN KEY_ORDINAL ELSE 99 END

GO


/*
test:
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = 'Chart_Access'
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = 'FACILITY'
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = 'SERVICE_AGREEMENT'
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = 'CHARGE_MASTER'
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = ''
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = NULL
*/


-- End of 01) DACS-3020 - Alter Procedure - [dbo].[Maintenance_SelectIndexesForTablesbyTableName].SQL
GO

-- Start of 02) DACS-3020 - SQL Create alter procedure - Maintenance_CompareDataRecordsByTableAndIdFields.SQL

----------------------------------------
-- 02) DACS-3020 - SQL Create alter procedure - Maintenance_CompareDataRecordsByTableAndIdFields.SQL
----------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_CompareDataRecordsByTableAndIdFields]
	 @TableName VARCHAR(256)
	,@IdColumnName VARCHAR(256)
	,@IdComp1 INT
	,@IdComp2 INT
	,@TestMode BIT = 0
	,@ShowDifferencesOnly BIT = 1
AS
BEGIN

	PRINT('  ------------------------');
	PRINT('@tableName = ' + @tableName);
	PRINT('@IdColumnName = ' + @IdColumnName);
	PRINT('@IdComp1 = ' + CAST(@IdComp1 AS VARCHAR(30)));
	PRINT('@IdComp2 = ' + CAST(@IdComp2 AS VARCHAR(30)));
	PRINT('  ------------------------');
	PRINT(' ');

	IF @testMode <> 0
		SELECT * from service_agreement where SERVICE_AGREEMENT_id IN (@IdComp1,@IdComp2)

	DECLARE @tempColumnCompare TABLE 
		( 
			 ColumnName VARCHAR(256)
			,Value1 VARCHAR(MAX) NULL
			,Value2 VARCHAR(MAX) NULL
			,Matching INT NULL
		);

	INSERT @tempColumnCompare(ColumnName)
		SELECT [COLUMN_NAME] 
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = @tableName
		
	IF @testMode <> 0
		SELECT * FROM @tempColumnCompare ORDER BY ColumnName

	DECLARE @columnCount INT = (SELECT COUNT(*) FROM @tempColumnCompare);
	IF @testMode <> 0
		SELECT '@columnCount =' = @columnCount;

	-- populate our column data:
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = @columnCount;

	DECLARE @FetchColumnName VARCHAR(256);
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [ColumnName] FROM @tempColumnCompare;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchColumnName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): ' + IIF(@FetchColumnName IS NULL, 'NULL', CAST(@FetchColumnName AS VARCHAR(256)))
			);

		DECLARE @SQL1 NVARCHAR(MAX) = N'SELECT @retvalOUT = CAST(' + CAST(@FetchColumnName AS NVARCHAR(256)) + N' AS VARCHAR(MAX)) FROM ' + CAST(@tableName AS NVARCHAR(256)) + N' WHERE ' + CAST(@IdColumnName AS NVARCHAR(512)) + ' = ' + CAST(@IdComp1 AS NVARCHAR(200)) + N';';
		DECLARE @SQL2 NVARCHAR(MAX) = N'SELECT @retvalOUT = CAST(' + CAST(@FetchColumnName AS NVARCHAR(256)) + N' AS VARCHAR(MAX)) FROM ' + CAST(@tableName AS NVARCHAR(256)) + N' WHERE ' + CAST(@IdColumnName AS NVARCHAR(512)) + ' = ' + CAST(@IdComp2 AS NVARCHAR(200)) + N';';

		DECLARE @retVal1 VARCHAR(MAX)   
		DECLARE @retVal2 VARCHAR(MAX)   

		DECLARE @ParmDefinition nvarchar(MAX) = N'@retvalOUT VARCHAR(MAX) OUTPUT';

		EXEC sp_executesql @SQL1, @ParmDefinition, @retvalOUT=@retVal1 OUTPUT;
		EXEC sp_executesql @SQL2, @ParmDefinition, @retvalOUT=@retVal2 OUTPUT;

		IF @testMode <> 0
		BEGIN
			PRINT(CAST(@ProcessCount AS VARCHAR(20)) + '  --> @SQL1 = ' + @SQL1) ;
			PRINT(CAST(@ProcessCount AS VARCHAR(20)) + '  ----> @retVal1 = ' + @retVal1) ;

			PRINT(CAST(@ProcessCount AS VARCHAR(20)) + '  --> @SQL2 = ' + @SQL2) ;
			PRINT(CAST(@ProcessCount AS VARCHAR(20)) + '  ----> @retVal2 = ' + @retVal2) ;
		END


		UPDATE @tempColumnCompare
			SET 
			  [Value1] = @retVal1
			, [Value2] = @retVal2
			, [Matching] =	CASE WHEN (@retVal1 < @retVal2) OR (@retVal1 IS NULL AND @retVal2 IS NOT NULL) THEN -1 
								 WHEN (@retVal1 = @retVal2) OR (@retVal1 IS NULL AND @retVal2 IS NULL) THEN 0
								 WHEN (@retVal1 > @retVal2) OR (@retVal1 IS NOT NULL AND @retVal2 IS NULL)THEN 1
							END 
		WHERE 
			ColumnName = @FetchColumnName;

		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchColumnName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 

	IF @testMode <> 0
		SELECT * FROM @tempColumnCompare ORDER BY ColumnName;

	DECLARE @matchingCount INT = (SELECT COUNT(*) FROM @tempColumnCompare WHERE [Matching] = 0)

	INSERT INTO @tempColumnCompare (ColumnName,Value1,Value2,Matching) 
		VALUES ('[' + @tableName + '] Table: (' + @IdColumnName +  ') From->To',@IdComp1,@IdComp2,@matchingCount);

	IF @showDifferencesOnly = 0
		SELECT * FROM @tempColumnCompare ORDER BY ColumnName;
	ELSE
		SELECT * FROM @tempColumnCompare WHERE [Matching] <> 0 ORDER BY ColumnName;


END -- end of stored procedure
GO

/*
testing
exec [dbo].[Maintenance_CompareDataRecordsByTableAndIdFields]
	 @TableName = 'SERVICE_AGREEMENT'
	,@IdColumnName = 'SERVICE_AGREEMENT_ID'
	,@IdComp1 = 88
	,@IdComp2 = 93

exec [dbo].[Maintenance_CompareDataRecordsByTableAndIdFields]
	 @TableName = 'CHART'
	,@IdColumnName = 'CHART_ID'
	,@IdComp1 = 2086061
	,@IdComp2 = 2164620
*/
-- End of 02) DACS-3020 - SQL Create alter procedure - Maintenance_CompareDataRecordsByTableAndIdFields.SQL
GO

-- Start of 03) DACS-3020 - SQL Create alter procedure - Maintenance_ExpireChargeMasterByComplexFiltering.SQL

----------------------------------------
-- 03) DACS-3020 - SQL Create alter procedure - Maintenance_ExpireChargeMasterByComplexFiltering.SQL
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
      @SAId INT
	, @ExpireDate DATETIME = NULL
    , @ChargeMasterId INT = NULL
	, @CptCode VARCHAR(5) = NULL
    , @BillingCode VARCHAR(20) = NULL
    , @Description VARCHAR(100) = NULL
    , @CategoryId INT = NULL
    , @DepartmentId INT = NULL
    , @UsageCodeId INT = NULL
    , @PatientClassId INT = NULL
	, @TestMode BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @ExpireDate IS NULL
	BEGIN
		SET @ExpireDate = GETDATE();
	END;
	
	-- fill our temp table with all the CM Ids for the service agreement and prune that based on filtering
	DECLARE @tempCMIds TABLE 
	( 
		  CMId INT
		, SAId INT
		, ExpireDate DATETIME
		, CptCode VARCHAR(5)
		, BillingCode VARCHAR(20)
		, Description VARCHAR(100)
		, CategoryId INT
		, DepartmentId INT
		, UsageCodeId INT
		, PatientClassId INT
	);

	INSERT @tempCMIds(CMId,SAId,ExpireDate,CptCode,BillingCode,Description,CategoryId,DepartmentId,UsageCodeId,PatientClassId)
		SELECT 
			  CHARGE_MASTER_ID
			, SERVICE_AGREEMENT_ID
			, EXPIRATION_DATE
			, CPT_CODE
			, BILLING_CODE
			, [DESCRIPTION]
			, CHARGE_MASTER_CATEGORY_ID
			, CHARGE_MASTER_DEPT_ID
			, CHARGE_MASTER_USAGE_CODE
			, PATIENT_CLASS_ID
		FROM 
			[dbo].[CHARGE_MASTER]
		WHERE 
			SERVICE_AGREEMENT_ID = @SAId
			AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate)
	
	DECLARE @countCM INT = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('@SAId = ' + CAST(@SAId AS varchar(20)));
	PRINT('@ExpireDate = ' + CAST(@ExpireDate AS varchar(40)));
	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @msg VARCHAR(2000);  

	IF @countCM <= 0
	BEGIN
		SET @msg = '0 :: No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) + ', @ExpireDate = ' + CAST(@ExpireDate AS varchar(40));
		PRINT(@msg);
		SELECT 'Results' = @msg;
		RETURN;
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;
	
	DECLARE @ProcessingFields VARCHAR(1000) = '@SAId = ' + CAST(@SAId AS varchar(20)) + ', @ExpireDate = ' + CAST(@ExpireDate AS varchar(40));
	
	IF @ChargeMasterId IS NOT NULL AND @ChargeMasterId > 0
	BEGIN
		SET @ProcessingFields = (@ProcessingFields + ', ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(30))) 
		DELETE FROM @tempCMIds WHERE CMId <> @ChargeMasterId;
	END
	ELSE
	BEGIN
		IF @CptCode IS NOT NULL AND LEN(@CptCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CptCode = ' + @CptCode + '%') 
			-- DELETE FROM @tempCMIds WHERE CptCode <> @CptCode;
			DELETE FROM @tempCMIds WHERE CptCode NOT LIKE (@CptCode + '%');
		END;
	
		IF @BillingCode IS NOT NULL AND LEN(@BillingCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', BillingCode = ' + @BillingCode) 
			-- DELETE FROM @tempCMIds WHERE BillingCode <> @BillingCode;
			DELETE FROM @tempCMIds WHERE BillingCode NOT LIKE (@BillingCode + '%');
		END;
	
		IF @Description IS NOT NULL AND LEN(@Description) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', Description = %' + @Description + '%') 
			-- DELETE FROM @tempCMIds WHERE [Description] <> @Description;
			DELETE FROM @tempCMIds WHERE [Description] NOT LIKE ('%' + @Description + '%');
		END;

		IF @CategoryId IS NOT NULL AND @CategoryId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CategoryId = ' + CAST(@CategoryId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE CategoryId <> @CategoryId;
		END

		IF @DepartmentId IS NOT NULL AND @DepartmentId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', DepartmentId = ' + CAST(@DepartmentId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE DepartmentId <> @DepartmentId;
		END

		IF @UsageCodeId IS NOT NULL AND @UsageCodeId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', UsageCodeId = ' + CAST(@UsageCodeId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE UsageCodeId <> @UsageCodeId;
		END

		IF @PatientClassId IS NOT NULL AND @PatientClassId > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', PatientClassId = ' + CAST(@PatientClassId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE PatientClassId <> @PatientClassId;
		END
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;

	SET @countCM = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('Processing Filters = ' + @ProcessingFields);
	PRINT('Processing @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @tempResults TABLE ( Value VARCHAR(2000) );

	INSERT @tempResults(Value)
		SELECT  
			'CM: ' + CAST(CMId AS VARCHAR(30)) + ', ' +
			CptCode + ', ' +
			BillingCode + ', ' +
			Description AS [Value]
		FROM 
			@tempCMIds
			
	IF @TestMode = 1
	BEGIN
		PRINT('------------------------------------------');
		PRINT('       TESTMODE - EXITING WITHOUT PROCESSING');
		PRINT('------------------------------------------');
		SET @msg = '0 :: TEST MODE EXIT.  No Charge Master Records to process.  # would have processed: ' + CAST(@countCM AS varchar(40)) + ' :: filters = ' + @ProcessingFields;
		PRINT(@msg);
		INSERT INTO @tempResults (Value) VALUES (@msg);
		SELECT TOP 2000 * FROM @tempResults;
		RETURN;
	END;
	
	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		UPDATE CHARGE_MASTER 
			SET EXPIRATION_DATE = @ExpireDate
		WHERE SERVICE_AGREEMENT_ID = @SAId 
			AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate) 
			AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds);
		
		SET @countCM = 
			(
				SELECT COUNT(*) 
				FROM CHARGE_MASTER 
				WHERE SERVICE_AGREEMENT_ID = @SAId 
					AND EXPIRATION_DATE = @ExpireDate 
					AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds));
					
		PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	SET @msg = CAST(@countCM AS VARCHAR(30)) + ' :: Filters = ' + @ProcessingFields;
	--SELECT 'Results' = @msg;
	INSERT INTO @tempResults (Value) VALUES (@msg);
	SELECT TOP 2000 * FROM @tempResults;
END

GO

/*
Testing:
begin tran;
exec [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
      @SAId = 440
	, @ExpireDate = '04-01-2024'
	, @TestMode = 1
    --, @ChargeMasterId = 12345
	, @CptCode = 'A4223'
    --, @BillingCode = '1234567'
    , @Description = 'IV TUBING PRIMARY'
    , @CategoryId = 25460
    , @DepartmentId = 2509
    --, @UsageCodeId = 1
    , @PatientClassId = -1
	

exec [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
                          @SAId = 597
	                    , @ExpireDate = '12/12/2024'
                        , @ChargeMasterId = NULL
	                    , @CptCode = ''
                        , @BillingCode = ''
                        , @Description = 'eye'
                        , @CategoryId = NULL
                        , @DepartmentId = NULL
                        , @UsageCodeId = NULL
                        , @PatientClassId = NULL
                        , @TestMode = 1
                        ;
*/
-- End of 03) DACS-3020 - SQL Create alter procedure - Maintenance_ExpireChargeMasterByComplexFiltering.SQL
GO

-- Start of 04) DACS-3020 - SQL Create alter procedure - Maintenance_SelectChartsUsingProcedureCodes.SQL

----------------------------------------
-- 04) DACS-3020 - SQL Create alter procedure - Maintenance_SelectChartsUsingProcedureCodes.SQL
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_SelectChartsUsingProcedureCodes]
	 @SAIdList VARCHAR(1000)			-- i.e. 440,1029,333, ....
	,@ProcedureCodeList VARCHAR(2000)	-- i.e. 99999,99292,0010A, ....
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- copy string lists to temp tables
	DECLARE @tempSAIds TABLE	( SAID INT );
	INSERT @tempSAIds(SAID)
		SELECT 
			CAST(RTRIM(LTRIM(value)) AS INT) AS SAID
		FROM STRING_SPLIT (@SAIdList, ',')

	DECLARE @tempProcedureCodes TABLE	( PCCD VARCHAR(5) );
	INSERT @tempProcedureCodes(PCCD)
		SELECT 
			CAST(RTRIM(LTRIM(value)) AS VARCHAR(5)) AS PCCD
		FROM STRING_SPLIT (@ProcedureCodeList, ',')

	-- select * from @tempSAIds; -- testing
	-- select * from @tempProcedureCodes; -- testing

	SELECT top 1000 
		 cm.CPT_CODE
		,coer.CHART_ID
		FROM CHART_OBSERVATION_ENCOUNTER_RESULT coer
		inner join CHARGE_MASTER cm ON cm.charge_master_id = coer.charge_master_id
		inner join SERVICE_AGREEMENT sa ON sa.service_agreement_id = cm.service_agreement_id
		WHERE
		(sa.[EXPIRATION_DATE] IS NULL OR sa.[EXPIRATION_DATE] >= GETDATE())
		AND 
		cm.SERVICE_AGREEMENT_ID IN (SELECT DISTINCT SAID FROM @tempSAIds)
		AND 
		cm.CPT_CODE IN (SELECT DISTINCT PCCD FROM @tempProcedureCodes)
	
	
END -- end of stored procedure
GO	

/*
testing:
exec [dbo].[Maintenance_SelectChartsUsingProcedureCodes]
	 @SAIdList = '597,1029,333'
	,@ProcedureCodeList = '99284,36415,93005,85025,80053,J3490'
*/
-- End of 04) DACS-3020 - SQL Create alter procedure - Maintenance_SelectChartsUsingProcedureCodes.SQL
GO

-- Start of 05) DACS-3020 - SQL Create alter procedure - Maintenance_DeleteChargeMasterByComplexFiltering.SQL

----------------------------------------
-- 05) DACS-3020 - SQL Create alter procedure - Maintenance_DeleteChargeMasterByComplexFiltering.SQL
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_DeleteChargeMasterByComplexFiltering]
      @SAId INT
    , @ChargeMasterId INT = NULL
	, @CptCode VARCHAR(5) = NULL
    , @BillingCode VARCHAR(20) = NULL
    , @Description VARCHAR(100) = NULL
    , @CategoryId INT = NULL
    , @DepartmentId INT = NULL
    , @UsageCodeId INT = NULL
    , @PatientClassId INT = NULL
	, @TestMode BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	-- fill our temp table with all the CM Ids for the service agreement and prune that based on filtering
	DECLARE @tempCMIds TABLE 
	( 
		  CMId INT
		, SAId INT
		, CptCode VARCHAR(5)
		, BillingCode VARCHAR(20)
		, Description VARCHAR(100)
		, CategoryId INT
		, DepartmentId INT
		, UsageCodeId INT
		, PatientClassId INT
	);

	INSERT @tempCMIds(CMId,SAId,CptCode,BillingCode,Description,CategoryId,DepartmentId,UsageCodeId,PatientClassId)
		SELECT 
			  CHARGE_MASTER_ID
			, SERVICE_AGREEMENT_ID
			, CPT_CODE
			, BILLING_CODE
			, [DESCRIPTION]
			, CHARGE_MASTER_CATEGORY_ID
			, CHARGE_MASTER_DEPT_ID
			, CHARGE_MASTER_USAGE_CODE
			, PATIENT_CLASS_ID
		FROM 
			[dbo].[CHARGE_MASTER]
		WHERE 
			SERVICE_AGREEMENT_ID = @SAId
	
	DECLARE @countCM INT = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('@SAId = ' + CAST(@SAId AS varchar(20)));
	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @msg VARCHAR(2000);  

	IF @countCM <= 0
	BEGIN
		SET @msg = '0 :: No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20));
		PRINT(@msg);
		SELECT 'Results' = @msg;
		RETURN;
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;
	
	DECLARE @ProcessingFields VARCHAR(1000) = '@SAId = ' + CAST(@SAId AS varchar(20));
	
	IF @ChargeMasterId IS NOT NULL AND @ChargeMasterId > 0
	BEGIN
		SET @ProcessingFields = (@ProcessingFields + ', ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(30))) 
		DELETE FROM @tempCMIds WHERE CMId <> @ChargeMasterId;
	END
	ELSE
	BEGIN
		IF @CptCode IS NOT NULL AND LEN(@CptCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CptCode = ' + @CptCode + '%') 
			-- DELETE FROM @tempCMIds WHERE CptCode <> @CptCode;
			DELETE FROM @tempCMIds WHERE CptCode NOT LIKE (@CptCode + '%');
		END;
	
		IF @BillingCode IS NOT NULL AND LEN(@BillingCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', BillingCode = ' + @BillingCode) 
			-- DELETE FROM @tempCMIds WHERE BillingCode <> @BillingCode;
			DELETE FROM @tempCMIds WHERE BillingCode NOT LIKE (@BillingCode + '%');
		END;
	
		IF @Description IS NOT NULL AND LEN(@Description) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', Description = %' + @Description + '%') 
			-- DELETE FROM @tempCMIds WHERE [Description] <> @Description;
			DELETE FROM @tempCMIds WHERE [Description] NOT LIKE ('%' + @Description + '%');
		END;

		IF @CategoryId IS NOT NULL AND @CategoryId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CategoryId = ' + CAST(@CategoryId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE CategoryId <> @CategoryId;
		END

		IF @DepartmentId IS NOT NULL AND @DepartmentId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', DepartmentId = ' + CAST(@DepartmentId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE DepartmentId <> @DepartmentId;
		END

		IF @UsageCodeId IS NOT NULL AND @UsageCodeId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', UsageCodeId = ' + CAST(@UsageCodeId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE UsageCodeId <> @UsageCodeId;
		END

		IF @PatientClassId IS NOT NULL AND @PatientClassId > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', PatientClassId = ' + CAST(@PatientClassId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE PatientClassId <> @PatientClassId;
		END
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;

	SET @countCM = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('Processing Filters = ' + @ProcessingFields);
	PRINT('Processing @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @tempResults TABLE ( Value VARCHAR(2000) );

	INSERT @tempResults(Value)
		SELECT  
			'CM: ' + CAST(CMId AS VARCHAR(30)) + ', ' +
			CptCode + ', ' +
			BillingCode + ', ' +
			Description AS [Value]
		FROM 
			@tempCMIds
			
	IF @TestMode = 1
	BEGIN
		PRINT('------------------------------------------');
		PRINT('       TESTMODE - EXITING WITHOUT PROCESSING');
		PRINT('------------------------------------------');
		SET @msg = '0 :: TEST MODE EXIT.  No Charge Master Records to process.  # would have processed: ' + CAST(@countCM AS varchar(40)) + ' :: filters = ' + @ProcessingFields;
		PRINT(@msg);
		INSERT INTO @tempResults (Value) VALUES (@msg);
		SELECT TOP 2000 * FROM @tempResults;
		RETURN;
	END;
	
	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		DELETE FROM CHARGE_MASTER
		WHERE SERVICE_AGREEMENT_ID = @SAId 
			AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds);
		
		SET @countCM = 
			(
				SELECT COUNT(*) 
				FROM CHARGE_MASTER 
				WHERE SERVICE_AGREEMENT_ID = @SAId 
					AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds)
			);
					
		PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	SET @msg = CAST(@countCM AS VARCHAR(30)) + ' :: Filters = ' + @ProcessingFields;
	--SELECT 'Results' = @msg;
	INSERT INTO @tempResults (Value) VALUES (@msg);
	SELECT TOP 2000 * FROM @tempResults;
END

GO

/*
Testing:
begin tran;
exec [dbo].[Maintenance_DeleteChargeMasterByComplexFiltering]
      @SAId = 440
	, @TestMode = 1
    --, @ChargeMasterId = 12345
	, @CptCode = 'A4223'
    --, @BillingCode = '1234567'
    , @Description = 'IV TUBING PRIMARY'
    , @CategoryId = 25460
    , @DepartmentId = 2509
    --, @UsageCodeId = 1
    , @PatientClassId = -1
	

exec [dbo].[Maintenance_DeleteChargeMasterByComplexFiltering]
                          @SAId = 597
                        , @ChargeMasterId = NULL
	                    , @CptCode = ''
                        , @BillingCode = ''
                        , @Description = 'eye'
                        , @CategoryId = NULL
                        , @DepartmentId = NULL
                        , @UsageCodeId = NULL
                        , @PatientClassId = NULL
                        , @TestMode = 1
                        ;
*/
-- End of 05) DACS-3020 - SQL Create alter procedure - Maintenance_DeleteChargeMasterByComplexFiltering.SQL
GO

-- Start of 01) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsCountForCoder.SQL

-----------------------------------------------------------------------------------
-- 01) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsCountForCoder.SQL
-----------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFromChartTotalChartsCountForCoder]
      @UserProfileId INT
	, @FromDate DATE
	, @ToDate DATE
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @UserProfileId IS NULL OR @UserProfileId <= 0
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @FromDate IS NULL
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @ToDate IS NULL
	BEGIN
		SET @ToDate = GETDATE();
		RETURN;
	END;

	-- these could be handled differently but are as is due to reverse compatibility with the original inline C# programming.
	DECLARE @testFromDate DATETIME = (CAST(@FromDate AS DATETIME));
	DECLARE @testToDate DATETIME = (CAST(@ToDate AS DATETIME));

	SELECT COUNT(*) 
		FROM CHART WITH (NOLOCK) 
		WHERE CHART_STATUS_ID in (4,5) 
		AND COMPLETED_BY_USER_PROFILE_ID = @UserProfileId
		AND APPROVED_DATE BETWEEN @testFromDate AND @testToDate;

END -- end of procedure
GO
-- End of 01) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsCountForCoder.SQL
GO

-- Start of 02) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsReviewedCountForCoder.SQL

-----------------------------------------------------------------------------------
-- 02) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsReviewedCountForCoder.SQL
-----------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFromChartTotalChartsReviewedCountForCoder]
      @UserProfileId INT
	, @FromDate DATE
	, @ToDate DATE
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @UserProfileId IS NULL OR @UserProfileId <= 0
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @FromDate IS NULL
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @ToDate IS NULL
	BEGIN
		SET @ToDate = GETDATE();
		RETURN;
	END;

	-- these could be handled differently but are as is due to reverse compatibility with the original inline C# programming.
	DECLARE @testFromDate DATETIME = (CAST(@FromDate AS DATETIME));
	DECLARE @testToDate DATETIME = (CAST(@ToDate AS DATETIME));

	SELECT COUNT(*) 
		FROM CHART WITH (NOLOCK) 
		WHERE CHART_STATUS_ID in (4,5) 
		AND COMPLETED_BY_USER_PROFILE_ID = @UserProfileId
		AND APPROVED_DATE BETWEEN @testFromDate AND @testToDate
		AND APPROVED_BY_USER_PROFILE_ID <> 2 
		AND APPROVAL_REASON_CODE = 3;
		
END -- end of procedure
GO
-- End of 02) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsReviewedCountForCoder.SQL
GO

-- Start of 03) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsApprovedCountForFirstAuditor.SQL

-----------------------------------------------------------------------------------
-- 03) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsApprovedCountForFirstAuditor.SQL
-----------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFromChartTotalChartsApprovedCountForFirstAuditor]
      @UserProfileId INT
	, @FromDate DATE
	, @ToDate DATE
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @UserProfileId IS NULL OR @UserProfileId <= 0
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @FromDate IS NULL
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @ToDate IS NULL
	BEGIN
		SET @ToDate = GETDATE();
		RETURN;
	END;

	-- these could be handled differently but are as is due to reverse compatibility with the original inline C# programming.
	DECLARE @testFromDate DATETIME = (CAST(@FromDate AS DATETIME));
	DECLARE @testToDate DATETIME = (CAST(@ToDate AS DATETIME));

	SELECT COUNT(*) 
		FROM CHART WITH (NOLOCK) 
		WHERE CHART_STATUS_ID in (4,5) 
		AND APPROVED_BY_USER_PROFILE_ID = @UserProfileId
		AND APPROVED_DATE BETWEEN @testFromDate AND @testToDate;
		
END -- end of procedure
GO
-- End of 03) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsApprovedCountForFirstAuditor.SQL
GO

-- Start of 04) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsReviewedCountForFirstAuditor.SQL

-----------------------------------------------------------------------------------
-- 04) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsReviewedCountForFirstAuditor.SQL
-----------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFromChartTotalChartsReviewedCountForFirstAuditor]
      @UserProfileId INT
	, @FromDate DATE
	, @ToDate DATE
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @UserProfileId IS NULL OR @UserProfileId <= 0
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @FromDate IS NULL
	BEGIN
		SELECT 'ERROR' = 0;
		RETURN;
	END;

	IF @ToDate IS NULL
	BEGIN
		SET @ToDate = GETDATE();
		RETURN;
	END;

	-- these could be handled differently but are as is due to reverse compatibility with the original inline C# programming.
	DECLARE @testFromDate DATETIME = (CAST(@FromDate AS DATETIME));
	DECLARE @testToDate DATETIME = (CAST(@ToDate AS DATETIME));

	SELECT COUNT(*) 
		FROM CHART WITH (NOLOCK) 
		WHERE CHART_STATUS_ID in (4,5) 
		AND APPROVED_BY_USER_PROFILE_ID = @UserProfileId
		AND (SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID > 2 AND SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> @UserProfileId)
		AND START_SECOND_LEVEL_QA_USER_PROFILE_ID > 0
		AND SECOND_LEVEL_QA_APPROVED_DATETIME BETWEEN @testFromDate AND @testToDate;

END -- end of procedure
GO
-- End of 04) DACS-3034 - Create Or Alter Procedure - SelectFromChartTotalChartsReviewedCountForFirstAuditor.SQL
GO

-- Start of 01) DACS-3020 - Alter Procedure - [dbo].[Maintenance_SelectIndexesForTablesbyTableName].SQL

----------------------------------------------------------------------------------------
-- 01) DACS-3020 - Alter Procedure - [dbo].[Maintenance_SelectIndexesForTablesbyTableName].SQL
----------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROC [dbo].[Maintenance_SelectIndexesForTablesbyTableName]  
	 @TableName VARCHAR(1024)
AS  
	-- Original implementation bt Mr. D. Sexton
	
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @TableName IS NULL OR LEN(@TableName) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'Error: TableName is invalid.';
		RETURN;
	END;

	PRINT('TableName = ' + @TableName);

	SELECT 
		  TABLENAME = T.NAME
		, INDEXNAME = I.NAME
		, COLUMNNAME = C.NAME
		, IC.KEY_ORDINAL
		, IC.IS_INCLUDED_COLUMN
		, IC.INDEX_COLUMN_ID
	FROM
		SYS.INDEXES AS I
		INNER JOIN SYS.INDEX_COLUMNS AS IC
			ON I.OBJECT_ID = IC.OBJECT_ID
			AND I.INDEX_ID = IC.INDEX_ID
		INNER JOIN SYS.COLUMNS AS C
			ON IC.OBJECT_ID = C.OBJECT_ID
			AND IC.COLUMN_ID = C.COLUMN_ID
		INNER JOIN SYS.TABLES AS T
			ON T.OBJECT_ID = C.OBJECT_ID
	WHERE 
		T.NAME = @TableName
	ORDER BY 
		INDEXNAME
		, CASE WHEN KEY_ORDINAL > 0 THEN KEY_ORDINAL ELSE 99 END

GO


/*
test:
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = 'Chart_Access'
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = 'FACILITY'
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = 'SERVICE_AGREEMENT'
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = 'CHARGE_MASTER'
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = ''
	exec [dbo].[Maintenance_SelectIndexesForTablesbyTableName] @TableName = NULL
*/


-- End of 01) DACS-3020 - Alter Procedure - [dbo].[Maintenance_SelectIndexesForTablesbyTableName].SQL
GO

-- Start of 02) DACS-3020 - SQL Create alter procedure - Maintenance_CompareDataRecordsByTableAndIdFields.SQL

----------------------------------------
-- 02) DACS-3020 - SQL Create alter procedure - Maintenance_CompareDataRecordsByTableAndIdFields.SQL
----------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_CompareDataRecordsByTableAndIdFields]
	 @TableName VARCHAR(256)
	,@IdColumnName VARCHAR(256)
	,@IdComp1 INT
	,@IdComp2 INT
	,@TestMode BIT = 0
	,@ShowDifferencesOnly BIT = 1
AS
BEGIN

	PRINT('  ------------------------');
	PRINT('@tableName = ' + @tableName);
	PRINT('@IdColumnName = ' + @IdColumnName);
	PRINT('@IdComp1 = ' + CAST(@IdComp1 AS VARCHAR(30)));
	PRINT('@IdComp2 = ' + CAST(@IdComp2 AS VARCHAR(30)));
	PRINT('  ------------------------');
	PRINT(' ');

	IF @testMode <> 0
		SELECT * from service_agreement where SERVICE_AGREEMENT_id IN (@IdComp1,@IdComp2)

	DECLARE @tempColumnCompare TABLE 
		( 
			 ColumnName VARCHAR(256)
			,Value1 VARCHAR(MAX) NULL
			,Value2 VARCHAR(MAX) NULL
			,Matching INT NULL
		);

	INSERT @tempColumnCompare(ColumnName)
		SELECT [COLUMN_NAME] 
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = @tableName
		
	IF @testMode <> 0
		SELECT * FROM @tempColumnCompare ORDER BY ColumnName

	DECLARE @columnCount INT = (SELECT COUNT(*) FROM @tempColumnCompare);
	IF @testMode <> 0
		SELECT '@columnCount =' = @columnCount;

	-- populate our column data:
	DECLARE @ProcessCount INT = 1;
	DECLARE @TotalToProcessCount INT = @columnCount;

	DECLARE @FetchColumnName VARCHAR(256);
	DECLARE cursorTempRows CURSOR LOCAL FOR SELECT [ColumnName] FROM @tempColumnCompare;  

	OPEN cursorTempRows;
	FETCH NEXT FROM cursorTempRows INTO @FetchColumnName;
				
	PRINT('------------------- processing loop --------------------');		
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		PRINT(
			'Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
			+ ' ): ' + IIF(@FetchColumnName IS NULL, 'NULL', CAST(@FetchColumnName AS VARCHAR(256)))
			);

		DECLARE @SQL1 NVARCHAR(MAX) = N'SELECT @retvalOUT = CAST(' + CAST(@FetchColumnName AS NVARCHAR(256)) + N' AS VARCHAR(MAX)) FROM ' + CAST(@tableName AS NVARCHAR(256)) + N' WHERE ' + CAST(@IdColumnName AS NVARCHAR(512)) + ' = ' + CAST(@IdComp1 AS NVARCHAR(200)) + N';';
		DECLARE @SQL2 NVARCHAR(MAX) = N'SELECT @retvalOUT = CAST(' + CAST(@FetchColumnName AS NVARCHAR(256)) + N' AS VARCHAR(MAX)) FROM ' + CAST(@tableName AS NVARCHAR(256)) + N' WHERE ' + CAST(@IdColumnName AS NVARCHAR(512)) + ' = ' + CAST(@IdComp2 AS NVARCHAR(200)) + N';';

		DECLARE @retVal1 VARCHAR(MAX)   
		DECLARE @retVal2 VARCHAR(MAX)   

		DECLARE @ParmDefinition nvarchar(MAX) = N'@retvalOUT VARCHAR(MAX) OUTPUT';

		EXEC sp_executesql @SQL1, @ParmDefinition, @retvalOUT=@retVal1 OUTPUT;
		EXEC sp_executesql @SQL2, @ParmDefinition, @retvalOUT=@retVal2 OUTPUT;

		IF @testMode <> 0
		BEGIN
			PRINT(CAST(@ProcessCount AS VARCHAR(20)) + '  --> @SQL1 = ' + @SQL1) ;
			PRINT(CAST(@ProcessCount AS VARCHAR(20)) + '  ----> @retVal1 = ' + @retVal1) ;

			PRINT(CAST(@ProcessCount AS VARCHAR(20)) + '  --> @SQL2 = ' + @SQL2) ;
			PRINT(CAST(@ProcessCount AS VARCHAR(20)) + '  ----> @retVal2 = ' + @retVal2) ;
		END


		UPDATE @tempColumnCompare
			SET 
			  [Value1] = @retVal1
			, [Value2] = @retVal2
			, [Matching] =	CASE WHEN (@retVal1 < @retVal2) OR (@retVal1 IS NULL AND @retVal2 IS NOT NULL) THEN -1 
								 WHEN (@retVal1 = @retVal2) OR (@retVal1 IS NULL AND @retVal2 IS NULL) THEN 0
								 WHEN (@retVal1 > @retVal2) OR (@retVal1 IS NOT NULL AND @retVal2 IS NULL)THEN 1
							END 
		WHERE 
			ColumnName = @FetchColumnName;

		SET @ProcessCount = @ProcessCount + 1;
		FETCH NEXT FROM cursorTempRows INTO @FetchColumnName;		   
	END; -- end WHILE

	-- cleanup our cursor
	CLOSE cursorTempRows;  
	DEALLOCATE cursorTempRows; 

	IF @testMode <> 0
		SELECT * FROM @tempColumnCompare ORDER BY ColumnName;

	DECLARE @matchingCount INT = (SELECT COUNT(*) FROM @tempColumnCompare WHERE [Matching] = 0)

	INSERT INTO @tempColumnCompare (ColumnName,Value1,Value2,Matching) 
		VALUES ('[' + @tableName + '] Table: (' + @IdColumnName +  ') From->To',@IdComp1,@IdComp2,@matchingCount);

	IF @showDifferencesOnly = 0
		SELECT * FROM @tempColumnCompare ORDER BY ColumnName;
	ELSE
		SELECT * FROM @tempColumnCompare WHERE [Matching] <> 0 ORDER BY ColumnName;


END -- end of stored procedure
GO

/*
testing
exec [dbo].[Maintenance_CompareDataRecordsByTableAndIdFields]
	 @TableName = 'SERVICE_AGREEMENT'
	,@IdColumnName = 'SERVICE_AGREEMENT_ID'
	,@IdComp1 = 88
	,@IdComp2 = 93

exec [dbo].[Maintenance_CompareDataRecordsByTableAndIdFields]
	 @TableName = 'CHART'
	,@IdColumnName = 'CHART_ID'
	,@IdComp1 = 2086061
	,@IdComp2 = 2164620
*/
-- End of 02) DACS-3020 - SQL Create alter procedure - Maintenance_CompareDataRecordsByTableAndIdFields.SQL
GO

-- Start of 03) DACS-3020 - SQL Create alter procedure - Maintenance_ExpireChargeMasterByComplexFiltering.SQL

----------------------------------------
-- 03) DACS-3020 - SQL Create alter procedure - Maintenance_ExpireChargeMasterByComplexFiltering.SQL
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
      @SAId INT
	, @ExpireDate DATETIME = NULL
    , @ChargeMasterId INT = NULL
	, @CptCode VARCHAR(5) = NULL
    , @BillingCode VARCHAR(20) = NULL
    , @Description VARCHAR(100) = NULL
    , @CategoryId INT = NULL
    , @DepartmentId INT = NULL
    , @UsageCodeId INT = NULL
    , @PatientClassId INT = NULL
	, @TestMode BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @ExpireDate IS NULL
	BEGIN
		SET @ExpireDate = GETDATE();
	END;
	
	-- fill our temp table with all the CM Ids for the service agreement and prune that based on filtering
	DECLARE @tempCMIds TABLE 
	( 
		  CMId INT
		, SAId INT
		, ExpireDate DATETIME
		, CptCode VARCHAR(5)
		, BillingCode VARCHAR(20)
		, Description VARCHAR(100)
		, CategoryId INT
		, DepartmentId INT
		, UsageCodeId INT
		, PatientClassId INT
	);

	INSERT @tempCMIds(CMId,SAId,ExpireDate,CptCode,BillingCode,Description,CategoryId,DepartmentId,UsageCodeId,PatientClassId)
		SELECT 
			  CHARGE_MASTER_ID
			, SERVICE_AGREEMENT_ID
			, EXPIRATION_DATE
			, CPT_CODE
			, BILLING_CODE
			, [DESCRIPTION]
			, CHARGE_MASTER_CATEGORY_ID
			, CHARGE_MASTER_DEPT_ID
			, CHARGE_MASTER_USAGE_CODE
			, PATIENT_CLASS_ID
		FROM 
			[dbo].[CHARGE_MASTER]
		WHERE 
			SERVICE_AGREEMENT_ID = @SAId
			AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate)
	
	DECLARE @countCM INT = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('@SAId = ' + CAST(@SAId AS varchar(20)));
	PRINT('@ExpireDate = ' + CAST(@ExpireDate AS varchar(40)));
	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @msg VARCHAR(2000);  

	IF @countCM <= 0
	BEGIN
		SET @msg = '0 :: No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) + ', @ExpireDate = ' + CAST(@ExpireDate AS varchar(40));
		PRINT(@msg);
		SELECT 'Results' = @msg;
		RETURN;
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;
	
	DECLARE @ProcessingFields VARCHAR(1000) = '@SAId = ' + CAST(@SAId AS varchar(20)) + ', @ExpireDate = ' + CAST(@ExpireDate AS varchar(40));
	
	IF @ChargeMasterId IS NOT NULL AND @ChargeMasterId > 0
	BEGIN
		SET @ProcessingFields = (@ProcessingFields + ', ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(30))) 
		DELETE FROM @tempCMIds WHERE CMId <> @ChargeMasterId;
	END
	ELSE
	BEGIN
		IF @CptCode IS NOT NULL AND LEN(@CptCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CptCode = ' + @CptCode + '%') 
			-- DELETE FROM @tempCMIds WHERE CptCode <> @CptCode;
			DELETE FROM @tempCMIds WHERE CptCode NOT LIKE (@CptCode + '%');
		END;
	
		IF @BillingCode IS NOT NULL AND LEN(@BillingCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', BillingCode = ' + @BillingCode) 
			-- DELETE FROM @tempCMIds WHERE BillingCode <> @BillingCode;
			DELETE FROM @tempCMIds WHERE BillingCode NOT LIKE (@BillingCode + '%');
		END;
	
		IF @Description IS NOT NULL AND LEN(@Description) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', Description = %' + @Description + '%') 
			-- DELETE FROM @tempCMIds WHERE [Description] <> @Description;
			DELETE FROM @tempCMIds WHERE [Description] NOT LIKE ('%' + @Description + '%');
		END;

		IF @CategoryId IS NOT NULL AND @CategoryId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CategoryId = ' + CAST(@CategoryId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE CategoryId <> @CategoryId;
		END

		IF @DepartmentId IS NOT NULL AND @DepartmentId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', DepartmentId = ' + CAST(@DepartmentId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE DepartmentId <> @DepartmentId;
		END

		IF @UsageCodeId IS NOT NULL AND @UsageCodeId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', UsageCodeId = ' + CAST(@UsageCodeId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE UsageCodeId <> @UsageCodeId;
		END

		IF @PatientClassId IS NOT NULL AND @PatientClassId > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', PatientClassId = ' + CAST(@PatientClassId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE PatientClassId <> @PatientClassId;
		END
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;

	SET @countCM = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('Processing Filters = ' + @ProcessingFields);
	PRINT('Processing @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @tempResults TABLE ( Value VARCHAR(2000) );

	INSERT @tempResults(Value)
		SELECT  
			'CM: ' + CAST(CMId AS VARCHAR(30)) + ', ' +
			CptCode + ', ' +
			BillingCode + ', ' +
			Description AS [Value]
		FROM 
			@tempCMIds
			
	IF @TestMode = 1
	BEGIN
		PRINT('------------------------------------------');
		PRINT('       TESTMODE - EXITING WITHOUT PROCESSING');
		PRINT('------------------------------------------');
		SET @msg = '0 :: TEST MODE EXIT.  No Charge Master Records to process.  # would have processed: ' + CAST(@countCM AS varchar(40)) + ' :: filters = ' + @ProcessingFields;
		PRINT(@msg);
		INSERT INTO @tempResults (Value) VALUES (@msg);
		SELECT TOP 2000 * FROM @tempResults;
		RETURN;
	END;
	
	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		UPDATE CHARGE_MASTER 
			SET EXPIRATION_DATE = @ExpireDate
		WHERE SERVICE_AGREEMENT_ID = @SAId 
			AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate) 
			AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds);
		
		SET @countCM = 
			(
				SELECT COUNT(*) 
				FROM CHARGE_MASTER 
				WHERE SERVICE_AGREEMENT_ID = @SAId 
					AND EXPIRATION_DATE = @ExpireDate 
					AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds));
					
		PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	SET @msg = CAST(@countCM AS VARCHAR(30)) + ' :: Filters = ' + @ProcessingFields;
	--SELECT 'Results' = @msg;
	INSERT INTO @tempResults (Value) VALUES (@msg);
	SELECT TOP 2000 * FROM @tempResults;
END

GO

/*
Testing:
begin tran;
exec [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
      @SAId = 440
	, @ExpireDate = '04-01-2024'
	, @TestMode = 1
    --, @ChargeMasterId = 12345
	, @CptCode = 'A4223'
    --, @BillingCode = '1234567'
    , @Description = 'IV TUBING PRIMARY'
    , @CategoryId = 25460
    , @DepartmentId = 2509
    --, @UsageCodeId = 1
    , @PatientClassId = -1
	

exec [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
                          @SAId = 597
	                    , @ExpireDate = '12/12/2024'
                        , @ChargeMasterId = NULL
	                    , @CptCode = ''
                        , @BillingCode = ''
                        , @Description = 'eye'
                        , @CategoryId = NULL
                        , @DepartmentId = NULL
                        , @UsageCodeId = NULL
                        , @PatientClassId = NULL
                        , @TestMode = 1
                        ;
*/
-- End of 03) DACS-3020 - SQL Create alter procedure - Maintenance_ExpireChargeMasterByComplexFiltering.SQL
GO

-- Start of 04) DACS-3020 - SQL Create alter procedure - Maintenance_SelectChartsUsingProcedureCodes.SQL

----------------------------------------
-- 04) DACS-3020 - SQL Create alter procedure - Maintenance_SelectChartsUsingProcedureCodes.SQL
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_SelectChartsUsingProcedureCodes]
	 @SAIdList VARCHAR(1000)			-- i.e. 440,1029,333, ....
	,@ProcedureCodeList VARCHAR(2000)	-- i.e. 99999,99292,0010A, ....
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- copy string lists to temp tables
	DECLARE @tempSAIds TABLE	( SAID INT );
	INSERT @tempSAIds(SAID)
		SELECT 
			CAST(RTRIM(LTRIM(value)) AS INT) AS SAID
		FROM STRING_SPLIT (@SAIdList, ',')

	DECLARE @tempProcedureCodes TABLE	( PCCD VARCHAR(5) );
	INSERT @tempProcedureCodes(PCCD)
		SELECT 
			CAST(RTRIM(LTRIM(value)) AS VARCHAR(5)) AS PCCD
		FROM STRING_SPLIT (@ProcedureCodeList, ',')

	-- select * from @tempSAIds; -- testing
	-- select * from @tempProcedureCodes; -- testing

	SELECT top 1000 
		 cm.CPT_CODE
		,coer.CHART_ID
		FROM CHART_OBSERVATION_ENCOUNTER_RESULT coer
		inner join CHARGE_MASTER cm ON cm.charge_master_id = coer.charge_master_id
		inner join SERVICE_AGREEMENT sa ON sa.service_agreement_id = cm.service_agreement_id
		WHERE
		(sa.[EXPIRATION_DATE] IS NULL OR sa.[EXPIRATION_DATE] >= GETDATE())
		AND 
		cm.SERVICE_AGREEMENT_ID IN (SELECT DISTINCT SAID FROM @tempSAIds)
		AND 
		cm.CPT_CODE IN (SELECT DISTINCT PCCD FROM @tempProcedureCodes)
	
	
END -- end of stored procedure
GO	

/*
testing:
exec [dbo].[Maintenance_SelectChartsUsingProcedureCodes]
	 @SAIdList = '597,1029,333'
	,@ProcedureCodeList = '99284,36415,93005,85025,80053,J3490'
*/
-- End of 04) DACS-3020 - SQL Create alter procedure - Maintenance_SelectChartsUsingProcedureCodes.SQL
GO

-- Start of 05) DACS-3020 - SQL Create alter procedure - Maintenance_DeleteChargeMasterByComplexFiltering.SQL

----------------------------------------
-- 05) DACS-3020 - SQL Create alter procedure - Maintenance_DeleteChargeMasterByComplexFiltering.SQL
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_DeleteChargeMasterByComplexFiltering]
      @SAId INT
    , @ChargeMasterId INT = NULL
	, @CptCode VARCHAR(5) = NULL
    , @BillingCode VARCHAR(20) = NULL
    , @Description VARCHAR(100) = NULL
    , @CategoryId INT = NULL
    , @DepartmentId INT = NULL
    , @UsageCodeId INT = NULL
    , @PatientClassId INT = NULL
	, @TestMode BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	-- fill our temp table with all the CM Ids for the service agreement and prune that based on filtering
	DECLARE @tempCMIds TABLE 
	( 
		  CMId INT
		, SAId INT
		, CptCode VARCHAR(5)
		, BillingCode VARCHAR(20)
		, Description VARCHAR(100)
		, CategoryId INT
		, DepartmentId INT
		, UsageCodeId INT
		, PatientClassId INT
	);

	INSERT @tempCMIds(CMId,SAId,CptCode,BillingCode,Description,CategoryId,DepartmentId,UsageCodeId,PatientClassId)
		SELECT 
			  CHARGE_MASTER_ID
			, SERVICE_AGREEMENT_ID
			, CPT_CODE
			, BILLING_CODE
			, [DESCRIPTION]
			, CHARGE_MASTER_CATEGORY_ID
			, CHARGE_MASTER_DEPT_ID
			, CHARGE_MASTER_USAGE_CODE
			, PATIENT_CLASS_ID
		FROM 
			[dbo].[CHARGE_MASTER]
		WHERE 
			SERVICE_AGREEMENT_ID = @SAId
	
	DECLARE @countCM INT = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('@SAId = ' + CAST(@SAId AS varchar(20)));
	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @msg VARCHAR(2000);  

	IF @countCM <= 0
	BEGIN
		SET @msg = '0 :: No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20));
		PRINT(@msg);
		SELECT 'Results' = @msg;
		RETURN;
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;
	
	DECLARE @ProcessingFields VARCHAR(1000) = '@SAId = ' + CAST(@SAId AS varchar(20));
	
	IF @ChargeMasterId IS NOT NULL AND @ChargeMasterId > 0
	BEGIN
		SET @ProcessingFields = (@ProcessingFields + ', ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(30))) 
		DELETE FROM @tempCMIds WHERE CMId <> @ChargeMasterId;
	END
	ELSE
	BEGIN
		IF @CptCode IS NOT NULL AND LEN(@CptCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CptCode = ' + @CptCode + '%') 
			-- DELETE FROM @tempCMIds WHERE CptCode <> @CptCode;
			DELETE FROM @tempCMIds WHERE CptCode NOT LIKE (@CptCode + '%');
		END;
	
		IF @BillingCode IS NOT NULL AND LEN(@BillingCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', BillingCode = ' + @BillingCode) 
			-- DELETE FROM @tempCMIds WHERE BillingCode <> @BillingCode;
			DELETE FROM @tempCMIds WHERE BillingCode NOT LIKE (@BillingCode + '%');
		END;
	
		IF @Description IS NOT NULL AND LEN(@Description) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', Description = %' + @Description + '%') 
			-- DELETE FROM @tempCMIds WHERE [Description] <> @Description;
			DELETE FROM @tempCMIds WHERE [Description] NOT LIKE ('%' + @Description + '%');
		END;

		IF @CategoryId IS NOT NULL AND @CategoryId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CategoryId = ' + CAST(@CategoryId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE CategoryId <> @CategoryId;
		END

		IF @DepartmentId IS NOT NULL AND @DepartmentId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', DepartmentId = ' + CAST(@DepartmentId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE DepartmentId <> @DepartmentId;
		END

		IF @UsageCodeId IS NOT NULL AND @UsageCodeId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', UsageCodeId = ' + CAST(@UsageCodeId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE UsageCodeId <> @UsageCodeId;
		END

		IF @PatientClassId IS NOT NULL AND @PatientClassId > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', PatientClassId = ' + CAST(@PatientClassId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE PatientClassId <> @PatientClassId;
		END
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;

	SET @countCM = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('Processing Filters = ' + @ProcessingFields);
	PRINT('Processing @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @tempResults TABLE ( Value VARCHAR(2000) );

	INSERT @tempResults(Value)
		SELECT  
			'CM: ' + CAST(CMId AS VARCHAR(30)) + ', ' +
			CptCode + ', ' +
			BillingCode + ', ' +
			Description AS [Value]
		FROM 
			@tempCMIds
			
	IF @TestMode = 1
	BEGIN
		PRINT('------------------------------------------');
		PRINT('       TESTMODE - EXITING WITHOUT PROCESSING');
		PRINT('------------------------------------------');
		SET @msg = '0 :: TEST MODE EXIT.  No Charge Master Records to process.  # would have processed: ' + CAST(@countCM AS varchar(40)) + ' :: filters = ' + @ProcessingFields;
		PRINT(@msg);
		INSERT INTO @tempResults (Value) VALUES (@msg);
		SELECT TOP 2000 * FROM @tempResults;
		RETURN;
	END;
	
	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		DELETE FROM CHARGE_MASTER
		WHERE SERVICE_AGREEMENT_ID = @SAId 
			AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds);
		
		SET @countCM = 
			(
				SELECT COUNT(*) 
				FROM CHARGE_MASTER 
				WHERE SERVICE_AGREEMENT_ID = @SAId 
					AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds)
			);
					
		PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	SET @msg = CAST(@countCM AS VARCHAR(30)) + ' :: Filters = ' + @ProcessingFields;
	--SELECT 'Results' = @msg;
	INSERT INTO @tempResults (Value) VALUES (@msg);
	SELECT TOP 2000 * FROM @tempResults;
END

GO

/*
Testing:
begin tran;
exec [dbo].[Maintenance_DeleteChargeMasterByComplexFiltering]
      @SAId = 440
	, @TestMode = 1
    --, @ChargeMasterId = 12345
	, @CptCode = 'A4223'
    --, @BillingCode = '1234567'
    , @Description = 'IV TUBING PRIMARY'
    , @CategoryId = 25460
    , @DepartmentId = 2509
    --, @UsageCodeId = 1
    , @PatientClassId = -1
	

exec [dbo].[Maintenance_DeleteChargeMasterByComplexFiltering]
                          @SAId = 597
                        , @ChargeMasterId = NULL
	                    , @CptCode = ''
                        , @BillingCode = ''
                        , @Description = 'eye'
                        , @CategoryId = NULL
                        , @DepartmentId = NULL
                        , @UsageCodeId = NULL
                        , @PatientClassId = NULL
                        , @TestMode = 1
                        ;
*/
-- End of 05) DACS-3020 - SQL Create alter procedure - Maintenance_DeleteChargeMasterByComplexFiltering.SQL
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
