--------------------------------------------------------------------
-- 02) DACS-2246 - Populate [RevCycleDB].[dbo].[SERVICE_AGREEMENT_PAYOR] .sql
--------------------------------------------------------------------
USE RevCycleDB
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


  


