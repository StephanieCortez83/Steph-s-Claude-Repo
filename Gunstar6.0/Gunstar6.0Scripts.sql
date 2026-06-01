USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 1) DACS-2370 INSERT LOG_NOTE_CATEGORY.sql

GO

INSERT INTO [dbo].[LOG_NOTE_CATEGORY]
           ([LOG_NOTE_CATEGORY_ID]
           ,[SYSTEM_DEFINED]
           ,[DESCRIPTION])
     VALUES
           (36,
           'Y'
           ,'Infusions/Injections completed.')
GO


-- End of 1) DACS-2370 INSERT LOG_NOTE_CATEGORY.sql
GO

-- Start of 01) DACS-1591 - Add 'Service Agreement Enable Import Export' User Right and Groups.sql

----------------------------------------
-- 01) DACS-1591 - Add 'Service Agreement Enable Import Export' User Right and Groups.sql
----------------------------------------
GO

----------------------------------------
-- Step 1)  Get the needed variables in order to perform the task
----------------------------------------
DECLARE	@DEFINED_RIGHT_ID int =						161;  -- DEFINED_RIGHT_ID to be created
DECLARE	@DEFINED_RIGHT_NAME varchar(50) =			'Service Agreement Enable Import Export';
DECLARE	@DEFINED_RIGHT_DEFINITION varchar(2000) =	NULL;  -- If null, the stored procedure will use the @DEFINED_RIGHT_NAME value
DECLARE	@CREATING_USER_ID int =						10149; -- Marcus Ferrell
DECLARE @USER_GROUP_NAME varchar(35) =				'Service Agreement Enable Import Export';

DECLARE	@DEFINED_RIGHT_RESULT_ID int;
DECLARE	@USER_GROUP_RESULT_ID int;
DECLARE	@GROUP_RIGHT_RESULT_ID int;


----------------------------------------
-- Step 2)  Create the DEFINED_RIGHT table entry
----------------------------------------
exec [dbo].[DEFINED_RIGHT_QUALIFY_INSERT]
	 @DEFINED_RIGHT_ID =				@DEFINED_RIGHT_ID
	,@DEFINED_RIGHT_NAME =				@DEFINED_RIGHT_NAME
	,@DEFINED_RIGHT_DEFINITION =		@DEFINED_RIGHT_DEFINITION
	,@DEFINED_RIGHT_CREATING_USER_ID =	@CREATING_USER_ID
	,@DEFINED_RIGHT_RESULT_ID =			@DEFINED_RIGHT_RESULT_ID OUTPUT;

--PRINT('DRTI_ID = ' + CAST(@DEFINED_RIGHT_RESULT_ID as VARCHAR(32)));


----------------------------------------
-- Step 3)  Create the associated USER_GROUP and GROUP_RIGHTS table entries
----------------------------------------
exec [dbo].[LINK_DEFINED_RIGHT_TO_USER_GROUP_NAME_AND_GROUP_RIGHTS_QUALIFY_INSERT]
	 @DEFINED_RIGHT_ID =	@DEFINED_RIGHT_RESULT_ID
	,@USER_GROUP_NAME =		@USER_GROUP_NAME
	,@CREATING_USER_ID =	@CREATING_USER_ID
	,@USER_GROUP_ID =		@USER_GROUP_RESULT_ID OUTPUT
	,@GROUP_RIGHTS_ID =		@GROUP_RIGHT_RESULT_ID OUTPUT

--PRINT('LDRTUGNAGRTI_UG_ID = ' + CAST(@USER_GROUP_RESULT_ID as VARCHAR(32)));
--PRINT('LDRTUGNAGRTI_GR_ID = ' + CAST(@GROUP_RIGHT_RESULT_ID as VARCHAR(32)));

-- End of 01) DACS-1591 - Add 'Service Agreement Enable Import Export' User Right and Groups.sql
GO

-- Start of 02) DACS-1591 - Create procedure - [dbo].[ExpireChargeMasterAndChargeAmountBySAIdAndCmId].SQL

------------------------------------------------------------------------------
-- 02) DACS-1591 - Create procedure - [dbo].[ExpireChargeMasterAndChargeAmountBySAIdAndCmId].SQL
------------------------------------------------------------------------------
GO

GO

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


-- End of 02) DACS-1591 - Create procedure - [dbo].[ExpireChargeMasterAndChargeAmountBySAIdAndCmId].SQL
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
