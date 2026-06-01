
USE [RevCycleDB]
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
	@ChartPostBillAuditCompletedDtTo DATE = NULL
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