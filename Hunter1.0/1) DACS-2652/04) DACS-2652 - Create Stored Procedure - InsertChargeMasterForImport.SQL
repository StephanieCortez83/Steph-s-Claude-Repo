---------------------------------------------------------------------------------
-- 04) DACS-2652 - Create Stored Procedure - InsertChargeMasterForImport.SQL
---------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[InsertChargeMasterForImport]
      @SaId INT					-- Service Agreement affected by this stored procedure
	, @Uid INT = 10149 			-- User performing action.  Marcus Ferrel
	, @CMCategoryId INT 
	, @Description VARCHAR(100)
	, @CptCode VARCHAR(5)
	, @BillingCode VARCHAR(20)
	, @ModifierRequired BIT
	, @CMDeptartmentId INT
	, @CMUsageCode INT
	, @EffectiveDate DATETIME = NULL
	, @ExpirationDate DATETIME= NULL
	, @DisplaySeq INT
	, @LongDescription VARCHAR(1100)
	, @MaxQuantity INT
	, @PatientClassId INT
	, @AliasBillingCode VARCHAR(20)
	, @BypassAutoApproval BIT
	, @ObsPatientArrivalSourceId INT
	, @ObsHourTypeId INT
	, @ObsTelemetry BIT
	, @AllowNegativeUnitsInd BIT
	, @SpecialHandlingInstructions VARCHAR(2000)
	, @AgeMinimum INT
	, @AgeMaximum INT
AS
BEGIN

	IF @SaId IS NULL OR @SaId <= 0
	BEGIN
		SELECT 'Error' = -2 ,'Message' = 'Service Agreement Id is Invalid';
		RETURN;
	END;
	
	IF @Uid IS NULL OR @Uid <= 0
	BEGIN
		SELECT 'Error' = -3 ,'Message' = 'User Profile Id is Invalid';
		RETURN;
	END;
	
	IF @EffectiveDate IS NULL
		SET @EffectiveDate = GETDATE();

	IF @ExpirationDate IS NULL
		SET @ExpirationDate = DATEADD(yy,100,@EffectiveDate);
	

	DECLARE @DOS DATETIME = GETDATE();

	INSERT INTO [dbo].[CHARGE_MASTER]
		(	 
			 [SERVICE_AGREEMENT_ID]
            ,[CHARGE_MASTER_CATEGORY_ID]
            ,[DESCRIPTION]
			,[CPT_CODE]
            ,[BILLING_CODE]
            ,[MODIFIER_REQUIRED]
            ,[CHARGE_MASTER_DEPT_ID]
            ,[CHARGE_MASTER_USAGE_CODE]
            ,[EFFECTIVE_DATE]
            ,[EXPIRATION_DATE]
            ,[DISPLAY_SEQ]
            ,[LONG_DESCRIPTION]
            ,[MAX_QUANTITY]
            ,[PATIENT_CLASS_ID]
            ,[ALIAS_BILLING_CODE]
            ,[CREATION_DATE_TIME]
            ,[CREATING_USER_PROFILE_ID]
            ,[CHANGED_DATE_TIME]
            ,[CHANGING_USER_PROFILE_ID]
            ,[BYPASS_AUTO_APPROVAL]
            ,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
            ,[OBSERVATION_HOUR_TYPE_ID]
            ,[OBSERVATION_TELEMETRY]
            ,[ALLOW_NEGATIVE_UNITS_IND]
            ,[SPECIAL_HANDLING_INSTRUCTIONS]
            ,[AGE_MINIMUM]
            ,[AGE_MAXIMUM]
		)
	VALUES
		(
			 @SaId
            ,@CMCategoryId
            ,@Description
			,@CptCode
            ,@BillingCode
            ,@ModifierRequired
            ,@CMDeptartmentId
            ,@CMUsageCode
            ,@EffectiveDate
            ,@ExpirationDate
            ,@DisplaySeq
            ,@LongDescription
            ,@MaxQuantity
            ,@PatientClassId
            ,@AliasBillingCode
            ,@DOS
            ,@Uid
            ,@DOS
            ,@Uid
            ,@BypassAutoApproval
            ,@ObsPatientArrivalSourceId
            ,@ObsHourTypeId
            ,@ObsTelemetry
            ,@AllowNegativeUnitsInd
            ,@SpecialHandlingInstructions
            ,@AgeMinimum
            ,@AgeMaximum
		)
		
	SELECT SCOPE_IDENTITY()

END
GO	

/*
testing:
BEGIN TRAN;
	exec [dbo].[UpdateChargeMasterModifierBySaidAndCptAndModList] @SaId= 555208 , @CptCode= '0001U', @ModList= 'XA,XB,XC,XD,XE,';
	exec [dbo].[UpdateChargeMasterModifierBySaidAndCptAndModList] @SaId= 555208 , @CptCode= '0002A', @ModList= 'XF,XG,XH,XI,XJ,', @Uid= 12089;
COMMIT TRAN;\
ROLLBACK TRAN;
*/