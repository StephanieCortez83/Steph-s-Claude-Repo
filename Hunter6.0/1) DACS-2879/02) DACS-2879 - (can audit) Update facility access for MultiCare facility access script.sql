----------------------------------------
-- 02) DACS-2879 - (cannot audit) Update facility access for MultiCare facility access script
USE [RevCycleDB]
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
 
rollback tran;
commit tran; 
*/

