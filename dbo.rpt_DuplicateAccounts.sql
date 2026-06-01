SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 7/9/2013
-- Description:	Reports duplicate accounts accross an organization
--              matching on patient name, date of birth, gender and
--              date of service within 24 hours.

-- *****************************************************************
-- Edited on 6/2/2016 Don Hutton
-- Added FACILITY and SERVICE parameters
-- Added TIME_OF_DIS column

-- Edited on 10/5/2021 Don Hutton
-- AAR-1630 Added CPT_CODE

-- AAR-1857 03/15/22 Don Hutton
-- Added Facility_Procedure_CPT

-- =============================================
CREATE PROCEDURE [dbo].[rpt_DuplicateAccounts]
  @Organization INT,
  @DOSFrom DATE,
  @DOSTo DATE,
  @ReportUser INT,
  @SERVICE as varchar(max),
  @FACILITY as varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


  DECLARE @m_Organization INT = @Organization;
  DECLARE @m_DOSFrom DATE = @DOSFrom;
  DECLARE @m_DOSTo DATE = @DOSTo;
  DECLARE @m_ReportUser INT = @ReportUser;
  DECLARE @m_SERVICE varchar(max) = @SERVICE ;  
  DECLARE @m_FACILITY varchar(max) = @FACILITY ; 


-- Implemented three #temp tables to reduce logical reads by 98% (8M vs 100K). Also reduces CPU and duration by 80%.  dsexton, 3/17/2022
if object_id('TempDB..#Charts', 'U') is not null DROP TABLE #Charts
if object_id('TempDB..#Charts2', 'U') is not null DROP TABLE #Charts2
if object_id('TempDB..#ChartsFinal', 'U') is not null DROP TABLE #ChartsFinal


select 
	chart_ID,
	f.[NAME] AS FACILITY,
	c.FACILITY_CHART_ID,
	c.TIME_OF_SERVICE,
	c.Service_agreement_ID,

	Facility_Level_ID = cast(null as int),
	Date_received = cast(null as datetime),
	time_of_DIS = cast(null as datetime),
	patient_first_name = cast(null as varchar(50)), 
	patient_last_name =  cast(null as varchar(100)),
	patient_dob = cast(null as datetime), 
	gender = cast(null as varchar(10))
  into #Charts
FROM CHART c WITH (NOLOCK)
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK)
	ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
INNER JOIN FACILITY f WITH (NOLOCK)
	ON f.FACILITY_ID = c.FACILITY_ID
LEFT OUTER JOIN FACILITY_LEVEL fl  
ON c.SERVICE_AGREEMENT_ID = fl.SERVICE_AGREEMENT_ID
and c.facility_level_id = fl.facility_level_id 
WHERE sa.COMPANY_ID = @m_Organization
AND sa.facility_id IN (SELECT * FROM SPLITSTRING(@m_FACILITY, ','))
	AND c.CHART_STATUS_ID IN (1,2,3,4,5)
	AND DATEADD(DAY, DATEDIFF(DAY, 0, TIME_OF_SERVICE), 0) BETWEEN @m_DOSFrom	AND @m_DOSTo
	AND sa.SERVICE_MODEL_CD IN (SELECT * FROM SPLITSTRING(@m_SERVICE, ','))
	AND c.FACILITY_ID IN (
		SELECT FACILITY_ID
		FROM FACILITY_USER_AUTHORIZATION fua WITH (NOLOCK)
		WHERE fua.USER_PROFILE_ID = @m_ReportUser
		)

	
select chart_ID, 
	time_of_service,
	patient_first_name = cast(null as varchar(50)), 
	patient_last_name =  cast(null as varchar(100)),
	patient_dob = cast(null as datetime), 
	gender = cast(null as varchar(10))
  into #Charts2
FROM CHART c2 WITH (NOLOCK)
INNER JOIN SERVICE_AGREEMENT sa2 WITH (NOLOCK)
	ON sa2.SERVICE_AGREEMENT_ID = c2.SERVICE_AGREEMENT_ID
WHERE 
	sa2.COMPANY_ID = @m_Organization
	AND sa2.facility_id IN (SELECT * FROM SPLITSTRING(@m_FACILITY, ','))
	AND c2.CHART_STATUS_ID IN (1,2,3,4,5)
    AND sa2.SERVICE_MODEL_CD IN (SELECT * FROM SPLITSTRING(@m_SERVICE, ','))
	AND DATEADD(DAY, DATEDIFF(DAY, 0, c2.TIME_OF_SERVICE), 0) BETWEEN @m_DOSFrom	AND @m_DOSTo


update t
set 
	t.date_received = c.date_received,
	t.time_of_dis = c.time_of_dis,
	t.facility_level_ID = c.facility_Level_ID,
	t.patient_first_name = c.patient_first_name,
	t.patient_last_name = c.patient_last_name,
	t.patient_DOB = c.patient_DOB,
	t.gender = c.gender
from #Charts as t
	join CHART as c on t.chart_ID = c.chart_ID

update t
set t.patient_first_name = c.patient_first_name,
	t.patient_last_name = c.patient_last_name,
	t.patient_DOB = c.patient_DOB,
	t.gender = c.gender
from #Charts2 as t
	join CHART as c on t.chart_ID = c.chart_ID


select *
 INTO #ChartsFinal
from #Charts as c
WHERE exists
	(select 1 
	from #Charts2 as c2
	where
		c2.CHART_ID <> c.CHART_ID
		AND LTRIM(RTRIM(c2.PATIENT_LAST_NAME)) = LTRIM(RTRIM(c.PATIENT_LAST_NAME))
		AND LTRIM(RTRIM(c2.PATIENT_FIRST_NAME)) = LTRIM(RTRIM(c.PATIENT_FIRST_NAME))
		AND (
		 DATEDIFF(HOUR, c2.TIME_OF_SERVICE, c.TIME_OF_SERVICE) BETWEEN 0	AND 24
		 OR DATEDIFF(HOUR, c.TIME_OF_SERVICE, c2.TIME_OF_SERVICE) BETWEEN 0 AND 24
		 )
	AND DATEADD(dd, DATEDIFF(DAY, 0, c2.PATIENT_DOB), 0) = DATEADD(DAY, DATEDIFF(DAY, 0, c.PATIENT_DOB), 0)
	 AND c2.GENDER = c.GENDER
	 )


  SELECT 
	c.Facility,
	  c.FACILITY_CHART_ID,
	  c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME AS PATIENT_NAME,
	  c.TIME_OF_SERVICE,
	  c.PATIENT_DOB,
	  c.GENDER,
	  c.DATE_RECEIVED,
	  c.TIME_OF_DIS,
	  fl.CPT_CODE,

	    LTRIM(STUFF(
  	  (select  ', ' + cm.CPT_CODE
		from 
		FACILITY_PROCEDURE_EVALUATION fpe,
     	CHARGE_MASTER cm
		where fpe.CHART_ID = c.CHART_ID
		and   cm.CHARGE_MASTER_ID = fpe.FACILITY_PROCEDURE_ID 
		  ORDER BY cm.CPT_CODE
		  FOR XML PATH(''),					
	   TYPE				
       ).value('.', 'VARCHAR(MAX)'), 1, 1, '')		
	   ) as Facility_Procedure_CPT  	  

  FROM 
	#ChartsFinal as c
	LEFT OUTER JOIN FACILITY_LEVEL fl  
		ON c.SERVICE_AGREEMENT_ID = fl.SERVICE_AGREEMENT_ID
		and c.facility_level_id = fl.facility_level_id 
  ORDER BY PATIENT_NAME,
	  TIME_OF_SERVICE,
	  FACILITY,
	  PATIENT_DOB,
	  GENDER,
	  FACILITY_CHART_ID

END
GO
GRANT EXECUTE ON  [dbo].[rpt_DuplicateAccounts] TO [dbx_ExecuteReportProcs]
GO
