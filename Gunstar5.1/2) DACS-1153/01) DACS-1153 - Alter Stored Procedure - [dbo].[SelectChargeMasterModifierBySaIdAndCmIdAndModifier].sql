----------------------------------------
-- 01) DACS-1153 - Alter Stored Procedure - [dbo].[SelectChargeMasterModifierBySaIdAndCmIdAndModifier].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterModifierBySaIdAndCmIdAndModifier]
    @ServiceAgreementId INT, 
    @ChargeMasterId INT, 
	@Modifier VARCHAR(20)
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		[BILLING_CODE]
    FROM 
		[dbo].[CHARGE_MASTER_MODIFIER]
    WHERE 
		[SERVICE_AGREEMENT_ID]= @ServiceAgreementId
        AND [CHARGE_MASTER_ID]= @ChargeMasterId
        AND [MODIFIER]= @Modifier;

END
GO


