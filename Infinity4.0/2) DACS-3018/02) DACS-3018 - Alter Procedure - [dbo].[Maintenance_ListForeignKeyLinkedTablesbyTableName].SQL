----------------------------------------------------------------------------------------
-- 02) DACS-3018 - Alter Procedure - [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName].SQL
----------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName]  
	 @TableName VARCHAR(1024)
AS  
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @TableName IS NULL OR LEN(@TableName) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'Error: TableName is invalid.';
		RETURN;
	END;

	PRINT('TableName = ' + @TableName);

	IF OBJECT_ID('tempdb..#tmpFKeys') IS NOT NULL
	BEGIN
		DROP TABLE #tmpFKeys
	END;
	
	IF OBJECT_ID('tempdb..#tmpFKTables') IS NOT NULL
	BEGIN
		DROP TABLE #tmpFKTables
	END;

	-- find Foreign Keys specified thru linked objects.  deleting these tables should remove any FK exceptions!!
	CREATE TABLE #tmpFKeys(
		PKTABLE_QUALIFIER	[nvarchar](255) NULL
		,PKTABLE_OWNER		[nvarchar](255) NULL
		,PKTABLE_NAME		[nvarchar](255) NULL
		,PKCOLUMN_NAME		[nvarchar](255) NULL
		,FKTABLE_QUALIFIER	[nvarchar](255) NULL
		,FKTABLE_OWNER		[nvarchar](255) NULL
		,FKTABLE_NAME		[nvarchar](255) NULL
		,FKCOLUMN_NAME		[nvarchar](255) NULL
		,KEY_SEQ			INT
		,UPDATE_RULE		INT	
		,DELETE_RULE		INT
		,FK_NAME			[nvarchar](255) NULL
		,PK_NAME			[nvarchar](255) NULL
		,DEFERRABILITY		INT
	)

	INSERT INTO #tmpFKeys
		EXEC sp_fkeys @pktable_name = @TableName
	
	SELECT [FKTABLE_NAME] INTO #tmpFKTables
		FROM (SELECT DISTINCT [FKTABLE_NAME] FROM #tmpFKeys) AS FKSource;

	SELECT * FROM #tmpFKTables;

GO


/*
test:
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = 'FACILITY'
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = 'SERVICE_AGREEMENT'
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = 'CHARGE_MASTER'
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = ''
	exec [dbo].[Maintenance_ListForeignKeyLinkedTablesbyTableName] @TableName = NULL
*/


