Use RevCycleDB
GO

---------------------------------------------------------------------------------  
-- Purpose - Grant access to given user on all facilities  
-- Created By - Kalpana Panwar  
-- Created On - 08/07/2023
---------------------------------------------------------------------------------  
--USAGE
--EXEC [dbo].[Maintenance_GrantUserAccessToSpecificFacilities] 
--@Facility_id_list = '1353,581,1510,724,1511,672,1512,988,1266,1362,733,725,734,706,707,1350,708,726,965,940,983,939,937,938,985,934,1155,1542,1543,1544,1545,1546,1548,1549,1550,1551,
--1552,1553,1911,1554,1555,1556,1557,1558,1559,1560,1562,1951,1950,1945,1946,1949,1948,1947,1056,1236,1235,1237,466,1340,703,417,1777,1779,1778,1759,810,1160,975,1039,1139,989,974,1286,1106,
--1109,1137,1003,1066,410,409,1028,1140,973,1030,1143,1159,1145,1144,1029,990,1031,1161,1142,1107,1138,1163,1171,1912,1173,1916,1209,1914,1219,1180,1913,1187,1920,1908,1931,1194,1178,1924,1177,
--1926,1172,1927,1942,1928,1206,1175,1929,1930,1190,1183,1943,1952,1203,1189,1932,1185,1933,1197,1934,1536,1935,1192,1936,1937,1195,1188,1938,1193,1939,1174,1940,1186,1196,1941,1860,1527,276,277,
--1254,914,529,1013,525,526,527,528,1879,1776,1289,797,1790,1758,1565,1528,1566,1519,1697,1564,1526,1521,1569,1568,1520,1522,1655,1537,1656,1567,1501,1771,1993,1326,1873,1854,1899,1900,1872,1903,
--1964,1874,1897,1896,1904,916,597,596,1794,598,1923,595,900,901,532,1068,1162,1158,1880,1150,954,1042,1393,1534,795,1098,1101,1103,1099,1314,865,1032,1270,427,1184,1997,1036,1034,1035,1642,963,
--960,961,962,894,881,1382,1321,1294,1310,1503,1502,1856,1643,1489,1490,1765,1839,1766,1840,1841,1767,1768,1842,1769,1843,1770,1844,1764,1845,637,1308,1224,1225,925,295,472,361,311,394,327,454,
--964,368,348,1648,291,370,297,699,307,362,995,1356,359,360,347,286,319,554,284,358,325,516,405,727,329,334,412,296,318,401,317,339,310,893,323,324,356,972,499,431,313,308,398,336,1307,377,376,
--885,1232,320,1204,304,404,1748,302,906,1539,1334,1563,478,950,997,449,236,1906,1907,1336,1922,1538,1341,1343,1969,1316,1317,1773,1772,1061,1062,1377,1059,1268,1267,1063,1328,1060,1378,1064,1750,
--1269,1847,1848,1849,1850,1851,1852,534,945,905,819,710,1689,1688,1717,1664,1698,1665,1699,1836,1865,1653,1652,1666,1700,1667,1701,1668,1718,1702,713,1746,1669,1703,1670,1704,1719,1671,1705,1234,
--1257,1734,1735,1726,1727,1738,1739,1747,1754,1793,1809,912,721,718,722,1959,1960,1961,1679,1713,1728,1729,1745,1925,1918,1672,1706,1720,1736,1737,1730,1731,1744,1673,1707,1721,1674,1708,1722,1743,
--1041,719,1088,1723,1675,1709,1677,1711,1676,1710,1740,1741,1732,1733,913,720,993,992,1293,994,924,1019,1020,1373,1181,1017,1018,1374,1148,1999,2005,2004,2000,1998,1905,1761,1182,1375,1517,1662,
--1475,1516,1392,1725,1122,1121,1170,1123,1119,1117,1118,1116,1115,1114,1120,1878,1863,1862,1864,1861,1877,1876,757,1452,272,273,1724,530,262,1426,1488,1890,1348,1349,1465,1365,1491,1492,349,1464,
--1469,1354,1361,1384,1830,1241,1240,1238,1752,1751,1753,1857,1858,1859,1389,1239,922,1716,1714,1715,1958,389,669,996,768,1968,1994,1967,1962,1965,1996,2002,1985,1970,866,1749,1775,862,861,864,863,
--826,779,955,1311,1242,678,971,632,694,695,956,623,957,1910,458,1233,732,1683,1682,1681,1680,1783,1782,1784,1785,1786,1787,1789,1791,1797,1792,1798,1802,1795,1796,1803,1804,1805,1799,1800,1801,
--1810,1811,1812,1813,1817,1814,1815,1816,1818,1819,1824,1825,1826,1827,1821,1820,1822,1823,1828,1831,1953,1832,1954,1834,1955,1833,1956,1835,1957,1866,1867,1868,1869,1870,1846,1855,1871,1881,1882,
--1883,1884,1885,1909,1044,1372,1915,1755,1479,1480,1983,1686,1482,1687,1476,1481,876,793,1875,897,1774,1459,896,1462,1460,1458,1461',
--@UserProfileId = 10245, @AdministratorUsername = 'MFERRELL', @EffectiveDate = '8/7/2023 12:00:00 AM', @ExpirationDate = '12/31/2099 12:00:00 AM'  

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_GrantUserAccessToSpecificFacilities]  
  @Facility_id_list AS VARCHAR(MAX)
 ,@UserProfileId        AS INT = NULL  
 ,@Username         AS VARCHAR(15) = NULL  
 ,@AdministratorUsername      AS VARCHAR(15)  
 ,@EffectiveDate        AS DATETIME  
 ,@ExpirationDate       AS DATETIME  
 ,@AllowAutomationFacilitiesOnly AS BIT = 0  
 ,@CanApproveCharts       AS BIT = 0  
 ,@AuditApprovalRate       AS BIT = 0  
 ,@SecondLevelAuditApprovalRate  AS BIT = 0   
AS  
BEGIN  
  
 SET NOCOUNT ON  
  
 BEGIN TRANSACTION  
  
 BEGIN TRY  
  DECLARE @RowCount      INT   
  DECLARE @RowCountFound     INT  
  DECLARE @FacilityComment    VARCHAR(255)  
  DECLARE @FacilityId      INT  
  DECLARE @FacilityAuthId     INT  
  DECLARE @StateString     VARCHAR(MAX)  
  DECLARE @OutputAuditLogObjectStateId INT  
  DECLARE @OutputAuditLogId    INT  
  DECLARE @AdministratorUserProfileId  INT  
  DECLARE @AdministratorEmailAddress  VARCHAR(50)  
  DECLARE @AdministratorFirstName   VARCHAR(25)  
  DECLARE @AdministratorLastName   VARCHAR(25)  
  
  ---------------------------------------------------------  
  -- GET ADMINISTRATOR INFO  
  -------------------------------------------------------  

  SELECT  
   @AdministratorUserProfileId = [USER_PROFILE].[USER_PROFILE_ID]  
   ,@AdministratorEmailAddress = [USER_PROFILE].[EMAIL_ADDRESS]  
   ,@AdministratorFirstName = [USER_PROFILE].[FIRST_NAME]  
   ,@AdministratorLastName = [USER_PROFILE].[LAST_NAME]  
  FROM  
   [dbo].[USER_PROFILE] WITH (NOLOCK)   
  WHERE  
   [USER_PROFILE].[SIGN_ON_ID] = @AdministratorUsername   
  
  IF @ROWCOUNT > 1  
  BEGIN  
   RAISERROR('Found multiple users with Username %s', 16, 1, @AdministratorUsername) WITH NOWAIT  
   RETURN  
  END  
    
  IF @AdministratorUserProfileId IS NULL   
  BEGIN  
   RAISERROR('%d Creating User Profile ID not found in the system.', 16, 1, @AdministratorUserProfileId) WITH NOWAIT  
   RETURN  
  END  
  
  IF @UserProfileId IS NULL AND @Username IS NULL  
  BEGIN    
   RAISERROR('Please provide a User Profile ID OR Sign On ID to grant access', 16, 1) WITH NOWAIT  
   RETURN   
  END  
  
  IF @UserProfileId IS NOT NULL AND @Username IS NOT NULL  
  BEGIN  
   IF NOT EXISTS(SELECT 1 FROM [USER_PROFILE] WITH (NOLOCK) WHERE [USER_PROFILE].[SIGN_ON_ID] = @Username AND [USER_PROFILE].[USER_PROFILE_ID] = @UserProfileId)  
   BEGIN  
    RAISERROR('User Profile ID %d AND Sign On ID %s combination not found in the system.', 16, 1, @UserProfileId, @Username) WITH NOWAIT     
    RETURN  
   END  
  END  
  ELSE IF @Username IS NOT NULL  
  BEGIN  
   SELECT @UserProfileId = [USER_PROFILE].[USER_PROFILE_ID] FROM [USER_PROFILE] WITH (NOLOCK) WHERE [USER_PROFILE].[SIGN_ON_ID] = @Username  
    
   IF @UserProfileId IS NULL  
   BEGIN  
    RAISERROR('%s Sign On ID not found in the system.', 16, 1, @Username) WITH NOWAIT     
    RETURN  
   END  
  END  
  ELSE IF @UserProfileId IS NOT NULL  
  BEGIN  
   IF NOT EXISTS(SELECT 1 FROM [USER_PROFILE] WITH (NOLOCK) WHERE [USER_PROFILE].[USER_PROFILE_ID] = @UserProfileId)  
   BEGIN  
    RAISERROR('%d User Profile ID not found in the system.', 16, 1, @UserProfileId) WITH NOWAIT     
    RETURN  
   END  
  END  
  
  IF @EffectiveDate IS NULL  
  BEGIN  
   RAISERROR('Effective Date is required', 16, 1)  
  END  
   
  IF @ExpirationDate IS NULL  
  BEGIN  
   RAISERROR('Expiration Date is required', 16, 1)  
  END  
     
  SELECT DISTINCT [SERVICE_AGREEMENT].[FACILITY_ID]  
  INTO #FacilityUserAuthorization  
  FROM [SERVICE_AGREEMENT]
  WHERE   
      
  -- make sure it's not a demo service agreement  
  (  
   [SERVICE_AGREEMENT].[DEMO_TEST_SITE_IND] IS NULL   
   OR   
   [SERVICE_AGREEMENT].[DEMO_TEST_SITE_IND] = 0  
  )  
  AND [SERVICE_AGREEMENT].[DESCRIPTION] NOT LIKE 'Practice%'  
  AND [SERVICE_AGREEMENT].[DESCRIPTION] NOT LIKE 'Demo%'  
      
  -- make sure it's only for non-expired service agreements  
  AND [SERVICE_AGREEMENT].[EXPIRATION_DATE] > GETDATE()  
      
  -- make sure the user doesn't already have a facility user authorizaton for the current facility id  
  AND [SERVICE_AGREEMENT].[FACILITY_ID] NOT IN   
  (  
   -- get a list of the user's current authorized facilties  
   SELECT [FACILITY_USER_AUTHORIZATION].[FACILITY_ID]   
   FROM [FACILITY_USER_AUTHORIZATION]  
   WHERE [FACILITY_USER_AUTHORIZATION].[USER_PROFILE_ID] = @UserProfileId   
    AND @EffectiveDate BETWEEN [FACILITY_USER_AUTHORIZATION].[EFFECTIVE_DATE] AND [FACILITY_USER_AUTHORIZATION].[EXPIRATION_DATE]  
  )   
  
  -- make sure the user doesn't already have a FUTURE facility user authorizaton for the current facility id  
  AND [SERVICE_AGREEMENT].[FACILITY_ID] NOT IN   
  (  
   SELECT [FACILITY_USER_AUTHORIZATION].[FACILITY_ID]   
   FROM [FACILITY_USER_AUTHORIZATION]  
   WHERE [FACILITY_USER_AUTHORIZATION].[USER_PROFILE_ID] = @UserProfileId   
    AND [FACILITY_USER_AUTHORIZATION].[EFFECTIVE_DATE] > @EffectiveDate  
  )   
  
  ---- only authorize to automation facilities if required  
  AND   
  (   
   @AllowAutomationFacilitiesOnly = 0  
   OR  
   @AllowAutomationFacilitiesOnly = 1 AND [SERVICE_AGREEMENT].[AUTOMATION_CODING_ENABLED] = 1  
  )  
  AND
  EXISTS (SELECT * FROM  dbo.SplitString(@Facility_id_list, ',') WHERE items = [SERVICE_AGREEMENT].[FACILITY_ID])

  SET @RowCount = @@ROWCOUNT  
  SET @RowCountFound  = @RowCount      
  
  WHILE(@RowCount > 0)  
  BEGIN     
   SET @RowCount = @RowCount - 1  
  
   SELECT @FacilityId = [FACILITY_ID]  
   FROM #FacilityUserAuthorization
   ORDER BY [FACILITY_ID]  
   OFFSET @RowCount ROWS   
   FETCH NEXT 1 ROWS ONLY;  

   INSERT INTO [dbo].[FACILITY_USER_AUTHORIZATION]  
   (  
     [FACILITY_ID]  
    ,[USER_PROFILE_ID]  
    ,[CREATION_DATE_TIME]  
    ,[CREATING_USER_PROFILE_ID]  
    ,[CHANGED_DATE_TIME]  
    ,[CHANGING_USER_PROFILE_ID]  
    ,[EFFECTIVE_DATE]  
    ,[EXPIRATION_DATE]  
    ,[CAN_APPROVE_CHARTS]  
    ,[AUDIT_APPROVAL_RATE]  
    ,[NUMBER_COMPLETED]  
    ,[AUDIT_PROCEDURE_RATE]  
    ,[PROCEDURE_NUMBER_COMPLETED]  
    ,[ACCOUNT_MANAGER_IND]  
    ,[AUDIT_INFUSION_RATE]  
    ,[INFUSION_NUMBER_COMPLETED]  
    ,[AUDIT_OBSERVATION_RATE]  
    ,[OBSERVATION_NUMBER_COMPLETED]  
    ,[CODER_AUTHORIZED_SERVICE_CODE]  
    ,[FACILITY_PROF_ID]  
    ,[SECOND_LEVEL_AUDIT_APPROVAL_RATE]  
    ,[FORCE_AUDIT]  
   )  
   VALUES  
   (  
    @FacilityId,  
    @UserProfileId,  
    GETDATE(),  
    @AdministratorUserProfileId,   
    NULL,   
    NULL,  
    @EffectiveDate,   
    @ExpirationDate,  
    @CanApproveCharts,   
    @AuditApprovalRate,  
    0,   
    0,   
    0,   
    0,  
    0,  
    0,  
    0,  
    0,  
    0,  
    NULL,  
    @SecondLevelAuditApprovalRate,  
    0      
   )  
  
   SELECT @FacilityAuthId = SCOPE_IDENTITY();    
  
   ---------------------------------------------------------------------  
   -- HANDLE LOGGING  
   ---------------------------------------------------------------------  
   -- INSERT "FACILITY AUTHORIZATION" AUDIT LOG & AUDIT LOG OBJECT STATE  
   SET @FacilityComment = 'Inserted authorized facility ID ' + CAST(@FacilityId AS VARCHAR)  
  
   SET @StateString =   '{'  
        + '"Facility Authorization ID":"'   
        + CAST(@FacilityAuthId AS VARCHAR)  
        + '","Facility ID":"'  
        + CAST(@FacilityId AS VARCHAR)  
        + '","User Profile ID":"'  
        + CAST(@UserProfileId AS VARCHAR)  
        + '","Effective Date":"'  
        + FORMAT(CONVERT(DATE, @EffectiveDate), 'MM/dd/yyyy hh:mm:ss tt')   
        + '","Expiration Date":"'  
        + + FORMAT(CONVERT(DATE, @ExpirationDate), 'MM/dd/yyyy hh:mm:ss tt')   
        + '","Can Approve Charts":"'  
        + CASE @CanApproveCharts WHEN 1 THEN 'True' ELSE 'False' END  
        + '","First Level Audit Rate":"'  
        + CASE @AuditApprovalRate WHEN 1 THEN 'True' ELSE 'False' END               
        + '","Number Completed":"0'  
        + '","Audit Procedure Rate":"0'  
        + '","Procedure Number Completed":"0'  
        + '","Account Manager Indicator":"0'  
        + '","Audit Infusion Rate":"0'  
        + '","Infusion Number Completed":"0'  
        + '","Audit Observation Rate":"0'  
        + '","Observation Number Completed":"0'  
        + '","Coder Authorized Service Code":"0'  
        + '","Second Level Audit Rate":"0'  
        + CAST(@SecondLevelAuditApprovalRate AS VARCHAR)  
        + '","Force Audit": "False"'  
        + '}'  
  
   EXEC [dbo].[AUDIT_LOG_INSERT]  
    @OBJECT_TYPE =     'Facility Authorization'  
    ,@OBJECT_ID =      @FacilityAuthId  
    ,@EVENT_NAME =     'Create'  
    ,@COMMENT =      ''  
    ,@CHANGING_USER_PROFILE_ID =  @AdministratorUserProfileId  
    ,@CHANGING_SIGN_ON_ID =   @AdministratorUsername  
    ,@CHANGING_EMAIL_ADDRESS =  @AdministratorEmailAddress  
    ,@CHANGING_FIRST_NAME =   @AdministratorFirstName  
    ,@CHANGING_LAST_NAME =   @AdministratorLastName  
    ,@AUDIT_LOG_ID =     @OutputAuditLogId OUTPUT  
  
   EXEC [dbo].[AUDIT_LOG_OBJECT_STATE_INSERT]  
    @AUDIT_LOG_ID =     @OutputAuditLogId  
    ,@STATE =      @StateString  
    ,@AUDIT_LOG_OBJECT_STATE_ID = @OutputAuditLogObjectStateId  
  
   -- INSERT "USER PROFILE" AUDIT LOG & AUDIT LOG OBJECT STATE  
   EXEC [dbo].[AUDIT_LOG_INSERT]  
    @OBJECT_TYPE =     'User Profile'  
    ,@OBJECT_ID =      @UserProfileId  
    ,@EVENT_NAME =     'Updated'  
    ,@COMMENT =      @FacilityComment  
    ,@CHANGING_USER_PROFILE_ID =  @AdministratorUserProfileId  
    ,@CHANGING_SIGN_ON_ID =   @AdministratorUsername  
    ,@CHANGING_EMAIL_ADDRESS =  @AdministratorEmailAddress  
    ,@CHANGING_FIRST_NAME =   @AdministratorFirstName  
    ,@CHANGING_LAST_NAME =   @AdministratorLastName  
    ,@AUDIT_LOG_ID =     @OutputAuditLogId OUTPUT  
  
   EXEC [dbo].[AUDIT_LOG_OBJECT_STATE_INSERT]  
    @AUDIT_LOG_ID =     @OutputAuditLogId  
    ,@STATE =      @StateString  
    ,@AUDIT_LOG_OBJECT_STATE_ID = @OutputAuditLogObjectStateId   
  END;  
   
  COMMIT TRANSACTION;  
  
  IF @RowCountFound > 0   
   PRINT CAST(@RowCountFound AS VARCHAR) + ' Records Inserted Sucessfully.'  
  ELSE  
   PRINT 'No Records found.'  
      
 END TRY  
 BEGIN CATCH    
  PRINT 'ERROR :: ' + ERROR_MESSAGE()  
  PRINT 'Rolling back transaction'  
  IF (@@TRANCOUNT > 0)  
   ROLLBACK TRAN  
  RAISERROR('Failure. See error message noted above.', 16, 1) WITH NOWAIT  
 END CATCH  
END ;
GO
