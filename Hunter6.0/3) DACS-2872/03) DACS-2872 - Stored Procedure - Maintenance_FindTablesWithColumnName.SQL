----------------------------------------------------
-- 03) DACS-2872 - Stored Procedure - Maintenance_FindTablesWithColumnName.SQL
----------------------------------------------------
USE [RevCycleDB]
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_FindTablesWithColumnName]  
	  @SearchTerm AS VARCHAR(100)
	, @ExactSearch AS BIT = NULL
AS  
BEGIN    
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @SearchTerm IS NULL OR LEN(@SearchTerm) <= 0 OR LEN(@SearchTerm) > 100
	BEGIN
		PRINT('@SearchTerm is invalid');
		RETURN;
	END;
	
	IF @ExactSearch = 1
		PRINT('Using exact search.');
	ELSE
		SET @SearchTerm = '%' + @SearchTerm + '%';


	SELECT
		 c.name  AS 'ColumnName'
		, (SCHEMA_NAME(t.schema_id) + '.' + t.name) AS 'TableName'
	FROM
		sys.columns c
		JOIN sys.tables t ON c.object_id = t.object_id
	WHERE       
		c.name LIKE @SearchTerm
	ORDER BY
		TableName, ColumnName;

END

GO

/*
testing:
exec [dbo].[Maintenance_FindTablesWithColumnName]  @SearchTerm = 'service_agreement_'
exec [dbo].[Maintenance_FindTablesWithColumnName]  @SearchTerm = 'service_agreement_', @ExactSearch = 1
exec [dbo].[Maintenance_FindTablesWithColumnName]  @SearchTerm = 'service_agreement_', @ExactSearch = 0
 

SELECT      c.name  AS 'ColumnName'
            ,(SCHEMA_NAME(t.schema_id) + '.' + t.name) AS 'TableName'
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
WHERE       c.name LIKE '%MyName%'
ORDER BY    TableName, ColumnName;
			
Search Tables and Views:
SELECT      COLUMN_NAME AS 'ColumnName'
            ,TABLE_NAME AS  'TableName'
FROM        INFORMATION_SCHEMA.COLUMNS
WHERE       COLUMN_NAME LIKE '%MyName%'
ORDER BY    TableName, ColumnName;
*/