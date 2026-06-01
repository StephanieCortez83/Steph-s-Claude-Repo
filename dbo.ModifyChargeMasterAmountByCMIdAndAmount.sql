SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ModifyChargeMasterAmountByCMIdAndAmount]
    @ChargeMasterId INT  -- Single Charge Master Id  
    , @Amount money  
    , @EffectiveDate DATETIME = NULL  
    , @ExpirationDate DATETIME = NULL  
AS  
BEGIN  
  
 IF @ChargeMasterId IS NULL OR @ChargeMasterId <= 0  
 BEGIN  
  SELECT 'Error' = 'Error: Charge Master Id is invalid';  
  RETURN 0;  
 END;  
  
 IF @Amount IS NULL OR @Amount < 0.0  
 BEGIN  
  SELECT 'Error' = 'Error: Amount is invalid';  
  RETURN 0;  
 END;  
   
 DECLARE @DoInsert DATE = GETDATE();  
 DECLARE @DoExpire DATE = DATEADD(yy,100,@DoInsert);  
  
 IF @EffectiveDate IS NOT NULL  
  SET @DoInsert = @EffectiveDate;  
  
 IF @ExpirationDate IS NOT NULL  
  SET @DoExpire = @ExpirationDate;  
 ELSE  
  SET @DoExpire = DATEADD(yy,100,@DoInsert);  
  
 DECLARE @DoExpirePrev DATE = DATEADD(day,-1,@DoInsert);  
  
  
  PRINT('@ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(20)));  
  PRINT('@Amount = ' + CAST(@Amount AS VARCHAR(50)));  
  PRINT('@DoInsert = ' + CAST(@DoInsert AS VARCHAR(50)));  
  PRINT('@DoExpirePrev = ' + CAST(@DoExpirePrev AS VARCHAR(50)));  
  PRINT('@DoExpire = ' + CAST(@DoExpire AS VARCHAR(50)));  
  
--------------------------------------------
-- setup resources
--------------------------------------------
 SET NOCOUNT ON  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 
 IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[CHARGE_MASTER] WHERE [CHARGE_MASTER_ID] = @ChargeMasterId)
 BEGIN  
  SELECT 'Error' = 'Error: Charge Master Id NOT found.';  
  RETURN -1;  
 END;  
 
 IF EXISTS(SELECT TOP 1 1 FROM [CHARGE_MASTER_CHARGE_AMOUNT] WHERE [charge_master_id]= @ChargeMasterId AND [CHARGE_AMOUNT]= @Amount AND [EFFECTIVE_DATE] <= @DoInsert AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @DoInsert))  
 BEGIN  
  SELECT 'Error' = 'Error: Active CMCA match found.';  
  RETURN -2;  
 END;  

 IF EXISTS (SELECT TOP 1 1 FROM [CHARGE_MASTER_CHARGE_AMOUNT] WHERE [charge_master_id]= @ChargeMasterId AND [EFFECTIVE_DATE] = @DoInsert OR [EXPIRATION_DATE] = @DoInsert)
 BEGIN  
  SELECT 'Error' = 'Error: Effective period of the charge amount matches the effective period of another charge amount which is not allowed.';  
  RETURN -3;  
 END;  
 
--------------------------------------------
-- pre-test for trigger violation - CREATE TRIGGER [dbo].[ValidateChargeAmount] ON [dbo].[CHARGE_MASTER_CHARGE_AMOUNT]
--------------------------------------------
 DECLARE @MaxDate DATE = '12/31/9999';

 IF EXISTS (
	SELECT TOP 1 1 
	FROM 
		[CHARGE_MASTER_CHARGE_AMOUNT] 
	WHERE 
		[CHARGE_MASTER_ID] = @ChargeMasterId 
		AND (
				(
					@DoInsert >= [EFFECTIVE_DATE]
					AND @DoInsert <= ISNULL([EXPIRATION_DATE], @MaxDate)
				)
				OR (
					ISNULL(@DoExpire, @MaxDate) <= ISNULL([EXPIRATION_DATE], @MaxDate)
					AND ISNULL(@DoExpire, @MaxDate) >= [EFFECTIVE_DATE]
				)
				OR (
					@DoInsert <= [EFFECTIVE_DATE]
					AND ISNULL(@DoExpire, @MaxDate) >= ISNULL([EXPIRATION_DATE], @MaxDate)
				)
			)
 )
 BEGIN  
  SELECT 'Error' = 'Error: Insert/Update Trigger Pre-Test failed.  Check for overlapping effective and expiration dates.';  
  RETURN -4;  
 END;  
 
 IF EXISTS (SELECT TOP 1 1 FROM [CHARGE_MASTER_CHARGE_AMOUNT] WHERE [charge_master_id] = @ChargeMasterId AND [EFFECTIVE_DATE] < @DoInsert AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @DoInsert))
 BEGIN  
  UPDATE [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT]  
   SET [EXPIRATION_DATE] = @DoExpirePrev  
  WHERE   
   [CHARGE_MASTER_ID] = @ChargeMasterId  
   AND [EFFECTIVE_DATE] < @DoInsert  
   AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @DoInsert);  
 END;  
  
 IF EXISTS (SELECT TOP 1 1 FROM [CHARGE_MASTER_CHARGE_AMOUNT] WHERE [charge_master_id] = @ChargeMasterId AND [EFFECTIVE_DATE] < @DoInsert AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @DoInsert))  
 BEGIN  
  SELECT 'Error' = 'Error: CMCA expiration failed.';  
  RETURN -5;  
 END;  
  
 INSERT INTO [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT]  
  ([CHARGE_MASTER_ID], [CHARGE_AMOUNT], [EFFECTIVE_DATE], [EXPIRATION_DATE])  
 VALUES  
  (@ChargeMasterId, @Amount, @DoInsert, @DoExpire);  
  
 SELECT 'Success' = 'SUCCESS';  
 RETURN 0; 
END  
GO
