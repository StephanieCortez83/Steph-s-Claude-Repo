SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[rpt_PQRS_MIPS_QUALITY] @ReportUser  int
																, @DateType	   int
																, @StartDate   datetime
																, @EndDate	   datetime
																, @COMPANY_ID  varchar(MAX)
																, @FACILITY_ID varchar(MAX)
																, @CUID		   varchar(MAX)
																, @TimeZone	   varchar(50)
AS
	BEGIN

		-- test parameters
		--declare
		--    @ReportUser INT = 80,
		--    @DateType INT = 0, -- 0 Approved, 1 DOS, 2 Sent, 3 PostAudit
		--	@StartDate DATETIME = '11/01/2024',
		--	@EndDate DATETIME   = '11/10/2024',

		--	@COMPANY_ID  VARCHAR(MAX) = '296', 
		--	@FACILITY_ID VARCHAR(MAX) = '2641', -- '2639, 2640, 2641, 2642, 2643, 2644, 2645, 2646',

		--	@CUID        VARCHAR(MAX) = '-1',
		--	@TimeZone VARCHAR(50) =	'Central Daylight Time';   --'India Standard Time'
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
		DROP TABLE IF EXISTS #CodedCharts;
		DROP TABLE IF EXISTS #Scorecard_1;
		DROP TABLE IF EXISTS #Scorecard_2;
		DROP TABLE IF EXISTS #AuditGrid1;
		DROP TABLE IF EXISTS #AuditNotes1;
		DROP TABLE IF EXISTS #AuditNotes2;
		DROP TABLE IF EXISTS #CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION;
		DROP TABLE IF EXISTS #combined;
		DROP TABLE IF EXISTS #PQRS;
		DROP TABLE IF EXISTS #Chart_Prefilter;

		-- ********************************************************************************
		-- AuthorizedFacilities
		SELECT	*
		INTO	#AuthorizedFacilities
		FROM	(SELECT DISTINCT
						fua.FACILITY_ID
				 FROM	FACILITY_USER_AUTHORIZATION fua
					  , USER_PROFILE up
					  , SERVICE_AGREEMENT sa
				 WHERE	fua.USER_PROFILE_ID = up.USER_PROFILE_ID
						AND fua.FACILITY_ID = sa.FACILITY_ID
						AND up.IS_ACTIVE = 'Y'
						AND GETDATE() BETWEEN fua.EFFECTIVE_DATE AND fua.EXPIRATION_DATE
						AND GETDATE() BETWEEN sa.EFFECTIVE_DATE AND sa.EXPIRATION_DATE
						AND sa.DEMO_TEST_SITE_IND = 0
						AND fua.USER_PROFILE_ID = @ReportUser
						
				AND EXISTS (SELECT	1
							FROM	@Companies x
							WHERE	x.COMPANY_ID = sa.COMPANY_ID)
				AND (@AllFacilities = 1
					 OR EXISTS (SELECT	1
								FROM	@Facilities x
								WHERE	fua.FACILITY_ID = x.FACILITY_ID))
						AND sa.SERVICE_AGREEMENT_ID IN (SELECT	DISTINCT
																SERVICE_AGREEMENT_ID
														FROM	SERVICE_AGREEMENT_PQRS
														WHERE	GETDATE() BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, '12/31/2099')) -- Active PQRS Service Agreements
		) af;

		-- select * from #AuthorizedFacilities

		-- *************************************************************************
		-- Coders/UserClass
		IF OBJECT_ID('TempDB..#coder', 'U') IS NOT NULL
			DROP TABLE #coder;

		SELECT	DISTINCT
				t1.USER_PROFILE_ID
		INTO	#coder
		FROM	(SELECT USER_PROFILE_ID
				 FROM	USER_PROFILE up
				 WHERE	USER_PROFILE_ID <> 2
						AND (CHANGED_DATE_TIME > CONVERT(date, DATEADD(MONTH, -3, GETDATE()))
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

		WITH chartList AS (
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
			  , c.FACILITY_ID
			  , c.SERVICE_AGREEMENT_ID
			  , c.FACILITY_CHART_ID
			  , c.COMPLETED_BY_USER_PROFILE_ID
			  , c.COMPLETION_DATE
			  , c.PATIENT_DISPOSITION_ID
			  , c.MEDICAL_RECORD_NUM
			  , c.TIME_OF_SERVICE
			  , c.CHART_STATUS_ID
			  , c.PROVIDER_EVAL_PERFORMED_BY_IND
			  , c.PHYSICIAN_ID
			  , c.NURSE_PRACTITIONER_ID
			  , c.START_QA_DATE
			  , c.APPROVED_DATE
			  , c.APPROVED_BY_USER_PROFILE_ID
			  , c.POST_BILL_AUDIT_STARTED
			  , c.POST_BILL_AUDIT_COMPLETED
			  , c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID
			  , c.START_SECOND_LEVEL_QA_DATETIME
			  , c.SECOND_LEVEL_QA_APPROVED_DATETIME
			  , c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
			  , FACILITY_SERVICE_LEVEL_AUDIT_COMMENT
			  , FACILITY_PROCEDURES_AUDIT_COMMENT
			  , PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT
			  , PHYSICIAN_PROCEDURES_AUDIT_COMMENT
			  , DIAGNOSIS_CODING_AUDIT_COMMENT
			  , INFUSION_INJECTION_AUDIT_COMMENT
			  , AUDITOR_REVIEW_FEEDBACK
			  , OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT
			  , OBSERVATION_PROCEDURES_AUDIT_COMMENT
			  , OBSERVATION_AUDITOR_REVIEW_FEEDBACK
			  , DEMOGRAPHIC_AUDIT_COMMENT
			  , ANESTHESIA_CODING_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_AUDITOR_REVIEW_FEEDBACK
			  , SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_OBSERVATION_FACILITY_PROCEDURE_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK
			  , SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT
			  , SECOND_LEVEL_QA_ANESTHESIA_CODING_AUDIT_COMMENT
		INTO	[#ChartSubset]
		FROM	CHART AS c WITH (NOLOCK)
				LEFT OUTER JOIN CHART_SECOND_LEVEL_AUDIT_COMMENTS sl
					ON c.CHART_ID = sl.CHART_ID
		WHERE	EXISTS (SELECT	1
						FROM	chartList x
						WHERE	c.CHART_ID = x.CHART_ID);
						 

		-- *****************************************************************************************************************************************
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

		-- *****************************************************************************************************************************************
		SELECT	c.CHART_ID
			  , c.FACILITY_CHART_ID
			  , c.FACILITY_ID
			  , up.USER_PROFILE_ID
			  , up.LAST_NAME + ', ' + up.FIRST_NAME										AS CoderName
			  , c.TIME_OF_SERVICE
			  , c.COMPLETION_DATE
			  , c.PROVIDER_EVAL_PERFORMED_BY_IND
			  , c.PHYSICIAN_ID
			  , c.NURSE_PRACTITIONER_ID
			  , c.APPROVED_BY_USER_PROFILE_ID
			  , c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
			  , c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID
			  , CASE
					WHEN c.START_QA_DATE IS NOT NULL
						 AND c.APPROVED_DATE IS NOT NULL
						 AND c.APPROVED_BY_USER_PROFILE_ID <> 2
						THEN 1
					ELSE 0
				END																		AS Audit1
			  , CASE
					WHEN c.START_SECOND_LEVEL_QA_DATETIME IS NOT NULL
						 AND c.SECOND_LEVEL_QA_APPROVED_DATETIME IS NOT NULL
						 AND c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2
						THEN 1
					ELSE 0
				END																		AS Audit2
			  , CASE
					WHEN c.POST_BILL_AUDIT_STARTED IS NOT NULL
						 AND c.POST_BILL_AUDIT_COMPLETED IS NOT NULL
						 AND c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID IS NOT NULL
						THEN 1
					ELSE 0
				END																		AS AuditPBA
			  , c.APPROVED_DATE
			  , c.SECOND_LEVEL_QA_APPROVED_DATETIME
			  , c.POST_BILL_AUDIT_COMPLETED
				-- PBA Audit Reason
			  , (SELECT pba.ChartPostBillAuditReasonTypeCode
				 FROM	ChartPostBillAudit pba
				 WHERE	pba.ChartPostBillAuditStatusTypeCode = 3
						AND pba.ChartId = c.CHART_ID)									AS AuditReasonCode

				--Dx
			  , (SELECT STUFF((SELECT	'; ' + CODER_ICD10_CODE
							   FROM		(SELECT CODER_ICD10_CODE
											  , CODER_POSTING_ORDER
										 FROM	CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx
										 WHERE	dx.CHART_ID = c.CHART_ID
												AND dx.EXCLUDE_FROM_QA_REPORT <> 1
												AND dx.CODER_ICD10_CODE <> '') x
							   ORDER BY CODER_POSTING_ORDER
							  FOR XML PATH('')), 1, 1, ''))								AS Dx_CoderOrig
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND (dx.IS_CODER_CORRECT = 1
							 OR EXCLUDE_FROM_QA_REPORT = 1))							AS DxCorrect
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID)										AS DxAttempted
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION = 'A'
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS DxAdditions
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION = 'R'
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS DxRevisions
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION = 'D'
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS DxDeletions
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION = 'C'
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS DxAbstract
			  , (SELECT STUFF((SELECT	'; ' + AUDITOR_ICD10_CODE
							   FROM		(SELECT AUDITOR_ICD10_CODE
										 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx
										 WHERE	dx.CHART_ID = c.CHART_ID
												AND dx.ACTION = 'A'
												AND EXCLUDE_FROM_QA_REPORT <> 1) x
							   ORDER BY AUDITOR_ICD10_CODE
							  FOR XML PATH('')), 1, 1, ''))								AS DxAdd_Action
			  , (SELECT STUFF((SELECT	'; ' + AUDITOR_ICD10_CODE
							   FROM		(SELECT AUDITOR_ICD10_CODE
										 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx
										 WHERE	dx.CHART_ID = c.CHART_ID
												AND dx.ACTION = 'R'
												AND EXCLUDE_FROM_QA_REPORT <> 1) x
							   ORDER BY AUDITOR_ICD10_CODE
							  FOR XML PATH('')), 1, 1, ''))								AS DxRev_Action
			  , (SELECT STUFF((SELECT	'; ' + CODER_ICD10_CODE
							   FROM		(SELECT CODER_ICD10_CODE
										 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx
										 WHERE	dx.CHART_ID = c.CHART_ID
												AND dx.ACTION = 'D'
												AND EXCLUDE_FROM_QA_REPORT <> 1) x
							   ORDER BY CODER_ICD10_CODE
							  FOR XML PATH('')), 1, 1, ''))								AS DxDel_Action

				--Dx Post	
			  , (SELECT STUFF((SELECT	'; ' + ICDCode
							   FROM		(SELECT ICDCode
											  , ICDPostingOrder
										 FROM	ChartPostBillAudit pba
											  , ChartAuditVersion cav
											  , ChartAuditDiagnosisVersionItem i
										 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
												AND cav.ChartAuditVersionId = i.ChartAuditVersionId
												AND pba.ChartPostBillAuditStatusTypeCode = 3
												AND cav.VersionNumber = 1
												AND ISNULL(i.ExcludeFromQA, 0) <> 1
												AND i.ChartAuditActionTypeCode = 4
												AND pba.ChartId = c.CHART_ID) x
							   ORDER BY ICDPostingOrder
							  FOR XML PATH('')), 1, 1, ''))								AS Dx_Orig_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 2
						AND pba.ChartId = c.CHART_ID)									AS DxAdditions_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 1
						AND pba.ChartId = c.CHART_ID)									AS DxRevisions_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 5
						AND pba.ChartId = c.CHART_ID)									AS DxDeletions_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 3
						AND pba.ChartId = c.CHART_ID)									AS DxAbstract_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode = 4
						AND pba.ChartId = c.CHART_ID)									AS DxNoChange_Post
			  , (SELECT STUFF((SELECT	'; ' + ICDCode
							   FROM		(SELECT ICDCode
										 FROM	ChartPostBillAudit pba
											  , ChartAuditVersion cav
											  , ChartAuditDiagnosisVersionItem i
										 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
												AND cav.ChartAuditVersionId = i.ChartAuditVersionId
												AND pba.ChartPostBillAuditStatusTypeCode = 3
												AND cav.VersionNumber = 2
												AND i.ExcludeFromQA <> 1
												AND i.ChartAuditActionTypeCode = 2
												AND pba.ChartId = c.CHART_ID) x
							   ORDER BY ICDCode
							  FOR XML PATH('')), 1, 1, ''))								AS DxAdd_Action_Post
			  , (SELECT STUFF((SELECT	'; ' + ICDCode
							   FROM		(SELECT ICDCode
										 FROM	ChartPostBillAudit pba
											  , ChartAuditVersion cav
											  , ChartAuditDiagnosisVersionItem i
										 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
												AND cav.ChartAuditVersionId = i.ChartAuditVersionId
												AND pba.ChartPostBillAuditStatusTypeCode = 3
												AND cav.VersionNumber = 2
												AND i.ExcludeFromQA <> 1
												AND i.ChartAuditActionTypeCode = 1
												AND pba.ChartId = c.CHART_ID) x
							   ORDER BY ICDCode
							  FOR XML PATH('')), 1, 1, ''))								AS DxRev_Action_Post
			  , (SELECT STUFF((SELECT	'; ' + ICDCode
							   FROM		(SELECT i2.ICDCode
										 FROM	ChartAuditDiagnosisVersionItem i2
										 WHERE	i2.ChartAuditDiagnosisVersionItemId IN (SELECT	i.PrevChartAuditDiagnosisVersionItemId
																						FROM	ChartPostBillAudit pba
																							  , ChartAuditVersion cav
																							  , ChartAuditDiagnosisVersionItem i
																						WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
																								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
																								AND pba.ChartPostBillAuditStatusTypeCode = 3
																								AND cav.VersionNumber = 2
																								AND i.ExcludeFromQA <> 1
																								AND i.ChartAuditActionTypeCode = 5
																								AND pba.ChartId = c.CHART_ID)) x
							   ORDER BY ICDCode
							  FOR XML PATH('')), 1, 1, ''))								AS DxDel_Action_Post

				-- Prof Procedures
			  , (SELECT COUNT(*) AS CNT
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
				 WHERE	pro.CHART_ID = c.CHART_ID
						AND pro.PROCEDURE_TYPE = 'PP'
						AND pro.EXCLUDE_FROM_QA_REPORT <> 1
						AND (pro.CODER_QUANTITY > 0
							 OR pro.AUDITOR_QUANTITY > 0))								AS ProfProc_UnitOpp
			  , (SELECT COUNT(*) AS CNT
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
				 WHERE	pro.CHART_ID = c.CHART_ID
						AND pro.PROCEDURE_TYPE = 'PP'
						AND pro.EXCLUDE_FROM_QA_REPORT <> 1
						AND pro.CODER_QUANTITY <> pro.AUDITOR_QUANTITY)					AS ProfProc_UnitRev
			  , (SELECT COUNT(*) AS CNT
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
				 WHERE	pro.CHART_ID = c.CHART_ID
						AND pro.PROCEDURE_TYPE = 'PP'
						AND pro.EXCLUDE_FROM_QA_REPORT <> 1
						AND (pro.CODER_MODIFIER <> ''
							 OR pro.AUDITOR_MODIFIER <> ''))							AS ProfProc_ModOpp
			  , (SELECT COUNT(*) AS CNT
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
				 WHERE	pro.CHART_ID = c.CHART_ID
						AND pro.PROCEDURE_TYPE = 'PP'
						AND pro.EXCLUDE_FROM_QA_REPORT <> 1
						AND pro.CODER_MODIFIER <> pro.AUDITOR_MODIFIER)					AS ProfProc_ModRev
			  , (SELECT STUFF((SELECT	'; ' + CAST(Coder1 AS varchar)
							   FROM		(SELECT CASE
													WHEN LEN(pro.CODER_CPT_CODE) > 0
														 AND LEN(pro.CODER_MODIFIER) > 0
														THEN pro.CODER_CPT_CODE + ' / ' + pro.CODER_MODIFIER + ' / ' + CAST(pro.CODER_QUANTITY AS varchar)
													WHEN LEN(pro.CODER_CPT_CODE) > 0
														THEN pro.CODER_CPT_CODE + ' / ' + CAST(pro.CODER_QUANTITY AS varchar)
													WHEN LEN(pro.CODER_MODIFIER) > 0
														THEN pro.CODER_MODIFIER + ' / ' + CAST(pro.CODER_QUANTITY AS varchar)
												END AS Coder1
										 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro
										 WHERE	pro.CHART_ID = c.CHART_ID
												AND pro.PROCEDURE_TYPE = 'PP'
												AND pro.EXCLUDE_FROM_QA_REPORT <> 1) x
							   ORDER BY Coder1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProc_CoderOrig
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND (pr.IS_CODER_CORRECT = 1
							 OR EXCLUDE_FROM_QA_REPORT = 1))							AS ProfProcCorrect
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP')									AS ProfProcAttempted
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION = 'A'
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS ProfProcAdditions
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION = 'R'
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS ProfProcRevisions
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION = 'D'
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS ProfProcDeletions
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION = 'C'
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS ProfProcAbstract
			  , (SELECT STUFF((SELECT	'; ' + CAST(Audit1 AS varchar)
							   FROM		(SELECT CASE
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														 AND LEN(pr.AUDITOR_MODIFIER) > 0
														 AND LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5)) + ' / ' + CAST(pr.AUDITOR_MODIFIER AS varchar(10)) + ' / ' + CAST(pr.AUDITOR_QUANTITY AS varchar(5))
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														 AND LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5)) + ' / ' + CAST(pr.AUDITOR_QUANTITY AS varchar(5))
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5))
													WHEN LEN(pr.AUDITOR_MODIFIER) > 0
														THEN CAST(pr.AUDITOR_MODIFIER AS varchar(10))
													WHEN LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_QUANTITY AS varchar(5))
												END AS Audit1
										 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr
										 WHERE	pr.CHART_ID = c.CHART_ID
												AND pr.PROCEDURE_TYPE = 'PP'
												AND pr.ACTION = 'A'
												AND EXCLUDE_FROM_QA_REPORT <> 1) x
							   ORDER BY Audit1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProcAdd_Action
			  , (SELECT STUFF((SELECT	'; ' + CAST(Audit1 AS varchar)
							   FROM		(SELECT CASE
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														 AND LEN(pr.AUDITOR_MODIFIER) > 0
														 AND LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5)) + ' / ' + CAST(pr.AUDITOR_MODIFIER AS varchar(10)) + ' / ' + CAST(pr.AUDITOR_QUANTITY AS varchar(5))
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														 AND LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5)) + ' / ' + CAST(pr.AUDITOR_QUANTITY AS varchar(5))
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5))
													WHEN LEN(pr.AUDITOR_MODIFIER) > 0
														THEN CAST(pr.AUDITOR_MODIFIER AS varchar(10))
													WHEN LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_QUANTITY AS varchar(5))
												END AS Audit1
										 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr
										 WHERE	pr.CHART_ID = c.CHART_ID
												AND pr.PROCEDURE_TYPE = 'PP'
												AND pr.ACTION = 'R'
												AND EXCLUDE_FROM_QA_REPORT <> 1) x
							   ORDER BY Audit1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProcRev_Action
			  , (SELECT STUFF((SELECT	'; ' + CAST(Audit1 AS varchar)
							   FROM		(SELECT CASE
													WHEN LEN(pr.CODER_CPT_CODE) > 0
														 AND LEN(pr.CODER_MODIFIER) > 0
														 AND LEN(pr.CODER_QUANTITY) > 0
														THEN CAST(pr.CODER_CPT_CODE AS varchar(5)) + ' / ' + CAST(pr.CODER_MODIFIER AS varchar(10)) + ' / ' + CAST(pr.CODER_QUANTITY AS varchar(5))
													WHEN LEN(pr.CODER_CPT_CODE) > 0
														 AND LEN(pr.CODER_QUANTITY) > 0
														THEN CAST(pr.CODER_CPT_CODE AS varchar(5)) + ' / ' + CAST(pr.CODER_QUANTITY AS varchar(5))
													WHEN LEN(pr.CODER_CPT_CODE) > 0
														THEN CAST(pr.CODER_CPT_CODE AS varchar(5))
													WHEN LEN(pr.CODER_MODIFIER) > 0
														THEN CAST(pr.CODER_MODIFIER AS varchar(10))
													WHEN LEN(pr.CODER_QUANTITY) > 0
														THEN CAST(pr.CODER_QUANTITY AS varchar(5))
												END AS Audit1
										 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr
										 WHERE	pr.CHART_ID = c.CHART_ID
												AND pr.PROCEDURE_TYPE = 'PP'
												AND pr.ACTION = 'D'
												AND EXCLUDE_FROM_QA_REPORT <> 1) x
							   ORDER BY Audit1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProcDel_Action
			  , (SELECT STUFF((SELECT	'; ' + CAST(Audit1 AS varchar)
							   FROM		(SELECT CASE
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														 AND LEN(pr.AUDITOR_MODIFIER) > 0
														 AND LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5)) + ' / ' + CAST(pr.AUDITOR_MODIFIER AS varchar(10)) + ' / ' + CAST(pr.AUDITOR_QUANTITY AS varchar(5))
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														 AND LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5)) + ' / ' + CAST(pr.AUDITOR_QUANTITY AS varchar(5))
													WHEN LEN(pr.AUDITOR_CPT_CODE) > 0
														THEN CAST(pr.AUDITOR_CPT_CODE AS varchar(5))
													WHEN LEN(pr.AUDITOR_MODIFIER) > 0
														THEN CAST(pr.AUDITOR_MODIFIER AS varchar(10))
													WHEN LEN(pr.AUDITOR_QUANTITY) > 0
														THEN CAST(pr.AUDITOR_QUANTITY AS varchar(5))
												END AS Audit1
										 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr
										 WHERE	pr.CHART_ID = c.CHART_ID
												AND pr.PROCEDURE_TYPE = 'PP'
												AND pr.ACTION = 'C'
												AND EXCLUDE_FROM_QA_REPORT <> 1) x
							   ORDER BY Audit1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProcAbs_Action
				-- Prof Procedures Post
			  , (SELECT SUM(x.cnt)
				 FROM	(SELECT COUNT(*) AS cnt
						 FROM	ChartPostBillAudit pba
							  , ChartAuditVersion cav
							  , ChartAuditProcedureVersionItem i
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
						 FROM	ChartPostBillAudit pba
							  , ChartAuditVersion cav
							  , ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 2
								AND i.ExcludeFromQA <> 1
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID
								AND i.Quantity IS NOT NULL
								AND i.PrevChartAuditProcedureVersionItemId IS NULL) x ) AS ProfProc_UnitOpp_Post
			  , (SELECT SUM(ISNULL(x.RevCNT, 0))
				 FROM	(SELECT CASE
									WHEN ISNULL(i.Quantity, 0) = (SELECT	ISNULL(i2.Quantity, 0)
																  FROM		ChartAuditProcedureVersionItem i2
																  WHERE		i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId)
										THEN 0
									ELSE 1
								END AS RevCNT
						 FROM	ChartPostBillAudit pba
							  , ChartAuditVersion cav
							  , ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 2
								AND i.ExcludeFromQA <> 1
								AND i.ChartAuditActionTypeCode <> 4
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID) x )						AS ProfProc_UnitRev_Post
			  , (SELECT SUM(x.cnt)
				 FROM	(SELECT COUNT(*) AS cnt
						 FROM	ChartPostBillAudit pba
							  , ChartAuditVersion cav
							  , ChartAuditProcedureVersionItem i
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
						 FROM	ChartPostBillAudit pba
							  , ChartAuditVersion cav
							  , ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 2
								AND i.ExcludeFromQA <> 1
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID
								AND i.Modifier IS NOT NULL
								AND i.PrevChartAuditProcedureVersionItemId IS NULL) x ) AS ProfProc_ModOpp_Post
			  , (SELECT SUM(ISNULL(x.RevCNT, 0))
				 FROM	(SELECT CASE
									WHEN ISNULL(i.Modifier, 0) = (SELECT	ISNULL(i2.Modifier, 0)
																  FROM		ChartAuditProcedureVersionItem i2
																  WHERE		i2.ChartAuditProcedureVersionItemId = i.PrevChartAuditProcedureVersionItemId)
										THEN 0
									ELSE 1
								END AS RevCNT
						 FROM	ChartPostBillAudit pba
							  , ChartAuditVersion cav
							  , ChartAuditProcedureVersionItem i
						 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
								AND pba.ChartPostBillAuditStatusTypeCode = 3
								AND cav.VersionNumber = 2
								AND i.ExcludeFromQA <> 1
								AND i.ChartAuditActionTypeCode <> 4
								AND i.ProcedureType = 'PP'
								AND pba.ChartId = c.CHART_ID) x )						AS ProfProc_ModRev_Post
			  , (SELECT STUFF((SELECT	'; ' + Auditor1
							   FROM		(SELECT CASE
													WHEN LEN(i.CptCode) > 0
														 AND LEN(i.Modifier) > 0
														 AND LEN(i.Quantity) > 0
														THEN i.CptCode + ' / ' + i.Modifier + ' / ' + CAST(i.Quantity AS varchar)
													WHEN LEN(i.CptCode) > 0
														 AND LEN(i.Quantity) > 0
														THEN i.CptCode + ' / ' + CAST(i.Quantity AS varchar)
												END AS Auditor1
										 FROM	ChartPostBillAudit pba
											  , ChartAuditVersion cav
											  , ChartAuditProcedureVersionItem i
										 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
												AND cav.ChartAuditVersionId = i.ChartAuditVersionId
												AND pba.ChartPostBillAuditStatusTypeCode = 3
												AND cav.VersionNumber = 1
												AND ISNULL(i.ExcludeFromQA, 0) <> 1
												AND i.ProcedureType = 'PP'
												AND i.ChartAuditActionTypeCode = 4
												AND pba.ChartId = c.CHART_ID) x
							   ORDER BY Auditor1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProc_Orig_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 2
						AND pba.ChartId = c.CHART_ID)									AS ProfProcAdditions_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 1
						AND pba.ChartId = c.CHART_ID)									AS ProfProcRevisions_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 5
						AND pba.ChartId = c.CHART_ID)									AS ProfProcDeletions_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 3
						AND pba.ChartId = c.CHART_ID)									AS ProfProcAbstract_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode = 4
						AND pba.ChartId = c.CHART_ID)									AS ProfProcNoChange_Post
			  , (SELECT STUFF((SELECT	'; ' + Auditor1
							   FROM		(SELECT CASE
													WHEN LEN(i.CptCode) > 0
														 AND LEN(i.Modifier) > 0
														 AND LEN(i.Quantity) > 0
														THEN i.CptCode + ' / ' + i.Modifier + ' / ' + CAST(i.Quantity AS varchar)
													WHEN LEN(i.CptCode) > 0
														 AND LEN(i.Quantity) > 0
														THEN i.CptCode + ' / ' + CAST(i.Quantity AS varchar)
												END AS Auditor1
										 FROM	ChartPostBillAudit pba
											  , ChartAuditVersion cav
											  , ChartAuditProcedureVersionItem i
										 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
												AND cav.ChartAuditVersionId = i.ChartAuditVersionId
												AND pba.ChartPostBillAuditStatusTypeCode = 3
												AND cav.VersionNumber = 2
												AND i.ExcludeFromQA <> 1
												AND i.ProcedureType = 'PP'
												AND i.ChartAuditActionTypeCode = 2
												AND pba.ChartId = c.CHART_ID) x
							   ORDER BY Auditor1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProcAdd_Action_Post
			  , (SELECT STUFF((SELECT	'; ' + Auditor1
							   FROM		(SELECT CASE
													WHEN LEN(i.CptCode) > 0
														 AND LEN(i.Modifier) > 0
														 AND LEN(i.Quantity) > 0
														THEN i.CptCode + ' / ' + i.Modifier + ' / ' + CAST(i.Quantity AS varchar)
													WHEN LEN(i.CptCode) > 0
														 AND LEN(i.Quantity) > 0
														THEN i.CptCode + ' / ' + CAST(i.Quantity AS varchar)
												END AS Auditor1
										 FROM	ChartPostBillAudit pba
											  , ChartAuditVersion cav
											  , ChartAuditProcedureVersionItem i
										 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
												AND cav.ChartAuditVersionId = i.ChartAuditVersionId
												AND pba.ChartPostBillAuditStatusTypeCode = 3
												AND cav.VersionNumber = 2
												AND i.ExcludeFromQA <> 1
												AND i.ProcedureType = 'PP'
												AND i.ChartAuditActionTypeCode = 1
												AND pba.ChartId = c.CHART_ID) x
							   ORDER BY Auditor1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProcRev_Action_Post
			  , (SELECT STUFF((SELECT	'; ' + Auditor1
							   FROM		(SELECT CASE
													WHEN LEN(i2.CptCode) > 0
														 AND LEN(i2.Modifier) > 0
														 AND LEN(i2.Quantity) > 0
														THEN i2.CptCode + ' / ' + i2.Modifier + ' / ' + CAST(i2.Quantity AS varchar)
													WHEN LEN(i2.CptCode) > 0
														 AND LEN(i2.Quantity) > 0
														THEN i2.CptCode + ' / ' + CAST(i2.Quantity AS varchar)
												END AS Auditor1
										 FROM	ChartAuditProcedureVersionItem i2
										 WHERE	i2.ChartAuditProcedureVersionItemId IN (SELECT	i.PrevChartAuditProcedureVersionItemId
																						FROM	ChartPostBillAudit pba
																							  , ChartAuditVersion cav
																							  , ChartAuditProcedureVersionItem i
																						WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
																								AND cav.ChartAuditVersionId = i.ChartAuditVersionId
																								AND pba.ChartPostBillAuditStatusTypeCode = 3
																								AND cav.VersionNumber = 2
																								AND i.ExcludeFromQA <> 1
																								AND i.ProcedureType = 'PP'
																								AND i.ChartAuditActionTypeCode = 5
																								AND pba.ChartId = c.CHART_ID)) x
							   ORDER BY Auditor1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProcDel_Action_Post
			  , (SELECT STUFF((SELECT	'; ' + Auditor1
							   FROM		(SELECT CASE
													WHEN LEN(i.CptCode) > 0
														 AND LEN(i.Modifier) > 0
														 AND LEN(i.Quantity) > 0
														THEN i.CptCode + ' / ' + i.Modifier + ' / ' + CAST(i.Quantity AS varchar)
													WHEN LEN(i.CptCode) > 0
														 AND LEN(i.Quantity) > 0
														THEN i.CptCode + ' / ' + CAST(i.Quantity AS varchar)
												END AS Auditor1
										 FROM	ChartPostBillAudit pba
											  , ChartAuditVersion cav
											  , ChartAuditProcedureVersionItem i
										 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
												AND cav.ChartAuditVersionId = i.ChartAuditVersionId
												AND pba.ChartPostBillAuditStatusTypeCode = 3
												AND cav.VersionNumber = 2
												AND i.ExcludeFromQA <> 1
												AND i.ProcedureType = 'PP'
												AND i.ChartAuditActionTypeCode = 3
												AND pba.ChartId = c.CHART_ID) x
							   ORDER BY Auditor1
							  FOR XML PATH('')), 1, 1, ''))								AS ProfProcAbs_Action_Post
			  , (SELECT COUNT(DISTINCT dx.CHART_ID)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.IS_CHIEF_COMPLAINT_CHANGE = 1
						AND dx.EXCLUDE_FROM_QA_REPORT <> 1)								AS DxChiefComplaintChanges
			  , (SELECT COUNT(DISTINCT dx.CHART_ID)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.IS_PRIMARY_DIAGNOSIS_CHANGE = 1
						AND dx.EXCLUDE_FROM_QA_REPORT <> 1)								AS DxPrimaryDxChanges
			  , (SELECT COUNT(DISTINCT dx.CHART_ID)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID)										AS DxChartsSubmitted
				-- Service			
			  , CASE
					WHEN sa.EVALUATE_PHYSICIAN_PROCEDURES = 1
						THEN 'Y'
					ELSE 'N'
				END																		AS ProfProcService
			  , CASE
					WHEN sa.PERFORM_DIAGNOSIS_CODING = 1
						THEN 'Y'
					ELSE 'N'
				END																		AS DxService

				-- Actions			
			  , (SELECT COUNT(*)
				 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pr WITH (NOLOCK)
				 WHERE	c.CHART_ID = pr.CHART_ID
						AND pr.PROCEDURE_TYPE = 'PP'
						AND pr.ACTION <> ''
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS ProfProcActions
			  , (SELECT COUNT(*)
				 FROM	#CHART_QA_SCORECARD_DIAGNOSIS_AUDIT_ACTION dx WITH (NOLOCK)
				 WHERE	c.CHART_ID = dx.CHART_ID
						AND dx.ACTION <> ''
						AND EXCLUDE_FROM_QA_REPORT <> 1)								AS DxActions

				-- Post Attempted and Action
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND pba.ChartId = c.CHART_ID)									AS ProfProcAttempted_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND pba.ChartId = c.CHART_ID)									AS DxAttempted_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditProcedureVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ProcedureType = 'PP'
						AND i.ChartAuditActionTypeCode <> 4
						AND pba.ChartId = c.CHART_ID)									AS ProfProcActions_Post
			  , (SELECT COUNT(*)
				 FROM	ChartPostBillAudit pba
					  , ChartAuditVersion cav
					  , ChartAuditDiagnosisVersionItem i
				 WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId
						AND cav.ChartAuditVersionId = i.ChartAuditVersionId
						AND pba.ChartPostBillAuditStatusTypeCode = 3
						AND cav.VersionNumber = 2
						AND i.ExcludeFromQA <> 1
						AND i.ChartAuditActionTypeCode <> 4
						AND pba.ChartId = c.CHART_ID)									AS DxActions_Post
		INTO	#Scorecard_1
		FROM	[#ChartSubset]					  c WITH (NOLOCK)
				LEFT OUTER JOIN USER_PROFILE	  up WITH (NOLOCK)
					ON c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
				LEFT OUTER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK)
					ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID;

		--      select * from [#ChartSubset] 
		--		select * from #Scorecard_1

		-- *****************************************************************************************************************************************
		-- Auditor Grid Temp 
		SELECT	CHART_ID
			  , ProfProcService
			  , ProfProcAttempted
			  , ProfProcActions
			  , CASE
					WHEN s.ProfProcAdditions > 0
						THEN CAST(s.ProfProcAdditions AS varchar(5)) + ' Additions - ' + CAST(s.ProfProcAdd_Action AS varchar(200))
				END				 AS ProfProcAdditionError
			  , CASE
					WHEN s.ProfProcRevisions > 0
						THEN CAST(s.ProfProcRevisions AS varchar(5)) + ' Revisions - ' + CAST(s.ProfProcRev_Action AS varchar(200))
				END				 AS ProfProcRevisionError
			  , CASE
					WHEN s.ProfProcDeletions > 0
						THEN CAST(s.ProfProcDeletions AS varchar(5)) + ' Deletions - ' + CAST(s.ProfProcDel_Action AS varchar(200))
				END				 AS ProfProcDeletionError
			  , CASE
					WHEN s.ProfProcAbstract > 0
						THEN CAST(s.ProfProcAbstract AS varchar(5)) + ' Abstract - ' + CAST(s.ProfProcAbs_Action AS varchar(200))
				END				 AS ProfProcAbstractError
			  , CASE
					WHEN s.ProfProcAdditions_Post > 0
						THEN CAST(s.ProfProcAdditions_Post AS varchar(5)) + ' Additions_Post - ' + CAST(s.ProfProcAdd_Action_Post AS varchar(200))
				END				 AS ProfProcAdditionPostError
			  , CASE
					WHEN s.ProfProcRevisions_Post > 0
						THEN CAST(s.ProfProcRevisions_Post AS varchar(5)) + ' Revisions_Post - ' + CAST(s.ProfProcRev_Action_Post AS varchar(200))
				END				 AS ProfProcRevisionPostError
			  , CASE
					WHEN s.ProfProcDeletions_Post > 0
						THEN CAST(s.ProfProcDeletions_Post AS varchar(5)) + ' Deletions_Post - ' + CAST(s.ProfProcDel_Action_Post AS varchar(200))
				END				 AS ProfProcDeletionPostError
			  , CASE
					WHEN s.ProfProcAbstract_Post > 0
						THEN CAST(s.ProfProcAbstract_Post AS varchar(5)) + ' Abstract_Post - ' + CAST(s.ProfProcAbs_Action_Post AS varchar(200))
				END				 AS ProfProcAbstractPostError
			  , s.ProfProcNoChange_Post
			  , s.ProfProcAttempted_Post
			  , s.ProfProcActions_Post
			  , DxService
			  , DxAttempted
			  , DxActions
			  , CASE
					WHEN s.DxAdditions > 0
						THEN CAST(s.DxAdditions AS varchar(5)) + ' Additions - ' + CAST(s.DxAdd_Action AS varchar(200))
				END				 AS DxAdditionError
			  , CASE
					WHEN s.DxRevisions > 0
						THEN CAST(s.DxRevisions AS varchar(5)) + ' Revisions - ' + CAST(s.DxRev_Action AS varchar(200))
				END				 AS DxRevisionError
			  , CASE
					WHEN s.DxDeletions > 0
						THEN CAST(s.DxDeletions AS varchar(5)) + ' Deletions - ' + CAST(s.DxDel_Action AS varchar(200))
				END				 AS DxDeletionError
			  , CASE
					WHEN s.DxAbstract > 0
						THEN CAST(s.DxAbstract AS varchar(5)) + ' Abstract'
				END				 AS DxAbstractError
			  , CASE
					WHEN s.DxAdditions_Post > 0
						THEN CAST(s.DxAdditions_Post AS varchar(5)) + ' Additions_Post - ' + CAST(s.DxAdd_Action_Post AS varchar(200))
				END				 AS DxAdditionPostError
			  , CASE
					WHEN s.DxRevisions_Post > 0
						THEN CAST(s.DxRevisions_Post AS varchar(5)) + ' Revisions_Post - ' + CAST(s.DxRev_Action_Post AS varchar(200))
				END				 AS DxRevisionPostError
			  , CASE
					WHEN s.DxDeletions_Post > 0
						THEN CAST(s.DxDeletions_Post AS varchar(5)) + ' Deletions_Post - ' + CAST(s.DxDel_Action_Post AS varchar(200))
				END				 AS DxDeletionPostError
			  , CASE
					WHEN s.DxAbstract_Post > 0
						THEN CAST(s.DxAbstract_Post AS varchar(5)) + ' Abstract_Post'
				END				 AS DxAbstractPostError
			  , s.DxNoChange_Post
			  , s.DxAttempted_Post
			  , s.DxActions_Post
		INTO	#AuditGrid1
		FROM	#Scorecard_1 s;

		-- select * from #AuditGrid1

		-- *****************************************************************************************************************************************
		-- Auditor Notes Temp
		SELECT	CHART_ID
			  , CASE
					WHEN LEN(DEMOGRAPHIC_AUDIT_COMMENT) > 0
						THEN COALESCE('Demographics: (1st Auditor) ' + DEMOGRAPHIC_AUDIT_COMMENT + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_DEMOGRAPHIC_AUDIT_COMMENT + ';', '')
						  ELSE ''
					  END AS Demo
			  , CASE
					WHEN LEN(PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT) > 0
						THEN COALESCE('Phys E/M: (1st Auditor) ' + PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_PHYSICIAN_SERVICE_LEVEL_AUDIT_COMMENT + ';', '')
						  ELSE ''
					  END PhyService
			  , CASE
					WHEN LEN(FACILITY_SERVICE_LEVEL_AUDIT_COMMENT) > 0
						THEN COALESCE('Fac Svcs: (1st Auditor) ' + FACILITY_SERVICE_LEVEL_AUDIT_COMMENT + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_FACILITY_SERVICE_LEVEL_AUDIT_COMMENT + ';', '')
						  ELSE ''
					  END AS FacService
			  , CASE
					WHEN LEN(FACILITY_PROCEDURES_AUDIT_COMMENT) > 0
						THEN COALESCE('Fac Proc: (1st Auditor) ' + FACILITY_PROCEDURES_AUDIT_COMMENT + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_FACILITY_PROCEDURES_AUDIT_COMMENT + ';', '')
						  ELSE ''
					  END AS FacProc
			  , CASE
					WHEN LEN(PHYSICIAN_PROCEDURES_AUDIT_COMMENT) > 0
						THEN COALESCE('Phy Proc: (1st Auditor) ' + PHYSICIAN_PROCEDURES_AUDIT_COMMENT + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_PHYSICIAN_PROCEDURES_AUDIT_COMMENT + ';', '')
						  ELSE ''
					  END AS PhyProc
			  , CASE
					WHEN LEN(DIAGNOSIS_CODING_AUDIT_COMMENT) > 0
						THEN COALESCE('Diagnosis: (1st Auditor) ' + DIAGNOSIS_CODING_AUDIT_COMMENT + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_DIAGNOSIS_CODING_AUDIT_COMMENT + ';', '')
						  ELSE ''
					  END AS Diagnosis
			  , CASE
					WHEN LEN(INFUSION_INJECTION_AUDIT_COMMENT) > 0
						THEN COALESCE('Inf/Inj: (1st Auditor) ' + INFUSION_INJECTION_AUDIT_COMMENT + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_INFUSION_INJECTION_AUDIT_COMMENT + ';', '')
						  ELSE ''
					  END AS InfInj
			  , CASE
					WHEN LEN(AUDITOR_REVIEW_FEEDBACK) > 0
						THEN COALESCE('General: (1st Auditor) ' + AUDITOR_REVIEW_FEEDBACK + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_AUDITOR_REVIEW_FEEDBACK) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_AUDITOR_REVIEW_FEEDBACK + ';', '')
						  ELSE ''
					  END AS General
			  , CASE
					WHEN LEN(ANESTHESIA_CODING_AUDIT_COMMENT) > 0
						THEN COALESCE('Anesthesia: (1st Auditor) ' + ANESTHESIA_CODING_AUDIT_COMMENT + ';', '')
					ELSE ''
				END + CASE
						  WHEN LEN(SECOND_LEVEL_QA_ANESTHESIA_CODING_AUDIT_COMMENT) > 0
							  THEN COALESCE('(2nd Auditor) ' + SECOND_LEVEL_QA_ANESTHESIA_CODING_AUDIT_COMMENT + ';', '')
						  ELSE ''
					  END AS Anesthesia
			  , CASE
					WHEN (LEN(OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT) > 0
						  OR LEN(OBSERVATION_PROCEDURES_AUDIT_COMMENT) > 0
						  OR LEN(OBSERVATION_AUDITOR_REVIEW_FEEDBACK) > 0)
						THEN COALESCE('Obs: (1st Auditor) ' + OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT + OBSERVATION_PROCEDURES_AUDIT_COMMENT + OBSERVATION_AUDITOR_REVIEW_FEEDBACK + ';', '')
					ELSE ''
				END
				+ CASE
					  WHEN (LEN(SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT) > 0
							OR	LEN(SECOND_LEVEL_QA_OBSERVATION_FACILITY_PROCEDURE_AUDIT_COMMENT) > 0
							OR	LEN(SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK) > 0)
						  THEN COALESCE(
								   '(2nd Auditor) ' + SECOND_LEVEL_QA_OBSERVATION_INFUSION_INJECTION_AUDIT_COMMENT + SECOND_LEVEL_QA_OBSERVATION_FACILITY_PROCEDURE_AUDIT_COMMENT
								   + SECOND_LEVEL_QA_OBSERVATION_AUDITOR_REVIEW_FEEDBACK + ';', '')
					  ELSE ''
				  END	  AS Obs
		INTO	#AuditNotes1
		FROM	[#ChartSubset];

		-- Post Bill Audit Comments
		SELECT	cs.CHART_ID
			  , (SELECT DISTINCT
						'FacilityProcedure: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 1 -- FacilityProcedure
				 WHERE	ca.ChartId = cs.CHART_ID) AS FacProc
			  , (SELECT DISTINCT
						'PhysicianProcedure: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 2 -- PhysicianProcedure
				 WHERE	ca.ChartId = cs.CHART_ID) AS PhyProc
			  , (SELECT DISTINCT
						'Observation: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 3 -- ObservationProcedure
				 WHERE	ca.ChartId = cs.CHART_ID) AS Obs
			  , (SELECT DISTINCT
						'InfusionInjection: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 4 -- InfusionInjectionProcedure
				 WHERE	ca.ChartId = cs.CHART_ID) AS InfInj
			  , (SELECT DISTINCT
						'FacilityService: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 5 -- FacilityService
				 WHERE	ca.ChartId = cs.CHART_ID) AS FacService
			  , (SELECT DISTINCT
						'PhysicianService: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 6 -- PhysicianService
				 WHERE	ca.ChartId = cs.CHART_ID) AS PhyService
			  , (SELECT DISTINCT
						'Demographics: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 7 -- Demo
				 WHERE	ca.ChartId = cs.CHART_ID) AS Demo
			  , (SELECT DISTINCT
						'Anesthesia: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 9 -- Anesthesia
				 WHERE	ca.ChartId = cs.CHART_ID) AS Anesthesia
			  , (SELECT DISTINCT
						'Diagnosis: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 10	-- Dx
				 WHERE	ca.ChartId = cs.CHART_ID) AS Diagnosis
			  , (SELECT DISTINCT
						'General: ' + c.Comment + '; '
				 FROM	ChartPostBillAudit					ca
						INNER JOIN ChartAuditVersion		av
							ON av.ChartAuditId = ca.ChartPostBillAuditId
							   AND	av.VersionNumber = 2
						INNER JOIN ChartAuditVersionComment c
							ON c.ChartAuditVersionId = av.ChartAuditVersionId
							   AND	c.ChartAuditSectionTypeCode = 11	-- General
				 WHERE	ca.ChartId = cs.CHART_ID) AS General
		INTO	#AuditNotes2
		FROM	[#ChartSubset] cs;

		-- select * from #AuditNotes2

		-- *****************************************************************************************************************************************
		--calculations
		SELECT	(SELECT NAME
				 FROM	FACILITY
				 WHERE	FACILITY_ID = s.FACILITY_ID)										 AS Facility
			  , s.CHART_ID
			  , s.FACILITY_CHART_ID
			  , s.USER_PROFILE_ID
			  , s.CoderName
			  , 'Coder ' + CAST(DENSE_RANK() OVER (ORDER BY s.User_Profile_ID) AS varchar)	 AS HiddenName
			  , s.TIME_OF_SERVICE
			  , s.COMPLETION_DATE
			  , s.AuditReasonCode
			  , (SELECT up1.LAST_NAME + ', ' + up1.FIRST_NAME
				 FROM	USER_PROFILE AS up1
				 WHERE	up1.USER_PROFILE_ID = s.APPROVED_BY_USER_PROFILE_ID)				 Auditor1
			  , (SELECT up2.LAST_NAME + ', ' + up2.FIRST_NAME
				 FROM	USER_PROFILE AS up2
				 WHERE	up2.USER_PROFILE_ID = s.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID) Auditor2
			  , (SELECT up3.LAST_NAME + ', ' + up3.FIRST_NAME
				 FROM	USER_PROFILE AS up3
				 WHERE	up3.USER_PROFILE_ID = s.POST_BILL_AUDIT_COMPLETED_BY_USER_ID)		 AuditorPost
			  , s.Audit1
			  , s.Audit2
			  , s.AuditPBA
			  , CASE
					WHEN s.Audit1 = 1
						THEN s.APPROVED_DATE
					ELSE NULL
				END																			 AS APPROVED_DATE
			  , CASE
					WHEN s.Audit2 = 1
						THEN s.SECOND_LEVEL_QA_APPROVED_DATETIME
					ELSE NULL
				END																			 AS SECOND_LEVEL_APPROVED_DATE
			  , CASE
					WHEN s.AuditPBA = 1
						THEN s.POST_BILL_AUDIT_COMPLETED
					ELSE NULL
				END																			 AS POST_BILL_AUDIT_DATE
			  , fp.LAST_NAME + ', ' + fp.FIRST_NAME											 AS Provider
			  , s.ProfProc_CoderOrig
			  , s.ProfProc_Orig_Post
			  , s.Dx_CoderOrig
			  , s.Dx_Orig_Post
		INTO	#Scorecard_2
		FROM	#Scorecard_1					s
				LEFT JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK)
					ON (CASE
							WHEN s.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
								 OR s.PROVIDER_EVAL_PERFORMED_BY_IND = 0
								THEN s.PHYSICIAN_ID
							WHEN s.PROVIDER_EVAL_PERFORMED_BY_IND = 1
								THEN s.NURSE_PRACTITIONER_ID
						END) = fp.FACILITY_PROF_ID;

		-- select * from #Scorecard_2

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

		-- *********************************************************************

		-- Output
		SELECT	s.CHART_ID
			  , s.Facility
			  , s.CoderName
			  , s.Auditor1
			  , s.Auditor2
			  , s.AuditorPost
			  , (SELECT Description
				 FROM	ChartPostBillAuditReasonTypeCode
				 WHERE	ChartPostBillAuditReasonTypeCode = s.AuditReasonCode) AS AuditReason
			  , s.FACILITY_CHART_ID											  AS Chart_Identifier
			  , s.TIME_OF_SERVICE
			  , s.APPROVED_DATE
			  , s.SECOND_LEVEL_APPROVED_DATE
			  , s.POST_BILL_AUDIT_DATE
			  , s.Provider
			  , p.PQRS_MEASURES_NUMBER										  AS PQRS_MEASURES_NUMBER
			  , p.BILLING_CODE
			  , p.PQRS_Description

				-- *********
				-- ProProc
			  , ISNULL(s.ProfProc_CoderOrig, '-')							  AS ProfProc_CoderOrig
			  , (SELECT CASE
							WHEN ProfProcService = 'N'
								THEN '-'
							WHEN ProfProcService = 'Y'
								 AND ProfProcAttempted = 0
								THEN '-'
							WHEN (ProfProcService = 'Y'
								  AND	ProfProcActions > 0)
								THEN COALESCE(ProfProcAdditionError + ';', '') + COALESCE(ProfProcRevisionError + ';', '') + COALESCE(ProfProcDeletionError + ';', '')
									 + COALESCE(ProfProcAbstractError + ';', '')
							WHEN (ProfProcService = 'Y'
								  AND	ProfProcActions = 0
								  AND	ProfProcAttempted > 0)
								THEN 'Correct'
						END
				 FROM	#AuditGrid1
				 WHERE	CHART_ID = s.CHART_ID)								  AS ProfProcError
			  , ISNULL(s.ProfProc_Orig_Post, '-')							  AS ProfProc_Orig_Post
			  , (SELECT CASE
							WHEN ProfProcService = 'N'
								THEN '-'
							WHEN ProfProcService = 'Y'
								 AND ProfProcAttempted_Post = 0
								THEN '-'
							WHEN (ProfProcService = 'Y'
								  AND	ProfProcAttempted_Post > 0
								  AND	ProfProcActions_Post > 0)
								THEN COALESCE(ProfProcAdditionPostError + ';', '') + COALESCE(ProfProcRevisionPostError + ';', '') + COALESCE(ProfProcDeletionPostError + ';', '')
									 + COALESCE(ProfProcAbstractPostError + ';', '')
							WHEN (ProfProcService = 'Y'
								  AND	ProfProcActions_Post = 0
								  AND	ProfProcAttempted_Post > 0)
								THEN 'Correct'
						END
				 FROM	#AuditGrid1
				 WHERE	CHART_ID = s.CHART_ID)								  AS ProfProcError_Post

				-- *********
				-- Dx
			  , ISNULL(s.Dx_CoderOrig, '-')									  AS Dx_CoderOrig
			  , (SELECT CASE
							WHEN DxService = 'N'
								THEN '-'
							WHEN DxService = 'Y'
								 AND DxAttempted = 0
								THEN '-'
							WHEN (DxService = 'Y' AND DxActions	  > 0)
								THEN COALESCE(DxAdditionError + ';', '') + COALESCE(DxRevisionError + ';', '') + COALESCE(DxDeletionError + ';', '') + COALESCE(DxAbstractError + ';', '')
							WHEN (DxService = 'Y'
								  AND	DxActions = 0
								  AND	DxAttempted > 0)
								THEN 'Correct'
						END
				 FROM	#AuditGrid1
				 WHERE	CHART_ID = s.CHART_ID)								  AS DxError
			  , ISNULL(s.Dx_Orig_Post, '-')									  AS Dx_Orig_Post
			  , (SELECT CASE
							WHEN DxService = 'N'
								THEN '-'
							WHEN DxService = 'Y'
								 AND DxAttempted_Post = 0
								THEN '-'
							WHEN (DxService = 'Y'
								  AND	DxAttempted_Post > 0
								  AND	DxActions_Post > 0)
								THEN COALESCE(DxAdditionPostError + ';', '') + COALESCE(DxRevisionPostError + ';', '') + COALESCE(DxDeletionPostError + ';', '')
									 + COALESCE(DxAbstractPostError + ';', '')
							WHEN (DxService = 'Y'
								  AND	DxActions_Post = 0
								  AND	DxAttempted_Post > 0)
								THEN 'Correct'
						END
				 FROM	#AuditGrid1
				 WHERE	CHART_ID = s.CHART_ID)								  AS DxError_Post

				-- *********
				-- Notes
			  , (SELECT COALESCE(Demo, '') + COALESCE(PhyService, '') + COALESCE(FacService, '') + COALESCE(FacProc, '') + COALESCE(PhyProc, '') + COALESCE(Diagnosis, '') + COALESCE(InfInj, '')
						+ COALESCE(General, '') + COALESCE(Anesthesia, '') + COALESCE(Obs, '') AS AuditNotes
				 FROM	#AuditNotes1
				 WHERE	CHART_ID = s.CHART_ID)								  AS AuditNotes
			  , (SELECT COALESCE(Demo, '') + COALESCE(PhyService, '') + COALESCE(FacService, '') + COALESCE(FacProc, '') + COALESCE(PhyProc, '') + COALESCE(Diagnosis, '') + COALESCE(InfInj, '')
						+ COALESCE(General, '') + COALESCE(Anesthesia, '') + COALESCE(Obs, '') AS AuditNotes
				 FROM	#AuditNotes2
				 WHERE	CHART_ID = s.CHART_ID)								  AS PostAuditNotes
			  , CASE
					WHEN s.Audit1 = 1
						 OR s.Audit2 = 1
						 OR s.AuditPBA = 1
						THEN 1
					ELSE 0
				END															  Audited
		FROM	#Scorecard_2	 s
				INNER JOIN #PQRS p
					ON s.CHART_ID = p.CHART_ID	-- only records with PQRS
		WHERE	CASE -- exclude records with completion date 10/1-10/7 with Billing Code of 99999
					WHEN (CAST(s.COMPLETION_DATE AS date) BETWEEN '10/01/2024' AND '10/07/2024'
						  AND	p.BILLING_CODE <> '99999')
						THEN 1
					WHEN CAST(s.COMPLETION_DATE AS date) <= '10/01/2024'
						THEN 1
					WHEN CAST(s.COMPLETION_DATE AS date) >= '10/07/2024'
						THEN 1
				END = 1;

	--END
	END;
GO
