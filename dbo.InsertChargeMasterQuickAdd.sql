SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChargeMasterQuickAdd]
      @SaId INT
	, @Uid INT
	, @CptCode VARCHAR(5)
	, @BillingCode VARCHAR(20)
	, @Description VARCHAR(100)
	, @CMCategoryId INT 
	, @CMDepartmentId INT
	, @CMUsageCode INT
	, @PatientClassId INT
	, @EffectiveDate DATETIME = NULL
	, @ExpirationDate DATETIME= NULL
AS
BEGIN

	IF @SaId IS NULL OR @SaId <= 0
	BEGIN
		PRINT('Service Agreement Id is Invalid');
		RETURN -1;
	END;
	
	IF @Uid IS NULL OR @Uid <= 0
	BEGIN
		PRINT('User Profile Id is Invalid');
		RETURN -1;
	END;
	
	IF @EffectiveDate IS NULL
	BEGIN
		PRINT('Effective Date is Invalid');
		RETURN -3;
	END;

	IF @ExpirationDate IS NULL
	BEGIN
		PRINT('Expiration Date is Invalid');
		RETURN -4;
	END;
	

	DECLARE @DOS DATETIME = GETDATE();

	INSERT INTO [dbo].[CHARGE_MASTER]
		(	 
			 [SERVICE_AGREEMENT_ID]
			,[CPT_CODE]
            ,[BILLING_CODE]
            ,[DESCRIPTION]
            ,[CHARGE_MASTER_CATEGORY_ID]
            ,[CHARGE_MASTER_DEPT_ID]
            ,[CHARGE_MASTER_USAGE_CODE]
            ,[PATIENT_CLASS_ID]
            ,[EFFECTIVE_DATE]
            ,[EXPIRATION_DATE]
            ,[CREATION_DATE_TIME]
            ,[CREATING_USER_PROFILE_ID]
            ,[CHANGED_DATE_TIME]
            ,[CHANGING_USER_PROFILE_ID]
		)
	VALUES
		(
			 @SaId
			,@CptCode
            ,@BillingCode
            ,@Description
            ,@CMCategoryId
            ,@CMDepartmentId
            ,@CMUsageCode
            ,@PatientClassId
            ,@EffectiveDate
            ,@ExpirationDate
            ,@DOS
            ,@Uid
            ,@DOS
            ,@Uid
		)
		
	PRINT('CM Insert complete for ' + CAST(@SaId AS VARCHAR(32))+ ' : ' + @CptCode + ' : ' + + @BillingCode + ' : ' + @Description);
	RETURN SCOPE_IDENTITY();
END
GO
