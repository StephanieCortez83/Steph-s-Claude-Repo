SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[rpt_CoderQATrending] @StartDate DATETIME,
	@EndDate DATETIME,
	@TimeZone VARCHAR(MAX),
	@MonthView BIT = 0,
	@Facility VARCHAR(MAX),
	@UserGroup VARCHAR(MAX),
	@ReportUser INT,
	@TimeInterval INT = NULL, 
	@CUID INT,
	@PostBill VARCHAR(MAX),
	@RateAlert int,
	@AlertPerc varchar(15), 
	@Region int   -- Added ACS-13142 DAH 09/24/18  **********
AS

begin 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	set transaction isolation level read uncommitted

	---- TEST PARMS --
	--declare
	--	@ReportUser    int          = 80
	--	,@Region       int          = 0
	--	,@Facility     varchar(max) = '581'
	--	,@UserGroup    varchar(max) = '164,165,166'
	--	,@TimeZone     varchar(max) = 'Central Daylight Time'
	--	,@MonthView    int          = 0
	--	,@StartDate    datetime     = '20180801'
	--	,@EndDate      datetime     = '20180831'
	--	,@TimeInterval int          = 0
	--	,@CUID         int          = -1
	--	,@PostBill     varchar(5)   = '0,1'
	--	,@RateAlert    int          = 1
	--	,@AlertPerc    varchar(15)  = '0.98';
	---- TEST PARMS --

	DECLARE @m_ReportUser INT = @ReportUser;
	DECLARE @m_Facility VARCHAR(MAX) = @Facility;
	DECLARE @m_UserGroup VARCHAR(MAX) = @UserGroup;
	DECLARE @CTOffSet VARCHAR(9) = (
			SELECT CT_OFFSET
			FROM TIME_ZONE
			WHERE [DESCRIPTION] = @TimeZone
			)
	DECLARE @Operator VARCHAR(1) = SUBSTRING(@CTOffSet, 1, 1)
	DECLARE @hms VARCHAR(8) = SUBSTRING(@CTOffSet, 2, LEN(@CTOffSet) - 1)
	DECLARE @HOURs DECIMAL(10, 2) = DATEPART(HOUR, @hms)
	DECLARE @MINUTEs DECIMAL(10, 2) = DATEPART(MINUTE, @hms)
	DECLARE @HrsOffSet DECIMAL(10, 2) = CAST(@Operator + CONVERT(VARCHAR, DATEPART(HOUR, @hms)) AS DECIMAL(10, 2))
	DECLARE @MinOffSet DECIMAL(10, 2) = CAST(@Operator + CONVERT(VARCHAR, DATEPART(MINUTE, @hms)) AS DECIMAL(10, 2))
	DECLARE @m_StartDate DATE = CASE 
			WHEN @MonthView = 0
				THEN @StartDate
			ELSE DATEADD(DAY, - (DAY(@StartDate) - 1), @StartDate)
			END
	DECLARE @m_EndDate DATE = CASE 
			WHEN @MonthView = 0
				THEN @EndDate
			ELSE DATEADD(DAY, - (DAY(DATEADD(MONTH, 1, @StartDate))), DATEADD(MONTH, 1, @StartDate))
			END;
	DECLARE @m_TimeInterval INT = @TimeInterval;
	DECLARE @m_CUID INT = @CUID;
	DECLARE @m_PostBill VARCHAR(MAX) = @PostBill;



	if object_id('TempDB..#coder', 'U') is not null drop table #coder


select distinct t1.USER_PROFILE_ID, t1.last_name, t1.first_name				
into #coder				
from  				
		(
		SELECT USER_PROFILE_ID, last_name, first_name				
		FROM USER_PROFILE				
		WHERE 
		-- is_active = 'Y' and		-- DAH 12/9/20 AAR-1011 inactive coders requested in report
		(USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') )
			OR -1 in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') ) )
		and USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') )
				
		UNION				
				
		SELECT up.USER_PROFILE_ID, up.last_name, up.first_name								
		FROM USER_GROUP_TO_USER_PROFILE ugup,				
		user_profile up				
		where up.user_profile_id = ugup.user_profile_id				
		-- and up.is_active = 'Y'	-- DAH 12/9/20 AAR-1011 inactive coders requested in report				
		and (ugup.USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') )
			OR -1 in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') ) )
		and ugup.USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') )		
		) t1


create nonclustered index idx_USER_PROFILE_ID on #coder (USER_PROFILE_ID);






	if object_id('TempDB..#POST_BILL1', 'U') is not null drop table #POST_BILL1;


select * 								
into #POST_BILL1							
from								
(

SELECT 

	            cpbar.CHART_ID, 
				c2.FACILITY_ID,
				f.NAME as FNAME,
				NULL Coder,
				NULL CUID,
				CASE @m_TimeInterval
					WHEN 0
						THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED ))), 0)), 0)
					WHEN 1
						THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED ))), 0)), - 1)
					WHEN 2
						THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED ))), 0)), 0)
					WHEN 3
						THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED ))), 0)), 0)
					ELSE NULL
					END [DATE],
				1 Charts,
				1 Audits,
				(	SELECT 1
					FROM chart c
					WHERE c.chart_id = cpbar.chart_id
						AND c.patient_disposition_id = 5
						AND sa.evaluate_observation_departments = 1
						AND c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = - 1
					) ObsAudits,


	     CASE WHEN cpbar.PHYSICIAN_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS PA,
				CASE WHEN cpbar.PHYSICIAN_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS PPA,
				CASE WHEN cpbar.DIAGNOSIS_ICD10_ERROR IS NULL THEN 0 ELSE 1 END AS DA,
				CASE WHEN cpbar.FACILITY_SVC_ERROR IS NULL THEN 0 ELSE 1 END AS FA,
				CASE WHEN cpbar.INFUSION_ERROR IS NULL THEN 0 ELSE 1 END AS FIA,
				CASE WHEN cpbar.FACILITY_PROCEDURE_ERROR IS NULL THEN 0 ELSE 1 END AS FPA,
				CASE when cpbar.FACILITY_SVC_ERROR = 1 then 0 
	               when cpbar.FACILITY_SVC_ERROR is null then 0
	               else 1 end as FLOSE,
				CASE when cpbar.FACILITY_PROCEDURE_ERROR = 1 then 0 
	               when cpbar.FACILITY_PROCEDURE_ERROR is null then 0
	               else 1 end as FPROCE,
				CASE when cpbar.INFUSION_ERROR = 1 then 0 
	               when cpbar.INFUSION_ERROR is null then 0
	               else 1 end as FINJE,
				CASE when cpbar.PHYSICIAN_SVC_ERROR = 1 then 0 
	               when cpbar.PHYSICIAN_SVC_ERROR is null then 0
	               else 1 end as PLOSE,
				CASE when cpbar.PHYSICIAN_PROCEDURE_ERROR = 1 then 0 
	               when cpbar.PHYSICIAN_PROCEDURE_ERROR is null then 0
	               else 1 end as PPROCE,
				CASE when cpbar.DIAGNOSIS_ICD10_ERROR = 1 then 0 
	               when cpbar.DIAGNOSIS_ICD10_ERROR is null then 0
	               else 1 end as DE,
				CASE WHEN cpbar.OBSERVATION_INFUSIONS_ERROR IS NULL THEN 0 ELSE 1 END AS OIA,
				CASE WHEN cpbar.OBSERVATION_HOURS_ERROR IS NULL THEN 0 ELSE 1 END AS OHA,
				CASE WHEN cpbar.OBSERVATION_PROCEDURES_ERROR IS NULL THEN 0 ELSE 1 END AS OPA,
				CASE when cpbar.OBSERVATION_INFUSIONS_ERROR = 1 then 0 
	               when cpbar.OBSERVATION_INFUSIONS_ERROR is null then 0
	               else 1 end OIE,
				CASE when cpbar.OBSERVATION_HOURS_ERROR = 1 then 0 
	               when cpbar.OBSERVATION_HOURS_ERROR is null then 0
	               else 1 end as OHE,
				CASE when cpbar.OBSERVATION_PROCEDURES_ERROR = 1 then 0 
	               when cpbar.OBSERVATION_PROCEDURES_ERROR is null then 0
	               else 1 end as OPE,
				CASE WHEN cpbar.DEMOGRAPHIC_ERROR IS NULL THEN 0 ELSE 1 END AS DEMA,
				CASE when cpbar.DEMOGRAPHIC_ERROR = 1 then 0 
               when cpbar.DEMOGRAPHIC_ERROR is null then 0
               else 1 end as DEME                     
           


      FROM [dbo].[CHART_POST_BILL_AUDIT_REVIEW] cpbar ,
          	  service_agreement sa ,
              FACILITY f ,
			  chart c2 


      WHERE 
DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c2.POST_BILL_AUDIT_COMPLETED ))), 0) BETWEEN @m_StartDate AND @m_EndDate	  	  
--		  cast(c2.POST_BILL_AUDIT_COMPLETED as date)BETWEEN @StartDate AND @EndDate

			  and cpbar.chart_id = c2.chart_id
              and sa.service_agreement_id = c2.service_agreement_id
              and f.FACILITY_ID = c2.FACILITY_ID
			  and c2.POST_BILL_AUDIT_COMPLETED is not null
			  and (@m_Facility = '-1' or (c2.facility_id IN (select * from dbo.SplitString(@m_Facility, ','))))
			  and sa.COMPANY_ID <> 140 -- Test/Demo								
			  and sa.DEMO_TEST_SITE_IND = 0

			  -- Added ACS-13142 DAH 09/24/18  **********
			  and sa.service_agreement_id in ( select distinct service_agreement_id from [dbo].[SERVICE_AGREEMENT_MANAGEMENT_TEAM]
                                               where ( user_profile_id = @Region or 0 = @Region)
                                               and management_team_role_id = 1 
                                              ) 

)t1




		update x
	set x.CUID = ln.Completed_By_User_ID
	from
		#POST_BILL1 as x
			join
		(
			select chart_ID, MinLogNoteID = min(LOG_NOTE_ID) 
			from log_note  
			where CATEGORY_ID = 2
			group by chart_ID
		) as t
				on x.chart_ID = t.chart_ID
			join
		log_note as ln 
				on t.MinLogNoteID = ln.log_note_ID;






	WITH CoderQASUMmary
	AS (
		SELECT car.FACILITY_ID,
			car.FNAME,
			car.Coder,
			car.CUID CUID,
			car.[DATE],
			COUNT(*) Charts,
			CAST(SUM(car.Audits) AS DECIMAL) Audits,
			SUM(car.ObsAudits) ObsAudits,
			CAST(SUM(car.fa) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.OIA) + SUM(car.OPA) + SUM(car.OHA) + SUM(car.DEMA) AS DECIMAL) Available,
			SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) + SUM(car.OHE) + SUM(car.OPE) + SUM(car.OIE) + SUM(car.DEME) Earned,
			CAST(SUM(car.fa) + SUM(car.PA) + SUM(car.DA) + SUM(car.FPA) + SUM(car.FIA) + SUM(car.PPA) + SUM(car.OIA) + SUM(car.OPA) + SUM(car.OHA) AS DECIMAL) Available_NODEM,
			SUM(car.FLOSE) + SUM(car.FPROCE) + SUM(car.FINJE) + SUM(car.PLOSE) + SUM(car.PPROCE) + SUM(car.DE) + SUM(car.OHE) + SUM(car.OPE) + SUM(car.OIE) Earned_NODEM,
			CAST(SUM(car.FA) + SUM(car.FPA) + SUM(car.FIA) AS DECIMAL) FAvail,
			CAST(SUM(car.PA) + SUM(car.PPA) AS DECIMAL) PAvail,
			CAST(SUM(car.PA) AS DECIMAL) PA,
			CAST(SUM(car.PPA) AS DECIMAL) PPA,
			CAST(SUM(car.DA) AS DECIMAL) DAvail,
			SUM(car.FLOSE) FLOS,
			SUM(car.FPROCE) FProc,
			SUM(car.FINJE) FInj,
			SUM(car.PLOSE) PLOS,
			SUM(car.PPROCE) PProc,
			SUM(car.DE) Diag,
			CAST(SUM(car.OIA) AS DECIMAL) ObsInjAvail,
			CAST(SUM(car.OHA) AS DECIMAL) ObsHOURsAvail,
			CAST(SUM(car.OPA) AS DECIMAL) ObsProcAvail,
			SUM(car.OIE) ObsInj,
			SUM(car.OHE) ObsHOURs,
			SUM(car.OPE) ObsProc,
			CAST(SUM(car.DEMA) AS DECIMAL) DemoAvail,
			SUM(car.DEME) Demo,
      SUM(car.FA) FA,
      SUM(car.FPA) FPA,
      SUM(car.FIA) FIA
		FROM (
			SELECT car2.FACILITY_ID,
				car2.FNAME,
				car2.CNAME Coder,
				car2.CUID CUID,
				CASE @m_TimeInterval
					WHEN 0
						THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					WHEN 1
						THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), - 1)
					WHEN 2
						THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					WHEN 3
						THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0)), 0)
					ELSE NULL
					END [DATE],
				1 Charts,
				car2.AUDITED Audits,
				(
					SELECT 1
					FROM chart c
					WHERE c.chart_id = car2.chart_id
						AND c.patient_disposition_id = 5
						AND sa.evaluate_observation_departments = 1
						AND c.OBSERVATION_COMPLETED_BY_USER_PROFILE_ID = - 1
					) ObsAudits,
				car2.PA,
				car2.PPA,
				car2.DA,
				car2.FA,
				car2.FIA,
				car2.FPA,
				car2.FLOSE,
				car2.FPROCE,
				car2.FINJE,
				car2.PLOSE,
				car2.PPROCE,
				car2.DE,
				car2.OIA,
				car2.OHA,
				car2.OPA,
				car2.OIE,
				car2.OHE,
				car2.OPE,
				car2.DEMA,
				car2.DEME
			FROM chart_audit_result car2 ,
				--user_profile up ,
				chart c2 ,
				service_agreement sa 
			WHERE DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, car2.APPROVED_DATE))), 0) BETWEEN @m_StartDate AND @m_EndDate
				AND car2.chart_id = c2.chart_id
				AND sa.service_agreement_id = c2.service_agreement_id

				AND car2.CUID IN (select user_profile_id from #coder)

				AND (@m_Facility = '-1' or (car2.facility_id IN (select * from dbo.SplitString(@m_Facility, ','))))
			    and sa.COMPANY_ID <> 140 -- Test/Demo								
			    and sa.DEMO_TEST_SITE_IND = 0
                AND '0' IN ( SELECT * FROM dbo.SplitString (@m_PostBill, ',') )  

					-- added ACS-13142 DAH 09/24/18  **********
				and sa.service_agreement_id in ( select distinct service_agreement_id from [dbo].[SERVICE_AGREEMENT_MANAGEMENT_TEAM]
                                                where ( user_profile_id = @Region or 0 = @Region)
                                                and management_team_role_id = 1 
                                                ) 

				
				--AND up.USER_PROFILE_ID = car2.CUID
				--AND ( car2.CUID in (@m_CUID) 		
				--	  or -1 in (@m_CUID) ) 		
			
				--AND up.USER_CLASS_CD IN (
				--	1,
				--	2,
				--	4,
				--	5
				--	)
				--AND up.USER_GROUP_ID IN (
				--	SELECT *
				--	FROM dbo.SplitString(@m_UserGroup, ',')
				--	)
			
UNION ALL

				SELECT 	
				pb1.FACILITY_ID,
				pb1.FNAME,
				#coder.last_name + ', ' + #coder.first_name  as Coder,				
				pb1.CUID,
				pb1.[DATE],
				pb1.Charts,
				pb1.Audits,
				pb1.ObsAudits,
                pb1.PA,
				pb1.PPA,
				pb1.DA,
				pb1.FA,
				pb1.FIA,
				pb1.FPA,
				pb1.FLOSE,
				pb1.FPROCE,
				pb1.FINJE,
				pb1.PLOSE,
				pb1.PPROCE,
				pb1.DE,
				pb1.OIA,
				pb1.OHA,
				pb1.OPA,
				pb1.OIE,
				pb1.OHE,
				pb1.OPE,
				pb1.DEMA,
				pb1.DEME


 FROM #POST_BILL1 pb1,
 --user_profile up 	
 #coder
 where
 pb1.CUID = #coder.user_profile_id

 and '1' IN ( SELECT * FROM dbo.SplitString (@m_PostBill, ',') )  -- include Post Bill Audit Data.

--    up.USER_PROFILE_ID = pb1.CUID
--				AND ( pb1.CUID in (@m_CUID) 		
--					  or -1 in (@m_CUID) ) 	
--and up.USER_GROUP_ID IN (
--					SELECT *
--					FROM dbo.SplitString(@m_UserGroup, ',')
--					)
--and up.USER_CLASS_CD IN (1, 2, 4, 5)										  					

			) car

		GROUP BY car.FACILITY_ID,
			car.FNAME,
			car.Coder,
			car.CUID,
			car.[DATE]
		)
	SELECT 
	    DENSE_RANK() OVER (ORDER BY CUID) as t_index,
        'Coder' + cast(DENSE_RANK() OVER (ORDER BY CUID)  as varchar) as HiddenName,
	    cqas.FACILITY_ID,
		FNAME,
		Coder,
		CUID CUID,
		[DATE],
		Charts,
		Audits,
		Audits / Charts AuditRate,
		ObsAudits,
		Available,
		Earned,
		Available_NODEM,
		Earned_NODEM,
		FAvail,
		PAvail,
		PA,
		PPA,
		DAvail,
		FLOS,
		FProc,
		FInj,
		PLOS,
		PProc,
		Diag,
		ObsInjAvail,
		ObsHoursAvail,
		ObsProcAvail,
		ObsInj,
		ObsHours,
		ObsProc,
		DemoAvail,
		Demo,

        CAST( ROUND(FLOS * 1.00 / ISNULL(NULLIF(FA, 0), 1) , 3) AS FLOAT) as FacLosRate,
        CAST( ROUND(Finj * 1.00 / ISNULL(NULLIF(FIA, 0), 1) , 3) AS FLOAT) as FacInjRate,
        CAST( ROUND(FPROC * 1.00 / ISNULL(NULLIF(FPA, 0), 1) , 3) AS FLOAT) as FacProcRate,

		NULLIF((FLOS + Finj + FPROC) / ISNULL(NULLIF(FAvail, 0), 1), 0) FacRate,
		NULLIF(ObsProc / ISNULL(NULLIF(ObsProcAvail, 0), 1), 0) ObsProcRate,
		--NULLIF(ObsInj / ISNULL(NULLIF(ObsInjAvail, 0), 1), 0) ObsInjRate,
		cast(NULLIF(ObsInj * 1.00/ ISNULL(NULLIF(ObsInjAvail, 0), 1), 3) as float) ObsInjRate,
		--NULLIF(ObsHOURs / ISNULL(NULLIF(ObsHOURsAvail, 0), 1), 0) ObsRate,
		cast(NULLIF(ObsHOURs * 1.00/ ISNULL(NULLIF(ObsHOURsAvail, 0), 1), 3) as float) ObsRate,
		NULLIF(PLOS / ISNULL(NULLIF(PA, 0), 1), 0) PhysLosRate,
		NULLIF(PProc / ISNULL(NULLIF(PPA, 0), 1), 0) PhysProcRate,
		NULLIF((PLOS + PProc) / ISNULL(NULLIF(PAvail, 0), 1), 0) PhysRate,
		--NULLIF(Diag / ISNULL(NULLIF(DAvail, 0), 1), 0) DiagRate,
		cast(NULLIF(Diag *1.00 / ISNULL(NULLIF(DAvail, 0), 1), 3) as float) DiagRate,
		NULLIF(Demo / ISNULL(NULLIF(DemoAvail, 0), 1), 0) DemoRate,
		NULLIF(Earned / ISNULL(NULLIF(Available, 0), 1), 0) Rate,
		NULLIF(Earned_NODEM / ISNULL(NULLIF(Available_NODEM, 0), 1), 0) Rate_NODEM,
    FA,
    FPA,
    FIA,
	
	-- Added ACS-13142 DAH 09/24/18  **********
			(select Region		
     from vw_AccountManager_Region
     where id = am.user_profile_id )  as [REGION],
	 --

	 case when @RateAlert = 0 then 0 
			when case when isnull(FA,0) = 0 then 1 else cast(round(FLOS * 1.00 / isnull(nullif(FA, 0), 1) , 3) as float) end < @AlertPerc then 1 --FacLosRate,
			when case when isnull(FIA,0) = 0 then 1 else cast(round(Finj * 1.00 / isnull(nullif(FIA, 0), 1) , 3) as float) end < @AlertPerc then 1 --FacInjRate,
			when case when isnull(FPA,0) = 0 then 1 else cast(round(FPROC * 1.00 / isnull(nullif(FPA, 0), 1) , 3) as float) end < @AlertPerc then 1 --FacProcRate,
			when case when isnull(FAvail,0) = 0 then 1 else nullif((FLOS + Finj + FPROC) / isnull(nullif(FAvail, 0), 1), 0) end < @AlertPerc then 1 --FacRate,
			when case when isnull(ObsProcAvail,0) = 0 then 1 else nullif(ObsProc / isnull(nullif(ObsProcAvail, 0), 1), 0) end < @AlertPerc then 1 --ObsProcRate,
			when case when isnull(ObsInjAvail,0) = 0 then 1 else cast(nullif(ObsInj * 1.00 / isnull(nullif(ObsInjAvail, 0), 1), 3) as float) end < @AlertPerc then 1 --ObsInjRate,
			when case when isnull(ObsHOURsAvail,0) = 0 then 1 else cast(nullif(ObsHOURs * 1.00 / isnull(nullif(ObsHOURsAvail, 0), 1), 3) as float) end < @AlertPerc then 1 --ObsRate,
			when case when isnull(PA,0) = 0 then 1 else nullif(PLOS / isnull(nullif(PA, 0), 1), 0) end < @AlertPerc then 1 --PhysLosRate,
			when case when isnull(PPA,0) = 0 then 1 else nullif(PProc / isnull(nullif(PPA, 0), 1), 0) end < @AlertPerc then 1 --PhysProcRate,
			when case when isnull(PAvail,0) = 0 then 1 else nullif((PLOS + PProc) / isnull(nullif(PAvail, 0), 1), 0) end < @AlertPerc then 1 --PhysRate,
			when case when isnull(DAvail,0) = 0 then 1 else cast(nullif(Diag *1.00 / isnull(nullif(DAvail, 0), 1), 3) as float) end < @AlertPerc then 1 --DiagRate,
			when case when isnull(DemoAvail,0) = 0 then 1 else nullif(Demo / isnull(nullif(DemoAvail, 0), 1), 0) end < @AlertPerc then 1 --DemoRate
			when case when isnull(Available,0) = 0 then 1 else nullif(Earned / isnull(nullif(Available, 0), 1), 0) end < @AlertPerc then 1 --Rate
		else 0 end [RateAlert],
	 --

	 case when @RateAlert = 0 then '' 
			when case when isnull(FA,0) = 0 then 1 else cast(round(FLOS * 1.00 / isnull(nullif(FA, 0), 1) , 3) as float) end < @AlertPerc then 'FacLosRate'
			when case when isnull(FIA,0) = 0 then 1 else cast(round(Finj * 1.00 / isnull(nullif(FIA, 0), 1) , 3) as float) end < @AlertPerc then 'FacInjRate'
			when case when isnull(FPA,0) = 0 then 1 else cast(round(FPROC * 1.00 / isnull(nullif(FPA, 0), 1) , 3) as float) end < @AlertPerc then 'FacProcRate'
			when case when isnull(FAvail,0) = 0 then 1 else nullif((FLOS + Finj + FPROC) / isnull(nullif(FAvail, 0), 1), 0) end < @AlertPerc then 'FacRate'
			when case when isnull(ObsProcAvail,0) = 0 then 1 else nullif(ObsProc / isnull(nullif(ObsProcAvail, 0), 1), 0) end < @AlertPerc then 'ObsProcRate'
			when case when isnull(ObsInjAvail,0) = 0 then 1 else cast(nullif(ObsInj * 1.00 / isnull(nullif(ObsInjAvail, 0), 1), 3) as float) end < @AlertPerc then 'ObsInjRate'
			when case when isnull(ObsHOURsAvail,0) = 0 then 1 else cast(nullif(ObsHOURs * 1.00 / isnull(nullif(ObsHOURsAvail, 0), 1), 3) as float) end < @AlertPerc then 'ObsRate'
			when case when isnull(PA,0) = 0 then 1 else nullif(PLOS / isnull(nullif(PA, 0), 1), 0) end < @AlertPerc then 'PhysLosRate'
			when case when isnull(PPA,0) = 0 then 1 else nullif(PProc / isnull(nullif(PPA, 0), 1), 0) end < @AlertPerc then 'PhysProcRate'
			when case when isnull(PAvail,0) = 0 then 1 else nullif((PLOS + PProc) / isnull(nullif(PAvail, 0), 1), 0) end < @AlertPerc then 'PhysRate'
			when case when isnull(DAvail,0) = 0 then 1 else cast(nullif(Diag *1.00 / isnull(nullif(DAvail, 0), 1), 3) as float) end < @AlertPerc then 'DiagRate'
			when case when isnull(DemoAvail,0) = 0 then 1 else nullif(Demo / isnull(nullif(DemoAvail, 0), 1), 0) end < @AlertPerc then 'DemoRate'
			when case when isnull(Available,0) = 0 then 1 else nullif(Earned / isnull(nullif(Available, 0), 1), 0) end < @AlertPerc then 'Rate'
		else '' end [RateAlertField]

	into #results
	FROM 
		CoderQASummary cqas
		inner join SERVICE_AGREEMENT sa on cqas.FACILITY_ID = sa.FACILITY_ID
		left join SERVICE_AGREEMENT_MANAGEMENT_TEAM samt1 on sa.SERVICE_AGREEMENT_ID = samt1.SERVICE_AGREEMENT_ID and samt1.MANAGEMENT_TEAM_ROLE_ID = 1
		left join USER_PROFILE am on samt1.USER_PROFILE_ID = am.USER_PROFILE_ID and am.IS_ACTIVE = 'Y'
	WHERE EXISTS ( -- Added ACS-13142 DAH 10/15/18
				SELECT *
				FROM FACILITY_USER_AUTHORIZATION  FUA WITH (NOLOCK),								
				USER_PROFILE UP	WITH (NOLOCK), 							
				service_agreement sa WITH (NOLOCK)								
				WHERE 								
				FUA.FACILITY_ID = cqas.FACILITY_ID								
				AND fua.user_profile_id = up.user_profile_id								
				AND UP.IS_ACTIVE = 'Y'								
				and getdate () between fua.EFFECTIVE_DATE and fua.EXPIRATION_DATE								
				AND FUA.USER_PROFILE_ID = @ReportUser	
			      )
	
	
	----------------------------------------------------------------------------------------------------
	
	select 
		r.*
		,case when @RateAlert = 0 then 0 
			when cast( ROUND(sum(FLOS)over(partition by r.FACILITY_ID, r.CUID) * 1.00 / ISNULL(NULLIF(sum(FA)over(partition by r.FACILITY_ID, r.CUID), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 --FacLosRateOverall
			when CAST( ROUND(sum(Finj)over(partition by r.FACILITY_ID, r.CUID) * 1.00 / ISNULL(NULLIF(sum(FIA)over(partition by r.FACILITY_ID, r.CUID), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 --FacInjRateOverall
			when CAST( ROUND(sum(FPROC)over(partition by r.FACILITY_ID, r.CUID) * 1.00 / ISNULL(NULLIF(sum(FPA)over(partition by r.FACILITY_ID, r.CUID), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 --FacProcRateOverall
			when NULLIF(sum((FLOS + Finj + FPROC))over(partition by r.FACILITY_ID, r.CUID) / ISNULL(NULLIF(sum(FAvail)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 0) between .01 and @AlertPerc then 1 --FacRateOverall
			when NULLIF(sum(ObsProc)over(partition by r.FACILITY_ID, r.CUID) / ISNULL(NULLIF(sum(ObsProcAvail)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 0) between .01 and @AlertPerc then 1 --ObsProcRateOverall
			when cast(NULLIF(sum(ObsInj)over(partition by r.FACILITY_ID, r.CUID) * 1.00/ ISNULL(NULLIF(sum(ObsInjAvail)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 3) as float) between .01 and @AlertPerc then 1 --ObsInjRateOverall
			when cast(NULLIF(sum(ObsHOURs)over(partition by r.FACILITY_ID, r.CUID) * 1.00/ ISNULL(NULLIF(sum(ObsHOURsAvail)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 3) as float) between .01 and @AlertPerc then 1 --ObsRateOverall
			when NULLIF(sum(PLOS)over(partition by r.FACILITY_ID, r.CUID) / ISNULL(NULLIF(sum(PA)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 0) between .01 and @AlertPerc then 1 --PhysLosRateOverall
			when NULLIF(sum(PProc)over(partition by r.FACILITY_ID, r.CUID) / ISNULL(NULLIF(sum(PPA)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 0) between .01 and @AlertPerc then 1 --PhysProcRateOverall
			when NULLIF(sum((PLOS + PProc))over(partition by r.FACILITY_ID, r.CUID) / ISNULL(NULLIF(sum(PAvail)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 0) between .01 and @AlertPerc then 1 --PhysRateOverall
			when cast(NULLIF(sum(Diag)over(partition by r.FACILITY_ID, r.CUID) *1.00 / ISNULL(NULLIF(sum(DAvail)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 3) as float) between .01 and @AlertPerc then 1 --DiagRateOverall
			when NULLIF(sum(Demo)over(partition by r.FACILITY_ID, r.CUID) / ISNULL(NULLIF(sum(DemoAvail)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 0) between .01 and @AlertPerc then 1 --DemoRateOverall
			when NULLIF(sum(Earned)over(partition by r.FACILITY_ID, r.CUID) / ISNULL(NULLIF(sum(Available)over(partition by r.FACILITY_ID, r.CUID), 0), 1), 0) between .01 and @AlertPerc then 1 --RateOverall
		else 0 end [OverallCheck]
	from 
		#results r
	order by r.Coder, r.FNAME, r.[DATE]


	drop table #results


end 


GO
GRANT EXECUTE ON  [dbo].[rpt_CoderQATrending] TO [dbx_ExecuteReportProcs]
GO
