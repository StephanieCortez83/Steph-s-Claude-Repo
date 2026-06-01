SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[rpt_PQRS_MIPS_QUALITY_SUMMARY] @ReportUser	  int
																	  , @DateType	  int
																	  , @StartDate	  datetime
																	  , @EndDate	  datetime
																	  , @COMPANY_ID	  varchar(MAX)
																	  , @FACILITY_ID  varchar(MAX)
																	  , @CUID		  varchar(MAX)
																	  , @TimeZone	  varchar(50)
																	  , @TimeInterval int
AS
	BEGIN

		-- --test parameters
		--declare
		--    @ReportUser INT = 80,
		--    @DateType INT = 0, -- 0 Approved, 1 DOS, 2 Sent, 3 PostAudit
		--	@StartDate DATETIME = '11/04/2024',
		--	@EndDate DATETIME   = '11/04/2024',

		--	@COMPANY_ID  VARCHAR(MAX) = '296', 
		--	@FACILITY_ID VARCHAR(MAX) = '2641',
		--	@UserClass   VARCHAR(MAX) = '-1',  -- -1 All, 1 Corp Employee, 4 Client, 5 Vendor
		--	@CUID        VARCHAR(MAX) = '-1',
		--	@TimeZone VARCHAR(50) =	'Central Daylight Time', --'India Standard Time'
		--	@TimeInterval INT = 1;		-- 0 Day, 1 Week, 2 Month, 3 Year

		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		SET NOCOUNT ON;

		DECLARE @CTOffSet varchar(9) = (SELECT	CT_OFFSET
										FROM	TIME_ZONE
										WHERE	[DESCRIPTION] = @TimeZone);
		DECLARE @Operator varchar(1) = SUBSTRING(@CTOffSet, 1, 1);
		DECLARE @hms varchar(8) = SUBSTRING(@CTOffSet, 2, LEN(@CTOffSet) - 1);
		DECLARE @HOURs decimal(10, 2) = DATEPART(HOUR, @hms);
		DECLARE @MINUTEs decimal(10, 2) = DATEPART(MINUTE, @hms);
		DECLARE @HrsOffSet decimal(10, 2) = CAST(@Operator + CONVERT(varchar, DATEPART(HOUR, @hms)) AS decimal(10, 2));
		DECLARE @MinOffSet decimal(10, 2) = CAST(@Operator + CONVERT(varchar, DATEPART(MINUTE, @hms)) AS decimal(10, 2));
		DECLARE @FromDatetime datetime = DATEADD(HOUR, -@HrsOffSet, DATEADD(MINUTE, -@MinOffSet, @StartDate))
			  , @ThruDatetime datetime = DATEADD(HOUR, -@HrsOffSet, DATEADD(MINUTE, -@MinOffSet, dateadd(second,86399,@EndDate)));
		DECLARE @AllCompanies  bit		= IIF(@COMPANY_ID LIKE '%-1%', 1, 0)
			  , @AllFacilities bit		= IIF(@FACILITY_ID LIKE '%-1%', 1, 0)
			  , @AllUsers	   bit		= IIF(@CUID LIKE '%-1%', 1, 0)
			  , @Today		   datetime = GETDATE();

			  


		DECLARE @Companies table (COMPANY_ID int);

		INSERT	@Companies (COMPANY_ID)
				SELECT value  FROM STRING_SPLIT(@COMPANY_ID,  ',');

		DECLARE @Facilities table (FACILITY_ID int);

		INSERT	@Facilities (FACILITY_ID)
				SELECT value  FROM STRING_SPLIT(@FACILITY_ID,  ',');

		DECLARE @Users table (USER_PROFILE_ID int);

		INSERT	@Users (USER_PROFILE_ID)
				SELECT value  FROM STRING_SPLIT(@CUID, ',');

		DROP TABLE IF EXISTS #AuthorizedFacilities;
		DROP TABLE IF EXISTS #ChartSubset;
		DROP TABLE IF EXISTS #CodedCharts1;
		DROP TABLE IF EXISTS #CodedCharts;
		DROP TABLE IF EXISTS #Scorecard_1;
		DROP TABLE IF EXISTS #Scorecard_2;
		DROP TABLE IF EXISTS #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
		DROP TABLE IF EXISTS #combined;
		DROP TABLE IF EXISTS #TempChartQAS_AAA;
		DROP TABLE IF EXISTS #Unit_Mod_1;
		DROP TABLE IF EXISTS #PQRS;
		DROP TABLE IF EXISTS #Scorecard_3;
		DROP TABLE IF EXISTS #Chart_Prefilter;
		


		--DECLARE @HrsOffSet int = 8
		--,@MinOffSet int = 20
		--,@startdate datetime = '10/1/24'
		--,@enddate datetime = '10/30/24'

		--SELECT TOP 100  @StartDate,@EndDate,TIME_OF_SERVICE, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.TIME_OF_SERVICE))), 0)  

		--FROM dbo.CHART
		--WHERE TIME_OF_SERVICE IS NOT NULL AND 
		--DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, c.TIME_OF_SERVICE))), 0) BETWEEN @StartDate AND @EndDate

		-- *****************************************************************************************************************************************
		-- AuthorizedFacilities
		SELECT	DISTINCT
				fua.FACILITY_ID
		INTO	#AuthorizedFacilities
		FROM	FACILITY_USER_AUTHORIZATION	 fua
				INNER JOIN USER_PROFILE		 up
					ON fua.USER_PROFILE_ID = up.USER_PROFILE_ID
				INNER JOIN SERVICE_AGREEMENT sa
					ON fua.FACILITY_ID = sa.FACILITY_ID
		WHERE	up.IS_ACTIVE = 'Y'
				AND @Today BETWEEN fua.EFFECTIVE_DATE AND fua.EXPIRATION_DATE
				AND @Today BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
				AND sa.DEMO_TEST_SITE_IND = 0
				AND fua.USER_PROFILE_ID = @ReportUser
				AND EXISTS (SELECT	1
							FROM	@Companies x
							WHERE	x.COMPANY_ID = sa.COMPANY_ID)
				AND (@AllFacilities = 1
					 OR EXISTS (SELECT	1
								FROM	@Facilities x
								WHERE	fua.FACILITY_ID = x.FACILITY_ID))
				AND EXISTS (SELECT	1
							FROM	SERVICE_AGREEMENT_PQRS x
							WHERE	(@Today BETWEEN x.EFFECTIVE_DATE AND x.EXPIRATION_DATE
									 OR x.EXPIRATION_DATE IS NULL)
									AND sa.SERVICE_AGREEMENT_ID = x.SERVICE_AGREEMENT_ID);	-- Active PQRS Service Agreements



		-- *************************************************************************
		-- Coders/UserClass
		DROP TABLE IF EXISTS #coder;

		SELECT	DISTINCT
				t1.USER_PROFILE_ID
		INTO	#coder
		FROM	(SELECT USER_PROFILE_ID
				 FROM	USER_PROFILE up
				 WHERE	USER_PROFILE_ID <> 2
						AND (CHANGED_DATE_TIME > CONVERT(date, DATEADD(MONTH, -3, @Today))
							 OR IS_ACTIVE = 'Y')
						AND (@AllUsers =1 OR EXISTS( SELECT 1 FROM @Users x WHERE up.USER_PROFILE_ID=x.USER_PROFILE_ID))) t1;

		CREATE NONCLUSTERED INDEX idx_USER_PROFILE_ID
			ON #coder (USER_PROFILE_ID);



		SELECT	CHART_ID
		INTO	#Chart_Prefilter
		FROM	dbo.CHART c
		WHERE	c.COMPLETED_BY_USER_PROFILE_ID IN (SELECT USER_PROFILE_ID FROM	 #coder) -- = @CUID
				AND c.FACILITY_ID IN (SELECT FACILITY_ID FROM	   #AuthorizedFacilities)
				AND c.CHART_STATUS_ID <> 6; -- 6	Removed



		WITH chartList AS 		
		(
						  SELECT	c.CHART_ID
						  FROM		CHART AS c WITH (NOLOCK)
						  WHERE		EXISTS (SELECT	1
											FROM	#Chart_Prefilter x
											WHERE	c.CHART_ID = x.CHART_ID)
									AND c.APPROVED_DATE BETWEEN @FromDatetime AND @ThruDatetime
									AND @DateType = 0
						  UNION
						  SELECT	c.CHART_ID
						  FROM		CHART AS c WITH (NOLOCK)
						  WHERE		EXISTS (SELECT	1
											FROM	#Chart_Prefilter x
											WHERE	c.CHART_ID = x.CHART_ID)
									AND c.TIME_OF_SERVICE BETWEEN @FromDatetime AND @ThruDatetime
									AND @DateType = 1
						  UNION
						  SELECT	c.CHART_ID
						  FROM		CHART AS c WITH (NOLOCK)
						  WHERE		EXISTS (SELECT	1
											FROM	#Chart_Prefilter x
											WHERE	c.CHART_ID = x.CHART_ID)
									AND c.SENT_DATE BETWEEN @FromDatetime AND @ThruDatetime
									AND @DateType = 2
						  UNION
						  SELECT	c.CHART_ID
						  FROM		CHART AS c WITH (NOLOCK)
						  WHERE		EXISTS (SELECT	1
											FROM	#Chart_Prefilter x
											WHERE	c.CHART_ID = x.CHART_ID)
									AND c.POST_BILL_AUDIT_COMPLETED BETWEEN @FromDatetime AND @ThruDatetime
									AND @DateType = 3
						  )

		SELECT	c.CHART_ID
			  , c.SERVICE_AGREEMENT_ID
			  , c.FACILITY_CHART_ID
			  , c.TIME_OF_SERVICE
			  , c.COMPLETED_BY_USER_PROFILE_ID
			  , c.COMPLETION_DATE
			  , c.PATIENT_DISPOSITION_ID
			  , c.CHART_STATUS_ID
			  , c.APPROVAL_REASON_CODE
			  , c.START_QA_DATE
			  , c.APPROVED_DATE
			  , c.APPROVED_BY_USER_PROFILE_ID
			  , c.POST_BILL_AUDIT_STARTED
			  , c.POST_BILL_AUDIT_COMPLETED
			  , c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID
			  , c.START_SECOND_LEVEL_QA_DATETIME
			  , c.SECOND_LEVEL_QA_APPROVED_DATETIME
			  , c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
		INTO	#CodedCharts1
		FROM	CHART AS c WITH (NOLOCK)
		WHERE	EXISTS (SELECT	1
						FROM	chartList x
						WHERE	c.CHART_ID = x.CHART_ID);

		SELECT		c.COMPLETED_BY_USER_PROFILE_ID
				  , COUNT(*) AS Number_of_Charts_Coded
		INTO		[#CodedCharts]
		FROM		#CodedCharts1 c
		GROUP BY	c.COMPLETED_BY_USER_PROFILE_ID;




		-- *******************************************************************
		SELECT	c.CHART_ID
			  , c.SERVICE_AGREEMENT_ID
			  , c.FACILITY_CHART_ID
			  , c.COMPLETED_BY_USER_PROFILE_ID
			  , c.PATIENT_DISPOSITION_ID
			  , c.APPROVAL_REASON_CODE
			  , c.TIME_OF_SERVICE
			  , c.COMPLETION_DATE
			  , c.START_QA_DATE
			  , c.APPROVED_DATE
			  , c.APPROVED_BY_USER_PROFILE_ID
			  , c.POST_BILL_AUDIT_STARTED
			  , c.POST_BILL_AUDIT_COMPLETED
			  , c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID
			  , c.START_SECOND_LEVEL_QA_DATETIME
			  , c.SECOND_LEVEL_QA_APPROVED_DATETIME
			  , c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
		INTO	[#ChartSubset]
		FROM	#CodedCharts1 AS c;
		-- WHERE	
		-- c.CHART_STATUS_ID in (4, 5)  
		--AND     c.APPROVAL_REASON_CODE = 3
		--AND     c.APPROVED_BY_USER_PROFILE_ID <> 2
		-- AND c.START_QA_DATE is not null or c.POST_BILL_AUDIT_STARTED is not null	

		

		-- *********************************************************************
		-- PQRS

		-- PQRS Step 1
		IF OBJECT_ID('TempDB..#MIPS_1', 'U') IS NOT NULL
			DROP TABLE #MIPS_1;

		SELECT	CODE
			  , CMS_PQRI_MEASURE_ID
			  , PQRS_Code
			  , Effective_Date
			  , Expiration_Date
		INTO	#MIPS_1
		FROM	(SELECT DISTINCT
						CODE_2			   AS CODE
					  , CMS_PQRI_MEASURE_ID
					  , PQRS_Code		   = CAST(NULL AS varchar(20))
					  , Effective_Date	   = CAST(NULL AS datetime)
					  , Expiration_Date	   = CAST(NULL AS datetime)
				 FROM	[CMS_PQRI_MEASURE_CODE]
				 WHERE	code_2 IS NOT NULL
						AND [coding_system] IN ('HCPCS', 'CPT_II', 'DQ411', 'OTHER')
						AND LEN(code_2) > 0
						AND code_2 NOT LIKE '0000%'
				 UNION
				 SELECT DISTINCT
						CODE
					  , CMS_PQRI_MEASURE_ID
					  , PQRS_Code		= CAST(NULL AS varchar(20))
					  , Effective_Date	= CAST(NULL AS datetime)
					  , Expiration_Date = CAST(NULL AS datetime)
				 FROM	[CMS_PQRI_MEASURE_CODE]
				 WHERE	code IS NOT NULL
						AND [coding_system] IN ('HCPCS', 'CPT_II', 'DQ411', 'OTHER')
						AND LEN(code) > 0
						AND code NOT LIKE '0000%') t1;

		UPDATE	#MIPS_1
		SET		PQRS_Code = c.PQRS#
			  , Effective_Date = c.Effective_Date
			  , Expiration_Date = c.Expiration_Date
		FROM	CMS_PQRI_MEASURE c
		WHERE	#MIPS_1.CMS_PQRI_MEASURE_ID = c.CMS_PQRI_MEASURE_ID;

		DELETE FROM	 #MIPS_1 WHERE PQRS_Code  IS NULL;

		-- PQRS Step 2
		IF OBJECT_ID('TempDB..#PQRS_1', 'U') IS NOT NULL
			DROP TABLE #PQRS_1;

		SELECT	DISTINCT
				ppe.CHART_ID AS CHART_ID
			  , c.TIME_OF_SERVICE
			  , c.SERVICE_AGREEMENT_ID
			  , ppe.MODIFIERS
			  , cm.BILLING_CODE
			  , cm.CPT_CODE
			  , cm.DESCRIPTION
		INTO	#PQRS_1
		FROM	PHYSICIAN_PROCEDURE_EVALUATION ppe
			  , CHARGE_MASTER cm
			  , #ChartSubset c
		WHERE	ppe.CHART_ID = c.CHART_ID
				AND cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
				AND cm.CHARGE_MASTER_USAGE_CODE = 9;

		-- PQRS Step 3
		IF OBJECT_ID('TempDB..#PQRS', 'U') IS NOT NULL
			DROP TABLE #PQRS;

		SELECT	t2.CHART_ID
			  , t2.BILLING_CODE
			  , t2.TIME_OF_SERVICE
			  , t2.SERVICE_AGREEMENT_ID
			  , t2.CPT_CODE
			  , t2.DESCRIPTION AS PQRS_Description
			  , t2.PQRS_MEASURES_NUMBER
			  , t2.cms_pqri_measure_id
		INTO	#PQRS
		FROM	(SELECT DISTINCT
						c.CHART_ID	AS CHART_ID
					  , c.BILLING_CODE
					  , c.TIME_OF_SERVICE
					  , c.SERVICE_AGREEMENT_ID
					  , c.CPT_CODE
					  , c.DESCRIPTION
					  , m.PQRS_Code AS PQRS_MEASURES_NUMBER
						--m.[DESCRIPTION] as PQRS_Description,
					  , m.cms_pqri_measure_id
				 FROM	#PQRS_1			   c
						INNER JOIN #MIPS_1 m
							ON c.BILLING_CODE = m.CODE
							   --c.CPT_CODE = m.CODE
							   AND	c.TIME_OF_SERVICE BETWEEN m.[Effective_Date] AND ISNULL(m.Expiration_Date, '12/31/2099')
				 UNION
				 SELECT DISTINCT
						c.CHART_ID	AS CHART_ID
					  , c.BILLING_CODE
					  , c.TIME_OF_SERVICE
					  , c.SERVICE_AGREEMENT_ID
					  , c.CPT_CODE
					  , c.DESCRIPTION
					  , m.PQRS_Code AS PQRS_MEASURES_NUMBER
						--m.[DESCRIPTION] as PQRS_Description,
					  , m.cms_pqri_measure_id
				 FROM	#PQRS_1			   c
						INNER JOIN #MIPS_1 m
							ON
						-- c.BILLING_CODE = m.CODE
						c.CPT_CODE = m.CODE
						AND c.TIME_OF_SERVICE BETWEEN m.[Effective_Date] AND ISNULL(m.Expiration_Date, '12/31/2099')) t2;

		-- Check for Valid/Active Measures by SA
		DELETE	FROM #PQRS
		WHERE	#PQRS.cms_pqri_measure_id NOT IN (SELECT	p.CMS_PQRI_MEASURE_ID
												  FROM		#PQRS p
														  , SERVICE_AGREEMENT_PQRS sap
												  WHERE		p.SERVICE_AGREEMENT_ID = sap.SERVICE_AGREEMENT_ID
															AND p.CMS_PQRI_MEASURE_ID = sap.CMS_PQRI_MEASURE_ID
															AND p.TIME_OF_SERVICE BETWEEN sap.EFFECTIVE_DATE AND ISNULL(sap.EXPIRATION_DATE, '12/30/2099'));

		-- ************************************************************************
		-- Correction to Split Dx Types
		SELECT	dx.CHART_ID
			  , dx.FACILITY_CHART_ID
			  , dx.ACTION
			  , dx.CODER_DIAGNOSIS_TYPE_DESCRIPTION
				--,dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
			  , CASE
					WHEN dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION = 'Primary Dx'
						 AND dx.AUDITOR_ICD10_CODE <> ''
						THEN CASE
								 WHEN icd.DIAGNOSIS_TYPE_ID = 1
									  AND	icd.IS_PRIMARY = 1
									 THEN 'Chief Complaint'
								 WHEN icd.DIAGNOSIS_TYPE_ID = 1
									  AND	icd.IS_PRIMARY = 0
									 THEN 'Additional Complaint'
								 WHEN icd.DIAGNOSIS_TYPE_ID = 2
									  AND	icd.IS_PRIMARY = 1
									 THEN 'Primary Dx'
								 WHEN icd.DIAGNOSIS_TYPE_ID = 2
									  AND	icd.IS_PRIMARY = 0
									 THEN 'Secondary Dx'
								 WHEN icd.DIAGNOSIS_TYPE_ID = 3
									  AND	icd.IS_PRIMARY = 1
									 THEN 'Chief Complaint and Primary Dx'
								 WHEN icd.DIAGNOSIS_TYPE_ID = 5
									  AND	icd.IS_PRIMARY = 0
									 THEN 'Chief Complaint and Secondary Dx'
								 ELSE ''
							 END
					ELSE dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
				END AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
			  , dx.IS_CHIEF_COMPLAINT_CHANGE
			  , dx.IS_PRIMARY_DIAGNOSIS_CHANGE
			  , dx.IS_CODER_CORRECT
			  , dx.CODER_ICD10_CODE
			  , dx.AUDITOR_ICD10_CODE
			  , dx.EXCLUDE_FROM_QA_REPORT
		INTO	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION
		FROM	#ChartSubset										 c
				INNER JOIN CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx
					ON c.CHART_ID = dx.CHART_ID
				LEFT JOIN CHART_DIAGNOSIS_CODE_ICD10				 icd
					ON dx.CHART_ID = icd.CHART_ID
					   AND dx.AUDITOR_ICD10_CODE = icd.ICD10_CODE
		WHERE	dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION NOT LIKE '%and%';

		----------------------------------------------------------------------------------------------------------------------------------
		SELECT	dx.CHART_ID
			  , dx.FACILITY_CHART_ID
			  , dx.[ACTION]
			  , dx.CODER_DIAGNOSIS_TYPE_DESCRIPTION
			  , dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION
			  , SUBSTRING(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION, 0, CHARINDEX(' and ', dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION))												[FIRST_DT_DESC]
			  , SUBSTRING(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION, CHARINDEX(' and ', dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION) + 5, LEN(dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION)) [SECOND_DT_DESC]
			  , dx.IS_CHIEF_COMPLAINT_CHANGE
			  , dx.IS_PRIMARY_DIAGNOSIS_CHANGE
			  , dx.IS_CODER_CORRECT
			  , dx.CODER_ICD10_CODE
			  , dx.AUDITOR_ICD10_CODE
			  , dx.EXCLUDE_FROM_QA_REPORT
			  , 0																																							AS [Split]
		INTO	#combined
		FROM	#ChartSubset											 c
				INNER JOIN dbo.CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx
					ON c.CHART_ID = dx.CHART_ID
		WHERE	dx.AUDITOR_DIAGNOSIS_TYPE_DESCRIPTION LIKE '%and%';

		----------------------------------------------------------------------------------------------------------------------------------
		DECLARE @chart int;

		WHILE EXISTS (SELECT *	  FROM #combined WHERE Split = 0)
			BEGIN
				SET @chart = (SELECT TOP 1	   CHART_ID FROM   #combined WHERE Split = 0);

				INSERT INTO #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION
							SELECT	c.CHART_ID
								  , c.FACILITY_CHART_ID
								  , c.ACTION
								  , c.CODER_DIAGNOSIS_TYPE_DESCRIPTION
								  , c.FIRST_DT_DESC
								  , CASE
										WHEN c.ACTION = 'A'
											THEN 0
										WHEN c.FIRST_DT_DESC LIKE '%Chief%'
											 AND c.IS_CHIEF_COMPLAINT_CHANGE = 1
											THEN 1
										ELSE 0
									END IS_CHIEF_COMPLAINT_CHANGE
								  , CASE
										WHEN c.ACTION = 'A'
											THEN 0
										WHEN c.FIRST_DT_DESC LIKE '%Primary%'
											 AND c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1
											THEN 1
										ELSE 0
									END IS_PRIMARY_DIAGNOSIS_CHANGE
								  , CASE
										WHEN c.EXCLUDE_FROM_QA_REPORT = 1
											THEN 1
										ELSE c.IS_CODER_CORRECT
									END IS_CODER_CORRECT
								  , c.CODER_ICD10_CODE
								  , c.AUDITOR_ICD10_CODE
								  , c.EXCLUDE_FROM_QA_REPORT
							FROM	#combined c
							WHERE	c.CHART_ID = @chart
							UNION ALL
							SELECT	c.CHART_ID
								  , c.FACILITY_CHART_ID
								  , c.ACTION
								  , c.CODER_DIAGNOSIS_TYPE_DESCRIPTION
								  , c.SECOND_DT_DESC
								  , CASE
										WHEN c.ACTION = 'A'
											THEN 0
										WHEN c.SECOND_DT_DESC LIKE '%Chief%'
											 AND c.IS_CHIEF_COMPLAINT_CHANGE = 1
											THEN 1
										ELSE 0
									END IS_CHIEF_COMPLAINT_CHANGE
								  , CASE
										WHEN c.ACTION = 'A'
											THEN 0
										WHEN c.SECOND_DT_DESC LIKE '%Primary%'
											 AND c.IS_PRIMARY_DIAGNOSIS_CHANGE = 1
											THEN 1
										ELSE 0
									END IS_PRIMARY_DIAGNOSIS_CHANGE
								  , CASE
										WHEN c.EXCLUDE_FROM_QA_REPORT = 1
											THEN 1
										ELSE c.IS_CODER_CORRECT
									END IS_CODER_CORRECT
								  , c.CODER_ICD10_CODE
								  , c.AUDITOR_ICD10_CODE
								  , c.EXCLUDE_FROM_QA_REPORT
							FROM	#combined c
							WHERE	c.CHART_ID = @chart;

				UPDATE #combined  SET Split	  = 1 WHERE CHART_ID = @chart;
			END;

		----------------------------------------------------------------------------------------------------------------------------------
		SELECT	t.CHART_ID
			  , IS_CODER_CORRECT
			  , EXCLUDE_FROM_QA_REPORT
			  , ACTION
			  , CODER_ANESTHESIA_CODE
			  , AUDITOR_ANESTHESIA_CODE
		INTO	#TempChartQAS_AAA
		FROM	CHART_QA_SCORECARD_ANESTHESIA_AUDIT_ACTION AS c
				JOIN #ChartSubset						   AS t
					ON c.CHART_ID = t.CHART_ID;

		----------------------------------------------------------------------------------------------------------------------------------
		IF OBJECT_ID('TempDB..#ChartPostBillAudit', 'U') IS NOT NULL
			DROP TABLE #ChartPostBillAudit;

		SELECT	pba.*
		INTO	#ChartPostBillAudit
		FROM	dbo.ChartPostBillAudit	pba
				INNER JOIN #ChartSubset cs
					ON pba.ChartId = cs.CHART_ID;

		----------------------------------------------------------------------------------------------------------------------------------
		IF OBJECT_ID('TempDB..#ChartAuditVersion', 'U') IS NOT NULL
			DROP TABLE #ChartAuditVersion;

		SELECT	cav.*
		INTO	#ChartAuditVersion
		FROM	dbo.ChartAuditVersion cav
		WHERE	cav.ChartAuditId IN (SELECT DISTINCT
											ChartPostBillAuditId
									 FROM	#ChartPostBillAudit);

		CREATE NONCLUSTERED INDEX [tIDX_ChartAuditVersion_ChartAuditId_Include]
			ON #ChartAuditVersion ([ChartAuditId] ASC)
			INCLUDE
		(
		[ChartAuditVersionId]
	  , [VersionNumber]
		)	;

		IF OBJECT_ID('TempDB..#ChartAuditFacilityLosVersionItem', 'U') IS NOT NULL
			DROP TABLE #ChartAuditFacilityLosVersionItem;

		SELECT	caflos.*
		INTO	#ChartAuditFacilityLosVersionItem
		FROM	dbo.ChartAuditFacilityLosVersionItem caflos
		WHERE	caflos.ChartId IN (SELECT DISTINCT	 ChartId FROM #ChartPostBillAudit  )
				AND caflos.ExcludeFromQA <> 1;

		CREATE NONCLUSTERED INDEX [tIDX_ChartAuditFacilityLosVersionItem__ChartAuditActionTypeCode_ExcludeFromQA__include]
			ON #ChartAuditFacilityLosVersionItem
		(
		[ChartAuditActionTypeCode]
	  , [ExcludeFromQA]
		)
			INCLUDE ([ChartAuditVersionId]);

		IF OBJECT_ID('TempDB..#ChartAuditPhysicianLosVersionItem', 'U') IS NOT NULL
			DROP TABLE #ChartAuditPhysicianLosVersionItem;

		SELECT	caplos.*
		INTO	#ChartAuditPhysicianLosVersionItem
		FROM	dbo.ChartAuditPhysicianLosVersionItem caplos
		WHERE	caplos.ChartId IN (SELECT DISTINCT	 ChartId FROM #ChartPostBillAudit  )
				AND caplos.ExcludeFromQA <> 1;

		CREATE NONCLUSTERED INDEX [tIDX_ChartAuditPhysicianLosVersionItem__ChartAuditActionTypeCode_ExcludeFromQA__include]
			ON #ChartAuditPhysicianLosVersionItem
		(
		[ChartAuditActionTypeCode]
	  , [ExcludeFromQA]
		)
			INCLUDE ([ChartAuditVersionId]);

		IF OBJECT_ID('TempDB..#ChartAuditProcedureVersionItem', 'U') IS NOT NULL
			DROP TABLE #ChartAuditProcedureVersionItem;

		SELECT	cap.*
		INTO	#ChartAuditProcedureVersionItem
		FROM	dbo.ChartAuditProcedureVersionItem cap
		WHERE	cap.ChartAuditVersionId IN (SELECT	DISTINCT
													ChartAuditVersionId
											FROM	#ChartAuditVersion)
				--and cap.CptCode in (select distinct sp.cpt_code
				--					from
				--						#ChartSubset cs
				--						inner join dbo.SENT_PROCEDURE sp on cs.CHART_ID = sp.chart_id)
				AND cap.ExcludeFromQA <> 1;

		CREATE NONCLUSTERED INDEX [tIDX_ChartAuditProcedureVersionItem_VersionIdProcType]
			ON #ChartAuditProcedureVersionItem
		(
		[ChartAuditVersionId] ASC
	  , [ProcedureType] ASC
		)	;

		IF OBJECT_ID('TempDB..#ChartAuditDiagnosisVersionItem', 'U') IS NOT NULL
			DROP TABLE #ChartAuditDiagnosisVersionItem;

		SELECT	cad.*
		INTO	#ChartAuditDiagnosisVersionItem
		FROM	dbo.ChartAuditDiagnosisVersionItem cad
		WHERE	cad.ExcludeFromQA <> 1;

		CREATE NONCLUSTERED INDEX [tIDX_ChartAuditDiagnosisVersionItem]
			ON #ChartAuditDiagnosisVersionItem ([ChartAuditVersionId] ASC)
			INCLUDE
		(
		[ChartAuditActionTypeCode]
	  , [ExcludeFromQA]
		)	;

		IF OBJECT_ID('TempDB..#ChartAuditAnesthesiaVersionItem', 'U') IS NOT NULL
			DROP TABLE #ChartAuditAnesthesiaVersionItem;

		SELECT	caa.*
		INTO	#ChartAuditAnesthesiaVersionItem
		FROM	dbo.ChartAuditAnesthesiaVersionItem caa
		WHERE	caa.ChartAuditVersionId IN (SELECT	DISTINCT
													ChartAuditVersionId
											FROM	#ChartAuditVersion)
				AND caa.ExcludeFromQA <> 1;

		CREATE NONCLUSTERED INDEX [tIDX_ChartAuditAnesthesiaVersionItem_VersionIdTypeCode]
			ON #ChartAuditAnesthesiaVersionItem
		(
		[ChartAuditVersionId] ASC
	  , [ChartAuditActionTypeCode] ASC
		)	;

		-- *****************************************************************************************************************************************
		SELECT	c.SERVICE_AGREEMENT_ID
			  , sa.DESCRIPTION																  AS ServiceAgreementDescription
			  , c.CHART_ID
			  , c.FACILITY_CHART_ID
			  , up.USER_PROFILE_ID
			  , up.LAST_NAME + ', ' + up.FIRST_NAME											  AS CoderName
			  , CASE
					WHEN c.START_QA_DATE IS NOT NULL
						 AND c.APPROVED_DATE IS NOT NULL
						 AND c.APPROVED_BY_USER_PROFILE_ID <> 2
						THEN 1
					ELSE 0
				END																			  AS Audit1
			  , CASE
					WHEN c.START_SECOND_LEVEL_QA_DATETIME IS NOT NULL
						 AND c.SECOND_LEVEL_QA_APPROVED_DATETIME IS NOT NULL
						 AND c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2
						THEN 1
					ELSE 0
				END																			  AS Audit2
			  , CASE
					WHEN c.POST_BILL_AUDIT_STARTED IS NOT NULL
						 AND c.POST_BILL_AUDIT_COMPLETED IS NOT NULL
						 AND c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID IS NOT NULL
						THEN 1
					ELSE 0
				END																			  AS AuditPBA
			  , c.APPROVED_DATE
			  , c.SECOND_LEVEL_QA_APPROVED_DATETIME
			  , c.POST_BILL_AUDIT_COMPLETED
			  , c.COMPLETION_DATE
				--Physician Procedure
			  , (SELECT COUNT(*) AS CNT
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
				 WHERE	pro.CHART_ID = c.CHART_ID
						AND pro.PROCEDURE_TYPE = 'PP'
						AND pro.EXCLUDE_FROM_QA_REPORT <> 1
						AND (pro.CODER_QUANTITY > 0
							 OR pro.AUDITOR_QUANTITY > 0))									  AS ProfProc_UnitOpp
			  , (SELECT COUNT(*) AS CNT
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
				 WHERE	pro.CHART_ID = c.CHART_ID
						AND pro.PROCEDURE_TYPE = 'PP'
						AND pro.EXCLUDE_FROM_QA_REPORT <> 1
						AND pro.CODER_QUANTITY <> pro.AUDITOR_QUANTITY)						  AS ProfProc_UnitRev
			  , (SELECT COUNT(*) AS CNT
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
				 WHERE	pro.CHART_ID = c.CHART_ID
						AND pro.PROCEDURE_TYPE = 'PP'
						AND pro.EXCLUDE_FROM_QA_REPORT <> 1
						AND (pro.CODER_MODIFIER <> ''
							 OR pro.AUDITOR_MODIFIER <> ''))								  AS ProfProc_ModOpp
			  , (SELECT COUNT(*) AS CNT
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
				 WHERE	pro.CHART_ID = c.CHART_ID
						AND pro.PROCEDURE_TYPE = 'PP'
						AND pro.EXCLUDE_FROM_QA_REPORT <> 1
						AND pro.CODER_MODIFIER <> pro.AUDITOR_MODIFIER)						  AS ProfProc_ModRev
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP')										  AS ProfProcAttempted
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION <> ''
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS ProfProcActions
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND (pr.IS_CODER_CORRECT = 1
							 OR EXCLUDE_FROM_QA_REPORT = 1))								  AS ProfProcCorrect
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION = 'A'
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS ProfProcAdditions
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION = 'R'
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS ProfProcRevisions
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION = 'D'
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS ProfProcDeletions
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION = 'C'
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS ProfProcAbstract
				--Physician Procedure Post 
			  , (SELECT SUM(x.cnt)
				 FROM	(SELECT COUNT(*) AS cnt
						 FROM	#ChartPostBillAudit pba
							  , #ChartAuditVersion cav
							  , #ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 1
								AND i.ExcludeFromQA <> 1
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID
								AND i.Quantity IS NOT NULL
						 UNION ALL
						 SELECT COUNT(*) AS cnt
						 FROM	#ChartPostBillAudit pba
							  , #ChartAuditVersion cav
							  , #ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 2
								AND i.ExcludeFromQA <> 1
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID
								AND i.Quantity IS NOT NULL
								AND i.PrevChartAuditProcedureVersionItemId IS NULL) x )		  AS ProfProc_UnitOpp_Post
			  , (SELECT SUM(ISNULL(x.RevCNT, 0))
				 FROM	(SELECT CASE
									WHEN ISNULL(i.Quantity, 0) = (SELECT	ISNULL(i2.Quantity, 0)
																  FROM		#ChartAuditProcedureVersionItem i2
																  WHERE		i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId)
										THEN 0
									ELSE 1
								END AS RevCNT
						 FROM	#ChartPostBillAudit pba
							  , #ChartAuditVersion cav
							  , #ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 2
								AND i.ExcludeFromQA <> 1
								AND i.ChartAuditActionTypeCode <> 4
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID) x )							  AS ProfProc_UnitRev_Post
			  , (SELECT SUM(x.cnt)
				 FROM	(SELECT COUNT(*) AS cnt
						 FROM	#ChartPostBillAudit pba
							  , #ChartAuditVersion cav
							  , #ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 1
								AND i.ExcludeFromQA <> 1
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID
								AND i.Modifier IS NOT NULL
						 UNION ALL
						 SELECT COUNT(*) AS cnt
						 FROM	#ChartPostBillAudit pba
							  , #ChartAuditVersion cav
							  , #ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 2
								AND i.ExcludeFromQA <> 1
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID
								AND i.Modifier IS NOT NULL
								AND i.PrevChartAuditProcedureVersionItemId IS NULL) x )		  AS ProfProc_ModOpp_Post
			  , (SELECT SUM(ISNULL(x.RevCNT, 0))
				 FROM	(SELECT CASE
									WHEN ISNULL(i.Modifier, 0) = (SELECT	ISNULL(i2.Modifier, 0)
																  FROM		#ChartAuditProcedureVersionItem i2
																  WHERE		i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId)
										THEN 0
									ELSE 1
								END AS RevCNT
						 FROM	#ChartPostBillAudit pba
							  , #ChartAuditVersion cav
							  , #ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 2
								AND i.ExcludeFromQA <> 1
								AND i.ChartAuditActionTypeCode <> 4
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID) x )							  AS ProfProc_ModRev_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND pba.ChartId = c.CHART_ID)										  AS ProfProcAttempted_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode <> 4
						AND pba.ChartId = c.CHART_ID)										  AS ProfProcActions_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 4
						AND pba.ChartId = c.CHART_ID)										  AS ProfProcNoChange_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 2
						AND pba.ChartId = c.CHART_ID)										  AS ProfProcAdditions_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 1
						AND pba.ChartId = c.CHART_ID)										  AS ProfProcRevisions_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 5
						AND pba.ChartId = c.CHART_ID)										  AS ProfProcDeletions_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 3
						AND pba.ChartId = c.CHART_ID)										  AS ProfProcAbstract_Post
				-- Dx
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID)											  AS DxAttempted
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION <> ''
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS DxActions
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND (dx.IS_CODER_CORRECT = 1
							 OR EXCLUDE_FROM_QA_REPORT = 1))								  AS DxCorrect
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION = 'A'
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS DxAdditions
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION = 'R'
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS DxRevisions
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION = 'D'
						AND EXCLUDE_FROM_QA_REPORT <> 1)									  AS DxDeletions
			  , (SELECT COUNT(DISTINCT dx.CHART_ID)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION = 'C'
						AND EXCLUDE_FROM_QA_REPORT <> 1
						AND dx.CHART_ID NOT IN (SELECT	CHART_ID
												FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx2
												WHERE	dx2.CHART_ID = dx.CHART_ID
														AND dx2.ACTION IN ('D', 'R', 'A')
														AND dx2.EXCLUDE_FROM_QA_REPORT <> 1)) AS DxAbstract
			  , (SELECT COUNT(DISTINCT dx.CHART_ID)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID)											  AS DxSubmitted
				-- Dx Post	
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND pba.ChartId = c.CHART_ID)										  AS DxAttempted_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode <> 4
						AND pba.ChartId = c.CHART_ID)										  AS DxActions_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 4
						AND pba.ChartId = c.CHART_ID)										  AS DxNoChange_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 2
						AND pba.ChartId = c.CHART_ID)										  AS DxAdditions_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 1
						AND pba.ChartId = c.CHART_ID)										  AS DxRevisions_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 5
						AND pba.ChartId = c.CHART_ID)										  AS DxDeletions_Post
			  , (SELECT COUNT(*)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 3
						AND pba.ChartId = c.CHART_ID)										  AS DxAbstract_Post
			  , (SELECT COUNT(DISTINCT pba.ChartId)
				 FROM	#ChartPostBillAudit pba
					  , #ChartAuditVersion cav
					  , #ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND pba.ChartId = c.CHART_ID)										  AS DxSubmitted_Post
				-- Service
			  , CASE
					WHEN sa.EVALUATE_PHYSICIAN_PROCEDURES = 1
						THEN 'Y'
					ELSE 'N'
				END																			  AS ProfProcService
		INTO	#Scorecard_1
		FROM	[#ChartSubset]					  c WITH (NOLOCK)
				LEFT OUTER JOIN USER_PROFILE	  up WITH (NOLOCK)
					ON c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
				LEFT OUTER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK)
					ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID;

		-- select * from [#ChartSubset]
		-- select * from #Scorecard_1

		-- *****************************************************************************************************************************************
		-- Coded Charts
		DECLARE @ScoreCardCnt int = 0;
		DECLARE @CodedChartsCnt int = 0;

		SET @ScoreCardCnt = (SELECT COUNT(*)FROM #Scorecard_1);
		SET @CodedChartsCnt = (SELECT COUNT	 (*)FROM #CodedCharts);

		IF @ScoreCardCnt = 0
		   AND	@CodedChartsCnt > 0
			BEGIN
				INSERT INTO #Scorecard_1
							SELECT	DISTINCT
									0									AS service_agreement_id
								  , ''									AS ServiceAgreementDescription
								  , 0									AS chart_id
								  , 0									AS facility_chart_id
									-- '' as APPROVED_DATE, 
								  , COMPLETED_BY_USER_PROFILE_ID		AS USER_PROFILE_ID
								  , up.LAST_NAME + ', ' + up.FIRST_NAME AS CoderName
								  , 0									AS Audit1
								  , 0									AS Audit2
								  , 0									AS AuditPBA
								  , ''									APPROVED_DATE
								  , ''									SECOND_LEVEL_QA_APPROVED_DATETIME
								  , ''									POST_BILL_AUDIT_COMPLETED
								  , ''									COMPLETION_DATE

									-- Physician Procedure
								  , 0									AS ProfProc_UnitOpp
								  , 0									AS ProfProc_UnitRev
								  , 0									AS ProfProc_ModOpp
								  , 0									AS ProfProc_ModRev
								  , 0									AS ProfProcAttempted
								  , 0									AS ProfProcActions
								  , 0									AS ProfProcCorrect
								  , 0									AS ProfProcAdditions
								  , 0									AS ProfProcRevisions
								  , 0									AS ProfProcDeletions
								  , 0									AS ProfProcAbstract
									-- Physician Procedure Post
								  , 0									AS ProfProc_UnitOpp_Post
								  , 0									AS ProfProc_UnitRev_Post
								  , 0									AS ProfProc_ModOpp_Post
								  , 0									AS ProfProc_ModRev_Post
								  , 0									AS ProfProcAttempted_Post
								  , 0									AS ProfProcActions_Post
								  , 0									AS ProfProcNoChange_Post
								  , 0									AS ProfProcAdditions_Post
								  , 0									AS ProfProcRevisions_Post
								  , 0									AS ProfProcDeletions_Post
								  , 0									AS ProfProcAbstract_Post
									-- Dx
								  , 0									AS DxAttempted
								  , 0									AS DxActions
								  , 0									AS DxCorrect
								  , 0									AS DxAdditions
								  , 0									AS DxRevisions
								  , 0									AS DxDeletions
								  , 0									AS DxAbstract
								  , 0									AS DxSubmitted
									-- Dx Post
								  , 0									AS DxAttempted_Post
								  , 0									AS DxActions_Post
								  , 0									AS DxNoChange_Post
								  , 0									AS DxAdditions_Post
								  , 0									AS DxRevisions_Post
								  , 0									AS DxDeletions_Post
								  , 0									AS DxAbstract_Post
								  , 0									AS DxSubmitted_Post
									-- Service
								  , 0									AS ProfProcService
							FROM	#CodedCharts				 c
									LEFT OUTER JOIN USER_PROFILE up WITH (NOLOCK)
										ON c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID;
			END;
		-- *****************************************************************************************************************************************

		--calculations 
		-- last detail temp table
		SELECT -- (only user profile id and chart id are needed)
				s.CHART_ID
			  , s.USER_PROFILE_ID
			  , s.CoderName
			  , p.PQRS_MEASURES_NUMBER																							AS PQRS_MEASURES_NUMBER
			  , p.BILLING_CODE
			  , 1																												AS Coded
			  , IIF(s.Audit1 = 1 OR s.Audit2 = 1 OR s.AuditPBA = 1, 1, 0)														Audited
			  , IIF(s.Audit1 = 1, s.APPROVED_DATE, NULL)																		AS APPROVED_DATE
			  , IIF(s.Audit2 = 1, s.SECOND_LEVEL_QA_APPROVED_DATETIME, NULL)													AS SECOND_LEVEL_APPROVED_DATE
			  , IIF(s.AuditPBA = 1, s.POST_BILL_AUDIT_COMPLETED, NULL)															AS POST_BILL_AUDIT_DATE
			  , s.COMPLETION_DATE

			  -- Physician Procedure
			  , IIF(s.ProfProcAttempted_Post > 0 AND s.ProfProcActions_Post > 0, s.ProfProcAdditions_Post, s.ProfProcAdditions) AS ProfProcAdditions
			  , IIF(s.ProfProcAttempted_Post > 0 AND s.ProfProcActions_Post > 0, s.ProfProcRevisions_Post, s.ProfProcRevisions) AS ProfProcRevisions
			  , IIF(s.ProfProcAttempted_Post > 0 AND s.ProfProcActions_Post > 0, s.ProfProcDeletions_Post, s.ProfProcDeletions) AS ProfProcDeletions
			  , IIF(s.ProfProcAttempted_Post > 0 AND s.ProfProcActions_Post > 0, s.ProfProcNoChange_Post, s.ProfProcCorrect)	AS ProfProcCorrect
			  -- Dx 
			  , IIF(s.DxAttempted_Post > 0 AND s.DxActions_Post	 > 0, s.DxAdditions_Post, s.DxAdditions)						AS DxAdditions
			  , IIF(s.DxAttempted_Post > 0 AND s.DxActions_Post	 > 0, s.DxRevisions_Post, s.DxRevisions)						AS DxRevisions
			  , IIF(s.DxAttempted_Post > 0 AND s.DxActions_Post	 > 0, s.DxDeletions_Post, s.DxDeletions)						AS DxDeletions
			  , IIF(s.DxAttempted_Post > 0 AND s.DxActions_Post	 > 0, s.DxNoChange_Post, s.DxCorrect)							AS DxCorrect
			  , IIF(s.DxAttempted_Post > 0 AND s.DxActions_Post	 > 0, s.DxAbstract_Post, s.DxAbstract)							AS DxAbstract

			  -- Totals
			  , IIF(s.ProfProcAdditions_Post > 0, s.ProfProcAdditions_Post, s.ProfProcAdditions)								AS AddedCount
			  , IIF(s.ProfProcRevisions_Post > 0, s.ProfProcRevisions_Post, s.ProfProcRevisions)								AS RevisedCount
			  , IIF(s.ProfProcDeletions_Post > 0, s.ProfProcDeletions_Post, s.ProfProcDeletions)								AS DeletedCount
			  , IIF(s.ProfProcNoChange_Post > 0, s.ProfProcNoChange_Post, s.ProfProcCorrect)									AS CorrectCount
			  , (SELECT CASE
							WHEN ProfProcService = 'N'
								THEN '-'
							WHEN ProfProcService = 'Y'
								 AND ProfProcAttempted = 0
								THEN '-'
							WHEN (ProfProcService = 'Y'
								  AND	ProfProcActions > 0)
								THEN 'Error'
							WHEN (ProfProcService = 'Y'
								  AND	ProfProcActions = 0
								  AND	ProfProcAttempted > 0)
								THEN 'Correct'
						END
				 FROM	#Scorecard_1
				 WHERE	CHART_ID = s.CHART_ID)																					AS ProfProcError
			  , (SELECT CASE
							WHEN ProfProcService = 'N'
								THEN '-'
							WHEN ProfProcService = 'Y'
								 AND ProfProcAttempted_Post = 0
								THEN '-'
							WHEN (ProfProcService = 'Y'
								  AND	ProfProcAttempted_Post > 0
								  AND	ProfProcActions_Post > 0)
								THEN 'Error'
							WHEN (ProfProcService = 'Y'
								  AND	ProfProcActions_Post = 0
								  AND	ProfProcAttempted_Post > 0)
								THEN 'Correct'
						END
				 FROM	#Scorecard_1
				 WHERE	CHART_ID = s.CHART_ID)																					AS ProfProcError_Post
		INTO	#Scorecard_2
		FROM	#Scorecard_1	 s
				INNER JOIN #PQRS p
					ON s.CHART_ID = p.CHART_ID;

		-- ****************************************
		SELECT		CoderName
				  , PQRS_MEASURES_NUMBER
				  , BILLING_CODE
				  , SUM(Coded)			   AS Coded
				  , SUM(Audited)		   AS Audited
				  , CASE
						WHEN APPROVED_DATE > ISNULL(SECOND_LEVEL_APPROVED_DATE, '01/01/1900')
							 AND APPROVED_DATE > ISNULL(POST_BILL_AUDIT_DATE, '01/01/1900')
							THEN APPROVED_DATE
						WHEN SECOND_LEVEL_APPROVED_DATE > ISNULL(APPROVED_DATE, '01/01/1900')
							 AND SECOND_LEVEL_APPROVED_DATE > ISNULL(POST_BILL_AUDIT_DATE, '01/01/1900')
							THEN SECOND_LEVEL_APPROVED_DATE
						WHEN POST_BILL_AUDIT_DATE > ISNULL(APPROVED_DATE, '01/01/1900')
							 AND POST_BILL_AUDIT_DATE > ISNULL(SECOND_LEVEL_APPROVED_DATE, '01/01/1900')
							THEN POST_BILL_AUDIT_DATE
					END					   AS AuditDate

				  -- Physician Procedure
				  , SUM(ProfProcAdditions) AS ProfProcAdditions
				  , SUM(ProfProcRevisions) AS ProfProcRevisions
				  , SUM(ProfProcDeletions) AS ProfProcDeletions
				  , SUM(ProfProcCorrect)   AS ProfProcCorrect
				  -- Dx 
				  --sum(DxAdditions) as DxAdditions,
				  --DxRevisions,
				  --DxDeletions,
				  --DxCorrect,
				  --DxAbstract,
				  ---- Totals
				  , SUM(AddedCount)		   AS AddedCount
				  , SUM(RevisedCount)	   AS RevisedCount
				  , SUM(DeletedCount)	   AS DeletedCount
				  , SUM(CorrectCount)	   AS CorrectCount
				  , SUM(CASE
							WHEN ProfProcError = 'Correct'
								 OR ProfProcError_Post = 'Correct'
								THEN 1
						END)			   Correct
				  , SUM(CASE
							WHEN ProfProcError = 'Error'
								 OR ProfProcError_Post = 'Error'
								THEN 1
						END)			   Revision
		INTO		#Scorecard_3
		FROM		#Scorecard_2
		WHERE		CASE -- exclude records with completion date 10/1-10/7 with Billing Code of 99999
						WHEN (CAST(COMPLETION_DATE AS date) BETWEEN '10/01/2024' AND '10/07/2024'
							  AND	BILLING_CODE <> '99999')
							THEN 1
						WHEN CAST(COMPLETION_DATE AS date) <= '10/01/2024'
							THEN 1
						WHEN CAST(COMPLETION_DATE AS date) >= '10/07/2024'
							THEN 1
					END = 1
		GROUP BY	CoderName
				  , PQRS_MEASURES_NUMBER
				  , BILLING_CODE
				  , CASE
						WHEN APPROVED_DATE > ISNULL(SECOND_LEVEL_APPROVED_DATE, '01/01/1900')
							 AND   APPROVED_DATE > ISNULL(POST_BILL_AUDIT_DATE, '01/01/1900')
							THEN APPROVED_DATE
						WHEN SECOND_LEVEL_APPROVED_DATE > ISNULL(APPROVED_DATE, '01/01/1900')
							 AND   SECOND_LEVEL_APPROVED_DATE > ISNULL(POST_BILL_AUDIT_DATE, '01/01/1900')
							THEN SECOND_LEVEL_APPROVED_DATE
						WHEN POST_BILL_AUDIT_DATE > ISNULL(APPROVED_DATE, '01/01/1900')
							 AND   POST_BILL_AUDIT_DATE > ISNULL(SECOND_LEVEL_APPROVED_DATE, '01/01/1900')
							THEN POST_BILL_AUDIT_DATE
					END;

		

		-- *****************************************************************************************************************************************

		--Output
		SELECT		s.CoderName
				  , s.PQRS_MEASURES_NUMBER
				  , s.BILLING_CODE
				  , SUM(s.Correct)																   AS Correct
				  , SUM(s.Revision)																   AS Revision
				  , SUM(s.AddedCount)															   AS AddedCount
				  , SUM(s.RevisedCount)															   AS RevisedCount
				  , SUM(s.DeletedCount)															   AS DeletedCount
				  , SUM(s.CorrectCount)															   AS AccurateCount
				  , SUM(Coded)																	   AS Coded
				  , SUM(Audited)																   AS Audited
				  , CASE @TimeInterval
						WHEN 0
							THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, AuditDate))), 0)), 0)
						WHEN 1
							THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, AuditDate))), 0)), -1)
						WHEN 2
							THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, AuditDate))), 0)), 0)
						WHEN 3
							THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, AuditDate))), 0)), 0)
						ELSE NULL
					END																			   AS AuditDate

					--AuditDate,

					-- Physician Procedure
				  , SUM(s.ProfProcDeletions) + SUM(s.ProfProcRevisions) + SUM(s.ProfProcAdditions) AS ProfProc_N
				  , SUM(s.ProfProcCorrect) + SUM(s.ProfProcRevisions) + SUM(s.ProfProcAdditions)   AS ProfProc_D
		FROM		#Scorecard_3 s
		GROUP BY	s.CoderName
				  , s.PQRS_MEASURES_NUMBER
				  , s.BILLING_CODE
				  , CASE @TimeInterval
						WHEN 0
							THEN DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, AuditDate))), 0)), 0)
						WHEN 1
							THEN DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, AuditDate))), 0)), -1)
						WHEN 2
							THEN DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, AuditDate))), 0)), 0)
						WHEN 3
							THEN DATEADD(YEAR, DATEDIFF(YEAR, 0, DATEADD(DAY, DATEDIFF(DAY, 0, DATEADD(HOUR, @HrsOffSet, DATEADD(MINUTE, @MinOffSet, AuditDate))), 0)), 0)
						ELSE NULL
					END;

	-- END
 	END;
GO
