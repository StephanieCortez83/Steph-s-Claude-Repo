------------------------------------------------------------------------------
-- 02) DACS-1591 - Create procedure - [dbo].[ExpireChargeMasterAndChargeAmountBySAIdAndCmId].SQL
------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[ExpireChargeMasterAndChargeAmountBySAIdAndCmId] 
	  @ServiceAgreementId INT = NULL
	, @ChargeMasterId INT = NULL
AS
BEGIN

	IF @ServiceAgreementId <= 0
	BEGIN
		SELECT 'Result' = -1, 'Message' = 'Service Agreement Id is invalid.';
		RETURN;
	END;

	IF @ChargeMasterId <= 0
	BEGIN
		SELECT 'Result' = -2, 'Message' = 'Charge Master Id is invalid.';
		RETURN;
	END;

	DECLARE @ExpireDate DATETIME = GETDATE();

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	
	-- expire ALL active charge master amount entries first should this table ever get a foreign key constraint
	UPDATE [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT]
		SET [EXPIRATION_DATE] = @ExpireDate
	WHERE 
		[CHARGE_MASTER_ID] = @ChargeMasterId
		AND [EFFECTIVE_DATE] < @ExpireDate
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpireDate);
	
	-- expire charge master entry
	DECLARE @FoundItemCount INT = 
								(
									SELECT 
										COUNT(*) 
									FROM 
										[RevCycleDB].[dbo].[CHARGE_MASTER] 
									WHERE 
										[SERVICE_AGREEMENT_ID]= @ServiceAgreementId 
										AND [CHARGE_MASTER_ID]= @ChargeMasterId
										AND [EFFECTIVE_DATE] < @ExpireDate
										AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpireDate)
								);

	IF @FoundItemCount = 1
	BEGIN
		UPDATE [RevCycleDB].[dbo].[CHARGE_MASTER]
			SET [EXPIRATION_DATE] = GETDATE()
		WHERE 
			[SERVICE_AGREEMENT_ID]= @ServiceAgreementId 
			AND [CHARGE_MASTER_ID]= @ChargeMasterId
			AND [EFFECTIVE_DATE] < @ExpireDate
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpireDate);
	END
	ELSE
	BEGIN
		IF @FoundItemCount = 0
		BEGIN
			SELECT 'Result' = -3, 'Message' = 'Charge Master Id result does not exist.';
		END;
		
		IF @FoundItemCount > 1
		BEGIN
			SELECT 'Result' = -4, 'Message' = 'Charge Master Id result is non-unique.';
		END;
	
		RETURN;
	END;
	
	SET @FoundItemCount = ( 
							SELECT 
								COUNT(*) 
							FROM 
								[RevCycleDB].[dbo].[CHARGE_MASTER] 
							WHERE 
								[SERVICE_AGREEMENT_ID]= @ServiceAgreementId 
								AND [CHARGE_MASTER_ID]= @ChargeMasterId
								AND [EFFECTIVE_DATE] < @ExpireDate
								AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpireDate)
						  );	
								
	IF	@FoundItemCount = 0						
		SELECT 'Result' = 1, 'Message' = 'Success.';
	ELSE
		SELECT 'Result' = 0, 'Message' = 'Error: charge master count = ' + CAST(@FoundItemCount AS VARCHAR(20));

END
GO


