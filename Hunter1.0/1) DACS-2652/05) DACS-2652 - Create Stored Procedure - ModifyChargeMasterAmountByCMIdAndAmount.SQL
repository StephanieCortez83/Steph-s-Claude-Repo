---------------------------------------------------------------------------------
-- 05) DACS-2652 - Create Stored Procedure - ModifyChargeMasterAmountByCMIdAndAmount.SQL
---------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[ModifyChargeMasterAmountByCMIdAndAmount]
      @ChargeMasterId INT		-- Single Charge Master Id
    , @Amount money
AS
BEGIN

	IF @ChargeMasterId IS NULL OR @ChargeMasterId <= 0
	BEGIN
		SELECT 'Error' = 'Charge Master Id is invalid';
		RETURN;
	END;

	IF @Amount IS NULL OR @Amount < 0.0
	BEGIN
		SELECT 'Error' = 'Amount is invalid';
		RETURN;
	END;
	
	DECLARE @DoInsert DATETIME = GETDATE();
	DECLARE @DoExpirePrev DATETIME = DATEADD(dd,-1,@DoInsert);
	DECLARE @DoExpire DATETIME =  DATEADD(yy,100,@DoInsert);

	PRINT('@ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(20)));
	PRINT('@Amount = ' + CAST(@Amount AS VARCHAR(50)));
	PRINT('@DoInsert = ' + CAST(@DoInsert AS VARCHAR(50)));
	PRINT('@DoExpirePrev = ' + CAST(@DoExpirePrev AS VARCHAR(50)));
	PRINT('@DoExpire = ' + CAST(@DoExpire AS VARCHAR(50)));

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @CountCMAmount INT = (SELECT COUNT(*) FROM [CHARGE_MASTER_CHARGE_AMOUNT] WHERE [charge_master_id] = @ChargeMasterId);
	
	IF @CountCMAmount > 0
	BEGIN
		UPDATE [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT]
			SET [EXPIRATION_DATE] = @DoExpirePrev
		WHERE 
			[CHARGE_MASTER_ID] = @ChargeMasterId
			AND [EFFECTIVE_DATE] < @DoInsert
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @DoInsert);
	END;

	SET @CountCMAmount = (
			SELECT COUNT(*) 
			FROM 
				[CHARGE_MASTER_CHARGE_AMOUNT] 
			WHERE 
				[charge_master_id] = @ChargeMasterId
				AND [EFFECTIVE_DATE] <= @DoInsert
				AND [EXPIRATION_DATE] > @DoInsert	
			);
	
	IF @CountCMAmount > 0
	BEGIN
		SELECT 'Error' = 'Overlapping effective dates.';
		RETURN;
	END;


	BEGIN TRANSACTION;

	BEGIN TRY
		INSERT INTO [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT]
			([CHARGE_MASTER_ID], [CHARGE_AMOUNT], [EFFECTIVE_DATE], [EXPIRATION_DATE])
		VALUES
			(@ChargeMasterId, @Amount, @DoInsert, @DoExpire);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		SELECT 'Error' = 'Insert exception: ' + CAST( ERROR_NUMBER() AS VARCHAR(50)) + ' : ' + CAST( ERROR_MESSAGE() AS VARCHAR(5000));
		ROLLBACK TRANSACTION;
		RETURN;
	END CATCH;

	SELECT 'Success' = 'SUCCESS';

END
GO	

