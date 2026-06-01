SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- JIRA RAP-123 02/01/24 DAH Added Tenet Grouping to #AuthorizedFacilities, Added Clinic/Clinic ID, PatientClass/Patient Class ID as new fields


CREATE PROCEDURE [dbo].[rpt_CorroHealth_Coder_QA_Trending] 
    @ReportUser INT,
	@StartDate DATETIME,
	@EndDate DATETIME,
	@CUID VARCHAR(MAX),
	@COMPANY_ID VARCHAR(MAX),
	@FACILITY_ID VARCHAR(MAX),	
	@Region VARCHAR(MAX),
	@PatientClass VARCHAR(MAX),
    @UserGroup VARCHAR(MAX),
	@TimeZone VARCHAR(50),
	@MonthView INT,
	@TimeInterval INT,
	@RateAlert    INT ,	
	@AlertPerc    VARCHAR(15),
	@GlobalGroup  int,
	@PBA int,
	@Clinic varchar(max)

AS

BEGIN


    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;


	------ test parameters *****    	

	--declare @ReportUser INT = 80,			--6861,		--10837,		-- 10420,		--11288,
	--    	@StartDate DATETIME = '20230830',		--'11/4/2021',			--'12/27/2021',		--'1/1/2021',		--'1/1/2022',
	--	    @EndDate DATETIME =	  '20240201',			--'11/11/2021',				--'1/1/2022',			--'12/31/2021',		--'2/1/2022',
	--	    @CUID VARCHAR(MAX) = '-1',
	--		@COMPANY_ID int = -1,   
	--	    @FACILITY_ID VARCHAR(MAX) =	'-1',  -- '2122', 		--'-1' All,	-2 All Tenet OP,		
	--		@PatientDisposition int = -99,
	--		@UserGroup VARCHAR(MAX) = -1, --'202,201,203,208,212',			--'202,201',			--'202,201,203,208,212',
	--		@Region VARCHAR(MAX) = '0',             --  '0,2220,6172,7157,6793',		--'6793',			--'7157',		--'6172',		--'0,2220,2219,5843,6172,52,7157,6793',		
	--        @PatientClass VARCHAR(MAX) = '-999',      -- -999 All
	--		@TimeZone VARCHAR(50) =	'Central Daylight Time',			--'India Standard Time',
	--		@MonthView INT = 0,			-- 0 Use dates, 1 Complete Month
	--	    @TimeInterval INT = 1,		-- 0 Day, 1 Week, 2 Month, 3 Year
	--		@RateAlert    Int = 0,		-- 0 No, 1 Yes
	--		@AlertPerc    varchar(15)  = '0.85',
	--		@GlobalGroup  int = -1,    -- -1 ALL 
	--        @Clinic varchar(max) = '123, AHH'; --  'PBG';  -- '-1' ALL -- 123, BCPCCFLU, AHH
	--declare @PBA int = -1 -- -1 All, 1 Audited, 2 Not Audited w/PBA, 3 Audited w/PBA



		DECLARE @m_ReportUser INT
	--	DECLARE @m_StartDate DATETIME
	--	DECLARE @m_EndDate DATETIME    
		DECLARE @m_FACILITY_ID VARCHAR(MAX)
		Set @m_ReportUser = @ReportUser
	--	Set @m_StartDate = @StartDate
	--	Set @m_EndDate = @EndDate
		Set @m_FACILITY_ID = @FACILITY_ID
		DECLARE @m_CUID VARCHAR(MAX) = @CUID;
	--    DECLARE @m_PatientDisposition VARCHAR(MAX) = @PatientDisposition;
		DECLARE @m_Region VARCHAR(MAX) = @Region;
		DECLARE @m_UserGroup VARCHAR(MAX) = @UserGroup;
		DECLARE @m_GlobalGroup int = @GlobalGroup;
		DECLARE @m_COMPANY_ID VARCHAR(MAX) = @COMPANY_ID;
		DECLARE @m_PatientClass VARCHAR(MAX) = @PatientClass;
		DECLARE @m_Clinic varchar(max) = @Clinic;




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






	if object_id('TempDB..#AuthorizedFacilities', 'U') is not null drop table #AuthorizedFacilities;
	if object_id('TempDB..#ChartSubset', 'U') is not null drop table #ChartSubset;
	if object_id('TempDB..#CodedCharts1', 'U') is not null drop table #CodedCharts1;
	if object_id('TempDB..#CodedCharts', 'U') is not null drop table #CodedCharts;
	if object_id('TempDB..#Scorecard_1', 'U') is not null drop table #Scorecard_1;
	if object_id('TempDB..#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION', 'U') is not null drop table #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
	if object_id('TempDB..#combined', 'U') is not null drop table #combined;
	if object_id('TempDB..#Scorecard_2', 'U') is not null drop table #Scorecard_2;

	-- added to support tuning by dsexton 2/2022 (reduces logical reads and duration by 70-95% depending on parameters used)
	if object_id('TempDB..#ChartTable', 'U') is not null drop table #ChartTable;
	if object_id('TempDB..#ChartDemoHX', 'U') is not null drop table #ChartDemoHX;
	if object_id('TempDB..#DemoAuditChartIDs', 'U') is not null drop table #DemoAuditChartIDs;
	if object_id('TempDB..#TempChartQAS_PAA', 'U') is not null drop table #TempChartQAS_PAA;
	if object_id('TempDB..#TempChartQAS_FLAA', 'U') is not null drop table #TempChartQAS_FLAA;
	if object_id('TempDB..#TempChartQAS_PLAA', 'U') is not null drop table #TempChartQAS_PLAA;
	if object_id('TempDB..#TempChartQAS_DAA', 'U') is not null drop table #TempChartQAS_DAA;
	if object_id('TempDB..#TempChartQAS_AAA', 'U') is not null drop table #TempChartQAS_AAA;

	if object_id('TempDB..#chart_list', 'U') is not null drop table #chart_list;
	if object_id('TempDB..#ChartsCompleted', 'U') is not null drop table #ChartsCompleted;

	-- ***********************************************************************
	-- AuthorizedFacilities

	SELECT *
	INTO #AuthorizedFacilities
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
		 and  ( SA.COMPANY_ID in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ','))
				OR	-1 in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ',')) )

		and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
				OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )

		and
				(
				0 in (SELECT * FROM SPLITSTRING(@m_Region, ',')) 
				or (sa.SERVICE_AGREEMENT_ID in
						(
						select distinct
							   samt.SERVICE_AGREEMENT_ID
						from
							SERVICE_AGREEMENT_MANAGEMENT_TEAM samt
							,USER_PROFILE up
						where
							samt.USER_PROFILE_ID = up.USER_PROFILE_ID and samt.MANAGEMENT_TEAM_ROLE_ID = 1
							and up.USER_PROFILE_ID in (SELECT * FROM SPLITSTRING(@m_Region, ',')) 
						)
				   )
				)
    
		union  -- AAR-1629 10/05/21
	
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
		and sa.DEMO_TEST_SITE_IND = 1
		and sa.facility_id  in (1780, 1781)
		and fua.USER_PROFILE_ID = @m_ReportUser
		and  ( SA.COMPANY_ID in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ','))
				OR	-1 in (SELECT * FROM SPLITSTRING(@m_COMPANY_ID, ',')) )	  
		and  ( fua.FACILITY_ID in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ','))
				OR	-1 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )
		and
				(
				0 in (SELECT * FROM SPLITSTRING(@m_Region, ',')) 
				or (sa.SERVICE_AGREEMENT_ID in
						(
						select distinct
							   samt.SERVICE_AGREEMENT_ID
						from
							SERVICE_AGREEMENT_MANAGEMENT_TEAM samt
							,USER_PROFILE up
						where
							samt.USER_PROFILE_ID = up.USER_PROFILE_ID and samt.MANAGEMENT_TEAM_ROLE_ID = 1
							and up.USER_PROFILE_ID in (SELECT * FROM SPLITSTRING(@m_Region, ',')) 
						)
				   )
				)

-- RAP-123 02/01/24 Added Tenet Grouping
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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP %'	 
		and (-2 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )

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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 1%'	 
		and (-3 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )

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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 2%'	 
		and (-4 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )

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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 3%'	 
		and (-5 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )

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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 4%'	 
		and (-6 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )

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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 5%'	 
		and (-7 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )

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
		and SA.COMPANY_ID = 19 -- Tenet Healthcare Corporation	
		and sa.description like 'Tenet OP 6%'	 
		and (-8 in (SELECT * FROM SPLITSTRING(@m_FACILITY_ID, ',')) )

			) fa;









	-- AAR-2119 Add Global Grouping

	IF @m_GlobalGroup <> -1
	BEGIN

	delete from #AuthorizedFacilities
	where facility_id not in (
	select facility_id from SSRS_SUBSCRIPTION_GLOBAL_GROUP where group_id = @m_GlobalGroup
	) 

	END;



	-- *********************************************************************
	-- Coders/Usergroup


	if object_id('TempDB..#coder', 'U') is not null drop table #coder


	select distinct t1.USER_PROFILE_ID 
	into #coder				
	from  				
			(
			SELECT USER_PROFILE_ID 
			FROM USER_PROFILE				
			WHERE  USER_PROFILE_ID <> 2
			and ( CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR IS_ACTIVE = 'Y' )
			and (USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') )
				OR -1 in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') ) )
			and (USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') )
				OR -1 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) )
			
			UNION				
				
			SELECT up.USER_PROFILE_ID 
			FROM USER_GROUP_TO_USER_PROFILE ugup,				
			user_profile up				
			where up.user_profile_id = ugup.user_profile_id
			and UP.USER_PROFILE_ID <> 2
			and ( up.CHANGED_DATE_TIME > convert(date, dateadd(month, -3, getdate())) OR IS_ACTIVE = 'Y' )			
			and (ugup.USER_PROFILE_ID in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') )
				OR -1 in ( SELECT items FROM dbo.SplitString(@m_CUID, ',') ) )
			and (ugup.USER_GROUP_ID in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') )		
				OR -1 in ( SELECT items FROM dbo.SplitString(@m_UserGroup, ',') ) )
			) t1


	create nonclustered index idx_USER_PROFILE_ID on #coder (USER_PROFILE_ID);


	-- **************************************************************
	-- Patient Class

	if object_id('TempDB..#PatientClass1', 'U') is not null drop table #PatientClass1;

	select distinct
	pc.PATIENT_CLASS_ID
	into #PatientClass1
	from dbo.PATIENT_CLASS pc
	inner join dbo.SERVICE_AGREEMENT sa on pc.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
	where 
	  sa.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
	and ( @StartDate between pc.EFFECTIVE_DATE and pc.EXPIRATION_DATE
		 or @EndDate between pc.EFFECTIVE_DATE and isnull(pc.EXPIRATION_DATE, '12/31/2099') )

	and (-999 in ( SELECT items FROM dbo.SplitString(@m_PatientClass, ',') )
		 OR 
		 pc.description in ( 
							select pc1.description 
							from PATIENT_CLASS pc1
							where pc1.PATIENT_CLASS_ID in ( SELECT items FROM dbo.SplitString(@m_PatientClass, ',') )
							)
		 )

	-- *****************************************************************

	-- Coded Charts   

	-- Expensive, but verified this is the most efficient way to obtain this record set.  dsexton, 2/2022
	SELECT	
	c.chart_id, c.facility_id, c.service_agreement_id, c.facility_chart_id, 
	c.APPROVED_DATE, c.completed_by_user_profile_id, 
	c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID,
	c.CHART_STATUS_ID,
	c.APPROVAL_REASON_CODE, START_QA_DATE,
	c.CLINIC_ID,
	c.PATIENT_CLASS_ID

	INTO	[#CodedCharts1]
	FROM	chart as c  with (NOLOCK)
	left join dbo.CHART_POST_BILL_AUDIT_REVIEW cpbar on c.CHART_ID = cpbar.CHART_ID
	WHERE	
	c.CHART_STATUS_ID in (4, 5) -- Approved, Sent
	AND c.COMPLETED_BY_USER_PROFILE_ID  in ( select USER_PROFILE_ID from #coder) 
	-- AND	convert(varchar, c.APPROVED_DATE, 112) BETWEEN convert(varchar, @m_StartDate, 112) AND convert(varchar, @m_EndDate, 112)
	AND DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.APPROVED_DATE ))), 0) BETWEEN @m_StartDate AND @m_EndDate	  	  

	AND	c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities)
	AND c.PATIENT_CLASS_ID in ( select PATIENT_CLASS_ID from #PatientClass1)
	AND (c.CLINIC_ID in (SELECT * FROM SPLITSTRING(@m_Clinic, ',')) or '-1' in (SELECT * FROM SPLITSTRING(@m_Clinic, ',')) )
	
	
	and (@PBA = -1	--All
			or (@PBA = 1 and c.START_QA_DATE is not null)	-- Audited
			or (@PBA = 2 and c.START_QA_DATE is null and cpbar.CHART_ID is not null)	--Not Audited w/PBA
			or (@PBA = 3 and c.START_QA_DATE is not null and cpbar.CHART_ID is not null)	--Audited w/PBA
		)
	; 



	SELECT	
	c.COMPLETED_BY_USER_PROFILE_ID as USER_PROFILE_ID,
	c.facility_id, 
	c.CLINIC_ID,
	c.service_agreement_id,
	c.PATIENT_DISPOSITION_ID,
	c.PATIENT_CLASS_ID,
	CASE @m_TimeInterval
						WHEN 0
							THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, approved_date))), 0)), 0)
						WHEN 1
							THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, approved_date))), 0)), - 1)
						WHEN 2
							THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, approved_date))), 0)), 0)
						WHEN 3
							THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, approved_date))), 0)), 0)
						ELSE NULL
						END [DATE],
	count(*) as Number_of_Charts_Coded
	INTO	[#CodedCharts]
	FROM	#CodedCharts1 c
	group by c.COMPLETED_BY_USER_PROFILE_ID,
	c.facility_id, c.CLINIC_ID,
	c.service_agreement_id,
	c.PATIENT_DISPOSITION_ID,
	c.PATIENT_CLASS_ID,
	approved_date 
	;



	-- *****************************************************************************************************************************************





	SELECT	c.chart_id, c.facility_id, c.service_agreement_id, c.facility_chart_id, 
	CASE @m_TimeInterval
						WHEN 0
							THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, approved_date))), 0)), 0)
						WHEN 1
							THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, approved_date))), 0)), - 1)
						WHEN 2
							THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, approved_date))), 0)), 0)
						WHEN 3
							THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, approved_date))), 0)), 0)
						ELSE NULL
						END [APPROVED_DATE],

	c.completed_by_user_profile_id, 
	c.approved_by_user_profile_id, c.PATIENT_DISPOSITION_ID

	,c.APPROVAL_REASON_CODE
	,c.CLINIC_ID
	,c.PATIENT_CLASS_ID
	INTO	[#ChartSubset]
	FROM	#CodedCharts1 as c 

	WHERE	c.CHART_STATUS_ID in (4, 5)
	AND     c.APPROVAL_REASON_CODE = 3
	AND     c.APPROVED_BY_USER_PROFILE_ID <> 2			
	AND 	c.START_QA_DATE is not null; 








	-- *****************************************************************************************************************************************
	-- Correction to Split Dx Types

	-- Expensive, but verified this is the most efficient way to obtain this record set.  dsexton, 2/2022
		select 
			 dx.CHART_ID		
			,dx.FACILITY_CHART_ID
			,dx.ACTION
			,dx.CODER_DIAGNOSIS_TYPE_DESCRIPTION
			,case when dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION = 'Primary Dx' and dx.AUDITOR_ICD10_CODE <> '' then
					case when icd.DIAGNOSIS_TYPE_ID = 1 and icd.IS_PRIMARY = 1 then 'Chief Complaint'
							when icd.DIAGNOSIS_TYPE_ID = 1 and icd.IS_PRIMARY = 0 then 'Additional Complaint'
							when icd.DIAGNOSIS_TYPE_ID = 2 and icd.IS_PRIMARY = 1 then 'Primary Dx'
							when icd.DIAGNOSIS_TYPE_ID = 2 and icd.IS_PRIMARY = 0 then 'Secondary Dx'
							when icd.DIAGNOSIS_TYPE_ID = 3 and icd.IS_PRIMARY = 1 then 'Chief Complaint and Primary Dx'
							when icd.DIAGNOSIS_TYPE_ID = 5 and icd.IS_PRIMARY = 0 then 'Chief Complaint and Secondary Dx'
						else '' end
					else dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION end AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
			,dx.IS_CHIEF_COMPLAINT_CHANGE
			,dx.IS_PRIMARY_DIAGNOSIS_CHANGE
			,dx.IS_CODER_CORRECT
			,dx.CODER_ICD10_CODE
			,dx.AUDITOR_ICD10_CODE
			,dx.EXCLUDE_FROM_QA_REPORT
		into #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION
		from
			#ChartSubset c
			inner join CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
			left join CHART_DIAGNOSIS_CODE_ICD10 icd on dx.CHART_ID = icd.CHART_ID and dx.AUDITOR_ICD10_CODE = icd.ICD10_CODE
		where
			dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION not like '%and%'

	
		----------------------------------------------------------------------------------------------------------------------------------

		select 
			dx.CHART_ID
			,dx.FACILITY_CHART_ID
			,dx.[ACTION]
			,dx.CODER_DIAGNOSIS_TYPE_DESCRIPTION
			,dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
			,substring(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION,0,charindex(' and ',dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)) [FIRST_DT_DESC]
			,substring(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION,charindex(' and ',dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)+5,len(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)) [SECOND_DT_DESC]
			,dx.IS_CHIEF_COMPLAINT_CHANGE
			,dx.IS_PRIMARY_DIAGNOSIS_CHANGE
			,dx.IS_CODER_CORRECT
			,dx.CODER_ICD10_CODE
			,dx.AUDITOR_ICD10_CODE
			,dx.EXCLUDE_FROM_QA_REPORT
			,0 as [Split]
		into #combined
		from
			#ChartSubset c
			inner join dbo.CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx on c.CHART_ID = dx.CHART_ID
		where
			dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION like '%and%'

		create nonclustered index idx_CHART_ID on #combined(CHART_ID);

		----------------------------------------------------------------------------------------------------------------------------------

	/*	-- commented out by ds 2/2022.  There's no reason to do RBAR processing here which is very inefficient.
		declare @chart int

		while exists (select top 1 * from #combined where Split = 0)
		begin
		
			set @chart = (select top 1 CHART_ID from #combined where Split = 0)
	*/

			insert into #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION
			select 
				c.CHART_ID
			   ,c.FACILITY_CHART_ID
			   ,c.ACTION
			   ,c.CODER_DIAGNOSIS_TYPE_DESCRIPTION
			   ,c.FIRST_DT_DESC
			   ,case when c.ACTION = 'A' then 0 
						when c.FIRST_DT_DESC like '%Chief%' and c.IS_CHIEF_COMPLAINT_CHANGE = 1 then 1 
					else 0 end IS_CHIEF_COMPLAINT_CHANGE
			   ,case when c.ACTION = 'A' then 0 
						when c.FIRST_DT_DESC like '%Primary%' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 then 1 
					else 0 end IS_PRIMARY_DIAGNOSIS_CHANGE
			   ,case when c.EXCLUDE_FROM_QA_REPORT = 1 then 1 else c.IS_CODER_CORRECT end IS_CODER_CORRECT
			   ,c.CODER_ICD10_CODE
			   ,c.AUDITOR_ICD10_CODE
			   ,c.EXCLUDE_FROM_QA_REPORT
			from
				#combined c

			/*	commented out by ds 2/2022
			where
				c.CHART_ID = @chart
			*/

			union all

			select 
				c.CHART_ID
			   ,c.FACILITY_CHART_ID
			   ,c.ACTION
			   ,c.CODER_DIAGNOSIS_TYPE_DESCRIPTION
			   ,c.SECOND_DT_DESC
			   ,case when c.ACTION = 'A' then 0 
						when c.SECOND_DT_DESC like '%Chief%' and c.IS_CHIEF_COMPLAINT_CHANGE = 1 then 1 
					else 0 end IS_CHIEF_COMPLAINT_CHANGE
			   ,case when c.ACTION = 'A' then 0 
						when c.SECOND_DT_DESC like '%Primary%' and c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 then 1 
					else 0 end IS_PRIMARY_DIAGNOSIS_CHANGE
			   ,case when c.EXCLUDE_FROM_QA_REPORT = 1 then 1 else c.IS_CODER_CORRECT end IS_CODER_CORRECT
			   ,c.CODER_ICD10_CODE
			   ,c.AUDITOR_ICD10_CODE
			   ,c.EXCLUDE_FROM_QA_REPORT
			from
				#combined c

			/*	commented out by ds 2/2022
			where
				c.CHART_ID = @chart
			*/

			/* Already commented out. dsexton, 2/2022
			--update #combined
			--set Split = 1
			--where CHART_ID = @chart
			*/

		/*	commented out by ds 2/2022
			delete from #combined where CHART_ID = @chart
		end
		*/



	-- *****************************************************************************************************************************************



	-- changes to support tuning by dsexton, 2/2022 -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, PROCEDURE_TYPE, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE, CODER_CHARGE_MASTER_DEPT_ID, AUDITOR_CHARGE_MASTER_DEPT_ID
	  into #TempChartQAS_PAA
	from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

	select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
	  into #TempChartQAS_FLAA
	from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

	select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_MODIFIER, AUDITOR_MODIFIER, CODER_CPT_CODE, AUDITOR_CPT_CODE
	  into #TempChartQAS_PLAA
	from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

	select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, IS_CHIEF_COMPLAINT_CHANGE, IS_PRIMARY_DIAGNOSIS_CHANGE
	  into #TempChartQAS_DAA
	from CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID

	select t.Chart_ID, IS_CODER_CORRECT, EXCLUDE_FROM_QA_REPORT, ACTION, CODER_ANESTHESIA_CODE, AUDITOR_ANESTHESIA_CODE
	  into #TempChartQAS_AAA
	from CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION as c join #ChartSubset as t on c.chart_ID = t.chart_ID
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- All subqueries below were modified to reference the new temp tables (above) which contain small subsets of data from the base tables.  dsexton, 2/2022
	select

				c.chart_id, c.facility_chart_id, c.facility_id, c.service_agreement_id,
				c.PATIENT_DISPOSITION_ID,
				c.APPROVED_DATE as APPROVED_DATE, 
				c.COMPLETED_BY_USER_PROFILE_ID as USER_PROFILE_ID,
				c.CLINIC_ID,  
				c.PATIENT_CLASS_ID,
	--			-- ds note: this section was already commented out
	----			(select count(*) from CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID)
	----			+ (select count(*) from CHART_QA_SCORECARD_FACILITY_LOS_AUDIT_ACTION flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID)  
	----			+ (select count(*) from CHART_QA_SCORECARD_PHYSICIAN_LOS_AUDIT_ACTION plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) 
	----			+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as TotalCodesCount,


				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND (pr.IS_CODER_CORRECT = 1 OR pr.EXCLUDE_FROM_QA_REPORT = 1))
				+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR flos.EXCLUDE_FROM_QA_REPORT = 1))  
				+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 or PLOS.EXCLUDE_FROM_QA_REPORT = 1)) 
    			+ (select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND (aaa.IS_CODER_CORRECT = 1 or aaa.EXCLUDE_FROM_QA_REPORT = 1))   --AAA - NEW -- ********
				+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR dx.EXCLUDE_FROM_QA_REPORT = 1)) as TotalCorrectCodesCount,

				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
				+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
				+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND plos.EXCLUDE_FROM_QA_REPORT = 0)
				+ (select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.IS_CODER_CORRECT = 0 AND ACTION = 'R'  AND  aaa.EXCLUDE_FROM_QA_REPORT = 0)   --AAA - NEW -- ******** 
				+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'R' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalRevisedCodesCount,

				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND pr.EXCLUDE_FROM_QA_REPORT = 0 ) 
				+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
				+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
				+ (select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.IS_CODER_CORRECT = 0 AND ACTION = 'A'  AND  aaa.EXCLUDE_FROM_QA_REPORT = 0)   --AAA - NEW -- ******** 
				+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'A' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalAddedCodesCount,

				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND pr.EXCLUDE_FROM_QA_REPORT = 0) 
				+ (select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND flos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND flos.EXCLUDE_FROM_QA_REPORT = 0)  
				+ (select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND plos.EXCLUDE_FROM_QA_REPORT = 0) 
				+ (select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.IS_CODER_CORRECT = 0 AND ACTION = 'D'  AND  aaa.EXCLUDE_FROM_QA_REPORT = 0)   --AAA - NEW -- ******** 
				+ (select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND dx.IS_CODER_CORRECT = 0 AND ACTION = 'D' AND dx.EXCLUDE_FROM_QA_REPORT = 0) as TotalDeletedCodesCount,


				(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID AND (dx.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as DxCorrect,
				(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxAttempted,
				(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAdditions,
				(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxRevisions,
				(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxDeletions,
	--			(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxAbstract,		-- Already commented out. dsexton 2/2022
				(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
						AND dx.chart_id not in (select chart_id from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx2 WHERE dx2.CHART_ID = dx.CHART_ID AND dx2.ACTION in ('D','R','A') AND dx2.EXCLUDE_FROM_QA_REPORT <> 1 )	) as DxAbstract,

				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityProcCorrect,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP') as FacilityProcAttempted,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAdditions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcRevisions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcDeletions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcAbstract,

				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as InfusionInjectionCorrect,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI') as InfusionInjectionAttempted,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAdditions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionRevisions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionDeletions,
				--(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionAbstract,		-- Already commented out. dsexton 2/2022
				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
										AND pr.chart_id not in (select chart_id from #TempChartQAS_PAA pr2 
												WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'CI' AND pr2.ACTION in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as InfusionInjectionAbstract,

				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ProfProcCorrect,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP') as ProfProcAttempted, 
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAdditions, 							 
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcRevisions, 							 
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcDeletions, 							 
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcAbstract, 		

				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND (pr.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as ObsHoursCorrect,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB') as ObsHoursAttempted, 
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAdditions, 							 
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursRevisions, 							 
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursDeletions, 							 
				--(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursAbstract,		-- Already commented out. dsexton 2/2022
				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1
						AND pr.chart_id not in (select chart_id from #TempChartQAS_PAA pr2 WHERE pr2.CHART_ID = pr.CHART_ID AND pr2.PROCEDURE_TYPE = 'OB' AND pr2.ACTION in ('D','R','A') AND pr2.EXCLUDE_FROM_QA_REPORT <> 1 )) as ObsHoursAbstract, 	
			
				(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID  AND (flos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1)) as FacilityLOSCorrect,
				(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID) as FacilityLOSAttempted, 
				(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAdditions,
				(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSRevisions,
				(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSDeletions,
				(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSAbstract,		

				(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND (plos.IS_CODER_CORRECT = 1 OR EXCLUDE_FROM_QA_REPORT = 1))  as PhysicianLOSCorrect,
				(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID) as PhysicianLOSAttempted, 	
				(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAdditions,
				(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSRevisions,
				(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSDeletions,
				(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION = 'C' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSAbstract,


				(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_CHIEF_COMPLAINT_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxChiefComplaintChanges,
				(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1 and dx.EXCLUDE_FROM_QA_REPORT <> 1) as DxPrimaryDxChanges,	
				(select count(DISTINCT dx.CHART_ID) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID) as DxChartsSubmitted,
			
				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as InfInjChanges,
				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'CI') as InfInjSubmitted,
				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB' and pr.IS_CODER_CORRECT = 0 and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursChanges,
				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and PROCEDURE_TYPE = 'OB') as ObsHoursSubmitted, 
				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as ProcModifierChanges, 

				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_FLAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSModifierChanges,  			
																																		 
				(select count(DISTINCT pr.CHART_ID) from #TempChartQAS_PLAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID and CODER_MODIFIER <> AUDITOR_MODIFIER and pr.EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSModifierChanges,
			
		--(select count(DISTINCT CHART_ID) from dbo.GetChartDemographicAuditActions(c.CHART_ID)) as DemographicChanges,
		DemographicChanges = cast(null as int),		-- added here to bypass call to function dbo.GetChartDemographicAuditActions. This value gets populated near the bottom now. dsexton, 2/2022
			
				case when sa.EVALUATE_FACILITY_SVC = 1 then 'Y' else 'N' end as FacilityLOSService,
				case when (sa.INFUSION_INJECTION_METHOD_ID = 1 or sa.INFUSION_INJECTION_METHOD_ID = 2) then 'Y' else 'N' end as InfusionInjectionService,
				case when sa.EVALUATE_FACILITY_PROCEDURES = 1 then 'Y' else 'N' end as FacilityProcService,
				case when sa.EVALUATE_PHYSICIAN_SVC = 1 then 'Y' else 'N' end as PhysicianLOSService,
				case when sa.EVALUATE_PHYSICIAN_PROCEDURES = 1 then 'Y' else 'N' end as ProfProcService,
				case when sa.PERFORM_DIAGNOSIS_CODING = 1 then 'Y' else 'N' end as DxService,
 				case when sa.EVALUATE_OBSERVATION_DEPARTMENTS = 1 and c.PATIENT_DISPOSITION_ID = 5 then 'Y' else 'N' end as ObsHoursService,

				(select count(*) from #TempChartQAS_FLAA flos with (NOLOCK)  where c.CHART_ID = flos.CHART_ID AND flos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityLOSActions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'CI' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as InfusionInjectionActions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'FP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as FacilityProcActions,
				(select count(*) from #TempChartQAS_PLAA plos with (NOLOCK)  where c.CHART_ID = plos.CHART_ID  AND plos.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as PhysicianLOSActions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'PP' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ProfProcActions,
				(select count(*) from #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx with (NOLOCK) where c.CHART_ID = dx.CHART_ID and dx.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as DxActions,
				(select count(*) from #TempChartQAS_PAA pr with (NOLOCK) where c.CHART_ID = pr.CHART_ID AND pr.PROCEDURE_TYPE = 'OB' AND pr.ACTION <> '' AND EXCLUDE_FROM_QA_REPORT <> 1) as ObsHoursActions, 							 
	 --AAA - NEW -- ********			
				(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND (aaa.IS_CODER_CORRECT = 1 OR aaa.EXCLUDE_FROM_QA_REPORT = 1))  as AnesthesiaCorrect,
				(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID) as AnesthesiaAttempted, 	
				(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.ACTION = 'A' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaAdditions,
				(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.ACTION = 'R' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaRevisions,
				(select count(*) from #TempChartQAS_AAA aaa with (NOLOCK)  where c.CHART_ID = aaa.CHART_ID  AND aaa.ACTION = 'D' AND EXCLUDE_FROM_QA_REPORT <> 1) as AnesthesiaDeletions,	
				(select count(DISTINCT aaa.CHART_ID) from #TempChartQAS_AAA aaa with (NOLOCK) where c.CHART_ID = aaa.CHART_ID and aaa.ACTION = 'C' AND aaa.EXCLUDE_FROM_QA_REPORT <> 1
						AND aaa.chart_id not in (select chart_id from #TempChartQAS_AAA aaa2 WHERE aaa2.CHART_ID = aaa.CHART_ID AND aaa2.ACTION in ('D','R','A') AND aaa2.EXCLUDE_FROM_QA_REPORT <> 1 )	) as AnesthesiaAbstract


	  into #Scorecard_1
				FROM				
				[#ChartSubset] c with (NOLOCK) 
							LEFT OUTER JOIN SERVICE_AGREEMENT sa with (NOLOCK) on c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID                   
 				WHERE		c.approved_by_user_profile_id > 2
				;		    
			


	------------------------------------------------------------------------------------------------------------------------------------------
	-- Beginning of section that directly incorporates the query from function dbo.GetChartDemographicAuditActions.  dsexton, 2/2022

	Select 
		Chart_ID, 
		Medical_Record_Num,
		Service_Agreement_ID,
		ADMISSION_DATE_TIME,
		SERVICE_AGREEMENT_ARRIVAL_MODE_ID,
		ARRIVAL_DATE_TIME,
		PATIENT_DISPOSITION_MAP_ID,
		PHYSICIAN_ID,
		TIME_TO_ROOM,
		SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, 
		GENDER, 
		RESIDENT_PARTICIPATED_IN_CARE, 
		FINANCIAL_CLASS_CD, 
		PATIENT_DOB, 
		NURSE_PRACTITIONER_ID, 
		Time_of_Service, 
		PATIENT_DISPOSITION_ID,
		FACILITY_ADMIN_CHART_ID, 
		TIME_OF_DIS, 
		CONDITION_OF_ACCIDENT_ID, 
		CLINIC_ID, 
		ATTESTATION_SIGNED_BY_ATTENDING, 
		SCRIBE_ID, 
		LAST_ENCOUNTER_DATE, 
		LAST_MENSTRUAL_PERIOD,
		PATIENT_AGE, 
		TIME_OF_PHYS_EVAL, 
		TIME_OF_TRIAGE, 
		MEDICAL_EXAMINER_NOTIFIED, 
		ORGAN_DONATION, 
		USE_TIME_BASED_CHARGE_CAPTURE, 
		SEEN_IN_ED_WITHIN_48_HOURS_OF_OR,
		PATIENT_DISPOSITION_DESTINATION_ID 
	 INTO #ChartTable
	from CHART with(nolock) 
	where chart_ID in (Select Chart_ID from #ChartSubset)


	select Chart_ID, Medical_Record_Num, Admission_Date_Time, SERVICE_AGREEMENT_ARRIVAL_MODE_ID, Arrival_Date_Time, PATIENT_DISPOSITION_MAP_ID, PHYSICIAN_ID, TIME_TO_ROOM,
		SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, GENDER, RESIDENT_PARTICIPATED_IN_CARE, FINANCIAL_CLASS_CD, PATIENT_DOB, NURSE_PRACTITIONER_ID, Time_of_Service, PATIENT_DISPOSITION_ID,
		FACILITY_ADMIN_CHART_ID, TIME_OF_DIS, CONDITION_OF_ACCIDENT_ID, CLINIC_ID, ATTESTATION_SIGNED_BY_ATTENDING, SCRIBE_ID, LAST_ENCOUNTER_DATE, LAST_MENSTRUAL_PERIOD,
		PATIENT_AGE, TIME_OF_PHYS_EVAL, TIME_OF_TRIAGE, MEDICAL_EXAMINER_NOTIFIED, ORGAN_DONATION, USE_TIME_BASED_CHARGE_CAPTURE, SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, PATIENT_DISPOSITION_DESTINATION_ID 
	 INTO #ChartDemoHX
	from CHART_DEMOGRAPHIC_HISTORY with(nolock)
	where Chart_ID in (Select Chart_ID from #ChartSubset)


	create table #DemoAuditChartIDs (Chart_ID int)

	insert into #DemoAuditChartIDs

			-- Add the SELECT statement with parameter references here
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
				AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM	

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_MEDICAL_RECORD_NUMBER, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_MRN_AS_QA_ELEMENT, 1) = 1
				AND c.MEDICAL_RECORD_NUM <> cdh.MEDICAL_RECORD_NUM	
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0	
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(COLLECT_ADMISSION_DATE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DATE_OF_ADMISSION_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.ADMISSION_DATE_TIME, '12/31/9999'), ISNULL(cdh.ADMISSION_DATE_TIME, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
			WHERE 
				ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_ARRIVAL_MODE saam WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID = saam.SERVICE_AGREEMENT_ARRIVAL_MODE_ID
			WHERE 
				ISNULL(sa.COLLECT_ARRIVAL_MODE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_ARRIVAL_MODE_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_ARRIVAL_MODE_ID, - 1)

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0		
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_ARRIVAL_DATE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DATE_OF_ARRIVAL_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.ARRIVAL_DATE_TIME, '12/31/9999'), ISNULL(cdh.ARRIVAL_DATE_TIME, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON c.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID		
			WHERE 
				ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.PATIENT_DISPOSITION_MAP_ID, - 1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN PATIENT_DISPOSITION_MAP pdm WITH (NOLOCK) ON cdh.PATIENT_DISPOSITION_MAP_ID = pdm.PATIENT_DISPOSITION_MAP_ID
			WHERE 
				ISNULL(sa.INCLUDE_FACILITY_DISPOSITION_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.PATIENT_DISPOSITION_MAP_ID, - 1) <> ISNULL(cdh.PATIENT_DISPOSITION_MAP_ID, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON c.PHYSICIAN_ID = fp.FACILITY_PROF_ID			--here
			WHERE 
				ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON cdh.PHYSICIAN_ID = fp.FACILITY_PROF_ID
			WHERE 
				ISNULL(sa.COLLECT_PHYSICIAN, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_PROVIDER_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.PHYSICIAN_ID, - 1) <> ISNULL(cdh.PHYSICIAN_ID, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_TO_ROOM, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_TIME_TO_ROOM_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_TO_ROOM, '12/31/9999'), ISNULL(cdh.TIME_TO_ROOM, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
			WHERE 
				ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
				AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
				AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
			WHERE 
				ISNULL(sa.COLLECT_TRIAGE_ACUITY, 'N') <> 'N'
				AND sa.INCLUDE_TRIAGE_LEVEL_AS_QA_ELEMENT = 1
				AND ISNULL(c.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1) <> ISNULL(cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_TRIAGE_ACUITY sata WITH (NOLOCK) ON cdh.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID = sata.SERVICE_AGREEMENT_TRIAGE_ACUITY_ID
			WHERE 
				ISNULL(sa.COLLECT_GENDER, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_GENDER_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.GENDER, '') <> ISNULL(cdh.GENDER, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_RESIDENT_PARTICIPATED_IN_CARE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_RESIDENT_PARTICIPATED_IN_CARE_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.RESIDENT_PARTICIPATED_IN_CARE, '') <> ISNULL(cdh.RESIDENT_PARTICIPATED_IN_CARE, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND ffc.FINANCIAL_CLASS_CD = cdh.FINANCIAL_CLASS_CD
			WHERE 
				ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_FINANCIAL_CLASS ffc WITH (NOLOCK) ON ffc.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND ffc.FINANCIAL_CLASS_CD = c.FINANCIAL_CLASS_CD
			WHERE 
				ISNULL(sa.COLLECT_FINANCIAL_CLASS, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_FINANCIAL_CLASS_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.FINANCIAL_CLASS_CD, '') <> ISNULL(cdh.FINANCIAL_CLASS_CD, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_BIRTH, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DOB_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.PATIENT_DOB, '12/31/9999'), ISNULL(cdh.PATIENT_DOB, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON c.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
			WHERE 
				ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_PROFESSIONAL np WITH (NOLOCK) ON cdh.NURSE_PRACTITIONER_ID = np.FACILITY_PROF_ID
			WHERE 
				ISNULL(sa.COLLECT_NURSE_PRACTITIONER, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_NURSE_PRACTITIONER_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.NURSE_PRACTITIONER_ID, - 1) <> ISNULL(cdh.NURSE_PRACTITIONER_ID, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_SERVICE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DOS_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_OF_SERVICE, '12/31/9999'), ISNULL(cdh.TIME_OF_SERVICE, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
			WHERE 
				ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')
      		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = cdh.PATIENT_DISPOSITION_ID
			WHERE 
				ISNULL(sa.COLLECT_PATIENT_DISPOSITION, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DISPOSITION_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.PATIENT_DISPOSITION_ID, '') <> ISNULL(cdh.PATIENT_DISPOSITION_ID, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_FACILITY_ADMIN_CHART_ID, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_FAC_ADMIN_CID_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.FACILITY_ADMIN_CHART_ID, '') <> ISNULL(cdh.FACILITY_ADMIN_CHART_ID, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_DIS, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_TIME_OF_DIS_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_OF_DIS, '12/31/9999'), ISNULL(cdh.TIME_OF_DIS, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND coa.CONDITION_OF_ACCIDENT_ID = c.CONDITION_OF_ACCIDENT_ID
			WHERE 
				ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
				AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_CONDITION_OF_ACCIDENT coa WITH (NOLOCK) ON coa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND coa.CONDITION_OF_ACCIDENT_ID = cdh.CONDITION_OF_ACCIDENT_ID
			WHERE 
				ISNULL(sa.COLLECT_CONDITION_OF_ACCIDENT, 0) <> 0
				AND ISNULL(sa.INCLUDE_COA_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.CONDITION_OF_ACCIDENT_ID, '') <> ISNULL(cdh.CONDITION_OF_ACCIDENT_ID, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND cl.CLINIC_ID = c.CLINIC_ID
			WHERE 
				ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN SERVICE_AGREEMENT_CLINIC cl WITH (NOLOCK) ON cl.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND cl.CLINIC_ID = cdh.CLINIC_ID
			WHERE 
				ISNULL(sa.COLLECT_CLINIC, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_CLINIC_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.CLINIC_ID, '') <> ISNULL(cdh.CLINIC_ID, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_ATTESTATION_SIGNED_BY_ATTENDING, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_ATTESTATION_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.ATTESTATION_SIGNED_BY_ATTENDING, '') <> ISNULL(cdh.ATTESTATION_SIGNED_BY_ATTENDING, '')

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON c.SCRIBE_ID = s.FACILITY_PROF_ID
			WHERE 
				ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
				AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_PROFESSIONAL s WITH (NOLOCK) ON cdh.SCRIBE_ID = s.FACILITY_PROF_ID
			WHERE 
				ISNULL(sa.COLLECT_SCRIBE, 0) <> 0
				AND ISNULL(sa.INCLUDE_SCRIBE_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.SCRIBE_ID, '') <> ISNULL(cdh.SCRIBE_ID, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_UC_LAST_ENCOUNTER_DATE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_LAST_ENCOUNTER_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.LAST_ENCOUNTER_DATE, '12/31/9999'), ISNULL(cdh.LAST_ENCOUNTER_DATE, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
				AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_LAST_MENSTRUAL_PERIOD, 0) <> 0
				AND ISNULL(sa.INCLUDE_LMP_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.LAST_MENSTRUAL_PERIOD, '12/31/9999'), ISNULL(cdh.LAST_MENSTRUAL_PERIOD, '12/31/9999')) <> 0

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_PATIENT_AGE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_AGE_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.PATIENT_AGE, - 1) <> ISNULL(cdh.PATIENT_AGE, - 1)
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_PHYS_EVAL, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DATE_OF_PHYS_EVAL_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_OF_PHYS_EVAL, '12/31/9999'), ISNULL(cdh.TIME_OF_PHYS_EVAL, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0
      		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_DATE_OF_TRIAGE, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_DATE_OF_TRIAGE_AS_QA_ELEMENT, 1) = 1
				AND DATEDIFF(DAY, ISNULL(c.TIME_OF_TRIAGE, '12/31/9999'), ISNULL(cdh.TIME_OF_TRIAGE, '12/31/9999')) <> 0
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')
      		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_MEDICAL_EXAMINER_NOTIFIED, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_MEDICAL_EXAMINER_NOTIFIED_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.MEDICAL_EXAMINER_NOTIFIED, '') <> ISNULL(cdh.MEDICAL_EXAMINER_NOTIFIED, '')
		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')
      		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_ORGAN_DONATION, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_ORGAN_DONATION_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.ORGAN_DONATION, '') <> ISNULL(cdh.ORGAN_DONATION, '')
		
			---- Time Based Physician LOS 
			UNION 

			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE, 0) <> 0
				AND ISNULL(c.USE_TIME_BASED_CHARGE_CAPTURE, '') <> ISNULL(cdh.USE_TIME_BASED_CHARGE_CAPTURE, '')
      		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.ALLOW_PHYSICIAN_TIME_BASED_CHARGE_CAPTURE, 0) <> 0
				AND ISNULL(c.USE_TIME_BASED_CHARGE_CAPTURE, '') <> ISNULL(cdh.USE_TIME_BASED_CHARGE_CAPTURE, '')

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')
      		
			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN #ChartDemoHx cdh  ON c.CHART_ID = cdh.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			WHERE 
				ISNULL(sa.COLLECT_SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_SEEN_IN_ED_AS_QA_ELEMENT, 1) = 1
				AND ISNULL(c.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '') <> ISNULL(cdh.SEEN_IN_ED_WITHIN_48_HOURS_OF_OR, '')

			UNION
		
			SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN CHART_CONSULTING_PHYSICIAN ccp WITH (NOLOCK) ON c.CHART_ID = ccp.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = ccp.FACILITY_PROFESSIONAL_ID
			WHERE 
				ISNULL(sa.COLLECT_CONSULTING_PHYSICIANS, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT, 1) = 1
				AND NOT EXISTS (
								select *
								from CHART_CONSULTING_PHYSICIAN_HISTORY h with (nolock)
								where h.CHART_ID = ccp.CHART_ID							
								and h.FACILITY_PROFESSIONAL_ID = ccp.FACILITY_PROFESSIONAL_ID
		  )

		  UNION
		  SELECT c.Chart_ID
			FROM #ChartTable c 
			INNER JOIN CHART_CONSULTING_PHYSICIAN_HISTORY ccph WITH (NOLOCK) ON c.CHART_ID = ccph.CHART_ID
			INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
			INNER JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = ccph.FACILITY_PROFESSIONAL_ID
			WHERE 
				ISNULL(sa.COLLECT_CONSULTING_PHYSICIANS, 'N') <> 'N'
				AND ISNULL(sa.INCLUDE_CONSULTING_PHYSICIAN_AS_QA_ELEMENT, 1) = 1
				AND NOT EXISTS (
								select *
								from [dbo].[CHART_CONSULTING_PHYSICIAN] with (nolock)
								where CHART_ID = ccph.CHART_ID
				and FACILITY_PROFESSIONAL_ID = ccph.FACILITY_PROFESSIONAL_ID
				)

		-- RACS-2512 JHerrera added PATIENT_DISPOSITION_DESTINATION_ID 
	
		union 

		SELECT 
			--'A' AS 'Action',
			c.CHART_ID--,
			--'Patient Disposition Destination: ' + ISNULL(pdd.[DESCRIPTION], 'Not Set') [Description]
		FROM #ChartTable c WITH (NOLOCK)
		INNER JOIN #ChartDemoHx cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		left join dbo.PATIENT_DISPOSITION_DESTINATION pdd on c.PATIENT_DISPOSITION_DESTINATION_ID = pdd.PATIENT_DISPOSITION_DESTINATION_ID
		WHERE --c.CHART_ID = @ChartID
			 isnull(c.PATIENT_DISPOSITION_DESTINATION_ID,'-1') <> cdh.PATIENT_DISPOSITION_DESTINATION_ID	

		UNION
		
		SELECT 
			--'R' AS 'Action',
			c.CHART_ID--,
			--'Patient Disposition Destination: ' + ISNULL(pdd.[DESCRIPTION], 'Not Set')
		FROM #ChartTable c WITH (NOLOCK)
		INNER JOIN #ChartDemoHx cdh WITH (NOLOCK) ON c.CHART_ID = cdh.CHART_ID
		left join dbo.PATIENT_DISPOSITION_DESTINATION pdd on cdh.PATIENT_DISPOSITION_DESTINATION_ID = pdd.PATIENT_DISPOSITION_DESTINATION_ID
		WHERE --c.CHART_ID = @ChartID
			 isnull(c.PATIENT_DISPOSITION_DESTINATION_ID,'-1') <> cdh.PATIENT_DISPOSITION_DESTINATION_ID


	update #Scorecard_1 set DemographicChanges = 1 where chart_ID in (Select Chart_ID from #DemoAuditChartIDs)

	update #Scorecard_1 set DemographicChanges = 0 where DemographicChanges is null

	-- end of section to bypass call to function  dbo.GetChartDemographicAuditActions.  dsexton, 2/2022
	------------------------------------------------------------------------------------
	-- new logic added for charts completed from Coder Productivity by Facility Report. RACS-2577 JHerrera

	select chart_id	
	into #chart_list
	from
		CHART c     
	where
		c.CHART_STATUS_ID in (3, 4, 5, 8) 	
		and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.COMPLETION_DATE ))), 0) >= @StartDate
		and dateadd(dd, datediff(dd, 0, dateadd(hh, @HrsOffSet, dateadd(mi, @MinOffSet, c.COMPLETION_DATE ))), 0) <= dateadd(second, 86399, @EndDate)

		and c.COMPLETED_BY_USER_PROFILE_ID  in ( select USER_PROFILE_ID from #coder ) 
		and c.facility_id in ( select FACILITY_ID from #AuthorizedFacilities )
		AND c.PATIENT_CLASS_ID in ( select PATIENT_CLASS_ID from #PatientClass1)
		AND (c.CLINIC_ID in (SELECT * FROM SPLITSTRING(@m_Clinic, ',')) or '-1' in (SELECT * FROM SPLITSTRING(@m_Clinic, ',')) )
		

	create nonclustered index idx_CUID on #chart_list (chart_id)




	declare @ExcludeAutomation int = 0

	select
		--dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0) ADate
		CASE @m_TimeInterval
						WHEN 0
							THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)))), 0)), 0)
						WHEN 1
							THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)))), 0)), - 1)
						WHEN 2
							THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)))), 0)), 0)
						WHEN 3
							THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)))), 0)), 0)
						ELSE NULL
						END [ADate]
		,c.SERVICE_AGREEMENT_ID
		,FACILITY_ID
		,c.CLINIC_ID
		,c.PATIENT_CLASS_ID
		,COMPLETED_BY_USER_PROFILE_ID
		,case
			 when @ExcludeAutomation = 1 then
				 sum(   case
							when
							(
								c.TIME_OF_SERVICE < '11/06/2021'
								and Coder_Comment like '%**Automation**%'
							) then 0
							when
							(
								c.TIME_OF_SERVICE >= '11/06/2021'
								and
								(
									FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME is not null
									or PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME is not null
								)
							) then 0
						else 1 end
					)
			 when @ExcludeAutomation = 0 then sum(1)end      as Completed
	into #ChartsCompleted --#chart1
	from
		CHART c
	where
		exists
	(
		select CHART_ID from #chart_list where CHART_ID = c.CHART_ID
	)
	group by
		--dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)
		CASE @m_TimeInterval
						WHEN 0
							THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)))), 0)), 0)
						WHEN 1
							THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)))), 0)), - 1)
						WHEN 2
							THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)))), 0)), 0)
						WHEN 3
							THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, dateadd(day, datediff(day, 0, c.COMPLETION_DATE), 0)))), 0)), 0)
						ELSE NULL
						END
		,c.SERVICE_AGREEMENT_ID
		,FACILITY_ID
		,c.CLINIC_ID
		,c.PATIENT_CLASS_ID
		,COMPLETED_BY_USER_PROFILE_ID;

	-- *****************************************************************************************************************************************
	--calculations



	select 
	t1.USER_PROFILE_ID,
	t1.FACILITY_ID,
	t1.CLINIC_ID,
	t1.PATIENT_CLASS_ID,
	t1.service_agreement_id,
	cast(t1.APPROVED_DATE as date) as [DATE],

	sum(t1.ChartsCompleted) as ChartsCompleted,
	sum(t1.TotalCharts) as TotalCharts,
	sum(t1.TotalAudits) as TotalAudits,

	sum(t1.Diagnosis_N) as Diagnosis_N,
	sum(t1.Diagnosis_D) as Diagnosis_D,

	sum(t1.FacilityProc_N) as FacilityProc_N,
	sum(t1.FacilityProc_D) as FacilityProc_D,

	sum(t1.PhysicianLOS_EM_N) as PhysicianLOS_EM_N,
	sum(t1.PhysicianLOS_EM_D) as PhysicianLOS_EM_D,

	sum(t1.FacilityLOS_EM_N) as FacilityLOS_EM_N,
	sum(t1.FacilityLOS_EM_D) as FacilityLOS_EM_D,

	sum(t1.ProfProc_N) as ProfProc_N,
	sum(t1.ProfProc_D) as ProfProc_D,

	sum(t1.CoderAccuracy_N) as CoderAccuracy_N,
	sum(t1.CoderAccuracy_D) as CoderAccuracy_D, 

	sum(t1.ChiefComplaint_N) as ChiefComplaint_N, 
	sum(t1.ChiefComplaint_D) as ChiefComplaint_D,

	sum(t1.Principal_N) as Principal_N,
	sum(t1.Principal_D) as Principal_D, 

	sum(t1.InfInj_N) as InfInj_N,
	sum(t1.InfInj_D) as InfInj_D,

	sum(t1.ModifierUsage_N) as ModifierUsage_N,
	-- ModifierUsage_D  = TotalAudits,

	sum(t1.Demographic_N) as Demographic_N,
	-- Demographic_D  = TotalAudits, 

	sum(t1.ObsHours_N) as ObsHours_N,
	sum(t1.ObsHours_D) as ObsHours_D,
	 --AAA - NEW -- ********
	sum(t1.Anesthesia_N) as Anesthesia_N,
	sum(t1.Anesthesia_D) as Anesthesia_D


	into #Scorecard_2


	from (

	select 
	s.USER_PROFILE_ID,
	s.facility_id,
	s.CLINIC_ID,
	s.PATIENT_CLASS_ID, 
	s.service_agreement_id,
	s.APPROVED_DATE,

	0 as ChartsCompleted,
	0 as TotalCharts,

	(select count(DISTINCT s2.CHART_ID) from #Scorecard_1 s2 
	where 
		s2.USER_PROFILE_ID = s.user_profile_id
	and s2.facility_id = s.facility_id
	and s2.APPROVED_DATE = s.APPROVED_DATE
	and s2.PATIENT_CLASS_ID = s.PATIENT_CLASS_ID
	and s2.CLINIC_ID = s.CLINIC_ID
	) as TotalAudits,


	Sum(s.DxDeletions)+sum(s.DxRevisions)+sum(s.DxAdditions) as Diagnosis_N,
	Sum(s.DxCorrect)+sum(s.DxRevisions)+sum(s.DxAdditions) as Diagnosis_D,

	Sum(s.FacilityProcDeletions)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+sum(s.InfusionInjectionDeletions)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as FacilityProc_N,            
	Sum(s.FacilityProcCorrect)+sum(s.FacilityProcRevisions)+sum(s.FacilityProcAdditions)+Sum(s.InfusionInjectionCorrect)+sum(s.InfusionInjectionRevisions)+sum(s.InfusionInjectionAdditions) as FacilityProc_D,

	sum(s.PhysicianLOSDeletions)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions)as PhysicianLOS_EM_N,
	sum(s.PhysicianLOSCorrect)+sum(s.PhysicianLOSRevisions)+sum(s.PhysicianLOSAdditions) as PhysicianLOS_EM_D,

	sum(s.FacilityLOSDeletions)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions)as FacilityLOS_EM_N,
	sum(s.FacilityLOSCorrect)+sum(s.FacilityLOSRevisions)+sum(s.FacilityLOSAdditions) as FacilityLOS_EM_D,

	sum(s.ProfProcDeletions)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions)as ProfProc_N,
	sum(s.ProfProcCorrect)+sum(s.ProfProcRevisions)+sum(s.ProfProcAdditions) as ProfProc_D,

	Sum(s.TotalDeletedCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) as CoderAccuracy_N,
	Sum(s.TotalCorrectCodesCount)+sum(s.TotalRevisedCodesCount)+sum(s.TotalAddedCodesCount) as CoderAccuracy_D,

	sum(s.DxChiefComplaintChanges) + sum(s.DxAbstract) as ChiefComplaint_N,
	sum(s.DxChartsSubmitted) as ChiefComplaint_D,

	sum(s.DxPrimaryDxChanges) + sum(s.DxAbstract) as Principal_N,
	sum(s.DxChartsSubmitted) as Principal_D,

	-- sum(s.InfInjChanges)+sum(s.InfusionInjectionAbstract) as InfInj_N,  -- AAR-1674 10/27/21 remove Abstract from calculation.
	sum(s.InfInjChanges) as InfInj_N,
	sum(s.InfInjSubmitted) as InfInj_D,

	sum(s.ProcModifierChanges) + sum(s.FacilityLOSModifierChanges) + sum(s.PhysicianLOSModifierChanges) as ModifierUsage_N,
			
	sum(s.DemographicChanges) as Demographic_N,

	sum(s.ObsHoursChanges) + sum(s.ObsHoursAbstract) as ObsHours_N,
	sum(s.ObsHoursSubmitted) as ObsHours_D,
	 --AAA - NEW -- ********
	Sum(s.AnesthesiaDeletions)+sum(s.AnesthesiaRevisions)+sum(s.AnesthesiaAdditions) as Anesthesia_N,
	Sum(s.AnesthesiaCorrect)+sum(s.AnesthesiaRevisions)+sum(s.AnesthesiaAdditions) as Anesthesia_D

	from #Scorecard_1 s



	group by 
	s.user_profile_id,
	s.facility_id,
	s.CLINIC_ID,
	s.PATIENT_CLASS_ID,
	s.service_agreement_id,
	s.APPROVED_DATE

	union all 
	-- Coded charts with No Approved




	select 
	USER_PROFILE_ID,
	facility_id,
	CLINIC_ID,
	PATIENT_CLASS_ID,
	service_agreement_id,

	[DATE],
	null as ChartsCompleted,
	Number_of_Charts_Coded as TotalCharts,
	NULL as TotalAudits,
	NULL as Diagnosis_N,
	NULL as Diagnosis_D,
	NULL as FacilityProc_N,
	NULL as FacilityProc_D,
	NULL as PhysicianLOS_EM_N,
	NULL as PhysicianLOS_EM_D,
	NULL as FacilityLOS_EM_N,
	NULL as FacilityLOS_EM_D,
	NULL as ProfProc_N,
	NULL as ProfProc_D,
	NULL as CoderAccuracy_N,
	NULL as CoderAccuracy_D,
	NULL as ChiefComplaint_N,
	NULL as ChiefComplaint_D,
	NULL as Principal_N,
	NULL as Principal_D,
	NULL as InfInj_N,
	NULL as InfInj_D,
	NULL as ModifierUsage_N,
	NULL as Demographic_N,
	NULL as ObsHours_N,
	NULL as ObsHours_D,
	NULL as Anesthesia_N,  --AAA - NEW -- ********
	NULL as Anesthesia_D

	from #CodedCharts


	union all 

	select 
	COMPLETED_BY_USER_PROFILE_ID,
	facility_id,
	CLINIC_ID,
	PATIENT_CLASS_ID,
	service_agreement_id,
	ADate,
	Completed,
	null as TotalCharts,
	NULL as TotalAudits,
	NULL as Diagnosis_N,
	NULL as Diagnosis_D,
	NULL as FacilityProc_N,
	NULL as FacilityProc_D,
	NULL as PhysicianLOS_EM_N,
	NULL as PhysicianLOS_EM_D,
	NULL as FacilityLOS_EM_N,
	NULL as FacilityLOS_EM_D,
	NULL as ProfProc_N,
	NULL as ProfProc_D,
	NULL as CoderAccuracy_N,
	NULL as CoderAccuracy_D,
	NULL as ChiefComplaint_N,
	NULL as ChiefComplaint_D,
	NULL as Principal_N,
	NULL as Principal_D,
	NULL as InfInj_N,
	NULL as InfInj_D,
	NULL as ModifierUsage_N,
	NULL as Demographic_N,
	NULL as ObsHours_N,
	NULL as ObsHours_D,
	NULL as Anesthesia_N,  --AAA - NEW -- ********
	NULL as Anesthesia_D

	from #ChartsCompleted


	 ) t1



	group by 
	t1.USER_PROFILE_ID,
	t1.FACILITY_ID,
	t1.CLINIC_ID,
	t1.PATIENT_CLASS_ID,
	t1.service_agreement_id,
	t1.APPROVED_DATE

	


	-- ******************************************************************
	-- Output 

	select 
	1 as All_Data,

		(select Region		
		 from vw_AccountManager_Region
		 where id = samt.user_profile_id )  as [REGION],

	s.User_Profile_ID, 
	up.LAST_NAME + ', ' + up.FIRST_NAME as CoderName,
	'Coder ' + cast(DENSE_RANK() OVER (ORDER BY s.User_Profile_ID)  as varchar) as HiddenName,
	s.Facility_ID, 
	f.name as Facility,
	s.CLINIC_ID,
	(Select description from SERVICE_AGREEMENT_CLINIC where service_agreement_id = s.service_agreement_id and  CLINIC_ID = s.CLINIC_ID) as Clinic, 
	s.PATIENT_CLASS_ID,
	(select description from PATIENT_CLASS where service_agreement_id = s.service_agreement_id and  PATIENT_CLASS_ID = s.PATIENT_CLASS_ID) as PatientClass,
	s.Service_Agreement_ID, 

	s.[DATE],
	s.ChartsCompleted,
	s.TotalCharts,
	s.TotalAudits,
	s.Diagnosis_N,
	s.Diagnosis_D,
	s.FacilityProc_N,
	s.FacilityProc_D,
	s.PhysicianLOS_EM_N,
	s.PhysicianLOS_EM_D,
	s.FacilityLOS_EM_N,
	s.FacilityLOS_EM_D,
	s.ProfProc_N,
	s.ProfProc_D,
	s.CoderAccuracy_N,
	s.CoderAccuracy_D,
	s.ChiefComplaint_N,
	s.ChiefComplaint_D,
	s.Principal_N,
	s.Principal_D,
	s.InfInj_N,
	s.InfInj_D,
	s.ModifierUsage_N,
	s.Demographic_N,
	s.ObsHours_N,
	s.ObsHours_D,
	s.Anesthesia_N, --AAA - NEW -- ********
	s.Anesthesia_D,

	case when @RateAlert = 0 then 0 
		 when 1 - cast( ROUND(sum(s.Diagnosis_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.Diagnosis_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 --Diag
		 when 1 - cast( ROUND(sum(s.FacilityProc_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.FacilityProc_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 --FacilityProc
		 when 1 - cast( ROUND(sum(s.PhysicianLOS_EM_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.PhysicianLOS_EM_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 --PhysicianLOS_EM
		 when 1 - cast( ROUND(sum(s.FacilityLOS_EM_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.FacilityLOS_EM_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 --FacilityLOS_EM
		 when 1 - cast( ROUND(sum(s.ProfProc_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.ProfProc_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 -- ProfProc
		 when 1 - cast( ROUND(sum(s.CoderAccuracy_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.CoderAccuracy_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 -- CoderAccuracy
		 when 1 - cast( ROUND(sum(s.ChiefComplaint_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.ChiefComplaint_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 -- ChiefComplaint
		 when 1 - cast( ROUND(sum(s.Principal_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.Principal_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 -- Principal
		 when 1 - cast( ROUND(sum(s.InfInj_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.InfInj_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 -- InfInj
		 when 1 - cast( ROUND(sum(s.ObsHours_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.ObsHours_D)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 -- ObsHours

		 when 1 - cast( ROUND(sum(s.ModifierUsage_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.TotalAudits)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 -- ModifierUsage
		 when 1 - cast( ROUND(sum(s.Demographic_N)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]) * 1.00 / ISNULL(NULLIF(sum(s.TotalAudits)over(partition by s.FACILITY_ID, s.User_Profile_ID, s.[DATE]), 0), 1) , 3) AS FLOAT) between .01 and @AlertPerc then 1 -- Demographic

		 else 0 end [OverallCheck]
	from 
	#Scorecard_2 s
	LEFT OUTER JOIN USER_PROFILE up on s.user_profile_id = up.USER_PROFILE_ID   
	inner join facility f on s.facility_id = f.facility_id
	left join SERVICE_AGREEMENT_MANAGEMENT_TEAM samt on s.SERVICE_AGREEMENT_ID = samt.SERVICE_AGREEMENT_ID and samt.MANAGEMENT_TEAM_ROLE_ID = 1
 
	where 

	( samt.user_profile_id in (SELECT * FROM SPLITSTRING(@m_Region, ','))
				OR ( 0 in (SELECT * FROM SPLITSTRING(@m_Region, ','))) )
 


END               







GO
GRANT EXECUTE ON  [dbo].[rpt_CorroHealth_Coder_QA_Trending] TO [dbx_ExecuteReportProcs]
GO
