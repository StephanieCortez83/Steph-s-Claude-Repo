SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 9/8/2014
-- Description:	SQL for the QA Diagnosis Changes by Facility report

-- Edited: Don Hutton 
-- Edited date: 1/8/2016
-- Description: Added ICD10 
-- =============================================
CREATE PROCEDURE [dbo].[rpt_QADiagnosisChangesByFacility] 
	-- Add the parameters for the stored procedure here
	@ReportUser INT, 
	@UserGroups VARCHAR(MAX),
  @Facilities VARCHAR(MAX),
	@DateType INT = 0, -- 0: Date of Service, 1: Sent Date
	@StartDate DATE,
	@EndDate DATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
  DECLARE @m_ReportUser INT = @ReportUser,
    @m_UserGroups VARCHAR(MAX) = @UserGroups,
	  @m_Facilities VARCHAR(MAX) = @Facilities,
	  @m_DateType INT = @DateType,
	  @m_StartDate DATE = @StartDate,
	  @m_EndDate DATE = @EndDate;
	  
declare @ReportUserClass int = (select user_class_cd from user_profile where user_profile_id = @m_ReportUser);


if object_id('TempDB..#PROD1', 'U') is not null				
begin drop table #PROD1 end;				
if object_id('TempDB..#PROD2', 'U') is not null				
begin drop table #PROD2 end;


  WITH USERS
  AS (
	  SELECT USER_PROFILE_ID
	  FROM USER_PROFILE WITH (NOLOCK)
	  WHERE IS_ACTIVE = 'Y'
		  AND USER_GROUP_ID IN (
			  SELECT *
			  FROM dbo.SplitString(@m_UserGroups, ',')
			  )
	
	  UNION
	
	  SELECT up.USER_PROFILE_ID
	  FROM USER_PROFILE up WITH (NOLOCK)
	  INNER JOIN USER_GROUP_TO_USER_PROFILE ug2up WITH (NOLOCK) ON ug2up.USER_PROFILE_ID = up.USER_PROFILE_ID
	  WHERE IS_ACTIVE = 'Y'
		  AND ug2up.USER_GROUP_ID IN (
			  SELECT *
			  FROM dbo.SplitString(@m_UserGroups, ',')
			  )
	  )

select * 	
INTO #USERS	
from USERS	
option (maxdop 4);	
	
;WITH
  FACILITIES
  AS (
	  SELECT DISTINCT FACILITY_ID
	  FROM FACILITY_USER_AUTHORIZATION WITH (NOLOCK)
	  WHERE USER_PROFILE_ID IN (
			  SELECT *
			  FROM #USERS
			  )
		  AND EXISTS (
			  SELECT *
			  FROM dbo.SplitString(@m_Facilities, ',')
			  WHERE ITEMS = FACILITY_ID
			  )
	  )

select * 	
INTO #FACILITIES
from FACILITIES	
option (maxdop 4);
	
  select * into #PROD1 from				
(
select 
'ICD9' as ICD_CODE ,
T1.USER_GROUP_ID,
T1.USER_GROUP,
T1.FACILITY_ID,
T1.FACILITY,
T1.CODER,
T1.ACTION,
T1.DESCRIPTION ,
T1.ICD9_CODE as CODE,

CASE WHEN T1.ICD9_CODE = T1.CHIEF_COMPLAINT	AND T1.ICD9_CODE = T1.PRIMARY_COMPLAINT	THEN 'Chief & Primary'
	 WHEN T1.ICD9_CODE = T1.CHIEF_COMPLAINT	THEN 'Chief Complaint'
	 WHEN T1.ICD9_CODE = T1.PRIMARY_COMPLAINT	THEN 'Primary'
	 ELSE 'Secondary' END as DIAGNOSIS,

case when @ReportUserClass <> 1 AND @ReportUserClass <> T1.AUDITOR_Class then '' else T1.AUDITOR end as AUDITOR,
--T1.AUDITOR,

T1.TIME_OF_SERVICE,
T1.FACILITY_CHART_ID

from ( 

SELECT 
ug.USER_GROUP_ID,
    ug.NAME USER_GROUP,
    f.FACILITY_ID,
	  f.[NAME] FACILITY,
	  up.LAST_NAME + ', ' + up.FIRST_NAME CODER,
	  CASE caa.ACTION
		  WHEN 'A'
			  THEN 'Added'
		  WHEN 'R'
			  THEN 'Removed'
		  END ACTION,


	  LTRIM(RIGHT(caa.Description, LEN(caa.Description)-CHARINDEX(',', caa.Description))) as DESCRIPTION ,
	  left(caa.Description, CHARINDEX(',', caa.Description)-1) as ICD9_CODE,
	  ' ' as ICD10_CODE,


	  aup.LAST_NAME + ', ' + aup.FIRST_NAME AUDITOR,
	  aup.USER_CLASS_CD as AUDITOR_Class,
	  c.TIME_OF_SERVICE,
	  c.FACILITY_CHART_ID, 
	  c.CHIEF_COMPLAINT,
	  c.PRIMARY_COMPLAINT
  FROM CHART c WITH (NOLOCK)
  INNER JOIN CHART_AUDIT_ACTION caa WITH (NOLOCK) ON caa.CHART_ID = c.CHART_ID
  INNER JOIN USER_PROFILE up WITH (NOLOCK) ON up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
  INNER JOIN USER_PROFILE aup WITH (NOLOCK) ON aup.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
  INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
  LEFT JOIN USER_GROUP ug WITH (NOLOCK) ON ug.USER_GROUP_ID = up.USER_GROUP_ID
  WHERE c.CHART_STATUS_ID IN (4, 5) -- Approved & Sent
	  AND EXISTS (
		  SELECT *
		  FROM #FACILITIES
		  WHERE FACILITY_ID = c.FACILITY_ID
		  )

	  AND caa.CLASS = '6' -- Diagnosis Coding
	  AND DATEADD(DAY, DATEDIFF(DAY, 0, CASE @m_DateType
				  WHEN 0
					  THEN c.TIME_OF_SERVICE
				  WHEN 1
					  THEN c.SENT_DATE
				  END), 0) BETWEEN @m_StartDate AND @m_EndDate
	  AND EXISTS (
		  SELECT *
		  FROM #USERS
		  WHERE USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
		  )
) T1
)x;

select * into #PROD2 from				
(	
select 
'ICD10' as ICD_CODE,
T1.USER_GROUP_ID,
T1.USER_GROUP,
T1.FACILITY_ID,
T1.FACILITY,
T1.CODER,
T1.ACTION,
T1.DESCRIPTION ,
T1.ICD10_CODE as CODE,

CASE  WHEN T1.DIAGNOSIS_TYPE_ID = 1	AND T1.IS_PRIMARY = 1	THEN 'Chief Complaint'
      WHEN T1.DIAGNOSIS_TYPE_ID = 2 AND T1.IS_PRIMARY = 1	THEN 'Primary' 
      WHEN T1.DIAGNOSIS_TYPE_ID = 2 AND T1.IS_PRIMARY = 0	THEN 'Secondary' 
      WHEN T1.DIAGNOSIS_TYPE_ID = 3	THEN 'Complaint & Diagnosis'
      ELSE 'NULL' END as DIAGNOSIS,

case when @ReportUserClass <> 1 AND @ReportUserClass <> T1.AUDITOR_Class then '' else T1.AUDITOR end as AUDITOR,
--T1.AUDITOR,
T1.TIME_OF_SERVICE,
T1.FACILITY_CHART_ID

from ( 

SELECT 
c.chart_id ,
ug.USER_GROUP_ID,
    ug.NAME USER_GROUP,
    f.FACILITY_ID,
	  f.[NAME] FACILITY,
	  up.LAST_NAME + ', ' + up.FIRST_NAME CODER,
	  'Added' as  ACTION,

      LTRIM(RIGHT(caa.Description, LEN(caa.Description)-CHARINDEX(',', caa.Description))) as DESCRIPTION ,
	  ' ' as ICD9_CODE,
	  left(caa.Description, CHARINDEX(',', caa.Description)-1) as ICD10_CODE,

	  aup.LAST_NAME + ', ' + aup.FIRST_NAME AUDITOR,
	  aup.USER_CLASS_CD as AUDITOR_Class,
	  c.TIME_OF_SERVICE,
	  c.FACILITY_CHART_ID,
	  dc.DIAGNOSIS_TYPE_ID,
	  dc.IS_PRIMARY 
  FROM CHART c WITH (NOLOCK)
  INNER JOIN CHART_AUDIT_ACTION caa WITH (NOLOCK) ON caa.CHART_ID = c.CHART_ID
  INNER JOIN USER_PROFILE up WITH (NOLOCK) ON up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
  INNER JOIN USER_PROFILE aup WITH (NOLOCK) ON aup.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
  INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
  LEFT JOIN USER_GROUP ug WITH (NOLOCK) ON ug.USER_GROUP_ID = up.USER_GROUP_ID
  inner join CHART_DIAGNOSIS_CODE_ICD10 dc WITH (NOLOCK) on c.CHART_ID = dc.CHART_ID
  and left(caa.Description, CHARINDEX(',', caa.Description)-1) = dc.ICD10_CODE
  WHERE c.CHART_STATUS_ID IN (4, 5) -- Approved & Sent
  	  AND EXISTS (
		  SELECT *
		  FROM #FACILITIES
		  WHERE FACILITY_ID = c.FACILITY_ID
		  )

	  AND caa.CLASS = 'D' -- Diagnosis Coding
	  AND DATEADD(DAY, DATEDIFF(DAY, 0, CASE @m_DateType
				  WHEN 0
					  THEN c.TIME_OF_SERVICE
				  WHEN 1
					  THEN c.SENT_DATE
				  END), 0) BETWEEN @m_StartDate AND @m_EndDate
	  AND EXISTS (
		  SELECT *
		  FROM #USERS
		  WHERE USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
		  )

union

SELECT 
c.chart_id ,
ug.USER_GROUP_ID,
    ug.NAME USER_GROUP,
    f.FACILITY_ID,
	  f.[NAME] FACILITY,
	  up.LAST_NAME + ', ' + up.FIRST_NAME CODER,
	  'Removed' as ACTION,

      LTRIM(RIGHT(caa.Description, LEN(caa.Description)-CHARINDEX(',', caa.Description))) as DESCRIPTION ,
	  ' ' as ICD9_CODE,
	  left(caa.Description, CHARINDEX(',', caa.Description)-1) as ICD10_CODE,

	  aup.LAST_NAME + ', ' + aup.FIRST_NAME AUDITOR,
	  aup.USER_CLASS_CD as AUDITOR_Class,
	  c.TIME_OF_SERVICE,
	  c.FACILITY_CHART_ID,
	  dc.DIAGNOSIS_TYPE_ID,
	  dc.IS_PRIMARY 
  FROM CHART c WITH (NOLOCK)
  INNER JOIN CHART_AUDIT_ACTION caa WITH (NOLOCK) ON caa.CHART_ID = c.CHART_ID
  INNER JOIN USER_PROFILE up WITH (NOLOCK) ON up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
  INNER JOIN USER_PROFILE aup WITH (NOLOCK) ON aup.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
  INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
  LEFT JOIN USER_GROUP ug WITH (NOLOCK) ON ug.USER_GROUP_ID = up.USER_GROUP_ID
  inner join CHART_DIAGNOSIS_CODE_HISTORY_ICD10 dc WITH (NOLOCK) on c.CHART_ID = dc.CHART_ID
  and left(caa.Description, CHARINDEX(',', caa.Description)-1) = dc.ICD10_CODE
  WHERE c.CHART_STATUS_ID IN (4, 5) -- Approved & Sent
  	  AND EXISTS (
		  SELECT *
		  FROM #FACILITIES
		  WHERE FACILITY_ID = c.FACILITY_ID
		  )

	  AND caa.CLASS = 'D' -- Diagnosis Coding
	  AND DATEADD(DAY, DATEDIFF(DAY, 0, CASE @m_DateType
				  WHEN 0
					  THEN c.TIME_OF_SERVICE
				  WHEN 1
					  THEN c.SENT_DATE
				  END), 0) BETWEEN @m_StartDate AND @m_EndDate
	  AND EXISTS (
		  SELECT *
		  FROM #USERS
		  WHERE USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
		  )

) T1
)y;

select * from #PROD1
union
select * from #PROD2
  ORDER BY 
  ICD_CODE DESC,
  USER_GROUP,
  FACILITY,
  CODER,
  FACILITY_CHART_ID,
  ACTION,
  DESCRIPTION

END





GO
GRANT EXECUTE ON  [dbo].[rpt_QADiagnosisChangesByFacility] TO [dbx_ExecuteReportProcs]
GO
