SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[rpt_PQRS_MIPS_QUALITY_DETAIL_REPORT] 
                                                                  @ReportUser  int
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
		--    @DateType INT = 1, -- 0 Approved, 1 DOS, 2 Sent, 3 PostAudit
		--	@StartDate DATETIME = '02/11/2024',
		--	@EndDate DATETIME   = '02/13/2024',
			

		--	@COMPANY_ID  VARCHAR(MAX) = '296', 
		--	@FACILITY_ID VARCHAR(MAX) = '-1', -- '2639, 2640, 2641, 2642, 2643, 2644, 2645, 2646',

		--	@CUID        VARCHAR(MAX) = '-1', -- 15849
		--	@TimeZone VARCHAR(50) =	'Central Daylight Time'   --'India Standard Time', 	'Central Daylight Time'			
		--	;

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
		DECLARE 		
			    @AllFacilities bit		= IIF(@FACILITY_ID LIKE '%-1%', 1, 0)
			  , @AllUsers	   bit		= IIF(@CUID LIKE '%-1%', 1, 0)
			  , @Today		   datetime = GETDATE();

			  
		

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
		DROP TABLE IF EXISTS #Chart_Prefilter;
		DROP TABLE IF EXISTS #AuditNotes1;
		DROP TABLE IF EXISTS #AuditNotes2;

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
						
						and sa.company_id = @COMPANY_ID

			
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
	
	
	-- *************************************************************************
		-- Parameter Check
		-- Limits the parameters set by Report User

declare @CNT_Facility int = (select count(*) from #AuthorizedFacilities);
declare @CNT_CUID int = (SELECT count(*) FROM #coder);

-- If Date Range Exceeds 31 Days
IF (datediff(day,@StartDate,@EndDate) > 31 ) 
BEGIN
SELECT	'' AS Facility
		,0	 as CHART_ID
		,'' as FACILITY_CHART_ID
		,0   as USER_PROFILE_ID
		,''	 as CoderName
		,''  as HiddenName
		,''  as TIME_OF_SERVICE
		,''  as COMPLETION_DATE
		,''  as AuditReasonCode
	    ,''  as AuditReason
		,''  as Auditor1
		,''  as Auditor2
	    ,''  as AuditorPost
        ,0   as Coded
		,0   as Audit1
	    ,0   as Audit2
	    ,0   as AuditPBA
		,0   as Audited
		,''  as APPROVED_DATE
		,''	 as SECOND_LEVEL_APPROVED_DATE
		,''  as POST_BILL_AUDIT_DATE
		,''  as AuditDate
		,''  as Provider
		,''  as AuditCategory		
	    ,''  as PreviousCode	
	    ,''  as [Action]        
	    ,''  as AuditorCode	
	    ,'' as CPT_CODE 
	    ,'' as BILLING_CODE
	    ,'' as PQRS_Description
	    ,'' as PQRS_MEASURES_NUMBER
   	   ,0 as Correct
	   ,0 as Revision
	   ,0 as ProfProcAdditions
	   ,0 as ProfProcRevisions
	   ,0 as ProfProcDeletions
	   ,0 as ProfProcCorrect
	   ,0 as ProfProc_N
       ,0 as ProfProc_D
       ,0 as ProfProc_Total
       ,datediff(day,@StartDate,@EndDate)
end;




-- If Date Range Exceeds 7 Days with Multiple Coders
ELSE
IF (
    datediff(day,@StartDate,@EndDate) >= 7 
AND ( '-1' in (@CUID) OR @CNT_CUID > 1 ) 
   ) 
BEGIN
SELECT	'' AS Facility
		,0	 as CHART_ID
		,'' as FACILITY_CHART_ID
		,0   as USER_PROFILE_ID
		,''	 as CoderName
		,''  as HiddenName
		,''  as TIME_OF_SERVICE
		,''  as COMPLETION_DATE
		,''  as AuditReasonCode
	    ,''  as AuditReason
		,''  as Auditor1
		,''  as Auditor2
	    ,''  as AuditorPost
        ,0   as Coded
		,0   as Audit1
	    ,0   as Audit2
	    ,0   as AuditPBA
		,0   as Audited
		,''  as APPROVED_DATE
		,''	 as SECOND_LEVEL_APPROVED_DATE
		,''  as POST_BILL_AUDIT_DATE
		,''  as AuditDate
		,''  as Provider
		,''  as AuditCategory		
	    ,''  as PreviousCode	
	    ,''  as [Action]        
	    ,''  as AuditorCode	
	    ,'' as CPT_CODE 
	    ,'' as BILLING_CODE
	    ,'' as PQRS_Description
	    ,'' as PQRS_MEASURES_NUMBER
   	   ,0 as Correct
	   ,0 as Revision
	   ,0 as ProfProcAdditions
	   ,0 as ProfProcRevisions
	   ,0 as ProfProcDeletions
	   ,0 as ProfProcCorrect
	   ,0 as ProfProc_N
       ,0 as ProfProc_D
       ,0 as ProfProc_Total
       ,datediff(day,@StartDate,@EndDate)
end;

ELSE	
BEGIN 

    -- *************************************************************************			 

		SELECT	CHART_ID
		INTO	#Chart_Prefilter
		FROM	dbo.CHART c
		WHERE	c.COMPLETED_BY_USER_PROFILE_ID IN (SELECT USER_PROFILE_ID FROM #coder) 
				AND c.FACILITY_ID IN (SELECT FACILITY_ID FROM #AuthorizedFacilities)
				AND c.CHART_STATUS_ID <> 6 -- 6	Removed 				
				;





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
		, c.SERVICE_AGREEMENT_ID
		, c.TIME_OF_SERVICE

			  , c.FACILITY_ID
			  
			  , c.FACILITY_CHART_ID
			  , c.COMPLETED_BY_USER_PROFILE_ID
			  , c.COMPLETION_DATE
			  , c.PATIENT_DISPOSITION_ID
			  , c.MEDICAL_RECORD_NUM
			  
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
						 




-- **********************************************************************

-- Audit/Post Bill Audit Comment Temp Tables

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
		-- select * from #ChartSubset




-- **********************************************************************
-- Audit Data

DROP TABLE IF EXISTS #Audit_1;

create table #Audit_1
(					
	  chart_ID	    int	
	, Category 		varchar(10)
	, PreviousCode	varchar(10)
	, Action        varchar(20)
	, AuditorCode	varchar(10)
	, ExcludeFromQA int
)					
					

-- Post Bill Audit - Revision, Abstract, No Change,  Deletion 
INSERT INTO #Audit_1		
SELECT 
pba.ChartId, 
'Post' as Category,
i.CptCode as PreviousCode,
( select description from [dbo].[ChartAuditActionTypeCode] where ChartAuditActionTypeCode = i2.ChartAuditActionTypeCode) Action,
i2.cptcode as AuditorCode,
ISNULL(i2.ExcludeFromQA, 0) as ExcludeFromQA

FROM 
ChartPostBillAudit pba, 
ChartAuditVersion cav, 
ChartAuditProcedureVersionItem i, 
ChartAuditProcedureVersionItem i2 
WHERE	pba.ChartPostBillAuditId = cav.ChartAuditId	
AND cav.ChartAuditVersionId = i.ChartAuditVersionId 
AND pba.ChartPostBillAuditStatusTypeCode = 3 -- PBAComplete
-- AND ISNULL(i2.ExcludeFromQA, 0) = 0
AND i.ProcedureType = 'PP' 
and i2.PrevChartAuditProcedureVersionItemId = i.ChartAuditProcedureVersionItemId
and i2.ChartAuditActionTypeCode in ( 1, 3, 4, 5 ) -- 1 Revision, 3 Abstract, 4 No Change, 5 Deletion
AND pba.ChartId in ( select chart_id from #ChartSubset c ) 



-- Post Bill Audit - Additions Only 
INSERT INTO #Audit_1
select 
pba.ChartId, 
'Post' as Category,
'' as PreviousCode,
( select description from [dbo].[ChartAuditActionTypeCode] where ChartAuditActionTypeCode = i.ChartAuditActionTypeCode) Action,
i.cptcode as AuditorCode,
ISNULL(i.ExcludeFromQA, 0) as ExcludeFromQA
FROM 
ChartPostBillAudit pba, 
ChartAuditVersion cav, 
ChartAuditProcedureVersionItem i 
WHERE 
pba.ChartPostBillAuditId = cav.ChartAuditId 
AND cav.ChartAuditVersionId = i.ChartAuditVersionId 
AND pba.ChartPostBillAuditStatusTypeCode = 3 -- PBAComplete
AND cav.VersionNumber = 2 
-- AND ISNULL(i.ExcludeFromQA, 0) = 0
AND i.ProcedureType = 'PP' 
AND i.ChartAuditActionTypeCode = 2 -- Additions
AND pba.ChartId in ( select chart_id from #ChartSubset c ) 



INSERT INTO #Audit_1 
 select  
 chart_id, 
 'Pre' as Category,
 coder_cpt_code as PreviousCode, 
 case when [action] = 'A' then 'Added'
      when [action] = 'C' then 'Abstract Change'
      when [action] = 'D' then 'Deleted'
      when [action] = 'R' then 'Revised'
	  End as Action, 
 auditor_cpt_code as AuditorCode, 
 pro.EXCLUDE_FROM_QA_REPORT as ExcludeFromQA
 FROM	CHART_QA_SCORECARD_PROCEDURE_AUDIT_ACTION pro 
			   WHERE	pro.CHART_ID in ( select chart_id from #ChartSubset c ) 
			   AND pro.PROCEDURE_TYPE = 'PP'; 
			   -- AND pro.EXCLUDE_FROM_QA_REPORT = 0 



-- select * from #Audit_1 

-- **********************************************************************
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

-- select * from #MIPS_1


-- New PQRS Step 2

	IF OBJECT_ID('TempDB..#PQRS_1', 'U') IS NOT NULL
			DROP TABLE #PQRS_1;

select 
Service_Agreement_ID, 
Description,
CPT_Code,
Billing_Code,
Effective_Date,
Expiration_Date
INTO	#PQRS_1
 from CHARGE_MASTER cm
WHERE	
service_agreement_id in ( select distinct service_agreement_id from #ChartSubset ) 
and CHARGE_MASTER_USAGE_CODE = 9 -- PQRS Option 




		-- PQRS Step 3
		IF OBJECT_ID('TempDB..#PQRS_2', 'U') IS NOT NULL
			DROP TABLE #PQRS_2;

		SELECT	        t2.SERVICE_AGREEMENT_ID
                      , t2.CPT_CODE				
					  , t2.BILLING_CODE				
					  , t2.DESCRIPTION
					  , t2.Effective_Date as CM_Effective_Date
                      , t2.Expiration_Date as CM_Expiration_Date

					  , t2.PQRS_MEASURES_NUMBER					
					  , t2.cms_pqri_measure_id
					--  , t2.MIPS_Effective_Date
					--  , t2.MIPS_Expiration_Date
		INTO	#PQRS_2
		FROM	(SELECT DISTINCT
		                c.SERVICE_AGREEMENT_ID
                      , c.CPT_CODE				
					  , c.BILLING_CODE				
					  , c.DESCRIPTION
					  , c.Effective_Date
                      , c.Expiration_Date

					  , m.PQRS_Code AS PQRS_MEASURES_NUMBER						
					  , m.cms_pqri_measure_id
				--	  , m.[Effective_Date]  as MIPS_Effective_Date
				--	  , ISNULL(m.Expiration_Date, '12/31/2099') as MIPS_Expiration_Date
				 FROM	#PQRS_1			   c
						INNER JOIN #MIPS_1 m
							ON c.BILLING_CODE = m.CODE
							   
				 UNION
				 SELECT DISTINCT
						c.SERVICE_AGREEMENT_ID
                      , c.CPT_CODE
					  , c.BILLING_CODE				
					  , c.DESCRIPTION 
					  , c.Effective_Date
                      , c.Expiration_Date

					  , m.PQRS_Code AS PQRS_MEASURES_NUMBER						
					  , m.cms_pqri_measure_id
				--	  , m.[Effective_Date] as MIPS_Effective_Date
				--	  , ISNULL(m.Expiration_Date, '12/31/2099') as MIPS_Expiration_Date
				 FROM	#PQRS_1			   c
						INNER JOIN #MIPS_1 m ON	c.CPT_CODE = m.CODE


 				  ) t2;
				  
-- select * from #PQRS_2;
				
		
		
			IF OBJECT_ID('TempDB..#PQRS', 'U') IS NOT NULL
			DROP TABLE #PQRS;
													 
												 
	   	   select 
		   p.*,
		   sap.SERVICE_AGREEMENT_PQRS_ID,
		   sap.EFFECTIVE_DATE as SAP_EFFECTIVE_DATE,
		   ISNULL(sap.EXPIRATION_DATE, '12/31/2099') as SAP_EXPIRATION_DATE
		   INTO	#PQRS
		   FROM		#PQRS_2 p,
		   SERVICE_AGREEMENT_PQRS sap 
		   where 
		   p.SERVICE_AGREEMENT_ID = sap.SERVICE_AGREEMENT_ID
		   AND p.CMS_PQRI_MEASURE_ID = sap.CMS_PQRI_MEASURE_ID


-- Data Corrections/Adjustments


update #PQRS
set SAP_EXPIRATION_DATE = '2024-01-01 00:00:00.000'

where service_agreement_id = 2578
and cpt_code = 'V0704'
and CMS_PQRI_MEASURE_ID = 209;

update #PQRS
set SAP_EXPIRATION_DATE = '2024-01-01 00:00:00.000'

where service_agreement_id = 2588
and CMS_PQRI_MEASURE_ID = 210
and service_agreement_pqrs_id = 2541;




		-- *****************************************************************************************************************************************



 
-- Remove Non PQRS Records
-- Added Delete Statements 01/21/25

update #Audit_1 
set [Action] = 'No Change'
where [Action] Is Null



delete from  #Audit_1 
where Action = 'Added'
and AuditorCode not in ( select distinct CPT_Code from #PQRS);


delete from  #Audit_1 
where Action = 'Deleted'
and PreviousCode not in ( select distinct CPT_Code from #PQRS);

delete from  #Audit_1 
where Action = 'No Change'
and PreviousCode not in ( select distinct CPT_Code from #PQRS);

delete from  #Audit_1 
where Action = 'Abstract Change'
and AuditorCode not in ( select  distinct CPT_Code from #PQRS);

delete from  #Audit_1 
where Action = 'Revised'
and (
PreviousCode not in ( select  distinct CPT_Code from #PQRS)
and
AuditorCode not in ( select  distinct CPT_Code from #PQRS )
);



		-- *****************************************************************************************************************************************
-- ScoreCard ****		

DROP TABLE IF EXISTS #Scorecard_1;	

create table #Scorecard_1
(
ID                          INT IDENTITY NOT NULL PRIMARY KEY,
CHART_ID					int,
FACILITY_CHART_ID			varchar(20),
FACILITY_ID					int,
SERVICE_AGREEMENT_ID		int,
USER_PROFILE_ID				int,
CoderName					varchar(100),
TIME_OF_SERVICE				datetime,
COMPLETION_DATE				datetime,
PROVIDER_EVAL_PERFORMED_BY_IND	int,
PHYSICIAN_ID				int,
NURSE_PRACTITIONER_ID		int,
APPROVED_BY_USER_PROFILE_ID int,
SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID int,
POST_BILL_AUDIT_COMPLETED_BY_USER_ID        int,
Audit1						bit,
Audit2						bit,
AuditPBA					bit,
APPROVED_DATE				datetime,
SECOND_LEVEL_QA_APPROVED_DATETIME datetime,
POST_BILL_AUDIT_COMPLETED   datetime,
AuditDate					datetime,
AuditReasonCode             int,
Category 					varchar(10),
PreviousCode				varchar(10),
[Action]					varchar(20),
AuditorCode					varchar(10),
ExcludeFromQA				int
);


insert into #Scorecard_1		
		SELECT	
		        c.CHART_ID
			  , c.FACILITY_CHART_ID
			  , c.FACILITY_ID
			  , c.SERVICE_AGREEMENT_ID
			  , up.USER_PROFILE_ID
			  , up.LAST_NAME + ', ' + up.FIRST_NAME	AS CoderName
			  , c.TIME_OF_SERVICE
			  , c.COMPLETION_DATE
			  , c.PROVIDER_EVAL_PERFORMED_BY_IND
			  , c.PHYSICIAN_ID
			  , c.NURSE_PRACTITIONER_ID
			  , c.APPROVED_BY_USER_PROFILE_ID
			  , c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID
			  , c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID
			  , CASE WHEN c.START_QA_DATE IS NOT NULL  AND c.APPROVED_DATE IS NOT NULL AND c.APPROVED_BY_USER_PROFILE_ID <> 2  THEN 1 ELSE 0 END													AS Audit1
			  , CASE WHEN c.START_SECOND_LEVEL_QA_DATETIME IS NOT NULL AND c.SECOND_LEVEL_QA_APPROVED_DATETIME IS NOT NULL AND c.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID <> 2 THEN 1 ELSE 0	END	AS Audit2
			  , CASE WHEN c.POST_BILL_AUDIT_STARTED IS NOT NULL AND c.POST_BILL_AUDIT_COMPLETED IS NOT NULL AND c.POST_BILL_AUDIT_COMPLETED_BY_USER_ID IS NOT NULL THEN 1 ELSE 0 END				AS AuditPBA
			  , c.APPROVED_DATE
			  , c.SECOND_LEVEL_QA_APPROVED_DATETIME
			  , c.POST_BILL_AUDIT_COMPLETED

--			  -- When multi audits exist, get last date *** 
			  , CASE WHEN APPROVED_DATE > ISNULL(SECOND_LEVEL_QA_APPROVED_DATETIME, '01/01/1900')
						 AND APPROVED_DATE > ISNULL(POST_BILL_AUDIT_COMPLETED, '01/01/1900')
						THEN APPROVED_DATE
						WHEN SECOND_LEVEL_QA_APPROVED_DATETIME > ISNULL(APPROVED_DATE, '01/01/1900')
							 AND SECOND_LEVEL_QA_APPROVED_DATETIME > ISNULL(POST_BILL_AUDIT_COMPLETED, '01/01/1900')
						THEN SECOND_LEVEL_QA_APPROVED_DATETIME
						WHEN POST_BILL_AUDIT_COMPLETED > ISNULL(APPROVED_DATE, '01/01/1900')
							 AND POST_BILL_AUDIT_COMPLETED > ISNULL(SECOND_LEVEL_QA_APPROVED_DATETIME, '01/01/1900')
						THEN POST_BILL_AUDIT_COMPLETED
						ELSE c.TIME_OF_SERVICE
					END					   AS AuditDate
---- PBA Audit Reason *****
			  , (SELECT pba.ChartPostBillAuditReasonTypeCode FROM ChartPostBillAudit pba WHERE	pba.ChartPostBillAuditStatusTypeCode = 3 AND pba.ChartId = c.CHART_ID) AS AuditReasonCode


		
	,a1.Category 		
	,a1.PreviousCode	
	,isnull(a1.Action, 'No Change') as [Action]
	,a1.AuditorCode	
	,a1.ExcludeFromQA
		

		FROM	[#ChartSubset]					  c WITH (NOLOCK)
				LEFT OUTER JOIN USER_PROFILE	  up WITH (NOLOCK)
					ON c.COMPLETED_BY_USER_PROFILE_ID = up.USER_PROFILE_ID
				LEFT OUTER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK)
					ON c.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID
				
				LEFT OUTER JOIN	#Audit_1 a1 ON c.chart_id = a1.chart_id


		
		-- *****************************************************************************************************************************************
		--calculations

		DROP TABLE IF EXISTS #Scorecard_2;

		SELECT	ID,
		(SELECT NAME
				 FROM	FACILITY
				 WHERE	FACILITY_ID = s.FACILITY_ID)										 AS Facility
			  , s.CHART_ID
			  , s.FACILITY_CHART_ID
			  , s.USER_PROFILE_ID
			  , s.CoderName
--			  , 'Coder ' + CAST(DENSE_RANK() OVER (ORDER BY s.User_Profile_ID) AS varchar)	 AS HiddenName
			  , s.TIME_OF_SERVICE
			  , s.COMPLETION_DATE
			  , s.AuditReasonCode
			  , (SELECT Description
				 FROM	ChartPostBillAuditReasonTypeCode
				 WHERE	ChartPostBillAuditReasonTypeCode = s.AuditReasonCode) AS AuditReason
			  , (SELECT up1.LAST_NAME + ', ' + up1.FIRST_NAME
				 FROM	USER_PROFILE AS up1
				 WHERE	up1.USER_PROFILE_ID = s.APPROVED_BY_USER_PROFILE_ID)				 Auditor1
			  , (SELECT up2.LAST_NAME + ', ' + up2.FIRST_NAME
				 FROM	USER_PROFILE AS up2
				 WHERE	up2.USER_PROFILE_ID = s.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID) Auditor2
			  , (SELECT up3.LAST_NAME + ', ' + up3.FIRST_NAME
				 FROM	USER_PROFILE AS up3
				 WHERE	up3.USER_PROFILE_ID = s.POST_BILL_AUDIT_COMPLETED_BY_USER_ID)		 AuditorPost
              , 1 as Coded
			  , s.Audit1
			  , s.Audit2
			  , s.AuditPBA
			  , CASE WHEN s.Audit1 = 1 OR s.Audit2 = 1 OR s.AuditPBA = 1  THEN 1 ELSE 0 END Audited
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

				,AuditDate

					


			  , fp.LAST_NAME + ', ' + fp.FIRST_NAME											 AS Provider
			 
  	,s.Category as AuditCategory		
	,s.PreviousCode	
	,isnull(s.Action, 'No Change') as [Action]        
	,s.AuditorCode
	,s.ExcludeFromQA	

	,p.CPT_CODE 
	,p.BILLING_CODE
 	,p.Description as PQRS_Description		
	,p.PQRS_MEASURES_NUMBER

	,case 
	 when s.ExcludeFromQA = 1 then 1
	 when isnull(s.Action, 'No Change') = 'No Change' then 1 
	 else 0 end as Correct

	,case 
	 when s.ExcludeFromQA = 1 then 0
	 when isnull(s.Action, 'No Change') <> 'No Change' then 1 
	 else 0 end as Revision


 --   ,case when s.Action = 'Added' then 1 else 0 end as ProfProcAdditions
	--,case when s.Action = 'Revised' then 1 else 0 end as ProfProcRevisions
	--,case when s.Action = 'Deleted' then 1 else 0 end as ProfProcDeletions
	--,case when isnull(s.Action, 'No Change') = 'No Change' then 1 else 0 end as ProfProcCorrect

	

  	into #Scorecard_2
		FROM	#Scorecard_1					s
				LEFT JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK)
					ON (CASE
							WHEN s.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
								 OR s.PROVIDER_EVAL_PERFORMED_BY_IND = 0
								THEN s.PHYSICIAN_ID
							WHEN s.PROVIDER_EVAL_PERFORMED_BY_IND = 1
								THEN s.NURSE_PRACTITIONER_ID
						END) = fp.FACILITY_PROF_ID
				LEFT JOIN #PQRS p ON 
				 
				     p.CPT_CODE = s.AuditorCode
				 AND p.SERVICE_AGREEMENT_ID = s.SERVICE_AGREEMENT_ID
				 AND s.TIME_OF_SERVICE BETWEEN p.SAP_EFFECTIVE_DATE AND ISNULL(p.SAP_EXPIRATION_DATE, '12/31/2099')
				 AND s.TIME_OF_SERVICE BETWEEN p.CM_EFFECTIVE_DATE AND ISNULL(p.CM_EXPIRATION_DATE, '12/31/2099')
				 where s.[Action] <> 'Deleted' -- All records except deleted


insert into #Scorecard_2
SELECT	ID,
(SELECT NAME
				 FROM	FACILITY
				 WHERE	FACILITY_ID = s.FACILITY_ID)										 AS Facility
			  , s.CHART_ID
			  , s.FACILITY_CHART_ID
			  , s.USER_PROFILE_ID
			  , s.CoderName
			  --, 'Coder ' + CAST(DENSE_RANK() OVER (ORDER BY s.User_Profile_ID) AS varchar)	 AS HiddenName
			  , s.TIME_OF_SERVICE
			  , s.COMPLETION_DATE
			  , s.AuditReasonCode
			  , (SELECT Description
				 FROM	ChartPostBillAuditReasonTypeCode
				 WHERE	ChartPostBillAuditReasonTypeCode = s.AuditReasonCode) AS AuditReason
			  , (SELECT up1.LAST_NAME + ', ' + up1.FIRST_NAME
				 FROM	USER_PROFILE AS up1
				 WHERE	up1.USER_PROFILE_ID = s.APPROVED_BY_USER_PROFILE_ID)				 Auditor1
			  , (SELECT up2.LAST_NAME + ', ' + up2.FIRST_NAME
				 FROM	USER_PROFILE AS up2
				 WHERE	up2.USER_PROFILE_ID = s.SECOND_LEVEL_QA_APPROVED_BY_USER_PROFILE_ID) Auditor2
			  , (SELECT up3.LAST_NAME + ', ' + up3.FIRST_NAME
				 FROM	USER_PROFILE AS up3
				 WHERE	up3.USER_PROFILE_ID = s.POST_BILL_AUDIT_COMPLETED_BY_USER_ID)		 AuditorPost
              , 1 as Coded
			  , s.Audit1
			  , s.Audit2
			  , s.AuditPBA
			  , CASE WHEN s.Audit1 = 1 OR s.Audit2 = 1 OR s.AuditPBA = 1  THEN 1 ELSE 0 END Audited
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

				,AuditDate

					


			  , fp.LAST_NAME + ', ' + fp.FIRST_NAME											 AS Provider
			 
  	,s.Category as AuditCategory		
	,s.PreviousCode	
	,isnull(s.Action, 'No Change') as [Action]        
	,s.AuditorCode
	,s.ExcludeFromQA		

	,p.CPT_CODE 
	,p.BILLING_CODE
 	,p.Description as PQRS_Description	
	,p.PQRS_MEASURES_NUMBER

	,case 
	 when s.ExcludeFromQA = 1 then 1
	 when isnull(s.Action, 'No Change') = 'No Change' then 1 
	 else 0 end as Correct

	,case 
	 when s.ExcludeFromQA = 1 then 0
	 when isnull(s.Action, 'No Change') <> 'No Change' then 1 
	 else 0 end as Revision


 --   ,case when s.Action = 'Added' then 1 else 0 end as ProfProcAdditions
	--,case when s.Action = 'Revised' then 1 else 0 end as ProfProcRevisions
	--,case when s.Action = 'Deleted' then 1 else 0 end as ProfProcDeletions
	--,case when isnull(s.Action, 'No Change') = 'No Change' then 1 else 0 end as ProfProcCorrect

	

 	
		FROM	#Scorecard_1					s
				LEFT JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK)
					ON (CASE
							WHEN s.PROVIDER_EVAL_PERFORMED_BY_IND IS NULL
								 OR s.PROVIDER_EVAL_PERFORMED_BY_IND = 0
								THEN s.PHYSICIAN_ID
							WHEN s.PROVIDER_EVAL_PERFORMED_BY_IND = 1
								THEN s.NURSE_PRACTITIONER_ID
						END) = fp.FACILITY_PROF_ID
				LEFT JOIN #PQRS p ON 
				     p.CPT_CODE = s.PreviousCode
                 AND p.SERVICE_AGREEMENT_ID = s.SERVICE_AGREEMENT_ID
				 AND s.TIME_OF_SERVICE BETWEEN p.SAP_EFFECTIVE_DATE AND ISNULL(p.SAP_EXPIRATION_DATE, '12/30/2099')
				 AND s.TIME_OF_SERVICE BETWEEN p.CM_EFFECTIVE_DATE AND ISNULL(p.CM_EXPIRATION_DATE, '12/30/2099')
				 where s.[Action] = 'Deleted' -- Deleted Records Only
				 and s.ID not in ( select id from #Scorecard_2);




-- Remove No Change, Non PQRS Records,  example Chart - 131131460
delete 
from #Scorecard_2 
where PQRS_MEASURES_NUMBER is null
and PreviousCode Is NUll
and [Action] = 'No Change'; 




select 
s.* 


--,(s.ProfProcDeletions)+(s.ProfProcRevisions)+(s.ProfProcAdditions)as ProfProc_N
--,(s.ProfProcCorrect)+(s.ProfProcRevisions)+(s.ProfProcAdditions) as ProfProc_D
--,(s.ProfProcDeletions)+(s.ProfProcCorrect)+(s.ProfProcRevisions)+(s.ProfProcAdditions) as ProfProc_Total

-- Auditor Notes
 , (SELECT COALESCE(Demo, '') + COALESCE(PhyService, '') + COALESCE(FacService, '') + COALESCE(FacProc, '') + COALESCE(PhyProc, '') + COALESCE(Diagnosis, '') + COALESCE(InfInj, '')
	+ COALESCE(General, '') + COALESCE(Anesthesia, '') + COALESCE(Obs, '') AS AuditNotes
	 FROM	#AuditNotes1
	 WHERE	CHART_ID = s.CHART_ID)								  AS AuditNotes

  , (SELECT COALESCE(Demo, '') + COALESCE(PhyService, '') + COALESCE(FacService, '') + COALESCE(FacProc, '') + COALESCE(PhyProc, '') + COALESCE(Diagnosis, '') + COALESCE(InfInj, '')
	+ COALESCE(General, '') + COALESCE(Anesthesia, '') + COALESCE(Obs, '') AS AuditNotes
	 FROM	#AuditNotes2
	 WHERE	CHART_ID = s.CHART_ID)								  AS PostAuditNotes


from #Scorecard_2 s

order by chart_id;


    end

    end



GO
