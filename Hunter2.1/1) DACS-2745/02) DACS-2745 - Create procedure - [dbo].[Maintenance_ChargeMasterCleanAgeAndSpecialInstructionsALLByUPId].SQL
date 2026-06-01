---------------------------------------------------------------------
-- 02) DACS-2745 - Create procedure - [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsALLByUPId].SQL
---------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_ChargeMasterCleanAgeAndSpecialInstructionsALLByUPId]
      @UPId INT					-- User Profile Id for this actions
AS
BEGIN

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
		OR ([AGE_MINIMUM] = 0 AND [AGE_MAXIMUM] = 11988);

	UPDATE [dbo].[CHARGE_MASTER]
		SET   [SPECIAL_HANDLING_INSTRUCTIONS] = NULL
			, [CHANGED_DATE_TIME] = GETDATE()
			, [CHANGING_USER_PROFILE_ID] = @UPId
	WHERE 
		[SPECIAL_HANDLING_INSTRUCTIONS] = 'FALSE';
		
	SELECT 'Result' = 'SUCCESS: Completed';

END
GO





