--------------------------------------------------------------------
-- 01) DACS-2495 - Update and Insert into [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] .sql
--------------------------------------------------------------------
USE RevCycleDB
GO

-- Step 1:  Set the target SAID for the specific service agreement to update.
-- qa is (Service Agreement ID = 555115 Facility ID = 555114);  prod is (Service Agreement ID = 1960 Facility ID = 2063) staging is (Service Agreement ID = 555102 Facility ID = 555102)
DECLARE @SAID int = -1;
DECLARE @UID int = -1;
DECLARE @CreationDate DATETIME = '06/23/2023';
DECLARE @EffectiveDate DATETIME = '01/01/2023';
DECLARE @ExpirationDate DATETIME = '06/20/2023';
DECLARE @NewRecordExpirationDate DATETIME = '12/30/2099';

-- SELECT ServerName = @@servername

IF @@servername = 'DRCMSQLAZ01\QA'
BEGIN
	-- set for QA ACS database
	SET @SAID = 555115;
	SET @UID = 12089;
END
ELSE IF @@servername = 'TRCMSQLAZ04' OR @@servername = 'TRCMSQLAZ04'
BEGIN
	-- set for Staging ACS database
	SET @SAID = 555102;
	SET @UID = 13103;
END
ELSE IF @@servername = 'PRCMSQLAZ04' OR @@servername = 'PRCMSQLAZ05'
BEGIN
	-- set for Production ACS database
	SET @SAID = 1960;
	SET @UID = (select top 1 user_profile_id from user_profile where sign_on_id = 'WPIPPIN');
	
	IF @UID <= 0
	BEGIN
		RAISERROR('ERROR!!!! cannot determine User Id To complete operation.', 20, -1)
		RETURN;
	END;
END
ELSE
BEGIN
	RAISERROR('ERROR!!!! cannot determine database server target or unknown target.', 20, -1)
	RETURN;
END;

-- Step 3:  Get the financial class ids needed
-- SELECT * FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID

DECLARE @FacFinClassCount int = (SELECT COUNT([FINANCIAL_CLASS_ID]) FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID);

SELECT SAId = @SAID, UID = @UID, FacFinClassCount = @FacFinClassCount;

IF  @FacFinClassCount = 0
BEGIN
	PRINT('No FACILITY_FINANCIAL_CLASS entries, adding...');
	INSERT INTO [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS]
           ([FINANCIAL_CLASS_CD]
           ,[SERVICE_AGREEMENT_ID]
           ,[BYPASS_CHART]
           ,[CREATION_DATE_TIME]
           ,[CREATING_USER_PROFILE_ID]
           ,[CHANGED_DATE_TIME]
           ,[CHANGING_USER_PROFILE_ID]
           ,[DESCRIPTION]
           ,[EXECUTE_MEDICAL_NECESSITY_IND]
           ,[CCS_BILLING_METHOD_CD]
           ,[COLLECT_CONDITION_OF_ACCIDENT_IND]
           ,[PHYSICIAN_SERVICES]
           ,[PHYSICIAN_PROCEDURES]
           ,[OBSERVATION_HOURS_LIMIT]
           ,[DO_NOT_APPLY_FACILITY_LEVEL_25_MOD_BASED_ON_INF_INJ]
           ,[EXPORT_MODIFIERS]
           ,[PAYOR_METHOD_CD]
           ,[PAYOR_CLASS_ID]
           ,[APPLY_Q6_MODIFIER]
           ,[COPIED_FROM_FINANCIAL_CLASS_ID]
           ,[APPLY_PHYS_SVC_MOD_25_ON_STATUS_B_PROCS]
           ,[COLLECT_PQRS]
           ,[ALLOW_MIDLEVEL_BILLING_OF_EM_SERVICES_IND]
           ,[COLLECT_LMP]
           ,[EXPORT_GC_MODIFIER]
           ,[DIAGNOSIS_CODE_INPATIENTS]
           ,[REQUIRE_AUDIT]
           ,[APPLY_UA_MOD_TO_SURGICAL_FAC_PROCS]
           ,[DO_NOT_ROUND_UP_ANESTHESIA_TIME_UNITS]
           ,[USE_MEDICARE_ANESTHESIA_RULES]
           ,[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_TIME_CALCULATION]
           ,[USE_GOVERNMENT_RULES_FOR_CLINIC_PROFEE_EFFECTIVE_DATE])
     VALUES
		 ('K',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Workmans Comp',		0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('W',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Well Program',			0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('U',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Undetermined',			0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('H',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Medicare-HMO',			0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('P',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Medicare Psy IP',		0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('M',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Medicare',				0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('B',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Medi-Cal HPSM',		0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('C',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Medi-Cal',				0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('Z',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Local/State Fed',		0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('J',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Jail',					0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('I',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Insurance',			0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('G',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Govn Non Manage Care',	0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('O',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Govn Manage Care',		0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('F',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Full Pay',				0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('D',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'County Programs',		0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('N',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'County Indigent',		0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)
		,('E',@SAID,0,@CreationDate,@UID,@CreationDate,@UID,'Charity Care',			0,NULL,0,0,0,0,0,1,-1,NULL,0,NULL,0,0,0,0,0,'N',0,0,NULL,0,0,NULL)	
		;	
END;

SET @FacFinClassCount = (SELECT COUNT([FINANCIAL_CLASS_ID]) FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID);

IF  @FacFinClassCount < 16
BEGIN
	RAISERROR('ERROR!!!! Not enough FACILITY_FINANCIAL_CLASS codes to perform task.', 20, -1)
	RETURN;
END;

DECLARE @B int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'B');
DECLARE @C int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'C');
DECLARE @D int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'D');
DECLARE @E int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'E');
DECLARE @F int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'F');
DECLARE @G int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'G');
DECLARE @H int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'H');
DECLARE @I int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'I');
DECLARE @J int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'J');
DECLARE @K int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'K');
DECLARE @L int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'L');
DECLARE @M int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'M');
DECLARE @N int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'N');
DECLARE @O int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'O');
DECLARE @U int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'U');
DECLARE @W int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] WHERE [SERVICE_AGREEMENT_ID] = @SAID AND FINANCIAL_CLASS_CD = 'W');

select B = @B, C = @C, D = @D, E = @E, F = @F, G = @G, H = @H, I = @I, J = @J, K = @K, L = @L, M = @M, N = @N, O = @O, U = @U, W = @W


-- Step 4: update present records
/*
DECLARE @SAID int = 555115;
SELECT * FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] WHERE [SERVICE_AGREEMENT_ID] = @SAID; -- see all

SELECT * 
FROM 
	[RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
WHERE
	[SERVICE_AGREEMENT_ID] = @SAID
	AND [FACILITY_PAYOR_ID] IN 
		 ('C10','C15','C20','C25','C30','C35'
		,'C70','C71','C72','C73','C74','C75','C76','C79','C80','C84','C85','C86','C90','C91','C92','C94','C95','D00','D02'
		,'D05','D50','E00','E01','E25','E27','E33','E34','E35','E50','F10','F18','F19','F50','F60','F74','F75','F99','G17'
		,'G31','G35','G40','G83','G86','G90','G95','H02','H05','H06','H20','H24','H27','H30','H31','H40','H41','H44','H45'
		,'H50','H71','H80','H88','H90','H91','H94','H95','I00','I01','I07','I20','I23','I30','I41','I42','I43','I44','I45'
		,'I46','I47','I48','I50','I52','I53','I54','I55','I60','I62','I66','I70','I88','I98','I99','J01','J06','J09','J10'
		,'J11','J12','J13','J22','J23','J24','J25','J27','J28','J30','J31','J32','J34','J35','J36','J37','J38','J39','J99'
		,'K00','K05','M20','M30','M40','M90','M94','M95','N90','N91','O00','O97','O99','U15','U16','U22','W10','W22','W60'
		);
*/

--BEGIN TRAN;
UPDATE 
	[RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
SET
	[EXPIRATION_DATE] = @ExpirationDate
WHERE
	[SERVICE_AGREEMENT_ID] = @SAID
	AND [FACILITY_PAYOR_ID] IN 
		 ('C10','C15','C20','C25','C30','C35'
		,'C70','C71','C72','C73','C74','C75','C76','C79','C80','C84','C85','C86','C90','C91','C92','C94','C95','D00','D02'
		,'D05','D50','E00','E01','E25','E27','E33','E34','E35','E50','F10','F18','F19','F50','F60','F74','F75','F99','G17'
		,'G31','G35','G40','G83','G86','G90','G95','H02','H05','H06','H20','H24','H27','H30','H31','H40','H41','H44','H45'
		,'H50','H71','H80','H88','H90','H91','H94','H95','I00','I01','I07','I20','I23','I30','I41','I42','I43','I44','I45'
		,'I46','I47','I48','I50','I52','I53','I54','I55','I60','I62','I66','I70','I88','I98','I99','J01','J06','J09','J10'
		,'J11','J12','J13','J22','J23','J24','J25','J27','J28','J30','J31','J32','J34','J35','J36','J37','J38','J39','J99'
		,'K00','K05','M20','M30','M40','M90','M94','M95','N90','N91','O00','O97','O99','U15','U16','U22','W10','W22','W60'
		);
-- Expect 137 to 140 affected on QA-ACS and staging-ACS; 0 on production unless this script has already been run or manual entries made
-- COMMIT TRAN;
-- ROLLBACK TRAN 

-- Step 5: insert new records
-- BEGIN TRAN;
SET @ExpirationDate = @NewRecordExpirationDate;

INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
	([SERVICE_AGREEMENT_ID]
	,[FACILITY_PAYOR_ID]
	,[FACILITY_PAYOR_NAME]
	,[FINANCIAL_CLASS_ID]
	,[PAYOR_METHOD_CD]
	,[PHYSICIAN_SERVICE_GUIDELINE_ID]
	,[ALLOW_PHYSICIAN_SERVICE_OBSERVATION]
	,[EFFECTIVE_DATE]
	,[EXPIRATION_DATE])
VALUES
	--(@SAID,FACILITY_PAYOR_ID,FACILITY_PAYOR_NAME,@FinClSID,3,8,0,'01/01/2023','01/01/2099')
	 (@SAID,'C10','MCAL HPSM INPATIENT'			,@B,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C15','MCAL PSYCH INPATIENT'		,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C20','MCAL HPSM OP'				,@B,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C25','MCAL PSYCH OUTPTIEN'			,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C30','MCAL HPSM SOC'				,@B,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C35','MCAL EDS SOC'				,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C70','MCAL IP FULL SCOPE'			,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C71','MCAL OP FULL SCOPE'			,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C72','MCAL FQHC FULL SCOPE'		,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C73','MCAL OP RESTRICTED'			,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C74','MCAL HOSP PE'				,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C75','BCCTP'						,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C76','MCAL IP RESTRICTED'			,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C79','MCAL FQHC RESTRICTED'		,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C80','MCAL NOT EDS COUNTY'			,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C84','MCAL HPE/FQHC'				,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C85','CHDP-EDS'					,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C86','CHDP-HPSM'					,@B,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C90','MEDI-CAL LTC NON-SOC'		,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C91','MEDI-CAL LTC SOC'			,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C92','HPSM LTC ANC CHARGES'		,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C94','MCAL HOSP PE LTC'			,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C95','HPSM MEDI-CAL SNF'			,@B,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'D00','CORDILLERAS SUITE'			,@D,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'D02','PSYCH SHERIFF'				,@D,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'D05','CORDILLERAS MHRC'			,@D,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'D50','CORONER'						,@D,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E00','GA/RECOVERY/WFW'				,@E,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E01','PUBLIC HEALTH SVS'			,@E,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E25','DISCOUNTED HLTH'				,@E,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E27','INDIGENT M HLTH'				,@E,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E33','330 PROGRAM'					,@E,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E34','330 PROGRAM ($5)'			,@E,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E35','330 PROGRAM WAIVED'			,@E,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E50','CHARITY CARE'				,@E,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F10','COMPLETED OEA APP'			,@F,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F18','LEGAL SETTLEMENT PEN'		,@F,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F19','SELF PAY'					,@F,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F50','SELF PAY SLIDING FEE'		,@F,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F60','PSYCH-PT RESPONSIBLE'		,@F,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F74','SELF PAY VERIFIED'			,@F,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F75','SELF PAY NOT PT F/U'			,@F,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F99','PAYMENT PLAN'				,@F,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G17','VICTIMS OF CRIME'			,@G,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G31','CCS'							,@G,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G35','DEPENDENT CHILDRENS'			,@G,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G40','GRANT FUNDED STUDY'			,@G,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G83','DCY & SEQUOIA YOUTH'			,@G,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G86','DELTA DNTL KIDS/FMLY'		,@G,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G90','PACT'						,@G,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G95','CDP'							,@G,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H02','MCARE-ADV CIGNA'				,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H05','MCARE-ADV BLUE SHLD'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H06','MCARE-ADV BLUE CROSS'		,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H20','HPSM OP CARE ADV'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H24','HPSM OP CARE ADV CMC'		,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H27','MCARE-ADV AETNA'				,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H30','HPSM IP CARE ADV B'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H31','HPSM PSY CARE ADV B'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H40','HPSM IP CARE ADV'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H41','HPSM PSY CARE ADV'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H44','HPSM IP CARE ADV CMC'		,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H45','HPSM PSY CAREADV CMC'		,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H50','MCARE-ADV UNITED'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H71','MCARE-KAISER MED HMO'		,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H80','MCARE - OTHER HMOS'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H88','MCARE-HEALTH NET-HMO'		,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H90','HPSM LTC CARE ADV'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H91','HPSM LTC CARE ADV B'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H94','HPSM LTC CARE ADV CM'		,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H95','HPSM LTC CADV CMC B'			,@H,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I00','REV SERV OTHER COMM'			,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I01','AARP'						,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I07','GOLDEN GATE REGIONAL'		,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I20','CIGNA'						,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I23','UNITED HEALTH CARE'			,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I30','AETNA OUT OF AREA'			,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I41','COV CA-ANTHEM PPO'			,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I42','COV CA-BLUE SHLD PPO'		,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I43','COV CA-CHINESE C HMO'		,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I44','COV CA-HLTH NET PPO'			,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I45','COV CA-KAISER P HOM'			,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I46','VA HEALTHCARE'				,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I47','VA FEE BASIS'				,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I48','CHAMPVA'						,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I50','BLUE SHIELD'					,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I52','TRICARE 4 LIFE'				,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I53','HUMANA'						,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I54','TRICARE EAST'				,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I55','CHAMPUS'						,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I60','BLUE CROSS NO CALIF'			,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I62','BLUE X/SHLD OUT STAT'		,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I66','CITY/COSANFRANCISCO'			,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I70','KAISER'						,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I88','HEALTH NET'					,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I98','IMPACT PROGRAM'				,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I99','OTHER COMMERCIAL INS'		,@I,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J01','COUNTY INMATE'				,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J06','ATHERTON POLICE DEPT'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J09','BELMONT POLICE DEPT'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J10','SHERIFF-MEDICAL JAIL'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J11','BROADMORE POLICE DPT'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J12','BRISBANE POLICE DEPT'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J13','BURLINGAME POLICE'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J22','DALY CITY POLICE DPT'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J23','EAST PALO ALTO PD'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J24','FOSTER CITY POLICE'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J25','HALF MOON BAY PD'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J27','HILLSBOROUGH POLICE'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J28','MENLOW PARK POLICE'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J30','JUVENILE PROBATION'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J31','MILLBRAE POLICE DEPT'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J32','PACIFICA POLICE DEPT'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J34','REDWOOD CITY POLICE'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J35','SAN BRUNO POLICE'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J36','SAN CARLOS POLICE'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J37','SAN MATEO POLICE DPT'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J38','SHERIFF DEPT FOR MLE'		,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J39','SO SAN FRANCISCO PD'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J99','OTHER POLICE/CPS'			,@J,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'K00','WORK COMP-COUNTY EMP'		,@K,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'K05','WORK COMP-NON COUNTY'		,@K,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M20','MCARE OP'					,@M,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M30','MEDICARE IP B ONLY'			,@M,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M40','MEDICARE INPATIENT'			,@M,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M90','MEDICARE LTC INPT'			,@M,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M94','MCARE IP PSY PART B'			,@M,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M95','MCARE IP PSY A&B'			,@M,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'N90','MEDICARE PT B LTC'			,@M,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'N91','MEDI-CAL LTC ANC CHG'		,@C,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'O00','RYAN WHITE'					,@O,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'O97','HELATHWORX'					,@O,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'O99','OTHER STATE/FED PRGM'		,@O,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'U15','REFERRED TO MEDI-CAL'		,@U,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'U16','SSI PENDING'					,@U,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'U22','WELL PENDING MEDI-CA'		,@U,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'W10','ACE COUNTY'					,@W,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'W22','ACE COUNTY FEE WAIVE'		,@W,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'W60','ACE COUNTY TEMPORARY'		,@W,3,8,0,@EffectiveDate,@ExpirationDate)
-- Expect 139 affected
-- COMMIT TRAN;
-- ROLLBACK TRAN 

-- See the results
SELECT * 
FROM 
	[RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
WHERE
	[SERVICE_AGREEMENT_ID] = @SAID
	AND [FACILITY_PAYOR_ID] IN 
		 ('C10','C15','C20','C25','C30','C35'
		,'C70','C71','C72','C73','C74','C75','C76','C79','C80','C84','C85','C86','C90','C91','C92','C94','C95','D00','D02'
		,'D05','D50','E00','E01','E25','E27','E33','E34','E35','E50','F10','F18','F19','F50','F60','F74','F75','F99','G17'
		,'G31','G35','G40','G83','G86','G90','G95','H02','H05','H06','H20','H24','H27','H30','H31','H40','H41','H44','H45'
		,'H50','H71','H80','H88','H90','H91','H94','H95','I00','I01','I07','I20','I23','I30','I41','I42','I43','I44','I45'
		,'I46','I47','I48','I50','I52','I53','I54','I55','I60','I62','I66','I70','I88','I98','I99','J01','J06','J09','J10'
		,'J11','J12','J13','J22','J23','J24','J25','J27','J28','J30','J31','J32','J34','J35','J36','J37','J38','J39','J99'
		,'K00','K05','M20','M30','M40','M90','M94','M95','N90','N91','O00','O97','O99','U15','U16','U22','W10','W22','W60'
		);

GO
  


