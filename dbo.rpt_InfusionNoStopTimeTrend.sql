SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





-- =============================================
-- Author:		Daniel Bonebrake
-- Create date: 6/26/2014
-- Description:	SQL for the Infusion No Stop Time Trend Report
-- Modifications: 
--				Jay Herrera | 2/25/2020 | AAR-58 | Added date range parms.
-- =============================================
CREATE PROCEDURE [dbo].[rpt_InfusionNoStopTimeTrend]
	-- Add the parameters for the stored procedure here
    @ReportUser int,
	@StartDate datetime,
	@EndDate datetime,
	@Company int,
	@Facility VARCHAR(MAX),
	@RateBasis INT = 0, -- Default APC Rate
	@GroupBy INT = 0, -- 0: No Grouping, 1: Patient Class, 2: Department
	@Departments VARCHAR(MAX) = NULL,
	@Combine INT
as

begin
	
	set transaction isolation level read uncommitted
	set nocount on;

	---- TEST PARMS
	--declare
	--  @ReportUser   int           = 80
	--	,@StartDate   datetime     = '20220801'
	--	,@EndDate     datetime     = '20220831'
	--    ,@Company     int          = 33
	--	,@Facility    varchar(max) = '276'
	--	,@RateBasis   int          = 0
	--	,@GroupBy     int          = 0
	--	,@Departments varchar(max) = '-1'
	--	,@Combine     int          = 1;
	---- TEST PARMS

	-- Insert statements for procedure here
	declare
         @m_ReportUser   int         = @ReportUser
		,@First_Day     datetime     = @StartDate	--dateadd(month, -13, dateadd(month, datediff(month, 0, getdate()), 0))
		,@Last_Day      datetime     = @EndDate		--dateadd(month, datediff(month, 0, cast(getdate() as date)), 0) - 1
		,@m_Company     int          = @Company
		,@m_Facility    varchar(max) = @Facility
		,@m_RateBasis   int          = @RateBasis
		,@m_GroupBy     int          = @GroupBy
		,@m_Departments varchar(max) = @Departments
		,@m_Combine     int          = @Combine;


if object_ID('TempDB..#Facility', 'U') is not null drop table #Facility;


		--SELECT ITEMS as Facility_ID
		--into #Facility
		--FROM dbo.SplitString(@m_Facility, ',')


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
	) fa;



create nonclustered index idx_Facility_ID on #Facility (Facility_ID)

-------------------------------------------------------------

if object_ID('TempDB..#Department', 'U') is not null drop table #Department;

select CHARGE_MASTER_DEPT_ID 
into #Department
from CHARGE_MASTER_DEPARTMENT cmd
where 
cmd.service_agreement_id in ( select service_agreement_id from service_agreement where facility_id IN ( SELECT Facility_ID FROM #Facility ) )
and cmd.name in ( select name from CHARGE_MASTER_DEPARTMENT where CHARGE_MASTER_DEPT_ID IN (SELECT ITEMS FROM dbo.SplitString(@m_Departments, ',') ) 
                  or -1 IN (SELECT ITEMS FROM dbo.SplitString(@m_Departments, ',') ) 
				)





create nonclustered index idx_CHARGE_MASTER_DEPT_ID on #Department (CHARGE_MASTER_DEPT_ID)



-------------------------------------------------------------------

--declare @Fac_Cnt int = (select count(Facility_ID) from #Facility)


IF @m_Combine = 1	 -- keeps data at facility level
BEGIN	



	SELECT x.FACILITY_ID,
		f.NAME FName,
		x.DOSMonth,
		SUM(CASE 
				WHEN x.Outpatient = 0
					THEN x.NoStop
				ELSE 0
				END) IP_NoStop,
		SUM(CASE 
				WHEN x.Outpatient = 1
					THEN x.NoStop
				ELSE 0
				END) OP_NoStop,
		SUM(CASE 
				WHEN x.Outpatient = 0
					THEN x.RATE
				ELSE 0
				END) IP_Rate,
		SUM(CASE 
				WHEN x.Outpatient = 1
					THEN x.RATE
				ELSE 0
				END) OP_Rate,
		COUNT(*) Total,
		x.GROUP_DESC,
		x.GROUP_ID,
		case when f.abbreviated_name = '' then name 
             when f.abbreviated_name is null then name 
	         else f.abbreviated_name end as Tab_Name
	FROM FACILITY f,
		(
			SELECT c.FACILITY_ID,
				c.SERVICE_AGREEMENT_ID,
				c.CHART_ID,
				DATEADD(MONTH, DATEDIFF(MONTH, 0, c.TIME_OF_SERVICE), 0) DOSMonth,
				CASE 
					WHEN c.PATIENT_DISPOSITION_ID = 5
						THEN 1
					WHEN pd.OUTPATIENT_IND = 0
						THEN 0
					ELSE 1
					END Outpatient,
				
				ci.INFUSION_TYPE,
				CASE 
					WHEN ci.NO_STOP_TIME = 1
						THEN 1
					ELSE 0
					END NoStop,
				CASE 
					WHEN it.CHEMO_IND = 1
						THEN 1
					ELSE 0
					END Chemo,
				CASE 
					WHEN it.HYDRATION_IND = 1
						THEN 1
					ELSE 0
					END Hydration,
				ci.INITIALS,
				it.APC_RATE RATE,
				CASE @m_GroupBy
					WHEN 1
						THEN pc.[DESCRIPTION]
					WHEN 2
						THEN cmd.[NAME]
					ELSE NULL
					END GROUP_DESC,
				CASE @m_GroupBy
					WHEN 1
						THEN c.PATIENT_CLASS_ID
					WHEN 2
						THEN ci.CHARGE_MASTER_DEPT_ID
					ELSE NULL
					END GROUP_ID
			FROM CHART c
			INNER JOIN CHART_INFUSION ci WITH (NOLOCK) ON ci.CHART_ID = c.CHART_ID
			INNER JOIN INFUSION_TYPE it WITH (NOLOCK) ON it.INFUSION_TYPE = ci.INFUSION_TYPE
			INNER JOIN PATIENT_CLASS pc WITH (NOLOCK) ON pc.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
			INNER JOIN CHARGE_MASTER_DEPARTMENT cmd WITH (NOLOCK) ON cmd.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
			LEFT JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
			WHERE it.INJECTION = 0
				AND @m_RateBasis = 0
				AND c.CHART_STATUS_ID = 5
				AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN @First_Day AND @Last_Day
				AND ci.CHARGE_MASTER_DEPT_ID IN ( SELECT CHARGE_MASTER_DEPT_ID FROM #Department)				
				
			
			UNION ALL
			
			SELECT c.FACILITY_ID,
				c.SERVICE_AGREEMENT_ID,
				c.CHART_ID,
				DATEADD(MONTH, DATEDIFF(MONTH, 0, c.TIME_OF_SERVICE), 0) DOSMonth,
				CASE 
					WHEN c.PATIENT_DISPOSITION_ID = 5
						THEN 1
					WHEN pd.OUTPATIENT_IND = 0
						THEN 0
					ELSE 1
					END Outpatient,
				
				ci.INFUSION_TYPE,
				CASE 
					WHEN ci.NO_STOP_TIME = 1
						THEN 1
					ELSE 0
					END NoStop,
				CASE 
					WHEN it.CHEMO_IND = 1
						THEN 1
					ELSE 0
					END Chemo,
				CASE 
					WHEN it.HYDRATION_IND = 1
						THEN 1
					ELSE 0
					END Hydration,
				ci.INITIALS,
				CASE ci.INFUSION_TYPE
					WHEN 7
						THEN (
								SELECT MAX(ca.CHARGE_AMOUNT)
								FROM CHARGE_MASTER cm WITH (NOLOCK)
								INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
								WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
									AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
									AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
									AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                    AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
									AND CPT_CODE = '96361'
								)
					WHEN 6
						THEN ABS((
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96375'
									) - (
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96365'
									))
					WHEN 9
						THEN ABS((
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96413'
									) - (
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96411'
									))

					WHEN 11
						THEN ABS((
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96422'
									) - (
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96420'
									))
					ELSE 0
					END AS RATE,
				CASE @m_GroupBy
					WHEN 1
						THEN pc.[DESCRIPTION]
					WHEN 2
						THEN cmd.[NAME]
					ELSE NULL
					END GROUP_DESC,
				CASE @m_GroupBy
					WHEN 1
						THEN c.PATIENT_CLASS_ID
					WHEN 2
						THEN ci.CHARGE_MASTER_DEPT_ID
					ELSE NULL
					END GROUP_ID
			FROM CHART c
			INNER JOIN CHART_INFUSION ci WITH (NOLOCK) ON ci.CHART_ID = c.CHART_ID
			INNER JOIN INFUSION_TYPE it WITH (NOLOCK) ON it.INFUSION_TYPE = ci.INFUSION_TYPE
			INNER JOIN PATIENT_CLASS pc WITH (NOLOCK) ON pc.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
			INNER JOIN CHARGE_MASTER_DEPARTMENT cmd WITH (NOLOCK) ON cmd.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
			LEFT JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
			WHERE it.INJECTION = 0
				AND @m_RateBasis = 1
				AND c.CHART_STATUS_ID = 5				
				AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN @First_Day AND @Last_Day
				AND ci.CHARGE_MASTER_DEPT_ID IN ( SELECT CHARGE_MASTER_DEPT_ID FROM #Department )				
				
			) x
	WHERE f.FACILITY_ID = x.FACILITY_ID
		AND x.FACILITY_ID IN ( SELECT Facility_ID FROM #Facility )
	GROUP BY x.FACILITY_ID,
		f.NAME,
		x.DOSMonth,
		x.GROUP_ID,
		x.GROUP_DESC,
		case when f.abbreviated_name = '' then name 
             when f.abbreviated_name is null then name 
	         else f.abbreviated_name end
	ORDER BY FName,
		FACILITY_ID,
		DOSMonth,
		GROUP_DESC

END
ELSE	
IF   @m_Combine = 0	-- this combines data at company level
BEGIN	

SELECT  c.company_id FACILITY_ID,
		c.NAME FName,
		x.DOSMonth,
		SUM(CASE 
				WHEN x.Outpatient = 0
					THEN x.NoStop
				ELSE 0
				END) IP_NoStop,
		SUM(CASE 
				WHEN x.Outpatient = 1
					THEN x.NoStop
				ELSE 0
				END) OP_NoStop,
		SUM(CASE 
				WHEN x.Outpatient = 0
					THEN x.RATE
				ELSE 0
				END) IP_Rate,
		SUM(CASE 
				WHEN x.Outpatient = 1
					THEN x.RATE
				ELSE 0
				END) OP_Rate,
		COUNT(*) Total,
		x.GROUP_DESC,
		x.GROUP_ID, 
		c.NAME as Tab_Name
	FROM company c,
	service_agreement sa, 
		(
			SELECT c.FACILITY_ID,
				c.SERVICE_AGREEMENT_ID,
				c.CHART_ID,
				DATEADD(MONTH, DATEDIFF(MONTH, 0, c.TIME_OF_SERVICE), 0) DOSMonth,
				CASE 
					WHEN c.PATIENT_DISPOSITION_ID = 5
						THEN 1
					WHEN pd.OUTPATIENT_IND = 0
						THEN 0
					ELSE 1
					END Outpatient,
				
				ci.INFUSION_TYPE,
				CASE 
					WHEN ci.NO_STOP_TIME = 1
						THEN 1
					ELSE 0
					END NoStop,
				CASE 
					WHEN it.CHEMO_IND = 1
						THEN 1
					ELSE 0
					END Chemo,
				CASE 
					WHEN it.HYDRATION_IND = 1
						THEN 1
					ELSE 0
					END Hydration,
				ci.INITIALS,
				it.APC_RATE RATE,
				CASE @m_GroupBy
					WHEN 1
						THEN pc.[DESCRIPTION]
					WHEN 2
						THEN cmd.[NAME]
					ELSE NULL
					END GROUP_DESC,
				CASE @m_GroupBy
					WHEN 1
						THEN c.PATIENT_CLASS_ID
					WHEN 2
						THEN ci.CHARGE_MASTER_DEPT_ID
					ELSE NULL
					END GROUP_ID
			FROM CHART c
			INNER JOIN CHART_INFUSION ci WITH (NOLOCK) ON ci.CHART_ID = c.CHART_ID
			INNER JOIN INFUSION_TYPE it WITH (NOLOCK) ON it.INFUSION_TYPE = ci.INFUSION_TYPE
			INNER JOIN PATIENT_CLASS pc WITH (NOLOCK) ON pc.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
			INNER JOIN CHARGE_MASTER_DEPARTMENT cmd WITH (NOLOCK) ON cmd.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
			LEFT JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
			WHERE it.INJECTION = 0
				AND @m_RateBasis = 0
				AND c.CHART_STATUS_ID = 5
				AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN @First_Day AND @Last_Day
				AND ci.CHARGE_MASTER_DEPT_ID IN ( SELECT CHARGE_MASTER_DEPT_ID FROM #Department )
			
			UNION ALL
			
			SELECT 
			    c.FACILITY_ID,
				c.SERVICE_AGREEMENT_ID,
				c.CHART_ID,
				DATEADD(MONTH, DATEDIFF(MONTH, 0, c.TIME_OF_SERVICE), 0) DOSMonth,
				CASE 
					WHEN c.PATIENT_DISPOSITION_ID = 5
						THEN 1
					WHEN pd.OUTPATIENT_IND = 0
						THEN 0
					ELSE 1
					END Outpatient,
				
				ci.INFUSION_TYPE,
				CASE 
					WHEN ci.NO_STOP_TIME = 1
						THEN 1
					ELSE 0
					END NoStop,
				CASE 
					WHEN it.CHEMO_IND = 1
						THEN 1
					ELSE 0
					END Chemo,
				CASE 
					WHEN it.HYDRATION_IND = 1
						THEN 1
					ELSE 0
					END Hydration,
				ci.INITIALS,
				CASE ci.INFUSION_TYPE
					WHEN 7
						THEN (
								SELECT MAX(ca.CHARGE_AMOUNT)
								FROM CHARGE_MASTER cm WITH (NOLOCK)
								INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
								WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
									AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
									AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
									AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                    AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
									AND CPT_CODE = '96361'
								)
					WHEN 6
						THEN ABS((
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96375'
									) - (
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96365'
									))
					WHEN 9
						THEN ABS((
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96413'
									) - (
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96411'
									))
					WHEN 11
						THEN ABS((
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96422'
									) - (
									SELECT MAX(ca.CHARGE_AMOUNT)
									FROM CHARGE_MASTER cm WITH (NOLOCK)
									INNER JOIN CHARGE_MASTER_CHARGE_AMOUNT ca WITH (NOLOCK) ON ca.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID
									WHERE SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ISNULL(cm.EFFECTIVE_DATE, '1/1/2000') AND ISNULL(cm.EXPIRATION_DATE, GETDATE())
										AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ca.EFFECTIVE_DATE AND ISNULL(ca.EXPIRATION_DATE, GETDATE())
										AND cm.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID 
                                        AND (cm.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID OR cm.PATIENT_CLASS_ID = -1) 
										AND CPT_CODE = '96420'
									))
					ELSE 0
					END AS RATE,
				CASE @m_GroupBy
					WHEN 1
						THEN pc.[DESCRIPTION]
					WHEN 2
						THEN cmd.[NAME]
					ELSE NULL
					END GROUP_DESC,
				CASE @m_GroupBy
					WHEN 1
						THEN c.PATIENT_CLASS_ID
					WHEN 2
						THEN ci.CHARGE_MASTER_DEPT_ID
					ELSE NULL
					END GROUP_ID
			FROM CHART c
			INNER JOIN CHART_INFUSION ci WITH (NOLOCK) ON ci.CHART_ID = c.CHART_ID
			INNER JOIN INFUSION_TYPE it WITH (NOLOCK) ON it.INFUSION_TYPE = ci.INFUSION_TYPE
			INNER JOIN PATIENT_CLASS pc WITH (NOLOCK) ON pc.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
			INNER JOIN CHARGE_MASTER_DEPARTMENT cmd WITH (NOLOCK) ON cmd.CHARGE_MASTER_DEPT_ID = ci.CHARGE_MASTER_DEPT_ID
			LEFT JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
			WHERE it.INJECTION = 0
				AND @m_RateBasis = 1
				AND c.CHART_STATUS_ID = 5				
				AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN @First_Day AND @Last_Day
				AND ci.CHARGE_MASTER_DEPT_ID IN ( SELECT CHARGE_MASTER_DEPT_ID FROM #Department )				

			) x
	WHERE   sa.service_agreement_id = x.service_agreement_id
	    and sa.company_id = c.company_id
		and x.FACILITY_ID IN ( SELECT Facility_ID FROM #Facility )
	GROUP BY 
	
	    c.company_id, 
 	    c.NAME,	
		x.DOSMonth,
		x.GROUP_ID,
		x.GROUP_DESC
		--,		c.NAME
	ORDER BY c.NAME,
		c.company_id,
		DOSMonth,
		GROUP_DESC



end




end












GO
GRANT EXECUTE ON  [dbo].[rpt_InfusionNoStopTimeTrend] TO [dbx_ExecuteReportProcs]
GO
