----------------------------------------
-- 03) DACS-2951 - MDM Verbiage updates 2024.3 - Create SPROC - Maintenance_DeleteChargeMasterAndCMCAAndCMMByServiceAgreementId.sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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


