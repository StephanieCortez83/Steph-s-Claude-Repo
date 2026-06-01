SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[sp_Get_DashboardPendingReport]
    @ReturnCount bit = 0,
    @DosFrom date = NULL,
    @DosTo date = NULL,
    @ReceivedFrom date = NULL,
    @ReceivedTo date = NULL,
    @SentFrom date = NULL,
    @SentTo date = NULL,
    @ChartStatuses varchar(50) = '',
    @PendingReasons varchar(MAX) = NULL,
    @Facilities varchar(MAX) = NULL,
    @MedicalRecordNumber varchar(25) = '',
    @FacilityChartIdentifier varchar(25) = '',
    @FacilityAdminChartID varchar(25) = '',       
    @ClinicID varchar(10) = '',
    @PatientClassID int = - 1,
    @LocationCodes varchar(MAX) = NULL,
    @Providers varchar(MAX) = NULL,
    @ObservationDepartments varchar(MAX) = NULL,
    @OrderBy int = 0, -- DOS
    @SortDirection varchar(4) = 'ASC',
    @ChartSearchMaxCount int = 3000,
	@ChartPostBillAuditStatus int = 0,
	@ChartPostBillAuditStartDtFrom date = NULL,
	@ChartPostBillAuditStartDtTo date = NULL,
	@ChartPostBillAuditCompletedDtFrom date = NULL,
	@ChartPostBillAuditCompletedDtTo date = NULL,
	@ChartPostBillAuditFlaggedDtFrom date = NULL,
	@ChartPostBillAuditFlaggedDtTo date = NULL,
	@ChartPostBillAuditFlagged bit = 0,
	@FacilityChartIdentifierList varchar(MAX) = NULL,
	@ImageFilter int = 0,
	@AutomationFilter int = 0,
	@LongPatientId varchar(75) = NULL
	
AS
BEGIN
SET NOCOUNT ON;

DECLARE @Today DATE = GETDATE();

-- Insert statements for procedure here
DECLARE @m_ReturnCount BIT = @ReturnCount
    ,@m_ClinicID VARCHAR(10) = @ClinicID
    ,@m_PatientClassID INT = @PatientClassID
	,@m_ChartPostBillAuditStatus INT = @ChartPostBillAuditStatus
	,@m_ChartPostBillAuditFlagged BIT = @ChartPostBillAuditFlagged
    ,@m_ChartStatuses VARCHAR(50) = @ChartStatuses
    ,@m_PendingReasons VARCHAR(MAX) = @PendingReasons
    ,@m_Facilities VARCHAR(MAX) = @Facilities
    ,@m_MedicalRecordNumber VARCHAR(25) = @MedicalRecordNumber
    ,@m_FacilityChartIdentifier VARCHAR(25) = @FacilityChartIdentifier
    ,@m_FacilityAdminChartID VARCHAR(25) = @FacilityAdminChartID
    ,@m_LocationCodes VARCHAR(MAX) = @LocationCodes
    ,@m_Providers VARCHAR(MAX) = @Providers
    ,@m_ObservationDepartments VARCHAR(MAX) = @ObservationDepartments
    ,@m_OrderBy INT = @OrderBy
    ,@m_SortDirection VARCHAR(4) = @SortDirection
    ,@OrderByString VARCHAR(100)
    ,@cmd VARCHAR(MAX) = ''
    ,@cmd2 VARCHAR(MAX) = ''
    ,@cmd1 VARCHAR(MAX) = ''
    ,@cmd3 VARCHAR(MAX) = ''
    ,@WhereClause VARCHAR(MAX) = ''
    ,@AndStr VARCHAR(5) = ''
    ,@m_ChartSearchMaxCount INT = @ChartSearchMaxCount + 1
	,@m_FacilityChartIdentifierList VARCHAR(MAX) = @FacilityChartIdentifierList
	,@m_ChartPostBillAuditStartDtFrom DATE =		IIF(@ChartPostBillAuditStartDtFrom IS NOT NULL AND ISDATE(CAST(@ChartPostBillAuditStartDtFrom AS VARCHAR(40))) = 1, @ChartPostBillAuditStartDtFrom, NULL)   
	,@m_ChartPostBillAuditStartDtTo DATE = 			IIF(@ChartPostBillAuditStartDtTo IS NOT NULL AND ISDATE(CAST(@ChartPostBillAuditStartDtTo AS VARCHAR(40))) = 1, @ChartPostBillAuditStartDtTo, NULL)
	,@m_ChartPostBillAuditCompletedDtFrom DATE = 	IIF(@ChartPostBillAuditCompletedDtFrom IS NOT NULL AND ISDATE(CAST(@ChartPostBillAuditCompletedDtFrom AS VARCHAR(40))) = 1, @ChartPostBillAuditCompletedDtFrom, NULL)
	,@m_ChartPostBillAuditCompletedDtTo DATE = 		IIF(@ChartPostBillAuditCompletedDtTo IS NOT NULL AND ISDATE(CAST(@ChartPostBillAuditCompletedDtTo AS VARCHAR(40))) = 1, @ChartPostBillAuditCompletedDtTo, NULL)
	,@m_ChartPostBillAuditFlaggedDtFrom DATE = 		IIF(@ChartPostBillAuditFlaggedDtFrom IS NOT NULL AND ISDATE(CAST(@ChartPostBillAuditFlaggedDtFrom AS VARCHAR(40))) = 1, @ChartPostBillAuditFlaggedDtFrom, NULL)
	,@m_ChartPostBillAuditFlaggedDtTo DATE = 		IIF(@ChartPostBillAuditFlaggedDtTo IS NOT NULL AND ISDATE(CAST(@ChartPostBillAuditFlaggedDtTo AS VARCHAR(40))) = 1, @ChartPostBillAuditFlaggedDtTo, NULL)
    ,@m_DosFrom DATE = 								IIF(@DosFrom IS NOT NULL AND ISDATE(CAST(@DosFrom AS VARCHAR(40))) = 1, @DosFrom, NULL)
    ,@m_DosTo DATE = 								IIF(@DosTo IS NOT NULL AND ISDATE(CAST(@DosTo AS VARCHAR(40))) = 1, @DosTo, @Today)
    ,@m_ReceivedFrom DATE = 						IIF(@ReceivedFrom IS NOT NULL AND ISDATE(CAST(@ReceivedFrom AS VARCHAR(40))) = 1, @ReceivedFrom, NULL)
    ,@m_ReceivedTo DATE = 							IIF(@ReceivedTo IS NOT NULL AND ISDATE(CAST(@ReceivedTo AS VARCHAR(40))) = 1, @ReceivedTo, @Today)
    ,@m_SentFrom DATE = 							IIF(@SentFrom IS NOT NULL AND ISDATE(CAST(@SentFrom AS VARCHAR(40))) = 1, @SentFrom, NULL)
    ,@m_SentTo DATE = 								IIF(@SentTo IS NOT NULL AND ISDATE(CAST(@SentTo AS VARCHAR(40))) = 1, @SentTo, @Today)
	;
	 
	 
IF @m_ChartSearchMaxCount > 3001		-- 20241223 - wpippin - DACS-3619
  SET @m_ChartSearchMaxCount = 3001;
	 
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
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) BETWEEN ''' + CONVERT(varchar, @m_DosFrom) + ''' AND ''' + CONVERT(varchar, @m_DosTo) + ''''
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
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) BETWEEN ''' + CONVERT(varchar, @m_ReceivedFrom) + ''' AND ''' + CONVERT(varchar, @m_ReceivedTo) + ''''
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
ELSE
BEGIN
	IF (@m_FacilityChartIdentifierList <> '')
	BEGIN
	  SET @m_FacilityChartIdentifierList = REPLACE(@m_FacilityChartIdentifierList, N' ', N'');
	  SET @m_FacilityChartIdentifierList = REPLACE(@m_FacilityChartIdentifierList, N',,', N',');
	  SET @m_FacilityChartIdentifierList = REPLACE(@m_FacilityChartIdentifierList, N',', N''',''');
	  SET @m_FacilityChartIdentifierList = '''' + @m_FacilityChartIdentifierList + '''';

	  SET @WhereClause += ' 
	 ' + @AndStr + 'c.FACILITY_CHART_ID IN (' + @m_FacilityChartIdentifierList + ')';
 
	  SET @AndStr = ' AND ';
	END  
END

IF (@m_FacilityAdminChartID <> '')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + 'c.FACILITY_ADMIN_CHART_ID LIKE (''' + @m_FacilityAdminChartID + '%'')'
  SET @AndStr = ' AND '
END

IF (@LongPatientId IS NOT NULL)
BEGIN
	SET @LongPatientId = LTRIM(RTRIM(@LongPatientId));
	
	IF LEN(@LongPatientId) > 0
	BEGIN
		PRINT('LPID.')
		SET @WhereClause += ' 
 ' + @AndStr + 'c.LONG_PATIENT_ID1 LIKE (''' + @LongPatientId + '%'')'
		SET @AndStr = ' AND '
	END
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

-- 20241223 - wpippin - DACS-3619  -- correct should likely be: (sa.COLLECT_CLINIC <> ''N'' AND c.CLINIC_ID=@ClinicID) but if the search wants a clinicid, then they get one
-- IF (NULLIF(@m_ClinicID, '') IS NOT NULL       
    -- AND @m_ClinicID <> '-1')
-- BEGIN
  -- SET @WhereClause += ' 
 -- ' + @AndStr + '(
    -- sa.COLLECT_CLINIC = ''N''
    -- OR c.CLINIC_ID = ''' + @m_ClinicID + '''
  -- )'
  -- SET @AndStr = ' AND '
-- END

IF (NULLIF(@m_ClinicID, '') IS NOT NULL       
    AND @m_ClinicID <> '-1')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + '(
    c.CLINIC_ID = ''' + @m_ClinicID + '''
  )'
  SET @AndStr = ' AND '
END
-- end 20241223 - wpippin - DACS-3619  -- correct should likely be: (sa.COLLECT_CLINIC <> ''N'' AND c.CLINIC_ID=@ClinicID) but if the search wants a clinicid, then they get one

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

-- Modified 20250425 - wpippin - DACS-4425 - adjustment to get SPROC back in sync with DACS worked tickets
IF @ImageFilter = 1
BEGIN
	SET @WhereClause += '
 ' + @AndStr + 'c.IMAGES_AVAILABLE = 1'
	SET @AndStr = ' AND '
END
ELSE IF @ImageFilter = 2
BEGIN
	SET @WhereClause += '
 ' + @AndStr + 'c.IMAGES_AVAILABLE = 0'
	SET @AndStr = ' AND '
END

IF @AutomationFilter = 1
BEGIN
	SET @WhereClause += '
 ' + @AndStr + '(c.FACILITY_AUTOMATION_CODING_COMPLETE = 1 OR c.PHYSICIAN_AUTOMATION_CODING_COMPLETE = 1 OR c.FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL OR c.PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL)'
	SET @AndStr = ' AND '
END
ELSE IF @AutomationFilter = 2
BEGIN
	SET @WhereClause += '
 ' + @AndStr + '(c.FACILITY_AUTOMATION_CODING_COMPLETE = 0 OR c.PHYSICIAN_AUTOMATION_CODING_COMPLETE = 0 OR c.FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NULL OR c.PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NULL)'
	SET @AndStr = ' AND '
END
-- end Modified 20250425 - wpippin - DACS-4425 - adjustment to get SPROC back in sync with DACS worked tickets

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
  ,c.LONG_PATIENT_ID1
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
  ,c.LONG_PATIENT_ID1
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
  ,NULL [LONG_PATIENT_ID1]
FROM #ImageSubset as xx
INNER JOIN IMPORT_IMAGE ii WITH (NOLOCK) on ii.import_image_ID = xx.import_Image_ID'
    END
    ELSE
    BEGIN
        SET @cmd2 += 'SELECT COUNT(*) TOTAL FROM #ImageSubset '
    END

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
  ,NULL [LONG_PATIENT_ID1]
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
			WHEN 24
                THEN 'c.LONG_PATIENT_ID1'
            ELSE 'DOS'
            END
    SET @OrderByString += CASE @m_SortDirection
            WHEN 'ASC'
                THEN ' ASC'
            ELSE ' DESC'
            END 
			+ ', c.CHART_ID ' + CASE @m_SortDirection WHEN 'ASC' THEN ' ASC' ELSE ' DESC'  END
    SET @cmd2 += '
ORDER BY ' + @OrderByString

  -- debug
  /*
	PRINT '2) Execute the next 3 commands.';
	PRINT '2a @cmd1';
	PRINT @cmd1;
	PRINT '2b @cmd';
	PRINT @cmd;
	PRINT '2c @cmd2';
	PRINT @cmd2;
	*/
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

-- =============================================
-- Author: Daniel Bonebrake
-- Create date: 12/3/2015
-- Updated date: 1/31/2018 JohnS: Added #ChartIDs temp table to improve performance
-- Modified 20230419 - wpippin - added filtering for [FLAGGED_FOR_POST_BILL_AUDIT_DT] (ACS c# = PostBillAuditFlagged) field
-- Modified 20230501 - wpippin - added filtering for logNotes fields indicating flags for the new PBA audit and new PBA flagged for additional audit notes
-- Modified 20230608 - wpippin - revert logNotes fields behavior back to using [CHART].[FLAGGED_FOR_POST_BILL_AUDIT_DT] and add [FLAGGED_FOR_POST_BILL_AUDIT] [bit] NULL behavior.
-- Modified 20230815 - wpippin - added FacilityChartIdentifierList input parameter
-- Modified 20240802 - wpippin - modify parameter @OrderByString to become VARCHAR(100) per JB's instructions at ~ line # 105
-- Modified 20250425 - wpippin - DACS-4425 - adjustment to get SPROC back in sync with DACS worked tickets
-- Modified 20250922 - wpippin - DACS-4715 - adds date validation to incoming DATE type parameters
-- Modified 20251024 - wpippin - DACS-4824 - adds handling of @LongPatientId parameter
-- =============================================
END
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[sp_Get_DashboardPendingReportByChartIds] 
	 @ChartIds			varchar(MAX)
	,@OrderBy			int			= 0 -- DOS
	,@SortDirection		varchar(4)	= 'A'
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @ChartSearchMaxCount INT = 3001;
			
	SELECT	
		CAST(value AS int) Item
	INTO	
		#ChartIdList
	FROM
		STRING_SPLIT(@ChartIds, ',')
	WHERE	
		LEN(value) > 0;

	DELETE FROM #ChartIdList WHERE [Item] IS NULL OR LEN([Item]) <= 1

	IF NOT EXISTS (SELECT TOP 1 1 FROM #ChartIdList)
		RETURN;

	DROP TABLE IF EXISTS #ChartSubset;

	SELECT TOP (@ChartSearchMaxCount)
			c.CHART_ID
		  , c.FACILITY_CHART_ID																				 
		  , c.MEDICAL_RECORD_NUM																			 
		  , c.PATIENT_DOB																					 
		  , c.SERVICE_AGREEMENT_ID																			 
		  , c.CLIENT_COMMENT																				 
		  , c.CHANGED_DATE_TIME																				 
		  , c.CREATION_DATE_TIME																			 
		  , c.TIME_OF_SERVICE																				 
		  , c.TIME_OF_DIS																					 
		  , c.CODER_COMMENT																					 
		  , c.PATIENT_LAST_NAME																				 
		  , c.PATIENT_FIRST_NAME																			 
		  , c.CHART_STATUS_ID																				 
		  , c.PATIENT_DISPOSITION_ID																		 
		  , c.PENDING_REASON_ID																				 
		  , c.FACILITY_ID																					 
		  , c.SENT_DATE																						 
		  , c.LOCATION_CODE																					 
		  , c.FACILITY_ADMIN_CHART_ID																		 
		  , c.PHYSICIAN_ID																					 
		  , c.NURSE_PRACTITIONER_ID																			 
		  , c.PATIENT_CLASS_ID																				 
		  , c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID															 
		  , c.INITIAL_CHARGE_MASTER_DEPT_ID																	 
		  , f.[NAME]														FACILITY 				 
		  , sa.SERVICE_MODEL_CD + CAST(up.USER_CLASS_CD AS varchar(10))  	AS ServiceModelCode		 
		  , up.FIRST_NAME
		  , up.LAST_NAME
		  , c.ASSIGNED_TO_ID
	INTO	#ChartSubset
	FROM	dbo.CHART						 c WITH (NOLOCK)
			INNER JOIN dbo.FACILITY			 f WITH (NOLOCK)
				ON f.FACILITY_ID = c.FACILITY_ID
			INNER JOIN dbo.USER_PROFILE		 up WITH (NOLOCK)
				ON up.USER_PROFILE_ID = c.ASSIGNED_TO_ID
			INNER JOIN dbo.SERVICE_AGREEMENT sa WITH (NOLOCK)
				ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
	WHERE	c.CHART_ID IN (SELECT [Item] FROM #ChartIdList);

	SELECT	
		 FACILITY_PROF_ID
		,fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.NAME_SUFFIX + ' (' + fp.EMPLOYEE_IDENTIFIER + ')' Professional
	INTO	
		#FacilityProfessionals
	FROM	
		dbo.FACILITY_PROFESSIONAL fp WITH (NOLOCK)
	WHERE
		fp.[FACILITY_PROF_ID] IN (SELECT DISTINCT [PHYSICIAN_ID] FROM #ChartSubset WHERE [PHYSICIAN_ID] > 0 UNION SELECT DISTINCT [NURSE_PRACTITIONER_ID] FROM #ChartSubset WHERE [NURSE_PRACTITIONER_ID] > 0);

	SELECT		
		c.FACILITY
	  , c.CHART_ID
	  , c.FACILITY_CHART_ID
	  , c.MEDICAL_RECORD_NUM
	  , c.PATIENT_DOB
	  , ii.CREATION_DATE_TIME								LAST_IMAGE_RECEIPT_DATE
	  , c.CLIENT_COMMENT
	  , c.CHANGED_DATE_TIME
	  , IIF(ii.CREATION_DATE_TIME IS NOT NULL, 'Yes', 'No') [EMR?]
	  , 'Yes'												[Census?]
	  , c.CREATION_DATE_TIME								Received
	  , c.TIME_OF_SERVICE									DOS
	  , c.TIME_OF_DIS										DISCHARGE
	  , cs.[DESCRIPTION]									[STATUS]
	  , pr.PendingReason									[Pending Reason]
	  , pd.[DESCRIPTION]									[Patient Disposition]
	  , c.CODER_COMMENT										[Coder Notes]
	  --, ii.CREATION_DATE_TIME								[Patient]					-- This appears to be wrong. DACS-3926 - 20241223 - wpippin
	  , IIF(c.PATIENT_FIRST_NAME IS NULL,'',c.PATIENT_FIRST_NAME) + ' ' + IIF(c.PATIENT_LAST_NAME IS NULL,'',c.PATIENT_LAST_NAME)	[Patient]	-- This appears to be wrong. DACS-3926 - 20241223 - wpippin
	  , p.Professional										Physician
	  , c.CHART_STATUS_ID
	  , ISNULL(pc.DESCRIPTION, 'All')						PatientClass
	  , c.PATIENT_DISPOSITION_ID
	  , c.PENDING_REASON_ID
	  , c.FACILITY_ID
	  , c.SENT_DATE											[Sent]
	  , c.LOCATION_CODE
	  , n.Professional										[Mid-Level]
	  , sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC
	  , cmd.NAME											[InitialObservationDept]
	  , c.FACILITY_ADMIN_CHART_ID
	  , c.ServiceModelCode									[Service Model Code]
	  , c.FIRST_NAME										[First Name]
	  , c.LAST_NAME											[Last Name]
	  , pba.ChartPostBillAuditStatusTypeCode				[ChartPostBillAuditStatusTypeCode]
	FROM
		#ChartSubset													   c
		LEFT JOIN #FacilityProfessionals								   p
			ON p.FACILITY_PROF_ID = c.PHYSICIAN_ID
			   AND c.PHYSICIAN_ID > -1
		LEFT JOIN #FacilityProfessionals								   n
			ON n.FACILITY_PROF_ID = c.NURSE_PRACTITIONER_ID
			   AND c.NURSE_PRACTITIONER_ID > -1
		INNER JOIN dbo.CHART_STATUS										   cs WITH (NOLOCK)
			ON cs.CHART_STATUS_ID = c.CHART_STATUS_ID
		LEFT JOIN dbo.PATIENT_CLASS										   pc WITH (NOLOCK)
			ON pc.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
		LEFT JOIN dbo.PATIENT_DISPOSITION								   pd WITH (NOLOCK)
			ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		LEFT JOIN dbo.SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao WITH (NOLOCK)
			ON sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
		LEFT JOIN dbo.CHARGE_MASTER_DEPARTMENT							   cmd WITH (NOLOCK)
			ON cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
			   AND c.INITIAL_CHARGE_MASTER_DEPT_ID > -1 										-- reduces LReads by 90% on Charge_Master_Department 
		LEFT JOIN dbo.ChartPostBillAudit								   pba
			ON pba.ChartId = c.CHART_ID
		LEFT JOIN (SELECT	MAX(CREATION_DATE_TIME) CREATION_DATE_TIME
						  , SERVICE_AGREEMENT_ID
						  , FACILITY_CHART_ID
				   FROM		dbo.IMPORT_IMAGE ii WITH (NOLOCK)
				   GROUP BY SERVICE_AGREEMENT_ID
						  , FACILITY_CHART_ID)							   ii
			ON ii.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			   AND ii.FACILITY_CHART_ID = c.FACILITY_CHART_ID
		LEFT JOIN (SELECT	cpr.CHART_ID
						  , STRING_AGG(pr.DESCRIPTION, '|')WITHIN GROUP(ORDER BY sapr.RANK_VALUE ASC) PendingReason
				   FROM		dbo.CHART_PENDING_REASON						cpr WITH (NOLOCK)
							INNER JOIN dbo.SERVICE_AGREEMENT_PENDING_REASON sapr WITH (NOLOCK)
								ON sapr.SERVICE_AGREEMENT_PENDING_REASON_ID = cpr.SERVICE_AGREEMENT_PENDING_REASON_ID
							INNER JOIN dbo.PENDING_REASON					pr WITH (NOLOCK)
								ON pr.PENDING_REASON_ID = sapr.PENDING_REASON_ID
				   GROUP BY cpr.CHART_ID)								   pr
			ON c.CHART_ID = pr.CHART_ID
			   AND c.CHART_STATUS_ID IN (2, 6)
	ORDER BY 
		IIF(@SortDirection = 'A' AND @OrderBy = 0, c.TIME_OF_SERVICE, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 1, c.FACILITY_CHART_ID, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 2, c.MEDICAL_RECORD_NUM, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 3, c.CREATION_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 4, c.CHANGED_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 5, IIF(ii.CREATION_DATE_TIME IS NOT NULL, 'Yes', 'No'), '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 6, 'Yes', '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 7, c.CREATION_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 8, cs.[DESCRIPTION], '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 9, pr.PendingReason, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 10, ii.CREATION_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 11, p.Professional, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 12, c.TIME_OF_DIS, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 13, ii.CREATION_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 14, ISNULL(pc.DESCRIPTION, 'All'), '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 15, c.FACILITY, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 16, c.SENT_DATE, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 17, c.LOCATION_CODE, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 18, n.Professional, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 19, cmd.NAME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 20, sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 21, c.FACILITY_ADMIN_CHART_ID, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 22, pd.[DESCRIPTION], '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 23, c.PATIENT_DOB, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 24, c.LONG_PATIENT_ID1, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy >= 25, c.TIME_OF_SERVICE, '') ASC
	  
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 0, c.TIME_OF_SERVICE, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 1, c.FACILITY_CHART_ID, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 2, c.MEDICAL_RECORD_NUM, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 3, c.CREATION_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 4, c.CHANGED_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 5, IIF(ii.CREATION_DATE_TIME IS NOT NULL, 'Yes', 'No'), '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 6, 'Yes', '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 7, c.CREATION_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 8, cs.[DESCRIPTION], '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 9, pr.PendingReason, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 10, ii.CREATION_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 11, p.Professional, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 12, c.TIME_OF_DIS, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 13, ii.CREATION_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 14, ISNULL(pc.DESCRIPTION, 'All'), '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 15, c.FACILITY, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 16, c.SENT_DATE, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 17, c.LOCATION_CODE, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 18, n.Professional, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 19, cmd.NAME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 20, sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 21, c.FACILITY_ADMIN_CHART_ID, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 22, pd.[DESCRIPTION], '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 23, c.PATIENT_DOB, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 24, c.LONG_PATIENT_ID1, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy >= 25, c.TIME_OF_SERVICE, '') DESC
	  , IIF(@SortDirection = 'A', c.CHART_ID, '') ASC
	  , IIF(@SortDirection <> 'A', c.CHART_ID, '') DESC;

/*
-- =============================================
-- Create date: 03/06/2025
-- This SPROC MUST return the same final results as does SPROC [dbo].[sp_Get_DashboardPendingReport]
-- it borrows heavily from the above SPROC as it is meant to server as a kind of caching of the last results from the other SPROC.
-- =============================================
*/
END;

GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     PROCEDURE [dbo].[sp_Get_DashboardPendingReportV2025]
    @ReturnCount BIT = 0,															-- this version does not return a result count.  it only returns records and lets ACS count them.
    @DosFrom date = NULL,
    @DosTo date = NULL,
    @ReceivedFrom date = NULL,
    @ReceivedTo date = NULL,
    @SentFrom date = NULL,
    @SentTo date = NULL,
    @ChartStatuses varchar(50) = '',
    @PendingReasons varchar(MAX) = NULL,
    @Facilities varchar(MAX) = NULL,
    @MedicalRecordNumber varchar(25) = '',
    @FacilityChartIdentifier varchar(25) = '',
    @FacilityAdminChartID varchar(25) = '',       
    @ClinicID varchar(10) = '',
    @PatientClassID INT = -1,
    @LocationCodes varchar(MAX) = NULL,
    @Providers varchar(MAX) = NULL,
    @ObservationDepartments varchar(MAX) = NULL,
    @OrderBy INT = 0, -- DOS
    @SortDirection varchar(4) = 'ASC',
    @ChartSearchMaxCount INT = 3000, 												-- this is left for compatibility.  is always set to 3000
	@ChartPostBillAuditStatus INT = 0,
	@ChartPostBillAuditStartDtFrom date = NULL,
	@ChartPostBillAuditStartDtTo date = NULL,
	@ChartPostBillAuditCompletedDtFrom date = NULL,
	@ChartPostBillAuditCompletedDtTo date = NULL,
	@ChartPostBillAuditFlaggedDtFrom date = NULL,
	@ChartPostBillAuditFlaggedDtTo date = NULL,
	@ChartPostBillAuditFlagged BIT = 0,
	@FacilityChartIdentifierList varchar(MAX) = NULL,
	@ImageFilter INT = 0,
	@AutomationFilter INT = 0,
	@PageIndex INT = NULL,
	@PageSize INT = NULL,
	@ShowDebug BIT = 0,																-- testing only
	@LogParams BIT = 1																-- for testing as requested by DBA Team
AS
BEGIN
	SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- todo check to see if needed for efficency.  DBAs did not use previously
	SET DEADLOCK_PRIORITY -10;

	---------------------------
	-- using ablative methodology to hopefully speed processing since very seldom are all criteria acted upon.
	-- *Note: MF wants the ability for this main SPROC to handle paging.  it presently does not so some fields will be needed to be added.  to maintain compatibility will have to have default values set to null
	-- @PageIndex and @PageSize.  if value are NULL, ignore them.  if set we send a paging based subset of provided valid values
	---------------------------
	DECLARE @minSearchDate DATETIME = CAST(DateAdd(day, -1642.5, GETDATE()) AS DATE)
	DECLARE @maxSearchDate DATETIME = CAST(DateAdd(day, 1, CAST(GETDATE() AS DATE)) AS DATE)
	DECLARE @countTbChartMaster INT = 0;
	DECLARE @LogParamList VARCHAR(MAX) = '';
	DECLARE @NewLogParamId INT = 0;
	DECLARE @StartTime DATETIME = GETDATE();
	
	IF @LogParams = 1
	BEGIN 
															-- SET @LogParamList += '"@ExecDT":"' + CAST(GETDATE() AS VARCHAR) + '",'; 
															-- SET @LogParamList += '"@ReturnCount":"' + IIF(@ReturnCount IS NULL, 'NULL', CAST(@ReturnCount AS VARCHAR)) + '",'; 
		IF @DosFrom IS NOT NULL 							SET @LogParamList += '"@DosFrom":"' + IIF(@DosFrom IS NULL, 'NULL', CAST(@DosFrom AS VARCHAR)) + '",'; 
		IF @DosTo IS NOT NULL 								SET @LogParamList += '"@DosTo":"' + IIF(@DosTo IS NULL, 'NULL', CAST(@DosTo AS VARCHAR)) + '",'; 
		IF @ReceivedFrom IS NOT NULL 						SET @LogParamList += '"@ReceivedFrom":"' + IIF(@ReceivedFrom IS NULL, 'NULL', CAST(@ReceivedFrom AS VARCHAR)) + '",'; 
		IF @ReceivedTo IS NOT NULL 							SET @LogParamList += '"@ReceivedTo":"' + IIF(@ReceivedTo IS NULL, 'NULL', CAST(@ReceivedTo AS VARCHAR)) + '",'; 
		IF @SentFrom IS NOT NULL 							SET @LogParamList += '"@SentFrom":"' + IIF(@SentFrom IS NULL, 'NULL', CAST(@SentFrom AS VARCHAR)) + '",'; 
		IF @SentTo IS NOT NULL 								SET @LogParamList += '"@SentTo":"' + IIF(@SentTo IS NULL, 'NULL', CAST(@SentTo AS VARCHAR)) + '",'; 
		IF @ChartStatuses <> '' 							SET @LogParamList += '"@ChartStatuses":"' + IIF(@ChartStatuses IS NULL, 'NULL', CAST(@ChartStatuses AS VARCHAR)) + '",'; 
		IF @PendingReasons IS NOT NULL						SET @LogParamList += '"@PendingReasons":"' + IIF(@PendingReasons IS NULL, 'NULL', CAST(@PendingReasons AS VARCHAR(MAX))) + '",'; 
		IF @Facilities IS NOT NULL 							SET @LogParamList += '"@Facilities":"' + IIF(@Facilities IS NULL, 'NULL', CAST(@Facilities AS VARCHAR(MAX))) + '",'; 
		IF @MedicalRecordNumber <> '' 						SET @LogParamList += '"@MedicalRecordNumber":"' + IIF(@MedicalRecordNumber IS NULL, 'NULL', CAST(@MedicalRecordNumber AS VARCHAR)) + '",'; 
		IF @FacilityChartIdentifier <> '' 					SET @LogParamList += '"@FacilityChartIdentifier":"' + IIF(@FacilityChartIdentifier IS NULL, 'NULL', CAST(@FacilityChartIdentifier AS VARCHAR)) + '",'; 
		IF @FacilityAdminChartID <> '' 						SET @LogParamList += '"@FacilityAdminChartID":"' + IIF(@FacilityAdminChartID IS NULL, 'NULL', CAST(@FacilityAdminChartID AS VARCHAR)) + '",'; 
		IF @ClinicID <> '' 									SET @LogParamList += '"@ClinicID":"' + IIF(@ClinicID IS NULL, 'NULL', CAST(@ClinicID AS VARCHAR)) + '",'; 
		IF @PatientClassID <> -1 							SET @LogParamList += '"@PatientClassID":"' + IIF(@PatientClassID IS NULL, 'NULL', CAST(@PatientClassID AS VARCHAR)) + '",'; 
		IF @LocationCodes IS NOT NULL 						SET @LogParamList += '"@LocationCodes":"' + IIF(@LocationCodes IS NULL, 'NULL', CAST(@LocationCodes AS VARCHAR)) + '",'; 
		IF @Providers IS NOT NULL 							SET @LogParamList += '"@Providers":"' + IIF(@Providers IS NULL, 'NULL', CAST(@Providers AS VARCHAR)) + '",'; 
		IF @ObservationDepartments IS NOT NULL 				SET @LogParamList += '"@ObservationDepartments":"' + IIF(@ObservationDepartments IS NULL, 'NULL', CAST(@ObservationDepartments AS VARCHAR)) + '",'; 
		IF @OrderBy > 0 									SET @LogParamList += '"@OrderBy":"' + IIF(@OrderBy IS NULL, 'NULL', CAST(@OrderBy AS VARCHAR)) + '",'; 
		IF @SortDirection <> 'ASC'							SET @LogParamList += '"@SortDirection":"' + IIF(@SortDirection IS NULL, 'NULL', CAST(@SortDirection AS VARCHAR)) + '",'; 
		IF @ChartSearchMaxCount <> 3000 					SET @LogParamList += '"@ChartSearchMaxCount":"' + IIF(@ChartSearchMaxCount IS NULL, 'NULL', CAST(@ChartSearchMaxCount AS VARCHAR)) + '",'; 
		IF @ChartPostBillAuditStatus > 0 					SET @LogParamList += '"@ChartPostBillAuditStatus":"' + IIF(@ChartPostBillAuditStatus IS NULL, 'NULL', CAST(@ChartPostBillAuditStatus AS VARCHAR)) + '",'; 
		IF @ChartPostBillAuditStartDtFrom IS NOT NULL 		SET @LogParamList += '"@ChartPostBillAuditStartDtFrom":"' + IIF(@ChartPostBillAuditStartDtFrom IS NULL, 'NULL', CAST(@ChartPostBillAuditStartDtFrom AS VARCHAR)) + '",'; 
		IF @ChartPostBillAuditStartDtTo IS NOT NULL 		SET @LogParamList += '"@ChartPostBillAuditStartDtTo":"' + IIF(@ChartPostBillAuditStartDtTo IS NULL, 'NULL', CAST(@ChartPostBillAuditStartDtTo AS VARCHAR)) + '",'; 
		IF @ChartPostBillAuditCompletedDtFrom IS NOT NULL	SET @LogParamList += '"@ChartPostBillAuditCompletedDtFrom":"' + IIF(@ChartPostBillAuditCompletedDtFrom IS NULL, 'NULL', CAST(@ChartPostBillAuditCompletedDtFrom AS VARCHAR)) + '",'; 
		IF @ChartPostBillAuditCompletedDtTo IS NOT NULL 	SET @LogParamList += '"@ChartPostBillAuditCompletedDtTo":"' + IIF(@ChartPostBillAuditCompletedDtTo IS NULL, 'NULL', CAST(@ChartPostBillAuditCompletedDtTo AS VARCHAR)) + '",'; 
		IF @ChartPostBillAuditFlaggedDtFrom IS NOT NULL 	SET @LogParamList += '"@ChartPostBillAuditFlaggedDtFrom":"' + IIF(@ChartPostBillAuditFlaggedDtFrom IS NULL, 'NULL', CAST(@ChartPostBillAuditFlaggedDtFrom AS VARCHAR)) + '",'; 
		IF @ChartPostBillAuditFlaggedDtTo IS NOT NULL 		SET @LogParamList += '"@ChartPostBillAuditFlaggedDtTo":"' + IIF(@ChartPostBillAuditFlaggedDtTo IS NULL, 'NULL', CAST(@ChartPostBillAuditFlaggedDtTo AS VARCHAR)) + '",'; 
		IF @ChartPostBillAuditFlagged > 0 					SET @LogParamList += '"@ChartPostBillAuditFlagged":"' + IIF(@ChartPostBillAuditFlagged IS NULL, 'NULL', CAST(@ChartPostBillAuditFlagged AS VARCHAR)) + '",'; 
		IF @FacilityChartIdentifierList IS NOT NULL			SET @LogParamList += '"@FacilityChartIdentifierList":"' + IIF(@FacilityChartIdentifierList IS NULL, 'NULL', CAST(@FacilityChartIdentifierList AS VARCHAR)) + '",'; 
		IF @ImageFilter > 0 								SET @LogParamList += '"@ImageFilter":"' + IIF(@ImageFilter IS NULL, 'NULL', CAST(@ImageFilter AS VARCHAR)) + '",'; 
		IF @AutomationFilter > 0 							SET @LogParamList += '"@AutomationFilter":"' + IIF(@AutomationFilter IS NULL, 'NULL', CAST(@AutomationFilter AS VARCHAR)) + '",'; 
		 IF @PageIndex IS NOT NULL 							SET @LogParamList += '"@PageIndex":"' + IIF(@PageIndex IS NULL, 'NULL', CAST(@PageIndex AS VARCHAR)) + '",'; 
		 IF @PageSize IS NOT NULL 							SET @LogParamList += '"@PageSize":"' + IIF(@PageSize IS NULL, 'NULL', CAST(@PageSize AS VARCHAR)) + '",'; 
		--SET @LogParamList += '"@ShowDebug":"' + IIF(@ShowDebug IS NULL, 'NULL', CAST(@ShowDebug AS VARCHAR)) + '",'; 
		--SET @LogParamList += '"@LogParams":"' + IIF(@LogParams IS NULL, 'NULL', CAST(@LogParams AS VARCHAR)) + '",'; 
		INSERT INTO [SearchLog] ([Title], [Params]) VALUES ('sp_Get_DashboardPendingReportV2025', @LogParamList);		
		SET @NewLogParamId = SCOPE_IDENTITY();
	END;
	
	---------------------------
	-- handle paging: 
	---------------------------
	SET @PageIndex = IIF(@PageIndex IS NULL OR @PageIndex < 1, 1, @PageIndex)
	SET @PageSize = IIF(@PageSize IS NULL OR @PageSize <= 0 OR @PageSize > 3000, 3000, @PageSize)
	DECLARE @PagingRowSkip INT = @PageSize * (@PageIndex - 1);

BEGIN TRY

	---------------------------
	-- rule 1: must be a selected facility 	
	---------------------------
	IF @Facilities IS NULL OR LEN(RTRIM(@Facilities)) <= 0
	BEGIN 
		PRINT('Must Provide a Facility')
		IF @NewLogParamId > 0 UPDATE [SearchLog] SET [Msg] = 'Error: Must Provide a Facility' WHERE [SearchLogId] = @NewLogParamId;
		RETURN;
	END;
	
	---------------------------
	-- rule 2: must be a date range selected for Date Of Service OR Date received OR Date sent
	---------------------------
	DECLARE @_DosFrom DATETIME = IIF(@DosFrom BETWEEN @minSearchDate AND @maxSearchDate AND ISDATE(CAST(@DosFrom AS VARCHAR(40))) = 1, @DosFrom, NULL);
	DECLARE @_DosTo DATETIME = IIF(@DosTo BETWEEN @minSearchDate AND @maxSearchDate AND ISDATE(CAST(@DosTo AS VARCHAR(40))) = 1, @DosTo, NULL);
	
	DECLARE @_ReceivedFrom DATETIME = IIF(@ReceivedFrom BETWEEN @minSearchDate AND @maxSearchDate AND ISDATE(CAST(@ReceivedFrom AS VARCHAR(40))) = 1, @ReceivedFrom, NULL);
	DECLARE @_ReceivedTo DATETIME = IIF(@ReceivedTo BETWEEN @minSearchDate AND @maxSearchDate AND ISDATE(CAST(@ReceivedTo AS VARCHAR(40))) = 1, @ReceivedTo, NULL);
	
	DECLARE @_SentFrom DATETIME = IIF(@SentFrom BETWEEN @minSearchDate AND @maxSearchDate AND ISDATE(CAST(@SentFrom AS VARCHAR(40))) = 1, @SentFrom, NULL);
	DECLARE @_SentTo DATETIME = IIF(@SentTo BETWEEN @minSearchDate AND @maxSearchDate AND ISDATE(CAST(@SentTo AS VARCHAR(40))) = 1, @SentTo, NULL);
	
	IF @_DosFrom IS NULL AND @_DosTo IS NULL AND @_ReceivedFrom IS NULL AND @_ReceivedTo IS NULL AND @_SentFrom IS NULL AND @_SentTo IS NULL
	BEGIN 
		PRINT('Invalid Date Range set for charts')
		IF @NewLogParamId > 0 UPDATE [SearchLog] SET [Msg] = 'Error: Invalid Date Range set for charts' WHERE [SearchLogId] = @NewLogParamId;
		RETURN;
	END;
	
	---------------------------
	-- clean dates.  if a just a From date is entered, the user wants just that day of data.  if both empty, default to max range for SQL purposes
	---------------------------
	IF @_DosFrom IS NULL
		SET @_DosFrom = @minSearchDate;
	ELSE IF @_DosFrom IS NOT NULL AND @_DosTo IS NULL
		SET @_DosTo = @_DosFrom;
	IF @_DosTo IS NULL
		SET @_DosTo = @maxSearchDate;
	
	IF @_ReceivedFrom IS NULL
		SET @_ReceivedFrom = @minSearchDate;
	ELSE IF @_ReceivedFrom IS NOT NULL AND @_ReceivedTo IS NULL
		SET @_ReceivedTo = @_ReceivedFrom;
	IF @_ReceivedTo IS NULL
		SET @_ReceivedTo = @maxSearchDate;

	IF @_SentFrom IS NULL
		SET @_SentFrom = @minSearchDate;
	ELSE IF @_SentFrom IS NOT NULL AND @_SentTo IS NULL
		SET @_SentTo = @_SentFrom;
	IF @_SentTo IS NULL
		SET @_SentTo = @maxSearchDate;
	
	IF @ShowDebug = 1
	BEGIN
		PRINT('@_DosFrom = ' + CAST(@_DosFrom AS VARCHAR(50)));
		PRINT('@_DosTo = ' + CAST(@_DosTo AS VARCHAR(50)));
		PRINT('@_ReceivedFrom = ' + CAST(@_ReceivedFrom AS VARCHAR(50)));
		PRINT('@_ReceivedTo = ' + CAST(@_ReceivedTo AS VARCHAR(50)));
		PRINT('@_SentFrom = ' + CAST(@_SentFrom AS VARCHAR(50)));
		PRINT('@_SentTo = ' + CAST(@_SentTo AS VARCHAR(50)));
		PRINT('@PagingRowSkip =' + CAST(@PagingRowSkip AS VARCHAR(50)))
	END;
	
	DROP TABLE IF EXISTS #FacilityIDList;
	SELECT [value] = cast(value as int) INTO #FacilityIDList FROM STRING_SPLIT(@Facilities, ',')

	IF @ShowDebug = 1
	BEGIN
		SELECT '#FacilityIDList = ' = '----->>>';
		--SELECT * FROM #FacilityIDList;
		SELECT '#FacilityIDList count' = (SELECT COUNT(value) FROM #FacilityIDList)
	END;
		
	IF @ChartStatuses IS null OR LEN(@ChartStatuses) <= 0
		SET @ChartStatuses = '2';

	DROP TABLE IF EXISTS #ChartStatusIDList;
	SELECT [value] = cast(value as int) INTO #ChartStatusIDList FROM STRING_SPLIT(@ChartStatuses, ',')

	IF @ShowDebug = 1
	BEGIN
		SELECT '#ChartStatusIDList = ' = '----->>>';
		--SELECT * FROM #ChartStatusIDList;
		SELECT '#ChartStatusIDList count' = (SELECT COUNT(value) FROM #ChartStatusIDList)
	END;

	SET @PatientClassID = ISNULL(@PatientClassID,-1);
	SET @MedicalRecordNumber = RTRIM(ISNULL(@MedicalRecordNumber,''));
	SET @FacilityAdminChartID = RTRIM(ISNULL(@FacilityAdminChartID,''));
	SET @ClinicID = RTRIM(ISNULL(@ClinicID,''));
	SET @LocationCodes = RTRIM(ISNULL(@LocationCodes,''));
	SET @FacilityChartIdentifier = RTRIM(ISNULL(@FacilityChartIdentifier,''));
	SET @FacilityChartIdentifierList = RTRIM(ISNULL(@FacilityChartIdentifierList,''));

	IF LEN(ISNULL(@FacilityChartIdentifierList,'')) > 1
	BEGIN
		SET @FacilityChartIdentifierList = REPLACE(ISNULL(@FacilityChartIdentifierList,''), N' ', N'');
		SET @FacilityChartIdentifierList = REPLACE(@FacilityChartIdentifierList, N',,', N',');
		--SET @FacilityChartIdentifierList = REPLACE(@FacilityChartIdentifierList, N',', N''',''');
		--SET @FacilityChartIdentifierList = '''' + @FacilityChartIdentifierList + '''';
	END;


	---------------------------
	-- declare #tbChartMaster: the master list of chart info to process
	---------------------------
	DROP TABLE IF EXISTS #tbChartMaster;
	CREATE TABLE #tbChartMaster
	(
		 [CHART_ID] INT
		,[SERVICE_AGREEMENT_ID] INT NULL
		,[FACILITY_ID] INT NULL
		,[FACILITY_CHART_ID] VARCHAR(20) NULL
		,[CLINIC_ID] VARCHAR(10) NULL
		,[MEDICAL_RECORD_NUM] VARCHAR(20) NULL
		,[PATIENT_DOB] DATETIME NULL
		,[CLIENT_COMMENT] VARCHAR(500) NULL
		,[CHANGED_DATE_TIME] DATETIME NULL
		,[Census?] VARCHAR(5) NULL
		,[CREATION_DATE_TIME] DATETIME NULL
		,[TIME_OF_SERVICE] DATETIME NULL
		,[TIME_OF_DIS] DATETIME NULL
		,[CHART_STATUS_ID] INT NULL
		,[PENDING_REASON_ID] INT NULL
		,[PATIENT_DISPOSITION_ID] INT NULL
		,[SENT_DATE] DATETIME NULL
		,[LOCATION_CODE] VARCHAR(10) NULL
		,[PHYSICIAN_ID] INT NULL
		,[NURSE_PRACTITIONER_ID] INT NULL
		,[CODER_COMMENT] VARCHAR(2000) NULL
		,[Patient] VARCHAR(100) NULL
		,[PATIENT_FIRST_NAME] VARCHAR(25) NULL
		,[PATIENT_LAST_NAME] VARCHAR(50) NULL
		,[PATIENT_CLASS_ID] INT NULL
		,[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID] INT NULL
		,[INITIAL_CHARGE_MASTER_DEPT_ID] INT NULL
		,[FACILITY_ADMIN_CHART_ID] VARCHAR(20) NULL
		,[IMAGES_AVAILABLE] BIT NULL
		,[FACILITY_AUTOMATION_CODING_COMPLETE] BIT NULL
		,[PHYSICIAN_AUTOMATION_CODING_COMPLETE]  BIT NULL
		,[FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME] DATETIME NULL
		,[PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME] DATETIME NULL
		,[FLAGGED_FOR_POST_BILL_AUDIT] BIT NULL
		,[POST_BILL_AUDIT_STARTED] DATETIME NULL
		,[POST_BILL_AUDIT_COMPLETED] DATETIME NULL
		,[FLAGGED_FOR_POST_BILL_AUDIT_DT] DATETIME NULL
	)

	IF @PatientClassID > 0 
		OR LEN(@MedicalRecordNumber) > 0 
		OR LEN(@FacilityAdminChartID) > 0
		OR LEN(@ClinicID) > 0
		OR LEN(@LocationCodes) > 1
		OR LEN(@FacilityChartIdentifier) > 0
		OR LEN(@FacilityChartIdentifierList) > 1
	BEGIN 
		PRINT('Performing ID Search')

		IF Len(@MedicalRecordNumber) > 0
			SET @MedicalRecordNumber += '%';
		IF Len(@FacilityAdminChartID) > 0
			SET @FacilityAdminChartID += '%';			
		IF Len(@ClinicID) > 0
			SET @ClinicID += '%';			
		IF Len(@FacilityChartIdentifier) > 0
			SET @FacilityChartIdentifier += '%';

		IF @ShowDebug = 1
		BEGIN
			PRINT('@PatientClassID =' + CAST(@PatientClassID AS VARCHAR(50)));
			PRINT('@MedicalRecordNumber =' + CAST(@MedicalRecordNumber AS VARCHAR(50)));
			PRINT('@FacilityAdminChartID =' + CAST(@FacilityAdminChartID AS VARCHAR(50)));
			PRINT('@ClinicID =' + CAST(@ClinicID AS VARCHAR(50)));
			PRINT('@LocationCodes =' + CAST(@LocationCodes AS VARCHAR(500)));
			PRINT('@FacilityChartIdentifier =' + CAST(@FacilityChartIdentifier AS VARCHAR(500)));
			PRINT('@FacilityChartIdentifierList =' + CAST(@FacilityChartIdentifierList AS VARCHAR(500)))
			SELECT '@FacilityChartIdentifierList' = '--->>>'
			SELECT RTRIM(LTRIM([value])) FROM STRING_SPLIT(@FacilityChartIdentifierList, ',')
		END;

		---------------------------
		-- Id filtering
		---------------------------
		INSERT INTO #tbChartMaster
		SELECT TOP 10000 -- arbitrary limit.  will reduce for final results output lower
			 c.[CHART_ID]
			,c.[SERVICE_AGREEMENT_ID]
			,c.[FACILITY_ID]
			,c.[FACILITY_CHART_ID]
			,c.[CLINIC_ID]
			,c.[MEDICAL_RECORD_NUM]
			,c.[PATIENT_DOB]
			,c.[CLIENT_COMMENT]
			,c.[CHANGED_DATE_TIME]
			,'Yes' AS [Census?]
			,c.[CREATION_DATE_TIME]
			,c.[TIME_OF_SERVICE]
			,c.[TIME_OF_DIS]
			,c.[CHART_STATUS_ID]
			,c.[PENDING_REASON_ID]
			,c.[PATIENT_DISPOSITION_ID]
			,c.[SENT_DATE]
			,c.[LOCATION_CODE]
			,c.[PHYSICIAN_ID]
			,c.[NURSE_PRACTITIONER_ID]
			,c.[CODER_COMMENT]
			,c.[PATIENT_LAST_NAME] + ', ' + c.[PATIENT_FIRST_NAME] [Patient]
			,c.[PATIENT_FIRST_NAME]
			,c.[PATIENT_LAST_NAME]
			,c.[PATIENT_CLASS_ID]
			,c.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
			,c.[INITIAL_CHARGE_MASTER_DEPT_ID]
			,c.[FACILITY_ADMIN_CHART_ID]
			,c.[IMAGES_AVAILABLE]
			,c.[FACILITY_AUTOMATION_CODING_COMPLETE]
			,c.[PHYSICIAN_AUTOMATION_CODING_COMPLETE] 
			,c.[FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME]
			,c.[PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME]
			,c.[FLAGGED_FOR_POST_BILL_AUDIT]
			,c.[POST_BILL_AUDIT_STARTED]
			,c.[POST_BILL_AUDIT_COMPLETED]
			,c.[FLAGGED_FOR_POST_BILL_AUDIT_DT]
		FROM 
			[CHART] c
			INNER JOIN #FacilityIDList f ON c.[FACILITY_ID] = f.[value]
			INNER JOIN #ChartStatusIDList csil ON c.[CHART_STATUS_ID] = csil.[value]
		WHERE
			[TIME_OF_SERVICE] BETWEEN @_DosFrom AND @_DosTo
			AND [DATE_RECEIVED] BETWEEN @_ReceivedFrom AND @_ReceivedTo
			AND ([SENT_DATE] IS NULL OR [SENT_DATE] BETWEEN @_SentFrom AND @_SentTo)
			AND c.[CREATION_DATE_TIME] BETWEEN @minSearchDate AND @maxSearchDate 	-- this sets absolute range
			AND
			(
				(@PatientClassID > 0 AND [PATIENT_CLASS_ID] = @PatientClassID)
				OR
				(LEN(@MedicalRecordNumber) > 0 AND [MEDICAL_RECORD_NUM] LIKE @MedicalRecordNumber)
				OR
				(LEN(@FacilityAdminChartID) > 0 AND [FACILITY_ADMIN_CHART_ID] LIKE (@FacilityAdminChartID + '%'))
				OR
				(LEN(@ClinicID) > 0 AND [CLINIC_ID] LIKE (@ClinicID + '%'))
				OR
				(LEN(@FacilityChartIdentifier) > 0 AND [FACILITY_CHART_ID] LIKE (@FacilityChartIdentifier + '%'))
				OR
				(LEN(@FacilityChartIdentifierList) > 1 AND [FACILITY_CHART_ID] IN (SELECT RTRIM(LTRIM([value])) FROM STRING_SPLIT(@FacilityChartIdentifierList, ',')))
				OR
				(LEN(@LocationCodes) > 1 AND [LOCATION_CODE] IN (SELECT [value] FROM STRING_SPLIT(@LocationCodes, ',')))
			)
		ORDER BY
			c.[CREATION_DATE_TIME] DESC;
		;	
			
		IF @_SentFrom <> @minSearchDate OR @_SentTo <> @maxSearchDate
			DELETE FROM #tbChartMaster WHERE [SENT_DATE] IS NULL;
		
		IF @ShowDebug = 1
		BEGIN
			SELECT '#tbChartMaster' = ' --- Id Filter ------->>>'
			SELECT * FROM #tbChartMaster; -- testing
			SELECT '#tbChartMaster count' = (SELECT COUNT(*) FROM #tbChartMaster)
		END;
		
		SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
		IF @countTbChartMaster <= 0
		BEGIN
			IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: Id Filter' WHERE [SearchLogId] = @NewLogParamId;
			RETURN;
		END;
	END
	ELSE
	BEGIN
		PRINT('Performing Rule 1 & 2 Search')
		---------------------------
		-- populate primary chart source
		-- will process the Rule 1 and 2 parameters here to get our base table to work on
		---------------------------
		INSERT INTO #tbChartMaster
		SELECT TOP 10000 -- arbitrary limit.  will reduce for final results output lower
			 c.[CHART_ID]
			,c.[SERVICE_AGREEMENT_ID]
			,c.[FACILITY_ID]
			,c.[FACILITY_CHART_ID]
			,c.[CLINIC_ID]
			,c.[MEDICAL_RECORD_NUM]
			,c.[PATIENT_DOB]
			,c.[CLIENT_COMMENT]
			,c.[CHANGED_DATE_TIME]
			,'Yes' AS [Census?]
			,c.[CREATION_DATE_TIME]
			,c.[TIME_OF_SERVICE]
			,c.[TIME_OF_DIS]
			,c.[CHART_STATUS_ID]
			,c.[PENDING_REASON_ID]
			,c.[PATIENT_DISPOSITION_ID]
			,c.[SENT_DATE]
			,c.[LOCATION_CODE]
			,c.[PHYSICIAN_ID]
			,c.[NURSE_PRACTITIONER_ID]
			,c.[CODER_COMMENT]
			,c.[PATIENT_LAST_NAME] + ', ' + c.[PATIENT_FIRST_NAME] [Patient]
			,c.[PATIENT_FIRST_NAME]
			,c.[PATIENT_LAST_NAME]
			,c.[PATIENT_CLASS_ID]
			,c.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
			,c.[INITIAL_CHARGE_MASTER_DEPT_ID]
			,c.[FACILITY_ADMIN_CHART_ID]
			,c.[IMAGES_AVAILABLE]
			,c.[FACILITY_AUTOMATION_CODING_COMPLETE]
			,c.[PHYSICIAN_AUTOMATION_CODING_COMPLETE] 
			,c.[FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME]
			,c.[PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME]
			,c.[FLAGGED_FOR_POST_BILL_AUDIT]
			,c.[POST_BILL_AUDIT_STARTED]
			,c.[POST_BILL_AUDIT_COMPLETED]
			,c.[FLAGGED_FOR_POST_BILL_AUDIT_DT]
		FROM 
			[CHART] c
			INNER JOIN #FacilityIDList f ON c.[FACILITY_ID] = f.[value]
			INNER JOIN #ChartStatusIDList csil ON c.[CHART_STATUS_ID] = csil.[value]
		WHERE
			[TIME_OF_SERVICE] BETWEEN @_DosFrom AND @_DosTo
			AND [DATE_RECEIVED] BETWEEN @_ReceivedFrom AND @_ReceivedTo
			AND ([SENT_DATE] IS NULL OR [SENT_DATE] BETWEEN @_SentFrom AND @_SentTo)
			AND c.[CREATION_DATE_TIME] BETWEEN @minSearchDate AND @maxSearchDate 	-- this sets absolute range
		ORDER BY
			c.[CREATION_DATE_TIME] DESC;
		;	
			
		IF @_SentFrom <> @minSearchDate OR @_SentTo <> @maxSearchDate
			DELETE FROM #tbChartMaster WHERE [SENT_DATE] IS NULL;
		
		---------------------------
		-- chart status == pending filtering
		---------------------------
		IF EXISTS (SELECT top 1 1 FROM #ChartStatusIDList WHERE [value] = 2) AND @PendingReasons IS NOT NULL AND LEN(@PendingReasons) > 0
		BEGIN
			DROP TABLE IF EXISTS #PendingIDList;
			SELECT [value] = cast(value as int) INTO #PendingIDList FROM STRING_SPLIT(@PendingReasons, ',')

			IF @ShowDebug = 1
			BEGIN
				SELECT '#PendingIDList = ' = '----->>>';
				SELECT '@PendingReasons = ' = @PendingReasons;
				--SELECT * FROM #PendingIDList;
				SELECT '#PendingIDList count' = (SELECT COUNT(value) FROM #PendingIDList)
			END;

			DELETE FROM #tbChartMaster WHERE [PENDING_REASON_ID] NOT IN (SELECT [value] FROM #PendingIDList);

			IF @ShowDebug = 1
			BEGIN
				SELECT '#tbChartMaster' = ' --- chart status == Pending Filter ------->>>'
				--SELECT * FROM #tbChartMaster; -- testing
				SELECT '#tbChartMaster count' = (SELECT COUNT(*) FROM #tbChartMaster)
			END;
			
			SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
			IF @countTbChartMaster <= 0
			BEGIN
				IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountStep1] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: Pending Filter' WHERE [SearchLogId] = @NewLogParamId;
				RETURN;
			END;
		END;
		
		IF @ShowDebug = 1
		BEGIN
			SELECT '#tbChartMaster' = ' --- Base ------->>>'
			--SELECT * FROM #tbChartMaster; -- testing
			SELECT '#tbChartMaster count' = (SELECT COUNT(*) FROM #tbChartMaster)
		END;
		
		SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
		IF @countTbChartMaster <= 0
		BEGIN
			IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: Base Filter' WHERE [SearchLogId] = @NewLogParamId;
			RETURN;
		END;
		
		IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountStep1] = 0, [secondsStep1] = DATEDIFF(SECOND, @StartTime, GETDATE()) WHERE [SearchLogId] = @NewLogParamId;

	END;







	---------------------------
	-- Providers filtering
	---------------------------
	IF @Providers IS NOT NULL AND LEN(@Providers) > 0
	BEGIN
		DROP TABLE IF EXISTS #ProviderNPIList;
		SELECT [value] INTO #ProviderNPIList FROM STRING_SPLIT(@Providers, ',');
		IF @ShowDebug = 1
		BEGIN
			SELECT '#ProviderNPIList = ' = '----->>>';
			SELECT '@Providers = ' = @Providers;
			--SELECT * FROM #ProviderNPIList;
			SELECT '#ProviderNPIList count' = (SELECT COUNT(*) FROM #ProviderNPIList)
		END;
		
		DROP TABLE IF EXISTS #UpirIdList;
		SELECT [FACILITY_PROF_ID] 
		INTO #UpirIdList 
		FROM 
			[FACILITY_PROFESSIONAL] f 
			INNER JOIN #tbChartMaster tcm ON tcm.[SERVICE_AGREEMENT_ID] = f.[SERVICE_AGREEMENT_ID]
			INNER JOIN #ProviderNPIList pnl ON f.UPIR_ID = pnl.[value]
		;

		IF @ShowDebug = 1
		BEGIN
			SELECT '#UpirIdList = ' = '----->>>';
			--SELECT * FROM #UpirIdList;
			SELECT '#tbChartMaster count' = (SELECT COUNT(CHART_ID) FROM #tbChartMaster)
		END;

		DELETE FROM #tbChartMaster WHERE [PHYSICIAN_ID] NOT IN (SELECT [FACILITY_PROF_ID] FROM #UpirIdList) AND [NURSE_PRACTITIONER_ID] NOT IN (SELECT [FACILITY_PROF_ID] FROM #UpirIdList);

		IF @ShowDebug = 1
		BEGIN
			SELECT '#tbChartMaster' = ' --- Providers Filter ------->>>'
			--SELECT * FROM #tbChartMaster; -- testing
			SELECT '#tbChartMaster count' = (SELECT COUNT(CHART_ID) FROM #tbChartMaster)
		END;
		
		SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
		IF @countTbChartMaster <= 0
		BEGIN
			IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: Provider Filter' WHERE [SearchLogId] = @NewLogParamId;
			RETURN;
		END;
	END;

	---------------------------
	-- observation filtering
	---------------------------
	IF @ObservationDepartments IS NOT NULL AND LEN(@ObservationDepartments) > 0
	BEGIN
		DROP TABLE IF EXISTS #ObsList;
		SELECT [value] = CAST(value AS int) INTO #ObsList FROM STRING_SPLIT(@ObservationDepartments, ',');
		IF @ShowDebug = 1
		BEGIN
			SELECT '#ObsList = ' = '----->>>';
			SELECT '@ObservationDepartments = ' = @ObservationDepartments;
			--SELECT * FROM #ObsList;
			SELECT '#ObsList count' = (SELECT COUNT(*) FROM #ObsList)
		END;
		
		DELETE FROM #tbChartMaster WHERE [INITIAL_CHARGE_MASTER_DEPT_ID] NOT IN (SELECT [value] FROM #ObsList);

		IF @ShowDebug = 1
		BEGIN
			SELECT '#tbChartMaster' = ' --- Observation Filter ------->>>'
			--SELECT * FROM #tbChartMaster; -- testing
			SELECT '#tbChartMaster count' = (SELECT COUNT(CHART_ID) FROM #tbChartMaster)
		END;
		
		SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
		IF @countTbChartMaster <= 0
		BEGIN
			IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: Observation Filter' WHERE [SearchLogId] = @NewLogParamId;
			RETURN;
		END;
	END;

	---------------------------
	-- image filtering
	---------------------------
	IF @ImageFilter IN (1,2)
	BEGIN
		DECLARE @ImageFilterTestValue BIT = IIF(@ImageFilter = 2, 0, 1);
		DELETE FROM #tbChartMaster WHERE [IMAGES_AVAILABLE] <> @ImageFilterTestValue;
	  
		IF @ShowDebug = 1
		BEGIN
			SELECT '#tbChartMaster' = ' --- Image Filter ------->>>'
			--SELECT * FROM #tbChartMaster; -- testing
			SELECT '#tbChartMaster count' = (SELECT COUNT(CHART_ID) FROM #tbChartMaster)
		END;
		
		SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
		IF @countTbChartMaster <= 0
		BEGIN
			IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: Image Filter' WHERE [SearchLogId] = @NewLogParamId;
			RETURN;
		END;
	END;

	---------------------------
	-- automation filtering
	---------------------------
	IF @AutomationFilter IN (1,2)
	BEGIN
		DECLARE @AutomationFilterTestValue BIT = IIF(@AutomationFilter = 2, 0, 1);
		DELETE FROM #tbChartMaster 
		WHERE 
			[FACILITY_AUTOMATION_CODING_COMPLETE] <> @AutomationFilterTestValue 
			AND [PHYSICIAN_AUTOMATION_CODING_COMPLETE] <> @AutomationFilterTestValue
			AND [FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME] IS NULL
			AND [PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME] IS NULL;
	  
		IF @ShowDebug = 1
		BEGIN
			SELECT '#tbChartMaster' = ' --- Automation Filter ------->>>'
			--SELECT * FROM #tbChartMaster; -- testing
			SELECT '#tbChartMaster count' = (SELECT COUNT(CHART_ID) FROM #tbChartMaster)
		END
		
		SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
		IF @countTbChartMaster <= 0
		BEGIN
			IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: Automation Filter' WHERE [SearchLogId] = @NewLogParamId;
			RETURN;
		END;
	END;

	---------------------------
	-- PBA	
	-- *Note: we NEED to update the Dashboard Search Webform to ONLY use one date field + a drop down box that selects the kind of search wanted and then only show parameters needed jsut for that search.  NEED to use Reporting Examples for future!!
	---------------------------
	DECLARE @testDateFrom DATETIME;
	DECLARE @testDateTo DATETIME;
	
	IF @ChartStatuses like '%5%'
	BEGIN 
		IF @ChartPostBillAuditFlagged = 1
		BEGIN
			DELETE FROM #tbChartMaster WHERE [FLAGGED_FOR_POST_BILL_AUDIT] <> 1;
		  
			IF @ShowDebug = 1
			BEGIN
				SELECT '#tbChartMaster' = ' --- ChartPostBillAuditFlagged Filter ------->>>'
				--SELECT * FROM #tbChartMaster; -- testing
				SELECT '#tbChartMaster count' = (SELECT COUNT(CHART_ID) FROM #tbChartMaster)
			END

			SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
			IF @countTbChartMaster <= 0
			BEGIN
				IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: ChartPostBillAuditFlagged Filter' WHERE [SearchLogId] = @NewLogParamId;
				RETURN;
			END;
		END; 	

		IF @ChartPostBillAuditFlaggedDtFrom IS NOT NULL  										-- note these are DATE type
		BEGIN  
			SET @testDateFrom = @ChartPostBillAuditFlaggedDtFrom;
			SET @testDateTo = dateadd(day,1,IIF(@ChartPostBillAuditFlaggedDtTo IS NULL, @ChartPostBillAuditFlaggedDtFrom, @ChartPostBillAuditFlaggedDtTo));		
			DELETE FROM #tbChartMaster WHERE NOT(FLAGGED_FOR_POST_BILL_AUDIT_DT >= @testDateFrom AND FLAGGED_FOR_POST_BILL_AUDIT_DT < @testDateTo);
		
			SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
			IF @countTbChartMaster <= 0
			BEGIN
				IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: ChartPostBillAuditFlaggedDt Filter' WHERE [SearchLogId] = @NewLogParamId;
				RETURN;
			END;
		END;
	END;
	
	IF @ChartPostBillAuditStartDtFrom IS NOT NULL  										-- note these are DATE type
	BEGIN  
		SET @testDateFrom = @ChartPostBillAuditStartDtFrom;
		SET @testDateTo = dateadd(day,1,IIF(@ChartPostBillAuditStartDtTo IS NULL, @ChartPostBillAuditStartDtFrom, @ChartPostBillAuditStartDtTo));		
		DELETE FROM #tbChartMaster WHERE NOT(POST_BILL_AUDIT_STARTED >= @testDateFrom AND POST_BILL_AUDIT_STARTED < @testDateTo);
	
		SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
		IF @countTbChartMaster <= 0
		BEGIN
			IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: ChartPostBillAuditStartDt Filter' WHERE [SearchLogId] = @NewLogParamId;
			RETURN;
		END;
	END;

	IF @ChartPostBillAuditCompletedDtFrom IS NOT NULL  										-- note these are DATE type
	BEGIN  
		SET @testDateFrom = @ChartPostBillAuditCompletedDtFrom;
		SET @testDateTo = dateadd(day,1,IIF(@ChartPostBillAuditCompletedDtTo IS NULL, @ChartPostBillAuditCompletedDtFrom, @ChartPostBillAuditCompletedDtTo));		
		DELETE FROM #tbChartMaster WHERE NOT(POST_BILL_AUDIT_COMPLETED >= @testDateFrom AND POST_BILL_AUDIT_COMPLETED < @testDateTo);
	
		SET @countTbChartMaster = (SELECT COUNT(CHART_ID) FROM #tbChartMaster);
		IF @countTbChartMaster <= 0
		BEGIN
			IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = 0, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'No result: ChartPostBillAuditCompletedDt Filter' WHERE [SearchLogId] = @NewLogParamId;
			RETURN;
		END;
	END;

	---------------------------
	-- return our result set by filling in missing fields and using temp table
	---------------------------
	IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountStep2] = @countTbChartMaster, [secondsStep2] = DATEDIFF(SECOND, @StartTime, GETDATE()) WHERE [SearchLogId] = @NewLogParamId;

	DROP TABLE IF EXISTS #PbaTable;
	SELECT 
		 [ChartId]
		,[ChartPostBillAuditStatusTypeCode]
	INTO #PbaTable
	FROM 
		[ChartPostBillAudit]
	WHERE 
		[ChartId] IN (SELECT [CHART_ID] FROM #tbChartMaster);

	IF @ShowDebug = 1
	BEGIN
		SELECT '#PbaTable = ' = '----->>>';
		-- SELECT * FROM #PbaTable;
		SELECT '#PbaTable count' = (SELECT COUNT(*) FROM #PbaTable)
	END;

	DROP TABLE IF EXISTS #tbResults;
	SELECT TOP 3000
		 f.[NAME] AS [Facility]
		,c.[CHART_ID] AS [ChartId]
		,c.[FACILITY_CHART_ID] AS [FacilityChartID]
		,c.[MEDICAL_RECORD_NUM] AS [MedicalRecordNumber]
		,c.[PATIENT_DOB] AS [PatientDateOfBirth]
		,(SELECT 
			MAX(IMPORT_IMAGE.CREATION_DATE_TIME)
			FROM 
				IMPORT_IMAGE WITH (NOLOCK)  
			WHERE 
				IMPORT_IMAGE.FACILITY_CHART_ID = c.FACILITY_CHART_ID  
				AND IMPORT_IMAGE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID  
		  ) AS [LastImageReceiptDate]  
		,c.[CLIENT_COMMENT] AS [ClientComment]
		,c.[CHANGED_DATE_TIME] AS [LastChangedDate]
		,IIF(EXISTS (SELECT TOP 1 1 
					FROM 
						IMPORT_IMAGE ii WITH (NOLOCK) 
					WHERE 
						ii.FACILITY_CHART_ID = c.FACILITY_CHART_ID 
						AND ii.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID), 'Yes', 'No') AS [EMR?]
		,'Yes' AS [Census?]  
		,c.[CREATION_DATE_TIME] AS [Received]
		,c.[TIME_OF_SERVICE] AS [DateOfService]
		,c.[TIME_OF_DIS] AS [DischargeDate]
		,cs.[DESCRIPTION] AS [Status]
		,CASE WHEN c.CHART_STATUS_ID in (2, 6)  
			THEN (  
			  SELECT STUFF(  
				(  
				  SELECT '|' + pr.DESCRIPTION  
				  FROM CHART_PENDING_REASON WITH (NOLOCK),  
					SERVICE_AGREEMENT_PENDING_REASON sap WITH (NOLOCK),  
					PENDING_REASON pr WITH (NOLOCK)  
				  WHERE CHART_ID = c.CHART_ID  
					AND sap.SERVICE_AGREEMENT_PENDING_REASON_ID = CHART_PENDING_REASON.SERVICE_AGREEMENT_PENDING_REASON_ID  
					AND sap.PENDING_REASON_ID = pr.PENDING_REASON_ID  
				  ORDER BY sap.RANK_VALUE  
				  FOR XML PATH('')  
				), 1, 1, '')  
			  )  
			ELSE ''  
		  END [PendingReason]  
		,pd.[DESCRIPTION] AS [DisplayablePatientDisposition]
		,c.[CODER_COMMENT] AS [CoderNotes]
		,c.[PATIENT_LAST_NAME] + ', ' + c.[PATIENT_FIRST_NAME] AS [PatientName]
		,fp.[LAST_NAME] + ', ' + fp.[FIRST_NAME] + ' ' + fp.NAME_SUFFIX + ' (' + fp.[EMPLOYEE_IDENTIFIER] + ')' AS [PhysicianName]
		,c.[CHART_STATUS_ID] AS [ChartStatusId]
		,ISNULL(pc.[DESCRIPTION], 'All') AS [PatientClass]
		,c.[PATIENT_DISPOSITION_ID] AS [PatientDispositionId]
		,c.[PENDING_REASON_ID] AS [PendingReasonId]
		,c.[FACILITY_ID] AS [FacilityId]
		,c.[SENT_DATE] AS [SentDate]
		,c.[LOCATION_CODE] AS [LocationCode]
		,mlp.[LAST_NAME] + ', ' + mlp.[FIRST_NAME] + ' ' + mlp.[NAME_SUFFIX] + ' (' + mlp.[EMPLOYEE_IDENTIFIER] + ')' AS [MidLevel]
		,sao.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC] AS [ObservationArrivalSource]
		,cmd.[NAME] AS [ObservationDepartment]
		,c.[FACILITY_ADMIN_CHART_ID] AS [FacilityAdminChartID]
		,'' AS [ServiceModelCode]
		,'' AS [FirstName]
		,'' AS [LastName]
		,pba.ChartPostBillAuditStatusTypeCode AS [PostBillAuditStatusTypeCode]
	INTO 
		#tbResults
	FROM
		#tbChartMaster c
		INNER JOIN [FACILITY] f ON f.[FACILITY_ID] = c.[FACILITY_ID]
		INNER JOIN [CHART_STATUS] cs ON cs.[CHART_STATUS_ID] = c.[CHART_STATUS_ID]
		LEFT JOIN [PATIENT_DISPOSITION] pd ON pd.[PATIENT_DISPOSITION_ID] = c.[PATIENT_DISPOSITION_ID]
		LEFT JOIN [PATIENT_CLASS] pc ON pc.[PATIENT_CLASS_ID] = c.[PATIENT_CLASS_ID]
		LEFT JOIN [FACILITY_PROFESSIONAL] fp ON fp.[FACILITY_PROF_ID] = c.[PHYSICIAN_ID] AND c.[PHYSICIAN_ID] > -1  -- reduces LReads by 70-90% on Facility_Professional  
		LEFT JOIN [FACILITY_PROFESSIONAL] mlp ON mlp.[FACILITY_PROF_ID] = c.[NURSE_PRACTITIONER_ID] AND c.[NURSE_PRACTITIONER_ID] > -1  -- reduces LReads by 70-90% on Facility_Professional   
		LEFT JOIN [CHARGE_MASTER_DEPARTMENT] cmd ON cmd.[CHARGE_MASTER_DEPT_ID] = c.[INITIAL_CHARGE_MASTER_DEPT_ID] AND c.[INITIAL_CHARGE_MASTER_DEPT_ID] > -1 -- reduces LReads by 90% on Charge_Master_Department   
		LEFT JOIN [SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE] sao ON sao.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID] = c.[OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
		LEFT JOIN #PbaTable pba ON c.[CHART_ID] = pba.[chartId]
	;

	SET @countTbChartMaster = (SELECT COUNT([ChartId]) FROM #tbResults);
	IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountStep3] = @countTbChartMaster, [SecondsStep3] = DATEDIFF(SECOND, @StartTime, GETDATE()) WHERE [SearchLogId] = @NewLogParamId;

	IF @ShowDebug = 1
	BEGIN
		SELECT '#tbResults = ' = '----->>>';
		--SELECT * FROM #tbResults;
		SELECT '#tbResults count' = (SELECT COUNT(ChartId) FROM #tbResults)
	END;


	---------------------------
	-- ordering	--- !!!! this will be handled within ACS via LinQ statements as a step 2 item  !!!!!!!!!!!!!!!
	---------------------------
	IF @SortDirection = 'DESC'
		SELECT 
			* 
		FROM 
			#tbResults
		ORDER BY
			CASE @OrderBy  
				WHEN 0  THEN [DateOfService]  
				WHEN 1  THEN [FacilityChartID]  
				WHEN 2  THEN [MedicalRecordNumber]  
				WHEN 3  THEN [Received]  
				WHEN 4  THEN [LastChangedDate]  
				WHEN 5  THEN [EMR?]  
				WHEN 7  THEN [Received]  
				WHEN 8  THEN [Status]  
				WHEN 9  THEN [PendingReason]  
				WHEN 10 THEN [PatientName]  
				WHEN 11 THEN [PhysicianName]  
				WHEN 12 THEN [DischargeDate]  
				WHEN 13 THEN [LastImageReceiptDate]
				WHEN 14 THEN [PatientClass]  
				WHEN 15 THEN [Facility]  
				WHEN 16 THEN [SentDate]  
				WHEN 17 THEN [LocationCode]  
				WHEN 18 THEN [MidLevel]  
				WHEN 19 THEN [ObservationDepartment]  
				WHEN 20 THEN [ObservationArrivalSource]  
				WHEN 21 THEN [FacilityAdminChartID]  
				WHEN 22 THEN [DisplayablePatientDisposition]  
				WHEN 23 THEN [PatientDateOfBirth]  
				-- WHEN 6  THEN [Census?]  -- not used for now
				ELSE 		 [DateOfService]  
			END DESC -- end CASE @OrderBy
		OFFSET @PagingRowSkip ROWS FETCH NEXT @PageSize ROWS ONLY;
	ELSE
		SELECT 
			* 
		FROM 
			#tbResults
		ORDER BY
			CASE @OrderBy  
				WHEN 0  THEN [DateOfService]  
				WHEN 1  THEN [FacilityChartID]  
				WHEN 2  THEN [MedicalRecordNumber]  
				WHEN 3  THEN [Received]  
				WHEN 4  THEN [LastChangedDate]  
				WHEN 5  THEN [EMR?]  
				WHEN 7  THEN [Received]  
				WHEN 8  THEN [Status]  
				WHEN 9  THEN [PendingReason]  
				WHEN 10 THEN [PatientName]  
				WHEN 11 THEN [PhysicianName]  
				WHEN 12 THEN [DischargeDate]  
				WHEN 13 THEN [LastImageReceiptDate]
				WHEN 14 THEN [PatientClass]  
				WHEN 15 THEN [Facility]  
				WHEN 16 THEN [SentDate]  
				WHEN 17 THEN [LocationCode]  
				WHEN 18 THEN [MidLevel]  
				WHEN 19 THEN [ObservationDepartment]  
				WHEN 20 THEN [ObservationArrivalSource]  
				WHEN 21 THEN [FacilityAdminChartID]  
				WHEN 22 THEN [DisplayablePatientDisposition]  
				WHEN 23 THEN [PatientDateOfBirth]  
				-- WHEN 6  THEN [Census?]  -- not used for now
				ELSE 		 [DateOfService]  
			END -- end CASE @OrderBy
		OFFSET @PagingRowSkip ROWS FETCH NEXT @PageSize ROWS ONLY;

	
	---------------------------
	-- final Result logging
	---------------------------
	IF @NewLogParamId > 0 UPDATE [SearchLog] SET [CountResult] = @countTbChartMaster, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE()), [Msg] = 'Final result' WHERE [SearchLogId] = @NewLogParamId;
	
END TRY
BEGIN CATCH
	---------------------------
	-- show Exception response and log it
	---------------------------
	IF @NewLogParamId > 0 
		UPDATE [SearchLog] 
			SET [CountResult] = @countTbChartMaster
			, [SecondsResult] = DATEDIFF(SECOND, @StartTime, GETDATE())
			, [Msg] = 'Exception:: ErrNum: ' + CAST(ERROR_NUMBER() AS VARCHAR(50)) + 
						'| ErrMsg: ' + CAST(ERROR_MESSAGE() AS VARCHAR(500)) + 
						'| ErrSev: ' + CAST(ERROR_SEVERITY() AS VARCHAR(500)) + 
						'| ErrSta: ' + CAST(ERROR_STATE() AS VARCHAR(500)) + 
						'| ErrLin: ' + CAST(ERROR_LINE() AS VARCHAR(500)) + 
						'| ErrPro: ' + CAST(ERROR_PROCEDURE() AS VARCHAR(500))
		WHERE 
			[SearchLogId] = @NewLogParamId;

END CATCH
	
END -- end SPROC
GO


SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[sp_Get_DashboardPendingReportV2025ByChartIds] 
	 @ChartIds			varchar(MAX)
	,@OrderBy			int			= 0 -- DOS
	,@SortDirection		varchar(4)	= 'A'
	,@PageIndex INT = NULL
	,@PageSize INT = NULL
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SET @PageIndex = IIF(@PageIndex IS NULL OR @PageIndex < 1, 1, @PageIndex)
	SET @PageSize = IIF(@PageSize IS NULL OR @PageSize <= 0 OR @PageSize > 3000, 3000, @PageSize)
	DECLARE @PagingRowSkip INT = @PageSize * (@PageIndex - 1);

	DECLARE @ChartSearchMaxCount INT = 3001;
			
	SELECT	
		CAST(value AS int) Item
	INTO	
		#ChartIdList
	FROM
		STRING_SPLIT(@ChartIds, ',')
	WHERE	
		LEN(value) > 0;

	DELETE FROM #ChartIdList WHERE [Item] IS NULL OR LEN([Item]) <= 1

	IF NOT EXISTS (SELECT TOP 1 1 FROM #ChartIdList)
		RETURN;

	DROP TABLE IF EXISTS #ChartSubset;

	SELECT TOP (@ChartSearchMaxCount)
			c.CHART_ID
		  , c.FACILITY_CHART_ID																				 
		  , c.MEDICAL_RECORD_NUM																			 
		  , c.PATIENT_DOB																					 
		  , c.SERVICE_AGREEMENT_ID																			 
		  , c.CLIENT_COMMENT																				 
		  , c.CHANGED_DATE_TIME																				 
		  , c.CREATION_DATE_TIME																			 
		  , c.TIME_OF_SERVICE																				 
		  , c.TIME_OF_DIS																					 
		  , c.CODER_COMMENT																					 
		  , c.PATIENT_LAST_NAME																				 
		  , c.PATIENT_FIRST_NAME																			 
		  , c.CHART_STATUS_ID																				 
		  , c.PATIENT_DISPOSITION_ID																		 
		  , c.PENDING_REASON_ID																				 
		  , c.FACILITY_ID																					 
		  , c.SENT_DATE																						 
		  , c.LOCATION_CODE																					 
		  , c.FACILITY_ADMIN_CHART_ID																		 
		  , c.PHYSICIAN_ID																					 
		  , c.NURSE_PRACTITIONER_ID																			 
		  , c.PATIENT_CLASS_ID																				 
		  , c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID															 
		  , c.INITIAL_CHARGE_MASTER_DEPT_ID																	 
		  , f.[NAME]														FACILITY 				 
		  , sa.SERVICE_MODEL_CD + CAST(up.USER_CLASS_CD AS varchar(10))  	AS ServiceModelCode		 
		  , up.FIRST_NAME
		  , up.LAST_NAME
		  , c.ASSIGNED_TO_ID
		  , c.LONG_PATIENT_ID1
	INTO	#ChartSubset
	FROM	dbo.CHART						 c WITH (NOLOCK)
			INNER JOIN dbo.FACILITY			 f WITH (NOLOCK)
				ON f.FACILITY_ID = c.FACILITY_ID
			INNER JOIN dbo.USER_PROFILE		 up WITH (NOLOCK)
				ON up.USER_PROFILE_ID = c.ASSIGNED_TO_ID
			INNER JOIN dbo.SERVICE_AGREEMENT sa WITH (NOLOCK)
				ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
	WHERE	c.CHART_ID IN (SELECT [Item] FROM #ChartIdList);

	SELECT	
		 FACILITY_PROF_ID
		,fp.LAST_NAME + ', ' + fp.FIRST_NAME + ' ' + fp.NAME_SUFFIX + ' (' + fp.EMPLOYEE_IDENTIFIER + ')' Professional
	INTO	
		#FacilityProfessionals
	FROM	
		dbo.FACILITY_PROFESSIONAL fp WITH (NOLOCK)
	WHERE
		fp.[FACILITY_PROF_ID] IN (SELECT DISTINCT [PHYSICIAN_ID] FROM #ChartSubset WHERE [PHYSICIAN_ID] > 0 UNION SELECT DISTINCT [NURSE_PRACTITIONER_ID] FROM #ChartSubset WHERE [NURSE_PRACTITIONER_ID] > 0);

	SELECT		
		c.FACILITY
	  , c.CHART_ID
	  , c.FACILITY_CHART_ID
	  , c.MEDICAL_RECORD_NUM
	  , c.PATIENT_DOB
	  , ii.CREATION_DATE_TIME								LAST_IMAGE_RECEIPT_DATE
	  , c.CLIENT_COMMENT
	  , c.CHANGED_DATE_TIME
	  , IIF(ii.CREATION_DATE_TIME IS NOT NULL, 'Yes', 'No') [EMR?]
	  , 'Yes'												[Census?]
	  , c.CREATION_DATE_TIME								Received
	  , c.TIME_OF_SERVICE									DOS
	  , c.TIME_OF_DIS										DISCHARGE
	  , cs.[DESCRIPTION]									[STATUS]
	  , pr.PendingReason									[Pending Reason]
	  , pd.[DESCRIPTION]									[Patient Disposition]
	  , c.CODER_COMMENT										[Coder Notes]
	  --, ii.CREATION_DATE_TIME								[Patient]					-- This appears to be wrong. DACS-3926 - 20241223 - wpippin
	  , IIF(c.PATIENT_FIRST_NAME IS NULL,'',c.PATIENT_FIRST_NAME) + ' ' + IIF(c.PATIENT_LAST_NAME IS NULL,'',c.PATIENT_LAST_NAME)	[Patient]	-- This appears to be wrong. DACS-3926 - 20241223 - wpippin
	  , p.Professional										Physician
	  , c.CHART_STATUS_ID
	  , ISNULL(pc.DESCRIPTION, 'All')						PatientClass
	  , c.PATIENT_DISPOSITION_ID
	  , c.PENDING_REASON_ID
	  , c.FACILITY_ID
	  , c.SENT_DATE											[Sent]
	  , c.LOCATION_CODE
	  , n.Professional										[Mid-Level]
	  , sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC
	  , cmd.NAME											[InitialObservationDept]
	  , c.FACILITY_ADMIN_CHART_ID
	  , c.ServiceModelCode									[Service Model Code]
	  , c.FIRST_NAME										[First Name]
	  , c.LAST_NAME											[Last Name]
	  , pba.ChartPostBillAuditStatusTypeCode				[ChartPostBillAuditStatusTypeCode]
	  , c.LONG_PATIENT_ID1
	FROM
		#ChartSubset													   c
		LEFT JOIN #FacilityProfessionals								   p
			ON p.FACILITY_PROF_ID = c.PHYSICIAN_ID
			   AND c.PHYSICIAN_ID > -1
		LEFT JOIN #FacilityProfessionals								   n
			ON n.FACILITY_PROF_ID = c.NURSE_PRACTITIONER_ID
			   AND c.NURSE_PRACTITIONER_ID > -1
		INNER JOIN dbo.CHART_STATUS										   cs WITH (NOLOCK)
			ON cs.CHART_STATUS_ID = c.CHART_STATUS_ID
		LEFT JOIN dbo.PATIENT_CLASS										   pc WITH (NOLOCK)
			ON pc.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
		LEFT JOIN dbo.PATIENT_DISPOSITION								   pd WITH (NOLOCK)
			ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
		LEFT JOIN dbo.SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao WITH (NOLOCK)
			ON sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
		LEFT JOIN dbo.CHARGE_MASTER_DEPARTMENT							   cmd WITH (NOLOCK)
			ON cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
			   AND c.INITIAL_CHARGE_MASTER_DEPT_ID > -1 										-- reduces LReads by 90% on Charge_Master_Department 
		LEFT JOIN dbo.ChartPostBillAudit								   pba
			ON pba.ChartId = c.CHART_ID
		LEFT JOIN (SELECT	MAX(CREATION_DATE_TIME) CREATION_DATE_TIME
						  , SERVICE_AGREEMENT_ID
						  , FACILITY_CHART_ID
				   FROM		dbo.IMPORT_IMAGE ii WITH (NOLOCK)
				   GROUP BY SERVICE_AGREEMENT_ID
						  , FACILITY_CHART_ID)							   ii
			ON ii.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			   AND ii.FACILITY_CHART_ID = c.FACILITY_CHART_ID
		LEFT JOIN (SELECT	cpr.CHART_ID
						  , STRING_AGG(pr.DESCRIPTION, '|')WITHIN GROUP(ORDER BY sapr.RANK_VALUE ASC) PendingReason
				   FROM		dbo.CHART_PENDING_REASON						cpr WITH (NOLOCK)
							INNER JOIN dbo.SERVICE_AGREEMENT_PENDING_REASON sapr WITH (NOLOCK)
								ON sapr.SERVICE_AGREEMENT_PENDING_REASON_ID = cpr.SERVICE_AGREEMENT_PENDING_REASON_ID
							INNER JOIN dbo.PENDING_REASON					pr WITH (NOLOCK)
								ON pr.PENDING_REASON_ID = sapr.PENDING_REASON_ID
				   GROUP BY cpr.CHART_ID)								   pr
			ON c.CHART_ID = pr.CHART_ID
			   AND c.CHART_STATUS_ID IN (2, 6)
	ORDER BY 
		IIF(@SortDirection = 'A' AND @OrderBy = 0, c.TIME_OF_SERVICE, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 1, c.FACILITY_CHART_ID, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 2, c.MEDICAL_RECORD_NUM, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 3, c.CREATION_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 4, c.CHANGED_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 5, IIF(ii.CREATION_DATE_TIME IS NOT NULL, 'Yes', 'No'), '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 6, 'Yes', '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 7, c.CREATION_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 8, cs.[DESCRIPTION], '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 9, pr.PendingReason, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 10, ii.CREATION_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 11, p.Professional, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 12, c.TIME_OF_DIS, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 13, ii.CREATION_DATE_TIME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 14, ISNULL(pc.DESCRIPTION, 'All'), '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 15, c.FACILITY, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 16, c.SENT_DATE, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 17, c.LOCATION_CODE, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 18, n.Professional, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 19, cmd.NAME, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 20, sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 21, c.FACILITY_ADMIN_CHART_ID, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 22, pd.[DESCRIPTION], '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 23, c.PATIENT_DOB, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy = 24, c.LONG_PATIENT_ID1, '') ASC
	  , IIF(@SortDirection = 'A' AND @OrderBy >= 25, c.TIME_OF_SERVICE, '') ASC
	  
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 0, c.TIME_OF_SERVICE, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 1, c.FACILITY_CHART_ID, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 2, c.MEDICAL_RECORD_NUM, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 3, c.CREATION_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 4, c.CHANGED_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 5, IIF(ii.CREATION_DATE_TIME IS NOT NULL, 'Yes', 'No'), '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 6, 'Yes', '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 7, c.CREATION_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 8, cs.[DESCRIPTION], '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 9, pr.PendingReason, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 10, ii.CREATION_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 11, p.Professional, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 12, c.TIME_OF_DIS, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 13, ii.CREATION_DATE_TIME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 14, ISNULL(pc.DESCRIPTION, 'All'), '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 15, c.FACILITY, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 16, c.SENT_DATE, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 17, c.LOCATION_CODE, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 18, n.Professional, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 19, cmd.NAME, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 20, sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 21, c.FACILITY_ADMIN_CHART_ID, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 22, pd.[DESCRIPTION], '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 23, c.PATIENT_DOB, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy = 24, c.LONG_PATIENT_ID1, '') DESC
	  , IIF(@SortDirection <> 'A' AND @OrderBy >= 25, c.TIME_OF_SERVICE, '') DESC
	  , IIF(@SortDirection = 'A', c.CHART_ID, '') ASC
	  , IIF(@SortDirection <> 'A', c.CHART_ID, '') DESC
	OFFSET @PagingRowSkip ROWS FETCH NEXT @PageSize ROWS ONLY;


/*
-- =============================================
-- Create date: 03/06/2025
-- This SPROC MUST return the same final results as does SPROC [dbo].[sp_Get_DashboardPendingReportv2025]
-- it borrows heavily from the above SPROC as it is meant to server as a kind of caching of the last results from the other SPROC.
-- =============================================
*/
END;

GO
