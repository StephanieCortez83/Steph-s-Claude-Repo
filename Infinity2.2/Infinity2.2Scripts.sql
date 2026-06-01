USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2951 - MDM Verbiage updates 2024.3 - Create SPROC - Maintenance_UpdatePhysicianServiceRiskMessages.sql

----------------------------------------
-- 01) DACS-2951 - MDM Verbiage updates 2024.3 - Create SPROC - Maintenance_UpdatePhysicianServiceRiskMessages.sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_UpdatePhysicianServiceRiskMessages]
     @RiskSearchString varchar(100) 		-- uses a LIKE statement so make sure to format as required
    ,@NewRiskMessage varchar(4000) = ''
	,@BackupPhysicianServiceTable bit = 0
	,@TestMode bit = 0 						-- Just returns first found string
AS
BEGIN
/*
Suggested search statements:
'<b>Minimal%'
'<b>Low%'
'<b>Moderate%'
'<b>High Risk%'
*/

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @BackupPhysicianServiceTable <> 0
	BEGIN
		DECLARE @DestTable varchar(512) = 'PHYSICIAN_SERVICE_BACKUP-';
		SET @DestTable = @DestTable + CAST(datediff(day, '1899-12-30T00:00:00', getdate()) AS varchar(50));
		
		PRINT('Backing up PHYSICIAN_SERVICE Table to @DestTable:' + @DestTable);
		
		exec [dbo].[Maintenance_BackupTable] @SrcTable = 'PHYSICIAN_SERVICE'
			, @DestTable = @DestTable ;
	END;
	
	DECLARE @countFound INT;
		
	PRINT('finding rows with [' + @RiskSearchString + '] to update.');
	SET @countFound = (
		SELECT COUNT(*) FROM [RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
	WHERE 
		[CATEGORY_ID] = 3 AND [SUBCATEGORY_ID] = 3 AND [MINOR_CATEGORY] = 1
		AND [PLAN_ID] = 1 AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = 8 AND ([EFFECTIVE_DATE] <= GETDATE() AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE()))
		AND [DESCRIPTION] LIKE @RiskSearchString
		);

	IF @TestMode <> 0 OR (@NewRiskMessage IS NULL OR LEN(@NewRiskMessage) <= 0)
	BEGIN
		PRINT('Found record count: ' + CAST(@countFound AS varchar(30)));
		
		PRINT('Test Mode Results for [' + @RiskSearchString + ']:');

		SELECT TOP 1 [DESCRIPTION] FROM [RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
		WHERE 
			[CATEGORY_ID] = 3 AND [SUBCATEGORY_ID] = 3 AND [MINOR_CATEGORY] = 1
			AND [PLAN_ID] = 1 AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = 8 AND ([EFFECTIVE_DATE] <= GETDATE() AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE()))
			AND [DESCRIPTION] LIKE @RiskSearchString;
	
		RETURN;
	END;

	IF @countFound > 0
	BEGIN
		PRINT('updating record count: ' + CAST(@countFound AS varchar(30)));
		
		UPDATE [RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
			SET [DESCRIPTION] = @NewRiskMessage
		WHERE 
			[CATEGORY_ID] = 3 AND [SUBCATEGORY_ID] = 3 AND [MINOR_CATEGORY] = 1 
			AND [PLAN_ID] = 1 AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = 8 AND ([EFFECTIVE_DATE] <= GETDATE() AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE()))
			AND [DESCRIPTION] LIKE @RiskSearchString;

		SELECT 'Result' = @countFound;
		RETURN;
	END
	ELSE
	BEGIN
		PRINT('No rows to update for: ' + @RiskSearchString);
	END;

	SELECT 'Result' = 0;
END
GO

/*
Testing:
begin tran;

--exec [dbo].[Maintenance_UpdatePhysicianServiceRiskMessages]
--     @RiskSearchString = '<b>Moderate%'
--	,@BackupPhysicianServiceTable = 1
--	,@TestMode = 1
--    ,@NewRiskMessage = '<b>Moderate</b> risk of morbidity from additional diagnostic testing or treatment.<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Examples only:<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Prescription Drug Management (Prescriptions written at discharge; prescription strength meds administered<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;during encounter - <font color="Red">including those required for a procedure i.e., lidocaine or tetanus</font>, dosage changes, instructions<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;to stop taking prescriptions medication, and prescriptions considered but ultimately not given.<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Decision regarding minor surgery with identified patient or procedure risk factors<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Decision regarding elective major surgery without identified risk factors<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Diagnosis or treatment significantly limited by SDOH. (Food and/or housing insecurities, unemployment,<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;lack of transportation etc.)<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Radiation exposure from CT scan (No Contrast) or Head, Neck, or Torso X-Ray</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Administration of IV Fluids, with or without additives</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Infant OTC Meds</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Acetaminophen (Tylenol) age < 24 months</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Ibuprofen (Motrin) age < 6 months</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Diphenhydramine (Benadryl) age < 6 years</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Rigid Musculoskeletal Immobilization (Custom Splint or Cast)</font><br> '
	
exec [dbo].[Maintenance_UpdatePhysicianServiceRiskMessages]
     @RiskSearchString = '<b>Moderate%'
    ,@NewRiskMessage = '<b>Moderate</b> risk of morbidity from additional diagnostic testing or treatment.<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Examples only:<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Prescription Drug Management (Prescriptions written at discharge; prescription strength meds administered<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;during encounter - <font color="Red">including those required for a procedure i.e., lidocaine or tetanus</font>, dosage changes, instructions<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;to stop taking prescriptions medication, and prescriptions considered but ultimately not given.<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Decision regarding minor surgery with identified patient or procedure risk factors<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Decision regarding elective major surgery without identified risk factors<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Diagnosis or treatment significantly limited by SDOH. (Food and/or housing insecurities, unemployment,<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;lack of transportation etc.)<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Radiation exposure from CT scan (No Contrast) or Head, Neck, or Torso X-Ray</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Administration of IV Fluids, with or without additives</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Infant OTC Meds</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Acetaminophen (Tylenol) age < 24 months</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Ibuprofen (Motrin) age < 6 months</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Diphenhydramine (Benadryl) age < 6 years</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Rigid Musculoskeletal Immobilization (Custom Splint or Cast)</font><br> '

exec [dbo].[Maintenance_UpdatePhysicianServiceRiskMessages]
     @RiskSearchString = '<b>Moderate%'
	,@TestMode = 1
    ,@NewRiskMessage = ''


-- rollback tran;
-- commit tran;


*/	
-- End of 01) DACS-2951 - MDM Verbiage updates 2024.3 - Create SPROC - Maintenance_UpdatePhysicianServiceRiskMessages.sql
GO

-- Start of 02) DACS-2951 - MDM Verbiage updates 2024.3 - SQL Script to update MDM Moderate Risk text.sql

----------------------------------------
-- 02) DACS-2951 - MDM Verbiage updates 2024.3 - SQL Script to update MDM Moderate Risk text.sql
----------------------------------------
GO

GO

GO

exec [dbo].[Maintenance_UpdatePhysicianServiceRiskMessages]
     @RiskSearchString = '<b>Moderate%'
	,@BackupPhysicianServiceTable = 1
    ,@NewRiskMessage = '<b>Moderate</b> risk of morbidity from additional diagnostic testing or treatment.<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Examples only:<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Prescription Drug Management (Prescriptions written at discharge; prescription strength meds administered<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;during encounter - <font color="Red">including those required for a procedure i.e., lidocaine or tetanus</font>, dosage changes, instructions<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;to stop taking prescriptions medication, and prescriptions considered but ultimately not given.<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Decision regarding minor surgery with identified patient or procedure risk factors<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Decision regarding elective major surgery without identified risk factors<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Diagnosis or treatment significantly limited by SDOH. (Food and/or housing insecurities, unemployment,<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;lack of transportation etc.)<br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Radiation exposure from CT scan (No Contrast) or Head, Neck, or Torso X-Ray</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Administration of IV Fluids, with or without additives</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Infant OTC Meds</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Acetaminophen (Tylenol) age < 24 months</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Ibuprofen (Motrin) age < 6 months</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">* Diphenhydramine (Benadryl) age < 6 years</font><br>   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="Red">• Rigid Musculoskeletal Immobilization (Custom Splint or Cast)</font><br> '

GO
-- End of 02) DACS-2951 - MDM Verbiage updates 2024.3 - SQL Script to update MDM Moderate Risk text.sql
GO

-- Start of 03) DACS-2951 - MDM Verbiage updates 2024.3 - Create SPROC - Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId.sql

----------------------------------------
-- 03) DACS-2951 - MDM Verbiage updates 2024.3 - Create SPROC - Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId.sql
----------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId]
      @SAId INT
	, @BackupDestTableSuffix VARCHAR(128) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @BackupDestTableSuffix IS NULL OR LEN(@BackupDestTableSuffix) <= 0
	BEGIN
		PRINT('Table Suffix is invalid.  Skipping backup of tables.');
		SET @BackupDestTableSuffix = NULL;
		--RETURN;
	END;
	
	DECLARE @countCM  INT = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId);
	DECLARE @countCMM INT = (SELECT COUNT(*) FROM CHARGE_MASTER_MODIFIER WHERE SERVICE_AGREEMENT_ID = @SAId);
	DECLARE @countCMA INT = (SELECT COUNT(*) FROM CHARGE_MASTER_CHARGE_AMOUNT WHERE CHARGE_MASTER_ID IN (SELECT CHARGE_MASTER_ID FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId));

	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));
	PRINT('Starting @countCMM = ' + CAST(@countCMM AS varchar(20)));
	PRINT('Starting @countCMA = ' + CAST(@countCMA AS varchar(20)));

	DECLARE @Nsql   NVARCHAR(MAX),
		    @Result INT;

	PRINT('------------------------------------------');
	PRINT('     Process Charge Master Charge Master Amount');
	PRINT('------------------------------------------');
	
	IF @countCMA > 0
	BEGIN
		DECLARE @CMABackupTarget VARCHAR(512) = 'CHARGE_MASTER_CHARGE_AMOUNT_' + @BackupDestTableSuffix;
		PRINT('Backup CM [CHARGE_MASTER_CHARGE_AMOUNT to ' + @CMABackupTarget + ']...');
		
		IF @BackupDestTableSuffix IS NOT NULL
			EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CHARGE_MASTER_CHARGE_AMOUNT', @DestTable = @CMABackupTarget;
		
		SET @Nsql = N'SELECT @Result = COUNT(*) FROM ' + QUOTENAME(@CMABackupTarget);
		PRINT(N'count CMA SQL :: ' + @Nsql)
		EXEC sp_executesql
			  @Nsql,
			  N'@Result INT OUTPUT',
			  @Result = @Result OUTPUT; 
		PRINT(N'count CMA :: ' + CAST(@Result AS VARCHAR(30)));
		
		IF @Result <= 0 AND @BackupDestTableSuffix IS NOT NULL
		BEGIN
			PRINT(N'Charge Master Charge Amount backup failed.  adjust and try again.');
		END
		ELSE
		BEGIN
			DELETE FROM CHARGE_MASTER_CHARGE_AMOUNT WHERE CHARGE_MASTER_ID IN (SELECT CHARGE_MASTER_ID FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId);
			SET @countCMA  = (SELECT COUNT(*) FROM CHARGE_MASTER_CHARGE_AMOUNT WHERE CHARGE_MASTER_ID IN (SELECT CHARGE_MASTER_ID FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId));
			PRINT('Resulting CMA Count for SAId  = ' + CAST(@countCMA AS varchar(20)));
		END;		
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Charge Amount Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;

	PRINT('------------------------------------------');
	PRINT('      Process Charge Master Modifier');
	PRINT('------------------------------------------');

	IF @countCMM > 0
	BEGIN
		DECLARE @CMMBackupTarget VARCHAR(512) = 'CHARGE_MASTER_MODIFIER_' + @BackupDestTableSuffix;
		PRINT('Backup CM [CHARGE_MASTER_MODIFIER to ' + @CMMBackupTarget + ']...');
		
		IF @BackupDestTableSuffix IS NOT NULL
			EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CHARGE_MASTER_MODIFIER', @DestTable = @CMMBackupTarget;
		
		SET @Nsql = N'SELECT @Result = COUNT(*) FROM ' + QUOTENAME(@CMMBackupTarget);
		PRINT(N'count CMM SQL :: ' + @Nsql)
		EXEC sp_executesql
			  @Nsql,
			  N'@Result INT OUTPUT',
			  @Result = @Result OUTPUT; 
		PRINT(N'count CMM :: ' + CAST(@Result AS VARCHAR(30)));
		
		IF @Result <= 0 AND @BackupDestTableSuffix IS NOT NULL
		BEGIN
			PRINT(N'Charge Master Modifier backup failed.  adjust and try again.');
		END
		ELSE
		BEGIN
			DELETE FROM CHARGE_MASTER_MODIFIER WHERE SERVICE_AGREEMENT_ID = @SAId;
			SET @countCMM  = (SELECT COUNT(*) FROM CHARGE_MASTER_MODIFIER WHERE SERVICE_AGREEMENT_ID = @SAId);
			PRINT('Resulting CMM Count for SAId  = ' + CAST(@countCMM AS varchar(20)));
		END;		
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Modifier Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		DECLARE @CMBackupTarget VARCHAR(512) = 'CHARGE_MASTER_' + @BackupDestTableSuffix;
		PRINT('Backup CM [CHARGE_MASTER to ' + @CMBackupTarget + ']...');
		
		IF @BackupDestTableSuffix IS NOT NULL
			EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CHARGE_MASTER', @DestTable = @CMBackupTarget;
		
		SET @Nsql = N'SELECT @Result = COUNT(*) FROM ' + QUOTENAME(@CMBackupTarget);
		PRINT(N'count CM SQL :: ' + @Nsql)
		EXEC sp_executesql
			  @Nsql,
			  N'@Result INT OUTPUT',
			  @Result = @Result OUTPUT; 
		PRINT(N'count CM :: ' + CAST(@Result AS VARCHAR(30)));
		
		IF @Result <= 0 AND @BackupDestTableSuffix IS NOT NULL
		BEGIN
			PRINT(N'Charge Master backup failed.  adjust and try again.');
		END
		ELSE
		BEGIN
			DELETE FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId;
			SET @countCM  = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId);
			PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
		END;		
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	SELECT 'Processing complete for SAId' = CAST(@SAId AS VARCHAR(20));
END

GO


-- End of 03) DACS-2951 - MDM Verbiage updates 2024.3 - Create SPROC - Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId.sql
GO

-- Start of 04) DACS-2951 - MDM Verbiage updates 2024.3 - SQL Script to delete all non Active CDMs from list of SAs.sql

----------------------------------------
-- 04) DACS-2951 - MDM Verbiage updates 2024.3 - SQL Script to delete all non Active CDMs from list of SAs.sql
/*
DELETE all CDMs ONLY if there are no charts:
Neighbors - Baytown GR (Service Agreement ID = 1914 Facility ID = 2026)
Neighbors - Crosby GR (Service Agreement ID = 1965 Facility ID = 2067)
Neighbors - Kingwood GR (Service Agreement ID = 1995 Facility ID = 2074)
Neighbors - Pasadena GR (Service Agreement ID = 1996 Facility ID = 2075)
Neighbors - Pearland GR (Service Agreement ID = 1997 Facility ID = 2076)
Neighbors - Porter GR (Service Agreement ID = 1998 Facility ID = 2077)

for QA Testing:
(Service Agreement ID = 555103 Facility ID = 1832)  first has 4 test charts that are removed
(Service Agreement ID = 555200 Facility ID = 555172) second has no charts at all
*/
----------------------------------------
GO

GO

GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @countFound INT;
DECLARE @saFound INT;
DECLARE @SAId INT;

/*
-- QA Test:
------
SET @SAId = 555103; -- QA  first has 4 test charts that are removed
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId, @BackupDestTableSuffix = 'DACS-2951-QA1';
END;
------

------
SET @SAId = 555200; -- QA  second has no charts at all
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId, @BackupDestTableSuffix = 'DACS-2951-QA2';
END;
------
*/

-- Production:
------
SET @SAId = 1914; -- Neighbors - Baytown GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId, @BackupDestTableSuffix = 'DACS-2951-1';
END;
------

------
SET @SAId = 1965; -- Neighbors - Crosby GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-2'; -- (DBA replace if you think these table backups are necessary)
END;
------

------
SET @SAId = 1995; -- Neighbors - Kingwood GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-3'; -- (DBA replace if you think these table backups are necessary)
END;
------

------
SET @SAId = 1996; -- Neighbors - Pasadena GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-4'; -- (DBA replace if you think these table backups are necessary)
END;
------

------
SET @SAId = 1997; -- Neighbors - Pearland GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-5'; -- (DBA replace if you think these table backups are necessary)
END;
------

------
SET @SAId = 1998; -- Neighbors - Porter GR
SET @countFound = (SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAId);
SET @saFound = (SELECT COUNT(*) FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAId);
PRINT('-----------------------------------------')
PRINT('SAId = ' + CAST(@SAId AS VARCHAR(30)))
PRINT('SAFound = ' + CAST(@saFound AS VARCHAR(30)))
PRINT('countFound = ' + CAST(@countFound AS VARCHAR(30)))

IF @countFound > 0 OR @saFound <= 0
BEGIN
	PRINT('Chart in use for service agreement [' + CAST(@SAId AS VARCHAR(30)) + '] = [' + CAST(@countFound AS VARCHAR(30)) + '] or NO SA Found.  CANNOT delete CDMs.');
END
ELSE
BEGIN
	PRINT('Processing CM Deletes for SAId = ' + CAST(@SAId AS VARCHAR(30)));
	exec [dbo].[Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId] @SAId = @SAId;--, @BackupDestTableSuffix = 'DACS-2951-6'; -- (DBA replace if you think these table backups are necessary)
END;
------



GO

/*
testing:
SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = 555103 
SELECT COUNT(*) FROM charge_master where SERVICE_AGREEMENT_ID = 555103 

SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = 555200 
SELECT COUNT(*) FROM charge_master where SERVICE_AGREEMENT_ID = 555200 

DECLARE @SAID INT = 555203
SELECT 'SA Name' = @SAID
SELECT [description] FROM SERVICE_AGREEMENT where SERVICE_AGREEMENT_ID = @SAID 
SELECT COUNT(*) FROM chart where SERVICE_AGREEMENT_ID = @SAID 
SELECT COUNT(*) FROM charge_master where SERVICE_AGREEMENT_ID = @SAID 

begin tran;


select top 10 * from chart
*/
-- End of 04) DACS-2951 - MDM Verbiage updates 2024.3 - SQL Script to delete all non Active CDMs from list of SAs.sql
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
