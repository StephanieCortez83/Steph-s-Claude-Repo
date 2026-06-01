----------------------------------------
-- 01) DACS-2951 - MDM Verbiage updates 2024.3 - Create SPROC - Maintenance_UpdatePhysicianServiceRiskMessages.sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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