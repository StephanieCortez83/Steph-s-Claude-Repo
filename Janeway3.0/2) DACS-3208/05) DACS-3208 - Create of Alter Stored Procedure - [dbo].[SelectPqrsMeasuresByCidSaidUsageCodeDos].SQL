------------------------------------------------------------------------------------
-- 05) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectPqrsMeasuresByCidSaidUsageCodeDos].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPqrsMeasuresByCidSaidUsageCodeDos] 
	  @chartId INT
	, @serviceAgreementId INT
	, @usageCode INT
	, @chartDOS DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @chartId < 0
	BEGIN
		-- SELECT 'Error' = -1, 'Message' = 'bad @chartId';
		RETURN;
	END;
		
	IF @serviceAgreementId IS NULL OR @serviceAgreementId <= 0
	BEGIN
		-- SELECT 'Error' = -1, 'Message' = 'bad @serviceAgreementId';
		RETURN;
	END;

	IF @chartDOS IS NULL
	BEGIN
		SET @chartDOS = GETDATE();
		-- PRINT('@chartDOS set to ' + CAST(@chartDOS AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		  CM.CHARGE_MASTER_ID
		, CM.CHARGE_MASTER_CATEGORY_ID
		, CM.DESCRIPTION
		, CM.LONG_DESCRIPTION
		, CM.CPT_CODE
		, CM.BILLING_CODE
		, CM.MODIFIER_REQUIRED
		, PPE.ICD9_CODE
		, PPE.ICD_10_CODE
		, PPE.PROCEDURE_DATE
		, CMC.DESCRIPTION
		, PPE.QUANTITY
		, PPE.MODIFIERS
		, PPE.PHYSICIAN_ID
		, PPE.INSUFFICIENT_DOCUMENTATION_TO_BILL
		, PPE.ADD_TO_FACILITY_PROCEDURE
		, CM.MAX_QUANTITY
		, CM.ALLOW_NEGATIVE_UNITS_IND
		, CM.CHARGE_MASTER_DEPT_ID 
		, 0 EXCLUDE_FROM_CODER_QA_REPORT
		, CAST(0 AS BIT) HAS_MODIFIERS
	FROM 
		CHARGE_MASTER CM 
        LEFT JOIN PHYSICIAN_PROCEDURE_EVALUATION PPE ON CM.CHARGE_MASTER_ID = PPE.PHYSICIAN_PROCEDURE_ID
			AND (CHART_ID= @chartId OR CHART_ID IS NULL)
        JOIN CHARGE_MASTER_CATEGORY CMC ON CMC.CHARGE_MASTER_CATEGORY_ID = CM.CHARGE_MASTER_CATEGORY_ID
    WHERE 
		@chartDOS BETWEEN CM.EFFECTIVE_DATE AND CM.EXPIRATION_DATE
		AND CM.SERVICE_AGREEMENT_ID = @serviceAgreementId            
        AND CM.CHARGE_MASTER_USAGE_CODE = @usageCode
	;

END -- end procedure

GO

/*
testing:
EXEC SelectPqrsMeasuresByCidSaidUsageCodeDos
	@chartId = 2100107114,
    @serviceAgreementId = 555266,
    @usageCode = 9,
    @chartDOS = '1/22/2024 12:00:00 AM'
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/