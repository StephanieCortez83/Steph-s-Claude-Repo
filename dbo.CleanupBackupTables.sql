SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[CleanupBackupTables]  
	 @TableStartsWith VARCHAR(255)
	,@TestMode INT = 0  -- 1 = in test mode: no deletes performed, 0 = will perform deletes
	,@YearsToRetain INT = 2 -- older than 2 years is the default.
AS  
/*
CleanupBackupTables
Takes a table name that begins with @TableStartsWith and drops all of the backup tables that are
older than @YearsToRetain based on their creation date.  @TestMode set to 0 actually drops the tables.
I suggest running this in @TestMode = 1 before actually dropping tables.
*/
BEGIN
	PRINT('TableStartsWith = ' + @TableStartsWith);
	PRINT('TestMode = ' + CAST(@TestMode AS VARCHAR(20)));
	PRINT('YearsToRetain = ' + CAST(@YearsToRetain AS VARCHAR(4)));

	IF OBJECT_ID('tempdb..#tmpTableNamesLike') IS NOT NULL
	BEGIN
		DROP TABLE #tmpTableNamesLike
	END;

	SELECT * INTO #tmpTableNamesLike
			FROM sys.tables where name like @TableStartsWith + '%';

		select * from #tmpTableNamesLike;

		-- declare variables
		DECLARE @DateToDrop DATETIME = (SELECT DATEADD(YEAR, -@YearsToRetain, GETDATE()));
		DECLARE @FetchDropTableName VARCHAR(255);
		DECLARE @FetchTableCreateDate DATETIME;
		DECLARE @ProcessCount INT = 1;

		select @DateToDrop;

		-- Define the cursor (based on the first query)
		DECLARE cursorAllTablesWithLikeName CURSOR LOCAL FOR  
			SELECT [name], [create_date] FROM #tmpTableNamesLike
			ORDER BY [name] ASC;  
		
		-- Open the cursor (based on the first query)
		OPEN cursorAllTablesWithLikeName;

		-- Fetch the first record from the cursor
		FETCH NEXT FROM cursorAllTablesWithLikeName
			INTO @FetchDropTableName, @FetchTableCreateDate;
		
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			
			IF @FetchTableCreateDate < @DateToDrop
			BEGIN
 	
				PRINT N'DROPPING TABLE : ' + @FetchDropTableName + N' Created : ' + CONVERT(VARCHAR(10), @FetchTableCreateDate, 101);
				
				IF @TestMode = 0
				BEGIN
					-- perform the delete
					DECLARE @DropSQL nvarchar(MAX) = 
							  N'Drop Table ' + QUOTENAME(@FetchDropTableName) + N';'
					EXEC sys.sp_executesql @DropSQL;
				END
				
			END
			ELSE
			BEGIN
				PRINT N'KEEPING TABLE : ' + @FetchDropTableName + N' Created : ' + CONVERT(VARCHAR(10), @FetchTableCreateDate, 101);
			END;

			PRINT('------------------------');

			-- Fetch the next record from the cursor
			FETCH NEXT FROM cursorAllTablesWithLikeName
				INTO @FetchDropTableName, @FetchTableCreateDate;
				
		END  -- end fetch while loop
		 
		-- cleanup our cursor
		CLOSE cursorAllTablesWithLikeName;  
		DEALLOCATE cursorAllTablesWithLikeName;
END -- of procedure
GO
