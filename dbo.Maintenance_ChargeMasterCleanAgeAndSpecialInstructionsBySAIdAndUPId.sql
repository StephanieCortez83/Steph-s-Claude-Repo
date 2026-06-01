SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsBySAIdAndUPId]
        @SaId INT					-- Service Agreement affected by this stored procedure
      , @UPId INT					-- User Profile Id for this actions
AS
BEGIN

	IF @SaId IS NULL OR @SaId <= 0
	BEGIN
		SELECT 'Result' = 'Error: Service Agreement Id is Invalid';
		RETURN;
	END;

	IF @UPId IS NULL OR @UPId <= 0
	BEGIN
		SELECT 'Result' = 'Error: User Profile Id is Invalid';
		RETURN;
	END;


	UPDATE  [dbo].[CHARGE_MASTER]
		SET   [AGE_MINIMUM] = NULL
			, [AGE_MAXIMUM] = NULL
			, [CHANGED_DATE_TIME] = GETDATE()
			, [CHANGING_USER_PROFILE_ID] = @UPId
	WHERE 
		([AGE_MINIMUM] = 0 AND [AGE_MAXIMUM] = 999) 
		OR ([AGE_MINIMUM] = 0 AND [AGE_MAXIMUM] = 11988)
		AND [SERVICE_AGREEMENT_ID] = @SaId;

	UPDATE [dbo].[CHARGE_MASTER]
		SET   [SPECIAL_HANDLING_INSTRUCTIONS] = NULL
			, [CHANGED_DATE_TIME] = GETDATE()
			, [CHANGING_USER_PROFILE_ID] = @UPId
	WHERE 
		[SPECIAL_HANDLING_INSTRUCTIONS] = 'FALSE'
		AND [SERVICE_AGREEMENT_ID] = @SaId;
		
	SELECT 'Result' = 'SUCCESS: Completed';

END
GO
