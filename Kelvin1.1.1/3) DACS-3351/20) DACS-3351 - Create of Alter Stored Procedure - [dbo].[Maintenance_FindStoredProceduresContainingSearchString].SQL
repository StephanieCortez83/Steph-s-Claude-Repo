------------------------------------------------------------------------------------
-- 20) DACS-3351 - Create of Alter Stored Procedure - [dbo].[Maintenance_FindStoredProceduresContainingSearchString].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_FindStoredProceduresContainingSearchString] 
	  @SearchString VARCHAR(256)
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- validate parameters
	----------------
	IF @SearchString IS NULL OR LEN(@SearchString) <= 0
	BEGIN
		RETURN;
	END;

	SET @SearchString = '%' + @SearchString + '%';

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		ROUTINE_NAME
		, ROUTINE_DEFINITION
	FROM 
		INFORMATION_SCHEMA.ROUTINES
	WHERE 
		ROUTINE_DEFINITION LIKE @SearchString
		AND ROUTINE_TYPE = 'PROCEDURE';

END -- end procedure

GO

/*
testing:
begin tran; -- testing
EXEC [dbo].[Maintenance_FindStoredProceduresContainingSearchString] @SearchString= '= (SELECT '
rollback tran; -- testing
commit tran; -- testing
*/