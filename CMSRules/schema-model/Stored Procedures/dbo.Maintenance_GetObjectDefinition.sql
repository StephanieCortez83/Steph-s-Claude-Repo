SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[Maintenance_GetObjectDefinition]
      @Name VARCHAR(512)
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		 o.[name]
		,o.[type]
		,o.[modify_date]
		,LEN(m.definition) AS LengthDefinition
		,m.[definition]
	FROM 
		[sys].[objects] o
		JOIN sys.sql_modules m ON o.OBJECT_ID = m.OBJECT_ID
	WHERE 
		o.[name] = @Name
	
/*
EXEC [dbo].[Maintenance_GetObjectDefinition] @Name='PqrsMeasureIsSatisfiedByMeasureIdAndREQ2DxOr3Cpt_Type118A';
*/	
END -- end procedure
GO
