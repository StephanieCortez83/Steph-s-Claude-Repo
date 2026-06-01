USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2879 - (cannot audit) Update facility access for MultiCare facility access script.sql

----------------------------------------
-- 01) DACS-2879 - (can audit) Update facility access for MultiCare facility access script.sql
----------------------------------------
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

---------------------------------------------------------------------------------
/*
Production SAIDs, FIDs
Effective 12/13/23 - 2298
	MultiCare Lacey OCED - 2214/2298

Effective 1/1/24 - 1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288
	MultiCare Allenmore Hospital - 935/1061
	MultiCare Auburn Med Center - 936/1062
	MultiCare Bonney Lake - 1276/1377
	MultiCare Covington Medical Center - 939/1059
	MultiCare Deaconess Hospital - 1168/1268
	MultiCare Deaconess Hospital North ED - 1152/1267
	MultiCare Good Samaritan Hospital - 937/1063
	MultiCare Good Samaritan Hospital - Parkland - 1215/1328
	MultiCare Mary Bridge Childrens Hospital - 934/1060
	MultiCare South Hill - 1277/1378
	MultiCare Tacoma General Hospital - 938/1064
	MultiCare TG Federal Way ED - 1628/1750
	MultiCare Valley Hospital - 1169/1269
	MultiCare Yakima Memorial Hospital - 1928/2031
	PRACTICE CHARTS - MultiCare - 1170/1288


Users:
USER_PROFILE_ID	SIGN_ON_ID			EMAIL_ADDRESS
14491			RBEERA				ramyakeerthi.beera@corrohealth.com
12511			MBHANUPRAKASH		bhanuprakashreddy.malapati@corrohealth.com
14487			SBORKAR				samiksha.borkar@corrohealth.com
14539			NGOWRI				nagaarjuna.gowri@corrohealth.com
14543			VGUDISI				viveksai.gudisi@corrohealth.com
14538			SKODAKANDLA			santhosh.kodakandla@corrohealth.com
14545			MKOLLURI			mahesh.kolluri@corrohealth.com
14486			PKOPPU				pavani.koppu@corrohealth.com
14534			DKRISHNAVENAMMA		dandugala.krishnavenamma@corrohealth.com
14494			MMAHESHBABU			mutyala.maheshbabu@corrohealth.com
14493			SMANDELA			syamkumar.mandela@corrohealth.com
14489			DMAURYA				deepak.maurya@corrohealth.com
14537			BMORE				bhausaheb.more@corrohealth.com
14536			PNAGARGOJE			prashant.nagargoje@corrohealth.com
14533			PNARWADE			pravin.narwade@corrohealth.com
14535			PNIKITA				pokale.nikita@corrohealth.com
14541			HSANAPATHI			himaprasad.sanapathi@corrohealth.com
14492			SSAWAKAR			shravan.sawakar@corrohealth.com
14488			TSOWMYA				thogarla.sowmya@corrohealth.com
14544			MSUKANYA			mukkara.sukanya@corrohealth.com
14540			ETUMMAKOMMA			eswarkanth.tummakomma@corrohealth.com
14490			AVENKATASIVA		angadi.venkatasiva@corrohealth.com
*/
---------------------------------------------------------------------------------

-- expect selects to match
SELECT '[dbo].[FACILITY_USER_AUTHORIZATION] count ' = COUNT(*) FROM [dbo].[FACILITY_USER_AUTHORIZATION];
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'FACILITY_USER_AUTHORIZATION', @DestTable = 'FACILITY_USER_AUTHORIZATION_DACS-2879_NOAUDIT';

-- fill a tem table of user profile ids to process
IF OBJECT_ID('tempdb..#TempSignOnIds', 'U') IS NOT NULL	DROP TABLE #TempSignOnIds

SELECT [USER_PROFILE_ID] , [SIGN_ON_ID] INTO #TempSignOnIds FROM [dbo].[USER_PROFILE]
WHERE [SIGN_ON_ID] IN 
(
	 'RBEERA'
	,'MBHANUPRAKASH'			
	,'SBORKAR'					
	,'NGOWRI'					
	,'VGUDISI'					
	,'SKODAKANDLA'				
	,'MKOLLURI'				
	,'PKOPPU'					
	,'DKRISHNAVENAMMA'			
	,'MMAHESHBABU'				
	,'SMANDELA'				
	,'DMAURYA'					
	,'BMORE'					
	,'PNAGARGOJE'				
	,'PNARWADE'				
	,'PNIKITA'					
	,'HSANAPATHI'				
	,'SSAWAKAR'				
	,'TSOWMYA'					
	,'MSUKANYA'				
	,'ETUMMAKOMMA'				
	,'AVENKATASIVA'	
)

DECLARE @TotalToProcessCount INT = (SELECT COUNT(*) FROM #TempSignOnIds); -- expected value is 65 (4 or so on dev server)
SELECT 'User @TotalToProcessCount = ' = @TotalToProcessCount;

IF @TotalToProcessCount <= 0
BEGIN
	PRINT('User Total Process Count <= 0.  Nothing to process.');
	RETURN;
END;


DECLARE @FetchUPId INT;
DECLARE @FetchSOId VARCHAR(100);
DECLARE @ProcessCount INT = 1;
DECLARE cursorTempSignOnIds CURSOR LOCAL FOR SELECT [USER_PROFILE_ID] , [SIGN_ON_ID] FROM #TempSignOnIds;  

OPEN cursorTempSignOnIds;
FETCH NEXT FROM cursorTempSignOnIds	INTO @FetchUPId, @FetchSOId;
		
PRINT('------------------- while loop --------------------');		
WHILE @@FETCH_STATUS = 0  
BEGIN  
	PRINT('Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
		+ ' ): FetchUPId = ' + IIF(@FetchUPId IS NULL, 'NULL', CAST(@FetchUPId AS VARCHAR(50))) 
		+ ' : FetchSOId = ' + IIF(@FetchSOId IS NULL, 'NULL', CAST(@FetchSOId AS VARCHAR(50))));

	EXEC [dbo].[Maintenance_GrantUserAccessToSpecificFacilities]
	  @Facility_id_list = '1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288' -- Production
	 ,@UserProfileId = @FetchUPId  
	 ,@AdministratorUsername = 'MFERRELL'  
	 ,@EffectiveDate = '01/01/24' ,@ExpirationDate = '01/01/25'  
	 ,@CanApproveCharts = 0  
	 ,@AuditApprovalRate = 0  
	 ,@SecondLevelAuditApprovalRate = 1 
	 --,@IncludeDemoSites = 1	 

	EXEC [dbo].[Maintenance_GrantUserAccessToSpecificFacilities]
	  @Facility_id_list = '2298' -- Production
	 ,@UserProfileId = @FetchUPId  
	 ,@AdministratorUsername = 'MFERRELL'  
	 ,@EffectiveDate = '12/13/2023' ,@ExpirationDate = '12/13/2024'  
	 ,@CanApproveCharts = 0  
	 ,@AuditApprovalRate = 0  
	 ,@SecondLevelAuditApprovalRate = 1 

	PRINT('   ------------------------');

	SET @ProcessCount = @ProcessCount + 1;
	FETCH NEXT FROM cursorTempSignOnIds	INTO @FetchUPId, @FetchSOId;		   

END; -- end WHILE

-- cleanup our cursor
CLOSE cursorTempSignOnIds;  
DEALLOCATE cursorTempSignOnIds; 
PRINT('------------------- Done --------------------');		

GO
/*
testing on QA:
select distinct * from service_agreement where service_agreement_id IN (555226,555228,555234) -- gets facility ids for check

begin tran;

EXEC [dbo].[Maintenance_GrantUserAccessToSpecificFacilities]  @Facility_id_list = '555198,555200,555206' ,@UserProfileId = 11428
 ,@AdministratorUsername = 'MFERRELL'   ,@EffectiveDate = '10/26/2023'  ,@ExpirationDate = '10/26/2024'   ,@CanApproveCharts = 0  
 ,@AuditApprovalRate = 0   ,@SecondLevelAuditApprovalRate = 1   ,@IncludeDemoSites = 1; 
 
*/
-- End of 01) DACS-2879 - (cannot audit) Update facility access for MultiCare facility access script.sql
GO

-- Start of 02) DACS-2879 - (can audit) Update facility access for MultiCare facility access script.sql

----------------------------------------
-- 02) DACS-2879 - (cannot audit) Update facility access for MultiCare facility access script
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

---------------------------------------------------------------------------------
/*
Production SAIDs, FIDs
Effective 12/13/23 - 2298
	MultiCare Lacey OCED - 2214/2298

Effective 1/1/24 - 1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288
	MultiCare Allenmore Hospital - 935/1061
	MultiCare Auburn Med Center - 936/1062
	MultiCare Bonney Lake - 1276/1377
	MultiCare Covington Medical Center - 939/1059
	MultiCare Deaconess Hospital - 1168/1268
	MultiCare Deaconess Hospital North ED - 1152/1267
	MultiCare Good Samaritan Hospital - 937/1063
	MultiCare Good Samaritan Hospital - Parkland - 1215/1328
	MultiCare Mary Bridge Childrens Hospital - 934/1060
	MultiCare South Hill - 1277/1378
	MultiCare Tacoma General Hospital - 938/1064
	MultiCare TG Federal Way ED - 1628/1750
	MultiCare Valley Hospital - 1169/1269
	MultiCare Yakima Memorial Hospital - 1928/2031
	PRACTICE CHARTS - MultiCare - 1170/1288


Users:
USER_PROFILE_ID	SIGN_ON_ID			EMAIL_ADDRESS
10837			BPUROHIT			bhartihansraj.purohit@corrohealth.com
14474			SPARAMASIVAM		swetha.paramasivam@corrohealth.com
12604			HKASIREDDIGARI2		haritha.kasireddy@corrohealth.com
10314			KTHIRUMALBABU		keerthana.thirumalbabu@corrohealth.com
11964			SBKASA				kasashunmuki.bhavani@corrohealth.com
11702			RPADMA				rachakonda.padma@corrohealth.com
10539			BSRIJITH			srijith.bitlakunta@corrohealth.com

*/
---------------------------------------------------------------------------------

-- expect selects to match
SELECT '[dbo].[FACILITY_USER_AUTHORIZATION] count ' = COUNT(*) FROM [dbo].[FACILITY_USER_AUTHORIZATION];
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'FACILITY_USER_AUTHORIZATION', @DestTable = 'FACILITY_USER_AUTHORIZATION_DACS-2879_AUDIT';


-- fill a tem table of user profile ids to process
IF OBJECT_ID('tempdb..#TempSignOnIds', 'U') IS NOT NULL	DROP TABLE #TempSignOnIds

SELECT [USER_PROFILE_ID] , [SIGN_ON_ID] INTO #TempSignOnIds FROM [dbo].[USER_PROFILE]
WHERE [SIGN_ON_ID] IN 
(
	 'BPUROHIT'			
	,'SPARAMASIVAM'		
	,'HKASIREDDIGARI2'		
	,'KTHIRUMALBABU'		
	,'SBKASA'				
	,'RPADMA'				
	,'BSRIJITH'			
)

DECLARE @TotalToProcessCount INT = (SELECT COUNT(*) FROM #TempSignOnIds); -- expected value is 65 (4 or so on dev server)
SELECT 'User @TotalToProcessCount = ' = @TotalToProcessCount;

IF @TotalToProcessCount <= 0
BEGIN
	PRINT('User Total Process Count <= 0.  Nothing to process.');
	RETURN;
END;


DECLARE @FetchUPId INT;
DECLARE @FetchSOId VARCHAR(100);
DECLARE @ProcessCount INT = 1;
DECLARE cursorTempSignOnIds CURSOR LOCAL FOR SELECT [USER_PROFILE_ID] , [SIGN_ON_ID] FROM #TempSignOnIds;  

OPEN cursorTempSignOnIds;
FETCH NEXT FROM cursorTempSignOnIds	INTO @FetchUPId, @FetchSOId;
		
PRINT('------------------- while loop --------------------');		
WHILE @@FETCH_STATUS = 0  
BEGIN  
	PRINT('Processing ' + CAST(@ProcessCount AS VARCHAR(20)) + ' of ' + CAST(@TotalToProcessCount AS VARCHAR(20)) 
		+ ' ): FetchUPId = ' + IIF(@FetchUPId IS NULL, 'NULL', CAST(@FetchUPId AS VARCHAR(50))) 
		+ ' : FetchSOId = ' + IIF(@FetchSOId IS NULL, 'NULL', CAST(@FetchSOId AS VARCHAR(50))));

	EXEC [dbo].[Maintenance_GrantUserAccessToSpecificFacilities]
	  @Facility_id_list = '1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288' -- Production
	 ,@UserProfileId = @FetchUPId  
	 ,@AdministratorUsername = 'MFERRELL'  
	 ,@EffectiveDate = '01/01/24' ,@ExpirationDate = '01/01/25'  
	 ,@CanApproveCharts = 1  
	 ,@AuditApprovalRate = 0  
	 ,@SecondLevelAuditApprovalRate = 1 
	 --,@IncludeDemoSites = 1	 

	EXEC [dbo].[Maintenance_GrantUserAccessToSpecificFacilities]
	  @Facility_id_list = '2298' -- Production
	 ,@UserProfileId = @FetchUPId  
	 ,@AdministratorUsername = 'MFERRELL'  
	 ,@EffectiveDate = '12/13/2023' ,@ExpirationDate = '12/13/2024'  
	 ,@CanApproveCharts = 1  
	 ,@AuditApprovalRate = 0  
	 ,@SecondLevelAuditApprovalRate = 1 

	PRINT('   ------------------------');

	SET @ProcessCount = @ProcessCount + 1;
	FETCH NEXT FROM cursorTempSignOnIds	INTO @FetchUPId, @FetchSOId;		   

END; -- end WHILE

-- cleanup our cursor
CLOSE cursorTempSignOnIds;  
DEALLOCATE cursorTempSignOnIds; 
PRINT('------------------- Done --------------------');		

GO
/*
testing on QA:
select distinct * from service_agreement where service_agreement_id IN (555226,555228,555234) -- gets facility ids for check

begin tran;

EXEC [dbo].[Maintenance_GrantUserAccessToSpecificFacilities]  @Facility_id_list = '555198,555200,555206' ,@UserProfileId = 11428
 ,@AdministratorUsername = 'MFERRELL'   ,@EffectiveDate = '10/26/2023'  ,@ExpirationDate = '10/26/2024'   ,@CanApproveCharts = 0  
 ,@AuditApprovalRate = 0   ,@SecondLevelAuditApprovalRate = 1   ,@IncludeDemoSites = 1; 
 
*/

-- End of 02) DACS-2879 - (can audit) Update facility access for MultiCare facility access script.sql
GO

-- Start of 01) DACS-2880 - SQL Script - expire facility list for MultiCare facility expiration script.SQL

----------------------------------------------------
-- 01) DACS-2880 - SQL Script - expire facility list for MultiCare facility expiration script.SQL
----------------------------------------------------
GO

/*
expiration date: 12/31/23

facility list:
	(1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288)

	MultiCare Allenmore Hospital - 935/1061
	MultiCare Auburn Med Center - 936/1062
	MultiCare Bonney Lake - 1276/1377
	MultiCare Covington Medical Center - 939/1059
	MultiCare Deaconess Hospital - 1168/1268
	MultiCare Deaconess Hospital North ED - 1152/1267
	MultiCare Good Samaritan Hospital - 937/1063
	MultiCare Good Samaritan Hospital - Parkland - 1215/1328
	MultiCare Mary Bridge Childrens Hospital - 934/1060
	MultiCare South Hill - 1277/1378
	MultiCare Tacoma General Hospital - 938/1064
	MultiCare TG Federal Way ED - 1628/1750
	MultiCare Valley Hospital - 1169/1269
	MultiCare Yakima Memorial Hospital - 1928/2031
	PRACTICE CHARTS - MultiCare - 1170/1288

user list:
	('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU')

	Adam, Angela				= AADAM
	Akula, Swathi				= SAKULA
	Allakonda, Yogeshwar		= YALLAKONDA
	ANNEPU, JYOTHINADH			= JANNEPU
	Arabale, Samarth			= SARABALE
	Bane, Samiksha Darshan		= SBANE
	Bommana, Rajasekhara Reddy	= RRBOMMANA
	Cletus, John				= JCLETUS
	DURGAPRASAD, GADUSULA		= GPRASAD
	Ghanekar, Swapnil			= SGHANEKAR
	GUNDI, PRAVEEN				= PGUNDI
	Harrington, Michelle		= MHARRINGTON1
	HEGGER, SUSAN				= SHEGGER
	IMTYAZUDDIN, MOHAMMAD		= MIMTYAZUDDIN
	Jagadale, Shubhangi			= SJAGADALE
	Jeyaram, Alageshwari		= AJEYARAM
	Kankal, Gopinath			= GKANKAL
	Katepalli, Harikrishna		= HKATEPALLI
	KUNCHE, MADHURI				= MKUNCHE
	Mali, Supriya				= SMALI1
	Neerudu, Ashwini			= ANEERUDU
	PATIL, JANHAVI				= JPATIL
	Porter, Debbie				= DEPORTER
	RAGHURAM, SUGANYA			= SRAGHURAM
	Raghuraman, Archana			= ARAGHURAMAN
	Ranjith, Nara				= NRANJITH
	Rodda, Nirmala				= NDRODDA
	SANDERS, MEREDITH			= MESANDERS
	Shinde, Sonal Tanaji		= SSHINDE
	VAITY, GITANJALI			= GVAITY1
	VISWANATHAN, BHARATHI		= BVISWANATHAN1
	YELLAPU, SRINIVASA RAO		= SYELLAPU
*/

-------------------------
-- begin tran; -- testing
-------------------------

DECLARE @expirationDate datetime = '12-31-2023';
DECLARE @changedDate datetime = GETDATE();
DECLARE @changingUserId INT = 10149;   -- MFERRELL
DECLARE @changingUserName VARCHAR(50) = 'MFERRELL';

--backup the target table
exec [dbo].[Maintenance_BackupTable] @SrcTable = 'FACILITY_USER_AUTHORIZATION', @DestTable = 'FACILITY_USER_AUTHORIZATION_DACS-2880';

-- User profile id list to process:
SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU');

-- SELECT TOP 1000 * FROM [FACILITY_USER_AUTHORIZATION] WHERE user_profile_id = @targetUId ORDER BY facility_id ASC
DECLARE @countFacsBeforeUpdate INT = (
	SELECT COUNT(*) 
	FROM [FACILITY_USER_AUTHORIZATION] 
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU'))
	AND [EFFECTIVE_DATE] <= GETDATE() 
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	);
	
-- expect 26 for QA, 421 for production
SELECT '@countFacsBeforeUpdate' = @countFacsBeforeUpdate;

DECLARE @countFacsToUpdate INT = (
	SELECT COUNT(*) 
		FROM [FACILITY_USER_AUTHORIZATION] 
		WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU')) 
		AND [EFFECTIVE_DATE] <= GETDATE() 
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
		AND [FACILITY_ID] IN (1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288) 
	);

-- expect 13 for QA, 416 for production
SELECT '@countFacsToUpdate' = @countFacsToUpdate;

PRINT('performing update...')

UPDATE [FACILITY_USER_AUTHORIZATION]
	SET [EXPIRATION_DATE] = @expirationDate
		, [CHANGED_DATE_TIME] = @changedDate
		, [CHANGING_USER_PROFILE_ID] = @changingUserId
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU'))
	AND [EFFECTIVE_DATE] <= GETDATE() 
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	AND [FACILITY_ID] IN (1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288);

DECLARE @countFacsAfterUpdate INT = (
	SELECT COUNT(*) FROM [FACILITY_USER_AUTHORIZATION] 
	WHERE [USER_PROFILE_ID] IN (SELECT [USER_PROFILE_ID] FROM [USER_PROFILE] WHERE [SIGN_ON_ID] IN ('AADAM','SAKULA','YALLAKONDA','JANNEPU','SARABALE','SBANE','RRBOMMANA','JCLETUS','GPRASAD','SGHANEKAR','PGUNDI','MHARRINGTON1','SHEGGER','MIMTYAZUDDIN','SJAGADALE','AJEYARAM','GKANKAL','HKATEPALLI','MKUNCHE','SMALI1','ANEERUDU','JPATIL','DEPORTER','SRAGHURAM','ARAGHURAMAN','NRANJITH','NDRODDA','MESANDERS','SSHINDE','GVAITY1','BVISWANATHAN1','SYELLAPU'))
		AND [EFFECTIVE_DATE] <= GETDATE() 
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= GETDATE())
	);
	
-- expect 26 for QA, 5 (but cannot test this due to lack of write access) for production
SELECT '@countFacsAfterUpdate' = @countFacsAfterUpdate;

-- log the action :[dbo].[Maintenance_LogAdminAction]
DECLARE @comment VARCHAR(500) = 'Expired Facility Authorization records for user list. Stats: [start,updated,result] :: [ ' +  
	CAST(@countFacsBeforeUpdate AS VARCHAR(50)) + ' , ' +  
	CAST(@countFacsToUpdate AS VARCHAR(50)) + ' , ' +  
	CAST(@countFacsAfterUpdate AS VARCHAR(50)) + ']';
DECLARE @stateString VARCHAR(MAX) = 'Facility List: 1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,1269,2031,1288. User Sign On List: AADAM,SAKULA,YALLAKONDA,JANNEPU,SARABALE,SBANE,RRBOMMANA,JCLETUS,GPRASAD,SGHANEKAR,PGUNDI,MHARRINGTON1,SHEGGER,MIMTYAZUDDIN,SJAGADALE,AJEYARAM,GKANKAL,HKATEPALLI,MKUNCHE,SMALI1,ANEERUDU,JPATIL,DEPORTER,SRAGHURAM,ARAGHURAMAN,NRANJITH,NDRODDA,MESANDERS,SSHINDE,GVAITY1,BVISWANATHAN1,SYELLAPU';

exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1061, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1062, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1377, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1059, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1268, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1267, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1063, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1328, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1060, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1378, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1064, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1750, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1269, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  2031, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
exec [dbo].[Maintenance_LogAdminAction] @ObjectId=  1288, @AdministratorUsername = @changingUserName, @ObjectType = 'Facility Authorization', @EventName = 'Updated', @Comment = @comment, @StateString = @stateString;
	
/*
-------------------------
-- testing
-- rollback tran;
-- commit tran;	
-------------------------

FACILITY_AUTH_ID	FACILITY_ID	USER_PROFILE_ID	CREATION_DATE_TIME	CREATING_USER_PROFILE_ID	CHANGED_DATE_TIME	CHANGING_USER_PROFILE_ID	EFFECTIVE_DATE	EXPIRATION_DATE	CAN_APPROVE_CHARTS	AUDIT_APPROVAL_RATE	NUMBER_COMPLETED	AUDIT_PROCEDURE_RATE	PROCEDURE_NUMBER_COMPLETED	ACCOUNT_MANAGER_IND	AUDIT_INFUSION_RATE	INFUSION_NUMBER_COMPLETED	AUDIT_OBSERVATION_RATE	OBSERVATION_NUMBER_COMPLETED	CODER_AUTHORIZED_SERVICE_CODE	FACILITY_PROF_ID	SECOND_LEVEL_AUDIT_APPROVAL_RATE	FORCE_AUDIT	ACTIVE_CHART_ID	FACILITY_USER_AUTHORIZATION_EXPIRATION_DATE_CHANGE_REASON_ID	FACILITY_USER_AUTHORIZATION_EXPIRATION_DATE_CHANGE_OTHER_REASON	EMR_ACCESS_EFFECTIVE_DATE	EMR_ACCESS_EXPIRATION_DATE	ALLOW_EMR_ACCESS	EMR_ACCESS_USER_PROFILE_ID
1	1	1	2007-10-28 19:09:00.000	0	2010-12-20 22:38:00.000	696	2003-01-01 00:00:00.000	2099-12-31 00:00:00.000	1	0	3	0	0	NULL	0	0	0	0	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL

select top 10 * from audit_log order by audit_log_id desc;
[drcmsqlaz03].[RevCycleDB].[dbo].
*/	
-- End of 01) DACS-2880 - SQL Script - expire facility list for MultiCare facility expiration script.SQL
GO

-- Start of 01) DACS-2872 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Second Level Audit].SQL

----------------------------------------------------
-- 01) DACS-2872 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Second Level Audit].SQL
----------------------------------------------------
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 6)
BEGIN
	PRINT('Adding [dbo].[ChartPostBillAuditReasonTypeCode] item [Second Level Audit]');
	INSERT 
		INTO [dbo].[ChartPostBillAuditReasonTypeCode] 
			([ChartPostBillAuditReasonTypeCode], [Key], [DisplayName], [ExternalCode], [Description])
	VALUES 
		(6, 'SecondLevelAudit', 'Second Level Audit', 'SLA', 'Second Level Audit (2nd Level Audit)');
END;

IF NOT EXISTS(SELECT 1 FROM [dbo].[ChartPostBillAuditReasonTypeCode] WHERE [ChartPostBillAuditReasonTypeCode] = 6)
BEGIN
	PRINT('!!!! Failed to add [ChartPostBillAuditReasonTypeCode] item [Second Level Audit] !!!!');
END;

GO

/*
testing: 
SELECT TOP (1000) [ChartPostBillAuditReasonTypeCode]
      ,[Key]
      ,[DisplayName]
      ,[ExternalCode]
      ,[Description]
  FROM [RevCycleDB].[dbo].[ChartPostBillAuditReasonTypeCode]
---
begin tran;
*/

-- End of 01) DACS-2872 - SQL Script - Insert new [ChartPostBillAuditReasonTypeCode] record - [Second Level Audit].SQL
GO

-- Start of 02) DACS-2872 - Stored Procedure - Maintenance_InsertICD_10_DIRECT_PICK.SQL

----------------------------------------------------
-- 02) DACS-2872 - Stored Procedure - Maintenance_InsertICD_10_DIRECT_PICK.SQL
----------------------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_InsertICD_10_DIRECT_PICK]  
	  @Icd10Code AS VARCHAR(10)
	, @DirectPickType AS INT
	, @SequenceNumber AS INT
	, @ShortDescription AS VARCHAR(100)
	, @LongDescription AS VARCHAR(500)
	, @EffectiveDate AS DATETIME
	, @ExpirationDate AS DATETIME = '12-31-2099'
AS  
BEGIN    
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @Icd10Code IS NULL OR LEN(@Icd10Code) <= 0 OR LEN(@Icd10Code) > 10
	BEGIN
		PRINT('@Icd10Code is invalid');
		SELECT 'Result' = '@Icd10Code is invalid';
		RETURN;
	END;
	
	IF @ShortDescription IS NULL OR LEN(@ShortDescription) <= 0 OR LEN(@ShortDescription) > 100
	BEGIN
		PRINT('@ShortDescription is invalid');
		SELECT 'Result' = '@ShortDescription is invalid';
		RETURN;
	END;

	IF @LongDescription IS NULL OR LEN(@LongDescription) > 500
	BEGIN
		PRINT('Setting LongDescription to ShortDescription.');
		SET @LongDescription = @ShortDescription;
	END;
	
	IF @EffectiveDate IS NULL
	BEGIN
		PRINT('Setting EffectiveDate to now.');
		SET @EffectiveDate = GETDATE();
	END;

	IF @ExpirationDate IS NULL
	BEGIN
		PRINT('Setting ExpirationDate to 12-31-2099.');
		SET @ExpirationDate ='12-31-2099';
	END;

	DECLARE @foundCount INT = ( 
		SELECT COUNT(*) 
		FROM 
			[dbo].[ICD_10_DIRECT_PICK] 
		WHERE 
			[ICD_10_CODE] = @Icd10Code 
			AND [EFFECTIVE_DATE] <= @EffectiveDate
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @ExpirationDate)
		);

	IF @foundCount > 0
	BEGIN
		PRINT('This record already exists in the table.  Exiting.');
		SELECT 'Result' = 'This record already exists in the table.  Exiting.';
		RETURN;
	END;
	

	INSERT INTO [dbo].[ICD_10_DIRECT_PICK]
	(
		  [ICD_10_CODE]
		, [DIRECT_PICK_TYPE]
		, [SEQUENCE_NUMBER]
		, [SHORT_DESCRIPTION]
		, [LONG_DESCRIPTION]
		, [EFFECTIVE_DATE]
		, [EXPIRATION_DATE]
	)
	VALUES
	(	  @Icd10Code
		, @DirectPickType
		, @SequenceNumber
		, @ShortDescription
		, @LongDescription
		, @EffectiveDate
		, @ExpirationDate
	)

	SET @foundCount = ( 
		SELECT COUNT(*) 
		FROM 
			[dbo].[ICD_10_DIRECT_PICK] 
		WHERE 
			[ICD_10_CODE] = @Icd10Code 
			AND [EFFECTIVE_DATE] <= @EffectiveDate
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @ExpirationDate)
		);

	IF @foundCount <= 0
	BEGIN
		PRINT('Failed to insert record.');
		SELECT 'Result' = 'Failed to insert record.';
		RETURN;
	END;

	PRINT('SUCCESS');
	SELECT 'Result' = 'SUCCESS'; 

END

GO

/*
testing
begin tran;
exec [dbo].[Maintenance_InsertICD_10_DIRECT_PICK] @Icd10Code = 'testing', @DirectPickType = 1, @SequenceNumber = 77
	, @ShortDescription = 'testing short', @LongDescription = 'testing long', @EffectiveDate = '01-01-2022', @ExpirationDate = '12-30-2099'

exec [dbo].[Maintenance_InsertICD_10_DIRECT_PICK] @Icd10Code = '', @DirectPickType = 1, @SequenceNumber = 77
	, @ShortDescription = 'testing short', @LongDescription = 'testing long', @EffectiveDate = '01-01-2022'

exec [dbo].[Maintenance_InsertICD_10_DIRECT_PICK] @Icd10Code = 'sdfsdfsdf', @DirectPickType = 1, @SequenceNumber = 77
	, @ShortDescription = 'testing short', @LongDescription = 'testing long', @EffectiveDate = '01-01-2022'

select top 10 * from [dbo].[ICD_10_DIRECT_PICK] order by ICD_10_DIRECT_PICK_ID desc;
*/
-- End of 02) DACS-2872 - Stored Procedure - Maintenance_InsertICD_10_DIRECT_PICK.SQL
GO

-- Start of 03) DACS-2872 - Stored Procedure - Maintenance_FindTablesWithColumnName.SQL

----------------------------------------------------
-- 03) DACS-2872 - Stored Procedure - Maintenance_FindTablesWithColumnName.SQL
----------------------------------------------------
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_FindTablesWithColumnName]  
	  @SearchTerm AS VARCHAR(100)
	, @ExactSearch AS BIT = NULL
AS  
BEGIN    
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	IF @SearchTerm IS NULL OR LEN(@SearchTerm) <= 0 OR LEN(@SearchTerm) > 100
	BEGIN
		PRINT('@SearchTerm is invalid');
		RETURN;
	END;
	
	IF @ExactSearch = 1
		PRINT('Using exact search.');
	ELSE
		SET @SearchTerm = '%' + @SearchTerm + '%';


	SELECT
		 c.name  AS 'ColumnName'
		, (SCHEMA_NAME(t.schema_id) + '.' + t.name) AS 'TableName'
	FROM
		sys.columns c
		JOIN sys.tables t ON c.object_id = t.object_id
	WHERE       
		c.name LIKE @SearchTerm
	ORDER BY
		TableName, ColumnName;

END

GO

/*
testing:
exec [dbo].[Maintenance_FindTablesWithColumnName]  @SearchTerm = 'service_agreement_'
exec [dbo].[Maintenance_FindTablesWithColumnName]  @SearchTerm = 'service_agreement_', @ExactSearch = 1
exec [dbo].[Maintenance_FindTablesWithColumnName]  @SearchTerm = 'service_agreement_', @ExactSearch = 0
 

SELECT      c.name  AS 'ColumnName'
            ,(SCHEMA_NAME(t.schema_id) + '.' + t.name) AS 'TableName'
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
WHERE       c.name LIKE '%MyName%'
ORDER BY    TableName, ColumnName;
			
Search Tables and Views:
SELECT      COLUMN_NAME AS 'ColumnName'
            ,TABLE_NAME AS  'TableName'
FROM        INFORMATION_SCHEMA.COLUMNS
WHERE       COLUMN_NAME LIKE '%MyName%'
ORDER BY    TableName, ColumnName;
*/
-- End of 03) DACS-2872 - Stored Procedure - Maintenance_FindTablesWithColumnName.SQL
GO

-- Start of 01) DACS-2885 - SQL Script - Update Observation Exclusions for Common Spirit - STL - Memorial Lufkin 2122,2161.SQL

----------------------------------------
-- 01) DACS-2885 - SQL Script - Update Observation Exclusions for Common Spirit - STL - Memorial Lufkin 2122,2161.SQL
----------------------------------------
GO


-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
DECLARE @CHANGING_USER_PROFILE_ID int =								10149; -- Mr. Ferrell.
DECLARE @SERVICE_AGREEMENT_ID_TARGET int =							2122;  
DECLARE @FACILITY_ID_TARGET int =									2161;  
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED int;

-- Use this to see what reasons already exist for this SA.
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
    @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Step 2a)
-- replacing the defaults since this is a brand new site.  This is a bit outside the normal behavior.
/*
-1	16	Blood Transfusion
-1	17	GI Lab Procedures
-1	18	Cath Lab Procedures
-1	19	Surgery
-1	20	Monitored Infusions
have to append a space to make the description not match the default values so that the Qualify insert sproc will run
then after inserts fix the description fields.
*/

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Blood Transfusion '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'GI Lab Procedures '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Cath Lab Procedures '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Surgery '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Monitored Infusions '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

UPDATE OBSERVATION_EXCLUSION_HOURS_REASON
	SET [DESCRIPTION] = RTRIM([DESCRIPTION]) 
	WHERE SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Step 2)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Radiology'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Fluoroscopy'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Therapy - OT,PT,ST'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;


-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly.
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
    @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;


--============================================================--
--============================================================--
-- TOOLS:
--============================================================--
--============================================================--

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
-- 	@SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Use this to see what reasons already exist for this SA.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
--  @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;
-- End of 01) DACS-2885 - SQL Script - Update Observation Exclusions for Common Spirit - STL - Memorial Lufkin 2122,2161.SQL
GO

-- Start of 02) DACS-2885 - SQL Script - Update Observation Exclusions for Common Spirit - STL - Memorial Livingston 2170,2269.SQL

----------------------------------------
-- 02) DACS-2885 - SQL Script - Update Observation Exclusions for Common Spirit - STL - Memorial Livingston 2170,2269.SQL
----------------------------------------
GO


-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
DECLARE @CHANGING_USER_PROFILE_ID int =								10149; -- Mr. Ferrell.
DECLARE @SERVICE_AGREEMENT_ID_TARGET int =							2170;  
DECLARE @FACILITY_ID_TARGET int =									2269;  
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED int;

-- Use this to see what reasons already exist for this SA.
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
    @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Step 2a)
-- replacing the defaults since this is a brand new site.  This is a bit outside the normal behavior.
/*
-1	16	Blood Transfusion
-1	17	GI Lab Procedures
-1	18	Cath Lab Procedures
-1	19	Surgery
-1	20	Monitored Infusions
have to append a space to make the description not match the default values so that the Qualify insert sproc will run
then after inserts fix the description fields.
*/

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Blood Transfusion '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'GI Lab Procedures '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Cath Lab Procedures '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Surgery '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Monitored Infusions '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

UPDATE OBSERVATION_EXCLUSION_HOURS_REASON
	SET [DESCRIPTION] = RTRIM([DESCRIPTION]) 
	WHERE SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Step 2)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Radiology'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Fluoroscopy'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Therapy - OT,PT,ST'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;


-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly.
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
    @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;


--============================================================--
--============================================================--
-- TOOLS:
--============================================================--
--============================================================--

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
-- 	@SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Use this to see what reasons already exist for this SA.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
--  @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;
-- End of 02) DACS-2885 - SQL Script - Update Observation Exclusions for Common Spirit - STL - Memorial Livingston 2170,2269.SQL
GO

-- Start of 03) DACS-2885 - TESTING ON QA - SQL Script - Update Observation Exclusions for Common Spirit TEST 555241,555213.SQL

----------------------------------------
-- 03) DACS-2885 - TESTING ON QA - SQL Script - Update Observation Exclusions for Common Spirit TEST 555241,555213.SQL
----------------------------------------
GO


-- Step 1)  Get the needed variables in order to perform the task
--   Some tools are listed at the bottom of this file to help find the required information.
DECLARE @CHANGING_USER_PROFILE_ID int =								10149; -- Mr. Ferrell.
DECLARE @SERVICE_AGREEMENT_ID_TARGET int =							555241;  
DECLARE @FACILITY_ID_TARGET int =									555213;  
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED int;

-- Use this to see what reasons already exist for this SA.
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
    @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Step 2a)
-- replacing the defaults since this is a brand new site.  This is a bit outside the normal behavior.
/*
-1	16	Blood Transfusion
-1	17	GI Lab Procedures
-1	18	Cath Lab Procedures
-1	19	Surgery
-1	20	Monitored Infusions
have to append a space to make the description not match the default values so that the Qualify insert sproc will run
then after inserts fix the description fields.
*/

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Blood Transfusion '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'GI Lab Procedures '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Cath Lab Procedures '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Surgery '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Monitored Infusions '
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

UPDATE OBSERVATION_EXCLUSION_HOURS_REASON
	SET [DESCRIPTION] = RTRIM([DESCRIPTION]) 
	WHERE SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Step 2)  Insert new OBSERVATION_EXCLUSION_HOURS_REASON entries
-- (Repeat the for each unique Description required)

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Radiology'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Fluoroscopy'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;

exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_QUALIFY_INSERT]
	 @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET
	,@OBSERVATION_EXCLUSION_HOURS_REASON_DESCRIPTION = 'Therapy - OT,PT,ST'
	,@OBSERVATION_EXCLUSION_HOURS_REASON_ID = @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED OUTPUT;


-- Use this to see what reasons exist for this SA after inserts.  Check that they all inserted correctly.
exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
    @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;


--============================================================--
--============================================================--
-- TOOLS:
--============================================================--
--============================================================--

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
-- 	@SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

-- Use this to see what reasons already exist for this SA.
-- exec [dbo].[OBSERVATION_EXCLUSION_HOURS_REASON_SELECT_DISTINCT_BY_SERVICE_AGREEMENT_ID]
--  @SERVICE_AGREEMENT_ID = @SERVICE_AGREEMENT_ID_TARGET;

/*
DECLARE @CHANGING_USER_PROFILE_ID int =								10149; -- Mr. Ferrell.
DECLARE @SERVICE_AGREEMENT_ID_TARGET int =							2122;  
DECLARE @FACILITY_ID_TARGET int =									2161;  
DECLARE @OBSERVATION_EXCLUSION_HOURS_REASON_ID_GENERATED int;

SELECT DISTINCT 
	 [SERVICE_AGREEMENT_ID]
	,[EXCLUSION_HOURS_REASON_ID]
	,[DESCRIPTION]
FROM [drcmsqlaz03].[RevCycleDB].[dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] with (NOLOCK)
WHERE
	([SERVICE_AGREEMENT_ID] = @SERVICE_AGREEMENT_ID_TARGET);

SET @SERVICE_AGREEMENT_ID_TARGET = 2170 ;
SET @FACILITY_ID_TARGET = 2269;

SELECT DISTINCT 
	 [SERVICE_AGREEMENT_ID]
	,[EXCLUSION_HOURS_REASON_ID]
	,[DESCRIPTION]
FROM [drcmsqlaz03].[RevCycleDB].[dbo].[OBSERVATION_EXCLUSION_HOURS_REASON] with (NOLOCK)
WHERE
	([SERVICE_AGREEMENT_ID] = @SERVICE_AGREEMENT_ID_TARGET);
	
select distinct top 15 * from OBSERVATION_EXCLUSION_HOURS_REASON order by EXCLUSION_HOURS_REASON_ID asc
begin tran;
*/
-- End of 03) DACS-2885 - TESTING ON QA - SQL Script - Update Observation Exclusions for Common Spirit TEST 555241,555213.SQL
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
