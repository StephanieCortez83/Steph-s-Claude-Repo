----------------------------------------
-- 03) DACS-2955 - Alter SPROC - Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId.sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId]
      @SAId INT
	, @ResultAsStrings BIT = 0  
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @ResultAsStrings = 1
	BEGIN
	
		SELECT TOP 100 
			cm.[CPT_CODE] + '\t' + cmm.[MODIFIER] + '\t' + cmm.[BILLING_CODE] AS RESULT
			FROM [CHARGE_MASTER_MODIFIER] cmm 
			INNER JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID] = cmm.[CHARGE_MASTER_ID]
		WHERE 
			cmm.[SERVICE_AGREEMENT_ID] = @SAId 
			AND cmm.[SERVICE_AGREEMENT_ID] = cm.[SERVICE_AGREEMENT_ID]
			AND (cmm.[BILLING_CODE] IS NOT NULL AND LEN(cmm.[BILLING_CODE]) > 0)
		ORDER BY cm.[cpt_code] ASC;

		RETURN;
	END;
	
	SELECT TOP 100 
		  cm.[CPT_CODE]
		, cmm.[MODIFIER]
		, cmm.[BILLING_CODE]
		FROM [CHARGE_MASTER_MODIFIER] cmm 
		INNER JOIN [CHARGE_MASTER] cm ON cm.[CHARGE_MASTER_ID] = cmm.[CHARGE_MASTER_ID]
	WHERE 
		cmm.[SERVICE_AGREEMENT_ID] = @SAId 
		AND cmm.[SERVICE_AGREEMENT_ID] = cm.[SERVICE_AGREEMENT_ID]
		AND (cmm.[BILLING_CODE] IS NOT NULL AND LEN(cmm.[BILLING_CODE]) > 0)
	ORDER BY cm.[cpt_code] ASC;

END

GO


/*
testing - 
begin tran;
exec [dbo].[Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId] @SAId = 1739; -- Prod
exec [dbo].[Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId] @SAId = 535; -- QA
exec [dbo].[Maintenance_SelectChargeMasterModifiersWithBillingCodesByServiceAgreementId] @SAId = 535, @ResultAsStrings = 1; -- QA
-- rollback tran
-- commit tran;

*/