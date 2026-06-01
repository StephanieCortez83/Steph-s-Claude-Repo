SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Don Hutton
-- Create date: 3/22/2019
-- Description:	SQL for the No Infusion Stop Time Report
-- =============================================
CREATE PROCEDURE [dbo].[rpt_NoInfusionStopTimeReport]
	-- Add the parameters for the stored procedure here
@ReportUser int,
@StartDate date,
@ThruDate date,
@DateType varchar(20),
@MonthView int,
@Company int,
@Facility varchar(max),
@Department varchar(max),
@DeptType int,
@Combine int



AS
BEGIN





	---- TEST PARMS
	--declare
	--     @ReportUser   int           = 80
	--	,@StartDate   datetime     = '20220801'
	--	,@ThruDate    datetime     = '20220831'
	--	,@DateType    varchar(20)  = 'Sent'
	--	,@MonthView   int          = 1   -- 0 Fullmonth, 1 Use Date Parms 
	--    ,@Company     int          = 33
	--	,@Facility    varchar(max) = '-1'
	--	,@Department varchar(max) = '-1' -- -1 All
 --       ,@DeptType   int		   = -1	
	--    ,@Combine    int          = 1 ; -- 1 Facility, 0 Company		
	---- TEST PARMS






	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	set transaction isolation level read uncommitted
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	declare @m_ReportUser int = @ReportUser
	declare @m_StartDate date = @StartDate
	declare @m_ThruDate date = @ThruDate	
	declare @m_DateType varchar(20) = @DateType
	declare @m_MonthView int = @MonthView
	declare @m_Company int = @Company
	declare @m_Facility varchar(max) = @Facility
    declare @m_Department varchar(max) = @Department
    declare @m_DeptType int = @DeptType
	declare @m_Combine INT = @Combine;




-----------------------------------------------------------------------------------

if object_ID('TempDB..#Facility', 'U') is not null drop table #Facility;


SELECT *
INTO #Facility
FROM (
    SELECT DISTINCT fua.FACILITY_ID
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id 
	and up.IS_ACTIVE = 'Y'						
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser
	and sa.company_id = @m_Company
    and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_Facility, ','))
            OR	-1 in (SELECT * FROM SPLITSTRING(@m_Facility, ',')) )
union

    SELECT DISTINCT fua.FACILITY_ID
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id 
	and up.IS_ACTIVE = 'Y'						
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser
	and sa.company_id = 19
	and sa.company_id = @m_Company
    and -2 in (SELECT * FROM SPLITSTRING(@m_Facility, ',')) 
	and sa.facility_id  not in ( 2436, 2437, 2410, 2411, 2412, 2413, 2371, 2372, 2373 ) -- Conifer Sites RAP-383

union

    SELECT DISTINCT fua.FACILITY_ID
	FROM FACILITY_USER_AUTHORIZATION fua,
	USER_PROFILE up,
	SERVICE_AGREEMENT sa
	WHERE 
	fua.user_profile_id = up.user_profile_id
	and fua.facility_id = sa.facility_id 
	and up.IS_ACTIVE = 'Y'						
	and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE
	and getdate () between sa.EFFECTIVE_DATE and sa.EXPIRATION_DATE
	and sa.DEMO_TEST_SITE_IND = 0
	and fua.USER_PROFILE_ID = @m_ReportUser
	and sa.company_id = 19
	and sa.company_id = @m_Company
    and -3 in (SELECT * FROM SPLITSTRING(@m_Facility, ',')) 
	and sa.facility_id  in ( 2436, 2437, 2410, 2411, 2412, 2413, 2371, 2372, 2373 ) -- Conifer Sites RAP-383
	) fa;

create nonclustered index idx_Facility_ID on #Facility (Facility_ID)

-----------------------------------------------------------------------------------

if object_ID('TempDB..#Department', 'U') is not null drop table #Department;

select CHARGE_MASTER_DEPT_ID 
into #Department
from CHARGE_MASTER_DEPARTMENT cmd
where 
cmd.service_agreement_id in ( select service_agreement_id from service_agreement where facility_id IN ( SELECT Facility_ID FROM #Facility ) )
and cmd.OBSERVATION_IND = CASE WHEN @m_DeptType <> -1 
                               THEN CASE WHEN @m_DeptType = 1 THEN 0
                                         ELSE 1 END 
                                         ELSE cmd.OBSERVATION_IND END

--and cmd.name in ( select name from CHARGE_MASTER_DEPARTMENT where CHARGE_MASTER_DEPT_ID IN (SELECT ITEMS FROM dbo.SplitString(@m_Department, ',') ) )
and cmd.name in ( select name from CHARGE_MASTER_DEPARTMENT where CHARGE_MASTER_DEPT_ID IN (SELECT ITEMS FROM dbo.SplitString(@m_Department, ',') ) 
or -1 IN (SELECT ITEMS FROM dbo.SplitString(@m_Department, ',') ) )


create nonclustered index idx_CHARGE_MASTER_DEPT_ID on #Department (CHARGE_MASTER_DEPT_ID)


--------------------------------------------------------------------------------------------------------------------------------


IF @m_Combine = 1	 -- keeps data at facility level
BEGIN	


-- Infusion No Stop Time List
select x.name 'Facility', x.facility_chart_id 'Patient ID', Patient, Initials, x.InfusionType 'Infusion Type',
       x.facility_id, x.start_date, CCSDisposition 'CCS Disposition', FacDisposition 'Fac Disposition', DispClass, x.APC_Rate,
	   case when x.INFUSION_TYPE = 6 then ABS(x.charge_96375 - charge_96365)
            when x.INFUSION_TYPE = 7 then charge_96361 
            when x.INFUSION_TYPE = 9 then ABS(x.charge_96413 - x.charge_96411)
			when x.INFUSION_TYPE = 11 then ABS(x.charge_96422 - x.charge_96420)
            else 0 end as Facility_Rate, x.OBSERVATION_IND, x.Department, x.Unit, x.Generic_Name
from (
select f.NAME,
       c.FACILITY_CHART_ID,
			 c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME as 'Patient',
			 UPPER(ci.INITIALS) as 'Initials',
       it.DESCRIPTION as InfusionType, c.facility_id, ci.START_DATE,
       pd.DESCRIPTION CCSDisposition,
			 (select pdm.FACILITY_PATIENT_DISPOSITION from PATIENT_DISPOSITION_MAP pdm
			          where pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID) FacDisposition,
 (case when (select (case when c.patient_disposition_id = 5 then 1
                           when pd.OUTPATIENT_IND = 0 then 0 
                           else 1 end) Outpatient
	            from   PATIENT_DISPOSITION pd 
              where pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID) = 0 then 'Inpatients' 
        else 'Outpatients' end) DispClass,       
       it.apc_rate,
       ISNULL(cmd.OBSERVATION_IND, 0) AS OBSERVATION_IND,
       cmd.[NAME] AS Department,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96361') AS charge_96361,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96365') AS charge_96365,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96375') as charge_96375,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96411') AS charge_96411,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96413') as charge_96413,
		  (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96420') as charge_96420,
		(SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96422') as charge_96422,
       it.INFUSION_TYPE,
       crd.MED_SERVICE Unit,
       UPPER(LEFT(ci.generic_substance_name,1))+LOWER(SUBSTRING(ci.generic_substance_name,2,LEN(ci.generic_substance_name))) as Generic_Name       
from chart c
join chart_infusion ci on c.CHART_ID = ci.CHART_ID
left outer join CHARGE_MASTER_DEPARTMENT cmd on cmd.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
left outer join CHART_REPORTING_DATA crd on crd.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID and crd.FACILITY_CHART_ID = c.FACILITY_CHART_ID, 
facility f, 
infusion_type it, 
patient_disposition pd
where ci.CHART_ID = c.CHART_ID
and   ci.NO_STOP_TIME = 1
and   f.FACILITY_ID = c.FACILITY_ID
and   f.FACILITY_ID IN ( SELECT Facility_ID FROM #Facility )
and   it.INFUSION_TYPE = ci.INFUSION_TYPE
and   it.NO_STOP_TIME_IND = 1
and   c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
and   c.chart_status_id = 5
and   case when @m_DateType='Sent' then dateadd(day, datediff(day, 0, c.sent_date), 0) else dateadd(day, datediff(day, 0, c.time_of_service), 0) end 
  between case when @m_MonthView=0 then @m_StartDate else DATEADD(dd,-(DAY(@m_StartDate)-1),@m_StartDate) end 
    and case when @m_MonthView=0 then @m_ThruDate else DATEADD(dd,-(DAY(DATEADD(mm,1,@StartDate))),DATEADD(mm,1,@StartDate)) end
and ci.CHARGE_MASTER_DEPT_ID IN ( SELECT CHARGE_MASTER_DEPT_ID FROM #Department ) --in (@Department)
)x
--WHERE x.OBSERVATION_IND = CASE WHEN @DeptType <> -1 
--                               THEN CASE WHEN @DeptType = 1 THEN 0
--                                         ELSE 1 END 
--                                         ELSE x.OBSERVATION_IND END
                                                             
order by x.name, DispClass desc, UPPER(x.INITIALS), x.InfusionType, x.FACILITY_CHART_ID

END



--------------------------------------------------------------------------------------------------------------------------------

ELSE	
IF   @m_Combine = 0	-- this combines data at company level
BEGIN


-- Infusion No Stop Time List
select x.name 'Facility', x.facility_chart_id 'Patient ID', Patient, Initials, x.InfusionType 'Infusion Type',
       x.facility_id, x.start_date, CCSDisposition 'CCS Disposition', FacDisposition 'Fac Disposition', DispClass, x.APC_Rate, 
       case when x.INFUSION_TYPE = 6 then ABS(x.charge_96375 - charge_96365)
            when x.INFUSION_TYPE = 7 then charge_96361 
            when x.INFUSION_TYPE = 9 then ABS(x.charge_96413 - x.charge_96411)
			when x.INFUSION_TYPE = 11 then ABS(x.charge_96422 - x.charge_96420)	   
            else 0 end as Facility_Rate, x.OBSERVATION_IND, x.Department, x.Unit, x.Generic_Name
from (
select co.NAME,
       c.FACILITY_CHART_ID,
			 c.PATIENT_LAST_NAME + ', ' + c.PATIENT_FIRST_NAME as 'Patient',
			 UPPER(ci.INITIALS) as 'Initials',
       it.DESCRIPTION as InfusionType, c.facility_id, ci.START_DATE,
       pd.DESCRIPTION CCSDisposition,
			 (select pdm.FACILITY_PATIENT_DISPOSITION from PATIENT_DISPOSITION_MAP pdm
			          where pdm.PATIENT_DISPOSITION_MAP_ID = c.PATIENT_DISPOSITION_MAP_ID) FacDisposition,
 (case when (select (case when c.patient_disposition_id = 5 then 1
                           when pd.OUTPATIENT_IND = 0 then 0 
                           else 1 end) Outpatient
	            from   PATIENT_DISPOSITION pd 
              where pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID) = 0 then 'Inpatients' 
        else 'Outpatients' end) DispClass,       
       it.apc_rate,
       ISNULL(cmd.OBSERVATION_IND, 0) AS OBSERVATION_IND,
       cmd.[NAME] AS Department,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96361') AS charge_96361,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96365') AS charge_96365,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96375') as charge_96375,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96411') AS charge_96411,
       (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96413') as charge_96413,
		  (SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96420') as charge_96420,
		(SELECT MAX(ca.CHARGE_AMOUNT)
        FROM CHARGE_MASTER cm WITH (NOLOCK)
        JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
        WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
          AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
		  AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
		  AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1)
          AND CPT_CODE = '96422') as charge_96422,
       it.INFUSION_TYPE,
       crd.MED_SERVICE Unit,
       UPPER(LEFT(ci.generic_substance_name,1))+LOWER(SUBSTRING(ci.generic_substance_name,2,LEN(ci.generic_substance_name))) as Generic_Name       
from chart c
join chart_infusion ci on c.CHART_ID = ci.CHART_ID
left outer join CHARGE_MASTER_DEPARTMENT cmd on cmd.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
left outer join CHART_REPORTING_DATA crd on crd.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID and crd.FACILITY_CHART_ID = c.FACILITY_CHART_ID, 
service_agreement sa,
company co, 
infusion_type it, 
patient_disposition pd
where ci.CHART_ID = c.CHART_ID
and   ci.NO_STOP_TIME = 1
and   c.service_agreement_id = sa.service_agreement_id
and   sa.company_id = co.company_id
and   c.FACILITY_ID IN ( SELECT Facility_ID FROM #Facility )
and   it.INFUSION_TYPE = ci.INFUSION_TYPE
and   it.NO_STOP_TIME_IND = 1
and   c.PATIENT_DISPOSITION_ID = pd.PATIENT_DISPOSITION_ID
and   c.chart_status_id = 5
and   case when @m_DateType='Sent' then dateadd(day, datediff(day, 0, c.sent_date), 0) else dateadd(day, datediff(day, 0, c.time_of_service), 0) end 
  between case when @m_MonthView=0 then @m_StartDate else DATEADD(dd,-(DAY(@m_StartDate)-1),@m_StartDate) end 
    and case when @m_MonthView=0 then @m_ThruDate else DATEADD(dd,-(DAY(DATEADD(mm,1,@m_StartDate))),DATEADD(mm,1,@m_StartDate)) end
and ci.CHARGE_MASTER_DEPT_ID IN ( SELECT CHARGE_MASTER_DEPT_ID FROM #Department ) --in (@Department)
)x
--WHERE x.OBSERVATION_IND = CASE WHEN @DeptType <> -1 
--                               THEN CASE WHEN @DeptType = 1 THEN 0
--                                         ELSE 1 END 
--                                         ELSE x.OBSERVATION_IND END
                                                             
order by x.name, DispClass desc, UPPER(x.INITIALS), x.InfusionType, x.FACILITY_CHART_ID


END






END













GO
GRANT EXECUTE ON  [dbo].[rpt_NoInfusionStopTimeReport] TO [dbx_ExecuteReportProcs]
GO
