USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcProcModifierBySaIdAndProcId].sql

----------------------------------------
-- 01) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcProcModifierBySaIdAndProcId].sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysSvcProcModifierBySaIdAndProcId]
    @SAId INT,
    @ProcId INT
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		[MODIFIER]
	FROM 
		[dbo].[PHYSICIAN_SERVICE_PROCEDURE]
	WHERE
		[SERVICE_AGREEMENT_ID] = @SAId
		AND [PHYSICIAN_SERVICE_PROC_ID] = @ProcId;

END
GO


-- End of 01) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcProcModifierBySaIdAndProcId].sql
GO

-- Start of 02) DACS-645 - Create Table - [dbo].[PhysicianServiceEvalDiagnosis].sql

----------------------------------------
-- 02) DACS-645 - Create Table - [dbo].[PhysicianServiceEvalDiagnosis].sql
----------------------------------------
GO

GO

GO

CREATE TABLE [dbo].[PhysicianServiceEvalDiagnosis](
	[PhysicianServiceEvalDiagnosisId] [int] IDENTITY(1,1) NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartId] [int] NOT NULL,
	[PhysicianServiceLevelNumber] [int] NOT NULL,
	[PhysicianServiceProcId] [int] NOT NULL,
	[CptCode] VARCHAR(10) NOT NULL,
	[Icd10Codes] VARCHAR(128) NOT NULL, -- can be comma delimited list
	[Modifiers] VARCHAR(128) NOT NULL, -- can be comma delimited list
	[DateOfService] DATETIME NULL,
 CONSTRAINT [PK_PhysicianServiceEvalDiagnosis] PRIMARY KEY CLUSTERED 
(
	[PhysicianServiceEvalDiagnosisId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[PhysicianServiceEvalDiagnosis] ADD  CONSTRAINT [DF_PhysicianServiceEvalDiagnosis_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[PhysicianServiceEvalDiagnosis] ADD  CONSTRAINT [DF_PhysicianServiceEvalDiagnosis_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO


-- End of 02) DACS-645 - Create Table - [dbo].[PhysicianServiceEvalDiagnosis].sql
GO

-- Start of 03) DACS-645 - Create Stored Procedure - [dbo].[ModifyPhySvcDiagnosisCode].sql

----------------------------------------
-- 03) DACS-645 - Create Stored Procedure - [dbo].[ModifyPhySvcDiagnosisCode].sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[ModifyPhySvcDiagnosisCode]
	@ChartId INT,
	@PhysicianServiceProcId INT,
	@LevelNumber INT,
	@UserProfileId INT,
	@CptCode VARCHAR(10),
	@Icd10Code VARCHAR(128),
	@Modifiers VARCHAR(128),
	@DOS DATETIME
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- check the input variables
	IF 	@ChartId <= 0
	BEGIN
		SELECT 'Result' = -1
		RETURN;
	END;
	
	IF 	@PhysicianServiceProcId <= 0
	BEGIN
		SELECT 'Result' = -2
		RETURN;
	END;
	
	IF 	@LevelNumber <= 0
	BEGIN
		SELECT 'Result' = -3
		RETURN;
	END;
	
	IF 	@UserProfileId <= 0
	BEGIN
		SELECT 'Result' = -4
		RETURN;
	END;

	IF 	@CptCode IS NULL OR @CptCode = ''
	BEGIN
		SELECT 'Result' = -5
		RETURN;
	END;

	IF 	@DOS < DATEADD(yyyy, -100 , GETDATE())
	BEGIN
		SELECT 'Result' = -6
		RETURN;
	END;

	IF @Icd10Code IS NULL
		SET @Icd10Code = '';

	IF @Modifiers IS NULL
		SET @Modifiers = '';
	
	-- search index group fields = [ChartId], [PhysicianServiceProcId], [PhysicianServiceLevelNumber], [DateOfService], [CptCode]
	
	-- see if we already have an entry
	DECLARE @FoundProcId INT = (SELECT 
									[PhysicianServiceEvalDiagnosisId] 
								FROM 
									[dbo].[PhysicianServiceEvalDiagnosis]
								WHERE	
									[ChartId] = @ChartId
									AND [PhysicianServiceProcId] = @PhysicianServiceProcId
									AND [PhysicianServiceLevelNumber] = @LevelNumber
									AND [DateOfService] = @DOS
									AND [CptCode] = @CptCode);
	
	IF @FoundProcId IS NOT NULL -- if already have an entry, do an UPDATE
	BEGIN
		UPDATE [dbo].[PhysicianServiceEvalDiagnosis]
			SET 
				  [DateTimeLastUpdated] = GETDATE()
				, [Icd10Codes] = @Icd10Code
				, [Modifiers] = @Modifiers
		WHERE
			[ChartId] = @ChartId
			AND [PhysicianServiceProcId] = @PhysicianServiceProcId
			AND [PhysicianServiceLevelNumber] = @LevelNumber
			AND [DateOfService] = @DOS
			AND [CptCode] = @CptCode;
	END
	ELSE -- if not already existing entry do an insert.
	BEGIN
		INSERT INTO [dbo].[PhysicianServiceEvalDiagnosis]
			([CreatedByUserProfileId],[LastUpdatedByUserProfileId],[ChartId],[PhysicianServiceLevelNumber],[PhysicianServiceProcId],[CptCode],[Icd10Codes],[Modifiers],[DateOfService])
		VALUES
			(@UserProfileId,@UserProfileId,@ChartId,@LevelNumber,@PhysicianServiceProcId,@CptCode,@Icd10Code,@Modifiers,@DOS);
	END;

	--Send result:
	SELECT 
		COUNT(PhysicianServiceEvalDiagnosisId) 
	FROM 
		[dbo].[PhysicianServiceEvalDiagnosis]
	WHERE	
		[ChartId] = @ChartId
		AND [PhysicianServiceLevelNumber] = @LevelNumber
		AND [PhysicianServiceProcId] = @PhysicianServiceProcId
		AND [DateOfService] = @DOS
		AND [CptCode] = @CptCode;
	
END
GO


-- End of 03) DACS-645 - Create Stored Procedure - [dbo].[ModifyPhySvcDiagnosisCode].sql
GO

-- Start of 04) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcEvalDiagModifierByChartIdAndProcIdAndLevelAndDos].sql

----------------------------------------
-- 04) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcEvalDiagModifierByChartIdAndProcIdAndLevelAndDos].sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysSvcEvalDiagModifierByChartIdAndProcIdAndLevelAndDos]
    @ChartId INT,
    @ProcId INT,
	@LevelNumber INT,
	@DateOfService DATETIME
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		[Modifiers]
	FROM 
		[dbo].[PhysicianServiceEvalDiagnosis]
	WHERE
		[ChartId] = @ChartId
		AND [PhysicianServiceProcId] = @ProcId
		AND [PhysicianServiceLevelNumber] = @LevelNumber
		AND [DateOfService] = @DateOfService;

END
GO


-- End of 04) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcEvalDiagModifierByChartIdAndProcIdAndLevelAndDos].sql
GO

-- Start of 05) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcEvalDiagIcd10ByChartIdAndProcIdAndLevelAndDos].sql

----------------------------------------
-- 05) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcEvalDiagIcd10ByChartIdAndProcIdAndLevelAndDos].sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysSvcEvalDiagIcd10ByChartIdAndProcIdAndLevelAndDos]
    @ChartId INT,
    @ProcId INT,
	@LevelNumber INT,
	@DateOfService DATETIME
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		[Icd10Codes]
	FROM 
		[dbo].[PhysicianServiceEvalDiagnosis]
	WHERE
		[ChartId] = @ChartId
		AND [PhysicianServiceProcId] = @ProcId
		AND [PhysicianServiceLevelNumber] = @LevelNumber
		AND [DateOfService] = @DateOfService;

END
GO
-- End of 05) DACS-645 - Create Stored Procedure - [dbo].[SelectPhysSvcEvalDiagIcd10ByChartIdAndProcIdAndLevelAndDos].sql
GO

-- Start of 06) DACS-645 - Alter Table - Add unique constraint and Index to [dbo].[PhysicianServiceEvalDiagnosis].sql

----------------------------------------
-- 06) DACS-645 - Alter Table - Add unique constraint and Index to [dbo].[PhysicianServiceEvalDiagnosis].sql
----------------------------------------
GO

-- index group fields = [ChartId], [PhysicianServiceProcId], [PhysicianServiceLevelNumber], [DateOfService], [CptCode]
ALTER TABLE [RevCycleDB].[dbo].[PhysicianServiceEvalDiagnosis] 
	ADD CONSTRAINT UNQ_PhysicianServiceEvalDiagnosis  
       UNIQUE  
       ( 
		     [ChartId]
		   , [PhysicianServiceProcId]
		   , [PhysicianServiceLevelNumber]
		   , [DateOfService]
		   , [CptCode]
	   );
	   
GO

CREATE INDEX ix_PhysicianServiceEvalDiagnosis_CidPspIdPslnDosCpt  
	ON [RevCycleDB].[dbo].[PhysicianServiceEvalDiagnosis] 
		(	
			 [ChartId]
		   , [PhysicianServiceProcId]
		   , [PhysicianServiceLevelNumber]
		   , [DateOfService]
		   , [CptCode]
		)		 
		ON FGIndex1;

GO
-- End of 06) DACS-645 - Alter Table - Add unique constraint and Index to [dbo].[PhysicianServiceEvalDiagnosis].sql
GO

-- Start of 01) DACS-1153 - Alter Stored Procedure - [dbo].[SelectChargeMasterModifierBySaIdAndCmIdAndModifier].sql

----------------------------------------
-- 01) DACS-1153 - Alter Stored Procedure - [dbo].[SelectChargeMasterModifierBySaIdAndCmIdAndModifier].sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterModifierBySaIdAndCmIdAndModifier]
    @ServiceAgreementId INT, 
    @ChargeMasterId INT, 
	@Modifier VARCHAR(20)
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		[BILLING_CODE]
    FROM 
		[dbo].[CHARGE_MASTER_MODIFIER]
    WHERE 
		[SERVICE_AGREEMENT_ID]= @ServiceAgreementId
        AND [CHARGE_MASTER_ID]= @ChargeMasterId
        AND [MODIFIER]= @Modifier;

END
GO


-- End of 01) DACS-1153 - Alter Stored Procedure - [dbo].[SelectChargeMasterModifierBySaIdAndCmIdAndModifier].sql
GO

-- Start of 02) DACS-1153 - Alter Stored Procedure - [dbo].[SelectChargeMasterModifierBySaIdAndBillingCodeAssigned].sql

----------------------------------------
-- 02) DACS-1153 - Alter Stored Procedure - [dbo].[SelectChargeMasterModifierBySaIdAndBillingCodeAssigned].sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterModifierBySaIdAndBillingCodeAssigned]
    @ServiceAgreementId INT
	
AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
	SELECT 
       [CHARGE_MASTER_ID]
      ,[MODIFIER]
	FROM 
		[RevCycleDB].[dbo].[CHARGE_MASTER_MODIFIER]
    WHERE 
		[SERVICE_AGREEMENT_ID]= @ServiceAgreementId
		AND ([BILLING_CODE] IS NOT NULL AND [BILLING_CODE] <> '');

END
GO


-- End of 02) DACS-1153 - Alter Stored Procedure - [dbo].[SelectChargeMasterModifierBySaIdAndBillingCodeAssigned].sql
GO

-- Start of 01) DACS-2571_Drop_NextGen_Synonyms.sql

---------------------------------------------------------------
/*
DACS-2571:      Deprecate NextGen Funcitonality
Description:    This script drops the synonymsbelow that is
                used by NextGen code:

                report_NG_UnmappedPayers 
                usp_R_NextGen_DFT_Errors
                usp_R_NEXTGEN_Insurances
                usp_R_NextGen_RCM_Clients
                usp_R_NextGen_RCM_Hospitals
                usp_R_RCM_Hospital_Insurances
                usp_U_Client_Facility_Insurance_NextGen_Key
                usp_U_Reprocess_Void_NextGen_DFT_Error

*/
---------------------------------------------------------------



IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'report_NG_UnmappedPayers')
BEGIN
    DROP SYNONYM report_NG_UnmappedPayers;
    PRINT 'Synonym [report_NG_UnmappedPayers] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_NextGen_DFT_Errors')
BEGIN
    DROP SYNONYM usp_R_NextGen_DFT_Errors;
    PRINT 'Synonym [usp_R_NextGen_DFT_Errors] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_NEXTGEN_Insurances')
BEGIN
    DROP SYNONYM usp_R_NEXTGEN_Insurances;
    PRINT 'Synonym [usp_R_NEXTGEN_Insurances] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_NextGen_RCM_Clients')
BEGIN
    DROP SYNONYM usp_R_NextGen_RCM_Clients;
    PRINT 'Synonym [usp_R_NextGen_RCM_Clients] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_NextGen_RCM_Hospitals')
BEGIN
    DROP SYNONYM usp_R_NextGen_RCM_Hospitals;
    PRINT 'Synonym [usp_R_NextGen_RCM_Hospitals] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_R_RCM_Hospital_Insurances')
BEGIN
    DROP SYNONYM usp_R_RCM_Hospital_Insurances;
    PRINT 'Synonym [usp_R_RCM_Hospital_Insurances] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_U_Client_Facility_Insurance_NextGen_Key')
BEGIN
    DROP SYNONYM usp_U_Client_Facility_Insurance_NextGen_Key;
    PRINT 'Synonym [usp_U_Client_Facility_Insurance_NextGen_Key] has been dropped.';
END

IF EXISTS (SELECT * FROM sys.synonyms WHERE name = 'usp_U_Reprocess_Void_NextGen_DFT_Error')
BEGIN
    DROP SYNONYM usp_U_Reprocess_Void_NextGen_DFT_Error;
    PRINT 'Synonym [usp_U_Reprocess_Void_NextGen_DFT_Error] has been dropped.';
END


-- End of 01) DACS-2571_Drop_NextGen_Synonyms.sql
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
