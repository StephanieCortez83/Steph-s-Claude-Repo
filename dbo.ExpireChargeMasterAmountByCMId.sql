SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE     PROCEDURE [dbo].[ExpireChargeMasterAmountByCMId]
	  @CMId INT
	, @DateOfService DATETIME
AS

	IF @CMId IS NULL OR @CMId <= 0
	BEGIN
		SELECT 'Error' = 'Charge Master Id is invalid';
		RETURN;
	END;

	IF @DateOfService IS NULL OR @DateOfService < '01-01-1900'
	BEGIN
		SELECT @DateOfService = CAST(GETDATE() AS DATE)
		RETURN;
	END;

	DECLARE @DoExpire DATETIME = DATEADD(ss,-1,@DateOfService);
	
	PRINT('@CMId = ' + CAST(@CMId AS VARCHAR(20)));
	PRINT('@DateOfService = ' + CAST(@DateOfService AS VARCHAR(50)));
	PRINT('@DoExpire = ' + CAST(@DoExpire AS VARCHAR(50)));

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- check for an active match for our present cmid
	DECLARE @FoundMatch INT = (
		SELECT COUNT([charge_master_id]) FROM [CHARGE_MASTER_CHARGE_AMOUNT] 
		WHERE [charge_master_id]= @CMId 
			AND [EFFECTIVE_DATE] <= @DateOfService AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @DateOfService)
		);
	
	IF @FoundMatch <= 0 
	BEGIN
		SELECT 'Success' = 'Success: no active CMCA match found.';
		RETURN;
	END;

	PRINT('@FoundMatch = ' + CAST(@FoundMatch AS VARCHAR(50)));

	UPDATE [RevCycleDB].[dbo].[CHARGE_MASTER_CHARGE_AMOUNT]
		SET 
		  [EXPIRATION_DATE] = IIF([EFFECTIVE_DATE] < @DoExpire, @DoExpire, [EFFECTIVE_DATE])
	WHERE 
		[CHARGE_MASTER_ID] = @CMId
		AND [EFFECTIVE_DATE] <= @DateOfService AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @DateOfService);

	SET @FoundMatch = (
		SELECT COUNT([charge_master_id]) FROM [CHARGE_MASTER_CHARGE_AMOUNT] 
		WHERE [charge_master_id]= @CMId
			AND [EFFECTIVE_DATE] <= @DateOfService AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @DateOfService)
		);
	
	IF @FoundMatch <= 0 
	BEGIN
		SELECT 'Success' = 'Success: expired all CMCA matches found.';
		RETURN;
	END;

	SELECT 'Error' = 'CMCA expiration failed.';

GO
