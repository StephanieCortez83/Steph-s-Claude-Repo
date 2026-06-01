USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2246 - Populate [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] .sql

--------------------------------------------------------------------
-- 01) DACS-2246 - Populate [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] .sql
--------------------------------------------------------------------
GO

-- Step 1:  Set the target SAID for the specific service agreement to update.
-- qa is (Service Agreement ID = 555115 Facility ID = 555114) prod is (Service Agreement ID = 1960 Facility ID = 2063)
DECLARE @SAID int = 555115;

-- Step 2:  Set the user Id of the account performing the actions
DECLARE @UID int = 12089;

/*
see who the SAID is related to, if desired as a check.  [description] should be one ofn the San Mateo Facilities
  select * from service_Agreement where service_Agreement_id = @SAID;

see what records already exist, if desired as a check.
  select * FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS]
  WHERE [SERVICE_AGREEMENT_ID] = @SAID
  ORDER BY [FINANCIAL_CLASS_ID];
*/

-- Step 3:  Remove all existing records
-- BEGIN TRAN;
DELETE FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS]
  WHERE [SERVICE_AGREEMENT_ID] = @SAID;
-- expect 0 affected  
-- COMMIT TRAN;
-- ROLLBACK TRAN 
 
-- Step 4: insert new records
-- BEGIN TRAN;
DECLARE @InsertionDate DATETIME = '06/01/2023';

INSERT INTO [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS]
	(FINANCIAL_CLASS_CD,[DESCRIPTION],SERVICE_AGREEMENT_ID,CREATION_DATE_TIME,CREATING_USER_PROFILE_ID,CHANGED_DATE_TIME,CHANGING_USER_PROFILE_ID)
VALUES
	-- (FINANCIAL_CLASS_CD,[DESCRIPTION],@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	 ('B'	,'Medi-Cal HPSM',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('C'	,'Medi-Cal',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('D'	,'County Programs',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('E'	,'Charity Care',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('F'	,'Full Pay',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('G'	,'Govn Non Manage Care',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('H'	,'Medicare-HMO',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('I'	,'Insurance',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('J'	,'Jail',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('K'	,'Workmans Comp',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('M'	,'Medicare',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('N'	,'County Indigent',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('O'	,'Govn Manage Care',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('P'	,'Medicare Psy IP',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('U'	,'Undetermined',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('W'	,'Well Program',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('Z'	,'Local/State Fed',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('1'	,'Legal Pending B/D',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('2'	,'Well Program B/D',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('3'	,'Full Pay-Bad Debt',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('4'	,'Medicare Bad Debt',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('5'	,'Ins/Work Comp-B/D',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('6'	,'Medi-Cal Bad Debt',@SAID,@InsertionDate,@UID,@InsertionDate,@UID)
	,('7'	,'Legal Pending B/D',@SAID,@InsertionDate,@UID,@InsertionDate,@UID);
-- Expect 24 affected
-- COMMIT TRAN;
-- ROLLBACK TRAN 


  


-- End of 01) DACS-2246 - Populate [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS] .sql
GO

-- Start of 02) DACS-2246 - Populate [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] .sql

--------------------------------------------------------------------
-- 02) DACS-2246 - Populate [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] .sql
--------------------------------------------------------------------
GO

-- Step 1:  Set the target SAID for the specific service agreement to update.
-- qa is (Service Agreement ID = 555115 Facility ID = 555114) prod is (Service Agreement ID = 1960 Facility ID = 2063)
DECLARE @SAID int = 555115;

-- Step 2:  Set the user Id of the account performing the actions
DECLARE @UID int = 12089;

-- Step 3:  Get the financial class id for the 'undetermined' financial class
-- DECLARE @FinClSID int = 2100100714;
DECLARE @FinClSID int = (SELECT TOP 1 [FINANCIAL_CLASS_ID] FROM [RevCycleDB].[dbo].[FACILITY_FINANCIAL_CLASS]
							WHERE [SERVICE_AGREEMENT_ID] = @SAID AND [DESCRIPTION] = 'Undetermined');

PRINT('@FinClSID = ' + CAST( @FinClSID AS varchar(50)));

DECLARE @FoundCount int = (select count(*) FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
							WHERE [SERVICE_AGREEMENT_ID] = @SAID AND [FINANCIAL_CLASS_ID] = @FinClSID);

PRINT('@FoundCount = ' + CAST( @FoundCount AS varchar(50)));

/*
see who the SAID is related to, if desired as a check.  [description] should be one of the San Mateo Facilities
  select * from service_Agreement where service_Agreement_id = @SAID;

see what records already exist, if desired as a check.
if greater than 0 (zero) and # = 139 (expected insertion count), prolly should skip the deletion and insertion steps
select * FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
WHERE [SERVICE_AGREEMENT_ID] = @SAID
AND [FINANCIAL_CLASS_ID] = @FinClSID
ORDER BY [SERVICE_AGREEMENT_PAYOR_ID];

*/

IF @FoundCount >= 139
BEGIN
	PRINT('@FoundCount = 139 (Expected Insertion Count). Exiting.');
	RETURN;
END

PRINT('Processing Inserts...');

-- Step 4:  Remove all existing records
IF @FinClSID IS NOT NULL
BEGIN
-- BEGIN TRAN;
	DELETE FROM [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
	  WHERE [SERVICE_AGREEMENT_ID] = @SAID AND [FINANCIAL_CLASS_ID] = @FinClSID;
-- expect 0 affected  
-- COMMIT TRAN;
-- ROLLBACK TRAN 
END;
 
-- Step 5: insert new records
-- BEGIN TRAN;
DECLARE @EffectiveDate DATETIME = '01/01/2023';
DECLARE @ExpirationDate DATETIME = '01/01/2099';

INSERT INTO [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR]
	(SERVICE_AGREEMENT_ID
	,FACILITY_PAYOR_ID
	,FACILITY_PAYOR_NAME
	,FINANCIAL_CLASS_ID
	,PAYOR_METHOD_CD
	,PHYSICIAN_SERVICE_GUIDELINE_ID
	,ALLOW_PHYSICIAN_SERVICE_OBSERVATION
	,EFFECTIVE_DATE
	,EXPIRATION_DATE)
VALUES
	--(@SAID,FACILITY_PAYOR_ID,FACILITY_PAYOR_NAME,@FinClSID,3,8,0,'01/01/2023','01/01/2099')
	 (@SAID,'C10','MCAL HPSM INPATIENT'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C15','MCAL PSYCH INPATIENT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C20','MCAL HPSM OP'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C25','MCAL PSYCH OUTPTIEN'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C30','MCAL HPSM SOC'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C35','MCAL EDS SOC'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C70','MCAL IP FULL SCOPE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C71','MCAL OP FULL SCOPE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C72','MCAL FQHC FULL SCOPE'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C73','MCAL OP RESTRICTED'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C74','MCAL HOSP PE'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C75','BCCTP'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C76','MCAL IP RESTRICTED'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C79','MCAL FQHC RESTRICTED'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C80','MCAL NOT EDS COUNTY'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C84','MCAL HPE/FQHC'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C85','CHDP-EDS'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C86','CHDP-HPSM'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C90','MEDI-CAL LTC NON-SOC'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C91','MEDI-CAL LTC SOC'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C92','HPSM LTC ANC CHARGES'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C94','MCAL HOSP PE LTC'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'C95','HPSM MEDI-CAL SNF'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'D00','CORDILLERAS SUITE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'D02','PSYCH SHERIFF'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'D05','CORDILLERAS MHRC'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'D50','CORONER'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E00','GA/RECOVERY/WFW'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E01','PUBLIC HEALTH SVS'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E25','DISCOUNTED HLTH'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E27','INDIGENT M HLTH'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E33','330 PROGRAM'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E34','330 PROGRAM ($5)'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E35','330 PROGRAM WAIVED'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'E50','CHARITY CARE'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F10','COMPLETED OEA APP'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F18','LEGAL SETTLEMENT PEN'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F19','SELF PAY'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F50','SELF PAY SLIDING FEE'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F60','PSYCH-PT RESPONSIBLE'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F74','SELF PAY VERIFIED'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F75','SELF PAY NOT PT F/U'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'F99','PAYMENT PLAN'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G17','VICTIMS OF CRIME'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G31','CCS'							,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G35','DEPENDENT CHILDRENS'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G40','GRANT FUNDED STUDY'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G83','DCY & SEQUOIA YOUTH'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G86','DELTA DNTL KIDS/FMLY'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G90','PACT'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'G95','CDP'							,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H02','MCARE-ADV CIGNA'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H05','MCARE-ADV BLUE SHLD'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H06','MCARE-ADV BLUE CROSS'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H20','HPSM OP CARE ADV'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H24','HPSM OP CARE ADV CMC'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H27','MCARE-ADV AETNA'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H30','HPSM IP CARE ADV B'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H31','HPSM PSY CARE ADV B'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H40','HPSM IP CARE ADV'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H41','HPSM PSY CARE ADV'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H44','HPSM IP CARE ADV CMC'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H45','HPSM PSY CAREADV CMC'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H50','MCARE-ADV UNITED'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H71','MCARE-KAISER MED HMO'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H80','MCARE - OTHER HMOS'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H88','MCARE-HEALTH NET-HMO'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H90','HPSM LTC CARE ADV'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H91','HPSM LTC CARE ADV B'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H94','HPSM LTC CARE ADV CM'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'H95','HPSM LTC CADV CMC B'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I00','REV SERV OTHER COMM'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I01','AARP'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I07','GOLDEN GATE REGIONAL'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I20','CIGNA'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I23','UNITED HEALTH CARE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I30','AETNA OUT OF AREA'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I41','COV CA-ANTHEM PPO'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I42','COV CA-BLUE SHLD PPO'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I43','COV CA-CHINESE C HMO'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I44','COV CA-HLTH NET PPO'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I45','COV CA-KAISER P HOM'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I46','VA HEALTHCARE'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I47','VA FEE BASIS'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I48','CHAMPVA'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I50','BLUE SHIELD'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I52','TRICARE 4 LIFE'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I53','HUMANA'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I54','TRICARE EAST'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I55','CHAMPUS'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I60','BLUE CROSS NO CALIF'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I62','BLUE X/SHLD OUT STAT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I66','CITY/COSANFRANCISCO'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I70','KAISER'						,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I88','HEALTH NET'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I98','IMPACT PROGRAM'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'I99','OTHER COMMERCIAL INS'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J01','COUNTY INMATE'				,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J06','ATHERTON POLICE DEPT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J09','BELMONT POLICE DEPT'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J10','SHERIFF-MEDICAL JAIL'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J11','BROADMORE POLICE DPT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J12','BRISBANE POLICE DEPT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J13','BURLINGAME POLICE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J22','DALY CITY POLICE DPT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J23','EAST PALO ALTO PD'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J24','FOSTER CITY POLICE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J25','HALF MOON BAY PD'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J27','HILLSBOROUGH POLICE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J28','MENLOW PARK POLICE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J30','JUVENILE PROBATION'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J31','MILLBRAE POLICE DEPT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J32','PACIFICA POLICE DEPT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J34','REDWOOD CITY POLICE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J35','SAN BRUNO POLICE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J36','SAN CARLOS POLICE'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J37','SAN MATEO POLICE DPT'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J38','SHERIFF DEPT FOR MLE'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J39','SO SAN FRANCISCO PD'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'J99','OTHER POLICE/CPS'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'K00','WORK COMP-COUNTY EMP'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'K05','WORK COMP-NON COUNTY'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M20','MCARE OP'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M30','MEDICARE IP B ONLY'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M40','MEDICARE INPATIENT'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M90','MEDICARE LTC INPT'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M94','MCARE IP PSY PART B'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'M95','MCARE IP PSY A&B'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'N90','MEDICARE PT B LTC'			,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'N91','MEDI-CAL LTC ANC CHG'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'O00','RYAN WHITE'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'O97','HELATHWORX'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'O99','OTHER STATE/FED PRGM'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'U15','REFERRED TO MEDI-CAL'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'U16','SSI PENDING'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'U22','WELL PENDING MEDI-CA'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'W10','ACE COUNTY'					,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'W22','ACE COUNTY FEE WAIVE'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
	,(@SAID,'W60','ACE COUNTY TEMPORARY'		,@FinClSID,3,8,0,@EffectiveDate,@ExpirationDate)
-- Expect 139 affected
-- COMMIT TRAN;
-- ROLLBACK TRAN 


  


-- End of 02) DACS-2246 - Populate [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] .sql
GO

-- Start of 01) DACS-2455 - Alter Table [dbo].[PHYSICIAN_SERVICE_EVAL_AUTOMATION] - add date field default values.SQL

----------------------------------------
-- Perform task:  01) DACS-2455 - Alter Table [dbo].[PHYSICIAN_SERVICE_EVAL_AUTOMATION] - add date field default values.SQL
----------------------------------------
GO

ALTER TABLE [dbo].[PHYSICIAN_SERVICE_EVAL_AUTOMATION] ADD  CONSTRAINT [DF_PHYSICIAN_SERVICE_EVAL_AUTOMATION_CREATION_DATE_TIME]  DEFAULT (getdate()) FOR [CREATION_DATE_TIME]
GO

ALTER TABLE [dbo].[PHYSICIAN_SERVICE_EVAL_AUTOMATION] ADD  CONSTRAINT [DF_PHYSICIAN_SERVICE_EVAL_AUTOMATION_CHANGED_DATE_TIME]  DEFAULT (getdate()) FOR [CHANGED_DATE_TIME]
GO
-- End of 01) DACS-2455 - Alter Table [dbo].[PHYSICIAN_SERVICE_EVAL_AUTOMATION] - add date field default values.SQL
GO

-- Start of 01) DACS-2457 - Alter procedure [dbo].[spGetServiceAgreementClinics].SQL

--------------------------------------------------------------------------
-- 01) DACS-2457 - Alter procedure [dbo].[spGetServiceAgreementClinics].SQL
--------------------------------------------------------------------------

GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[spGetServiceAgreementClinics]
@ServiceAgreementId int = null, @ClinicId varchar(10) = null
WITH EXEC AS CALLER
AS
declare @service_agreement_id int=@ServiceAgreementId;
declare @clinic_id datetime=@ClinicId;

select SERVICE_AGREEMENT_ID, 
       CLINIC_ID, 
       [DESCRIPTION], 
       SERVICE_LINE_ID,
       NEW_PATIENT_CLASS_ID,
       ESTABLISHED_PATIENT_CLASS_ID
from SERVICE_AGREEMENT_CLINIC
where (@service_agreement_id is null or SERVICE_AGREEMENT_ID=@service_agreement_id)
  and (@clinic_id is null or CLINIC_ID=@clinic_id)
order by [DESCRIPTION]; -- add ordering 20230607 - DACS-2457

GO


-- End of 01) DACS-2457 - Alter procedure [dbo].[spGetServiceAgreementClinics].SQL
GO

-- Start of 02) DACS-2457 - Create procedure [dbo].[GetProviderBusinessUnitIdByServiceAgreementAndClinicId].SQL

--------------------------------------------------------------------------
-- 02) DACS-2457 - Create procedure [dbo].[GetProviderBusinessUnitIdByServiceAgreementAndClinicId].SQL
--------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[GetProviderBusinessUnitIdByServiceAgreementAndClinicId]
	@ServiceAgreementId int, 
	@ClinicId varchar(10)
WITH EXEC AS CALLER
AS

-- Testing:
-- DECLARE @ServiceAgreementId int = 555115;
-- DECLARE @ClinicId varchar(10) = 'XXX' -- no returned data
-- DECLARE @ClinicId varchar(10) = 'COA' -- returned data
-- DECLARE @ClinicId varchar(10) = '&X<>X''X' -- no returned data
-- DECLARE @ClinicId varchar(10) = '<C>O&A''' -- returned data

-- some adjustments to avoid most hacking attempts.
SET @ClinicId = REPLACE(@ClinicId, '&', '')
SET @ClinicId = REPLACE(@ClinicId, '<', '')
SET @ClinicId = REPLACE(@ClinicId, '>', '')
SET @ClinicId = REPLACE(@ClinicId, '''', '')

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT TOP 1 
	[PROVIDER_BUSINESS_UNIT_ID]
FROM 
	[dbo].[PROVIDER_BUSINESS_UNIT]
    INNER JOIN [dbo].[SERVICE_AGREEMENT_CLINIC] 
		ON [SERVICE_AGREEMENT_CLINIC].[SERVICE_AGREEMENT_ID] = [PROVIDER_BUSINESS_UNIT].[SERVICE_AGREEMENT_ID]
		AND [SERVICE_AGREEMENT_CLINIC].[CLINIC_ID] = [PROVIDER_BUSINESS_UNIT].[BUSINESS_UNIT_NAME]
WHERE 
	[SERVICE_AGREEMENT_CLINIC].[SERVICE_AGREEMENT_ID] = @ServiceAgreementId 
	AND [SERVICE_AGREEMENT_CLINIC].[CLINIC_ID] = @ClinicId;

GO

-- Testing: 
-- exec [dbo].[GetProviderBusinessUnitIdByServiceAgreementAndClinicId] @ServiceAgreementId = 555115, @ClinicId = '<C>O&A''';


-- End of 02) DACS-2457 - Create procedure [dbo].[GetProviderBusinessUnitIdByServiceAgreementAndClinicId].SQL
GO

-- Start of 01) DACS-1348 - Update 1224 1336 Observation Exclusions.SQL

----------------------------------------
-- Perform task:  01) DACS-1348 - Update 1224 1336 Observation Exclusions for EXISTING Facility.SQL
----------------------------------------
GO

-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
DECLARE @SAId int =		1224;  
DECLARE @FId int =		1336;  
DECLARE @Result int;

-- Use this to see what reasons already exist for this SA.  See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;


-- Step 2)  Update OBSERVATION_EXCLUSION_HOURS_REASON entries that already exist to be a bit more readible.  !!!Cannot delete as they are in use by existing charts!!!
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'Barium Enema (1h 15m)' WHERE [DESCRIPTION] = 'Barium Enema (1.25 hrs)' 									AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)' WHERE [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2.5 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1.25 hrs)' 	AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1.25 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'PT/OT/SP (Rehab) (documented time)' WHERE [DESCRIPTION] = 'PT/OT/SP (Rehab)' 							AND [SERVICE_AGREEMENT_ID] = @SAId;

-- Use this to see the changes to validate.  See bottom of file for expected returns.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;


-- Step 3)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)
-- formatting: Description (0-60min); Description (XXh YYm)
-- maximum description length is 50 characters.
--exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS proc(paracentesis,BM bx,LP,etc.)(30m or DT)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
-- broken into 2 entries:
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS procs (BM biopsy,LP,Steroid inj.,etc)(30m/DT)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Paracentesis (30m or documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/contrast (1h)', 										@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w & wo contrast (1h)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Foley Insertion  (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'GI procedures (documented time)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hemodialysis (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA (1h 45m)', 											@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA return to dept (45m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Metered dose inhaler (MDI) (15m)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/contrast (1h 30m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM perfusion rest/stress (2h)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Nutrition  (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PICC insertion (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Pulmonary Function Study (1h or documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'SC to LH transport (documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly. See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

GO




--============================================================--
--============================================================--
-- TOOLS:
--============================================================--
--============================================================--
/*
-- DECLARE @SERVICE_AGREEMENT_DESCRIPTION_TARGET VARCHAR(50) = 'Advocate Christ Coding'; -- optional.  Can be used with the lower tools to help determine the above variables

-- Use this to list all OBSERVATION_EXCLUSION_HOURS_REASONs for a given SERVICE_AGREEMENT_DESCRIPTION
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_DESCRIPTION
-- ex. SERVICE_AGREEMENT_ID		FACILITY_ID		COMPANY_ID		DESCRIPTION				EFFECTIVE_DATE			EXPIRATION_DATE
-- ex. 77						225				13				Advocate Christ Coding	2007-10-01 00:00:00.000	2012-10-31 00:00:00.000
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_ID
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_ID]
-- 	@SERVICE_AGREEMENT_ID = @SAId;

-- Use this to see what reasons already exist for this SA.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
--  @SERVICE_AGREEMENT_ID = @SAId;

Before updates should looks something like this:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2.5 hrs)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1.25 hrs)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1.25 hrs)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1.25 hrs)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)

after:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2h 30m)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1h 15m)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1h 15m)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1h 15m)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)
1224	2100100129	BS procs (paracentesis, BM bx, LP, steroid inj, etc.)
1224	2100100130	CT w/contrast (1h)
1224	2100100131	CT w & wo contrast (1h)
1224	2100100132	CT w/o contrast (1h)
1224	2100100133	Foley Insertion  (15m)
1224	2100100134	GI procedures (documented time)
1224	2100100135	Hemodialysis (documented time)
1224	2100100136	HIDA (1h 45m)
1224	2100100137	HIDA return to dept (45m)
1224	2100100138	Metered dose inhaler (MDI) (15m)
1224	2100100139	MRI w/o contrast (1h)
1224	2100100140	MRI w/contrast (1h 30m)
1224	2100100141	NM perfusion rest/stress (2h)
1224	2100100142	Nutrition  (documented time)
1224	2100100143	PICC insertion (15m)
1224	2100100144	Pulmonary Function Study (1h or documented time)
1224	2100100145	SC to LH transport (documented time)
*/
-- End of 01) DACS-1348 - Update 1224 1336 Observation Exclusions.SQL
GO

-- Start of 02) DACS-1348 - Update 1796 1922 Observation Exclusions.SQL

----------------------------------------
-- Perform task:  02) DACS-1348 - Update 1796 1922 Observation Exclusions.SQL
----------------------------------------
GO

-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
DECLARE @SAId int =		1796;  
DECLARE @FId int =		1922;  
DECLARE @Result int;

-- Use this to see what reasons already exist for this SA.  See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

----------------------------------------
-- EXPECT 47 TOTAL ENTRIES ON FINAL SELECT CHECK
----------------------------------------

-- Step 2)  Update OBSERVATION_EXCLUSION_HOURS_REASON entries that already exist to be a bit more readible.  !!!Cannot delete as they are in use by existing charts!!!
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'Barium Enema (1h 15m)' WHERE [DESCRIPTION] = 'Barium Enema (1.25 hrs)' 									AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)' WHERE [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2.5 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1.25 hrs)' 	AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1.25 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'PT/OT/SP (Rehab) (documented time)' WHERE [DESCRIPTION] = 'PT/OT/SP (Rehab)' 							AND [SERVICE_AGREEMENT_ID] = @SAId;

-- Use this to see the changes to validate.  See bottom of file for expected returns.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

-- Step 3)  Make sure the boase entries are present (i.e. from 1224 SA) OBSERVATION_EXCLUSION_HOURS_REASON entries
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PT/OT/SP (Rehab) (documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CARDIOVERSION', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'TRANSFUSION', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'IV THERAPY', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Other', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO 2D W/O SPEC CLR FLOW (1 hr)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO STRESS TREADMILL (2 hrs)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'TEE COMPLETE (ECHO) (1 hr)', 				@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CV STRESS TEST TREADMILL (1h 15m)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM STRESS TEST (2 hrs)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'EEG (30 min)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/O CONTRAST - Brain (30 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/O CONTRAST - Other (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ CONTRAST - Brain (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ CONTRAST - Other (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ & W/O CONTRAST - Brain (45 min)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ & W/O CONTRAST - Other (1 hr)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CTA (1 hr)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI (1 hr)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'US (abdomen/carotid) (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Spinal films (cervical, thoracic, lumbar) (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Venous/Arterial studies (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Upper GI (1 hr)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Barium Enema (1h 15m)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hand Held Neb TX (HHN) (15 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Routine radiology (CXR/ABD) (30 min)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECG (15 min)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Step 4)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)
-- formatting: Description (0-60min); Description (XXh YYm)
-- maximum description length is 50 characters.
--exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS proc(paracentesis,BM bx,LP,etc.)(30m or DT)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
-- broken into 2 entries:
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS procs (BM biopsy,LP,Steroid inj.,etc)(30m/DT)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Paracentesis (30m or documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/contrast (1h)', 										@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w & wo contrast (1h)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Foley Insertion  (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'GI procedures (documented time)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hemodialysis (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA (1h 45m)', 											@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA return to dept (45m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Metered dose inhaler (MDI) (15m)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/contrast (1h 30m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM perfusion rest/stress (2h)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Nutrition  (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PICC insertion (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Pulmonary Function Study (1h or documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'SC to LH transport (documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly. See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

GO




--============================================================--
--============================================================--
-- TOOLS:
--============================================================--
--============================================================--
/*
-- DECLARE @SERVICE_AGREEMENT_DESCRIPTION_TARGET VARCHAR(50) = 'Advocate Christ Coding'; -- optional.  Can be used with the lower tools to help determine the above variables

-- Use this to list all OBSERVATION_EXCLUSION_HOURS_REASONs for a given SERVICE_AGREEMENT_DESCRIPTION
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_DESCRIPTION
-- ex. SERVICE_AGREEMENT_ID		FACILITY_ID		COMPANY_ID		DESCRIPTION				EFFECTIVE_DATE			EXPIRATION_DATE
-- ex. 77						225				13				Advocate Christ Coding	2007-10-01 00:00:00.000	2012-10-31 00:00:00.000
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_ID
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_ID]
-- 	@SERVICE_AGREEMENT_ID = @SAId;

-- Use this to see what reasons already exist for this SA.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
--  @SERVICE_AGREEMENT_ID = @SAId;

Before updates should looks something like this:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2.5 hrs)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1.25 hrs)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1.25 hrs)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1.25 hrs)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)

after:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2h 30m)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1h 15m)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1h 15m)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1h 15m)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)
1224	2100100129	BS procs (paracentesis, BM bx, LP, steroid inj, etc.)
1224	2100100130	CT w/contrast (1h)
1224	2100100131	CT w & wo contrast (1h)
1224	2100100132	CT w/o contrast (1h)
1224	2100100133	Foley Insertion  (15m)
1224	2100100134	GI procedures (documented time)
1224	2100100135	Hemodialysis (documented time)
1224	2100100136	HIDA (1h 45m)
1224	2100100137	HIDA return to dept (45m)
1224	2100100138	Metered dose inhaler (MDI) (15m)
1224	2100100139	MRI w/o contrast (1h)
1224	2100100140	MRI w/contrast (1h 30m)
1224	2100100141	NM perfusion rest/stress (2h)
1224	2100100142	Nutrition  (documented time)
1224	2100100143	PICC insertion (15m)
1224	2100100144	Pulmonary Function Study (1h or documented time)
1224	2100100145	SC to LH transport (documented time)
*/
-- End of 02) DACS-1348 - Update 1796 1922 Observation Exclusions.SQL
GO

-- Start of 03) DACS-1348 - Update 1424 1538 Observation Exclusions.SQL

----------------------------------------
-- Perform task:  03) DACS-1348 - Update 1424 1538 Observation Exclusions.SQL
----------------------------------------
GO

-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
DECLARE @SAId int =		1424;  
DECLARE @FId int =		1538;  
DECLARE @Result int;

-- Use this to see what reasons already exist for this SA.  See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

----------------------------------------
-- EXPECT 47 TOTAL ENTRIES ON FINAL SELECT CHECK
----------------------------------------

-- Step 2)  Update OBSERVATION_EXCLUSION_HOURS_REASON entries that already exist to be a bit more readible.  !!!Cannot delete as they are in use by existing charts!!!
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'Barium Enema (1h 15m)' WHERE [DESCRIPTION] = 'Barium Enema (1.25 hrs)' 									AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)' WHERE [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2.5 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1.25 hrs)' 	AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1.25 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'PT/OT/SP (Rehab) (documented time)' WHERE [DESCRIPTION] = 'PT/OT/SP (Rehab)' 							AND [SERVICE_AGREEMENT_ID] = @SAId;

-- Use this to see the changes to validate.  See bottom of file for expected returns.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

-- Step 3)  Make sure the boase entries are present (i.e. from 1224 SA) OBSERVATION_EXCLUSION_HOURS_REASON entries
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PT/OT/SP (Rehab) (documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CARDIOVERSION', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'TRANSFUSION', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'IV THERAPY', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Other', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO 2D W/O SPEC CLR FLOW (1 hr)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO STRESS TREADMILL (2 hrs)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'TEE COMPLETE (ECHO) (1 hr)', 				@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CV STRESS TEST TREADMILL (1h 15m)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM STRESS TEST (2 hrs)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'EEG (30 min)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/O CONTRAST - Brain (30 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/O CONTRAST - Other (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ CONTRAST - Brain (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ CONTRAST - Other (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ & W/O CONTRAST - Brain (45 min)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ & W/O CONTRAST - Other (1 hr)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CTA (1 hr)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI (1 hr)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'US (abdomen/carotid) (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Spinal films (cervical, thoracic, lumbar) (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Venous/Arterial studies (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Upper GI (1 hr)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Barium Enema (1h 15m)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hand Held Neb TX (HHN) (15 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Routine radiology (CXR/ABD) (30 min)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECG (15 min)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Step 4)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)
-- formatting: Description (0-60min); Description (XXh YYm)
-- maximum description length is 50 characters.
--exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS proc(paracentesis,BM bx,LP,etc.)(30m or DT)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
-- broken into 2 entries:
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS procs (BM biopsy,LP,Steroid inj.,etc)(30m/DT)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Paracentesis (30m or documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/contrast (1h)', 										@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w & wo contrast (1h)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Foley Insertion  (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'GI procedures (documented time)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hemodialysis (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA (1h 45m)', 											@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA return to dept (45m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Metered dose inhaler (MDI) (15m)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/contrast (1h 30m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM perfusion rest/stress (2h)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Nutrition  (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PICC insertion (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Pulmonary Function Study (1h or documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'SC to LH transport (documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly. See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

GO




--============================================================--
--============================================================--
-- TOOLS:
--============================================================--
--============================================================--
/*
-- DECLARE @SERVICE_AGREEMENT_DESCRIPTION_TARGET VARCHAR(50) = 'Advocate Christ Coding'; -- optional.  Can be used with the lower tools to help determine the above variables

-- Use this to list all OBSERVATION_EXCLUSION_HOURS_REASONs for a given SERVICE_AGREEMENT_DESCRIPTION
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_DESCRIPTION
-- ex. SERVICE_AGREEMENT_ID		FACILITY_ID		COMPANY_ID		DESCRIPTION				EFFECTIVE_DATE			EXPIRATION_DATE
-- ex. 77						225				13				Advocate Christ Coding	2007-10-01 00:00:00.000	2012-10-31 00:00:00.000
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_ID
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_ID]
-- 	@SERVICE_AGREEMENT_ID = @SAId;

-- Use this to see what reasons already exist for this SA.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
--  @SERVICE_AGREEMENT_ID = @SAId;

Before updates should looks something like this:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2.5 hrs)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1.25 hrs)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1.25 hrs)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1.25 hrs)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)

after:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2h 30m)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1h 15m)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1h 15m)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1h 15m)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)
1224	2100100129	BS procs (paracentesis, BM bx, LP, steroid inj, etc.)
1224	2100100130	CT w/contrast (1h)
1224	2100100131	CT w & wo contrast (1h)
1224	2100100132	CT w/o contrast (1h)
1224	2100100133	Foley Insertion  (15m)
1224	2100100134	GI procedures (documented time)
1224	2100100135	Hemodialysis (documented time)
1224	2100100136	HIDA (1h 45m)
1224	2100100137	HIDA return to dept (45m)
1224	2100100138	Metered dose inhaler (MDI) (15m)
1224	2100100139	MRI w/o contrast (1h)
1224	2100100140	MRI w/contrast (1h 30m)
1224	2100100141	NM perfusion rest/stress (2h)
1224	2100100142	Nutrition  (documented time)
1224	2100100143	PICC insertion (15m)
1224	2100100144	Pulmonary Function Study (1h or documented time)
1224	2100100145	SC to LH transport (documented time)
*/
-- End of 03) DACS-1348 - Update 1424 1538 Observation Exclusions.SQL
GO

-- Start of 04) DACS-1348 - Update 1227 1341 Observation Exclusions.SQL

----------------------------------------
-- Perform task:  04) DACS-1348 - Update 1227 1341 Observation Exclusions.SQL
----------------------------------------
GO

-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
DECLARE @SAId int =		1227;  
DECLARE @FId int =		1341;  
DECLARE @Result int;

-- Use this to see what reasons already exist for this SA.  See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

----------------------------------------
-- EXPECT 47 TOTAL ENTRIES ON FINAL SELECT CHECK
----------------------------------------

-- Step 2)  Update OBSERVATION_EXCLUSION_HOURS_REASON entries that already exist to be a bit more readible.  !!!Cannot delete as they are in use by existing charts!!!
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'Barium Enema (1h 15m)' WHERE [DESCRIPTION] = 'Barium Enema (1.25 hrs)' 									AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)' WHERE [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2.5 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1.25 hrs)' 	AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1.25 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'PT/OT/SP (Rehab) (documented time)' WHERE [DESCRIPTION] = 'PT/OT/SP (Rehab)' 							AND [SERVICE_AGREEMENT_ID] = @SAId;

-- Use this to see the changes to validate.  See bottom of file for expected returns.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

-- Step 3)  Make sure the boase entries are present (i.e. from 1224 SA) OBSERVATION_EXCLUSION_HOURS_REASON entries
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PT/OT/SP (Rehab) (documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CARDIOVERSION', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'TRANSFUSION', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'IV THERAPY', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Other', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO 2D W/O SPEC CLR FLOW (1 hr)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO STRESS TREADMILL (2 hrs)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'TEE COMPLETE (ECHO) (1 hr)', 				@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CV STRESS TEST TREADMILL (1h 15m)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM STRESS TEST (2 hrs)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'EEG (30 min)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/O CONTRAST - Brain (30 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/O CONTRAST - Other (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ CONTRAST - Brain (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ CONTRAST - Other (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ & W/O CONTRAST - Brain (45 min)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ & W/O CONTRAST - Other (1 hr)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CTA (1 hr)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI (1 hr)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'US (abdomen/carotid) (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Spinal films (cervical, thoracic, lumbar) (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Venous/Arterial studies (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Upper GI (1 hr)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Barium Enema (1h 15m)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hand Held Neb TX (HHN) (15 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Routine radiology (CXR/ABD) (30 min)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECG (15 min)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Step 4)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)
-- formatting: Description (0-60min); Description (XXh YYm)
-- maximum description length is 50 characters.
--exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS proc(paracentesis,BM bx,LP,etc.)(30m or DT)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
-- broken into 2 entries:
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS procs (BM biopsy,LP,Steroid inj.,etc)(30m/DT)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Paracentesis (30m or documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/contrast (1h)', 										@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w & wo contrast (1h)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Foley Insertion  (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'GI procedures (documented time)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hemodialysis (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA (1h 45m)', 											@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA return to dept (45m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Metered dose inhaler (MDI) (15m)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/contrast (1h 30m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM perfusion rest/stress (2h)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Nutrition  (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PICC insertion (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Pulmonary Function Study (1h or documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'SC to LH transport (documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly. See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

GO




--============================================================--
--============================================================--
-- TOOLS:
--============================================================--
--============================================================--
/*
-- DECLARE @SERVICE_AGREEMENT_DESCRIPTION_TARGET VARCHAR(50) = 'Advocate Christ Coding'; -- optional.  Can be used with the lower tools to help determine the above variables

-- Use this to list all OBSERVATION_EXCLUSION_HOURS_REASONs for a given SERVICE_AGREEMENT_DESCRIPTION
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_DESCRIPTION
-- ex. SERVICE_AGREEMENT_ID		FACILITY_ID		COMPANY_ID		DESCRIPTION				EFFECTIVE_DATE			EXPIRATION_DATE
-- ex. 77						225				13				Advocate Christ Coding	2007-10-01 00:00:00.000	2012-10-31 00:00:00.000
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_ID
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_ID]
-- 	@SERVICE_AGREEMENT_ID = @SAId;

-- Use this to see what reasons already exist for this SA.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
--  @SERVICE_AGREEMENT_ID = @SAId;

Before updates should looks something like this:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2.5 hrs)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1.25 hrs)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1.25 hrs)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1.25 hrs)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)

after:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2h 30m)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1h 15m)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1h 15m)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1h 15m)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)
1224	2100100129	BS procs (paracentesis, BM bx, LP, steroid inj, etc.)
1224	2100100130	CT w/contrast (1h)
1224	2100100131	CT w & wo contrast (1h)
1224	2100100132	CT w/o contrast (1h)
1224	2100100133	Foley Insertion  (15m)
1224	2100100134	GI procedures (documented time)
1224	2100100135	Hemodialysis (documented time)
1224	2100100136	HIDA (1h 45m)
1224	2100100137	HIDA return to dept (45m)
1224	2100100138	Metered dose inhaler (MDI) (15m)
1224	2100100139	MRI w/o contrast (1h)
1224	2100100140	MRI w/contrast (1h 30m)
1224	2100100141	NM perfusion rest/stress (2h)
1224	2100100142	Nutrition  (documented time)
1224	2100100143	PICC insertion (15m)
1224	2100100144	Pulmonary Function Study (1h or documented time)
1224	2100100145	SC to LH transport (documented time)
*/
-- End of 04) DACS-1348 - Update 1227 1341 Observation Exclusions.SQL
GO

-- Start of 05) DACS-1348 - Update 1229 1343 Observation Exclusions.SQL

----------------------------------------
-- Perform task:  05) DACS-1348 - Update 1229 1343 Observation Exclusions.SQL
----------------------------------------
GO

-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
DECLARE @SAId int =		1229;  
DECLARE @FId int =		1343;  
DECLARE @Result int;

-- Use this to see what reasons already exist for this SA.  See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

----------------------------------------
-- EXPECT 47 TOTAL ENTRIES ON FINAL SELECT CHECK
----------------------------------------

-- Step 2)  Update OBSERVATION_EXCLUSION_HOURS_REASON entries that already exist to be a bit more readible.  !!!Cannot delete as they are in use by existing charts!!!
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'Barium Enema (1h 15m)' WHERE [DESCRIPTION] = 'Barium Enema (1.25 hrs)' 									AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)' WHERE [DESCRIPTION] = 'ECHO STRESS PHARMOCOLOGIC (2.5 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST PHARMACOLOGIC (1.25 hrs)' 	AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1h 15m)' WHERE [DESCRIPTION] = 'CV STRESS TEST TREADMILL (1.25 hrs)' 			AND [SERVICE_AGREEMENT_ID] = @SAId;
UPDATE [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] SET [DESCRIPTION] = 'PT/OT/SP (Rehab) (documented time)' WHERE [DESCRIPTION] = 'PT/OT/SP (Rehab)' 							AND [SERVICE_AGREEMENT_ID] = @SAId;

-- Use this to see the changes to validate.  See bottom of file for expected returns.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

-- Step 3)  Make sure the boase entries are present (i.e. from 1224 SA) OBSERVATION_EXCLUSION_HOURS_REASON entries
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PT/OT/SP (Rehab) (documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CARDIOVERSION', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'TRANSFUSION', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'IV THERAPY', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Other', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO 2D W/O SPEC CLR FLOW (1 hr)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO STRESS TREADMILL (2 hrs)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECHO STRESS PHARMOCOLOGIC (2h 30m)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'TEE COMPLETE (ECHO) (1 hr)', 				@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CV STRESS TEST TREADMILL (1h 15m)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CV STRESS TEST PHARMACOLOGIC (1h 15m)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM STRESS TEST (2 hrs)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'EEG (30 min)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/O CONTRAST - Brain (30 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/O CONTRAST - Other (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ CONTRAST - Brain (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ CONTRAST - Other (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ & W/O CONTRAST - Brain (45 min)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT W/ & W/O CONTRAST - Other (1 hr)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CTA (1 hr)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI (1 hr)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'US (abdomen/carotid) (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Spinal films (cervical, thoracic, lumbar) (45 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Venous/Arterial studies (1 hr)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Upper GI (1 hr)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Barium Enema (1h 15m)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hand Held Neb TX (HHN) (15 min)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Routine radiology (CXR/ABD) (30 min)', 	@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'ECG (15 min)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Step 4)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)
-- formatting: Description (0-60min); Description (XXh YYm)
-- maximum description length is 50 characters.
--exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS proc(paracentesis,BM bx,LP,etc.)(30m or DT)', 			@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
-- broken into 2 entries:
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'BS procs (BM biopsy,LP,Steroid inj.,etc)(30m/DT)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Paracentesis (30m or documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/contrast (1h)', 										@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w & wo contrast (1h)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'CT w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Foley Insertion  (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'GI procedures (documented time)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Hemodialysis (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA (1h 45m)', 											@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'HIDA return to dept (45m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Metered dose inhaler (MDI) (15m)', 						@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/o contrast (1h)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'MRI w/contrast (1h 30m)', 								@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'NM perfusion rest/stress (2h)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Nutrition  (documented time)', 							@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'PICC insertion (15m)', 									@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Pulmonary Function Study (1h or documented time)', 		@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT] @OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'SC to LH transport (documented time)', 					@SERVICE_AGREEMENT_ID = @SAId, @OBSERVATION_EXCLUSION_HOURS_REASON_ID = @Result OUTPUT;


-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly. See bottom of file for expected return
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID] @SERVICE_AGREEMENT_ID = @SAId;

GO




--============================================================--
--============================================================--
-- TOOLS:
--============================================================--
--============================================================--
/*
-- DECLARE @SERVICE_AGREEMENT_DESCRIPTION_TARGET VARCHAR(50) = 'Advocate Christ Coding'; -- optional.  Can be used with the lower tools to help determine the above variables

-- Use this to list all OBSERVATION_EXCLUSION_HOURS_REASONs for a given SERVICE_AGREEMENT_DESCRIPTION
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_DESCRIPTION
-- ex. SERVICE_AGREEMENT_ID		FACILITY_ID		COMPANY_ID		DESCRIPTION				EFFECTIVE_DATE			EXPIRATION_DATE
-- ex. 77						225				13				Advocate Christ Coding	2007-10-01 00:00:00.000	2012-10-31 00:00:00.000
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_DESCRIPTION]
-- 	@SERVICE_AGREEMENT_DESCRIPTION = @SERVICE_AGREEMENT_DESCRIPTION_TARGET;

-- Use this to list the basic information for a given SERVICE_AGREEMENT_ID
-- exec [dbo].[SERVICE_AGREEMENT_SELECT_BASIC_INFORMATION_BY_SERVICE_AGREEMENT_ID]
-- 	@SERVICE_AGREEMENT_ID = @SAId;

-- Use this to see what reasons already exist for this SA.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
--  @SERVICE_AGREEMENT_ID = @SAId;

Before updates should looks something like this:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2.5 hrs)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1.25 hrs)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1.25 hrs)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1.25 hrs)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)

after:
SERVICE_AGREEMENT_ID	EXCLUSION_HOURS_REASON_ID	DESCRIPTION
1224	1540	PT/OT/SP (Rehab)
1224	1541	CARDIOVERSION
1224	1542	TRANSFUSION
1224	1543	IV THERAPY
1224	1699	Other
1224	1480	ECHO 2D W/O SPEC CLR FLOW (1 hr)
1224	1481	ECHO STRESS TREADMILL (2 hrs)
1224	1482	ECHO STRESS PHARMOCOLOGIC (2h 30m)
1224	1483	TEE COMPLETE (ECHO) (1 hr)
1224	1484	CV STRESS TEST TREADMILL (1h 15m)
1224	1485	CV STRESS TEST PHARMACOLOGIC (1h 15m)
1224	1486	NM STRESS TEST (2 hrs)
1224	1487	EEG (30 min)
1224	1488	CT W/O CONTRAST - Brain (30 min)
1224	1489	CT W/O CONTRAST - Other (45 min)
1224	1490	CT W/ CONTRAST - Brain (45 min)
1224	1491	CT W/ CONTRAST - Other (1 hr)
1224	1492	CT W/ & W/O CONTRAST - Brain (45 min)
1224	1493	CT W/ & W/O CONTRAST - Other (1 hr)
1224	1494	CTA (1 hr)
1224	1495	MRI (1 hr)
1224	1496	US (abdomen/carotid) (1 hr)
1224	1497	Spinal films (cervical, thoracic, lumbar) (45 min)
1224	1498	Venous/Arterial studies (1 hr)
1224	1499	Upper GI (1 hr)
1224	1500	Barium Enema (1h 15m)
1224	1501	Hand Held Neb TX (HHN) (15 min)
1224	1502	Routine radiology (CXR/ABD) (30 min)
1224	1503	ECG (15 min)
1224	2100100129	BS procs (paracentesis, BM bx, LP, steroid inj, etc.)
1224	2100100130	CT w/contrast (1h)
1224	2100100131	CT w & wo contrast (1h)
1224	2100100132	CT w/o contrast (1h)
1224	2100100133	Foley Insertion  (15m)
1224	2100100134	GI procedures (documented time)
1224	2100100135	Hemodialysis (documented time)
1224	2100100136	HIDA (1h 45m)
1224	2100100137	HIDA return to dept (45m)
1224	2100100138	Metered dose inhaler (MDI) (15m)
1224	2100100139	MRI w/o contrast (1h)
1224	2100100140	MRI w/contrast (1h 30m)
1224	2100100141	NM perfusion rest/stress (2h)
1224	2100100142	Nutrition  (documented time)
1224	2100100143	PICC insertion (15m)
1224	2100100144	Pulmonary Function Study (1h or documented time)
1224	2100100145	SC to LH transport (documented time)
*/
-- End of 05) DACS-1348 - Update 1229 1343 Observation Exclusions.SQL
GO

-- Start of 01) DACS-2452 - Alter Stored Procedure dbo].[sp_Get_DashboardPendingReport] - Modify FLAGGED_FOR_POST_BILL_AUDIT_DT filtering.SQL

--------------------------------------------------------------
-- 01) DACS-2452 - Alter Stored Procedure dbo].[sp_Get_DashboardPendingReport] - Modify FLAGGED_FOR_POST_BILL_AUDIT_DT filtering.SQL
--------------------------------------------------------------
GO

GO

GO



-- =============================================
-- Author: Daniel Bonebrake
-- Create date: 12/3/2015
-- Updated date: 1/31/2018 JohnS: Added #ChartIDs temp table to improve performance
-- Updated date: 10/3/2018 JohnS: Made the following changes:
--   1) The SQL that inserts charts into the #ChartIDs temp table does not include the "TOP" max charts results statement to limit the results to 3001 rows (3000 is the current value for the max charts results). 
--      This could potentially cause millions of rows to be inserted into the #ChartIDs temp table. Added the "TOP" statement in this insert query. 
--   2) The SQL that does include the "TOP" statement is the SELECT statement into the #ChartSubset table. This SQL selects from the CHART table and joins the CHART table to the #ChartIDs table. 
--      The FROM clause should be selecting from the #ChartIDs table and joining the #ChartIDs table to the CHART table. The "TOP" statement was removed from the SQL that selects rows into the #ChartSubset table. 
--   3) In the query that inserts rows into #ImageSubset, added ii.CHART_ID = -1 to the WHERE clause. Rows with a value in the CHART_ID column should not be included in that query.
--   4) In the query that inserts rows into #ImageSubset, added ii.FACILITY_ID = c.FACILITY_ID to the WHERE clause in the sub-query that checks if ii.FACILITY_CHART_ID exists in the CHART table.
--   5) Changed the @cmd variable to only include " UNION " when the value of @m_ReturnCount = 1.
--   6) Created a separate command variable (@cmd3) for storing the SQL that checks the count in the #ChartIDs table and modified the SQL at the bottom of the stored proc to execute @cmd3 + @cmd + @cmd1 when the 
--      value of the @m_ReturnCount = 1. 
-- Description: SQL for pending transactions portion of dashboard
-- =============================================

-- Modified 20230419 - wpippin - added filtering for [FLAGGED_FOR_POST_BILL_AUDIT_DT] (ACS c# = PostBillAuditFlagged) field
-- Modified 20230501 - wpippin - added filtering for logNotes fields indicating flags for the new PBA audit and new PBA flagged for additional audit notes
-- Modified 20230608 - wpippin - revert logNotes fields behavior back to using [CHART].[FLAGGED_FOR_POST_BILL_AUDIT_DT] and add [FLAGGED_FOR_POST_BILL_AUDIT] [bit] NULL behavior.

CREATE OR ALTER PROCEDURE [dbo].[sp_Get_DashboardPendingReport]
    @ReturnCount BIT = 0,
    @DosFrom DATE = NULL,
    @DosTo DATE = NULL,
    @ReceivedFrom DATE = NULL,
    @ReceivedTo DATE = NULL,
    @SentFrom DATE = NULL,
    @SentTo DATE = NULL,
    @ChartStatuses VARCHAR(50) = '',
    @PendingReasons VARCHAR(MAX) = NULL,
    @Facilities VARCHAR(MAX) = NULL,
    @MedicalRecordNumber VARCHAR(25) = '',
    @FacilityChartIdentifier VARCHAR(25) = '',
    @FacilityAdminChartID VARCHAR(25) = '',       
    @ClinicID VARCHAR(10) = '',
    @PatientClassID INT = - 1,
    @LocationCodes VARCHAR(MAX) = NULL,
    @Providers VARCHAR(MAX) = NULL,
    @ObservationDepartments VARCHAR(MAX) = NULL,
    @OrderBy INT = 0, -- DOS
    @SortDirection VARCHAR(4) = 'ASC',
    @ChartSearchMaxCount INT = 3000,
	@ChartPostBillAuditStatus INT = 0,
	@ChartPostBillAuditStartDtFrom DATE = NULL,
	@ChartPostBillAuditStartDtTo DATE = NULL,
	@ChartPostBillAuditCompletedDtFrom DATE = NULL,
	@ChartPostBillAuditCompletedDtTo DATE = NULL,
	@ChartPostBillAuditFlaggedDtFrom DATE = NULL,
	@ChartPostBillAuditFlaggedDtTo DATE = NULL,
	@ChartPostBillAuditFlagged BIT = 0
	
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @Today DATE = GETDATE();

-- Insert statements for procedure here
DECLARE @m_ReturnCount BIT = @ReturnCount
    ,@m_ClinicID VARCHAR(10) = @ClinicID
    ,@m_PatientClassID INT = @PatientClassID
	,@m_ChartPostBillAuditStatus INT = @ChartPostBillAuditStatus
	,@m_ChartPostBillAuditStartDtFrom DATE = @ChartPostBillAuditStartDtFrom
	,@m_ChartPostBillAuditStartDtTo DATE = @ChartPostBillAuditStartDtTo
	,@m_ChartPostBillAuditCompletedDtFrom DATE = @ChartPostBillAuditCompletedDtFrom
	,@m_ChartPostBillAuditCompletedDtTo DATE = @ChartPostBillAuditCompletedDtTo
	,@m_ChartPostBillAuditFlaggedDtFrom DATE = @ChartPostBillAuditFlaggedDtFrom
	,@m_ChartPostBillAuditFlaggedDtTo DATE = @ChartPostBillAuditFlaggedDtTo
	,@m_ChartPostBillAuditFlagged BIT = @ChartPostBillAuditFlagged
    ,@m_ChartStatuses VARCHAR(50) = @ChartStatuses
    ,@m_PendingReasons VARCHAR(MAX) = @PendingReasons
    ,@m_DosFrom DATE = @DosFrom
    ,@m_DosTo DATE = ISNULL(@DosTo, @Today)
    ,@m_ReceivedFrom DATE = @ReceivedFrom
    ,@m_ReceivedTo DATE = ISNULL(@ReceivedTo, @Today)
    ,@m_SentFrom DATE = @SentFrom
    ,@m_SentTo DATE = ISNULL(@SentTo, @Today)
    ,@m_Facilities VARCHAR(MAX) = @Facilities
    ,@m_MedicalRecordNumber VARCHAR(25) = @MedicalRecordNumber
    ,@m_FacilityChartIdentifier VARCHAR(25) = @FacilityChartIdentifier
    ,@m_FacilityAdminChartID VARCHAR(25) = @FacilityAdminChartID
    ,@m_LocationCodes VARCHAR(MAX) = @LocationCodes
    ,@m_Providers VARCHAR(MAX) = @Providers
    ,@m_ObservationDepartments VARCHAR(MAX) = @ObservationDepartments
    ,@m_OrderBy INT = @OrderBy
    ,@m_SortDirection VARCHAR(4) = @SortDirection
    ,@OrderByString VARCHAR(50)
    ,@cmd VARCHAR(MAX) = ''
    ,@cmd2 VARCHAR(MAX) = ''
    ,@cmd1 VARCHAR(MAX) = ''
    ,@cmd3 VARCHAR(MAX) = ''
    ,@WhereClause VARCHAR(MAX) = ''
    ,@AndStr VARCHAR(5) = ''
    ,@m_ChartSearchMaxCount INT = @ChartSearchMaxCount + 1;

SET @cmd1 = '
if object_id(''TempDB..#ChartSubset'', ''U'') is not null drop table #ChartSubset
if object_ID(''TempDB..#ImageSubset'', ''U'') is not null drop table #ImageSubset
if object_id(''TempDB..#FacilityIDList'', ''U'') is not null drop table #FacilityIDList
if object_id(''TempDB..#StatusIDList'', ''U'') is not null drop table #StatusIDList
if object_id(''TempDB..#ProviderNPIList'', ''U'') is not null drop table #ProviderNPIList
if object_id(''TempDB..#ChartIDs'', ''U'') is not null drop table #ChartIDs
'

IF (NULLIF(@m_Facilities, '') IS NOT NULL)
BEGIN
  SET @cmd1 += '
SELECT Items = cast(Items as int) 
  INTO #FacilityIDList
FROM dbo.SplitString(''' + @m_Facilities + ''','','')
'
END

IF (@m_ChartStatuses <> '')
BEGIN
  SET @cmd1 += '
SELECT Items = cast(Items as int) 
  INTO #StatusIDList
FROM dbo.SplitString(''' + @m_ChartStatuses + ''','','')
'
END

IF (@m_Providers <> '')
BEGIN
  SET @cmd1 += '
SELECT Items
  INTO #ProviderNPIList
FROM dbo.SplitString(''' + @m_Providers + ''','','')
'
END

  SET @cmd1 += '
SELECT TOP ' + CONVERT(VARCHAR, @m_ChartSearchMaxCount) + ' 
	ii.import_Image_ID,
	f.[NAME] FACILITY
  INTO #ImageSubset
FROM 
  IMPORT_IMAGE ii WITH (NOLOCK)
  INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = ii.FACILITY_ID
  INNER JOIN #FacilityIDList as t1 ON ii.Facility_ID = t1.Items
WHERE 
  NULLIF(ii.DATE_OF_SERVICE, '''') IS NOT NULL'

IF (@m_DosFrom IS NOT NULL)
BEGIN
  IF (@m_DosFrom = @m_DosTo)
  BEGIN
      SET @cmd1 += '
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) = ''' + CONVERT(VARCHAR, @m_DosFrom) + ''''
  END
  ELSE
  BEGIN
      SET @cmd1 += '
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_DosFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_DosTo) + ''''
  END
END
ELSE
BEGIN
IF (@m_ReceivedFrom IS NOT NULL)
BEGIN
  IF (@m_ReceivedFrom = @m_ReceivedTo)
  BEGIN
    SET @cmd1 += '
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) = ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''''
  END
  ELSE
  BEGIN
    SET @cmd1 += '
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ReceivedTo) + ''''
  END
END
END

SET @cmd1 += '
  AND ii.CHART_ID = -1 
  AND ii.FACILITY_CHART_ID NOT IN 
  (
    SELECT c.FACILITY_CHART_ID
    FROM CHART c WITH (NOLOCK)
    WHERE c.FACILITY_ID = ii.FACILITY_ID 
    AND c.FACILITY_CHART_ID = ii.FACILITY_CHART_ID
  )
'

SET @cmd1 += '
SELECT TOP ' + CONVERT(VARCHAR, @m_ChartSearchMaxCount) + ' CHART_ID
 into #ChartIDs
FROM CHART c WITH (NOLOCK)
'

IF (NULLIF(@m_Facilities, '') IS NOT NULL)
BEGIN
  SET @cmd1 += '
  INNER JOIN #FacilityIDList as t1 on c.Facility_ID = t1.Items'
END

IF (@m_ChartStatuses <> '')
BEGIN
  SET @cmd1 += '
  INNER JOIN #StatusIDList as t2 on c.chart_Status_ID = t2.Items'

  IF (NULLIF(@m_PendingReasons, '') IS NOT NULL)
  BEGIN
  --  SET @WhereClause += '
 --' + @AndStr + ' c.PENDING_REASON_ID IN (' + @m_PendingReasons + ')'
    --SET @AndStr = ' AND '
    SET @WhereClause += '
 ' + @AndStr + ' 0 < CASE WHEN c.CHART_STATUS_ID in (2, 6) THEN 
                (SELECT COUNT(cpr.CHART_PENDING_REASON_ID) from CHART_PENDING_REASON cpr WITH (NOLOCK), SERVICE_AGREEMENT_PENDING_REASON spr WITH (NOLOCK)
                 WHERE cpr.chart_id = c.chart_id AND cpr.SERVICE_AGREEMENT_PENDING_REASON_ID = spr.SERVICE_AGREEMENT_PENDING_REASON_ID 
                 AND spr.PENDING_REASON_ID IN (' +  @m_PendingReasons + '))
                 ELSE 1 END '
    SET @AndStr = ' AND '
  END
END

IF (NULLIF(@m_ClinicID, '') IS NOT NULL       
    AND @m_ClinicID <> '-1')
BEGIN
  SET @cmd1 += '
  INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID'
END

IF (@m_MedicalRecordNumber <> '')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + 'c.MEDICAL_RECORD_NUM LIKE (''' + @m_MedicalRecordNumber + '%'')'
  SET @AndStr = ' AND '
END

IF (@m_FacilityChartIdentifier <> '')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + 'c.FACILITY_CHART_ID LIKE (''' + @m_FacilityChartIdentifier + '%'')'
  SET @AndStr = ' AND '
END

IF (@m_FacilityAdminChartID <> '')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + 'c.FACILITY_ADMIN_CHART_ID LIKE (''' + @m_FacilityAdminChartID + '%'')'
  SET @AndStr = ' AND '
END

IF (NULLIF(@m_LocationCodes, '') IS NOT NULL)
BEGIN
  SET @WhereClause += '
 ' + @AndStr + 'EXISTS (
    SELECT *
    FROM dbo.SplitString(''' + @m_LocationCodes + ''','','')
    WHERE ITEMS = c.LOCATION_CODE
  )'
  SET @AndStr = ' AND '
END

IF (NULLIF(@m_ObservationDepartments, '') IS NOT NULL)
BEGIN
  SET @WhereClause += '
 ' + @AndStr + 'c.INITIAL_CHARGE_MASTER_DEPT_ID IN (' + @m_ObservationDepartments + ')'
  SET @AndStr = ' AND '
END

IF (NULLIF(@m_ClinicID, '') IS NOT NULL       
    AND @m_ClinicID <> '-1')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + '(
    sa.COLLECT_CLINIC = ''N''
    OR c.CLINIC_ID = ''' + @m_ClinicID + '''
  )'
  SET @AndStr = ' AND '
END

IF (NULLIF(@m_Providers, '') IS NOT NULL)
BEGIN

  SET @cmd1 += '
  LEFT JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = c.PHYSICIAN_ID
    and c.physician_ID > -1 
  LEFT JOIN FACILITY_PROFESSIONAL mlp WITH (NOLOCK) ON mlp.FACILITY_PROF_ID = c.NURSE_PRACTITIONER_ID
    and c.NURSE_PRACTITIONER_ID > -1'

  SET @WhereClause += '
  ' + @AndStr + 'EXISTS (
    SELECT *
    FROM #ProviderNPIList
    WHERE ITEMS = fp.UPIR_ID

    UNION

    SELECT *
    FROM #ProviderNPIList
    WHERE ITEMS = mlp.UPIR_ID
  )'
  SET @AndStr = ' AND '
END

IF (@m_DosFrom IS NOT NULL)
BEGIN
  IF (@m_DosFrom = @m_DosTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) = ''' + CONVERT(VARCHAR, @m_DosFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_DosFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_DosTo) + ''''
    SET @AndStr = ' AND '
  END
END

IF (@m_ReceivedFrom IS NOT NULL)
BEGIN
  IF (@m_ReceivedFrom = @m_ReceivedTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.DATE_RECEIVED), 0) = ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.DATE_RECEIVED), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ReceivedTo) + ''''
    SET @AndStr = ' AND '
  END
END

IF (@m_SentFrom IS NOT NULL)
BEGIN
  IF (@m_SentFrom = @m_SentTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.SENT_DATE), 0) = ''' + CONVERT(VARCHAR, @m_SentFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.SENT_DATE), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_SentFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_SentTo) + ''''
    SET @AndStr = ' AND '
  END
END

IF (@m_PatientClassID > 0)
BEGIN
  SET @WhereClause += '
 ' + @AndStr + 'c.PATIENT_CLASS_ID = ' + CONVERT(VARCHAR, @m_PatientClassID)
  SET @AndStr = ' AND '
END

-- Post Bill Audit filters
IF (@m_ChartPostBillAuditStatus > 0)
BEGIN
  SET @cmd1 += '
  INNER JOIN ChartPostBillAudit pba ON pba.ChartId = c.CHART_ID'
  SET @WhereClause += '
 ' + @AndStr + 'pba.ChartPostBillAuditStatusTypeCode = ' + CONVERT(VARCHAR, @m_ChartPostBillAuditStatus)
  SET @AndStr = ' AND '
END
ELSE
BEGIN
  SET @cmd1 += '
  LEFT JOIN ChartPostBillAudit pba ON pba.ChartId = c.CHART_ID'
END

IF (@m_ChartPostBillAuditStartDtFrom IS NOT NULL)
BEGIN
  IF (@m_ChartPostBillAuditStartDtFrom = @m_ChartPostBillAuditStartDtTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.POST_BILL_AUDIT_STARTED), 0) = ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditStartDtFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.POST_BILL_AUDIT_STARTED), 0) BETWEEN ''' + CONVERT(VARCHAR,  @m_ChartPostBillAuditStartDtFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditStartDtTo) + ''''
    SET @AndStr = ' AND '
  END
END

IF (@m_ChartPostBillAuditCompletedDtFrom IS NOT NULL)
BEGIN
  IF (@m_ChartPostBillAuditCompletedDtFrom = @m_ChartPostBillAuditCompletedDtTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.POST_BILL_AUDIT_COMPLETED), 0) = ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditCompletedDtFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.POST_BILL_AUDIT_COMPLETED), 0) BETWEEN ''' + CONVERT(VARCHAR,  @m_ChartPostBillAuditCompletedDtFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditCompletedDtTo) + ''''
    SET @AndStr = ' AND '
  END
END

-- Modified 20230608 - wpippin - revert logNotes fields behavior back to using [CHART].[FLAGGED_FOR_POST_BILL_AUDIT_DT] and add [FLAGGED_FOR_POST_BILL_AUDIT] [bit] NULL behavior.
IF (@m_ChartStatuses <> '' AND @m_ChartStatuses like '%5%')
BEGIN
	IF (@m_ChartPostBillAuditFlaggedDtFrom IS NOT NULL)
	BEGIN
	  IF (@m_ChartPostBillAuditFlaggedDtFrom = @m_ChartPostBillAuditFlaggedDtTo)
	  BEGIN
		SET @WhereClause += '
	 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.FLAGGED_FOR_POST_BILL_AUDIT_DT), 0) = ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditFlaggedDtFrom) + ''''
		SET @AndStr = ' AND '
	  END
	  ELSE
	  BEGIN
		SET @WhereClause += '
	 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.FLAGGED_FOR_POST_BILL_AUDIT_DT), 0) BETWEEN ''' + CONVERT(VARCHAR,  @m_ChartPostBillAuditFlaggedDtFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditFlaggedDtTo) + ''''
		SET @AndStr = ' AND '
	  END
	END

	IF (@m_ChartPostBillAuditFlagged IS NOT NULL AND @m_ChartPostBillAuditFlagged = 1)
	BEGIN
		SET @WhereClause += '
	 ' + @AndStr + 'c.FLAGGED_FOR_POST_BILL_AUDIT = 1'
		SET @AndStr = ' AND '
	END
END
--end Post Bill Audit Filters

-- Append where clause to @cmd
IF (@WhereClause <> '')
BEGIN
  SET @cmd1 += '
WHERE ' + @WhereClause
  SET @WhereClause = ''
  SET @AndStr = ''
END

IF (@m_ReturnCount = 1)
BEGIN
    SET @cmd3 += 'SELECT COUNT(*) TOTAL FROM #ChartIDs '
END

IF (@m_ReturnCount = 0)
BEGIN
  SET @cmd1 += '
SELECT c.CHART_ID
  ,c.FACILITY_CHART_ID
  ,c.MEDICAL_RECORD_NUM
  ,c.PATIENT_DOB
  ,c.service_agreement_ID
  ,c.CLIENT_COMMENT
  ,c.CHANGED_DATE_TIME
  ,c.CREATION_DATE_TIME
  ,c.TIME_OF_SERVICE
  ,c.TIME_OF_DIS
  ,c.CODER_COMMENT
  ,c.PATIENT_LAST_NAME
  ,c.PATIENT_FIRST_NAME
  ,c.CHART_STATUS_ID
  ,c.PATIENT_DISPOSITION_ID
  ,c.PENDING_REASON_ID
  ,c.FACILITY_ID
  ,c.SENT_DATE
  ,c.LOCATION_CODE
  ,c.FACILITY_ADMIN_CHART_ID
  ,c.Physician_ID
  ,c.Nurse_Practitioner_ID
  ,c.Patient_Class_ID
  ,c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
  ,c.INITIAL_CHARGE_MASTER_DEPT_ID
  ,f.[NAME] FACILITY
  ,sa.SERVICE_MODEL_CD + CONVERT(varchar(10), up.USER_CLASS_CD) AS ServiceModelCode
  ,up.FIRST_NAME
  ,up.LAST_NAME
  ,c.ASSIGNED_TO_ID
INTO #ChartSubset
FROM #ChartIDs t
  INNER join CHART c WITH (NOLOCK) ON c.chart_ID = t.chart_ID
  INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
  INNER JOIN USER_PROFILE up WITH (NOLOCK) ON up.USER_PROFILE_ID = c.ASSIGNED_TO_ID
  INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID'
END

-- Build the Query
IF (@m_ReturnCount = 0)
BEGIN	
    SET @cmd += '

SELECT c.FACILITY
  ,c.CHART_ID
  ,c.FACILITY_CHART_ID
  ,c.MEDICAL_RECORD_NUM
  ,c.PATIENT_DOB
  ,(
    SELECT TOP 1 IMPORT_IMAGE.CREATION_DATE_TIME
    FROM IMPORT_IMAGE WITH (NOLOCK)
    WHERE IMPORT_IMAGE.FACILITY_CHART_ID = c.FACILITY_CHART_ID
      AND IMPORT_IMAGE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    ORDER BY IMPORT_IMAGE.CREATION_DATE_TIME DESC
  ) LAST_IMAGE_RECEIPT_DATE
  ,c.CLIENT_COMMENT
  ,c.CHANGED_DATE_TIME
  ,CASE 
    WHEN (
      c.FACILITY_CHART_ID IN (
        SELECT DISTINCT ii.FACILITY_CHART_ID
        FROM IMPORT_IMAGE ii WITH (NOLOCK)
        WHERE ii.FACILITY_CHART_ID = c.FACILITY_CHART_ID
          AND ii.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      )
    )
    THEN ''Yes''
    ELSE ''No''
  END [EMR?]
  ,''Yes'' [Census?]
  ,c.CREATION_DATE_TIME Received
  ,c.TIME_OF_SERVICE DOS
  ,c.TIME_OF_DIS DISCHARGE
  ,cs.[DESCRIPTION] [STATUS]
  ,CASE WHEN c.CHART_STATUS_ID in (2, 6)
    THEN (
      SELECT STUFF(
        (
          SELECT ''|'' + pr.DESCRIPTION
          FROM CHART_PENDING_REASON WITH (NOLOCK),
            SERVICE_AGREEMENT_PENDING_REASON sap WITH (NOLOCK),
            PENDING_REASON pr WITH (NOLOCK)
          WHERE CHART_ID = c.CHART_ID
            AND sap.SERVICE_AGREEMENT_PENDING_REASON_ID = CHART_PENDING_REASON.SERVICE_AGREEMENT_PENDING_REASON_ID
            AND sap.PENDING_REASON_ID = pr.PENDING_REASON_ID
          ORDER BY sap.RANK_VALUE
          FOR XML PATH('''')
        ), 1, 1, '''')
      )
    ELSE ''''
  END [Pending Reason]
  ,pd.[DESCRIPTION] [Patient Disposition]
  ,c.CODER_COMMENT AS [Coder Notes]
  ,c.PATIENT_LAST_NAME + '', '' + c.PATIENT_FIRST_NAME [Patient]
  ,fp.LAST_NAME + '', '' + fp.FIRST_NAME + '' '' + fp.NAME_SUFFIX + '' ('' + fp.EMPLOYEE_IDENTIFIER + '')'' Physician
  ,c.CHART_STATUS_ID
  ,ISNULL(PATIENT_CLASS.DESCRIPTION, ''All'') PatientClass
  ,c.PATIENT_DISPOSITION_ID
  ,c.PENDING_REASON_ID
  ,c.FACILITY_ID
  ,c.SENT_DATE SENT
  ,c.LOCATION_CODE
  ,mlp.LAST_NAME + '', '' + mlp.FIRST_NAME + '' '' + mlp.NAME_SUFFIX + '' ('' + mlp.EMPLOYEE_IDENTIFIER + '')'' [Mid-Level]
  ,sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC
  ,cmd.NAME as [InitialObservationDept]
  ,c.FACILITY_ADMIN_CHART_ID
  ,c.ServiceModelCode [Service Model Code]
  ,c.FIRST_NAME [First Name]
  ,c.LAST_NAME [Last Name]
  ,pba.ChartPostBillAuditStatusTypeCode [ChartPostBillAuditStatusTypeCode]
FROM #ChartSubset as c
  LEFT JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = c.PHYSICIAN_ID
    and c.physician_ID > -1  -- reduces LReads by 70-90% on Facility_Professional
  LEFT JOIN FACILITY_PROFESSIONAL mlp WITH (NOLOCK) ON mlp.FACILITY_PROF_ID = c.NURSE_PRACTITIONER_ID
    and c.NURSE_PRACTITIONER_ID > -1 '	-- reduces LReads by 70-90% on Facility_Professional 
  + '
  --INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
  INNER JOIN CHART_STATUS cs WITH (NOLOCK) ON cs.CHART_STATUS_ID = c.CHART_STATUS_ID
  LEFT JOIN PATIENT_CLASS WITH (NOLOCK) ON PATIENT_CLASS.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
  LEFT JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
  LEFT JOIN SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao WITH (NOLOCK) ON sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
  LEFT JOIN CHARGE_MASTER_DEPARTMENT cmd WITH (NOLOCK) ON cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
    and c.INITIAL_CHARGE_MASTER_DEPT_ID > -1 ' -- reduces LReads by 90% on Charge_Master_Department 
  + '
  LEFT JOIN
    (	'-- reduces LReads by 25% on Import_Image (compared to having two subqueries in the SELECT statement)
    + '
      SELECT Facility_Chart_ID, Service_Agreement_ID, MaxCreationDT = max(CREATION_DATE_TIME)
      FROM IMPORT_IMAGE WITH (NOLOCK)
      GROUP BY Facility_Chart_ID, Service_Agreement_ID
    ) as ii on c.facility_Chart_ID = ii.facility_chart_ID
        and c.service_agreement_ID = ii.service_agreement_id'
  + '
  LEFT JOIN ChartPostBillAudit pba ON pba.ChartId = c.CHART_ID'
	  
END

IF (NULLIF(@m_Facilities, '') IS NOT NULL)
BEGIN
  

  --IF (NULLIF(@m_Providers, '') IS NOT NULL)
  --BEGIN
  --  SET @WhereClause += '
  --' + @AndStr + 'EXISTS (
  --  SELECT *
  --  FROM dbo.SplitString(''' + @m_Providers + ''','','')
  --  WHERE ITEMS = fp.UPIR_ID

  --  UNION

  --  SELECT *
  --  FROM dbo.SplitString(''' + @m_Providers + ''','','')
  --  WHERE ITEMS = mlp.UPIR_ID
  --)'
  --  SET @AndStr = ' AND '
  --END

--  -- Append where clause to @cmd
--  IF (@WhereClause <> '')
--  BEGIN
--    SET @cmd += '
--WHERE ' + @WhereClause
--    SET @WhereClause = ''
--    SET @AndStr = ''
--  END

  SET @cmd += '

UNION  '

    IF (@m_ReturnCount = 0)
    BEGIN
      SET @cmd2 += 'SELECT xx.FACILITY
  ,-1 CHART_ID
  ,ii.FACILITY_CHART_ID [Patient No.]
  ,'''' MEDICAL_RECORD_NUM
  ,'''' PATIENT_DOB
  ,'''' LAST_IMAGE_RECEIPT_DATE
  ,ii.CLIENT_COMMENT
  ,'''' CHANGED_DATE_TIME
  ,''Yes'' [EMR?]
  ,''No'' [Census?]
  ,ii.CREATION_DATE_TIME Received
  ,ii.DATE_OF_SERVICE DOS
  ,ii.DATE_OF_DISCHARGE DISCHARGE
  ,''Awaiting census record'' [STATUS]
  ,'''' [Pending Reason]
  ,'''' [Patient Disposition]
  ,'''' [Coder Notes]
  ,'''' [Patient]
  ,'''' [Physician]
  ,-1 CHART_STATUS_ID
  ,'''' PatientClass
  ,-1 PATIENT_DISPOSITION_ID
  ,-1 PENDING_REASON_ID
  ,ii.FACILITY_ID
  ,NULL SENT
  ,NULL LOCATION_CODE
  ,'''' [Mid-Level]
  ,'''' OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC
  ,'''' [InitialObservationDept]
  ,'''' FACILITY_ADMIN_CHART_ID
  ,'''' [Service Model Code]
  ,'''' [First Name]
  ,'''' [Last Name] 
  ,NULL [ChartPostBillAuditStatusTypeCode]
FROM #ImageSubset as xx
INNER JOIN IMPORT_IMAGE ii WITH (NOLOCK) on ii.import_image_ID = xx.import_Image_ID'
    END
    ELSE
    BEGIN
        SET @cmd2 += 'SELECT COUNT(*) TOTAL FROM #ImageSubset '
    END

--    IF (@m_DosFrom IS NOT NULL)
--    BEGIN
--      IF (@m_DosFrom = @m_DosTo)
--      BEGIN
--        SET @WhereClause += '
--  ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) = ''' + CONVERT(VARCHAR, @m_DosFrom) + ''''
--        SET @AndStr = ' AND '
--      END
--      ELSE
--      BEGIN
--        SET @WhereClause += '
--  ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_DosFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_DosTo) + ''''
--        SET @AndStr = ' AND '
--      END
--    END
--    ELSE
--      SET @WhereClause += '
--  ' + @AndStr + 'NULLIF(ii.DATE_OF_SERVICE, '''') IS NOT NULL'
--      SET @AndStr = ' AND '
--      IF (@m_ReceivedFrom IS NOT NULL)
--      BEGIN
--        IF (@m_ReceivedFrom = @m_ReceivedTo)
--        BEGIN
--          SET @WhereClause += '
--  ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) = ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''''
--          SET @AndStr = ' AND '
--        END
--        ELSE
--        BEGIN
--          SET @WhereClause += '
--  ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ReceivedTo) + ''''
--          SET @AndStr = ' AND '
--        END
--      END
--
--  -- Append where clause to @cmd2
--  IF (@WhereClause <> '')
--  BEGIN
--    SET @cmd2 += '
--WHERE ' + @WhereClause
--    SET @WhereClause = ''
--    SET @AndStr = ''
--  END
END
ELSE
-- Return empty result set if no facility is selected
BEGIN
  IF (@m_ReturnCount = 0)
  BEGIN
    SET @cmd = '
SELECT NULL FACILITY
  ,NULL CHART_ID
  ,NULL [Patient No.]
  ,NULL MEDICAL_RECORD_NUM
  ,NULL PATIENT_DOB
  ,NULL LAST_IMAGE_RECEIPT_DATE
  ,NULL CLIENT_COMMENT
  ,NULL CHANGED_DATE_TIME
  ,NULL [EMR?]
  ,NULL [Census?]
  ,NULL Received
  ,NULL DOS
  ,NULL DISCHARGE
  ,NULL [STATUS]
  ,NULL [Pending Reason]
  ,NULL [Patient Disposition]
  ,NULL [Coder Notes]
  ,NULL [Patient]
  ,NULL [Physician]
  ,NULL CHART_STATUS_ID
  ,NULL PatientClass
  ,NULL PATIENT_DISPOSITION_ID
  ,NULL PENDING_REASON_ID
  ,NULL FACILITY_ID
  ,NULL SENT
  ,NULL LOCATION_CODE
  ,NULL [Mid-Level]
  ,NULL OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC
  ,NULL [InitialObservationDept]
  ,NULL FACILITY_ADMIN_CHART_ID
  ,NULL [Service Model Code]
  ,NULL [First Name]
  ,NULL [Last Name]
WHERE 1=2'
  END
  ELSE
  BEGIN
    SET @cmd = 'SELECT 0'
  END

--debug
  PRINT '1) Executing the following command.';
  PRINT @cmd;
--end debug

  EXEC(@cmd)
  RETURN
END

IF (@m_ReturnCount = 0)
BEGIN
    SET @OrderByString = CASE @m_OrderBy
            WHEN 0
                THEN 'DOS'
            WHEN 1
                THEN 'c.FACILITY_CHART_ID'
            WHEN 2
                THEN 'c.MEDICAL_RECORD_NUM'
            WHEN 3
                THEN 'RECEIVED'
            WHEN 4
                THEN 'CHANGED_DATE_TIME'
            WHEN 5
                THEN '[EMR?]'
            WHEN 6
                THEN '[Census?]'
            WHEN 7
                THEN 'Received'
            WHEN 8
                THEN 'Status'
            WHEN 9
                THEN '[Pending Reason]'
            WHEN 10
                THEN 'Patient'
            WHEN 11
                THEN 'Physician'
            WHEN 12
                THEN 'DISCHARGE'
            WHEN 13
                THEN 'LAST_IMAGE_RECEIPT_DATE'
            WHEN 14
                THEN 'PatientClass'
            WHEN 15
                THEN 'FACILITY'
            WHEN 16
                THEN 'SENT'
            WHEN 17
                THEN 'LOCATION_CODE'
            WHEN 18
                THEN '[Mid-Level]'
            WHEN 19
                THEN '[InitialObservationDept]'
            WHEN 20
                THEN 'OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC'
            WHEN 21
                THEN 'FACILITY_ADMIN_CHART_ID'
			WHEN 22
                THEN '[Patient Disposition]'
			WHEN 23
                THEN 'c.PATIENT_DOB'
            ELSE 'DOS'
            END
    SET @OrderByString += CASE @m_SortDirection
            WHEN 'ASC'
                THEN ' ASC'
            ELSE ' DESC'
            END
    SET @cmd2 += '
ORDER BY ' + @OrderByString

  -- debug
	PRINT '2) Execute the next 3 commands.';
	PRINT '2a @cmd1';
	PRINT @cmd1;
	PRINT '2b @cmd';
	PRINT @cmd;
	PRINT '2c @cmd2';
	PRINT @cmd2;
  -- end debug

    EXEC (@cmd1 + @cmd + @cmd2);
    RETURN
END
ELSE
BEGIN
SET @cmd = @cmd1 + '

SELECT SUM(TOTAL) 
FROM (
  ' + @cmd3 + @cmd + @cmd2 
  + '
  ) t'

  -- debug
  --PRINT '3) Execute the command.'
  --PRINT @cmd;
  -- end debug

  EXEC(@cmd)
  RETURN
END
END
GO


-- End of 01) DACS-2452 - Alter Stored Procedure dbo].[sp_Get_DashboardPendingReport] - Modify FLAGGED_FOR_POST_BILL_AUDIT_DT filtering.SQL
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
