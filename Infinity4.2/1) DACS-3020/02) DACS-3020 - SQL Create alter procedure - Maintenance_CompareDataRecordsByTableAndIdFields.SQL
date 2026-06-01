----------------------------------------
-- 02) DACS-3020 - SQL Create alter procedure - Maintenance_CompareDataRecordsByTableAndIdFields.SQL
----------------------------------------
USE [RevCycleDB]
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
