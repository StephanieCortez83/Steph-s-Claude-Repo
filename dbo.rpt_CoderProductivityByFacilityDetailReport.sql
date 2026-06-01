SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[rpt_CoderProductivityByFacilityDetailReport] (@TimeZone			  varchar(25)
																	, @Organization		  int
																	, @Facility			  varchar(MAX)
																	, @StartDate		  datetime
																	, @EndDate			  datetime
																	, @ReportUser		  int
																	, @UserGroup		  varchar(MAX)
																	, @ExcludeAutomation  int
																	, @PatientDisposition varchar(MAX)
																	, @PatientClass		  varchar(MAX)
																	, @Clinic			  varchar(MAX)
																	)

AS
	BEGIN

		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		SET NOCOUNT ON;

-- Test Parameters
		--declare 
		--@TimeZone			  varchar(25)  = 'Central Daylight Time'	
	 -- , @Organization		  int		   = 19	
	 -- , @Facility			  varchar(MAX) = '1781, 1782, 2672' -- -1 All
	 -- , @StartDate		      datetime     = '12/01/2024'
	 -- , @EndDate			  datetime     = '12/05/2024'
	 -- , @ReportUser		      int          =  80
	 -- , @UserGroup		      varchar(MAX) = '-1'
	 -- , @ExcludeAutomation    int          = 0 -- 1 Exclude Auto
	 -- , @PatientDisposition   varchar(MAX) = '-99'
	 -- , @PatientClass		  varchar(MAX) = '10820' -- '-999'
	 -- , @Clinic				  varchar(MAX) = '-1'	-- -1 All 'STM,STJ'



		DECLARE @IncludeAllFacilities		  bit = IIF(@Facility LIKE '%-1%', 1, 0)
			  , @IncludeAllUserGroups		  bit = IIF(@UserGroup LIKE '%-1%', 1, 0)
			  , @IncludeAllCompanies		  bit = IIF(@Organization = -1, 1, 0)
			  , @IncludeAllPatientDisposition bit = IIF(@PatientDisposition LIKE '%-99%', 1, 0)
			  , @IncludeAllPatientClass		  bit = IIF(@PatientClass LIKE '%-999%', 1, 0)
			  , @IncludeAllClinics		      bit = IIF(@Clinic LIKE '%-1%', 1, 0)
			  , @CNT_Facility				  int;


		----------------------------------------------------------------------------------------------------
		-- Parameter Check --return if more than 1 day range, or more than 5 days against all Facilities
		IF (DATEDIFF(DAY, @StartDate, @EndDate) >= 32)
		   OR	(DATEDIFF(DAY, @StartDate, @EndDate) >= 6
				 AND @IncludeAllFacilities = 1)
			BEGIN
				SELECT	'' AS ADate
					  , '' AS Coder
					  , 0  AS UserID
					  , '' AS Facility
					  , 0  AS FacilityID
					  , 0  AS CHART_ID
					  , '' AS FACILITY_CHART_ID
					  , '' AS Patient_Disposition
					  , 0  AS Completed
					  , 0  AS Audited
					  , 0  AS Pended
					  , 0  AS Automation_Ind
					  , 0  AS [Total]
					  , '' AS [Organization]
					  , DATEDIFF(DAY, @StartDate, @EndDate);

				RETURN;
			END;

		--get date/times based on offsets
		DECLARE @CTOffSet varchar(9) = (SELECT	CT_OFFSET
										FROM	TIME_ZONE
										WHERE	DESCRIPTION = @TimeZone);
		DECLARE @Operator varchar(1) = SUBSTRING(@CTOffSet, 1, 1)
			  , @hms	  varchar(8) = SUBSTRING(@CTOffSet, 2, LEN(@CTOffSet) - 1);
		DECLARE @hours	 decimal(10, 2) = DATEPART(HOUR, @hms)
			  , @minutes decimal(10, 2) = DATEPART(MINUTE, @hms);
		DECLARE @HrsOffSet decimal(10, 2) = CAST(@Operator + CONVERT(varchar, DATEPART(HOUR, @hms)) AS decimal(10, 2))
			  , @MinOffSet decimal(10, 2) = CAST(@Operator + CONVERT(varchar, DATEPART(MINUTE, @hms)) AS decimal(10, 2));
		DECLARE @StartDatetimeOffset datetime = DATEADD(hh, -@HrsOffSet, DATEADD(mi, -@MinOffSet, @StartDate))
			  , @EndDatetimeOffset	 datetime = DATEADD(SECOND, -1, DATEADD(DAY, 1, DATEADD(hh, -@HrsOffSet, DATEADD(mi, -@MinOffSet, @EndDate))));

		--convert multiple params to table

		DROP TABLE IF EXISTS #Facilities;
		DROP TABLE IF EXISTS #UserGroups;
		DROP TABLE IF EXISTS #PatientDisposition;
		DROP TABLE IF EXISTS #PatientClass;
		DROP TABLE IF EXISTS #Clinics;
		

		SELECT	CAST(value AS int) FACILITY_ID
		INTO	#Facilities
		FROM	STRING_SPLIT(@Facility, ',');

		SELECT	CAST(value AS int) USER_GROUP_ID
		INTO	#UserGroups
		FROM	STRING_SPLIT(@UserGroup, ',');

		SELECT	CAST(value AS int) PATIENT_DISPOSITION_ID
		INTO	#PatientDisposition
		FROM	STRING_SPLIT(@PatientDisposition, ',');

		SELECT	CAST(value AS int) PATIENT_CLASS_ID
		INTO	#PatientClass
		FROM	STRING_SPLIT(@PatientClass, ',');

		SELECT	CAST(value AS varchar(10)) Clinic_ID
		INTO	#Clinics
		FROM	STRING_SPLIT(@Clinic, ',');



		PRINT 'Section: 00 ' + CONVERT(varchar, GETDATE(), 121);

		----------------------------------------------------------------------------------------------------
		DROP TABLE IF EXISTS #Facility1;
		
		SELECT	DISTINCT
				t1.FACILITY_ID
			  , t1.NAME
		INTO	#Facility1
		FROM	(SELECT DISTINCT
						f.FACILITY_ID
					  , f.NAME
				 FROM	SERVICE_AGREEMENT	sa WITH (NOLOCK)
						INNER JOIN FACILITY f WITH (NOLOCK)
							ON f.FACILITY_ID = sa.FACILITY_ID
				 WHERE	(sa.COMPANY_ID = @Organization
						 OR @IncludeAllCompanies = 1)
						AND (f.FACILITY_ID IN (SELECT FACILITY_ID FROM	 #Facilities)
							 OR @IncludeAllFacilities = 1)
						AND sa.DEMO_TEST_SITE_IND = 0
						AND (@StartDate BETWEEN sa.EFFECTIVE_DATE AND DATEADD(SECOND, 86399, sa.EXPIRATION_DATE)
							 OR @EndDate BETWEEN sa.EFFECTIVE_DATE AND DATEADD(SECOND, 86399, sa.EXPIRATION_DATE))
						AND EXISTS (SELECT	*
									FROM	FACILITY_USER_AUTHORIZATION FUA WITH (NOLOCK)
											INNER JOIN USER_PROFILE		UP WITH (NOLOCK)
												ON FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
									WHERE	FUA.FACILITY_ID = f.FACILITY_ID
											AND UP.IS_ACTIVE = 'Y'
											AND GETDATE() BETWEEN FUA.EFFECTIVE_DATE AND FUA.EXPIRATION_DATE
											AND FUA.USER_PROFILE_ID = @ReportUser)
				 UNION -- AAR-1694 include Tenet Practice Charts
				 SELECT DISTINCT
						f.FACILITY_ID
					  , f.NAME
				 FROM	SERVICE_AGREEMENT	sa WITH (NOLOCK)
						INNER JOIN FACILITY f WITH (NOLOCK)
							ON f.FACILITY_ID = sa.FACILITY_ID
				 WHERE	sa.COMPANY_ID = 19
						AND (sa.COMPANY_ID = @Organization
							 OR @IncludeAllCompanies = 1)
						AND (f.FACILITY_ID IN (SELECT FACILITY_ID FROM	 #Facilities)
							 OR @IncludeAllFacilities = 1)
						AND (@StartDate BETWEEN sa.EFFECTIVE_DATE AND DATEADD(SECOND, 86399, sa.EXPIRATION_DATE)
							 OR @EndDate BETWEEN sa.EFFECTIVE_DATE AND DATEADD(SECOND, 86399, sa.EXPIRATION_DATE))
						AND EXISTS (SELECT	*
									FROM	FACILITY_USER_AUTHORIZATION FUA WITH (NOLOCK)
											INNER JOIN USER_PROFILE		UP WITH (NOLOCK)
												ON FUA.USER_PROFILE_ID = UP.USER_PROFILE_ID
									WHERE	FUA.FACILITY_ID = f.FACILITY_ID
											AND UP.IS_ACTIVE = 'Y'
											AND GETDATE() BETWEEN FUA.EFFECTIVE_DATE AND FUA.EXPIRATION_DATE
											AND FUA.USER_PROFILE_ID = @ReportUser)) AS t1;

		SET @CNT_Facility = @@rowcount;

		----------------------------------------------------------------------------------------------------
		-- Parameter Check --return if more than 5 days and more than 10 facilities found
		IF (DATEDIFF(DAY, @StartDate, @EndDate) >= 6
			AND @CNT_Facility > 10)
			BEGIN
				SELECT	'' AS ADate
					  , '' AS Coder
					  , 0  AS UserID
					  , '' AS Facility
					  , 0  AS FacilityID
					  , 0  AS CHART_ID
					  , '' AS FACILITY_CHART_ID
					  , '' AS Patient_Disposition
					  , 0  AS Completed
					  , 0  AS Audited
					  , 0  AS Pended
					  , 0  AS Automation_Ind
					  , 0  AS [Total]
					  , '' AS [Organization]
					  , DATEDIFF(DAY, @StartDate, @EndDate);

				RETURN;
			END;

		PRINT 'Section: 01.1 ' + CONVERT(varchar, GETDATE(), 121);

		--- 

		DROP TABLE IF EXISTS #PatientClass1;

		SELECT	DISTINCT
				pc.PATIENT_CLASS_ID
		INTO	#PatientClass1
		FROM	dbo.PATIENT_CLASS				 pc
				INNER JOIN dbo.SERVICE_AGREEMENT sa
					ON pc.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
		WHERE	(@IncludeAllFacilities = 1
				 OR sa.FACILITY_ID IN (SELECT FACILITY_ID FROM #Facility1))
				AND sa.COMPANY_ID = @Organization
				AND (@IncludeAllPatientClass = 1
					 OR pc.DESCRIPTION IN (SELECT	pc1.DESCRIPTION
										   FROM		PATIENT_CLASS pc1
										   WHERE	pc1.PATIENT_CLASS_ID IN (@PatientClass)));



		PRINT 'Section: 01.2 ' + CONVERT(varchar, GETDATE(), 121);
		PRINT 'Section: 02 ' + CONVERT(varchar, GETDATE(), 121);

		----------------------------------------------------------------------------------------------------
		
		DROP TABLE IF EXISTS #UserGroup1;
		
		SELECT	t1.USER_PROFILE_ID
			  , t1.USER_GROUP_ID
		INTO	#UserGroup1
		FROM	(SELECT USER_PROFILE_ID
					  , USER_GROUP_ID
				 FROM	USER_PROFILE
				 WHERE
					 --USER_GROUP_ID in (@UserGroup) 
				(USER_GROUP_ID IN (SELECT USER_GROUP_ID	  FROM #UserGroups)
				 OR @IncludeAllUserGroups = 1)
				 -- USER_GROUP_ID in (201,202,203,208,212) -- testing only ************
				 UNION
				 SELECT ugup.USER_PROFILE_ID
					  , ugup.USER_GROUP_ID
				 FROM	USER_GROUP_TO_USER_PROFILE ugup
				 WHERE	(USER_GROUP_ID IN (SELECT USER_GROUP_ID	  FROM #UserGroups)
						 OR @IncludeAllUserGroups = 1)
		-- ugup.USER_GROUP_ID in (201,202,203,208,212) -- testing only ************
		) t1;

		PRINT 'Section: 03 ' + CONVERT(varchar, GETDATE(), 121);

		----------------------------------------------------------------------------------------------------
		-- Pended - Pull

		DROP TABLE IF EXISTS #LogNote1;

		SELECT	LN.LOG_NOTE_ID
		INTO	#LogNote1
		FROM	LOG_NOTE LN WITH (NOLOCK)
		WHERE	LN.CATEGORY_ID = 6 -- Chart pended
				AND LN.CREATION_DATE_TIME BETWEEN @StartDatetimeOffset AND @EndDatetimeOffset
				AND EXISTS (SELECT	1
							FROM	#UserGroup1 x
							WHERE	x.USER_PROFILE_ID = LN.COMPLETED_BY_USER_ID);

		PRINT 'Section: 04.1 ' + CONVERT(varchar, GETDATE(), 121);



		DROP TABLE IF EXISTS #LogNote2;

		SELECT	LN.CHART_ID
			  , DATEADD(DAY, DATEDIFF(DAY, 0, LN.COMPLETION_DATE), 0) ADate
			  , LN.COMPLETION_DATE
			  , coder.LAST_NAME + ', ' + coder.FIRST_NAME			  Coder
			  , LN.COMPLETED_BY_USER_ID
			  , LN.CATEGORY_ID
			  , LN.SUMMARY											  AS SUMMARY
			  , 1													  AS Pended
		INTO	#LogNote2
		FROM	LOG_NOTE				LN WITH (NOLOCK)
				INNER JOIN USER_PROFILE coder WITH (NOLOCK)
					ON coder.USER_PROFILE_ID = LN.COMPLETED_BY_USER_ID
		WHERE	LN.CATEGORY_ID = 6 -- Chart pended
				AND LOG_NOTE_ID IN (SELECT LOG_NOTE_ID FROM	 #LogNote1);

		PRINT 'Section: 04.2 ' + CONVERT(varchar, GETDATE(), 121);

		----------------------------------------------------------------------------------------------------
		IF OBJECT_ID('TempDB..#Detail1', 'U') IS NOT NULL
			DROP TABLE #Detail1;

		CREATE TABLE #Detail1 (ADate				  datetime
							 , Facility				  varchar(50)
							 , FacilityID			  int
							 , [CHART_ID]			  int
							 , [FACILITY_CHART_ID]	  varchar(20)
							 , Coder				  varchar(55)
							 , UserID				  int
							 , PATIENT_DISPOSITION_ID int
							 , Completed			  int
							 , Audited				  int
							 , Pended				  int
							 , Automation			  int
							 , PATIENT_CLASS_ID		  int
							 , Patient_Class		  varchar(50)
							 , SERVICE_AGREEMENT_ID	  int	
							 , Clinic_ID			  varchar(10)
							 , Clinic	              varchar(100)
							 );

		PRINT 'Section: 05 ' + CONVERT(varchar, GETDATE(), 121);
		----------------------------------------------------------------------------------------------------

		-- Pended - Insert
		INSERT INTO #Detail1
					SELECT	ln1.ADate
						  , f.[NAME]				 Facility
						  , f.FACILITY_ID			 FacilityID
						  , c.CHART_ID
						  , c.FACILITY_CHART_ID
						  , ln1.Coder
						  , ln1.COMPLETED_BY_USER_ID UserID
						  , c.PATIENT_DISPOSITION_ID
						  , 0						 AS Completed
						  , 0						 AS Audited
						  , ln1.Pended				 AS Pended
						  , CASE
								WHEN (c.TIME_OF_SERVICE < '11/06/2021'
									  AND	CODER_COMMENT LIKE '%**Automation**%')
									THEN 1
								WHEN (c.TIME_OF_SERVICE >= '11/06/2021'
									  AND	(FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL
											 OR PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL))
									THEN 1
								ELSE 0
							END						 AS Automation
						  , c.PATIENT_CLASS_ID
						  , NULL	-- Patient_Class
						  , c.SERVICE_AGREEMENT_ID
						  , c.Clinic_ID
						  , NULL    -- Clinic
					FROM	#LogNote2			ln1
							INNER JOIN CHART	c WITH (NOLOCK)
								ON ln1.CHART_ID = c.CHART_ID
							INNER JOIN FACILITY f WITH (NOLOCK)
								ON f.FACILITY_ID = c.FACILITY_ID
					WHERE	EXISTS (SELECT	1
									FROM	#Facility1
									WHERE	FACILITY_ID = c.FACILITY_ID)
							AND ln1.COMPLETED_BY_USER_ID <> 2;

		PRINT 'Section: 06 ' + CONVERT(varchar, GETDATE(), 121);

		----------------------------------------------------------------------------------------------------
		DROP TABLE IF EXISTS #chart_list;
		
		-- Completed - Pull 
		SELECT	CHART_ID
		INTO	#chart_list
		FROM	CHART c
		WHERE	c.CHART_STATUS_ID IN (3, 4, 5, 8)
				AND c.COMPLETION_DATE BETWEEN @StartDatetimeOffset AND @EndDatetimeOffset
				AND EXISTS (SELECT	1
							FROM	#UserGroup1
							WHERE	USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID)
				AND EXISTS (SELECT	1
							FROM	#Facility1
							WHERE	FACILITY_ID = c.FACILITY_ID);

		CREATE NONCLUSTERED INDEX idx_CUID
			ON #chart_list (CHART_ID);

		PRINT 'Section: 07 ' + CONVERT(varchar, GETDATE(), 121);

		----------------------------------------------------------------------------------------------------
		---- Completed
		INSERT INTO #Detail1
					SELECT	DATEADD(DAY, DATEDIFF(DAY, 0, c.COMPLETION_DATE), 0) ADate
						  , f.[NAME]											 Facility
						  , c.FACILITY_ID
						  , c.CHART_ID
						  , c.FACILITY_CHART_ID
						  , up.LAST_NAME + ', ' + up.FIRST_NAME					 AS Coder
						  , c.COMPLETED_BY_USER_PROFILE_ID
						  , c.PATIENT_DISPOSITION_ID
						  , CASE
								WHEN @ExcludeAutomation = 1
									THEN (CASE
											  WHEN (c.TIME_OF_SERVICE < '11/06/2021'
													AND CODER_COMMENT LIKE '%**Automation**%')
												  THEN 0
											  WHEN (c.TIME_OF_SERVICE >= '11/06/2021'
													AND (FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL
														 OR PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL))
												  THEN 0
											  ELSE 1
										  END)
								WHEN @ExcludeAutomation = 0
									THEN 1
							END													 AS Completed
						  , 0													 AS Audited
						  , 0													 AS Pended
						  , CASE
								WHEN (c.TIME_OF_SERVICE < '11/06/2021'
									  AND	CODER_COMMENT LIKE '%**Automation**%')
									THEN 1
								WHEN (c.TIME_OF_SERVICE >= '11/06/2021'
									  AND	(FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL
											 OR PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL))
									THEN 1
								ELSE 0
							END													 AS Automation
						  , c.PATIENT_CLASS_ID
						  , NULL	-- Patient_Class
						  , c.SERVICE_AGREEMENT_ID
						  , c.Clinic_ID
						  , NULL    -- Clinic

					--INTO	#chart1
					FROM	CHART				   c
							INNER JOIN FACILITY	   f WITH (NOLOCK)
								ON f.FACILITY_ID = c.FACILITY_ID
							LEFT JOIN USER_PROFILE up
								ON up.USER_PROFILE_ID = c.COMPLETED_BY_USER_PROFILE_ID
					WHERE	EXISTS (SELECT	CHART_ID
									FROM	#chart_list
									WHERE	CHART_ID = c.CHART_ID)
							AND c.COMPLETED_BY_USER_PROFILE_ID <> 2;

		PRINT 'Section: 08 ' + CONVERT(varchar, GETDATE(), 121);
		----------------------------------------------------------------------------------------------------  
		PRINT 'Section: 09 ' + CONVERT(varchar, GETDATE(), 121);
		----------------------------------------------------------------------------------------------------  

		-- Audited
		INSERT INTO #Detail1
					SELECT	DATEADD(DAY, DATEDIFF(DAY, 0, c.APPROVED_DATE), 0)				   ADate
						  , f.[NAME]														   Facility
						  , f.FACILITY_ID													   FacilityID
						  , c.CHART_ID
						  , c.FACILITY_CHART_ID
						  , auditor.LAST_NAME + ', ' + auditor.FIRST_NAME					   Coder
						  , auditor.USER_PROFILE_ID											   UserID
						  , c.PATIENT_DISPOSITION_ID
						  , 0																   AS Completed
						  , IIF(c.APPROVED_BY_USER_PROFILE_ID = auditor.USER_PROFILE_ID, 1, 0) Audited
						  , 0																   AS Pended
						  , CASE
								WHEN (c.TIME_OF_SERVICE < '11/06/2021'
									  AND	CODER_COMMENT LIKE '%**Automation**%')
									THEN 1
								WHEN (c.TIME_OF_SERVICE >= '11/06/2021'
									  AND	(FACILITY_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL
											 OR PHYSICIAN_AUTOMATION_CODING_RECEIVED_DATE_TIME IS NOT NULL))
									THEN 1
								ELSE 0
							END																   AS Automation
						  , c.PATIENT_CLASS_ID
						  , NULL	-- Patient_Class
						  , c.SERVICE_AGREEMENT_ID
						  , c.Clinic_ID
						  , NULL    -- Clinic
					FROM	CHART				   c WITH (NOLOCK)
							JOIN FACILITY		   f WITH (NOLOCK)
								ON f.FACILITY_ID = c.FACILITY_ID
							LEFT JOIN USER_PROFILE auditor WITH (NOLOCK)
								ON auditor.USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID
								   AND auditor.USER_PROFILE_ID <> 2
					WHERE	c.CHART_STATUS_ID IN (3, 4, 5, 8)
							AND c.[START_QA_DATE] IS NOT NULL -- excludes Pushed Charts
							AND c.APPROVED_BY_USER_PROFILE_ID <> 2 -- excludes Pushed Charts
							AND EXISTS (SELECT	1
										FROM	#UserGroup1
										WHERE	USER_PROFILE_ID = c.APPROVED_BY_USER_PROFILE_ID)
							AND EXISTS (SELECT	1
										FROM	#Facility1
										WHERE	FACILITY_ID = c.FACILITY_ID)
							AND c.APPROVED_DATE BETWEEN @StartDatetimeOffset AND @EndDatetimeOffset;

		PRINT 'Section: 10 ' + CONVERT(varchar, GETDATE(), 121);

		----------------------------------------------------------------------------------------------------
		-- Output 
		IF @ExcludeAutomation = 1
			BEGIN
				DELETE #Detail1	 WHERE Automation  = 1;
			END;

		-- IF @PatientDisposition <> -99 
		IF @IncludeAllPatientDisposition = 0
			BEGIN
				DELETE	#Detail1
				WHERE	PATIENT_DISPOSITION_ID NOT IN (@PatientDisposition);
			END;

		--alter table #Detail1
		--add Patient_Class varchar(50)
		UPDATE	#Detail1
		SET		Patient_Class = pc.[DESCRIPTION]
		FROM	#Detail1					 d
				INNER JOIN dbo.PATIENT_CLASS pc
					ON d.PATIENT_CLASS_ID = pc.PATIENT_CLASS_ID;

        UPDATE	#Detail1
		SET		Clinic = sac.[DESCRIPTION]
		FROM	#Detail1					 d
				INNER JOIN dbo.SERVICE_AGREEMENT_CLINIC sac
					ON d.SERVICE_AGREEMENT_ID = sac.SERVICE_AGREEMENT_ID
					and d.CLINIC_ID = sac.CLINIC_ID
					;


		WITH cteDistChart AS (
							 SELECT DISTINCT CHART_ID FROM #Detail1
							 )
		   , cteFlag AS (
						SELECT		d.CHART_ID
								  , ' ' + STRING_AGG(RULE_ID + ' - ' + [MESSAGE], '; ')WITHIN GROUP(ORDER BY CAST(RULE_ID AS int)) AUTO_FLAG
						FROM		cteDistChart							   d
									INNER JOIN AUTOMATION_CODING_AUDIT_MESSAGE ac
										ON ac.CHART_ID = d.CHART_ID
						GROUP BY	d.CHART_ID
						)
		SELECT		d.ADate
				  , d.Coder
				  , d.UserID
				  , d.Facility
				  , d.FacilityID
				  , d.CHART_ID
				  , d.FACILITY_CHART_ID
				  , (SELECT pd.DESCRIPTION
					 FROM	PATIENT_DISPOSITION pd
					 WHERE	pd.PATIENT_DISPOSITION_ID = d.PATIENT_DISPOSITION_ID) AS Patient_Disposition
				  , d.Completed
				  , d.Audited
				  , d.Pended
				  , d.Automation												  AS Automation_Ind
				  , d.Completed + d.Audited + d.Pended							  AS [Total]
				  , o.[DESCRIPTION]												  AS [Organization]
				  , f.AUTO_FLAG					
				  , d.Patient_Class
				  , d.Clinic
		FROM		#Detail1						 d
					INNER JOIN dbo.SERVICE_AGREEMENT sa
						ON d.FacilityID = sa.FACILITY_ID
					INNER JOIN dbo.ORGANIZATION		 o
						ON sa.ORGANIZATION_ID = o.ORGANIZATION_ID
					LEFT JOIN cteFlag				 f
						ON f.CHART_ID = d.CHART_ID
		
		WHERE		
					      d.PATIENT_CLASS_ID IN (SELECT PATIENT_CLASS_ID FROM #PatientClass1)					
					 AND ( d.Clinic_id in ( select Clinic_ID from #Clinics ) or @IncludeAllClinics = 1 )      

		ORDER BY	d.Coder
				  , d.Facility
				  , d.CHART_ID
				  , d.ADate
				  , d.Completed
				  , d.Audited
				  , d.Pended
				  , d.Automation;

		PRINT 'Section: 11 ' + CONVERT(varchar, GETDATE(), 121);
 	END;

GO
