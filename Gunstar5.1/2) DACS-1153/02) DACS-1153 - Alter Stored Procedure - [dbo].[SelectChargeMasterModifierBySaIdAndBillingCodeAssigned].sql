----------------------------------------
-- 02) DACS-1153 - Alter Stored Procedure - [dbo].[SelectChargeMasterModifierBySaIdAndBillingCodeAssigned].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterModifierBySaIdAndBillingCodeAssigned]
    @ServiceAgreementId INT
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
	SELECT 
       [CHARGE_MASTER_ID]
      ,[MODIFIER]
	FROM 
		[RevCycleDB].[dbo].[CHARGE_MASTER_MODIFIER]
    WHERE 
		[SERVICE_AGREEMENT_ID]= @ServiceAgreementId
		AND ([BILLING_CODE] IS NOT NULL AND [BILLING_CODE] <> '');

END
GO


