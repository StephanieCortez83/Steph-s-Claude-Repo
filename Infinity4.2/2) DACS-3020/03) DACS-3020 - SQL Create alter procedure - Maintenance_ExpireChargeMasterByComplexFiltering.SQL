----------------------------------------
-- 03) DACS-3020 - SQL Create alter procedure - Maintenance_ExpireChargeMasterByComplexFiltering.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
      @SAId INT
	, @ExpireDate DATETIME = NULL
    , @ChargeMasterId INT = NULL
	, @CptCode VARCHAR(5) = NULL
    , @BillingCode VARCHAR(20) = NULL
    , @Description VARCHAR(100) = NULL
    , @CategoryId INT = NULL
    , @DepartmentId INT = NULL
    , @UsageCodeId INT = NULL
    , @PatientClassId INT = NULL
	, @TestMode BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @ExpireDate IS NULL
	BEGIN
		SET @ExpireDate = GETDATE();
	END;
	
	-- fill our temp table with all the CM Ids for the service agreement and prune that based on filtering
	DECLARE @tempCMIds TABLE 
	( 
		  CMId INT
		, SAId INT
		, ExpireDate DATETIME
		, CptCode VARCHAR(5)
		, BillingCode VARCHAR(20)
		, Description VARCHAR(100)
		, CategoryId INT
		, DepartmentId INT
		, UsageCodeId INT
		, PatientClassId INT
	);

	INSERT @tempCMIds(CMId,SAId,ExpireDate,CptCode,BillingCode,Description,CategoryId,DepartmentId,UsageCodeId,PatientClassId)
		SELECT 
			  CHARGE_MASTER_ID
			, SERVICE_AGREEMENT_ID
			, EXPIRATION_DATE
			, CPT_CODE
			, BILLING_CODE
			, [DESCRIPTION]
			, CHARGE_MASTER_CATEGORY_ID
			, CHARGE_MASTER_DEPT_ID
			, CHARGE_MASTER_USAGE_CODE
			, PATIENT_CLASS_ID
		FROM 
			[dbo].[CHARGE_MASTER]
		WHERE 
			SERVICE_AGREEMENT_ID = @SAId
			AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate)
	
	DECLARE @countCM INT = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('@SAId = ' + CAST(@SAId AS varchar(20)));
	PRINT('@ExpireDate = ' + CAST(@ExpireDate AS varchar(40)));
	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @msg VARCHAR(2000);  

	IF @countCM <= 0
	BEGIN
		SET @msg = '0 :: No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) + ', @ExpireDate = ' + CAST(@ExpireDate AS varchar(40));
		PRINT(@msg);
		SELECT 'Results' = @msg;
		RETURN;
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;
	
	DECLARE @ProcessingFields VARCHAR(1000) = '@SAId = ' + CAST(@SAId AS varchar(20)) + ', @ExpireDate = ' + CAST(@ExpireDate AS varchar(40));
	
	IF @ChargeMasterId IS NOT NULL AND @ChargeMasterId > 0
	BEGIN
		SET @ProcessingFields = (@ProcessingFields + ', ChargeMasterId = ' + CAST(@ChargeMasterId AS VARCHAR(30))) 
		DELETE FROM @tempCMIds WHERE CMId <> @ChargeMasterId;
	END
	ELSE
	BEGIN
		IF @CptCode IS NOT NULL AND LEN(@CptCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CptCode = ' + @CptCode + '%') 
			-- DELETE FROM @tempCMIds WHERE CptCode <> @CptCode;
			DELETE FROM @tempCMIds WHERE CptCode NOT LIKE (@CptCode + '%');
		END;
	
		IF @BillingCode IS NOT NULL AND LEN(@BillingCode) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', BillingCode = ' + @BillingCode) 
			-- DELETE FROM @tempCMIds WHERE BillingCode <> @BillingCode;
			DELETE FROM @tempCMIds WHERE BillingCode NOT LIKE (@BillingCode + '%');
		END;
	
		IF @Description IS NOT NULL AND LEN(@Description) > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', Description = %' + @Description + '%') 
			-- DELETE FROM @tempCMIds WHERE [Description] <> @Description;
			DELETE FROM @tempCMIds WHERE [Description] NOT LIKE ('%' + @Description + '%');
		END;

		IF @CategoryId IS NOT NULL AND @CategoryId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', CategoryId = ' + CAST(@CategoryId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE CategoryId <> @CategoryId;
		END

		IF @DepartmentId IS NOT NULL AND @DepartmentId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', DepartmentId = ' + CAST(@DepartmentId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE DepartmentId <> @DepartmentId;
		END

		IF @UsageCodeId IS NOT NULL AND @UsageCodeId >= 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', UsageCodeId = ' + CAST(@UsageCodeId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE UsageCodeId <> @UsageCodeId;
		END

		IF @PatientClassId IS NOT NULL AND @PatientClassId > 0
		BEGIN
			SET @ProcessingFields = (@ProcessingFields + ', PatientClassId = ' + CAST(@PatientClassId AS VARCHAR(30))) 
			DELETE FROM @tempCMIds WHERE PatientClassId <> @PatientClassId;
		END
	END;
	
	-- IF @TestMode = 1
	-- 	SELECT * FROM @tempCMIds;

	SET @countCM = (SELECT COUNT(*) FROM @tempCMIds);

	PRINT('Processing Filters = ' + @ProcessingFields);
	PRINT('Processing @countCM  = ' + CAST(@countCM AS varchar(20)));

	DECLARE @tempResults TABLE ( Value VARCHAR(2000) );

	INSERT @tempResults(Value)
		SELECT  
			'CM: ' + CAST(CMId AS VARCHAR(30)) + ', ' +
			CptCode + ', ' +
			BillingCode + ', ' +
			Description AS [Value]
		FROM 
			@tempCMIds
			
	IF @TestMode = 1
	BEGIN
		PRINT('------------------------------------------');
		PRINT('       TESTMODE - EXITING WITHOUT PROCESSING');
		PRINT('------------------------------------------');
		SET @msg = '0 :: TEST MODE EXIT.  No Charge Master Records to process.  # would have processed: ' + CAST(@countCM AS varchar(40)) + ' :: filters = ' + @ProcessingFields;
		PRINT(@msg);
		INSERT INTO @tempResults (Value) VALUES (@msg);
		SELECT TOP 2000 * FROM @tempResults;
		RETURN;
	END;
	
	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		UPDATE CHARGE_MASTER 
			SET EXPIRATION_DATE = @ExpireDate
		WHERE SERVICE_AGREEMENT_ID = @SAId 
			AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate) 
			AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds);
		
		SET @countCM = 
			(
				SELECT COUNT(*) 
				FROM CHARGE_MASTER 
				WHERE SERVICE_AGREEMENT_ID = @SAId 
					AND EXPIRATION_DATE = @ExpireDate 
					AND [CHARGE_MASTER_ID] IN (SELECT DISTINCT CMId FROM @tempCMIds));
					
		PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	SET @msg = CAST(@countCM AS VARCHAR(30)) + ' :: Filters = ' + @ProcessingFields;
	--SELECT 'Results' = @msg;
	INSERT INTO @tempResults (Value) VALUES (@msg);
	SELECT TOP 2000 * FROM @tempResults;
END

GO

/*
Testing:
begin tran;
exec [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
      @SAId = 440
	, @ExpireDate = '04-01-2024'
	, @TestMode = 1
    --, @ChargeMasterId = 12345
	, @CptCode = 'A4223'
    --, @BillingCode = '1234567'
    , @Description = 'IV TUBING PRIMARY'
    , @CategoryId = 25460
    , @DepartmentId = 2509
    --, @UsageCodeId = 1
    , @PatientClassId = -1
	
rollback tran;
commit tran;

exec [dbo].[Maintenance_ExpireChargeMasterByComplexFiltering]
                          @SAId = 597
	                    , @ExpireDate = '12/12/2024'
                        , @ChargeMasterId = NULL
	                    , @CptCode = ''
                        , @BillingCode = ''
                        , @Description = 'eye'
                        , @CategoryId = NULL
                        , @DepartmentId = NULL
                        , @UsageCodeId = NULL
                        , @PatientClassId = NULL
                        , @TestMode = 1
                        ;
*/
