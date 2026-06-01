SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectIcd10CodeMasterIsValid] 
	 @Icd10Code VARCHAR(10)
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- setup resources
	----------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- Replaces the following ACS inline SQL:
	----------------
/*
	ICD10CodeMasterDAO.cs: IsValidICD10Code(...)
"SELECT ICD_10_CODE "
+ " FROM ICD_10_CODE_MASTER cm with (NOLOCK)"
+ " WHERE cm.ICD_10_CODE = '" + cleanCode + "' ";
*/	

	----------------
	-- Assume ACS is performing variable validation prior to calling SPROC:
	----------------

	SELECT TOP 1 1
	FROM
		ICD_10_CODE_MASTER
	WHERE
		ICD_10_CODE = @Icd10Code;

END -- end procedure

GO
