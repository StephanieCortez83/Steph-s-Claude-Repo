-----------------------------------------------------
-- 01) DACS-2811 - Create OR Alter Procedure - [dbo].[SelectIcd10RuleBySelectedCodeAndDos].sql
-----------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[SelectIcd10RuleBySelectedCodeAndDos]
	  @SelectedCode VARCHAR(10)
	, @DateOfService DATETIME
AS
	IF @SelectedCode IS NULL OR LEN(@SelectedCode) <= 0
	BEGIN
		print('SelectedCode is invalid');
		RETURN;
	END;

	IF @DateOfService IS NULL OR @DateOfService < '01-01-1900' OR @DateOfService > '12-31-2099'
	BEGIN
		print('DateOfService is invalid');
		RETURN;
	END;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT DISTINCT 
		ICD_10_RULE_ID, DESCRIPTION, RULE_TYPE_CD, FIRST_CODE, LAST_CODE
	FROM 
		ICD_10_RULE
	WHERE 
        EFFECTIVE_DT <= @DateOfService AND EXPIRATION_DT >= @DateOfService
        AND ((@SelectedCode BETWEEN FIRST_CODE and LAST_CODE ) OR FIRST_CODE = @SelectedCode
        OR @SelectedCode >= FIRST_CODE and @SelectedCode LIKE (LAST_CODE + '%') )
	ORDER BY 
		FIRST_CODE, LAST_CODE, RULE_TYPE_CD;

GO

/*
testing:
exec [dbo].[SelectIcd10RuleBySelectedCodeAndDos] @SelectedCode='i10', @DateOfService='10-12-2023';

SELECT DISTINCT ir.ICD_10_RULE_ID, ir.DESCRIPTION, ir.RULE_TYPE_CD, ir.FIRST_CODE, ir.LAST_CODE
FROM ICD_10_RULE ir with (NOLOCK)
WHERE EFFECTIVE_DT <= '10-12-2023' AND ir.EXPIRATION_DT >= '10-12-2023'
AND (('i10' BETWEEN ir.FIRST_CODE and ir.LAST_CODE ) OR ir.FIRST_CODE = 'i10'
OR 'i10' >= ir.FIRST_CODE and 'i10' LIKE ir.LAST_CODE + '%' )
ORDER BY ir.FIRST_CODE, ir.LAST_CODE, ir.RULE_TYPE_CD;
*/