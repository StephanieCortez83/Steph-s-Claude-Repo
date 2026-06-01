SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectIcd10RuleBySelectedCodeAndDos]
	  @SelectedCode VARCHAR(100)
	, @DateOfService DATETIME
AS
	------------------------------------------------------------------------------------
	-- DACS-3324 - 20240625 - JB suggested removing conditionals for variable validation and modifying ACS to check before calling
	------------------------------------------------------------------------------------

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT DISTINCT 
		ICD_10_RULE_ID
		, DESCRIPTION
		, RULE_TYPE_CD
		, FIRST_CODE, LAST_CODE
	FROM 
		ICD_10_RULE
	WHERE 
        EFFECTIVE_DT <= @DateOfService AND EXPIRATION_DT >= @DateOfService
        AND ((@SelectedCode BETWEEN FIRST_CODE and LAST_CODE ) OR FIRST_CODE = @SelectedCode
        OR @SelectedCode >= FIRST_CODE and @SelectedCode LIKE (LAST_CODE + '%') )
	ORDER BY 
		FIRST_CODE
		, LAST_CODE
		, RULE_TYPE_CD;

GO
