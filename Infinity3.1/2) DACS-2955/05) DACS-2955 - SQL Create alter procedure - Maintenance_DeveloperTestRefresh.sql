----------------------------------------
-- 05) DACS-2955 - SQL Create alter procedure - Maintenance_DeveloperTestRefresh.sql
----------------------------------------
USE [DeveloperTest]
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_DeveloperTestRefresh]
	@TableList VARCHAR(MAX)
AS
BEGIN
	/*
		Original source provided by J. Burge 20240131
		Turned into procedure by W. Pippin 20240202
	*/

	SET NOCOUNT ON;

	--determine table list
	DECLARE @tables TABLE
	(
		ID INT IDENTITY(1, 1)
	   ,SchemaName sysname
	   ,TableName sysname
	);
	INSERT @tables
	(
		SchemaName
	   ,TableName
	)
	VALUES
		('dbo', 'CHARGE_MASTER')
		,('dbo', 'SERVICE_AGREEMENT');

	IF @TableList IS NULL OR LEN(@TableList) <= 0
	BEGIN
		PRINT('@TableList is empty.  Only copying CHARGE_MASTER AND SERVICE_AGREEMENT tables');
	END
	ELSE
	BEGIN
		INSERT @tables(SchemaName,TableName)
			SELECT 
				'dbo' AS SchemaName
				, RTRIM(LTRIM(value)) AS TableName
			FROM STRING_SPLIT (@TableList, ',')
		
		-- select * from @tables -- testing
	END;

	--validation
	--drop all tables
	DECLARE @sql NVARCHAR(MAX)
		   ,@SchemaName sysname
		   ,@TableName sysname
		   ,@rowcount INT
		   ,@b VARCHAR(100) = CHAR(13) + '--------------------------' + CHAR(13)
		   ,@error BIT = 0;

	IF @@SERVERNAME <> 'dRCMSQLaz03'
	BEGIN
		RAISERROR('SCRIPT MUST BE RAN ON dRCMSQLaz03', 16, -1);
		SET @error = 1;
	END;
	IF @error = 0
	BEGIN

		PRINT @b + 'DROPPING TABLES' + @b;

		DECLARE cr_drop CURSOR LOCAL FOR SELECT name FROM DeveloperTest.sys.tables;

		OPEN cr_drop;
		FETCH NEXT FROM cr_drop
		INTO @TableName;

		WHILE @@FETCH_STATUS = 0 AND @error = 0
		BEGIN

			SET @sql
				= N'
	IF DB_NAME() <> ''DeveloperTest''
	BEGIN
		RAISERROR(''FATAL ERROR: Must BE RAN IN DeveloperTest DATABASE'',16,-1)
		set @error =1 
		return
	END

	DROP TABLE IF EXISTS ' + @TableName;
			EXECUTE DeveloperTest.dbo.sp_executesql @sql
											  ,N'@error bit output'
											  ,@error = @error OUTPUT;
			PRINT 'Dropped Table ' + @TableName;
			FETCH NEXT FROM cr_drop
			INTO @TableName;
		END;
		CLOSE cr_drop;
		DEALLOCATE cr_drop;


		--create tables
		IF @error = 0
		BEGIN
			PRINT @b + 'CREATING TABLES' + @b;
			DECLARE cr_create CURSOR LOCAL FOR
			SELECT SchemaName
				  ,TableName
			FROM @tables;

			OPEN cr_create;
			FETCH NEXT FROM cr_create
			INTO @SchemaName
				,@TableName;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @sql
					= N'SELECT * INTO DeveloperTest.' + @SchemaName + N'.' + @TableName + N' FROM RevCycleDB.' + @SchemaName
					  + N'.' + @TableName + N' SET @rowcount=@@ROWCOUNT';
				PRINT '--' + CHAR(13) + 'Creating table: ' + @SchemaName + '.' + @TableName;

				EXECUTE DeveloperTest.dbo.sp_executesql @sql
												  ,N'@rowcount int output'
												  ,@rowcount = @rowcount OUTPUT;
				PRINT CAST(@rowcount AS VARCHAR(20)) + ' rows inserted';

				FETCH NEXT FROM cr_create
				INTO @SchemaName
					,@TableName;
			END;
			CLOSE cr_create;
			DEALLOCATE cr_create;
		END;

		PRINT @b + 'DeveloperTest REFRESH SUCCESSFULLY COMPLETED' + @b;
	END;


END -- end of stored procedure
GO

/*
testing
begin tran;
exec [dbo].[Maintenance_DeveloperTestRefresh] @TableList = 'blah, blah2, blah3'
rollback tran;
commit tran;
*/
