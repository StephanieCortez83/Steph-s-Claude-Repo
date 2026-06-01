SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_FindTablesWithColumnName]  
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
